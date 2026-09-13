# ONI Mod Compilation Reference (Session Notes)

## Direct csc.exe compilation (from bash/git-bash)

The Roslyn compiler bundled with Visual Studio can compile ONI mods from command line:

```bash
ONI_MANAGED="/c/Program Files (x86)/Steam/steamapps/common/OxygenNotIncluded/OxygenNotIncluded_Data/Managed"

"/c/Program Files/Microsoft Visual Studio/{ver}/.../Bin/Roslyn/csc.exe" \
  -target:library \
  -noconfig -nostdlib \
  -out:MyMod.dll \
  -reference:"/c/Program Files (x86)/Reference Assemblies/Microsoft/Framework/.NETFramework/v4.8/mscorlib.dll" \
  -reference:"/c/Program Files (x86)/Reference Assemblies/Microsoft/Framework/.NETFramework/v4.8/Facades/netstandard.dll" \
  -reference:"/c/Program Files (x86)/Reference Assemblies/Microsoft/Framework/.NETFramework/v4.8/System.dll" \
  -reference:"/c/Program Files (x86)/Reference Assemblies/Microsoft/Framework/.NETFramework/v4.8/System.Core.dll" \
  -reference:"$ONI_MANAGED/Assembly-CSharp.dll" \
  -reference:"$ONI_MANAGED/0Harmony.dll" \
  -reference:"$ONI_MANAGED/UnityEngine.dll" \
  -reference:"$ONI_MANAGED/UnityEngine.CoreModule.dll" \
  -reference:"$ONI_MANAGED/UnityEngine.UI.dll" \
  -reference:"$ONI_MANAGED/UnityEngine.Physics2DModule.dll" \
  -reference:"$ONI_MANAGED/UnityEngine.AnimationModule.dll" \
  -reference:"$ONI_MANAGED/Assembly-CSharp-firstpass.dll" \
  MyMod.cs
```

**Required:** `-noconfig -nostdlib` + explicit `mscorlib`, `netstandard`, `System`, `System.Core` references.

**Target v4.8 NOT v4.7.2** — as of 2026, ONI ships 0Harmony for .NET 4.8.

## MSBuild CLI compilation (recommended)

Use `.csproj` with absolute HintPaths:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="15.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <Import Project="$(MSBuildExtensionsPath)\$(MSBuildToolsVersion)\Microsoft.Common.props"
    Condition="Exists('$(MSBuildExtensionsPath)\$(MSBuildToolsVersion)\Microsoft.Common.props')" />
  <PropertyGroup>
    <Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
    <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
    <BaseOutputPath>bin\</BaseOutputPath>
    <OutputType>Library</OutputType>
    <TargetFrameworkVersion>v4.8</TargetFrameworkVersion>
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Debug|AnyCPU' ">
    <OutputPath>bin\Debug\</OutputPath>
    <DefineConstants>DEBUG;TRACE</DefineConstants>
    <DebugType>full</DebugType>
    <Optimize>false</Optimize>
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="0Harmony">
      <HintPath>C:\Program Files (x86)\Steam\steamapps\common\OxygenNotIncluded\OxygenNotIncluded_Data\Managed\0Harmony.dll</HintPath>
    </Reference>
    <Reference Include="Assembly-CSharp">
      <HintPath>C:\Program Files (x86)\Steam\steamapps\common\OxygenNotIncluded\OxygenNotIncluded_Data\Managed\Assembly-CSharp.dll</HintPath>
    </Reference>
    <Reference Include="System" />
    <Reference Include="System.Core" />
    <Reference Include="UnityEngine">
      <HintPath>C:\Program Files (x86)\Steam\steamapps\common\OxygenNotIncluded\OxygenNotIncluded_Data\Managed\UnityEngine.dll</HintPath>
    </Reference>
    <Reference Include="UnityEngine.CoreModule">
      <HintPath>C:\Program Files (x86)\Steam\steamapps\common\OxygenNotIncluded\OxygenNotIncluded_Data\Managed\UnityEngine.CoreModule.dll</HintPath>
    </Reference>
    <Reference Include="UnityEngine.UI">
      <HintPath>C:\Program Files (x86)\Steam\steamapps\common\OxygenNotIncluded\OxygenNotIncluded_Data\Managed\UnityEngine.UI.dll</HintPath>
    </Reference>
  </ItemGroup>
  <ItemGroup>
    <Compile Include="AutomaticOilRefinery.cs" />
  </ItemGroup>
  <Import Project="$(MSBuildToolsPath)\Microsoft.CSharp.targets" />
