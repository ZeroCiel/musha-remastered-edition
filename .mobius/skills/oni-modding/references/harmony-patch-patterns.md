# ONI Harmony Patch Patterns

## ⚠️ TargetMethods Null Element Crash

Harmony crashes hard if `TargetMethods()` yields `null`:

```
HarmonyLib.HarmonyException: Patching exception in method null
  ---> System.Exception: Method static IEnumerable<MethodBase> X::TargetMethods()
  returned an unexpected result: some element was null
```

**Fix**: Every yield must be behind a null check:

```csharp
static IEnumerable<MethodBase> TargetMethods()
{
    var type = AccessTools.TypeByName("SomeClass");
    if (type == null) yield break; // safe: empty enumerable
    var method = AccessTools.Method(type, "OnSpawn");
    if (method == null) yield break;
    yield return method;
}
```

## Class Name Discovery

`AccessTools.TypeByName()` fails if name is wrong. Find names in DLL metadata:

```python
import re
with open("Assembly-CSharp.dll", "rb") as f:
    text = f.read().decode("utf-8", errors="replace")
for m in re.finditer(r'[A-Z][a-zA-Z]*Discharger[A-Za-z]*\x00', text):
    print(m.group().replace('\x00',''))
```

**Rules**:
- Config class = `XxxConfig` (e.g. `LargeElectrobankDischargerConfig`)
- Building instance class = `Xxx` WITHOUT `Config` and WITHOUT size prefix (`Large`/`Small`)
  - ✅ `ElectrobankDischarger`
  - ❌ `LargeElectrobankDischarger`
- Source paths in DLL confirm filenames: `LargeElectrobankDischargerConfig.cs`

## Speed Mod (Flydo/FetchDrone)

```csharp
[HarmonyPatch]
public static class FetchDroneSpeedPatch
{
    static IEnumerable<MethodBase> TargetMethods()
    {
        var type = AccessTools.TypeByName("FetchDrone");
        var m = type != null ? AccessTools.Method(type, "OnSpawn") : null;
        if (m != null) yield return m;
    }
    static void Postfix(object __instance)
    {
        var kmb = __instance as KMonoBehaviour;
        var nav = kmb?.GetComponent<Navigator>();
        if (nav == null) return;
        var abilitiesField = AccessTools.Field(nav.GetType(), "abilities");
        var abilities = abilitiesField?.GetValue(nav);
        if (abilities == null || !abilities.GetType().Name.Contains("Flyer")) return;
        nav.defaultSpeed *= 4f;
    }
}
```

## ⚠️ Build 587362 (Old ONI): Harmony Does NOT Work At All

**This is the critical finding for this user's game version.** All `[HarmonyPatch]` attributes produce zero effect — no prefix/postfix/transpiler runs, no errors logged, no debug messages in Player.log. Confirmed across multiple mods:
- BigPenOnly (room size)
- GrantSwimSkill
- NoWaterStress
- AllDiversLung
- LargeDischarger2000W

**Root cause**: Unknown (old Harmony 2.4.2? game build quirk?), but trying to fix Harmony itself is a dead end.

**Workaround**: Coroutine-based approach via `Game.OnPrefabInit` patch (the ONE Harmony patch that actually fires):

```csharp
[HarmonyPatch(typeof(Game), "OnPrefabInit")]
public static class Game_OnPrefabInit_Patch
{
    static void Postfix()
    {
        Global.Instance.StartCoroutine(MyFixCoroutine());
    }

    static IEnumerator MyFixCoroutine()
    {
        yield return new WaitForSeconds(3f); // wait for game init
        while (true)
        {
            var buildings = Object.FindObjectsByType<BuildingComplete>(FindObjectsSortMode.None);
            foreach (var b in buildings)
            {
                if (b?.Def == null) continue;
                // fix logic here
            }
            yield return new WaitForSeconds(3f); // repeat
        }
    }
}
```

