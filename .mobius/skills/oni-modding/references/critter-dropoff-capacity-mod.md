# CritterDropOff / CreatureDeliveryPoint Capacity Mod — U59 Status

## Problem

Old `BiggerCritterDropOff` mod patches `CritterDropOff.OnSpawn` — but `CritterDropOff` was **renamed to `CreatureDeliveryPoint`** in ONI U59+. The old DLL crashes on load (Harmony can't find target method).

## Correct but Non-Working Approach

The following code **compiles, loads without errors, and runs the Postfix** — but the capacity change does NOT take effect (value is overwritten after OnSpawn):

```csharp
using HarmonyLib;
using System;

namespace BiggerCritterDropOff
{
    [HarmonyPatch(typeof(CreatureDeliveryPoint), "OnSpawn")]
    public static class DeliveryPointPatch
    {
        static void Postfix(object __instance)
        {
            try
            {
                var capacity = __instance as IUserControlledCapacity;
                if (capacity != null)
                {
                    capacity.UserMaxCapacity = 1000;
                }
            }
            catch (Exception e)
            {
                Debug.LogError("[Mod] " + e.Message);
            }
        }
    }

    // Same for fish feeders
    [HarmonyPatch(typeof(CreatureFeeder), "OnSpawn")]
    public static class FeederPatch
    {
        static void Postfix(object __instance)
        {
            var capacity = __instance as IUserControlledCapacity;
            if (capacity != null)
            {
                capacity.UserMaxCapacity = 1000;
            }
        }
    }
}
```

## Tried-and-Failed Approaches (U59-737790, June 2026)

| Approach | Result |
|----------|--------|
| `[HarmonyPatch(typeof(CreatureDeliveryPoint), "OnSpawn")]` Postfix | No crash, but no effect — capacity stays at default (20) |
| `[HarmonyPatch(typeof(CritterDropOffConfig), "ConfigureBuildingTemplate")]` Postfix | Crashes — `go` param is a StorageLocker, not the target |
| `[HarmonyPatch(typeof(CreatureFeederConfig), "ConfigureBuildingTemplate")]` Postfix | Crashes — `go` is a StorageLocker, NPE |
| Reflection on `maxCapacity` field | No such field exists — capacity is managed via `IUserControlledCapacity` interface only |

## Attempted Alternatives (June 2026 session — all failed)

### 1. Patch `DoPostConfigureComplete` on config classes

```csharp
[HarmonyPatch(typeof(CreatureDeliveryPointConfig), "DoPostConfigureComplete")]
static void Postfix(GameObject go)
{
    var capacity = go.GetComponent<IUserControlledCapacity>();
    if (capacity != null) { capacity.UserMaxCapacity = 1000; }
}
```

**Result**: Compiles and loads fine. **But capacity still at default 20.** `DoPostConfigureComplete`'s `go` parameter correctly has `IUserControlledCapacity` component, but setting it here is also overwritten later.

### 2. Patch interface method `IUserControlledCapacity.get_UserMaxCapacity`

```csharp
[HarmonyTargetMethod]
static MethodBase TargetMethod()
{
    var iface = typeof(IUserControlledCapacity);
    var prop = iface.GetProperty("UserMaxCapacity");
    return prop.GetGetMethod(); // abstract interface method!
}
static void Postfix(IUserControlledCapacity __instance, ref float __result)
{
    __result = 1000;
}
```

**Result**: **CRASH** — `BadImageFormatException: Method has no body`. Harmony cannot patch abstract interface methods. Only concrete implementations can be patched, but `CreatureDeliveryPoint` doesn't have its own `get_UserMaxCapacity` — the interface method is implemented via explicit interface implementation in the base class.

### 3. Patch concrete class `get_UserMaxCapacity` on `CreatureDeliveryPoint`

```csharp
[HarmonyPatch(typeof(CreatureDeliveryPoint), "get_UserMaxCapacity")]
```

**Result**: **CRASH** — `Undefined target method for patch method`. `CreatureDeliveryPoint` does NOT implement `get_UserMaxCapacity` as a separate method — it's inherited through the `IUserControlledCapacity` interface via a shared base class method. Harmony can't locate the method by name on this derived class.

### 4. FishDeliveryPoint is a separate class

`FishDeliveryPoint` (fish delivery point) is **NOT** a subclass of `CreatureDeliveryPoint`. It's a separate runtime class with its own `FishDeliveryPointConfig`. Both inherit from different bases but share the `IUserControlledCapacity` interface.

### 5. Patch `Game.OnPrefabInit` + coroutine to set capacities after initialization (UNTESTED)

This was the final approach — instead of patching the building's lifecycle, patch game init to iterate all existing instances:

```csharp
[HarmonyPatch(typeof(Game), "OnPrefabInit")]
public static class GameInitPatch
{
    static void Postfix(Game __instance)
    {
        __instance.StartCoroutine(SetCapacitiesLater());
    }
    
    static IEnumerator SetCapacitiesLater()
    {
        yield return new WaitForSeconds(1f);
        foreach (var delPt in Resources.FindObjectsOfTypeAll<CreatureDeliveryPoint>())
        {
            var cap = delPt as IUserControlledCapacity;
            if (cap != null) cap.UserMaxCapacity = 1000f;
        }
        // Same for FishDeliveryPoint (via reflection) and CreatureFeeder
    }
}
```

**Result**: Compiled successfully but was not tested in-game this session. **May still fail** if the building's own initialization happens after the 1-second delay.

## ✅ THE ONE WORKING APPROACH: Storage.capacityKg via coroutine

After all Harmony Postfix approaches failed, the **only thing that actually worked** was:

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
            SetAllCapacities();
            yield return new WaitForSeconds(1f);
        }
    }

    static void SetAllCapacities()
    {
        foreach (var go in Resources.FindObjectsOfTypeAll<GameObject>())
        {
            string name = go.name;
            if (name.Contains("CreatureDeliveryPoint") || 
                name.Contains("FishDeliveryPoint") ||
                name.Contains("CreatureFeeder"))
            {
                var storage = go.GetComponent<Storage>();
                if (storage != null)
                    storage.capacityKg = 1000f;
            }
        }
    }
}
```

**Key insight**: `IUserControlledCapacity.UserMaxCapacity` is a layer on top of the actual `Storage` component. Even when `UserMaxCapacity` is overwritten after `OnSpawn`, modifying `Storage.capacityKg` directly works because the storage capacity check reads from this field.

The coroutine runs for ~20 seconds after game init, catching buildings that are constructed after the first scan. This handles both existing and newly-built delivery points.

Target classes:
- `CreatureDeliveryPoint` — small creature drop-off (地上小动物放生点)
- `FishDeliveryPoint` — aquatic creature drop-off (鱼类放生点)
- `CreatureFeeder` — fish feeder (鱼类喂食器)

## Failed approaches (U59-737790, June 2026)

| Approach | Result |
|----------|--------|
| `[HarmonyPatch(typeof(CreatureDeliveryPoint), "OnSpawn")]` Postfix | No crash, no effect — capacity stays at 20 |
| `[HarmonyPatch(typeof(CritterDropOffConfig), "ConfigureBuildingTemplate")]` Postfix | Crashes — `go` param is a StorageLocker, not the target |
| `[HarmonyPatch(typeof(CreatureFeederConfig), "ConfigureBuildingTemplate")]` Postfix | Crashes — same StorageLocker issue |
| Reflection on `maxCapacity` field | No such field exists |
| Patch `IUserControlledCapacity.get_UserMaxCapacity` (interface) | **CRASH**: `BadImageFormatException: Method has no body` |
| Patch concrete `CreatureDeliveryPoint.get_UserMaxCapacity` | **CRASH**: `Undefined target method` — inherited via interface dispatch |
| `DoPostConfigureComplete` on config classes | No crash, no effect |
| `Game.OnPrefabInit` + coroutine setting `IUserControlledCapacity.UserMaxCapacity` | Compiled, ran, but no effect — value overwritten |

## Additional findings

1. **`IUserControlledCapacity` is an INTERFACE** — Harmony cannot patch interface methods directly. Causes `BadImageFormatException`.
2. **`FishDeliveryPoint` is NOT a subclass of `CreatureDeliveryPoint`**. Separate classes. Both implement `IUserControlledCapacity` independently. `FishDeliveryPoint` exists in Assembly-CSharp.dll as an internal type.
3. **`UserMaxCapacity` set in `OnSpawn` Postfix is OVERWRITTEN** — the setter runs without error, but by the time the building UI is visible, capacity is back to 20. Likely overwritten by state machine init or save data reapplication.

## Conclusion

**Don't bother with `IUserControlledCapacity.UserMaxCapacity` in U59+.** It's overwritten after every initialization path. The only reliable approach is to modify `Storage.capacityKg` on the building's GameObject via a coroutine that runs after the building is fully initialized.
