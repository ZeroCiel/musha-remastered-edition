# PLib Options Bypass — Unity 6000 Crash Workaround

## Problem

PLib.dll (any version up to v4.24.0.0) crashes on ONI U59-737790+ (Unity 6000) when opening any PLib-based mod's options/settings dialog:

```
TypeLoadException: Could not resolve type with token 010001ce from typeref
  (expected class 'TMPro.FaceInfo' in assembly 'Unity.TextMeshPro')
  at PeterHan.PLib.UI.PComboBox`1[T].SetMinWidthInCharacters (...) in <...>:0
```

## Root Cause

Unity 6000 removed `TMPro.FaceInfo` from Unity.TextMeshPro. PLib's `PComboBox` (used in options UI dropdowns) accesses this class directly.

## Workaround: Edit Config Files Directly

Most PLib-based mods store their configuration in plain-text files. Common locations:

1. **`Controller.json`** (in mod folder) — used by RoomSize mod and similar
2. **`<StaticID>.json`** (in `config/` directory or mod folder)
3. **`mod.yaml`** — rarely, some mods read from here

Example (RoomSize mod):
```json
{
  "NatureReserve": 0,
  "Laboratory": 2,
  "Latrine": 2,
  "CreaturePen": 904   // 96 + 904 = 1000
}
```

## Permanent Fix

Write a new Harmony mod that doesn't use PLib. For config storage, use a simple JSON file in the mod directory. See [Room Type Constraint Modding](references/room-type-constraint-modding.md) for the full approach.
