# Debug Boss Print Pattern

When the user needs to send debug logs to a boss/code reviewer for analysis, use the following pattern:

## Prefix Convention

All debug prints use `[DEBUGBOSS]` prefix so the boss can grep instantly:

```lua
print("[DEBUGBOSS] 神行物品被使用！doer=", act.doer, "target=", act.target)
```

## Where to Add Prints

Cover every branch in the critical path:

1. **Action handler** (modmain.lua) — print doer validity, target info, which branch was taken
2. **Component CRUD** (component.lua) — print every call to AddWaypoint/RemoveWaypoint with params
3. **net_bool dirty listener** (prefab common_postinit) — print ismastersim, HasTag, net_bool value, TheFrontEnd existence
4. **Screen data loading** — print replica vs storage, shard detection, waypoint count
5. **DoTeleport / confirm button** — print selected index, waypoint data, ismastersim, execution path
6. **RPC handler** — print all received params, shard info, storage state, passable check results

## Example: Full Path Coverage

```lua
-- Action handler
print("[DEBUGBOSS] 神行物品被使用！doer=", act.doer, "target=", act.target)
if act.target then
    print("[DEBUGBOSS]   目标prefab:", act.target.prefab, "isValid:", act.target:IsValid())
end

-- net_bool dirty listener
print("[DEBUGBOSS] mingsheng_openteleport_dirty 触发！")
print("[DEBUGBOSS]   TheWorld.ismastersim =", TheWorld.ismastersim)
print("[DEBUGBOSS]   inst:HasTag mingsheng =", inst:HasTag("mingsheng"))
print("[DEBUGBOSS]   net_bool value =", inst.mingsheng_openteleport:value())
if not TheFrontEnd then
    print("[DEBUGBOSS]   TheFrontEnd 不存在！无法弹界面")
    return
end
```
