# LDT 功能参考表

用户提供的 200+ LDT 文件功能对照。

## 核心文本 LDT

| 文件 | 功能 | 国服兼容 |
|---|---|---|
| GLOBAL_STRING.LDT | 全服所有字串（UI/系统提示/聊天） | ✅ 可直接替换 |
| GLOBAL_MOB.LDT | 怪物/NPC/宝箱名称及对话框 | ✅ 可直接替换 |
| SKILL_TXT.LDT | 技能详细描述 | ✅ 可直接替换 |
| SKILL_CONTENT.LDT | 技能页面位置 | ✅ 可直接替换 |
| CLASS_STRING.LDT | 职业限制字串 | ❌ 结构不同 |
| TITLE.LDT | 称号描述/属性/buff/颜色 | ❌ 结构不同 |

## 商城 & 外观

| 文件 | 功能 | 国服兼容 |
|---|---|---|
| CASH_SHOP.LDT | 商城物品（名称/Icon/价格/发送物品） | ❌ 64vs70字段 |
| BEAUTY_SHOP.LDT | 美容院项目（发型/颜色等） | ❌ 15vs67字段 |
| CASH_SHOP_HOT.LDT | 快捷购买物品 | ✅ |
| CASHSHOP_DEFAULT.LDT | 商城默认显示 | ✅ |

## 任务 & 事件

| 文件 | 功能 |
|---|---|
| QUEST.LDT | 任务列表（含主线/支线） |
| QUEST_LIST.LDT | NPC任务目录 |
| QUEST_REWARD.LDT | 任务奖励/扣除物品 |
| QUEST_ESSENTIAL.LDT | 传奇任务ID |
| QUEST_RANDOM.LDT | 随机任务概率 |
| EVENT_INFO.LDT | 活动设置（名称/图片/时间） |
| EVENT_INFO_ATTEND.LDT | 活动出席奖励 |

## 物品 & 装备

| 文件 | 功能 |
|---|---|
| ITEM_1/2/3.LDT | 物品库（可用职业/耐久/套装/属性） |
| SETITEM.LDT | 套装信息 |
| ITEM_ENCHANT.LDT | 砸图概率 |
| ITEM_UPGRADE.LDT | 物品升级 |
| ITEM_CREATE_RECIPE.LDT | 制造配方 |
| GAMBLE.LDT | 换购/抽奖箱子 |

## NPC & 对话

| 文件 | 功能 |
|---|---|
| NPC.LDT | NPC ID/名称/对话栏 |
| NPCTALK.LDT | 所有NPC对话内容/触发条件 |
| NPCTRADE.LDT | 购买项目设置 |
| NPC_EVENT.LDT | 兑换项目 |

## 技能 & 战斗

| 文件 | 功能 |
|---|---|
| SKILL.LDT | 技能ID/名称/学习要求 |
| SKILL_USE.LDT | 技能效果/buff/CD |
| LEARN_SKILL.LDT | 技能学习条件 |
| ATTACK_TREE.LDT | 攻击树 |
| EFFECT.LDT | 所有BUFF效果 |

## 怪物

| 文件 | 功能 |
|---|---|
| MOBBASE.LDT | 怪物基本值 |
| MOBLOOT.LDT | 掉落概率 |
| MOB_ATTACK_AI.LDT | 怪物攻击AI |
| MOBARRANGE.LDT | 怪物刷新位置/时间 |

## 国服独有新系统（S2不支持）

觉醒(AWAKEN)、战令(BATTLEPASS)、传奇技能(LEGEND_SKILL)、魂宠(SOULPET)、副本(INDUN)、PVP完整系统等 470+ 个 LDT。

## 国服文本自动替换效果

使用 `merge_spf.py` 后自动获得的文本修正：

| 旧(S2) | 新(国服) |
|---|---|
| 红利 | 点券 |
| 戳戳乐 | 淘淘乐 |
| 时尚商店 | 商城 |
| 追踪 | 搜索 |
| 骑士 | 盾卫 |
| 剑斗士 | 狂战 |
| 魔导士 | 魔法师 |
| 浪人剑客 | 吉他手 |
