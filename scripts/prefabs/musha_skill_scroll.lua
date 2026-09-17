-- ============================================================
-- musha_skill_scroll.lua — 技能卷轴（2026-09-17 新建）
--   来源：二转「就职仪式」的赠礼（用户：『转职之后给技能卷轴』）
--   定位（用户 2026-09-17）：「技能卷轴是**普通技能学习**专用的，大部分时候可制作 或 可掉落；
--                           珍惜技能 = boss 掉落」→ 本物品只覆盖普通技能那条线
--   用法：背包里右键 → 「展开卷轴」→ 解锁本职业的技能（剑士 = 剑气斩 Lv1）→ 卷轴消耗
--   制作：modmain 里 AddRecipe2（莎草纸×2 + 蜘蛛丝×2 / 科学机器 / musha 专属）
--   简介（STRINGS）：记载着普通技能要诀的卷轴。展开后习得其中的技能。
--   TODO（未做）：珍惜技能卷轴（boss 掉落，另一件物品/另一套掉落表；美术参考 图片/珍惜技能.png）
--
--   美术（用户给的两张图，在 mods/musha/图片/ 里）：
--     · 图标 = 图片/技能卷轴_图标.png → 由 exported/_tools/make_skill_scroll.py 缩成 64×64
--       写到 images/inventoryimages/musha_skill_scroll.png → **还得用 Mod Tool 转一次 .tex/.xml**；
--       没转之前本文件自检不过 → 图标退回原版莎草纸（不崩、也不影响 mod）
--     · 地上/手中 = 图片/技能卷轴_地上.png → 缩成 72×72 + scml，编成 anim/musha_skill_scroll.zip
--       （我会用命令行 scml.exe 编好放进去；没编成也一样自动退回 papyrus）
--
--   ★ 素材自检（铁律：assets 里写不存在的文件 → RegisterPrefabs 阶段 assert → **整个 mod 被禁**）
-- ============================================================

local function asset_exists(path)
    local f = softresolvefilepath or (GLOBAL ~= nil and GLOBAL.softresolvefilepath)
    if f == nil then return false end
    local ok, resolved = pcall(f, path)
    return ok and resolved ~= nil
end

local HAS_ANIM = asset_exists("anim/musha_skill_scroll.zip")
local HAS_ICON = asset_exists("images/inventoryimages/musha_skill_scroll.xml")
                 and asset_exists("images/inventoryimages/musha_skill_scroll.tex")

if not (HAS_ANIM and HAS_ICON) then
    print("[Musha] 技能卷轴：专属素材还没齐，先借原版莎草纸（不会崩）。缺："
        .. (HAS_ANIM and "" or " anim/musha_skill_scroll.zip")
        .. (HAS_ICON and "" or " images/inventoryimages/musha_skill_scroll.{xml,tex}"))
end

local BANK  = HAS_ANIM and "musha_skill_scroll" or "papyrus"
local BUILD = HAS_ANIM and "musha_skill_scroll" or "papyrus"

local assets = HAS_ANIM and
{
    Asset("ANIM", "anim/musha_skill_scroll.zip"),
} or
{
    -- 原版资源兜底（data/anim/papyrus.zip 确认存在，转职卷轴也在用）
    Asset("ANIM", "anim/papyrus.zip"),
}

if HAS_ICON then
    table.insert(assets, Asset("ATLAS", "images/inventoryimages/musha_skill_scroll.xml"))
    table.insert(assets, Asset("IMAGE", "images/inventoryimages/musha_skill_scroll.tex"))
end

local function OnUseScroll(inst, doer)
    if not doer or not doer:IsValid() then return end
    if inst._unrolling then return end
    inst._unrolling = true
    inst:DoTaskInTime(0.5, function()
        if inst:IsValid() then inst._unrolling = false end
    end)

    local pc = doer.components.musha_profession_component
    if pc == nil then
        if doer.components.talker then doer.components.talker:Say("没有职业系统的支持…", 3) end
        return
    end

    local ok, why = pc:UnlockSkillByBook()
    if ok then
        -- ★ 解锁成功才消耗（没解锁成功就不浪费）
        if inst.components.stackable then
            inst.components.stackable:Get():Remove()
        else
            inst:Remove()
        end
    elseif doer.components.talker then
        if why == "already" then
            doer.components.talker:Say("这卷卷轴上的技能你已经会了。", 3)
        elseif why == "noskill" then
            doer.components.talker:Say("还没有进阶职业，展开也没用。", 3)
        end
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

    -- ★ tag 要在 SetPristine() 之前加：客户端也要有这个 tag 才会出"展开卷轴"右键
    --   （scripts/actions/musha_actions.lua：musha_scroll → MUSHA_UNROLL_SCROLL）
    inst:AddTag("musha_scroll")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "MUSHA_SKILL_SCROLL"

    inst:AddComponent("inventoryitem")
    if HAS_ICON then
        inst.components.inventoryitem.imagename = "musha_skill_scroll"
        inst.components.inventoryitem.atlasname = "images/inventoryimages/musha_skill_scroll.xml"
    else
        inst.components.inventoryitem.imagename = "papyrus"   -- 原版大图集 images/inventoryimages.xml
    end

    inst:AddComponent("musha_action")
    inst.components.musha_action:SetFn(OnUseScroll)

    return inst
end

return Prefab("musha_skill_scroll", fn, assets)
