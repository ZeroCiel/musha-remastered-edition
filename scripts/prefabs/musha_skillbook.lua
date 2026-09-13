-- ====================================
-- musha_skillbook.lua
-- 通用技能书 prefab
-- 已被转职的角色右键使用 → 打开技能 UI
-- 未转职的角色 → 提示先转职
-- ====================================

local assets = {
    Asset("ATLAS", "images/inventoryimages/musha_skillbook.xml"),
    Asset("IMAGE", "images/inventoryimages/musha_skillbook.tex"),
}

local function OnUseBook(inst, doer)
    if not doer or not doer:IsValid() then return end

    local pc = doer.components.musha_profession_component
    if not pc then
        if doer.components.talker then
            doer.components.talker:Say("没有职业系统的支持…", 3)
        end
        return
    end

    if not pc:HasJob() then
        if doer.components.talker then
            doer.components.talker:Say("你还没有选择职业！", 3)
        end
        return
    end

    -- 服务端：通过 net_bool 通知客户端打开职业面板
    -- （客户端 mushapanelchanged 监听 → PushEvent("musha_open_skill_panel") → panel ShowPanel）
    if TheWorld.ismastersim and doer._musha_panel_net then
        doer._musha_panel_net:set(true)
        -- 下一帧复位，保证下次右键还能触发 dirty
        if not doer._musha_panel_reset_task then
            doer._musha_panel_reset_task = doer:DoTaskInTime(0, function()
                doer._musha_panel_reset_task = nil
                if doer._musha_panel_net then
                    doer._musha_panel_net:set(false)
                end
            end)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("musha_skillbook")
    inst.AnimState:SetBuild("musha_skillbook")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("musha_skillbook")
    -- 右键动作 tag：INVENTORY ComponentAction 按 tag 路由到 MUSHA_OPEN_PANEL
    inst:AddTag("musha_panel")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- 服务端
    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "MUSHA_SKILLBOOK"

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "musha_skillbook"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/musha_skillbook.xml"

    -- 右键使用
    inst:AddComponent("musha_action")
    inst.components.musha_action:SetFn(OnUseBook)

    -- 监听移除事件，清理快捷键
    inst:ListenForEvent("onremove", function()
        -- 遍历所有玩家清理快捷键
        -- 实际在关闭 UI 时清理
    end)

    return inst
end

return Prefab("musha_skillbook", fn, assets)
