-- ============================================================
-- musha_weapon_skill.lua —— 武器绑定的技能（v1：剑气斩）
-- 2026-09-13 新建；方案见 musha-weapon-skill-plan.md
--
-- 设计要点（用户 2026-09-13 拍板）：
--   · 技能绑在【武器】上，不绑职业；4 个候选武器技能，玩家自选 2 个（"4 选 2"的选人 UI 后做）
--   · 战士主战主动技只有 1 个，其余都是被动 / 耍戏
--   · **服务端权威**：客户端只报"我要放技能 + 瞄哪一点"，
--     校验（拿的是不是这把武器 / 冷却）/ 伤害 / 命中判定 全在服务端算
--   · 主机（自己当服主）直接调服务端函数，不走 RPC
--
-- 加新武器的技能 = 在下面 SKILLS 里加一行（key 用武器的 tag 或 prefab 名）
-- 调手感 = 只动下面的常量
-- ============================================================

local WeaponSkill = {}

-- ============ 手感常量（想调只动这里）============
WeaponSkill.CAST_KEY     = KEY_F     -- 施放键（v1 先写死 F；以后接 musha_keyhandler 的 skill_1 让玩家可改键）
WeaponSkill.COOLDOWN     = 6         -- 冷却（秒）
WeaponSkill.DAMAGE_MULT  = 1.2       -- 伤害 = 武器伤害 × 这个（走 combat:CalcDamage，武器精通会一起算进去）
WeaponSkill.HIT_RADIUS   = 1.6       -- 剑气命中判定半径（世界单位）
WeaponSkill.LAUNCH_DIST  = 0.6       -- 出手点离身位多远（太近会贴脸）
WeaponSkill.MAX_RANGE    = 12        -- 瞄点最远（防乱点屏幕外）

-- ============ 技能表：武器 → 技能 ============
--   key：武器的 tag（优先）或 prefab 名
--   生命树枝 / 水晶剑 以后在这里各加一行（等美术 + 数值定下来）
WeaponSkill.SKILLS = {
    musha_sword = { id = "slash_qi", name = "剑气斩", fx = "musha_slash_qi_fx" },
}

-- ============ 内部工具 ============
local function GetCDTable(doer)
    doer._musha_wskill_cd = doer._musha_wskill_cd or {}
    return doer._musha_wskill_cd
end

local function Say(doer, msg)
    if doer and doer:IsValid() and doer.components.talker then
        doer.components.talker:Say(msg, 3)
    end
end

-- 手里拿的武器对应哪个技能（返回 def, weapon）
function WeaponSkill.GetWeaponSkill(doer)
    if not (doer and doer:IsValid() and doer.components.inventory) then return nil, nil end
    local weapon = doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if not weapon then return nil, nil end
    for tag, def in pairs(WeaponSkill.SKILLS) do
        if weapon:HasTag(tag) then return def, weapon end
    end
    local def = WeaponSkill.SKILLS[weapon.prefab]
    if def then return def, weapon end
    return nil, weapon
end

-- 还剩几秒冷却 —— ★ 优先读武器自带的 rechargeable 组件（原版格式，每把武器各自计），
--   武器没挂这个组件时才退回"玩家身上那张手写表"（兜底，别删）
function WeaponSkill.GetCooldownLeft(doer, weapon, skill_id)
    if weapon ~= nil and weapon.components ~= nil and weapon.components.rechargeable ~= nil then
        return weapon.components.rechargeable:GetTimeToCharge()
    end
    local until_t = GetCDTable(doer)[skill_id]
    if not until_t then return 0 end
    return math.max(0, until_t - (GetTime() or 0))
end

-- 伤害：优先用 combat:CalcDamage（会把武器精通等乘区一起算上）
--   万一这个 API 在本版本不叫这名 → 退回 武器伤害 × 倍率，并日志提醒一次
local _calc_warned = false
function WeaponSkill.ComputeDamage(doer, target, weapon)
    local mult = WeaponSkill.DAMAGE_MULT
    local dmg
    local ok, err = pcall(function()
        dmg = doer.components.combat:CalcDamage(target, weapon, mult)
    end)
    if not ok or type(dmg) ~= "number" or dmg <= 0 then
        if not _calc_warned then
            _calc_warned = true
            print("[Musha] combat:CalcDamage 用不了（" .. tostring(err) .. "）→ 退回 武器伤害×倍率 兜底")
        end
        local base = 20
        if weapon and weapon.components.weapon then
            base = weapon.components.weapon:GetDamage(doer, target) or base
        end
        dmg = base * mult
    end
    return dmg
end

