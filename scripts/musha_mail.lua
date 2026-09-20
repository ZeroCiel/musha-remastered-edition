-- ============================================================
-- musha_mail.lua — 信箱 / 信差包 共用常量与工具
--   设计稿：musha-信箱邮包设计.md
--   用法：prefab / 组件里 pcall(require, "musha_mail")（照 musha_crest.lua 的兜底写法）
--
--   ⚠️ 本文件在组件/prefab 沙箱里跑 → **不许用 GLOBAL**，要全局就直接写裸名字
--      （TheSim / TheWorld / SpawnPrefab / Vector3 都是原版全局，裸名可用）
-- ============================================================

local M = {}

-- ---------- 信差包 ----------
M.BAG_VISIBLE_SLOTS = 5      -- 玩家能看见/能拖的格子（用户定：5 格）
M.BAG_BUFFER_SLOTS  = 9      -- "待寄区"：框外隐藏格，只由代码读写，玩家看不见
M.BAG_TOTAL_SLOTS   = 14     -- 5 + 9

-- ---------- 收件箱 ----------
M.BOX_GRID_SLOTS   = 12                                   -- 网格永远 12 格（未解锁的显示为叉、放不进去）
M.BOX_SLOT_INIT    = 3                                    -- 初始可用 3 格
-- ★ 2026-09-20 用户："信箱面板改 4x3、遗漏最后一格、设计为 12 就好"
--   → 12 格**全都能解锁**（原来留 1 格永远叉着，作废）：3 → 5 → 7 → 9 → 12（最后一档 +3，把第 12 格补齐）
M.BOX_UNLOCK_STEPS = { 5, 7, 9, 12 }
-- 升级消耗：5 木板 → 10 木板 → 20 木板 → 20 木板 + 2 宝石（木板 20 封顶，之后每步再加 2 宝石）
--   ⚠️ 这几档现在是**升级套件**的配方材料（见下），不是"右键收件箱直接扣材料"
M.BOX_UPGRADE_COST = {
    { { "log", 5 } },
    { { "log", 10 } },
    { { "log", 20 } },
    { { "log", 20 }, { "redgem", 2 } },
}

-- ---------- 升级套件（2026-09-19 用户拍板）----------
--   "做升级套件，拥有这个适合特定信息的道具时，右键的[触摸]变成[升级]"
--   → 每档一个 prefab（**物品不能存自定义字段，靠 prefab 名带信息**）
--   step 1..4；to = 升到几格
--   2026-09-20：最后一档改成 12（用户要 12 格全可用）
M.KIT_TAG = "musha_mailkit"
M.KITS = {
    { prefab = "musha_mailkit_1", step = 1, to = 5 },
    { prefab = "musha_mailkit_2", step = 2, to = 7 },
    { prefab = "musha_mailkit_3", step = 3, to = 9 },
    { prefab = "musha_mailkit_4", step = 4, to = 12 },
}

-- 当前 unlocked 该用哪一档套件；nil = 已经满级（11）
function M.KitStepFor(unlocked)
    unlocked = unlocked or M.BOX_SLOT_INIT
    for _, k in ipairs(M.KITS) do
        if unlocked < k.to then return k.step end
    end
    return nil
end

-- 写"已解锁格数"：统一走 musha_maillevel 组件（它会把网络变量推给客户端 → 叉号格才会跟着退）
--   ★ 2026-09-21 用户口径：容器图要改必须从组件里改 + 要 replica
function M.SetShadowUnlocked(shadow, n)
    if shadow == nil then return end
    local lvl = shadow.components ~= nil and shadow.components.musha_maillevel or nil
    if lvl ~= nil then
        lvl:SetUnlocked(n)
    else
        shadow.unlocked = n             -- 兜底（组件没挂上时）
    end
end

-- 玩家身上有没有升级套件（服务端用）
--   ⚠️ 2026-09-19 踩过：**服务端的 Inventory 组件没有 GetItems()**
--      （`GetItems()` 是 replica 才有的方法：inventory_replica.lua:332）
--      服务端只能用 itemslots / ForEachItem / GetItemInSlot / GetEquippedItem
--      —— 这个错当时是在场景动作 fn 里抛的，直接把玩家状态机卡在动作里
function M.FindKit(player)
    local inv = player ~= nil and player.components.inventory or nil
    if inv == nil then return nil end
    local found = nil
    inv:ForEachItem(function(item)
        if found == nil and item:HasTag(M.KIT_TAG) then
            found = item
        end
    end)
    if found ~= nil then return found end
    local hand = inv:GetEquippedItem(EQUIPSLOTS.HANDS)
    if hand ~= nil and hand:HasTag(M.KIT_TAG) then return hand end
    return nil
end

-- ---------- tag ----------
M.SHADOW_TAG  = "musha_mail_shadow"   -- 隐形收件箱实体
M.MAILBOX_TAG = "musha_mailbox"        -- 信箱建筑（入口）
M.BAG_TAG     = "musha_mailbag"        -- 信差包（可携带容器）

-- 禁寄名单：唯一任务道具一律不许寄（防卡关）；带容器的也不寄（防套娃）
M.NO_MAIL_TAGS = {
    "musha_crest", "musha_scroll", "musha_jobbook", "musha_learnable",
    "musha_note", "irreplaceable",
}

-- ============================================================
-- 基础工具
-- ============================================================

function M.UserID(player)
    if player == nil then return nil end
    -- DST 玩家实体自带 userid（同一个人跨存档一致）
    return player.userid
