# ITEM_1/2/3 LDT 字段分析 (2026-05-27)

> ⚠️ **注意：此文件部分内容已被推翻**。详见 `item-2-name-field-truth-verified.md`。
> **ITEM_2 的 `_Name` 字段就是中文商品名**（如"活动黑色短裤"），不是数字ID引用。
> 此文件中关于 `_Name` 为数字ID的结论已在 2026-05-28 通过验证被推翻。

## 基本结构

三个ITEM文件**完全相同**的列结构：125列，完全同构。

| 文件名 | 行数 |
|--------|------|
| ITEM_1.LDT | 14,682 |
| ITEM_2.LDT | 9,582 |
| ITEM_3.LDT | 14,451 |

## 关键发现

### _Name 和 _Description 的关系（ITEM_2关键发现）

**重要**！ITEM_2（时装/道具表）中：
- **`_Name` 字段被观察到显示数字ID引用**（如"4","6","17"），而不是中文文本
- **真正的中文名在 `_Description`**
- 其他表（NPCTALK等）正常，_Name就是中文

验证：2497件时装中，_Name为中文的0件，为数字的2497件。

详见 `references/item-2-name-field-truth.md`。

### Cash系列字段

3个文件都有完全相同的现金相关字段：

| 索引 | 字段名 | 类型 | 说明 |
|------|--------|------|------|
| 8 | `_GamePrice` | int | 游戏币价格 |
| 9 | `_CashPrice` | int | 点券价格 |
| 10 | `_CashCheck` | bool | 布尔开关，0=不可购买/未上架, non-0=可购买 |
| 109 | `_CashPoint` | int | 红利点券价 |

### _CashCheck 真实含义（更正）

**结论：`_CashCheck` 是 type=2 (bool) 字段。**
LDT的bool类型在二进制里是uint32存储（0=false, non-0=true）。ITEM_2中看到的值如1600、2100、55000等都是"true"。所以：
- `_CashCheck=0` = 不可购买/未上架
- `_CashCheck≠0` = 可购买/已上架

**之前的理解有误：** 之前以为_CashCheck是int类型的具体数值（限购量、VIP权限等），但经过重新确认type定义和各值分布，它只是bool。

### _CashCheck 值分布（ITEM_2.LDT）

- 0: 7,054行（绝大多数未上架）
- non-0: ~2,500行（已上架的，值从100到55000不等，值本身无含义）

## ITEM_2 时装分类

ITEM_2是时装/外观道具主表（9582行）。

### 关键分类字段

| 字段 | 索引 | 含义 |
|------|------|------|
| `_Type` | 13 | 物品大类(1=装备, 2=消耗品, 4=材料, 5=宠物) |
| `_SubType` | 14 | 子类(时装1ST=1普通装备, ST=2时装外观) |
| `_PosID1` | 15 | 装备位置(3=发型, 4=衣服, 5=裤子, 11=翅膀...) |
| `_Category` | 0 | 物品分类编码（混合ID，不是简单分类号） |
| `_Num` | 1 | 编号/子分类 |
| `_Icon` | 6 | 图标文件ID(对应BANX.SPF的GLOBALRES/XXXX.PNG) |
| `_IconIndex` | 7 | 图标格子索引 |
| `_RareLimit` | 12 | 稀有度限制 |
| `_Time_Type` | 87 | 时限类型(0=永久, 1=限时) |
| `_Lifetime` | 88 | 时限时间(168=7天, 720=30天) |

### 时装判别规则

时装 = `_Type=1 && _SubType=2`

ITEM_2中T=1,ST=2共**1518行**，全部_CashCheck=0且_CashPrice=0（未上架商城）。

按_PosID1细分：
- 3 = 发型（头发、发带等）
- 4 = 衣服（上衣、连衣裙等）
- 5 = 裤子/裙子（短裤、长裤等）
- 6 = 手套/手臂
- 7 = 鞋/靴子
- 1 = 头饰（帽子、发夹等）
- 11 = 翅膀/披风/背部装饰

### _Type/_SubType 分布（ITEM_2）

