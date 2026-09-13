# BiggerCritterDropOff Capacity Mod — Session 2 (June 19-20, 2026)

## Goal
Increase creature delivery point capacity from 20 to 1000 for both FishDeliveryPoint and CreatureDeliveryPoint.

## What Worked
- **FishDeliveryPoint** (鱼类放生点): ✅ Modified `Storage.capacityKg` via coroutine → 1000
- **CreatureFeeder** (喂食器): ✅ Same approach → 1000
- **CreatureDeliveryPoint** (小动物放归点): ❌ NOT working — all approaches failed

## Failed Approaches for CreatureDeliveryPoint

| # | Approach | Result |
|---|----------|--------|
| 1 | `CreatureDeliveryPoint.OnSpawn` Postfix → `IUserControlledCapacity.UserMaxCapacity = 1000` | Compiled, no crash, but capacity stayed at 20 |
| 2 | `CreatureDeliveryPointConfig.DoPostConfigureComplete` Postfix → Storage.capacityKg | Compiled, no crash, capacity at 20 |
| 3 | `CreatureFeederConfig.ConfigureBuildingTemplate` Postfix → crashed (go was StorageLocker, NPE) | ❌ CRASH |
| 4 | `Game.OnPrefabInit` + coroutine → iterate Resources.FindObjectsOfTypeAll, name-contains check + Storage.capacityKg | Logged "Applied capacities", still 20 after reload |
| 5 | Coroutine + `GetComponent<IUserControlledCapacity>()` via interface | Still 20 |
| 6 | Coroutine + `GetComponentsInChildren<Storage>()` | Still 20 |
| 7 | `CreatureDeliveryPointConfig.ConfigureBuildingTemplate` Postfix → Storage.capacityKg on template | Still 20 |

## Key Discovery
- `ConfigureBuildingTemplate`'s `go` parameter is NOT always the target building. `CreatureFeederConfig.ConfigureBuildingTemplate` received a **StorageLocker** GameObject, not the feeder.
- `DoPostConfigureComplete` is the **safer** hook — its `go` always IS the target building.
- Even `DoPostConfigureComplete` didn't work for CreatureDeliveryPoint's capacity (but it works for removing PressureVulnerable from WideFarmTile).

## Working Code (FishDeliveryPoint only)
```csharp
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
            foreach (var go in Resources.FindObjectsOfTypeAll<GameObject>())
            {
                if (go.name.Contains("FishDeliveryPoint") ||
                    go.name.Contains("CreatureFeeder"))
                {
                    var storage = go.GetComponent<Storage>();
                    if (storage != null) storage.capacityKg = 1000f;
                }
            }
            yield return new WaitForSeconds(1f);
        }
    }
}
```

## Related
- 2836775275 = AutomaticOilRefinery workshop mod (移植后产出从5kg改为10kg)
- 3309623145 = 房间大小修改 workshop mod
