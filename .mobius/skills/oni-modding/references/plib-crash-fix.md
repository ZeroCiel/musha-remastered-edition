# PLib Crash Fix (Unity 6000 / TMPro.FaceInfo)

## Problem
PLib v4.24.0.0 and all earlier versions crash when rendering PLib options UI (dropdown/combo box) due to `TMPro.FaceInfo` being removed from Unity.TextMeshPro in Unity 6000.

## Status
**UNRESOLVED as of June 2026**. No version of PLib exists that works with ONI U59-737790+ (Unity 6000.3.5f2).

## Workaround
Avoid PLib entirely for new mods. Use raw Harmony patches and direct JSON config files.
