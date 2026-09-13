# DST Net_bool 通知客机打开 UI 界面

## 问题

服务端代码（AddAction handler、prefab OnUse、BufferedAction）中无法安全调用 `TheFrontEnd` 或 `SendModRPCToClient`：
- `TheFrontEnd` 只在客户端存在（服务端 nil）
- `SendModRPCToClient` 在 buffered action 上下文中被引擎禁止（assertion failed）

## Solution: Dual Path — net_bool + PushEvent

Use DST's `net_bool` auto-sync mechanism combined with a local `PushEvent` as backup. The character prefab registers two listeners in `common_postinit`, and the action handler triggers both paths.

### 问题场景

在以下模式中，单一 net_bool 路径可能不可靠：
- **Listen Server（肉身开服/主机联机）**：服务端 Action handler 执行时，net_bool 同步到客机端的延迟或同步失败导致界面不弹
- **洞穴/分片切换**：角色 entity 重建后 net_bool 的 GUID 映射变化

### 修复方案：双路径触发

#### 角色预制体 common_postinit（两条路径）

```lua
-- 方式1：本地 PushEvent 路径（服务端 PushEvent → Listen Server 客机端收到）
inst:ListenForEvent("mingsheng_openteleport", function()
    if not TheFrontEnd then return end
    local ok, screen = pcall(require, "screens/mingsheng_teleportscreen")
    if ok and screen then
        TheFrontEnd:PushScreen(screen(inst))
    end
end)

-- 方式2：net_bool 同步路径（服务端 set(true) 同步到客机触发）
inst.mingsheng_openteleport = net_bool(inst.GUID, "mingsheng_openteleport", "mingsheng_openteleport_dirty")
inst:ListenForEvent("mingsheng_openteleport_dirty", function()
    if not inst.mingsheng_openteleport:value() then return end
    if not TheFrontEnd then
        inst.mingsheng_openteleport:set_local(false)
        return
    end
    local ok, screen = pcall(require, "screens/mingsheng_teleportscreen")
    if ok and screen then
        TheFrontEnd:PushScreen(screen(inst))
    end
    inst.mingsheng_openteleport:set_local(false)
end)
```

#### Action handler 触发点（双触发）

```lua
if doer.mingsheng_openteleport then
    doer.mingsheng_openteleport:set_local(false)  -- 本地置false，不触发网络同步
    doer.mingsheng_openteleport:set(true)          -- 同步到客机触发 dirty
    doer:PushEvent("mingsheng_openteleport")       -- 额外本地事件（Listen Server 备用）
end
return true
```

## 关键原理

| 步骤 | 说明 |
|------|------|
| 1. 服务端 `set_local(false); set(true)` | `set_local` 只在本地改值不触发网络，`set(true)` 发网络同步 |
| 2. 服务端 `PushEvent("event_name")` | 本地事件，Listen Server 模式下服务端也有事件总线 |
| 3. net_bool 自动同步到客机 | 触发 dirty → PushScreen |
| 4. PushEvent 路径 | 提供备用触发（net_bool 不可靠时的兜底） |
| 5. `set_local(false)` in listener | 本地重置，下次可再次触发 |

### 场景3：洞穴分片（Secondary Shard）

在洞穴分片中**不能弹界面**（TheFrontEnd 不存在，洞穴是独立服务器进程）。需要用 `SendModRPCToShard` 通知地表主分片：

```lua
-- 洞穴 Action handler 中
if shard == "cave" then
    local player_id = doer.userid
    local rpc_id = MOD_RPC[ns][name]
    if rpc_id then
        pcall(SendModRPCToShard, rpc_id, 0, player_id)  -- 0 = master shard
    end
    return true
end
```

See `references/dst-cross-shard-teleport-pattern.md` for full details.

## 双路径导致界面双重弹出

- **`set_local(false)` 替代 `set(false)`** — `set(false)` 会触发一次不必要的网络同步；`set_local(false)` 只改本地值
- **⚠️ Listen Server 双重弹出**：PushEvent + net_bool 双路径在 Listen Server 模式下可能导致界面被 PushScreen 两次（一次来自 PushEvent，一次来自 net_bool dirty 随后触发）。如果出现界面闪烁或叠层，在 Action handler 中避免同时触发两条路径：
  ```lua
  -- Listen Server 模式：只用 PushEvent 路径，不用 net_bool
  if TheWorld.ismastersim then
      doer:PushEvent("mingsheng_openteleport")
  else
      -- 纯联机/远程客机模式：只用 net_bool
      doer.mingsheng_openteleport:set_local(false)
      doer.mingsheng_openteleport:set(true)
  end
  ```
  或者接受双路径（两条路径都会 PushScreen 同一份数据，第一次 PopScreen 后第二个界面还在）。
- **不要用 `if TheWorld.ismastersim then return end`** 过滤 — 这个模式会阻塞单人模式。改为检查 `TheFrontEnd` 是否存在（不存在=纯服务端线程）
- **net_bool 必须在 common_postinit 里挂** — 不能在 master_postinit 或客户端 only 分支里挂
- **PushEvent 路径的 `TheFrontEnd` 检查** — 服务端 PushEvent 时 TheFrontEnd 不存在，会直接跳过，不会报错
- **关闭按钮用 PopScreen 不用 Hide** — `TheFrontEnd:PopScreen()`
- **不拦截移动键** — Screen OnControl 中不拦截 CONTROL_MOVE_UP/DOWN/ACCEPT

## 数据同步方案（Replica 模式）

Waypoint 数据通过 replica 组件 `net_string` JSON 同步：

```
scripts/components/
  mingsheng_teleport_player.lua            -- 服务端组件（数据+持久化）
  mingsheng_teleport_player_replica.lua    -- 客机 replica（net_string+缓存+脏事件）
```

**服务端组件**通过 `self.inst.replica.xxx:PushData(data)` 推数据。

**Replica 组件**持有 `net_string`，接收数据更新缓存。

**⚠️ `net_*` 不要放在服务端组件里** — 职责分离。

**⚠️ 读档后必须手动推一次 replica** — OnLoad 后显式调 `SyncToReplica()`。
