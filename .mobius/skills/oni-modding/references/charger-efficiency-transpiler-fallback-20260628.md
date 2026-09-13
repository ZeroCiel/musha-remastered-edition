# Charger Efficiency Mod (Transpiler → Game.LateUpdate Fallback)

## Workshop Mod Info

- **Workshop ID:** 3745786025
- **staticID:** `yidongdianyuanxiaolv`
- **Title:** "移动电池充电器效率提高到98.3%"
- **DLL in legacy.bin (extracted):** `C:\Users\Administrator\AppData\Local\Temp\charger_mod.dll`
- **Size:** 8,704 bytes
- **Locale:** Chinese (filename in legacy.bin is Chinese-named)

## Original Mod Intent

Modifies `ElectrobankCharger.ChargeInternal` to change charge efficiency:
- Original: ~50% (240J/s charge, 480W power draw)
- Target: ~98.3% (472J/s charge, 480W power draw, heat halved)

## Mod Architecture (Original)

The original mod uses a **Transpiler** (IL rewrite) on `ElectrobankCharger.ChargeInternal`. It defines constants:

```
ORIGINAL_CHARGE_RATE = 240
NEW_CHARGE_RATE = 472
ORIGINAL_POWER_COST = 0.48f
NEW_POWER_COST = 0.48f (unchanged)
NEW_EFFICIENCY = 0.983f
NEW_SELF_HEAT = (halved)
```

Also has `CreateBuildingDef_Patch` (Postfix) to modify `SelfHeatKilowattsWhenActive` and `ExhaustKilowattsWhenActive`.

## Why It Broke in U59

The Transpiler pattern-matches specific IL instructions in `ChargeInternal`. In different game builds, the C# compiler may generate different IL sequences — the pattern match silently fails. The mod **compiles and loads without errors** but produces zero effect. No crash, no log output.

## Replacement: Game.LateUpdate Per-Frame Boost

### Key: ElectrobankCharger IS NOT a UnityEngine.Object

**CRITICAL:** `ElectrobankCharger` is a plain C# class (StateMachine definition). You CANNOT use:

```csharp
UnityEngine.Object.FindObjectsOfType<ElectrobankCharger>(); // ❌ CS0311: cannot use as type parameter
```

Instead, scan all GameObjects:

```csharp
var allGo = UnityEngine.Object.FindObjectsOfType<UnityEngine.GameObject>();
foreach (var g in allGo)
{
    var charger = g.GetComponent(typeof(ElectrobankCharger));
    if (charger == null) continue;
    // ... process
}
```

### Battery boost via reflection

Battery does NOT have an `AddJoules` method in compile-time API. Use reflection on the `charge` field:

```csharp
var chargeField = typeof(Battery).GetField("charge",
    BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
if (chargeField != null)
{
    float cur = (float)chargeField.GetValue(battery);
    float newCharge = Math.Min(cur + extraJoules, battery.capacity);
    chargeField.SetValue(battery, newCharge);
}
```

### Finding the battery from ElectrobankCharger

```csharp
// ElectrobankCharger has a field "electrobank" pointing to the electrobank GameObject/Component
var field = charger.GetType().GetField("electrobank",
    BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
var eb = field.GetValue(charger);

// eb might be Component or GameObject:
if (eb is Component comp)
    return comp.GetComponent<Battery>();
if (eb is GameObject go)
    return go.GetComponent<Battery>();
```

### Full OnLateUpdate pattern

```csharp
public static void OnLateUpdate(Game __instance)
{
    if (__instance == null) return;
    
    var allGo = UnityEngine.Object.FindObjectsOfType<UnityEngine.GameObject>();
    List<object> chargers = null;
    foreach (var g in allGo)
    {
        var sm = g.GetComponent(typeof(ElectrobankCharger));
        if (sm != null)
        {
            if (chargers == null) chargers = new List<object>();
            chargers.Add(sm);
        }
    }
    if (chargers == null || chargers.Count == 0) return;

    float dt = UnityEngine.Time.deltaTime;
    float extra = 232f * dt; // 472 - 240 = 232 J/s

    foreach (var charger in chargers)
    {
        var g = (charger as Component)?.gameObject;
        if (g == null) continue;
        
        var operational = g.GetComponent<Operational>();
        if (operational == null || !operational.IsActive) continue;
        
        // Find battery (see above) and boost charge
    }
}
```

## Build Summary

- **Target:** ElectrobankChargerConfig.CreateBuildingDef (Postfix) + Game.LateUpdate (Postfix)
- **Exact code used:** `D:\Backup\Documents\Klei\OxygenNotIncluded\mods\Local\ChargerEfficiency\ChargerEfficiency.cs`
- **Mod files:** mod.yaml + mod_info.yaml + ChargerEfficiency.dll
- **Result:** Compiled (1 warning: FindObjectsOfType deprecation), deployed to mods/Local/ChargerEfficiency/