end

-- 能不能寄（只做"物品本身"的判断；容量判断在 MoveItem 里）
function M.CanMail(item)
    if item == nil or not item:IsValid() then return false end
    if item.components.container ~= nil then return false end          -- 不寄容器
    if item.components.inventoryitem == nil then return false end
    for _, t in ipairs(M.NO_MAIL_TAGS) do
        if item:HasTag(t) then return false end
    end
    return true
end

-- 物品当前在谁手里（背包 / 容器）
function M.Holder(item)
    local iio = item ~= nil and item.components.inventoryitem or nil
    return iio ~= nil and iio.owner or nil
end

-- 把一个物品从原处搬到目标容器的指定格
--   返回 true = 搬成功
function M.MoveItem(item, dest_container, slot)
    if item == nil or dest_container == nil then return false end
    if not item:IsValid() then return false end
    local holder = M.Holder(item)
    if holder ~= nil then
        if holder.components.inventory ~= nil then
            holder.components.inventory:RemoveItem(item)
        elseif holder.components.container ~= nil then
            holder.components.container:RemoveItem(item)
        end
    end
    return dest_container:GiveItem(item, slot) == true
end

-- ★★ 2026-09-20 修「寄出去了、包里却没清掉」的根因：
--   老写法靠 item.components.inventoryitem.owner 找回"原容器"再 RemoveItem ——
--   物品躺在容器（信差包）里时 owner 不一定指向那个容器，于是"摘不掉"；
--   紧接着 GiveItem 到收件箱又成功了 → 同一件东西同时挂在包和收件箱上（看着就是没清掉）。
--   正解：谁在遍历、就从谁那一格拿 —— 容器自己 RemoveItemBySlot(slot) 一定拿得掉。
function M.TakeFromSlot(container, slot)
    if container == nil or slot == nil then return nil end
    if container.slots == nil or container.slots[slot] == nil then return nil end
    return container:RemoveItemBySlot(slot)
end

-- 在收件箱里找一个"已解锁 + 空着"的格子
function M.BoxFreeSlot(shadow)
    local c = shadow ~= nil and shadow.components.container or nil
    if c == nil then return nil end
    local unlocked = shadow.unlocked or M.BOX_SLOT_INIT
    for i = 1, math.min(unlocked, M.BOX_GRID_SLOTS) do
        if c.slots[i] == nil then return i end
    end
    return nil
end

-- 把一件东西寄进收件箱。返回 true = 成功
function M.TryDeliver(shadow, item)
    if shadow == nil or not shadow:IsValid() then return false end
    if not M.CanMail(item) then return false end
    local slot = M.BoxFreeSlot(shadow)
    if slot == nil then return false end                    -- 满了 → 不寄（用户定：满了就停，不丢东西）
    return M.MoveItem(item, shadow.components.container, slot)
end

-- 在 (x,y,z) 附近找"这个玩家自己的"收件箱
function M.FindShadow(x, y, z, userid)
    if userid == nil then return nil end
    local ents = TheSim:FindEntities(x, y, z, 10, { M.SHADOW_TAG })
    for _, e in ipairs(ents or {}) do
        if e:IsValid() and e.owner_userid == userid then
            return e
        end
    end
    return nil
end

-- ★ 2026-09-20：找"眼前可以当我收件箱"的影子
--   ① 我自己的（owner_userid == 我）→ 直接用
--   ② 没有我自己的，但脚边躺着"没主的"影子 → 认领它（老存档 bug 把 owner_userid 丢了的孤儿，别再造一个）
--   返回 shadow, need_claim（need_claim=true = 调用方要给它写上 owner_userid）
function M.ClaimNearbyShadow(x, y, z, userid)
    if userid == nil then return nil, false end
    local ents = TheSim:FindEntities(x, y, z, 10, { M.SHADOW_TAG })
    local orphan = nil
    for _, e in ipairs(ents or {}) do
        if e:IsValid() then
            if e.owner_userid == userid then return e, false end
            if e.owner_userid == nil and orphan == nil then orphan = e end
        end
    end
    if orphan ~= nil then return orphan, true end
    return nil, false
end

-- ★ 2026-09-20：世界范围内找"我的收件箱"（不受 10 格半径限制）
--   用途：区分「收件箱在别的信箱那儿」和「我的收件箱真的没了」——
--   后者必须能就地重建，否则玩家会永远卡在"绑过但摸不到"。
--   ⚠️ 只在服务端调；半径给足（DST 世界最大也就 2000 上下）
function M.FindMyShadowAnywhere(userid)
    if userid == nil then return nil end
    local ents = TheSim:FindEntities(0, 0, 0, 5000, { M.SHADOW_TAG })
    for _, e in ipairs(ents or {}) do
        if e:IsValid() and e.owner_userid == userid then
            return e
        end
    end
    return nil
end

-- 玩家背包里所有的信差包（⚠️ 服务端 Inventory 没有 GetItems()，用 ForEachItem）
function M.FindBags(player)
    local out = {}
    local inv = player ~= nil and player.components.inventory or nil
    if inv == nil then return out end
    inv:ForEachItem(function(item)
        if item:HasTag(M.BAG_TAG) then
            table.insert(out, item)
        end
    end)
    -- 手上那件也算
    local hand = inv:GetEquippedItem(EQUIPSLOTS.HANDS)
    if hand ~= nil and hand:HasTag(M.BAG_TAG) then
        table.insert(out, hand)
    end
    return out
end

return M
