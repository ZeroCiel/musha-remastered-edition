# Latale tbluItem2 ContainerType Values

The `ContainerType` field in `tbluItem2` determines which inventory tab/category an item appears in.

## Discovered Values (from S2 single-machine build, CharID=11541)

| ContainerType | Tab Name | Typical Contents |
|---|---|---|
| 0 | (unknown) | — |
| **1** | **消耗栏 (Consumables)** | Potions, scrolls, event items, non-equipment items |
| **2** | **装备栏 (Equipment)** | Weapons, armor, accessories, wings |
| 3 | (unknown) | — |
| 6 | Special? | Some cash-shop wings (闪亮的天使翅膀 40153236 was type 6) |
| 7 | (unknown) | — |
| 9 | (unknown) | — |
| 11 | (unknown) | — |
| 12 | (unknown) | — |
| 13 | (unknown) | — |

## Bug: 天使翅膀出现在消耗栏

- **天使翅膀+4** (TypeID=911110255) had `ContainerType=1` (消耗栏) but should have been `ContainerType=2` (装备栏)
- Fix: `UPDATE tbluItem2 SET ContainerType=2 WHERE ItemNo=X`

## Query to Check Container Distribution

```sql
SELECT DISTINCT ContainerType FROM tbluItem2 WHERE CharID=<CharID> ORDER BY ContainerType;

SELECT TypeID, ContainerType, ContainerSlot 
FROM tbluItem2 WHERE CharID=<CharID> AND ContainerType IN (1, 2) 
ORDER BY ContainerType, ContainerSlot;
```

## Query to Find Items in Wrong Tab

```sql
SELECT t.ItemNo, t.TypeID, t.ContainerType, t.ContainerSlot, i._Name
FROM tbluItem2 t
JOIN ITEM_2 i ON t.TypeID = i._Num   -- adjust LDT name as needed
WHERE t.CharID = <CharID>
  AND t.ContainerType = 1             -- consumables tab
  AND i._Category NOT IN (...);       -- not consumable category
```

## Session Context

Discovered during 2026-05-27 session: 天使翅膀+4 (911110255) appeared in 消耗栏 instead of 装备栏. Corrected by deleting the items (user wanted them removed entirely), not by changing ContainerType.
