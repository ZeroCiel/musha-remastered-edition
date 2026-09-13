# 神行传送拖拽排序完整实现参考

## 架构决策

### Order-based 排序（替代数组位置交换）

每个 waypoint 带 `order` 字段，列表永远按 order 排序显示。
拖拽时只交换 order 值（不是数组元素），松手后重排。

### 拖拽中不交换数据

拖拽时（AddMoveHandler）只跟踪目标槽位（drag_target_slot）。
松手时（EndDrag）执行一次 order 交换 + PopulateEntries 刷新。

### DST API 多值陷阱

所有坐标函数返回 `x, y, z` 三个值，不是 Vector3 对象：

```lua
-- ✅
local _, y = entry:GetWorldPosition()
local _, my = TheInput:GetScreenPosition()
local _, hy = self.drag_handle:GetPosition()
```

## 完整拖拽流程

### 构造时

```lua
self.drag_mode = false
self.drag_entry_index = nil
self.drag_target_slot = nil
self._drag_handler = nil

-- 骨头
self.drag_handle = self.root:AddChild(ImageButton(...))
self.drag_handle:SetPosition(195, 56)
self.drag_handle:SetScale(0.5, 0.42, 1)
self.drag_handle.OnMouseButton = function(self2, button, down, x, y)
    if button == MOUSEBUTTON_LEFT and down then
        self:StartDrag()
        return true
    end
    return false
end
self.drag_handle:Hide()
```

### StartDrag

```lua
function MingshengTeleportScreen:StartDrag()
    if #self.waypoints < 2 then return end

    self.drag_mode = true
    self.drag_entry_index = self.selected or 1

    -- 变灰
    for _, entry in ipairs(self.entries) do
        if entry.wp then
            entry:SetTextColour(0.5, 0.5, 0.5, 1)
            entry:SetTextFocusColour(0.5, 0.5, 0.5, 1)
            entry:SetTextSelectedColour(0.5, 0.5, 0.5, 1)
            entry.text:SetColour(0.5, 0.5, 0.5, 1)
        end
    end

    local _, mouse_y = TheInput:GetScreenPosition()
    self.drag_start_y = mouse_y or 0
    local _, anchor_y = self.drag_handle:GetPosition()
    self.drag_anchor_y = anchor_y or 0

    self._drag_handler = TheInput:AddMoveHandler(function(x, y)
        if not self.drag_mode then return end
        if not TheInput:IsMouseDown(MOUSEBUTTON_LEFT) then
            self:EndDrag()
            return
        end

        local dy = y - self.drag_start_y
        local target_y = self.drag_anchor_y + dy

        -- Y轴限制
        local min_y = START_Y + (MAX_TOTAL - 1) * SPACING - 500
        local max_y = START_Y
        target_y = math.max(min_y, math.min(max_y, target_y))

        -- 计算槽位
        local slot = math.floor((START_Y - target_y) / math.abs(SPACING) + 0.5) + 1
        slot = math.max(1, math.min(MAX_TOTAL, slot))

        local snapped_y = START_Y + (slot - 1) * SPACING
        self.drag_handle:SetPosition(195, snapped_y)

        -- 只记槽位，不交换数据
        self.drag_target_slot = slot
    end)

    self.drag_handle:MoveToFront()
    self.drag_handle:SetScale(0.55, 0.48, 1)
end
```

### EndDrag

```lua
function MingshengTeleportScreen:EndDrag()
    if not self.drag_mode then return end
    self.drag_mode = false

    if self._drag_handler then
        self._drag_handler:Remove()
        self._drag_handler = nil
    end

    -- 松手时执行一次 order 交换
    -- ⚠️ 必须用 self.entries[i].wp 而不是 self.waypoints[i]
    --    waypoints 被 sort 后索引含义改变，entries[i].wp 是稳定引用
    if self.drag_entry_index and self.drag_target_slot
       and self.drag_target_slot ~= self.drag_entry_index then
        local slot = self.drag_target_slot
        local src_entry = self.entries[self.drag_entry_index]
        local dst_entry = self.entries[slot]
        if src_entry and src_entry.wp and dst_entry and dst_entry.wp then
            local tmp = src_entry.wp.order
            src_entry.wp.order = dst_entry.wp.order
            dst_entry.wp.order = tmp
            table.sort(self.waypoints, function(a, b)
                return (a.order or 999) < (b.order or 999)
            end)
            self:PopulateEntries(self.waypoints)
        end
    end

    -- 恢复颜色
    for _, entry in ipairs(self.entries) do
        if entry.wp then
            entry:SetTextColour(1, 1, 1, 1)
            entry:SetTextFocusColour(1, 1, 1, 1)
            entry:SetTextSelectedColour(1, 1, 1, 1)
            entry.text:SetColour(1, 1, 1, 1)
        end
    end

    self.drag_handle:SetScale(0.5, 0.42, 1)
    self.drag_target_slot = nil

    if self.drag_entry_index and self.entries[self.drag_entry_index]
       and self.entries[self.drag_entry_index].wp then
        self:SelectEntry(self.drag_entry_index)
    elseif #self.waypoints > 0 then
        self:SelectEntry(1)
    end
end
```

## 服务端组件 order 管理

```lua
-- AddWaypoint
local max_order = 0
for _, wp in ipairs(list) do
    if wp.order and wp.order > max_order then max_order = wp.order end
end
table.insert(list, { name=name, x=x, y=y, z=z, order = max_order + 1 })

-- RemoveWaypoint (after table.remove)
table.sort(list, function(a,b) return (a.order or 999) < (b.order or 999) end)
for i, wp in ipairs(list) do wp.order = i end

-- SyncToReplica: always include order field in serialized data
```

## 旧存档兼容

OnLoad 中检测是否有 order 字段，没有就按数组顺序分配：

```lua
function _ensure_orders()
    for _, list in ipairs({self._surface, self._cave}) do
        local has_order = false
        for _, wp in ipairs(list) do
            if wp.order then has_order = true; break end
        end
        if not has_order then
            for i, wp in ipairs(list) do wp.order = i end
        end
        table.sort(list, function(a,b) return a.order < b.order end)
    end
end
```
