# Dumping ONI Data Structures at Runtime

When exploring ONI's obfuscated or version-dependent classes, the fastest approach is to write a Harmony postfix that dumps all fields of a target object to Player.log.

## Pattern: Constructor Postfix Dump

```csharp
public override void OnLoad(Harmony harmony)
{
    base.OnLoad(harmony);

    var type = typeof(TargetClass);
    foreach (var ctor in type.GetConstructors(
        BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
    {
        var dumper = typeof(MyDumper).GetMethod("Dump",
            BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
        harmony.Patch(ctor, postfix: new HarmonyMethod(dumper));
    }
}

public static void Dump(TargetClass __instance)
{
    var type = __instance.GetType();
    string output = "[MyMod] === TargetClass DUMP ===\n";

    foreach (var f in type.GetFields(
        BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
    {
        var val = f.GetValue(__instance);
        string str;
        if (val is IDictionary dict)
        {
            str = "{Dict count=" + dict.Count + "}";
            foreach (var key in dict.Keys)
            {
                // KEY INSIGHT: key.ToString() may not show identifying info
                // (e.g. SkillGroup.ToString() just says "Database.SkillGroup")
                // Probe Id/Name property/field on the key object:
                string keyStr = key?.ToString() ?? "null";
                if (key != null)
                {
                    var kt = key.GetType();
                    var idP = kt.GetProperty("Id");
                    if (idP != null) keyStr = idP.GetValue(key)?.ToString() ?? keyStr;
                    else
                    {
                        var idF = kt.GetField("Id",
                            BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
                        if (idF != null) keyStr = idF.GetValue(key)?.ToString() ?? keyStr;
                    }
                }
                str += "\n    [" + keyStr + "] = " + (dict[key]?.ToString() ?? "null");
            }
        }
        else if (val is Array arr)
            str = "[" + arr.Length + " items]";
        else
            str = val?.ToString() ?? "null";

        output += $"  Field {f.Name} ({f.FieldType.Name}) = {str}\n";
    }
    Debug.Log(output);
}
```

## When to Use

- Exploring class structure before writing actual patch logic
- Checking if a field/property exists in your ONI version
- Confirming dictionary key/value types (e.g. `Dictionary<SkillGroup, float>` vs `Dictionary<Skill, SkillAptitude>`)
- Verifying constructor arguments and defaults

## IList / Trait Dump Pattern

In this session, we dumped `MinionStartingStats.Traits` (a `List<Trait>`). Calling `item.ToString()` on a Trait just yields `"Klei.AI.Trait"` — useless. Full reflection dump of properties AND fields reveals identifying information:

```csharp
else if (val is IList list && !(val is Array))
{
    str = "[" + list.Count + " items]";
    foreach (var item in list)
    {
        if (item == null) { str += "\n    - null"; continue; }
        string extra = "";
        var itemType = item.GetType();
        // Dump all properties
        foreach (var p in itemType.GetProperties(
            BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
        {
            try { var v = p.GetValue(item); extra += $"  .{p.Name}={v}"; }
            catch { extra += $"  .{p.Name}=<err>"; }
        }
        // Dump all fields — this is where Id/Guid/Name live for Trait
        foreach (var f in itemType.GetFields(
            BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
        {
            try { var v = f.GetValue(item); extra += $"  .{f.Name}={v}"; }
            catch { }
        }
        str += "\n    - " + item.ToString() + extra;
    }
}
```

Output example:
```
- Klei.AI.Trait  .Id=GrantSkill_Mining1  .Guid=GrantSkill_Mining1  .Name=掌握技能：坚硬材料挖掘  .Rating=0  .PositiveTrait=True  .OnAddTrait=System.Action`1[UnityEngine.GameObject]  ...
```

## Caveats

- The dump triggers every time the constructor is called — may flood logs if the class is constructed frequently
- Fields loaded after construction (via OnSpawn/Start/etc.) won't appear — use a later hook point
- Array contents aren't expanded (add depth-limited recursion if needed)
- If the dump itself causes a crash (recursive logging), wrap in try/catch
- **IMPORTANT: Do NOT access `Db.Get()` inside `OnLoad()` or `MinionStartingStats` constructor postfix hooks!** The database is null during startup. Use `Game.LateUpdate` + a `_didInit` guard + check for `Db.Get() != null` before iterating resources.
- **MinionStartingStats ctor patches fire DURING asset loading** — if your patch modifies constructor data, `Db.Get()` will be null. Only use LateUpdate or OnSpawn hooks for Db-dependent operations.
