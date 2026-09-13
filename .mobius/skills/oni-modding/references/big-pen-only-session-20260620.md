# BigPenOnly — Room Size Constraint Modification (June 20, 2026)

## Goal
Remove CreaturePen max size limit. Verified: RoomType constraints DO NOT control room size.

## Constraint Structure (build 587362, English locale)

### RoomConstraints.Constraint (base class):
- 2 constructors (7-param: building/room/name/desc/stomp, 8-param: +creature)
- Fields: name, description, conflictDescription (String), times_required (Int32), room_criteria (Func<Room,bool>), building_criteria (Func<Building,bool>), creature_criteria (Func<Creature,bool>), stomp_in_conflict (List<Constraint>)

### Constraint name matching (locale-dependent):
- English: "Minimum size: 12 tiles" / "Maximum size: 96 tiles"
- Chinese: "最小尺寸：12格" / "最大尺寸：96格"
- ALWAYS check both: cn.Contains("Maximum") || cn.Contains("最大")

## All Approaches Failed
1. Remove max constraint → room recognized, internal ~480 cap remains
2. Replace constraint with Func delegate checking cells.Count <= 480 → room becomes generic
3. RoomProber.RefreshRooms postfix forcing roomType → RoomProber overrides next refresh

Conclusion: Room size limits are hardcoded in CavityBuilder.Run(), not in RoomType constraints. No mod-side fix possible with simple patches.
