# Latale ITEM LDT Cross-Version Reference

## Column Count Differences

| File | S1 (彩虹岛S1) | S2 怀旧端 | Notes |
|------|-------------|----------|-------|
| ITEM_1.LDT | 109 cols | 109 cols | Same structure |
| ITEM_2.LDT | 109 cols | **125 cols** | S2 adds 16 columns |
| ITEM_3.LDT | 109 cols | 109 cols | Same structure |
| CASH_SHOP.LDT | 64 cols (no _RowId) | 64 cols (no _RowId) | Same structure |
| GLOBAL_STRING.LDT | 2 cols | 2 cols | Same structure |

## S2 ITEM_2 Extra Columns (vs S1)

S2 ITEM_2 has these additional columns at the end (columns 109-124):

| Index | Name | Type | Purpose |
|-------|------|------|---------|
| 109 | _ItemLvValue | float | Item level value |
| 110 | _AuctionCategory | float | Auction house category |
| 111 | _AuctionQuality | float | Auction quality tier |
| 112 | _ShopID | float | Shop ID |
| 113 | _EnchantAllow | dword | Allow enchanting |
| 114 | _WeddingItem | dword | Wedding item flag |
| 115 | _dec_cool | dword | Decoration cooldown |
| 116 | _MotionTypeID3 | float | Third motion type |
| 117 | _Seal_Min_Cnt | float | Min seal count |
| 118 | _Seal_Max_Cnt | float | Max seal count |
| 119 | _Colouring | float | Coloring data |
| 120 | _PatternClass | float | Pattern class |
| 121 | _PatternType | float | Pattern type |
| 122 | _Breakup | float | Breakup flag |
| 123 | _Pet_Potential | float | Pet potential |

S1 also has `_NameColor` (col 74) which S2 does NOT have — rare, probably not used.

**When porting items from S1 to S2 ITEM_2**: you must pad the extra 16 columns with zeros (or copy from a similar S2 item).

## LDT Float-Type Integer Trick

In Latale LDT files, columns typed as `3` (float, 4 bytes) OFTEN store integer values. If you read them as Python `float` you get tiny scientific-notation values (e.g. `1.401e-45`). **Always read type-3 columns as int32 (`<i`) when you know they contain integers** (RowId, Category, Type, SubType, ItemID, Price, Count, etc.).

```python
# WRONG — gives garbage for integer fields
if types[i] == 3:
    val = struct.unpack_from('<f', data, o)[0]  # → 1.401e-45

# CORRECT for integer-valued float columns
if types[i] == 3:
    val = struct.unpack_from('<i', data, o)[0]   # → 518160621
```

This affects: ITEM_1-3 `_Category`, `_Type`, `_SubType`, `_ItemLv`, CASH_SHOP `_ItemID*`, `_CashPrice`, etc.

## CASH_SHOP.LDT Structure (S2 怀旧端)

64 columns, NO `_RowId` column. The first column is `_CategoryView` (dword type 2).

| Index | Name | Type | Notes |
|-------|------|------|-------|
| 0 | _CategoryView | dword | Shop category view |
| 1 | _CategoryIndex | float (int) | Main category |
| 2 | _CategoryIndex2 | float (int) | Sub-category |
| ... 3-5 | ... | ... | ... |
| 6 | _Name | word | String ID (GLOBAL_STRING index) |
| 7 | _Description | word | String ID |
| 8 | _IconFile | float (int) | Icon SPF file ID |
| 9 | _IconIndex | float (int) | Icon index within file |
| 10 | _Gender | float (int) | Gender restriction |
| 11 | _PriceType | float (int) | 0=cash, 1=bonus, 2=gold |
| 12 | _CashPrice | float (int) | Price |
| ... | ... | ... | ... |
| 15 | _ItemID1 | float (int) | Item ID (from ITEM_* tables) |
| 16 | _ItemRare1 | float (int) | Rare grade |
| 17 | _ItemCount1 | float (int) | Quantity |
| ... | ... | ... | ... |
| 61 | _Buy_Disable | dword | Buy disabled flag |
| 62 | _Give_Disable | dword | Gift disabled flag |
| 63 | _Limited_Time_Type | float (int) | Limited time type |

CASH_SHOP has NO string-type columns — `_Name` and `_Description` are word-indexes into `GLOBAL_STRING.LDT`.

## Binary Row Size

| File | Row size | Notes |
|------|----------|-------|
| ITEM_1.LDT | 436 bytes | All type-3 (4 bytes each) × 109 |
| ITEM_2.LDT | 500 bytes | 125 cols × 4 bytes |
| ITEM_3.LDT | 436 bytes | 109 cols × 4 bytes |
| CASH_SHOP.LDT | 252 bytes | 64 cols × ~4 bytes avg |
| CREATION_INFO.LDT | 328 bytes | 82 cols × 4 bytes |
| GLOBAL_STRING.LDT | Variable | String(length)+text format, ~32 bytes avg |

## Example: Ice Bow (Item ID 518160621)

This item exists in S1 ITEM_1 (as a base weapon with Icon=10001101, IconIndex=174).
It was ported to S2 ITEM_2 as a fashion weapon (时装武器) with:
- _Category=1 (武器)
- _Type=1
- _SubType=1 (弓)
- _PosID1=3 (时装)
- _Icon=10001101, _IconIndex=174

Status columns used: `_StatusType1=66` (物理攻击力最小值), `_StatusValue1=74`, `_StatusType2=62` (物理攻击力最大值), `_StatusValue2=81`, `_StatusType3=218` (魔法攻击力最小值), `_StatusValue3=10`, `_StatusType4=70` (魔法攻击力最大值), `_StatusValue4=135` — giving +35% min/max phys/mag (these values need verification, see session 2026-05-29).
