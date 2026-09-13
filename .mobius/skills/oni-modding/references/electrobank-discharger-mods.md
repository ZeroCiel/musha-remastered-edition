# Electrobank Discharger Power Modding (U59-737790, build 587362)

## Class Names (binary-hardcoded in Assembly-CSharp.dll)

| Building | Config Class | Runtime Class | Original Wattage |
|----------|-------------|---------------|------------------|
| Large Discharger | `LargeElectrobankDischargerConfig` | `ElectrobankDischarger` | 480W |
| Small/Compact Discharger | `SmallElectrobankDischargerConfig` | `ElectrobankDischarger` | 60W |

**NOT** `CompactElectrobankDischargerConfig` — that class does NOT exist.

## Field to Patch

```csharp
buildingDef.GeneratorWattageRating  // Output power (generator side, NOT EnergyConsumptionWhenActive)
```

Discharger is a **generator** (outputs power), not a consumer — `EnergyConsumptionWhenActive` is 0 and irrelevant.

## Harmony Pattern That Works (U59-737790)

```csharp
[HarmonyPatch]
public static class LargeDischargerConfigPatch
{
    static IEnumerable<MethodBase> TargetMethods()
    {
        var configType = AccessTools.TypeByName("LargeElectrobankDischargerConfig");
        if (configType != null)
        {
            var method = AccessTools.Method(configType, "CreateBuildingDef");
            if (method != null) yield return method;
        }
    }

    static void Postfix(object __instance, ref object __result)
    {
        var def = __result as BuildingDef;
        if (def == null) return;
        def.GeneratorWattageRating = 4000f;  // your target value
    }
}
```

For small/compact, same pattern with `SmallElectrobankDischargerConfig`.

## Spawn Patch (for existing buildings)

Use `building.prefabid.ToString().Contains("Large")` to distinguish large vs small:
```csharp
string prefabId = building.prefabid?.ToString() ?? "";
float target = prefabId.Contains("Large") ? 4000f : 2000f;
```

**DO NOT** use `building.Def.Name` — it's localized and unreliable for type checking.

## Known Pitfalls

### 1. Mod Crash → Auto-Disable
If Harmony throws `Undefined target method` on load (wrong class name), ONI marks the mod as **broken**. Next launch:
- DLL is **not loaded** at all (no `Loading MOD dll:` in Player.log)
- Must manually re-enable in Mod menu (click the disabled mod)
- Fix the source, rebuild, copy DLL, re-enable in Mod menu

### 2. DLL Deployment
Game loads from `mods/Local/<ModName>/<ModName>.dll` (the **root** of the mod folder).
`bin/Release/<ModName>.dll` is the build output; it must be copied to the root.

### 3. Backup DLL in Same Folder Breaks Load
A file like `LargeDischarger2000W_4000W.dll` in the same mod directory gets loaded as a **second mod** with the same staticID → crash. Keep backups OUTSIDE the mod folder.

### 4. `[HarmonyPatch]` vs `Game.OnPrefabInit` Coroutine
On U59-737790 (build 587362):
- `[HarmonyPatch]` with `TargetMethods()` → **works** for config classes
- `Game.OnPrefabInit` Harmony patch → **does NOT trigger**
- If Harmony patching fails entirely, use coroutine via `Global.Instance.StartCoroutine()`

### 5. Rebuild After Source Change
`dotnet build -c Release` may serve a cached DLL. Use `dotnet clean && dotnet build -c Release --force` to force recompilation. Verify by checking file size/timestamp.
