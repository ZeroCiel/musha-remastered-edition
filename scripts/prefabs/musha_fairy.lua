-- ============================================================
-- 小灵（精灵伙伴）—— 粒子汇聚出场的胆怯小精灵（2026-09-27 v1）
--
-- ★ 它是什么
--   一只由 36 颗光点组成的光灵精灵：
--     · 玩家登场 / 重生 / 下洞穴回来时，在玩家周围 20 格内随机出生（modmain 召唤）
--     · 光点从四周汇聚，按剪影拼出精灵形状（圆头 + 薄翼 + 光尾，约 1.7 秒）
--     · 然后精灵飘向玩家，停在 2~3 格外（胆怯不贴脸），常驻漂浮跟随
--     · 自带光源（夜里照亮一小圈），新手期（职业 1 级）见面会冒字打招呼、引导职业
--
-- ★ 联网结构（关键：粒子零网络开销）
--   - 本体（本 prefab）= 联网实体：服务端生成 → 所有玩家可见。
--     本体没有动画（形态全靠粒子），只有 Light（发光）+ 空 AnimState（给冒字用）
--   - 光点粒子 = 每个客户端各自的**本地实体**（照剑气斩消散粒子同款写法：
--     不 AddNetwork、SetCanSleep(false)、DoPeriodicTask 推进、本体没了就自毁）
--     → 服务端不发送任何粒子数据，36 个本地实体开销可控
--   - 触发方式：客户端收到本体创建时（common fn 在两端都跑），
--     `not TheWorld.ismastersim` 分支本地生成粒子群（SetParent 挂在本体下，
--     本体移动粒子跟着走，无需额外同步）
--
-- ★ 出场编排
--   0.0s    本体在玩家周围随机点生成（服务端，modmain）
--   0.0s    各客户端本地生成 36 颗光点：从本体周围随机位置出发
--   0~1.4s  光点沿弧线飞向剪影落点（easeOut：先快后慢）
--   1.4~1.7s 定形：全体闪亮一下，进入漂浮呼吸态
--   1.7s起  服务端把本体飘向玩家（每帧缓动），到害羞距离停住
--   约2.8s  新手期玩家：冒字打招呼 + 职业引导（胆怯语气）
--
-- ★ 服务端 ↔ 本体的握手：modmain 召唤后 PushEvent("musha_fairy_bind", {leader=玩家})，
--   本体在这里绑主人并开始问候——不往全局环境挂任何函数（项目规矩）
--
-- ★ 想调的参数都在 CONFIG 区，改数值即可；台词都在 FAIRY_LINES
-- ============================================================

local SIL = nil
do
    local ok, mod = pcall(require, "musha_fairy_silhouette")
    if ok and mod and mod.points then
        SIL = mod
    else
        print("[Musha] 小灵剪影表加载失败（musha_fairy_silhouette），精灵退化成单点光球")
        SIL = { points = { { x = 0, y = 0.6, s = 1.2 } }, total = 1 }
    end
end

-- ===== CONFIG（想调手感改这里） =====
local CONFIG = {
    FLY_TIME       = 1.4,      -- 光点汇聚飞行时长（秒）
    SETTLE_TIME    = 0.3,      -- 定形闪亮时长（秒）
    FOLLOW_DIST    = 2.5,      -- 害羞跟随距离（格）：到这么远就停住
    SHY_DISTANCE   = 1.6,      -- 玩家逼近到这个距离内，精灵往后缩
    FLY_HEIGHT     = 0.7,      -- 漂浮高度（格，本体锚点离地）
    BOB_AMP        = 0.14,     -- 漂浮上下幅度
    PARTICLE_SCALE = 0.055,    -- 光点基础大小（相对素材；s 字段是每颗的乘数）
    COLOUR         = { 0.62, 0.93, 1.0 },  -- 青白月光色（和剑气月牙同色系）
    LIGHT_RADIUS   = 2.2,      -- 光照半径（格）
    LIGHT_INTENSITY = 0.72,
    FLY_DT         = 1 / 30,   -- 汇聚期推进步长
    IDLE_DT        = 1 / 12,   -- 常驻期推进步长（降频省 CPU）
    SAY_FIRST_LEVEL = 1,       -- 职业等级 ≤ 这个值时算「新手期」，见面打招呼
    GREET_DELAY    = 2.8,      -- 出场后多久开始说话（秒）
    CHAT_INTERVAL  = { 90, 150 },  -- 常驻问候间隔范围（秒）
    CHAT_NEAR      = 4.0,      -- 玩家在这个距离内才问候
    FORM_TIME      = nil,      -- （内部）汇聚+定形总时长，fn 里算
}
CONFIG.FORM_TIME = CONFIG.FLY_TIME + CONFIG.SETTLE_TIME

