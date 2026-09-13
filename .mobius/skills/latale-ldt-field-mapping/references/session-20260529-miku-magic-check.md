# 2026-05-29 雪初音/Magic_Ver系列检查 + CASH_SHOP格式TXT分类拆分

## 雪初音2011~2014 (雪ミク) 系列

- 共24件，全部PosID1=1（头饰类），Type=1 SubType=2（时装子类）
- _Name是数字（如"1""2""3""4""5""7"），_Description是日文描述（如"雪ミク2014魔女帽子"）
- 不是GLString引用——_Category/Num/ColorID正好组成ID后几位（904/816/04=ID 90481604）
- CashCheck=1（已允许上架）
- CASH_SHOP只有5件存在（RowId=1322~1326），全为_CategoryView=0（隐藏），分类(6,14,0)
- 另外19件未在CASH_SHOP中

### 关键发现：跨服端时装的PosID1范围比国服更广

他乡端（跨服端）中，**PosID1=1**的物品也可能是时装，不限于{3,4,5,6,7,8}。
筛选时装时需额外检查 _Type=1, _SubType=2（时装子类）。

## Magic_Ver.1~4 系列 (炼金术士联动)

| 商城名 | ItemID | 名称(日文) | 实际物品 |
|--------|--------|-----------|---------|
| Magic_Ver.1 | 90581701 | シャリステラのカチューシャ | 发箍(铃铛) |
| Magic_Ver.2 | 90481702 | シャルロッテのキャップ | 猫耳帽 |
| Magic_Ver.3 | 90481703 | ウィルベルのハット | 大帽子(魔法阵) |
| Magic_Ver.4 | 90581704 | ミルカのヘアリボン | 发带 |

- 全部PosID1=1, Type=1, SubType=2, CashCheck=1
- CASH_SHOP中RowId=1327~1330，分类(6,14,0)，_CategoryView=0，价格200
- _Name为日文（非数字ID，可读文本）

## CASH_SHOP格式TXT分类拆分工作流

### 场景
从ITEM_2.CashCheck=0筛选后生成的CASH_SHOP格式TXT文件（约1200行）中，混入了非发型物品（耳环、指南针等）。

### 分类方法
1. 读取目标TXT的所有行
2. 从ITEM_2.LDT查找每个ItemID的_PosID1、_Type、_SubType
3. 按以下规则分类：
   - **发型**：PosID1=3 或 (PosID1=1, Type=1, SubType=2 且名称含"发型"/"头发")
   - **耳环/指南针/耳朵类**：名称含"耳环""指南针""耳朵"
   - **装备/武器类**：PosID1=1或2, Type=1, SubType=1
   - **雪初音/Magic_Ver联动**：含"雪ミク""雪初音""Magic_Ver"

### 重编号规则
- _RowId从2400起递增（用户指定）
- _PositionIndex从912008起递增
- 每类文件独立重编号

### 文件生成
- 发型only: `发型only_CASH_SHOP格式.txt`
- 耳环类: `耳环类_CASH_SHOP格式.txt`
- 雪初音追加: `雪初音_CASH_SHOP上架格式.txt`（CASH_SHOP直接追加格式）

## 补充：跨服端的PosID1=1时装筛选规则

**PosID1取值范围不要局限于{3,4,5,6,7,8}**。他乡端/跨服端的时装可能存放在PosID1=1（头饰类）中，包括：
- 雪初音2011~2014系列24件
- Magic_Ver.1~4（炼金术士联动）
- 初音ミクGP ver.フェザー

**判断标准**：_Type=1, _SubType=2 时，无论_PosID1值为何，都是时装。
