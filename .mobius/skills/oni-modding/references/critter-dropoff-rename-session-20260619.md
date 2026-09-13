# CritterDropOff → CreatureDeliveryPoint Rename (2026-06-19 Session)

## The Problem

A 2023 BiggerCritterDropOff mod (shipped as `CritterDropOff` in old ONI) crashed on startup in ONI U59-737790 (June 2026). Player.log showed:

```
HarmonyLib.HarmonyException: Patching exception in method 
    static System.Reflection.MethodBase BiggerCritterDropOff.BiggerDropOffPatch::TargetMethod()
    ---> System.Exception: Method static System.Reflection.MethodBase 
    BiggerCritterDropOff.BiggerDropOffPatch::TargetMethod() returned an unexpected result: null
```

Root cause: `CritterDropOff.OnSpawn` no longer exists. The class was renamed.

## Diagnosis: Binary String Search

Used Python to search Assembly-CSharp.dll for `CritterDropOff`:

```python
import os, re
f = r'C:\Program Files (x86)\Steam\steamapps\common\OxygenNotIncluded\OxygenNotIncluded_Data\Managed\Assembly-CSharp.dll'
with open(f, 'rb') as fh:
    data = fh.read()
matches = [m.start() for m in re.finditer(b'CritterDropOff', data)]
print('Found at offsets:', matches)
```

Found `CritterDropOffConfig` (the building config class) at 3 offsets. The old runtime class `CritterDropOff` was removed entirely.

## Solution

Two approaches that work with modern ONI:

### Approach A: Patch the runtime class

```csharp
[HarmonyPatch(typeof(CreatureDeliveryPoint), "OnSpawn")]
public static class DropOffPatch
{
    static void Postfix(object __instance)
    {
        var capacity = __instance as IUserControlledCapacity;
        if (capacity != null)
            capacity.UserMaxCapacity = 1000;
    }
}
```

### Approach B: Also patch CreatureFeeder for fish feeders

```csharp
[HarmonyPatch(typeof(CreatureFeeder), "OnSpawn")]
public static class FeederPatch
{
    static void Postfix(object __instance)
    {
        var capacity = __instance as IUserControlledCapacity;
        if (capacity != null)
            capacity.UserMaxCapacity = 1000;
    }
}
```

## Key Learnings

- `CritterDropOff` → `CritterDropOffConfig` (building config, creates BuildingDef/GoTo)
- `CritterDropOff` runtime class → `CreatureDeliveryPoint` (implements IUserControlledCapacity)
- Fish feeder runtime class → `CreatureFeeder` (also implements IUserControlledCapacity)
- Both `CreatureDeliveryPoint` and `CreatureFeeder` exist in Assembly-CSharp.dll, not in a separate assembly
- Using `[HarmonyPatch(typeof(X), "Y")]` with the correct type name is SAFER than `TargetMethod()` + reflection when the ONI version is known — csc validates the type at compile time

## Compiled DLL Size

The output `BiggerCritterDropOff.dll` was 5120 bytes (5KB) using csc direct compilation with -noconfig -nostdlib.
