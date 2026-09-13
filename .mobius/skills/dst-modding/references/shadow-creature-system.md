# DST Shadow Creature 系统（影怪/暗影随从）

2026-08-23 暗影馈赠 bug 排查与修复的完整结论。

## 生成链路（低理智影怪）

- 原版 `TheWorld.components.shadowcreaturespawner:SpawnShadowCreature(player, params)` 是**唯一入口**：
  普通低san、海上（oceanhorror）、诱导疯狂（inducedinsanity）全部走它（UpdateSpawn → SpawnShadowCreature）。
- 拦截方法：override 该方法，条件满足直接 return nil（不生成）。
  - 挂载点：`AddSimPostInit`（TheWorld.ismastersim 时），组件为 nil 时 `DoTaskInTime(0)` 重试一次（AddSimPostInit 时机防御）。
- 不走 spawner 的影怪 prefab 列表（用 AddPrefabPostInit 覆盖）：
  `crawlinghorror, terrorbeak, crawlingnightmare, oceanhorror, nightmarebeak`
  （地下梦魇光 childspawner、废墟雕像、海上各走各路）。

## 仇恨机制

- **nightmare 系统直接 `SetTarget(玩家)`，不走 `combat.shouldaggrofn`**。
  shouldaggrofn 只挡"新仇恨判定"；已建立的 target 必须主动清。
- 清仇恨方案：周期任务（0.3s）直接检查 `combat.target` 是否命中条件，**不限距离**
  （只按半径扫会漏掉远处 SetTarget 后一路冲过来咬人的情况）。
- 近身推离仍按小半径 FindEntities。

## shadowcreature tag 的坑

- `shadowcreature` 标签 = 原版影怪标签 → **普通生物不会攻击它**。
- 给随从（如暗影明生 shadow_mingsheng）加这个 tag 会导致：
  1. 随从不受攻击（"没有仇恨"）
  2. 随从打怪后，怪物无法索敌它 → 仇恨全部落到附近的明生本体上
- 修复：随从不要带 shadowcreature tag（保留 shadow/companion 等自己的标签）。

## 紫护符检测

- DST `EQUIPSLOTS` 只有 HANDS/HEAD/BODY/BEARD，**没有 AMULET**。
- purpleamulet（梦魇护符）equipslot = `EQUIPSLOTS.BODY`（原版 amulet.lua 409 行）。
- `GetEquippedItem(EQUIPSLOTS.AMULET)` 传 nil → 永远返回 nil → 检测恒 false，整条链路静默失效。
  排查"功能完全没生效"先查槽位常量。

## 夜视与护符

- 佩戴 purpleamulet 时 mod 强制 san=0；若再用回理智道具（遭遇 +50 san）把 san 抬过阈值，
  sanitydelta 监听会把夜视关掉。
- 解法：sanitydelta 里判断"BODY 槽戴 purpleamulet → 强制 is_nightvision=true"，不看 san 阈值。
