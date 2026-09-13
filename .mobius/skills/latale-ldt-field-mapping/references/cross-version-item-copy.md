# 跨版本ITEM表数据拷贝指南

## 背景

彩虹岛不同版本（S1/S2/S3/他乡/怀旧）的ITEM_1/2/3.LDT列结构不同，不能直接复制行。

## 版本列结构差异

| 版本 | 列数 | 行数(ITEM_2) | 数据区特征 | 解析方式 |
|------|------|-------------|-----------|----------|
| S1 (彩虹岛S1) | 109列 | 2901行 | 固定宽+变长string | 按类型号(0~5)解析 |
| 怀旧端 (他乡包衍生) | 125列 | 9583~10591行 | 固定500字节/行 | 前48列int4B+string区\x00分隔 |

## S1 vs 怀旧端 ITEM_2 共有列

前20列名称和顺序完全一致：
`_Category, _Num, _ColorID, _Name, _Description, _Icon, _IconIndex, _GamePrice, _CashPrice, _CashCheck, _Update_Date, _RareLimit, _Type, _SubType, _PosID1, _SubPosID11, _SubPosID12, _PosID2, _SubPosID21, _SubPosID22, _Kind`

S1独有的列(1个)：
- `_NameColor` (索引74, type=2)

怀旧端独有的列(17个)：
- `_Use_Type` (索引5, type=1) — S1没有这个列！
- `_StatusType5~8` / `_StatusValue5~8` (索引30~37)
- `_Specialeffect` (索引83)
- `_Seal_Min_Cnt` / `_Seal_Max_Cnt` (索引118~119)
- `_Colouring` / `_PatternClass` / `_PatternType` / `_Breakup` / `_Pet_Potential` (索引120~124)

## 跨版本拷贝策略

### 不可行：整行复制
- S1行(109列)不等于怀旧端行(125列)
- 直接复制行数据会导致列偏移和解析错误

### 推荐：手动配对字段

```python
# 从S1读取目标行
s1_row = parse_ldt_get_row(s1_path, target_rowid_or_index)

# 在怀旧端新建/重写行
hj_path = "D:\\彩虹岛\\resource\\ROWID\\DATA\\LDT\\ITEM_2.LDT"
# 新建行的INT字段映射：
field_map = {
    '_Category': s1_row.get('_Category', 0),
    '_Num': new_unique_item_id,  # 不能照抄S1的ID！
    '_ColorID': s1_row.get('_ColorID', 0),
    '_Name': s1_row.get('_Name', ''),  # S1的_Name是索引ID，这里实际写中文名
    '_Description': s1_row.get('_Description', ''),
    '_Icon': s1_row.get('_Icon', 0),
    '_IconIndex': s1_row.get('_IconIndex', 0),
    '_GamePrice': s1_row.get('_GamePrice', 0),
    '_Type': s1_row.get('_Type', 0),  # S1是int32或float
    '_SubType': s1_row.get('_SubType', 0),
    '_PosID1': s1_row.get('_PosID1', 0),
    # ... 其余字段根据怀旧端的列结构填充默认值
}
# 怀旧端独有字段填默认值：
hj_extra_defaults = {
    '_Use_Type': 0,    # S1没有，填0
    '_StatusType5': 0, '_StatusValue5': 0,
    '_StatusType6': 0, '_StatusValue6': 0,
    '_StatusType7': 0, '_StatusValue7': 0,
    '_StatusType8': 0, '_StatusValue8': 0,
    '_Specialeffect': 0,
    '_Seal_Min_Cnt': 0, '_Seal_Max_Cnt': 0,
    '_Colouring': 0, '_PatternClass': 0, '_PatternType': 0,
    '_Breakup': 0, '_Pet_Potential': 0,
}
```

### 字段值类型适配

S1的type=3字段在按int32读取后，值可以直接移植到怀旧端的int字段：
- `_Category` → int, 填0(消耗品)/1(装备)/2(材料)
- `_Type` → int, 1=装备
- `_SubType` → int, 1=普通装备
- `_PosID1` → int, 15=武器

S1的_Name/Description是索引ID（非道具名）：
- **_Name在S1=type1(unsigned short)**，存的是字符串表索引ID
- 需要查GLOBAL_STRING或其他表获取实际中文名
- 或直接用彩虹岛编辑器看S1端的ITem名称
- 写入怀旧端时填实际中文名

### S1端Type=3字段的解析陷阱

S1 ITEM表的 _Category/_Type/_SubType/_Icon/_IconIndex/_GamePrice 等字段的类型号=3（float），但**实际存的是int32值**。

```python
# ✅ 正确：按int32读
val = struct.unpack_from('<i', data, o)[0]  # → 0, 1, 2, ...

# ❌ 错误：按float读会得到极小科学计数法值
val = struct.unpack_from('<f', data, o)[0]  # → 2.35e-38（垃圾值）
```

这导致之前的解析脚本全都不对——所有分类字段（Category/Type/SubType）都被读成了极小数，无法筛选。

## RowId搜索确认

当给定一个ItemID后，必须在所有ITEM文件中搜索确认其存在：

```python
# 搜索所有ITEM文件
for fname in ["ITEM_1.LDT", "ITEM_2.LDT", "ITEM_3.LDT"]:
    # 逐行检查所有int字段
    # RowId=518160621 → 在S1和怀旧端的三个ITEM文件都找不到
```

如果所有ITEM文件都找不到，可能原因：
1. 该ID不是ITEM表的RowId，而是CHAR_WEAPON或其他表的ID
2. 该道具在目标版本不存在
3. ID格式不同（如需要补前导0或转换）

## 实操建议

S1端数据提取：
1. **首选彩虹岛编辑器**打开S1的ITEM_2.LDT直接看
2. **次选Python代码**：按type号解析后type=3字段当int32读
3. 找到目标行后，手动配对字段写入怀旧端ITEM_2
4. 怀旧端独有字段填默认值（0）
5. ItemID(_Num)必须唯一，不能照抄S1的ID
6. _Name写实际中文名（不是S1的索引ID）
