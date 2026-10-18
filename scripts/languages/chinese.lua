-- Musha 0.7.6 — 简体中文语言文件

local S = GLOBAL.STRINGS

-- 物品名称
S.NAMES.MUSHA_SWORD = "剑"
S.NAMES.MUSHA_LIFEBRANCH = "生命树枝"
S.NAMES.MUSHA_SKILLBOOK = "技能书"
S.NAMES.MUSHA_SKILL_SCROLL = "技能卷轴"
S.NAMES.MUSHA_NOTE = "便签"
S.NAMES.MUSHA_JOBBOOK = "职业书"
S.NAMES.MUSHA_JOBBOOK_WARRIOR = "职业书（战士）"
-- ✅ 2026-09-17 发布前：测试专用转职书已下架 → S.NAMES.MUSHA_JOBBOOK_SABER = "剑士转职书（测试）"
S.NAMES.MUSHA_BOOK_UNKNOWN = "一本未知的书籍"
S.NAMES.MUSHA_JOBBOOK_MAGE = "法师职业书"
S.NAMES.MUSHA_JOBBOOK_RANGER = "游侠职业书"
S.NAMES.MUSHA_JOBBOOK_GUARDIAN = "近卫职业书"
S.NAMES.MUSHA_JOBBOOK_ASSASSIN = "刺客职业书"
S.NAMES.MUSHA_ADVANCE_ALTAR = "酒馆"
S.NAMES.MUSHA_ADVANCE_SCROLL = "转职卷轴"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_ADVANCE_SCROLL = "酒馆深处取出的古老卷轴。展开它，接下考验。"
S.NAMES.MUSHA_SKILLBOOK_SWORDSMAN = "剑士基础技能书"
S.NAMES.MUSHA_SKILLBOOK_GUARDIAN = "近卫基础技能书"
S.NAMES.MUSHA_SKILLBOOK_ALCHEMIST = "药剂师基础技能书"
S.NAMES.MUSHA_SKILLBOOK_ELEMENTALIST = "元素法师基础技能书"
S.NAMES.MUSHA_SKILLBOOK_BARD = "吟游诗人基础技能书"
S.NAMES.MUSHA_SKILLBOOK_MOONSHADOW = "月影猎手基础技能书"
S.NAMES.MUSHA_REST_ITEM = "休息"

-- 物品描述
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_JOBBOOK_WARRIOR = "一本记载着战士之路的书。使用后转职为战士。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_JOBBOOK_MAGE = "一本记载着法师之路的书。使用后转职为法师。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_JOBBOOK_RANGER = "一本记载着游侠之路的书。使用后转职为游侠。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_JOBBOOK_ASSASSIN = "一本记载着刺客之路的书。使用后转职为刺客。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_ADVANCE_ALTAR = "一座古老的酒馆，蕴藏着进阶的力量。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_SWORDSMAN = "记载着剑士基础技能的书。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_GUARDIAN = "记载着近卫基础技能的书。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_ALCHEMIST = "记载着药剂师基础技能的书。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_ELEMENTALIST = "记载着元素法师基础技能的书。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_BARD = "记载着吟游诗人基础技能的书。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK_MOONSHADOW = "记载着月影猎手基础技能的书。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SWORD = "一把沉重的职业剑，散发着淡淡的寒光。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_LIFEBRANCH = "一根还活着的树枝，握在手里温温的，像在轻轻抽芽。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILLBOOK = "一本泛黄的书，记载着你的职业技能。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_SKILL_SCROLL = "记载着普通技能要诀的卷轴。展开后习得其中的技能。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_REST_ITEM = "右键点击切换休息状态。"

-- 角色选人界面
S.CHARACTER_TITLES.musha = "冒险者"
S.CHARACTER_NAMES.musha = "穆莎"
S.CHARACTER_DESCRIPTIONS.musha = "*开局携带指引便签\n*多个方向成长\n*等级越高能力越强"
S.CHARACTER_QUOTES.musha = "\"你会知道我的厉害的！\""
STRINGS.NAMES.musha = "穆莎"

