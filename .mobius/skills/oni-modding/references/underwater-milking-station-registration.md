# UnderwaterMilkingStation Offsets & Build Registration (build 587362)

## Key Offsets in Assembly-CSharp.dll

| Offset | String | Meaning |
|--------|--------|---------|
| 9046684 | `UNDERWATERBREATHINGSTATION.UNDERWATERMILKINGSTATION.GOURMETCOOKINGSTATION...` | Chore/errand station chain — the station IDs in priority order for duplicant pathing |
| 9411419 | `UnderwaterMilkingStationConfig` | Class name, in the `Config.UnderwaterBreathingStationConfig.UnderwaterMilkingStationConfig` chain |
| 13344303 | `UnderwaterMilkingStationConfig.cs` | Source file path reference |
| 13548814 | `STRINGS.BUILDINGS.PREFABS\|UNDERWATERMILKINGSTATION` | Building PREFABS ID registration |
| 13631548 | `UnderwaterMilkingStationConfig` | Another class reference (likely in metadata) |
| 8960888 | `ELIGIBLE_MILKING_PERCENTAGE` | Tuning constant — fertility % threshold for a pacu to be "milkable" |
| 9047169 | `CAN_USE_MILKING_STATION` | Chore condition check for the milking errand |
| 9542428 | `CanUseMilkingStation` | Duplicant-side condition (camelCase variant in chore conditions) |

## Problem Diagnosis

**Building "建造条件调不出来" (can't find build conditions):**

The building `UNDERWATERMILKINGSTATION` is registered in:
1. The `BUILDINGS.PREFABS` string table (offset 13548814) — the game knows this building ID exists
2. The chore/errand station chain (offset 9046684) — the game knows this is a station type

But it is **NOT** registered in:
- Any `BUILDCATEGORY`, `PLANSUBCATEGORY`, or `PLANCATEGORY` string entry
- Any `TECH` / tech tree node (no `RESEARCH.TECHS.<tech>.UNDERWATERMILKINGSTATION` reference exists)
- No `BUILDINGS.BUILDING_STATUS_ITEMS` or building panel registration

**Root cause**: The building's `UnderwaterMilkingStationConfig` class exists in the assembly code (method body metadata at offsets 9411419, 13344303) and its PREFABS entry is created, but the tech unlock + build menu category assignment was never wired up in this game version (build 587362). The building is partially implemented — it's a remnant of DLC5 content that was added to the PREFABS table but not fully integrated.

**Result**: In-game, the building ID exists but never appears in any build menu tab, and no research technology unlocks it. The player cannot find it in the build menu.

## Comparison with Related Buildings

| Building | PREFABS ID | In Tech Tree | In Build Menu |
|----------|-----------|--------------|---------------|
| `CRITTERCONDO` | Yes | Yes | Yes |
| `UNDERWATERCRITTERCONDO` | Yes | Likely | Likely (DLC5) |
| `UNDERWATERMILKINGSTATION` | Yes | **No** | **No** |
| `MILKINGSTATION` | Yes | Likely | Unknown (land variant) |

The `UNDERWATERMILKINGSTATION` building ID sits alphabetically between `UNDERWATERCRITTERCONDO` and `MASSIVEHEATSINK` in the PREFABS table — suggesting it was added as part of a batch of new DLC5 buildings but only some were fully wired up.

## Milking Mechanic Details

The milking check chain (from string analysis):
```
percentFertilityConsumedPerMilking → RequiresMilking → EndBlinking → 
CanUseMilkingStation → RanchStation.TryToCreateErrand
```

- `percentFertilityConsumedPerMilking` — controls how much fertility is consumed per milking action
- `RequiresMilking` — flag set on a pacu when its fertility exceeds the threshold
- `GETTING_MILKED` / `HAD_CONSUMED_MILK_RECENTLY_EFFECT_ID` — cooldown effect preventing re-milking too soon
- `MILK_PRODUCTION_PERCENTAGE_PER_SECOND` — production rate for pacu milk
- `MILKPRODUCTIONDELTA` — delta applied to milk production (affected by happiness/glum state)

## Mod Approach for Registration Fix

```csharp
[HarmonyPatch(typeof(Game), "OnPrefabInit")]
public static class UnlockBuildingPatch
{
    static void Postfix(Game __instance)
    {
        __instance.StartCoroutine(RegisterBuilding());
    }

    static IEnumerator RegisterBuilding()
    {
        yield return new WaitForSeconds(5f);
        DoRegistration();
    }

    static void DoRegistration()
    {
        string buildingId = "UnderwaterMilkingStation";
        // Approach 1: Add to tech's unlockedItems list via reflection
        var techs = Db.Get().Techs;
        var resourcesField = techs.GetType().GetField("resources", ...);
        // Find "Ranching" tech, get its unlockedItems field, add buildingId
        // Approach 2: Try BuildingConfigManager.RegisterBuilding(string)
    }
}
```

Note: This approach was created but NOT verified in-game by the user in this session. The user encountered the build menu registration issue and was still testing when the conversation moved to post-session review.
