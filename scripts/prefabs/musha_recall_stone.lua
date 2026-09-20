-- ============================================================
-- musha_recall_stone.lua — 回城石（2026-09-20 用户需求）
--
--   行为：
--     · 拿在手上，对**任何东西**（建筑 / 生物 / 玩家 / 树…）右键 → 绑定它
--       （可换绑；换绑不重置次数与冷却）
--     · 背包里右键石头 → **回家**：传送到绑定的那个东西身边
--       · 那东西还在 → 传过去（取它的当前位置，会动的目标也跟着动）
--       · 不在了 → 用不了，提示，**不消耗次数**
--     · 冷却 360 秒；可用 3 次；第 3 次用完 → 石头自动消失
--
--   逻辑全在 components/musha_recall.lua（物品级存档必须靠组件）
--   配方在 modmain.lua：红宝石**或**绿宝石 x1 + 金块 x2 + 石头 x10
--
--   素材：专属 zip 还没打包 → 借原版 anim/gems.zip（bank=gems build=gems 动画=redgem_idle）
--         图标同理借原版红宝石图标（都在游戏里，验证过存在）
--         用户画好后：anim/musha_recall_stone.zip + images/inventoryimages/musha_recall_stone.*
--                   丢进去就自动切过来，代码一行不用改
-- ============================================================

-- 素材自检（铁律：assets 里写不存在的文件 → RegisterPrefabs assert → 整个 mod 被禁）
local function FileOK(path)
    local f = softresolvefilepath
    if f == nil then return false end
    local o, r = pcall(f, path)
    return o and r ~= nil
end

local HAS_ANIM = FileOK("anim/musha_recall_stone.zip")
local HAS_ICON = FileOK("images/inventoryimages/musha_recall_stone.xml")
                 and FileOK("images/inventoryimages/musha_recall_stone.tex")

local BANK  = HAS_ANIM and "musha_recall_stone" or "gems"
local BUILD = HAS_ANIM and "musha_recall_stone" or "gems"
local ANIM  = HAS_ANIM and "idle"               or "redgem_idle"

local assets = {
    HAS_ANIM and Asset("ANIM", "anim/musha_recall_stone.zip") or Asset("ANIM", "anim/gems.zip"),
}
if HAS_ICON then
    table.insert(assets, Asset("ATLAS", "images/inventoryimages/musha_recall_stone.xml"))
    table.insert(assets, Asset("IMAGE", "images/inventoryimages/musha_recall_stone.tex"))
end

if not (HAS_ANIM and HAS_ICON) then
    print("[Musha] 回城石：专属素材还没打包，先用占位（不会崩）。缺："
        .. (HAS_ANIM and "" or " anim/musha_recall_stone.zip")
        .. (HAS_ICON and "" or " images/inventoryimages/musha_recall_stone.{xml,tex}")
        .. " → 先借原版宝石")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(BANK)
    inst.AnimState:SetBuild(BUILD)
    inst.AnimState:PlayAnimation(ANIM, true)

    -- 原版宝石那套"浮起来"的表现（双端都要，所以在 SetPristine 之前）
    pcall(function() MakeInventoryFloatable(inst, "small", 0.2, 1.1) end)

    -- tag 必须在 SetPristine() 之前：客机右键要看得见
    inst:AddTag("musha_recall_stone")
    -- 冷却表现：原版靠这个 tag 给物品栏图标挂深蓝扇形遮罩（客机也要有这个 tag 才画）
    inst:AddTag("rechargeable")

    inst:AddComponent("musha_action")       -- 右键入口（背包右键 = 回家）

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")        -- 左键查看（名字 override 在语言文件里）
    inst.components.inspectable.nameoverride = "MUSHA_RECALL_STONE"

    inst:AddComponent("inventoryitem")      -- 不挂 stackable → 天然不可堆叠（每块石头各自带绑定）
    inst.components.inventoryitem.atlasname = HAS_ICON
        and "images/inventoryimages/musha_recall_stone.xml" or "images/inventoryimages.xml"
    inst.components.inventoryitem.imagename = HAS_ICON and "musha_recall_stone" or "redgem"

    -- 核心组件：绑定 / 回家 / 次数 / 冷却 / 存档
    inst:AddComponent("musha_recall")

    -- 冷却的视觉全靠原版这个组件：物品栏/背包/快捷栏图标自动出深蓝扇形 + 转满播 frame_pst
    -- （= 沃尔特回旋镖 / 沃尔特盾 / 旺达怀表 那套；不需要我们自己画冷却动画）
    inst:AddComponent("rechargeable")

    -- 背包右键 = 回家
    inst.components.musha_action:SetFn(function(stone, doer)
        if stone.components.musha_recall ~= nil then
            stone.components.musha_recall:Recall(doer)
        end
    end)
    inst.components.musha_action:SetCanUseCheck(function(_, doer)
        return doer ~= nil and doer:IsValid()
    end)

    return inst
end

return Prefab("musha_recall_stone", fn, assets, {})