-- 动作名称
S.ACTIONS.MUSHA_USE_JOBBOOK = "转职"
S.ACTIONS.MUSHA_USE_JOBBOOK_STR = {
    ["转职"] = "转职",
    ["使用"] = "使用",
    ["未知"] = "未知",
}
S.ACTIONS.MUSHA_OPEN_ALTAR = "打开酒馆"          -- 2026-09-17：原 MUSHA_QUEST_INTERACT("查看任务")，祭坛改成容器后重命名
S.ACTIONS.MUSHA_UNROLL_SCROLL = "展开卷轴"      -- 2026-09-17：转职卷轴（祭坛里取出来的）
-- ★ 2026-09-18 进阶方向徽记（就职仪式发两枚：剑士 / 近卫；用掉一枚 = 选定方向，不可更改）
S.ACTIONS.MUSHA_USE_CREST = "使用徽记"
-- ★ 2026-09-19 邮包系统（信箱 + 信差包）
--   动作名：默认「触摸」；背包里带着升级套件时 strfn 会改成「升级」
--   （BIND / OPEN 两条备用文案：等"是否已绑定"同步到客户端后再启用 —— 见 musha_actions.lua 的 strfn）
S.ACTIONS.MUSHA_OPEN_MAILBOX = "触摸"
S.ACTIONS.MUSHA_PUT_MAILBOX = "存入信箱"
S.ACTIONS.MUSHA_OPEN_MAILBOX_STR = {
    UPGRADE = "升级",
    BIND    = "触摸（绑定）",
    OPEN    = "触摸（打开）",
}
S.ACTIONS.MUSHA_OPEN_MAILBAG = "打开信差包"
S.NAMES.MUSHA_MAILBOX = "信箱"
S.NAMES.MUSHA_MAILBAG = "信差包"
S.NAMES.MUSHA_MAILKIT_1 = "邮包升级套件 I（收件箱 3→5 格）"
S.NAMES.MUSHA_MAILKIT_2 = "邮包升级套件 II（收件箱 5→7 格）"
S.NAMES.MUSHA_MAILKIT_3 = "邮包升级套件 III（收件箱 7→9 格）"
S.NAMES.MUSHA_MAILKIT_4 = "邮包升级套件 IV（收件箱 9→12 格）"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILBOX = "第一次摸它，你的收件箱就落在这儿了。之后它一直在。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILBAG = "往里面塞东西，合上——它们就自己回家。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILKIT_1 = "拿着它对信箱说「升级」。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILKIT_2 = "拿着它对信箱说「升级」。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILKIT_3 = "拿着它对信箱说「升级」。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_MAILKIT_4 = "拿着它对信箱说「升级」。"
S.NAMES.MUSHA_CREST_SABER = "剑士徽记"
S.NAMES.MUSHA_CREST_GUARDIAN = "近卫徽记"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_CREST_SABER = "刻着剑纹的徽记。用掉它，你就是剑士了——方向不可更改。"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_CREST_GUARDIAN = "刻着盾纹的徽记。用掉它，你就是近卫了——方向不可更改。"
S.ACTIONS.MUSHA_LEARN_SKILL = "学习技能"
S.ACTIONS.MUSHA_REST = "休息"
S.ACTIONS.MUSHA_OPEN_PANEL = "打开面板"
S.ACTIONS.MUSHA_READ_NOTE = "阅读"

-- 系统消息
S.MUSHA_JOB_USE_NO_SYSTEM = "没有职业系统的支持…"
S.MUSHA_JOB_USE_ALREADY_HAS = "我已经选择了职业！"
S.MUSHA_JOB_USE_WARRIOR = "我已转职成为战士"
S.MUSHA_JOB_USE_NO_JOB = "我还没有选择职业！"

-- 职业名称
S.MUSHA_JOB_WARRIOR = "战士"
S.MUSHA_JOB_MAGE = "法师"
S.MUSHA_JOB_RANGER = "游侠"
S.MUSHA_JOB_ASSASSIN = "刺客"
S.MUSHA_JOB_SWORDSMAN = "剑士"
S.MUSHA_JOB_SABER = "剑士"        -- 代码里的树名是 saber（组件 self.saber），补个别名给技能页显示用
S.MUSHA_JOB_GUARDIAN = "近卫"
S.MUSHA_JOB_ALCHEMIST = "药剂师"
S.MUSHA_JOB_ELEMENTALIST = "元素法师"
S.MUSHA_JOB_BARD = "吟游诗人"
S.MUSHA_JOB_MOONSHADOW = "月影猎手"
S.MUSHA_JOB_NONE = "无职业"

-- 任务消息
S.MUSHA_QUEST_ACCEPTED = "我接取了任务，去完成它吧！"
S.MUSHA_QUEST_ABORTED = "我放弃了当前任务，损失了 80 点经验。"
S.MUSHA_QUEST_COMPLETE = "任务完成！"
S.MUSHA_QUEST_ALL_DONE = "我已完成了所有转职任务！"


