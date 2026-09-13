# Flydo Mining Hotfix Session — 2026-06-24

## Problem
Player reported: flydo stopped mining after a Harmony-based throttle hotfix was applied.

## Root Cause
The hotfix patched **both** `UpdateWorkTarget` and `RefreshLaser` with a shared Prefix that used `return false` to skip calls within 800ms. Since both methods shared the same `__instance`-based throttle dictionary `_lastUpdate`, they blocked each other. When `RefreshLaser` fired, it reset the timer for `UpdateWorkTarget` too — causing the mining target update to be skipped 90%+ of the time.

## Fix Applied
1. **Only throttle `RefreshLaser`** (the laser animation — suspected OOM culprit). `UpdateWorkTarget` (finding mining targets) was left unpatched.
2. Created a separate `PrefixRefreshLaser` method with a much lighter 100ms throttle instead of 800ms.
3. `UpdateWorkTarget` now runs at full speed — flydo checks for mining targets every frame.

## Code Changes
- Changed `UpdateWorkTarget` patch to use `ThrottlePrefix.Prefix` → removed (no longer patching this method at all)
- `RefreshLaser` now uses `ThrottlePrefix.PrefixRefreshLaser` → 100ms cooldown
- `PrefixRefreshLaser` uses the same `_lastUpdate` dictionary but with 0.1f threshold

## Workshop Mod Identified
- **Workshop ID:** 3714990201
- **staticID:** `FlydoAerialMining`
- **DLL location:** `C:\Program Files (x86)\Steam\steamapps\workshop\content\457140\3714990201\16373731911900856938_legacy.bin` (ZIP archive)
- **DLL contains classes:** `FlydoMinerMonitor` (with `UpdateWorkTarget`, `RefreshLaser`), `FlydoMinerConfig`, `FlydoLaser`, `FlydoAerialMiningMod`, etc.

## FindType Diagnosis Trap (2026-06-28)

**Problem:** The hotfix's `DelayedPatcher` kept retrying but never found `FlydoMinerMonitor`. No patch was ever applied. Player.log showed:

```
[FlydoMiningHotfix] Loaded! Delaying patch until FlydoAerialMining is ready.
```

...but NEVER showed:
```
[FlydoMiningHotfix] UpdateWorkTarget — 不限频
```

**Root cause:** The workshop mod `FlydoAerialMining` (3714990201) was NOT enabled in the game's Mod menu. Without the workshop DLL loaded, `FindType("FlydoMinerMonitor")` can never find it.

**Fix:** Add diagnostic logging on first retry attempt to dump all loaded types containing "Flydo":

```csharp
if (_retryCount == 1)
{
    Debug.Log("[FlydoMiningHotfix] Scanning assemblies for Flydo types...");
    foreach (var asm in System.AppDomain.CurrentDomain.GetAssemblies())
    {
        foreach (var t in asm.GetTypes())
        {
            if (t.Name.Contains("Flydo"))
                Debug.Log($"[FlydoMiningHotfix] Found type: {t.FullName} in {asm.GetName().Name}");
        }
    }
}
```

If this outputs nothing, the workshop mod is not loaded — check Mod menu.

**Secondary fix:** `asm.GetType(name)` only finds types with exact namespace. Workshop mod DLLs often use NO namespace. Add a fallback scan of all types in each assembly:

```csharp
private static System.Type FindType(string name)
{
    foreach (var asm in System.AppDomain.CurrentDomain.GetAssemblies())
    {
        var t = asm.GetType(name);
        if (t != null) return t;
        foreach (var t2 in asm.GetTypes())
        {
            if (t2.Name == name || t2.FullName == name)
                return t2;
        }
    }
    return null;
}
```

## Key Lessons for Future Hotfixes
- DO NOT throttle method calls that check "is there work to do?" — the user wants the work to be detected promptly.
- If only one method is causing OOM, only patch that one.
- `return false` in a Harmony Prefix **completely disables** the original method — treat it as a nuclear option.
- Workshop mod DLLs may be inside legacy.bin archives, not in Mods/Steam/ — use Python zipfile to extract for inspection.
