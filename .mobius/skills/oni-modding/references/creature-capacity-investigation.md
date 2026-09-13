# CreatureDeliveryPoint Capacity Investigation (June 2026)

## The Problem

User wants to increase CritterDropOff capacity from 40 to 1000 for all variants:
- **CreatureDeliveryPoint** (地上小动物放生点) — original 40 critters
- **FishDeliveryPoint** (鱼类放生点) — original 20 kg
- **CreatureFeeder** (喂食器) — original storage capacity

## Key Discovery: Different Buildings, Different Mechanisms

### FishDeliveryPoint & CreatureFeeder ✅
These use **`Storage.capacityKg`** as their capacity mechanism. A coroutine that sets `Storage.capacityKg = 1000f` on `Game.OnPrefabInit` works.

### CreatureDeliveryPoint ❌ (NOT via Storage)
Component dump of an in-game CreatureDeliveryPoint showed:

```
IUserControlledCapacity: False        # NOT implemented on the building itself
Storage.capacityKg = 20000             # Already high — mass limit, not critter count
Component: BaggableCritterCapacityTracker  ← THIS controls capacity
```

`BaggableCritterCapacityTracker` fields:
```
<creatureLimit>k__BackingField = 40     # Backing field for the property
maximumCreatures = 40                    # Same value via a different field
IUserControlledCapacity.UserMaxCapacity = 40  # Tracker implements this interface!
```

The tracker **implements `IUserControlledCapacity`**, but the building (CreatureDeliveryPoint) does NOT. The interface is on the component, not the building itself.

## Working Solution for CreatureDeliveryPoint

A three-layer approach:

```csharp
// Layer 1: Intercept the getter — any code reading creatureLimit gets 1000
[HarmonyPatch(typeof(BaggableCritterCapacityTracker), "get_creatureLimit")]
public static class CreatureLimitGetterPatch
{
    static void Postfix(ref int __result)
    {
        if (__result < 900) __result = 1000;
    }
}

// Layer 2: Set at spawn time
[HarmonyPatch(typeof(BaggableCritterCapacityTracker), "OnSpawn")]
public static class TrackerOnSpawnPatch
{
    static void Postfix(BaggableCritterCapacityTracker __instance)
    {
        var field = __instance.GetType().GetField("maximumCreatures",
            BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        if (field != null) field.SetValue(__instance, 1000);

        var cap = __instance as IUserControlledCapacity;
        if (cap != null) cap.UserMaxCapacity = 1000;
    }
}

// Layer 3: Coroutine fallback for already-spawned buildings
[HarmonyPatch(typeof(Game), "OnPrefabInit")]
public static class GameInitPatch
{
    static void Postfix(Game __instance)
    {
        __instance.StartCoroutine(CapacityWatcher());
    }
    // ... coroutine finds all CreatureDeliveryPoint → gets BaggableCritterCapacityTracker → sets fields
}
```

## Failed Approaches (10+)

| # | Approach | Result |
|---|----------|--------|
| 1 | `OnSpawn` Postfix → `IUserControlledCapacity.UserMaxCapacity` | Value overwritten |
| 2 | `ConfigureBuildingTemplate` Postfix → `go.GetComponent<Storage>()` | Wrong `go` (StorageLocker) |
| 3 | `DoPostConfigureComplete` Postfix | Value overwritten |
| 4 | `CreatureDeliveryPoint.get_UserMaxCapacity` patch | Undefined target (interface dispatch) |
| 5 | `IUserControlledCapacity.get_UserMaxCapacity` patch | BadImageFormatException (no body) |
| 6 | `Game.OnPrefabInit` coroutine → set `Storage.capacityKg` | No effect on critter count |
| 7 | `Game.OnPrefabInit` coroutine → set `IUserControlledCapacity` on building | No effect (building doesn't implement it) |
| 8 | `Resources.FindObjectsOfTypeAll<GameObject>()` name match + Storage | Only works for FishDeliveryPoint |
| 9 | `Resources.FindObjectsOfTypeAll<CreatureDeliveryPoint>()` → GetComponent<Storage>() | Storage exists but capacityKg=20000, not the critter limit |
| 10 | Setting `BaggableCritterCapacityTracker` fields directly + interface via coroutine | Intermittent — gets overwritten by Sim1000ms |

## Key Lessons

1. **Always component-dump unknown buildings** before designing patches
2. `CreatureDeliveryPoint` and `FishDeliveryPoint` are fundamentally different — same UI purpose, different mechanics
3. `BaggableCritterCapacityTracker` is the real capacity controller for creature buildings
4. The tracker has THREE capacity fields that all need to be set: `creatureLimit` (auto-property), `maximumCreatures` (field), `UserMaxCapacity` (interface property)
5. **Patching the getter** (`get_creatureLimit`) is the most reliable approach — it intercepts all reads regardless of how the value is set
