# 彩虹岛技能学习系统 (SKILL / LEARN_SKILL)

## 核心文件

| 文件 | 路径 (DATA/LDT/) | 作用 |
|------|------------------|------|
| SKILL.LDT | DATA/LDT/ | 技能主表（定义、条件、升级） |
| LEARN_SKILL.LDT | DATA/LDT/ | 学习条件表（NPC学习条件） |
| SKILL_USE.LDT | DATA/LDT/ | 技能效果/伤害公式 |
| SKILL_TXT.LDT | DATA/LDT/ | 技能名称/描述文本 |
| CLASS_STRING.LDT | DATA/LDT/ | 职业ID→名称映射（前端显示用） |
| CLASS_CHANGE.LDT | DATA/LDT/ | **S4端常缺失**，职业转换 |
| CLASS_EFFECT.LDT | DATA/LDT/ | **S4端常缺失**，职业效果 |
| CLASS_SWITCH.LDT | DATA/LDT/ | **S4端常缺失**，职业切换 |
| NPC_EVENT_DETAIL.LDT | DATA/COMMON/ | 技能初始化（洗点）费用 |

## SKILL.xls 结构

| 列(0-based) | 字段 | 说明 |
|:---:|:---|:---|
| 0 | _ID | 技能ID |
| 1 | _Name | 技能名 |
| 3 | _MaxSlv | 最大等级 |
| 6 | _SkillType | 1=主动 |
| 8 | _UpRequireSkillPoint | 升级所需技能点数 |
| 10 | _UpRequire1_Type | 升级条件1类型 |
| 11 | _UpRequire1_ID | 条件1参数ID |
| 12 | _UpRequire1_Value1 | 条件值（如等级要求） |
| 13 | _UpRequire1_ValueSlv1 | 每级增加值 |
| 16 | _UpRequire2_Type | 升级条件2类型 |
| 17 | _UpRequire2_ID | 条件2参数ID |
| 18 | _UpRequire2_Value1 | 前置技能ID（Type=3时） |
| 20 | _UpRequire2_Value2 | 前置技能等级 |
| 22 | _Learn_Skill | 1=可从NPC学习, 0=不可 |
| 41 | _Description | 技能描述（GS显示） |
| 42 | _DisableDescription | 不可用时的描述+学习条件 |

### 升级条件类型

- **Type=1 ID=3** → 等级限制, Value1=要求等级
- **Type=3 ID=2** → 前置技能需求, Value1=技能ID, Value2=所需等级

## LEARN_SKILL.xls 结构

彩虹岛编辑器导出格式：TAB分隔GBK文本，50列。

| 列(0-based) | 字段 | 说明 |
|:---:|:---|:---|
| 0 | _ID | 技能ID（与SKILL一致） |
| 1 | _Name | 技能名 |
| 2 | _Consumption_Ely | 消耗金钱 |
| 3 | _Consumption_Item | 消耗道具 |
| 4~7 | _Require1_Type/ID/Value1/Value2 | 条件1（4列一组） |
| 8~11 | _Require2 | 条件2 |
| 12~15 | _Require3 | 条件3 |
| 16~19 | _Require4 | 条件4 |
| 20~23 | _Require5 | 条件5 |
| **24~27** | **_Require6_Type/ID/Value1/Value2** | ⚠️ 职业限制固定位置 |
| 28~31 | _Require7 | 条件7 |
| 32~35 | _Require8 | 条件8 |
| 36 | _Description | 学习描述 |
| 37 | _Message | 学习成功消息 |
| 39~48 | _ErrorMessage_Ely~8 | 各种失败提示 |

### Require条件类型

- `Type=1 ID=3 V1=N` : 等级≥N（**保留**）
- `Type=1 ID=1 V1=位掩码` : ⚠️ **职业限制（GS实际校验逻辑不在此处，见下文）**
- `Type=3 ID=2 V1=N V2=M` : 前置技能ID=N 等级≥M

## ⚠️ 核心发现：职业限制不在 LEARN_SKILL（2026-06-09）

**GS实际判断"能不能学技能"的核心逻辑完全不在LEARN_SKILL里。**

验证过程：
1. 在XLS中清掉LEARN_SKILL全部Require组的`Type=1 ID=1`（958行全清）
2. 彩虹岛编辑器写回LDT，重启GS
3. **结果：法师仍然学不了技能，GS无报错**

LEARN_SKILL只是定义了NPC学习时显示的UI条件/费用。实际的职业限制校验在GS的exe代码本身。

