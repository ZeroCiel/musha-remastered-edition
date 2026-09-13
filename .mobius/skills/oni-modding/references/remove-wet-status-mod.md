# Remove Wet Status Effects Mod (SoakingWet / FeetWet)

## Approach: Delete Status Items from DUPLICANTSTATUSITEMS Dictionary

The cleanest way to prevent wet status effects is to remove their definitions from the `DUPLICANTSTATUSITEMS.statusItems` dictionary after `CreateStatusItems()` runs. This makes the game completely unaware of these statuses — they never appear, never apply stress, never affect decor.

## Session Notes (June 21, 2026)

**Status**: Compiled but not yet tested due to Harmony patch compatibility issues.

**Target status items**: `SOAKINGWET` (浑身湿透), `FEETWET` (双脚湿透)

### Code (via Game.OnPrefabInit + coroutine, user's only reliable approach)

```csharp
using HarmonyLib;
using System;
using System.Collections;
using System.Reflection;
using UnityEngine;

namespace NoSoakingWet
{
    [HarmonyPatch(typeof(Game), "OnPrefabInit")]
    public static class RemoveWetStatusPatch
    {
        static void Postfix(Game __instance)
        {
            __instance.StartCoroutine(RemoveWetStatus());
        }

        static IEnumerator RemoveWetStatus()
        {
            yield return new WaitForSeconds(3f);

            try
            {
                foreach (var asm in AppDomain.CurrentDomain.GetAssemblies())
                {
                    foreach (var t in asm.GetTypes())
                    {
                        if (t.Name != "DUPLICANTSTATUSITEMS") continue;

                        // Get Instance (singleton)
                        var flags = BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic;
                        object instance = null;
                        var prop = t.GetProperty("Instance", flags);
                        if (prop != null)
                            instance = prop.GetValue(null, null);
                        else
                        {
                            var field = t.GetField("Instance", flags);
                            if (field != null)
                                instance = field.GetValue(null);
                        }
                        if (instance == null) continue;

                        // Get the statusItems dictionary
                        var dictField = t.GetField("statusItems", flags);
                        if (dictField == null) continue;

                        var dict = dictField.GetValue(instance) as IDictionary;
                        if (dict == null) continue;

                        string[] removeKeys = { "SOAKINGWET", "FEETWET" };
                        foreach (var key in removeKeys)
                        {
                            if (dict.Contains(key))
                            {
                                dict.Remove(key);
                                Debug.Log("[NoSoakingWet] Removed: " + key);
                            }
                        }
                        break;
                    }
                }
            }
            catch { }
        }
    }
}
```

### Alternative: Patch DUPLICANTSTATUSITEMS.CreateStatusItems (if Harmony works)

```csharp
[HarmonyPatch(typeof(DUPLICANTSTATUSITEMS), "CreateStatusItems")]
public static class RemoveWetStatusPatch
{
    static void Postfix(DUPLICANTSTATUSITEMS __instance)
    {
        var field = typeof(DUPLICANTSTATUSITEMS)
            .GetField("statusItems", BindingFlags.Instance | BindingFlags.NonPublic);
        if (field == null) return;

        var dict = field.GetValue(__instance) as IDictionary;
        if (dict == null) return;

        string[] removeKeys = { "SOAKINGWET", "FEETWET" };
        foreach (var key in removeKeys)
        {
            if (dict.Contains(key))
            {
                dict.Remove(key);
                Debug.Log("[NoSoakingWet] Removed: " + key);
            }
        }
    }
}
```

### Requirements

- Uses reflection to find `DUPLICANTSTATUSITEMS` type (not compile-time dependent)
- Status item keys: `"SOAKINGWET"`, `"FEETWET"` (uppercase, confirmed from DLL string table)
- Works by deleting from the dictionary → game treats them as non-existent → no visual, no stress, no decor impact
- Does NOT affect liquid physics — water is still water, duplicants still interact with it
- Only removes the status UI and its mechanical effects (stress/decor)

### Related Files

- Mod source: `D:/Backup/Documents/Klei/OxygenNotIncluded/mods/local/NoSoakingWet/`
