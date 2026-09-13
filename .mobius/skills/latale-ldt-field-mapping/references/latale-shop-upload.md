# 商城上架工作流

## 1. ITEM_2筛选
详见 `item2-clean-strategy` 参考。

## 2. CashCheck设置
```python
# LDT中col10（0-based）= _CashCheck
# 搜道具名→定位行→改col10 0→1
```

**安全**：单独改CashCheck不会导致Bay崩溃。

## 3. LDT 65536/16777216 污染清零

```python
targets = [65536, 16777216]
for row in range(10053):
    off = DATA_OFF + row * ROW_SIZE
    for ci in range(48):
        val = struct.unpack_from('<I', data, off + ci*4)[0]
        if val in targets:
            struct.pack_into('<I', data, off + ci*4, 0)
```

## 4. CASH_SHOP.xls 生成（66列格式）

彩虹岛编辑器要求CASH_SHOP.xls有**66列**（65个字段 + 末尾空列/TAB）。

| 索引 | 字段 | 说明 |
|------|------|------|
| 0 | _ID(RowId) | 自增 |
| 1 | _CategoryView | 1 |
| 2 | _CategoryIndex | 商城大分类 |
| 5 | _PositionIndex | 排序，自增 |
| 6 | _EventType | 0 |
| 7 | _Name | GBK编码 |
| 9 | _IconFile | **必填！** |
| 10 | _IconIndex | **必填！** |
| 13 | _CashPrice | 240 |
| 16 | _ItemID1 | 道具ID |
| 62 | _Buy_Disable | **必填1** |
| 63 | _Give_Disable | **必填1** |
| 64 | _Limited_Time_Type | 0(永久) |
| 65 | (空) | 末尾TAB |

### 图标读取（注意列偏移！）
从item2_clean.txt读图标：col8 = IconFile, col9 = IconIndex（0-based = parts[7], parts[8]）

### GS报错排查
| 错误 | 可能原因 | 修复 |
|------|---------|------|
| `Invalid Data iPackageID = [N]` | IconFile/IconIndex=0, 行数不是66列, ItemID不存在 | 补图标/加末尾TAB/修正ItemID |
| `CASH_PRICE_RATIO.LDT No Data` | _Limited_Time_Type非法 | 只能0/1001/1002 |

## 当前推荐工作流
1. Python生成CASH_SHOP.xls（66列，图标从item2_clean.txt col8/col9读）
2. 彩虹岛编辑器打开CASH_SHOP.LDT，导出TXT
3. 合并TXT，再导回LDT
4. 打包测试
