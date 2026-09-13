# SmallDischargerAnywhere Mod

## Goal

Make `SmallElectrobankDischargerConfig` (袖珍放电器) placeable anywhere in mid-air,
no ground tile required. Blueprint placement + post-build validity check.

## First Attempt: BuildLocationRule Only

```csharp
[HarmonyPatch(typeof(SmallElectrobankDischargerConfig), "CreateBuildingDef")]
public static void Postfix(BuildingDef __result)
{
    SetField(__result, "BuildLocationRule", BuildLocationRule.Anywhere);
}
```

**Result:** Blueprint can be placed anywhere. After completion, "没有地面砖块" popup appears.
Building still works but looks wrong.

## Second Attempt: Patch OccupyArea Methods

Tried to patch: `OccupyArea.IsValidTileLocation`, `OccupyArea.SetOccupyGridSpace`,
`OccupyArea.RefreshCellOccupied`, `Building.ForcePermanentCheck`

**Result:** ALL of these crash with:
```
HarmonyLib.HarmonyException ---> ArgumentException: Undefined target method
```
→ Mod DLL fails to load → ONI auto-disables it.

## Third Attempt: Patch BuildingComplete_OnSpawn + BuildingComplete_OnInit

These methods exist in U59 (confirmed by DLL string search).
Postfix checks `PrefabID == "SMALLELECTROBANKDISCHARGER"` and destroys `OccupyArea`.

## Fourth Attempt: Game.LateUpdate Cleanup (CURRENT)

```csharp
[HarmonyPatch(typeof(Game), "LateUpdate")]
public static void Postfix()
{
    if (Time.frameCount % 60 != 0) return;
    // Find only BuildingComplete, not all GameObjects
    var buildings = Object.FindObjectsOfType<BuildingComplete>();
    foreach (var b in buildings)
        if (b.Def.PrefabID == "SMALLELECTROBANKDISCHARGER")
            Object.DestroyImmediate(b.GetComponent<OccupyArea>());
}
```

**WARNING:** Only scan BuildingComplete, NOT GameObject. Scanning all GameObjects
in LateUpdate exhausts memory → `OutOfMemoryException: Out of memory` in unrelated
NavGrid constructor.

## Key Takeaways

- PrefabID constant is `SMALLELECTROBANKDISCHARGER` (uppercase, no separator)
- ElectrobankDischarger has NO DecorProvider → deleting OccupyArea is safe
- BuildingComplete_OnSpawn/OnInit exist but Game.LateUpdate is more reliable
- BOTH mod.yaml AND mod_info.yaml are REQUIRED (user corrected this multiple times)
