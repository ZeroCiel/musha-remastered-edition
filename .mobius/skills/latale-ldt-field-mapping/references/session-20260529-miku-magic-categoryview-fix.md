# 雪初音 + Magic_Ver 联动时装可见性修复（2026-05-29）

## 背景

彩虹岛S2他乡端CASH_SHOP.LDT中存在9件_CategoryView=0的隐藏联动时装：
- 雪初音2011~2014：5件（ItemID: 90481604, 81281604, 40181601, 90581602, 90281603）
- Magic_Ver.1~4（炼金术士联动）：4件（ItemID: 90581701, 90481702, 90481703, 90581704）

## 发现过程

1. 在CASH_SHOP中搜"Magic_Ver"发现4条记录，搜"雪"发现相关行
2. 原CASH_SHOP.LDT文件（bak_hair版本，1492行）中存在这9行
3. 当前CASH_SHOP.LDT（1482行）已被用户清理删除了这些行
4. 从bak_hair备份中提取原始二进制数据，改_CategoryView=1后追加回当前文件

## 关键信息

### 这些物品的ITEM_2属性

雪初音系列：
- 全部 `Type=1, SubType=2`（时装）
- `PosID1=1`（不是常见3~8，而是头饰/联动类）
- `CashCheck=1`（端自带已开启上架）
- `_Name` 是日文名直接写入（非GLString ID）
- `_Icon`=10001501，`_IconIndex`各不同（97~125）
- 无时限

Magic_Ver系列：
- 全部 `Type=1, SubType=2`（时装）
- `PosID1=1`
- `CashCheck=1`
- `_Name` 是日文名直接写入

### CASH_SHOP中的设定

- 分类(6,14,0) — 联动专用分类
- `_CategoryView=0` → 隐藏
- `_PriceType=1, CashPrice=200`
- `_Buy_Disable=1, _Give_Disable=1`

### 判断时装的终极标准

不是PosID1，而是 `Type=1 AND SubType=2`。PosID1=1/2也可能是时装：
- 雪初音2011~2014系列24件：PosID1=1, Type=1, SubType=2
- Magic_Ver系列4件：PosID1=1, Type=1, SubType=2

## 修复方法

1. 定位备份文件（如 `CASH_SHOP.LDT.bak_hair`）
2. 找到目标行的二进制位置（RowId范围1322~1330）
3. 提取整行数据（不含RowId）
4. 修改第0个字段（_CategoryView）从0→1
5. 更新RowId为当前最大+1
6. 更新_PositionIndex为当前最大+1
7. 追加到当前CASH_SHOP.LDT末尾
8. 更新文件头行数

## 验证

打包SPF后启动GS，商城可见这9件商品，可直接购买。
但官方已移除贴图资源（客户端无对应形象），购买后显示为空白/透明。

## 参考

- bak_hair备份：`D:\彩虹岛\resource\ROWID\DATA\LDT\CASH_SHOP.LDT.bak_hair`（1492行）
- 修复前备份：`.bak_before_miku_visible`
- 对应TXT导出：`C:\Users\Administrator\Desktop\雪初音_CASH_SHOP上架格式.txt`（24件完整雪初音）
