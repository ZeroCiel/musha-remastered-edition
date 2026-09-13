# Aquatic Pasture / Underwater Milking Station — Mechanism & Debugging

## Milking Trigger Chain

Extracted from Assembly-CSharp.dll string table (build 587362):

```
percentFertilityConsumedPerMilking →
  RequiresMilking →
    EndBlinking →
      CanUseMilkingStation →
        RanchStation.TryToCreateErrand
```

### How it works:

1. **Pacu has `percentFertilityConsumedPerMilking`** — a tunable constant that defines how much fertility is consumed per milking action
2. **When pacu's fertility progress reaches this threshold** → the `RequiresMilking` flag is set on the creature
3. **`GETTING_MILKED` status + `HAD_CONSUMED_MILK_RECENTLY_EFFECT_ID` cooldown** — prevents re-milking too soon
4. **`MILK_PRODUCTION_PERCENTAGE_PER_SECOND` + `MILKPRODUCTIONDELTA`** — control the rate at which milk accumulates
5. **Output**: `FishMilk` item (resource ID), also produces `FISHMILKICE` variant
6. **Feeder behavior**: `FaceMilkFeeder → ReserveMilkFeeder → UnreserveMilkFeeder → GetTargetMilkFeeder → targetMilkFeeder` — creatures path to milk feeders using this behavior chain

### Prerequisites for milking to work:

| Condition | Detail |
|-----------|--------|
| Room type | Must be CreaturePen / AquaticPasture (not generic/杂间) |
| Pacu tamed | Wild pacu have `Wildness` that blocks fertility growth |
| Pacu happy | Glum pacu have `MILKPRODUCTIONDELTA` slowed to zero |
| Fertility progress | Must exceed `ELIGIBLE_MILKING_PERCENTAGE` threshold |
| Duplicant ability | `CAN_USE_MILKING_STATION` chore — may require Ranching skill |
| Underwater access | `CAN_USE_MILKING_STATION` is in same chain as `UnderwaterBreathingStation` |
| No cooldown | Pacu must not have `HAD_CONSUMED_MILK_RECENTLY_EFFECT_ID` |

## Key Classes & String Offsets

All offsets are positions in `Assembly-CSharp.dll` where the string/reference was found.

### Building Configs

| Name | Offset | Description |
|------|--------|-------------|
| `UnderwaterMilkingStationConfig` | 9411419 | Milking station building config |
| `UnderwaterMilkingStation` (class ref) | 13344303 | Runtime class |
| `UnderwaterMilkingStationConfig` (again) | 13631548 | Another reference |
| `MilkingStationConfig` (land) | 9411429 | Land variant |
| `MilkingStationConfig` (class ref) | 9542434 | Land runtime (has CanUseMilkingStation nearby) |
| `MilkingStationConfig` (file ref) | 13325840 | Source file path |
| `UnderwaterMilkFeederConfig` | 9413199 | **Separate building** — the feeder, not the station |
| `MilkFeederConfig` (land) | 9413209 | Land feeder variant |
| `MilkPressConfig` | ~13325840 | Converts milk? |
| `MilkFatSeparatorConfig` | ~13619294 | Separates milk components |

### Chore/Condition Constants

| String | Offset | Meaning |
|--------|--------|---------|
| `CAN_USE_MILKING_STATION` | 9047169 | Chore condition for milking station |
| `CAN_USE_RANCH_STATION` | 9047189 | General ranch station chore |
| `IS_CREATURE_AVAILABLE_FOR_RANCHING` | 9006714 | General ranch availability check |
| `MISSING_RESEARCH_STATION` | 9047201 | In same condition chain |
| `WASH_STATION` | ~9047200 | In same condition chain |

### Tuning Constants

| String | Offset | Type | Description |
|--------|--------|------|-------------|
| `ELIGIBLE_MILKING_PERCENTAGE` | 8960888 | float | Fertility % threshold for milking |
| `RANCHING_CAPTURABLE_MULTIPLIER_BONUS_PER_POINT` | 9130092 | float | Ranching skill multiplies capture speed |
| `RANCHING_DURATION_MULTIPLIER_BONUS_PER_POINT` | 9130139 | float | Ranching skill multiplies ranch duration |
| `MILK_PRODUCTION_PERCENTAGE_PER_SECOND` | ~ | float | Milk production rate |
| `MILKPRODUCTIONDELTA` | ~ (near INCUBATIONDELTA) | float | Per-tick delta |
| `FertilityConsumedPerMilking` | ~ (near RequiresMilking) | float | Fertility consumed per milking action |
| `percentFertilityConsumedPerMilking` | ~ | float | Same as above, alternate name |
| `INCUBATIONDELTA` | ~ (near MILKPRODUCTIONDELTA) | float | Egg incubation delta (nearby context) |
| `INITIAL_MORB_DEVELOPMENT_PERCENTAGE` | 8960922 | float | Nearby constant in CREATURES tuning |

