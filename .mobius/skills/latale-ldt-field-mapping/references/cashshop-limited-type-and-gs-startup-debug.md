# CASH_SHOP _Limited_Time_Type 与 GS 启动失败排查

## 现象

GS启动时CASH_SHOP加载到某行后FAILED，日志：
```
(CCashShopInfo::IsValid,103) : CASH_SHOP.LDT : CASH_PRICE_RATIO.LDT No Data {RowId} {Name} 240 1 {Limited}
(CCashShopInfoManager::SetData,143) : CASH_SHOP.LDT : Invalid Data {RowId} {Name} 240 1 {Limited} 1
......DATA/LDT/CASH_SHOP.LDT : FAILED !    iPackageID = [{RowId}]
GetCashShopInfoManager()::Init() : [FAILED]
```

## 根因

_Limited_Time_Type 的值不正确。

### 取值规则

| 类型 | _Limited_Time_Type | 说明 |
|------|-------------------|------|
| 永久 | 0 | 无时限 |
| 7天限时 | **1001** | 对应CASH_PRICE_RATIO中RowId=1001的行 |
| 30天限时 | **1002** | 对应CASH_PRICE_RATIO中RowId=1002的行 |
| 15天/1天/3天等 | 1001 | 没有专用行，复用7天比例 |

**错误的值**：1、2 或其他不是CASH_PRICE_RATIO.RowId的数字。
原因：GS加载限时道具时，用_Limited_Time_Type去CASH_PRICE_RATIO中按RowId查找价格比例行。
当前CASH_PRICE_RATIO.LDT只有两行：
```
RowId=1001 → [0, 0, 28, 0, 100, 249, 0, 0, 0]  (7天比例28, 30天比例100, 90天比例249)
RowId=1002 → [0, 0, 0, 0, 100, 0, 0, 0, 0]      (30天比例100)
```

### CASH_PRICE_RATIO结构

9列：_Price_Ratio1, _Price_Ratio3, _Price_Ratio7, _Price_Ratio15, _Price_Ratio30, _Price_Ratio90, _Price_Ratio180, _Price_Ratio360, _Price_Ratio_Unlimit

每列对应相应天数的价格倍率（百分比）。如RowId=1001的_Price_Ratio7=28表示7天道具价格为永久价格的28%。

## 其他GS启动失败原因

### 1. 列偏移（_EventType写入PositionIndex值）

如果日志中_EventType值异常大（如912008而不是0或1）：
- 检查写入时是否跳过TXT的第0列（_RowId）
- TXT有65列，CASH_SHOP.LDT有64列，`parts[ci+1]`才是LDT的第ci列

### 2. _Limited_Time_Type=1

值1是非法值。限时类必须=CASH_PRICE_RATIO的RowId（1001/1002），永久类=0。

## 验证方法

追加行后，读回二进制确认关键字段：
```python
# 读新行的_EventType(col5)和_Name(col6)
fp = row_start + 4  # 跳过RowId
fp += 5 * 4  # 跳过col0~4 (都是int)
ev = struct.unpack('<I', d[fp:fp+4])[0]  # col5 = EventType
assert ev in (0, 1), f'EventType={ev} 异常！列偏移了'

# 读_Limited_Time_Type(col63)
lt_pos = row_start + 4
for ci in range(63):  # 跳到col63
    t = col_types[ci]
    if t == 1:
        slen = struct.unpack('<H', d[lt_pos:lt_pos+2])[0]
        lt_pos += 2 + slen
    else:
        lt_pos += 4
lt = struct.unpack('<I', d[lt_pos:lt_pos+4])[0]
assert lt in (0, 1001, 1002), f'Limited={lt} 异常！'
```
