# DST 条件背刺 — Combat.StartAttack hook + 朝向检测

在 `modmain.lua` 中用 `AddComponentPostInit("combat", ...)` hook `StartAttack`，
通过 `externaldamagemultipliers` 在攻击前动态注入伤害倍率。

## IsBehindTarget — 朝向/背向检测

```lua
local function IsBehindTarget(attacker, target)
    if not target or not target.Transform or not attacker.Transform then
        return false
    end
    local tx, _, tz = target.Transform:GetWorldPosition()
    local ax, _, az = attacker.Transform:GetWorldPosition()
    local dx, dz = ax - tx, az - tz
    if dx == 0 and dz == 0 then return false end

    -- 目标朝向向量 (DST 坐标: 旋转角 → sin/cos)
    local rot = target.Transform:GetRotation()
    local rad = rot * (math.pi / 180)
    local fx, fz = math.sin(rad), -math.cos(rad)

    -- 点积 < 0 表示在背后 (>90°)
    local dist = math.sqrt(dx * dx + dz * dz)
    local dot = (fx * dx + fz * dz) / dist
    return dot < -0.3  -- 约 107° 开角，避免正面擦边触发
end
```

## Combat.StartAttack hook

```lua
Safe("背刺Hook", function()
    local Combat = GLOBAL.require("components/combat")
    local old_StartAttack = Combat.StartAttack

    Combat.StartAttack = function(self, target, ...)
        -- 清除上一轮背刺标记
        if self.externaldamagemultipliers then
            self.externaldamagemultipliers:RemoveModifier(self.inst, "rogue_backstab")
        end

        -- 检查背刺条件
        if self.inst and self.inst:HasTag("musha") and target then
            local pc = self.inst.components.musha_profession_component
            if pc and pc.rogue and pc.rogue.backstab
                and pc.rogue.backstab.current_level > 0 then
                if IsBehindTarget(self.inst, target) then
                    local mult = pc.rogue.backstab.level_effects[
                        pc.rogue.backstab.current_level] or 2.0
                    if self.externaldamagemultipliers then
                        self.externaldamagemultipliers:SetModifier(
                            self.inst, mult, "rogue_backstab")
                    end

                    -- 视觉反馈 (最多每 10 秒一次，避免刷屏)
                    if self.inst.components.talker
                        and TheWorld and TheWorld.ismastersim then
                        if not self.inst._backstab_last_msg_time
                            or (GLOBAL.GetTime() - self.inst._backstab_last_msg_time) > 10 then
                            self.inst.components.talker:Say(
                                string.format("背刺！×%.0f", mult), 1.5)
                            self.inst._backstab_last_msg_time = GLOBAL.GetTime()
                        end
                    end
                end
            end
        end

        return old_StartAttack(self, target, ...)
    end
end)
```

## 技能树定义 (在 profession_component 中)

```lua
self.rogue = {
    backstab = {
        current_level = 0,
        max_level = 2,
        level_effects = {
            [1] = 2.0,      -- 2倍伤害
            [2] = 3.0,      -- 3倍伤害
        },
        skill_point_cost = {
            [1] = 2,        -- Lv1 消耗 2 技能点
            [2] = 4,        -- Lv2 消耗 4 技能点
        },
        unlock_requirements = {
            [1] = 1,        -- 1 级可学
            [2] = 5,        -- 5 级可升
        }
    }
}
```

## 自定义技能点消耗 (在 UpgradeSkill 中)

```lua
-- 检查技能点（支持自定义每级消耗）
local cost = 1
if skill.skill_point_cost and skill.skill_point_cost[next_level] then
    cost = skill.skill_point_cost[next_level]
end
if self.userdata.skill_points < cost then
    -- 提示不足...
    return false
end
self.userdata.skill_points = self.userdata.skill_points - cost
```

## 为什么 hook StartAttack 而不是 CalcDamage 或其他

- `StartAttack` 在实际攻击发生前调用 → 可以在伤害计算前设置 modifier
- `externaldamagemultipliers` 在 `CalcDamage` 中被读取 → 自动应用到最终伤害
- `onattackother` 事件在伤害已计算后才触发 → 太晚
- `CalcDamage` 被所有 combat 调用，范围太广

## 参考实现

完整代码：
- `musha/modmain.lua` — IsBehindTarget + Combat hook
- `musha/scripts/components/musha_profession_component.lua` — rogue 技能树 + 升级
- `musha/scripts/skills/musha_skill_data.lua` — MUSHA_SKILLS_ASSASSIN