### Creature Behavior

| String | Offset | Description |
|--------|--------|-------------|
| `RequiresMilking` | ~ | Flag on creature when milkable |
| `EndBlinking` | ~ | State machine state after milking |
| `UpdateBlinking` | ~ | State machine update |
| `BeginBlinking` | ~ | State machine state begin |
| `IsBlinking` | ~ | State machine bool |
| `GetMilkable` | ~ | Method to check milkability |
| `IsReadyToMilk` | ~ | Method |
| `FaceMilkFeeder` | 9595839 | Behavior: creature faces the milk feeder |
| `ReserveMilkFeeder` | 9595857 | Behavior: reserve the feeder |
| `UnreserveMilkFeeder` | ~ | Behavior: release the feeder |
| `GetTargetMilkFeeder` | ~ | Method: find feeder target |
| `targetMilkFeeder` | 9595877 | Field |
| `milkFeeder` | ~ | Field |
| `FillFeeder` | ~ | Behavior: fill the feeder |
| `Behaviour_Milking` | ~ | Behavior tree entry |

### Status Items & Effects

| String | Description |
|--------|-------------|
| `GETTING_MILKED` | Status item during milking |
| `HAD_CONSUMED_MILK_RECENTLY_EFFECT_ID` | Cooldown effect after milking |
| `MILK_SLOT_LOCKED` | Building storage slot lock |
| `UNUSABLEGUNKED` | Building unusable state |

### Resource IDs

| String | Description |
|--------|-------------|
| `FishMilk` | The milk item produced |
| `FISHMILK` | Alternate/tag ID |
| `MURKYBRINEICE` | Related resource |
| `FISHMILKICE` | Frozen variant |

## Modding Approach: Force Milking Errands

On build 587362, `[HarmonyPatch(typeof(Db), "Initialize")]` silently fails. Use `Game.OnPrefabInit` coroutine instead:

```csharp
[HarmonyPatch(typeof(Game), "OnPrefabInit")]
public static class ForceMilkingRefreshPatch
{
    static void Postfix(Game __instance)
    {
        __instance.StartCoroutine(RefreshLoop());
    }

    static IEnumerator RefreshLoop()
    {
        yield return new WaitForSeconds(5f);
        
        Type ranchStationType = null;
        foreach (var asm in AppDomain.CurrentDomain.GetAssemblies())
            foreach (var t in asm.GetTypes())
                if (t.Name == "RanchStation") { ranchStationType = t; break; }

        var flags = BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic;
        var tryCreate = ranchStationType?.GetMethod("TryToCreateErrand", flags);
        var findTarget = ranchStationType?.GetMethod("FindTarget", flags);
        var refresh = ranchStationType?.GetMethod("Refresh", flags);

        while (true)
        {
            if (ranchStationType != null)
                foreach (var station in Resources.FindObjectsOfTypeAll(ranchStationType))
                {
                    findTarget?.Invoke(station, null);
                    refresh?.Invoke(station, null);
                    tryCreate?.Invoke(station, null);
                }
            yield return new WaitForSeconds(3f);
        }
    }
}
```

**Note**: This mod was created and compiled but NOT verified by the user. It depends on `RanchStation`, `TryToCreateErrand`, `FindTarget`, `Refresh` existing at runtime with exactly those names. If the class was renamed (e.g. to `CreatureRanchStation`), the coroutine will silently do nothing.

## Duplicant Underwater Access

`CAN_USE_MILKING_STATION` appears in the same string chain as `UnderwaterBreathingStation`. If the milking station is placed underwater, duplicants may need:
1. Underwater breathing (from an UnderwaterBreathingStation building)
2. Or the Atmo Suit / oxygen mask equivalent for underwater
3. Or the dupe may need the `Swimming1` skill to operate underwater

If none of these are present, the chore condition will never be satisfied and the station won't show any work errand.

## Common Failure Modes

1. **Room not recognized** (>96 tiles, modded rooms that lost their type, or rooms without proper boundaries)
2. **Wild pacu** — wild creatures have zero fertility growth
3. **Glum/Unhappy pacu** — caused by overcrowding, wrong environment, or being in a non-room area
4. **No fertility progress** — pacu need to be fed and happy to grow fertility
5. **Recently milked** — cooldown effect active
6. **No Ranching skill on dupe** — the CAN_USE_MILKING_STATION condition checks for Ranching skill
7. **Underwater access missing** — dupe can't reach the building underwater
8. **Different ONI version** — build 587362 may have incomplete or buggy UnderwaterMilkingStation implementation (DLC5/bionic era content on a pre-U59 build)
