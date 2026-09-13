# Reverse-Engineering ONI APIs from Assembly-CSharp.dll

When writing Harmony patches for ONI mods, you often need to know what methods, properties, and fields exist on game classes — but these are frequently private, internal, or renamed between versions. The DLL binary contains all class/member names as readable ASCII strings.

## How to Extract API Strings

Use `execute_code` (Python with `re.finditer` from binary) to scan `Assembly-CSharp.dll`:

```python
import re

dll = r"C:\Program Files (x86)\Steam\steamapps\common\OxygenNotIncluded\OxygenNotIncluded_Data\Managed\Assembly-CSharp.dll"

with open(dll, "rb") as f:
    data = f.read()

strings = set()
for m in re.finditer(rb'[\x20-\x7e]{4,}', data):
    s = m.group().decode('ascii', errors='ignore')
    if "TargetClass" in s:  # filter by class name
        strings.add(s)

for s in sorted(strings):
    print(s)
```

## What You Can Discover

### Class hierarchy (from source path strings)
Look for paths like `Assets\scripts\game\Buildings\OilRefinery.cs` — these tell you the inheritance chain:

```
KMonoBehaviour/Workable/ComplexFabricatorWorkable
KMonoBehaviour/scripts/ComplexFabricator
```

Reading the path: `OilRefinery` inherits from (or contains) `ComplexFabricator`, and `ComplexFabricatorWorkable` inherits from `Workable` → `KMonoBehaviour`.

### Property names (backing fields)
```
<ElementConverter>k__BackingField       → property `ElementConverter` exists
<outputElements>k__BackingField          → property `outputElements` exists
```
The `<PropertyName>k__BackingField` pattern means there is an auto-implemented property.

### Method names (from member refs)
```
get_ElementConverter                     → property getter
set_ElementConverter                     → property setter
get_OutputCellOne                        → property getter
WorkableStartWork                        → method (may be private/protected)
WorkableCompleteWork                     → method
WorkableCompleteTransition               → method
ConvertMass                              → private method
```

### State machines
Pattern: `ClassName|StatesInstance` and `ClassName|States` indicate a `StateMachine` inner class:
```
OilRefinery|States            → state machine definition
OilRefinery|StatesInstance    → state machine instance
OilRefinery|WorkableTarget    → workable target state
ComplexFabricatorSM|States    → complex fabricator state machine
```

### Event/fire strings
```
FabricatorOrderStarted
FabricatorOrderCompleted
FabricatorOrdersUpdated
```
These are often `GameHashes` or trigger names for state transitions.

## Practical: Finding What Changed Between ONI Versions

1. Extract strings from both old and new `Assembly-CSharp.dll`
2. Diff the outputs to find renamed/removed members
3. Search by feature: `ElementConverter`, `OilRefinery`, `Storage`, `ComplexFabricator`, `Workable`

## Known API Shifts (as of June 2026)

| Search term | Found in old DLL | Found in new DLL | Conclusion |
|---|---|---|---|
| `ElementConverter` | 🟢 | 🟢 | Still exists |
| `ElementConverter.Run` | 🟢 | 🟢 (in strings) | Method exists |
| `ElementConverter.ConvertMass` | 🟢 | 🟢 | **Use this for reflection** |
| `OilRefinery.outputElements` | 🟢 | ❌ | Moved to `ElementConverter` |
| `OilRefinery.ConvertInputs` | 🟢 | ❌ | Removed entirely |
| `ComplexFabricatorWorkable.WorkableStartWork` | ❌ | ❌ | Not exposed (protected) |
| `ComplexFabricator.RequestRecipe` | ❌ | ❌ | Not available |
| `ComplexFabricator.CurrentWorkingRecipe` | ❌ | ❌ | Not available |

## Pitfalls

- `strings` CLI tool (`/usr/bin/strings`) often fails on bash git-bash with exit code 49 (broken pipe on slow reads). Use Python's `re.finditer` on binary data instead.
- Not all methods in the DLL are public — `BindingFlags.NonPublic` is often required for reflection targets.
- A method name appearing in strings doesn't guarantee the exact signature — check parameter count and types.
- `ComplexFabricatorWorkable` inherits from `Workable` but its work methods (`WorkableStartWork`) are `protected` — cannot be called externally without reflection or a subclass.
- OilRefinery in modern ONI (~2026+) is state-machine-driven via `ComplexFabricatorSM`, not direct method calls. The correct hook point is `ElementConverter.ConvertMass` (private, reflection).
