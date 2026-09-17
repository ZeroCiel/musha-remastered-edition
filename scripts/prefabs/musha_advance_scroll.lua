-- ============================================================
-- musha_advance_scroll.lua — 转职卷轴（2026-09-17 新建）
-- 来源：右键【进阶祭坛】打开它 → 里面躺着这一卷 → 拿出来 → 右键"展开卷轴"接取转职任务
-- 交互链：INVENTORY 右键 → MUSHA_UNROLL_SCROLL → musha_action:UseItem → OnUseScroll
--          → GLOBAL.MUSHA_AltarUseScroll(doer)（在 modmain 的祭坛段里定义）
--          → 成功接取 → 消耗本卷；失败（没职业/已进阶/等级不够/已有任务）→ 台词说明 + 卷轴留在手里
--
-- ⚠️ 美术占位：现在用的是**原版莎草纸（papyrus）**的贴图 + 图标。
--    等专属卷轴素材出来：改下面 3 处（bank/build/PlayAnimation + imagename）即可，逻辑不用动。
-- ============================================================

local assets =
{
    -- 原版资源（data/anim/papyrus.zip 已在游戏里，2026-09-17 核实存在）
    Asset("ANIM", "anim/papyrus.zip"),
}

-- modmain 的祭坛段把接取逻辑挂在这里（跨文件调用：prefab 文件拿不到 modmain 的 local）
-- ⚠️ prefab 环境里 GLOBAL 可能取不到 → 用防御式取法，取不到就明着报错（别静默失败）
local function GetAltarAccept()
    local g = GLOBAL
    if g ~= nil and type(g.MUSHA_AltarUseScroll) == "function" then
        return g.MUSHA_AltarUseScroll
    end
    return nil
end

local function OnUseScroll(inst, doer)
    if not doer or not doer:IsValid() then
        return
    end
    -- 防连点（展开有 0.5s 的"读卷"动作）
    if inst._unrolling then
        return
    end
    inst._unrolling = true
    inst:DoTaskInTime(0.5, function()
        if inst:IsValid() then inst._unrolling = false end
    end)

    local accept = GetAltarAccept()
    if accept == nil then
        print("[Musha ERROR] musha_advance_scroll: 取不到 GLOBAL.MUSHA_AltarUseScroll（modmain 祭坛段没跑？）")
        if doer.components.talker then
            doer.components.talker:Say("卷轴上的咒文失效了……", 3)
        end
        return
    end
    -- ★ 只有真的接取成功才吃掉卷轴（失败的原因由 MUSHA_AltarUseScroll 里的台词说明）
    if accept(doer) and inst:IsValid() then
        inst:Remove()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("papyrus")
    inst.AnimState:SetBuild("papyrus")
    inst.AnimState:PlayAnimation("idle")

    -- ★ tag 要在 SetPristine() 之前加：客户端也要有它才会出"展开卷轴"右键
    inst:AddTag("musha_scroll")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    -- 图标：借原版莎草纸的图（imagename 默认走游戏大图集 images/inventoryimages.xml）
    inst.components.inventoryitem.imagename = "papyrus"

    -- musha_action 组件（modmain 的 INVENTORY ComponentAction 认 musha_scroll tag → MUSHA_UNROLL_SCROLL）
    inst:AddComponent("musha_action")
    inst.components.musha_action:SetFn(OnUseScroll)

    return inst
end

return Prefab("musha_advance_scroll", fn, assets)
