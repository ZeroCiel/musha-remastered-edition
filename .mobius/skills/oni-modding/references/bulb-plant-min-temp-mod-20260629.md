# BulbPlantMinTemp — 灯泡花最低温度12°C

Created 2026-06-29, copied from CoralMinTemp pattern.

## What it does
Patches `BulbPlantConfig.CreatePrefab` (Postfix), sets `TemperatureVulnerable.internalTemperatureLethal_Low` and `internalTemperatureWarning_Low` to 285.15K (12°C).

## ⚠️ KNOWN LIMITATION (2026-07-02): PrickleGrass overrides

**Changing TemperatureVulnerable alone does NOT work.** BulbPlant uses `PrickleGrass` component (not standard plant wilting) to manage its wilt state. The `PrickleGrass.WiltingState` state machine **completely bypasses** TemperatureVulnerable's threshold check. 

**Definitively proven (2026-07-02 session):**
1. ✅ `BulbPlantConfig.CreatePrefab` Postfix changes `internalTemperatureLethal_Low` from 288K → 285.15K (confirmed in Player.log)
2. ✅ `PrickleGrass.OnSpawn` Postfix re-applies 285.15K (confirmed trigger)
3. ✅ `Game.LateUpdate` Postfix force-reapplies 285.15K every 2s (confirmed trigger)
4. ❌ **BulbPlant STILL wilts at low temperature** despite all three protections

**Components on BulbPlant gameObject (28 total):**
- ✅ TemperatureVulnerable (值被改成285.15K，但不管用)
- ✅ PrickleGrass (关键状态机组件—枯萎由它控制)
- ✅ HeatBulb (非MonoBehaviour子类, 可能存在单独的温度判断)
- ✅ WiltCondition (出现两次？可能是父类和子类)
- ✅ PrimaryElement (状态机可能直接读这个的温度)
- ✅ StateMachineController, SimTemperatureTransfer
- ❌ PlantablePlot — 不存在（灯泡花不是用种植架的植物）

**PrickleGrass exposed methods (可Harmony patch):**
- `DestroySelf`
- `OnPrefabInit`
- `OnSpawn`
- 注意：没有 `GetWiltCondition` 方法

**Root cause:** PrickleGrass `+States|WiltingState` state machine reads temperature from PrimaryElement or through its own state machine logic, completely ignoring `TemperatureVulnerable.internalTemperatureLethal_Low`.

**Still-untested approaches:**
1. Patch `PrickleGrass` StateMachine AliveStates/WiltingState transitions
2. Patch `HeatBulb` InitializeStates or related sm methods
3. Destroy `WiltCondition` component on BulbPlant via LateUpdate
4. Reduce `SimTemperatureTransfer` conductance instead
5. Directly modify `PrimaryElement.Temperature` per-frame (global, affects all)

**See also:** `references/bulb-plant-min-temp-session-20260702.md`

## File structure
```
mods/Local/BulbPlantMinTemp/
├── BulbPlantMinTemp.cs
├── BulbPlantMinTemp.csproj
├── BulbPlantMinTemp.dll
├── mod.yaml
└── mod_info.yaml
```

## Code pattern
```csharp
var plantType = Type.GetType("BulbPlantConfig, Assembly-CSharp");
var createPrefab = plantType.GetMethod("CreatePrefab", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
harmony.Patch(createPrefab, postfix: new HarmonyMethod(postfix));

// In postfix:
var tempVuln = __result.GetComponent<TemperatureVulnerable>();
var lethalField = typeof(TemperatureVulnerable).GetField("internalTemperatureLethal_Low", ...);
lethalField.SetValue(tempVuln, 285.15f); // 12°C
```

## Temperature conversion
- 12°C = 285.15K
- 15°C = 288.15K (CoralMinTemp)
- 0°C = 273.15K
