# Algae (绿藻) Oxygen Mechanics in ONI

## 常规模式 (Vanilla / Base Game)

- **藻类 (Algae) 元素定义**：在 `elements/solid.yaml` 中，只定义了基本物理属性（比热容0.2、导热2、熔点398.15K→泥土）。**没有** `OreSubClass.Sublimates` 标记。
- **藻类本身在格子里不会产氧**。它只是一个固体资源。
- 产氧必须通过建筑：藻类箱 (Algae Deoxidizer) 或 盆栽 (Terrarium)。

## 水星包 (Spaced Out DLC4 / Frosty Planet Pack)

- **灯喙鱼 (Lamprey / Radiant Eel)** 的行为机制：
  - 检测附近格子是否有藻类在地上（未挖掘为砖块状态）
  - 满足光照条件
  - 消耗藻类 → 产生氧气
- 这是鱼的行为，不是藻类元素自己的属性。
- 所以常规模式没有这种鱼 → 藻类不会自然产氧。

## 相关 DLL 类名（从 Assembly-CSharp.dll grep 得到）

| 类名 | 说明 |
|------|------|
| `DissolvingAlgae` | 藻类溶解组件，继承自 `Sublimates` |
| `Sublimates` | 升华基类（与 Oxylite、BleachStone 同体系） |
| `SublimatesEmit` / `OxyrockEmit` / `BleachstoneEmit` | 升华速率 |
| `DissolvingElementDiseaseEmitter` | 溶解时同时发射病菌 |
| `DissolvingElementDormant` | 溶解休眠状态 |
| `AlgaeConfig` | 藻类元素配置类，路径 `Assets/scripts/Mods/Ore/AlgaeConfig.cs` |
| `AlgaeHabitatConfig` | 藻类栖息地（建筑） |
| `AlgaeDistilleryConfig` | 藻类蒸馏器（建筑） |
| `AlgaeStegoConfig` | 水星包生物（藻类剑龙） |
| `AlgaeCometConfig` | 藻类彗星 |

## 从 DLL 提取类名的方法

```bash
# grep 模式搜索
grep -aPo '.{0,100}Algae.{0,100}' Assembly-CSharp.dll

# 查找特定模式字符串
grep -aPo '.{0,80}AlgaeConfig.{0,80}' Assembly-CSharp.dll

# 查找 Dissolving/Sublimates 相关类
grep -aPo '.{0,100}Dissolving.{0,100}' Assembly-CSharp.dll
```

## 扩展思路

若要在常规模式下实现"藻类在光照下产氧"，需要：
1. 用 Harmony patch 给藻类元素添加一个 `OnSpawn` 或 `Game.LateUpdate` 的检测逻辑
2. 检测格子亮度（lux 值）
3. 如果有藻类在上面 + 达到亮度阈值 → 调用气体发射逻辑
4. 可参考 `DissolvingAlgae` 的组件结构，或参考灯喙鱼的原始代码
