# DST net_bool RPC 绝缘层实验日志

## 背景

明生神行传送：服务端动作（`ACTIONS.MINGSHENG_USEITEM`）中通过 `doer.mingsheng_openteleport:set(true)` 通知客机弹传送界面。用户反馈net_bool不可靠（客机收不到同步信号），想尝试用RPC绕一圈作为"绝缘层"。

## 实验：服务端动作里发 SendModRPCToServer

### 修改

**动作里**（modmain.lua）：
```lua
-- 原来的 net_bool:set
-- if doer.mingsheng_openteleport then
--     doer.mingsheng_openteleport:set_local(false)
--     doer.mingsheng_openteleport:set(true)
-- end

-- 改为 RPC
SendModRPCToServer(MOD_RPC["mingsheng"]["openteleport"])
```

**新增 handler**：
```lua
AddModRPCHandler("mingsheng", "openteleport", function(player)
    if player.mingsheng_openteleport then
        player.mingsheng_openteleport:set_local(false)
        player.mingsheng_openteleport:set(true)
    end
end)
```

### 结果

```
[DEBUGBOSS]   走RPC模式通知客机弹界面
Invalid RPC sender: expected player, got userid
```

**失败**。RPC系统要求sender是玩家实体，但动作在服务端执行，sender是服务端进程ID。

### 结论

- **服务端动作（Action handler）里不能调 SendModRPCToServer**
- `SendModRPCToServer` 只能在**客机上下文**里调（widget按钮点击、screen的OnControl）
- RPC不能用来"包裹"服务端的net_bool:set作为绝缘层——这条路不通

## 官方做法：net_event:push()

DST原版弹制作栏用的不是net_bool，而是 `net_event:push()` + `player_classified` 监听。

**链路**：
1. 服务端 `builder.lua` 调 `self.inst.replica.builder:OpenCraftingMenu()`
2. `Builder:OpenCraftingMenu()` → `self.classified.opencraftingmenuevent:push()`
3. 客机 `player_classified` 监听 `"builder.opencraftingmenu"` → `player.HUD:OpenCrafting()`

**net_event vs net_bool**：
- `net_bool:set(true)` — 设置状态，适合toggle/开关
- `net_event:push()` — 触发一次，适合"弹界面"这种一次性事件
- net_event是官方推荐做法，语义更清晰

## 可行的服务端→客机通信模式

1. **net_bool:set**（明生当前在用）— 绑在角色prefab上，每人独立
2. **net_event:push**（官方做法）— 同样绑在角色prefab上，一次性触发
3. **双路径**（net_bool + PushEvent）— Listen Server模式下PushEvent作为本地备用
