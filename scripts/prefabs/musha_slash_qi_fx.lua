-- ============================================================
-- 剑气斩特效（slash_qi）—— 直线飞行 + 命中炸开消散（2026-09-14 v9）
--
--   ★ 机制 = 原版 projectile 组件（直线飞，无重力/无弹道）
--     · 参考：遗迹守卫 mod 的 mecha_x_projectile.lua；原版 blowdart / boomerang 也是它
--     · 它只认**实体**目标（Throw 里会调 target:GetPosition()），所以落点用隐形实体当靶子：
--       prefabs/musha_skill_point.lua（无 health/combat → combat.lua:1122 直接 return，安全）
--     · ⚠️ projectile 和 complexprojectile **互斥**（共用 "projectile" tag），别同时加
--
--   ★ 素材三选一（FX_ART）
--     jimeng   = 自己的剑气图 anim/slash_fx.zip（单帧，动画名 anim）—— 观感偏"刀光/冲击波"
--     crescent = 原版真月牙 anim/crabking_claw_swipe_fx.zip（4 帧一次性动画 atk1）★ 现用这个
--     vanilla  = 原版暗影抛射体 anim/shadow_thrall_projectile_fx.zip（pre/loop/impact）
--   2026-09-14 用户：「冲击波 改月牙」→ FX_ART 从 jimeng 改成 crescent（真月牙形状）。
--   想换成自己画的亮青月牙：先打包 exported/crescent_cyan/crescent_cyan.scml → anim/crescent_cyan.zip，
--   再把下面 FX_ART 改成 "cyan"（一行）。
--
--   ★ 消散 = 动画淡出 + 本地粒子（2026-09-14 v9，用户选的方案②）
--     饥荒没给 mod 通用粒子发射器（AddParticleEmitter 这种引擎 API 不存在），
--     但**原版 FX 的粒子都是"不联网的本地实体"**（看 hitsparks_fx / explode_small：
--     `--[[Non-networked entity]]` + `if not TheNet:IsDedicated() then 本地生成` + animover 自毁）。
--     这套写法零网络开销，12 个粒子对 CPU 完全无压力（对比：把粒子做成联网实体才会卡，
--     这就是某些粒子 mod 吃 CPU 的原因）。
--     触发链：服务端命中 → net_event:push() → 每个客户端各自本地生成粒子（服务端不发一个字节）。
--     粒子素材直接用我们自己的 slash_fx（已经打包好、且 modmain 里全局声明了，客户端一定有）。
-- ============================================================

local FX_ART = "cyan"      -- 2026-09-14 用户已打包 anim/crescent_cyan.zip（自己的亮青月牙）→ 换过来
                           -- 备选：jimeng（旧图，像刀光/冲击波） / crescent（原版真月牙，蟹王爪击） / vanilla（暗影抛射体）

local ART = ({
    -- jimeng 的 scale 说明：素材画布 512x512，但可见的剑气只占 305x171（约 60%x33%）
    --   · 0.30 → 屏幕上只有 ≈0.9x0.5 世界单位（太小，就是"大小不明"的原因）
    --   · 0.80 → ≈2.4x1.4 世界单位（约 0.6 格宽）★ 现在用这个
    --   · 想更大就往 1.0 走（≈3.0x1.7 单位，接近一格宽）
    jimeng   = { bank = "slash_fx",                  build = "slash_fx",                  pre = "anim",            fly = "anim",            hit = "anim",             scale = 0.80, bloom = false },

    -- ★ 自己画的亮青月牙（2026-09-14，exported/crescent_cyan/）
    --   可见 487x389 → scale 0.45 ≈ 2.2x1.75 世界单位（正好一道大月牙）
    --   打包：exported/crescent_cyan/crescent_cyan.scml → anim/crescent_cyan.zip，然后把 FX_ART 改成 "cyan"
    --   换 B(厚月牙)/C(双弧)：把 exported/crescent_cyan/crescent_b_thick.png 或 _c_double.png
    --     复制成 crescent_cyan-0.png，重新导一次 scml 即可（代码不用动）
    cyan     = { bank = "crescent_cyan",             build = "crescent_cyan",             pre = "anim",            fly = "anim",            hit = "anim",             scale = 0.45, bloom = true },

    crescent = { bank = "crabking_claw_swipe_fx",    build = "crabking_claw_swipe_fx",    pre = "atk1",            fly = "atk1",            hit = "atk1",             scale = 0.30, bloom = false },
    vanilla  = { bank = "shadow_thrall_projectile_fx", build = "shadow_thrall_projectile_fx", pre = "projectile_pre", fly = "projectile_loop", hit = "projectile_impact", scale = 1, bloom = false },
})[FX_ART]      -- ⚠️ 外面这对括号不能省：Lua 5.1 不许「表构造后面直接跟索引」

