# Flydo Aerial Mining — Build Support Architecture Limit

## Workshop Mod

- **Workshop ID:** 3714990201
- **staticID:** FlydoAerialMining
- **Version:** 1.9.0
- **Author:** YourName (workshop name)
- **DLL extracted from legacy.bin**

## Hotfix (FlydoMiningHotfix) — Current State

**Path:** `mods/Local/FlydoMiningHotfix/`

### What it patches

1. **FlydoMinerMonitor.UpdateWorkTarget** — REMOVED throttle (was 800ms, causing Flydo to not mine)
2. **FlydoMinerMonitor.RefreshLaser** — throttle to 100ms (prevents OOM from laser animation spam)

### Patch mechanism

Uses `DelayedPatcher` (Unity coroutine component). Waits for FlydoAerialMining DLL to load (via `FindType("FlydoMinerMonitor")`), then creates a NEW Harmony instance to patch the discovered Type. This is necessary because:

- FlydoAerialMining DLL may not be loaded when `OnLoad` runs
- `FindType` searches all loaded assemblies for the class name string

### 2026-06-28 Fix: Throttle Conflict

**Root cause of Flydo not mining:** Both `UpdateWorkTarget` and `RefreshLaser` were throttled via a **shared** `_lastUpdate` Dictionary. The 800ms throttle on `UpdateWorkTarget` meant Flydo only checked for diggable targets once every 0.8 seconds. During that gap, the Flydo sat idle.

**Fix:** Remove throttle from `UpdateWorkTarget` entirely. Only throttle `RefreshLaser` (100ms, separate Dictionary).

## ⚠ Architecture Limit: BUILD IS NOT POSSIBLE via Hotfix

### Extracted DLL methods (FlydoMinerMonitor):

| Method | Purpose |
|--------|---------|
| `UpdateWorkTarget()` | Scans for dig targets every frame |
| `FindBestMineableCell()` | Returns nearest diggable cell |
| `IsDiggable(GameObject)` | Checks if a target can be mined |
| `StartDigChore()` | Creates WorkChore<Diggable> |
| `RefreshLaser()` | Dig laser animation (OOM culprit) |
| `NotifyDigWorkTick()` / `OnWorkTick()` | Dig progress callbacks |
| `GetDiggable()` / `GetWorkable()` | Getter helpers |
| `CancelCurrentChore()` | Cancel active chore |
| `SetTargetPos()` | Navigation helper |
| `ForceDigLaserOn` | Laser state flag |
| `LaserOff` | Laser state method |

**Fields:** `_activeChore`, `_currentDiggable`, `_currentTargetCell`, `_digLaserAnim`, `_digLaserCtrl`, `_laserActive`, `_laserTargetCell`, `_laserToggler`, `_splashTargetCell`, `targetCell`

### Why building can't be added via patch

1. **No constructable target scanning** — `FindBestMineableCell` and `IsDiggable` are dig-specific. No equivalent for BuildingUnderConstruction/Constructable
2. **No build state machine** — Internal fields like `_currentDiggable`, `_digLaserAnim`, `_laserToggler` are all dig-specific. No build equivalents exist
3. **No build chore type** — `StartDigChore` creates `WorkChore<Diggable>`. Building needs `WorkChore<Constructable>` which has different navigation and animation requirements
4. **No build animation** — The laser animation system (`_digLaserAnim`, `_digLaserCtrl`, `_laserToggler`) is designed for digging. Building needs a different animation loop (hover-over-constructable with periodic work ticks)
5. **Navigation different** — Dig targeting positions Flydo above the target. Build requires Flydo to approach and hover next to/near the constructable

**Conclusion:** Adding build capability requires a **standalone mod** that extends or forks FlydoMinerMonitor. Estimated scope: 50% of original mod development effort.

### What CAN be patched via hotfix

- ✅ Scanned for buildable targets in `UpdateWorkTarget` (postfix) — but cannot actually execute build work
- ✅ Override `IsDiggable` to return true for Constructable — but StartDigChore won't know what to do
- ✅ Navigation to build target — but no chore/animation system to execute construction

## Extracted DLL Classes (Full List)

```
FlydoAerialMiningMod       — KMod.UserMod2 entry point
FlydoMinerConfig           — IBuildingConfig for the Flydo building
FlydoMinerMonitor          — Core state machine: dig logic, navigation, laser
FlydoGood                  — Unknown purpose (possibly a tag/status)
Diggable_GetAnim_Patch     — Harmony patch: dig animation
Diggable_OnWorkTick_FlydoLaser_Patch — Harmony patch: laser on work tick
```

Also references: `FetchDrone`, `FetchDroneConfig`, `FetchDrone_OnSpawn_Patch`, `RFetchDrone`, `XFetchDroneConfig` — likely used as reference code when building FlydoMinerMonitor (they're similar drone-worker patterns).
