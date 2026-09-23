-- ================================================================
-- 技能图标清单（唯一真源）—— 2026-09-19
--
-- 用户给齐的 128x128 技能图标已铺在 `images/skill_icons/<id>.png`：
--   combat_recovery / weapon_proficiency / slash_qi / last_stand / iron_will / life_leech
--
-- 用法（跟 scripts/musha_nav_icons.lua 一套）：
--   · modmain 读本清单 → 转好 tex/xml 的那张才注册进 Assets
--   · 已注册的 id 会挂到 TUNING.MUSHA_SKILL_ICONS，UI 只给这些画图标、其余退回占位
--   · 没转 tex 的那张**不注册**（不会崩），日志里会打印"N / 6 张"
--
-- ⚠️ png 文件名必须 ASCII（中文名转出来的 xml 是空的）
-- ⚠️ 转完 tex/xml 必须重启游戏（assets 只在开游戏时加载一次）
-- ⚠️ 图标路径约定：images/skill_icons/<id>.xml + .tex，元素名 = <id>.tex
-- ================================================================
return {
    "combat_recovery",      -- 战斗恢复（战士）
    "weapon_proficiency",   -- 武器精通（战士）
    "slash_qi",             -- 剑气斩（剑士）
    "last_stand",           -- 我，活着（剑士）
    "iron_will",            -- 钢铁意志（近卫）
    "life_leech",           -- 生命偷取（近卫）
}
