-- ============================================================
-- musha_skill_point.lua — 隐形"落点"实体（2026-09-14 新建）
-- 用途：原版 `projectile` 组件（直线抛射体）只认**实体**目标，不认坐标
--       （Throw(owner, target, attacker) 里会调 target:GetPosition() / target:PushEvent）。
--       我们技能是"点地 AOE"，落点是个坐标 → 所以在落点放一个隐形实体给它当靶子，
--       剑气飞到这个点就"命中"它，命中回调里再做我们自己的 AOE 伤害。
-- 安全：它没有 health / combat / _combat tag →
--       combat.lua:1122 `CanHitTarget` 不通过 → DoAttack 直接 return，不会有伤害/报错。
--       另外挂 notarget/noattack，怪物不会把它当目标。
-- 不用打包任何素材。
-- ============================================================

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst:AddTag("notarget")
    inst:AddTag("noattack")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    -- 保险：万一抛射体没打中/没被清掉，3 秒后自己消失（不留垃圾实体）
    inst:DoTaskInTime(3, inst.Remove)

    return inst
end

return Prefab("musha_skill_point", fn)
