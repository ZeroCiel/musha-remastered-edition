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
-- ★ 2026-09-14 用户：「F 容易误触」→ **按键触发已停用**
--   （modmain.lua 里那块 TheInput:AddKeyHandler 监听已被注释掉，别再挂回去）
--   技能现在只走**右键原版 AoE 路径**（右键 → 瞄准圈 → 点地 → 出「剑气斩」）。
--   CAST_KEY / 下面的 ClientCast() 现在没人调用，留着备用。
WeaponSkill.CAST_KEY     = KEY_F     -- （已停用）施放键；要恢复按键先跟用户确认
WeaponSkill.COOLDOWN     = 12        -- 兜底冷却（秒；读不到技能等级时用）
WeaponSkill.DAMAGE_MULT  = 1.2       -- ★ 兜底倍率（只在拿不到技能等级时用；正常走下面的 MULT_BY_LEVEL）

-- ★ 2026-09-14 用户拍板：伤害按【技能等级】走 —— 草案里的 100% / 130% / 160% 就是这套
--   命中伤害 = 武器伤害 × 倍率（走 combat:CalcDamage，武器精通会一起算进去）
--   等级读的是职业组件的技能树（和耗能量同一个源）→ 没学过/读不到就按 Lv1 的 100%
WeaponSkill.MULT_BY_LEVEL = { 1.00, 1.30, 1.60 }
WeaponSkill.HIT_RADIUS   = 1.6       -- 剑气命中判定半径（世界单位）
-- ★ 2026-09-17 出手几何**统一成一个参数**（用户 + 外部评审都指出"两套参数打架"）：
--   以前：前后距离用 LAUNCH_DIST=0.6，而 FX 文件里又写了 FX_LAUNCH_AT=(1.0,1.60)，其中 x=1.0 根本没人读
--   → 改一个地方没用、看着像"位置不对"。现在**唯一来源** = LAUNCH_OFFSET(前后, 上下, 0)：
--   起点用它、落点靶子高度也用它。调手感只改这一行。
WeaponSkill.LAUNCH_OFFSET = Vector3(1.0, 1.30, 0)
WeaponSkill.MAX_RANGE    = 12        -- 瞄点最远（防乱点屏幕外）

-- ============ ★ 技能能量消耗（2026-09-14 用户拍板）============
--   每放一次的耗能量随【技能等级】递减：Lv1 18 → Lv2 16 → Lv3 14
--   加点门槛（角色等级）= 3 / 7 / 12，写在 scripts/skills/musha_skill_data.lua 的 req_lv
--   ⚠️ 技能等级组件 components/musha_skills 目前还是 .bak（未启用）→ 读不到等级就按 Lv1 的 18 点算
--   数值来源：musha_mp（服务端组件，netvar 同步，客户端 badge 画那个能量球）
WeaponSkill.COST_BY_LEVEL = { 18, 16, 14 }

-- ★ 2026-09-16 用户：冷却改成**按技能等级**递减 —— Lv1 12 → Lv2 9 → Lv3 7.6（秒）
--   想改只动这一行；某把武器要单独定 → 在 SKILLS 那行加 cooldowns = { ... } 覆盖
WeaponSkill.COOLDOWN_BY_LEVEL = { 12, 9, 7.6 }

-- ============ 技能表：武器 → 技能 ============
--   key：武器的 tag（优先）或 prefab 名
--   tree / skill：连到【职业组件】的技能树节点（加点学习的那棵树）——
--     tree  = 哪个树（warrior/saber/…），skill 不写就按 id 取
--     ★ 2026-09-14：剑气斩已"加点学习"上架 → 没学过（等级 0）右键不给放
--   生命树枝 / 水晶剑 以后在这里各加一行（等美术 + 数值定下来）
--   想给某把武器单独定消耗 → 在这一行里加 cost = { ... }（覆盖上面的 COST_BY_LEVEL）
WeaponSkill.SKILLS = {
    musha_sword = { id = "slash_qi", name = "剑气斩", fx = "musha_slash_qi_fx", tree = "saber" },
}

