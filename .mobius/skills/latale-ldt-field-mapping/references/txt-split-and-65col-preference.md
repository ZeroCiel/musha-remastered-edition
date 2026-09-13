# TXT分类拆分 + 65列格式偏好（2026-05-29）

## 用户格式偏好（重要）

**"以后发格式需要写进_RowId"** — 从今以后所有CASH_SHOP追加TXT文件必须包含`_RowId`作为第1列，即65列（`_RowId` + CASH_SHOP 64字段）。

之前给64列（不含_RowId）的格式被用户明确纠正。原因：彩虹岛编辑器导入时需要看到_RowId字段才能正确识别数据行。

## TXT分类拆分工作流

当从ITEM_2全量筛选生成的TXT（约1200行）中混入非发型物品时，按以下流程拆分：

### 1. 查ITEM_2确定分类

逐个ItemID查ITEM_2的_PosID1、_Type、_SubType、_Name：

```
发型(PosID1=3) → 发型文件
耳环类 → 名称含"耳环"、"指南针"、"耳朵"
其他（衣服/裤子等）→ 按PosID1分类或归入主文件
```

### 2. 联动时装单独处理

雪初音2011~2014（24件）、Magic_Ver.1~4（4件）等联动时装：
- 可能已在CASH_SHOP中但_CategoryView=0（隐藏）
- 用户不可见，需要单独追加或改可见
- 生成单独的CASH_SHOP追加文件（24~28行）

### 3. 重编号

每个分类文件独立重编号：
- 文件内部连续、不跨文件重号
- _RowId从2400起
- _PositionIndex从912008起

### 3.5 耳环生成时的排除规则

从全量xls提取耳环文件时，必须排除：
- 名称含"不使用"的条目（如"不使用_太极耳环""不使用_太极旗耳环""不使用_环型耳环"）
- 名称含"测试用"的条目（如"测试用时尚耳环"）
- 这些是测试/废弃道具，加入商城无意义（用户明确要求删除）

### 4. 输出格式

```
_RowId|_CategoryView|_CategoryIndex|_CategoryIndex2|_CategoryIndex3|_PositionIndex|...64字段
```
- 65列（第1列_RowId + 64个CASH_SHOP字段）
- |分隔
- UTF-8编码
- 第1行字段名
- 不允许缺少任何列

### _Name列索引陷阱

在65列TXT中，_Name在第8列（0-indexed=7），不是第9列（0-indexed=8）。
- 表头：`_RowId|_CategoryView|_CategoryIndex|_CategoryIndex2|_CategoryIndex3|_PositionIndex|_EventType|_Name|_Description|...`
- 所以如果`parts = line.split('|')`，`parts[7]`才是_Name（**不是parts[8]**）
- 把parts[8]当成_Name会导致所有名称为空

## 联动时装特点

雪初音2011~2014系列（ITEM_2）：
- PosID1=1（不是标准时装部位3~8）
- Type=1 SubType=2（装备类，时装子类）
- _Name是数字（GLString引用），_Description有日文名
- 部分已在CASH_SHOP中（_CategoryView=0隐藏）
- 可以用_Description前20字符作为商城名，或用日文原名

Magic_Ver.1~4：
- 炼金术士联动（シャーリーのアトリエ）
- 同样是PosID1=1, Type=1, SubType=2
- CASH_SHOP已有但隐藏（_CategoryView=0）
- 价格200点券（比普通时装240略低）

## 判断时装的终极标准

PosID1=3~8只是国服标准。在他乡端/跨服端：

**Type=1（装备类）且SubType=2（时装子类）才是判断时装的最终标准**

PosID1=1也可以有Type=1 SubType=2的时装（如雪初音帽子、发箍、蝴蝶结等头饰类）
PosID1=2也可以有时装（雪初音鞋子、手套等部件）

所以筛选时装时：
1. 先用 Type=1 AND SubType=2 筛选
2. 再用 _Name可读 / _Description不含任务关键词 做二次过滤
3. 最后看PosID1确认部位分类
