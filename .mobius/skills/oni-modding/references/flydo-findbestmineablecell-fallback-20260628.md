# Flydo FindBestMineableCell Postfix — 2026-06-28 Session

## Problem
Flydo (from FlydoAerialMining v1.9.0 workshop mod) would find dig targets (log shows "Found dig target at cell X") but would NOT actually start the dig chore. The original mod's `FindBestMineableCell` returned -1 (no target) in many cases, causing Flydo to idle.

## Hotfix Approach
Patch `FlydoMinerMonitor.FindBestMineableCell` with a Postfix that fires when the original returns `-1`:

```csharp
public static void FBMC(object __instance, ref int __result)
{
    if (__result != -1) return; // original found one
    
    var go = GetGO(__instance); // get Flydo's GameObject
    var diggables = Object.FindObjectsOfType<Diggable>();
    Diggable best = null;
    float bestDist = 999f;
    
    foreach (var d in diggables)
    {
        float dist = Vector3.Distance(pos, d.transform.position);
        if (dist < bestDist && dist < 50f && Grid.IsValidCell(Grid.PosToCell(d)))
        {
            bestDist = dist;
            best = d;
        }
    }
    
    if (best != null)
        __result = Grid.PosToCell(best);
}
```

## Parallel Approach (also in same hotfix)
Also patch `Game.LateUpdate` — every 60 frames, scan all GameObjects for `FlydoMinerMonitor` component (via `GetComponent("FlydoMinerMonitor")` string lookup), find nearest `Diggable`, and call `UpdateWorkTarget()` via reflection as a forced nudge.

## RefreshLaser Throttling
- **Original bug:** Workshop mod's `RefreshLaser()` runs every frame → OOM from laser animation spam
- **100ms throttle:** Initially tried but too aggressive — may have interfered with dig chore lifecycle
- **500ms throttle:** Safer — allows dig chore to complete while preventing OOM
- **Shared dictionary bug:** Original hotfix used ONE dictionary for BOTH `UpdateWorkTarget` and `RefreshLaser` → `UpdateWorkTarget` got accidentally throttled at 800ms → Flydo never scanned for new targets

## Key Lessons
1. Never share throttle dictionaries between unrelated methods.
2. FindType in delayed patcher MUST scan all assembly types (not just `asm.GetType`) because workshop mod DLLs have no namespace.
3. Add diagnostic logging on first scan attempt to confirm FindType is working.
4. `Object.FindObjectsOfType<Diggable>()` works because Diggable is a Component.
5. 500ms throttle on RefreshLaser seems to be the sweet spot.
