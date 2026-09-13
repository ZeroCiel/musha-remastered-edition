# Session 2026-05-29: Shoe Append + GS Debug

## Key Learnings

### PosID1 Mapping Correction
**Old (wrong):** PosID1=7=鞋子
**Corrected:** PosID1=7=**手套**, PosID1=8=**鞋子**, PosID1=9=**翅膀**

This was discovered when "鞋子" file contained "金钱豹毛手套"、"黑羊手套" etc. — all gloves.

| PosID1 | Actual Body Part |
|--------|-----------------|
| 1 | Headband/Special |
| 2 | Weapon/Special |
| 3 | Hair |
| 4 | Top/Clothes |
| 5 | Pants |
| 6 | Ring/Special |
| 7 | **Gloves** |
| 8 | **Shoes** |
| 9 | Wings |
| 10 | Face decoration |
| 11 | Wings/Quest items (mixed!) |
| 12-14 | Rings/Shields |
| 17+ | Unknown |

### GS Crash Debug: ItemID in CASH_SHOP must have CashCheck=1

Even if CASH_SHOP has a valid row pointing to an ItemID, **the ItemID must have _CashCheck=1 in ITEM_2** or GS will reject the row.

Log pattern without CASH_PRICE_RATIO hint:
```
CASH_SHOP.LDT : Invalid Data 2803 耶比妹妹拖鞋(7日) 240 1 1001 1
......DATA/LDT/CASH_SHOP.LDT : FAILED !    iPackageID = [2803]
```
→ Check ItemID=1200000002 in ITEM_2 → CashCheck=0. Fix: set to 1.

### First-run verification pattern
After appending to CASH_SHOP and fixing ITEM_2 CashCheck:
1. Start GS
2. Check log for `GetCashShopInfoManager()::Init() : [OK]` (success) vs `FAILED` (failure)
3. If FAILED, read the `iPackageID = [{RowId}]` to find the problem row

### User workflow preference (reinforced)
- User explicitly said binary writes "seem to not work" and prefers manual rainbow editor copy-paste
- User explicitly said "你不是二进制的问题，你需要测试验证" — the GS failure isn't about binary format, it's about field values
- The correct workflow: generate txt → let user add via editor → user tests → report back
