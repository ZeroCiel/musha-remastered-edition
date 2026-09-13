---
name: dst-modding
description: 综合DST Mod开发全参考：modmain/replica/ModRPC、UI（ImageButton/拖拽/遮罩/ScrollList/Screen+ScrollingGrid）、Farming/Giant作物、职业系统（Musha+明生）、崩溃调试、夜视修复、温度系统、武器模板+动画源文件
---

# DST Modding — Development Guide

Complete reference for Don't Starve Together mod development.

> **Related skill:** `oni-modding` — sibling Klei guide (ONI, C#/Harmony, U59); different toolchain.

> **工作流偏好**：①"照搬 X"先读 X 再动手。②UI 坐标一次给完。③"不如前面第N版"→按 backlog 逐版还原。④找参考色别空手回来，给候选色号。⑤见 `references/design-review-workflow.md`。⑥**回话用 `1. 2. 3.` 编号列点**，用户会按编号纠正（原话「不透明 **2** 错了」）；多子句口述先判定每句归属哪个元素。

## Quick Reference
- **安装路径**：`D:\SteamLibrary\steamapps\common\Don't Starve Together`；明生mod 在 `mods\mingsheng\`。
- **种瓜得瓜农场系统** → `references/farm-plant-system.md` — growable 阶段表、巨大化判定、压力清零配方、腐烂恢复、DoGrowth vs 手写
- **面板UI/环境坑/任务系统** → `references/widget-panel-ui.md`+`scripts/lua_syntax_check.py`（luaparser 入口 `ast.parse`）；`references/dst-mod-env-and-config.md`；`references/musha-quest-system.md`
- **面板/滚动/导航** → `references/screen-scrolling-grid.md`、`references/in-game-settings-component.md`、`references/panel-nav-and-icon-buttons.md`
- **职业状态卡面板布局规格（SSOT）** → `references/job-panel-layout.md`（用户口述的权威布局描述，返修以此为准）
- **EQUIPSLOTS 没有 AMULET 槽（2026-08-23 暗影馈赠 bug 根因）**
- **DST API 坑速查（2026-08-23 测试报告批量修复）** → `references/dst-api-pitfalls.md` — 不存在的 API（Ents[guid] / locomotor:Stop() / 巨大化动画名）、传送后回走、Screen ACCEPT 鼠标误触、names xml region 名规则、eater 拒食防御
- **DST 自定义 UI 面板布局（2026-09-01 Musha 职业面板）** → `references/dst-ui-layout.md` — Widget 坐标规则（SetSize/SetScale/SetPosition/锚点）、背景装饰层与内容层解耦、根容器统一缩放、竖版背景装不下横版内容的三种方案、面板元素坐标表
- **影怪系统（2026-08-23）** → `references/shadow-creature-system.md` — SpawnShadowCreature 唯一入口拦截、SetTarget 不走 shouldaggrofn 需轮询清仇恨、shadowcreature tag 导致随从不受攻击+仇恨转移、夜视与护符
- **系统坑合集（2026-08-23 测试轮）** → `references/dst-system-pitfalls.md` — growable 阶段按 name 判断/巨大化动画名、传送误触+回走+记录点验证、names xml region 名规则、伯尼式物品变活物、温度绝缘等效冷热电路：DST 装备槽只有 HANDS/HEAD/BODY/BEARD。purpleamulet（梦魇护符）的 equipslot 是 `EQUIPSLOTS.BODY`（原版 amulet.lua）。`GetEquippedItem(EQUIPSLOTS.AMULET)` 传的是 nil 永远返回 nil → 任何"佩戴护符判定"静默失效、整条链路白写。检查佩戴物品用 BODY 槽。
- **影怪系统（shadowcreaturespawner 拦截/回避）** → `references/shadow-creature-system.md` — 低san/诱导疯狂统一走 SpawnShadowCreature 单入口、SetTarget 不走 shouldaggrofn、暗影馈赠（戴紫色护符影怪不索敌/远离/拦截生成）实现与坑
- **明生知天命武器容器被动（2026-08-23）** → `references/mingsheng-ztm-passives.md` — 7 格容器存放告示的常驻被动（+5攻击/隔热保暖/发光/位面/材料减免/速度）；发光"时有时无"（C-01）根因：光源生成/移除写在 SetDamage 伤害计算函数里、无周期兜底
- **影怪系统拦截（Shadow Creature，2026-08-23）** → `references/shadow-creature-system.md` — 低san/诱导疯狂统一走 shadowcreaturespawner:SpawnShadowCreature（override 单点拦截）、childspawner 系影怪（crawlingnightmare/nightmarebeak/oceanhorror）走 prefab post-init、SetTarget 绕过 shouldaggrofn 需周期 ClearTarget（不能限距离）、AddSimPostInit 组件时机重试、0帧兜底移除
- **EQUIPSLOTS 坑（2026-08-23）**：DST 只有 HANDS/HEAD/BODY/BEARD 四个装备槽，**没有 AMULET**；purpleamulet 等护符穿 BODY 槽。`GetEquippedItem(EQUIPSLOTS.AMULET)`（nil）恒返回 nil → 守卫静默失效不报错。影怪拦截的守卫修复见 `references/shadow-creature-system.md`
- **影怪生成系统与「不刷怪」拦截（2026-08-23）** → `references/shadow-creature-system.md` — spawn 链路（shadowcreaturespawner 为主入口，裂隙/噩梦光/雕像会绕过）、生成拦截三层防线（包装 SpawnShadowCreature + AddSimPostInit + prefab 级 0 帧兜底移除） 挂服务端）、旧怪双保险
- **影怪（nightmare creature）仇恨修复坑**：nightmare 系统生成影怪时直接 `combat:SetTarget(玩家)`，**不走 shouldaggrofn**——`SetShouldAggroFn` 只拦新仇恨，已有仇恨必须周期任务 `ClearTarget()` 解除。shouldaggrofn 里别写 `target.components.combat.target ~= inst` 条件（玩家一还手就永远继续锁敌，死循环）。
- **UI 列表/下拉滚动（ScrollingGrid/TrueScrollList）** → `references/scrolling-grid-truescrolllist-api.md` — 固定大小+下拉的标准做法、widget 复用机制、手写 scroll_offset 的坑、拖拽排序与复用池冲突的三方案
- **明生 S2 C-01 遭遇（已修复 2026-08-20）** → `references/mingsheng-c01-zaoyu-status.md` — 体温锁定接tuning、发光半径7、隔热保暖120；含**DST 双向隔热保暖正确姿势**（insulator 组件只能单一季节，双季须走玩家 temperature 的 inherentinsulation + inherentsummerinsulation 字段）
- **AddComponentAction rules** → `references/addcomponentaction-rules.md` — NEVER bind SCENE/USEITEM to vanilla components
- **SG clean pattern** → `references/sg-clean-pattern.md` — NAMIDA-style stategraph template (~260 lines)
- **Bernie dark fix + finiteuses** → `references/bernie-and-finiteuses.md` — OverrideSymbol fix, finiteuses state pattern
- **动画 bank/build 调试** → `references/anim-bank-build-debug.md` — 出现错误角色动画（wilson vs bernie）的排查清单（grep 全部 prefabs 的 SetBank，召唤物是独立 prefab）、原版代码位置 data/databundles/scripts/、anim.bin/build.bin 检查法、bank 切换完整流程（SG 动画名映射表 + hop 状态删除）、bernie_big 有官方 atk
- **明生项目文档地图** → `references/mingsheng-project-docs.md` — SSOT 设计文档位置（V5.1/动画指导/台词库）、S1-backlog、文档状态标记/螺旋约定、gap 分析法（🟢已具备 vs 🔴真空白）、待拍板决策（告示者变身器 vs 独立战斗体）
- **官方机制速查+Lua验证** → `references/official-mechanisms-lua-check.md` — ms_setmoonphase 官方已监听(PushEvent即生效)、查理免疫=grue:SetResistance(1)(免疫一次)、grue:AddImmunity、luaparser 语法批量验证、speech 脚本编辑坑、GLOBAL 配置跨文件传递(prefab无GLOBAL变量)
- **数值配置化（TUNING 四档）** → `references/dst-tuning-config.md` — 四档常量表+configuration_options 模式、prefab 无 GLOBAL 变量（strict 坑）、modmain 顶部初始化顺序、配方成本系数收敛
- **脚本编辑 Lua 的坑** → `references/lua-edit-pitfalls.md` — 批量替换吞行尾逗号、插入块插到表外（锚点含 `{`）、重复 key 覆盖、luaparser 语法验证（含对照法定位）
- **官方机制速查** → `references/dst-vanilla-mechanics.md` — ms_setmoonphase 官方已监听（字段 new/full）、grue SetResistance/AddImmunity（查理免疫"免疫一次"语义）、speech 状态台词字段可自行添加、respawnfromghost 复活标准路径、配方材料 prefab 名
- **官方系统机制速查** → `references/dst-systems-quirks.md` — grue免疫查理(SetResistance=挡一次/AddImmunity=常驻)、ms_setmoonphase官方监听已存在、speech台词GetString回退、ImageButton无SetTint、externalabsorbmodifiers防御、配方材料prefab名、patch误匹配教训
- **DST 系统 API 速查** → `references/dst-systems-api.md` — SetTint 只有 Image 有（ImageButton 用 .image:SetTint）、ms_setmoonphase 官方 clock 已监听、speech 挂载 + ANNOUNCE 字段可加（GetString 回退）、dapperness 单位是 per-second、externalabsorbmodifiers 防御、damagemultiplier、配方材料 prefab 名（opalpreciousgem/dragon_scales/toadstool_cap/tentaclespots）、相似 PostInit 块批量 patch 吞块的坑
- **UI Widget 坑** → `references/ui-widget-pitfalls.md` — SetTint 只有 Image 有；ImageButton 要 `self.image:SetTint`，否则 "attempt to call method 'SetTint' (a nil value)"

## Replica Component Pattern

## Replica Component Pattern

### File Structure
```
scripts/components/
  xxx_component.lua              -- Server: data + CRUD + SyncToReplica
  xxx_component_replica.lua      -- Client: net_string + cached_data + dirty
```

### Must Register
```lua
AddReplicableComponent("xxx_component")  -- omit _replica suffix
```

### ⚠️ Cores Traps
- `net_*` vars only in replica or common_postinit, NOT in server component constructor
- OnLoad → manual SyncToReplica()
- Float comparison: use 0.1 tolerance, never `==`
- Shard naming: `"surface"`/`"cave"` uniformly, never `"world"`

## ModRPC — 完整 Battle-Tested 示例

### 📌 用户偏好：优先参考其他 mod 的现成实现

不要自己发明 RPC/net_bool 模式。去 `mods/workshop-*` 里搜 `AddModRPCHandler` 找现成的已工作代码做模板。已验证的参考mod：
- `workshop-1430350339` (bronya/布洛妮娅) — 按钮点击发RPC给服务端学技能
- `workshop-2188103687` (ShowMe) — 客户端通知服务端开关某些功能

### 示例1: bronya — 按钮点击 → 服务端执行 (workshop-1430350339)

**widget 中客户端发送：**
```lua
-- scripts/widgets/bronya_skill.lua
local function fn()
    SendModRPCToServer(MOD_RPC["bronya"]["chooseskill"], self.id)
end
self.avatar:SetOnClick(fn)
```

**modmain 或独立文件注册服务端 handler：**
```lua
-- scripts/widgets/bronya_skill.lua (可以直接放在widget文件底部!)
AddModRPCHandler("bronya", "chooseskill", function(inst, id)
    if inst.components.bronyaskill then
        local item = id % 10
        local pos = (id - item) / 10
        inst.components.bronyaskill:LearnSkill(pos, item)
    end
end)
```

**清理按钮（无参数RPC）：**
```lua
-- scripts/widgets/bronya_ui.lua
AddModRPCHandler("bronya", "cleanskill", function(inst)
    if inst.components.bronyaskill then
        inst.components.bronyaskill:ClearSkill()
    end
end)

-- 客户端发送
local function fn()
    SendModRPCToServer(MOD_RPC["bronya"]["cleanskill"])
end
self.reset = self:AddChild(ImageButton(...))
self.reset:SetOnClick(fn)
```

### 示例2: ShowMe — 客户端通知 + 服务端处理 + net_string 回应 (workshop-2188103687)

**服务端注册：**
```lua
-- modmain.lua
AddModRPCHandler("ShowMe", "AOS", function(inst)
    inst.has_AlwaysOnStatus = true
end)

AddModRPCHandler("ShowMe", "Estimate", function(inst)
    inst.should_Estimate_Stale = true
end)
```

**带参数的 RPC（服务端处理 + 通过 net_string 回传结果）：**
```lua
-- 服务端注册
AddModRPCHandler("ShowMeSHint", "Hint", function(player, guid, item)
    if player.player_classified == nil then return end
    if item ~= nil and item.components ~= nil then
        local s = GetTestString(item, player)
        if s ~= "" then
            player.player_classified.net_showme_hint2:set(guid..";"..s)
        end
    end
end)

-- 客户端发送
SendModRPCToServer(MOD_RPC.ShowMeSHint.Hint, inst.GUID, inst)

-- 客户端监听 net_string 回应
AddPrefabPostInit("player_classified", function(inst)
    inst.net_showme_hint2 = GLOBAL.net_string(inst.GUID, "showme_hintbua.", "showme_hint_dirty2")
    if CLIENT_SIDE then
        inst:ListenForEvent("showme_hint_dirty2", function(inst)
            inst.showme_hint2 = inst.net_showme_hint2:value()
        end)
    end
end)
```

### 参数签名速查

| Direction | Register | Send |
|-----------|----------|------|
| Client→Server | `AddModRPCHandler(ns, name, fn(player, ...))` | `SendModRPCToServer(MOD_RPC[ns][name], ...)` |
| Server→Client | `AddClientModRPCHandler(ns, name, fn(data))` | `SendModRPCToClient(MOD_RPC[ns][name], player_entity, ...)` |

### Traps
- **No SendModRPCToClient in buffered action context** (assertion fails). Use net_bool on character instead.
- **AddModRPCHandler callback runs on server** — TheFrontEnd is nil. Always use SendModRPCToClient.
- **Second arg to SendModRPCToClient must be player entity**, not player.userid
- **No nested tables** — JSON encode/decode
- **MOD_RPC 表是 DST 自动生成的**，格式为 `MOD_RPC["namespace"]["rpckey"]` 或 `MOD_RPC.namespace.rpckey`，两种语法都可用
- **AddModRPCHandler 可以写在任何位置**（不一定要在 modmain.lua），bronya 的例子中 handler 直接写在 widget 文件底部
- **客户端发送前确保 MOD_RPC 表已加载**（一般在 widget 的 SetOnClick 回调里发送，此时游戏已完全加载）
- **AddModRPCHandler 第一个参数自动是发送RPC的玩家实体**，不需要额外传 player 参数

### ⚠️ 踩坑：动作（Action handler）里不能直接 SendModRPCToServer

`SendModRPCToServer` 必须在**客机上下文**（widget按钮点击、screen的OnControl）中调用。在服务端动作handler（`AddAction` 的fn回调）中调用会报：

```
Invalid RPC sender: expected player, got userid
```

**原因**：动作在服务端执行，sender是服务端进程ID，不是玩家实体。RPC系统要求sender必须是玩家。

**结论**：不要试图在服务端动作里用 `SendModRPCToServer` 包裹 `net_bool:set()` 作为"绝缘层"——这条路不通。

### 服务端→客机弹界面的通信模式

DST中服务端动作→客机弹UI有三种模式：

#### 模式A：net_bool（当前明生在用）
服务端 `doer.mingsheng_openteleport:set(true)` → net_bool同步到客机 → 客机监听 `_dirty` 事件弹界面。

```lua
-- 角色prefab common_postinit
inst.mingsheng_openteleport = net_bool(inst.GUID, "mingsheng_openteleport", "mingsheng_openteleport_dirty")
inst:ListenForEvent("mingsheng_openteleport_dirty", function()
    if not inst.mingsheng_openteleport:value() then return end
    if not TheFrontEnd then
        inst.mingsheng_openteleport:set_local(false)
        return
    end
    TheFrontEnd:PushScreen(screen(inst))
    inst.mingsheng_openteleport:set_local(false)
end)
```

#### 模式B：net_event（官方做法，推荐）
DST原版弹制作栏用的就是 `net_event:push()`。比net_bool更干净——语义是"触发一次"，不是"设置状态"。

**官方builder链路**：
```
服务端 builder.lua 
  → replica.builder:OpenCraftingMenu()
    → classified.opencraftingmenuevent:push()   -- net_event!
      → 客机 player_classified 监听 "builder.opencraftingmenu"
        → player.HUD:OpenCrafting()
```

**在角色prefab上用net_event**：
```lua
-- 角色prefab common_postinit
inst.mingsheng_openteleport_event = net_event(inst.GUID, "mingsheng_openteleport_event")
inst:ListenForEvent("mingsheng_openteleport_event", function()
    if not TheFrontEnd then return end
    local ok, screen = pcall(require, "screens/mingsheng_teleportscreen")
    if ok and screen then
        TheFrontEnd:PushScreen(screen(inst))
    end
end)
```

服务端动作里触发：
```lua
if TheWorld.ismastersim then
    inst.mingsheng_openteleport_event:push()
end
```

#### 模式C：双路径（net_bool + PushEvent，Listen Server备用）
见下方 "net_bool UI Toggle" 章节的 Dual Path 方案。

#### 模式对比

| 模式 | 同步方式 | 适用场景 | 可靠度 |
|------|---------|---------|--------|
| net_bool:set | 网络同步 | 主机+专用服务器 | 高（原版验证） |
| net_event:push | 网络同步 | 主机+专用服务器 | 更高（官方在用） |
| PushEvent | 本地事件 | Listen Server备用 | 本地可靠，不跨网络 |

详见 `references/dst-netbool-rpc-insulation-pattern.md`

## ImageButton Focus/Scale Guide

### ⚠️ Fatal: OnGainFocus → SelectEntry stack overflow

```lua
-- CRASH: OnGainFocus → SelectEntry → Unselect → focus rebalance → OnGainFocus again → infinite loop
entry.OnGainFocus = function(self2)
    self:SelectEntry(self2.index)  -- overflow!
end
```

**Root cause**: Unselect triggers focus rebalance which re-enters OnGainFocus.

**✅ Safe**: Only set `self.selected = self2.index` in OnGainFocus, never call SelectEntry/Unselect.

### Manual Scale Control

```lua
entry.scale_on_focus = false
entry.ignore_standard_scaling = true
entry:SetScale(0.42, 0.39, 1)

entry.OnGainFocus = function(self2)
    self2:SetScale(0.45, 0.42, 1)
    self2.text:SetColour(1, 1, 1, 1)
    if self.selected ~= self2.index then self.selected = self2.index end
end
entry.OnLoseFocus = function(self2)
    self2:SetScale(0.42, 0.39, 1)
    self2.text:SetColour(1, 1, 1, 1)
end
```

### Text Color Turns Black on Focus

ImageButton's `textfocuscolour` defaults to black. Override in OnGainFocus:
`self2.text:SetColour(1, 1, 1, 1)` — explicit call in focus handler is most reliable.

### SetMouseConsumes Doesn't Exist

Neither Image nor Widget has this method. Prevent bg click-through with coordinate check in OnClick.

### ImageButton highlight atlas mismatch

`ImageButton(atlas, normal, over, down, disabled, selected)` — the `selected` (highlight) texture must be in the **same atlas** as `normal`. If you have the highlight in a separate `.tex`+`.xml` file, passing its region name will produce:

```
WARNING! Could not find region 'xxx.tex' from atlas 'other.xml'.
```

**Fix options:**
1. **Merge atlases**: Use a tool to combine both textures into one `.tex`+`.xml` atlas
2. **Skip highlight**: Omit the last 3-4 args (pass just atlas + normal), handle visual feedback via `OnGainFocus`/`OnLoseFocus` scale/text color changes instead
3. **Custom widget**: Use `Image` + `Text` inside a `Widget` and handle focus/click manually

For option 2 (most practical for modders without atlas tools):
```lua
local entry = self.root:AddChild(ImageButton(
    "images/teleport/xxx_slot.xml",    -- atlas
    "xxx_slot.tex"                      -- normal texture
    -- no highlight — use scale/color in OnGainFocus instead
))
entry.scale_on_focus = false
entry.ignore_standard_scaling = true
entry.OnGainFocus = function(self2)
    self2:SetScale(0.45, 0.42, 1)
    self2.text:SetColour(1, 1, 1, 1)
end
entry.OnLoseFocus = function(self2)
    self2:SetScale(0.42, 0.39, 1)
    self2.text:SetColour(1, 1, 1, 1)
end
```

## Pure Mouse Drag Sort (AddMoveHandler)

**Design**: No keyboard up/down. Click to select (no teleport), Enter to confirm teleport. Bone handle for reorder. Drag only moves the bone (no data swap mid-drag). On release, perform one swap + full refresh.

**User preference confirmed**: mid-drag text/order flashing is unacceptable. Keep the UI stable during drag, only update on release.

### ⚠️ DST Position API: Inconsistent Return Type (Vector3 vs Multi-Value)

**DST's position functions have an inconsistent return type.** Sometimes they return a Vector3 object (with .x/.y/.z), sometimes they return multiple values (x, y, z). The same function can behave differently depending on context.

**✅ Safe pattern (works for both):**

```lua
-- Safe: treats first return value as either Vector3 object or raw x coordinate
local result = entry:GetWorldPosition()
local y
if type(result) == "table" then
    y = result.y     -- Vector3 object path
else
    _, y = entry:GetWorldPosition()  -- multi-value path
end
y = y or 0
```

**Observed behavior from crash logs:**
- `GetPosition()` → returns Vector3: `(195.00, 53.00, 0.00)` → `.x` works, multi-value unpack gives nil for y
- `GetScreenPosition()` → returns Vector3 in the addon screen context
- `GetWorldPosition()` → returns Vector3 in the addon screen context

**Common crash:** `local _, ey = entry:GetWorldPosition()` → `ey = nil` because it returned a Vector3, not multi-value. Then `math.abs(ey - target_y)` → nil arithmetic.

**Safer single-value extraction (use `.x`/`.y`):**

```lua
local mpos = TheInput:GetScreenPosition()
local my = mpos and mpos.y or 0

local epos = entry:GetWorldPosition()
local ey = epos and epos.y or 0

local hpos = self.drag_handle:GetPosition()
local hx = hpos and hpos.x or 0
local hy = hpos and hpos.y or 0
```

**TL;DR**: Prefer `.x`/`.y` property access with nil guard. Multi-value unpack (`local _, y = ...`) may return nil. Property access works when it's a Vector3, and when it's not, the `.x`/`.y` fall through to nil which is caught by the `or 0` guard.

### Asset Declaration

```lua
Asset("ATLAS", "images/.../xxx.xml"),
Asset("IMAGE", "images/.../xxx.tex"),
```
Missing declaration → `Invalid resource handle` + texture not shown.

### ⚠️ TheInput:AddMouseUpHandler Doesn't Exist

Use `IsMouseDown(MOUSEBUTTON_LEFT)` inside AddMoveHandler callback to detect release.

### ⚠️ SetOnClick Doesn't Support Hold-and-Drag

Must override `OnMouseButton` to intercept press: `if button == MOUSEBUTTON_LEFT and down then self:StartDrag() end`

### Y-axis Slot System

Divide Y range into MAX_TOTAL slots, snap bone to nearest slot.

```
START_Y + (slot-1) * SPACING  → slot Y coordinate
slot = floor((START_Y - target_y) / |SPACING| + 0.5) + 1
```

### StartDrag Flow

1. Gray out all entries (SetTextColour 0.5,0.5,0.5)
2. Record drag start Y (multi-value! `local _, mouse_y = ...`)
3. Register `TheInput:AddMoveHandler` for real-time tracking
4. In handler: check `TheInput:IsMouseDown(MOUSEBUTTON_LEFT)` — if not, EndDrag
5. Calculate slot → snap bone position → record `self.drag_target_slot`
6. **Do NOT swap data mid-drag** — only track target slot

### EndDrag — Perform One Swap on Release

**⚠️ CRITICAL: Use `entries[i].wp`, NOT `waypoints[i]` for order swap.**

`self.waypoints` is re-sorted by order after every swap, so `waypoints[i]` does NOT point to the same logical waypoint across operations. But `entries[i]` is a stable widget array — `entries[i].wp` always points to the correct waypoint regardless of sort order.

```lua
-- ✅ CORRECT: use entries[i].wp for stable reference
local src_entry = self.entries[self.drag_entry_index]
local dst_entry = self.entries[self.drag_target_slot]
if src_entry and src_entry.wp and dst_entry and dst_entry.wp then
    local tmp = src_entry.wp.order
    src_entry.wp.order = dst_entry.wp.order
    dst_entry.wp.order = tmp
    table.sort(self.waypoints, function(a,b)
        return (a.order or 999) < (b.order or 999)
    end)
    self:PopulateEntries(self.waypoints)
end

-- ❌ WRONG: self.waypoints[idx] changes meaning after sort
self.waypoints[self.drag_entry_index].order = self.waypoints[self.drag_target_slot].order  -- bug! waypoints[1] changed!
```

## Order-Based Waypoint Reorder

**Key insight**: swapping array positions causes chaos when slots have no data. Instead, each waypoint carries an `order` field. Drag only swaps order values, then re-sorts the array.

### Waypoint Data Structure

```lua
{
    name = "传送点名称",
    x = 123.0, y = 0.0, z = 456.0,
    order = 1,  -- UI sort key, maintained continuously 1..N
}
```

### CRUD Rules

| Operation | What happens to order |
|-----------|----------------------|
| AddWaypoint | order = max_order_in_list + 1 |
| RemoveWaypoint(index) | Remove at index, then renumber all orders 1..N |
| SwapOrder(idx1, idx2) | Swap order values, re-sort list by order |

### Server Component Example

```lua
-- AddWaypoint auto-assigns order
function AddWaypoint(name, x, y, z, shard)
    local list = self:GetList(shard)
    local max_order = 0
    for _, wp in ipairs(list) do
        if wp.order and wp.order > max_order then max_order = wp.order end
    end
    table.insert(list, { name=name, x=x, y=y, z=z, order = max_order + 1 })
end

-- RemoveWaypoint renumbers
function RemoveWaypoint(index, shard)
    table.sort(list, function(a,b) return (a.order or 999) < (b.order or 999) end)
    table.remove(list, index)
    for i, wp in ipairs(list) do wp.order = i end  -- renumber 1..N
end

-- SwapOrder — used by drag
function SwapOrder(idx1, idx2, shard)
    local list = self:GetList(shard)
    table.sort(list, function(a,b) return (a.order or 999) < (b.order or 999) end)
    if not list[idx1] or not list[idx2] then return end
    list[idx1].order, list[idx2].order = list[idx2].order, list[idx1].order
    for i, wp in ipairs(list) do wp.order = i end
    self:SyncToReplica()
end
```

### PopulateEntries Must Sort by Order

```lua
function MyScreen:PopulateEntries(waypoints)
    table.sort(waypoints, function(a, b)
        return (a.order or 999) < (b.order or 999)
    end)
    -- then fill entries as usual
end
```

### Drag: Swap Order on Release, Not Mid-Drag

**User preference**: mid-drag should not flash/change text. Only swap on release.

**⚠️ CRITICAL**: Use `self.entries[i].wp` for order swap, NOT `self.waypoints[i]`. After sorting, `waypoints[i]` changes meaning — `entries[i].wp` is the stable reference.

```lua
-- Inside AddMoveHandler callback — ONLY track slot, don't swap:
if slot ~= self.drag_entry_index and self.entries[slot] and self.entries[slot].wp then
    self.drag_target_slot = slot  -- just remember where we are
end

-- Inside EndDrag — execute ONE swap:
if self.drag_target_slot and self.drag_target_slot ~= self.drag_entry_index then
    local slot = self.drag_target_slot
    local src_entry = self.entries[self.drag_entry_index]
    local dst_entry = self.entries[slot]
    if src_entry and src_entry.wp and dst_entry and dst_entry.wp then
        local tmp = src_entry.wp.order
        src_entry.wp.order = dst_entry.wp.order
        dst_entry.wp.order = tmp
        table.sort(self.waypoints, function(a,b)
            return (a.order or 999) < (b.order or 999)
        end)
        self:PopulateEntries(self.waypoints)
    end
end
```

### Old Save Compatibility

```lua
function _ensure_orders()
    for _, list in ipairs({self._surface, self._cave}) do
        local has_order = false
        for _, wp in ipairs(list) do
            if wp.order then has_order = true; break end
        end
        if not has_order then
            for i, wp in ipairs(list) do wp.order = i end
        end
        table.sort(list, function(a,b) return a.order < b.order end)
    end
end
```

## PlayerVision / NightVision Guide

### Key Facts
- `playervision` is a **client-only** component. Server code (`TheWorld.ismastersim`) does NOT have `inst.components.playervision`.
- Access via `inst.components.playervision` only on the client side.

### How NightVision Works
```lua
-- simutil.lua: CanEntitySeeInDark
function CanEntitySeeInDark(inst)
    if inst.components.playervision ~= nil then
        return inst.components.playervision:HasNightVision()
    end
    local inventory = inst.replica.inventory
    return inst:HasTag("canseeindark")
        or (inventory ~= nil and inventory:EquipHasTag("nightvision"))
end
```
NightVision comes from either: `playervision:HasNightVision()` (low sanity / forced), `"canseeindark"` tag, or equipped item with `"nightvision"` tag.

### ForceNightVision API
```lua
function PlayerVision:ForceNightVision(force)
    if not self.forcenightvision ~= not force then
        self.forcenightvision = force == true
        if not self.nightvision then
            self:UpdateCCTable()
            self.inst:PushEvent("nightvision", self.forcenightvision)
        end
    end
end
```
⚠️ **Trap**: If `self.nightvision` is already `true` (e.g., from low sanity), `ForceNightVision(true)` does NOTHING — the `if not self.nightvision` guard skips the update.

### Nightmare Amulet Re-equip NightVision Fix

**Bug**: 戴上梦魇护符→san压到0→夜视开。脱掉再戴上→san需要时间重新降到0才触发夜视→夜视不恢复。

**Fix**: 客户端监听 equip/unequip，紫色护符时直接 ForceNightVision。

```lua
if not TheWorld.ismastersim then
    AddPlayerPostInit(function(inst)
        local function OnEquipChanged(data)
            local item = data and data.item
            if item and item.prefab == "purpleamulet" and inst:HasTag("mingsheng") then
                local pv = inst.components.playervision
                if pv then pv:ForceNightVision(true) end
            end
        end
        local function OnUnequipChanged(data)
            local item = data and data.item
            if item and item.prefab == "purpleamulet" and inst:HasTag("mingsheng") then
                local pv = inst.components.playervision
                if pv then pv:ForceNightVision(false) end
            end
        end
        inst:ListenForEvent("equip", OnEquipChanged)
        inst:ListenForEvent("unequip", OnUnequipChanged)
    end)
end
```

**Pattern rules**:
- `inst:HasTag()` at runtime inside callback, NOT in postinit closure — tags may not be ready yet
- `equip`/`unequip` event `data.item` = the item entity; check `data.item.prefab`
- Wrap in `inst:HasTag("mingsheng")` guard to avoid affecting other characters

### 屏蔽疯狂滤镜（明生角色专用）
```lua
if not TheNet:IsDedicated() then
    AddComponentPostInit("playercontroller", function(self, inst)
        if inst ~= GLOBAL.ThePlayer then return end
        local PostProcessor = GLOBAL.PostProcessor
        local PostProcessor_mt = GLOBAL.getmetatable(PostProcessor).__index
        local original_SetColourCubeLerp = PostProcessor_mt.SetColourCubeLerp
        PostProcessor_mt.SetColourCubeLerp = function(self, channel, blend_amount)
            if channel == 1 and GLOBAL.ThePlayer and GLOBAL.ThePlayer:HasTag("mingsheng") then
                blend_amount = 0
            end
            original_SetColourCubeLerp(self, channel, blend_amount)
        end
        PostProcessor:SetDistortionFactor(1)
        PostProcessor_mt.SetDistortionFactor = function() end
        PostProcessor:SetOverlayBlend(0)
        PostProcessor_mt.SetOverlayBlend = function() end
    end)
end
```

## CHARACTER_INGREDIENT 自定义消耗类型 — 坑点

### 关键陷阱：`IsCharacterIngredient` 不能用直接值比较

❌ **错误写法**（不生效）：
```lua
IsCharacterIngredient = function(ingredienttype)
    if ingredienttype == MINGSHENG_HUNGER then  -- 直接比较值，不生效！
```

✅ **正确写法**（必须用字符串查表法）：
```lua
local MY_CHARACTER_INGREDIENT = {
    MINGSHENG_HUNGER = true,  -- key 是字符串 "MINGSHENG_HUNGER"
}
local oldIsCharacterIngredient = GLOBAL.IsCharacterIngredient
if oldIsCharacterIngredient ~= nil then
    GLOBAL.IsCharacterIngredient = function(ingredienttype)
        if ingredienttype and MY_CHARACTER_INGREDIENT[ingredienttype] then
            return true
        end
        return oldIsCharacterIngredient(ingredienttype)
    end
end
```

**原因**：DST 内部 `character_ingredients` 的 type 字段是字符串索引，直接 `==` 比较在某些版本/环境下不匹配。用表查（`MY_TABLE[ingredienttype]`）强制字符串匹配，兼容性更好。

### 完整写法（放 modmain.lua）

```lua
-- 1. 定义新类型
CHARACTER_INGREDIENT.MINGSHENG_HUNGER = "MINGSHENG_HUNGER"
STRINGS.NAMES["MINGSHENG_HUNGER"] = STRINGS.NAMES.HUNGER

-- 2. 注册 IsCharacterIngredient（必须用表查法）
local MY_CHARACTER_INGREDIENT = { MINGSHENG_HUNGER = true }
local oldIsCharacterIngredient = GLOBAL.IsCharacterIngredient
if oldIsCharacterIngredient ~= nil then
    GLOBAL.IsCharacterIngredient = function(ingredienttype)
        if ingredienttype and MY_CHARACTER_INGREDIENT[ingredienttype] then
            return true
        end
        return oldIsCharacterIngredient(ingredienttype)
    end
end

-- 3. 在角色 prefab 的 master_postinit 里 hook builder（参考霍霍mod写法）
-- 必须放在角色预制体（如 mingsheng.lua）里，不能用 AddComponentPostInit
```

### 为什么 `==` 不生效
- `CHARACTER_INGREDIENT.XXX` 存的是 Lua 字符串，配方里 `ingredient.type` 也是传这个字符串
- 但 DST 的 `Ingredient()` 构造函数或某些版本的 `AllRecipes` 可能会把 type 封装成 userdata 或做 intern 处理
- 用表查绕过 intern 问题

## 配方 Ingredient 跨MOD物品贴图

当配方引用**其他MOD的物品**作为材料时，`Ingredient` 后面必须跟 atlas 和 image 参数，否则显示空白/乱码。

```lua
Ingredient(prefab, count, atlas_path, image_name)
```

示例（引用雪露mod的 kitana）：
```lua
Ingredient('setsuro_kitana', 2, 'images/inventoryimages/setsuro_kitana.xml', 'setsuro_kitana.tex')
```

注意路径是相对于 mod 目录的，用其他mod的贴图时路径指向那个mod的资源。如果两个mod在同级目录（workshop-content），用相对路径即可。

## Crash / Error Reference

### 1. SetMouseConsumes doesn't exist
```
attempt to call method 'SetMouseConsumes' (a nil value)
```

### 2. DST position API inconsistency (most common crash)
```
attempt to perform arithmetic on local 'ey' (a nil value)
```
Root cause: DST position functions (`GetPosition`, `GetWorldPosition`, `GetScreenPosition`) behave inconsistently — sometimes returning Vector3 objects (`.x`/`.y`), sometimes multi-values. Multi-value unpack `local _, y = ...` will be nil when the function returns a Vector3.

**Fix**: Use property access with nil guard:
```lua
local epos = entry:GetWorldPosition()
local ey = epos and epos.y or 0
```

### 3. OnGainFocus → SelectEntry stack overflow
```
scripts/widgets/text.lua:86: stack overflow
```
Only set `self.selected = self2.index`, never call SelectEntry/Unselect.

### 4. AddMouseUpHandler doesn't exist
Use `IsMouseDown(MOUSEBUTTON_LEFT)` inside AddMoveHandler.

### 5. ImageButton — `IsFocused()` doesn't exist

```lua
-- ❌ CRASH: attempt to call method 'IsFocused' (a nil value)
if not self:IsFocused() then
    entry:SetFocus()
end

-- ✅ CORRECT: use IsSelected() or HasFocus()
if not entry:IsSelected() then
    entry:SetFocus()
end
```

### 6. Escape character corruption from patch tool
patch tool writes `\"` → Lua syntax error. Manually inspect after patch.

### 7. ForceNightVision on server side
```
attempt to call method 'ForceNightVision' (a nil value)
```
Root cause: `playervision` is a client-only component. Server code must NOT call `inst.components.playervision`. Wrap in `if not TheWorld.ismastersim then ... end`.

### 8. Minion/仆从被攻击不受击（直接消失）

Root cause: SG 的 `events` 里 `EventHandler("attacked", ...)` 跳到了 `"disappear"` 状态而不是 `"hit"`。被打直接消失看起来像"没受击判定"。

Fix: 改为跳 `"hit"` 状态：
```lua
EventHandler("attacked", function(inst, data)
    if not (inst.components.health:IsDead() or inst.components.health:IsInvincible()) then
        inst.sg:GoToState("hit", data ~= nil and data.attacker or nil)
    end
end),
```

### 9. 角色死亡后分身突破数量上限

Root cause: `CanSummonMoreShadows`/`CountIllusions` 用 `leader.followers` 计数。角色死亡时 follower 关系断开，但分身实体仍然存活。重新召唤时 leader.followers 为空 → 不触发上限检查 → 旧分身 + 新分身同时存在。

**方案A（推荐）**: 设 `keepdeadleader = true` — 死亡不断开关系，follower 计数正常。
```lua
inst:AddComponent("follower")
inst.components.follower.keepdeadleader = true
```

**方案B（兜底）**: 死亡时强制移除所有分身。
```lua
AddPlayerPostInit(function(inst)
    if TheWorld.ismastersim then
        inst:ListenForEvent("death", function()
            if not inst:IsValid() or not inst:HasTag("mingsheng") or not inst.components.leader then return end
            local to_remove = {}
            for follower, _ in pairs(inst.components.leader.followers) do
                if follower:IsValid() and (follower:HasTag("shadow_mingsheng") or follower:HasTag("illusion_mingsheng")) then
                    table.insert(to_remove, follower)
                end
            end
            for _, f in ipairs(to_remove) do
                if f:IsValid() then f:Remove() end
            end
        end)
    end
end)
```
- Use `inst:HasTag("mingsheng")` at runtime inside callback, NOT at postinit time (tag may not be ready)
- DST `foreach` on `leader.followers` while removing is unsafe → collect into array first, then remove

### 10. 生存告示催熟不巨大化修复

**Bug**：`mingsheng_shengcun.lua` 的 `BoostCrop` 用 `SetStage()` 直接跳阶段，跳过了 growable 的 `pregrowfn`（stress checkpoint），导致作物永远无法巨大化。

**修复**：手动触发当前阶段的 `pregrowfn`，在进入 final stage 时设 `force_oversized = true`。

```lua
if inst.components.growable then
    local stages = inst.components.growable.stages or {}
    local current = inst.components.growable.stage or 1
    if current < #stages then
        local stage_data = stages[current]
        if stage_data and stage_data.pregrowfn then
            stage_data.pregrowfn(inst)  -- 手动触发 stress checkpoint
        end
        inst.components.growable:SetStage(current + 1)
    end
    local new_current = inst.components.growable.stage or 1
    if new_current == #stages then
        inst.force_oversized = true  -- 原版farm_plants.lua:518读到则强制巨大化
    end
    return true
end
```

### 11. 分身自然消失产生杂音（音效在实体销毁时播放）

### 12. Builder/Hunger Ingredient — HasCharacterIngredient 返回值陷阱

`HasCharacterIngredient` 必须返回 **两个值**：`has_ingredient(bool), current_amount(number)`。

```lua
-- ❌ WRONG: return 下面换行导致只返回一个值，freebuildmode 下 0 是 falsy
return
    (self.freebuildmode and 0) or math.ceil(self.inst.components.hunger.current) >= ingredient.amount,
    self.inst.components.hunger.current

-- ✅ CORRECT: 先算再返回
local current = math.ceil(self.inst.components.hunger.current)
local has = self.freebuildmode or current >= ingredient.amount
return has, current
```

### 13. Prefab 列表引用了不存在的 prefab

```lua
-- ❌ 会导致 `Can't find prefab` 错误
local prefabs = { "shadow_shield", ... }

-- ✅ 确认 prefab 存在再添加
local prefabs = { "shadow_despawn", ... }
```

### 14. strict.lua 函数声明顺序

Lua strict mode 要求 **所有 `local function X()` 定义必须在任何调用之前**，即使调用在闭包回调里延迟执行也不行。加载时 strict 扫描会报 `variable 'X' is not declared`。

```lua
-- ❌ BAD: PlaySmokeEffects 在 StartFollowerTimer 之后定义，但 StartFollowerTimer 的闭包里调用了它
-- ✅ GOOD: 把所有被调用的函数定义放在调用者之前
```

### 15. ImageButton 构造传 nil 导致 Atlas 空字符串查找

```lua
-- ImageButton(atlas, normal, hover, disabled, down, selected)
-- 中间的 hover/disabled/down 传 nil 时，DST 内部会试图用空字符串查找默认贴图
-- 日志：Looking for default texture '' from atlas '...'
-- 不影响功能，但日志冗余
ImageButton("atlas.xml", "normal.tex", nil, nil, nil, "selected.tex")
```

## Builder/Hunger Ingredient — 装迷糊抵消逻辑（2026-06-04）

装迷糊（mingsheng_zhuangmihu）是一个带耐久（4620秒=77分钟）的头部饰品，提供：
- 保暖（绝缘Large级别，耐久0时不保暖）
- 理智恢复+20/min（耐久0时不恢复）
- **制作消耗抵消**：30%概率退回收割hunger/sanity/health消耗

### 实现位置
`mingsheng.lua` 的 `master_postinit` → `RemoveIngredients` hook 末尾。

```lua
-- 在RemoveIngredients末尾：
if TheWorld.ismastersim and inst:HasTag("mingsheng") then
    local head = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    if head and head.prefab == "mingsheng_zhuangmihu" and head.components.fueled and head.components.fueled.currentfuel > 0 then
        if math.random() <= 0.3 then  -- 30%概率抵消
            -- 退回所有character_ingredients消耗
            -- 消耗装迷糊10秒耐久
        end
    end
end
```

## 生存告示催熟巨大化（2026-06-04）

`mingsheng_shengcun.lua` 的 `BoostCrop` 原本用 `SetStage(current+1)` 直接跳阶段，**跳过了stress checkpoint**（pregrowfn不执行）。

### 修复
1. 先手动调用 `stage_data.pregrowfn(inst)` 再 `SetStage`
2. 进入final stage(full)时设 `inst.force_oversized = true`

### 巨化判定
```
farm_plants.lua line 518:
inst.is_oversized = inst.force_oversized or (not inst.no_oversized and ...stress == NONE)
```
- stress_points ≤ 1 → NONE → 巨大化
- 催熟时设置 force_oversized = true 可绕过stress检查

三种可行的实现模式，**推荐模式三（雪露/设乐模式）**。

#### 模式一：Prefab 实例级别 hook（霍霍模式）

在角色预制体的 `master_postinit` 里直接 hook 玩家实例的 builder 组件。

**优点**：只对本角色生效，不污染全局。
**缺点**：必须在 prefab 里写，代码分散。

```lua
-- 在 mingsheng.lua 的 master_postinit 中
-- Step 1: modmain.lua 中注册 IsCharacterIngredient
local oldIsCharacterIngredient = IsCharacterIngredient
IsCharacterIngredient = function(ingredienttype)
    if ingredienttype == "MINGSHENG_HUNGER" then
        return true
    end
    if oldIsCharacterIngredient then
        return oldIsCharacterIngredient(ingredienttype)
    end
end

-- Step 2: 在 master_postinit 中 hook builder
local old_HasCharacterIngredient = inst.components.builder.HasCharacterIngredient
inst.components.builder.HasCharacterIngredient = function(self, ingredient, ...)
    if ingredient.type == CHARACTER_INGREDIENT.MINGSHENG_HUNGER then
        if self.inst.components.hunger ~= nil then
            return (self.freebuildmode and 0) or
                math.ceil(self.inst.components.hunger.current) >= ingredient.amount,
                self.inst.components.hunger.current
        end
    end
    return old_HasCharacterIngredient(self, ingredient, ...)
end

local old_RemoveIngredients = inst.components.builder.RemoveIngredients
inst.components.builder.RemoveIngredients = function(self, ingredients, recname)
    local recipe = AllRecipes[recname]
    if recipe then
        for k, v in pairs(recipe.character_ingredients) do
            if v.type == CHARACTER_INGREDIENT.MINGSHENG_HUNGER then
                local current = math.ceil(self.inst.components.hunger.current)
                if current >= v.amount then
                    inst.components.hunger:DoDelta(-v.amount, nil, true)
                end
            end
        end
    end
    return old_RemoveIngredients(self, ingredients, recname)
end
```

#### 模式二：AddComponentPostInit 全局 hook（早期尝试，不推荐）

在 modmain 中用 `AddComponentPostInit("builder", ...)` 全局 hook builder 组件。
⚠️ **问题**：可能与其他 builder 修改冲突，且 prefab 级别 hook 更安全。

#### 模式三（推荐）：服务端+客户端一个函数（雪露/设乐模式）

参考 3660903728（设乐雪露）写法，`HasCharacterIngredient` 同时处理服务端和客户端：

```lua
CHARACTER_INGREDIENT.MY_TYPE = "my_type"

local oldIsCharacterIngredient = IsCharacterIngredient
IsCharacterIngredient = function(ingredienttype)
    if ingredienttype == "my_type" then return true end
    if oldIsCharacterIngredient then return oldIsCharacterIngredient(ingredienttype) end
end

AddComponentPostInit("builder", function(self)
    local old_HasCharacterIngredient = self.HasCharacterIngredient
    self.HasCharacterIngredient = function(self, ingredient, ...)
        if ingredient.type == CHARACTER_INGREDIENT.MY_TYPE then
            local amount = ingredient.amount
            local current = 0
            -- Try server component first, then client replica
            if self.inst.components.myresource ~= nil then
                current = math.ceil(self.inst.components.myresource.current)
            elseif self.inst.replica.myresource ~= nil and self.inst.replica.myresource.classified ~= nil then
                current = math.ceil(self.inst.replica.myresource.classified.currentvalue:value())
            end
            return current >= amount, current  -- NO freebuildmode magic
        end
        return old_HasCharacterIngredient(self, ingredient, ...)
    end

    local old_RemoveIngredients = self.RemoveIngredients
    self.RemoveIngredients = function(self, ingredients, recname)
        if self.freebuildmode then
            return old_RemoveIngredients(self, ingredients, recname)
        end
        local recipe = AllRecipes[recname]
        if recipe then
            for k, v in pairs(recipe.character_ingredients) do
                if v.type == CHARACTER_INGREDIENT.MY_TYPE then
                    if self.inst.components.myresource then
                        self.inst.components.myresource:DoDelta(-v.amount)
                    end
                end
            end
        end
        return old_RemoveIngredients(self, ingredients, recname)
    end
end)
```

**关键规则**：
1. **不 hook builder_replica** — 客户端自动从服务端同步显示结果
2. **IsCharacterIngredient 无条件覆盖** — 不要用 `if oldIsCharacterIngredient ~= nil then` 包裹
3. **RemoveIngredients 的 freebuildmode** — 雪露模式在顶部 return early
4. **HasCharacterIngredient 返回两个值** — `return has_ingredient(bool), current_amount(number)`
5. **服务端和客户端两者选一**，不要同时 hook 两个端

#### 调试检查清单

- [ ] IsCharacterIngredient 是否正确返回 true？
- [ ] HasCharacterIngredient 是否被调用？
- [ ] HasCharacterIngredient 是否返回了两个值？
- [ ] RemoveIngredients 是否被执行了？
- [ ] 客户端 replica 是否被重复 hook？

### 16. Follower: keepdeadleader 防止死亡时关系断开

**模式**：角色死亡时 follower 关系默认断开（`keepdeadleader = false`）。如果你希望在主人死后仆从继续跟随（复活后数量上限计数也正常），设置 `keepdeadleader = true`。

阿比盖尔、麦斯威尔暗影仆从、WX-78 守卫等官方 prefab 都在用：

```lua
inst:AddComponent("follower")
inst.components.follower.keepdeadleader = true  -- 主人死后不断开关系
```

**为什么重要**：召唤上限检查（如 `CanSummonMoreShadows`）依赖 `leader.followers` 计数。死亡后关系断开 → `leader.followers` 清空 → 复活后重新召唤不触上限 → 突破上限。`keepdeadleader = true` 从根源解决这个问题。

**注意**：`keepdeadleader = true` 只是保持 follower 关系，不会阻止分身到期自然消失（180秒计时器到期移除）。

## Temperature: Lock → Heat/Cold Resistance Alternative

When temperature lock causes noise/visual artifacts (wind sounds, overlay persistence), replace with **WX-78 style heat/cold resistance** instead.

### WX-78 Circuit Pattern

```lua
-- Raise/lower overheat/freeze thresholds
temp.mintemp = -100  -- won't freeze
temp.maxtemp = 100   -- won't overheat
temp.inherentsummerinsulation = TUNING.INSULATION_MED_LARGE or 120
temp.inherentwinterinsulation = TUNING.INSULATION_MED_LARGE or 120
```

Save original values on a timer task, restore after DURATION seconds:
```lua
-- Save
doer._zaoyu_old_mintemp = temp.mintemp
doer._zaoyu_old_maxtemp = temp.maxtemp
doer._zaoyu_old_summerins = temp.inherentsummerinsulation
doer._zaoyu_old_winterins = temp.inherentwinterinsulation

-- Apply
temp.mintemp = -100
temp.maxtemp = 100

-- Restore after duration
doer:DoTaskInTime(DURATION, function()
    if doer:IsValid() then
        local temp = doer.components.temperature
        if doer._zaoyu_old_mintemp then temp.mintemp = doer._zaoyu_old_mintemp end
        if doer._zaoyu_old_maxtemp then temp.maxtemp = doer._zaoyu_old_maxtemp end
        if doer._zaoyu_old_summerins then temp.inherentsummerinsulation = doer._zaoyu_old_summerins end
        if doer._zaoyu_old_winterins then temp.inherentwinterinsulation = doer._zaoyu_old_winterins end
        -- nil out saved values
    end
end)
```

### Why Not Temperature Lock

`temperaturelock` locks temp to a fixed value (e.g. 24°C). After the lock expires, the DST ambient temperature system may:
- Keep playing wind/hot/cold environmental sounds
- Keep displaying heat wave / freeze overlays
- Take time to "catch up" to actual ambient temp

Heat/cold resistance avoids this entirely by preventing the temperature from reaching dangerous thresholds in the first place.

### ⚠️ Temperature Lock Wind Sound Bug

If you DO use temperature lock (locking to a fixed temp like 24°C for 30s), **do NOT use `DoPeriodicTask` to repeatedly set the temperature every tick**.

```lua
-- ❌ BAD: every 0.5s, force-set temperature → DST wind/hot/cold sound system fires repeatedly
if not self.task then
    self.task = self.inst:DoPeriodicTask(0.5, function()
        if self.locked and self.inst.components.temperature then
            self.inst.components.temperature:SetTemperature(self.target_temp)
            self.elapsed_time = self.elapsed_time + 0.5
        end
    end, 0)
end

-- ✅ GOOD: set temperature ONCE at lock start
-- DST's natural insulation handles keeping it there for 30s
if self.inst.components.temperature then
    self.inst.components.temperature:SetTemperature(self.target_temp)
end
-- No periodic task needed!
```

**Root cause**: DST's ambient sound system detects temperature crossing thresholds (overheat/freeze) and plays environmental wind/burning/freezing sounds. When a periodic task repeatedly sets the temperature to a middle value, the sound system keeps "catching up" and replaying transition sounds. Setting the temperature once avoids this entirely.

## Teleport UI via net_bool — Singleplayer + Multiplayer Pattern

See `references/dst-netbool-open-ui-pattern.md` for the complete reference.

## Cross-Shard Teleport UI (Surface ↔ Caves)

See `references/dst-cross-shard-teleport-pattern.md` for the complete reference.

### ⚠️ Key Insight: Caves are a separate server process

DST caves = Secondary Shard = **independent server process** with no TheFrontEnd.
- Cannot push UI screens from cave Action handlers
- Must use `SendModRPCToShard` + `AddShardModRPCHandler` to notify the surface/server master shard to pop UI
- Player's `userid` (OU_xxx string), not entity GUID, is the cross-shard identifier
- Movement across shards requires a cave entrance portal entity, not Physics:Teleport

### Architecture flow

```
Player right-clicks shenxing in caves
  → Cave Action handler (no TheFrontEnd)
  → shard == "cave" check
  → SendModRPCToShard(rpc_id, 0, player_id)
  → Surface master receives RPC
  → FindEntities to locate player on surface
  → net_bool:set(true) + PushEvent → UI pops on surface client
  → Screen shows both surface + cave waypoints (prefixed "[洞穴]")
  → User selects cave waypoint → RPC → CONFIRM_TELEPORT(index, "cave")
  → Surface server finds nearest cave entrance → teleports player there → enters cave
```

### UI shows both shards' waypoints

When popping the teleport screen, read both `surface` and `cave` waypoints from the storage component, merging into one list with cave points labeled.

当服务端通知客机弹传送界面时，标准模式是 net_bool + `mingsheng_openteleport_dirty` 事件监听。

### 架构

```
服务端 PushEvent → modmain action handler → doer.mingsheng_openteleport:set(true)
                                                          ↓
                                              dirty事件触发 → 角色prefab监听
                                                          ↓
                                              ismastersim? → 单人:直接弹 / 客机:弹
```

### ⚠️ 关键踩坑: set_local(false) 替代 set(false)

```lua
-- ❌ BAD: set(false) 触发不必要的网络同步
doer.mingsheng_openteleport:set_local(false)
            doer.mingsheng_openteleport:set(true)

-- ✅ GOOD: set_local(false) 只在本地改值，不触发网络
doer.mingsheng_openteleport:set_local(false)
doer.mingsheng_openteleport:set(true)
```

`set(false)` 会触发一次网络同步（false→true→false→true），浪费带宽且可能造成时序问题。`set_local(false)` 只改本地值，`set(true)` 通过网络同步出去。

### ⚠️ 双路径触发: PushEvent + net_bool

对于 Listen Server（肉身开服/主机联机）模式，单一 net_bool 路径可能因网络同步延迟或分片切换不可靠。**加 PushEvent 作为备用路径**：

```lua
-- modmain 中双触发
if doer.mingsheng_openteleport then
    doer.mingsheng_openteleport:set_local(false)
    doer.mingsheng_openteleport:set(true)
    doer:PushEvent("mingsheng_openteleport")  -- 本地备用路径
end
```

```lua
-- 角色 prefab common_postinit 中双监听
-- 方式1: PushEvent 路径
inst:ListenForEvent("mingsheng_openteleport", function()
    if not TheFrontEnd then return end
    local ok, screen = pcall(require, "screens/mingsheng_teleportscreen")
    if ok and screen then
        TheFrontEnd:PushScreen(screen(inst))
    end
end)

-- 方式2: net_bool 路径
inst.mingsheng_openteleport = net_bool(inst.GUID, "mingsheng_openteleport", "mingsheng_openteleport_dirty")
inst:ListenForEvent("mingsheng_openteleport_dirty", function()
    if not inst.mingsheng_openteleport:value() then return end
    if not TheFrontEnd then
        inst.mingsheng_openteleport:set_local(false)
        return
    end
    local ok, screen = pcall(require, "screens/mingsheng_teleportscreen")
    if ok and screen then
        TheFrontEnd:PushScreen(screen(inst))
    end
    inst.mingsheng_openteleport:set_local(false)
end)
```

### ⚠️ 不要用 ismastersim 过滤（单人模式陷阱）

```lua
-- ❌ BAD: 单人模式下 ismastersim=true，整个监听被跳过
inst:ListenForEvent("mingsheng_openteleport_dirty", function()
    if TheWorld.ismastersim then return end  -- ← 单人模式跳过!
```

改为直接检查 `TheFrontEnd` 是否存在（Dedicated Server 下才是 nil，Listen Server/单人都有 TheFrontEnd）：

### 单人模式直接传送（DoTeleport）

界面的 `DoTeleport` 已经处理了单人模式分支（`TheWorld.ismastersim` 时直接在客户端消耗物品+传送，不走RPC），不需要额外修改。

### 界面读取数据 — 分片参数陷阱

```lua
-- ❌ BAD: 无 shard 参数 — 在洞穴打开界面会返回地表数据
self.waypoints = storage:GetWaypoints()

-- ✅ GOOD: 传入当前分片参数
local shard = TheWorld:HasTag("cave") and "cave" or "surface"
self.waypoints = storage:GetWaypoints(shard)
```

### Debug Print 规范

当需要给开发者（boss/第三方）发日志调试时，使用统一前缀：

```lua
print("[DEBUGBOSS] 关键路径描述:", var1, var2)
```

关键路径包括：
- 组件创建（打印当前世界分片）
- AddWaypoint 调用（参数+结果）
- 右键使用动作响应（目标/分片/分支选择）
- net_bool dirty 事件触发（ismastersim值/tag/value）
- 界面数据加载（来源/数量）
- DoTeleport 执行（selected索引/目标坐标/传送路径）
- RPC handler 接收（参数校验）

前缀统一为 `[DEBUGBOSS]`，方便对方直接搜索过滤日志。

## Sound Management: Cleaning Up Noisy Effects

### General Rule

Sound via `inst.SoundEmitter:PlaySound("...")` should be played **BEFORE** the entity is destroyed, never in `OnRemove` callback. During `OnRemove`, the entity's SoundEmitter is in an unstable state — playing sounds here produces crackling/noise artifacts.

### Best Practices

```lua
-- ⚠️ BAD: sound in OnRemove
local function OnRemove(inst)
    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("...")  -- crackle noise!
    end
end

-- ✅ GOOD: sound before Remove()
inst:DoTaskInTime(duration, function()
    if inst:IsValid() then
        if inst.SoundEmitter then
            inst.SoundEmitter:PlaySound("...")
        end
        inst:Remove()
    end
end)
```

### Kill Sounds on Removal

Always add `KillAllSounds()` in `OnRemove` to prevent lingering ambient sounds:
```lua
local function OnRemove(inst)
    if inst.SoundEmitter then
        inst.SoundEmitter:KillAllSounds()
    end
    -- visual FX only (no sound)
end
```

### Prefab List Validation

When listing prefabs for a prefab (the `prefabs = { ... }` table), every entry MUST exist as a registered prefab. Missing prefabs log `Can't find prefab X` and are silently skipped. Remove non-existent prefabs from the list.

### User Preference: No Annoying Sounds

The user of this codebase is extremely sensitive to unnecessary sound effects. Default to silence unless the sound provides gameplay-essential feedback. Remove:
- Minion despawn sounds
- Summon loop sounds (`shadowtalker_LP` etc.)
- Any "flavor" sounds that don't convey game state

#### 迁移 builder hook 时的陷阱：不要遗漏关联逻辑

当把 builder hook 从 `AddComponentPostInit`（modmain）移到 `master_postinit`（prefab）时，必须同时迁移**所有关联逻辑**，不仅仅是 `HasCharacterIngredient` 和 `RemoveIngredients`。

常见遗漏（已在迁移时逐个确认）：
- **装迷糊抵消逻辑**（消耗三维时的概率补偿）✅
- **freebuildmode 处理**（模式一 vs 模式三的差异）✅
- **其他角色的 tag 检查**（`self.inst:HasTag("mingsheng")`）✅

**迁移检查清单**：
- [ ] HasCharacterIngredient 迁移了吗？
- [ ] RemoveIngredients 迁移了吗？包含内部的所有分支逻辑
- [ ] 任何依赖 `self.inst`（原 hook 内的 inst 引用）的附带的 logic 迁移了吗？
- [ ] 旧位置删干净了吗（避免双重hook）？

### 16. IsCharacterIngredient 注册 — 不要用 nil guard 包裹

```lua
-- ❌ BAD: 如果原版 IsCharacterIngredient 是 nil（被其他mod删除或不存在），整个注册不生效
local oldIsCharacterIngredient = IsCharacterIngredient
if oldIsCharacterIngredient ~= nil then
    IsCharacterIngredient = function(ingredienttype)
        if ingredienttype == MINGSHENG_HUNGER then
            return true
        end
        return oldIsCharacterIngredient(ingredienttype)
    end
end

-- ✅ CORRECT: 无条件覆盖，内部处理 nil
local oldIsCharacterIngredient = IsCharacterIngredient
IsCharacterIngredient = function(ingredienttype)
    if ingredienttype == MINGSHENG_HUNGER then
        return true
    end
    if oldIsCharacterIngredient then
        return oldIsCharacterIngredient(ingredienttype)
    end
end
```

### 17. CHARACTER_INGREDIENT 自定义消耗 — 客户端不需要 hook builder_replica

**模式总结**（从多个mod验证：Elaina、雪露Setsuro、藿藿Huohuo）：

所有mod都只在**服务端** hook `builder.HasCharacterIngredient` + `RemoveIngredients`。客户端 `builder_replica.HasCharacterIngredient` **不需要** hook。

```lua
-- 服务端 (master_postinit 或 AddComponentPostInit)
local old_HasCharacterIngredient = inst.components.builder.HasCharacterIngredient
inst.components.builder.HasCharacterIngredient = function(self, ingredient, ...)
    if ingredient.type == MY_CUSTOM_TYPE then
        if self.inst.components.myresource ~= nil then
            local current = math.ceil(self.inst.components.myresource.current)
            local has = self.freebuildmode or current >= ingredient.amount
            return has, current
        end
    end
    return old_HasCharacterIngredient(self, ingredient, ...)
end

-- 客户端 builder_replica 不 hook！DST 自动从服务端同步显示结果
```

为什么不需要：
- 客户端 builder_replica 的 `HasCharacterIngredient` 在初始化时会从服务端同步结果
- 额外 hook 容易引入不一致（比如 `classified` 还没初始化就读到了0）
- 雪露、Elaina 都没有客户端 hook，正常工作

### 18. AddPlayerPostInit — tag timing pitfall

### 19. Headgear wear-check for builder cost offset

When a character has a 특정 head item equipped that negates crafting costs on a % chance, hook `RemoveIngredients` AFTER calling the original function:

```lua
local old_RemoveIngredients = inst.components.builder.RemoveIngredients
inst.components.builder.RemoveIngredients = function(self, ingredients, recname)
    -- handle custom character ingredient consumption
    local recipe = AllRecipes[recname]
    if recipe then
        for k, v in pairs(recipe.character_ingredients) do
            if v.type == CHARACTER_INGREDIENT.MINGSHENG_HUNGER then
                local current = math.ceil(self.inst.components.hunger.current)
                if current >= v.amount then
                    inst.components.hunger:DoDelta(-v.amount, nil, true)
                end
            end
        end
    end

    local ret = old_RemoveIngredients(self, ingredients, recname)

    -- After removal: check for headgear offset
    if TheWorld.ismastersim and inst:HasTag("mingsheng") then
        local head = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if head and head.prefab == "mingsheng_zhuangmihu" and head.components.fueled and head.components.fueled.currentfuel > 0 then
            if math.random() <= 0.3 then  -- 30% chance
                local recipe = AllRecipes[recname]
                if recipe then
                    for k, v in pairs(recipe.character_ingredients) do
                        if v.type == CHARACTER_INGREDIENT.MINGSHENG_HUNGER then
                            inst.components.hunger:DoDelta(v.amount, nil, true)
                        elseif v.type == CHARACTER_INGREDIENT.SANITY then
                            inst.components.sanity:DoDelta(v.amount)
                        elseif v.type == CHARACTER_INGREDIENT.HEALTH then
                            inst.components.health:DoDelta(v.amount)
                        end
                    end
                end
                -- Consume headgear durability
                if head.components.fueled then
                    head.components.fueled:DoDelta(-10)
                end
            end
        end
    end
    return ret
end
```

Key pattern: run `old_RemoveIngredients` first, then check conditions and refund, not the other way around (the cost must be deducted first, then optionally undone).

### 20. Crop giant growth — guaranteed oversized

To force a crop to become oversized when entering its final stage, set `inst.force_oversized = true` before it transitions:

```lua
-- In pregrowfn or before SetStage to final stage:
inst.force_oversized = true
```

DST reads this in `farm_plants.lua` line 518:
```lua
inst.is_oversized = inst.force_oversized or (not inst.no_oversized and ...)
```

**When using SetStage manually** (e.g. for a growth-spell), always call the current stage's `pregrowfn` first so stress checkpoints are accumulated:

```lua
local stages = inst.components.growable.stages
local current = inst.components.growable.stage
local stage_data = stages[current]
if stage_data and stage_data.pregrowfn then
    stage_data.pregrowfn(inst)
end
inst.components.growable:SetStage(current + 1)

-- Force oversized on final stage
if current + 1 == #stages then
    inst.force_oversized = true
end
```

**Why not DoMagicGrowth?** `domagicgrowthfn` sets `inst.no_oversized = true` (line 596 of farm_plants.lua), which permanently blocks oversized regardless of stress state. Manually calling `pregrowfn` + `SetStage` avoids this.

When using `AddPlayerPostInit` with `inst:HasTag(...)`, **check the tag at runtime inside the callback, not at initialization time**.

```lua
-- ❌ BAD: at postinit time, tags may not be ready yet
AddPlayerPostInit(function(inst)
    if TheWorld.ismastersim and inst:HasTag("mingsheng") then  -- tag check at closure time!
        inst:ListenForEvent("death", function()
            -- ...
        end)
    end
end)

-- ✅ GOOD: check tag at runtime when event fires
AddPlayerPostInit(function(inst)
    if TheWorld.ismastersim then
        inst:ListenForEvent("death", function()
            if not inst:IsValid() or not inst:HasTag("mingsheng") then return end  -- tag check at runtime
            -- ...
        end)
    end
end)
```

**Why**: Character tags (`inst:HasTag("mingsheng")`) are added during `common_postinit` or `master_postinit`, but `AddPlayerPostInit` may fire before those complete. At closure time, the tag might not exist yet → the listener never gets registered. At runtime inside the event callback, the tag is guaranteed to be set.

This is also fine — adding a death listener to every player and checking the tag at event time costs virtually nothing:

```lua
AddPlayerPostInit(function(inst)
    if TheWorld.ismastersim then
        inst:ListenForEvent("death", function()
            if not inst:IsValid() or not inst:HasTag("mingsheng") then return end
            -- mingsheng-specific death handling
        end)
    end
end)
```

`rechargeable` 是原版组件，自带**图标冷却遮罩效果**（类似绿护符用完后的冷却圈）。

```lua
inst:AddComponent("rechargeable")
inst.components.rechargeable:SetChargeTime(COOLDOWN_SECONDS)
inst.components.rechargeable:SetCharged(true)  -- 默认已充能

-- 使用时触发放电（开始冷却动画）
inst.components.rechargeable:Discharge(AMOUNT)

-- 冷却完成回调
inst.components.rechargeable:SetOnChargedFn(function(inst)
    -- 冷却结束
end)
```

适用于任何有冷却机制的物品（技能、献祭、定时使用等）。`Discharge` 参数=冷却秒数。

### 19. giant crop / oversized — force_oversized bypass

原版巨大化判定（farm_plants.lua line 518）：
```lua
inst.is_oversized = inst.force_oversized or (not inst.no_oversized and inst.components.farmplantstress ~= nil and inst.components.farmplantstress:GetFinalStressState() == FARM_PLANT_STRESS.NONE)
```

催熟（domagicgrowthfn）会设 `inst.no_oversized = true` 阻止巨大化。

**强制巨大化方案**：在作物进入final stage前设 `inst.force_oversized = true`。不依赖stress check，必定巨大化。

```lua
-- 生存告示催熟：手动触发stress checkpoint + force oversized
if inst.components.growable then
    local stages = inst.components.growable.stages or {}
    local current = inst.components.growable.stage or 1
    if current < #stages then
        local stage_data = stages[current]
        if stage_data and stage_data.pregrowfn then
            stage_data.pregrowfn(inst)
        end
        inst.components.growable:SetStage(current + 1)
    end
    -- 进入final stage时强制巨大化
    local new_current = inst.components.growable.stage or 1
    if new_current == #stages then
        inst.force_oversized = true
    end
end
```

**不要用** `inst.components.growable:DoMagicGrowth()` — 它会设no_oversized=true。
**使用** `SetStage` + `pregrowfn` 手动触发stress checkpoint + `force_oversized`。

### 20. rechargeable component
`rechargeable` is a vanilla DST component that provides icon cooldown overlay (like the green amulet's cooldown circle after use).

`irreplaceable` 标签会导致服务器下线/重启时从角色身上卸载物品到地上（即使该物品不应该掉落）。如果不需要这个行为，移除 `inst:AddTag(\"irreplaceable\")`。

### Builder RemoveIngredients: Hat-Gated Consumption Offset

When a worn hat (e.g. 装迷糊/zhuangmihu) should offset builder ingredient consumption, hook `RemoveIngredients` in the character prefab **after** calling the original. This is a refund pattern (deduct first, then optionally undo):

```lua
-- In master_postinit
local old_RemoveIngredients = inst.components.builder.RemoveIngredients
inst.components.builder.RemoveIngredients = function(self, ingredients, recname)
    -- Custom MINGSHENG_HUNGER consumption (character ingredient)
    local recipe = AllRecipes[recname]
    if recipe then
        for k, v in pairs(recipe.character_ingredients) do
            if v.type == CHARACTER_INGREDIENT.MINGSHENG_HUNGER then
                local current = math.ceil(self.inst.components.hunger.current)
                if current >= v.amount then
                    inst.components.hunger:DoDelta(-v.amount, nil, true)
                end
            end
        end
    end

    local ret = old_RemoveIngredients(self, ingredients, recname)

    -- Post-consumption offset: check hat, random mitigation, consume hat durability
    if TheWorld.ismastersim and inst:HasTag("mingsheng") then
        local head = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if head and head.prefab == "mingsheng_zhuangmihu"
            and head.components.fueled and head.components.fueled.currentfuel > 0 then

            if math.random() <= 0.3 then  -- 30% chance to refund
                if recipe then
                    for k, v in pairs(recipe.character_ingredients) do
                        if v.type == CHARACTER_INGREDIENT.MINGSHENG_HUNGER then
                            inst.components.hunger:DoDelta(v.amount, nil, true)
                        elseif v.type == CHARACTER_INGREDIENT.SANITY then
                            inst.components.sanity:DoDelta(v.amount)
                        elseif v.type == CHARACTER_INGREDIENT.HEALTH then
                            inst.components.health:DoDelta(v.amount)
                        end
                    end
                end
                head.components.fueled:DoDelta(-10)  -- consume hat durability
            end
        end
    end
    return ret
end
```

**Key design points**:
- **Post-consumption refund** — `old_RemoveIngredients` runs first, then we undo. Keeps base logic clean.
- **Check EQUIPSLOTS.HEAD** — `GetEquippedItem` returns item in head slot.
- **Durability check** — `fueled.currentfuel > 0` prevents triggering when hat is worn out.
- **Single random roll** — `math.random() <= 0.3` gates the entire offset, not a per-attribute roll.
- **Durability cost on trigger** — each successful offset costs 10 seconds of hat fuel.

### Crop Giantification Mechanics

#### Overview

Crops (farm_plants.lua) have a `farmplantstress` component with 7 stressor categories. Each growth stage transition runs a **checkpoint** that evaluates all 7 stressors and accumulates `stress_points`. At the **final stage** (full), `CalcFinalStressState()` determines the result.

#### Giantification Condition

```lua
-- farm_plants.lua:518
inst.is_oversized = inst.force_oversized
    or (not inst.no_oversized
        and inst.components.farmplantstress ~= nil
        and inst.components.farmplantstress:GetFinalStressState() == FARM_PLANT_STRESS.NONE)
```

**FARM_PLANT_STRESS values**:
```
NONE     = 1  -- stress_points ≤ 1 (allow 1 mistake)
LOW      = 2  -- stress_points ≤ 6
MODERATE = 3  -- stress_points ≤ 11
HIGH     = 4  -- anything worse
```

#### 7 Stressor Categories

| Stressor | Test | Condition |
|----------|------|-----------|
| nutrients | `CycleNutrientsAtPoint` | Soil has enough N/P/K |
| moisture | `farmsoildrinker:CalcPercentTimeHydrated()` | Hydrated ≥ `min_percent` |
| killjoys | FindEntities with `farm_plant_killjoy` tag | ≤ `max_killjoys_tolerance` |
| family | FindEntities with own `plant_type_tag` | ≥ `family_min_count` nearby |
| overcrowding | `GetEntitiesOnTileAtPoint` | ≤ `FARM_PANT_OVERCROWDING_MAX_PLANTS` |
| season | `plant_def.good_seasons[season]` | Current season is good |
| happiness | Updated by tend/interact | Has been tended recently |

#### Checkpoint Flow

```
pregrowfn → MakeStressCheckpoint(inst, is_final_stage)
  ├── Re-evaluate all 7 stressors
  ├── MakeCheckpoint() → sum stressed → add to stress_points
  ├── if is_final_stage: CalcFinalStressState()
  └── inst.scale = random * 0.07 + (stress_ratio > 0.5 ? 0.86 : 0.93)
```

#### ⚠️ DoMagicGrowth Blocks Giants

```lua
-- farm_plants.lua:596 (domagicgrowthfn)
if inst.components.growable:IsGrowing() then
    inst.no_oversized = true   -- FORCES no giant!
```

Any growth acceleration that goes through `DoGrowth`/`DoMagicGrowth` sets `no_oversized = true`. The only exception is `inst.force_oversized = true`.

#### ❌ SetStage() Skips Checkpoints

`growable:SetStage()` fires `fn` callback but NOT `pregrowfn` (where stress checkpoints run). Result: no stress accumulated, `final_stress_state` stays nil, no giant.

#### ✅ Manual Checkpoint + force_oversized (Mod Items)

For items that advance crops AND want to guarantee giants:

```lua
local function BoostCrop(inst)
    if inst.components.growable then
        local stages = inst.components.growable.stages or {}
        local current = inst.components.growable.stage or 1
        if current < #stages then
            local stage_data = stages[current]
            if stage_data and stage_data.pregrowfn then
                stage_data.pregrowfn(inst)  -- manual stress checkpoint
            end
            inst.components.growable:SetStage(current + 1)
        end
        local new_stage = inst.components.growable.stage or 1
        if new_stage == #stages then
            inst.force_oversized = true  -- overrides everything
        end
        return true
    end
    return false
end
```

#### Crop Lifespan Stages

```
seed → sprout → small → med → full (harvestable) → rotten → [self-sow if not oversized]
```

Oversized crops do NOT self-sow after rotting. Normal crops after rotting set `no_oversized = true` for the next generation.

#### Key Files

| File | Purpose |
|------|---------|
| `prefabs/farm_plants.lua` | All crop prefabs, stress tests, growth stages, oversized logic |
| `prefabs/farm_plant_defs.lua` | Per-crop definitions |
| `components/farmplantstress.lua` | Stress tracking, checkpoints, final calc |
| `components/farming_manager.lua` | Soil moisture/nutrients per tile |
| `components/growable.lua` | Stage progression |

## Farming / Giant Crops

### Giant Crop Conditions (Vanilla DST)

**7 stress categories** (registered in `farm_plants.lua`):
1. `nutrients` — soil depleted (via `CycleNutrientsAtPoint`)
2. `moisture` — soil too dry (< `plant_def.moisture.min_percent`)
3. `killjoys` — nearby weeds exceed tolerance
4. `family` — not enough same-type plants nearby
5. `overcrowding` — too many plants on same tile
6. `season` — wrong season for plant
7. `happiness` — set by player interaction (tending/fire)

**Stress checkpoint** triggers at each growth stage transition via `pregrowfn`:
```lua
-- farm_plants.lua stage definition
{
    name = "med",
    time = GetGrowTime,
    pregrowfn = function(inst)
        MakeStressCheckpoint(inst)  -- evaluates all 7 stressors
    end,
    -- ...
}
```

**Final stage (full) → giant check** (line 518):
```lua
inst.is_oversized = inst.force_oversized 
    or (not inst.no_oversized 
        and inst.components.farmplantstress ~= nil 
        and inst.components.farmplantstress:GetFinalStressState() == FARM_PLANT_STRESS.NONE)
```

**Final stress state calculation** (`farmplantstress.lua`):
```lua
self.final_stress_state = stress <= 1 and FARM_PLANT_STRESS.NONE    -- allow one mistake
    or stress <= 6 and FARM_PLANT_STRESS.LOW
    or stress <= 11 and FARM_PLANT_STRESS.MODERATE
    or FARM_PLANT_STRESS.HIGH
```

`FARM_PLANT_STRESS = { NONE=1, LOW=2, MODERATE=3, HIGH=4 }`

**Magic growth blocks giant** (`domagicgrowthfn` line 596):
```lua
if inst.components.growable:IsGrowing() then
    inst.no_oversized = true  -- ← this prevents giant!
```

### Forcing Giant

**Method 1**: Set `inst.force_oversized = true` just before stage transition to full. The `pregrowfn` for the "full" stage reads this and overrides the stress check:
```lua
-- In the "full" stage's pregrowfn:
inst.force_oversized = true
-- This causes line 518 to short-circuit: inst.is_oversized = true
```

**Method 2**: Use magic growth but clear `no_oversized` after:
```lua
inst.no_oversized = false  -- after DoMagicGrowth sets it true
```

### Stress Checkpoint must fire for giant

When advancing growth stages via `SetStage()`, the `pregrowfn` (which calls `MakeStressCheckpoint`) must be called manually:
```lua
-- Safe manual boost:
local stages = inst.components.growable.stages
local current = inst.components.growable.stage
if current < #stages then
    local stage_data = stages[current]
    if stage_data and stage_data.pregrowfn then
        stage_data.pregrowfn(inst)  -- trigger stress checkpoint!
    end
    inst.components.growable:SetStage(current + 1)
end
```

Without calling `pregrowfn`, `SetStage` skips stress accumulation entirely — no giant possible.

## DST Mod Debugging — Crash Diagnosis & Mod Loading Pitfalls

Diagnose and fix DST mod crashes by analyzing Lua error logs, with a focus on the `require` vs `modimport` loading environment distinction.

### Common Crash Sources

| Error | Cause | Fix |
|-------|-------|-----|
| `module 'xxx' not found` | File missing from mod directory | Copy from reference workshop mod |
| `variable 'GLOBAL' is not declared` | `require`-loaded file accessed `GLOBAL` | Switch to `modimport` + `GLOBAL.xxx = xxx` |
| `variable 'Widget' is not declared` | `require`-loaded file missing engine globals | `modimport` + explicit `require "widgets/widget"` for engine widgets |
| `attempt to call global 'XXX' (nil)` | modimport order wrong or export missing | Reorder modimports, add `GLOBAL.xxx = xxx` |
| `stack overflow` (text.lua:86) | OnGainFocus → SelectEntry infinite loop | Only set `self.selected`, never call SelectEntry in OnGainFocus |

### The Critical Distinction: `require` vs `modimport`

| Aspect | `modimport` | `require` |
|--------|-------------|-----------|
| Environment | Mod env with `GLOBAL` `__index` bridge | Isolated new environment |
| `GLOBAL` accessible? | ✅ Yes | ❌ Blocked by strict.lua |
| Engine widgets available? | ✅ Through GLOBAL bridge | ❌ Must explicit `require "widgets/widget"` |
| Use case | **Mod internal files** | **Game engine files only** |

**Rule**: Never `require` a mod's own file. Never use `GLOBAL.xxx` inside a `require`-loaded file — `GLOBAL` itself is blocked by strict.lua.

### Correct Pattern: modimport + GLOBAL exports

```lua
-- modmain.lua — order matters
modimport("scripts/persistentdata.lua")
modimport("scripts/mingsheng/scripts/lib/uidragzoom.lua")
modimport("scripts/screens/mingsheng_teleportscreen.lua")

-- Each mod file end:
GLOBAL.PersistentData = PersistentData
GLOBAL.UIDragZoom = UIDragZoom
-- NOT "return PersistentData"
```

### DST Lua Require Path Resolution

When `require "foo.bar.baz"`:
- Dots → directories: `foo/bar/baz.lua`
- Search order: 1) `../mods/<name>/scripts/foo/bar/baz.lua`, 2) `scripts/foo/bar/baz.lua` (game), 3) `scriptlibs/foo/bar/baz.lua`

### Crash: OnGainFocus → SelectEntry Stack Overflow

```lua
-- CRASH: infinite loop
entry.OnGainFocus = function(self2)
    self:SelectEntry(self2.index)  -- Unselect rebalances focus → re-enters OnGainFocus
end

-- SAFE: only set index
entry.OnGainFocus = function(self2)
    self.selected = self2.index
end
```

### Crash: SetMouseConsumes Doesn't Exist

Neither Image nor Widget has this method. Prevent click-through with coordinate checks in OnClick or use an overlay ImageButton with event consuming root.

### Crash: ImageButton — `IsFocused()` Doesn't Exist

Use `IsSelected()` or `HasFocus()` instead.

## AddAction + AddComponentAction — 完整交互系统模式

### 三件套结构

每个自定义右键交互需要3步：

1. **`AddAction(name, str, fn)`** — 定义动作
2. **`AddComponentAction(type, comp_name, fn(inst, doer, target, actions, right))`** — 在右键菜单显示动作选项
3. **`AddStategraphActionHandler("wilson", ActionHandler(action, anim))`** — 播放动画

### Action handler 签名

```lua
AddAction("MY_ACTION", "动作名", function(act)
    -- act.invobject = 手持物品
    -- act.target = 右键目标
    -- act.doer = 玩家
    -- return true → 动作成功
    -- return false → 玩家说"做不到"
end)
```

### ComponentAction 三种类型

| type | 触发条件 | 示例 | 可用性 |
|------|---------|------|--------|
| `"USEITEM"` | 手持物品右键另一个物体 | 命理→告示者修补、告示→盔甲修补 | ✅ 推荐 |
| `"INVENTORY"` | 背包里右键物品 | 右键背包里的告示者部署/激活 | ✅ 推荐（替代SCENE） |
| `"SCENE"` | 空手右键地面上的物体 | 右键仆从休息、地上物品激活 | ⚠️ 必须绑专用组件(非inventoryitem)，见下方 |
| `"POINT"` | 右键地面某个点 | 部署物品 | 极少用 |

### ⚠️ INVENTORY 类型需要 mingsheng_useitem 组件

INVENTORY 右键部署不是自动的——物品需要同时满足两个条件：

1. **标签**：`mingsheng_item` tag
2. **组件**：`mingsheng_useitem` component（其构造函数自动加 `mingsheng_item` tag）

```lua
-- ❌ 只有 tag，INVENTORY 右键不生效
inst:AddTag("mingsheng_item")

-- ✅ tag + component，INVENTORY 右键触发 MINGSHENG_USEITEM action
inst:AddComponent("mingsheng_useitem")
inst.components.mingsheng_useitem:SetFn(function(item, doer, target)
    -- 自定义部署逻辑
    doer.components.inventory:DropItem(item, true, true)
    return true
end)
```

`AddComponentAction("INVENTORY", "mingsheng_useitem", ...)` 匹配的是**组件名**，不是 tag。光有 `mingsheng_item` tag 没有 `mingsheng_useitem` 组件 → 右键没反应。这货类似 DST 原版 `deployable` 组件的角色。

### ⚠️ SCENE ComponentAction 规则：必须绑专用组件

**核心规则**：`AddComponentAction("SCENE", ...)` 的组件名必须是**独立专用组件**（如 `mingsheng_gaoshizhe_henshin` 用于物品、`mingsheng_gaoshizhe_minion` 用于仆从），**绝不绑定 `inventoryitem`、`follower` 等官方组件**。绑定官方组件会导致 SCENE 动作完全不触发。

已验证不工作的官方组件：`inventoryitem`（2026-08-07）、`follower`（2026-08-07）。

**仆从 SCENE（如"休息"动作）同理**：不要绑 `follower` 组件。写专用 marker（如 `mingsheng_gaoshizhe_minion`）放在仆从 prefab 上，然后在 modmain 绑到这个专用组件。
```lua
-- ❌ 不工作
AddComponentAction("SCENE", "follower", function(inst, doer, actions, right)
    if right and inst:HasTag("mingsheng_gaoshizhe_minion") then
        table.insert(actions, ACTIONS.MINGSHENG_GAOSHIZHE_REST)
    end
end)

-- ✅ 工作
AddComponentAction("SCENE", "mingsheng_gaoshizhe_minion", function(inst, doer, actions, right)
    if right and inst:HasTag("mingsheng_gaoshizhe_minion") then
        table.insert(actions, ACTIONS.MINGSHENG_GAOSHIZHE_REST)
    end
end)
```

已验证的工作模式：
```lua
-- ✅ 绑专用组件 — 工作
AddComponentAction("SCENE", "mingsheng_gaoshizhe_henshin", function(inst, doer, actions, right)
    -- 加 print 调试
    print(string.format("[DEBUG] SCENE check: right=%s tag=%s",
        tostring(right), tostring(inst:HasTag("my_tag"))))
    if right and doer ~= inst and inst:HasTag("my_tag") then
        table.insert(actions, ACTIONS.MY_ACTION)
    end
end)

-- ❌ 绑 inventoryitem — 不工作（2026-08-07 确认）
AddComponentAction("SCENE", "inventoryitem", ...)
```

- 专用组件只需是一个空 marker 类（构造函数加个 tag 即可），放在目标 prefab 上
- HasTag 过滤 + `doer ~= inst` 守卫
- **加 print 调试**看函数是否被调到、tag 状态是否正确

### ⚠️ USEITEM marker 组件放在手持物品上，不放在目标上

`AddComponentAction("USEITEM", "marker_comp", fn)` 匹配的是**手持物品**的组件：`inst` = 手持物品，`target` = 右键目标。把 marker 组件错放在目标 prefab 上 → GIVE 动作永远不会触发。

实例：梦魇/月华/命理需要 `mingsheng_repairable` 组件（不在 gaoshizhe 上），否则手持右键告示者充能/修补不触发。

**常见坑**：marker 组件只加在了目标物品上（如 gaoshizhe），忘了加在手持材料上（梦魇/月华/命理）。`AddComponentAction("USEITEM", "marker_comp", fn)` 里的 `inst` 是手持物品，不是目标。必须确认所有手持材料 prefab 都有 marker 组件。

**专用 marker 组件模板**（最小空类）：
```lua
-- scripts/components/my_marker.lua
local MyMarker = Class(function(self, inst)
    self.inst = inst
end)
return MyMarker
```

**仆从 SCENE 同理**：不要绑 `follower` 组件，写专用 marker（如 `mingsheng_gaoshizhe_minion`）放在仆从 prefab 上。

### `finiteuses` 二元充能状态模式

**用途**：物品需要"充能/未充能"二元状态，在 SCENE 右键时判断是否可激活。标签仍用于区分类型（如 shadow/illusion）。

**为什么不用纯标签**：
- 标签在 GIVE action 里加了之后，物品可能已被 Remove（充能即激活模式）
- SCENE 右键需要可靠的状态查询
- `finiteuses` 是 DST 原生组件，带网络同步和 UI 耐久条

**模式（craft 即带电）**：
```lua
-- prefab: craft 出来就带电（默认用 uses=1）
inst:AddComponent("finiteuses")
inst.components.finiteuses:SetMaxUses(1)
inst.components.finiteuses:SetUses(1)  -- 1=已充能，可直接激活

-- 默认类型标签
inst:AddTag("gaoshizhe_shadow")

-- SCENE check: 查 uses
local charged = inst.components.finiteuses and inst.components.finiteuses:GetUses() > 0

-- ACTIVATE action: 消耗 uses
gaoshizhe.components.finiteuses:SetUses(0)
gaoshizhe:Remove()
```

**模式（需要充能才可用）**：
```lua
-- prefab: 初始 0 uses
inst.components.finiteuses:SetUses(0)  -- 0=未充能

-- CHARGE action: 设 uses=1
act.target.components.finiteuses:SetUses(1)
act.target:AddTag("gaoshizhe_shadow")
```

**标签与耐久分工**：标签区分类型（shadow/illusion），`finiteuses` 管充能状态。两套互不干扰。GIVE 切换类型只改标签不改耐久。

**INVENTORY + mingsheng_useitem 模式**（首选替代）：
```lua
-- prefab 加组件
inst:AddComponent("mingsheng_useitem")
inst.components.mingsheng_useitem:SetFn(function(item, doer, target)
    -- 处理逻辑。target 在 INVENTORY 右键时通常为 nil
    if condition then
        -- do stuff
        item:Remove()  -- 手动移除物品
        return true
    end
    -- 兜底：丢到地上
    doer.components.inventory:DropItem(item, true, true)
    return true
end)
```
- 注意：`MINGSHENG_USEITEM` action 设置了 `instant = true`，不会自动消耗物品，需手动 `item:Remove()`
- INVENTORY 右键时 `target` 为 nil，USEITEM（手持右键）时 `target` 是右键目标

### ⚠️ AddComponentAction 重复注册覆盖（真实踩坑）

```lua
AddComponentAction("USEITEM", "mingsheng_repairable", function(inst, doer, target, actions, right)
    if not right then return end
    if not target then return end

    -- 可以在一个 handler 里处理多个目标+物品组合
    if target.prefab == "mingsheng_mingyun" and inst:HasTag("mingsheng_item") then
        table.insert(actions, ACTIONS.MINGSHENG_REPAIR_ARMOR)
    end
    if target.prefab == "mingsheng_gaoshizhe" and not target._gaoshi_type then
        if inst.prefab == "mingsheng_mengyan" or inst.prefab == "mingsheng_yuehua" then
            table.insert(actions, ACTIONS.MINGSHENG_GAOSHIZHE_CHARGE)
        end
    end
end)
```

### 坑点

- **AddComponentAction 对同一个 (type, comp_name) 组合只能有一个 handler**（最后一个覆盖前面的）。不同 type 不冲突。实际踩坑（告示者）：(USEITEM, mingsheng_repairable) 被注册了两次，第二个覆盖了第一个，导致充能和修补菜单项消失。

- **USEITEM marker 组件必须放在手持物品（source/inst）上，不能放在目标（target）上**。`AddComponentAction("USEITEM", "mingsheng_repairable", fn)` 匹配的是手持物品的组件，不是右键目标的组件。`inst` = 手持物品（如梦魇/月华/命理），`target` = 右键目标（如告示者）。把 `mingsheng_repairable` 错放在 gaoshizhe 上 → GIVE 充能永远不会触发。修复：把 marker 组件加到梦魇/月华/命理 prefab 上。
- Act.invobject / act.target / act.doer 在服务端都是实体引用，可直接读写其字段

- **`AddComponentAction` 对同一个 `(type, comp_name)` 组合只能有一个 handler**（最后一个覆盖前面的）。不同 type 不冲突：`("USEITEM", "xxx")` 和 `("SCENE", "xxx")` 是两个独立 key，各管各的。但同一个 type+comp_name 重复注册会覆盖。
  - **实际踩坑（告示者）**：`("USEITEM", "mingsheng_repairable")` 被注册了两次（充能+修补 vs 激活），第二个覆盖了第一个，导致充能和修补菜单项消失。修复：激活改为走 INVENTORY+mingsheng_useitem（物品栏右键）。
- Act.invobject / act.target / act.doer 在服务端都是实体引用，可直接读写其字段
- SCENE type 的 handler 中 `inst` = 场景中的目标物体，`doer` = 玩家
- USEITEM type 的 handler 中 `inst` = 手持物品，`target` = 右键目标
- **Action 类型选择**：看 `act.target` 是谁。优先用 INVENTORY（物品栏右键）或 USEITEM（手持物品右键目标）。`act.target` = 交互目标实体 → 选 USEITEM。搞混会导致 `act.target.prefab` 对不上永远返回 false。

### Stategraph 动画绑定

```lua
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MY_ACTION, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MY_ACTION, "doshortaction"))
```

- `"wilson"` = 服务端玩家 SG，`"wilson_client"` = 客户端玩家 SG，两个都要绑
- 常用动画：`"doshortaction"`（短动作，挥手）、`"give"`（递东西）、`"action"`（长动作）

## 双形态仆从物品（Item ↔ Minion Toggle）模式

### 适用场景

一个物品可以放置到地面，通过交互变成活的仆从（复用已有 minion prefab），仆从又可以变回物品收入背包。类似伯尼（Bernie）模式。

### 核心流程

```
制作物品 → 右键充能(消耗材料) → 右键激活(生成仆从) → 仆从战斗
                                                      ↓
                                             死亡→掉落物品(需修补)
                                                      ↓
                                             右键休息→变回物品(可收入背包)
                                             命理→修补→重新充能
```

### 实现模式

**物品 prefab**（简单，只做物品形态）：
```lua
-- scripts/prefabs/my_item.lua
inst:AddTag("my_item_tag")
inst:AddComponent("inventoryitem")     -- 可收入背包
inst:AddComponent("deployable")        -- 可放置到地面
inst:AddComponent("my_component_tag")  -- 供 AddComponentAction 匹配
inst._state_variable = nil             -- 状态标记（nil/shadow/illusion 等）
```

**modmain.lua** 中注册4个 action：
```lua
-- 1. 充能（手持材料→物品）
AddAction("MY_CHARGE", "赋予能量", function(act)
    -- 检查 act.invobject.prefab 是否为充能材料
    -- 消耗材料
    -- act.target._state_variable = "能量类型"
end)

-- 2. 激活（右键地面上的物品→生成仆从）
AddAction("MY_ACTIVATE", "激活", function(act)
    -- 检查 act.target._state_variable
    -- 检查上限（通过 doer.components.leader.followers 计数）
    -- SpawnPrefab("minion_prefab") → 设 follower → 设 tag
    -- 监听仆从 death → 掉落新物品
    -- act.target:Remove()
end)

-- 3. 休息（右键仆从→变回物品）
AddAction("MY_REST", "休息", function(act)
    -- SpawnPrefab("my_item")，继承状态
    -- act.target:Remove()
end)

-- 4. 修补（手持修补材料→破损物品）
AddAction("MY_REPAIR", "修补", function(act)
    -- 消耗修补材料
    -- 恢复可用状态（_state_variable = nil 即可重新充能）
end)
```

**ComponentAction 匹配**：
```lua
-- USEITEM: 手持材料→物品
AddComponentAction("USEITEM", "my_component_tag", function(inst, doer, target, actions, right)
    -- inst=手持物品, target=右键目标
    if target.prefab == "my_item" and inst.prefab == "charge_material" and not target._state_variable then
        table.insert(actions, ACTIONS.MY_CHARGE)
    end
    if target.prefab == "my_item" and inst.prefab == "repair_material" then
        table.insert(actions, ACTIONS.MY_REPAIR)
    end
end)

-- SCENE: 右键地面上的物品→激活
AddComponentAction("SCENE", "my_component_tag", function(inst, doer, actions, right)
    if inst.prefab == "my_item" and inst._state_variable then
        table.insert(actions, ACTIONS.MY_ACTIVATE)
    end
end)

-- follower tag: 右键仆从→休息
AddComponentAction("SCENE", "follower", function(inst, doer, actions, right)
    if inst:HasTag("my_minion_tag") then
        table.insert(actions, ACTIONS.MY_REST)
    end
end)
```

### 坑点

- **AddComponentAction 不能重复注册同一个 type+comp_name** — 合并到1个handler
- **仆从死亡掉落物品**要用 `ListenForEvent("death")`，在action handler里注册
- **数量上限**通过 `doer.components.leader.followers` 遍历计数
- **仆从要设 `keepdeadleader = true`** 防止死亡后follower关系断开

### ⚠️ 充能动作必须支持重新切换

设计上往往要求 "重新给予材料可以切换形态"（如 shadow↔illusion），但容易在**两处**同时堵死：

```lua
-- ❌ BAD: handler 层就挡住了已充能物品
if target.prefab == "my_item" and not target._state_variable then
    table.insert(actions, ACTIONS.MY_CHARGE)
end

-- ❌ BAD: action 层拒绝已充能
if act.target._state_variable then
    act.doer.components.talker:Say("已充能，请先激活。")
    return false
end
```

**正确做法**：

**Handler**（line 362）：去掉 `not target._state_variable`，让已充能物品也能弹出充能菜单。

**Action**：分两条路径处理：
```lua
-- 已充能 → 切换类型（同类型不浪费）
if act.target._state_variable then
    local old_type = act.target._state_variable
    act.target._state_variable = (new_type)
    if old_type == act.target._state_variable then
        -- 同类型，不消耗材料
        return false
    end
    -- 消耗材料 + 切换
    consume_material()
    return true
end

-- 未充能 → 正常充能
consume_material()
act.target._state_variable = (new_type)
return true
```

### 充能+自动激活 合并模式

当充能和激活是连续两步操作时，合并为一个 action。充能完成后直接 spawn 仆从 + Remove 物品：

```lua
AddAction("MY_CHARGE", "充能", function(act)
    -- ... 消耗材料、设置标签 ...
    act.target:AddTag("charged_shadow")

    -- 自动激活：检查上限 + spawn
    local doer = act.doer
    local n = count_minions(doer)
    if n >= MAX then
        doer.components.talker:Say("已达上限！", 3)
        return true  -- 已充能，不召唤
    end

    local minion = SpawnPrefab("my_minion")
    if minion then
        local x, y, z = act.target.Transform:GetWorldPosition()
        minion.Transform:SetPosition(x, y, z)
        minion.components.follower:SetLeader(doer)
        minion:ListenForEvent("death", function()
            local item = SpawnPrefab("my_item")
            if item then
                local mx, my, mz = minion.Transform:GetWorldPosition()
                item.Transform:SetPosition(mx, my, mz)
            end
        end)
    end
    act.target:Remove()
    return true
end)
```

要点：充能→直接spawn→Remove物品，一步到位。上限满了只充能不出。同类型切换也走同样路径。

### ⚠️ 充能+自动激活模式下的 SCENE 死代码陷阱（及两种修复）

当充能 action 在 handler 里直接 `Remove()` 目标物品时，**任何针对同一物品的 SCENE 右键激活 action 都会变成死代码**。原因链：
1. GIVE 充能 → handler 里 `act.target:Remove()` → 物品从世界消失
2. 已充能的物品从不独立存在于地面上
3. SCENE action（`AddComponentAction("SCENE", ...)`）只在地面物品右键时触发
4. → SCENE 激活 action 永远无法被触发

**方向A**（一步到位）：充能即激活。充能后直接 spawn + Remove。不需要 SCENE。
```lua
AddAction("MY_CHARGE", "充能", function(act)
    act.target:AddTag("charged")
    SpawnMinion(act.target)     -- 出仆从
    act.target:Remove()         -- 移除物品
    return true
end)
```

**方向B**（需要 SCENE 右键激活，本次 2026-08-07 采用）：充能只加标签不 Remove，SCENE 绑专用组件负责激活。
- 充能：`AddTag` + 消耗材料 + return true（不 Remove）
- SCENE：绑 `mingsheng_gaoshizhe_henshin` 专用组件（非 inventoryitem），检查 HasTag 后 spawn + Remove
- 此方向要求 SCENE 工作，**必须用专用组件绑定**（见上方 SCENE 规则）

## 配方注册

```lua
-- AddRecipe（旧版API）
AddRecipe("prefab_name", ingredients, tab, tech, ..., builder_tag, atlas, image)

-- AddRecipe2（新版推荐API）
AddRecipe2("prefab_name", {
    Ingredient("papyrus", 5),
    Ingredient("reviver", 1),
}, TECH.NONE, {
    atlas = "images/inventoryimages/my_item.xml",
    image = "my_item.tex",
    builder_tag = "mingsheng",
    numtogive = 1  -- 每次制作产出数量，默认1
}, {"CHARACTER"})
```

- `builder_tag` 限制只有该标签的角色能制作
- 第二个参数 `{"CHARACTER"}` 是 recipe tab（角色专属配方）
- Ingredient 跨mod物品需要额外传 atlas/image 参数

### Common DST Mod Libraries

- `persistentdata` — saves UI state across sessions; place at `scripts/persistentdata.lua`
- `uidragzoom` — UI drag-to-move + scroll-to-zoom with persistence; place at `scripts/<modname>/scripts/lib/uidragzoom.lua`

### Debug References (restored from `dst-mod-debugging`)

The following reference files under `references/` document specific debugging case studies, widget patterns, and fix techniques:

- `references/dst-combat-hook-backstab.md` — Backstab damage multiplier via externaldamagemultipliers
- `references/dst-cross-shard-teleport-pattern.md` — Cross-shard teleport UI (surface↔caves)
- `references/dst-custom-shop-widget-pattern.md` — Custom shop Widget with ImageButton tabs, ScrollingGrid, PushEvent toggle, drag-to-move persistence
- `references/dst-imagebutton-entries.md` — ImageButton entry pattern for selectable lists
- `references/dst-overlay-pattern.md` — Full-screen click-to-dismiss overlay
- `references/dst-screenshot-ocr.md` — EasyOCR setup and pixel analysis for DST crash screenshots
- `references/dst-scroll-list-pattern.md` — Manual scroll list for selectable entries
- `references/dst-ui-fixes.md` — UI scaling/positioning fix case study
- `references/error-log-format.md` — Annotated DST Lua crash log format
- `references/screenshot-analysis.md` — PIL pixel analysis for bug screenshots

## Musha Character Mod — Profession/Skill System

### Distinction: Musha ≠ Mingsheng

Musha (穆莎) and Mingsheng (铭盛) are **separate DST character mods** sharing the `mods/` directory. Do not confuse them.

### Project Location

D:\\\\SteamLibrary\\\\steamapps\\\\common\\\\Don't Starve Together\\\\mods\\\\musha\\\\

### Architecture Overview

```
mods/musha/
├── modmain.lua                    # Entry — prefab registration, combat hooks, actions
├── scripts/
│   ├── prefabs/
│   │   ├── musha.lua              # Character prefab
│   │   ├── musha_sword.lua        # Job weapon
│   │   ├── musha_jobbook_warrior.lua  # Base job books
│   │   ├── musha_skillbook.lua    # Advanced skill books
│   │   └── musha_note.lua         # Starting guidance note
│   ├── components/
│   │   ├── musha_profession_component.lua   # ★ Core: profession data + skill trees + exp
│   │   ├── musha_profession_component_replica.lua  # Client-side replica
│   │   ├── musha_quest.lua        # Quest system
│   │   ├── musha_skillui.lua      # Skill panel UI
│   │   ├── musha_book.lua         # Book interaction
│   │   └── musha_keyhandler.lua   # Key bindings
│   ├── skills/musha_skill_data.lua
│   ├── actions/musha_actions.lua
│   ├── rpcs/musha_rpcs.lua
│   └── widgets/                   # UI screens
```

### Profession System (musha_profession_component.lua)

**Career Constants** (modmain.lua):
```lua
MUSHA_JOB = {
    NONE = 0,  WARRIOR = 1,  MAGE = 2,  RANGER = 3,  ASSASSIN = 4,
    SWORDSMAN = 11, GUARDIAN = 12, ALCHEMIST = 21, ELEMENTALIST = 22,
    BARD = 31, MOONSHADOW = 41
}
```

**User Data Structure:**
```lua
self.userdata = {
    carrer_base = "warrior",     -- Base job (warrior/mage/ranger/rogue)
    carrer_special = "saber",    -- Advanced job
    level = 0, exp = 0,
    skill_points = 0, exp_to_next = 5,
    total_exp = 0, has_advanced = false,
    learned_skills = {},
}
```

### Adding a New Skill Checklist

1. Add skill definition to skill tree in `musha_profession_component.lua`
2. Update OnSave — add skill's `current_level`
3. Update OnLoad — restore `current_level`
4. Update GetAllSkillLevels — iterate the skill tree
5. Update GetDebugString — include in skill count
6. (Optional) Add combat hook in modmain.lua
7. (Optional) Add UI data in `musha_skill_data.lua`

### Combat Hooks Pattern (Backstab example)

```lua
local old_StartAttack = Combat.StartAttack
Combat.StartAttack = function(self, target, ...)
    self.externaldamagemultipliers:RemoveModifier(self.inst, "mod_name")
    if IsBehindTarget(self.inst, target) then
        local mult = 1 + (backstab_level * 0.3)
        self.externaldamagemultipliers:SetModifier(self.inst, mult, "mod_name")
    end
    return old_StartAttack(self, target, ...)
end
```

### Existing Combat Events (fired by profession component)
- `onattackother` — fires AFTER damage (for SAN costs, life leech)
- `losttarget` — target lost (clears hunt bonus, starts health regen)
- `killedother` — kills grant experience
- `attacked` — when player is hit (stops health regen)

### Persistence

All skill data saved via `OnSave()` returning structured table, restored via `OnLoad(data)`. The `userdata` table is saved wholesale, plus individual skill tree levels.

### Musha Reference Files

- `references/musha_jobsystem.md` — Complete job system design
- `references/musha_systems.md` — Quests, skill UI, key handling
- `references/dst-net-event-official-pattern.md` — DST官方builder_replica的OpenCraftingMenu net_event链路代码（已验证）

## Headgear Visual Display — swap_hat Symbol

DST 头部装备（`EQUIPSLOTS.HEAD`）在角色身上的显示需要**两样东西同时存在**：anim build 文件的 `swap_hat` symbol + Lua 代码的 `OverrideSymbol`。

### 原理

```
装备 prefab 的 AnimState:SetBuild("xxx") 指定的 .zip 文件
  → 必须有 swap_hat 这个 symbol（骨骼/图层）
  + 
装备 prefab 的 equippable:SetOnEquip() 中
  → OverrideSymbol("swap_hat", build_name, "swap_hat")
  → Show("HAT") / Show("HAT_HAIR")
```

**缺任何一项 → 装备可穿戴但角色头上不显示。**

### 完整代码模式（写 prefab 文件里）

```lua
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "你的build名", "swap_hat")
    owner.AnimState:Show("HAT")
    owner.AnimState:Show("HAT_HAIR")
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAT_HAIR")
end

inst.components.equippable:SetOnEquip(onequip)
inst.components.equippable:SetOnUnequip(onunequip)
```

**关键规则：**
- `onequip`/`onunequip` 定义为 `local function`，不要写在 `SetOnEquip` 回调内部
- `OverrideSymbol` 的第二个参数 = anim build 名（即 `.zip` 文件名去掉扩展名）
- 如果 anim build 就在角色自身的 build 里（共用 `swap_hat` symbol），第二个参数传角色 build 名即可

### 常见问题

#### 问题1：缺少 anim zip
```
inst.AnimState:SetBuild("mingsheng_zhuangmihu")
但 anim/mingsheng_zhuangmihu.zip 不存在
```
装备没有模型，头上不可见。检查：
```bash
ls mods/mingsheng/anim/ | grep zhuangmihu
```

#### 问题2：漏写 onequip/onunequip
装备有 anim zip + `swap_hat` symbol，但 prefab 没写 `SetOnEquip` → 头上空白。
原因：DST **不会自动**把装备的 build 渲染到角色头上。必须通过 `OverrideSymbol` 明确告诉引擎要覆盖角色头部的哪个 symbol。

### 制作头部装备需要的文件

| 文件 | 位置 | 说明 |
|------|------|------|
| `.zip` (anim build) | `anim/xxx.zip` | 必须包含 `swap_hat` symbol |
| `.tex` + `.xml` (atlas) | `images/inventoryimages/` | 背包图标 |
| prefab `.lua` | `scripts/prefabs/` | `EQUIPSLOTS.HEAD` + `SetBuild` + `SetOnEquip` with `OverrideSymbol` |

### 制作方法

1. 用 `Autocompiler` 将 `.scml` 编译为 `.zip`
2. 或在已有 build 的基础上用 `krane` 解包修改
3. 确保 zip 内有 `swap_hat` symbol

## net_bool UI Toggle: Singleplayer Mode Trap + Dual Path

**Bug A**: A net_bool dirty listener that starts with `if TheWorld.ismastersim then return end` blocks singleplayer entirely (singleplayer IS the master server).

**Bug B**: `set(false); set(true)` triggers an unnecessary network sync. Use `set_local(false)` instead.

**Bug C**: Listen Server (主机联机) 模式下，单一 net_bool 路径可能因网络同步延迟而失败。加 PushEvent 双路径备用。

**Bug**: A net_bool dirty listener that starts with `if TheWorld.ismastersim then return end` blocks singleplayer entirely (singleplayer IS the master server).

**Fix**: Replace the skip with `TheFrontEnd` existence check + dual paths:

```lua
-- 角色 prefab common_postinit
-- 方式1: PushEvent 路径（本地事件，Listen Server 备用）
inst:ListenForEvent("mingsheng_openteleport", function()
    if not TheFrontEnd then return end
    local ok, screen = pcall(require, "screens/mingsheng_teleportscreen")
    if ok and screen then
        TheFrontEnd:PushScreen(screen(inst))
    end
end)

-- 方式2: net_bool 路径
inst.mingsheng_openteleport = net_bool(inst.GUID, "mingsheng_openteleport", "mingsheng_openteleport_dirty")
inst:ListenForEvent("mingsheng_openteleport_dirty", function()
    if not inst.mingsheng_openteleport:value() then return end
    if not TheFrontEnd then
        inst.mingsheng_openteleport:set_local(false)
        return
    end
    local ok, screen = pcall(require, "screens/mingsheng_teleportscreen")
    if ok and screen then
        TheFrontEnd:PushScreen(screen(inst))
    end
    inst.mingsheng_openteleport:set_local(false)
end)
```

Key rules:
- Use `set_local(false)` (not `set(false)`) to avoid extra network sync
- No `TheWorld.ismastersim` check — rely on `TheFrontEnd` nil guard
- `pcall(require)` for screen module
- Dual trigger in Action handler:

See `references/mingsheng-shenxing-teleport-singleplayer-fix-2026-06-05.md` for full session details.

## Anim Build Decompilation (krane / ktools)

解包官方或第三方的 anim build `.zip` 文件，还原为 Spriter `.scml` + PNG。

### 官方 anim 文件位置

```
D:\SteamLibrary\steamapps\common\Don't Starve Together\data\anim\
```

以 `_build.zip` 结尾的是纯 build 文件（build.bin + atlas），以 `_fx.zip` 结尾的是特效动画。伯尼相关文件：
- `bernie_build.zip` — 小伯尼 build（25 symbols, 119 frames）
- `bernie_big.zip` — 大伯尼
- `bernie_lunar_build.zip` / `bernie_shadow_build.zip` — 月灵/暗影形态

### ktools 工具位置

```
/d/饥荒开发/ktools/
├── krane.exe   # anim/build 解包 → Spriter SCML
├── ktech.exe   # .tex 纹理转换 → PNG
```

### krane 用法

```bash
# 解包 anim.zip（包含 anim.bin + build.bin + atlas）
krane --build <build_name> ./anim_dir ./output

# 解包纯 build.zip（只有 build.bin + atlas）
# 先 unzip，再对目录跑
krane --build <build_name> ./extracted_dir ./output
```

### ⚠️ RGBA 纹理坑

ktools 自带的 ImageMagick DLL **缺少 RGBA coder**（只有 `IM_MOD_RL_png_.dll` / `IM_MOD_RL_rgb_.dll` / `IM_MOD_RL_xc_.dll`），遇到 RGBA 格式的 atlas 会报：

```
ERROR: krane.exe: NoDecodeDelegateForThisImageFormat `RGBA' @ error/blob.c/BlobToImage/355
```

**影响**：krane 能解析 build.bin 头部（symbol 数量/名称），但到贴图阶段就挂了。

**绕过方案**：
1. 找新版 ktools（带 RGBA coder 的编译版本）
2. 用 Python/PIL 手动解码 .tex → PNG，再手动拼 SCML（参考下方 build.bin 格式）
3. 装系统级 ImageMagick 并确认有 RGBA delegate

### build.bin v6 格式

解析用 Python `struct` 库：

```
// Header
uint32 magic        // "BILD" = 0x444C4942
uint32 version      // 6
uint32 num_symbols  // 25
uint32 num_frames   // 119
str    build_name   // length-prefixed (4-byte len + data)
uint32 num_atlases   // 1
str    atlas_names[] // length-prefixed per atlas

// Symbol data (repeated num_symbols times):
uint32 hash          // symbol hash
uint32 frame_idx     // base frame index
uint32 flags
uint32 num_sym_frames

// For each sym_frame:
uint32 source_frame
uint32 duration
float  bbox_x, bbox_y, bbox_w, bbox_h
float  u1, v1, u2, v2  // UV coordinates in atlas

uint32 name_hash      // symbol name hash
```

字符串是 **4字节长度前缀 + 数据**（不是 null-terminated），见 offset 0x10 处 `0C 00 00 00` = 长度12 → `bernie_build`。

### .tex 纹理格式

KTEX 格式，magic `4B 54 45 58`。RGBA 纹理的像素数据在 header 后可能 zlib 压缩。用 ktech 转换时遇到同款 RGBA delegate 缺失问题。

## Weapon Template + Artist Guide

When building a weapon mod that needs artist collaboration (e.g. book-as-weapon), see `references/weapon-template-artist-guide.md` for:
- Complete weapon mod directory structure
- Prefab code template (book weapon example)
- Animation frame design for artist instructions
- Copy-paste message to send to the artist
- **Spriter source-file workflow** (exported/ directory + BUILD/ folder + SCML files)

When the user has created `exported/<name>/BUILD/` with png frames and needs SCML files written for them, see `references/scml-standard-weapon-template.md` for:
- Standard weapon SCML template (book_weapon.scml + swap_book_weapon.scml)
- SCML XML structure reference (folder, file, entity, timeline, key)
- entity name must match build name rule
- Compilation via Krane or Autocompiler
- Common pitfalls (png path, pivot, entity mismatch)

**Key pattern**: Create `book_weapon_template/` as a working mod with `modinfo.lua`, `modmain.lua`, weapon prefab, and a `画师动画说明.txt` file that the user can forward directly to the artist. When the artist provides png frames in `exported/<name>/BUILD/`, write the SCML files by hand (do NOT copy from other mods — most are empty 0KB placeholders).

## 官方 Build 文件反编译

### 文件位置

DST 官方 anim/build 文件在 `数据目录/data/anim/`：

```
D:\SteamLibrary\steamapps\common\Don't Starve Together\data\anim\
```

以 bernie 为例：`bernie_build.zip`（仅 build，无 anim）、`bernie.zip`（build+anim）。

### krane 反编译 — RGBA 纹理坑

当前环境的 krane（`/d/饥荒开发/ktools/krane.exe`）无法解码 RGBA 格式的 .tex 纹理：

```
ERROR: krane.exe: NoDecodeDelegateForThisImageFormat `RGBA' @ error/blob.c/BlobToImage/355
```

**原因**：ktools 自带的 ImageMagick DLL 只包含 png/rgb/xc 三个 coder，缺少 `IM_MOD_RL_rgba_.dll`。

RGBA 纹理的特征：TEX 文件第 5 字节为 0x82（pixel format），build.bin 中 atlas 数据以 RGBA raw/zlib 存储。

**方案**：
1. 用支持 RGBA 的新版 krane（推荐）
2. 用 Python 手动解码 .tex → PNG，再配合 build.bin 解析

### 反编译输出组织结构

krane 输出是**平铺**的：所有 symbol 的 PNG 帧都在同一目录，文件名格式 `symbolname-帧号.png`。

**需要手动分层**：每个 symbol 建一个子目录，把对应 PNG 移入：

```bash
cd 输出目录
for f in *.png; do
    dir="${f%%-[0-9]*.png}"
    mkdir -p "$dir" && mv "$f" "$dir/"
done
```

结果结构：
```
bernie_build/
├── bernie_build.scml
├── bernie_armlower/
│   └── bernie_armlower-0.png
├── bernie_armupper/
│   ├── bernie_armupper-0.png
│   └── bernie_armupper-1.png
├── big_body/
│   ├── big_body-0.png
│   └── ...
└── ...
```

⚠️ **scml 文件在输出根目录**，别在整理时误删。

## Animation Compilation (scml → .zip)

将 Spriter SCML + PNG 帧编译为 DST 可用的 anim `.zip` 文件。

### 工具位置

```
C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Mod Tools\mod_tools\
├── scml.exe          # SCML 编译器（第一步）
├── autocompiler.exe  # 自动编译管线（scml + png → .zip）
├── png.exe           # PNG 编译器
```

### 编译流程

**步骤1**: `scml.exe` 处理 SCML + PNG 帧，生成中间文件。

```bash
"/c/Program Files (x86)/Steam/steamapps/common/Don't Starve Mod Tools/mod_tools/scml.exe" \
  "<mod_dir>/exported/<build_name>/<build_name>.scml" \
  "<mod_dir>/anim/"
```

**步骤2**: `autocompiler.exe` 运行完整管线（scml → png → zip）。

```bash
"/c/Program Files (x86)/Steam/steamapps/common/Don't Starve Mod Tools/mod_tools/autocompiler.exe" \
  "<mod_dir>"
```

### ⚠️ 常见坑点

#### 1. 输出位置：嵌套 `anim/anim/`

autocompiler 的输出会写入 `<mod_dir>/anim/anim/<build_name>.zip`（多一层嵌套）。**手动移到正确位置**：

```bash
mv <mod_dir>/anim/anim/<build_name>.zip <mod_dir>/anim/
rm -rf <mod_dir>/anim/anim/
```

#### 2. 缺失帧文件（0x0 占位帧）

krane 反编译不完整时，某些 symbol 文件夹可能缺失。`scml.exe` 报错：

```
ERROR: Missing image 'big_tail/big_tail-0.png' referenced by 'gaoshizhe.scml'.
```

**诊断**：比对 scml 中 `<folder>` 的 name 和实际存在的目录。

```python
import re, os
scml = open('exported/gaoshizhe/gaoshizhe.scml').read()
folders_in_scml = set(re.findall(r'<folder id="\d+" name="([^"]+)"', scml))
actual_dirs = set(d for d in os.listdir('exported/gaoshizhe/') if os.path.isdir(...))
print("Missing:", folders_in_scml - actual_dirs)
```

**修复**：缺失的帧如果尺寸是 `0x0`（空占位），创建 1x1 透明 PNG 即可：

```python
# 1x1 RGBA transparent PNG (minimal binary)
import struct, zlib, os

def create_minimal_png():
    raw = b'\x00\x00\x00\x00'
    ihdr = struct.pack('>IIBBBBB', 1, 1, 8, 6, 0, 0, 0)
    def chunk(t, d):
        c = t + d
        return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) + chunk(b'IDAT', zlib.compress(b'\x00'+raw)) + chunk(b'IEND', b'')

