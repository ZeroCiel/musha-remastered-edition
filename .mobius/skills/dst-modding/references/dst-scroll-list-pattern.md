# DST 手动滚动列表模式

当列表超过 4 个可见条目时，不使用 `ScrollableList`（15 参数 + 回收 widget 破坏数据绑定），而是手动实现滚动。

## 核心变量

```lua
local MAX_VISIBLE = 4   -- 同时可见条目数
local MAX_TOTAL = 7     -- 最大条目数
self.scroll_offset = 0   -- 当前滚动偏移（第一个可见条目的 index）
```

## 创建所有条目 + 更新可见性

```lua
-- 创建时：所有条目都创建，但只显示可见区内的
for i, wp in ipairs(self.waypoints) do
    if i > MAX_TOTAL then break end
    local entry = self.root:AddChild(ImageButton(...))
    entry.index = i
    entry.wp = wp
    table.insert(self.entries, entry)
end

-- 初始调用
self:UpdateVisibility()
```

## UpdateVisibility

```lua
function MyScreen:UpdateVisibility()
    local spacing = -60
    local start_y = 75
    for i, entry in ipairs(self.entries) do
        local visible_idx = i - self.scroll_offset
        if visible_idx >= 1 and visible_idx <= MAX_VISIBLE then
            entry:SetPosition(-5, start_y + (visible_idx - 1) * spacing)
            entry:Show()
        else
            entry:Hide()
        end
    end
end
```

## 滚轮滚动 (Screen 级)

```lua
-- 放在 Screen 方法上，不要放在 root Widget 上
function MyScreen:OnMouseWheel(down, amount)
    if down then
        self:ScrollBy(1)    -- 滚轮向下 → 显示后面的条目
    else
        self:ScrollBy(-1)
    end
end
```

## ScrollBy

```lua
function MyScreen:ScrollBy(delta)
    local new_offset = self.scroll_offset + delta
    local max_offset = math.max(0, #self.entries - MAX_VISIBLE)
    new_offset = math.max(0, math.min(new_offset, max_offset))
    if new_offset ~= self.scroll_offset then
        self.scroll_offset = new_offset
        self:UpdateVisibility()
    end
end
```

## 上下翻页按钮

只当条目数超过可见区时显示：

```lua
if #self.entries > MAX_VISIBLE then
    -- 上滚按钮：复用 close 按钮 atlas，旋转 90°
    self.scroll_up_btn = self.root:AddChild(ImageButton(
        "images/teleport/mingsheng_teleport_close.xml",
        "mingsheng_teleport_close.tex",
        nil, nil, nil, nil, {0.7, 0.7, 0.7, 1}, {1, 1, 1, 1}, 1))
    self.scroll_up_btn:SetPosition(220, start_y + 10)
    self.scroll_up_btn:SetScale(0.35, 0.35)
    self.scroll_up_btn:SetRotation(90)
    self.scroll_up_btn:SetOnClick(function() self:ScrollBy(-1) end)

    -- 下滚按钮：旋转 -90°
    self.scroll_down_btn = self.root:AddChild(ImageButton(...))
    self.scroll_down_btn:SetPosition(220, start_y + (MAX_VISIBLE - 1) * spacing + 10)
    self.scroll_down_btn:SetScale(0.35, 0.35)
    self.scroll_down_btn:SetRotation(-90)
    self.scroll_down_btn:SetOnClick(function() self:ScrollBy(1) end)
end
```

## 键盘导航自动滚动

上下键到达可见区边界时先滚动再选择：

```lua
function MyScreen:OnControl(control, down)
    if not down then return false end

    if control == CONTROL_MOVE_UP and self.selected and self.selected > 1 then
        -- 如果选中的是第一行可见项 → 先滚上去
        if self.selected == self.scroll_offset + 1 and self.scroll_offset > 0 then
            self:ScrollBy(-1)
        end
        self:SelectEntry(self.selected - 1)
        return true
    end

    if control == CONTROL_MOVE_DOWN then
        if self.selected and self.selected < #self.entries then
            -- 如果选中的是最后一行可见项 → 先滚下去
            if self.selected == self.scroll_offset + MAX_VISIBLE
                and self.scroll_offset < #self.entries - MAX_VISIBLE then
                self:ScrollBy(1)
            end
            self:SelectEntry(self.selected + 1)
        end
        return true
    end
    -- ...
end
```

## 文本防换行

DST 的 `Text` widget 没有 `SetTruncateString` 方法。用 `SetRegionSize` 限制宽度即可防止换行：

```lua
text:SetRegionSize(200, 40)      -- 固定宽度 200px
text:SetHAlign(ANCHOR_LEFT)
text:SetVAlign(ANCHOR_MIDDLE)
```

超出宽度的文字会被区域边界自然裁剪，不需要额外的截断 API。

## 参考实现

完整代码：`mingsheng/scripts/screens/mingsheng_teleportscreen.lua`
