# SmallDischargerAnywhere — Build Location Anywhere

## Mod Info

- **staticID:** SmallDischargerAnywhere
- **Target:** SmallElectrobankDischargerConfig (袖珍放电器)
- **Purpose:** Allow building the compact discharger without floor support

## Key Fix

Patch `SmallElectrobankDischargerConfig.CreateBuildingDef`:

```csharp
[HarmonyPatch(typeof(SmallElectrobankDischargerConfig), "CreateBuildingDef")]
public static class CreateDefPatch
{
    static void Postfix(BuildingDef __result)
    {
        if (__result == null) return;
        var f = typeof(BuildingDef).GetField("BuildLocationRule",
            BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        if (f != null)
            f.SetValue(__result, BuildLocationRule.Anywhere);
    }
}
```

## ⚠ OccupyArea.IsValidTileLocation — DOES NOT EXIST in U59

Do NOT try to patch `OccupyArea.IsValidTileLocation` — the method does NOT exist in U59-737790. Harmony will throw:

```
HarmonyLib.HarmonyException: Patching exception in method null
  ---> System.ArgumentException: Undefined target method for patch method
  static System.Void OccupyCheckPatch::Postfix(OccupyArea, System.Boolean&)
```

This crashes the ENTIRE mod load — the mod won't even initialize.

## Post-Build Ground Check Issue

Even with `BuildLocationRule.Anywhere`, the building may show a yellow warning "没有地面砖块" (no ground tile) after construction. This is from `OccupyArea`'s internal occupancy validation which is NOT callable from Harmony in U59.

**This warning is cosmetic** — the building works fine in mid-air. No known Harmony fix for this in U59.

## Mod Files

```
mods/Local/SmallDischargerAnywhere/
├── SmallDischargerAnywhere.cs
├── SmallDischargerAnywhere.csproj  
├── SmallDischargerAnywhere.dll
├── mod.yaml          # supportedContent: ALL
└── mod_info.yaml     # minimumSupportedBuild: 737790, version: 1
```
