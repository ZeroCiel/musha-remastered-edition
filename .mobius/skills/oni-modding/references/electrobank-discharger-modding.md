# 放电装置硬编码修改 (Electrobank Discharger Modding)

适用版本: ONI build 587362 (U59-737790)

## 类名对照

| 设备 | Config 类名 | 运行时类 | 原版功率 |
|------|------------|---------|---------|
| 大型放电器 | `LargeElectrobankDischargerConfig` | `ElectrobankDischarger` | 480W |
| 袖珍放电器 | `SmallElectrobankDischargerConfig` | `ElectrobankDischarger` | 60W |

**注意:** 袖珍放电器类名是 `SmallElectrobankDischargerConfig`，**不是** `CompactElectrobankDischargerConfig`。

## Patch 方案

### 方案 A: Harmony Patch（首选，本版可用）

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
        def.GeneratorWattageRating = 4000f;  // 480 → 4000
    }
}
```

关键字段: `GeneratorWattageRating`（发电功率），**不是** `EnergyConsumptionWhenActive`（用电器功率）。
大型和袖珍共用一个 `ElectrobankDischarger.OnSpawn` 基类，可用 OnSpawn Patch 兜底已建好的建筑。

### 方案 B: OnSpawn 兜底

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
        string defName = building.Def.Name;
        float target = defName.Contains("Large") ? 4000f : 2000f;
        building.Def.GeneratorWattageRating = target;
    }
}
```

## DLL 部署陷阱

1. **游戏从 Mod 根目录加载 DLL**，不是 `bin/Release/` 子目录
2. 编译后必须手动复制: `cp bin/Release/YourMod.dll <moddir>/YourMod.dll`
3. **不要在 Mod 文件夹里放备份 DLL**（如 `SomeMod_4000W.dll`），游戏会当做另一个 Mod 加载，导致冲突崩溃
4. 路径是 `mods/Local/`（大写 L），不是 `mods/local/`（小写 l）

## 验证方式

查看 `Player.log` (位于 `%USERPROFILE%\AppData\LocalLow\Klei\Oxygen Not Included\`):

```
[YourModName] Large GeneratorWattageRating: 480 -> 4000
[YourModName] Compact GeneratorWattageRating: 60 -> 2000
```

如果 Mod 加载成功但没有 patch 日志，检查 Harmony 是否真的被调用（Config patch 是可靠的验证方式）。
