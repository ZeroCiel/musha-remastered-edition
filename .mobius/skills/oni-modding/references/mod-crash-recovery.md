# ONI Mod Crash Recovery & DLL Deployment

## Mod Crash → Auto-Disable

If a Harmony patch throws an exception during `OnLoad` / DLL loading, ONI marks the mod as **damaged**. On next launch, the DLL is **silently skipped** — no `Loading MOD dll:` line in Player.log. The mod still appears in Mods menu but won't load code.

**Fix sequence:**
1. Close game
2. Replace broken DLL with fixed version (all `.dll` files in the mod root)
3. Delete any backup `.dll` files from the mod root directory (see "Backup DLL Conflict" below)
4. Open game → Mods menu → **manually re-enable** the mod → restart game

## DLL Deployment Trap

ONI loads `mods/Local/<ModName>/<ModName>.dll` (the **root** of the mod directory), NOT `bin/Release/` subdirectory.

**After `dotnet build -c Release`, always copy the DLL:**
```bash
cp bin/Release/MyMod.dll /d/Klei/mods/Local/MyMod/MyMod.dll
```

**Confirm with:** check for `Loading MOD dll:` in Player.log. Absent = game skipped the DLL (mod disabled or wrong path).

## Backup DLL Conflict

Putting a backup DLL (e.g. `LargeDischarger2000W_4000W.dll`) in the mod root causes ONI to load it as a **second mod instance** with the same staticID.

**Symptoms in Player.log:**
```
Loading MOD dll: LargeDischarger2000W.dll
Loading MOD dll: LargeDischarger2000W_4000W.dll
HarmonyException: Undefined target method for patch method ...DischargerConfigPatch::Postfix
Exception while loading mod ...disabling
```

**Fix:** Delete all backup DLLs from the mod root. Keep backups outside `mods/Local/`.

## Reading Player.log to Diagnose Mod Issues

Key patterns to grep:
- `Loading MOD dll:` — present = DLL loaded; absent = mod skipped/disabled
- `\[MyMod\]` — mod debug logs (custom Debug.Log calls)
- `Undefined target method` — class name mismatch in `AccessTools.TypeByName()`
- `Exception while loading mod` — mod threw during OnLoad
- `Failed to load mod ...disabling` — mod was auto-disabled
