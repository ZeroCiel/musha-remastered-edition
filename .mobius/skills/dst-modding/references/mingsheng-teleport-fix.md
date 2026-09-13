# Mingsheng Mod Teleport Fix — Session Reference

## Context

The 铭盛 (mingsheng) DST character mod crashed when using the 神行 (shenxing) teleport item. The teleport screen (`mingsheng_teleportscreen.lua`) was loaded via `require` and had a chain of missing dependencies plus strict.lua environment issues.

## Mod Location

```
C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together\mods\mingsheng\
```

Workshop reference impl found at:
```
C:\Program Files (x86)\Steam\steamapps\workshop\content\322330\3660903728\
```

## Error Progression & Fixes

### Error 1: Missing uidragzoom.lua
```
module 'mingsheng.scripts.lib.uidragzoom' not found
```
- **Cause**: `mingsheng_teleportscreen.lua` requires a UI drag library that doesn't exist
- **Fix**: Copied `uidragzoom.lua` from workshop mod 3660903728 to `scripts/mingsheng/scripts/lib/uidragzoom.lua`

### Error 2: Missing persistentdata.lua
```
module 'persistentdata' not found
```
- **Cause**: `uidragzoom.lua` internally requires `persistentdata` for save/load
- **Fix**: Copied `persistentdata.lua` from workshop mod 3660903728 to `scripts/persistentdata.lua`

### Error 3: Widget not declared
```
variable 'Widget' is not declared (scripts/strict.lua:23)
```
- **Cause**: `mingsheng_teleportscreen.lua` loaded via `require` — Widget is undeclared in the isolated environment
- **Wrong fix attempt**: Added `GLOBAL.setmetatable(env, ...)` bridge

### Error 4: GLOBAL not declared
```
variable 'GLOBAL' is not declared (scripts/strict.lua:23)
```
- **Cause**: Even `GLOBAL` is blocked by strict.lua in require'd files
- **Wrong fix attempt**: Explicit `require "widgets/widget"` — fixes Widget but not Class, TheFrontEnd, etc.

### Final Fix: modimport + Globals

Changed all three files from `require` to `modimport` + global variables:

**modmain.lua** — added:
```lua
modimport("scripts/persistentdata.lua")
modimport("scripts/mingsheng/scripts/lib/uidragzoom.lua")
modimport("scripts/screens/mingsheng_teleportscreen.lua")
```

**persistentdata.lua** — changed `return PersistentData` → `PersistentData = PersistentData`

**uidragzoom.lua**:
- Removed GLOBAL bridge attempt
- Changed `require("persistentdata")` → `PersistentData` (global)
- Changed `return UIDragZoom` → `UIDragZoom = UIDragZoom`

**mingsheng_teleportscreen.lua**:
- Removed GLOBAL bridge attempt
- Removed explicit widget requires
- Changed `return MingshengTeleportScreen` → `MingshengTeleportScreen = MingshengTeleportScreen`

**mingsheng_shenxing.lua**:
- Removed `local MingshengTeleportScreen = require "screens.mingsheng_teleportscreen"`
- Uses global `MingshengTeleportScreen` directly

## Key Takeaway

In DST modding, ALL cross-mod-file dependencies must use `modimport` + globals. `require` is ONLY for game engine files. The GLOBAL metatable bridge only exists in modimport-loaded files — trying to recreate it in require'd files is impossible because strict.lua blocks even `GLOBAL` itself.

## Action Return Value & Item Consumption

DST 的 `AddAction` 中 fn 的返回值决定物品是否被消耗：

```lua
-- ❌ 总是 return true → 物品总被消耗 (即使打开界面未使用)
AddAction("MINGSHENG_USEITEM", ..., function(act)
    act.invobject.components.xxx:UseItem(act.doer, act.target)
    return true  -- 永远消耗!
end)

-- ✅ 返回 UseItem 的结果 + action.instant = true 阻止自动消耗
AddAction("MINGSHENG_USEITEM", ..., function(act)
    if act.invobject and act.invobject.components.xxx then
        return act.invobject.components.xxx:UseItem(act.doer, act.target)
    end
    return false
end)
ACTIONS.MINGSHENG_USEITEM.instant = true  -- ★ 阻止 DST 自动消耗, 由函数/RPC 手动管理
```

### 核心矛盾: return true 自动消耗 vs return false 说"我做不到"

| 返回值 | DST 行为 | 问题 |
|--------|---------|------|
| `return true` | 动作成功 + **自动消耗物品** | 开界面就把物品吃了 |
| `return false` | 动作失败 + ThePlayer 说"**我做不到**" | 体验差 |

### 解决方案: `action.instant = true`

```lua
-- 函数层: 打开界面时 return true (不触发"我做不到")
function TeleportToWaypoint(inst, doer)
    if #waypoints > 1 then
        -- 打开选择界面
        TheFrontEnd:PushScreen(MingshengTeleportScreen(waypoints, doer))
        return true  -- ★ 返回 true, action.instant 阻止消耗
    end
    -- 单传送点: 直接消耗+传送
    inst:Remove()
    return true
end
```

**效果:**
- 记录传送点: 函数内手动消耗 → return true → instant 阻止二次消耗 ✓
- 单传送点: 函数内手动消耗 → return true ✓
- 多传送点: 开界面(不消耗) → return true → instant 阻止消耗 ✓
- 关闭界面(×/ESC): 物品还在 ✓
- 确认传送: RPC 手动消耗 → 传送 ✓

## UI Refactor: ImageButton Entry Pattern

将传送点条目从 `Widget+Image(bg)+Image(highlight)` 重构为官方 `ImageButton`:

- `normal` 纹理 = 槽位背景
- `selected` 纹理 = 高亮 (原 highlight)
- `Select()/Unselect()` 自动切换, 无需手动 Show/Hide
- 去掉自动选中第1条 (用户点击才高亮)
