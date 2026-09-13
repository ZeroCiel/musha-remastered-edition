# Custom Gas-Permeable Farm Tile — U59 Mod Pattern (2026-06-27)

## Context

WideFarmTile (宽液培砖) in U59-737790 CANNOT be made gas-permeable via post-hoc Harmony patching. The sim-layer solidity flag is set at construction time and never cleared by removing C# components like SimCellOccupier.

The only viable approach: register a **new building** (IBuildingConfig) that is defined as non-solid from `CreateBuildingDef`.

## Full Code: WideGasFarmTileConfig

### WideGasFarmTileConfig.cs

```csharp
using HarmonyLib;
using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using TUNING;

namespace NoPressureDamageFarmTile
{
    public class WideGasFarmTileConfig : IBuildingConfig
    {
        public const string ID = "WideGasFarmTile";
        public const string NAME = "宽液透气培砖";
        public const string DESC = "气体可以通过的种植砖。";
        public const string EFFECT = "既保留种植功能，又让气体自由穿过。";

        public override string[] GetDlcIds()
        {
            return DlcManager.AVAILABLE_ALL_VERSIONS;
        }

        public override BuildingDef CreateBuildingDef()
        {
            int width = 2;
            int height = 1;
            int hitpoints = 30;
            float construction_time = 60f;
            float[] tier_mass = BUILDINGS.CONSTRUCTION_MASS_KG.TIER3;
            string[] construction_materials = new string[] { "Metal", "Plumbable" };
            float melting_point = 1600f;
            BuildLocationRule build_location_rule = BuildLocationRule.Anywhere;
            EffectorValues tier_decoration = BUILDINGS.DECOR.NONE;

            BuildingDef def = BuildingTemplates.CreateBuildingDef(
                ID, width, height, "widefarmtile_kanim",
                hitpoints, construction_time, tier_mass, construction_materials,
                melting_point, build_location_rule, tier_decoration,
                NOISE_POLLUTION.NONE
            );

            // KEY: Set non-solid at creation time
            var solidField = typeof(BuildingDef).GetField("isSolidTile",
                BindingFlags.Public | BindingFlags.Instance | BindingFlags.NonPublic);
            if (solidField != null && solidField.FieldType == typeof(bool))
                solidField.SetValue(def, false);

            var tileLayerField = typeof(BuildingDef).GetField("TileLayer",
                BindingFlags.Public | BindingFlags.Instance | BindingFlags.NonPublic);
            if (tileLayerField != null)
                tileLayerField.SetValue(def, Grid.SceneLayer.TileMain);

            def.Floodable = false;
            def.Entombable = true;
            def.Overheatable = false;
            def.AudioCategory = "Metal";
            def.BaseTimeUntilRepair = -1f;
            def.DefaultAnimState = "off";
            def.ObjectLayer = ObjectLayer.Building;
            def.SceneLayer = Grid.SceneLayer.TileMain;

            return def;
        }

        public override void ConfigureBuildingTemplate(GameObject go, Tag prefab_tag)
        {
            var storage = go.AddComponent<Storage>();
            storage.capacityKg = 100f;
            storage.showInUI = true;
            storage.allowItemRemoval = true;
            storage.storageFilters = new List<Tag> { GameTags.Water, GameTags.Dirt };
            storage.SetDefaultStoredItemModifiers(Storage.StandardSealedStorage);

            var plot = go.AddComponent<PlantablePlot>();
            SetField(plot, "plantStorage", storage);
            SetField(plot, "userCopyable", true);

            var occupier = go.GetComponent<SimCellOccupier>();
            if (occupier != null)
                UnityEngine.Object.DestroyImmediate(occupier);

            BuildingTemplates.CreateDefaultStorage(go);
            go.AddOrGet<CopyBuildingSettings>();
            go.AddComponent<FarmTile>();
            go.AddOrGet<Harvestable>();

            var receptacle = go.AddComponent<SingleEntityReceptacle>();
            SetField(receptacle, "receptacleFilter", new List<Tag> { GameTags.Seed });
            SetField(receptacle, "occupyingObjectRelativePosition", new Vector3(1f, 0f, 0f));
            SetField(receptacle, "occupyingObjectOffset", 0f);

            var kpid = go.GetComponent<KPrefabID>();
            if (kpid != null)
                kpid.AddTag(new Tag("WideFarmTile"), false);
        }

        public override void DoPostConfigureComplete(GameObject go)
        {
            var pv = go.GetComponent<PressureVulnerable>();
            if (pv != null)
                UnityEngine.Object.DestroyImmediate(pv);
        }

        private static void SetField(object obj, string fieldName, object value)
        {
            var field = obj.GetType().GetField(fieldName,
                BindingFlags.Public | BindingFlags.Instance | BindingFlags.NonPublic);
            if (field != null)
                field.SetValue(obj, value);
        }
    }
}
```