-- ============================================================
-- 回城石（2026-09-20 用户需求）
--   拿在手上对任何东西用 = 绑定它；背包里右键石头 = 回家
--   冷却 360 秒 / 可用 3 次 / 用完自毁
-- ============================================================
S.NAMES.MUSHA_RECALL_STONE = "回城石"
S.ACTIONS.MUSHA_RECALL_HOME = "回家"
S.ACTIONS.MUSHA_BIND_STONE = "绑定"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_RECALL_STONE = "一块温热的石头。拿着它对一个地方说「就这儿」，之后右键就能回来——它认路，也认人。"
-- 第二条配方（绿宝石版）在合成栏里单独列一条，名字区分开
S.NAMES.MUSHA_RECALL_STONE_GREEN = "回城石（绿宝石）"

S.NAMES.MUSHA_RABBITBACKPACK = "兔子背包"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_RABBITBACKPACK = "毛茸茸的，还有一对小翅膀。听说和某个计划有关。"

-- ============================================================
-- ★ 2026-09-29 职业重置石（测试道具，用户："不开放任何制作条件"）
--   · 合成栏里**没有配方** → 只能 c_give("musha_job_reset")
--   · 使用权限：作者 SteamID / 测试安全员 / 本地房主模式（scripts/musha_dev_mode.lua）
-- ============================================================
S.NAMES.MUSHA_JOB_RESET = "职业重置石"
S.ACTIONS.MUSHA_RESET_JOB = "重置职业"
S.CHARACTERS.GENERIC.DESCRIBE.MUSHA_JOB_RESET = "冷得像一张空白存档。摸一下，职业、等级、技能全归零——只有测试人员用得动它。"