</Project>
```

Build command:
```bash
"/c/Program Files/Microsoft Visual Studio/18/Insiders/MSBuild/Current/Bin/MSBuild.exe" \
  MyMod.csproj -t:Build -p:Configuration=Debug -p:Platform=AnyCPU
```

**Pitfalls:**
- Platform: use `AnyCPU` (no space) — matches csproj
- BaseOutputPath is REQUIRED when building without .sln
- MSBuild.rsp from Visual Studio can eat arguments — use `/noAutoRsp` if weird errors
- If `"only one project allowed"` error persists, clear MSBuild.rsp content

## Harmony Patch patterns (common)

### Register new building
```csharp
[HarmonyPatch(typeof(GeneratedBuildings), "LoadGeneratedBuildings")]
public static void Postfix()
{
    Strings.Add($"STRINGS.BUILDINGS.PREFABS.{ID}.NAME", "Name");
    ModUtil.AddBuildingToPlanScreen("Refining", ID);
}
```

### Add tech unlock
```csharp
[HarmonyPatch(typeof(Db), "Initialize")]
public static void Prefix()
{
    Db.Get().Techs.Get("OilRefinery").unlockedItemIDs.Add(ID);
}
```

### Patch existing building behavior
```csharp
[HarmonyPatch(typeof(OilRefinery), "OnSpawn")]
public static void Postfix(OilRefinery __instance)
{
    __instance.gameObject.AddComponent<AutoRunController>();
}
```

## Key API changes between ONI versions (2022 → 2026)

| Class/Property | 2022 API | 2026 API |
|---------------|---------|-----------|
| `OilRefinery.outputElements` | Public field | Access via `GetComponent<ElementConverter>()` |
| `OilRefinery.ConvertInputs()` | Existed | Internal/removed — reflect into ElementConverter |
| `ElementConverter.Run()` | Existed | Removed — use reflection to find convert method |
| `Storage.GetMassAvailable()` | No params | Needs `SimHashes` tag |
| `GameObject.PrimaryElement` | Unity property | `.GetComponent<PrimaryElement>()` |
| `BuildingTemplates.DebugConstructFix` | Exists | Removed |
| Target framework | .NET 4.7.2 | .NET 4.8 |

## OilRefinery Auto-Run (no-dubplicate) Full Code

The full compiled-and-working mod code from the 2026 session:

```csharp
using HarmonyLib;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using static ElementConverter;

namespace AutomaticOilRefinery
{
    [HarmonyPatch]
    public static class AutoRefineryPatch
    {
        [HarmonyPostfix]
        [HarmonyPatch(typeof(OilRefinery), "OnPrefabInit")]
        public static void OnPrefabInit_Postfix(OilRefinery __instance)
        {
            var converter = __instance.GetComponent<ElementConverter>();
            if (converter != null)
            {
                converter.outputElements = new OutputElement[]
                {
                    new OutputElement(5f, SimHashes.Petroleum, 348.15f, false, true, 0f, 1f, byte.MaxValue, 0)
                };
            }
        }

        [HarmonyPostfix]
        [HarmonyPatch(typeof(OilRefinery), "OnSpawn")]
        public static void OnSpawn_Postfix(OilRefinery __instance)
        {
            if (__instance.GetComponent<AutoRunController>() == null)
                __instance.gameObject.AddComponent<AutoRunController>();
        }
    }

    public class AutoRunController : KMonoBehaviour, ISim200ms
    {
        private ElementConverter converter;
        private Operational operational;
        private Storage storage;
        private static MethodInfo _convertMethod;

        protected override void OnSpawn()
        {
            base.OnSpawn();
            converter = GetComponent<ElementConverter>();
            operational = GetComponent<Operational>();
            storage = GetComponent<Storage>();
            if (_convertMethod == null && converter != null)
            {
                var methods = typeof(ElementConverter).GetMethods(
                    BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
                foreach (var m in methods)
                {
                    var name = m.Name.ToLowerInvariant();
                    if ((name.Contains("convert") || name.Contains("process") || name.Contains("run") || name.Contains("operate"))
                        && m.GetParameters().Length == 0)
                    {
                        _convertMethod = m;
                        break;
                    }
                }
            }
        }

        public void Sim200ms(float dt)
        {
            if (operational == null || !operational.IsOperational) return;
            if (converter == null || storage == null) return;
            if (storage.GetMassAvailable(SimHashes.CrudeOil) < 10f) return;
            if ((storage.capacityKg - storage.MassStored()) < 6f) return;
            if (_convertMethod != null)
                _convertMethod.Invoke(converter, null);
            operational.SetActive(true);
        }
    }
}
```
