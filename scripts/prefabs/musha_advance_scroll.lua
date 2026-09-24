-- ============================================================
-- musha_advance_scroll.lua — 转职卷轴（2026-09-17 新建）
-- 来源：右键【进阶祭坛】打开它 → 里面躺着这一卷 → 拿出来 → 右键"展开卷轴"接取转职任务
-- 交互链：INVENTORY 右键 → MUSHA_UNROLL_SCROLL → musha_action:UseItem → OnUseScroll
--          → TUNING.MUSHA_ALTAR_USE_SCROLL(doer)（在 modmain 的祭坛段里挂上）
--          → 成功接取 → 消耗本卷；失败（没职业/已进阶/等级不够/已有任务）→ 台词说明 + 卷轴留在手里
--
-- ★ 2026-09-17 美术到货：用户给了 `图片/任务卷轴.png`（参考**彩虹岛**风格那张）→
--   已由 exported/_tools/make_advance_scroll_art.py 切成 64² 图标 + 72² 地上贴图 + scml。
--   打包后（tex/xml + anim/musha_advance_scroll.zip）自动生效；**没打包时自动退回原版莎草纸**（不崩）。
--   用户口径（2026-09-17）：「任务卷轴 / 技能卷轴这两个是**通用**道具」→ 都不绑职业。
-- ============================================================

-- 素材自检（铁律：assets 里写不存在的文件 → RegisterPrefabs assert → 整个 mod 被禁）
local function asset_exists(path)
    local f = softresolvefilepath or (GLOBAL ~= nil and GLOBAL.softresolvefilepath)
    if f == nil then return false end
    local ok, resolved = pcall(f, path)
    return ok and resolved ~= nil
end

local HAS_ANIM = asset_exists("anim/musha_advance_scroll.zip")
local HAS_ICON = asset_exists("images/inventoryimages/musha_advance_scroll.xml")
                 and asset_exists("images/inventoryimages/musha_advance_scroll.tex")

if not (HAS_ANIM and HAS_ICON) then
    print("[Musha] 转职卷轴：专属素材还没打包，先借原版莎草纸（不会崩）。缺："
        .. (HAS_ANIM and "" or " anim/musha_advance_scroll.zip")
        .. (HAS_ICON and "" or " images/inventoryimages/musha_advance_scroll.{xml,tex}"))
end

local BANK  = HAS_ANIM and "musha_advance_scroll" or "papyrus"
local BUILD = HAS_ANIM and "musha_advance_scroll" or "papyrus"

local assets =
{
    -- 原版资源兜底（data/anim/papyrus.zip 已在游戏里，2026-09-17 核实存在）
    HAS_ANIM and Asset("ANIM", "anim/musha_advance_scroll.zip") or Asset("ANIM", "anim/papyrus.zip"),
}

if HAS_ICON then
    table.insert(assets, Asset("ATLAS", "images/inventoryimages/musha_advance_scroll.xml"))
    table.insert(assets, Asset("IMAGE", "images/inventoryimages/musha_advance_scroll.tex"))
end

-- modmain 的祭坛段把接取逻辑挂到 TUNING 上（跨文件调用：prefab 拿不到 modmain 的 local）
-- ⚠️ **不能读 `GLOBAL`**：prefab 环境里 GLOBAL 是未声明的全局，一读就被 scripts/strict.lua
--    抛 "variable 'GLOBAL' is not declared"（2026-09-17 实测崩过）。TUNING 是游戏注入的全局，两端都在。
local function GetAltarAccept()
    local f = TUNING.MUSHA_ALTAR_USE_SCROLL
    if type(f) == "function" then
        return f
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
        print("[Musha ERROR] musha_advance_scroll: TUNING.MUSHA_ALTAR_USE_SCROLL 没挂上（modmain 酒馆段没跑？）")
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

    inst.AnimState:SetBank(BANK)
    inst.AnimState:SetBuild(BUILD)
    inst.AnimState:PlayAnimation("idle")

    -- ★ tag 要在 SetPristine() 之前加：客户端也要有它才会出"展开卷轴"右键
    inst:AddTag("musha_scroll")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    if HAS_ICON then
        inst.components.inventoryitem.imagename = "musha_advance_scroll"
        inst.components.inventoryitem.atlasname = "images/inventoryimages/musha_advance_scroll.xml"
    else
        -- 兜底：借原版莎草纸的图（imagename 默认走游戏大图集 images/inventoryimages.xml）
        inst.components.inventoryitem.imagename = "papyrus"
    end

    -- musha_action 组件（modmain 的 INVENTORY ComponentAction 认 musha_scroll tag → MUSHA_UNROLL_SCROLL）
    inst:AddComponent("musha_action")
    inst.components.musha_action:SetFn(OnUseScroll)

    return inst
end

return Prefab("musha_advance_scroll", fn, assets)
