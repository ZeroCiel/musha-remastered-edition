# EFFECT.LDT 字段结构

## 文件信息

- 路径: `D:\彩虹岛\resource\ROWID\DATA\LDT\EFFECT.LDT`
- 列数: 70
- 所有列类型: type=0 (string) — 变长字段，`\x00` 分隔
- 数据区偏移: 4772 (= 12 + 70*64 + 70*4)
- 行结构: 每行以 `\x00\x00` 序列分隔

## 字段列表

| 索引 | 字段名 | 说明 |
|------|--------|------|
| 0 | _Name | 效果名（控制字符+名称混合存放） |
| 1 | _Description | 效果描述（如 "经验值获得 200% (60分钟)"） |
| 2 | _Attack_Type | |
| 3 | _BuffID | BUFF ID（数值） |
| 4 | _BuffLv | BUFF等级 |
| 5~10 | _Buff_Icon / _Buff_IconIndex 等 | 图标/资源引用 |
| 11 | _Buff_Name | BUFF显示名称（如"爱丽丝的祝福"） |
| 12 | _Buff_Description | BUFF详细描述（如"经验值获得 200%， 任务奖励UP！ 50%"） |
| 13 | _EffectType | 效果类型 |
| 14~25 | _Require1/2_* | 触发条件 |
| 26~29 | _Apply_* | 应用概率/时间 |
| 47 | _StatusEffect | 状态效果类型 |
| 48 | _StatusEffectType | 状态效果子类型 |
| 49~57 | _EffectParameter1~9 | 效果参数 |
| 60 | _EffectValueType | **效果数值类型（改百分比的关键列）** |
| 61~62 | _SaveCheck / _Broadcast | 保存/广播 |
| 66 | _BuffGroup_Check | BUFF组检查 |
| 67 | _Log | 日志 |

## 关键字段说明

### _BuffID（col3）vs RowId
- **RowId** = EFFECT.LDT的行ID（就是二进制行号）
- **BuffID** = 字段3的值，作为外键被其他LDT引用
- **注意**：还有一个EffectID/效果引用ID（如63000912）也出现在某些行的field[0]中
- 三者完全独立！**不要混淆**

**重要：BuffID跨表复用模式（2026-05-30发现）**
EFFECT的BuffID（如7600=爱丽丝的祝福）可能同时出现在多个完全不同的系统中：
- FLAG_INFO.LDT — 作为FlagID（NPC对话/任务触发标记，如"与惠宗对话"）
- ITEM_ENCHANT.LDT — 作为强化属性ID
- QUEST_REWARD.LDT — 作为奖励ID
- PVP_EFFECT.LDT — 作为PVP效果ID

这意味着：**同一个数值在不同LDT表中含义完全不同**。不能因为数值相同就认为指向同一事物。通过文件路径+上下文区分。

### 爱丽丝BUFF结构示例（2026-05-30更新）

Row 19384（效果描述行）：
```
field[0] = 编码ID（含63000912作为EffectID引用）
field[1] = (爱丽丝增益效果) 经验值获得 200% (60分钟)
```

Row 19388（BUFF自身行）：
```
field[0] = \\x0c（控制字节）
field[1] = 爱丽丝的祝福\"（显示名）
field[2] = 经验值获得 200%， 任务奖励UP！ 50%\\x02（详细效果描述）
```

**爱丽丝的祝福关键映射**：
- EffectID（功能引用ID）= 63000912
- BuffID（EFFECT行内ID）= 7600
- _Name显示名 = "爱丽丝的祝福"（直接存GBK，不在GLOBAL_STRING）
- _EffectValueType = 200（百分比）
- ITEM_3中ItemID=190180612 = "燃烧标记"（无关，只是数值相近巧合）

### _EffectValueType（col60）
- 存储百分比数值，如200=200%，100=100%
- **之前改过爱丽丝祝福：200→100**

### 爱丽丝BUFF结构示例

Row 19384（效果描述行）：
```
field[0] = 编码ID（含63000912作为BuffID引用）
field[1] = (爱丽丝增益效果) 经验值获得 200% (60分钟)
```

Row 19388（BUFF自身行）：
```
field[0] = \x0c（控制字节）
field[1] = 爱丽丝的祝福"（显示名）
field[2] = 经验值获得 200%， 任务奖励UP！ 50%\x02（详细效果描述）
```

## 二进制编辑注意事项

- 所有列type=0（string），变长结构
- **⚠️ 高危：不等长修改导致GS闪退**：EFFECT用变长`\x00`分隔，不保持等长修改会破坏行边界 → GS在 `GlobalSys::Init()` 后直接闪退（日志不写任何ERROR/FAILED）。唯一表现就是启动到GlobalSys就消失。
- 安全改法：**保持字符串等长**。如"200%"(4B)→"20% "(4B，尾部补空格)
- 如果不等长（如改名字），必须用彩虹岛编辑器操作
- 行边界 = `\x00\x00\x00` 连续3个00
- 数据区偏移 = 4772（12 + 70*64 + 70*4）

**快速诊断GS闪退是否由EFFECT引起**：
1. 检查日志：`grep "GlobalSys\|FAILED\|ERROR"` — 如果停在了 `GlobalSys::Init() : [OK]` 后无后续，可能是EFFECT等全string表被破坏
2. 恢复EFFECT.LDT备份 → 重启GS验证
3. 如果恢复后正常 → 确认是EFFECT修改问题

**打包后文字来源混淆**：修改LDT文件后如果GS读的是SPF包（pack=1），而全盘搜索搜的是目录文件，两边可能不一致。搜索时也要搜 `.SPF` 文件。

**其他系统的字符串存储**：
- BUFF显示名：直接存在EFFECT.LDT的`_Buff_Name`字段（GBK编码），不在GLOBAL_STRING
- NPC对话文本：存在NPCTALK.LDT
- 系统提示信息：部分在GLOBAL_STRING.LDT
- 活动/任务文本：散落在QUEST_INFO、FLAG_INFO等表中

## 快速定位行

```python
# 按名称搜索（GBK编码）
kw = '爱丽丝'.encode('gbk')
idx = data.find(kw)
# 往前找行边界
start = idx
while start > data_off and not (data[start] == 0 and data[start-1] == 0):
    start -= 1
# 往后找行结束
end = start
while end < len(data) and not (data[end] == 0 and data[end+1] == 0 and data[end+2] == 0):
    end += 1
row = data[start:end]
fields = row.split(b'\x00')
```
