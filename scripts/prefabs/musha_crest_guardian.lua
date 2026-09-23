-- ============================================================
-- musha_crest_guardian.lua — 近卫徽记（进阶方向：近卫）
--   2026-09-18 新建。实现全在 scripts/musha_crest.lua（共用模块），本文件只负责注册。
--   用途：就职仪式发给玩家的两枚方向徽记之一；右键使用 = 选定【近卫】方向（不可逆）。
--   美术：想用 images/inventoryimages/musha_jobbook_guardian（近卫职业书那本书，**还没转 tex**）
--         → 自检不过就退回通用技能书图标，不会禁 mod。
--
--   ⚠️ 兜底说明同 musha_crest_saber.lua：prefab 里 require 根模块用 pcall 兜住，
--     失败就注册"哑徽记"，绝不因为一个 require 把整个 mod 弄挂。
-- ============================================================

local ok, Crest = pcall(require, "musha_crest")
if ok and Crest ~= nil and Crest.Make ~= nil then
    return Crest.Make("guardian")
end

print("[Musha ERROR] musha_crest 模块没加载成功（近卫徽记退化为哑物品）：" .. tostring(Crest))
return Prefab("musha_crest_guardian", function()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    inst:AddTag("musha_crest")
    inst.musha_career = "guardian"
    inst.entity:SetPristine()
    if TheWorld.ismastersim then
        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst:AddComponent("musha_action")
        inst.components.musha_action:SetFn(function(_, doer)
            if doer ~= nil and doer.components.talker ~= nil then
                doer.components.talker:Say("（这枚徽记失效了——请回报一个 bug）", 4)
            end
            return false
        end)
    end
    return inst
end, {})
