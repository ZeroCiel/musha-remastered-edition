# DST Full-Screen Overlay Pattern

How to add a click-to-dismiss dark overlay behind a modal panel in DST.

## The Pattern

```lua
-- 1. Create overlay BEFORE the panel (renders behind)
self.overlay = self:AddChild(ImageButton("images/global.xml", "square.tex"))
self.overlay:SetVAnchor(1)                    -- 1 = ANCHOR_MIDDLE
self.overlay:SetHAnchor(1)                    -- 1 = ANCHOR_MIDDLE
self.overlay:SetScaleMode(SCALEMODE_FILLSCREEN)
self.overlay:SetImageNormalColour(0, 0, 0, 0.6)  -- semi-transparent black
self.overlay:SetOnClick(function()
    TheFrontEnd:PopScreen()
end)

-- 2. THEN create the panel widget
self.root = self:AddChild(Widget("root"))

-- 3. ★ CRITICAL: root consumes all mouse events to prevent click-through
--    Without this, clicks on empty areas of the panel fall through to overlay
self.root.OnMouseButton = function(widget, button, down, x, y)
    return true  -- consume event, don't propagate to overlay
end
```

## Why It Works

- DST processes input from children added LAST (topmost) first
- Overlay added first → behind the panel → only catches clicks outside the panel
- Panel added after → on top → its buttons/entries get clicks first
- `root.OnMouseButton` returning `true` consumes ALL clicks within the panel area,
  preventing them from falling through to the overlay when children don't handle them

## Alternative: Color via constructor (when SetColour/SetImageNormalColour is unavailable)

Some DST versions don't expose `SetColour` or `SetImageNormalColour` on ImageButton.
In that case, pass colors through the constructor using a borrowed texture tinted black:

```lua
-- Use mod's own loaded texture, tint black via constructor colors
self.overlay = self:AddChild(ImageButton(
    "images/teleport/mingsheng_teleport_bg.xml",  -- atlas (loaded in Assets)
    "mingsheng_teleport_bg.tex",                   -- normal
    nil, nil, nil, nil,                            -- focus/disabled/down/selected
    {0, 0, 0, 0.6}, {0, 0, 0, 0.6}, 1            -- focus_color, normal_color, scale
))
```

**Warning:** The 7th/8th params being `focus_color`/`normal_color` is NOT the official
ImageButton constructor (which takes `scale`/`offset` in those positions). This works
only because DST's ImageButton passes all extra args through to `SetTextures()` which
silently ignores unknown parameters. Use `SetImageNormalColour()` when available instead.

## Critical Pitfalls

### ❌ Empty ImageButton() constructor

```lua
-- NEVER do this:
self.overlay = self:AddChild(ImageButton())
```

Result: DST creates a default BUTTON widget from `images/frontend.xml:button_long.tex`
with `help_message = "选择"`. This button intercepts ALL clicks everywhere on screen, 
including panel clicks. The close button and entry clicks will all trigger the overlay's 
action instead.

### ❌ ANCHOR_BOTH for SetVAnchor/SetHAnchor

```lua
-- NEVER do this:
self.overlay:SetVAnchor(ANCHOR_BOTH)   -- resolves to nil! crashes!
```

`ANCHOR_BOTH` is a scale mode constant, NOT a VAnchor/HAnchor value. 
VAnchor/HAnchor only accept: 0 (BOTTOM/LEFT), 1 (MIDDLE), 2 (TOP/RIGHT).

### ❌ Wrong overlay order

```lua
-- If panel is created BEFORE overlay:
self.root = self:AddChild(Widget("root"))     -- first
self.overlay = self:AddChild(ImageButton(...)) -- second → ON TOP of panel
-- Result: overlay blocks ALL clicks to the panel
```

## Real-World Error Log

```
[string "scripts/widgets/widget.lua"]:417: calling 'SetVAnchor' on bad self 
(number expected, got nil)
...
self.overlay = self:AddChild(ImageButton())     ← empty constructor
self.overlay:SetVAnchor(ANCHOR_BOTH)            ← nil anchor
```

Two bugs combined: ImageButton() creates a default button, then ANCHOR_BOTH
crashes because it's not a valid VAnchor value.

## Fix Checklist

- [ ] `ImageButton("images/global.xml", "square.tex")` — explicit texture
- [ ] `SetVAnchor(1)` and `SetHAnchor(1)` — numeric, not ANCHOR_BOTH
- [ ] `SetScaleMode(SCALEMODE_FILLSCREEN)` — fills the entire screen
- [ ] Overlay created BEFORE root widget — renders behind the panel
- [ ] `SetOnClick` calls `TheFrontEnd:PopScreen()` — clean close
