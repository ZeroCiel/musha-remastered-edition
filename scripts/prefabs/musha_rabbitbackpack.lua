-- ====================================
-- musha_rabbitbackpack.lua — 兔子背包（2026-09-26）
--
--   · 装备 BODY 位：背上出现兔子背包（swap_body 覆盖，背面视图）
--   · 容器 8 格（原版背包同款 UI：ui_backpack_2x4）
--   · 启用门控：只有「爱丽丝计划」mod 存在时才发（modmain 出生发放处判）
--   · 美术：图片/兔子背包/ 四视图（正面=图标+地面，背面=上背 swap 件）
-- ====================================

local assets = {
    Asset("ANIM", "anim/musha_rabbitbackpack.zip"),
    Asset("ATLAS", "images/inventoryimages/musha_rabbitbackpack.xml"),
    Asset("IMAGE", "images/inventoryimages/musha_rabbitbackpack.tex"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "musha_rabbitbackpack", "swap_body")
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("musha_rabbitbackpack")
    inst.AnimState:SetBuild("musha_rabbitbackpack")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("musha_rabbitbackpack")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "MUSHA_RABBITBACKPACK"

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "musha_rabbitbackpack"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/musha_rabbitbackpack.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("musha_rabbitbackpack")

    return inst
end

return Prefab("musha_rabbitbackpack", fn, assets)
