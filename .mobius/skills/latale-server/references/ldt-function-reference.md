# 彩虹岛 LDT 功能对照表

用户提供的 LDT 文件功能说明（200+ LDT 用途）。

## 文本/UI相关

| LDT | 作用 |
|---|---|
| GLOBAL_STRING.LDT | 全服所有字串（UI提示、系统消息） |
| GLOBAL_MOB.LDT | 全服怪物/NPC/宝箱头顶对话框内容 |
| CLASS_STRING.LDT | 职业限制的字串（武器限制提示） |
| CLASS_NAME.LDT | 职业名称（国服独有） |
| CLASS_EFFECT.LDT | 转职成功后底部聊天栏显示 |
| CLASS_CHANGE.LDT | 转职限制，转职后给予的白板武器、BUFF |
| CLASS_SWITCH.LDT | 副职业转换限制，转换后给予的白板武器、buff |
| SKILL_TXT.LDT | 技能详细描述 |
| SKILL.LDT | 技能ID、名称、学习等级、最高等级、所需技能点ELY |
| PVP_SKILL_TXT.LDT | PVP技能描述 |
| TITLE.LDT | 称号描述、称号给予的属性/buff、文字颜色 |
| CHAT_COLOR.LDT | 聊天字符颜色 |
| CHAT_COMMAND.LDT | 聊天公共设置 |
| CHAT_MACRO.LDT | 喇叭使用状态 |
| CHAT_TYPE.LDT | 聊天类型 |
| ABUSE_LIST.LDT | 屏蔽词名单1（屏蔽词+替换字符） |
| BAN_LIST.LDT | 屏蔽词名单2（屏蔽词+替换字符） |
| NOTICE_RANDOM.LDT | 系统随机公告 |

## 商城/现金

| LDT | 作用 |
|---|---|
| CASH_SHOP.LDT | 商城详情（物品显示页面/位置/名字/Icon/价格/发送物品） |
| CASH_SHOP_BURNING.LDT | 商城详情（废弃） |
| CASH_SHOP_HOT.LDT | 物品栏右侧快捷购买物品 |
| CASH_SHOP_HOT_BURNING.LDT | 快捷购买（废弃） |
| CASH_SHOP_LIMIT.LDT | 商城限制 |
| CASHSHOP_DEFAULT.LDT | 进入商城的默认显示 |
| CASHSHOP_HELP.LDT | 商城帮助 |
| CASH_PRICE_RATIO.LDT | 现金价格比（勿改） |
| BEAUTY_SHOP.LDT | 美容院所有项目（发型卷等） |
| VIP.LDT | 商城购买所需点数，奖励名单 |

## 任务

| LDT | 作用 |
|---|---|
| QUEST.LDT | 任务列表 |
| QUEST_1.LDT | 主线任务 |
| QUEST_2.LDT | 支线任务 |
| QUEST_ESSENTIAL.LDT | 传奇任务ID设置 |
| QUEST_INFO_1.LDT | 主线任务详细内容+Icon+完成后NPC对话 |
| QUEST_INFO_2.LDT | 支线任务详细内容+Icon+完成后NPC对话 |
| QUEST_LIST.LDT | NPC任务目录，包含的子任务 |
| QUEST_RANDOM.LDT | 随机任务出现概率 |
| QUEST_REWARD.LDT | 任务扣除物品及奖励 |
| QUEST_REWARD_1.LDT | 主线任务奖励 |
| QUEST_REWARD_2.LDT | 支线任务奖励 |
| QUEST_DROP_ITEM.LDT | 任务掉落物品和概率 |

## NPC

| LDT | 作用 |
|---|---|
| NPC.LDT | NPC ID、名称、对话栏显示、选择栏设置 |
| NPCTALK.LDT | 所有NPC对话ID、对话内容、隐藏对话触发事件/条件/效果 |
| NPCTRADE.LDT | 购买父项ID、子项ID、父项NPC对话框 |
| NPCTRADE_DETAIL.LDT | 购买子项对应的物品及要求 |
| NPCTRADE_LIST.LDT | 购买对话类型ID及子购买集 |
| NPC_EVENT.LDT | 兑换父项ID、子项ID、父项显示文本 |
| NPC_EVENT_DETAIL.LDT | 兑换子项物品及要求 |
| NPC_EVENT_LIST.LDT | 兑换对话类型ID及父项ID |
| NPC_GIFT.LDT | 礼物对话类型ID及NPC对话 |
| NPC_GUILD.LDT | 公会对话类型ID及NPC对话 |
| NPC_PORTAL.LDT | 传送对话ID、传送ID |
| NPC_STORAGE.LDT | 仓库对话类型ID及NPC对话 |
| FISHING_NPC.LDT | 钓鱼委托（等待时间/可获取数量/可钓物品列表） |

