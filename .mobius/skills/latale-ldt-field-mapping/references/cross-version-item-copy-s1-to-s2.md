# S1 → 怀旧S2 ITEM表道具复制指南

## 场景

从S1端（`D:\LaTale\彩虹岛S1`，109列格式）复制一条道具到怀旧S2端（`D:\彩虹岛`，125列格式）。

## 核心差异

| 属性 | S1 | 怀旧S2 |
|------|-----|--------|
| ITEM_2列数 | 109 | 125 |
| _Name存储 | 索引ID（type=1 int，非中文名） | 直接中文名（string） |
| type=3字段 | **按int32读取**（float×int混合存储） | 按int32读取 |
| _RowId列 | **无** | **无** |
| 独有列 | _NameColor | _StatusType5~8, _Use_Type, _Specialeffect, _Seal_*, _Colouring, _Pattern*, _Breakup, _Pet_Potential |
| S1无的16列 | — | _Use_Type, _StatusType5~8, _StatusValue5~8, _Specialeffect, _Seal_Min_Cnt, _Seal_Max_Cnt, _Colouring, _PatternClass, _PatternType, _Breakup, _Pet_Potential |

## S1端ITEM表解析注意

1. **type=3字段按int32读**：`_Category`、`_Type`、`_SubType`、`_Icon`、`_IconIndex`、`_GamePrice` 等字段类型号是3(float)，但实际存的是int32。用`struct.unpack('<i')`而非`struct.unpack('<f')`。
2. **`_Name`不是道具名**：类型号1(unsigned short)，存的是GLOBAL_STRING索引ID。0=空，非0值指向某字符串表的行号。
3. **道具中文名**：无法通过二进制搜索ITem表找到。优先用彩虹岛编辑器打开看，或从CASH_SHOP的_Name字段反查。
4. **GLOBAL_STRING两列全0**：S1的GLOBAL_STRING.LDT实际没有写入中文字符串，文字不在标准位置。
5. **S1 CASH_SHOP的_Name是string**：可以直接读中文名，用它反查ItemID再搜ITEM表。

## 字段映射规则

前20列列名一致（_Category ~ _SubPosID22），可直接一对一对映射。

S1独有字段填0：
- `_NameColor[74]` → 怀旧无此列，跳过

怀旧独有字段填默认值：
- `_Use_Type[5]` = 0
- `_StatusType5~8[30/32/34/36]` = 0
- `_StatusValue5~8[31/33/35/37]` = 0
- `_Specialeffect[83]` = 0
- `_Seal_Min_Cnt[118]` = 0
- `_Seal_Max_Cnt[119]` = 0
- `_Colouring[120]` = 0
- `_PatternClass[121]` = 0
- `_PatternType[122]` = 0
- `_Breakup[123]` = 0
- `_Pet_Potential[124]` = 0

## S1→怀旧字段值直映射

当S1和怀旧端的列名一致且S1的值是int时，可以直接拷贝：

```
S1列[索引]         → 怀旧列[索引]
_Category[0]       → _Category[0]
_Num[1]            → _Num[1]        (注意ItemID可能冲突！)
_ColorID[2]        → _ColorID[2]
_Name[3]           → _Name[3]       (但是S1是索引ID，怀旧要填中文名或0)
_Description[4]    → _Description[4] (同_Name)
_Icon[6]           → _Icon[6]
_IconIndex[7]      → _IconIndex[7]
```

S1索引5(_Use_Type)在S1不存在 → 怀旧填0。
S1索引74(_NameColor) → 怀旧没有此列，跳过。

## 怀旧端追加行方式

1. **备份**：`shutil.copy2(path, path + ".bak")`
2. **更新行数**：`struct.pack_into('<I', data, 8, old_count + 1)`
3. **逐列写二进制**：按type号pack
   - type=3(float)字段用 `struct.pack('<i', int_val)` 写int32
   - type=1(word)用 `struct.pack('<H', val)`
   - type=2(dword)用 `struct.pack('<I', val)`
   - type=0(byte)用 `struct.pack('<B', val)`
4. **写回文件**

## 实战：冰弓时装武器（怀旧端）

RowId：无显式_RowId列，直接append到末尾（9583→9584行）
关键值：
- `_Category=1`（武器）
- `_Type=1`（装备）
- `_SubType=1`（普通武器）
- `_PosID1=3`（时装位置）
- `_Icon=10001101`（冰弓贴图文件）
- `_IconIndex=174`
- `_ItemLv=1`
- `_Trade/_Destroy/_Storage/_Sell=1`
- `_EnchantAllow=1`
- `_Name` 和 `_Description` 填0（待补文字索引）
- 其余所有字段填0

## 注意事项

1. **ItemID(_Num)必须唯一**：建议与S1原ID不同，用怀旧端不冲突的数值
2. **S1→怀旧的_Name不能直接复制**：S1存的是索引ID(int)，怀旧存的是string(中文名)
3. **写入后测试**：用彩虹岛编辑器打开怀旧端ITEM_2，翻到最后行确认数据正确
4. **CASH_SHOP也需追加**：ITEM_2写完还要在CASH_SHOP加对应行才能在商城显示
5. **SPF打包**：改完LDT后需要重新打包ROWID.SPF才能生效
