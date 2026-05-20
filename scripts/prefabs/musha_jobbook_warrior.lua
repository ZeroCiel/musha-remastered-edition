-- ====================================
-- musha_jobbook_warrior.lua
-- 战士职业书 — 使用后转职为战士
-- ====================================
local MUSHA_JOB = {
    WARRIOR = 1, MAGE = 2, RANGER = 3, ASSASSIN = 4,
    SWORDSMAN = 11, GUARDIAN = 12,
    ALCHEMIST = 21, ELEMENTALIST = 22,
    BARD = 31, MOONSHADOW = 41,
}
local assets = {Asset("ANIM", "anim/musha_jobbook_warrior.zip"),
                Asset("ATLAS", "images/inventoryimages/musha_jobbook_warrior.xml"),
                Asset("IMAGE", "images/inventoryimages/musha_jobbook_warrior.tex")}

local function OnUseBook(inst, doer)
    if not doer or not doer:IsValid() then
        return
    end

    local pc = doer.components.musha_profession_component
    if not pc then
        if doer.components.talker then
            doer.components.talker:Say(STRINGS.MUSHA_JOB_USE_NO_SYSTEM, 3)
        end
        return
    end

    if pc:HasJob() then
        if doer.components.talker then
            doer.components.talker:Say(STRINGS.MUSHA_JOB_USE_ALREADY_HAS, 3)
        end
        return
    end

    doer.components.musha_profession_component:SetCarrerBase("warrior")
    if doer.components.talker then
        doer.components.talker:Say(STRINGS.MUSHA_JOB_USE_WARRIOR, 4)
    end

    -- 转职事件通知（组件监听后配送武器）
    doer:PushEvent("musha_job_changed", {
        job_id = MUSHA_JOB.WARRIOR
    })
    -- 将职业书变成技能书（不改变物品槽位置）
    inst:SetPrefabName("musha_skillbook")

    inst.AnimState:SetBuild("musha_skillbook")
    inst.AnimState:PlayAnimation("idle")

    inst:RemoveTag("musha_jobbook")
    -- 技能书改为打开面板 tag（显示"打开面板"右键动作）
    inst:AddTag("musha_panel")

    -- inst.components.inspectable.nameoverride = "MUSHA_SKILLBOOK" 注释掉了 名字改变在下面的函数里

    inst.components.inventoryitem.imagename = "musha_skillbook"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/musha_skillbook.xml"
    -- 重设右键动作为打开技能面板
    inst.components.musha_action:SetFn(function(item, user)
        if not user or not user:IsValid() then
            return
        end
        local pc = user.components.musha_profession_component
        if not pc or not pc:HasJob() then
            if user.components.talker then
                user.components.talker:Say(STRINGS.MUSHA_JOB_USE_NO_JOB, 3)
            end
            return
        end
        -- 服务端，PushEvent 通知客户端打开面板
        user:PushEvent("musha_open_skill_panel")
    end)

    -- 职业书变成通用技能书，保留在背包中
end

local function displaynamefn(inst)
    -- 检查是否有职业（通过网络变量/状态判断）
    -- 当前统一显示为"职业书（战士）"
    return STRINGS.NAMES.MUSHA_JOBBOOK_WARRIOR
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("musha_jobbook_warrior")
    inst.AnimState:SetBuild("musha_jobbook_warrior")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("musha_jobbook")

    inst.displaynamefn = displaynamefn

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "musha_jobbook_warrior"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/musha_jobbook_warrior.xml"

    inst:AddComponent("musha_action")
    inst.components.musha_action:SetFn(OnUseBook)

    return inst
end

return Prefab("musha_jobbook_warrior", fn, assets)
