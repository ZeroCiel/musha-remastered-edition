# DST UI Fixes — Case Studies

Recurring patterns for fixing visual bugs in DST mod UI screens.

## Pattern: Dialog Too Large / Buttons Misplaced

When users report a dialog is oversized and close/action buttons are in wrong positions, the root cause is `SetScale` on the background image being too large for the screen resolution. Fixing it requires a proportional recalibration of all child widget positions.

### Case: Mingsheng Teleport Screen (2024-05-21)

**Reported issues:**
- 传送框过大 (teleport dialog too big)
- 退出键位置错误 (close button in wrong position)

**Root cause:** Background `SetScale(0.7, 0.7, 1)` was too large for 1920×991 game window.

**Fix pattern:**

```lua
-- BEFORE (broken)
self.bg:SetScale(0.7, 0.7, 1)
self.title:SetPosition(0, 125)           -- title
self.close_btn:SetPosition(290, 125)     -- close button (too far right)
local start_y = 55
local spacing = -42

-- AFTER (fixed)
self.bg:SetScale(0.55, 0.55, 1)         -- reduce ~20%
self.title:SetPosition(0, 110)           -- adjust Y down
self.close_btn:SetPosition(225, 112)     -- bring X inward (~290 * 0.55/0.7 ≈ 228)
local start_y = 45                        -- compress list position
local spacing = -38                       -- tighten spacing
```

**Calibration formula:**
- `new_scale = old_scale * reduction_factor` (e.g., 0.7 → 0.55 = ~79% of original)
- Title: reduce Y by ~10-15px (compensates for smaller background top edge)
- Close button X: `old_x * (new_scale / old_scale)` ≈ proportional
- List entries: `start_y` reduced by ~10px, `spacing` tightened by ~4px
- Confirm button: auto-adjusts because it uses `start_y`/`spacing` variables

**Verification:** Ask the user to retest in-game. Tweak values if alignment is still off.

## Pattern: Star/Favorite Icon Using Wrong Texture

```lua
-- ❌ 复制粘贴遗留：star 用了 slot 的贴图
local star = entry:AddChild(Image("...mingsheng_teleport_slot.tex"))
star:SetScale(0.3, 0.3)
star:SetPosition(140, 1)

-- ✅ 应该用独立的 star 贴图
local star = entry:AddChild(Image("...mingsheng_teleport_star.tex"))
```

This is usually a copy-paste artifact. Check if a separate star/favorite asset exists; if not, note it as a cosmetic issue (doesn't affect functionality).

## Pattern: Adding UI Layout Comments to Help Manual Adjustment

When the user wants to manually tweak UI positions (rather than you guessing correct values), add a comprehensive annotation block to the code file. This turns the file into a self-documenting reference.

### Annotation Structure

**1. ASCII layout diagram at the top of the file:**

```
-- ╔══════════════════════════════════════════════════════════╗
-- ║                    UI 布局示意 (坐标原点 = 屏幕中心)      ║
-- ╠══════════════════════════════════════════════════════════╣
-- ║                                                          ║
-- ║   ┌──────────────────────────────────────────────┐       ║
-- ║   │  [背景 bg] 居中, SetScale 控制整体大小        │       ║
-- ║   │                                              │       ║
-- ║   │  RECORDED WAYPOINTS              [×关闭按钮] │ ← y≈110
-- ║   │  (title, x=0 居中)      (close_btn, x=右边)  │       ║
-- ║   │                                              │       ║
-- ║   │  ┌──────────────────────────────────┐ ★     │ ← entry[1]
-- ║   │  │ [slot背景] 传送点名称(金色文字)    │       │       ║
-- ║   │  └──────────────────────────────────┘       │       ║
-- ║   │       ... (up to 4 entries) ...             │       ║
-- ║   │                                              │       ║
-- ║   │        [确认按钮 confirm_btn]                 │       ║
-- ║   └──────────────────────────────────────────────┘       ║
-- ╚══════════════════════════════════════════════════════════╝
```

**2. Each adjustable parameter marked with `← [可调]`:**

```lua
self.bg:SetScale(0.55, 0.55, 1)    -- ← [可调] 面板整体缩放比例
self.title:SetPosition(0, 110)      -- ← [可调] 标题位置 (x=0居中, y越大越靠上)
self.close_btn:SetPosition(225, 112) -- ← [可调] x=按钮水平位置, y=对齐标题
local start_y = 45                   -- ← [可调] 列表起始Y
local spacing = -38                  -- ← [可调] 条目间距(负数)
text:SetPosition(-85, 4)            -- ← [可调] x=文字左偏移, y=垂直微调
star:SetPosition(140, 1)            -- ← [可调] 星标位置
```

**3. Position calculation formulas in comments:**

```lua
-- entry[i] 实际位置 = start_y + (i-1) * spacing
--   例: start_y=45, spacing=-38
--     entry[1] y=45, entry[2] y=7, entry[3] y=-31, entry[4] y=-69

-- 确认按钮公式: y = start_y + 4 * spacing - 20
--   即 45 + 4*(-38) - 20 = -127
```

**4. A quick-reference legend at the top:**

```lua
-- ║  调整整体大小: 改 bg:SetScale(sx, sy, 1)                  ║
-- ║  调整标题位置: 改 title:SetPosition(x, y)                 ║
-- ║  调整关闭按钮: 改 close_btn:SetPosition(x, y)             ║
-- ║  调整列表起始: 改 start_y (越大越靠上)                    ║
-- ║  调整列表间距: 改 spacing (负数, 越小间距越大)             ║
-- ║  调整确认按钮: 改 confirm_btn:SetPosition(x, y)            ║
```

### When to Use This

- User says they'll manually adjust the UI after you've attempted a fix
- User asks for comments/documentation to help with their own adjustments
- The exact correct values depend on testing that you can't perform (no game access)
- The UI has many interdependent position values and a diagram helps visualize

## Key Principles

1. **Scale first, then position** — SetScale on the background, then adjust all child positions relative to the NEW visual boundaries
2. **Use variables for spacing** — `start_y` and `spacing` as locals so confirm button position auto-adjusts
3. **Close button belongs at top-right of visible background** — its X position should be roughly `bg_visual_half_width - close_btn_half_width`
4. **Font size should match dialog scale** — reduce from 24 to 22 when shrinking background
5. **Test at 1920px width** — most common DST resolution; dialog should fit comfortably within the game viewport
6. **Add `← [可调]` markers** — when user will do the final tuning, mark every tunable value with a Chinese annotation so they can find them quickly
