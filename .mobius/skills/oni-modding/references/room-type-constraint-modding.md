# Room Type Constraint Modding (U59+ Deep Dive)

## Complete Session Log: Modifying CreaturePen Room Size (June 2026)

### Goal
Increase the maximum room size of the CreaturePen (畜舍) RoomType to 1000 tiles, without using PLib (broken on Unity 6000).

### Attempted Approaches & Results

#### Approach 1: Delete `roomConstraints` field (FAILED)
```csharp
var field = type.GetField("roomConstraints", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
// Returns NULL on U59-737790
```
**Result**: `roomConstraints` field does NOT exist on `RoomType` in U59+. Reflection returns null.

#### Approach 2: Delete `additional_constraints` entirely (PARTIAL SUCCESS)
Found the correct **properties**: `primary_constraint` (Constraint) and `additional_constraints` (Constraint[]).

Setting `additional_constraints` to empty array:
- Room becomes "杂间" (generic/unrecognized room type)
- The `primary_constraint` alone is NOT sufficient for room type recognition
- At least one additional constraint must remain

#### Approach 3: Delete only the max-size constraint (WORKING)
Removing only the constraint whose localized name is "最大尺寸：96格" while keeping the min-size "最小尺寸：12格":
- Room is correctly recognized as CreaturePen
- No effective upper size limit (room works at >96 tiles)
- But the desired 1000-tile cap is NOT enforced

#### Approach 4: Create new Constraint with Func delegate (FAILED)
Created a new `RoomConstraints.Constraint` with a `Func<Room,bool>` delegate checking `cells.Count <= 1000`:

```csharp
var ct = typeof(RoomConstraints.Constraint);
var ctors = ct.GetConstructors(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
var ctor = ctors[0]; // simpler constructor

Func<Room, bool> newRoomCriteria = (Room room) => {
    var cavity = room.GetType().GetProperty("cavity", ...).GetValue(room, null);
    var cells = cellsField.GetValue(cavity) as System.Collections.IList;
    return cells.Count <= 1000;
};

var newConstraint = ctor.Invoke(new object[] {
    null, newRoomCriteria, 1, "最大尺寸：1000格", null, null, null
}) as RoomConstraints.Constraint;
```
**Result**: Room became "杂间" (generic), size still 96. The `room_criteria` delegate may NOT be evaluated by RoomProber for room type classification. Size enforcement appears to happen elsewhere.

### Key Findings

1. **`RoomType.roomConstraints` field does NOT exist on U59-737790+**. Use properties instead:
   - `primary_constraint` (RoomConstraints.Constraint)
   - `additional_constraints` (RoomConstraints.Constraint[])

2. **Constraint names depend on game locale** — NOT always Chinese. With English locale:
   - Minimum: `"Minimum size: 12 tiles"` (description: `"Must have an area of at least 12 tiles"`)
   - Maximum: `"Maximum size: 96 tiles"` (description: `"Must have an area no larger than 96 tiles"`)
   - The class type is the base `RoomConstraints+Constraint` itself (NOT a subclass like `MaximumSize`)
   - When matching by name, use BOTH English and Chinese keywords: `cn.Contains("Maximum") || cn.Contains("最大")`

3. **Constraint constructors take Func delegates, not sizes** (confirmed via field dump, June 2026):
   **7-param constructor:**
   `(Func<Building,bool> building_criteria, Func<Room,bool> room_criteria, int times_required, string name, string description, List<Constraint> stomp_in_conflict, string overrideConstraintConflictName)`
   **8-param constructor (adds creature_criteria at front):**
   `(Func<Creature,bool> creature_criteria, Func<Building,bool> building_criteria, Func<Room,bool> room_criteria, int times_required, string name, string description, List<Constraint> stomp_in_conflict, string overrideConstraintConflictName)`
   
   **Constraint fields (all public/non-public):**
   | Field | Type | Example value |
   |-------|------|-------------|
   | `name` | String | `"Maximum size: 96 tiles"` |
   | `description` | String | `"Must have an area no larger than 96 tiles"` |
   | `conflictDescription` | String | `"Maximum size: 96 tiles"` |
   | `times_required` | Int32 | `1` |
   | `room_criteria` | `Func<Room,bool>` | delegate checking `cells.Count <= 96` |
   | `building_criteria` | `Func<Building,bool>` | `null` (for size constraints) |
   | `creature_criteria` | `Func<Creature,bool>` | `null` (for size constraints) |
   | `stomp_in_conflict` | `List<Constraint>` | `null` |

4. **CavityInfo has NO `numCells` field**. Cell count is `cells` (a `List<>`), so: `numCells = cells.Count`

5. **RoomProber enforces room size OUTSIDE the constraint system**. Even with all constraints removed from RoomType, `CavityBuilder.Run()` and/or `RoomProber.Tuning` constants impose a secondary cap (~96 tiles for CreaturePen). Modifying RoomType constraints alone may NOT change the effective limit.

### Current Semantics (Verified U59-737790)

- Removing the max-size constraint from `additional_constraints` (while keeping min-size): Room works correctly, unlimited size (but internal RoomProber cap still applies ~96-480 tiles).
- Creating a new Constraint with a `Func<Room,bool>` delegate and inserting it: Room becomes generic/杂间.
- Deleting ALL `additional_constraints`: Room becomes generic/杂间.
- `RoomProber.rooms` field is `List<Room>` (accessible via reflection).
- Attempting to force `room.roomType = penType` in RefreshRooms Postfix has no visible effect — the game may recalculate type after the patch runs.
- Creating a replacement constraint via the 7-param constructor with a new `Func<Room,bool>` delegate checking `cells.Count <= 1000`: also becomes generic/杂间. The `room_criteria` delegate is NOT evaluated for room type classification.

### Debugging Constraints (Field Dump Pattern)

To inspect constraint details at runtime, use this pattern:

```csharp
[HarmonyPatch(typeof(Db), "Initialize")]
public static class DebugConstraintsPatch
{
    private static bool _applied = false;
    static void Postfix()
    {
        if (_applied) return; _applied = true;
        // ... find RoomType by Id ...

        var addVal = addProp.GetValue(rt, null) as RoomConstraints.Constraint[];
        foreach (var c in addVal)
        {
            Debug.Log("Constraint: name='" + (c.name ?? "null") +
                "' type=" + c.GetType().FullName);

            // Dump constructors
            foreach (var ctor in c.GetType().GetConstructors(
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
            {
                var parms = ctor.GetParameters();
                // log parameter types
            }

            // Dump fields
            foreach (var f in c.GetType().GetFields(
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
            {
                var val = f.GetValue(c);
                Debug.Log("   field " + f.Name + " (" + f.FieldType.Name + ") = " + (val ?? "null"));
            }
        }
    }
}
```
