-- ====================================
-- musha_dex.lua
-- 图鉴页（面板「图鉴」→ dex）内容源
-- 读取方：scripts/screens/musha_panel_screen.lua → pcall(require, "musha_dex")
--
-- 格式：数组表（**正序**，谁先上架谁在上面）
--   {
--     name       = "条目名",                              -- 卡片顶部大字
--     tag        = "类别",                                -- 右上角小字
--     icon_atlas = "images/inventoryimages/<名>.xml",     -- 2026-09-16 新增：卡片左侧图标
--     icon_tex   = "<名>.tex",                            --   不写这两项 → 该条不显示图标（不报错）
--     lines      = { "说明行1", "说明行2", "说明行3" },     -- 最多 3 行，多了被裁
--   }
-- 图标直接复用装备自己的库存图集（跟背包里那张是同一份文件 → 不会出现"图鉴和实物长得不一样"）
-- 图标要真在游戏里显示，得先有 images/inventoryimages/<名>.png + .tex + .xml（tex 必须用 DST Mod Tool 转）
-- 单行别太长：卡片宽 840，图标占 ~110，剩下 ~670 px（字号 24）
--
-- ★ 2026-09-21 用户口径「A 全部」：把现有道具/建筑/系统**全部**列进来（原来只有 2 条）
--
-- ★ 2026-09-29 英文第二批：图鉴条目是**内容数据**（不是 UI 标签）→ 沿用 changelog 的
--   lines_en 同一约定，加 name_en / tag_en / lines_en 三字段；面板按本机语言挑一份
--   （musha_panel_screen.lua dex_apply 里的 PickLang / UIIsEN）。
--   英译长度受限：标题 ≤21 字符（标题条 302px / 字号 30）、说明行 ≤50 字符（590px / 字号 24）
--   —— DST 的 Text 不裁剪，超长会溢出卡片。
-- ====================================

