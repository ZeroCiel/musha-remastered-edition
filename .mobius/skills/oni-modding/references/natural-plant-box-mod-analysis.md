# Natural Plant Box (自然种植盒) Mod Analysis

**Workshop ID:** 3243440327 — `piapiNaturalPlantBox`
**Title:** 自然种植盒 (Natural Plant Box) v1.6.2
**Author:** pronoses (Chinese modder)
**Last update:** 2025-06-13 (Frosty Planet is supported per tags but may not include all Frosty plants)
**StaticID:** `piapiNaturalPlantBox`

## What It Does

Provides a custom planter box building that, when a seed is planted:
1. Accepts the seed via standard `PlantablePlot` / `SingleEntityReceptacle` mechanism
2. On `MoveNext` (the coroutine that spawns the plant after planting), Harmony Prefix/Postfix intercept:
   - The planter box `DeleteObject`s itself
   - The plant is spawned as a **wild plant** on the tile below
   - Acts as a tree-planting alternative without the planting restrictions

## DLL Structure (from string extraction)

Key classes/references found in the DLL:
- **`PiapiPlantHelperConfig`** — custom `IBuildingConfig` for the planter box building
- **`PlantablePlot.MoveNext`** — Harmony patch target (the coroutine step where the occupied object spawns)
- **`HarmonyPatch`** + **`Prefix`** / **`Postfix`** — on `PlantablePlot.MoveNext`
- **`AddDepositTag`** — called on `BuildingDef` to register accepted seeds
- **`Database.NoFarmables`** — referenced (the mod may patch this list)
- **`FARMABLE`** / **`NONE`** — Building category tags
- **`PlantableSeed`**, **`CropSeed`**, **`WaterSeed`**, **`DecorSeed`** — seed type tags

## How a New DLC Plant Might Be Missing

The planter box registers which seeds it accepts via `AddDepositTag()` on the `BuildingDef`. If a DLC plant (e.g. Frosty Planet's Bulb Plant) uses a different seed tag or has its tag not in the mod's whitelist, the seed won't show up in the planter box UI.

**Possible causes:**
1. The mod's `possibleDepositObjectTags` doesn't include the seed's tag
2. The Harmony patch on `MoveNext` doesn't handle the plant's specific spawn behavior
3. The plant's Config class isn't in the mod's patching logic

## Diagnostic Approach

1. Open game → build Natural Plant Box → check if Bulb Plant seed appears in the plantable list
2. If missing: the seed tag isn't in the whitelist → needs a DLL patch
3. If present but planting fails/hangs: the MoveNext patch doesn't handle it → different fix

## Current Status (2026-06-26)

- Mod exists locally at `mods/Steam/3243440327/`
- User wants to add Bulb Plant (水星包/Frosty Planet light plant) support
- DLL is small (10KB) and Dotfuscated — hard to decompile without dnSpy/ILSpy
- Fix approach: either patch the DLL directly at byte level, or write a separate Harmony patch mod that makes the planter box accept the Bulb Plant seed tag
