-- ============================================================
-- musha_job_reset.lua — 职业重置石（2026-09-29 用户需求）
--
--   用户原话：
--     "出一个物品 重置职业用的，不开放任何制作条件。"
--     "我测试需要用到，检查里可说 仅作者用，本地模式/使用者属于测试安全员都允许使用。"
--
--   行为：
--     · 背包右键 = 重置：职业清空 + 等级/经验/技能点/技能树全归 0，从 0 级重新开始
--     · **不注册任何配方** → 合成栏里根本没有它（= "不开放任何制作条件"）
--     · 使用权限：作者 SteamID / 测试安全员白名单 / 本地（房主）模式
--       → scripts/musha_dev_mode.lua:CanUseTestItem()
--     · 拿不到就控制台 c_give("musha_job_reset")
--
--   素材：不画新图 —— 借原版 anim/gems.zip（bank=gems build=gems 动画 redgem_idle）
--         + 原版红宝石图标。用户哪天画好专属图，丢 zip/xml/tex 进去自动切过来。
--
--   逻辑：重置本体在 components/musha_profession_component.lua:ResetJobForTest()
--   动作：scripts/actions/musha_actions.lua 的 MUSHA_RESET_JOB（tag=musha_reset_job）
-- ============================================================

local ok_dev, Dev = pcall(require, "musha_dev_mode")
if not ok_dev then Dev = nil end

local function DevCanUse(doer)
    if Dev == nil or type(Dev.CanUseTestItem) ~= "function" then return false end
    local ok, v = pcall(Dev.CanUseTestItem, Dev)
    return ok and v == true
end

-- 素材自检（铁律：assets 里写不存在的文件 → RegisterPrefabs assert → 整个 mod 被禁）
local function FileOK(path)
    local f = softresolvefilepath
    if f == nil then return false end
    local o, r = pcall(f, path)
    return o and r ~= nil
end

local HAS_ICON = FileOK("images/inventoryimages/musha_recall_stone.xml")
             and FileOK("images/inventoryimages/musha_recall_stone.tex")

local assets = { Asset("ANIM", "anim/gems.zip") }
if HAS_ICON then
    table.insert(assets, Asset("ATLAS", "images/inventoryimages/musha_recall_stone.xml"))
    table.insert(assets, Asset("IMAGE", "images/inventoryimages/musha_recall_stone.tex"))
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    -- 占位美术：借原版宝石（等经费再画专属"重置石"）
    inst.AnimState:SetBank("gems")
    inst.AnimState:SetBuild("gems")
    inst.AnimState:PlayAnimation("redgem_idle", true)

    pcall(function() MakeInventoryFloatable(inst, "small", 0.2, 1.1) end)

    -- tag 必须在 SetPristine() 之前：客机右键要看得见
    inst:AddTag("musha_reset_job")

    inst:AddComponent("musha_action")       -- 右键入口（背包右键 = 重置职业）

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "MUSHA_JOB_RESET"

    inst:AddComponent("inventoryitem")      -- 不挂 stackable → 不可堆叠
    inst.components.inventoryitem.atlasname = HAS_ICON
        and "images/inventoryimages/musha_recall_stone.xml" or "images/inventoryimages.xml"
    inst.components.inventoryitem.imagename = HAS_ICON and "musha_recall_stone" or "redgem"

    inst.components.musha_action:SetFn(function(_, doer)
        if doer == nil or not doer:IsValid() then return false end
        -- 权限：作者 / 测试安全员 / 本地房主模式（服务端权威，改包绕不过）
        if not DevCanUse(doer) then
            if doer.components.talker then
                doer.components.talker:Say("这块石头不认你。", 3)
            end
            return false
        end
        local pc = doer.components.musha_profession_component
        if pc == nil or type(pc.ResetJobForTest) ~= "function" then
            if doer.components.talker then
                doer.components.talker:Say("你身上没有职业组件。", 3)
            end
            return false
        end
        local ok = pc:ResetJobForTest()
        if ok and doer.components.talker then
            doer.components.talker:Say("职业已重置——从 0 级重新开始。", 4)
        end
        -- 用掉即销毁（测试道具，一次一颗）
        if doer.components.inventory then
            doer.components.inventory:RemoveItem(inst)
        end
        if inst:IsValid() then inst:Remove() end
        return true
    end)

    inst.components.musha_action:SetCanUseCheck(function(_, doer)
        return doer ~= nil and doer:IsValid()
    end)

    return inst
end

return Prefab("musha_job_reset", fn, assets, {})
