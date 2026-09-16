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
-- ====================================

return {
    {
        name = "生命树枝",
        tag = "武器",
        icon_atlas = "images/inventoryimages/musha_lifebranch.xml",
        icon_tex   = "musha_lifebranch.tex",
        lines = {
            "攻击 12（可升级，满级 18~24）",
            "装备时：每秒恢复 0.2 生命、每 24 秒 +0.1 精神",
            "来源：游戏内第 10 天 · 面板「礼包」页领取",
        },
    },
    {
        name = "剑",
        tag = "武器",
        icon_atlas = "images/inventoryimages/musha_sword.xml",
        icon_tex   = "musha_sword.tex",
        lines = {
            "攻击 42 · 近战范围 0.8（剑士武器技能：剑气斩）",
            "右键点地放「剑气斩」：伤害 ×1.00/1.30/1.60 · 冷却 12/9/7.6 秒（按技能等级）· 耗能 18",
            "技能页加点学会（3 级解锁，7 / 12 级可升级 → 耗能降 16 / 14）",
        },
    },
}
