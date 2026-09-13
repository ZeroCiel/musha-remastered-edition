# NPC商店系统操作指南

## 三表关系

```
NPCTRADE.LDT                    NPCTRADE_DETAIL.LDT              ITEM_3.LDT
┌────────────────────┐          ┌───────────────────┐          ┌──────────────┐
│ item_id=9101       │          │ item_id=20010001  │          │ item_id=     │
│ _BuyFactor=20      │    ──→   │ _ItemID=170140101 │    ──→   │ 170140101    │
│ _ID1=10010101      │          │ _ItemCount=1      │          │ _Name=贝罗斯 │
│ _ID2=10010401      │          │ _SellFactor=100   │          │ 传送胶囊     │
│ _ID13=20010001 ←───┼──────────┼───────────────────┤          └──────────────┘
│ ...                │          │ ...               │
│ Message = "欢迎"   │          │                   │
└────────────────────┘          └───────────────────┘

NPC.LDT (EventType=2 交易, TypeID=商店组ID)
┌──────────────────────────┐
│ item_id=1009 (爱思泰)    │
│ EventType=2, TypeID=91   │──→ NPCTRADE_LIST的分组ID
│ Text3 = "交易物品"       │       ┌────────────────────┐
└──────────────────────────┘       │ item_id=91         │
                                    │ _GroupID1=9103     │
                                    │ _GroupName1=交易   │
                                    │ 恢复药水           │
                                    └────────────────────┘
```

## 添加商品到NPC商店

### 如果NPCTRADE_DETAIL已有该道具
直接在NPCTRADE.LDT找到目标商店行，找一个空_ID槽填入DETAIL中的item_id。

例：药店9101的_ID13~50都是0，把_ID13=20010001即可。

### 如果NPCTRADE_DETAIL中没有
需要新增一行：新item_id（避开已有值）+ _ItemID（道具ID）+ _ItemRare + _ItemCount + _SellFactor

## 数量分离
同一道具不同数量在DETAIL中对应不同的item_id行：
- 10010101 → 单个药水
- 10010110 → 一组10个药水
- 10010199 → 一组99个药水
每组分别有各自的_item_id，在NPCTRADE的_ID字段里分别引用。

## 修改后不生效排查清单
1. □ pack=1需要重新打包SPF（`resource/ROWID.SPF`），pack=0直接读目录
2. □ GS是否已重启（taskkill + 重新启动）
3. □ NPCTRADE._IDx的值是否在NPCTRADE_DETAIL的item_id列存在
4. □ NPCTRADE_DETAIL._ItemID的值是否在ITEM_*.LDT中
5. □ NPC绑定是否正确（查NPC.LDT的EventType/TypeID）
