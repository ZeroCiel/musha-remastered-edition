# Coral Min Temp (氧齿珊瑚/浮游珊瑚 15°C) Mod — Session 2026-06-25

## Problem

Mod was showing as "过期/outdated" in the ONI mod menu.
Temperature change (setting lethalLowTemp=15) was not taking effect.

## Root Cause — "过期" Flag

The `mod.yaml` had extra fields (`APIVersion`, `version`, `author`, `supportedContent`) that caused `Recoverable parse error` in the game's YAML parser. The game still loaded the mod but marked it as outdated.

**Fix:** Keep `mod.yaml` minimal (3 fields only, same as working local mods like FlydoMiningHotfix):

```yaml
title: "Coral Min Temp 15°C"
description: "修改珊瑚（氧齿珊瑚、浮游珊瑚）最低生长温度为15°C"
staticID: CoralMinTemp15C
```

Put version info in `mod_info.yaml`:

```yaml
minimumSupportedBuild: 587362
version: 1.0.0
APIVersion: 2
```

## Root Cause — Temperature Not Changing

`Player.log` showed `[CoralMinTemp] Patched OxyCoralConfig.CreatePrefab` — the Harmony patch registered successfully.
BUT no `lethalLowTemp` or `warningLowTemp` modification was logged.

The Postfix found `PlantablePlot` component but the reflection for `lethalLowTemp` returned null — this field was removed or renamed in U59-737790.

**Current debugging approach:** Dump all components + all float fields on the prefab to discover the actual temperature field names.

## Mod Directory Structure

```
mods/Local/CoralMinTemp/
├── mod.yaml          # title, description, staticID only
├── mod_info.yaml     # minimumSupportedBuild: 587362, version, APIVersion
├── CoralMinTemp.cs   # source code
├── CoralMinTemp.csproj
├── CoralMinTemp.dll  # copied from bin/Release/ after each build
├── bin/Release/      # build output
└── obj/              # intermediate
```

## Key Lesson

When a Harmony patch loads successfully but produces no effect, the symptom is **silent field miss** — the Postfix runs but the reflected field name doesn't exist in this game version. Always dump the object to discover current field names.
