# Harmony Patch Field Reference

## Generator vs Consumer — Choosing the Right Field

| Building Type | Field to Patch | Example Class |
|---|---|---|
| Generator (produces power) | `GeneratorWattageRating` | `LargeElectrobankDischargerConfig`, `CompactElectrobankDischargerConfig`, `GeneratorConfig` |
| Consumer (uses power) | `EnergyConsumptionWhenActive` | `DoorConfig`, `LiquidValveConfig`, `SolidValveConfig` |

**Rule of thumb:** If the building adds power to the grid, it's `GeneratorWattageRating`. If it drains power, it's `EnergyConsumptionWhenActive`.

## Battery Capacity

| Battery Type | Class | Field | Default |
|---|---|---|---|
| Smart Battery | `BatterySmartConfig` | `capacity` (in BuildingDef creation) | 40 kJ |
| Battery (small) | `BatteryMediumConfig` | `capacity` | 40 kJ |
| Jumbo Battery | `BatteryMediumConfig` | `capacity` | 40 kJ (same class, different def) |

## Known Patch Targets (build 587362 U59)

### Dischargers (移动电池放电设备)

| Building | Config Class | Field | Default | Patch Method |
|---|---|---|---|---|
| Large Discharger | `LargeElectrobankDischargerConfig.CreateBuildingDef` | `GeneratorWattageRating` | 480 | Postfix on CreateBuildingDef |
| Compact Discharger | `CompactElectrobankDischargerConfig.CreateBuildingDef` | `GeneratorWattageRating` | 60 | Postfix on CreateBuildingDef |
| Runtime fallback | `ElectrobankDischarger.OnSpawn` | `building.Def.GeneratorWattageRating` | — | Postfix on OnSpawn, check def.Name.Contains("Large") |

### OnSpawn Runtime Patch Pattern

```csharp
[HarmonyPatch]
public static class DischargerSpawnPatch
{
    static IEnumerable<MethodBase> TargetMethods()
    {
        var type = AccessTools.TypeByName("ElectrobankDischarger");
        if (type != null)
        {
            var method = AccessTools.Method(type, "OnSpawn");
            if (method != null) yield return method;
        }
    }

    static void Postfix(object __instance)
    {
        var building = (__instance as KMonoBehaviour)?.GetComponent<BuildingComplete>();
        if (building?.Def == null) return;

        string defName = building.Def.Name;
        float target = defName.Contains("Large") ? 4000f : 2000f;
        building.Def.GeneratorWattageRating = target;
    }
}
```

## Log Verification

Check Player.log at:
```
C:/Users/Administrator/AppData/LocalLow/Klei/Oxygen Not Included/Player.log
```

Success looks like:
```
[ModName] Found LargeElectrobankDischargerConfig.CreateBuildingDef!
[ModName] GeneratorWattageRating: 480 -> 4000 (via Config patch)
[ModName] Spawn: LargeElectrobankDischarger GeneratorWattageRating 480 -> 4000
```
