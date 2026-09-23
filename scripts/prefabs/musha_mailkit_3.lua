-- ============================================================
-- musha_mailkit_3.lua — 邮包升级套件 III（收件箱 7 → 9 格）
--   实现见 scripts/musha_mailkit.lua；配方在 modmain.lua（木板 x20）。
-- ============================================================

local ok, Kit = pcall(require, "musha_mailkit")
if ok and Kit ~= nil and Kit.Make ~= nil then
    return Kit.Make(3)
end

print("[Musha ERROR] musha_mailkit 模块没加载成功（升级套件 III 退化为哑物品）：" .. tostring(Kit))
return Prefab("musha_mailkit_3", function()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    inst.AnimState:SetBank("papyrus")
    inst.AnimState:SetBuild("papyrus")
    inst.AnimState:PlayAnimation("idle")
    inst:AddTag("musha_mailkit")
    inst.mail_kit_step = 3
    inst.mail_kit_to = 9
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "MUSHA_MAILKIT_3"
    inst:AddComponent("inventoryitem")
    return inst
end, { Asset("ANIM", "anim/papyrus.zip") })
