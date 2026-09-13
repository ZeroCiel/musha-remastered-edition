# Flydo Speed Mod — Session Notes

## Goal
Create a Harmony mod that multiplies Flydo (飞寻机) movement speed by configurable factor.

## Key Discoveries

### Prefab Identity
- Flydo's C# class name is **`FetchDrone`** — NOT `"Flydo"` or `"FlydoConfig"`
- `FetchDroneConfig` is its building config class
- The prefab ID string in-game is `"FetchDrone"` (not `"Flydo"`)
- `STRINGS.ROBOTS+MODELS|FLYDO` is only a localization key, NOT the prefab name

### Navigation Type Distinction
Two robot types exist in ONI's robotic system:
| Robot | C# Class | Navigation Type | abilities TypeName |
|-------|----------|----------------|-------------------|
| Flydo (飞寻机) | `FetchDrone` | `FlyerNavigation` | Contains `"Flyer"` |
| SweepBot (扫地机) | `SweepBot` | `RobotGrid1x1` | Contains `"Grid"` (no "Flyer") |

To distinguish them: check `navigator.abilities.GetType().Name.Contains("Flyer")`.

### Speed Field
- `Navigator.defaultSpeed` is a public `float` field — no reflection needed
- Value is set during `OnPrefabInit`/`OnSpawn` by `FetchDroneConfig.CreatePrefab`

### Mod Structure
- Mod directory: `mods/local/FlydoSpeedTweak/`
- Files: `FlydoSpeedTweak.cs`, `FlydoSpeedTweak.dll`, `mod.yaml`, `mod_info.yaml`
- Uses old-style Harmony (class-level `[HarmonyPatch]`, no per-method attributes)
- Patches: `FetchDrone.OnSpawn` + `FetchDrone.OnPrefabInit` (fallback)

### Compilation
```bash
# SDK-style .csproj (preferred)
dotnet build -c Release --nologo -v q
# Copy DLL to mod root
cp bin/Release/FlydoSpeedTweak.dll mods/local/FlydoSpeedTweak/
```

### Config (Simple)
Hardcoded multiplier in `FlydoSpeedTweakMod.SpeedMultiplier`. To make configurable, add a JSON config file reader or migrate to PLib (not recommended — PLib crashes on Unity 6000).

## Migration of ControlYourRobots

Workshop ID: 3086964745
Static ID: `Sanchozz.ONIMods.ControlYourRobots`
Dependencies: `PLib.dll` (PeterHan's Library)

### Migration Steps
1. Copy DLL + mod.yaml + mod_info.yaml + anim/ + translations/ from Steam to local
2. Update `minimumSupportedBuild` to match game version (587362)
3. Translate `zh.po` — completed with all 17 keys translated
4. Update `mod.yaml` with Chinese title/description

### PO Translation Notes
- `msgctxt` strings must stay exact (they're lookup keys)
- Only fill `msgstr "..."`
- The `ru.po` was helpful as a reference to ensure all keys were covered
- Flydo = 飞寻机, SweepBot = 扫地机, MorbRover = 探测车, Biobot = 生物机器人
- "Sleep Mode" tooltip has an Easter egg: "Do robots dream of electric Dreckos?" → "机器人会梦见电子龙鳞壁虎吗？"
