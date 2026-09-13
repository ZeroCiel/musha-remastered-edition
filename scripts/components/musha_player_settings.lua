-- ====================================
-- musha_player_settings.lua
-- 玩家级"局内设置"（服务端权威，随玩家存档走）
-- 挂载：musha 玩家（modmain InitMushaPlayer 里补挂）
-- 同步：和世界级一样，由 musha_profession_component:PushSettings() 带出去
-- ====================================

local SPEC = {
    -- 生命回复倍率（乘在 class_traits.health_regen 上）
    hp_regen_mult = { default = 1,     kind = "choice", choices = { 0.5, 1, 2, 5 } },
    -- ⚠️ 能量(MP)回复倍率 mp_regen_mult 已于 2026-09-12 删除 ——
    --   全项目没有 MP/能量系统（无组件、无字段、无消费方），留着是空转。
    --   以后真做 MP 再加回来（旧存档里存过的这个键会被 OnLoad 自动丢弃，不会报错）。
    -- 显示调试信息
    show_debug    = { default = false, kind = "bool" },
}

local Musha_Player_Settings = Class(function(self, inst)
    self.inst = inst
    self.values = {}
    for k, s in pairs(SPEC) do
        self.values[k] = s.default
    end
end)

Musha_Player_Settings.SPEC = SPEC

function Musha_Player_Settings:Get(key)
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

function Musha_Player_Settings:Set(key, value)
    local s = SPEC[key]
    if s == nil then
        return false, "unknown_key"
    end

    if s.kind == "bool" then
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
    self.inst:PushEvent("musha_player_settings_changed", { key = key, value = value })
    return true
end

function Musha_Player_Settings:OnSave()
    return { values = self.values }
end

function Musha_Player_Settings:OnLoad(data)
    if data and type(data.values) == "table" then
        for k, v in pairs(data.values) do
            if SPEC[k] ~= nil then
                self.values[k] = v
            end
        end
    end
end

function Musha_Player_Settings:GetDebugString()
    local t = {}
    for k, v in pairs(self.values) do
        table.insert(t, k .. "=" .. tostring(v))
    end
    return table.concat(t, ", ")
end

return Musha_Player_Settings
