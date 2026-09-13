# NPC商店（NPCTRADE）系统 — S4端

NPC交易系统允许玩家通过NPC购买道具（用游戏币/金币，不是点券）。

## 数据链路

```
NPC.xls                 NPCTRADE_LIST.xls      NPCTRADE.xls          NPCTRADE_DETAIL.xls
┌──────────────┐       ┌────────────────┐      ┌───────────────┐      ┌─────────────────┐
│ EventType=4  │──────→│ ID             │      │ ID(=GroupID)  │      │ ID              │
│ TypeID=LIST_ID│      │ GroupID1=TRADE_ID│────→│ _ID1~50=ItemID│      │ _ItemID         │
│              │       │ GroupName1=分类名│      │ BuyFactor     │      │ _SellFactor(价格)│
└──────────────┘       └────────────────┘      └───────────────┘      └─────────────────┘
```

- **NPC.xls**: `EventType` = 4（交易），`TypeID` = NPCTRADE_LIST的ID（如91）
- **NPCTRADE_LIST.xls**: 交易分类，每个LIST最多20组交易（GroupID1~20 + GroupName1~20）
- **NPCTRADE.xls**: 实际商店，_ID1~_ID50填ItemID（道具编号，50个slot），BuyFactor控制价格倍率
- **NPCTRADE_DETAIL.xls**: 道具定价（ItemID + ItemRare + ItemCount + SellFactor）

## 文件位置

`D:\LaTale\S4\resource\ROWID\DATA\XLS\NPCTRADE*.xls`

## NPCTRADE.xls 结构

| 列 | 字段 | 类型 | 说明 |
|----|------|------|------|
| 0 | _ID | int | 商店ID，被LIST的GroupID引用 |
| 1 | _BuyFactor | int | 价格倍率，0=正常 |
| 2~51 | _ID1~_ID50 | int | 商品ItemID，50个slot |
| 52 | CutInImage | int | 界面图片，0=无 |
| 53 | Message | string | 商店说明文字，可空 |

共54列。多余的slot填0。

## NPCTRADE_LIST.xls 结构

| 列 | 字段 | 说明 |
|----|------|------|
| 0 | _ID | LIST ID，被NPC EventType=4引用 |
| 1~3 | _GroupID1 + _GroupName1 | 第一组交易（GroupID=TRADE.xls的ID，Name=玩家看到的Tab名） |
| 4~6 | _GroupID2 + _GroupName2 | 第二组... |
| ... | ... | 最多20组 |

每组2列（GroupID + GroupName），共41列（ID + 20×2）。

## NPCTRADE_DETAIL.xls 结构

| 列 | 字段 | 说明 |
|----|------|------|
| 0 | _ID | 自增 |
| 1 | _ItemID | 道具编号 |
| 2 | _ItemRare | 稀有度（通常1） |
| 3 | _ItemCount | 数量（通常1） |
| 4 | _SellFactor | 价格（金币） |

Lv1~Lv4通用定价：100 / 150 / 200 / 250

## 上架新商品步骤

### 1. NPCTRADE_DETAIL.xls — 定价

给每个ItemID加定价行。格式：
```
_id\titem_id\t1\t1\tprice
```

例（精灵石）：
```
783310102	160100101	1	1	100
783310103	160100102	1	1	150
783310104	160100103	1	1	200
783310105	160100104	1	1	250
```

### 2. NPCTRADE.xls — 建商店

新建一行，ID取当前最大+1，_ID1~_ID50填ItemID：
```
new_id\t0\titem1\titem2\t...\titem50\t0\t
```
53个\t分隔，BuyFactor=0，空白Message。

### 3. NPCTRADE_LIST.xls — 建分类

新建一条LIST，GroupID1=上面的TRADE ID，GroupName1=分类名：
```
new_list_id\tnew_trade_id\t分类名\t0\t\t0\t\t...\t0\t
```

### 4. NPC.xls — 绑定到NPC

找到目标NPC行，在空白EventType槽位加：
```
4\tnew_list_id\t显示文字
```

EventType=4表示交易，TypeID=LIST ID。
NPC一共有6组EventType槽位（每组3列：EventType+TypeID+Text）。
如果NPC已有EventType=4，可以新增一个槽位指向新的LIST。

## 精灵石上架示例

2026-06-07 实测：160100101~160101604（16属性×4等级=64个道具）。

脚本生成：
```python
prices = {'01': 100, '02': 150, '03': 200, '04': 250}
for prop in range(1, 17):
    for suffix in ['01', '02', '03', '04']:
        item_id = f'160100{prop}{suffix}'
        price = prices[suffix]
        # DETAIL行
        detail_id += 1
        # TRADE 50个slot
        items.append(item_id)
```

结果：
- DETAIL: 64行定价
- TRADE ID=7890105（64个精灵石填满50slot）
- LIST ID=6015304（"精灵石交易"）
- NPC绑定：在NPC.xls加EventType=4 → TypeID=6015304

## 注意

- 必须先加DETAIL定价，否则GS加载时报错
- TRADE的50个slot中多余的必须填0（不能缺列）
- LIST的GroupID必须指向TRADE的ID
- NPC的EventType=4的TypeID必须指向LIST的ID
- 格斗场NPC通常没有EventType=4，不需要加
- 备份4个文件后再操作（cp *.xls bak/）
- 改完后重启GS生效