### Registration: Harmony patch LoadGeneratedBuildings

```csharp
[HarmonyPatch(typeof(GeneratedBuildings), "LoadGeneratedBuildings")]
public static class WideGasFarmTileInit
{
    public static void Prefix()
    {
        try
        {
            var config = new WideGasFarmTileConfig();
            var bcm = BuildingConfigManager.Instance;
            if (bcm != null)
            {
                var method = typeof(BuildingConfigManager).GetMethod("RegisterBuilding",
                    BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
                if (method != null)
                {
                    method.Invoke(bcm, new object[] { config });
                    Debug.Log("[WideGasFarmTile] Registered via BuildingConfigManager");
                }
            }
        }
        catch (Exception e)
        {
            Debug.LogError($"[WideGasFarmTile] Registration error: {e.Message}");
        }
    }
}
```

### csproj — TargetFramework net48

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net48</TargetFramework>
    <AssemblyName>NoPressureFarmTile</AssemblyName>
    <LangVersion>7.3</LangVersion>
    <AppendTargetFrameworkToOutputPath>false</AppendTargetFrameworkToOutputPath>
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="0Harmony">
      <HintPath>C:\Program Files (x86)\Steam\steamapps\common\OxygenNotIncluded\OxygenNotIncluded_Data\Managed\0Harmony.dll</HintPath>
    </Reference>
    <Reference Include="Assembly-CSharp">
      <HintPath>C:\Program Files (x86)\Steam\steamapps\common\OxygenNotIncluded\OxygenNotIncluded_Data\Managed\Assembly-CSharp.dll</HintPath>
    </Reference>
    <!-- UnityEngine modules as needed -->
  </ItemGroup>
</Project>
```

## Known U59 API Quirks

| API | Status | Replacement |
|-----|--------|-------------|
| `FarmTileConfig.SetupFarmTile(go)` | ❌ Removed | Manual setup |
| `GameTags.FarmTile` | ❌ Removed | `new Tag("WideFarmTile")` |
| `GameTags.PlantableSeed` | ❌ Removed | `GameTags.Seed` |
| `PlantablePlot.plantStorage` | ❌ Compile error | Reflection SetField |
| `SingleEntityReceptacle.receptacleFilter` | ❌ Compile error | Reflection SetField |
| `BuildingDef.DecorBlockTileAtlas/Material/Decor` | ❌ Removed | Omit |
| `BuildingDef.DrawPathfinding` | ❌ Removed | Omit |
| `BuildingDef.isSolidTile` | ✅ Exists (field) | `GetField("isSolidTile")` |
| `BuildingDef.TileLayer` | ✅ Exists (field) | `GetField("TileLayer")` |
| `NOISE_POLLUTION.NONE` | ✅ Works | Standalone type |
| `GeneratedBuildings.MakeBuildingAlwaysOperational()` | ✅ Works | |
| `BuildingTemplates.CreateDefaultStorage(go)` | ✅ Works | |
