# BulbPlantMinTemp 灯泡花温度mod — 2026-07-05 最终验证

## 背景

用户说灯泡花40°C才不萎，想改到12°C。之前3层保护都失败（TemperatureVulnerable改值、PrickleGrass.OnSpawn强制复位、LateUpdate强制复位）。

## 本日尝试

### 尝试1：Destroy WiltCondition（失败）

删除 `WiltCondition` 组件导致 PrickleGrass 崩溃：

```
UnityEngine.GameObject 'BulbPlant' requires a component of type WiltCondition as requested by PrickleGrass!
  at Util.RequireComponent[T] (UnityEngine.Component cmp)
  at MyCmp.RequireComponent[T] (KMonoBehaviour c, System.Boolean isStart)
  at KMonoBehaviour.Start ()
```

WiltCondition 有 `[MyCmpReq]` 约束，是 PrickleGrass 的必需组件。

### 尝试2：反射强制 WiltCondition.isWilting = false（失败）

每0.5秒用反射把 `isWilting` 设为 false + 同时强制 TemperatureVulnerable 阈值。用户说还是不行。

### 尝试3（最终方案）：强制 PrimaryElement.Temperature ≥ 12°C（待验证）

用 `Game.LateUpdate` 每0.25秒扫描所有 BulbPlant，如果 PrimaryElement.Temperature < 285.15K，强制设为285.15K。
PrickleGrass 状态机读的是 PrimaryElement.Temperature，不是 TemperatureVulnerable。

## 总结

**mod层面无法让灯泡花无视低温枯萎，这是 Frosty Planet DLC 机制。** 唯一暴力方案是强制保持物体温度≥目标值。
