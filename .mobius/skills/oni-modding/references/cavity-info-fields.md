# CavityInfo — Confirmed Field Structure (U59-737790)

## Discovery Method

Reflection dump during `[HarmonyPostfix]` on `Db.Initialize`:
```csharp
Type cavityType = null;
foreach (var asm in AppDomain.CurrentDomain.GetAssemblies())
    foreach (var t in asm.GetTypes())
        if (t.Name == "CavityInfo") { cavityType = t; break; }

foreach (var f in cavityType.GetFields(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
    Debug.Log("  " + f.Name + " (" + f.FieldType.Name + ")");
```

## Confirmed Fields

| Field Name | Type | Notes |
|------------|------|-------|
| `handle` | `Handle` | Internal handle |
| `dirty` | `Boolean` | Whether needs re-computation |
| `cells` | `List<System.Int32>` | **Cell list — Count = room size in tiles** |
| `maxX` | `Int32` | Bounding box max X |
| `maxY` | `Int32` | Bounding box max Y |
| `minX` | `Int32` | Bounding box min X |
| `minY` | `Int32` | Bounding box min Y |
| `room` | `Room` | Back-reference to parent Room |
| `buildings` | `List<KPrefabID>` | Buildings in this cavity |
| `plants` | `List<...>` | Plants |
| `creatures` | `List<...>` | Creatures |
| `fishes` | `List<...>` | Fishes |
| `otherEntities` | `List<...>` | Other entities |
| `eggs` | `List<...>` | Eggs |
| `fish_eggs` | `List<...>` | Fish eggs |
| `occupancy` | (enum) | Occupancy state |

## Critical Notes

- **There is NO `numCells` field.** Cell count = `cells.Count` (the `List<System.Int32>`)
- **Do NOT use `maxX`/`maxY` as cell count proxies.** These are bounding box coordinates of the room's extent (e.g. x range from wall to wall), NOT the number of cells inside. If you accidentally use `maxX`, the size check becomes `maxX <= N` which is almost always true for large rooms.
- CavityInfo is NOT a nested class of RoomProber in U59 — it's a standalone class (namespace `RoomProber` but defined separately at `|CavityInfo` in metadata)

## How to Get Cell Count

```csharp
// Safe: always use cells.Count
var cellsField = cavityType.GetField("cells",
    BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
var cells = cellsField.GetValue(cavity) as System.Collections.IList;
int numCells = cells.Count; // This is the room size in tiles
```
