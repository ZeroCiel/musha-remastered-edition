# Bernie Dark Layer Fix & finiteuses State Control

## Bernie Dark/Shadow Layer

Bernie-based builds have TWO body symbol sets:
- `swap_bernie` — full color (live/active)
- `swap_bernie_dead` — dark silhouette (inactive/dead)

### WRONG: SetMultColour
`inst.AnimState:SetMultColour(1,1,1,1)` does NOT fix the dark appearance. The darkness is in the symbol images, not a colour multiply.

### CORRECT: OverrideSymbol
```lua
inst.AnimState:OverrideSymbol("swap_bernie_dead", "gaoshizhe", "swap_bernie")
inst.AnimState:OverrideSymbol("swap_bernie_dead_idle_willow", "gaoshizhe", "swap_bernie_idle_willow")
```

### Hide default weapon
Bernie builds often have a `swap_object` symbol showing a default weapon:
```lua
inst.AnimState:Hide("swap_object")
```

## finiteuses for Item State Control

Use `finiteuses` (not tags alone) for binary charged/uncharged state on ground items. Tags are only for type tracking (shadow vs illusion).

### Prefab: crafted as charged
```lua
inst:AddComponent("finiteuses")
inst.components.finiteuses:SetMaxUses(1)
inst.components.finiteuses:SetUses(1)  -- 1=charged, 0=broken
inst:AddTag("gaoshizhe_shadow")  -- type only, not state
```

### SCENE check uses finiteuses
```lua
AddComponentAction("SCENE", "my_henshin", function(inst, doer, actions, right)
    local charged = inst.components.finiteuses and inst.components.finiteuses:GetUses() > 0
    if right and doer ~= inst and charged then
        table.insert(actions, ACTIONS.MY_ACTIVATE)
    end
end)
```

### Activate consumes durability
```lua
if inst.components.finiteuses then
    inst.components.finiteuses:SetUses(0)
end
inst:Remove()
```

### GIVE charging sets uses
```lua
act.target.components.finiteuses:SetUses(1)
act.target:AddTag("gaoshizhe_shadow")
```