**Why this works**: `Game.OnPrefabInit` is patched via `[HarmonyPatch(typeof(Game), "OnPrefabInit")]` — this specific attribute target format may use a different patching path that survives. All other `[HarmonyPatch]` (on any other class) fails silently.

---

## Power Mod (Discharger/Generator) — COROUTINE APPROACH (for build 587362)

For generators (dischargers), the correct field is `GeneratorWattageRating`, NOT `EnergyConsumptionWhenActive`:

```csharp
[HarmonyPatch(typeof(Game), "OnPrefabInit")]
public static class Game_OnPrefabInit_Patch
{
    static void Postfix()
    {
        Global.Instance.StartCoroutine(FixDischargers());
    }

    static IEnumerator FixDischargers()
    {
        yield return new WaitForSeconds(3f);
        while (true)
        {
            var buildings = Object.FindObjectsByType<BuildingComplete>(FindObjectsSortMode.None);
            foreach (var b in buildings)
            {
                if (b?.Def == null) continue;
                if (b.Def.name.Contains("LargeElectrobankDischarger") && b.Def.GeneratorWattageRating < 1999f)
                {
                    b.Def.GeneratorWattageRating = 2000f;
                }
            }
            yield return new WaitForSeconds(3f);
        }
    }
}
```

**Correct field per building type**:
| Component | Field | Example |
|-----------|-------|---------|
| Generator (outputs power) | `GeneratorWattageRating` | Large Discharger, Manual Generator |
| Consumer (uses power) | `EnergyConsumptionWhenActive` | Liquid Tepidizer, Aquatuner |

### Class name references (confirmed for this build):
- Config: `LargeElectrobankDischargerConfig` (NOT `LargeDischargerConfig`)
- Instance: `ElectrobankDischarger` (no `Large` prefix)
- BuildingDef name contains: `LargeElectrobankDischarger`

### EnergyConsumer field candidates (may not exist on all builds):
- `WattageRating`
- `BaseWattage`
- `watageRating` (typo from old builds)
- `baseWattage`

Use `Traverse.Create(consumer).Field(fieldName)` to probe safely.

---

## Power Mod (Harmony direct approach — for newer ONI builds where Harmony works)

```csharp
[HarmonyPatch]
public static class PowerPatch
{
    static IEnumerable<MethodBase> TargetMethods()
    {
        var type = AccessTools.TypeByName("ElectrobankDischarger"); // NOT LargeElectrobankDischarger!
        var m = type != null ? AccessTools.Method(type, "OnSpawn") : null;
        if (m != null) yield return m;
    }
    static void Postfix(object __instance)
    {
        var kmb = __instance as KMonoBehaviour;
        var consumer = kmb?.GetComponent<EnergyConsumer>();
        if (consumer != null)
        {
            AccessTools.Field(consumer.GetType(), "WattageRating")?.SetValue(consumer, 2000f);
            AccessTools.Field(consumer.GetType(), "BaseWattage")?.SetValue(consumer, 2000f);
        }
        var bld = kmb?.GetComponent<BuildingComplete>();
        if (bld?.Def != null) bld.Def.GeneratorWattageRating = 2000f; // NOT EnergyConsumptionWhenActive!
    }
}
```

## Prevent OOM from Mod Update Spam

**Symptom**: `OutOfMemoryException: Out of memory` after hours of play. Check log for 100k+ lines from one mod.

**Pattern**: Throttle ISim200ms/ISim1000ms handlers:

```csharp
private static readonly Dictionary<object, float> _lastUpdate = new(16);

static bool Prefix(object __instance)
{
    float now = Time.realtimeSinceStartup;
    if (_lastUpdate.TryGetValue(__instance, out float last) && now - last < 0.8f)
        return false;
    _lastUpdate[__instance] = now;
    return true;
}
```

## OOM Crash Dection in Log

```bash
grep -n "OutOfMemoryException\|Out of memory" Player.log | tail -5
grep -c "YourModName" Player.log  # count per-mod log lines
```
