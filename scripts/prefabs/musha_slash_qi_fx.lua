-- ============================================================
-- 剑气斩特效（slash_qi）—— 月牙/剑气抛射体
-- 素材：原版 anim/shadow_thrall_projectile_fx.zip（暗影系抛射，黑红）
--       ★ 2026-09-12 用户从 8 个候选里选中「2 shadow_thrall_projectile_fx」
-- 移植点：换素材只改下面 5 行常量 + assets 里的 zip 路径，其余逻辑不动
-- 用法（等主动技能框架 ⑤ 接上）：
--   local fx = SpawnPrefab("musha_slash_qi_fx")
--   fx.Transform:SetPosition(px, py, pz)
--   fx.cast_hit = function(f, attacker, target) ... 伤害/命中结算 ... end
--   fx.components.complexprojectile:Launch(target_pos, attacker)
-- ============================================================

-- ★ 2026-09-13 新素材（即梦图抠背后的 512 版，见 exported/slash_fx/）：
--   用法：用 DST Mod Tool 把 exported/slash_fx/slash_fx.scml 打包成 anim/slash_fx.zip，
--         然后把下面 USE_CUSTOM_FX 改成 true（一处开关，其余自动切）
local USE_CUSTOM_FX  = false          -- ← 打包好 zip 后改 true
local CUSTOM_BANK    = "slash_fx"
local CUSTOM_BUILD   = "slash_fx"
local CUSTOM_ANIM    = "anim"         -- scml 里只有这一条单帧动画
local CUSTOM_SCALE   = 0.30           -- 512px × 0.30 ≈ 1.5 世界单位宽（嫌大改小）

local FX_BANK  = USE_CUSTOM_FX and CUSTOM_BANK  or "shadow_thrall_projectile_fx"
local FX_BUILD = USE_CUSTOM_FX and CUSTOM_BUILD or "shadow_thrall_projectile_fx"
local ANIM_PRE = USE_CUSTOM_FX and CUSTOM_ANIM  or "projectile_pre"      -- 出手/蓄势
local ANIM_FLY = USE_CUSTOM_FX and CUSTOM_ANIM  or "projectile_loop"     -- 飞行中
local ANIM_HIT = USE_CUSTOM_FX and CUSTOM_ANIM  or "projectile_impact"   -- 命中爆开

local FX_SPEED     = 13                       -- 水平飞行速度
local FX_GRAVITY   = 0                        -- 0 = 平飞（直线剑气）；要抛物线改 -30
local FX_LAUNCH_AT = Vector3(0, 1, 0)         -- 出手位置偏移（相对施法者朝向）
local FX_LIFETIME  = 1.5                      -- 兜底自毁（秒），防止没打中一直飞

local assets =
{
    Asset("ANIM", USE_CUSTOM_FX and "anim/slash_fx.zip" or "anim/shadow_thrall_projectile_fx.zip"),
}

local function OnHit(inst)
    if inst.components.complexprojectile then
        inst:RemoveComponent("complexprojectile")
    end
    if USE_CUSTOM_FX then
        -- 单帧素材：没有命中动画，短暂停留就消失（要"炸开"再补第二帧/第二张图）
        inst:DoTaskInTime(0.15, inst.Remove)
    else
        inst.AnimState:PlayAnimation(ANIM_HIT)
        inst:ListenForEvent("animover", inst.Remove)
    end
    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("rifts2/thrall_wings/projectile")
    end
    -- ⏭ 伤害结算本体在主动技能框架（⑤）里：框架把自己的回调塞进 inst.cast_hit
    if inst.cast_hit then
        inst.cast_hit(inst)
    end
end

local function OnLaunch(inst, attacker)
    inst.owner = attacker
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddPhysics()

    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:SetCollisionMask(COLLISION.GROUND)
    inst.Physics:SetCapsule(.2, .2)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("projectile")           -- complexprojectile 需要
    inst:AddTag("complexprojectile")

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank(FX_BANK)
    inst.AnimState:SetBuild(FX_BUILD)
    inst.AnimState:PlayAnimation(ANIM_PRE)
    inst.AnimState:SetLightOverride(1)  -- 暗影系素材偏黑，提亮才看得见
    if USE_CUSTOM_FX then
        inst.AnimState:SetScale(CUSTOM_SCALE, CUSTOM_SCALE, CUSTOM_SCALE)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:PushAnimation(ANIM_FLY)

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(FX_SPEED)
    inst.components.complexprojectile:SetGravity(FX_GRAVITY)
    inst.components.complexprojectile:SetLaunchOffset(FX_LAUNCH_AT)
    inst.components.complexprojectile:SetOnLaunch(OnLaunch)
    inst.components.complexprojectile:SetOnHit(OnHit)

    -- 兜底：没打中也要自己消失
    inst:DoTaskInTime(FX_LIFETIME, function(i)
        if i:IsValid() and i.components.complexprojectile then
            OnHit(i)
        end
    end)

    return inst
end

return Prefab("musha_slash_qi_fx", fn, assets)
