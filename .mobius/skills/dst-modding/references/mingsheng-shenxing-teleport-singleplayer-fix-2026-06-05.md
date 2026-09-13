# 神行传送单人模式修复（2026-06-05）

## Bug
单人模式右键神行物品，界面不弹出。

## Root Cause
在 `mingsheng.lua` 的 `common_postinit` 里，`mingsheng_openteleport_dirty` 监听器开头：
```lua
if TheWorld.ismastersim then return end
```
单人模式下服务端=客机，`ismastersim=true`，直接被跳过，界面永远弹不出来。

## Fix
把 `ismastersim` 的检查从"跳过"改为"直接弹界面"：
```lua
if TheWorld.ismastersim then
    -- 单人模式：服务端=客机，直接弹界面
    local ok, screen = pcall(require, "screens/mingsheng_teleportscreen")
    if ok and screen then
        TheFrontEnd:PushScreen(screen(inst))
        inst.mingsheng_openteleport:set_local(false)
    end
    return
end
```

## 涉及的代码路径

| 文件 | 函数/位置 | 作用 |
|------|----------|------|
| `scripts/prefabs/mingsheng.lua` | `mingsheng_openteleport_dirty` 监听器 | net_bool 触发 → 弹界面 |
| `modmain.lua` | `MINGSHENG_USEITEM` action | 右键神行物品 → set net_bool(true) |
| `scripts/prefabs/mingsheng_shenxing.lua` | `TeleportToWaypoint` | PushEvent → net_bool listener |
| `scripts/screens/mingsheng_teleportscreen.lua` | `ReadFromReplica` | 读 waypoints 数据 |
| `scripts/screens/mingsheng_teleportscreen.lua` | `DoTeleport` | 单人直接传送 / 联机发RPC |

## 另一个坑：ReadFromReplica 没传 shard 参数
原代码：
```lua
self.waypoints = storage:GetWaypoints()  -- 无 shard 参数
```
修复后：
```lua
local shard = TheWorld:HasTag("cave") and "cave" or "surface"
self.waypoints = storage:GetWaypoints(shard)
```
洞穴中如果不传 shard，`GetWaypoints()` 会返回 `GetShard()` → `cave` 的列表，但 `ReadFromReplica` 在洞穴环境可能先读 replica（无分片概念，只缓存当前分片数据）。单人模式直接读 storage 时必须显式传 shard。

## Debug 输出
所有 debug print 加了 `[DEBUGBOSS]` 前缀，涉及：
- 组件创建时打印分片
- AddWaypoint 参数
- 右键使用时的目标/分支/分片
- net_bool dirty 事件触发
- 界面数据加载来源和数量
- DoTeleport 执行路径（单人 vs RPC）
- CONFIRM_TELEPORT RPC handler 参数
