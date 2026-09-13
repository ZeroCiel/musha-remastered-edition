# Flydo Aerial Mining OOM Diagnosis (2026-06-23)

## Symptom

Game crashed with `System.OutOfMemoryException: Out of memory` after hours of gameplay.

## Log Analysis

Player.log showed 18,000+ repeated lines:
```
[FlydoAerialMining] Laser ON → cellule 180737 (eventSource=FetchDrone)
[FlydoAerialMining] Laser OFF
```

The laser was toggling ON/OFF dozens of times per second for hours, producing enough log output to exhaust memory.

## Root Cause

The `FlydoAerialMining` mod (workshop 3714990201, `FlydoAerialMining.dll`) implements `FlydoMinerMonitor` on `ISim200ms` — firing every 0.2 seconds. Each tick calls `UpdateWorkTarget()` → `RefreshLaser()` which toggles the dig laser animation.

The bug: when the dig target is invalid (already mined, or the flydo can't reach it), the mod enters a loop: start laser → immediately stop → check again → start laser → stop. Each cycle writes 2 log lines. Over hours, this consumes all available memory.

## Fix

Create a throttle patch mod that limits how often the problematic methods run:

```csharp
[HarmonyPatch]
public static class FlydoMinerWorkTargetPatch
{
    private static readonly Dictionary<object, float> _lastUpdate = new Dictionary<object, float>(16);

    static IEnumerable<MethodBase> TargetMethods()
    {
        var type = AccessTools.TypeByName("FlydoMinerMonitor");
        if (type != null)
        {
            var m = AccessTools.Method(type, "UpdateWorkTarget");
            if (m != null) yield return m;
            m = AccessTools.Method(type, "RefreshLaser");
            if (m != null) yield return m;
        }
    }

    static bool Prefix(object __instance)
    {
        float now = Time.realtimeSinceStartup;
        float last;
        lock (_lastUpdate)
        {
            if (_lastUpdate.TryGetValue(__instance, out last))
            {
                if (now - last < 0.8f) return false; // 800ms throttle
            }
            _lastUpdate[__instance] = now;
        }
        return true;
    }
}
```

Also throttle `Diggable.OnWorkTick` to max once per 100ms to prevent per-frame mining spam.

## RETRACTION: Throttle via Prefix return false breaks mining

**The original throttle approach broke flydo mining entirely.** `return false` in a Prefix skips the original method — if the target methods (`UpdateWorkTarget`, `RefreshLaser`) are called frequently during normal operation (not just during the OOM bug), skipping calls causes the flydo to never mine.

### Correct fix: limit iterations per call, not calls per second

Instead of throttling at the method-call level, the fix should limit how many iterations the OOM loop can do per single invocation. Options:

- **Option A**: Transpiler that injects a `break` after N iterations inside the loop that toggles the laser
- **Option B**: Limit the number of laser ON/OFF toggles per call, not the number of calls
- **Option C**: Remove the throttle entirely if the OOM bug was patched upstream

### Current status

The `FlydoMiningHotfix` mod currently blocks mining. To fix it, delete the ThrottlePrefix class entirely, or replace it with a loop-iteration limiter.

## Deploy (for reference only — this approach is deprecated)

The original (broken) fix lives as a separate mod:
- Location: `mods/local/FlydoMiningHotfix/`
- StaticID: `FlydoMiningHotfix`
- Must be enabled alongside `FlydoAerialMining` in the mods list
- The throttle patch intercepts the problematic methods and limits their execution rate
