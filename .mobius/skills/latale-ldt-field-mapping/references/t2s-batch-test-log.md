# 繁转简分批测试日志 (2026-05-27)

## 结论

**"设计"两个字改了会导致GS崩溃**，疑似服务端exe有硬编码校验。其余字安全。

## 测试过程

1. 一次性改28个文件共10个词("布浓云设计当扰从灾难") → GS崩
2. 分批测试：第一批12个描述类文件，只改去掉"设计"的8个字 → GS崩
3. 去掉"设计"二字后 → GS正常启动 ✅

## 测试批次定义

**第一批（描述文本类，安全）**：ACHIEVE.LDT, ACTION_INTERFACE.LDT, COLLECT_MOB.LDT, GIFT_INFO.LDT, ITEM_2.LDT, ITEM_3.LDT, NPCTALK.LDT, QUEST_1.LDT, QUEST_2.LDT, QUEST_INFO_1.LDT, QUEST_INFO_2.LDT, SAVEPOINT.LDT

**第二批（特效/技能类，中等）**：EFFECT.LDT, FX_GROUP.LDT, FX_UNIT.LDT, FX_UNIT_ROBOT.LDT, PVP_EFFECT.LDT, PVP_SKILL_USE.LDT, SKILL_USE.LDT

**第三批（数据表类，高风险）**：ITEM_ENCHANT.LDT, ITEM_UPGRADE.LDT, ITEM_UPGRADE_P.LDT, GAMBLE_REWARD.LDT, MAPEVENT.LDT, NPC_EVENT.LDT, NPC_EVENT_DETAIL.LDT, CP_EVENT_MISSION.LDT, QUEST.LDT

## 测试命令（二进制等长替换）

```python
trad2simp_gbk = {
    '佈': '布', '濃': '浓', '雲': '云',
    '當': '当', '擾': '扰', '從': '从', '災': '灾', '難': '难',
}
pairs = [(t.encode('gbk'), s.encode('gbk')) for t, s in trad2simp_gbk.items()]
# bytearray.find + replace
```
