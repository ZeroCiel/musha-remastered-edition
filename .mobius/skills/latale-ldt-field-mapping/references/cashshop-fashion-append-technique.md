# CASH_SHOP.LDT 行追加：从ITEM_2批量上架时装

## 操作总结

目标：将ITEM_2中所有时装类道具（PosID∈{3,4,5,6,7,8,11}且CashCheck=0）追加到CASH_SHOP。

## ⚠️ 前置条件：ITEM_2._CashCheck 必须先改（2026-05-28 新增）

CASH_SHOP.LDT 追加行和 ITEM_2._CashCheck 是两个独立但**必须同时完成**的步骤：

1. **ITEM_2._CashCheck 0→1**：允许物品上架商城（"物品列表内先允许上架物品"）
2. **CASH_SHOP.LDT 追加行**：定义商城展示和售价信息

**之前失败（窗口闪退）的原因**：只做了第2步，没做第1步。导致 GS 加载 CASH_SHOP 里引用了大量 CashCheck=0 的物品时，初始化逻辑验证失败崩溃。

### _CashCheck 修改方法

使用二进制直接修改 ITEM_2.LDT 的 `_CashCheck` 字段（第10列，type=3 int）：

```python
# 核心逻辑：按列偏移找到_CashCheck字段的位置，写入1
cc_pos = skip_to_col(data, pos, types, cc, cc_idx)
struct.pack_into('<I', data, cc_pos, 1)
```

筛选条件（与CASH_SHOP追加一致）：
- `_PosID1 ∈ {3,4,5,6,7,8,11}`（时装部位）
- 排除 `_Description` 以"基本"开头的行（基础发型/眼型等，281件）
- 只改 `_CashCheck=0` 的物品

### 执行顺序

```
1. 先改 ITEM_2._CashCheck 0→1（1856件时装）
2. 再追加 CASH_SHOP.LDT 行
3. 打包 ROWID.SPF
4. 重启 GS
```

如果窗口闪退导致数据回档，需要重新从第1步做起。备份文件 `ITEM_2.LDT.bak_cashcheck` 保存修改前的状态。

## 完整流程

### 1. 从ITEM_2筛选时装

关键字段：
- `_Type`(13) / `_SubType`(14) / `_PosID1`(15)
- 时装位置PosID：3=发型 4=衣服 5=裤子 6=手套 7=鞋 8=披风 11=翅膀
- `_CashCheck`(10)=0 → 未上架状态

```python
FASHION_POSIDS = {3, 4, 5, 6, 7, 8, 11}
# 获取
```

### 2. ITEM_2 ⚠️ _Name字段真相（2026-05-28 修正）

**`_Name` 就是中文商品名**，不是数字ID引用！

之前的"数字引用ID"结论是解析bug导致的（列偏移计算错误）。已验证样本：

| RowId | _Name (正确) | PosID | 结论 |
|-------|-------------|-------|------|
| 30245642 | 活动黑色短裤 | 5(裤子) | _Name=中文名 ✅ |
| 70140175 | 愉悦粉红色珠珠凉鞋 | 8(披风) | _Name=中文名 ✅ |
| 130229504 | 梅 | 3(发型) | _Name=中文名 ✅ |

_Description 可能为空或只含换行符，**不要**用它取商品名（会产出"未命名"行）。
详见 `item-2-name-field-truth-verified.md`。

**正确取名方式**：
```python
name = str(row[name_idx]).strip()  # _Name 就是中文名
if not name:
    name = '未命名'
```

### 3. ⚠️ _Icon和_IconIndex精确读取

ITEM_2中`_Icon`(6)和`_IconIndex`(7)都是int类型(type=3)。
但在此之前有3个string字段（_Name, _Description, _Use_Type），如果用while循环按类型跳读，string长度变化会导致后续int字段索引偏移，误读到_Use_Type的内容。

**正确做法**：手动按列索引精确读取，而非自动轮询循环。

列偏移验证（Row0链子短裤）：
- [6] `_Icon` = 10001208 ✅
- [7] `_IconIndex` = 227 ✅

### 4. CASH_SHOP行格式（64字段，与LDT一致）

CASH_SHOP.LDT共64列（不含_RowId），`|`分隔包含_RowId即为65个值：
```
_RowId|_CategoryView|_CategoryIndex|_CategoryIndex2|_CategoryIndex3|_PositionIndex|_EventType|_Name|_Description|_IconFile|_IconIndex|_Gender|_PriceType|_CashPrice|_SalePrice|_EventIcon|_ItemID1|_ItemRare1|_ItemCount1|_PriceRate1|_ItemID2|_ItemRare2|_ItemCount2|_PriceRate2|_ItemID3|_ItemRare3|_ItemCount3|_PriceRate3|_ItemID4|_ItemRare4|_ItemCount4|_PriceRate4|_ItemID5|_ItemRare5|_ItemCount5|_PriceRate5|_ItemID6|_ItemRare6|_ItemCount6|_PriceRate6|_ItemID7|_ItemRare7|_ItemCount7|_PriceRate7|_ItemID8|_ItemRare8|_ItemCount8|_PriceRate8|_MotionID|_ClassID|_Require1_Type|_Require1_ID|_Require1_Value1|_Require1_Value2|_Require2_Type|_Require2_ID|_Require2_Value1|_Require2_Value2|_Require3_Type|_Require3_ID|_Require3_Value1|_Require3_Value2|_Buy_Disable|_Give_Disable|_Limited_Time_Type|
```

