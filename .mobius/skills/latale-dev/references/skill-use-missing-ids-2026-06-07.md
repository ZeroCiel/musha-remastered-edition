# SKILL_USE 引用但 SKILL.xls 缺失的 ID

## 背景
GS 启动时报：
```
Skill Information Loading.........DATA/LDT/SKILL_USE.LDT : FAILED !
Not Exist in Skill.LDT (iKey = XXXXXX)
```

这是因为 SKILL_USE.LDT 引用了某个 SkillID，但 SKILL.LDT（从 SKILL.xls 写入）中不存在该 ID 定义。

## 批量扫描方法
1. 从 SKILL_USE.xls 提取第2列（_SkillID）的所有非零值
2. 从 SKILL.xls 提取所有 ID
3. 差集 = SKILL_USE 引用但 SKILL 缺少的

## S4端补入记录（2026-06-07）
一次性补入 **71个缺失ID**，全部在 SKILL2.xls 中找到。

### 插入方式
按 ID 排序，从后往前插入到 SKILL.xls 的 `\n` 分隔行列表中，避免索引偏移。

### SKILL2.xls 行数据注意
SKILL2.xls 的某些行末尾可能多一个 `\t`（空列），而当前 SKILL.xls 的对齐列数可能不同。插入时直接插入整行字节数据，不要 strip 或调整列数。

### 后续增量补入（GS报一个补一个）
| 日期 | ID | 说明 |
|------|----|------|
| 2026-06-07 | 8003213 | 超级玛璃第七关奖励技能（名未定） |
| 2026-06-07 | 1109605 | 补充插入 |

## 验证
补完后重新扫描，确保 SKILL_USE 引用的所有 ID 都在 SKILL.xls 中。
