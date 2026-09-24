-- ============================================================
-- musha_mailkit_4.lua — 邮包升级套件 IV（收件箱 9 → 12 格）
--   实现见 scripts/musha_mailkit.lua；配方在 modmain.lua（木板 x20 + 红宝石 x2）。
--   ★ 2026-09-24 用户：满档放开到 12（一次 +3；"为什么是 3"让玩家自己摸摸头皮）。
-- ============================================================

local ok, Kit = pcall(require, "musha_mailkit")
if ok and Kit ~= nil and Kit.Make ~= nil then
    return Kit.Make(4)
end

print("[Musha ERROR] musha_mailkit 模块没加载成功（升级套件 IV 退化为哑物品）：" .. tostring(Kit))
return Prefab("musha_mailkit_4", function()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    inst.AnimState:SetBank("papyrus")
    inst.AnimState:SetBuild("papyrus")
    inst.AnimState:PlayAnimation("idle")
    inst:AddTag("musha_mailkit")
    inst.mail_kit_step = 4
    inst.mail_kit_to = 12
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "MUSHA_MAILKIT_4"
    inst:AddComponent("inventoryitem")
    return inst
end, { Asset("ANIM", "anim/papyrus.zip") })