| Type | SubType | 行数 | 说明 |
|------|---------|------|------|
| 1 | 1 | 7,866 | 普通装备(武器/防具/饰品) |
| 1 | 2 | 1,518 | **时装/外观** |
| 5 | 1 | 169 | 宠物 |
| 4 | 1 | 17 | 材料 |
| 2 | 1 | 12 | 消耗品 |

## CASH_SHOP.LDT（商城表）

### 字段

CASH_SHOP是商城商品定义表，1492行，64列。

| 索引 | 字段 | 类型 | 说明 |
|------|------|------|------|
| 0 | `_CategoryView` | bool | 是否在商城显示 |
| 1 | `_CategoryIndex` | int | 大分类(1=时装, 3=装备, 6=功能, 7=活动) |
| 2 | `_CategoryIndex2` | int | 子分类(1=热门, 2=武器, 3=发型, 6=翅膀, 7=活动) |
| 3 | `_CategoryIndex3` | int | 细分类(1=男装, 2=女装, 4=披风, 7=武器, 9=发型, 14=翅膀) |
| 4 | `_PositionIndex` | int | 排序位置 |
| 5 | `_Name` | string | 商城显示名 |
| 6 | `_Description` | string | 描述 |
| 7 | `_IconFile` | int | 图标文件ID |
| 8 | `_IconIndex` | int | 图标格子索引 |
| 9 | `_Gender` | int | 性别(0=通用) |
| 10 | `_PriceType` | int | 价格类型(1=点券) |
| 11 | `_CashPrice` | int | 点券价格 |
| 12 | `_SalePrice` | int | 折扣价 |
| 13 | `_EventIcon` | int | 活动标签 |
| 14~21 | `_ItemID1~8` | int | 道具ID(最多8个捆绑) |
| 22~29 | `_ItemRare1~8` | int | 稀有度 |
| 30~37 | `_ItemCount1~8` | int | 数量 |
| 38~45 | `_PriceRate1~8` | int | 价格倍率 |
| 46 | `_MotionID` | int | 预览动作 |
| 47 | `_ClassID` | int | 职业限制 |
| 48~55 | `_Require1~3` | int | 购买条件 |
| 56 | `_Buy_Disable` | bool | 禁止购买 |
| 57 | `_Give_Disable` | bool | 禁止赠送 |
| 58 | `_Limited_Time_Type` | int | 限时类型 |

### 分类索引对照

| (CatIdx1,2,3) | 说明 | 条目数 |
|---------------|------|--------|
| (1,1,1) | 时装/热门/男装 | 388 |
| (1,1,2) | 时装/热门/女装 | 158 |
| (1,1,3) | 时装/热门/武器 | 157 |
| (1,6,14) | 时装/翅膀/翅膀 | 144 |
| (1,1,4) | 时装/热门/披风 | 63 |
| (1,3,9) | 时装/发型/女发 | 53 |
| (1,3,11) | 时装/发型/男发 | 36 |
| (1,2,7) | 时装/武器/武器 | 35 |

### 条目示例

```
_RowId=133
_CategoryView: 1
_CategoryIndex: 1
_CategoryIndex2: 1
_CategoryIndex3: 4
_PositionIndex: 900442
_Name: "忍者大师红色披风"
_IconFile: 10001201
_IconIndex: 230
_PriceType: 1
_CashPrice: 30
_ItemID1: 40190401
_ItemRare1: 1
_ItemCount1: 1
_PriceRate1: 1
_Buy_Disable: 1
_Give_Disable: 1
```

### 商城上架流程

要让时装上架商城，需要在CASH_SHOP.LDT中**新增行**：
1. 设置_CategoryView=1, _CategoryIndex/CategoryIndex2/CategoryIndex3为对应分类
2. _Name填显示名称
3. _CashPrice设定价（衣服类240点券，发型类400点券为标准参考价）
4. _ItemID1填ITEM_2中的道具ID
5. _ItemRare1=1, _ItemCount1=1, _PriceRate1=1
6. _Buy_Disable=1, _Give_Disable=1（启用购买和赠送）
7. 同时在ITEM_2中设置该道具的_CashCheck=1
