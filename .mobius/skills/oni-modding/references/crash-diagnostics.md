# ONI Crash Diagnostics

When a mod causes "game crashes on startup" or the Player.log shows no mod-related errors, the crash is often NOT the mod's fault.

## Step 1: Find the Crash

Player.log location:
```
C:\Users\{user}\AppData\LocalLow\Klei\Oxygen Not Included\Player.log
```

Previous session: `Player-prev.log`

## Step 2: Read The Last Lines

```bash
tail -100 "/c/Users/Administrator/AppData/LocalLow/Klei/Oxygen Not Included/Player.log"
```

The crash is usually near the **bottom** of the log, as ONI appends entries during shutdown/abort.

## Step 3: Classify the Crash

### A) YAML/DLC parsing error (not mod-related)

Pattern:
```
Fatal parse error in .../StreamingAssets/dlc/expansion1/templates/poi/aquatic/large_coal_geode.yaml
(Line: 416, Col: 3) - Exception during deserialization
Thread was being aborted.
```

**Cause**: Game's own DLC template files are corrupted (disk error, partial Steam update).

**Fix**: Steam → Library → right-click Oxygen Not Included → Properties → Installed Files → Verify integrity of game files.

DO NOT waste time debugging the mod — this crash happens before mods are even loaded.

### B) Harmony patch exception at load time

Pattern:
```
[ERROR] Failed to patch [ClassName] with [YourModName]
...
System.NullReferenceException
```

**Cause**: `HarmonyPostfix` target method doesn't exist in this ONI version, or the patch body throws.

**Fix**: Check the target method name still exists via API reverse-engineering (`Assembly-CSharp.dll` string scan). Common misses:
- `OilRefinery.OnPrefabInit` → exists ✓
- `OilRefinery.ConvertInputs` → removed ✗
- `outputElements` → moved to `ElementConverter` backing field

### C) NullReferenceException in Sim200ms

Pattern: Crash happens a few seconds into loading a save (not at startup).

**Cause**: `AutoRunController.Sim200ms` accesses a component that hasn't spawned yet, or `_convertMethod` is null on first call because reflection lookup failed.

**Fix**: Null-guard every field access in `Sim200ms`. Cache reflection results in a static field (one-time lookup).

### D) ONI itself crashes before mod loading

The log will show normal initialization up to "-- MAIN MENU --" then abruptly stop or show a `Unity`-level error (e.g. `KleiItems: Max Retries (0) reached` or a YAML parse error).

### E) OutOfMemoryException in NavGrid initialization

Pattern:
```
System.OutOfMemoryException: Out of memory
  at NavGrid..ctor_Patch1(NavGrid,string,NavGrid/Transition[],NavGrid/NavTypeData[],...)
  at GameNavGrids.CreateDiggerNavigation(Pathfinding pathfinding)
  at GameNavGrids..ctor(Pathfinding pathfinding)
  at Game.OnPrefabInit_Patch1(Game)
```

**Cause**: Memory exhaustion during pathfinding navgrid generation — happens at game startup before main menu. Not a mod code bug, but mods can trigger it by adding extra world traits/planetoids that inflate the navgrid size beyond available RAM.

**Fix sequence** (in order):
1. Close browser tabs / other memory-hungry apps. ONI needs ~2-3GB free on top of base OS.
2. Increase Windows page file if under 8GB (System Properties → Advanced → Performance → Virtual memory).
3. Disable world-gen mods (WGSM, WorldgenDesigner, CustomGameSettingsModifier) that add extra planetoids or world traits — these directly inflate navgrid memory.
4. If still crashing with NO mods → Steam verify game files (corrupted navgrid data can cause infinite allocation loops).
5. If still crashing after verify → 8GB RAM may genuinely be insufficient for U59+ with all DLC; reduce DLC content or upgrade RAM.

**Confusion trap**: `OutOfMemoryException` stack shows MonoMod/Unity internals, not a mod DLL. User may think "game broke itself" — but the trigger often IS a mod inflating the navgrid. The crash is real (OOM), just the root cause is mod-added content volume rather than a mod code exception.

### F) Codex duplicate entry warning (not a crash)

Pattern:
```
Tried to add PIAPIPLANTHELPER to the Codex screen multiple times
  at CodexCache.AddEntry(...)
  at CodexEntryGenerator.GenerateSingleBuildingEntry(...)
```

**This is a WARNING, not a crash.** The game continues running after this log entry. The building icon appears in the Codex once regardless.

**Cause**: A mod registers a building with an ID that's already in the Codex. Two scenarios:
1. A single mod registers the same building twice (rare — typically a mod code bug)
2. Two mods both register a building with the same string ID (common with mod conflicts)

**Detection**: Since the ID is compiled into .dll binaries, search all mod `.dll` files for the duplicate string:
```python
import re, os
for root, dirs, files in os.walk("mods_dir"):
    for f in files:
        if f.endswith(".dll"):
            data = open(os.path.join(root, f), "rb").read()
            if b"YOUR_DUPLICATE_ID" in data:
                print(os.path.join(root, f))
```

**Fix**: Identify which mod(s) contain the duplicate string, disable the redundant one, or check if one mod has a duplicate building registration in its code.

**Mod conflict chain**: If you see this warning alongside a startup crash (like NavGrid OOM), the Codex warning is usually a *symptom* of mod conflict, not the cause. Fix the OOM first, then the Codex warning will likely disappear when the problematic mod is removed.

## Key Diagnostic Principle

> A crash at **startup** (before main menu) is almost never the mod's fault. 
> A crash at **save load** (clicking a colony) may be the mod's fault.
> A crash **during gameplay** (after the colony is running) is most likely the mod's fault.

## Quick Self-Check

1. Disable the mod → does the game start? If yes → mod problem. If still crashes → game files/Steam problem.
2. Enable ONLY your mod (disable all others) → does it crash? If yes → your mod. If no → mod conflict.
