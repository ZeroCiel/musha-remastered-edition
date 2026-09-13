# 告示者标签重构 + 交互系统演进 (2026-08-07)

## 状态追踪：标签替代自定义字段

告示者的充能状态从 `inst._gaoshi_type` 字段改为标签：

| 状态 | 旧（字段） | 新（标签） |
|------|----------|----------|
| 暗影充能 | `_gaoshi_type = "shadow"` | `HasTag("gaoshizhe_shadow")` |
| 虚影充能 | `_gaoshi_type = "illusion"` | `HasTag("gaoshizhe_illusion")` |
| 未充能/破损 | `_gaoshi_type = nil` | 两个标签都没有 |

## SCENE ComponentAction 尝试 → 最终移除

### 第一次尝试：复用 mingsheng_repairable + prefab== 判断（失败）

```lua
-- ❌ 不生效
AddComponentAction("SCENE", "mingsheng_repairable", function(inst, doer, actions, right)
    if right and inst.prefab == "mingsheng_gaoshizhe" and inst._gaoshi_type then
        table.insert(actions, ACTIONS.MINGSHENG_GAOSHIZHE_ACTIVATE)
    end
end)
```

### 第二次尝试：NAMIDA 模式——独立组件 + HasTag（展示菜单但仍是死代码）

参考 workshop 2863315795 (NAMIDA) 的 `namida_erniu_henshin` 模式：
- 创建独立组件 `mingsheng_gaoshizhe_henshin`（只做 tag 标记）
- 用 `inst:HasTag(...)` 判断，不用 `inst.prefab ==`
- 加 `doer ~= inst` 守卫

修改后 SCENE action 绑到 `inventoryitem` 组件：
```lua
AddComponentAction("SCENE", "inventoryitem", function(inst, doer, actions, right)
    if right and doer ~= inst and inst:HasTag("mingsheng_gaoshizhe") 
       and (inst:HasTag("gaoshizhe_shadow") or inst:HasTag("gaoshizhe_illusion")) then
        table.insert(actions, ACTIONS.MINGSHENG_GAOSHIZHE_ACTIVATE)
    end
end)
```

**但是这个 SCENE 激活仍是死代码**：
```
充能(GIVE) → CHARGE handler 里 act.target:Remove()
→ 已充能的告示者从不独立存在于地面上
→ SCENE action 永远没有机会触发
```

### 最终方案：移除 SCENE 激活

用户选择方案1（简化）：删掉 SCENE 激活，充能即出仆从。

**最终交互流程**：
- 手持梦魇/月华 → GIVE 地上告示者 → 充能+自动出仆从
- 物品栏右键告示者 → 已充能出仆从 / 未充能丢地上
- 地上右键告示者 → 默认"拾取"

**删除的代码**：
- `MINGSHENG_GAOSHIZHE_ACTIVATE` action + SCENE ComponentAction + stategraph handler
- `mingsheng_gaoshizhe_henshin` 组件（不再使用）
- gaoshizhe prefab 上的 `mingsheng_repairable` 和 `mingsheng_gaoshizhe_henshin` 组件引用

## 关键坑点：USEITEM marker 组件位置

### Bug：GIVE 充能从未生效

```lua
AddComponentAction("USEITEM", "mingsheng_repairable", function(inst, doer, target, actions, right)
    -- inst = 手持物品（有 mingsheng_repairable 的实体）
    -- target = 右键目标
```

**`AddComponentAction("USEITEM", "mingsheng_repairable", ...)` 匹配的是手持物品（inst）的组件**。

**错误**：`mingsheng_repairable` 放在了 gaoshizhe（被右键的目标）上，没放在梦魇/月华/命理（手持物品）上 → GIVE 充能永远不会触发。

**修复**：
- gaoshizhe prefab：移除 `mingsheng_repairable`
- 梦魇/月华/命理 prefab：添加 `mingsheng_repairable`
