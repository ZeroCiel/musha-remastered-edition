-- ============================================================
-- musha_mailbag.lua — 信差包（可携带的 5 格容器）
--   2026-09-19 新建。设计稿：musha-信箱邮包设计.md
--
--   行为：
--     · 未绑定信箱：就是普通小容器（5 格），怎么用都行
--     · 绑定过信箱：**每次关包**把里面的东西寄回自己的收件箱
--         - 收件箱在附近（加载范围内）→ 直接投进去
--         - 收件箱不在 → 塞进**框外隐藏格（待寄区）**，包看起来空了；
--           回家靠近信箱时由 musha_mail 组件自动倒出
--     · 收件箱满了 → 停止寄送，东西留在包里 + 提示（不丢东西是第一原则）
--
--   ★ 隐藏格（待寄区）怎么实现的：
--     widget 的 slotpos **只列前 5 个**（玩家看得见）；容器实际有 14 格，
--     第 6~14 格**没有 slotpos** → 永远不画、玩家碰不到，但原版 container 的
--     存档逻辑照样存它们。代码用 container.slots[i] 直接读写。
--     ⚠️ 必须同时把 GetFreeSlot / GetSpecificSlotForItem 包一层，只认 1~5，
--        否则原版 GiveItem 会把东西丢进隐藏格 → 玩家看起来"东西消失了"。
-- ============================================================

local ok, Mail = pcall(require, "musha_mail")
if not ok or Mail == nil then Mail = nil end

-- 素材自检（铁律：assets 里写不存在的文件 → RegisterPrefabs assert → 整个 mod 被禁）
local function FileOK(path)
    local f = softresolvefilepath
    if f == nil then return false end
    local o, r = pcall(f, path)
    return o and r ~= nil
end

-- 地上/手持:专属 zip 还没打包 → 借原版莎草纸（data/anim/papyrus.zip 已在游戏里，验证过存在）
local HAS_ANIM = FileOK("anim/musha_mailbag.zip")
-- 图标：2026-09-19 已由 exported/_tools/make_mailbag_icon.py 出好 64² PNG，
--       等用户用 Mod Tool 转成 .tex + .xml 后自动切过来（没转就退回原版背包图标）
local HAS_ICON = FileOK("images/inventoryimages/musha_mailbag.xml")
                 and FileOK("images/inventoryimages/musha_mailbag.tex")

local BANK  = HAS_ANIM and "musha_mailbag" or "papyrus"
local BUILD = HAS_ANIM and "musha_mailbag" or "papyrus"

local assets = {
    HAS_ANIM and Asset("ANIM", "anim/musha_mailbag.zip") or Asset("ANIM", "anim/papyrus.zip"),
}
if HAS_ICON then
    table.insert(assets, Asset("ATLAS", "images/inventoryimages/musha_mailbag.xml"))
    table.insert(assets, Asset("IMAGE", "images/inventoryimages/musha_mailbag.tex"))
end

if not (HAS_ANIM and HAS_ICON) then
    print("[Musha] 信差包：专属素材还没打包，先用占位（不会崩）。缺："
        .. (HAS_ANIM and "" or " anim/musha_mailbag.zip")
        .. (HAS_ICON and "" or " images/inventoryimages/musha_mailbag.{xml,tex}（png 已出好，等 Mod Tool 转）"))
end

local VISIBLE = 5          -- 玩家看得见的格数
local TOTAL   = 14         -- 实际格数（后 9 格 = 待寄区，框外）

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(BANK)
    inst.AnimState:SetBuild(BUILD)
    inst.AnimState:PlayAnimation("idle")

    -- ★ tag 必须在 SetPristine() 之前（客机右键要看得见标签）
    inst:AddTag("musha_mailbag")

    inst:AddComponent("musha_action")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = HAS_ICON and "images/inventoryimages/musha_mailbag.xml"
        or "images/inventoryimages.xml"
    inst.components.inventoryitem.imagename = HAS_ICON and "musha_mailbag" or "backpack"

    -- ===== 容器 =====
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("musha_mailbag")

    -- 只认可见格（1~5）：防止原版把物品**自动**放进隐藏的待寄区（玩家会看着"东西消失了"）
    --   ⚠️ 光覆盖 GetFreeSlot / GetSpecificSlotForItem **不够**：
    --      原版 GiveItem 在 slot==nil 时还有一条 `for i = 1, self.numslots do` 的兜底扫描
    --      （container.lua:521-524）→ 会把东西扫进隐藏格。所以真正的闸门放在 GiveItem 上。
    --   ⚠️ 也不能用 params 的 usespecificslotsforitems=true 来挡：那样 CanTakeItemInSlot 会
    --      要求 slot == GetSpecificSlotForItem()，我的待寄区（显式给 6~14 号位）就写不进去了。
    local c = inst.components.container
    local function FirstVisibleFreeSlot(self)
        for i = 1, VISIBLE do
            if self.slots[i] == nil then return i end
        end
        return nil
    end
    c.GetFreeSlot = FirstVisibleFreeSlot
    local base_give = c.GiveItem
    c.GiveItem = function(self, item, slot, src_pos, drop_on_fail)
        if slot == nil then                       -- 自动放 → 只认可见格
            slot = FirstVisibleFreeSlot(self)
            if slot == nil then
                return false                      -- 可见格满了 → 拒收，绝不偷偷塞进隐藏格
            end
        end
        return base_give(self, item, slot, src_pos, drop_on_fail)
    end

    -- 关包 = 寄件（onclosefn 第 2 参是 **doer 本人**，不是 { doer = doer } 那张表；
    --   onopenfn 才是表 → 这俩签名不一样，别抄错）
    inst.components.container.onclosefn = function(bag, doer)
        if doer == nil or not doer:IsValid() then return end      -- 自动关闭时 doer 可能是 nil
        local mc = doer.components.musha_mail
        if mc == nil then return end
        mc:MailBag(bag, doer)
    end

    -- 待寄区格数上限（给 musha_mail 用）
    inst.buffer_slots = TOTAL - VISIBLE
    inst.visible_slots = VISIBLE

    -- 右键包 = 开 / 关
    inst.components.musha_action:SetFn(function(bag, doer)
        if doer == nil or not doer:IsValid() then return end
        if bag.components.container:IsOpenedBy(doer) then
            bag.components.container:Close(doer)
        else
            bag.components.container:Open(doer)
        end
    end)
    inst.components.musha_action:SetCanUseCheck(function(_, doer)
        return doer ~= nil and doer:IsValid()
    end)

    return inst
end

return Prefab("musha_mailbag", fn, assets, {})
