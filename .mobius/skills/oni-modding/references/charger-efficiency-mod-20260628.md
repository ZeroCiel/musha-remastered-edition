# Charger Efficiency Mod (98.3%)

Workshop mod 3745786025: "移动电池充电器效率提高到98.3%"

## Problem

Workshop mod uses a Transpiler to modify `ElectrobankCharger.ChargeInternal` IL.
In U59-737790, the IL structure changed → Transpiler silently fails (no error, no effect).

## Mod Structure (Rewritten for U59)

Two patches in `OnLoad`:

1. **`ElectrobankChargerConfig.CreateBuildingDef` Postfix** — halves SelfHeat and ExhaustHeat
2. **`Game.LateUpdate` Postfix** — every frame, boost `Battery.charge` field via reflection by 232 J/s * dt (original is ~240 J/s, target is 472 J/s → +232 J/s)

## Key Implementation Details

- `ElectrobankCharger` is NOT a `UnityEngine.Object` → cannot use `FindObjectsOfType<ElectrobankCharger>()`. Scan all GameObjects and check `GetComponent(typeof(ElectrobankCharger))`.
- `Battery` has no `AddJoules()` method. Use reflection on `Battery.charge` field (private float).
- Cache charger→battery mapping in a Dictionary to avoid scanning every frame.
- Use `Patches.OnLateUpdate(Game __instance)` signature for Game.LateUpdate Postfix.
