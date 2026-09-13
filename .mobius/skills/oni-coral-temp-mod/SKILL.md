---
name: oni-coral-temp-mod
title: "ONI Coral Min Temp Mod — 修改珊瑚最低生长温度"
description: "创建Harmony模组修改氧齿珊瑚(OxyCoral)和浮游珊瑚(PlanktonCoral)的最低生长温度。patch PlantablePlot.lethalLowTemp / warningLowTemp 字段为指定值。"
triggers:
  - "珊瑚温度"
  - "coral temp"
  - "coral minimum temperature"
  - "烟囱珊瑚"
  - "氧齿珊瑚最低温度"
  - "修改珊瑚生长温度"
---

# ONI 珊瑚最低温度修改模组

## 适用场景

修改**氧齿珊瑚（OxyCoral）**和**浮游珊瑚（PlanktonCoral）**的最低生长温度（致死低温和警告低温）。

## 模组结构

```
mods/Local/CoralMinTemp/
├── CoralMinTemp.cs        # 源码
├── CoralMinTemp.csproj    # 项目文件
├── mod.yaml               # YAML 格式（不是JSON！）
├── mod_info.yaml          # 简略yaml
└── CoralMinTemp.dll       # 编译产物（拷贝到根目录）
```

## mod.yaml 格式（YAML，不是JSON！）

```yaml
title: Coral Min Temp 15°C
description: 修改珊瑚（氧齿珊瑚、浮游珊瑚）最低生长温度为15°C
staticID: CoralMinTemp15C
supportedContent: ALL
minimumSupportedBuild: 737790
version: 1
```

⚠ **关键坑**：
- `mod.yaml` 是 **YAML 格式**，不是 JSON！写 `key: value` 不是 `"key": "value"`
- 字段名是 `minimumSupportedBuild` 不是 `minimumSupportedVersion`
- `minimumSupportedBuild` 写**当前游戏版本号**（U59 是 737790），不要写旧的 587362 以免显示模组过期
- `supportedContent` 是字符串值 `ALL` 不是数组 `["ALL"]`

## Harmony 代码要点

```csharp
public override void OnLoad(Harmony harmony)
{
    base.OnLoad(harmony);

    // 通过 Type.GetType 找到目标 Config 类
    var configType = Type.GetType("OxyCoralConfig, Assembly-CSharp");

    // Patch CreatePrefab（非虚方法，可用 Harmony）
    var createPrefab = configType.GetMethod("CreatePrefab",
        BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);

    var postfix = typeof(YourMod).GetMethod("Postfix_CreatePrefab",
        BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);

    harmony.Patch(createPrefab, postfix: new HarmonyMethod(postfix));
}

public static void Postfix_CreatePrefab(ref GameObject __result)
{
    var plantable = __result.GetComponent<PlantablePlot>();
    // 通过反射修改 lethalLowTemp 和 warningLowTemp 字段
    var field = typeof(PlantablePlot).GetField("lethalLowTemp", ...);
    field.SetValue(plantable, 15f);
}
```

## 编译命令

```bash
cd mods/Local/CoralMinTemp && dotnet build -c Release
cp bin/Release/CoralMinTemp.dll CoralMinTemp.dll
```

## 相关字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `lethalLowTemp` | float | 致死低温（低于此值植物受损） |
| `warningLowTemp` | float | 警告低温（低于此值提示） |
| `lethalHighTemp` | float | 致死高温 |
| `warningHighTemp` | float | 警告高温 |
