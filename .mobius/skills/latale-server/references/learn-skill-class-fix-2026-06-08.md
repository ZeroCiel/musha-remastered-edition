# LEARN_SKILL职业条件修正记录 (2026-06-08)

## 问题

法师技能（旋风劈、冰封龙枪、冰雪魔力、精灵潜力等）等级满足但无法从NPC学习。
点了学习按钮没反应，不报错。

## 诊断过程

1. **SKILL.xls** 的 `_UpRequire` 条件（等级、前置技能）与怀旧端一致，没有差异
2. **LEARN_SKILL.xls** 的职业条件 `Type=1 ID=1 V1=1003` 在CLASS_STRING.LDT中对应的是战士/骑士系列，不是法师
3. CLASS_STRING.LDT中法师的ID=3，魔导士ID=13
4. 数据库tbluPC.class字段显示角色class=13（魔导士初始职业）

## 修复

将LEARN_SKILL.xls中所有 `Type=1 ID=1 V1=1003` 改为 `V1=13`（魔导士体系）。
S3端的LEARN_SKILL.xls也使用V1=1003，说明数据源一致，但GS的exe不认1003。

## 注意

- GS读的是**LDT**（从xls转换打包后），不是xls直接
- 改xls后必须重新打包成LDT/SPF
- CLASS_STRING.LDT存储职业ID→名称的映射，但GS判断职业限制时可能还参考CLASS_CHANGE/CLASS_EFFECT/CLASS_SWITCH等表
- 当前端（S4）缺少CLASS_CHANGE.LDT/CLASS_EFFECT.LDT/CLASS_SWITCH.LDT（怀旧端有）

## NPC_EVENT_DETAIL 初始化费用

技能初始化所需彩虹币（110000 Ely）存储在 `NPC_EVENT_DETAIL.LDT` 的二进制数据中。
直接搜索int 110000的小端格式 `0xB0AE0100` 并替换为1即可改为1Ely。
