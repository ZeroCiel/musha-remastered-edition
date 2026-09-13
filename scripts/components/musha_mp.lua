-- ============================================================
-- musha_mp.lua（2026-09-13 新建）—— 能量（MP）组件（服务端）
-- 照「遗迹守卫」mecha_x_power 那套官方写法：
--   · 数值走 **netvar**（prefab 里 net_float），Class 的 setter 自动 set → 客户端无需 RPC
--   · 上下限/回复速率读职业表 class_traits（每个职业不同）
--   · 显示由客户端 badge 读 netvar 画，本组件只管数值
-- 上限公式：mp_base + mp_max_growth * 等级
--   （照职业表注释验算：mage 20 级 60+12*20=300 ✓、rogue 20 级 80+2*20=120 ✓、ranger 120+1.5*20=150 ✓）
-- ============================================================

local TICK = 1        -- 每秒自检（顺带算上限 + 回能量）

local function oncurrent(self, current)
    if self.inst.Musha_MP then
        self.inst.Musha_MP:set(current)
    end
end

local function onmax(self, max)
    if self.inst.Musha_MP_MAX then
        self.inst.Musha_MP_MAX:set(max)
    end
end

local MushaMP = Class(function(self, inst)
    self.inst = inst
    self.max = 100
    self.current = 0
    self.regen = 0

    if TheWorld and TheWorld.ismastersim then
        self.task = inst:DoPeriodicTask(TICK, function() self:Tick() end)
    end
end, nil, {
    current = oncurrent,
    max = onmax,
})

-- ---------------- 基础数值 ----------------
function MushaMP:GetPercent()
    return (self.max > 0) and (self.current / self.max) or 0
end

function MushaMP:Set(amount)
    self.current = math.clamp(amount or 0, 0, self.max)
end

function MushaMP:DoDelta(delta)
    self.current = math.clamp(self.current + (delta or 0), 0, self.max)
    return self.current
end

-- 花得起的判断（以后技能消耗走这个）
function MushaMP:CanAfford(cost)
    return (self.current or 0) >= (cost or 0)
end

-- 扣能量（不够返回 false，不扣）
function MushaMP:Spend(cost)
    cost = cost or 0
    if self.current < cost then
        return false
    end
    self.current = self.current - cost
    return true
end

function MushaMP:SetMax(max)
    self.max = math.max(1, max or 100)
    if self.current > self.max then
        self.current = self.max
    end
end

-- ---------------- 职业表：上限 / 回复 ----------------
function MushaMP:GetClassTraits()
    local pc = self.inst.components.musha_profession_component
    if not pc or not pc.class_traits then
        return nil
    end
    local base = pc.userdata and pc.userdata.carrer_base
    return base and pc.class_traits[base] or nil
end

function MushaMP:GetClassLevel()
    local pc = self.inst.components.musha_profession_component
    return (pc and pc.userdata and pc.userdata.level) or 0
end

-- 按「职业 + 等级」重算上限与每秒回复（职业表改了这里跟着变）
function MushaMP:RefreshFromClass()
    local t = self:GetClassTraits()
    local level = self:GetClassLevel()

    local mp_base  = (t and t.mp_base) or 100
    local growth   = (t and t.mp_max_growth) or 0
    local newmax   = math.floor(mp_base + growth * level + 0.5)

    -- 回复：有的职业写固定值 mp_regen，有的写 mp_regen_base + mp_regen_growth
    local regen
    if t and t.mp_regen then
        regen = t.mp_regen
    elseif t and t.mp_regen_base then
        regen = t.mp_regen_base + (t.mp_regen_growth or 0) * level
    else
        regen = 0
    end

    self.regen = math.max(0, regen)

    if newmax ~= self.max then
        self:SetMax(newmax)
        if self.current <= 0 then
            self.current = self.max    -- 第一次拿到职业：直接补满
        end
    end
end

function MushaMP:Tick()
    if not TheWorld or not TheWorld.ismastersim then return end
    if not self.inst.components.health or self.inst.components.health:IsDead() then return end

    self:RefreshFromClass()

    if self.regen > 0 and self.current < self.max then
        self:DoDelta(self.regen)
    end
end

-- ---------------- 存档 ----------------
function MushaMP:OnSave()
    return {
        current = self.current,
        max     = self.max,
    }
end

function MushaMP:OnLoad(data)
    if not data then return end
    if data.max then self:SetMax(data.max) end
    if data.current then self.current = math.clamp(data.current, 0, self.max) end
end

function MushaMP:OnRemoveFromEntity()
    if self.task then
        self.task:Cancel()
        self.task = nil
    end
end

return MushaMP
