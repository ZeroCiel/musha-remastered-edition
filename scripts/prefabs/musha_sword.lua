-- 文件: scripts/prefabs/musha_sword.lua
-- musha_sword — 职业剑，攻击力42，攻击距离0.4
--
-- ============================================================
-- 素材自检（2026-09-16 加，跟便签/生命树枝同一套规矩）
--   新剑 art = anim/musha_sword.zip（重剑，艾尔之光风；工程在 exported/musha_sword_v2/）。
--   zip 还没打包时**不能**登记 Asset（RegisterPrefabs 阶段 assert → 整个 mod 被禁），
--   也不能 OverrideSymbol 一个不存在的 build → 回退用原版战矛占位（旧行为）。
-- ============================================================
local function asset_exists(path)
    local f = softresolvefilepath or (GLOBAL ~= nil and GLOBAL.softresolvefilepath)
    if f == nil then return false end
    local ok, resolved = pcall(f, path)
    return ok and resolved ~= nil
end

local HAS_SWORD_ART = asset_exists("anim/musha_sword.zip")
if not HAS_SWORD_ART then
    print("[Musha] 职业剑：anim/musha_sword.zip 还没打包 → 先借原版战矛占位（不会崩），打包后自动换成重剑")
end

local assets = {
    Asset("ATLAS", "images/inventoryimages/musha_sword.xml"),
    Asset("IMAGE", "images/inventoryimages/musha_sword.tex"),
}
if HAS_SWORD_ART then
    table.insert(assets, Asset("ANIM", "anim/musha_sword.zip"))
else
    table.insert(assets, Asset("ANIM", "anim/swap_spear.zip"))   -- 兜底占位
end

-- ============================================================
-- 技能门控（2026-09-14）—— 「右键不出瞄准圈」的两个条件
--   ① 冷却：官方口径（playercontroller.lua:1609 TryAOETargeting 读 aoetargeting:IsEnabled()）
--      Discharge（开始冷却）→ SetEnabled(false) → net_bool 同步给客机 → 右键无反应、不弹字
--      冷却结束 → SetEnabled(true)
--   ② 加点学习（2026-09-14 新增，用户：剑气斩改 3 级加点学习）：
--      职业组件里 saber.slash_qi 等级为 0（没学过）→ 也不给进圈
--      学到后职业组件会 push "musha_skill_changed"（UpgradeSkill 里）→ 这里重新对齐
--   ⚠️ SetEnabled 只在服务端生效（内部有 if TheWorld.ismastersim），客机只是读 net_bool，别在客机上调。
--   ⚠️ 关闭时原版还会顺手 StopTargeting()（正在瞄准会被踢出圈），正是我们要的。
-- ============================================================
local function IsSkillLearned(item)
    local owner = item ~= nil and item._musha_owner or nil
    if owner == nil then return true end          -- 还没装上/异常 → 别锁死（宁可给放）
    local ok, WS = pcall(require, "musha_weapon_skill")
    if not ok or type(WS) ~= "table" or WS.GetSkillLevel == nil then return true end
    local def = WS.SKILLS ~= nil and WS.SKILLS[item.prefab] or nil
    if def == nil or def.tree == nil then return true end
    return WS.GetSkillLevel(owner, def) >= 1
end

local function RefreshSkillGate(item)
    local at = item ~= nil and item.components.aoetargeting or nil
    local rc = item ~= nil and item.components.rechargeable or nil
    if at ~= nil then
        at:SetEnabled((rc == nil or rc:IsCharged()) and IsSkillLearned(item))
    end
end

