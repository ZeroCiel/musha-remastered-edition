# CASH_SHOP追加GS崩溃分析与ITEM_2 CashCheck修复（2026-05-28）

## 核心原理：上架商品需要两步

GS加载CASH_SHOP时，会用`_ItemID1`去ITEM_2查`_CashCheck`。如果`CashCheck=0`（未上架），GS会校验失败并崩溃。

**所以追加CASH_SHOP行前，必须先改ITEM_2的_CashCheck。**

## GS启动报错索引

| 报错 | 含义 | 是否与ITEM_2修改有关 |
|------|------|---------------------|
| `QUEST_DROP_ITEM.LDT : FAILED ! iMonsterID = [810002615]` | GS exe硬编码了MonsterID查询，但QUEST_DROP_ITEM表里没有MonsterID列。810002615是该行自身的_RowId。 | ❌ 完全无关，不影响功能，可忽略 |
| `CASH_SHOP.LDT : FAILED ! iPackageID = [数字]` | CASH_SHOP._ItemID1引用了ITEM_3中不存在的ID | ⚠️ 数据问题 |
| 无日志直接闪退 | LDT结构损坏 / "设计"字被改 | 排查LDT完整性 |

## ITEM_2 CashCheck修改步骤

```python
# 正确筛选逻辑
FASHION_POSIDS = {3, 4, 5, 6, 7, 8}  # 注意：不包含11（翅膀位）
for row in rows:
    # row[0] = _RowId, row[1] = col0, row[2] = col1, ...
    # read_rows返回的索引要+1！
    p1 = row[posid1_idx + 1]  
    cc = row[cc_idx + 1]
    desc = str(row[desc_idx + 1])
    
    if p1 in FASHION_POSIDS and cc == 0 and not desc.startswith('基本'):
        # 二进制改CashCheck
        struct.pack_into('<I', data, cc_abs_offset, 1)
```

## 分批测试策略

用户偏好：**先只改一个部位测试**（如发型PosID1=3），能跑再加其他部位。不要一口气改全部。

## 导出文件格式

用户手动导入彩虹岛编辑器时，**txt（|分隔）比xls更实用**——可以直接复制粘贴到编辑器的新增行中。

txt规范：
- 64列（不含_RowId），第1行=字段名
- | 分隔，UTF-8
- 文本内容含|时分隔符改为丨
- _RowId从2400起，_PositionIndex从912008起
- _Buy_Disable=1, _Give_Disable=1, _CashPrice=240
