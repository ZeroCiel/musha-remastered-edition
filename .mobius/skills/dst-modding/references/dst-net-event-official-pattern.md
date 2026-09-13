# DST 官方 net_event 模式 — builder_replica OpenCraftingMenu

从DST源码 `data/databundles/scripts/components/builder_replica.lua` 验证的官方同步链路。

## 核心链路

```
服务端 builder.lua
  → replica.builder:OpenCraftingMenu()
    → classified.opencraftingmenuevent:push()   -- net_event!
      → 客机 player_classified 监听 "builder.opencraftingmenu"
        → player.HUD:OpenCrafting()
```

## builder_replica.lua 关键代码

文件: `data/databundles/scripts/components/builder_replica.lua`

```lua
function Builder:OpenCraftingMenu()
    if self.classified ~= nil then
        self.classified.opencraftingmenuevent:push()
    end
end
```

`self.classified` = 玩家的 `player_classified` 实例。`opencraftingmenuevent` 是注册在 classified 上的 `net_event`。

## player_classified.lua 监听端

文件: `data/databundles/scripts/prefabs/player_classified.lua`

事件监听注册（第1228行）：
```lua
inst:ListenForEvent("builder.opencraftingmenu", OnOpenCraftingMenuEvent)
```

事件处理（第755行）：
```lua
local function OnOpenCraftingMenuEvent(inst)
    local player = inst._parent
    if player ~= nil and TheFocalPoint.entity:GetParent() == player then
        if player.HUD ~= nil then
            player.HUD:OpenCrafting()
        end
    end
end
```

关键细节：
- `inst._parent` 指向玩家实体
- `TheFocalPoint.entity:GetParent() == player` 检查当前焦点的玩家是这个玩家（多人模式下区分）
- 监听的事件名是 `"builder.opencraftingmenu"` — 注意是点号分隔，不是下划线

## 在角色prefab上直接用net_event（无player_classified的mod写法）

```lua
-- common_postinit
inst.mingsheng_teleport_event = net_event(inst.GUID, "mingsheng_teleport_event")
inst:ListenForEvent("mingsheng_teleport_event", function()
    if not TheFrontEnd then return end
    local ok, screen = pcall(require, "screens/mingsheng_teleportscreen")
    if ok and screen then
        TheFrontEnd:PushScreen(screen(inst))
    end
end)
```

服务端动作中触发：
```lua
-- Action handler（服务端执行）
if doer.mingsheng_teleport_event then
    doer.mingsheng_teleport_event:push()
end
return true
```
