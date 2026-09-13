# Room Size Mod Session — 2026-06-19

## Context

Attempted to create a standalone Harmony mod (no PLib) to increase CreaturePen room size from 96 to 1000 tiles in ONI U59-737790 (Unity 6000).

## Key Discovery: RoomType API change in U59

`RoomType.roomConstraints` field **does not exist** in U59-737790. Reflection returns null.
Instead, RoomType exposes constraints via two underscore_case auto-properties:

- `primary_constraint` (RoomConstraints.Constraint)
- `additional_constraints` (RoomConstraints.Constraint[])

Both have getters/setters: `get_primary_constraint`, `set_primary_constraint`, etc.

## CreaturePen RoomType Structure (from debug log)

```
primary_constraint name: "养殖建筑" (requires RanchStation-type building)
primary_constraint description: "需要一个梳理站、小动物公寓、小动物直饮器、修剪站或挤奶站"
primary_constraint fields:
  name, description, conflictDescription (strings)
  times_required = 1
  room_criteria = null
  building_criteria = Func<KPrefabID, bool>  ← checks for ranch equipment
  creature_criteria = null
  stomp_in_conflict = null

additional_constraints[0] name: "最小尺寸：12格"
additional_constraints[1] name: "最大尺寸：96格"
```

## Constraint Constructor Signatures (U59)

The base `RoomConstraints.Constraint` class has two constructors with Func delegates:

```csharp
ctor(Func<Building,bool> building_criteria,
     Func<Room,bool> room_criteria,
     int times_required,
     string name,
     string description,
     List<Constraint> stomp_in_conflict,
     string overrideConstraintConflictName)

ctor(Func<Creature,bool> creature_criteria,
     Func<Building,bool> building_criteria,
     Func<Room,bool> room_criteria,
     int times_required,
     string name,
     string description,
     List<Constraint> stomp_in_conflict,
     string overrideConstraintConflictName)
```

The `room_criteria` delegate (a `Func<Room,bool>`) encapsulates the size check — e.g. checking `room.cavity.cells.Count <= 96`.

## CavityInfo Fields (U59)

CavityInfo has NO `numCells` field. Cell count is `cells.Count`. Full field list:

| Field | Type |
|-------|------|
| handle | Handle |
| dirty | bool |
| cells | List (of int/cell indices) |
| maxX, maxY, minX, minY | int |
| room | Room |
| buildings | List |
| plants | List |
| creatures | List |
| fishes | List |
| otherEntities | List |
| eggs | List |
| fish_eggs | List |
| occupancy | Occupancy |

## ALL Approaches Tried and Results

| # | Approach | Result |
|---|----------|--------|
| 1 | Remove ALL `additional_constraints` | Room becomes generic (杂间), no size limit |
| 2 | Remove only max-size constraint (keep min) | CreaturePen type recognized correctly, but size STILL capped at 96 |
| 3 | Create new Constraint with `Func<Room,bool>` checking cells.Count<=1000 | Room becomes generic, size stays 96 |
| 4 | Prefix/Postfix on RefreshRooms — temp 1000 constraint during refresh | No effect |
| 5 | Patch `RoomConstraints.Constraint.IsMet()` | Harmony can't find the method (interface dispatch?) |
| 6 | Force `room.roomType = CreaturePen` after refresh | No effect, RoomProber overrides |
| 7 | Patch `CavityBuilder.Run()` | No visible effect |
| 8 | Prefix/Postfix on RefreshRooms — 1000 constraint swap | No effect on room type or size |
| 9 | Patch Db.Initialize to replace constraint with int ctor | Constraint type is base class, no int ctor exists |

## Verified Conclusions (U59-737790, June 2026)

1. **Room size limit (~96 for CreaturePen) is NOT enforced by RoomType constraints.** It's hardcoded in `RoomProber.CavityBuilder.Run()` or `RoomProber.Tuning` constants.
2. **The `room_criteria` Func delegate on `Constraint` is NOT evaluated for room type classification.** It's only used for UI tooltip display.
3. **Removing `additional_constraints` entirely breaks room type recognition** — the room becomes generic ("杂间"). You must keep at least the min-size constraint.
4. **Creating a new Constraint instance with the correct Func delegate also fails** — room becomes generic. This confirms the delegate is not evaluated.
5. **The 480-tile CreaturePen observed earlier was from a DIFFERENT mod** (the old RoomSize mod with PLib, workshop 3374595157), NOT from this mod's constraint manipulation.
6. **Room type modification via RoomType constraints is IMPOSSIBLE in U59.** The ONLY working approach from historical mods was patching RoomProber's internal logic (not RoomType constraints). Those mods now crash on Unity 6000 due to PLib incompatibility.

## References

- `RoomProber` has nested types: `Tuning`, `Cell`, `Generation`, `RefreshModule`, `CavityBuilder`, `BuildingId`, `VisitTracker`, `Visitor`
- `RoomProber` fields: `generation`, `rooms` (List<Room>), `cavityInfos`, `grid`, `refresh`, `solidChanges`, `dirty`
- `RoomProber.rooms` has ~1264 entries (including individual tile cavities, not just rooms)
- The `Room` class has a writable `roomType` property, but writing to it is overridden on the next refresh cycle
