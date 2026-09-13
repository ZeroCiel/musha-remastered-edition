# LDT File Format — Detailed Reference

Based on LaTaleTools source (`Ldt.fs`) and verified against CASH_SHOP.LDT (4143 rows, 65 cols).

## File Header (12 bytes)

| Offset | Size | Field | Meaning |
|--------|------|-------|---------|
| 0x00 | 4 | Magic | Usually 0 |
| 0x04 | 4 | ColumnCount | Real column count + 1 (includes virtual _RowId) |
| 0x08 | 4 | RowCount | Number of data rows |

## Column Names (from offset 12)

Each column name is stored as a null-terminated string padded to 64 bytes total.

- Offset: `12 + n * 64` for column `n` (0-indexed, excluding _RowId)
- Encoding: UTF-8
- The first column `_RowId` is virtual and not stored in the name area

## Column Types (from offset 8204)

Each column type is a 4-byte int32.

- Offset: `8204 + n * 4` for column `n` (0-indexed, excluding _RowId)
- Values: 0=Unsigned(U32), 1=String, 2=Bool, 3=Signed(S32), 4=Float
- _RowId is always S32(3)

## Data Rows (from offset 8716)

Each row is parsed sequentially by column type:

| Type | Storage | Notes |
|------|---------|-------|
| U32(0) | 4 bytes | Little-endian |
| S32(3) | 4 bytes | Little-endian signed |
| Bool(2) | 4 bytes | 0=false, 1=true |
| Float(4) | 4 bytes | IEEE 754 |
| String(1) | 2-byte length prefix + data | Length includes null terminator. Encoding: EUC-KR (CP949) |

The data start offset (8716) is hardcoded from `Ldt.fs: readRow 8716L 0` and corresponds to the offset after all column name + type metadata.

## Column Structure for CASH_SHOP.LDT (65 cols)

Commonly modified fields:

| Col | Name | Type | Purpose |
|-----|------|------|---------|
| 0 | _RowId | S32 | Auto-increment row ID |
| 1 | _CategoryView | Bool | 1=visible in shop, 0=hidden |
| 2 | _CategoryIndex | S32 | Tab: 1=推荐, 2=装扮, 3=发型, 6=套装, 7=武器 |
| 5 | _PositionIndex | S32 | Sort order within category |
| 7 | _Name | Str | Item name (EUC-KR) |
| 8 | _Description | Str | Item description (EUC-KR) |
| 9 | _IconFile | S32 | Icon resource ID |
| 11 | _Gender | S32 | Gender restriction |
| 12 | _PriceType | S32 | 1 = cash points |
| 13 | _CashPrice | S32 | Price |
| 14 | _SalePrice | S32 | Sale/discount price |
| 16-47 | _ItemID1..8 (×4) | S32 | Item IDs for up to 8 bundled items |
| 17-47 | _ItemRare1..8 (×4) | S32 | Rarity for each |
| 18-47 | _ItemCount1..8 (×4) | S32 | Count for each |
| 62 | _Buy_Disable | Bool | Purchase blocked |
| 63 | _Give_Disable | Bool | Gifting blocked |
| 64 | _Limited_Time_Type | S32 | Time-limited item type |

## Column Structure for WORLD_MAP_STAGE.LDT (18 cols)

| Col | Name | Type | Purpose |
|-----|------|------|---------|
| 0 | _RowId | S32 | |  
| 1 | _Name | Str | Stage name (EUC-KR) |
| 2-5 | _PosX/Y, _Rect_W/H | S32 | Map position/area |
| 6 | _Map_Image | Str | Background image filename |
| 7-8 | _Map_W/H | S32 | Map pixel dimensions |
| 9 | _Description | Str | Stage description |
| 10-11 | _Icon, _Icon_Index | S32 | Icon resource |
| 12-16 | _Map_Info1..5 | Str | Additional info lines |
| 17 | _Land | S32 | Land type ID |

Guofu (CN) version has 19 cols: same structure + `_Map_Search` (Str) at the end.

## Column Structure for MAP_INFO.LDT (4 cols)

| Col | Name | Type | Purpose |
|-----|------|------|---------|
| 0 | _RowId | S32 | |
| 1 | _MapCode | Str | Map code (e.g. "00-00") |
| 2 | _Name | Str | Map name (EUC-KR) |
| 3 | _Type | Str | Map type ("Single", "Safety zone", "Field", etc.) |

## Column Structure for GLOBAL_STRING.LDT (3 cols)

| Col | Name | Type | Purpose |
|-----|------|------|---------|
| 0 | _RowId | S32 | |
| 1 | _String | Str | UI string (EUC-KR) |
| 2 | (unused?) | - | |

## Guofu (国服 CN) vs Current Version Differences

| LDT File | Guofu Cols | Current Cols | Difference |
|----------|-----------|--------------|------------|
| CASH_SHOP.LDT | 71 | 65 | Guofu adds: _EventPage, _MaxOz, _MaxMile, _StepGroup, _StepN, _StepN_OpenAmount, _World_Amount, _NewReturn_Account, _World_Amount_Type. Removes: _PriceType |
| WORLD_MAP_STAGE.LDT | 19 | 18 | Guofu adds _Map_Search at end |

Despite column differences, the _Name field at col 7 (0-indexed) contains EUC-KR encoded Korean text in **both** versions. Guofu LDTs do NOT contain simplified Chinese text — the Chinese display is handled client-side.
