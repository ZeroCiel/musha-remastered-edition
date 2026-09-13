# DST 可滚动列表 UI — ScrollingGrid / TrueScrollList / Screen vs HUD Widget

类知识：DST 里做「长列表 + 滚轮滚动 + 滚动条」的标准做法。2026-09-10 musha 面板任务区
想从固定 6 行改成可滚动（用户原话「拉动滚动类似明生传送」）时，读明生神行界面（mingsheng）后整理。

## 0. 工作流偏好（重要，先读）
这个用户有多个 mod，其中 `mingsheng`（明生）是功能完整的参考实现。当要求做一类 UI 功能
（滚动列表、拖拽排序、遮罩关闭、热区、ScrollingGrid），**先读明生的对应实现再动手**，不要手搓。
用户明确说过「呃呃 你读一下明生的那边行不行」——当时我手搓了固定行 + 自己写滚轮处理，方向不对。
参考文件：`mods/mingsheng/scripts/screens/mingsheng_teleportscreen.lua`（ScrollingGrid + 拖拽排序 + 黑幕关闭）。
教训：手搓之前先 `grep -rl "ScrollingGrid" mods/mingsheng` 看有没有现成模板。

## 1. 两条路线对比（先分清，再选）
| | A. 真 Screen + ScrollingGrid（明生） | B. HUD Widget + 手搓固定行（musha 现状） |
|---|---|---|
| 打开方式 | `TheFrontEnd:PushScreen(screen(inst))` | `AddClassPostConstruct("widgets/controls")` + `AddChild` |
| 滚动 | 自带滚动条 + 滚轮 + scissor 裁剪 | 无，行数写死（超出看不到） |
| 滚轮事件 | 走 `OnControl` 的 `CONTROL_SCROLLBACK/FWD` | HUD widget 里不可靠（滚轮走 OnMouseButton） |
| 关闭 | 黑幕 ImageButton + 关闭按钮 + `CONTROL_CANCEL` | `OnMouseButton` 自己判键 |
| 代价 | 打开方式要改（PushEvent→PushScreen），所有调用点跟着改 | 无滚动，行数有上限 |

**结论**：要滚轮滚动就必须用 ScrollingGrid；ScrollingGrid 要滚起来必须让它拿到焦点且跑在
frontend/screen 上下文里。所以 = 走 A（把面板从 HUD widget 改成真 Screen）。
HUD widget 里塞 ScrollingGrid 滚不动，别试。

## 2. ScrollingGrid 用法（`widgets/redux/templates.lua:1961`）
`TEMPLATES.ScrollingGrid(items, opts)` → 返回 `TrueScrollList`。
opts 关键字段：
```lua
TEMPLATES.ScrollingGrid({}, {
    context = { screen = self },
    widget_width = 387, widget_height = 65,
    num_visible_rows = 4, num_columns = 1,
    item_ctor_fn = item_ctor_fn,   -- 造一行 widget（返回 Widget）
    apply_fn = apply_fn,           -- 填数据：apply_fn(context, widget, data, index)
    scrollbar_offset = 10,
    scrollbar_height_offset = 0,
    peek_percent = 0,              -- 底部露出下一行的比例；0=不露
    allow_bottom_empty_row = true,
})
list:SetPosition(-5, -15)
list:SetItemsData(self.items)      -- 灌数据
list:RefreshView()                 -- 刷新
list:GetListWidgets()              -- 遍历当前所有行（拖拽/改色用）
```
- 行内加按钮：`ImageButton` + `SetOnClick`；`keep_scale_on_focus`/`ignore_standard_scaling`
  避免 hover 缩放错位（明生里是 `scale_on_focus=false; ignore_standard_scaling=true`）。
- 行高/宽写死，`num_visible_rows` 决定可见行数，超出的自动进滚动区。

## 3. 滚轮为什么能滚（机制）
- `TrueScrollList:OnControl`（`widgets/truescrolllist.lua:619`）处理
  `control_up=CONTROL_SCROLLBACK` / `control_down=CONTROL_SCROLLFWD`；
  条件：`down and (self.focus or custom_focus_check) and self.scroll_bar:IsVisible()`。
- 鼠标滚轮被 `TheInput` 自动翻译成这两个 control（`TheInput:GetControlIsMouseWheel(control)`）；
  滚轮原始键码是 `MOUSEBUTTON_SCROLLUP=1003 / SCROLLDOWN=1004`（constants.lua）。
- **必须给焦点**：`self.default_focus = self.list`（Screen 属性），否则滚轮不进来。
  实践：`self.root` 用 ANCHOR_MIDDLE 居中，`self.default_focus = self.list`。

## 4. Screen 的关闭模式（明生模板）
```lua
-- 全屏黑幕（半透明遮罩 + 点击关闭热区）
self.black_overlay = root:AddChild(Image("images/global.xml","square.tex"))
black_overlay:SetScale(50,50); black_overlay:SetTint(0,0,0,0.65)
self.black_clicker = root:AddChild(ImageButton("images/global.xml","square.tex"))
black_clicker:SetScale(50,50); black_clicker.image:SetTint(0,0,0,0)
black_clicker:SetOnClick(function() TheFrontEnd:PopScreen() end)
black_clicker:MoveToBack()          -- 垫到最底层，不然挡住列表点击

function Screen:OnControl(control, down)
    if Screen._base.OnControl(self, control, down) then return true end
    if not down then return false end
    if control == CONTROL_CANCEL then TheFrontEnd:PopScreen(); return true end
end
```
- ⚠️ `CONTROL_ACCEPT` 不可靠：鼠标点任何地方（含边框/背景）都会映射成 ACCEPT，无法区分键鼠点击
  与键盘回车 → 不要用 ACCEPT 触发「主操作」，改在行内按钮上挂 `SetOnClick`。

## 5. ScrollingGrid 里的拖拽排序（明生已实现，可照搬）
- 拖拽时**只交换 `order` 字段**，不动数组位置；松手后 `table.sort(items, order 比较)` + `SetItemsData` 重排。
- 拖拽中超出可视区自动滚：`list.displayed_start_index` 判断目标行是否越界 → `list:Scroll(±1)`。
- `TheInput:AddMoveHandler` + `TheInput:IsMouseDown(MOUSEBUTTON_LEFT)`，松手 `EndDrag()` 里 `handler:Remove()`。

## 6. 与 HUD widget 混用的注意
- HUD widget 的 `OnMouseButton` 是唯一能拿到鼠标键的地方（`widgets/widget.lua:56` 基类会派发给子 widget）。
  DST **没有** `OnMouseWheel` 回调——滚轮以独立 mouse button id 到达，见
  `references/widget-panel-ui.md` 的「Mouse input on a full-screen panel」节。
- 若坚持 HUD widget：只能做到「滚轮不关面板」，做不到滚动列表。
