# Steam Workshop Mod File Locations (ONI)

## Workshop Mod Storage

ONI workshop mods are stored in two locations:

### 1. Steam Workshop Cache (Legacy Bin)
```
C:\Program Files (x86)\Steam\steamapps\workshop\content\457140\<workshop_id>\16373731911900856938_legacy.bin
```
The `legacy.bin` is a **ZIP archive** containing the mod files (mod.yaml, .dll, etc.).
ONI reads directly from this archive — it is NOT extracted to a folder.

To inspect contents with Python:
```python
import zipfile
with zipfile.ZipFile(zp) as z:
    for n in z.namelist():
        print(n)  # e.g. "FlydoAerialMining.dll", "mod.yaml", "mod_info.yaml"
    dll_data = z.read("FlydoAerialMining.dll")
```

No `strings`/`grep` on the binary works — extract the DLL first.

### 2. Steam Workshop Extracted (Mods/Steam/)
```
D:\Backup\Documents\Klei\OxygenNotIncluded\mods\Steam\<workshop_id>\mod.yaml
D:\Backup\Documents\Klei\OxygenNotIncluded\mods\Steam\<workshop_id>\<ModName>.dll
```
This is where ONI copies mods after extraction. NOT all workshop mods appear here — some remain only in the legacy.bin.

### Known Workshop IDs

| ID | Name | staticID | 
|---|---|---|
| 3714990201 | Flydo Aerial Mining | FlydoAerialMining |
| 3671679281 | Wireless Power | WirelessPower.Dev |

## Finding a Mod by Workshop ID

If you can see the mod enabled in-game but can't find its files:

1. Check `Mods/Steam/<id>/` first
2. If not there, check `steamapps/workshop/content/457140/<id>/` for `legacy.bin`
3. Extract the DLL from the legacy.bin to inspect class/method names

## Harmony Hotfix for Workshop-Only Mods

When your hotfix mod needs to patch a class from a **workshop** mod (not in game's Assembly-CSharp.dll):

1. **`FindType()` approach** (current in FlydoMiningHotfix): searches all loaded assemblies by iterating `AppDomain.CurrentDomain.GetAssemblies()` every Update frame until the target type is found. This can fail if the workshop DLL hasn't loaded yet when the coroutine runs.

2. **Delayed patching via coroutine**: Use a Unity MonoBehaviour's `Update()` to retry the FindType/find-method approach every second. This is what FlydoMiningHotfix does — but it relies on the type being in a loaded assembly, which depends on game load timing.

3. **Alternative approach not yet tested**: Register the hotfix as a Harmony patch on a KNOWN-WORKING game class (e.g. `*Config.CreateBuildingDef`) and from there, schedule the delayed FindType approach.
