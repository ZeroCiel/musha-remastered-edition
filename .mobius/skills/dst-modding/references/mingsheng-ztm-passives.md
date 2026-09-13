# 明生 知天命武器容器被动（mingsheng_ztm.lua）

> 来源：2026-08-23 排查「卜算·遭遇」存入知天命的发光被动"时有时无"（V5.1 §2.4，C-01）。
> 知天命 = 明生书本武器，7 格容器，仅放卜算告示；每放入一种告示 +5 基础攻击（档位倍率），另带存入被动。

## 结构速览
- ztm 装备槽 = `EQUIPSLOTS.HANDS`（mingsheng.lua 的 equip 监听用 `data.eslot == EQUIPSLOTS.HANDS and data.item.prefab == "mingsheng_ztm"` 识别）。
- onequip 时 `container:Open(owner)` 打开容器 UI；容器内容变化会触发被动增删。
- 每种告示一个 `HasXxxInContainer(inst)` 判断（container:HasItemWithTag / Has）。
- 被动分布两处：
  1. `SetDamage(inst, data)` —— 伤害/位面/被动副作用全在这一个函数里
  2. `UpdateZaoyuInsulation(inst, owner)` —— 遭遇隔热保暖（单独函数，onequip/OnItemGetOrLose 调）

## 各告示存入被动（SetDamage 内）
- 命理 mingli：+5 基础攻击（伤害项）
- 梦魇 mengyan：+5 攻击 + 位面；`owner.components.grue:SetResistance(1)` 查理免疫（⚠️ 文档要求"受击消耗一次"，现为常驻——S1 backlog 项）
- 遭遇 zaoyu：+5 攻击 + **发光**（见下）
- 天体 tianti：位面 +5；材料减免（builder.ingredientmod 减半，配合绿护符共存判断 HasOtherIngredientMods）
- 月华 yuehua：位面 +5；移除 owner 的 `scarytoprey` tag（小动物不惊惧），取出时加回
- 生存 shengcun / 神行 shenxing：`ApplyPassiveEnchants(inst, owner)`（onequip 里调；饥饿消耗 -20% / 移速 +10%，本文件未细验）

## 发光被动（zaoyu）——"时有时无"根因（C-01）
- 实现：`HasZaoyuInContainer(inst)` 为真时，SpawnPrefab(`mingsheng_ztm_light`) 挂到**玩家实体**（`inst._light.entity:SetParent(owner.entity)`，位置 (0,2,0)）；取出时 Remove。
- **根因**：光源的生成/移除逻辑写在 `SetDamage`（伤害计算函数）里，而 SetDamage 只在装备/容器变化/攻击等有限时机被调用，**没有周期兜底**。玩家死亡重生、传送、换世界或光源实体被外部移除后，没有触发点重新生成 → 光"时有时无"。
- 修复方向：把光源同步从 SetDamage 拆出，挂 equip/unequip + 容器变化事件监听（或低频周期检查 `inst._light` 有效性），与伤害计算解耦。

## 调试
- ztm 相关 print 前缀 `[明生武器]`（遭遇隔热生效/移除等）。
- 护符/装备槽注意：DST 无 AMULET 槽，所有护符穿 BODY（见 shadow-creature-system.md）。
