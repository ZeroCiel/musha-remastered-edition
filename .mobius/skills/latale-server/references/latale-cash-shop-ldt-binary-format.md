# CASH_SHOP.LDT Binary Format

## S2 Server2 Format (hexiang build)

**File structure**: 12-byte header + 4143 field names × 64 bytes + data section (with padding gap).

### Header
```
Offset 0-3:   00 00 00 00       (unused/reserved)
Offset 4-7:   40 00 00 00       (field name padding = 64 bytes per field)
Offset 8-11:  2f 10 00 00       (field count = 4143 = 0x102f)
Offset 12+:   field names, each padded to 64 bytes with spaces
```

### Data Records
- **Record size**: 270 bytes per record
- **Data section start**: header_end + ~164033 bytes of padding (exact offset determined by finding first record with CategoryView=1)
- **Fixed width**: YES — every record is exactly 270 bytes

### Record Layout (270 bytes)

#### Leading Fixed Fields (24 bytes)
| Offset | Size | Field |
|--------|------|-------|
| 0-3    | 4    | `_CategoryView` |
| 4-7    | 4    | `_CategoryIndex` |
| 8-11   | 4    | `_CategoryIndex2` |
| 12-15  | 4    | `_PositionIndex` |
| 16-19  | 4    | `_Suggest` (sequential auto-increment) |
| 20-23  | 4    | `_EventType` |

#### Variable Strings (starts at offset 24)
| Offset | Size | Field |
|--------|------|-------|
| 24-25  | 2    | name_len (little-endian uint16) |
| 26+    | name_len | `_Name` (GBK encoded, null-terminated) |
| after name | 2 | padding (00 00) |
| varies | 2 | desc_len (usually 0) |
| varies | 2 | icon_file_len (usually 0) |

After strings, text fields usually have len=0 so effectively:
- name uses 14-18 bytes (2 for len + name data + 2 null padding)
- desc uses 2 bytes (len=0)
- icon_file uses ~4 bytes (len=152? or just padding to alignment boundary)
- Fixed fields start around offset 42-46 in practice

#### Fixed 4-byte Fields (starts after all strings, ~236 bytes total)

All fields are little-endian uint32.

**Icon/Gender/Price block (6 fields):**
- `_IconIndex` — icon frame index
- `_Gender` — gender restriction (200 = unisex?)
- `_PriceType` — 0 = gold? 1 = cash/points?
- `_CashPrice` — price in cash
- `_SalePrice` — sale/discount price
- `_EventIcon` — event icon overlay

**Item slot block (32 fields = 8 slots × 4 fields each):**
```
for each slot 1-8:
  _ItemID<N>     — item ID
  _ItemRare<N>   — rarity/enhance level
  _ItemCount<N>  — quantity
  _PriceRate<N>  — price rate multiplier
```

**Extended fields (21 fields):**
- `_MotionID`
- `_ClassID` — class restriction (88 = all classes?)
- `_Require1_Type`, `_Require1_ID`, `_Require1_Value1`, `_Require1_Value2`
- `_Require2_Type`, `_Require2_ID`, `_Require2_Value1`, `_Require2_Value2`
- `_Require3_Type`, `_Require3_ID`, `_Require3_Value1`, `_Require3_Value2`
- `_Buy_Disable`
- `_Give_Disable`
- `_Limited_Time_Type`
- `_Cap_Point`
- `_Cap_Check`
- `_Refund_Check`
- `_World_Amount`

Total fixed fields: 6 + 32 + 21 = 59 fields × 4 bytes = 236 bytes.

### Example Record: 暖呼呼粉嫩大衣

```
_CategoryView = 1
_CategoryIndex = 7
_CategoryIndex2 = 22
_PositionIndex = 0
_Suggest = 991708
_EventType = 1
_Name = "暖呼呼粉嫩大衣"
_IconIndex = 10001212
_Gender = 200
_PriceType = 0
_CashPrice = 1
_SalePrice = 88
_EventIcon = 0
_ItemID1 = 1709
_ItemRare1 = 1
_ItemCount1 = 1
_PriceRate1 = 1
_ItemID2 = 51776811
_ItemRare2 = 1
...all remaining items = 0...
_ClassID = 88
```

## S4chd Format (different)

The S4chd CASH_SHOP.LDT has:
- Field name padding = 68 bytes (not 64)
- Field count = 4309 (not 4143)
- **Different record format** — the S4 records do NOT have the 6 leading CategoryView/CategoryIndex/etc. fields before the Name string
- S4 header data starts at different offset

Record structure was NOT fully decoded in the session that produced this reference.