-- ===== 台词（胆怯害羞风；想改语气直接改这里） =====
local FAIRY_LINES = {
    greet_new = {   -- 新手期第一次见面（两句连续说）
        "那、那个……你好……我是小灵……",
        "你的职业……想看看吗……就在上面的面板里……",
    },
    guide = {       -- 新手期引导（跟在打招呼后面）
        "先转职……再学技能……面板里都有……我、我就在这陪着你……",
    },
    greet_back = {  -- 老玩家登场
        "又、又见面了……",
        "欢迎回来……嗯……",
    },
    check_in = {    -- 常驻问候（随机一句）
        "今天……怎么样……？",
        "嗯……还好吗……我一直在这边……",
        "不、不要突然冲过来呀……会吓到我……",
        "嗯……今天的光……很舒服……",
    },
}

local FX_ART = "slash_fx"   -- 光点素材：mod 自带剑气图（缩小 + 染色当光斑，全端可用）

local assets =
{
    Asset("ANIM", "anim/" .. FX_ART .. ".zip"),
}

-- 5.1 没有 math.clamp，自己兜一个
local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- ---------------------------------------------------------------------------
-- 客户端：本地光点粒子群（汇聚 → 定形 → 常驻漂浮；单状态机一个 task 走完）
-- ---------------------------------------------------------------------------

-- easeOutQuad：先快后慢，粒子「冲到位」而不是匀速爬
local function ease_out(k)
    k = clamp(k, 0, 1)
    return 1 - (1 - k) * (1 - k)
end

local function SpawnLocalParticles(inst)
    if TheNet ~= nil and TheNet:IsDedicated() then return end
    if inst._fairy_particles_born then return end
    inst._fairy_particles_born = true

    local cr, cg, cb = CONFIG.COLOUR[1], CONFIG.COLOUR[2], CONFIG.COLOUR[3]
    inst._fairy_particles = {}

    for i, pt in ipairs(SIL.points) do
        local p = CreateEntity()                     -- 不 AddNetwork = 本地实体
        p:AddTag("FX")
        p:AddTag("NOCLICK")
        p.entity:AddTransform()
        p.entity:AddAnimState()
        p.entity:SetCanSleep(false)                  -- FX 一律不休眠（照剑气斩写法）

        local ok = pcall(function()
            p.AnimState:SetBank(FX_ART)
            p.AnimState:SetBuild(FX_ART)
            p.AnimState:PlayAnimation("anim", true)  -- 单帧循环 = 静态光斑
            p.AnimState:SetLightOverride(1)          -- 无视光照，黑暗里也亮
            p.AnimState:SetMultColour(cr, cg, cb, 0) -- 起手全透明，飞出时渐显
        end)
        if not ok then
            p:Remove()
        else
            p.entity:SetParent(inst.entity)          -- 挂到本体下：本体移动粒子跟着

            -- 出生点：本体周围随机球面（半径 1.5~3 格），高度 -0.5~1.5
            local ang = math.random() * 2 * math.pi
            local r = 1.5 + math.random() * 1.5
            local sx, sy, sz = math.cos(ang) * r, -0.5 + math.random() * 2.0, math.sin(ang) * r
            local tx, ty, tz = pt.x or 0, pt.y or 0.6, 0
            local scale = CONFIG.PARTICLE_SCALE * (pt.s or 1)
            local arc = 0.35 + math.random() * 0.5   -- 弧线抬升幅度（每颗不同）
            local phase = math.random() * math.pi * 2
            local t = 0
            local frames = 0

            -- 单状态机：fly → settle → idle（一个 task 走完，不嵌套不泄漏）
            p:DoPeriodicTask(CONFIG.FLY_DT, function(e)
                if not e:IsValid() then return end
                if not inst:IsValid() then           -- 本体没了：粒子自毁（保险）
                    e:Remove()
                    return
                end
                t = t + CONFIG.FLY_DT
                frames = frames + 1

                if t < CONFIG.FLY_TIME then
                    -- 阶段 1：沿弧线飞向剪影落点（先快后慢）
                    local k = t / CONFIG.FLY_TIME
                    local ek = ease_out(k)
                    local x = sx + (tx - sx) * ek
                    local y = sy + (ty - sy) * ek + math.sin(k * math.pi) * arc
                    local z = sz + (tz - sz) * ek
                    e.Transform:SetPosition(x, y, z)
                    e.AnimState:SetScale(scale * (0.55 + 0.45 * k), scale * (0.55 + 0.45 * k), scale * (0.55 + 0.45 * k))
                    e.AnimState:SetMultColour(cr, cg, cb, math.min(1, k * 3))
                elseif t < CONFIG.FORM_TIME then
                    -- 阶段 2：定形闪亮（尺寸脉冲 + 全亮）
                    local k = (t - CONFIG.FLY_TIME) / CONFIG.SETTLE_TIME
                    local pulse = 1 + 0.45 * math.sin(k * math.pi)
                    e.Transform:SetPosition(tx, ty, tz)
                    e.AnimState:SetScale(scale * pulse, scale * pulse, scale * pulse)
                    e.AnimState:SetMultColour(cr, cg, cb, 1)
                elseif frames % 3 ~= 0 then
                    -- 阶段 3 的降频：常驻期每 3 帧才更新一次（10Hz，漂浮游走足够顺滑）
                    return
                else
                    -- 阶段 3：常驻漂浮（局部小幅游走 + 亮度呼吸）
                    local it = t - CONFIG.FORM_TIME
                    e.Transform:SetPosition(
                        tx + math.sin(it * 0.9 + phase) * 0.035,
                        ty + math.sin(it * 1.3 + phase) * 0.05,
                        tz + math.cos(it * 0.8 + phase) * 0.03)
                    local glow = 0.72 + 0.28 * math.sin(it * 1.1 + phase)
                    e.AnimState:SetMultColour(cr, cg, cb, glow)
                end
            end)
            table.insert(inst._fairy_particles, p)
        end
    end
