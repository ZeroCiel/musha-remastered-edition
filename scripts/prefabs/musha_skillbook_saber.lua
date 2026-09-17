-- ============================================================
-- musha_skillbook_saber.lua — 剑士技能书（2026-09-17 新建）
--   用户口径：「A 我指的是剑气斩，二转完成应该给一本属于剑气斩的技能树」
--   → 二转（就职仪式）的赠礼就是这本：**属于剑气斩那棵技能树**的职业专属技能书
--   用法：背包里右键 → 解锁本职业的"技能书解锁技"（剑士 = 剑气斩 Lv1）→ 成功才消耗
--
--   美术（ChatGPT 那张"三本书"大图里的中间那本 SWORDSMAN）：
--     · 图标 = exported/_tools/make_jobbook_art.py 切出来的 64×64
--       → images/inventoryimages/musha_skillbook_saber.png（**还得用 Mod Tool 转 .tex/.xml**）
--     · 地上 = 同脚本出的 exported/musha_skillbook_saber/{png,scml}（**还得打包成 anim/musha_skillbook_saber.zip**）
--   ⚠️ 素材没到位也能跑：自检不过就退回通用技能书的图标（musha_skillbook），不会禁 mod
--      （铁律：assets 里写不存在的文件 → RegisterPrefabs 阶段 assert → 整个 mod 被禁）
--
--   名字/简介走现成 STRINGS：MUSHA_SKILLBOOK_SWORDSMAN（"剑士基础技能书"）——
--   scripts/languages/{chinese,english}.lua 里 6 个进阶职业都写好了，以后做近卫/药剂师照抄本文件即可。
-- ============================================================

local function asset_exists(path)
    local f = softresolvefilepath or (GLOBAL ~= nil and GLOBAL.softresolvefilepath)
    if f == nil then return false end
    local ok, resolved = pcall(f, path)
    return ok and resolved ~= nil
end

local HAS_ANIM = asset_exists("anim/musha_skillbook_saber.zip")
local HAS_ICON = asset_exists("images/inventoryimages/musha_skillbook_saber.xml")
                 and asset_exists("images/inventoryimages/musha_skillbook_saber.tex")
-- ★ 2026-09-17 发布前自检抓到：兜底包 `anim/musha_skillbook.zip` **本身就不存在**
--   （老技能书从来只有图标、没有世界贴图）→ 原来那句无条件 Asset(...) 会让整个 mod 被禁。
--   所以兜底也要先探。
local HAS_FALLBACK_ANIM = asset_exists("anim/musha_skillbook.zip")

if not (HAS_ANIM and HAS_ICON) then
    print("[Musha] 剑士技能书：专属素材还没打包，先借通用技能书（不会崩）。缺："
        .. (HAS_ANIM and "" or " anim/musha_skillbook_saber.zip")
        .. (HAS_ICON and "" or " images/inventoryimages/musha_skillbook_saber.{xml,tex}"))
end

local USE_FALLBACK_ANIM = (not HAS_ANIM) and HAS_FALLBACK_ANIM
local HAS_ANY_ANIM      = HAS_ANIM or USE_FALLBACK_ANIM
local BANK  = HAS_ANIM and "musha_skillbook_saber" or (USE_FALLBACK_ANIM and "musha_skillbook" or nil)
local BUILD = BANK

local assets = HAS_ANIM and
{
    Asset("ANIM", "anim/musha_skillbook_saber.zip"),
} or (USE_FALLBACK_ANIM and { Asset("ANIM", "anim/musha_skillbook.zip") } or {})

if HAS_ICON then
    table.insert(assets, Asset("ATLAS", "images/inventoryimages/musha_skillbook_saber.xml"))
    table.insert(assets, Asset("IMAGE", "images/inventoryimages/musha_skillbook_saber.tex"))
end

-- 使用 → 解锁本职业的技能书解锁技（剑士 = 剑气斩 Lv1）
--   底层：components/musha_profession_component.lua 的 UnlockSkillByBook() / GrantSkillLevel1()
local function OnUseBook(inst, doer)
    if not doer or not doer:IsValid() then return end

    local pc = doer.components.musha_profession_component
    if pc == nil then
        if doer.components.talker then doer.components.talker:Say("没有职业系统的支持…", 3) end
        return
    end
    if not pc:HasJob() then
        if doer.components.talker then doer.components.talker:Say("你还没有选择职业！", 3) end
        return
    end

    local ok, why = pc:UnlockSkillByBook()
    if ok then
        if inst.components.stackable then
            inst.components.stackable:Get():Remove()
        else
            inst:Remove()
        end
    elseif doer.components.talker then
        if why == "already" then
            doer.components.talker:Say("这本书上的技能你已经会了。", 3)
        elseif why == "noskill" then
            doer.components.talker:Say("这本书属于别的职业。", 3)
        end
    end

    -- 服务端：通知客户端开面板（复用技能书那套 net_bool → PushEvent）
    if TheWorld.ismastersim and doer._musha_panel_net then
        doer._musha_panel_net:set(true)
        if not doer._musha_panel_reset_task then
            doer._musha_panel_reset_task = doer:DoTaskInTime(0, function()
                doer._musha_panel_reset_task = nil
                if doer._musha_panel_net then
                    doer._musha_panel_net:set(false)
                end
            end)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    -- 两个包都没有时**不能** SetBank（会 assert）→ 干脆不设，物品就是空白贴图（不崩）
    if HAS_ANY_ANIM then
        inst.AnimState:SetBank(BANK)
        inst.AnimState:SetBuild(BUILD)
        inst.AnimState:PlayAnimation("idle")
    end

    inst:AddTag("musha_skillbook")
    inst:AddTag("musha_panel")      -- INVENTORY 右键 → MUSHA_OPEN_PANEL → musha_action:UseItem

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "MUSHA_SKILLBOOK_SWORDSMAN"

    inst:AddComponent("inventoryitem")
    if HAS_ICON then
        inst.components.inventoryitem.imagename = "musha_skillbook_saber"
        inst.components.inventoryitem.atlasname = "images/inventoryimages/musha_skillbook_saber.xml"
    else
        inst.components.inventoryitem.imagename = "musha_skillbook"
        inst.components.inventoryitem.atlasname = "images/inventoryimages/musha_skillbook.xml"
    end

    inst:AddComponent("musha_action")
    inst.components.musha_action:SetFn(OnUseBook)

    return inst
end

return Prefab("musha_skillbook_saber", fn, assets)
