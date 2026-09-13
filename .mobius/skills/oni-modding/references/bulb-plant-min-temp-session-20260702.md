# BulbPlantMinTemp 灯泡花温度mod — 2026-07-02 调试记录

## 问题

灯泡花改 TemperatureVulnerable 到12°C后仍然在低温枯萎。

## 验证过程

### 阶段1：确认Patch生效

BulbPlantConfig.CreatePrefab Postfix:
- ✅ Patch被调用，游戏对象名 `BulbPlant`
- ✅ TemperatureVulnerable 组件存在
- ✅ `internalTemperatureLethal_Low`: 288 → 285.15 (改变成功)
- ✅ `internalTemperatureWarning_Low`: 293.15 → 285.15 (改变成功)
- ❌ PlantablePlot 组件为Null（灯泡花不带这个组件）
- ℹ️ HeatBulb 组件存在（`GetComponent("HeatBulb")` 返回非null对象）
- ℹ️ 28个组件：TemperatureVulnerable, PrickleGrass, WiltCondition, HeatBulb 等

### 阶段2：Game.LateUpdate强制复位

加 LateUpdate Postfix，每2秒扫描所有 TemperatureVulnerable，找到 BulbPlant 强制重新赋值。
- ✅ 强制复位日志输出
- ❌ 灯泡花仍然低温枯萎

### 阶段3：PrickleGrass.OnSpawn Postfix

加 PrickleGrass.OnSpawn Postfix，初始化时设置温度。
- ✅ BulbPlant 的 PrickleGrass.OnSpawn 多次触发
- ❌ 仍然枯萎

## 结论

**TemperatureVulnerable 字段的值不影响 BulbPlant 的枯萎判断。**

PrickleGrass 状态机（`PrickleGrass+States|WiltingState`）的温度判断完全绕过了 TemperatureVulnerable.internalTemperatureLethal_Low / Warning_Low。

## 关键发现

1. BulbPlant 的组件列表（从日志收集）：
   - DecorProvider, DiseaseSourceVisualizer, Effects, EntombVulnerable, InfoDescription
   - InfraredPrimaryElement, KBatchedAnimController, KBoxCollider2D
   - KPrefabID (Tag="BulbPlant"), KSelectable, Modifiers, Notifier
   - OccupyArea, PressureVulnerable, **PrickleGrass** (关键!)
   - **PrimaryElement**, Prioritizable, ReceptacleMonitor, SaveLoadRoot
   - SeedProducer, SimTemperatureTransfer, **StateMachineController**
   - **TemperatureVulnerable**, Traits, Transform, Uprootable, UprootedMonitor
   - **WiltCondition**, WiltCondition (注意: 出现两次?)

2. PrickleGrass 暴露的DL方法（非virtual，可patch）：
   - `DestroySelf`
   - `OnPrefabInit`
   - `OnSpawn`

3. PrickleGrass 状态机：
   - `PrickleGrass+States|AliveStates`
   - `PrickleGrass+States|WiltingState`
   - 没有 `GetWiltCondition` 方法

4. 温度检查可能路径：
   - PrickleGrass 状态机直接读 PrimaryElement 的温度
   - WiltCondition 的 `conditions` 字段
   - HeatBulb 组件有自己的温度逻辑（`HeatBulb` 非MonoBehaviour，字段不在文本段暴露）
   - `TemperatureVulnerableUpdater` + `WiltTempRangeMod`

## 仍未尝试的方案

1. Patch **PrickleGrass** 的 AliveStates / WiltingState 状态机过渡条件（用 Harmony 的 StateMachine patching 方式）
2. Patch **HeatBulb** 组件的 InitializeStates 或相关方法
3. Patch **WiltCondition** 的更新方法，对 BulbPlant 直接返回 false
4. Patch **PrimaryElement** 的 Temperature 属性（最粗暴，影响范围大）
5. 直接禁用 BulbPlant 上的 WiltCondition 组件（DestroyImmediate in LateUpdate）

## 补充

- 灯泡花不需要 `PlantablePlot` 组件（它是 Frosty Planet 的植物，用 ReceptacleMonitor）
- 灯泡花同时有 PrickleGrass 和 TemperatureVulnerable 两个温度相关组件
- PrickleGrass 通常用于丛林荆棘，灯泡花复用了它的状态机