end

-- 本体被移除时清掉所有本地粒子（防泄漏）
local function CleanupParticles(inst)
    if inst._fairy_particles ~= nil then
        for _, p in ipairs(inst._fairy_particles) do
            if p:IsValid() then p:Remove() end
        end
        inst._fairy_particles = nil
    end
end

-- ---------------------------------------------------------------------------
-- 服务端：跟随玩家 + 害羞后缩 + 说话
-- ---------------------------------------------------------------------------

local function SayLines(inst, lines)
    if inst.components.talker == nil then return end
    for i, text in ipairs(lines) do
        inst:DoTaskInTime((i - 1) * 2.6, function()
            if inst:IsValid() and inst.components.talker ~= nil then
                pcall(function() inst.components.talker:Say(text, 3.2, true) end)
            end
        end)
    end
end

local function PickLine(t)
    if t == nil or #t == 0 then return nil end
    return t[math.random(#t)]
end

-- 每帧跟随：目标 = 玩家周围 2.5 格 + 漂浮；玩家逼近 → 往外缩（害羞）
-- 精灵在玩家哪一侧就停哪一侧（用当前连线方向），稳定不绕圈
local function FollowLeader(inst, dt)
    local leader = inst._fairy_leader
    if leader == nil or not leader:IsValid() then return end
    -- 出场编排：先原地等光点拼形（1.7s），再开始飘向玩家
    if inst._fairy_born_time ~= nil and GetTime() - inst._fairy_born_time < CONFIG.FORM_TIME then
        return
    end
    local t = GetTime()
    local px, py, pz = leader.Transform:GetWorldPosition()
    local fx, fy, fz = inst.Transform:GetWorldPosition()

    local dx, dz = fx - px, fz - pz
    local dist = math.sqrt(dx * dx + dz * dz)
    if dist > 0.01 then
        dx, dz = dx / dist, dz / dist          -- 单位方向（玩家 → 精灵）
    else
        dx, dz = math.cos(t * 0.3), math.sin(t * 0.3)
    end
    local want_dist = CONFIG.FOLLOW_DIST
    -- 害羞后缩：玩家冲太近 → 目标距离拉大（精灵自己往后飘）
    if dist < CONFIG.SHY_DISTANCE then
        want_dist = CONFIG.SHY_DISTANCE + 1.2
    end
    -- 玩家在跑（本帧位移大）→ 精灵稍微跟远一点，飘起来更自然
    if inst._fairy_last_leader_pos ~= nil then
        local lx, ly, lz = inst._fairy_last_leader_pos[1], inst._fairy_last_leader_pos[2], inst._fairy_last_leader_pos[3]
        local moved = math.sqrt((px - lx) ^ 2 + (pz - lz) ^ 2) / math.max(dt, 0.001)
        if moved > 4 then
            want_dist = want_dist + 1.0
        end
    end
    inst._fairy_last_leader_pos = { px, py, pz }

    local tx, tz = px + dx * want_dist, pz + dz * want_dist
    local ty = CONFIG.FLY_HEIGHT + math.sin(t * 1.3) * CONFIG.BOB_AMP
    -- 缓动靠近（出生十几格 → 害羞距离，越近越慢）
    local k = clamp(dt * 2.2, 0, 1)
    inst.Transform:SetPosition(fx + (tx - fx) * k, fy + (ty - fy) * k, fz + (tz - fz) * k)
end

-- 出场编排（服务端）：新手期打招呼 + 职业引导 / 老玩家问好
local function StartGreeting(inst, leader)
    inst:DoTaskInTime(CONFIG.GREET_DELAY, function()
        if not inst:IsValid() or not leader:IsValid() then return end
        local is_new = false
        local comp = leader.components ~= nil and leader.components.musha_profession_component or nil
        if comp ~= nil and comp.userdata ~= nil and comp.userdata.level ~= nil then
            is_new = comp.userdata.level <= CONFIG.SAY_FIRST_LEVEL
        end
        if is_new then
            SayLines(inst, FAIRY_LINES.greet_new)
            inst:DoTaskInTime(#FAIRY_LINES.greet_new * 2.6, function()
                if inst:IsValid() and leader:IsValid() then
                    SayLines(inst, FAIRY_LINES.guide)
                end
            end)
        else
            local line = PickLine(FAIRY_LINES.greet_back)
            if line ~= nil then SayLines(inst, { line }) end
        end
    end)
    -- 常驻问候：随机间隔，玩家在附近才说
    inst:DoPeriodicTask(math.random(CONFIG.CHAT_INTERVAL[1], CONFIG.CHAT_INTERVAL[2]), function(e)
        if not e:IsValid() or not leader:IsValid() then return end
        local x1, y1, z1 = e.Transform:GetWorldPosition()
        local x2, y2, z2 = leader.Transform:GetWorldPosition()
        local d = math.sqrt((x1 - x2) ^ 2 + (z1 - z2) ^ 2)
        if d <= CONFIG.CHAT_NEAR then
            local line = PickLine(FAIRY_LINES.check_in)
            if line ~= nil then SayLines(inst, { line }) end
        end
    end)
end

-- ---------------------------------------------------------------------------
-- prefab 主体
-- ---------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()      -- 空动画：不渲染本体，只给冒字/引擎留位置
    inst.entity:AddNetwork()

    -- 发光（两端同参数，Light 随实体走；夜里照亮一小圈）
    inst.entity:AddLight()
    inst.Light:SetRadius(CONFIG.LIGHT_RADIUS)
    inst.Light:SetIntensity(CONFIG.LIGHT_INTENSITY)
    inst.Light:SetColour(CONFIG.COLOUR[1], CONFIG.COLOUR[2], CONFIG.COLOUR[3])
    inst.Light:SetFlicker(0.03)
    inst.Light:Enable(true)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")          -- 不可点选：灵体不挡操作
    inst.persists = false           -- 不进存档：每次登场重新出场（正合「登场自动播」）

    -- 冒字组件（两端都装，原版 NPC 同款——客机也要能看到精灵说话）
    inst:AddComponent("talker")
    inst.components.talker.fontsize = 22
    inst.components.talker.colour = Vector3(CONFIG.COLOUR[1], CONFIG.COLOUR[2], CONFIG.COLOUR[3])

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        -- 客户端：本地生成粒子群 + 出场
        inst:DoTaskInTime(0, SpawnLocalParticles)
        inst:ListenForEvent("onremove", CleanupParticles)
        return inst
    end

    inst._fairy_leader = nil
    inst._fairy_born_time = GetTime()
    inst:ListenForEvent("onremove", CleanupParticles)

    -- 主人绑定（modmain 召唤后推事件；不往全局环境挂函数）
    inst:ListenForEvent("musha_fairy_bind", function(inst2, data)
        if data ~= nil and data.leader ~= nil then
            inst2._fairy_leader = data.leader
            StartGreeting(inst2, data.leader)
        end
    end)

    -- 跟随推进（每帧）
    inst:DoPeriodicTask(FRAMES, function(e)
        if e:IsValid() and e._fairy_leader ~= nil then
            FollowLeader(e, FRAMES)
        end
    end)

    return inst
end

return Prefab("musha_fairy", fn, assets)
