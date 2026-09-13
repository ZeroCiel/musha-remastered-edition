# RoomProber Tuning Investigation (U59-737790)

## Goal

Find the hardcoded room size limit in RoomProber that persists even after removing all `additional_constraints` from a RoomType.

## Attempted Approaches

### 1. Finding RoomProber.Tuning fields via reflection at runtime

```csharp
var tuningType = typeof(RoomProber).GetNestedType("Tuning",
    BindingFlags.Public | BindingFlags.NonPublic);
foreach (var f in tuningType.GetFields(
    BindingFlags.Public | BindingFlags.Static | BindingFlags.NonPublic))
{
    Debug.Log("Tuning." + f.Name + " = " + (f.GetValue(null) ?? "null"));
}
```

**Result**: Not fully tested — see Player.log for output if this code runs.

### 2. Metadata search in Assembly-CSharp.dll

The string `RoomProber|Tuning` was found in Assembly-CSharp.dll's metadata at offset ~14017815, but the immediate surrounding context (`RoomProber|Tuning`, `RoomProber|Cell`, `RoomProber|Generation`, etc.) was just the TypeRef table — NOT the actual field definitions. The Tuning class's static fields may be named with standard C# conventions (e.g. `MAX_ROOM_SIZE`, `CREATURE_PEN_MAX_SIZE`, etc.) but these names were not discovered because they don't appear in the metadata strings heap near the TypeRef.

### 3. CavityBuilder.Run() method

The `RoomProber.CavityBuilder` nested class has a `Run()` method that constructs rooms from cavities. This method likely reads the room size from RoomProber's static configuration. The Harmony attribute `[HarmonyPatch(typeof(RoomProber.CavityBuilder), "Run")]` might be the correct target for intercepting room size enforcement.

## What to Try Next

1. **Log ALL static fields of ALL Tuning/Config classes** by dumping via reflection:
   - `typeof(RoomProber).GetNestedTypes(BindingFlags.Public|BindingFlags.NonPublic)` → find all nested types
   - For each: `GetFields(BindingFlags.Public|BindingFlags.Static|BindingFlags.NonPublic)` → log all values

2. **Scan `RoomProber` private fields** for a reference to room size configuration

3. **Search for `96` or `CREATURE_PEN` in Assembly-CSharp.dll** — the max size 96 is likely a const/readonly somewhere:
   ```python
   import re
   with open("Assembly-CSharp.dll", "rb") as f:
       data = f.read()
   # Search for 96 as a 4-byte int32 literal
   for m in re.finditer(rb'\x60\x00\x00\x00', data):
       ctx = data[max(0,m.start()-50):m.end()+50]
       # Check if context relates to rooms
   ```
