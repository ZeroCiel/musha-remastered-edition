-- ============================================================
-- musha_mailkit.lua — 升级套件（共用实现）
--   2026-09-19 新建。设计稿：musha-信箱邮包设计.md
--
--   用途：信箱收件箱 3 → 5 → 7 → 9 → 11 格，每档做一件套件。
--   玩家**背包里带着对应档的套件**时，右键信箱的动作从「触摸」变成「升级」。
--
--   ⚠️ 为什么是 4 个 prefab 而不是 1 个带等级的道具：
--      DST **不保存物品的自定义字段**（掉线重进就丢）→ 只有 prefab 名能可靠地"带信息"。
--      所以 4 档 = 4 个 prefab，各自在 scripts/prefabs/musha_mailkit_N.lua 里注册。
--
--   照 musha_crest.lua 的兜底写法：prefab 里 pcall(require)，失败退化"哑套件"。
-- ============================================================

local ok, Mail = pcall(require, "musha_mail")
if not ok or Mail == nil then
    print("[Musha ERROR] musha_mailkit: musha_mail 模块没加载成功")
    Mail = nil
end

local function FileOK(path)
    local f = softresolvefilepath
    if f == nil then return false end
    local o, r = pcall(f, path)
    return o and r ~= nil
end

local MushaMailKit = {}

-- step: 1..4（对应 musha_mail 的 KITS）
function MushaMailKit.Make(step)
    local def = nil
    if Mail ~= nil then
        for _, k in ipairs(Mail.KITS) do
            if k.step == step then def = k end
        end
    end
    if def == nil then
        def = { prefab = "musha_mailkit_" .. tostring(step), step = step, to = 3 + 2 * step }
    end

    -- 素材自检：图标还没画 → 借原版莎草纸图标；地上借原版 papyrus.zip（都在游戏里）
    local HAS_ICON = FileOK("images/inventoryimages/" .. def.prefab .. ".xml")
                     and FileOK("images/inventoryimages/" .. def.prefab .. ".tex")
    local assets = {
        Asset("ANIM", "anim/papyrus.zip"),
    }
    if HAS_ICON then
        table.insert(assets, Asset("ATLAS", "images/inventoryimages/" .. def.prefab .. ".xml"))
        table.insert(assets, Asset("IMAGE", "images/inventoryimages/" .. def.prefab .. ".tex"))
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

        inst:AddTag(Mail ~= nil and Mail.KIT_TAG or "musha_mailkit")
        -- 服务端字段：这件套件能把收件箱升到几格
        inst.mail_kit_step = def.step
        inst.mail_kit_to   = def.to

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst.components.inspectable.nameoverride = "MUSHA_MAILKIT_" .. tostring(def.step)

        inst:AddComponent("inventoryitem")
        if HAS_ICON then
            inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. def.prefab .. ".xml"
            inst.components.inventoryitem.imagename = def.prefab
        else
            inst.components.inventoryitem.atlasname = "images/inventoryimages.xml"
            inst.components.inventoryitem.imagename = "papyrus"
        end

        -- ⚠️ 不给套件挂 musha_action —— 它不需要右键动作（右击信箱时才用得上它）。
        --   而且这个文件里挂组件是**服务端专用**的写法，客机上根本不会加载 →
        --   真要给物品做右键，必须像 musha_mailbag.lua 那样把组件放在 SetPristine() **之前**。

        return inst
    end

    return Prefab(def.prefab, fn, assets, {})
end

return MushaMailKit
