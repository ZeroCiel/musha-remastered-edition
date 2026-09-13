# ElectrobankCharger U59 Type Discovery (2026-06-29)

## Key Facts

- `ElectrobankCharger` is a **plain C# class** (StateMachine definition), NOT a `UnityEngine.Object`.
- `FindObjectsOfType<ElectrobankCharger>()` → **compiler error**: `CS0311: type cannot be used as generic type parameter 'T' in Object.FindObjectsOfType<T>()`
- `ElectrobankCharger` is NOT a `Component` either → can't cast `charger as UnityEngine.Component`

## How to Find ElectrobankCharger Instances

Scan all GameObjects and filter by component type:
```csharp
var allGo = Object.FindObjectsOfType<GameObject>();
foreach (var g in allGo)
{
    var sm = g.GetComponent(typeof(ElectrobankCharger));
    if (sm != null) { /* found one */ }
}
```

## How to Check if Charger is Running

`ElectrobankCharger` has no direct `gameObject` property accessible without reflection. Use the `smi` (StateMachineInstance) property:
```csharp
var smiProp = charger.GetType().GetProperty("smi",
    BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
object smi = smiProp?.GetValue(charger);
var goProp = smi.GetType().GetProperty("gameObject",
    BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
var go = goProp.GetValue(smi) as GameObject;
var operational = go.GetComponent<Operational>();
```

## How to Find Battery (electrobank field)

The `electrobank` field holds a Component reference (probably an Electrobank itself, not a Battery). Cast to `UnityEngine.Component` first, then `GetComponent<Battery>()`:
```csharp
var ebField = charger.GetType().GetField("electrobank", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
var eb = ebField.GetValue(charger);
if (eb is UnityEngine.Component comp)
    return comp.GetComponent<Battery>();
```

## How to Boost Charge (No AddJoules Method)

`Battery` has NO `AddJoules` method. Use reflection on the `charge` field:
```csharp
var chargeField = typeof(Battery).GetField("charge",
    BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
float cur = (float)chargeField.GetValue(battery);
float newVal = System.Math.Min(cur + extraJoules, battery.capacity);
chargeField.SetValue(battery, newVal);
```
