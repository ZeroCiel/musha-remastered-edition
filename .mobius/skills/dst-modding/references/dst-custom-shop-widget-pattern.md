# DST Custom Shop Widget Pattern

## Overview

A custom shop UI implemented as a standalone `Widget` (not DST built-in container system), using `ImageButton` for category tabs and `ScrollingGrid` for item lists. The shop is toggled via `PushEvent` from a control button that listens for `CONTROL_ACCEPT`.

## Architecture

```
shenmohuan_register.lua (AddClassPostConstruct on "widgets/controls")
  ├── shenmohuan_shop.lua     — 商店主界面（背景+分类+商品列表）
  ├── shenmohuan_control.lua  — 其他控制按钮
  └── shenmohuan_control_shop.lua  — 商店开关按钮 (CONTROL_ACCEPT)
```

## Key Pattern: Toggle via PushEvent

### Control Button (shenmohuan_control_shop.lua)

```lua
-- 监听 CONTROL_ACCEPT (F键/空格)
function self:Passive_OnControl(control, down)
    if control == CONTROL_ACCEPT then
        if down then
            self:StartDrag()                            -- 启动拖拽（可拖动位置）
            self.owner:PushEvent("shenmohuan_shop_onclick")  -- 触发打开/关闭
        else
            self:EndDrag()
        end
    end
end
```

### Shop Widget Listens (shenmohuan_shop.lua)

```lua
self.owner:ListenForEvent("shenmohuan_shop_onclick", function()
    if self.image.shown then
        self.image:Hide()
    else
        self.image:Show()
    end
end)
```

## Drag-to-Move + Position Persistence

The shop control button supports drag-to-move with persistent position:

```lua
function self:StartDrag()
    local mousepos = TheInput:GetScreenPosition()
    self.dragPosDiff = self:GetPosition() - mousepos
    self.followhandler = TheInput:AddMoveHandler(function(x,y) self:SetDragPosition(x,y) end)
end

function self:EndDrag()
    self.followhandler:Remove()
    self:TrySaveDragState()
end

function self:TrySaveDragState(delay)
    delay = delay or 0.33
    -- Save position to persistent string via TheSim:SetPersistentString
    local pos = self:GetPosition()
    local save_data = { x = pos.x, y = pos.y, z = pos.z }
    TheSim:SetPersistentString("mod_config_data/Shenmohuan_MakeDraggableFn_shop", json.encode(save_data), true)
end

function self:LoadDragState()
    TheSim:GetPersistentString("mod_config_data/Shenmohuan_MakeDraggableFn_shop", function(success, data)
        if success then
            local save_data = json.decode(data)
            self:SetPosition(save_data.x, save_data.y, save_data.z)
        end
    end)
end
```

## Shop UI Structure

### Registration (shenmohuan_register.lua)

```lua
AddClassPostConstruct("widgets/controls", function(self)
    local Shenmohuan_Shopping = require("widgets/shenmohuan_shop")
    self.Shenmohuan_Shopping = self:AddChild(Shenmohuan_Shopping(self.owner))
    self.Shenmohuan_Shopping:Show()
end)

AddClassPostConstruct("widgets/controls", function(self)
    local Shenmohuan_control_shop = require("widgets/shenmohuan_control_shop")
    self.Shenmohuan_control_shop = self:AddChild(Shenmohuan_control_shop(self.owner))
    self.Shenmohuan_control_shop:Show()
end)
```

### Category Tabs (5 tabs)

```lua
local Buttontable = { "dstitem_list", "food_list", "synthetic_list", "item_list", "vip" }
-- Each tab is an ImageButton from images/shop/<name>.xml
```

### Item Grid (ScrollingGrid)

```lua
self.widget[name] = self.image:AddChild(TEMPLATES.ScrollingGrid(self.list[name], {
    context = {},
    widget_width = 300,
    widget_height = 300,
    num_visible_rows = 6,
    num_columns = 4,
    item_ctor_fn = ScrollWidgetsCtor,
    apply_fn = ApplyDataToWidget,
    scrollbar_offset = 10,
    scrollbar_height_offset = -60,
}))
```

### Tab Click → Switch Grid

```lua
self.control[name]:SetOnClick(function()
    if self.name ~= nil then
        self.widget[self.name]:Hide()     -- hide previous
    end
    self.name = name
    self.widget[name]:Show()              -- show new
end)
```

### Close Button

```lua
self.image_close_widgets = self.image:AddChild(ImageButton("images/shop/onclose.xml", "onclose.tex"))
self.image_close_widgets:SetPosition(580, 320, 0)
self.image_close_widgets:SetOnClick(function()
    self.image:Hide()
end)
```

## Data Structure

### Item Entry (Shop.lua)

```lua
{name = "log", diamond = 0, price = 50, size = 1, recycle = 18, xml = nil}
```

| Field | Description |
|-------|-------------|
| name | Prefab name (also used for atlas lookup) |
| diamond | Diamond currency price |
| price | Soul coin (镇魂币) price |
| size | Stack size per unit |
| recycle | Recycle value (0 = not recyclable) |
| xml | Optional atlas override path |

### Atlas Lookup for Item Icons

```lua
local function GetAtlas(imagename)
    local atlas = inventoryItemAtlasLookup[imagename .. ".tex"]
    if atlas then return atlas, imagename .. ".tex" end
    if TheSim:AtlasContains("images/inventoryimages1.xml", imagename .. ".tex") then
        atlas = "images/inventoryimages1.xml"
    elseif TheSim:AtlasContains("images/inventoryimages2.xml", imagename .. ".tex") then
        atlas = "images/inventoryimages2.xml"
    elseif softresolvefilepath("images/inventoryimages/" .. imagename .. ".xml") ~= nil then
        atlas = "images/inventoryimages/" .. imagename .. ".xml"
    else
        atlas = "images/inventoryimages1.xml"
    end
    inventoryItemAtlasLookup[imagename .. ".tex"] = atlas
    return atlas, imagename .. ".tex"
end
```

## Requires Custom ImageButton Widget

This mod uses a custom `shenmohuan_imagebutton` widget instead of the standard `ImageButton`. If porting this pattern, verify the ImageButton widget is available or replace with standard `ImageButton`.