### 最终排查方向

| 顺序 | 文件 | 状态 |
|:---:|:---|:---|
| 1 | ✅ LEARN_SKILL | 已排除（Type=1 ID=1清0仍不能学） |
| 2 | ❓ CLASS_CHANGE.LDT | **S4端常缺失**，需从S3/怀旧端复制 |
| 3 | ❓ CLASS_EFFECT.LDT | **S4端常缺失** |
| 4 | ❓ CLASS_SWITCH.LDT | **S4端常缺失** |
| 5 | ❓ SKILL.xls._Learn_Skill | 是否=1 |
| 6 | ❓ SKILL.xls._UpRequire1/2 | 前置技能是否满足 |

### S3端 LEARN_SKILL 差异化修复记录

| 项目 | 值 |
|------|-----|
| 来源 | D:\LaTale\S4\resource\ROWID\DATA\XLS\LEARN_SKILL.xls |
| 总行数 | 3201行 |
| Require Type/ID组合分布 | (0,0)=19537, (1,1)=2377, (1,3)=2219, (3,2)=1371 |
| 操作 | 清空全部2377组Type=1 ID=1 |
| 结果 | ✅ 用户确认修复——技能可以正常学习 |

S3端清理后正常学习，说明S3端GS能正常工作。当前端的问题不是LEARN_SKILL本身，而是端内其他系统（CLASS_CHANGE缺失等）导致职业判断异常。

### 怀旧端 vs 当前端 LEARN_SKILL 差异

| 对比项 | 怀旧端 (D:\ROWID) | 当前端 (D:\彩虹岛) |
|--------|-------------------|-------------------|
| XLS行数 | 5003行, 2803个ID | 2335行, 2332个ID |
| 相同ID | — | 1610个 |
| 仅怀旧有 | 1193个（战士系技能） | — |
| 仅当前有 | — | 722个（S4新职业技能） |
| V1值 | 1001/1002/1003等小整数 | 34359754769等大数（脏数据） |

**不要直接覆盖LEARN_SKILL.LDT**——两端ID差异大，覆盖导致S4新职业（龙战士/剑圣/炙焰天等）的技能学不了。

## 技能ID规律

| 前缀 | 职业系 | 示例 |
|:---:|:---|:---|
| 100xxxx | 战士/共通系 | 1000001=基础攻击 |
| 200xxxx | 法师系 | 2000002=风刃术, 2001002=旋风劈, 2001006=冰封龙枪 |
| 2004xxx | II阶技能 | 2004002=风刃术II |
| 2005xxx | II阶升级 | 2005002=旋风劈II |
| 210xxxx | III阶技能 | 2105002=旋风劈III（需要等级70） |
| 240xxxx | 高阶职业专精 | — |
| 300xxxx | 精灵系 | 3000340=精灵潜力 |
| 350xxxx | 属性增益系 | 3501401=冰雪魔力 |
| 800xxxx | 精灵精通系 | — |
| 80xxxxx | 熟练精灵 | — |

### 技能升级链示例（法师风系）

```
风刃术(2000002, Lv1)
  → 旋风劈(2001002, Lv12, 需风刃术Lv1)
    → 风庇护(2002002, Lv30, 需旋风劈Lv1)
      → 风刃术II(2004002, Lv38)
        → 旋风劈II(2005002, Lv35, 需风刃术II)
          → 风庇护II(2006002, Lv32)
            → 旋风狂扫II(2007002, Lv65)
              → 旋风劈III(2105002, Lv70)
```

## NPC_EVENT_DETAIL 技能初始化费用

技能初始化所需彩虹币（示例：110000 Ely）存储在 `NPC_EVENT_DETAIL.LDT` 的二进制数据中。直接搜索int 110000的小端格式 `0xB0AE0100` 并替换为1即可改为1Ely。

## ⚠️ LEARN_SKILL.LDT 不能直接二进制修改

LEARN_SKILL.LDT的二进制格式是**int列 + 变长string列混合**，不是固定宽度int：
- 不能用 `col×4` 计算偏移
- 搜索 `\x01\x00\x00\x00\x01\x00\x00\x00`（int32=1连续两次）搜不到Require组
- **唯一正确方式**：彩虹岛编辑器导出XLS → 修改XLS → 编辑器从改好的XLS导入写回LDT → 重启GS

## 相关参考文件

- `references/learn-skill-class-fix-2026-06-08.md` — 初始职业条件修正记录
- `references/session-20260609-learningskill-job-validation.md` — 职业验证完整调试记录