实际样例（他乡端）：
```
1709|1|7|22|0|991708|1|暖呼呼粉嫩大衣||10001212|200|0|1|88|0|1|51776811|1|1|1|0|1|0|0|0|1|0|0|0|1|0|0|0|1|0|0|0|1|0|0|0|1|0|0|0|1|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|1|1|0|
2786|1|1|2|5|992785|0|米黄单马尾长发||10001213|215|0|1|60|0|0|90356306|1|1|1|0|1|0|0|0|1|0|0|0|1|0|0|0|1|0|0|0|1|0|0|0|1|0|0|0|1|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|1|1|0|
```

注意：CASH_SHOP行大小不固定（260B~455B，因_Name中文长度变化）。不能使用固定长度二进制模板。

### 5. CASH_SHOP关键字段约束

| 字段 | 取值规则 | 注意 |
|------|---------|------|
| _CategoryView | 1 | 可见 |
| _CategoryIndex | 7(时限) / 1(永久) | |
| _CategoryIndex2 | 22(时限) / 2(发型) / 1(衣服/其他) | 他乡端分类 |
| _CategoryIndex3 | 0 | 他乡为0，你端原有时装为4 |
| _EventType | 1(时限) / 0(永久) | |
| _EventIcon | 1(时限) / 0(永久) | |
| _Name | ITEM_2._Name（中文商品名，不是ID引用） | 2026-05-28已确认 |
| _Description | 留空 | |
| _IconFile | ITEM_2._Icon | 列6，type=3 |
| _IconIndex | ITEM_2._IconIndex | 列7，type=3 |
| _PriceType | 1 | 点券 |
| _CashPrice | 240（走个过场，点券无限） | |
| _SalePrice | 0 | |
| _ItemID1 | ITEM_2._RowId | 道具ID |
| _ItemRare1~8 | 1 | |
| _ItemCount1~8 | 1 | |
| _PriceRate1~8 | 1 | |
| _Buy_Disable | 1 | **必须=1** |
| _Give_Disable | 1 | **必须=1** |
| _Limited_Time_Type | 2(时限) / 0(永久) | |

### 6. 故障响应策略（2026-05-27 实测教训）

⚠️ **用户对此操作容忍度极低。一旦AI失败两次，立刻停手换manual方式。**

**第一次失败**（build_ldt追加 → GS闪退）：
- 确认ItemID1全部在ITEM_2中存在 ✅
- 确认追加后build_ldt线性验证通过 ✅
- _Name=空字符串可能是根因（build_ldt对空string的写入有bug）
- 换方案：从已有CASH_SHOP行复制二进制模板，只改关键int字段

**第二次失败**（二进制模板追加 → GS仍闪退）：
- ❌ **不再尝试第三次自动写入**
- 改为：导出时装清单到桌面 `~/Desktop/时装列表_逐行.txt`
- 格式：他乡端65字段`|`分隔
- 让用户用彩虹岛编辑器的"LDT文本复制"功能逐行粘贴
- 这次失败的根本原因：_Name字段填了ITEM_2的数字ID而非_Description的中文名

**失败容忍规则编码**：
1. 第一次 → 换方案重试
2. 第二次 → 停手，切manual方案，输出清单供用户手动操作
3. 不要用同一种方式再试第三次——用户会觉得浪费时间的
4. 如果新方案比旧方案"退回"了（如上版本能复制粘贴，新版反而不行），用户会立刻指出

### 7. 他乡端 vs 你端CASH_SHOP差异

他乡端（用户提供的3行参考）：
- _CategoryIndex3全部=0（你端原有时装=4）
- 发型用(1,2,5)，衣服用(1,1,4)
- 时限用(7,22,0) + EventType=1 + EventIcon=1
- _PositionIndex用99xxxx格式（独立不重叠）
- _Limited_Time_Type始终=0（即使有时限商品）

你端原版：
- 有时装CategoryIndex3=4
- _PositionIndex=900442~912007
- 时限商品的_Limited_Time_Type=2

### 8. 后续批量上架建议

每次手动添加一条测试后，若确认GS不崩：

使用gen_cashshop_list.py生成清单后，逐行用彩虹岛编辑器复制：
```bash
python C:\Users\Administrator\Temp\gen_cashshop_list.py
# 输出：~/Desktop/时装列表_逐行.txt
```

文件中有2497行，按分类排序：永久发型→永久衣服→时限类。
