# 彩虹岛怪物名修改指南

## 核心文件

| 文件 | 用途 | 修改方式 |
|------|------|---------|
| `GLOBAL_MOB.LDT` | 怪物名称和描述（主表） | 彩虹岛编辑器 → Name列改中文 |
| `MOBBASE.LDT` | 怪物属性/参数 | 一般不改名 |
| `MAPEVENT.LDT` | 地图事件涉及怪物名 | 看情况 |
| `NPCTALK.LDT` | NPC对话提到怪物名 | 繁转简时覆盖 |
| `QUEST_*.LDT` | 任务文本含怪物名 | 繁转简时覆盖 |

## 场景：耶比妹妹→龙猫

"耶比妹妹"是怪物名+道具名+技能名+任务名四处出现的名称。
如果只要改**怪物显示名**：改 `GLOBAL_MOB.LDT` 的 _Name 列即可。
如果要**全端统一**：需要改 `GLOBAL_MOB + ITEM_2 + SKILL_TXT + QUEST + 任务相关` 所有出现"耶比"的文件。

**注意**：耶比在超多文件中出现（道具、技能、任务、成就、签到活动、商城、赌场等）。只改GLOBAL_MOB的话，任务描述、道具描述、技能描述里还会显示"耶比妹妹"。

## 二进制查找方法

```python
kw = '耶比'.encode('gbk')
with open('GLOBAL_MOB.LDT', 'rb') as f:
    data = f.read()
idx = data.find(kw)
# idx 是文件名在文件中的字节偏移
```

## NPC位置查找

"宝拉"在 NPC.LDT 中定义为活动NPC（Event类型），对话含"Event!是任务～"，通常在艾利亚斯区域。
