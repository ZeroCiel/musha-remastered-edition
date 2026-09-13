# Automatic Oil Refinery Mod — Recompile History

## Workshop ID: 2836775275
## Local path: `mods/local/lianyouchang/`

## What it does

Makes Oil Refinery auto-run without duplicant operation:
1. Removes oxygen from output (only Petroleum)
2. Attaches `AutoRunController` (ISim200ms) that periodically calls `ElementConverter.ConvertMass`

## Compilation notes (U59-737790, June 2026)

- Compiled successfully with latest ONI libs
- `ElementConverter.outputElements` field still exists — no API change needed
- `ElementConverter.ConvertMass` method still exists — fallback logic also searches for `Convert`/`DoConvert`
- No mod_info.yaml changes needed except localization/title

## Key files

- `AutomaticOilRefinery.cs` — source (Harmony patches + AutoRunController)
- `mod_info.yaml` — standard format with `APIVersion: 2`
