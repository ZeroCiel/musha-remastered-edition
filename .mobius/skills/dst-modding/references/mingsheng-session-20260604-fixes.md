# 2026-06-04 Session: 装迷糊抵消逻辑 + 生存告示催熟巨大化

## 1. 装迷糊抵消逻辑

**场景**：戴上装迷糊（头部饰品）时，制作消耗三维（饥饿/理智/血量）有概率被抵消。

**实现位置**：`scripts/prefabs/mingsheng.lua` 的 `master_postinit`，在 `RemoveIngredients` hook 末尾。

```lua
-- 在 old_RemoveIngredients 返回后，加抵消逻辑
local ret = old_RemoveIngredients(self, ingredients, recname)

-- 装迷糊抵消：30%概率退回消耗的三维
if TheWorld.ismastersim and inst:HasTag("mingsheng") then
    local head = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    if head and head.prefab == "mingsheng_zhuangmihu" and head.components.fueled and head.components.fueled.currentfuel > 0 then
        if math.random() <= 0.3 then  -- 30%概率
            local recipe = AllRecipes[recname]
            if recipe then
                for k, v in pairs(recipe.character_ingredients) do
                    if v.type == CHARACTER_INGREDIENT.MINGSHENG_HUNGER then
                        inst.components.hunger:DoDelta(v.amount, nil, true)
                    elseif v.type == CHARACTER_INGREDIENT.SANITY then
                        inst.components.sanity:DoDelta(v.amount)
                    elseif v.type == CHARACTER_INGREDIENT.HEALTH then
                        inst.components.health:DoDelta(v.amount)
                    end
                end
            end
            -- 消耗装迷糊耐久10秒
            if head.components.fueled then
                head.components.fueled:DoDelta(-10)
            end
        end
    end
end
```

## 2. 生存告示催熟巨大化修复

**Bug**：原 `BoostCrop` 使用 `SetStage(current+1)` 直接跳生长阶段，跳过了 stress checkpoint（pregrowfn 不执行），且原版 `domagicgrowthfn` 中设 `no_oversized=true` 阻止巨大化。

**Fix**（`scripts/prefabs/mingsheng_shengcun.lua`）：
1. 手动调用当前阶段数据的 `pregrowfn(inst)` 触发 stress checkpoint
2. 进入 final stage（full）时设 `inst.force_oversized = true`

```lua
local function BoostCrop(inst)
    if inst.components.grower then
        if inst.components.grower:CanGrow() then
            inst.components.grower:DoGrow()
        end
        return true
    end

    if inst.components.growable then
        local stages = inst.components.growable.stages or {}
        local current = inst.components.growable.stage or 1
        if current < #stages then
            local stage_data = stages[current]
            if stage_data and stage_data.pregrowfn then
                stage_data.pregrowfn(inst)  -- 触发 stress checkpoint
            end
            inst.components.growable:SetStage(current + 1)
        end

        -- 进入 final stage 时强制巨大化
        local new_current = inst.components.growable.stage or 1
        if new_current == #stages then
            inst.force_oversized = true
        end
        return true
    end
    return false
end
```

**原版巨大化判定**（farm_plants.lua L518）：
```lua
inst.is_oversized = inst.force_oversized or (not inst.no_oversized and ... == FARM_PLANT_STRESS.NONE)
```
