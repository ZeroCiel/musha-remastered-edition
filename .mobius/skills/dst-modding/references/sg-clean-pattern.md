# SG (Stategraph) — Clean NAMIDA Pattern

## DON'T: Copy vanilla SGs
Maxwell's shadow worker SG is 1476 lines with chop/mine/dig/shadowstrike. Don't copy it.

## DO: NAMIDA erniu pattern (~260 lines)

```lua
require("stategraphs/commonstates")

local actionhandlers = {}

local events = {
    CommonHandlers.OnLocomote(true, false),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnHop(),
    CommonHandlers.OnAttack(),  -- melee
    -- For ranged: use custom EventHandler("doattack", ...) instead
}

local states = {
    State{ name = "spawn", ... },    -- PlayAnimation("minion_spawn") → idle
    State{ name = "idle", ... },     -- PlayAnimation("idle_loop", true), Physics:Stop()
    State{ name = "run_start", ... },-- PlayAnimation("run_pre") → run
    State{ name = "run", ... },      -- PlayAnimation("run_loop", true), setTimeout loop
    State{ name = "run_stop", ... }, -- PlayAnimation("run_pst") → idle
    State{ name = "attack", ... },   -- melee: PlayAnimation("atk"), DoAttack at frame 8
    State{ name = "death", ... },    -- SpawnPrefab item, then Remove()
    State{ name = "hit", ... },      -- PlayAnimation("hit"), clear busy at frame 3
    State{ name = "dance", ... },    -- emoteXL loop
}

-- Boat hop states
local hop_timelines = { ... }
CommonStates.AddHopStates(states, true, ...)

return StateGraph("prefab_name", states, events, "spawn", actionhandlers)
```

## Key States

### death (drop item before remove)
```lua
State{
    name = "death", tags = {"busy"},
    onenter = function(inst)
        inst.Physics:Stop()
        inst.AnimState:Hide("swap_arm_carry")
        inst.AnimState:PlayAnimation("death")
        SpawnPrefab("collapse_small").Transform:SetPosition(inst:GetPosition():Get())
        local item = SpawnPrefab("mingsheng_gaoshizhe")
        item.Transform:SetPosition(inst:GetPosition():Get())
    end,
    events = {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then inst:Remove() end
        end),
    },
}
```

### attack (melee)
```lua
State{
    name = "attack", tags = {"attack", "notalking", "abouttoattack", "busy"},
    onenter = function(inst, target)
        inst.sg.statemem.target = target or inst.components.combat.target
        inst.components.combat:StartAttack()
        inst.Physics:Stop()
        inst.AnimState:PlayAnimation("atk")
    end,
    timeline = {
        TimeEvent(8*FRAMES, function(inst)
            inst.components.combat:DoAttack(inst.sg.statemem.target)
            inst.sg:RemoveStateTag("abouttoattack")
        end),
        TimeEvent(12*FRAMES, function(inst) inst.sg:RemoveStateTag("busy") end),
        TimeEvent(13*FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
    },
}
```

### hit
```lua
State{
    name = "hit", tags = {"busy"},
    onenter = function(inst)
        inst:ClearBufferedAction()
        inst.AnimState:PlayAnimation("hit")
        inst.Physics:Stop()
    end,
    timeline = {
        TimeEvent(3*FRAMES, function(inst) inst.sg:RemoveStateTag("busy") end),
    },
}
```
