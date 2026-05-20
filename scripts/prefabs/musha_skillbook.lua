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

    -- 客户端和服务端都处理
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

    -- 打开技能 UI（仅在客户端执行）
    if not TheWorld.ismastersim then
        if doer.components.musha_skillui then
            -- 注册技能快捷键
            local kh = doer.components.musha_keyhandler
            if kh then
                -- 获取当前职业的技能列表
                local pc = doer.components.musha_profession_component
                if pc then
                    local job_to_check = pc.mydata.carrer_base
                    if pc.mydata.carrer_special then
                        job_to_check = pc.mydata.carrer_special
                    end
                    local skill_list = GetJobSkillList(job_to_check)
                    for i, entry in ipairs(skill_list) do
                        local action_id = "skill_" .. i
                        kh:RegisterAction(action_id, function(inst_player, player)
                            -- 发送 RPC 升级技能
                            SendModRPCToServer(
                                GetModRPCIndex("musha_skill_upgrade"),
                                entry.id
                            )
                        end)
                    end
                end

                -- 注册打开技能书快捷键
                kh:RegisterAction("open_skillbook", function(inst_player, player)
                    SendModRPCToServer(
                        GetModRPCIndex("musha_request_skill_data")
                    )
                    if player.components.musha_skillui then
                        player.components.musha_skillui:OpenUI()
                    end
                end)
            end

            -- 先请求服务端数据
            SendModRPCToServer(
                GetModRPCIndex("musha_request_skill_data")
            )
            doer.components.musha_skillui:OpenUI()
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
