# xlrd列偏移修复记录（2026-05-29）

## 问题

从桌面xls文件（65列）读取数据追加到CASH_SHOP.LDT（64列）时，连续3次写入结果全错：
- _Name为空
- _ItemID1为0
- 所有数据整体偏移1列

## 根因

xls是65列（第0列=`_RowId` + 64个CASH_SHOP字段），而CASH_SHOP.LDT是64列（无_RowId）。

错误写法：`for c in range(sh.ncols): row.append(sh.cell_value(r, c))`
→ 把_RowId当成了_CategoryView写入

正确写法：`row = [sh.cell_value(r, c) for c in range(1, sh.ncols)]`

## 验证方法

写入后读取新行的二进制，检查关键字段：

```python
# 检查第6列（_Name）是否为可读的商品名
# 检查第15列（_ItemID1）是否匹配预期
```

如果`_Name`为空或`_ItemID1=0`，说明写入时列偏移了。

## xls列对应关系

```
xls col0 = _RowId（跳过）
xls col1 = CASH_SHOP col0 (_CategoryView)
xls col2 = CASH_SHOP col1 (_CategoryIndex)
...
xls col7 = CASH_SHOP col6 (_Name)
xls col8 = CASH_SHOP col7 (_Description)
...
xls col15 = CASH_SHOP col14 (_EventIcon)  -- 注意不是_ItemID1
xls col16 = CASH_SHOP col15 (_ItemID1)
...
xls col64 = CASH_SHOP col63 (_Limited_Time_Type)
```

## 执行环境限制

`execute_code`沙箱没有`xlrd`库，必须通过terminal()调用系统Python：`C:\Users\Administrator\AppData\Local\Programs\Python\Python311\python.exe`

推荐工作流：将写入脚本写到`C:\Users\Administrator\Temp\`，用terminal执行。