## 物品

| LDT | 作用 |
|---|---|
| ITEM_1.LDT | 物品库（可用职业/耐久/套装ID/装备属性） |
| ITEM_2.LDT | 物品库 |
| ITEM_3.LDT | 物品库 |
| ITEM_ADD_TIME.LDT | 宠物库，添加后可使用时间 |
| ITEM_ENCHANT.LDT | 物品砸图概率 |
| ITEM_OPTION.LDT | 物品砸图设置效果 |
| ITEM_SEAL.LDT | 可密封的装备 |
| ITEM_UPGRADE.LDT | 物品升级信息 |
| ITEM_CREATE_RECIPE.LDT | 制造所需等级/物品/经验/成功率 |
| ITEM_CREATE_RESULT.LDT | 物品制造结果 |
| ITEMSET.LDT | 掉落包裹子ID包含物品及概率 |
| ITEMSET_A.LDT | 掉落包裹父ID所包含的子ID |
| ITEMSET_B.LDT | 掉落包裹父ID所包含的子ID |
| SETITEM.LDT | 套装信息/属性/代码 |
| COLLECT_ITEM.LDT | 物品图鉴 |
| COLLECT_MOB.LDT | 怪物图鉴 |
| DELETE_ITEM.LDT | 到期删除的物品 |

## 战斗/核心数据（⚠️勿改）

| LDT | 作用 |
|---|---|
| ATTACK_TREE.LDT | 攻击树（重要数据！） |
| BEATTACKED.LDT | 被攻击后的状态（重要数据！） |
| ACTION_INTERFACE.LDT | 基本动作接口（无关游戏乐趣，勿改） |
| AUCTION_ITEM.LDT | 拍卖场项目（无关游戏乐趣，勿改） |
| AUCTION_TYPE.LDT | 拍卖场样式（无关游戏乐趣，勿改） |
| EFFECT.LDT | 游戏所有BUFF（物品/技能使用效果） |
| MOB_ACTION.LDT | 怪物行动AI |
| MOB_ATTACK_AI.LDT | 怪物攻击AI（技能使用概率/间隔） |
| MOB_MOTIONSTATUS.LDT | 怪物动作状态（含技能） |
| MOBBASE.LDT | 怪物基本值 |
| MOBLOOT.LDT | 怪物XP/ELT/掉落概率 |
| SKILL_USE.LDT | 技能使用要求/buff/声音/效果/CD/combo |
| LEARN_SKILL.LDT | 技能学习要求 |

## 成就/活动

| LDT | 作用 |
|---|---|
| ACHIEVE.LDT | 成就目录（条件+物品+RANK奖励） |
| ACHIEVE_MISSION.LDT | 成就达成条件（击杀怪物/次数） |
| ACHIEVE_RANK.LDT | 成就RANK详情（每级所需point/奖励属性） |
| EVENT_INFO.LDT | 游戏活动设置（名字/图片/介绍/时间） |
| EVENT_INFO_ATTEND.LDT | 活动出席奖励条件及代码 |
| EVENT_INFO_ITEM.LDT | 活动出席奖励物品 |
| EVENTPORTAL.LDT | 事件触发地图ID/传送位置 |

## ⚠️ 替换注意事项

- 标记为「勿改」「重要数据」的文件结构可能兼容但**不应替换**——即使字段数相同，替换后可能导致服务端崩溃
- 已确认安全的文本文件：GLOBAL_STRING, SKILL_TXT, GLOBAL_MOB, PVP_SKILL_TXT
- GLOBAL_SYS.LDT 结构不同（S2: String+String, 国服: Int+String），merge_spf.py 自动跳过
