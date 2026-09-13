# Coral Min Temp Mod — Debug Session 2026-06-25

## Problem

Mod patched `OxyCoralConfig.CreatePrefab` and `PlanktonCoralConfig.CreatePrefab` successfully (confirmed in Player.log), but coral minimum temperature did not change.

## Root Cause

In U59-737790, plant temperature is **not** stored on `PlantablePlot.lethalLowTemp` / `warningLowTemp`. It has been moved to the **`TemperatureVulnerable`** component's fields:

- `internalTemperatureLethal_Low` — lethal min temp (Kelvin)
- `internalTemperatureWarning_Low` — warning min temp (Kelvin)

These fields are PRIVATE — must be accessed via reflection, not direct property access.

## Debugging Method

1. Replaced the patch with a dump Postfix that iterates all components and prints their float fields
2. Two dump outputs confirmed `TemperatureVulnerable` with values:
   - OxyCoral: `lethalLow=253.15K (-20°C)`, `warnLow=298.15K (25°C)`
   - PlanktonCoral: `lethalLow=273.15K (0°C)`, `warnLow=298.15K (25°C)`
3. No `PlantablePlot` float fields related to temperature existed

## Fix

```csharp
var tempVuln = __result.GetComponent<TemperatureVulnerable>();
var t = typeof(TemperatureVulnerable);
var lethal = t.GetField("internalTemperatureLethal_Low",
    BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
var warning = t.GetField("internalTemperatureWarning_Low",
    BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
if (lethal != null) lethal.SetValue(tempVuln, 288.15f);
if (warning != null) warning.SetValue(tempVuln, 288.15f);
```

## "Version Expired" Fix

Mod showed "expired" in-game. Fix: include BOTH files:
- `mod.yaml`: title, description, staticID (3 fields only — no supportedContent or array fields)
- `mod_info.yaml`: minimumSupportedBuild, version, APIVersion

This matches the working pattern of `FlydoMiningHotfix`. The `supportedContent` array in `mod.yaml` caused `Recoverable parse error` warnings.

## Key Lesson

When a Harmony Postfix fires but nothing changes, DON'T assume the code is wrong — dump the full component tree to discover the actual field names. The game's internal API changes between builds.
