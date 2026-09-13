-- ====================================
-- musha_world_settings.lua
-- 世界级"局内设置"（服务端权威，随世界存档走）
-- 挂载：TheWorld（modmain 里 AddPrefabPostInit("world"/"forest"/"cave") 惰性补挂）
-- 同步：不自己发网络包 —— 值由 musha_profession_component:PushSettings()
--       塞进 userdata 的**副本**一起推给客户端（不动存档里的 userdata）
-- ====================================

-- 设置项定义（服务端校验用；客户端面板有自己的显示表，两边改动要同步）
local SPEC = {
    -- 怪物生成（P5 才接线，现在只存值）
    monster_spawn_enabled = { default = true, kind = "bool" },
    monster_spawn_mult    = { default = 1,    kind = "choice", choices = { 0, 0.5, 1, 2, 3 } },

    -- 每日任务发放数
    daily_quest_count     = { default = 4,    kind = "number", min = 1, max = 10, step = 1 },

    -- 经验倍率
    exp_mult              = { default = 1,    kind = "choice", choices = { 0.5, 1, 2, 3 } },
}

local Musha_World_Settings = Class(function(self, inst)
    self.inst = inst
    self.values = {}
    for k, s in pairs(SPEC) do
        self.values[k] = s.default
    end
end)

-- 供外部读取定义
Musha_World_Settings.SPEC = SPEC

-- 取一项；key 为 nil 时返回全部值的副本
function Musha_World_Settings:Get(key)
    if key == nil then
        local out = {}
        for k in pairs(SPEC) do
            out[k] = self.values[k]
        end
        return out
    end
    local v = self.values[key]
    if v == nil then
        local s = SPEC[key]
        v = s and s.default
    end
    return v
end

-- 改一项（带类型/范围校验），成功返回 true；失败返回 false, 原因
function Musha_World_Settings:Set(key, value)
    local s = SPEC[key]
    if s == nil then
        return false, "unknown_key"
    end

    if s.kind == "bool" then
        -- 注意 Lua 里 0 也是真，不能直接 and/or
        value = (value == true or value == 1)
    elseif s.kind == "number" then
        value = tonumber(value)
        if value == nil then
            return false, "not_number"
        end
        value = math.floor(value + 0.5)
        value = math.max(s.min or value, math.min(s.max or value, value))
    elseif s.kind == "choice" then
        value = tonumber(value)
        if value == nil then
            return false, "not_number"
        end
        local ok = false
        for _, c in ipairs(s.choices) do
            if c == value then
                ok = true
                break
            end
        end
        if not ok then
            return false, "bad_choice"
        end
    end

    self.values[key] = value
    self.inst:PushEvent("musha_world_settings_changed", { key = key, value = value })
    return true
end

function Musha_World_Settings:OnSave()
    return { values = self.values }
end

function Musha_World_Settings:OnLoad(data)
    if data and type(data.values) == "table" then
        for k, v in pairs(data.values) do
            if SPEC[k] ~= nil then
                self.values[k] = v
            end
        end
    end
end

function Musha_World_Settings:GetDebugString()
    local t = {}
    for k, v in pairs(self.values) do
        table.insert(t, k .. "=" .. tostring(v))
    end
    return table.concat(t, " ")
end

return Musha_World_Settings
