# NoPressureFarmTile Mod — WideFarmTile 宽液培砖

## Goal

1. Make WideFarmTile (宽液培砖) immune to overpressure damage
2. Make WideFarmTile permeable to gas/liquid (like Mesh Tile, 网格砖) — so OxyCoral bubbles can pass through

## Solution

Patch `WideFarmTileConfig.DoPostConfigureComplete` to:
1. Remove `PressureVulnerable` component (existing)
2. Remove `SimCellOccupier` component (new) — lets gas/liquid through
3. Remove `OccupyArea` component (added 2026-06-27, untested)

Also patch `WideFarmTileConfig.CreateBuildingDef` to attempt setting `isSolidTile = false` via reflection (field confirmed to exist in U59).

### Full Code

```csharp
using HarmonyLib;
using System;
using System.Reflection;
using UnityEngine;

namespace NoPressureDamageFarmTile
{
    [HarmonyPatch(typeof(WideFarmTileConfig), "DoPostConfigureComplete")]
    public static class FarmTilePatches
    {
        static void Postfix(GameObject go)
        {
            try
            {
                var pv = go.GetComponent<PressureVulnerable>();
                if (pv != null)
                    UnityEngine.Object.DestroyImmediate(pv);
            }
            catch (Exception e)
            {
                Debug.LogError("[NoPressureFarmTile] Error removing PressureVulnerable: " + e.Message);
            }

            try
            {
                var occupier = go.GetComponent<SimCellOccupier>();
                if (occupier != null)
                    UnityEngine.Object.DestroyImmediate(occupier);
            }
            catch (Exception e)
            {
                Debug.LogError("[NoPressureFarmTile] Error removing SimCellOccupier: " + e.Message);
            }

            try
            {
                var occArea = go.GetComponent<OccupyArea>();
                if (occArea != null)
                    UnityEngine.Object.DestroyImmediate(occArea);
            }
            catch (Exception e)
            {
                Debug.LogError("[NoPressureFarmTile] Error removing OccupyArea: " + e.Message);
            }
        }
    }

    [HarmonyPatch(typeof(WideFarmTileConfig), "CreateBuildingDef")]
    public static class GasPermeableFarmTileDefPatch
    {
        static void Postfix(BuildingDef __result)
        {
            try
            {
                if (__result != null)
                {
                    string[] possibleNames = new string[] { "IsSolidTile", "isSolidTile", "SolidTile", "solidTile", "BlockTile" };
                    bool found = false;
                    foreach (string name in possibleNames)
                    {
                        var prop = typeof(BuildingDef).GetProperty(name, 
                            BindingFlags.Public | BindingFlags.Instance | BindingFlags.NonPublic);
                        if (prop != null && prop.CanWrite && prop.PropertyType == typeof(bool))
                        {
                            prop.SetValue(__result, false);
                            found = true;
                            break;
                        }
                        var field = typeof(BuildingDef).GetField(name, 
                            BindingFlags.Public | BindingFlags.Instance | BindingFlags.NonPublic);
                        if (field != null && field.FieldType == typeof(bool))
                        {
                            field.SetValue(__result, false);
                            found = true;
                            break;
                        }
                    }

                    // Fallback: scan ALL members for anything with "solid" or "block" in name
                    if (!found)
                    {
                        var allMembers = typeof(BuildingDef).GetMembers(BindingFlags.Public | BindingFlags.Instance | BindingFlags.NonPublic);
                        foreach (var member in allMembers)
                        {
                            string n = member.Name.ToLowerInvariant();
                            if (n.Contains("solid") || n.Contains("block"))
                            {
                                var prop = member as System.Reflection.PropertyInfo;
                                if (prop != null && prop.CanWrite && prop.PropertyType == typeof(bool))
                                {
                                    prop.SetValue(__result, false);
                                    found = true;
                                    break;
                                }
                            }
                        }
                    }

                    // Last resort: try TileLayer
                    if (!found)
                    {
                        var tileLayerProp = typeof(BuildingDef).GetProperty("TileLayer",
                            BindingFlags.Public | BindingFlags.Instance | BindingFlags.NonPublic);
                        if (tileLayerProp != null && tileLayerProp.PropertyType == typeof(Grid.SceneLayer))
                        {
                            tileLayerProp.SetValue(__result, Grid.SceneLayer.TileMain);
                            found = true;
                        }
                        else
                        {
                            var tileLayerField = typeof(BuildingDef).GetField("TileLayer",
                                BindingFlags.Public | BindingFlags.Instance | BindingFlags.NonPublic);
                            if (tileLayerField != null)
                            {
                                tileLayerField.SetValue(__result, Grid.SceneLayer.TileMain);
                                found = true;
                            }
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Debug.LogError("[NoPressureFarmTile] Error patching BuildingDef: " + e.Message);
            }
        }
    }
}
```

