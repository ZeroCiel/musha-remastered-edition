# Coral Min Temp Debug Notes (U59-737790)

## Summary
Attempting to modify minimum growth temperature of OxyCoral (氧齿珊瑚) and PlanktonCoral (浮游珊瑚) from default to 15°C in U59 (build 737790).

## Key findings

### 1. Config classes still exist
- `OxyCoralConfig, Assembly-CSharp` — found by Type.GetType()
- `PlanktonCoralConfig, Assembly-CSharp` — found by Type.GetType()
- `CreatePrefab` method still exists on both — Harmony patch registers successfully

### 2. `PlantablePlot.lethalLowTemp` does NOT exist in U59
The `lethalLowTemp` and `warningLowTemp` float fields that existed on `PlantablePlot` in older versions have been removed in U59. Reflection returns null.

### 3. `Crop.lethalLowTemp` also does NOT exist in U59
Checking the `Crop` component inside `HarvestDesignatable` — these fields are also missing.

### 4. Actual temperature field location is unknown
A dump of all components and float fields on the coral prefab GameObject is needed to discover where the temperature lives in U59.

### 5. The temperature value might be hardcoded in CreatePrefab
In U59, plant temperatures might be set directly inside `CreatePrefab` body rather than read from config fields. If so, the only way to change it is to transpile/patch the method body itself (modify IL) or find the constant and replace it.

## Diagnostics approach
Replace Postfix with a comprehensive dump of all components and float fields on the prefab GameObject:
```csharp
public static void Postfix_CreatePrefab(ref GameObject __result)
{
    if (__result == null) return;
    string output = "[CoralMinTemp] === GameObject dump ===\n";
    foreach (var comp in __result.GetComponents<Component>())
    {
        if (comp == null) continue;
        output += $"  Component: {comp.GetType().FullName}\n";
        foreach (var f in comp.GetType().GetFields(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
        {
            if (f.FieldType == typeof(float))
                output += $"    Field {f.Name} = {f.GetValue(comp)}\n";
        }
    }
    Debug.Log(output);
}
```

## mod.yaml / mod_info.yaml configuration that works
The mod had "expired/outdated" flag until the correct yaml configuration was applied:

**mod.yaml** (keep minimal — no lists/arrays):
```yaml
title: "Coral Min Temp 15°C"
description: "修改珊瑚（氧齿珊瑚、浮游珊瑚）最低生长温度为15°C"
staticID: CoralMinTemp15C
```

**mod_info.yaml** (version metadata only):
```yaml
minimumSupportedBuild: 587362
version: 1.0.0
APIVersion: 2
```

## Lesson: "expired/outdated" troubleshooting
1. Player.log shows `Recoverable parse error` in mod.yaml — remove list/array fields
2. Player.log shows no error but still outdated — check mod_info.yaml format is YAML, not JSON
3. Still outdated — check if both mod.yaml AND mod_info.yaml exist (delete one)
4. Reference: FlydoMiningHotfix has only 3 fields in mod.yaml + 3 fields in mod_info.yaml