-- ===== 飞行手感（想调就动这里）=====
local FX_SPEED      = 45                      -- 飞行速度（直线）
local FX_RANGE      = 12                      -- 最远飞多少格（对齐技能的 MAX_RANGE），飞满即消失
local FX_HIT_DIST   = 0.6                     -- 离落点多近算命中
local FX_LAUNCH_AT  = Vector3(1.0, 1.25, 0)   -- 出手位置
local FX_LIFETIME   = 3                       -- 兜底自毁（秒）
local FX_ROT_OFFSET = 0                       -- 贴图朝向补偿（度）
local FX_COLOUR     = nil                     -- 本体染色 {r,g,b}，nil = 原色

-- ===== 命中炸开 FX（联网的那一个，整个命中只发这一个）=====
local FX_BURST        = "hitsparks_fx"        -- 备选：moonstorm_spark / dustmeringue / explode_small
local FX_BURST_SCALE  = 1.2
local FX_BURST_COLOUR = nil                   -- {r,g,b}，nil = 原色

-- ===== 消散：本体淡出 + 本地粒子 =====
local FX_FADE_TIME      = 0.18                -- 本体淡出时长（秒）；0 = 直接消失
local FX_PARTICLE_COUNT = 12                  -- 粒子个数（12 个本地实体完全无压力；想更花别超 24）
local FX_PARTICLE_LIFE  = 0.35                -- 粒子寿命（秒）
local FX_PARTICLE_SPEED = { 3.5, 7.0 }        -- 初速范围（世界单位/秒）
local FX_PARTICLE_UP    = { 1.0, 3.5 }        -- 初始向上速度范围
local FX_PARTICLE_GRAV  = 14                  -- 粒子下落加速度
local FX_PARTICLE_SCALE = { 0.16, 0.02 }      -- 起止大小（相对素材）
local FX_PARTICLE_SPIN  = 260                 -- 自转速度（度/秒）
local FX_PARTICLE_COLOUR = nil                -- 粒子染色 {r,g,b}，nil = 原色

local assets =
{
    Asset("ANIM", "anim/" .. ART.bank .. ".zip"),
}

-- 在指定位置放一下"炸开"（拿不到就悄悄跳过，不影响技能）
local function SpawnBurst(x, y, z)
    if FX_BURST == nil or FX_BURST == "" then return end
    local ok, fx = pcall(SpawnPrefab, FX_BURST)
    if not ok or fx == nil then
        if not SpawnBurst._warned then
            SpawnBurst._warned = true
            print("[Musha] 剑气炸开 FX 取不到：" .. tostring(FX_BURST))
        end
        return
    end
    fx.Transform:SetPosition(x, y or 0, z)
    if FX_BURST_SCALE ~= 1 then
        fx.Transform:SetScale(FX_BURST_SCALE, FX_BURST_SCALE, FX_BURST_SCALE)
    end
    if FX_BURST_COLOUR ~= nil and fx.AnimState ~= nil then
        fx.AnimState:SetMultColour(FX_BURST_COLOUR[1], FX_BURST_COLOUR[2], FX_BURST_COLOUR[3], 1)
    end