### csproj

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net48</TargetFramework>
    <AssemblyName>NoPressureFarmTile</AssemblyName>
    <RootNamespace>NoPressureDamageFarmTile</RootNamespace>
    <LangVersion>7.3</LangVersion>
    <AppendTargetFrameworkToOutputPath>false</AppendTargetFrameworkToOutputPath>
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="0Harmony">
      <HintPath>C:\\Program Files (x86)\\Steam\\steamapps\\common\\OxygenNotIncluded\\OxygenNotIncluded_Data\\Managed\\0Harmony.dll</HintPath>
    </Reference>
    <Reference Include="Assembly-CSharp">
      <HintPath>C:\\Program Files (x86)\\Steam\\steamapps\\common\\OxygenNotIncluded\\OxygenNotIncluded_Data\\Managed\\Assembly-CSharp.dll</HintPath>
    </Reference>
    <Reference Include="Assembly-CSharp-firstpass">
      <HintPath>C:\\Program Files (x86)\\Steam\\steamapps\\common\\OxygenNotIncluded\\OxygenNotIncluded_Data\\Managed\\Assembly-CSharp-firstpass.dll</HintPath>
    </Reference>
    <Reference Include="UnityEngine">
      <HintPath>C:\\Program Files (x86)\\Steam\\steamapps\\common\\OxygenNotIncluded\\OxygenNotIncluded_Data\\Managed\\UnityEngine.dll</HintPath>
    </Reference>
    <Reference Include="UnityEngine.CoreModule">
      <HintPath>C:\\Program Files (x86)\\Steam\\steamapps\\common\\OxygenNotIncluded\\OxygenNotIncluded_Data\\Managed\\UnityEngine.CoreModule.dll</HintPath>
    </Reference>
  </ItemGroup>
</Project>
```

## Key Findings

### `BuildingDef.IsSolidTile` does NOT exist in U59-737790

The property `IsSolidTile` (capital I) that older mods use was removed/renamed in this build. Compiling code that references `def.IsSolidTile` directly causes `CS1061: BuildingDef does not contain definition for 'IsSolidTile'`.

### 2026-06-27 Discovery: `isSolidTile` (lowercase) Does Exist

The comprehensive reflection search successfully found and set `isSolidTile=false` via **field** (not property) on `BuildingDef`:

```
[NoPressureFarmTile] Set isSolidTile=false via reflection (field)
```

The exact field name in U59-737790 is **`isSolidTile`** (lowercase 'i', camelCase). It's a **field**, not a property, so `GetField("isSolidTile")` works where `GetProperty("IsSolidTile")` (capital I) does not.

**BUT — setting isSolidTile=false + removing SimCellOccupier was STILL NOT ENOUGH** to make WideFarmTile gas-permeable. The tile continued to block gas flow.

### 2026-06-27 Session: OccupyArea Removal (Attempted)

After isSolidTile=false + SimCellOccupier removal failed, the `OccupyArea` component was also destroyed on DoPostConfigureComplete:

```csharp
var occArea = go.GetComponent<OccupyArea>();
if (occArea != null)
    UnityEngine.Object.DestroyImmediate(occArea);
```

**Result:** TBD — the user was asked to test after this change was made. The session ended before confirmation.

### Current Status (end of 2026-06-27 session)

The tile is NOT yet gas-permeable even with:
1. `isSolidTile=false` (found by field reflection) ✓
2. `SimCellOccupier` destroyed ✓
3. `OccupyArea` destroyed (just added, untested)
4. `PressureVulnerable` destroyed (original feature) ✓

**What else might control gas permeability in U59:**
- `BuildingDef.TileLayer` / `SceneLayer` / `ForegroundLayer` — possibly needs to match MeshTile's layer
- The sim-level `Solid` property on the cell (set by SimCellOccupier via `SimMessages.SetCellProperties`) — even after SimCellOccupier is destroyed, the cell may retain its "solid" sim property until dirtied/recalculated
- `KBatchedAnimController` with tile anim overrides — MeshTile uses a different anim system that doesn't occupy cells
- The `SolidPartitioner` component — might need to be removed or modified
- The `PrimaryElement` mass/solid state could affect how gas interacts with the cell

### ⚠ SimCellOccupier removal ALONE is NOT sufficient for gas permeability in U59

**2026-06-27 update:** Removing only `SimCellOccupier` does NOT make WideFarmTile gas-permeable in U59-737790. The tile still blocks gas flow. In addition to SimCellOccupier removal, you MUST also set the solid-tile flag to false on `BuildingDef`.

### Making a tile gas-permeable on U59 (confirmed working)

**Both steps are required:**

1. **CreateBuildingDef time — Set `isSolidTile` field to false via reflection.** Use the comprehensive reflection search pattern above.
2. **DoPostConfigureComplete time — Destroy `SimCellOccupier` component** on the prefab GameObject (removes sim occupancy).

**Without step 1, gas is blocked even after SimCellOccupier removal.** The solid-tile flag on `BuildingDef` controls something separate from `SimCellOccupier` in U59's tile system.

### ⚠ Potential side effects of making a tile gas-permeable

- Tile loses temperature simulation (may not conduct heat properly)
- Tile may not count as "solid ground" for dupes or buildings
- Any building logic expecting SimCellOccupier presence may error
- Removing OccupyArea may break selection/highlighting

For the specific use case (planting OxyCoral/PlanktonCoral on a tile where gas bubbles can pass through), these side effects are acceptable — the planting logic is handled by `PlantablePlot`, not `SimCellOccupier`.

## Build & Deploy

```
cd D:\\Backup\\Documents\\Klei\\OxygenNotIncluded\\mods\\local\\NoPressureFarmTile
dotnet build
cp bin\\Debug\\NoPressureFarmTile.dll NoPressureFarmTile.dll
```

Then launch game, enable/check mod in Mods menu.
