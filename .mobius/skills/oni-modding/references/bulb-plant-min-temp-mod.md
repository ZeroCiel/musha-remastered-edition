# BulbPlantMinTemp — 灯泡花最低温度12°C Mod (2026-06-29)

## Summary

Simple Harmony mod patching `BulbPlantConfig.CreatePrefab` to modify temperature thresholds.

## Code Pattern

```csharp
public override void OnLoad(Harmony harmony)
{
    base.OnLoad(harmony);
    var plantType = Type.GetType("BulbPlantConfig, Assembly-CSharp");
    var createPrefab = plantType.GetMethod("CreatePrefab",
        BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
    harmony.Patch(createPrefab, postfix: new HarmonyMethod(typeof(Mod), nameof(Mod.Postfix)));
}

public static void Postfix(ref GameObject __result)
{
    var tempVuln = __result.GetComponent<TemperatureVulnerable>();
    // Set internalTemperatureLethal_Low and internalTemperatureWarning_Low to 285.15K (12°C)
}

var plot = __result.GetComponent<PlantablePlot>();
// Also set lethalLowTemp and warningLowTemp as fallback
```

## ⚠️ U59-737790 Update (2026-07-02): PrickleGrass overrides TemperatureVulnerable

**This mod DOES NOT WORK** — changing TemperatureVulnerable values is not enough.

BulbPlant uses `PrickleGrass` component (not standard plant wilting) for its wilt state machine. The PrickleGrass.WiltingState bypasses TemperatureVulnerable's internalTemperature fields entirely. Even with values confirmed patched (log: `TempVuln lethalLow: 288 -> 285.15`), the plant still dies at low temperature.

Components on BulbPlant gameObject (logged 28 total):
- Has: TemperatureVulnerable, PrickleGrass, WiltCondition, HeatBulb
- Does NOT have: PlantablePlot

PlantablePlot fallback does nothing — the field is null on BulbPlant.

**Known failure modes:**
- ✅ TemperatureVulnerable value is correctly set to 285.15K
- ✅ Game.LateUpdate force-reapply every 2s doesn't help
- ❌ Plant still dies — PrickleGrass state machine controls wilting independently

**Next approach:** Patch PrickleGrass.GetWiltCondition/GetWiltConditions to return WiltCondition.None for BulbPlant.

## Key Details

- 12°C = 285.15K
- Default BulbPlant lethalLow was already 288.15K (15°C) — user wanted lower
- Successfully patches `TemperatureVulnerable.internalTemperatureLethal_Low` (old: 288 → new: 285.15)
- Dual-patch: both TemperatureVulnerable AND PlantablePlot for safety
- Target: `BulbPlantConfig` (NOT `BulbloomConfig` — different plant)
