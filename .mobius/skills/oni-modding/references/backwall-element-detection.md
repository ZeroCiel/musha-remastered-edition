# Backwall Element Detection in U59-737790

## Goal
Detect which cells have an Algae-element backwall (from Natural Backwall mod or natural worldgen) and produce oxygen there.

## Failed Approaches (U59-737790)

### ❌ `Grid.BackwallElement[cell]`
- **Does not exist** in U59. Compiler error if referenced.
- No public C# array exposes backwall element data.

### ❌ `Components.Buildings` scan
- **Does not exist** in U59. `CS0117: 'Components' does not contain 'Buildings'`.

### ❌ `FindObjectsOfType<BuildingComplete>()` + tag check
- Natural Backwall (3746622017) creates NO `BuildingComplete` GameObject.
- Only found `PropGravitasWall` etc. (decorative walls), no NaturalBackwall building.
- Logged 930 BuildingComplete objects, 0 were NaturalBackwall.

### ❌ `transform.parent` walk on Pickupable
- Background wall algae is NOT a Pickupable in a Storage parent.
- Background wall data lives entirely in the native sim layer.

### ❌ `BackwallManager.Instance`
- `BackwallManager` is a **static class** in U59.
- Cannot `FindObjectOfType<BackwallManager>()` — CS0718.
- Has no public `Instance` property.

### ❌ `Game.Instance.sim`
- `Game.sim` property does not exist in U59 (private/native field).

### ❌ `Grid.Element[cell]` check during LateUpdate loop
- Only finds the cell's PRIMARY element (gas/liquid/solid), not backwall.
- Cells with Algae backwall usually have O2/CO2/etc. as the primary element.
- Zero Algae elements found when looping all cells.

## Working Approach: Hook `SimMessages.SetBackwallData`

### Method Signature (U59)
```csharp
public static void SetBackwallData(int cell, ushort elemIdx, float mass, float temperature)
```

### Critical Implementation Detail
- `elemIdx` is `ushort`, NOT `int` — Harmony parameter matching is type-strict.
- `ElementLoader.GetElement(ushort)` does NOT work — that overload takes `Tag`.
- Use `ElementLoader.FindElementByHash(SimHashes.Algae).idx` to get the correct sim-level element index.
- Manual registration in `OnLoad` (NOT `[HarmonyPatch]` attribute) to handle graceful failure.

### Manual Registration Pattern
```csharp
MethodInfo targetMethod = typeof(SimMessages).GetMethod("SetBackwallData",
    BindingFlags.Public | BindingFlags.Static);
if (targetMethod != null)
{
    MethodInfo postfix = typeof(MyPatchClass).GetMethod("Postfix",
        BindingFlags.Static | BindingFlags.Public);
    harmony.Patch(targetMethod, postfix: new HarmonyMethod(postfix));
}
```

### Postfix Handler
```csharp
public static void Postfix(int cell, ushort elemIdx)
{
    Element element = ElementLoader.FindElementByHash(SimHashes.Algae);
    if (element == null) return;
    int algaeSimIdx = element.idx;
    if (elemIdx == algaeSimIdx)
        algaeBackwallCells.Add(cell);
    else
        algaeBackwallCells.Remove(cell);
}
```

### Each LateUpdate Tick
```csharp
foreach (int cell in algaeBackwallCells)
{
    if (!Grid.IsValidCell(cell)) continue;
    if (Grid.LightIntensity[cell] <= 0f) continue; // TODO: filter for fish light only
    if (Grid.Mass[cell] > 1.8f) continue;
    // emit 20g/s O2
}
```

### Limitations
1. **Only detects writes made while mod is loaded.** Pre-existing backwalls invisible.
2. **No initial scan possible** — no public read API for native sim backwall data.
3. **Re-writing with same material doesn't re-trigger** if already in HashSet.
4. **Only captures SetBackwallData calls** — if game uses a different path (load/save restore), those cells are missed.

## Natural Backwall Mod (3746622017) Summary
- staticID: `NaturalBackwallPlacer`
- Creates NO BuildingComplete, NO KMonoBehaviour, NO Storage, NO GameObject
- Writes sim data directly: calls `SimMessages.SetBackwallData` with material's element index
- Has `BuildLocationRule`, `Backwall` tag, `MakeBuildingAlwaysOperational`
- Only detectable via hooking the SimMessages call

## Final Verdict (June 2026)
**Backwall element detection from C# is unsupported in U59.** The only viable approach is hooking `SetBackwallData` writes, which has the critical flaw of missing pre-existing backwalls. For the Algae Oxygen mod, the recommended fallback is:
1. Ground pickups of Algae (Components.Pickupables, works reliably)
2. Manual cell registration by the player (hotkey or debug tool to mark cells)
3. Or, build a custom gas-permeable Algae tile building instead of using Natural Backwall
