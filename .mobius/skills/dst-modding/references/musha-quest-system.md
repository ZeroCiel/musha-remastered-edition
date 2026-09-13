# Musha 任务系统架构（2026-09-08 重构版）

用户自己的 DST mod（`mods/musha`）。任务系统在重构后分**两套独立任务**，别再按旧的"接3个做完进阶"理解。

## 数据模型（scripts/components/musha_quest.lua）
| 字段 | 含义 |
|------|------|
| `self.daily_quests` | 每日任务数组，可累积，上限 10（`DAILY_MAX`） |
| `self.advance_quest` | 转职任务，一次 1 个 |
| `self.advance_round` | 转职轮次 1..3 |
| `self.advance_target` | 目标职业字符串（如 `"saber"`） |

面板读的字段（经 replica `cached_data.userdata`）：
`daily_quests[{id,p,t,done}]`、`advance_quest{id,p,t,done}`、`advance_round`、`advance_target`。
旧字段 `quests_for_advance` / `quests_for_advance_done` 已废弃并在同步时清空——**面板 UI 还读旧字段就是显示空的原因**。

## 发放/推进规则
- 每日：`OnNewDay()`（WatchWorldState "startday"）= ①未完成 discover 类作废 ②survive 类进度+1
  ③`FillDailyQuests()` 补至配置数（`GLOBAL.__musha_daily_quest_count`，3~5，默认 4）
- 进度推进：所有事件走 `ProgressQuests(match_fn)`，内部同时检查每日 + 当前转职任务
- 转职：`AcceptAdvanceQuest(target)` 雕像每次接 1 个，难度池随轮次 1→2→3 递进（简单→中→难），
  跳过 `heal_skill`；第 3 轮完成 → `CompleteAdvanceQuest()` 设 `carrer_special` + 发 `musha_skillbook`
- 存档：`OnSave/OnLoad` 存 daily_quests / advance_quest / advance_round / advance_target；
  **OnLoad 里若任务为空要补发**（否则旧档进游戏没任务）

## 任务类型表（MUSHA_QUEST_TYPES，13 种）
discover(1龙蝇/4格罗姆/11海象营地) · kill_spider(2) · survive(3) · collect(5噩梦燃料) ·
collect_gems(6) · craft(7) · cookpot(8) · kill_pig(9) · kill_firehound(10) ·
heal_skill(12，技能系统未启用→抽池时排除) · craft_science(13)

事件驱动来源：
- 击杀/制造/锅：玩家实体事件（killed / craftitem / harvest）
- 收集：modmain 在 nightmarefuel、ruby/emerald/sapphire 的 `onputininventoryfn` 里 PushEvent `musha_item_collected`
- 发现：modmain 每 5 秒 `TheSim:FindEntities` 轮询（30/20/30 码）调 `quest:OnDiscovered(type)`
- 天数：WatchWorldState "startday"
- protect：quest 组件里 `areatrigger`、`heal_skill` 是历史遗留，方法要留空实现防崩

## 转职祭坛（占位实现）
真正的"进阶祭坛"prefab 从未实现（只有语言条目 + 动作钩子）。当前用
`AddPrefabPostInit("statuemaxwell")` 给它挂 `musha_altar` tag + `musha_action` 组件，
交互链：SCENE 右键 `MUSHA_QUEST_INTERACT` → `musha_action:InteractScene()` → 接转职任务。
> 注意：`musha_action` 组件原本**没有** `InteractScene` 方法（AddAction 里却在调），必须补，否则点祭坛即崩。

## 待办 / 设计定稿（见 mod 内 mush-backlog.md）
- ② 面板任务区改 ScrollingGrid 滚动框（参考 `mods/mingsheng/scripts/screens/mingsheng_teleportscreen.lua`）：
  每日行=淡黄底+右上"普通"小标；转职行=灰底框+顶红条+"（转职任务）"标；发放时整行滑入
- 任务扩编到 ~30（远期 50）：季节活动任务（秋/冬/春/夏专属，任务表加 `season` 字段按季节过滤）
  + 移动散步任务（`move` 类型，2~3s 采样位置累距离，3000/6000/10000 分档）
- 职业联动任务（技能击杀/背刺等）用户明确**搁置**

## 用户的协作习惯（重要）
- 数值微调（坐标/颜色/尺寸）**一次批量给完再动手**，别一条条问、一条条改——用户明确抱怨过
  "耗 token 和金额太快"。每次改动都返回完整 diff，逐条改最烧钱。
- 长会话 / 设计还在变时：先把设计写进 `mods/musha/mush-backlog.md`（用户会断电/下班），
  代码未定稿不要大改；用户回来说"继续"再动手。
- 面板 UI 用户看不到 AI 的视觉通道（本机图读不了），只能靠用户文字描述或截图评审（他用腾讯元宝看截图），
  所以 UI 调整靠"报数值"式微调。
