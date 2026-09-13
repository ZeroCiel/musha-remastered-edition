-- ============================================================
-- musha_energy_badge.lua（2026-09-13 新建）
-- 能量条显示 = 官方 Badge 基类 + 我们自己的 build "energy"
-- 照「遗迹守卫」Mecha_x_Power_UI.lua 的写法（作者：盾牌、Ciel、树萝莉）
--
-- 原理：Badge._ctor(self, anim, owner) 里那个 anim 参数**既是 bank 也是 build 名**，
--       基类内部就是 SetBank(anim) + SetBuild(anim) + PlayAnimation("anim")，
--       进度用 SetPercent("anim", 1-percent) 压。
--       → 我们的 anim/energy.zip 正好：bank = energy、build = energy、动画名 = anim ✓
--
-- 数值来源：prefab 上的 netvar（服务端改、客户端读），不经过 RPC
-- ============================================================

local Badge = require "widgets/badge"
local Widget = require "widgets/widget"

local MushaEnergyBadge = Class(Badge, function(self, owner)
    Badge._ctor(self, "energy", owner)

    self.owner = owner
    self:StartUpdating()
end)

function MushaEnergyBadge:OnUpdate(dt)
    if not self.owner then return end

    local cur = (self.owner.Musha_MP and self.owner.Musha_MP:value()) or 0
    local max = (self.owner.Musha_MP_MAX and self.owner.Musha_MP_MAX:value()) or 100
    if max <= 0 then max = 100 end

    -- val 是 0~1 的百分比；max 只用来决定中间数字显示多少（Badge 内部 val*max）
    self:SetPercent(math.clamp(cur / max, 0, 1), max)
end

return MushaEnergyBadge
