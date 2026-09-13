-- musha_action.lua
-- 通用右键动作绑定组件
-- 用于给物品绑定自定义右键使用逻辑
-- 在 modmain 中配合 AddAction + AddComponentAction + AddStategraphActionHandler 使用
--
-- 用法：
--   inst:AddComponent("musha_action")
--   inst.components.musha_action:SetFn(function(inst, doer) ... end)

local MushaAction = Class(function(self, inst)
    self.inst = inst
    self.onusefn = nil          -- 使用回调: function(inst, doer) → boolean
    self.canusecheckfn = nil    -- 可选条件检查: function(inst, doer) → boolean
end)

-- 设置使用回调函数
function MushaAction:SetFn(fn)
    self.onusefn = fn
end

-- 设置可用条件检查函数
function MushaAction:SetCanUseCheck(fn)
    self.canusecheckfn = fn
end

-- 执行使用
function MushaAction:UseItem(doer)
    if not self.onusefn then
        return false
    end

    if self.canusecheckfn and not self.canusecheckfn(self.inst, doer) then
        return false
    end

    return self.onusefn(self.inst, doer)
end

-- 执行使用（SCENE 动作入口：AddAction MUSHA_QUEST_INTERACT 调用了 InteractScene）
function MushaAction:InteractScene(doer)
    return self:UseItem(doer)
end

-- 检查是否可以使用
function MushaAction:CanUse(doer)
    if not self.onusefn then
        return false
    end

    if self.canusecheckfn then
        return self.canusecheckfn(self.inst, doer)
    end

    return true
end

-- 序列化
function MushaAction:OnSave()
    return {}
end

function MushaAction:OnLoad(data)
    -- 无持久化数据
end

-- 调试信息
function MushaAction:GetDebugString()
    if self.onusefn then
        return "已绑定动作"
    end
    return "未绑定动作"
end

return MushaAction