-- ============================================================
-- ★ 2026-09-29 英文第二批：面板 UI 文案表（STRINGS.MUSHA_PANEL）
--   读取方：screens/musha_panel_screen.lua、screens/musha_tavern_screen.lua
--   机制：modmain 按本机 Profile 语言 modimport 本文件 → 每个客户端拿到自己的语言
--   ⚠️ english.lua 里有同一份 key 的英文表，两边 key 必须一一对应
--   ⚠️ 信箱兜底日志（musha_panel_screen.lua:169-183）按用户口径保持中文，不进本表
-- ============================================================
S.MUSHA_PANEL = {
    -- ---- 页签 / 页内标题 ----
    TITLE_HOME = "主页",
    TITLE_SKILL = "技能",
    TITLE_EQUIP = "装备",
    TITLE_MAIL = "信箱",
    TITLE_SET = "设置",
    TITLE_GIFT = "礼包",
    TITLE_DEX = "图鉴",
    DEX_TITLE = "图鉴",
    EQUIP_HEAD = "装备 · 属性",

    -- ---- 职业 / 通用 ----
    NO_JOB = "无职业",
    UNKNOWN_QUEST = "未知任务",
    BOOL_ON = "开",
    BOOL_OFF = "关",

    -- ---- 主页：经验条 ----
    EXP_FMT = "职业经验 %s/%s",

    -- ---- 主页：任务区空状态 ----
    EMPTY_TITLE = "暂无任务",
    EMPTY_HINT = "完成转职条件后开启任务",
    EMPTY_TAVERN_TITLE = "请去酒馆接受相关任务 》",
    EMPTY_TAVERN_HINT = "每日委托在酒馆接取 · 转职任务从酒馆取卷轴",
    EMPTY_NOJOB_TITLE = "暂无职业",
    EMPTY_NOJOB_HINT = "使用职业书开启职业之路",

    -- ---- 任务行 ----
    QUEST_DONE = "✓ 完成",
    NEED_FMT = "需要：%s（%s/%s）",
    REWARD_EXP_FMT = "奖励：职业经验 +%s",
    REWARD_HINT = "奖励：见任务完成提示",
    ADVANCE_FMT = "【转职%s/3】",
    QUEST_REQ_DEFAULT = "完成任务目标",
    ABANDON = "放弃",   -- ★ 09-29 任务详情子行右端按钮（点了把任务丢回酒馆）

    -- "需要什么"文案（ty = 服务端 QDEFS.type 同源 key）
    QUEST_REQ = {
        discover       = "前往发现目标",
        kill_spider    = "击杀蜘蛛",
        survive        = "存活天数",
        collect        = "收集噩梦燃料",
        collect_gems   = "收集三色宝石（红/绿/蓝）",
        craft          = "制造任意物品",
        cookpot        = "收获烹饪锅",
        kill_pig       = "击杀猪人",
        kill_firehound = "击杀火猎犬",
        heal_skill     = "使用回复技能",
        craft_science  = "制造科学机器",
    },

    -- 任务名（面板本地表；服务端也发 q.n，客户端优先用本表 → 语言跟人走）
    QUEST_NAMES = {
        [1]  = "见到龙蝇",
        [2]  = "击杀20只蜘蛛",
        [3]  = "存活5天",
        [4]  = "找到格罗姆",
        [5]  = "获得七个噩梦燃料",
        [6]  = "收集三色宝石",
        [7]  = "制造20个物品",
        [8]  = "收获五次烹饪锅",
        [9]  = "击败野猪x8",
        [10] = "击败五只火猎犬",
        [11] = "找到海象营地",
        [12] = "使用回复技能达到5次",
        [13] = "建造一个科学机器",
    },

    -- ---- 就职仪式提示（服务端只发 key + 职业 key 列表，客户端本地拼）----
    CEREMONY_HINT = "就职仪式：回酒馆右键完成",
    CEREMONY_CHOICE_FMT = "选定方向：用掉手里的徽记（%s）",

    -- ---- 技能页 ----
    SKILL_HEAD = "技能",
    SKILL_HEAD_FMT = "%s · 等级 %d · 可用技能点 %d",
    TAB_UNLEARNED = "未学习",
    TAB_LEARNED = "已学习",
    SKILL_LVL_FMT = "%s等级 %d / %d",
    LBL_CURRENT = "当前：",
    LBL_MAXED = "已满级",
    LBL_NEXT = "下一级：",
    LBL_AFTER = "学完后：",
    NEED_LEVEL_FMT = "需要 Lv.%d",
    NEED_BOOK_FMT = "需要 %d 本技能书解锁",
    NEED_SP_FMT = "消耗 %d 技能点",
    UNLOCK_HINT_FMT = "点这里（或 +）用背包里的技能书解锁 · 需要 %d 本",
    SKILL_FOOT = "技能书学习的技能 · 后续开放",
    BTN_UPGRADE = "加点",
    SKILL_EMPTY_NOJOB = "还没有职业",
    SKILL_EMPTY_NONE = "还没有学习任何技能",
    SKILL_EMPTY_ALL = "该职业的技能已全部学习",

    -- ---- 横排技能树（widgets/musha_skill_tree.lua）----
    TREE_HINT = "按住空白处左右拖动 · 滚动条两侧小箭头也行",
    BADGE_BOOK = "书",
    BADGE_LOCK = "锁",
    BADGE_MAX = "满",
    HL_NAME_FMT = "%s（%d/%d）",
    LBL_CURRENT_UNLEARNED = "当前：未学习",
    REQ_LEVEL_FMT = "角色等级 %d",
    REQ_BOOK_FMT = "%d 本技能书",
    REQ_SP_FMT = "%d 技能点",
    LBL_PREREQ = "前置：",
    LBL_PREREQ_SEP = "、",
    LBL_COND = "条件：",

    -- ---- 设置页 ----
    SET_MONSTER_SPAWN = "怪物生成",
    SET_SPAWN_MULT = "生成倍率",
    SET_DAILY_COUNT = "每日任务数",
    SET_EXP_MULT = "经验倍率",
    SET_DEBUG = "调试信息",
    SAVE_LOG = "保存日志",
    EDIT = "编辑",
    EDITING = "编辑中",

    -- ---- 礼包页 ----
    GIFT_HEAD = "礼包",
    GIFT_HINT_EVENT = "节日活动期间发放 · 有活动时礼包会出现在这里",
    GIFT_HINT_EMPTY = "当前没有可领取的礼包 · 节日活动期间会出现在这里",
    GIFT_HINT_DAY = "按游戏内天数开放 · 每个只能领一次",
    GIFT_HINT_EVENT2 = "活动礼包 · 每个只能领一次",
    GIFT_DAY_FMT = "第 %d 天可领（还差 %d 天）",
    GIFT_DEFAULT = "礼包",
    CLAIMED = "已领取",
    CLAIM = "领取",

    -- ---- 图鉴页 ----
    DEX_TIP = "（图鉴按上架顺序排列；新内容会陆续补进来）",
    DEX_SCOPE_WORLD = "世界",
    DEX_SCOPE_PERSONAL = "个人",

    -- ---- 酒馆委托板 ----
    TAVERN_TITLE = "酒馆委托",
    TAVERN_SUB = "点「接取」才开始计进度",
    TAVERN_HEAD_AVAIL = "可接委托",
    TAVERN_HEAD_ACT = "进行中",
    TAVERN_FOOT = "再右键酒馆或点 × 关闭",
    TAVERN_EMPTY_AVAIL = "今天的委托都接完了",
    TAVERN_EMPTY_ACT = "还没有接取的委托",
    TAVERN_MORE_FMT = "…还有 %d 个",
    QUEST_DEFAULT_FMT = "任务%s",
    ACCEPT = "接取",
    REWARD_ROW_FMT = "%s · 经验 +%s · %s/3",
    Q_COMMON = "普通",
    Q_WHITE = "白",
    Q_SILVER = "银",
    Q_GOLD = "金",
}
