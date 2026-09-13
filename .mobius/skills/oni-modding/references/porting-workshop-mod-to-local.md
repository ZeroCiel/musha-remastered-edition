# Porting Workshop Mods to Local (for older game builds)

When a workshop mod in Steam cache (`legacy.bin`) requires a newer game build than your ONI version (e.g. 707956 vs your 587362), you can extract and port it to local mods.

## Steps

### 1. Locate the Workshop mod

```
C:\Program Files (x86)\Steam\steamapps\workshop\content\457140\<workshop_id>\<hash>_legacy.bin
```

The `legacy.bin` is a plain ZIP archive. Extract with Python:

```python
import zipfile
zp = "C:/Program Files (x86)/Steam/.../<hash>_legacy.bin"
target = "D:/Backup/Documents/Klei/OxygenNotIncluded/mods/Local/<ModName>"
with zipfile.ZipFile(zp) as z:
    z.extractall(target)
```

### 2. Modify `mod_info.yaml`

Change `minimumSupportedBuild` to 587362 (your build).

**Do NOT change** `APIVersion` or other fields.

### 3. Check & translate `mod.yaml`

Change title/description to Chinese if desired. Example:

```yaml
title: 无线供电
description: 通过无线电池、发送器和接收器网络，无需铺设电线即可传输电力。
```

### 4. Translate `.po` files

ONI mods use gettext `.po` files stored in `translations/`:

- The mod DLL calls `DetectLanguageCode()` internally
- It loads `translations/<lang>.po` matching the system locale
- Chinese = `zh.po`

Steps:
1. Copy `translations/en.po` → `translations/zh.po`
2. Translate all `msgstr` lines. Keep `msgid` (the key) unchanged
3. Header line: change `"Language: en"` to `"Language: zh"`
4. Keep `Content-Type: charset=UTF-8` as-is

### 5. Translate `description.txt`

This is the Steam workshop description. Translate as needed.

### 6. Done — no recompilation needed

DLLs are binary-compatible across same-major-version game builds. Only recompile if the mod uses C# features from a newer compiler.

## Known Workshop IDs

| ID | Name | staticID | 
|---|---|---|
| 3714990201 | Flydo Aerial Mining | FlydoAerialMining |
| 3671679281 | Wireless Power | WirelessPower.Dev |

## Dependency DLLs

Some mods bundle helper libraries (PLib, Zolibrary). Extract them alongside the main DLL. They're typically version-agnostic.