png_data = create_minimal_png()
for folder, files in [('bernie_ear', ['bernie_ear-0.png', ...]), ...]:
    os.makedirs(f'exported/gaoshizhe/{folder}', exist_ok=True)
    for f in files:
        open(f'exported/gaoshizhe/{folder}/{f}', 'wb').write(png_data)
```

#### 3. scml.exe 可以独立运行

如果 autocompiler 跑不起来（比如环境变量问题），`scml.exe` 可以独立调用并接受输出目录参数。编译完 scml 后 autocompiler 负责后续 png→zip 步骤。

#### 4. krane 只能解包，不能编译

`krane.exe` 是**单向**工具：`.zip` → `.scml` + `.png`。编译（scml → zip）只能用 DST Mod Tools 的 `scml.exe` + `autocompiler.exe`。

#### 5. 官方build的动画名不一定有"idle"

编译完的 build 在 prefab 里不能盲目写 `PlayAnimation("idle")`。先用 `grep '<animation ' exported/xxx/xxx.scml` 看有什么动画名。例如 bernie_build 没有"idle"，小玩偶休眠态叫 `inactive`，大伯尼是方向性 `idle_loop_down/up/side/nodir`。

⚠️ **Bernie `inactive` 动画是全黑影（silhouette）**，不是全色。`inactive` 使用 `swap_bernie_dead` 部件。如果需要全色地面物品显示，改用 `idle_loop_nodir`。配合 `SetMultColour(1,1,1,1)` 和 `Hide("swap_object")` 清理多余的武器/手持符号。

### build.bin 格式速查（v6）

```
magic(4) + version(4) + num_symbols(4) + num_frames(4)
+ name_len(4) + name(name_len)
+ num_atlases(4) + [atlas_name_len(4)+atlas_name]*N
+ symbol_data[]  -- 每个 symbol: hash+frame_idx+flags+num_frames + frames[] + name_hash
  每帧: src_frame(4)+duration(4)+bbox_xywh(4*4)+uv_u1v1u2v2(4*4)
```

## User Preferences
- Persistence: Component manages own OnSave/OnLoad, don't modify character prefab.
- Testing order: get single-player/host working first, worry about guests later. Never test guests without being asked.
- 反编译输出：PNG 按 symbol 分目录存放，不要平铺。
- **标签 > 自定义字段**：实体状态追踪优先用 `AddTag`/`RemoveTag`/`HasTag`，不用 `inst._xxx` 自定义字段。标签是 DST 原生机制，序列化/网络同步都更可靠。例如告示者的充能状态用 `gaoshizhe_shadow`/`gaoshizhe_illusion` 标签而非 `_gaoshi_type` 字段。自定义字段（如 `_gaoshi_type`）只在无法用标签表达时才用。
