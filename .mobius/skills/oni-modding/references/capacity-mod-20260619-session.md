# Capacity Mod Session — 2026-06-19 (continued in later session)

## What was attempted

User requested: convert old `BiggerCritterDropOff` mod (23年) to work with current ONI. The old mod patched `CritterDropOff.OnSpawn` with `IUserControlledCapacity.UserMaxCapacity = 1000`.

## Steps taken

1. **Initial compilation with new ONI libs** — compiled fine, loaded fine, but the Harmony TargetMethod returned null because `CritterDropOff` class was renamed.
2. **Class rename discovered**: `CritterDropOff` → `CreatureDeliveryPoint` (confirmed via binary string search in Assembly-CSharp.dll). `CritterDropOff.OnSpawn` doesn't exist anymore.
3. **Fix 1**: Changed to `[HarmonyPatch(typeof(CreatureDeliveryPoint), "OnSpawn")]` + `IUserControlledCapacity` cast. Compiled, loaded, ran — **capacity still at 20**.
4. **Fix 2**: Added `CreatureFeeder` parallel patch. Same result — no effect.
5. **Fix 3**: Added FishDeliveryPoint via reflection (dynamic TargetMethod). Loading crash — `TypeLoadException` from assembly scanning.
6. **Fix 4**: Switched to `ConfigureBuildingTemplate` Postfix on config classes (`CreatureDeliveryPointConfig`, `CreatureFeederConfig`). **Crashed** — `GameObject go` param was a `StorageLocker`, not the target building. `StorageLocker.set_UserMaxCapacity` threw NPE internally.
7. **Fix 5**: Tried `DoPostConfigureComplete` Postfix instead. Compiled fine, `IUserControlledCapacity` found correctly on the `GameObject go`... but **capacity still at 20**.
8. **Fix 6**: Tried `[HarmonyTargetMethod]` on `IUserControlledCapacity.get_UserMaxCapacity` interface getter. **CRASH**: `BadImageFormatException: Method has no body` — Harmony cannot patch abstract interface methods.
9. **Fix 7**: Tried `[HarmonyPatch(typeof(CreatureDeliveryPoint), "get_UserMaxCapacity")]`. **CRASH**: `Undefined target method` — `CreatureDeliveryPoint` doesn't have its own `get_UserMaxCapacity`, it's inherited via the interface.
10. **Fix 8**: `[HarmonyPatch(typeof(Game), "OnPrefabInit")]` + coroutine to wait 1s then iterate all instances via `Resources.FindObjectsOfTypeAll`. **Compiled and tested — DID NOT WORK**. Log showed "Applied capacities to all existing buildings" but capacity was still 20 in-game.
11. **Fix 9**: Extended coroutine to retry every 1s for 30s, plus one more at 35s, with multiple fallback methods (interface, reflection field, property, setter). **DID NOT WORK**.

## SECOND SESSION (later same day) — BREAKTHROUGH

### Fix 10 — THE WORKING APPROACH

After 9 failed approaches, the user asked if the Storage approach could work. The **key insight**: the actual storage capacity is stored on `Storage.capacityKg`, NOT on `IUserControlledCapacity.UserMaxCapacity`. The `IUserControlledCapacity` property was just a view/interface that wrote to a backing field that gets overwritten.

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

**Result: ✅ EFFECTIVE!** — CreatureDeliveryPoint, FishDeliveryPoint, and CreatureFeeder all received 1000 capacity.

### Key insight
The actual physical capacity in ONI is stored in `Storage.capacityKg`. The `IUserControlledCapacity.UserMaxCapacity` is just an interface overlay that maps to this (via a virtual property), but its setter is apparently bypassed/overwritten by the building's own initialization chain. Going directly to `Storage.capacityKg` sidesteps this.

## Key technical discoveries

### Storage.capacityKg is the real capacity field
- `Storage` component has a public field `capacityKg` (float)
- This is the actual physical capacity that determines how much mass the building can hold
- `IUserControlledCapacity` is just a UI/interface layer on top of this
- Setting `Storage.capacityKg` via coroutine AFTER all initialization is done works reliably

### FishDeliveryPoint is a separate class
- `FishDeliveryPoint` (鱼类放生点) is NOT a subclass of `CreatureDeliveryPoint`
- Both implement `IUserControlledCapacity` independently
- `FishDeliveryPoint` is in `Assembly-CSharp` but may not be public — compilation with `typeof(FishDeliveryPoint)` gave CS0246
- Its string exists in the DLL but the type might be internal/not exported

### Harmony cannot patch interface methods
- `IUserControlledCapacity.get_UserMaxCapacity` is an abstract interface method
- Harmony throws `BadImageFormatException: Method has no body`
- Only concrete implementations can be patched
- `CreatureDeliveryPoint` doesn't have its own explicit method — the property is inherited

### Capacity is overwritten late in initialization
- Even when `OnSpawn` Postfix successfully calls `capacity.UserMaxCapacity = 1000`, the value is back to 20 by the time the building appears
- Same for `DoPostConfigureComplete` Postfix and `Game.OnPrefabInit` coroutine using the interface
- The real fix: wait until after ALL initialization (2s+), then set `Storage.capacityKg` directly (not through the interface)

### ConfigureBuildingTemplate's GameObject parameter
- `ConfigureBuildingTemplate(GameObject go)` is called for building configs BUT the `go` parameter is NOT always the target building's GameObject
- For `CreatureFeederConfig.ConfigureBuildingTemplate`, the `go` was a `StorageLocker` (different building altogether)
- This makes `ConfigureBuildingTemplate` unreliable for patching specific buildings

### Final conclusion
**Don't use `IUserControlledCapacity` to modify building capacity in U59+.** Use `Storage.capacityKg` on the building's GameObject via a coroutine that runs after game initialization is complete.

## References in log

- Error: `Method static System.Reflection.MethodBase BiggerCritterDropOff.BiggerDropOffPatch::TargetMethod() returned an unexpected result: null`
- Error: `BadImageFormatException: Method has no body`
- Error: `Undefined target method for patch method static System.Void BiggerCritterDropOff.DeliveryPointGetterPatch::Postfix(System.Single& __result)`
- Log success: `BiggerCritterDropOff: Successfully loaded from path 'root' with content 'DLL'.`
- Log success (config patch): `[BiggerCritterDropOff] Set capacity to 1000 in ConfigureBuildingTemplate`
- Log error: `StorageLocker.set_UserMaxCapacity (System.Single value)` → NullReferenceException
- Log error: `FeederConfigPatch.Postfix` → NullReferenceException (capacity was null)
- Log success (coroutine): `[BiggerCritterDropOff] Applied capacities to all existing buildings`
- Log success (extended coroutine): `[BiggerCritterDropOff] Set capacities (attempt)`

## Binary string search results

```
CritterDropOff found at offsets: [9407968, 13293174, 13558929]
  → 9407968: CritterDropOffConfig (class name, appears between other config classes)
  → 13293174: CritterDropOffConfig.cs (source file path)
  → 13558929: CritterDropOffConfig type reference (alongside CritterCondoConfig, CritterPickUpConfig)
```

No `CritterDropOff` runtime class exists — only `CritterDropOffConfig`.
runtime class is `CreatureDeliveryPoint`.
