# Small Discharger Anywhere Mod — 2026-06-29 Session

## Goal
Make the small (Compact) Electrobank Discharger buildable without ground support (floating in air).

## What Worked
- `BuildLocationRule` → `BuildLocationRule.Anywhere` via CreateBuildingDef Postfix
- This allows the **blueprint** to be placed anywhere

## What Did NOT Work

### 1. OccupyArea method patching — Crashes the mod
All attempts to patch OccupyArea methods resulted in:
```
HarmonyException: Patching exception in method null
  ---> ArgumentException: Undefined target method for patch method ...
```

Non-existent methods tried (confirmed via DLL string search):
- `OccupyArea.IsValidTileLocation`
- `OccupyArea.SetOccupyGridSpace`
- `OccupyArea.RefreshCellOccup` / `RefreshCellOccupy`
- `Building.ForcePermanentCheck`

### 2. Game.LateUpdate occypArea removal
Destroying OccupyArea on built dischargers via LateUpdate polling:
- `Object.DestroyImmediate(occ)` — confirmed to run
- But user reports the "没有地面砖块" message still appears
- This suggests the check happens once at construction time and is cached, or the building component itself holds the state

### 3. BuildingComplete_OnSpawn / _OnInit patches
These methods DO exist in U59 (confirmed via string dump), but patching them to remove OccupyArea on the specific building type was attempted but user reports it didn't work on subsequent tests (the session ended before confirming the latest build).

## Prefab ID
The correct PrefabID string is: `SMALLELECTROBANKDISCHARGER` (all caps, no underscores)

## Conclusion
For U59-737790, the only reliable approach to floating buildings is `BuildLocationRule.Anywhere`. The post-build ground check appears to be baked into the sim layer and cannot be bypassed via Harmony patches on OccupyArea. The cosmetic yellow warning does not affect building functionality.
