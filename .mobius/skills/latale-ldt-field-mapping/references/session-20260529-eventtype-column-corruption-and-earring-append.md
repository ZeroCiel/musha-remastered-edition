# 2026-05-29 会话：EventType列偏移修复 + 耳环166件追加

## 场景

向CASH_SHOP.LDT追加166件耳环（从发型_xls导出.txt提取），GS启动时报错：

```
(CCashShopInfo::IsValid,103) : CASH_SHOP.LDT : CASH_PRICE_RATIO.LDT No Data 2541 银瀑布水耳环(7天) 240 1 2
(CCashShopInfoManager::SetData,143) : CASH_SHOP.LDT : Invalid Data 2541 银瀑布水耳环(7天) 240 1 2 1
```

## 根因：TXT→LDT列映射偏移

TXT有65列：col0=_RowId, col1=_CategoryView, ... col6=_EventType, col7=_Name
CASH_SHOP.LDT有64列：col0=_CategoryView, col1=..., col5=_EventType, col6=_Name

当 `for ci in range(64): v = parts[ci]` 时，parts[0]=_RowId（应该跳过），导致：
- LDT col0(CV) = parts[1] → 正确
- LDT col4(PosIdx) = parts[5] → 正确
- **LDT col5(EvType) = parts[6] = 原来的_PositionIndex值（如912008） → 错误！**
- LDT col6(Name) = parts[7] = 0/1 → 变成了EventType的数字！

**修复**：`for ci in range(64): v = parts[ci+1]`（跳过了TXT的col0）

## 验证方法

写完后读回新行的二进制数据，检查：
- _EventType ∈ {0, 1}
- _Name 实际为道具名（非数字）

## PosID1=2也可为时装

雪ミク系列（PosID1=2, Type=1, SubType=1）在CASH_SHOP中有记录，_CategoryView=0隐藏。
它们不适用于传统的"PosID1∈{3,4,5,6,7,8,11}=时装"判断。

## BANX主图差异（快速对照）

他乡端多21个完整IconFile：
10001105, 10001112, 10001113, 10001213, 10001214, 10001320, 10001321, 10001440~10001454系列, 10004301, 10004401, 10004403

共同IconFile中他乡多出的索引（如10001212多64张，怀旧端到190他乡到255）
