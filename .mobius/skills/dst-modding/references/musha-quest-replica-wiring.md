# Musha Quest/Advance System — Wiring, Replica Push & Panel Sync

Collected 2026-09-08 while repairing the Musha 转职任务 (advance quest) chain: panel stayed "暂无任务" forever, and several features did literally nothing. Root causes were half-wired plumbing, not game logic. This file is the wiring map + reusable fix patterns.

## Broken-chain audit: "feature does nothing" checklist
When a Musha feature silently no-ops, grep the FULL chain before touching game logic:
1. AddAction (scripts/actions/musha_actions.lua) — action exists?
2. ComponentAction gate (tag → action shown) — tag actually added anywhere?
3. Component method the action calls — EXISTS? (see InteractScene bug below)
4. Prefab/entity that carries the tag+component — registered in PrefabFiles or post-init'd?
5. Server writer that seeds the data the panel reads — called from anywhere?
6. Replica → panel read path — net_string dirty event pushed on write?

### Concrete dead links found (all fixed 2026-09-08)
- `AddAction("MUSHA_QUEST_INTERACT" ...)` called `act.target.components.musha_action:InteractScene(doer)` but musha_action.lua only had `UseItem`/`CanUse`/`SetFn` → SCENE click would LUA ERROR. FIX: alias `InteractScene(doer) = UseItem(doer)`.
- `Musha_Profession_Component:SetAdvanceQuest` (only writer of panel's `quests_for_advance`) had ZERO call sites → 3-slot 转职任务 could never start. FIX: altar interact (see below) now calls it via `quest:StartQuests(ids, pool, true)` which dual-writes.
- 进阶祭坛 prefab (`musha_altar`) never existed (language/action/tag scaffolding only). FIX: placeholder graft, below.
- `AbortQuests` wrote `pc.mydata.quests_for_advance` — component stores `pc.userdata`; `mydata` is nil → nil-index crash on abort. FIX: mydata → userdata (also in commands/musha_panel.lua `pc.mydata.has_advanced`).
- quest RegisterListeners had `areatrigger` → `OnAreaTrigger` (method missing = landmine) but real discovery is modmain's 5s poll → `OnDiscovered`. FIX: keep listener, add no-op method.
- collect quests: modmain already PushEvent's `"musha_item_collected"` on nightmarefuel/gem pickup but quest never listened → collect/collect_gems stuck at 0. FIX: `inst:ListenForEvent("musha_item_collected", ...) → OnCollected`.
- survive quest: no day hook. FIX: `inst:WatchWorldState("startday", function() self:OnDayPassed() end)` on the player entity (profession_component already uses the same pattern for daily XP).

## Dual-store architecture (map, do not confuse)
- **Logic/progress store**: `musha_quest.current_quests` (per-player component; progress via OnCrafted/OnKilled/OnCollected/OnDayPassed/OnCookpotHarvest → MarkQuestDone → CheckAllDone → pc:CompleteAdvance).
- **Panel display store**: `pc.userdata.quests_for_advance` (3 IDs) + `.quests_for_advance_done` + `.quests_advance_progress` (array of {p=progress, t=target}) — mirrored to client via replica net_string; panel_screen renders from `replica.cached_data.userdata`.
- Every place that mutates one store must sync the other. Concretely: StartQuests dual-writes ids into userdata; MarkQuestDone pushes done; CompleteAdvance pushes; OnLoad reconciles quest→userdata for old saves.

## Server → panel replica push (the reliable pattern)
Do NOT rely on the component's Klei `Class` props table for a push method — the constructor assigns `self.userdata = { ...data... }` which SHADOWS the props entry `userdata = DoUpdata`, so `pc:userdata(...)` / `pc:DoUpdata(...)` are confusing traps. The direct, verified path is to call the REPLICA component (exists on the server entity too):

```lua
-- from quest/profession component code (server side):
if pc.inst and pc.inst.replica and pc.inst.replica.musha_profession_component then
    pcall(function()
        pc.inst.replica.musha_profession_component:DoUpdata(pc.userdata)
    end)
end
```
- replica `DoUpdata(tbl)` json-encodes and `self.gamedata:set(...)`; net_string's 3rd arg is the dirty-event name (`"gamedata_dirty"`), which fires on ALL ends → panel's `OnGameDataChanged` re-reads `cached_data.userdata`. So one push refreshes both the local HUD panel and remote clients.
- Per-job data (warrior/saber/guardian/mage) have their own net_strings with `warrior_dirty` etc. — panel listens to all; pushing userdata alone (gamedata_dirty) is enough for quest/level/exp UI.
- Wrap in pcall: on single-player/host the replica exists, but defensive pcall avoids a nil-component LUA ERROR taking down the quest handler.
- Progress ticks: quest increments `q.progress` at 8 call sites; each was patched to call `self:SyncProgressToPanel()` right after `q.progress = q.progress + 1` (same indent — a python re-sub by leading whitespace works: `re.compile(r'^( *)(q\.progress = q\.progress \+ 1)\s*$', re.M)`). SyncProgressToPanel writes `pc.userdata.quests_advance_progress = {{p=..,t=..},...}` then does the replica push above. NOTE: killing 20 spiders = 20 json pushes — acceptable at this data size; if perf ever matters, throttle to N ticks.

## Placeholder entity: graft tags/components onto a vanilla prefab
To fake an unimplemented mod building (altar) with zero new art: `AddPrefabPostInit("statuemaxwell", ...)` on a vanilla prefab, add the mod tag + mod component + SetFn. No PrefabFiles entry, no anim assets needed. (Mod component lookup works for components living in scripts/components/ — same as jobbook/skillbook prefabs which AddComponent("musha_action") successfully.) Interaction then flows: SCENE right-click → ComponentAction (tag musha_altar) → AddAction fn → `musha_action:InteractScene` → SetFn.

Altar accept gate (statuemaxwell post-init fn, modmain): has job (carrer_base) → not advanced (no carrer_special / has_advanced) → no active quest → level ≥ 7 → pick 3 quests from pool 2 skipping heal_skill (skill system is `_musha_skills.lua.bak`, disabled) → set `pc.userdata.current_advance_target` + call `quest:StartQuests(ids, 2, true)`.
Pool skip helper: iterate MUSHA_QUEST_POOLS + MUSHA_QUEST_TYPES (both are GLOBAL, defined by musha_quest.lua); drop ids whose type == "heal_skill"; shuffle; take 3.
`BASE_TO_ADVANCE = { warrior="saber", mage="alchemist", ranger="bard", assassin="moonshadow", rogue="moonshadow" }` — single-target default for now (multi-target job choice UI not built).

## Save/Load consistency
- musha_quest OnSave stores current_quests/active/pool; pc OnSave stores whole userdata. Load both → normally consistent because StartQuests dual-writes.
- Old saves (pre-fix) may have active quests in musha_quest but empty `quests_for_advance`. OnLoad now rebuilds ids/done from current_quests into pc.userdata + pushes — keeps panel truthful after upgrade.

## Slide-in quest rows (panel animation, reusable)
- Make each of the 3 fixed quest rows a `Widget("quest_row_N")` child positioned at its target y; put name Text + status Text INSIDE the row at local (0,0) offsets (so row animation moves both). row:Hide() by default.
- On has_task false→true (panel visible): for i=1..3 set `row:SetPosition(0, target_y-90)` then animate via the widget's own uianim:
  ```lua
  row.inst.components.uianim:MoveTo(Vector3(0, from_y, 0), Vector3(0, row.target_y, 0),
      0.30 + (i-1)*0.08, i==3 and function() self._quest_slide_playing = false end or nil)
  ```
- If the panel is CLOSED when the task arrives, set a `_quest_slide_pending` flag; in ShowPanel after Refresh()+Show(), if pending then clear + PlayQuestSlideIn(). Guard re-entry with `_quest_slide_playing`.
- Status text per row: done → "✓"; else progress "p/t" from `quests_advance_progress[i]`; else "进行中".
- Empty-state copy is state-dependent (B-strategy): no job → "暂无职业 / 使用职业书开启职业之路"; has job, no quest → "暂无转职任务 / 前往进阶祭坛（麦斯威尔雕像）接取".

## Status
Fixed & code-reviewed (luaparser syntax OK on all 4 files). IN-GAME TEST STILL PENDING: c_spawn("statuemaxwell"), right-click accept (needs ≥7 / console-bumped level), watch rows slide in + progress tick, complete 3 → auto-advance + skillbook. See `mods/musha/musha-backlog.md` (2026-09-08 section) for the checklist.
