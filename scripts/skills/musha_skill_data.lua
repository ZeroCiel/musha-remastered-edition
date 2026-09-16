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

-- ⚠️ 本文件是**数据草案/备份区**：只被 modimport 加载，没有任何代码消费（不显示、不生效）。
--    正式技能规则（2026-09-13 二次修订）：每职业正式 = 1 主动技 + 1 武器技能，其余全部备份。
--    战士基调 = 走A（走位+平A）为主，不靠技能。

-- === 战士基础技能（⚠️ 以下 横扫/战吼/旋风斩 全部为「备份」，不实现、不上技能页） ===
MUSHA_SKILLS_WARRIOR = {
    -- 技能1：横扫  ✗【备份】2026-09-13 用户：有待考虑，或看赞助
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
    -- ✗ 铁壁 ironwall 已被用户删除（2026-09-12：与近卫的"钢铁意志"重复，都是减伤）
    -- 技能3：战吼  ✗【备份】2026-09-13 无正式排期
    war_cry = {
        name = "战吼",
        desc = "提升全队 {pct}% 攻击力，持续 8 秒",
        icon = "💥",
        max_level = 3,
        req_level = 5,
        req_lv = { 5, 10, 16 },
        levels = {
            [1] = { pct = 10 },
            [2] = { pct = 15 },
            [3] = { pct = 20 },
        },
    },
    -- 技能4：旋风斩  ✗【备份】2026-09-13 用户：极难做（不做）
    whirlwind = {
        name = "旋风斩",
        desc = "对周围敌人造成 {dmg}% 连续伤害",
        icon = "🌀",
        max_level = 3,
        req_level = 8,
        req_lv = { 8, 14, 20 },
        levels = {
            [1] = { dmg = 60 },
            [2] = { dmg = 80 },
            [3] = { dmg = 100 },
        },
    },
    -- 技能4：剑气斩（2026-09-12 用户：月牙飞出去、命中就有伤害；原定是"冲击波"）
    --   ★ 表现：挥出一枚月牙形剑气向前飞，命中即结算伤害（月牙素材待选，见状态卡的"月牙特效候选"）
    --   ★ 2026-09-14 用户定：加点门槛 = 角色 3 / 7 / 12 级（共 3 级）
    --                    每次施放消耗能量 = 18 / 16 / 14（等级越高越省）
    --                    改动的实现口在 scripts/musha_weapon_skill.lua 的 COST_BY_LEVEL
    slash_qi = {
        name = "剑气斩",
        desc = "向前挥出月牙剑气，命中造成 {dmg}% 伤害（消耗 {mp} 点能量）",
        icon = "🌙",
        max_level = 3,
        req_level = 3,
        req_lv = { 3, 7, 12 },
        cd = 6,             -- 冷却秒数（= musha_weapon_skill.lua 的 COOLDOWN，武器 rechargeable 走这个）
        levels = {
            [1] = { dmg = 100, mp = 18 },
            [2] = { dmg = 130, mp = 16 },
            [3] = { dmg = 160, mp = 14 },
        },
    },
    -- ✗ 狂暴 berserk 已被用户删除（"我记得没设计这个"，2026-09-12）
}

-- TODO: 其他职业技能数据
-- MUSHA_SKILLS_MAGE = { ... }
-- MUSHA_SKILLS_RANGER = { ... }
-- MUSHA_SKILLS_ASSASSIN = { ... }

-- === 刺客技能 ===
MUSHA_SKILLS_ASSASSIN = {
    backstab = {
        name = "背刺",
        desc = "从背后攻击造成 {mult} 倍伤害",
        icon = "🗡",
        max_level = 2,
        req_level = 1,
        req_lv = { 1, 5 },
        cost = { 2, 4 },
        levels = {
            [1] = { mult = "2" },
            [2] = { mult = "3" },
        },
    },
}

-- 职业 ID → 技能数据表映射
MUSHA_SKILL_MAP = {
    [MUSHA_JOB.WARRIOR] = MUSHA_SKILLS_WARRIOR,
    -- [MUSHA_JOB.MAGE] = MUSHA_SKILLS_MAGE,
    -- [MUSHA_JOB.RANGER] = MUSHA_SKILLS_RANGER,
    [MUSHA_JOB.ASSASSIN] = MUSHA_SKILLS_ASSASSIN,
}

-- 根据技能 ID 和等级生成描述文本
function GetSkillDescription(skill_id, level)
    for _, skill_set in pairs(MUSHA_SKILL_MAP) do
        local skill = skill_set[skill_id]
        if skill then
            local lv_data = skill.levels[level]
            if lv_data then
                local desc = skill.desc
                for k, v in pairs(lv_data) do
                    desc = desc:gsub("{" .. k .. "}", tostring(v))
                end
                return desc
            end
            return skill.desc
        end
    end
    return "未知技能"
end

-- 获取职业的技能列表（有序）
function GetJobSkillList(job_id)
    local skills = MUSHA_SKILL_MAP[job_id]
    if not skills then return {} end
    local list = {}
    for id, data in pairs(skills) do
        table.insert(list, { id = id, data = data })
    end
    table.sort(list, function(a, b)
        if a.data.req_level ~= b.data.req_level then
            return a.data.req_level < b.data.req_level
        end
        return a.id < b.id
    end)
    return list
end
