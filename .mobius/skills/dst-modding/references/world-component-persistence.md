# World Component Persistence Pattern

## Problem

Player components lose data on disconnect/save. For data that should persist across sessions and be shared across shards, a world component with OnSave/OnLoad is the correct pattern.

## Migration: Player → World Component

### Before (❌)
```lua
-- Component on player entity — data lost on save
AddPlayerPostInit(function(player)
    player:AddComponent("mingsheng_waypoint_storage")
end)
```

### After (✅)
```lua
-- Component on TheWorld — persists via OnSave/OnLoad
AddPrefabPostInit("forest", function(world)
    world:AddComponent("mingsheng_waypoint_storage")
end)
AddPrefabPostInit("cave", function(world)
    world:AddComponent("mingsheng_waypoint_storage")
end)
```

## Component Template: Per-Player Storage on World

```lua
local MyStorage = Class(function(self, inst)
    self.inst = inst
    self._data = {}  -- { [userid] = { ... } }
end)

-- ===== Persistence =====

function MyStorage:OnSave()
    if not next(self._data) then return end
    return { data = self._data }
end

function MyStorage:OnLoad(saved)
    if saved and saved.data then
        self._data = saved.data
    end
end

-- ===== Per-Player Access =====

function MyStorage:GetPlayerData(userid)
    if not userid then return nil end
    if not self._data[userid] then
        self._data[userid] = {}
    end
    return self._data[userid]
end

-- ===== CRUD with userid =====

function MyStorage:Add(userid, key, value)
    local pd = self:GetPlayerData(userid)
    if not pd then return false end
    pd[key] = value
    return true
end

function MyStorage:Get(userid, key)
    local pd = self._data[userid]
    if not pd then return nil end
    return pd[key]
end

function MyStorage:Remove(userid, key)
    local pd = self._data[userid]
    if not pd then return false end
    pd[key] = nil
    return true
end

-- ===== Serialization for RPC =====

function MyStorage:Serialize(userid)
    local pd = self._data[userid] or {}
    local result = {}
    for k, v in pairs(pd) do
        table.insert(result, {key = k, value = v})
    end
    return result
end
```

## API Migration Checklist

When moving from player to world component, update ALL callers:

| Old | New |
|-----|-----|
| `player.components.xxx` | `TheWorld.components.xxx` |
| `storage:GetWaypoints()` | `storage:GetWaypoints(player.userid)` |
| `storage:AddWaypoint(name, x, y, z, shard)` | `storage:AddWaypoint(player.userid, name, x, y, z, shard)` |
| `storage:Serialize(shard)` | `storage:Serialize(player.userid, shard)` |

## Shard Awareness

World components exist separately on surface and caves. Data must be shard-aware:
- Surface waypoints stored in `data[userid].surface`
- Cave waypoints stored in `data[userid].cave`
- Use `TheWorld:HasTag("cave")` to determine current shard

## DST prefab names for AddPrefabPostInit

| Prefab | Shard |
|--------|-------|
| `"forest"` | Surface world |
| `"cave"` | Cave world |
