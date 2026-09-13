# 彩虹岛 NPCTRADE 商店系统（经验参考）

## 基础链路（核心！）

```
NPC.EventType=4.TypeID → LIST.ID（对话选项注册）
  LIST.GroupID → TRADE.ID（商店种类）
    TRADE._ID1~_ID50 → ItemID（道具ID！不是DETAIL._ID！）
      GS自动匹配NPCTRADE_DETAIL中ItemID=该道具ID的行 → 取定价
```

## ⚠️ 大坑汇总

### 坑A：TRADE._ID1~_ID50 填ItemID，不是DETAIL._ID
GS内部通过ItemID自动匹配DETAIL中同ItemID的行获取定价。DETAIL的_ID是编辑器用的自增主键。

### 坑B：DETAIL新增行_ID不要离太远
新增DETAIL行的_ID如果离已有行太远，编辑器会无法识别。

### 坑C：ItemID字符串排序陷阱
属性编号作为字符串排序会乱！1601001001（属性10）会被排到160100101（属性1）前面。

```python
sorted(items, key=lambda x: int(x[7:-2]))  # 正确
```

### 坑D：用户手动调整DETAIL_ID后，TRADE里的引用也要同步改

### 坑E：LIST第一行ID（NPC类型相关ID）不能随便写

## 各文件详解

### NPCTRADE_DETAIL.xls — 商品定价注册
| 列 | 字段 | 说明 |
|----|------|------|
| 0 | _ID | 自增主键（编辑器用，GS不直接引用） |
| 1 | _ItemID | 道具ID（GS匹配此列与TRADE的ItemID） |
| 2 | _ItemRare | 固定1 |
| 3 | _ItemCount | 固定1 |
| 4 | _SellFactor | 价格（Lv1=100, Lv2=150, Lv3=200, Lv4=250） |

格式：制表符分隔GBK文本。Type行 + Header行 + 数据行。

### NPCTRADE_LIST.xls — NPC对话选项注册
| 列 | 说明 |
|----|------|
| 0 | LIST_ID（NPC.EventType=4.TypeID引用此值） |
| 1~2 | GroupID1 + GroupName1（第1个Tab页） |
| 3~4 | GroupID2 + GroupName2 |
| ... | 最多20组 |

- GroupID = TRADE.ID（种类ID）
- GroupName = 玩家Tab页显示名

### NPCTRADE.xls — 商店商品列表
**54列**：col0=_ID(TRADE_ID), col1=_BuyFactor, col2~51=_ID1~_ID50(ItemID), col52=CutInImage, col53=Message

## 精灵石上架流程

1. ITEM_1.xls 确认道具存在
2. NPCTRADE_DETAIL.xls 加定价（ItemID）
3. NPCTRADE.xls 新建种类行（**填ItemID，不是DETAIL._ID！**）
4. NPCTRADE_LIST.xls 新建分类（GroupID→TRADE_ID）
5. NPC.xls 给NPC加EventType=4.TypeID=新LIST_ID
6. 跑GS测试
