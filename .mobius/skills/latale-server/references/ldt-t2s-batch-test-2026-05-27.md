# LDT 繁简转换 — 分批测试验证记录 (2026-05-27)

## 背景

彩虹岛私服（D:\彩虹岛单机\）LDT文本繁转简，分批测试哪些文件安全可改。

## 关键发现

### 编码确认

- **原始繁体LDT是GBK编码**（不是Big5）
  - 字符串区91.4% GBK有效 vs 87.8% Big5有效
  - 所有常见繁体字（從雲當災難設計佈濃擾麗國狀態等）在GBK下都有对应编码
  - 每个繁→简对在GBK下都是**等长2字节**，不会改变文件结构

### 二进制替换有效

- 直接字节替换（不经过LDT解析器）的等长繁简转换**不会破坏文件结构**
- 字符串长度头健康、数据完整性通过

### 分批测试结果

| 批次 | 文件范围 | 结果 |
|------|---------|------|
| 第1批(描述类) | ACHIEVE/ACTION_INTERFACE/COLLECT_MOB/GIFT_INFO/ITEM_2/ITEM_3/NPCTALK/QUEST_1~2/QUEST_INFO_1~2/SAVEPOINT | ✅ 能启动 |
| 第2批(特效技能类) | EFFECT/FX_GROUP/FX_UNIT/FX_UNIT_ROBOT/PVP_EFFECT/PVP_SKILL_USE/SKILL_USE | ❌ 时尚商店"关闭中" |
| 任务文件全量 | QUEST_1/2/3/INFO_1/2/3/LIST/DROP_ITEM (18259处) | ❌ GS崩 |

### 问题推测

不是编码或长度问题——所有繁简转换对都是等长2字节替换。exe可能有：
1. SPF包格式校验（他乡包防篡改机制）
2. 特定LDT文件的CRC/哈希校验
3. 某些关键字段的格式约束（非文本字段被修改）

### 文件安全分类（待验证）

| 安全级别 | 文件 | 说明 |
|---------|------|------|
| ✅ 安全 | ACHIEVE, ACTION_INTERFACE, COLLECT_MOB, GIFT_INFO, ITEM_2, ITEM_3, NPCTALK, QUEST_1/2, QUEST_INFO_1/2, SAVEPOINT | 纯文本描述，第1批已验证 |
| ⚠️ 可疑 | EFFECT, FX_*, PVP_EFFECT, PVP_SKILL_USE, SKILL_USE | 改后时尚商店异常 |
| ❌ 高危 | 所有QUEST文件 (全量18259处) | 直接导致GS崩 |
| ❌ 高危 | "设计"二字 (設/計) | 疑似导致GS崩 |

### 后续策略

1. **每次只改一小批指定词**（如8个字：佈濃雲當擾從災難）
2. 用户打包→验证→确认→下一批
3. 优先改纯文本描述类文件，跳过特效/技能/数据表类
4. 保留原始版SPF备份 (ROWID_v0.SPF)
