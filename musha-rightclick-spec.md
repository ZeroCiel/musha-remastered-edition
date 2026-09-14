# 右键点地技能：原版两条路线 + 硬要求
2026-09-14 查证 · 全部结论来自当前版本 `data/databundles/scripts.zip`（行号是那个版本的行号）

## 一、原版只有两条路

### 路线 A：法杖那条（spellcaster → ACTIONS.CASTSPELL）
- 组件：`spellcaster` + `canuseonpoint = true`（组件自己会加 tag `castonpoint`，但**必须自己补**在 SetPristine 前，客机才看得到）
- `SetSpellFn(function(item, target, pos) end)` ← 回调签名
- 采集条件（componentactions.lua:2155 POINT.spellcaster）：
  - `inst:HasTag("castonpoint")`
  - 地面点 `TheWorld.Map:IsAboveGroundAtPoint(...)` 且没被挡
  - 非骑牛（除非有 crushitemcast 等特例 tag）
- 距离：动作自带 `distance=20`（actions.lua:455）
- 显示名：`ACTIONS.CASTSPELL` **没有 strfn** → 直接查 `STRINGS.ACTIONS.CASTSPELL`，而它是**字符串不是表** → 没法按物品区分，想改名只能自己挂 `ACTIONS.CASTSPELL.stroverridefn`（hack）
- 角色动作：SGwilson 的 CASTSPELL handler → 默认状态 `castspell`（抬手施法）
- 结论：能用，但"法术感"+ 改名要 hack

### 路线 B：女武神那条（aoetargeting + aoespell → ACTIONS.CASTAOE）★ 后来改用这条
样板：`prefabs/spear_wathgrithr.lua`（闪电战矛）、`prefabs/spear_gungnir.lua`（冈格尼尔）
- 组件：`aoetargeting`（**SetPristine 之前**加）+ `aoespell`（服务端加即可）+ 可选 `rechargeable`（冷却）
- `SetSpellFn(function(item, doer, pos) end)` ← **注意签名跟 A 不同**（A 是 target，B 是 doer）
- 采集条件（componentactions.lua:1990 POINT.aoespell）：
  1. **必须已经在 AoE 瞄准模式**：`playercontroller:IsAOETargeting()`，否则整个分支直接 `return`
  2. 物品上有 aoetargeting 组件时，它必须 `IsEnabled()`
  3. 手上不能拿着 active item（`inventory:GetActiveItem() ~= nil` 就 return）
  4. `TheWorld.Map:CanCastAtPoint(pos, alwayspassable, allowwater, deployradius)` 要为真
  5. 骑牛时除非 `aoetargeting.allowriding`
- 距离：`aoetargeting:GetRange()`（playeractionpicker.lua:95）→ 用 `SetRange(n)` 设
- 显示名（**这才是正规范式**）：`ACTIONS.CASTAOE.strfn = string.upper(act.invobject.prefab)`
  → 查 `STRINGS.ACTIONS.CASTAOE[<PREFAB 大写>]`，而 CASTAOE **是表**（有 GENERIC/HEALINGSTAFF…），缺项自动回 GENERIC
  → 所以每把武器加一行 `STRINGS.ACTIONS.CASTAOE.MUSHA_SWORD = "剑气斩"` 就行
- 角色动作：SGwilson 的 CASTAOE handler（1251）
  - 带 tag **`aoeweapon_lunge`** → `combat_lunge_start`（**角色冲刺位移**，女武神战矛/冈格尼尔就是这条）
  - 不带 → 默认 `castspell`（原地抬手）
- 冷却：女武神用 `rechargeable`（`Discharge(秒)` + `SetOnDischargedFn/OnChargedFn`，配合 `aoetargeting:SetEnabled(false/true)`）

## 二、路线 B 的硬要求（缺一条右键就永远不出现）
1. **`aoetargeting` 必须在 `inst.entity:SetPristine()` 之前加**
   原因：客机 `playercontroller:TryAOETargeting()` 直接读 `item.components.aoetargeting`（playercontroller.lua:1611）。
   服务端后加的组件客机没有 → 右键不进瞄准圈 → 采集条件 ① 永远不成立。
   （原版样板：plain `commonfn` 在 SetPristine 之前跑，里面就 `AddComponent("aoetargeting")`）
2. `SetRange(距离)` 客机也读 → 放在 pristine 之前那段里设（两边都有值）
3. `SetEnabled(true)` 是 netvar，服务端设即可同步；默认就是 true
4. `aoespell` 后加（服务端）**没问题**：动作注册机制 = `AddComponentAction` 按组件名登记
   + `EntityScript:RegisterComponentActions` 把组件 id 写进 `actionreplica` 同步给客机
   （componentactions.lua:3108 / 3121）
5. 玩家操作流程（原版行为）：**右键按一下**（此时没有别的右键动作）→ `TryAOETargeting()` → 出现瞄准圈
   → **再点地面** → 这次才出现 CASTAOE「技能名」→ 释放

## 三、musha 现在的接法（v4，2026-09-14）
`scripts/prefabs/musha_sword.lua`
- SetPristine 前：`AddComponent("aoetargeting")` + `SetAllowRiding(false)` + `SetRange(SKILL_RANGE)` + `reticule.mouseenabled = true`
- 服务端：`AddComponent("aoespell")` + `SetSpellFn(function(item, doer, pos) → WS.DoCast(doer, pos) end)`
- **没加** tag `aoeweapon_lunge` → 不位移（原地放）；想试女武神那种冲刺，加上这个 tag 就行
- 名字：modmain 里 `STRINGS.ACTIONS.CASTAOE.MUSHA_SWORD`（5 语言）

## 四、顺手查到的：玩家存活天数 API
- 每个玩家：`inst.components.age:GetAgeInDays()` = 存活天数（= floor(age / TUNING.TOTAL_DAY_TIME)，age.lua:55）
- HUD 上那个"第 N 天" = `GetDisplayAgeInDays()`（结果 +1，age.lua:59）
- 世界天数：`TheWorld.state.cycles`
- 原版用例：player_common_extensions.lua:199 上报 `dayssurvived`；birds.lua:79 用了 `if player.components.age ~= nil` 的保护写法
- 天数奖励用它判档：`GetAgeInDays()` ≥ 1/3/10/16/30