return {
    -- ── 武器 / 装备
    {
        name = "生命树枝",  name_en = "Life Branch",
        tag = "武器",       tag_en  = "Weapon",
        icon_atlas = "images/inventoryimages/musha_lifebranch.xml",
        icon_tex   = "musha_lifebranch.tex",
        lines = {
            "攻击 12（可升级，满级 18~24）",
            "装备时：每秒恢复 0.2 生命、每 24 秒 +0.1 精神",
            "来源：游戏内第 10 天 · 面板「礼包」页领取",
        },
        lines_en = {
            "Dmg 12 (upgradable, up to 18-24)",
            "While held: +0.2 HP/s, +0.1 sanity/24s",
            "Source: in-game day 10 · Panel > Gift",
        },
    },
    {
        name = "剑",        name_en = "Sword",
        tag = "武器",       tag_en  = "Weapon",
        icon_atlas = "images/inventoryimages/musha_sword.xml",
        icon_tex   = "musha_sword.tex",
        lines = {
            "攻击 42 · 近战范围 0.8（剑士武器技能：剑气斩）",
            "右键点地放「剑气斩」：伤害 ×1.00/1.30/1.60 · 冷却 12/9/7.6 秒（按技能等级）· 耗能 18",
            "技能页加点学会（3 级解锁，7 / 12 级可升级 → 耗能降 16 / 14）",
        },
        lines_en = {
            "Dmg 42 · Range 0.8 (Saber skill: Slash Qi)",
            "Slash Qi: x1.0/1.3/1.6 dmg · CD 12/9/7.6s",
            "Learned on Skills page (Lv3; upg. Lv7/12)",
        },
    },

    -- ── 道具
    {
        name = "回城石",    name_en = "Recall Stone",
        tag = "道具",       tag_en  = "Item",
        icon_atlas = "images/inventoryimages/musha_recall_stone.xml",
        icon_tex   = "musha_recall_stone.tex",
        lines = {
            "对任何东西右键 → 绑定它（建筑 / 生物 / 玩家 / 树都行；可换绑）",
            "背包里右键 → 传送回绑定的那个东西旁边（目标会动就跟到当前位置）",
            "可用 3 次 · 冷却 360 秒 · 第 3 次用完石头消失 · 目标没了则不消耗次数",
        },
        lines_en = {
            "Right-click anything to bind (re-bindable)",
            "Right-click in bag: teleport to that target",
            "3 uses · CD 360s · gone after the 3rd use",
        },
    },
    {
        name = "技能卷轴",  name_en = "Skill Scroll",
        tag = "道具",       tag_en  = "Item",
        icon_atlas = "images/inventoryimages/musha_skill_scroll.xml",
        icon_tex   = "musha_skill_scroll.tex",
        lines = {
            "用来解锁技能页上带「书」标记的技能（这些技能不吃技能点）",
            "可制作、也可掉落",
            "面板技能页：点「锁」或「+」都能用背包里的技能卷轴解锁",
        },
        lines_en = {
            "Unlocks skills marked Bk (they cost no SP)",
            "Craftable and droppable",
            "Skills page: click the lock or + to use it",
        },
    },
    {
        name = "便签",      name_en = "Note",
        tag = "道具",       tag_en  = "Item",
        icon_atlas = "images/inventoryimages/musha_note.xml",
        icon_tex   = "musha_note.tex",
        lines = {
            "开局自带；写着当前该干什么",
            "地上是一卷系绳的纸，拿在手里是展开的便签",
        },
        lines_en = {
            "Given at start; tells you what to do now",
            "Rolled on the ground, opened in your hand",
        },
    },

    -- ── 职业书 / 技能书
    {
        name = "战士职业书", name_en = "Warrior Job Book",
        tag = "职业书",     tag_en  = "Job Book",
        icon_atlas = "images/inventoryimages/musha_jobbook_warrior.xml",
        icon_tex   = "musha_jobbook_warrior.tex",
        lines = {
            "一转职业书：在酒馆完成就职仪式用",
            "转职完成后消耗",
        },
        lines_en = {
            "1st-change job book: used at the hotel",
            "Consumed when the change completes",
        },
    },
    {
        name = "法师职业书", name_en = "Mage Job Book",
        tag = "职业书",     tag_en  = "Job Book",
        icon_atlas = "images/inventoryimages/musha_jobbook_mage.xml",
        icon_tex   = "musha_jobbook_mage.tex",
        lines = { "一转职业书：在酒馆完成就职仪式用", "转职完成后消耗" },
        lines_en = { "1st-change job book: used at the hotel", "Consumed when the change completes" },
    },
    {
        name = "游侠职业书", name_en = "Ranger Job Book",
        tag = "职业书",     tag_en  = "Job Book",
        icon_atlas = "images/inventoryimages/musha_jobbook_ranger.xml",
        icon_tex   = "musha_jobbook_ranger.tex",
        lines = { "一转职业书：在酒馆完成就职仪式用", "转职完成后消耗" },
        lines_en = { "1st-change job book: used at the hotel", "Consumed when the change completes" },
    },
    {
        name = "潜行者职业书", name_en = "Rogue Job Book",
        tag = "职业书",     tag_en  = "Job Book",
        icon_atlas = "images/inventoryimages/musha_jobbook_rogue.xml",
        icon_tex   = "musha_jobbook_rogue.tex",
        lines = { "一转职业书：在酒馆完成就职仪式用", "转职完成后消耗" },
        lines_en = { "1st-change job book: used at the hotel", "Consumed when the change completes" },
    },
    {
        name = "技能书",    name_en = "Skillbook",
        tag = "技能书",     tag_en  = "Skillbook",
        icon_atlas = "images/inventoryimages/musha_skillbook.xml",
        icon_tex   = "musha_skillbook.tex",
        lines = {
            "二转赠礼：按本职业发一本",
            "给技能页上带「书」标记的技能当解锁材料",
        },
        lines_en = {
            "2nd-change gift: one per job",
            "Unlocks skills marked Bk on Skills page",
        },
    },
    {
        name = "剑士技能书", name_en = "Saber Skillbook",
        tag = "技能书",     tag_en  = "Skillbook",
        icon_atlas = "images/inventoryimages/musha_skillbook_saber.xml",
        icon_tex   = "musha_skillbook_saber.tex",
        lines = {
            "剑士二转赠礼",
            "内含武器技能「剑气斩」",
        },
        lines_en = {
            "Saber 2nd-change gift",
            "Holds the weapon skill Slash Qi",
        },
    },

    -- ── 建筑 / 容器
    {
        name = "酒馆",      name_en = "Hotel",
        tag = "建筑",       tag_en  = "Structure",
        icon_atlas = "images/inventoryimages/musha_advance_altar.xml",
        icon_tex   = "musha_advance_altar.tex",
        lines = {
            "合成：石块 12 + 木头 8 + 金块 6 + 硝石 2（科学机器解锁）",
            "坛内取出「转职卷轴」→ 展开才接取转职任务；3 轮考验后回酒馆完成就职仪式",
            "只有 Musha 能造",
        },
        lines_en = {
            "Science Machine: 12 rock, 8 log, 6 gold, 2 nitre",
            "Take the Job Change Scroll out, unroll to accept",
            "Only Musha can craft it",
        },
    },
    {
        name = "转职卷轴",  name_en = "Job Change Scroll",
        tag = "道具",       tag_en  = "Item",
        icon_atlas = "images/inventoryimages/musha_advance_scroll.xml",
        icon_tex   = "musha_advance_scroll.tex",
        lines = {
            "来源：酒馆里取出来",
            "展开 → 接取转职任务（3 轮考验）",
            "做完回酒馆完成就职仪式",
        },
        lines_en = {
            "Source: take it out of the hotel",
            "Unroll: accept the change quest (3 rounds)",
            "When done, return for the ceremony",
        },
    },
    {
        name = "信箱",      name_en = "Mailbox",
        tag = "建筑 · 容器", tag_en = "Structure · Container",
        icon_atlas = "images/inventoryimages/musha_mailbox.xml",
        icon_tex   = "musha_mailbox.tex",
        lines = {
            "合成：木板 4 + 草 8 + 金块 2（科学机器解锁）· 只有 Musha 能造",
            "初始 3 格（4 列 × 3 行 = 12 格上限）；背包带「邮包升级套件」右键信箱逐档扩容",
            "用来收／发邮包（信差包送东西）",
        },
        lines_en = {
            "Craft: 4 boards, 8 cutgrass, 2 gold · Musha only",
            "Starts at 3 slots (12 max) · grows with a kit",
            "Send and receive mail (via the mail bag)",
        },
    },
    {
        name = "信差包",    name_en = "Mail Bag",
        tag = "容器",       tag_en  = "Container",
        icon_atlas = "images/inventoryimages/musha_mailbag.xml",
        icon_tex   = "musha_mailbag.tex",
        lines = {
            "开局自带一只（只有新开的档给，跨世界不给）",
            "合成：草 8 + 木板 2 + 蜘蛛丝 2（科学机器解锁，谁都能做）",
            "和信箱配合寄东西（寄件 / 取件走面板「信箱」页）",
        },
        lines_en = {
            "One given at start (new saves only)",
            "Craft: 8 cutgrass, 2 boards, 2 silk",
            "Pairs with the mailbox (use the Mail page)",
        },
    },
    {
        name = "邮包升级套件", name_en = "Mailbag Upgrade Kit",
        tag = "道具",       tag_en  = "Item",
        lines = {
            "背包带着对应档的套件右键信箱 → 扩容（动作从「摸」变「升级」）",
            "扩容链 3 → 5 → 7 → 9 → 12 格；前 3 件各 +2，IV 那件 +3 —— 为什么？摸摸头皮",
            "配方：木板 5 / 10 / 20（科学机器）· 套件 IV = 木板 20 + 红宝石 2（炼金引擎）",
        },
        lines_en = {
            "Hold a kit and right-click the mailbox to upgrade",
            "Slots 3 > 5 > 7 > 9 > 12 (+2 each, IV +3)",
            "Cost: 5/10/20 boards · IV = 20 boards + 2 rubies",
        },
    },
}
