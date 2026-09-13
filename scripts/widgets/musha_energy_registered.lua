-- ============================================================
-- musha_energy_registered.lua（2026-09-13 新建）
-- 把能量条「官方挂载」进三围栏：AddClassPostConstruct("widgets/statusdisplays")
-- 照「遗迹守卫」Mecha_x_Power_Registered.lua 的写法（作者：盾牌、Ciel、树萝莉）
--
-- 三件事：
--   ① 只有 musha 角色才挂（HasTag("musha")）
--   ② 位置：拿 stomach / brain / heart 三个球的坐标推（横排/竖排两种布局都处理）
--   ③ 死亡变鬼时 Hide（hook SetGhostMode，别覆盖原方法）
-- ============================================================

AddClassPostConstruct("widgets/statusdisplays", function(self)
    if self.owner == nil or not self.owner:HasTag("musha") then
        return
    end

    local MushaEnergyBadge = require("widgets/musha_energy_badge")
    self.musha_energy_badge = self:AddChild(MushaEnergyBadge(self.owner))

    -- 位置：等三围球排好版之后再算（原版也是用 DoTaskInTime 延后）
    self.owner:DoTaskInTime(0.5, function()
        if self.musha_energy_badge == nil or self.stomach == nil then
            return
        end

        local pos = self.stomach:GetPosition()
        local sx, sy = pos:Get()                      -- 饥饿球

        if self.brain ~= nil and self.heart ~= nil then
            local bx, by = self.brain:GetPosition():Get()   -- 理智球
            local hx, hy = self.heart:GetPosition():Get()   -- 生命球

            if by == sy or by == hy then
                -- 横排布局：接在饥饿球外侧一格；潮湿计/船计跟着一起挪
                self.musha_energy_badge:SetPosition(pos + Vector3(sx - bx, 0, 0))
                if self.boatmeter ~= nil and self.moisturemeter ~= nil then
                    self.boatmeter:SetPosition(self.moisturemeter:GetPosition() + Vector3(sx - bx, 0, 0))
                end
            else
                -- 竖排布局：跟饥饿球同 x，往生命球那一侧让一格
                self.musha_energy_badge:SetPosition(pos + Vector3(sx - hx, 0, 0))
            end
        end
    end)

    -- 死亡/复活：鬼形态隐藏
    local old_SetGhostMode = self.SetGhostMode
    function self:SetGhostMode(ghostmode, ...)
        old_SetGhostMode(self, ghostmode, ...)
        if self.musha_energy_badge ~= nil then
            if ghostmode then
                self.musha_energy_badge:Hide()
            else
                self.musha_energy_badge:Show()
            end
        end
    end
end)
