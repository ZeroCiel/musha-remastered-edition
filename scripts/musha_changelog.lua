-- ====================================
-- musha_changelog.lua
-- 信箱页（更新日志）内容源
-- 读取方：scripts/screens/musha_panel_screen.lua → pcall(require, "musha_changelog")
--
-- 格式：数组表，**倒序**（最新在最上面）
--   { ver = "版本号", date = "日期", lines = { "正文1", ... }, lines_en = { "EN1", ... } }
--   ★ 2026-09-28 用户「英文全做」→ 每条加 lines_en（英文）；面板按 TUNING.MUSHA_UI_LANG 挑：
--     非 zh 且有 lines_en → 用英文，否则退回中文（ko/ru/jp 也走英文，和导航横幅 :2442 同口径）
--     中英**行数保持一致**（每页渲染按行数走，行数不齐会下沿错位）
-- 每页显示几条：由面板里的 MAIL_PER_PAGE 决定（现在是 2；09-25 信箱界限配套，3 条/页会整条出界）
-- ====================================

return {
    {
        ver = "0.7.13",
        date = "2026-09-28",
        lines = {
            "★ 酒馆委托板换上底图：木框花边框，接任务的界面有底了。",
            "★ 每日委托改规则：同一任务最多 3 人同时接取，各自记各自进度，互不共享。",
            "★ 主页改版：分上下两框（职业经验 / 任务区），没有任务时提示去酒馆接取；任务列表的滚动条竖轨不再显示（滚轮照常滚）。",
            "英文酒馆名统一改为直译 Hotel（建筑名 / 右键动作 / 描述 / 英文更新日志）；任务调试日志已关闭。",
            "★ 元素精灵登场：青白色光灵由光点汇聚成形，飘在你身边、夜里发光；新手期会冒字打招呼并引导职业。",
        },
        lines_en = {
            "★ The hotel commission board now has a background: the wooden flower frame on the accept-quest UI.",
            "★ New commission rule: the same quest can be accepted by up to 3 players at once — each tracks their own progress, never shared.",
            "★ Home page revamp: split into two frames (class EXP / quest area), an empty quest list now points you to the hotel; the quest list's scrollbar track is hidden (wheel scrolling unchanged).",
            "The English hotel name is now the literal \"Hotel\" (name / right-click action / description / EN changelog); quest debug logging is off.",
            "★ The Element Fairy arrives: a moonlit blue-white wisp gathers from sparks, floats at your side and glows at night; in your first steps it greets you with speech bubbles and guides you toward a class.",
        },
    },

    {
        ver = "0.7.12",          -- ★ 09-28 用户：本条 0.7.11 → **0.7.12**（合并远端精灵条目；0.7.12 之后才准叫 0.8.0）
        date = "2026-09-28",
        lines = {
            "★ 酒馆（转职祭坛）换新装：全新酒馆外观落地可见，修复建筑巨型 / 隐形问题，制作栏图标同步更新。",
            "★ 技能书新皮：「Don't Stare」封面 + 补上掉落时的地面动画（之前掉在地上看不见）。",
            "★ 面板换新底图（主页 + 技能页通用，自带内纸边）：移除旧的代码金框，不再双重框。",
            "面板微调：天使荷包角度调整、经验条拉长 30%、右上角叉号右移 25 像素。",
            "★ 酒馆新增「委托板」：右键酒馆打开，挂在屏幕右侧（不盖住你的容器）；每日委托点「接取」后才进「进行中」，品质分 普通 / 白 / 银 / 金 四档。",
            "★ 回城石绑定加固：绑定信息随存档保存，读档时校验目标身份，对不上宁可判定「不在了」，不再传错位置。",
            "技能页微调：横排技能树定位到页面左上、点节点不再左右跳动；「加点」换成粉红方块按钮；空状态提示字按需隐藏（任务列表保留）。",
            "修复：近卫职业书名字缺失、musha 恢复原版皮肤（v2 误打包回退）、背包补齐传送 / 重生姿势贴图。",
            "经费不足，延误出场。",
        },
        lines_en = {
            "★ The hotel (class-change altar) got a new look: the new exterior is visible now; fixed the giant / invisible building; crafting icon updated.",
            "★ Skillbook reskin: the \"Don't Stare\" cover, plus the ground animation it was missing when dropped (it used to be invisible on the ground).",
            "★ New panel background (Home + Skills share it, inner paper edge built in): the old code-drawn gold frame is gone — no more double frames.",
            "Panel tweaks: angel purse angle adjusted, EXP bar 30% longer, close button moved 25 px right.",
            "★ New hotel \"Commission Board\": right-click the hotel to open it, docked on the right edge (never covers your containers); a daily commission only moves to \"In Progress\" once accepted — four tiers: Common / White / Silver / Gold.",
            "★ Hardened Return Stone binding: the binding is saved with the world and re-checked on load; if the target no longer matches it counts as \"gone\" instead of sending you to the wrong place.",
            "Skills page tweaks: the horizontal skill tree is anchored to the top-left and no longer jumps when you click a node; the point button is now a pink square; empty-state hints hide as needed (the quest list keeps its own).",
            "Fixes: missing Guardian class-book name, Musha back on the original skin (reverted a wrong v2 package), inventory art for teleport / respawn poses completed.",
            "Out of budget — debut postponed.",
        },
    },

    {
        -- ★ 09-27 用户：两条「0.7.9半」合并成一条 = 0.7.10（09-21 里跟 09-24 重复的
        --   「回城石」「邮包系统」两条并入主打行，只留 09-21 独有的 5 行）
        ver = "0.7.10",
        date = "2026-09-24",
        lines = {
            "★ 主打「回城石」：任意目标右键绑定（建筑 / 生物 / 玩家 / 树都行，可换绑），背包右键一键回家。",
            "　　3 次 · 冷却 360 秒 · 会动的目标就跟到哪 · 用完石头消失、目标没了不耗次数。",
            "★ 主打「信箱 + 信差包」：开局自带信差包，关包自动寄回自己的信箱，回家靠近自动入库。",
            "　　寄件 / 取件走面板「信箱」页；初始 3 格，背包带「邮包升级套件 I~IV」右键信箱逐档扩容。",
            "导航整体搬到左侧：木牌标题条加大 20%、间距收紧 1/3；修复右上角红叉关不掉面板。",
            "赞助入口上线：荷包挂在天使裙上（愿者上钩）；导航横幅适配英 / 俄 / 日 / 韩界面。",
            "面板技能页改版：新增「横排技能树」（可左右拖动、滚轮、两侧箭头），右上可切回竖排列表。",
            "技能说明改成光标悬停整行才高亮显示（不再直接写在卡片里）。",
            "适配 Too Many Items：物品图标图集全局登记 → TMI 里能看到 Musha 物品的图标。",
            "图鉴页补全：道具 / 职业书 / 技能书 / 建筑 全部条目。",
            "本版为半版本：UI、角色动画、美术仍在制作中。",
        },
        lines_en = {
            "★ Headliner \"Return Stone\": right-click any target to bind it (building / creature / player / tree — rebindable), right-click it in your inventory to go home in one press.",
            "     3 charges · 360 s cooldown · it follows moving targets · the stone disappears when charges run out, and a lost target costs no charge.",
            "★ Headliner \"Mailbox + Messenger Bag\": you start with the bag; closing it mails things back to your own mailbox, and getting home near the box banks them automatically.",
            "     Send / collect on the panel's Mailbox page; 3 slots to start, right-click the mailbox with a \"Package Upgrade Kit I-IV\" in your inventory to expand it tier by tier.",
            "Navigation moved to the left: the wooden sign title bar is 20% bigger and spacing tightened by a third; fixed the top-right close button not closing the panel.",
            "Sponsor entry online: the purse hangs on the angel's dress (willing contributors only); nav banners now fit EN / RU / JA / KR interfaces.",
            "Skills page reworked: new \"horizontal skill tree\" (drag, mouse wheel, side arrows); switch back to the vertical list at the top right.",
            "Skill descriptions now highlight only when you hover the whole row (no longer printed inside the card).",
            "Too Many Items support: item icon atlases are registered globally, so Musha items show their icons inside TMI.",
            "Gallery page completed: every entry for items / class books / skillbooks / buildings.",
            "Half release: UI, character animation and art are still in progress.",
        },
    },
    {
        ver = "0.7.9",
        date = "2026-09-17",
        lines = {
            "酒馆改版：坛内取出「转职卷轴」→ 展开才接取转职任务；3 轮考验后回酒馆完成就职仪式。",
            "二转赠礼改为本职业「技能书」（剑士技能书内含剑气斩）；新增通用「技能卷轴」（可制作/可掉落）。",
            "新美术：战士职业书、剑士技能书、转职卷轴。",
            "生命树枝手持显示修复（地上/手上合成一包）并调整大小。",
            "修复：就职仪式发赠礼崩溃、第 3 轮完成没面板提示、酒馆空坛不解释；移除空转的「生命恢复」设置。",
        },
        lines_en = {
            "Hotel rework: take the \"Class Scroll\" out of the jar → unroll it to accept the class quest; finish 3 rounds of trials and come back for the investiture.",
            "The second-change gift is now your class \"skillbook\" (the Swordsman book contains Slash Qi); added a generic \"Skill Scroll\" (craftable / droppable).",
            "New art: Warrior class book, Swordsman skillbook, class scroll.",
            "Fixed Life Branch in-hand rendering (it merged into one bundle on ground / in hand) and resized it.",
            "Fixes: crash when the investiture granted the gift, no panel notice after round 3, unexplained empty jar; removed the dead \"Life Recovery\" setting.",
        },
    },
    {
        ver = "0.7.7",
        date = "2026-09-16",
        lines = {
            "新增武器技能「剑气斩」：剑士专属，右键瞄准、点地释放（月牙改用 8 方向光斩）。",
            "新增礼包系统：游戏时间礼包 + 节日礼包；面板新增「礼包」页（「装备」页暂时收起）。",
            "新增「生命树枝」道具（装备时每秒回 0.2 生命、每 24 秒 +0.1 精神）；便签新增“地上/手中”形态（一卷系绳的纸）。",
            "一转职业书在转职完成后消耗；二转不再额外补发技能书。",
            "修复：剑气斩会穿过敌人；转职任务「存活5天」进度不增长。",
        },
        lines_en = {
            "New weapon skill \"Slash Qi\": Swordsman-only — right-click to aim, click the ground to release (the crescent now uses an 8-direction light slash).",
            "New gift system: playtime gift pack + holiday gift pack; a new \"Gift Pack\" panel page (the Equipment page is stowed for now).",
            "New item \"Life Branch\" (+0.2 health per second while equipped, +0.1 sanity every 24 s); the note gets \"ground / in-hand\" forms (a tied scroll of paper).",
            "The first-change class book is consumed once the job changes; no extra skillbook is granted on the second change.",
            "Fixes: Slash Qi could pass through enemies; the \"Survive 5 days\" class quest did not progress.",
        },
    },
    {
        ver = "0.7.6",
        date = "2026-09-10",
        lines = {
            "Musha 系统 0.7.6 正式上线。",
            "职业面板改为多页书：主页 / 技能 / 信箱 / 设置 / 图鉴。",
            "新增局内设置：怪物生成、任务数量、经验倍率、生命与能量恢复。",
            "任务系统：每日自动发放 + 雕像接单的转职任务。",
        },
        lines_en = {
            "Musha system 0.7.6 is live.",
            "The class panel becomes a multi-page book: Home / Skills / Mailbox / Settings / Gallery.",
            "New in-game settings: monster spawning, quest count, XP multiplier, health and energy regen.",
            "Quest system: dailies issued automatically, plus class quests taken from the statue.",
        },
    },
    {
        ver = "0.7.5",
        date = "2026-09-09",
        lines = {
            "任务系统重构：每日自动发放 + 雕像接单轮转职任务。",
            "修复面板不显示（补回 AddReplicableComponent）。",
            "修复滚轮误关面板。",
        },
        lines_en = {
            "Quest system rebuilt: automatic dailies plus rotating statue-offered class quests.",
            "Fixed the panel not showing (AddReplicableComponent restored).",
            "Fixed the mouse wheel accidentally closing the panel.",
        },
    },
    {
        ver = "0.7.4",
        date = "2026-09-08",
        lines = {
            "面板从 HUD Widget 改为真 Screen + ScrollingGrid。",
            "滚动条外观定制（轨道 / 握把）。",
        },
        lines_en = {
            "The panel moved from an HUD widget to a real Screen + ScrollingGrid.",
            "Custom scrollbar look (track / grip).",
        },
    },
    {
        ver = "0.7.3",
        date = "2026-09-05",
        lines = {
            "进阶任务改为雕像接取（单轮 3 轮制）。",
        },
        lines_en = {
            "Advanced quests are now taken from the statue (3 rounds per cycle).",
        },
    },
}
