# 2026-05-27: 商城时装上架分析

## 问题
将ITEM_2中所有**时装类道具**添加到CASH_SHOP.LDT商城，让玩家可以点券购买。

## ITEM_2 时装分类分析

### 字段结构
| 字段 | 类型 | 说明 |
|------|------|------|
| _Type=1 | int | 装备大类 |
| _SubType=1 | int | 普通装备/时装装备（混在一起，需靠PosID区分） |
| _SubType=2 | int | **发型专属时装**（1518件，全部PosID=3） |
| _PosID1 | int | 装备位置(1=头饰 3=发型 4=衣服 5=裤子 6=手套 7=鞋 11=翅膀) |
| _Name | string | **中文名称**（之前解析bug显示为数字，实际是中文） |
| _CashCheck | bool | 0=未上架 1=上架 |
| _CashPrice | int | 点券价格（时装全部为0，需要设定） |
| _SubPosID11/12 | int | 子装备位（如衣服同时占裤子+手套位） |

### 时装判定规则
- **T=1, ST=2** = 发型（全1518件，PosID=3，全部_CashPrice=0）
- **T=1, ST=1** 中PosID为3-11的 = 其他时装装备（衣服/裤/鞋/手套/披风/翅膀）
- 特征：名字含"衣""裤""鞋""手""帽""披风""翅膀""发""尾"等
- 排除：名字含"翅膀"（用户说不要翅膀类）、含"+1""+2""+3"（强化版）

### 关键发现
_NAME列在第一次标准解析时显示中文（"链子短裤（男）"等），但后续代码写错导致读成数字。
_CashCheck对时装类全为0（未上架），_CashPrice全为0（无定价）。

## CASH_SHOP.LDT 字段分析

| 索引 | 字段 | 类型 | 说明 |
|------|------|------|------|
| 0 | _CategoryView | bool | 1=可见 |
| 1 | _CategoryIndex | int | 商城大分类 |
| 2 | _CategoryIndex2 | int | 子分类 |
| 3 | _CategoryIndex3 | int | 细分类 |
| 4 | _PositionIndex | int | 排序位置 |
| 5 | _EventType | int | 活动类型 |
| 6 | _Name | string | 商城显示名称 |
| 7 | _Description | string | 描述 |
| 8 | _IconFile | int | 图标文件ID |
| 9 | _IconIndex | int | 图标索引 |
| 10 | _Gender | int | 性别限制 |
| 11 | _PriceType | int | 1=点券 |
| 12 | _CashPrice | int | 价格（时装240/发型400） |
| 13 | _SalePrice | int | 折扣价 |
| 14 | _EventIcon | int | 活动图标 |
| 15 | _ItemID1 | int | 道具ID（ITEM表_RowId） |
| 16 | _ItemRare1 | int | 稀有度（常用1） |
| 17 | _ItemCount1 | int | 数量（常用1） |
| 18-26 | _ItemID2-8 + Rares + Counts | int | 多道具捆绑 |
| 47 | _MotionID | int | 动作ID |
| 48 | _ClassID | int | 职业限制 |
| 49-60 | _Require1-3 | int | 购买条件 |
| 61 | _Buy_Disable | bool | 必须=1 |
| 62 | _Give_Disable | bool | 必须=1 |
| 63 | _Limited_Time_Type | int | 限时类型 |

### 已有数据特征
- 分类层次：(CategoryIndex1, CategoryIndex2, CategoryIndex3)三元组
- 价格：大部分30点券（已有的老商品）
- _Buy_Disable=1, _Give_Disable=1 所有商品
- _PriceType=1（点券支付）
- _PositionIndex 决定显示顺序（大数值=靠后）

## 上架方案（计划中）
1. 从ITEM_2提取所有PosID=4/5/6/7/8/11的时装装备 + 全部T=1,ST=2的发型
2. 排除名字含"翅膀"的
3. 按装备位定价：衣服/裤/鞋/手=240，发型=400
4. 写入CASH_SHOP.LDT，生成新的_RowId和_PositionIndex
5. 同时将ITEM_2的_CashCheck设为1，_CashPrice设为对应价格