-- 这个技能在【职业组件】里练到几级了（0 = 没学）
--   ★ 真源 = components/musha_profession_component 的 self[tree][skill]（面板技能页读的就是它）
--   ⚠️ 别再去找 components/musha_skills —— 那个组件还是 .bak（未启用），永远读不到
function WeaponSkill.GetSkillLevel(doer, def)
    local pc = (doer ~= nil and doer.components ~= nil)
        and doer.components.musha_profession_component or nil
    if pc == nil or def == nil or def.tree == nil then return 0 end
    local tree = pc[def.tree]
    local node = tree ~= nil and tree[def.skill or def.id] or nil
    return (node ~= nil and node.current_level) or 0
end

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

-- 命中倍率：按技能等级取（1.00 / 1.30 / 1.60）；拿不到等级 → 兜底 DAMAGE_MULT
function WeaponSkill.GetDamageMult(doer, def)
    local mults = (def ~= nil and def.damage_mult) or WeaponSkill.MULT_BY_LEVEL
    if mults == nil or #mults == 0 then return WeaponSkill.DAMAGE_MULT end
    local lv = WeaponSkill.GetSkillLevel(doer, def)
    if lv < 1 then lv = 1 end
    if lv > #mults then lv = #mults end
    return mults[lv] or WeaponSkill.DAMAGE_MULT
end

-- 伤害：优先用 combat:CalcDamage（会把武器精通等乘区一起算上）
--   万一这个 API 在本版本不叫这名 → 退回 武器伤害 × 倍率，并日志提醒一次
local _calc_warned = false
function WeaponSkill.ComputeDamage(doer, target, weapon, def)
    local mult = WeaponSkill.GetDamageMult(doer, def)
    -- ★ 2026-09-16：万一 weapon 参数丢了（fx 上没存到），现查一遍手里的武器 ——
    --   否则 combat:CalcDamage 会按"空手默认伤害(10)"算 → 表现就是"打不死鸟"
    if weapon == nil then
        local _, w = WeaponSkill.GetWeaponSkill(doer)
        weapon = w
    end
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

    local x, _, z = fx.Transform:GetWorldPosition()
    -- ★ 2026-09-14 修「打不中」：以前拿 fx 自己的高度当球心（出手在 y≈1.25）→
    --   TheSim:FindEntities 是 **3D 球**搜索，球心悬在 1.25 高时，地面上的敌人只有
    --   水平半径 ≈1.0 能被扫到（1.6 的判定圈凭空缩掉 40%）→ 体感就是"剑气从怪身上穿过去"。
    --   改成用**地平面** y=0 搜索（怪都站在地面上）。
    -- ★★ 2026-09-16 修「一刀发出去连鸟都打不死」：
    --   老写法 = 以地面 y=0 为球心、半径 1.6 的 **3D 球** 直接搜 → 会飞的单位（鸟、蜜蜂、
    --   蝴蝶这类 y 在 2~4 的目标）根本不在球里 → 剑气从它们身上"穿过去"，一只都扫不到。
    --   现在：**大球搜（半径 +8，够得着空中的）+ 2D(XZ) 精确筛**（水平距离 ≤ HIT_RADIUS 才算命中）
    --   → 高度不再影响命中，水平范围依旧精准。
    local ents = TheSim:FindEntities(x, 0, z, WeaponSkill.HIT_RADIUS + 8, nil,
        { "FX", "NOCLICK", "INLIMBO", "player", "playerghost", "DECOR" })

    local hit = 0
    local R2 = WeaponSkill.HIT_RADIUS * WeaponSkill.HIT_RADIUS
    for _, t in ipairs(ents) do
        local ok = t:IsValid() and t ~= doer
            and t.components.combat and t.components.health
            and not t.components.health:IsDead()
        if ok then
            -- ★ 2D（XZ）精确筛：水平距离在判定圈里才算 —— 高度不参与，飞在天上的也算
            local tx, _, tz = t.Transform:GetWorldPosition()
            local ddx, ddz = tx - x, tz - z
            if ddx * ddx + ddz * ddz > R2 then ok = false end
        end
        if ok then
            -- 不打自己的随从/跟班
            local f = t.components.follower
            if f and f:GetLeader() == doer then ok = false end
        end
        if ok then
            local dmg = WeaponSkill.ComputeDamage(doer, t, fx.musha_weapon, def)
            t.components.combat:GetAttacked(doer, dmg, fx.musha_weapon)
            -- ★ 2026-09-16：每个目标打一行真实伤害（用户报"打不死鸟"时，看这行就知道数值对不对、
            --   到底是"没打中"还是"打了但伤害不对"）——实测完想关就把下面这行注释掉
            print(string.format("[Musha] 剑气斩 → %s 伤害 %.1f（HP %s → %s）",
                tostring(t.prefab),
                dmg,
                tostring(t.components.health ~= nil and math.ceil(t.components.health.currenthealth + dmg) or "?"),
                tostring(t.components.health ~= nil and math.ceil(t.components.health.currenthealth) or "?")))
            hit = hit + 1
        end
    end
    if hit > 0 then
        -- 日志带上倍率/等级，实测时一眼看出是不是按等级走了（100/130/160%）
        print("[Musha] " .. tostring(def.name) .. " 命中 " .. hit .. " 个目标"
            .. "（Lv" .. tostring(WeaponSkill.GetSkillLevel(doer, def))
            .. " ×" .. string.format("%.2f", WeaponSkill.GetDamageMult(doer, def)) .. "）")
    else
        print("[Musha] " .. tostring(def.name) .. " 落地没扫到目标（判定圈 " ..
            tostring(WeaponSkill.HIT_RADIUS) .. "，落点 " .. string.format("%.1f,%.1f", x, z) .. "）")
    end
