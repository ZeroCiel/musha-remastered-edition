# Workshop Room Size Mod 3374595157 — Analysis

## Info
- **Name:** "Modify Room Size 修改房间大小"
- **StaticID:** "RoomSize"
- **Workshop URL:** steamcommunity.com/sharedfiles/filedetails/?id=3374595157
- **Build:** 469112
- **Contents:** PLib.dll + Roomsize.dll

## Structure
The bin file (14285557663373856494_legacy.bin) is a valid ZIP containing:
```
Controller.json       (328 bytes)  — PLib config
mod.yaml              (129 bytes)  — title/description/staticID
mod_info.yaml         (85 bytes)   — supportedContent/minimumSupportedBuild/version/APIVersion
PLib.dll              (337920 bytes)
Roomsize.dll          (16384 bytes)
```

## Why It Doesn't Work on Modern ONI
1. **PLib dependency**: Roomsize.dll relies on PLib.dll for config UI. PLib references `TMPro.FaceInfo` which was removed in Unity 6000. Even if the DLL loads, it crashes when opening the settings dialog.
2. **Build 469112**: Too old. The RoomProber internals it patches may no longer exist.
3. **Size enforcement method**: The mod works by patching RoomProber internals (not RoomType constraints). In newer ONI builds, RoomProber's hardcoded size checks override these patches.

## To Recreate (Without PLib)
See [big-pen-only-session-20260620.md](references/big-pen-only-session-20260620.md) for detailed analysis of why RoomType constraint modification doesn't work. The ONLY reliable approach would be patching RoomProber.CavityBuilder.Run() at the IL level — not feasible with simple Harmony postfix/prefix.
