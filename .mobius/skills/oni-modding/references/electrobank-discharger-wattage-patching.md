# 放电器功率修改：类名、字段、部署坑

## 准确类名（U59 build 587362）

| 建筑 | Config 类名 | 字段 | 原值 |
|------|------------|------|------|
| 大型放电器 | `LargeElectrobankDischargerConfig` | `GeneratorWattageRating` | 480f |
| 袖珍放电器 | `SmallElectrobankDischargerConfig` | `GeneratorWattageRating` | 60f  |

**注意：袖珍是 `SmallElectrobankDischargerConfig`，不是 `CompactElectrobankDischargerConfig`** — 后者不存在，会报 `Undefined target method`。

## 字段选择

- `GeneratorWattageRating` = 发电功率（放电器是发电机，用这个）
- `EnergyConsumptionWhenActive` = 耗电功率（放电器不是用电器，这个值是0，不要改）

## 使用 CreateBuildingDef（而不是 CreatePrefab）

Patch `CreateBuildingDef` 方法，返回的 `BuildingDef` 直接设 `GeneratorWattageRating` 即可：
```csharp
[HarmonyPatch]
public static class LargeDischargerConfigPatch
{
    static IEnumerable<MethodBase> TargetMethods()
    {
        var configType = AccessTools.TypeByName("LargeElectrobankDischargerConfig");
        if (configType != null)
        {
            var method = AccessTools.Method(configType, "CreateBuildingDef");
            if (method != null) yield return method;
        }
    }

    static void Postfix(object __instance, ref object __result)
    {
        var def = __result as BuildingDef;
        if (def == null) return;
        float old = def.GeneratorWattageRating;
        def.GeneratorWattageRating = 4000f;
    }
}
```

## 同时改大型和袖珍

```csharp
// 大型
[HarmonyPatch]
public static class LargeDischargerConfigPatch
{
    static IEnumerable<MethodBase> TargetMethods()
    {
        var configType = AccessTools.TypeByName("LargeElectrobankDischargerConfig");
        if (configType != null)
        {
            var method = AccessTools.Method(configType, "CreateBuildingDef");
            if (method != null) yield return method;
        }
    }
    static void Postfix(object __instance, ref object __result)
    {
        var def = __result as BuildingDef;
        if (def == null) return;
        def.GeneratorWattageRating = 4000f;
    }
}

// 袖珍 — 类名不同
[HarmonyPatch]
public static class CompactDischargerConfigPatch
{
    static IEnumerable<MethodBase> TargetMethods()
    {
        var configType = AccessTools.TypeByName("SmallElectrobankDischargerConfig");
        if (configType != null)
        {
            var method = AccessTools.Method(configType, "CreateBuildingDef");
            if (method != null) yield return method;
        }
    }
    static void Postfix(object __instance, ref object __result)
    {
        var def = __result as BuildingDef;
        if (def == null) return;
        def.GeneratorWattageRating = 2000f;
    }
}
```

## OnSpawn Patch — 兜底已建好的放电器

在用 Config patch 的同时加一个 OnSpawn patch 处理已有存档里的放电器：
```csharp
[HarmonyPatch]
public static class DischargerSpawnPatch
{
    static IEnumerable<MethodBase> TargetMethods()
    {
        var type = AccessTools.TypeByName("ElectrobankDischarger");
        if (type != null)
        {
            var method = AccessTools.Method(type, "OnSpawn");
            if (method != null) yield return method;
        }
    }

    static void Postfix(object __instance)
    {
        var building = (__instance as KMonoBehaviour)?.GetComponent<BuildingComplete>();
        if (building?.Def == null) return;

        // ⚠️ 用 prefabid 判断类型（Def.Name 会被本地化，中文不可靠）
        string prefabId = building.prefabid?.ToString() ?? "";
        float target = prefabId.Contains("Large") ? 4000f : 2000f;

        building.Def.GeneratorWattageRating = target;
    }
}
```

## Harmony Style（build 587362）

- ✅ 类级别 `[HarmonyPatch]` + class 内含 `static void Postfix/Prefix` — 可用
- ✅ `[HarmonyPatch]` + `TargetMethods()` 返回 `IEnumerable<MethodBase>` — 可用
- ❌ `[HarmonyPostfix]` 方法级别属性 — 静默失败
- ❌ 方法参数用 `__instance`（object 类型）+ `__result`（ref）— 对 TargetMethods 模式必须用这两个参数名

## 部署注意

1. 编译后把 DLL 拷到 `mods/Local/<ModName>/` 根目录，不是 `bin/Release/`
2. **不要**在 mod 根目录放备份 DLL（如 `*_4000W.dll`）— 会被作为第二个 Mod 加载导致崩溃
3. Mod 崩溃后 ONI 自动禁用，需要 Mod 菜单重新勾选 + 重启游戏
4. 确认生效：查 Player.log 中 `Loading MOD dll:` 行 + mod 的 Debug.Log 行。若只有 mod.yaml 加载行（`大型放电器2000W: Successfully loaded from path 'root'`）但没有 `Loading MOD dll:` 行 → Mod 被自动禁用了，去 Mod 菜单重新勾选
5. 工坊上传前清理：删 `obj/`、`bin/`、`*.cs`、`*.csproj`、备份 DLL。DLL 文件名建议跟 staticID 一致
