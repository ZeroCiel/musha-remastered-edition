# CleanHydroponicDisease Mod — 液培砖自动清病菌

**Date:** 2026-07-05
**Game version:** U59-737790
**Mod path:** `D:\Backup\Documents\Klei\OxygenNotIncluded\mods\Local\CleanHydroponicDisease\`

## Problem

Deconstructing Hydroponic Farm Tiles releases diseased fertilizer content into surrounding water. The disease is NOT on piped liquid — pipes show no liquid, but the farm tile's Storage has diseased content items (fertilizer particles). These particles carry `PrimaryElement.DiseaseCount` that gets released as `Pickupable` objects during deconstruction.

## Approach

**Game.LateUpdate periodic scan** — not intercepting OnCleanUp (problematic for Storage items):

```csharp
var lateUpdate = typeof(Game).GetMethod("LateUpdate",
    BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
harmony.Patch(lateUpdate, postfix: new HarmonyMethod(typeof(Mod), nameof(OnLateUpdate)));

private static void OnLateUpdate()
{
    if (Game.Instance == null) return;
    if (Time.frameCount % 30 != 0) return; // every ~0.5s

    var buildings = Object.FindObjectsOfType<BuildingComplete>();
    foreach (var building in buildings)
    {
        if (building.Def.PrefabID != "HydroponicFarm") continue;  // <- prefab ID is "HydroponicFarm"
        
        var storage = building.GetComponent<Storage>();
        if (storage == null) continue;

        foreach (var item in storage.items)
        {
            if (item == null) continue;
            var pe = item.GetComponent<PrimaryElement>();
            if (pe != null && pe.DiseaseCount > 0)
                ClearDisease(pe);  // reflection-based setter
        }
    }
}
```

## Key Discoveries

1. **Prefab ID is `"HydroponicFarm"`** — not `"HydroponicFarmTile"` or `"WideFarmTile"`. Use `building.Def.PrefabID` to check.

2. **Disease is on Storage items (fertilizer particles), not on the building's own PrimaryElement** — clearing `building.GetComponent<PrimaryElement>().DiseaseCount` has NO effect on content spill.

3. **`PrimaryElement.DiseaseCount` is read-only** in C# — must use reflection to write:
   ```csharp
   var prop = typeof(PrimaryElement).GetProperty("DiseaseCount",
       BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
   if (prop != null && prop.CanWrite) prop.SetValue(pe, 0);
   ```

4. **Custom KMonoBehaviour.OnCleanUp override** — does NOT work for clearing Storage content disease because the disease carriers are created as new Pickupable objects during the Storage cleanup process, not pre-existing in the Storage items list at the time OnCleanUp fires. The Game.LateUpdate approach is more reliable.

5. **Throttling** — `Time.frameCount % 30` (check every ~0.5s) is safe. `FindObjectsOfType<BuildingComplete>()` is fine because building count is typically < 500.