local function on_equip(inst, owner)
    if HAS_SWORD_ART then
        -- 新重剑：符号名 = scml 里 <timeline name> = `swap_sword`
        --   ★ 命名规矩（照 musha_lifebranch → swap_lifebranch）：swap_ 前缀 + 去掉 musha
        owner.AnimState:OverrideSymbol("swap_object", "musha_sword", "swap_sword")
    else
        owner.AnimState:OverrideSymbol("swap_object", "swap_spear", "swap_spear")   -- 兜底占位
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    inst._musha_owner = owner
    -- 加点学到技能后要重新开门（事件由职业组件 UpgradeSkill 推；服务端设 net_bool 就能同步给客机）
    local cb = function() RefreshSkillGate(inst) end
    inst._musha_skill_cb = cb
    owner:ListenForEvent("musha_skill_changed", cb)

    RefreshSkillGate(inst)      -- 换/装武器时对齐冷却开关（读档后重装也能修正）

    -- ★ 2026-09-16 修「登录后技能放不出来，要装/卸两次才行」的**时序保险**：
    --   OnEquip 有可能跑在"职业组件 OnLoad 读完技能等级"之前 → 那一瞬间技能等级还是 0 → 门被关。
    --   → 隔一帧再对齐一次；同时职业组件读完数据后也会广播 musha_skill_changed（两条一起兜）。
    if inst._musha_gate_task ~= nil then inst._musha_gate_task:Cancel() end
    inst._musha_gate_task = owner:DoTaskInTime(0, function()
        inst._musha_gate_task = nil
        RefreshSkillGate(inst)
    end)
end

