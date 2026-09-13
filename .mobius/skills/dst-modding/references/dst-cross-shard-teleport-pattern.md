# DST 跨分片传送界面模式（地表↔洞穴）

## DST 服务器架构关键认知

**DST 的地表和洞穴是独立的服务器进程**（类似彩虹岛的多服务器架构），不是像 ONI 那样的 sim 层跨分片：

```
地表服务器 (Master / Listen Server)
  ├── 有 TheFrontEnd（可以弹UI界面）
  ├── 有客机端（玩家能看到画面）
  └── 角色 entity = GUID_A

洞穴服务器 (Secondary Shard / Dedicated)
  ├── 没有 TheFrontEnd（纯后台服务器）
  ├── 只处理逻辑，不渲染界面
  └── 角色 entity = GUID_B（不同 GUID）
```

**关键推论**：
- 洞穴服务器上没有 `TheFrontEnd` → **不能弹界面**
- 在洞穴里右键物品 → Action handler 在洞穴服务端跑 → 如果试图弹界面，TheFrontEnd 是 nil
- 地表和洞穴是**两个进程** → 不能直接调用对方进程的 entity 或 TheFrontEnd
- 玩家下洞穴时，entity 重建（GUID 变化），数据通过跨分片同步迁移

## 跨分片通信：Shard ModRPC

对于 Listen Server 模式（肉身开服），洞穴是独立进程，需要用 `SendModRPCToShard` + `AddShardModRPCHandler` 通信：

### 注册跨分片 RPC Handler

```lua
-- modmain.lua（两端的服务器都会加载，所以两端都会注册这个handler）
AddShardModRPCHandler("mingsheng", "SHARD_OPEN_TELEPORT", function(player_id)
    -- 这个 handler 在目标分片中执行（收到 RPC 的那个进程）
    -- player_id 是玩家的 OU_xxx 字符串标识
    local players = GLOBAL.FindEntities(0, 0, 0, 99999, {"player"}, {"playerghost", "INLIMBO"})
    for _, player in ipairs(players) do
        if player.userid == player_id then
            -- 在地表分片中找到对应玩家，弹界面
            if player.mingsheng_openteleport then
                player.mingsheng_openteleport:set_local(false)
                player.mingsheng_openteleport:set(true)
            end
            player:PushEvent("mingsheng_openteleport")
            break
        end
    end
end)
```

### 发送跨分片 RPC

```lua
-- 在洞穴分片的 Action handler 中
if shard == "cave" then
    local player_id = doer.userid  -- OU_76561198220617051 格式
    local rpc_id = MOD_RPC["mingsheng"]["SHARD_OPEN_TELEPORT"]
    if rpc_id then
        pcall(SendModRPCToShard, rpc_id, 0, player_id)  -- 0 = master shard
    end
    return true
end
```

**注意**：
- `SendModRPCToShard` 的第二个参数是目标 shard ID（0 = master/地表）
- `MOD_RPC[ns][name]` 由 DST 系统在注册后自动分配
- `player_id` 用 `doer.userid`（字符串格式 `OU_76561198220617051`），不是 entity GUID

## 界面显示两地传送点

地表弹界面时，应该同时显示**地表和洞穴的传送点**，并标记来源：

```lua
-- mingsheng_teleportscreen.lua ReadFromReplica
local surface_wps = storage:GetWaypoints("surface")
local cave_wps = storage:GetWaypoints("cave")
self.waypoints = {}
for _, wp in ipairs(surface_wps) do
    table.insert(self.waypoints, wp)
end
for _, wp in ipairs(cave_wps) do
    wp._shard = "cave"  -- 标记分片
    wp.name = "[洞穴]" .. wp.name  -- 用户可见标记
    table.insert(self.waypoints, wp)
end
```

## 传送到洞穴

DST 的跨分片移动**必须通过洞穴入口/出口传送门**，不能直接 `Physics:Teleport` 跨进程传送。

```lua
-- 在地表服务端：找到洞穴入口，把玩家传过去触发进洞
local x, y, z = player.Transform:GetWorldPosition()
local ents = TheSim:FindEntities(x, y, z, 100, {"cave_entrance"}, {"INLIMBO"})
if #ents == 0 then
    ents = TheSim:FindEntities(x, y, z, 1000, {"cave_entrance"}, {"INLIMBO"})
end
if #ents > 0 then
    local portal = ents[1]
    player.Transform:SetPosition(portal.Transform:GetWorldPosition())
    SpawnPrefab("statue_transition").Transform:SetPosition(portal.Transform:GetWorldPosition())
else
    player.components.talker:Say("神行：附近没有洞穴入口！", 3)
end
```

## 完整跨分片传送流程

```
玩家在洞穴右键神行
  → 洞穴服务端 Action handler（无 TheFrontEnd）
  → shard == "cave" 分支
  → SendModRPCToShard(SHARD_OPEN_TELEPORT, 0, player_id)
  → 地表主分片收到 RPC
  → FindEntities 找到玩家在地表的 entity
  → net_bool:set(true) + PushEvent 弹界面
  → 界面显示地表+洞穴传送点
  → 用户选洞穴点
  → DoTeleport → RPC → CONFIRM_TELEPORT(selected, "cave")
  → 地表服务端找洞穴入口 → 传送到洞口 → 进洞
```
