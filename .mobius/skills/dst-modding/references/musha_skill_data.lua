-- ====================================
-- musha_skill_data.lua
-- 技能数据定义
-- 每个职业的技能列表、等级需求、最大等级、描述
-- ====================================

-- 技能 ID → 数据
-- skill_id = {
--   name = "显示名称",
--   desc = "描述",
--   icons = "图标文字占位（后续换贴图）",
--   levels = { max_lv, { lv1_desc, lv2_desc, ... } },  -- 每级描述
--   req_level = 1,  -- 角色等级需求（第一级解锁所需等级）
--   req_lv = { 1, 3, 5, 8, 12, 18 },  -- 每级对应的角色等级需求
--   max_level = 5,
-- }

-- === 战士基础技能 ===
MUSHA_SKILLS_WARRIOR = {
    -- 技能1：横扫
    slash = {
        name = "横扫",
        desc = "对前方扇形范围造成 {dmg}% 伤害",
        icon = "⚔",
        max_level = 5,
        req_level = 1,
        req_lv = { 1, 3, 5, 8, 12 },
        levels = {
            [1] = { dmg = 80 },
            [2] = { dmg = 95 },
            [3] = { dmg = 110 },
            [4] = { dmg = 130 },
            [5] = { dmg = 150 },
        },
    },
    -- 技能2：铁壁
    iron_wall = {
        name = "铁壁",
        desc = "获得 {armor}% 伤害减免，持续 {dur} 秒",
        icon = "🛡",
        max_level = 5,
        req_level = 3,
        req_lv = { 3, 6, 10, 15, 20 },
        levels = {
            [1] = { armor = 20, dur = 8 },
            [2] = { armor = 25, dur = 10 },
            [3] = { armor = 30, dur = 12 },
            [4] = { armor = 35, dur = 15 },
            [5] = { armor = 40, dur = 18 },
        },
    },
    -- 技能3：战吼
    war_cry = {
        name = "战吼",
        desc = "提升周围友方 {atk}% 攻击力，持续 {dur} 秒",
        icon = "📯",
        max_level = 5,
        req_level = 5,
        req_lv = { 5, 8, 12, 16, 20 },
        levels = {
            [1] = { atk = 10, dur = 10 },
            [2] = { atk = 13, dur = 12 },
            [3] = { atk = 16, dur = 15 },
            [4] = { atk = 20, dur = 18 },
            [5] = { atk = 25, dur = 20 },
        },
    },
    -- 技能4：旋风斩
    whirlwind = {
        name = "旋风斩",
        desc = "持续旋转攻击周围敌人，每击 {dmg}% 伤害，持续 {dur} 秒",
        icon = "🌀",
        max_level = 5,
        req_level = 8,
        req_lv = { 8, 12, 16, 20, 25 },
        levels = {
            [1] = { dmg = 60, dur = 5 },
            [2] = { dmg = 70, dur = 6 },
            [3] = { dmg = 80, dur = 7 },
            [4] = { dmg = 90, dur = 8 },
            [5] = { dmg = 100, dur = 10 },
        },
    },
}

-- === 法师基础技能 ===
MUSHA_SKILLS_MAGE = {
    -- 技能1：火球术
    fireball = {
        name = "火球术",
        desc = "发射火球造成 {dmg}% 魔法伤害，灼烧 {burn} 秒",
        icon = "🔥",
        max_level = 5,
        req_level = 1,
        req_lv = { 1, 3, 5, 8, 12 },
        levels = {
            [1] = { dmg = 90, burn = 3 },
            [2] = { dmg = 105, burn = 3 },
            [3] = { dmg = 120, burn = 4 },
            [4] = { dmg = 140, burn = 4 },
            [5] = { dmg = 160, burn = 5 },
        },
    },
    -- 技能2：寒冰护盾
    frost_shield = {
        name = "寒冰护盾",
        desc = "生成护盾吸收 {shield}% 伤害，减速攻击者 {slow}%",
        icon = "❄",
        max_level = 5,
        req_level = 3,
        req_lv = { 3, 6, 10, 15, 20 },
        levels = {
            [1] = { shield = 15, slow = 20 },
            [2] = { shield = 20, slow = 25 },
            [3] = { shield = 25, slow = 30 },
            [4] = { shield = 30, slow = 35 },
            [5] = { shield = 35, slow = 40 },
        },
    },
    -- 技能3：闪现
    blink = {
        name = "闪现",
        desc = "瞬间向前传送 {dist} 格，冷却 {cd} 秒",
        icon = "✨",
        max_level = 5,
        req_level = 5,
        req_lv = { 5, 8, 12, 16, 20 },
        levels = {
            [1] = { dist = 4, cd = 12 },
            [2] = { dist = 5, cd = 10 },
            [3] = { dist = 6, cd = 8 },
            [4] = { dist = 7, cd = 6 },
            [5] = { dist = 8, cd = 4 },
        },
    },
    -- 技能4：闪电链
    chain_lightning = {
        name = "闪电链",
        desc = "释放闪电链攻击 {targets} 个目标，每跳 {dmg}% 伤害",
        icon = "⚡",
        max_level = 5,
        req_level = 8,
        req_lv = { 8, 12, 16, 20, 25 },
        levels = {
            [1] = { dmg = 70, targets = 3 },
            [2] = { dmg = 80, targets = 3 },
            [3] = { dmg = 90, targets = 4 },
            [4] = { dmg = 100, targets = 4 },
            [5] = { dmg = 110, targets = 5 },
        },
    },
}

