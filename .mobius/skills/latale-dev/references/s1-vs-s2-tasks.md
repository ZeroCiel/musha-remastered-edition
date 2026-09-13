# S1 任务系统分析（与S2对比）

> 更新时间：2026-05-30

## 文件结构对比（S2开发目的）

| 维度 | S1 | S2（他乡端） |
|------|-----|-----------|
| 任务主表 | `QUEST.LDT` (126列×2873行) 一张表全包 | 拆成 `QUEST_INFO_1` (29列) + `QUEST_1` (108列) |
| 奖励表 | `QUEST_REWARD.LDT` (33列×3028行) | `QUEST_REWARD_1.LDT` (33列×1153行) |
| 关联方式 | 行号对应，但QUEST行数≠REWARD行数（2873 vs 3028），多个REWARD行可能对应一个QUEST | _Quest_Next链式关联，BaseLV+地点+后继 |
| 任务名 | QUEST.LDT的_Name列（int32索引ID，同ITEM） | 同上，_Name也是索引ID |
| 任务文本 | QUEST.LDT尾部embed的string表（623KB） | QUEST_INFO_1的对话/描述列 |
| 地点/NPC | QUEST.LDT中列103~108 `_Place_Info1/2` `_NPC_Info1/2` | QUEST_INFO_1的col3/col4 |
| BaseLV | QUEST.LDT中列122 `_Quest_BaseLV`（type=3混合型） | QUEST_INFO_1的col20 |
| 任务条件 | QUEST.LDT中 `_Require1~4_Type/ID/Value`（列1~16） | S2无此字段（任务条件在其他表） |

## QUEST_REWARD 列结构（S1和S2一致）

33列，全int32：
```
[0] _Reward_EXP         [1] _Reward_Ely         [2] _Reward_Fame
[3] _Reward_EffectID1   [4] _Reward_EffectID2    [5] _Reward_EffectID3
[6] _Reward_EffectID4   [7] _Reward_ItemID1     [8] _Reward_StackCount1
[9] _Reward_Rare1       [10] _Reward_ItemID2    [11] _Reward_StackCount2
[12] _Reward_Rare2      [13] _Reward_ItemID3    [14] _Reward_StackCount3
[15] _Reward_Rare3      [16] _Reward_ItemID4    [17] _Reward_StackCount4
[18] _Reward_Rare4      [19] _Reward_ItemID5    [20] _Reward_StackCount5
[21] _Reward_Rare5      [22] _Reward_ItemID6    [23] _Reward_StackCount6
[24] _Reward_Rare6      [25] _Reward_Gpoint
[26] _Area_Reputation1  [27] _Reputation1        [28] _Area_Reputation2
[29] _Reputation2       [30] _Area_Reputation3   [31] _Reputation3
[32] _Reputation_Open
```

## S1 vs S2 任务经验和奖励对比

### 总览
| 指标 | S1 | S2 |
|------|-----|------|
| 总行数 | 3028 | 1153 |
| 非零EXP行 | 882 (29%) | 166 (14%) |
| 总经验 | 385亿 | 351亿 |
| 平均（非零） | 4368万 | 2.12亿 |
| 中位数（非零） | **1** | **1000万** |
| 20亿经验任务 | **0** | **12** |

**关键结论：S1任务经验和奖励普遍远低于S2。**

### 量级分布对比
| 量级 | S1 数量 | S1 合计 | S2 数量 | S2 合计 |
|------|---------|---------|---------|---------|
| 1~1000 | 606 (69%) | 4,041 | 64 (39%) | 0 |
| 1000~1万 | 10 | 36,790 | 4 | 6,000 |
| 1万~10万 | 30 | 902,800 | 3 | 98,680 |
| 10万~100万 | 14 | 381万 | 5 | 81.3万 |
| 100万~1000万 | 21 | 1.02亿 | 5 | 1000万 |
| 1000万~1亿 | 95 | 34.5亿 | 21 | 3.89亿 |
| 1亿~10亿 | 101 | 254亿 | 51 | 94.9亿 |
| 10亿+ | 5 | 95.3亿 | 13 | 253亿 |

**S1的特征：**
- 69%的非零EXP任务是1~1000经验的"零碎任务"（引导/对话/跑腿）
- 大部分经验来自101个"1亿~10亿"任务（254亿，占总66%）
- **没有20亿的"溢出"任务**
- 总经验385亿，比S2的351亿略高，但S2有12个20亿任务在注水
- **排除20亿后，S2的平均经验反而低于S1的平均（排除零碎1~1000后）**

### BaseLV分布
S1的`_Quest_BaseLV`列（type=3混合类型）大部分是乱码（占2730/2873行），只有约113行有正常1~200的BaseLV。正常BaseLV的任务中：
- BaseLV=1: 41个
- BaseLV=2: 7个
- BaseLV=3: 11个
- BaseLV=0: 1123个（可能等同于1级可接）

### 对接建议（面向S2开发）

1. **S1数据不能直接套用到S2**：表结构不同，行数不对应
2. **QUEST_REWARD的33列格式可以复用**：字段名和类型一致
3. **S1的奖励设计思路可以作为参考**：S1经验曲线平缓，没有20亿溢出值，中位数只有1（大部分是跑腿/对话任务）
4. **S2的问题在于20亿模板行未清理** + 正常任务（前22行之外）大部分EXP=0