local function on_unequip(inst, owner)
    if inst._musha_gate_task ~= nil then
        inst._musha_gate_task:Cancel()
        inst._musha_gate_task = nil
    end
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    if inst._musha_skill_cb ~= nil then
        owner:RemoveEventCallback("musha_skill_changed", inst._musha_skill_cb)
        inst._musha_skill_cb = nil
    end
    inst._musha_owner = nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    -- 世界/掉落形态（2026-09-16）：有了自己的 build 才设 bank/build；没打包时不设
    -- （地上就先不显示，但不崩 —— 之前 mod 被禁就是栽在"素材没打包却登记/引用"）
    if HAS_SWORD_ART then
        inst.AnimState:SetBank("musha_sword")
        inst.AnimState:SetBuild("musha_sword")
        inst.AnimState:PlayAnimation("idle")
    end

    inst:AddTag("musha_weapon")

    -- ============================================================
    -- 武器技能（剑气斩）—— 2026-09-14 v4：改走【女武神战矛那套 AoE 格式】
    --   原版样板：prefabs/spear_wathgrithr.lua（闪电战矛）、prefabs/spear_gungnir.lua（冈格尼尔）
    --   ★ AoE 右键的硬要求（三条，缺一条右键就永远不出）：
    --     1) aoetargeting 必须在 SetPristine() **之前**加 —— 客机要直接读
    --        item.components.aoetargeting（playercontroller:TryAOETargeting），
    --        没有它 → 右键不进瞄准圈 → componentactions 的 aoespell 分支开头就 return
    --     2) SetRange(距离)：CAST AOE 的可用距离取自这个值（playeractionpicker 读 GetRange()）
    --     3) 服务端还要 aoespell + SetSpellFn；动作注册靠"组件存在 + actionreplica 同步"
    --        （见 componentactions.lua: AddComponentAction / RegisterComponentActions）
    --   右键流程（原版手感）：右键按一下 → 进瞄准圈 → 再点地面 → 出现「剑气斩」→ 释放
    --   ⚠️ 千万别加 tag "aoeweapon_lunge"：SGwilson 的 CASTAOE handler 一看这 tag 就会
    --      把动作转成 combat_lunge_start（角色冲刺出去）—— 那是女武神的位移版，我们不位移
    -- ============================================================
    local ok_ws, WS_MOD = pcall(require, "musha_weapon_skill")
    local SKILL_RANGE = (ok_ws and type(WS_MOD) == "table" and WS_MOD.MAX_RANGE) or 12

    inst:AddComponent("aoetargeting")
    if inst.components.aoetargeting ~= nil then
        inst.components.aoetargeting:SetAllowRiding(false)   -- 骑牛时不摆（原版女武神也关）
        inst.components.aoetargeting:SetRange(SKILL_RANGE)   -- 技能最大距离
        local ret = inst.components.aoetargeting.reticule
        if ret ~= nil then
            ret.mouseenabled = true        -- 瞄准圈跟着鼠标（不然只能键盘推）
            ret.ease = true
        end
    end

    -- 武器组件（客户端也需要知道 attack range）
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- 武器组件
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(42)
    inst.components.weapon:SetRange(0.8)     -- ★ 2026-09-16 用户：重剑射程改 0.8（原 0.4）

    -- 可装备（武器栏）
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(on_equip)
    inst.components.equippable:SetOnUnequip(on_unequip)
    inst.components.equippable.walkspeedmult = 1.0

    -- 背包物品
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/musha_sword.xml"
    inst.components.inventoryitem.imagename = "musha_sword"

    -- 可堆叠/可丢
    inst:AddComponent("inspectable")

    -- ============================================================
    -- 武器绑定的技能 —— 剑气斩（2026-09-14 v4：女武神战矛那套 AoE 格式）
    --   ★ aoespell 的 SetSpellFn 签名是 (item, doer, pos)，
    --     跟法杖那条 spellcaster 的 (item, target, pos) **不一样** ——
    --     原版 AOESpell:CastSpell(doer, pos) 会把施法者一起传进来，不用自己从 owner 取。
    --   数值（冷却 / 伤害倍率 / 命中半径 / 最大距离）在 scripts/musha_weapon_skill.lua 文件头。
    --   以后别的武器要加技能：照抄这一段（+ 上面 aoetargeting 那段）。
    -- ============================================================
    inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(function(item, doer, pos)
        local ok, WS = pcall(require, "musha_weapon_skill")
        if not ok or type(WS) ~= "table" then return false, "NO_MODULE" end
        if not (doer ~= nil and doer:IsValid()) then return false, "NO_DOER" end
        local target_pos = nil
        if pos ~= nil then
            local px, py, pz = pos:Get()
            target_pos = Vector3(px, 0, pz)
        end
        return WS.DoCast(doer, target_pos)
    end)

    -- 技能冷却：走武器自带的【rechargeable】组件（原版格式，女武神战矛那套）
    --   ★ 2026-09-14 改：以前是"服务端在玩家身上存一张冷却表"，没走武器自己的组件。
    --     换这套的好处：① 每个武器实例各自计冷却（多把武器/换武器互不影响）
    --                   ② 状态会同步给客户端（以后接 UI 变暗、或冷却期禁用 aoetargeting 都行）
    --                   ③ 原版会 OnSave/OnLoad，存档也带着冷却
    --   · Discharge(秒) = 开始冷却；GetTimeToCharge() = 还剩几秒；IsCharged() = 好了没
    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(function(item)
        -- 冷却开始 → 关掉 AoE 瞄准（右键不出圈；原版也会顺手把正在瞄的圈收掉）
        RefreshSkillGate(item)
    end)
    inst.components.rechargeable:SetOnChargedFn(function(item)
        -- 冷却结束 → 恢复
        RefreshSkillGate(item)
    end)

    -- 读档时 rechargeable 是「静默恢复」（OnLoad 里 SetCharge 不触发回调）→
    -- 包一层 OnLoad 手动刷一次，免得存档里带冷却的武器重进游戏后右键还能进圈
    local _rc = inst.components.rechargeable
    local _rc_onload = _rc.OnLoad
    _rc.OnLoad = function(self, data, newents)
        if _rc_onload ~= nil then _rc_onload(self, data, newents) end
        RefreshSkillGate(inst)
    end

    RefreshSkillGate(inst)      -- 建出来先对齐一次（新武器 = 已充能 = 可放）

    return inst
end

return Prefab("musha_sword", fn, assets)
