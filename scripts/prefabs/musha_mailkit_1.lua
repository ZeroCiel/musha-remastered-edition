-- ============================================================
-- musha_mailkit_1.lua — 邮包升级套件 I（收件箱 3 → 5 格）
--   2026-09-19 新建。实现全在 scripts/musha_mailkit.lua（共用模块），本文件只负责注册。
--   用法：背包里带着它 → 右键自己的信箱，动作会从「触摸」变成「升级」。
--   配方在 modmain.lua（木板 x5）。
-- ============================================================

local ok, Kit = pcall(require, "musha_mailkit")
if ok and Kit ~= nil and Kit.Make ~= nil then
    return Kit.Make(1)
end

print("[Musha ERROR] musha_mailkit 模块没加载成功（升级套件 I 退化为哑物品）：" .. tostring(Kit))
return Prefab("musha_mailkit_1", function()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    inst.AnimState:SetBank("papyrus")
    inst.AnimState:SetBuild("papyrus")
    inst.AnimState:PlayAnimation("idle")
    inst:AddTag("musha_mailkit")
    inst.mail_kit_step = 1
    inst.mail_kit_to = 5
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "MUSHA_MAILKIT_1"
    inst:AddComponent("inventoryitem")
    return inst
end, { Asset("ANIM", "anim/papyrus.zip") })
