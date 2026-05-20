-- 文件: scripts/prefabs/musha_note.lua
-- 便签 - 开局携带，右键弹 UI 显示逐行浮现的职业引导文本

local assets = {
    Asset("ANIM", "anim/musha_note.zip"),
    Asset("ATLAS", "images/inventoryimages/musha_note.xml"),
    Asset("IMAGE", "images/inventoryimages/musha_note.tex"),
    Asset("ATLAS", "images/musha_note_bg.xml"),
    Asset("IMAGE", "images/musha_note_bg.tex")
}

local function OnUseNote(inst, doer)
    if not doer or not doer:IsValid() then
        return
    end

    -- 防止重复打开
    if inst._playing then
        return
    end
    inst._playing = true

    -- 触发事件，UI 通过 owner.screen_musha_note 找到实例
    doer:PushEvent("musha_use_note")

    -- 冷却后重置
    inst:DoTaskInTime(0.5, function()
        inst._playing = false
    end)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("musha_note")
    inst.AnimState:SetBuild("musha_note")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("musha_note")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "musha_note"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/musha_note.xml"

    -- musha_action 组件（modmain 里注册了 INVENTORY 右键触发 MUSHA_READ_NOTE → UseItem）
    inst:AddComponent("musha_action")
    inst.components.musha_action:SetFn(OnUseNote)

    return inst
end

return Prefab("musha_note", fn, assets)