end

-- ★ 本地粒子：只在客户端生成、不联网、自毁（照原版 FX 那套写法）
--   纯 Lua 推进（每帧改 Transform）：不做碰撞、不进网络 → 12 个的开销比一个正经实体还低
local function SpawnLocalParticles(x, y, z)
    if TheNet ~= nil and TheNet:IsDedicated() then return end
    local bank = ART.bank
    local dt = 1 / 30
    for _ = 1, FX_PARTICLE_COUNT do
        local p = CreateEntity()                     -- 不 AddNetwork = 本地实体
        p:AddTag("FX")
        p:AddTag("NOCLICK")
        p.entity:AddTransform()
        p.entity:AddAnimState()
        p.entity:SetCanSleep(false)                  -- FX 一律不休眠

        local ok = pcall(function()
            p.AnimState:SetBank(bank)
            p.AnimState:SetBuild(bank)
            p.AnimState:PlayAnimation(ART.fly)
            p.AnimState:SetLightOverride(1)
        end)
        if not ok then p:Remove() else
            p.Transform:SetPosition(x, (y or 0) + 0.4 + math.random() * 0.5, z)
            p.Transform:SetRotation(math.random() * 360)

            local ang = math.random() * 2 * math.pi
            local spd = FX_PARTICLE_SPEED[1] + math.random() * (FX_PARTICLE_SPEED[2] - FX_PARTICLE_SPEED[1])
            local vx, vz = math.cos(ang) * spd, math.sin(ang) * spd
            local vy = FX_PARTICLE_UP[1] + math.random() * (FX_PARTICLE_UP[2] - FX_PARTICLE_UP[1])
            local t = 0
            if FX_PARTICLE_COLOUR ~= nil then
                p.AnimState:SetMultColour(FX_PARTICLE_COLOUR[1], FX_PARTICLE_COLOUR[2], FX_PARTICLE_COLOUR[3], 1)
            end

            p:DoPeriodicTask(dt, function(e)
                if not e:IsValid() then return end
                t = t + dt
                local k = t / FX_PARTICLE_LIFE
                if k >= 1 then
                    e:Remove()
                    return
                end
                local px, py, pz = e.Transform:GetWorldPosition()
                vy = vy - FX_PARTICLE_GRAV * dt
                e.Transform:SetPosition(px + vx * dt, py + vy * dt, pz + vz * dt)
                local s = FX_PARTICLE_SCALE[1] + (FX_PARTICLE_SCALE[2] - FX_PARTICLE_SCALE[1]) * k
                e.AnimState:SetScale(s, s, s)
                e.Transform:SetRotation(e.Transform:GetRotation() + FX_PARTICLE_SPIN * dt)
                e.AnimState:SetMultColour(1, 1, 1, 1 - k)
            end)
        end
    end
end

-- 命中/打空时：每个客户端各自炸开 + 撒粒子（服务端只发一个 net_event）
local function OnBurstDirty(inst)
    if TheNet ~= nil and TheNet:IsDedicated() then return end
    -- 去重：主机上 net_event 的本地回响和小段补发可能撞在一起
    local now = GetTime()
    if inst._lastburst ~= nil and now - inst._lastburst < 2 * FRAMES then return end
    inst._lastburst = now

    local x, y, z = inst.Transform:GetWorldPosition()
    SpawnBurst(x, y, z)
    SpawnLocalParticles(x, y, z)
end

-- 淡出消散（没有粒子发射器，就是 alpha 逐帧往下压）
local function FadeOutAndRemove(inst)
    if FX_FADE_TIME <= 0 then
        inst:Remove()
        return
    end
    local t = 0
    local step = 0.03
    inst:DoPeriodicTask(step, function(i)
        if not i:IsValid() then return end
        t = t + step
        local a = 1 - t / FX_FADE_TIME
        if a <= 0 then
            i:Remove()
        elseif i.AnimState ~= nil then
            i.AnimState:SetMultColour(1, 1, 1, a)
        end
    end)
