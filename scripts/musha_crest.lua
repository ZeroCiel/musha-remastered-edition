-- ============================================================
-- musha_crest.lua — 进阶方向徽记（剑士 / 近卫）共用实现（2026-09-18 新建）
--
-- 用户口径：回到祭坛最后交互 → 返还两枚方向徽记（剑士 / 近卫），两枚都能看到、
--   共用绑定 ID；**用掉其中一枚 = 选定方向（不可逆）**，另一枚自动作废。
--
-- 分工：
--   · 物品本体  = scripts/prefabs/musha_crest_{saber,guardian}.lua（各 3 行，调本模块）
--   · 右键动作  = tag "musha_crest" → ACTIONS.MUSHA_USE_CREST（见 scripts/actions/musha_actions.lua）
--   · 全部逻辑  = 组件 musha_profession_component:UseAdvanceCrest()（服务端权威）
--
-- 美术现状（都先自检，缺了退回通用技能书，绝不因为缺文件禁 mod）：
--   · 剑士徽记 → 借现成的 musha_skillbook_saber 图标（已上线）
--   · 近卫徽记 → 想用 images/inventoryimages/musha_jobbook_guardian（**还没转 tex** → 自动退回）
--     近卫本来该有的图在 exported/jobbook_guardian_未上线/（icon 64² + 世界贴图 128²）
-- ============================================================

local MushaCrest = {}

local function asset_exists(path)
    local f = softresolvefilepath or (GLOBAL ~= nil and GLOBAL.softresolvefilepath)
    if f == nil then return false end
    local ok, resolved = pcall(f, path)
    return ok and resolved ~= nil
end

-- 每种徽记的素材与名字
MushaCrest.DEF = {
    saber = {
        prefab   = "musha_crest_saber",
        strname  = "MUSHA_CREST_SABER",
        icon     = "musha_skillbook_saber",   -- 专属图标（现成）
        anim     = "musha_skillbook_saber",   -- 世界贴图（现成）
        fb_icon  = "musha_skillbook",         -- 兜底图标
        fb_anim  = "musha_skillbook",
    },
    guardian = {
        prefab   = "musha_crest_guardian",
        strname  = "MUSHA_CREST_GUARDIAN",
        icon     = "musha_jobbook_guardian",  -- 近卫职业书书形象（已导出，等 Mod Tool 转 tex）
        anim     = "musha_crest_guardian",    -- 专属世界贴图（还没做 → 会退回兜底）
        fb_icon  = "musha_skillbook",
        fb_anim  = "musha_skillbook",
    },
}

-- 右键使用：全部逻辑在组件里（服务端权威）
local function OnUseCrest(inst, doer)
    if not TheWorld or not TheWorld.ismastersim then
        return true      -- 客户端只放过，等服务端结算
    end
    if doer == nil or not doer:IsValid() then return false end

    local pc = doer.components.musha_profession_component
    if pc == nil then
        if doer.components.talker then doer.components.talker:Say("（职业系统没有响应…）", 3) end
        return false
    end

    local career = inst.musha_career
    local ok, why = pc:UseAdvanceCrest(inst, career)
    if ok then
        if inst.components.stackable then
            inst.components.stackable:Get():Remove()
        else
            inst:Remove()
        end
        local jname = STRINGS["MUSHA_JOB_" .. string.upper(tostring(career or ""))] or tostring(career)
        if doer.components.talker then
            doer.components.talker:Say("就职完成——你成为了" .. jname .. "。", 6)
        end
        return true
    end

    -- 失败：作废的那枚直接消失，其它情况只提示
    if why == "void" then
        if inst.components.stackable then
            inst.components.stackable:Get():Remove()
        else
            inst:Remove()
        end
    end
    if doer.components.talker then
        local msg = ({
            void    = "这枚徽记已经作废了——方向不能改。",
            already = "你已经转职过了。",
            noskill = "这枚徽记和你的基础职业对不上。",
            server  = "（要在世界里使用）",
        })[why or ""] or "现在还不能用它。"
        doer.components.talker:Say(msg, 4)
    end
    return false
end

-- 生成一个徽记 prefab
function MushaCrest.Make(career)
    local def = MushaCrest.DEF[career]
    assert(def ~= nil, "MushaCrest.Make: 未知方向 " .. tostring(career))

    local has_icon = asset_exists("images/inventoryimages/" .. def.icon .. ".xml")
                     and asset_exists("images/inventoryimages/" .. def.icon .. ".tex")
    local has_anim = def.anim ~= nil and asset_exists("anim/" .. def.anim .. ".zip")
    local has_fb_icon = asset_exists("images/inventoryimages/" .. def.fb_icon .. ".xml")
                        and asset_exists("images/inventoryimages/" .. def.fb_icon .. ".tex")
    local has_fb_anim = def.fb_anim ~= nil and asset_exists("anim/" .. def.fb_anim .. ".zip")

    if not has_icon then
        print("[Musha] " .. def.prefab .. "：专属图标还没打包，先借 " .. def.fb_icon .. "（不会崩）")
    end

    local assets = {}
    if has_anim then
        table.insert(assets, Asset("ANIM", "anim/" .. def.anim .. ".zip"))
    elseif has_fb_anim then
        table.insert(assets, Asset("ANIM", "anim/" .. def.fb_anim .. ".zip"))
    end
    local icon_stem = has_icon and def.icon or (has_fb_icon and def.fb_icon or nil)
    if icon_stem ~= nil then
        table.insert(assets, Asset("ATLAS", "images/inventoryimages/" .. icon_stem .. ".xml"))
        table.insert(assets, Asset("IMAGE", "images/inventoryimages/" .. icon_stem .. ".tex"))
    end

    local bank = has_anim and def.anim or (has_fb_anim and def.fb_anim or nil)
    local any_anim = bank ~= nil

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        if any_anim then
            inst.AnimState:SetBank(bank)
            inst.AnimState:SetBuild(bank)
            inst.AnimState:PlayAnimation("idle")
        end

        inst:AddTag("musha_crest")     -- INVENTORY 右键 → MUSHA_USE_CREST
        inst.musha_career = career     -- 服务端字段：这枚徽记代表哪条支线

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst.components.inspectable.nameoverride = def.strname

        inst:AddComponent("inventoryitem")
        if icon_stem ~= nil then
            inst.components.inventoryitem.imagename = icon_stem
            inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. icon_stem .. ".xml"
        end

        inst:AddComponent("musha_action")
        inst.components.musha_action:SetFn(OnUseCrest)

        return inst
    end

    return Prefab(def.prefab, fn, assets)
end

return MushaCrest