-- 命中结算：剑气落地时扫一圈
function WeaponSkill.OnFxHit(fx)
    local doer  = fx.owner
    local def   = fx.musha_skill
    if not (doer and doer:IsValid() and def) then return end

    local x, y, z = fx.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, WeaponSkill.HIT_RADIUS, nil,
        { "FX", "NOCLICK", "INLIMBO", "player", "playerghost", "DECOR" })

    local hit = 0
    for _, t in ipairs(ents) do
        local ok = t:IsValid() and t ~= doer
            and t.components.combat and t.components.health
            and not t.components.health:IsDead()
        if ok then
            -- 不打自己的随从/跟班
            local f = t.components.follower
            if f and f:GetLeader() == doer then ok = false end
        end
        if ok then
            local dmg = WeaponSkill.ComputeDamage(doer, t, fx.musha_weapon)
            t.components.combat:GetAttacked(doer, dmg, fx.musha_weapon)
            hit = hit + 1
        end
    end
    if hit > 0 then
        print("[Musha] " .. tostring(def.name) .. " 命中 " .. hit .. " 个目标")
    end
end

-- ============ 服务端：施放 ============
function WeaponSkill.DoCast(doer, target_pos)
    if not (doer and doer:IsValid()) then return false end

    local def, weapon = WeaponSkill.GetWeaponSkill(doer)
    if not def then return false end          -- 手里没这把武器 → 静默（免得刷屏）

    local left = WeaponSkill.GetCooldownLeft(doer, weapon, def.id)
    if left > 0 then
        -- ★ 2026-09-14 用户：冷却不要弹提示（"冷却中（还剩 X 秒）"删掉）。
        --   官方口径 = 冷却期间右键**根本进不了瞄准圈**（武器 prefab 里把 rechargeable
        --   和 aoetargeting:SetEnabled 绑一起了）→ 这里静默失败即可，一个字都别说。
        return false
    end

    -- 瞄点：没给就按角色面向推出去
    local x, y, z = doer.Transform:GetWorldPosition()
    if target_pos == nil then
        local ang = (doer.Transform:GetRotation() or 0) * DEGREES
        target_pos = Vector3(x - math.sin(ang) * WeaponSkill.MAX_RANGE, 0,
                             z + math.cos(ang) * WeaponSkill.MAX_RANGE)
    end

    -- 限距 + 单位方向
    local dx, dz = target_pos.x - x, target_pos.z - z
    local d = math.sqrt(dx * dx + dz * dz)
    if d < 0.01 then return false end
    if d > WeaponSkill.MAX_RANGE then
        dx, dz = dx / d * WeaponSkill.MAX_RANGE, dz / d * WeaponSkill.MAX_RANGE
        d = WeaponSkill.MAX_RANGE
        target_pos = Vector3(x + dx, 0, z + dz)
    end
    local ux, uz = dx / d, dz / d

    local fx = SpawnPrefab(def.fx)
    if not fx then
        Say(doer, def.name .. " 特效没生成（检查 prefab 名）")
        return false
    end
    fx.Transform:SetPosition(x + ux * WeaponSkill.LAUNCH_DIST, y, z + uz * WeaponSkill.LAUNCH_DIST)
    fx.musha_skill  = def
    fx.musha_weapon = weapon
    fx.owner        = doer                      -- ★ 原版 projectile 不会自己写 inst.owner，命中回调要用
    fx.cast_hit = function(f) WeaponSkill.OnFxHit(f) end

    -- 原版 projectile（直线那套）只认**实体**目标 → 在落点放个隐形靶子给它
    local lp_x, lp_z = x + ux * d, z + uz * d
    local marker = SpawnPrefab("musha_skill_point")
    if marker ~= nil and fx.components.projectile ~= nil then
        marker.Transform:SetPosition(lp_x, 0, lp_z)
        fx.musha_marker = marker
        fx.components.projectile:Throw(doer, marker, doer)   -- (owner, target, attacker)
    else
        -- 兜底：靶子/组件没起来 → 直接贴着落点结算，别把技能吞掉
        if marker ~= nil then marker:Remove() end
        fx.Transform:SetPosition(lp_x, 0, lp_z)
        WeaponSkill.OnFxHit(fx)
        fx:Remove()
    end

    -- 开冷却：武器带 rechargeable 就走它（原版格式，每把武器各自计），没有才退回手写表
    if weapon ~= nil and weapon.components ~= nil and weapon.components.rechargeable ~= nil then
        weapon.components.rechargeable:Discharge(WeaponSkill.COOLDOWN)
    else
        GetCDTable(doer)[def.id] = (GetTime() or 0) + WeaponSkill.COOLDOWN
    end
    return true
end

-- ============ 客户端入口 ============
--   主机：直接调服务端函数；客机：把瞄点发给服务端（服务端自己校验）
function WeaponSkill.ClientCast(player)
    if not (player and player:IsValid()) then return end

    local pos = nil
    if TheInput and TheInput.GetWorldPosition then
        local ok, mx, my, mz = pcall(function()
            local a, b, c = TheInput:GetWorldPosition()
            return a, b, c
        end)
        if ok and type(mx) == "number" then
            pos = Vector3(mx, 0, mz or 0)
        end
    end

    if TheWorld and TheWorld.ismastersim then
        WeaponSkill.DoCast(player, pos)
    else
        -- 没有瞄点就发哨兵值（-9999）
        SendModRPCToServer(GetModRPC("musha", "musha_weapon_skill_cast"),
            pos and pos.x or -9999, pos and pos.z or -9999)
    end
end

return WeaponSkill
