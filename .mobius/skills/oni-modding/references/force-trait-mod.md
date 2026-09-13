# Forced Trait Mod — All Duplicants Get a Specific Trait

## Pattern (Verified Working on build 587362, Harmony 2.4.2)

### CRITICAL: Harmony Annotation Style
**This user's ONI (build 587362, Harmony 2.4.2) does NOT fire patches with per-method `[HarmonyPostfix]` attributes.**

✅ WORKS (old-style):
```csharp
[HarmonyPatch(typeof(MinionStartingStats), "GenerateTraits")]
public static class ForceTraitPatch
{
    // NO [HarmonyPostfix] attribute on the method!
    static void Postfix(MinionStartingStats __instance) { ... }
}
```

❌ FAILS (new-style, silent failure):
```csharp
[HarmonyPatch(typeof(MinionStartingStats), "GenerateTraits")]
[HarmonyPostfix]  // ← This causes SILENT FAILURE!
public static class ForceTraitPatch
{
    public static void Postfix(MinionStartingStats __instance) { ... }
}
```

Also ❌ FAILS (per-method attribute):
```csharp
[HarmonyPatch(typeof(MinionStartingStats), "GenerateTraits")]
public static class ForceTraitPatch
{
    [HarmonyPostfix]  // ← This also causes SILENT FAILURE!
    public static void Postfix(MinionStartingStats __instance) { ... }
}
```

**Always check the user's existing local mods' .cs files to determine annotation style.** The style must match exactly.

### ⚠️ ALTERNATIVE: Coroutine approach via Game.OnPrefabInit (works when Harmony patches fail)

**When `MinionStartingStats.GenerateTraits` Harmony patch silently fails (build 587362)**, use `Game.OnPrefabInit` + coroutine instead. This is the ONLY reliable approach for this user's build because:

- `Db.Initialize` patches don't fire on this build (unknown Harmony bug)
- `MinionStartingStats.GenerateTraits` patches also may not fire
- `Game.OnPrefabInit` is confirmed working across multiple mods

```csharp
using HarmonyLib;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using Klei.AI;
using UnityEngine;

namespace AllDiversLung
{
    [HarmonyPatch(typeof(Game), "OnPrefabInit")]
    public static class InjectDiversLungPatch
    {
        static void Postfix(Game __instance)
        {
            __instance.StartCoroutine(WaitAndInject());
        }

        static IEnumerator WaitAndInject()
        {
            yield return new WaitForSeconds(3f);

            // Find DiversLung trait from Db
            Trait diversLung = null;
            try
            {
                var traits = Db.Get().traits;
                if (traits == null) { Debug.Log("[AllDiversLung] traits is null"); }
                else
                {
                    foreach (var t in traits.resources)
                    {
                        string id = "";
                        var f = t.GetType().GetField("Id",
                            BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
                        if (f != null) id = f.GetValue(t)?.ToString() ?? "";
                        else id = t.Name ?? "";

                        if (id == "DiversLung")
                        {
                            diversLung = t;
                            Debug.Log("[AllDiversLung] Found DiversLung!");
                            break;
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Debug.Log("[AllDiversLung] Error finding trait: " + e.ToString());
            }

            if (diversLung == null)
            {
                Debug.Log("[AllDiversLung] DiversLung NOT FOUND, giving up");
                yield break;
            }

            // Find MinionStartingStats type via reflection
            // (it does NOT inherit from UnityEngine.Object in build 587362)
            Type minionStatsType = null;
            foreach (var asm in AppDomain.CurrentDomain.GetAssemblies())
            {
                minionStatsType = asm.GetType("MinionStartingStats");
                if (minionStatsType != null) break;
            }
            if (minionStatsType == null) yield break;

            var traitsField = minionStatsType.GetField("traits",
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            if (traitsField == null) yield break;

            // Use non-generic Resources.FindObjectsOfTypeAll(Type) via reflection
            var findMethod = typeof(Resources).GetMethod("FindObjectsOfTypeAll",
                BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic,
                null, new Type[] { typeof(Type) }, null);
            if (findMethod == null) yield break;

            // Periodically inject into all existing MinionStartingStats
            for (int i = 0; i < 30; i++)
            {
                DoInjection(findMethod, minionStatsType, traitsField, diversLung);
                yield return new WaitForSeconds(1f);
            }
        }

        static void DoInjection(MethodInfo findMethod, Type statsType, 
            FieldInfo traitsField, Trait trait)
        {
            try
            {
                var allObjects = findMethod.Invoke(null, new object[] { statsType }) as Array;
                if (allObjects == null) return;

                bool any = false;
                foreach (var obj in allObjects)
                {
                    if (obj == null) continue;
                    var list = traitsField.GetValue(obj) as List<Trait>;
                    if (list == null) continue;

                    bool found = false;
                    foreach (var t in list)
                    {
                        if (t == trait) { found = true; break; }
                    }
                    if (!found)
                    {
                        list.Add(trait);
                        any = true;
                    }
                }
                if (any) Debug.Log("[AllDiversLung] Injected into minion stats");
            }
            catch (Exception e)
            {
                Debug.Log("[AllDiversLung] Inject error: " + e.Message);
            }
        }
    }
}
```

**Key differences from the Harmony-patch approach:**
- Uses `Game.OnPrefabInit` (confirmed working) instead of `Db.Initialize` / `MinionStartingStats.GenerateTraits` (broken on build 587362)
- Uses `Resources.FindObjectsOfTypeAll(Type)` (non-generic) via reflection — because `MinionStartingStats` does NOT inherit from `UnityEngine.Object` on this build, so `Resources.FindObjectsOfTypeAll<MinionStartingStats>()` won't compile
- Periodically checks 30 times (30 seconds) to catch newly generated duplicants via printing pod / care packages
- Extracts `DoInjection` into a separate method to avoid C# yield-in-catch-block restrictions
- Requires `using Klei.AI;` for `Trait` reference
- **Limitation**: Only injects into existing MinionStartingStats objects. Duplicants already printed won't retroactively get the trait unless they have a MinionStartingStats object that's being watched. For already-spawned duplicants, use an alternative approach (e.g. patch MinionIdentity or check on spawn).

### 3-Stage Verification (Check Player.log after game launch + print attempt)
```
Stage 1: [INFO] AllDiversLung: Successfully loaded from path 'root' with content 'DLL'.
Stage 2: [INFO] Loading MOD dll: AllDiversLung.dll
Stage 3: [AllDiversLung] Trait: DiversLung  (from Debug.Log in patch)
```

If Stage 2 is missing → mod_info.yaml format problem.
If Stage 3 is missing → Harmony annotation style problem.
