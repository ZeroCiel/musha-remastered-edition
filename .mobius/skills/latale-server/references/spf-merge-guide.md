# SPF 合并指南（国服文本替换）

## 工具
- `D:\彩虹岛\spf_extract.py` — SPF 解包器
- `D:\彩虹岛\merge_spf.py` — SPF 合并器
- `D:\彩虹岛\ldt_tool.py` — LDT 解析器

## SPF 格式
- FINFO 条目在文件末尾，每条 140 字节：128B 路径 + 4B pos + 4B size + 4B ResID
- 从 `file_size - 280` 开始倒读（跳过末尾 140B 哨兵）
- 哨兵条目：content_pos=0 表示结束

## 合并策略
1. 解包国服 ROWID.SPF → D:\Server\SPF\guofu\DATA\LDT\
2. 对比 S2 和国服 LDT 结构
3. 只替换结构一致的 LDT（101 个）
4. 结构不同的保留 S2 版（95 个）

## 安全替换清单
GLOBAL_STRING, SKILL_TXT, SKILL_CONTENT, GLOBAL_MOB, PVP_SKILL_TXT,
QUEST_LIST/ESSENTIAL, NPCTRADE, CHAT_COMMAND/MACRO/TYPE,
CASHSHOP_HELP/DEFAULT, CASH_SHOP_HOT/LIMIT,
CLASS_CHANGE/EFFECT, ITEMSET_A/B, CARDBINDER, SEALSKILL_LEVEL

## 二分排查法
当合并后服务崩溃时，逐步减半文件数定位问题文件。
高风险文件：ATTACK_TREE.LDT, BEATTACKED.LDT 等核心战斗数据。

## 文本差异
红利→点券, 戳戳乐→淘淘乐, 时尚商店→商城, 追踪→搜索
骑士→盾卫, 剑斗士→狂战, 魔导士→魔法师
