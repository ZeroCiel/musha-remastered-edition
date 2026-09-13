# Building Capacity Modification — Working Approach (U59-737790)

## Summary

The **only reliable way** to change creature delivery point / fish feeder capacity in ONI U59+ is:

1. Patch `Game.OnPrefabInit`
2. Start a coroutine that repeats every 1s for ~20s
3. Find target buildings by component or name
4. Modify `Storage.capacityKg` directly (NOT `IUserControlledCapacity.UserMaxCapacity`)

## The Working Code

```csharp
using HarmonyLib;
using System;
using System.Collections;
using UnityEngine;

namespace BiggerCritterDropOff
{
    [HarmonyPatch(typeof(Game), "OnPrefabInit")]
    public static class GameInitPatch
    {
        static void Postfix(Game __instance)
        {
            __instance.StartCoroutine(CapacityWatcher());
        }

        static IEnumerator CapacityWatcher()
        {
            yield return new WaitForSeconds(2f);
            for (int i = 0; i < 20; i++)
            {
                try { SetAllCapacities(); }
                catch { }
                yield return new WaitForSeconds(1f);
            }
        }

        static void SetAllCapacities()
        {
            foreach (var go in Resources.FindObjectsOfTypeAll<GameObject>())
            {
                // Option A: component-based (reliable, catches name suffixes)
                if (go.GetComponent<CreatureDeliveryPoint>() != null ||
                    go.GetComponent<CreatureFeeder>() != null ||
                    HasComponentByName(go, "FishDeliveryPoint"))
                {
                    var storage = go.GetComponent<Storage>();
                    if (storage != null) storage.capacityKg = 1000f;
                }
            }
        }

        static bool HasComponentByName(GameObject go, string typeName)
        {
            foreach (var c in go.GetComponents(typeof(Component)))
                if (c != null && c.GetType().Name == typeName) return true;
            return false;
        }
    }
}
```

## Why This Works

- `IUserControlledCapacity.UserMaxCapacity` is a **wrapper** that gets overwritten by game state machine after `OnSpawn`
- `Storage.capacityKg` is the **actual field** the storage system reads
- The coroutine catches both existing and newly-built buildings
- Using `GetComponent<T>()` is more reliable than name-based matching (handles name suffixes like `Complete`)

## Related Files

- Source: `D:\Backup\Documents\Klei\OxygenNotIncluded\mods\local\BiggerCritterDropOff\BiggerCritterDropOff.cs`
- Backup: `.bak` files in same directory
- Workshop ID for original mod: N/A (custom local mod)
