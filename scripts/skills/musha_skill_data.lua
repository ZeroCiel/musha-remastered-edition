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
    ironwall = {
        name = "铁壁",
        desc = "受到伤害减少 {pct}%，持续 5 秒",
        icon = "🛡",
        max_level = 5,
        req_level = 3,
        req_lv = { 3, 5, 8, 12, 18 },
        levels = {
            [1] = { pct = 15 },
            [2] = { pct = 20 },
            [3] = { pct = 25 },
            [4] = { pct = 30 },
            [5] = { pct = 40 },
        },
    },
    -- 技能3：战吼
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
    -- 技能4：旋风斩
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
    -- 技能5：狂暴
    berserk = {
        name = "狂暴",
        desc = "攻击速度提升 {spd}%，持续 6 秒",
        icon = "🔥",
        max_level = 3,
        req_level = 12,
        req_lv = { 12, 16, 20 },
        levels = {
            [1] = { spd = 20 },
            [2] = { spd = 35 },
            [3] = { spd = 50 },
        },
    },
}

-- TODO: 其他职业技能数据
-- MUSHA_SKILLS_MAGE = { ... }
-- MUSHA_SKILLS_RANGER = { ... }
-- MUSHA_SKILLS_ASSASSIN = { ... }

-- 职业 ID → 技能数据表映射
MUSHA_SKILL_MAP = {
    [MUSHA_JOB.WARRIOR] = MUSHA_SKILLS_WARRIOR,
    -- [MUSHA_JOB.MAGE] = MUSHA_SKILLS_MAGE,
    -- [MUSHA_JOB.RANGER] = MUSHA_SKILLS_RANGER,
    -- [MUSHA_JOB.ASSASSIN] = MUSHA_SKILLS_ASSASSIN,
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