end

-- 收尾：清掉落点靶子 + 自己
local function Cleanup(inst, playimpact)
    if inst.musha_marker ~= nil and inst.musha_marker:IsValid() then
        inst.musha_marker:Remove()
        inst.musha_marker = nil
    end
    if not inst:IsValid() then return end
    if playimpact and ART.hit ~= ART.fly then
        inst.AnimState:PlayAnimation(ART.hit)
        inst:ListenForEvent("animover", function(i) FadeOutAndRemove(i) end)
    else
        FadeOutAndRemove(inst)
    end
end

-- 命中（原版 projectile 回调签名 = inst, attacker, target）
local function OnHit(inst, attacker, target)
    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("rifts2/thrall_wings/projectile")
    end
    if inst.cast_hit then          -- 伤害结算在武器技能那边（musha_weapon_skill.OnFxHit）
        inst.cast_hit(inst)
    end
    if inst._qi_burst ~= nil then
        inst._qi_burst:push()      -- ★ 通知所有客户端：炸开 + 撒粒子
    end
    Cleanup(inst, true)
end

-- 打空（飞满射程）：也炸一下再消散，只是不结算伤害
local function OnMiss(inst, attacker, target)
    if inst._qi_burst ~= nil then
        inst._qi_burst:push()
    end
    Cleanup(inst, false)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddPhysics()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)     -- 不跟地形/建筑碰撞（代价：也会穿墙）

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("projectile")        -- 原版 projectile 组件要求
    -- ⚠️ 千万别加 "complexprojectile"：跟 projectile 互斥

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank(ART.bank)
    inst.AnimState:SetBuild(ART.build)
    inst.AnimState:PlayAnimation(ART.pre)
    inst.AnimState:SetLightOverride(1)
    if ART.scale ~= 1 then
        inst.AnimState:SetScale(ART.scale, ART.scale, ART.scale)
    end
    if ART.bloom then
        -- 亮部辉光：亮青月牙靠它才有"在发光"的感觉（原版 FX 常用这招）
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end
    if FX_COLOUR ~= nil then
        inst.AnimState:SetMultColour(FX_COLOUR[1], FX_COLOUR[2], FX_COLOUR[3], 1)
    end

    -- ★ 命中信号（必须建在 SetPristine 之前）：服务端 push，各客户端各自本地出特效
    inst._qi_burst = net_event(inst.GUID, "musha_qi.burst", "musha_qi_burstdirty")
    inst:ListenForEvent("musha_qi_burstdirty", OnBurstDirty)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:PushAnimation(ART.fly)

    inst:AddComponent("projectile")
    local p = inst.components.projectile
    p:SetSpeed(FX_SPEED)
    p:SetHoming(false)              -- ★ 直线：出手朝向落点，之后不再转向
    p:SetRange(FX_RANGE)            -- 飞满就 Miss
    p:SetHitDist(FX_HIT_DIST)
    p:SetLaunchOffset(FX_LAUNCH_AT)
    p:SetOnHitFn(OnHit)
    p:SetOnMissFn(OnMiss)
    p:SetOnThrownFn(function(i, owner)
        i.owner = owner
        if FX_ROT_OFFSET ~= 0 then
            i.Transform:SetRotation(i.Transform:GetRotation() + FX_ROT_OFFSET)
        end
    end)

    -- 兜底：既没命中也没 Miss 也自己收尾
    inst:DoTaskInTime(FX_LIFETIME, function(i)
        if i:IsValid() then Cleanup(i, false) end
    end)

    return inst
end

return Prefab("musha_slash_qi_fx", fn, assets)
