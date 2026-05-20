-- 文件: scripts/prefabs/musha_sword.lua
-- musha_sword — 职业剑，攻击力42，攻击距离0.4

local assets = {
    Asset("ANIM", "anim/swap_spear.zip"),           -- 先用矛的动画占位，后续换 musha_sword.zip
    Asset("ATLAS", "images/inventoryimages/musha_sword.xml"),
    Asset("IMAGE", "images/inventoryimages/musha_sword.tex"),
}

local function on_equip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_spear", "swap_spear")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function on_unequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst:AddTag("musha_weapon")

    -- 武器组件（客户端也需要知道 attack range）
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- 武器组件
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(42)
    inst.components.weapon:SetRange(0.4)

    -- 可装备（武器栏）
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(on_equip)
    inst.components.equippable:SetOnUnequip(on_unequip)
    inst.components.equippable.walkspeedmult = 1.0

    -- 背包物品
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/musha_sword.xml"
    inst.components.inventoryitem.imagename = "musha_sword"

    -- 可堆叠/可丢
    inst:AddComponent("inspectable")

    return inst
end

return Prefab("musha_sword", fn, assets)