-- === 刺客基础技能 ===
MUSHA_SKILLS_ASSASSIN = {
    -- 技能1：背刺
    backstab = {
        name = "背刺",
        desc = "背后攻击造成 {dmg}% 伤害，暴击率 +{crit}%",
        icon = "🗡",
        max_level = 5,
        req_level = 1,
        req_lv = { 1, 3, 5, 8, 12 },
        levels = {
            [1] = { dmg = 150, crit = 10 },
            [2] = { dmg = 170, crit = 12 },
            [3] = { dmg = 190, crit = 15 },
            [4] = { dmg = 210, crit = 18 },
            [5] = { dmg = 250, crit = 20 },
        },
    },
    -- 技能2：潜行
    stealth = {
        name = "潜行",
        desc = "进入隐身状态 {dur} 秒，下次攻击必暴击",
        icon = "👤",
        max_level = 5,
        req_level = 3,
        req_lv = { 3, 6, 10, 15, 20 },
        levels = {
            [1] = { dur = 6 },
            [2] = { dur = 8 },
            [3] = { dur = 10 },
            [4] = { dur = 12 },
            [5] = { dur = 15 },
        },
    },
    -- 技能3：毒刃
    poison_blade = {
        name = "毒刃",
        desc = "攻击附加毒素，每秒 {dmg}% 伤害，持续 {dur} 秒",
        icon = "☠",
        max_level = 5,
        req_level = 5,
        req_lv = { 5, 8, 12, 16, 20 },
        levels = {
            [1] = { dmg = 15, dur = 5 },
            [2] = { dmg = 20, dur = 5 },
            [3] = { dmg = 25, dur = 6 },
            [4] = { dmg = 30, dur = 6 },
            [5] = { dmg = 35, dur = 7 },
        },
    },
    -- 技能4：暗影步
    shadow_step = {
        name = "暗影步",
        desc = "瞬间移动到目标背后，下3次攻击伤害 +{dmg}%",
        icon = "🌑",
        max_level = 5,
        req_level = 8,
        req_lv = { 8, 12, 16, 20, 25 },
        levels = {
            [1] = { dmg = 20 },
            [2] = { dmg = 30 },
            [3] = { dmg = 40 },
            [4] = { dmg = 50 },
            [5] = { dmg = 60 },
        },
    },
}

-- === 弓箭手基础技能 ===
MUSHA_SKILLS_RANGER = {
    -- 技能1：精准射击
    precision_shot = {
        name = "精准射击",
        desc = "远程伤害 +{dmg}%，射程 +{range}%",
        icon = "🏹",
        max_level = 5,
        req_level = 1,
        req_lv = { 1, 3, 5, 8, 12 },
        levels = {
            [1] = { dmg = 10, range = 5 },
            [2] = { dmg = 15, range = 8 },
            [3] = { dmg = 20, range = 10 },
            [4] = { dmg = 25, range = 12 },
            [5] = { dmg = 30, range = 15 },
        },
    },
    -- 技能2：箭雨
    arrow_rain = {
        name = "箭雨",
        desc = "对区域内的敌人造成 {dmg}% 伤害，持续 {dur} 秒",
        icon = "🌧",
        max_level = 5,
        req_level = 3,
        req_lv = { 3, 6, 10, 15, 20 },
        levels = {
            [1] = { dmg = 40, dur = 5 },
            [2] = { dmg = 50, dur = 5 },
            [3] = { dmg = 60, dur = 6 },
            [4] = { dmg = 70, dur = 6 },
            [5] = { dmg = 80, dur = 7 },
        },
    },
    -- 技能3：陷阱
    trap = {
        name = "陷阱",
        desc = "放置一个陷阱，踩中的敌人定身 {root} 秒并造成 {dmg}% 伤害",
        icon = "🪤",
        max_level = 5,
        req_level = 5,
        req_lv = { 5, 8, 12, 16, 20 },
        levels = {
            [1] = { dmg = 50, root = 2 },
            [2] = { dmg = 65, root = 3 },
            [3] = { dmg = 80, root = 3 },
            [4] = { dmg = 95, root = 4 },
            [5] = { dmg = 110, root = 4 },
        },
    },
    -- 技能4：鹰眼
    eagle_eye = {
        name = "鹰眼",
        desc = "开启鹰眼 {dur} 秒，暴击率 +{crit}%，暴击伤害 +{cridmg}%",
        icon = "🦅",
        max_level = 5,
        req_level = 8,
        req_lv = { 8, 12, 16, 20, 25 },
        levels = {
            [1] = { dur = 10, crit = 15, cridmg = 20 },
            [2] = { dur = 12, crit = 18, cridmg = 25 },
            [3] = { dur = 15, crit = 20, cridmg = 30 },
            [4] = { dur = 18, crit = 25, cridmg = 35 },
            [5] = { dur = 20, crit = 30, cridmg = 40 },
        },
    },
}
