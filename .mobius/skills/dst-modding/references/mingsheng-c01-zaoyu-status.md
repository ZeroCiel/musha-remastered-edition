# 明生 S2 C-01 遭遇(卜算·遭遇) 调查结论 — 2026-08-20

来源：V5.1 文档 S2 清单 C-01「遭遇发光修复（时有时无）」排查。
文档：`D:\Backup\Downloads\DST明生下一步指导\DST明生-V5.1.md`（SSOT，§2.4 卜算告示表）。

## 文档设定（遭遇，存入知天命被动）

| 项目 | 设定 |
|---|---|
| 制作 | 100 理智 + 莎草纸 |
| 使用效果 | 回 50 理智 + 体温锁定 180s + 触发一次排箫催眠 |
| 存入知天命 | +5 攻击；120 隔热 + 120 保暖；**7 单位白光** |
| 持续时间 | 四档：180/150/120/90s（tuning `zaoyu_duration`） |

## 代码实际状态（prefabs/mingsheng_zaoyu.lua + prefabs/mingsheng_ztm.lua）

| 设定 | 现状 |
|---|---|
| 回 50 理智 | ✅ 已实装 |
| 催眠 9s | ✅ 已实装（sleeper/grogginess/freezable 三路 + sleepcloud FX） |
| 体温锁定 180s | ⚠️ 有组件但**写死**：zaoyu.lua 里 `TEMP_LOCK=24, DURATION=30`（24/30 秒），
  tuning 四档 `zaoyu_duration` **没接上**（OnUseItem 里没用 MINGSHENG_TUNING） |
| +5 攻击 | ✅ ztm.lua SetDamage 里 `HasZaoyuInContainer` + ztm_bonus_per_talisman |
| **7 单位白光** | ⚠️ **有代码但半径 1.5**：ztm.lua ~156 行 `HasZaoyuInContainer` 时
  SpawnPrefab("mingsheng_ztm_light") 挂到**知天命书实体**（`_light.entity:SetParent(inst.entity)`），
  但 mingsheng_ztm_light.lua 里 `SetRadius(1.5)`（呼吸灯，0.7~0.95 intensity）。
  1.5 单位半径=基本看不见 → 文档写的"时有时无"是**误判，实际是从未正确显示** |
| **120 隔热 + 120 保暖** | ❌ **完全未实现**：ztm.lua 全文件 grep 不到 insulator/insulation/隔热/保暖 |

## ✅ 已修复（2026-08-20 完成，三处全改完语法 OK）

1. **体温锁定时长读 tuning**：zaoyu.lua `local DURATION = MINGSHENG_TUNING.zaoyu_duration or 180`
   （TEMP_LOCK=24 目标体温保留；`GLOBAL.MINGSHENG_TUNING` 由 modmain.lua 第9行 `require("mingsheng_tuning"):GetTuning(tier)` 挂全局，prefab 可直接用，不用 require）
2. **灯光半径 1.5 → 7**：mingsheng_ztm_light.lua `SetRadius(7)`。**决策：灯挂知天命武器实体**（保持原实现 `_light.entity:SetParent(inst.entity)`），作为光照来源，不挂玩家身上——用户确认"挂在武器上的是生成灯光来作为光照来源"。
3. **隔热/保暖 120**：见下方「双向隔热保暖的正确姿势」——新增 `UpdateZaoyuInsulation(inst, owner)`，在 onequip / onunequip / OnItemGetOrLose（itemlose+itemget 事件都会走它）三处调用。

## 双向隔热保暖的正确姿势（DST 温度系统）

⚠️ **不要用 insulator 组件做"120 隔热 + 120 保暖"**：`components/insulator.lua` 单实例只有单一季节类型
（`SetWinter()` 或 `SetSummer()` 二选一，`GetInsulation()` 返回 `value, type`），一个物品无法同时给冬夏两季。

正确做法：直接改**玩家 temperature 组件**的固有绝缘字段（`data/databundles/scripts/components/temperature.lua`
~line 228 `Temperature:GetInsulation()` 汇总时会读这两个字段）：
```lua
-- 装备知天命且容器内有遭遇时：
owner.components.temperature.inherentinsulation         += 120  -- 冬季保暖
owner.components.temperature.inherentsummerinsulation   += 120  -- 夏季隔热
-- 卸载/取出遭遇时减回，用 math.max(0, ...) 防负，owner._mingsheng_zaoyu_ins_active 标记防重复
```
参考对照：hawaiianshirt 是纯夏季（SetInsulation + SetSummer），帽子纯冬季；双向必须走 inherent 字段。

## 排查方法备忘

- 判断 UI/功能"没有"vs"看不见"：grep 全 mod 找 prefab/组件引用，别只看 prefab 本身。
  发光功能其实存在——是 mingsheng_ztm_light 半径 1.5 导致肉眼不可见。
- 文档状态列（⚠️ 时有时无待修）不一定是代码真相，要以代码为准。
