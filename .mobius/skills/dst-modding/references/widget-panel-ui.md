# DST Widget Panel UI — Layout & Pitfalls

Class knowledge for building/editing DST widget panels (pattern source: musha_panel_screen.lua).
Collected 2026-09 during Musha 0.7.7 panel compaction (review-driven: left-shift, shrink, Lv badge, faint empty exp bar).

## Positioning a panel on screen
- Use center anchor + offset: `SetScaleMode(SCALEMODE_FILLSCREEN); SetHAnchor(0); SetVAnchor(0); SetPosition(x, y)`.
- NEVER anchor TOP/RIGHT with a small offset for tall panels: with TOP anchor the offset is measured from the screen top, so a panel whose half-height exceeds the offset has its top half flying off-screen → symptom: only a sliver of background visible, content all gone.
- Coordinates are logical pixels on a 1920x1080 baseline (FILLSCREEN scales). Screen center = (0,0); right edge ≈ 960; bottom ≈ -540.
- Side-panel placement (0.7.8 FINAL, validated): panel 506x460 at root (-340, 36) → occupies x -593..-87, y -194..266. One session iterated RIGHT side → LEFT side near crafting bar: (250,60) → (190,60) → (-210,60) → (-310,0) → (-340,36); size 300x400 → 360x460 → 506x460 (aspect 1.1:1, height kept). Final left-side placement presses the world-center edge — user EXPLICITLY accepted ("接受可能压到对话/世界中心边缘" → picked yes). Don't revert to the old right-side rule on your own.
- ⚠️ SUPERSEDED (2026-09-08): user asked both Musha UIs centered on screen → root SetPosition is now (0,0) (see bottom section). Any prior "-340,36 / -380,36 / 屏幕左侧" note for panel_screen is history only.
- User adjusts position/size in terse numeric nudges ("左移400"、"左移100 下移60"、"换成1.2比例或者1.1 上移 -30x 36y") — apply each nudge verbatim, update the comment block with the new occupied range, re-run bracket check. Don't ask why or suggest alternatives unless a nudge would push the panel off-screen.
- Aspect-ratio change at constant height: PANEL_W = PANEL_H * ratio (1.1:1 → 506x460). Keeping height preserves the vertical content layout (job title + exp bar + 3 quest rows at fixed y); only width grows, content stays left-aligned.
- Interior fixed-x elements do NOT auto-scale with PANEL_W (they're centered-anchor literals): job_text x=-80 (4-char name → left edge -152), level_badge x=34, exp track center x=-2 (width 280, left end -142, fill left-pinned at -142+140*pct), quest name x=-68 (7-char → left edge -145), quest status x=55. All still fit at half-width 253; if the panel is widened again, re-check these against HALF_W.

## Text/Image layout
- DST Text/Image have NO SetHRegPoint — position everything from center anchors, manual math.
- Chinese char width ≈ font size: 4 chars @ 40px ≈ 160px wide. E.g. inside 300px panel (HALF_W=150), center x=-80 → left edge -152.
- Longest content governs: task names up to 7 chars @ 22px = 154px; center -68 → left edge -145, right edge +9 (status column at x=55 clears it).

## Left-growing progress bar
- Track: `square.tex` Image, width W, centered. Fill: same square, center x = track_left + (W/2)*pct so its left edge stays pinned to track's left edge; SetSize(W*pct, h) each refresh.
- PITFALL (found 0.7.7): fill y was hardcoded twice and drifted — create y = HALF_H-96, refresh y = HALF_H-112 → fill sat 16px below its track. Define track/fill y once (shared constant) and reuse in every refresh body.
- Fade at zero progress: when pct <= 0.001 (fresh job / Lv.0) drop track alpha 0.6→0.35, fill alpha 0.9→0.35, count text alpha 0.9→0.6 — an empty bar must not scream "progress".

## Duplicated refresh blocks (dirty-event handler + explicit Refresh)
- This widget keeps two identical refresh bodies (OnGameDataChanged from `gamedata_dirty`/`*_dirty` events + self:Refresh). patch's old_string must be unique → disambiguate with the preceding line: handler starts `local md = cached.userdata`, Refresh starts `local md = cd.userdata`.
- Any new member (e.g. level_badge) must be styled in BOTH blocks or states diverge between open paths.

## Quest-row frames & slide-in (2026-09-10)
- Row = Widget container holding, in order: **bg Image (背景板) → frame (4-line outline) → bar/barw (top strip) → name Text → status Text**.
  Add bg/frame/bar FIRST so they render under the text (child order = z-order).
- ⚠️ **背景板 ≠ 框体** — the user treats these as two separate elements. `bg` = the coloured plate (yellow/gray/green
  fill); `frame` = the per-row OUTLINE drawn on top of the plate. When the user says 框/框体 they mean the per-row
  outline (DEFAULT). 2026-09-10 I misread "加小框框作为整体的任务框架" as one big border around ALL rows and had to
  revert it the next turn — "整体的任务框架" was describing the per-row frames collectively. If they truly want one
  outer box they say 整体/外面. clarify() timed out that round; per-row is the safe default.
- Per-row frame = 4 thin `square.tex` bars (no art) at the bg's edges, `FT` thick, pushed outward `FOFF`; store them
  in `row.frame` (a table) and recolor per row type inside UpdateQuestRows:
  ```
  local FT, FOFF = 4, 4          -- 2026-09-10: 加粗到4像素 + 框体改大
  top:    x=-80,        y= 32+FOFF, w=ROW_W+2*FOFF, h=FT
  bottom: x=-80,        y=-32-FOFF, w=ROW_W+2*FOFF, h=FT
  left:   x=-500-FOFF,  y=0,        w=FT, h=64+2*FOFF
  right:  x= 340+FOFF,  y=0,        w=FT, h=64+2*FOFF
  ```
  colors: daily gold (0.9,0.72,0.3) / advance red (0.9,0.3,0.25) / done green (0.35,0.8,0.4).
  The top strip (bar/barw) sits INSIDE the frame at y=26 (y=32 collided with the new top frame line, FT=4).
- Right vertical rail (竖栏) + yellow grip (2026-09-10): ONE tall `square.tex` bar on the right of the rows in
  "蜡黄深陷" tint, plus a small bright-yellow grip at its top — both children of `self.content` (NOT per-row):
  rail `VBAR_X`=400, w=12, from `VBAR_TOP`=114 down to `VBAR_BOT`=-392, tint (0.62,0.54,0.33,0.82);
  grip 23 wide × 36 tall at rail top, tint (0.95,0.82,0.35). Nudged 右移12/上移8 (388→400, top 106→114) —
  a normal position nudge, apply verbatim.
- Frames need NO new art: built-in `Image("images/global.xml", "square.tex")` is a plain white square — tint it
  per row type. Reusable trick for ANY panel divider / frame / highlight without shipping a .tex.
  - daily row: bg 840x64 @(-80,0) tint (0.85,0.68,0.25,0.28) yellow + WHITE top strip `barw` 840x4 @(-80,32)
    tint (1,1,1,0.7) `barw:Show()`, red `bar:Hide()` — the white strip is the user's "普通任务" marker
  - advance row: bg tint (0.42,0.40,0.38,0.55) gray + red bar 840x6 @(-80,32) tint (0.85,0.22,0.18,0.95)
    `bar:Show()` + `barw:Hide()`
  - done row: bg tint (0.25,0.5,0.28,0.32) green
  - Draw order under the text: bg → bar → barw → name → status. Widths: keep ONE `ROW_W` constant feeding
    bg/bar/barw `SetSize` so a width change hits all three (user asked the strip 跟随大小 = follow the frame).
  - Row group x-offset: `ROW_X` (2026-09-10 nudges: 任务右移12 → 再右移20 → **ROW_X=32**); rows `SetPosition(ROW_X, target_y)`
    and store `row.target_x`. ⚠️ The empty-state pair (quest_empty/quest_hint) is a SEPARATE group — when the user
    says "任务右移N" they mean the task ROWS; do NOT auto-shift the empty text too (leaving it centered is correct
    since it must stay symmetric with the panel art).
- Text colour must contrast its frame: on the yellow daily frame use DARK text (0.28,0.2,0.1); advance row keeps
  red text (0.95,0.5,0.4). Setting a light text on the yellow frame = illegible.
- Slide-in: `row.inst.components.uianim:MoveTo(Vector3(ax,ay,0), Vector3(bx,by,0), dur, cb)`.
  **Direction is a USER PREFERENCE, not a default**: 2026-09-10 the user rejected the original bottom-to-top
  (from_y = target_y-90) and asked for **right-to-left push**: start `from_x = target_x + 320`, land on
  `target_x` (NOT 0 — offset rows land at ROW_X). Default to horizontal-from-right for this user.
- Stagger: dur = 0.30 + (idx-1)*0.08; put the completion callback ONLY on the last SHOWN row (clear
  `_quest_slide_playing` there). Count shown rows first — a hidden row must not consume a stagger slot or the
  final callback never fires and the guard sticks true.
- The row has `target_y` + `target_x` fields; the pre-slide SetPosition and the MoveTo endpoint must both carry
  y = target_y (don't drop the y component) and land on target_x, e.g.
  `MoveTo(Vector3(from_x,target_y,0), Vector3(target_x,target_y,0), dur, cb)`.

## Lv-as-badge pattern
- Small dark square Image (e.g. 46x26) + ~17px white Text stacked at same center; tint flips with job state: has_job (0.35,0.28,0.2,0.9), no-job grey (0.3,0.3,0.3,0.35). Reads as a small secondary tag, not a second heading floating at title size.

## Empty-state hierarchy
- Main line ~20px; helper line 15px, dimmer grey, alpha ~0.6 — helper must read as clearly secondary.
- Center the pair where the task rows would sit (task rows at y=40/-10/-60; empty pair at 0/-30) so layout doesn't jump when tasks appear.

- ✅ MIGRATED 2026-09-10 (this closes the TRANSITION note): quest server store is two independent models —
  `daily_quests` array (accumulates ≤10, discover voids next day) + single `advance_quest` w/ 3-round
  counter. SyncToPanel writes userdata `daily_quests[{id,n,p,t,done}]` / `advance_quest` / `advance_round`
  and CLEARS `quests_for_advance`. The panel NOW reads the new fields: `UpdateQuestRows(md, has_job)` takes
  the WHOLE userdata table (the old 3-array signature `(qa,qd,prog,has_job)` is gone — patch both call sites,
  the dirty handler and self:Refresh). Task name comes over the wire as `n` (fallback `QuestName(id)`).
  If the panel is blank, the #1 suspect is a missing `AddReplicableComponent("musha_profession_component")`
  in modmain (blank with ZERO log errors) — see `references/dst-mod-env-and-config.md` §6.0/§6.1.
  Verify server state with chat `/musha` (GetQuestDisplay). Model + roadmap: `references/musha-quest-system.md`.
- (HISTORY, superseded 2026-09-10) "panel task rows read a DIFFERENT store than scroll quests" — both flows
  now live in musha_quest and sync through the profession replica; the old quests_for_advance / current_quests
  split is gone. Keep for context only.
- ⚠️ OUTDATED as of 2026-09-08 fix session: the old note claimed the 3-slot chain could never start (SetAdvanceQuest had zero call sites → panel always 暂无任务). That plumbing is NOW WIRED end-to-end (altar/statue accept → StartQuests syncs userdata → replica push → panel rows slide in with x/y progress → all ✓ → CompleteAdvance auto-advances job). Full server-side wiring, sync push pattern, broken-link checklist, quest pool tables and the user's NEW design direction (每日4任务+雕像仅限转职+一次一个) are in `references/musha-quest-system.md` — read THAT file before touching quest code; this UI file covers panel render only.
- Do NOT "fix" 暂无任务 with copy implying unmet conditions — with the chain wired, empty now legitimately means "未接取/已完成". Empty-state copy is state-driven (无职业 → 使用职业书; 有职业未接 → 前往进阶祭坛(雕像)接取).

## Background image: scale proportionally, don't SetSize-stretch
- Panel bg `images/bookpage_bg.png` ORIGINALLY 1000x1467 (0.68:1 portrait) — SUPERSEDED 2026-09-03 by a NEW landscape bg 1232x832 (1.48:1); current Musha panels are horizontal cards (see bottom section). The old portrait dims still apply to `musha_note_bg` (1800x1011, 5月旧图).
- `SetSize(w, h)` with a different ratio warps the art (symptom: 面板歪了). Use `SetScale(BG_SCALE)` where BG_SCALE = target_h / 1467, and derive PANEL_W = 1000 * BG_SCALE so borders match the actual art (0.7.8 fix). Same rule with current src dims: BG_SCALE = PANEL_H/832, PANEL_W = 1232*BG_SCALE.
- 0.7.8 layout as-tested: center (-340, 36), ≈314x460. User judged it unfit — the panel still needs 4 job-switch buttons (warrior/saber/guardian/mage). Redraw spec (target panel 500x650, bg art 1000x1300 2x, zones: header → 4-button row → quest list) at `mods/musha/panel-bg-redraw-spec.md`.

## Verification without luac
- The Windows DST box has no luac/lua. Run `scripts/lua_bracket_check.py <file.lua>` for a string/comment-strip + bracket balance check. Catches unbalanced ( ) { } [ ], not logic errors.
- REAL Lua syntax check available: luaparser (pip) is installed on the SYSTEM python `C:/Users/Administrator/AppData/Local/Programs/Python/Python311/python.exe` but NOT in the hermes venv — `execute_code` / bare `python` import will fail with ModuleNotFoundError. Call the system python explicitly:
  ```bash
  "C:/Users/Administrator/AppData/Local/Programs/Python/Python311/python.exe" - <<'PYEOF'
  from luaparser import ast
  ast.parse(open(r"scripts\widgets\musha_panel_screen.lua", encoding="utf-8").read())
  print("SYNTAX OK")
  PYEOF
  ```
  Catches unbalanced do/end/if/function that a bracket check misses. Note: luaparser is Lua 5.3-ish; DST uses 5.1 — fine for syntax, GOTO/labels would differ but this codebase doesn't use them.

## Background image aspect ratio — SetSize stretches ("歪" symptom)
- PITFALL: `bg:SetSize(w, h)` forces the art to w x h regardless of the source image's native ratio → panel looks 歪/stretched. bookpage_bg.png NOW 1232x832 landscape (2026-09-03 swap); was 1000x1467 portrait in 0.7.8. When the user reports the panel looks wrong, suspect the bg ratio BEFORE tuning other layout values.
- FIX — proportional scaling: keep target height, derive width from source art, scale the Image (no SetSize on bg):
  ```lua
  local BG_W, BG_H = 1000, 1467          -- source art pixels
  local PANEL_H = 460                    -- chosen target height
  local BG_SCALE = PANEL_H / BG_H
  local PANEL_W = BG_W * BG_SCALE        -- ≈314 here; use for borders/HALF_W
  self.bg:SetScale(BG_SCALE)             -- NOT bg:SetSize(PANEL_W, PANEL_H)
  ```
- Reading source dims: DST images usually ship a .png next to the .tex. Read PNG IHDR bytes 16:24 as big-endian `'>II'` (w, h). Use execute_code / python open()+struct — the user may deny `python -c` shell one-liners. .tex magic is "KTEX" (hex 4b544558).
- ⚠️ 2026-09-08 pivot: the above "shrink bg to small card" guidance is the OLD approach. When the user asks for 原图全尺寸/按原图大小 (they did, after reporting a zoomed small card as 变形/compressed), STOP shrinking: `bg:SetSize(1232, 832)` with the art's NATIVE dims IS correct 1:1 (ratio preserved) — SetSize only warps when the w:h you pass ≠ the art ratio. Lay content out at full-size coords instead. Also NEVER pass pixel sizes as two-arg `SetScale(w, h)` (SetScale is a multiplier, not a size API; use SetSize or a single proportional factor).

## Musha panel redesign — CURRENT STATE (2026-09-08, art-native 1:1)
- ⚠️ The vertical redraw spec (`panel-bg-redraw-spec.md`, target 500x650 vertical, 4 job buttons) was SUPERSEDED 2026-09-03: instead of a redraw, the ART was swapped to a pre-made horizontal 1232x832 bookpage bg (new png → Mod Tools autocompiler regenerated tex/xml, in-game live) and code was adapted horizontally. Do NOT apply the old 500x650 vertical spec.
- ⚠️ SUPERSEDED same day (second user correction): the interim "small card + PANEL_ZOOM" stage (skillui 592x400 @zoom 1.4, panel_screen ≈503x340 @zoom 1.25) was judged 变形 → user requested 原图全尺寸 (native art size, 1:1, no compression). Current geometry:
  - **Both UIs now render bookpage_bg at native 1232x832**: `bg:SetSize(1232, 832)` (== native px ratio, so no aspect warp; SetSize only warps when w:h ≠ art ratio — native dims are the clean 1:1 case). Inner coords are now full-size logical units, NOT pre-zoom units.
  - ⚠️ Whole-card scale is an ACTIVE knob, not parked at 1: after the 1:1 pivot the card at zoom 1 filled nearly the whole user window, so the user drove it by bare ratio numbers — 缩小到0.87 → then 放大到0.93 (session end 2026-09-08: PANEL_ZOOM = 0.93 in BOTH skillui.lua and panel_screen.lua, render ≈1146x774). Same "apply the nudge verbatim" rule as position nudges: user types a number, change the one constant at the top of each file, say the resulting px, done. Do NOT re-derive all inner coords when they nudge zoom — content scales together.
  - skillui: card 1232x832. Rows LIST_X=52; page-1 rows from y+187 step 98 (font 44 name / 32 desc), other pages y+302 step 125; header name (-330,300) font 44, EXP track 420x16 center (280,236) fill left-pinned 70+210*pct; 技能点 text (280,300) font 32; hint y list_y-55 font 30.
  - panel_screen: bg native; title font 64 HAlign LEFT at (-300,230) after 2026-09-08 nudge chain (见下方"外部排版评审"节)；Lv badge 100x56 + Lv text at **x=264**, y=250 (2026-09-10 nudge chain: (180,230)→右30上20→(210,250)→+12→(222,250)→+12→(234,250)→+22→(256,250)→+8→(264,250)); ⚠️ CONTRAST IS A LIVE KNOB: user asked 淡化 (tint 0.55,0.48,0.4,0.55 / white alpha 0.8) → then 元宝 review flagged the Lv tag as too faint vs "战士" → re-bumped one notch to tint (0.5,0.42,0.34,0.8) + white alpha 1.0 (apply in creation AND both refresh bodies via replace_all, or open-state reverts to the old color). Don't treat either value as final — user flips 淡化/醒目 across sessions; exp track 930x22 center (-15,150) (LENGTHENED +220 over old 700, then +10 more right → 930; left end -480, right end 450), track grey (0.3,0.3,0.3,0.6) + fill grey (0.72,0.72,0.72,0.95) — user asked blue fill → grey, applied via replace_all in BOTH refresh bodies + the no-progress fade branch (0.72,0.72,0.72,0.35); fill left-pinned x=-480+465*pct (930*pct wide); exp count text font 26 at (-130,205), string = "职业经验 "..exp.."/"..exp_max (NOT bare "1/5" — 语义前缀 per 元宝 review; NOTE: user later corrected "回复原位置"→ exp_text belongs at -130 fixed, NOT re-centered when track lengthens); **6 quest rows** y = ROW_TOP(70) − (i−1)*ROW_STEP(78), i=1..6 (name font 34 x=-330 ANCHOR_LEFT, status font 30 x=150 ANCHOR_RIGHT); empty states (-20,-40) font 48 & helper (-20,-160) font 26 alpha 0.5. (Was 3 rows @step 115 before the 2026-09-10 quest-model migration — daily_quests can hold ≤5 + 1 advance row, so 3 slots overflowed.)
  - Both root positions stay (0,0) centered (skillui root = FrontEnd screen SCALEMODE_PROPORTIONAL + ANCHOR_MIDDLE; panel_screen = HUD widget SCALEMODE_FILLSCREEN + HAnchor/VAnchor 0).
- **Hot-zone over art-drawn button (reusable math)**: close ✕ is painted INTO the art at top-left px ≈(1140,90). To place the transparent hit ImageButton in center-origin coords (art W=1232,H=832): `x = art_px - W/2 = 1140-616 = 524`, `y = H/2 - art_py = 416-90 = 326`. Formula works for any element painted in the bg art. ⚠️ The art-px estimate is only a starting point — the real painted ✕ may sit a few px off. On 2026-09-08 the user nudged it repeatedly; SESSION-END position: left-up 15 → (509,341), left 10 → (499,341), left 4 → (495,341), left 3 → **(492, 341)** (size 80x80), i.e. actual art position ≈ px(1118,75). Apply such hit-zone offsets verbatim like position nudges — never re-derive from the formula once the user has hand-nudged it (art-px estimates are stale; the nudged value IS the ground truth).
## External layout review via 元宝 (Tencent AI) — workflow (2026-09-08)
- User regularly screenshots the in-game panel and pastes it into 元宝 for a design critique, then pastes 元宝's review text back and expects code patches from it. Treat the review as a SOURCE OF REQUIREMENTS, not prose to summarize.
- Distinguish code-fixable items vs ART-side items in the review: right-side button column / watermark / corner flowers are painted INTO bookpage_bg.png → NOT fixable in code; tell the user those need their art side (user or 元宝 redraw), don't attempt them. Code-side items (text positions, sizes, colors, hit zones, hierarchy) → patch now.
- 元宝's layout review findings mapped to concrete changes this session:
  1. Isolated count "1/5" under the bar reads orphaned → put the count ABOVE the bar centered with a semantic prefix: "职业经验 1/5" (text at bar-center y+55, ANCHOR_MIDDLE). Update BOTH duplicate refresh bodies' SetString (replace_all).
  2. Title row unbalanced (name far left, Lv floating center) → left-anchor job name (SetHAlign(ANCHOR_LEFT)), Lv badge sits right next to it as one visual group.
  3. Empty-state hierarchy too flat → main line bigger (48) + helper smaller/dimmer/farther (26, alpha 0.5, y gap ~120).
- After the review patches the user keeps giving single-axis nudges ("右移动一些"、"下移动 120") until it visually lands — apply verbatim, but BEFORE moving a text row DOWN check what sits below it: title font 64 at y=230 overlaps the exp count text at y=205 (64px glyph spans ±32). When a nudge would collide with the element below, ask a one-line scope question (move just the title vs the whole block) instead of guessing.

## Position nudge pitfalls (2026-09-08 update)
- User reports misplacement with qualitative phrases first ("还是歪了 战士整体向下"), then corrects with exact numbers. I misread "战士整体向下" as move-down instruction and moved the title UP (y 300→350) — user then gave exact "下移动 120". LESSON: qualitative Chinese layout complaints are ambiguous ("整体向下" could mean it IS too low, i.e. move up, or MOVE it down). When a qualitative nudge's direction is ambiguous, apply the number if given; if none given, ask which direction rather than guess — one clarifying line is cheaper than a wrong-direction patch + re-verify cycle.
- Live tracker doc: `mods/musha/ui-redesign-plan.md` (in project, not skill) holds the authoritative checklist/state incl. pending: in-game look after 1:1 change, blurry-text fallback, "豆包AI" watermark + right button column cleanup (user's art side), note_screen style unification.
- **Element-name disambiguation ("回复原位置/改回之前" corrections, 2026-09-08)**: user names elements loosely — "职业技能回复原来的位置" turned out to mean the exp-count label text ("职业经验 1/5"), NOT the job title "战士"; I guessed wrong (moved 战士 to (-380,300)) and even a clarify() timed out, then the user corrected with "改回之前——那个之前改回原位置的 应该是职业经验那个". LESSONS: (a) when a nudge could map to two widgets, keep a one-line map of this panel's labels→widgets (战士=job_text, 等级/Lv=level_badge+level_text, 职业经验/进度=exp_text, 小蓝条=exp_fill, 叉号=close_btn) and when ambiguous state which you're moving and which you're NOT; (b) "回复原位置/改回之前" is only executable if you remember the previous position per element — track a compact position history in the file's comment block as you nudge (each patch comment already logs old→new; before answering a "改回" request, re-read the comment to find the prior value); (c) a timed-out clarify must NOT default to a guess that moves the wrong element — when the element reference is ambiguous and no answer comes, the safe move is to ask which element in the same reply that you DO the unambiguous parts (nudges with clear targets like 叉号左移/等级右移), then apply the ambiguous one after confirmation.
- Multi-target nudge chains land best as separate patches per element with clear per-target comments (叉号 / Lv / 职业经验 / 战士 were four independent patches in the final exchange) — do NOT merge them into one giant old_string that can drift.
- **Screenshot feedback loop when vision is unavailable (2026-09-08)**: this user pastes in-game screenshots to judge layout, but on this host the assistant's vision channel could NOT read local image files at all — tried raw PNG path, RGBA→RGB conversion, downscaled PNG, and base64 data-URL; every path returned "[Unsupported Image]"/"unable to see". DON'T burn many tool calls converting; the image analysis model here is deepseek-family with no working vision fallback. Two workable substitutes: (a) ask the user for terse text (they answer in short phrases like "卡片位置/叠了/字糊/挡画面"); (b) inspect the screenshot file itself with PIL for size/format sanity — a screenshot whose pixel dims ≈ the computed card render dims tells you the card fills the window (that's how 0.93 ≈ user-window-width was confirmed: clip 1149x803 ≈ 0.93*1232=1146 wide). The same "my vision channel is unavailable, describe in text or give coordinates" handoff is pre-agreed with this user (see ui-redesign-plan "待用户确认" pattern).
- Panel-bg-redraw-spec.md in project still describes the ABANDONED vertical target — read it only for the four-job-button concept, not as current layout.

## Framed sub-page pattern: layered border + inner plate + INNER-BOUNDS CONSTRAINT (2026-09-11)
Screen-version 5-page panels (home/skill/mail/settings/dex) draw each sub-page as a stack:
layered frame (outer) → inner plate → content container → controls. Child order = z-order, so build in that order.

- **"魔兽/板甲质感" with only `square.tex`**: stack 3 `FrameLines` at increasing inset —
  outer dark brown-black `(0.20,0.14,0.09)` 6px → orange main band `(0.86,0.52,0.20)` 16px →
  inner gold hairline `(0.96,0.84,0.48)` 3px, plus 14x14 gold corner studs at `(±(W/2-6), ±(H/2-6))`.
  No art needed. **Say upfront** that real plate texture needs a 9-slice border `.tex` — this is only
  "layered depth", so the user doesn't expect a painted frame.
  ```lua
  -- inset = 往里缩多少才开始画, thick = 线粗; 4 条 square.tex 杠
  local function FrameLines(parent, w, h, inset, thick, r, g, b, a)
      local bw, bh = w - inset*2, h - inset*2
      for _, ln in ipairs({ {0, bh/2-thick/2, bw, thick}, {0, -(bh/2-thick/2), bw, thick},
                            {-(bw/2-thick/2), 0, thick, bh}, {bw/2-thick/2, 0, thick, bh} }) do
          local line = parent:AddChild(Image("images/global.xml", "square.tex"))
          line:SetSize(ln[3], ln[4]):SetPosition(ln[1], ln[2]):SetTint(r, g, b, a)
      end
  end
  ```
- **Inner plate inset rule**: plate inset must exceed the frame's total thickness or the plate covers the
  frame. Frame ends at inset 6+16+3 = 25 → plate `SetSize(W-50, H-50)`; its half-extent `W/2-25` meets the
  gold hairline's inner edge exactly.
- ⚠️ **PITFALL — every control in a framed page must FIT INSIDE the plate half-extents.**
  Mail page: page 890x600, plate 840x550 → **y must stay within ±275**. Pagination row sat at
  `PY = -H/2+32 = -268` with height 26 → bottom edge **-281**, i.e. 6px over, landing exactly on the frame's
  orange band (±294~±278) and gold hairline (±278~±275). The buttons' translucent tint blended with the
  frame underneath → user reported **"翻页会显示外框底色 颜色有问题"**.
  Fix: `PY = -H/2+46` (up 14) → buttons span -267~-241, fully on the plate.
- 🔎 **DIAGNOSTIC LESSON — a "color problem" near a frame/plate edge is usually GEOMETRY.**
  When the user reports 颜色有问题/发脏 on a control that sits near an edge, FIRST compute the control's
  min/max x,y against the plate half-extents. Overlap reads as a wrong color but the fix is a position nudge.
  Do NOT start changing RGB — that's how you burn a round and get 判错.
  Loose-report workflow: user gives the symptom without numbers → fix the root cause, then offer ONE
  concrete follow-up in the same reply ("if the 蜡黄 button still blends into the orange-grey plate,
  I'll switch it to 深棕底+金字"). Don't ask a question instead of patching.
- Reusable button skin for controls on a plate: `StyleLikeTriangle(b, w, h)` = image tint
  `(0.70,0.62,0.42,0.95)` / focus `(0.86,0.78,0.56,1)` + 4 white 2px `square.tex` border bars;
  label `b._label:SetSize(n)` to set font size (used to shrink pagination: `<`/`>` 44x26 @20pt, page nums 28x22 @16pt).
- Pagination pattern: `<` `>` as separate buttons + a `mail_pagenums` container rebuilt in Refresh
  (one button per page, click = `MailGoto(p)`); position container + both arrows off ONE `PY` local so a
  single nudge moves the whole row.

## Mouse input on a full-screen panel — scroll wheel closes it (2026-09-10)
- A panel whose `OnMouseButton(button, down, x, y)` closes on ANY `down` also closes on the MOUSE WHEEL: DST sends
  the wheel as its own mouse buttons `MOUSEBUTTON_SCROLLUP=1003` / `SCROLLDOWN=1004`
  (constants.lua: left=1000, right=1001, middle=1002). Symptom: 滚轮一滚面板就关.
- ✅ Fix — close only on left click:
  ```lua
  local MOUSE_LEFT = rawget(_G, "MOUSEBUTTON_LEFT") or 1000
  function self:OnMouseButton(button, down, x, y)
      if down and button == MOUSE_LEFT then self:HidePanel() end
      return true   -- still swallow the event, just don't act on non-left buttons
  end
  ```
- DST's `widgets/widget.lua` has NO `OnMouseWheel` — the wheel arrives through `OnMouseButton`, so filter by the
  button id instead of hunting for a wheel handler.
