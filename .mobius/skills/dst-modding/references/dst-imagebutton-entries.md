# DST ImageButton for List Entries

Use `ImageButton` for selectable list entries instead of manually managing `Widget` + `Image` + highlight widgets.

## Why ImageButton over Widget+Image

| Aspect | Widget + Image (hand-rolled) | ImageButton (official) |
|--------|------------------------------|------------------------|
| Highlight | Manual `hl:Show()/Hide()` | `SetSelected(true/false)` auto-swaps texture |
| Hover feedback | Must implement manually | Built-in `OnGainFocus`/`OnLoseFocus` |
| Click handling | Raw `OnMouseButton` callback | Standard `SetOnClick(fn)` |
| Down/press state | N/A | Built-in `image_down` texture swap |
| Scale on focus | N/A | Built-in `scale_on_focus` with `focus_scale` |

## The Pattern

```lua
-- Constructor: ImageButton(atlas, normal, focus, disabled, down, selected, scale, offset)
local entry = self.root:AddChild(ImageButton(
    "images/teleport/mingsheng_teleport_slot.xml",  -- atlas
    "mingsheng_teleport_slot.tex",                    -- normal (default slot bg)
    nil,                                              -- focus (nil = use normal)
    nil,                                              -- disabled
    nil,                                              -- down (nil = use focus)
    "mingsheng_teleport_highlight.tex",               -- selected (HIGHLIGHT!)
    {0.42, 0.42},                                     -- scale
    {0, 0}                                            -- offset
))

-- Child elements (text labels, icons) added normally
local text = entry:AddChild(Text(NEWFONT, 16, wp.name))
text:SetPosition(-85, 4)

-- Click handling
entry:SetOnClick(function()
    self:SelectEntry(i)
end)
```

## SelectEntry with ImageButton

```lua
function Screen:SelectEntry(index)
    if self.selected then
        self.entries[self.selected]:SetSelected(false)  -- auto-restores normal texture
    end
    self.selected = index
    if self.entries[index] then
        self.entries[index]:SetSelected(true)            -- auto-switches to selected texture
        if self.confirm_btn then
            self.confirm_btn:Show()
        end
    end
end
```

No more `hl:Show()`/`hl:Hide()` — ImageButton handles texture swapping internally.

## Avoiding Auto-Select

Don't call `SelectEntry(1)` in constructor. Let the user click first:

```lua
-- ❌ Don't do this:
if #self.waypoints > 0 then
    self:SelectEntry(1)  -- highlight appears before user interaction
end

-- ✅ Do this:
-- (just don't auto-select)
self.default_focus = self.entries[1]  -- keyboard navigation still works
```

## Frame/Background Scaling

When the entry background texture (slot frame) is wider than the panel background, it needs separate scaling:

```lua
-- Check UV proportions from .xml atlas files:
-- bg:   uw=0.555, vh=0.907 → panel at 0.55 scale → effective width ≈ 0.30
-- slot: uw=0.899, vh=0.299 → at 1.0 scale → effective width ≈ 0.90 (3x wider!)

-- Fix: scale slot proportionally to fit within panel
entry_scale = 0.42  -- 0.42 * 0.899 ≈ 0.38, slightly wider than bg (0.30) for visual padding
```

## Official ImageButton State Machine

From DST's `widgets/imagebutton.lua`:

```
Normal ──mouse enter──→ Focus (image_focus, focus_scale enlarges)
  │                        │
  │                        │ mouse leave
  │                        ↓
  │ ←────────────────── Normal
  │                        
  │ click down
  ↓
Down (image_down, optional move_on_click offset)
  │
  │ click up
  ↓
Selected / onClick fires

Selected (image_selected)
  │
  │ another entry selected
  ↓
Normal (SetSelected(false))
```

## Constructor Signature (Official)

```lua
ImageButton(atlas, normal, focus, disabled, down, selected, scale, offset)
--           1      2       3       4        5     6         7      8
```

- Params 3-6 default to `normal` if nil
- `scale`: table `{sx, sy}` or number → `{n, n}`
- `offset`: table `{ox, oy}` for image position within button
- **No color params in constructor** — use `SetImageNormalColour()`, `SetImageFocusColour()`, etc.
