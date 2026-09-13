# ITEM_1 装备限制与CLASS_STRING职业名对照

This file is kept for historical reference. The current localisation work is tracked in `references/2026-06-04-localization-session.md`.

## ITEM_1.xls 装备限制列索引 (0-based)
- col14: _Type (1=武器/装备)
- col15: _SubType
- col16: _PosID1 (部位ID, 13=弓)
- col39: _Require1_Type (0=无限制, 1=职业)
- col40: _Require1_ID (ClassID)
- col41: _Require1_Value1
- col42: _Require1_Value2
- col43: _Require2_Type
- col44: _Require2_ID
- col45: _Require2_Value1 (可能有位标记污染如2199024305160)
- col46: _Require2_Value2

## CLASS_STRING 台服→国服职业映射
| ClassID | TYPE值 | 台服 | 国服 |
|---------|--------|------|------|
| 1 | 1 | 战士 | 战士 |
| 2 | 2 | 骑士 | 盾卫 |
| 3 | 4 | 法师 | 法师 |
| 4 | 8 | 游侠 | 游侠 |
| 5 | 16 | 督军 | 督军 |
| 6 | 32 | 剑斗士 | 双刀 |
| 8 | 64 | 圣殿骑士 | 圣殿骑士 |
