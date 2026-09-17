-- 文件: scripts/prefabs/musha_lifebranch.lua
-- musha_lifebranch — 生命树枝（武器）
--   来源：天数奖励第 10 天那把武器（见 musha-dayrewards-plan.md：攻击 12，可升级，满级区间 18~24）
--   ★ 升级机制按计划「延后」（要抄"可移动携带的火堆"那套，原型还没找到）→ 现在固定 12，
--     留在下面的 LIFE_DAMAGE 常量里，机制定下来只改这里 + 加升级组件。
--   ★ 手上可持 = 抄剑那套 swap_object 覆盖（原版白拿的机制），见 on_equip / on_unequip。
--   ★ 攻击距离 0.4（跟剑一样）。tag 挂 musha_weapon，以后武器技能（剑气斩那套）靠它绑定。

-- ============================================================
-- 素材自检测（2026-09-14 事故修复）
--   事故：PrefabFiles 里一加进来、但 anim/*.zip 还没打包 →
--         注册资源时直接 "Could not find an asset matching anim/musha_lifebranch.zip"
--         → **整个 mod 被游戏禁用**（连带别的功能全没了）。
--   修法：用原版全局 softresolvefilepath()（util.lua:645，不崩版本，找不到返回 nil）
--         先探一下文件在不在，不在就跳过那几项资源 → 不崩；
--         等打包完放进 anim/ 和 images/inventoryimages/，进游戏就自动全功能，**不用再改代码**。
--   日志里会打一行 [Musha] 生命树枝：... 告诉你缺哪几样。
-- ============================================================
local function asset_exists(path)
    -- softresolvefilepath 是原版全局（util.lua:645）；保险起见两种取法都试
    local f = softresolvefilepath or (GLOBAL ~= nil and GLOBAL.softresolvefilepath)
    if f == nil then return false end
    local ok, resolved = pcall(f, path)
    return ok and resolved ~= nil
end

local HAS_ITEM_ART = asset_exists("anim/musha_lifebranch.zip")
-- ★★ 2026-09-17 用户选「4A」：地上(idle) + 手上(swap_lifebranch) **合并进同一个 zip/bank**
--   合并包 = anim/musha_lifebranch.zip（bank/build = musha_lifebranch，内含 2 个 symbol）
--   工程在 exported/musha_lifebranch/musha_lifebranch.scml（合并版；旧的世界单帧版备份成
--   musha_lifebranch.scml.bak_世界单帧_20260917）→ 用 Mod Tool / scml.exe 编译覆盖 anim/musha_lifebranch.zip
--   ⚠️ 合并包一导好，手上就从这个 build 取 symbol（旧的 anim/swap_lifebranch.zip 不再需要）
--   想回退成"手上用单独的 swap_lifebranch.zip"：把下面这行改成 false
local LIFE_ART_MERGED = true
local HAS_SWAP_ART
if LIFE_ART_MERGED then
    HAS_SWAP_ART = HAS_ITEM_ART                                   -- 合并包：symbol 就在同一个包里
else
    HAS_SWAP_ART = asset_exists("anim/swap_lifebranch.zip")
end
local HAS_ICON     = asset_exists("images/inventoryimages/musha_lifebranch.xml")
                     and asset_exists("images/inventoryimages/musha_lifebranch.tex")

if not (HAS_ITEM_ART and HAS_SWAP_ART and HAS_ICON) then
    print("[Musha] 生命树枝：素材还没打包，先当空壳跑（不会崩）。缺："
        .. (HAS_ITEM_ART and "" or " anim/musha_lifebranch.zip")
        .. (HAS_SWAP_ART and "" or " anim/swap_lifebranch.zip")
        .. (HAS_ICON and "" or " images/inventoryimages/musha_lifebranch.{xml,tex}"))
end

local LIFE_DAMAGE = 12      -- 基础攻击（升级机制没做，先固定）
local LIFE_RANGE  = 0.4     -- 攻击距离（跟剑一致）

-- ===== 装备被动（2026-09-16 用户口述设定，原设定漏档、这次补上）=====
--   每秒恢复 0.2 生命 + 每 24 秒 +0.1 精神，**必须装备（武器位）才生效**。
--   （用户原话：原本想做"衣服"（BODY 位），但和「人格」冲突，改放到武器位）
--   想调数值只改这三行：LIFE_REGEN 越大回血越快 / SANITY_REGEN 与 SANITY_INTERVAL 是"每多少秒加多少精神"
local LIFE_REGEN      = 0.2
local SANITY_REGEN    = 0.1
local SANITY_INTERVAL = 24
local REGEN_CAUSE     = "musha_lifebranch"

-- 装上：起两个周期任务（回血 / 回精神）；卸下：全部取消
local function stop_regen(inst)
    if inst._regen_task then inst._regen_task:Cancel(); inst._regen_task = nil end
    if inst._sanity_task then inst._sanity_task:Cancel(); inst._sanity_task = nil end
end

local function start_regen(inst, owner)
    stop_regen(inst)
    if not owner then return end
    inst._regen_task = owner:DoPeriodicTask(1, function(o)
        if o and o:IsValid() and o.components.health
           and not o.components.health:IsDead() and not o:HasTag("playerghost") then
            o.components.health:DoDelta(LIFE_REGEN, false, REGEN_CAUSE)
        end
    end)
    -- ⚠️ 2026-09-16 修崩：原写成 `o.components.sanity:IsDead()` —— **sanity 组件没有 IsDead**
    --   （只有 health 组件有；EntityScript 也没有）→ 每 24 秒那次必崩：
    --   "attempt to call method 'IsDead' (a nil value)"。判死统一走 health，跟上面回血那条同口径。
    inst._sanity_task = owner:DoPeriodicTask(SANITY_INTERVAL, function(o)
        if o and o:IsValid() and o.components.sanity
           and (o.components.health == nil or not o.components.health:IsDead())
           and not o:HasTag("playerghost") then
            o.components.sanity:DoDelta(SANITY_REGEN, false, REGEN_CAUSE)
        end
    end)
end

local assets = {}
if HAS_ITEM_ART then table.insert(assets, Asset("ANIM", "anim/musha_lifebranch.zip")) end
-- 合并模式不再单独加载 swap 包（symbol 已在上面那个 zip 里）
if (not LIFE_ART_MERGED) and HAS_SWAP_ART then
    table.insert(assets, Asset("ANIM", "anim/swap_lifebranch.zip"))
end
if HAS_ICON then
    table.insert(assets, Asset("ATLAS", "images/inventoryimages/musha_lifebranch.xml"))
    table.insert(assets, Asset("IMAGE", "images/inventoryimages/musha_lifebranch.tex"))
end

-- ===== 手持效果（原版机制：把角色手部的 swap_object 符号换成树枝）=====
--   第一参数固定 "swap_object"；第二参数 = build 名（= swap_lifebranch.zip 里的 build）；
--   第三参数 = 该 build 里的 sprite 名（= swap_lifebranch.png 去扩展名）
local function on_equip(inst, owner)
    if HAS_SWAP_ART then
        if LIFE_ART_MERGED then
            -- ★ 2026-09-17 合并包：build 名 = musha_lifebranch（不再是单独的 swap_lifebranch 包）
            owner.AnimState:OverrideSymbol("swap_object", "musha_lifebranch", "swap_lifebranch")
        else
            owner.AnimState:OverrideSymbol("swap_object", "swap_lifebranch", "swap_lifebranch")
        end
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    start_regen(inst, owner)        -- ★ 装备被动：每秒回血 + 每 24 秒回精神（仅装备时生效）
end

local function on_unequip(inst, owner)
    stop_regen(inst)                -- ★ 卸下即停
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    -- 物品自体动画（掉地上时显示；bank/build 名 = anim/musha_lifebranch.zip 的名字）
    -- ★ 素材没打包时不能 SetBank（同样会 assert）→ 用自检测挡住
    if HAS_ITEM_ART then
        inst.AnimState:SetBank("musha_lifebranch")
        inst.AnimState:SetBuild("musha_lifebranch")
        inst.AnimState:PlayAnimation("idle")
    end

    -- 武器技能以后靠这个 tag 绑定（见 scripts/musha_weapon_skill.lua 的 SKILLS 表）
    inst:AddTag("musha_weapon")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- 武器组件
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(LIFE_DAMAGE)
    inst.components.weapon:SetRange(LIFE_RANGE)

    -- 可装备（武器栏）+ 手持效果
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(on_equip)
    inst.components.equippable:SetOnUnequip(on_unequip)
    inst.components.equippable.walkspeedmult = 1.0

    -- 背包物品（图标；图标没打包时不设 atlasname，只是显示空白，不会崩）
    inst:AddComponent("inventoryitem")
    if HAS_ICON then
        inst.components.inventoryitem.atlasname = "images/inventoryimages/musha_lifebranch.xml"
        inst.components.inventoryitem.imagename = "musha_lifebranch"
    end

    -- 检查（看物品信息）
    inst:AddComponent("inspectable")

    -- 物品被销毁时收掉周期任务（不然回血/回精神会一直挂着）
    inst:ListenForEvent("onremove", function() stop_regen(inst) end)

    return inst
end

return Prefab("musha_lifebranch", fn, assets)
