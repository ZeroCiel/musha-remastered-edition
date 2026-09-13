# AddComponentAction Rules

**CRITICAL**: `AddComponentAction("SCENE", ...)` and `AddComponentAction("USEITEM", ...)` MUST bind to a dedicated custom component, NEVER to vanilla components (`inventoryitem`, `follower`, `trader`, etc.).

## Why
Vanilla components block custom SCENE/USEITEM actions. The component's own action collection mechanism swallows custom handlers silently.

## Correct Pattern

### 1. Create minimal marker component
```lua
-- scripts/components/xxx_henshin.lua
local MyHenshin = Class(function(self, inst)
    self.inst = inst
end)
return MyHenshin
```

### 2. Add to prefab
```lua
inst:AddComponent("xxx_henshin")
```

### 3. Bind to custom component
```lua
AddComponentAction("SCENE", "xxx_henshin", function(inst, doer, actions, right)
    -- Filter with HasTag, NOT prefab ==
    if right and doer ~= inst and inst:HasTag("mytag") then
        table.insert(actions, ACTIONS.MY_ACTION)
    end
end)
```

## Additional Rules
- Use `HasTag` filtering, NOT `prefab ==`
- Always `doer ~= inst` guard for SCENE
- Add `print()` for first-time debug — confirm callback fires
- Same rules apply to USEITEM bindings

## Debug Checklist
1. Is AddComponentAction bound to custom component (not inventoryitem/follower)?
2. Is the custom component in the prefab?
3. Does the entity have the expected tags?
4. Add print() to confirm callback fires