end

-- 这次施放要花多少能量（按技能等级取；没学过 → 按 Lv1 的值，反正上面会拦住不放）
function WeaponSkill.GetCost(doer, def)
    local costs = (def ~= nil and def.cost) or WeaponSkill.COST_BY_LEVEL
    if costs == nil or #costs == 0 then return 0 end

    local lv = WeaponSkill.GetSkillLevel(doer, def)
    if lv < 1 then lv = 1 end
    if lv > #costs then lv = #costs end
    return costs[lv] or 0
end

-- 这次施放要冷却几秒（按技能等级取；没学过/读不到 → 按 Lv1 的值）
function WeaponSkill.GetCooldown(doer, def)
    local cds = (def ~= nil and def.cooldowns) or WeaponSkill.COOLDOWN_BY_LEVEL
    if cds == nil or #cds == 0 then return WeaponSkill.COOLDOWN end

    local lv = WeaponSkill.GetSkillLevel(doer, def)
    if lv < 1 then lv = 1 end
    if lv > #cds then lv = #cds end
    return cds[lv] or WeaponSkill.COOLDOWN
end

-- ============ 服务端：施放 ============
function WeaponSkill.DoCast(doer, target_pos)
    if not (doer and doer:IsValid()) then return false end

    local def, weapon = WeaponSkill.GetWeaponSkill(doer)
    if not def then return false end          -- 手里没这把武器 → 静默（免得刷屏）

    -- ★ 2026-09-14：加点学习门槛 —— 没学过（等级 0）就不给放，静默（口径同冷却、不弹字）
    --   读的是职业组件的技能树（面板技能页那个）；剑上还挂了 aoetargeting 开关，见 musha_sword
    if def.tree ~= nil and WeaponSkill.GetSkillLevel(doer, def) < 1 then
        return false
    end

    local left = WeaponSkill.GetCooldownLeft(doer, weapon, def.id)
    if left > 0 then
        -- ★ 2026-09-14 用户：冷却不要弹提示（"冷却中（还剩 X 秒）"删掉）。
        --   官方口径 = 冷却期间右键**根本进不了瞄准圈**（武器 prefab 里把 rechargeable
        --   和 aoetargeting:SetEnabled 绑一起了）→ 这里静默失败即可，一个字都别说。
        return false
    end

    -- ★ 2026-09-14 能量校验：不够就静默失败（口径同冷却，不弹字、不提示）
    local mp   = doer.components.musha_mp
    local cost = WeaponSkill.GetCost(doer, def)
    if mp ~= nil and cost > 0 and not mp:CanAfford(cost) then
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
    -- ★ 2026-09-16 修「光斩出门那一下会往下掉」：
    --   ① 原版 projectile:Throw 自己会按 SetLaunchOffset 再 y+1.25（projectile.lua:159-162），
    --      而我们这里又手动设一次位置、y 给的是**角色脚下** → 起点和落点靶子高度口径不一致，
    --      客户端看就是"出门先往下沉一下再找平"。
    --   ② 现在 fx 那边 launchoffset 归零（见 musha_slash_qi_fx.lua），**径向 + 高度全在这里算**：
    --      起点 y = 落点靶子 y = 角色 y + 出手高度 → 直线平飞。
    -- ★ 2026-09-17 出手几何唯一来源 = WeaponSkill.LAUNCH_OFFSET（前后/高度一处改）
    local off = WeaponSkill.LAUNCH_OFFSET
    local ly = (y or 0) + off.y
    fx.musha_launch_y = off.y      -- 落点靶子高度读的就是这个值（不再由 FX 文件决定）
    fx.Transform:SetPosition(x + ux * off.x, ly, z + uz * off.x)
    fx.musha_skill  = def
    fx.musha_weapon = weapon
    fx.owner        = doer                      -- ★ 原版 projectile 不会自己写 inst.owner，命中回调要用
    fx.cast_hit = function(f) WeaponSkill.OnFxHit(f) end

    -- 原版 projectile（直线那套）只认**实体**目标 → 在落点放个隐形靶子给它
    local lp_x, lp_z = x + ux * d, z + uz * d
    local marker = SpawnPrefab("musha_skill_point")
    if marker ~= nil and fx.components.projectile ~= nil then
        -- ★ 2026-09-14 修「打不中」：靶子高度以前写死 0，而月牙是**从 y=1.25 出手**的 →
        --   原版 projectile 每帧按 3D 距离判"到没到"，靶子在地面时最近也差 1.25 >
        --   hitdist(1.0) → **永远判不中**（飞的路上就直接 Range 耗尽 = 空放）。
        --   现在靶子跟出手点**同高**（fx 把出手高度写在 musha_launch_y 里）。
        local launch_y = fx.musha_launch_y or 0
        marker.Transform:SetPosition(lp_x, (y or 0) + launch_y, lp_z)
        fx.musha_marker = marker
        fx.components.projectile:Throw(doer, marker, doer)   -- (owner, target, attacker)
    else
        -- 兜底：靶子/组件没起来 → 直接贴着落点结算，别把技能吞掉
        if marker ~= nil then marker:Remove() end
        fx.Transform:SetPosition(lp_x, 0, lp_z)
        WeaponSkill.OnFxHit(fx)
        fx:Remove()
    end

    -- ★ 扣能量：放在剑气真的出手之后（生成失败/靶子兜底都没走到这里时前面已经 return 了）
    if mp ~= nil and cost > 0 then
        mp:Spend(cost)
    end

    -- 开冷却：武器带 rechargeable 就走它（原版格式，每把武器各自计），没有才退回手写表
    local cd = WeaponSkill.GetCooldown(doer, def)     -- ★ 按技能等级：12 / 9 / 7.6 秒
    if weapon ~= nil and weapon.components ~= nil and weapon.components.rechargeable ~= nil then
        weapon.components.rechargeable:Discharge(cd)
    else
        GetCDTable(doer)[def.id] = (GetTime() or 0) + cd
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
