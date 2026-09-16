-- ====================================
-- musha_jobbook_warrior.lua
-- 战士职业书 — 使用后转职为战士
-- ====================================
local MUSHA_JOB = {
    WARRIOR = 1, MAGE = 2, RANGER = 3, ASSASSIN = 4,
    SWORDSMAN = 11, GUARDIAN = 12,
    ALCHEMIST = 21, ELEMENTALIST = 22,
    BARD = 31, MOONSHADOW = 41,
}
local assets = {Asset("ANIM", "anim/musha_jobbook_warrior.zip"),
                Asset("ATLAS", "images/inventoryimages/musha_jobbook_warrior.xml"),
                Asset("IMAGE", "images/inventoryimages/musha_jobbook_warrior.tex")}

local function OnUseBook(inst, doer)
    if not doer or not doer:IsValid() then
        return
    end

    local pc = doer.components.musha_profession_component
    if not pc then
        if doer.components.talker then
            doer.components.talker:Say(STRINGS.MUSHA_JOB_USE_NO_SYSTEM, 3)
        end
        return
    end

    local function Say(msg, t)
        if doer.components.talker then
            doer.components.talker:Say(msg, t or 3)
        end
    end

    -- ==========================================================
    -- 已有职业：这本"战士职业书"只管【一转】
    --   ★ 2026-09-12 用户纠正：二转任务不该由职业书接 —— 那是**进阶祭坛**的事。
    --     （之前这里会直接 AcceptAdvanceQuest，用户问"为什么原来的职业书就可以接？不需要祭坛？"）
    --   现在：已有职业 → 只给提示，指向祭坛；不接任何任务
    -- ==========================================================
    if pc:HasJob() then
        if pc:GetCarrer_base() ~= "warrior" then
            Say("你已经是别的职业了，不能改用战士职业书（职业不可更换）。", 3)
            return
        end
        if pc:GetCarrer_special() or (pc.userdata and pc.userdata.has_advanced) then
            Say("你已经完成二转，职业书用不上了。", 3)
            return
        end
        Say("你已经是战士了。二转任务要去【进阶祭坛】接取（右键祭坛）。", 4)
        return
    end

    -- ==========================================================
    -- 无职业：一转（0 级即可，无需等级）
    -- ★ 2026-09-12 起职业书【不再消耗】—— 用户拍板：书留在手里，
    --   5 级时右键同一本书领取二转任务（见上面那条分支）。
    --   （旧行为：inst:Remove() 把书吃掉；已删）
    -- ==========================================================
    pc:SetCarrerBase("warrior")
    Say(STRINGS.MUSHA_JOB_USE_WARRIOR, 4)

    -- 转职事件通知（组件监听后配送武器）
    doer:PushEvent("musha_job_changed", {
        job_id = MUSHA_JOB.WARRIOR
    })

    -- 首次一转仍送一本技能书
    local inv = doer.components.inventory
    if inv and not doer._musha_skillbook_given then
        doer._musha_skillbook_given = true
        local book = SpawnPrefab("musha_skillbook")
        if book then
            inv:GiveItem(book)
        end
    end

    -- ★ 2026-09-14 用户：「职业书 一转完成就移除」→ 转职成功立刻把这本吃掉
    --   ⚠️ 连带后果：以前那条"书留在手里、5 级时右键同一本书接二转任务"的路**没了** ——
    --      二转任务一律去【进阶祭坛】右键接（下面"已经是战士了"那条分支对旧存档仍然有效）。
    if inst ~= nil and inst:IsValid() then
        inst:Remove()
    end
end

local function displaynamefn(inst)
    -- 检查是否有职业（通过网络变量/状态判断）
    -- 当前统一显示为"职业书（战士）"
    return STRINGS.NAMES.MUSHA_JOBBOOK_WARRIOR
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("musha_jobbook_warrior")
    inst.AnimState:SetBuild("musha_jobbook_warrior")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("musha_jobbook")

    inst.displaynamefn = displaynamefn

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "musha_jobbook_warrior"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/musha_jobbook_warrior.xml"

    inst:AddComponent("musha_action")
    inst.components.musha_action:SetFn(OnUseBook)

    return inst
end

return Prefab("musha_jobbook_warrior", fn, assets)
