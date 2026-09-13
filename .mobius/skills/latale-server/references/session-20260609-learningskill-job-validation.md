# 2026-06-09 LEARN_SKILL职业限制验证记录

## 背景
法师学不了技能，怀疑LEARN_SKILL的职业限制(Type=1 ID=1)导致。

## 验证过程

### 第一步：XLS清空所有Type=1 ID=1
- 操作：修改 `D:\彩虹岛\resource\ROWID\DATA\XLS\LEARN_SKILL.xls`
- 改动：958组 Require 中 Type=1 ID=1 全部清0（Type/ID/Value1/Value2）
- 结果：用户用彩虹岛编辑器写回LDT后，**GS无报错但技能仍然学不了**

### 第二步：LDT二进制直接修改（失败）
- 尝试找LEARN_SKILL.LDT的int32=1,1模式
- 失败原因：格式是int+string混合，不是固定宽度int
- 教训：永远不要直接二进制改LEARN_SKILL.LDT，走XLS→编辑器路线

### 第三步：S3端验证
- 来源：`D:\LaTale\S4\resource\ROWID\DATA\XLS\LEARN_SKILL.xls`
- S3端V1值：1001/1002/1003体系（小整数，非脏数据）
- 清空2377组Type=1 ID=1后，**用户确认能学了**
- 说明S3端GS能正常工作，当前端的问题不在LEARN_SKILL

### 结论
当前端（彩虹岛）的学习问题根源不在LEARN_SKILL。可能与缺失的CLASS_CHANGE/CLASS_EFFECT/CLASS_SWITCH.LDT有关。LEARN_SKILL里的职业限制列对于GS是冗余的——角色看不到非本职业的技能，GS不需要额外校验。
