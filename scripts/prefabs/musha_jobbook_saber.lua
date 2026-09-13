-- ====================================
-- musha_jobbook_saber.lua（2026-09-12 新建）
-- 剑士转职书 —— **测试专用**（用户拍板）
--   ★★ 用途：跳过"祭坛 3 轮任务"，**直接把玩家过到二转（剑士）**，方便测二转之后的东西。
--   ★★★ 上线前必须删除（用户："用于测试 直接过到二转 上线后删除"）★★★
--        删除清单（3 处）：
--          1) 本文件 scripts/prefabs/musha_jobbook_saber.lua
--          2) modmain.lua 的 PrefabFiles 里的 "musha_jobbook_saber"
--          3) scripts/languages/chinese.lua / english.lua 里的 MUSHA_JOBBOOK_SABER 条目
--        （正式二转路径 = 进阶祭坛 → 3 轮任务 → 完成，见 quest:CompleteAdvanceQuest）
--   判定链：没一转 → 先一转；不是战士 → 这本只给战士；已二转 → 用不上；否则 → 直接过二转
--   ⚠️ 图标/动画借用「战士职业书」的资源占位（美术补图后改 assets 三行 + inventoryitem 两行）
-- ====================================

local TEST_ONLY = true                -- 标记：测试专用物品（上线前整个文件删掉）

local assets = {
    -- 占位：借用战士职业书的动画与图标
    Asset("ANIM", "anim/musha_jobbook_warrior.zip"),
    Asset("ATLAS", "images/inventoryimages/musha_jobbook_warrior.xml"),
    Asset("IMAGE", "images/inventoryimages/musha_jobbook_warrior.tex"),
    -- 美术补图后换成：
    -- Asset("ANIM", "anim/musha_jobbook_saber.zip"),
    -- Asset("ATLAS", "images/inventoryimages/musha_jobbook_saber.xml"),
    -- Asset("IMAGE", "images/inventoryimages/musha_jobbook_saber.tex"),
}

local ADVANCE_TARGET = "saber"        -- 战士的二转方向（与 modmain 的 BASE_TO_ADVANCE 一致）

local function Say(doer, msg, t)
    if doer and doer.components.talker then
        doer.components.talker:Say(msg, t or 3)
    end
end

local function OnUseBook(inst, doer)
    if not doer or not doer:IsValid() then
        return
    end

    local pc = doer.components.musha_profession_component
    if not pc then
        Say(doer, STRINGS.MUSHA_JOB_USE_NO_SYSTEM or "Musha 职业系统未就绪。")
        return
    end

    -- ① 必须先一转
    if not pc:HasBaseJob() then
        Say(doer, "你还没有一转 —— 先用职业书转职成基础职业，再来做二转。", 4)
        return
    end

    -- ② 这本只服务"战士 → 剑士"这条线
    if pc:GetCarrer_base() ~= "warrior" then
        Say(doer, "这本剑士转职书只给战士用。", 3)
        return
    end

    -- ③ 已经二转过了
    if pc:GetCarrer_special() or (pc.userdata and pc.userdata.has_advanced) then
        Say(doer, "你已经完成二转，转职书用不上了。", 3)
        return
    end

    -- ==========================================================
    -- ④ 直接过到二转（剑士）—— ★测试专用，上线前删本文件★
    --   正式路径是：进阶祭坛 → 3 轮任务 → CompleteAdvanceQuest
    -- ==========================================================
    pc.userdata.has_advanced = true
    local ok, err = pcall(function()
        pc:SetCarrerSpecial(ADVANCE_TARGET)     -- 内部会 ApplyProfessionData + PushSettings
    end)
    if not ok then
        Say(doer, "二转失败：" .. tostring(err), 4)
        return
    end

    -- 和正式路径保持一致：发一本基础技能书
    local inv = doer.components.inventory
    if inv then
        local sk = SpawnPrefab("musha_skillbook")
        if sk then
            inv:GiveItem(sk)
        end
    end

    Say(doer, "【测试】已直接完成二转：剑士（正式流程走进阶祭坛）", 5)
end

local function displaynamefn(inst)
    return STRINGS.NAMES.MUSHA_JOBBOOK_SABER or "剑士转职书"
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("musha_jobbook_warrior")     -- 占位
    inst.AnimState:SetBuild("musha_jobbook_warrior")    -- 占位
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("musha_jobbook")

    inst.displaynamefn = displaynamefn

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "musha_jobbook_warrior"     -- 占位
    inst.components.inventoryitem.atlasname = "images/inventoryimages/musha_jobbook_warrior.xml"

    inst:AddComponent("musha_action")
    inst.components.musha_action:SetFn(OnUseBook)

    return inst
end

return Prefab("musha_jobbook_saber", fn, assets)
