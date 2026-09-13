# TEMPLATES.ScrollingGrid / TrueScrollList — DST 固定大小+下拉列表

来源：本次把神魔环(magic-ring)商店的 ScrollingGrid 算法移植到明生传送框时实测。
官方代码：`data/databundles/scripts/widgets/redux/templates.lua`（ScrollingGrid ~line 1961）、
`data/databundles/scripts/widgets/truescrolllist.lua`。

## ScrollingGrid 签名与参数

```lua
TEMPLATES.ScrollingGrid(items, opts)
-- items = 数据数组；opts 关键字段：
--   context                传给 ctor/apply 的上下文表（放 self 引用、选中态等）
--   widget_width/height    每个 item widget 的尺寸（宽高是布局网格单位）
--   num_visible_rows       可见行数
--   num_columns            列数
--   item_ctor_fn(context, index)  → 创建【一个】item widget
--   apply_fn(context, widget, data, index)  → 把 data 填进 widget（index 是数据索引）
--   scrollbar_offset / scrollbar_height_offset / scroll_per_click
--   peek_percent | peek_height | force_peek   底部预览行高（默认 widget_height*0.25）
--   end_offset（默认0.75）/ allow_bottom_empty_row(true→end_offset=1)
--   scissor_pad
```

机制（重要）：
- 内部创建 **(num_visible_rows+2) × num_columns** 个 widget 放进 Grid，由 TrueScrollList
  **复用**这池子——滚动时只是把不同数据 shift 到同一批 widget 上，widget 与数据【不是一一对应】。
- 可见区域(scissor) = widget_width*num_columns × widget_height*num_visible_rows(+peek)。
- 滚动条自动生成（上下箭头+可拖 marker），`CanScroll()==false`（end_pos<=1）时自动隐藏。
- 滚轮由 OnUpdate 监听 CONTROL_SCROLLBACK/SCROLLFWD 处理，无需手写。

## TrueScrollList 关键接口（滚动状态下取映射用）

- `SetItemsData(items)` — 换数据后自动 RefreshView
- `Scroll(step)` / `ScrollToDataIndex(i)` / `ScrollToScrollPos(row)` / `ResetScroll()`
- `current_scroll_pos` / `target_scroll_pos` / `end_pos` — 行单位滚动位置
- `displayed_start_index` — **首个可见 widget 对应的数据索引**（RefreshView 里更新），
  已知 widget 槽位 i → 数据索引 = displayed_start_index + i
- `GetIndexOfFirstVisibleWidget()` → start_index, row_offset（row_offset 是部分行偏移）
- `IsItemFullyVisible(i)` / `CanScroll()` / `ForceItemFocus(itemindex)`
- apply_fn 收到的 index 就是数据索引（start_index+i），不是槽位号

## 坑：手写 scroll_offset 列表是坏的

明生 `mingsheng_teleportscreen.lua` 里 `self.scroll_offset` 在第27行声明、
第249-250行读取，但**全程从未赋值**——MAX_VISIBLE=4 时第5-7个传送点永久隐形，
没有任何滚动 UI。结论：不要手搓滚动偏移，直接上 ScrollingGrid（或 ScrollableList），
滚动状态由组件自己持有。

## 坑：拖拽排序 vs ScrollingGrid widget 复用

明生传送框原有拖拽柄排序（drag_handle 拖到固定槽位换 order），槽位 slot 与 entry 固定绑定。
ScrollingGrid 下 widget 是复用池，槽位≠数据索引，旧拖拽逻辑无法直接映射。
三方案取舍：
1. **ScrollingGrid + 上下移按钮排序**（推荐）—— 砍掉拖拽，视觉/滚动全自动，改动可控
2. 保留拖拽 + 手写滚轮滚动 —— 只修 scroll_offset，但滚动条丑、自造轮子
3. ScrollingGrid + 用 displayed_start_index 重写拖拽映射 —— 最理想但风险最高

## ✅ 方案3实测成功：ScrollingGrid + 拖拽重写（2026-08 明生传送框）

用户选了方案3并跑通。关键做法：**数据索引在 apply_fn 里挂到 widget 上**（复用池也能知道"这个 widget 现在显示第几个数据"）：
```lua
local function apply_fn(context, widget, data, index)
    widget.data = data
    widget.data_index = index   -- 复用池里每个 widget 记住当前数据索引
    ...
end
```

**item_ctor_fn 创建固定子控件**：slot ImageButton（点击选中）+ highlight Image（选中高亮，黄色 tint）+ Text + drag ImageButton（拖拽柄，OnMouseButton 触发 StartDrag）。闭包捕获 self 即可，不需要 context。

**拖拽逻辑**：
```lua
function MingshengTeleportScreen:StartDrag(widget)
    self.drag_src_index = widget.data_index          -- 源 = widget 上挂的索引
    self.drag_target_index = widget.data_index
    -- 变灰所有可见条目，AddMoveHandler 里：
    --   dy = 鼠标y - 起始y；row_offset = floor(dy / WIDGET_H + 0.5)
    --   target = clamp(src + row_offset, 1, #waypoints)
    --   self.list:Scroll(-1/1) 自动滚动跟随（用 displayed_start_index 判断是否出可视区）
end

function MingshengTeleportScreen:EndDrag()
    -- 交换 waypoints[src].order 和 waypoints[dst].order
    -- table.sort 按 order 重排；找到被拖 waypoint 新位置设为 selected_index
    -- self.list:SetItemsData(self.waypoints)  ← 必须重灌数据
    -- 恢复颜色；self.list:RefreshView()
end
```

要点：
- **WIDGET_W/H 必须等于 slot 图实际渲染尺寸**：图 PNG 922x154 × scale 0.42 ≈ 387x65，取 WIDGET_W=387, WIDGET_H=65，否则 Grid 布局错位。查 PNG 尺寸用 Python struct 读 IHDR。
- 条目列表放 root 位置 = 原可见行中心：4行从 y=75 到 -105，中心 -15。
- `self.list:GetListWidgets()` 拿复用池遍历变灰/恢复颜色；`displayed_start_index` 判断拖拽目标是否出可视区；`SetItemsData` 重排后强制刷新。
- 滚动条只在需要时自动显示（end_pos>1），无需手动控制显隐。
- 黑幕点关、RPC 跨分片、键盘 CONTROL_ACCEPT 传送逻辑原样保留，只换列表部分。

### 最终产品决策（2026-08，用户否决拖拽）

方案3技术上跑通了，但**产品上用户否决了拖拽**：每行一个拖拽柄在 UI 上显示为一根根竖条（用户原话"一根根小骨头绑在传送点后面"），视觉突兀。
最终做法：
- 拖拽柄创建后 `w.drag:Hide()`，apply_fn 里也**不要**再 `widget.drag:Show()`（两个地方都要改，否则刷新时又冒出来）
- StartDrag/EndDrag 代码保留但不触发（无手柄=无入口），滚动/选择/传送全部正常
- 结论：用户偏好**纯滚动列表，不要每行一个操作手柄**；排序功能如果需要，用上下移按钮（方案1）而不是行内手柄。方案3的 ScrollingGrid 核心（复用池、data_index 挂载、SetItemsData 刷新）依然有效，只是拖拽部分废弃。
- 字号教训：明生传送框 Text 用 NEWFONT 54 太大，用户要求改小到 38（NEWFONT 38 + RegionSize 240x44 正常显示）。UI 文案字号宁小勿大。

### 最终产品决策（2026-08-20 终版：行内星星热区 = 传送按钮，不用底部按钮）

传送按钮**不设底部 confirm**，改为**每行右侧星星区域直接是传送按钮**（用户原话："传送按钮不设置在底部 而是用右边的传送按钮的图标去替代"）：
- 删掉底部 confirm_btn（即使有 282x103 的 confirm 图也不用——用户嫌"附加在底部"）；grep 确认代码里无残留后再让用户重启（用户报"底部按钮还在"多半是没重启，不是没删）
- **星星不是 drag.tex！** PIL 逐列扫描 PNG 证实：slot.png（922x154）右侧自带黄色星星装饰（col5/col7 有黄色像素），drag.png（55x194）是灰色骨头（几乎无黄色）。把 drag.tex 挂点击是错的——骨头重新显示（用户嫌"骨头又多出来了"）且点击无效
- 最终方案：**透明热区覆盖在 slot 自带星星上**：
```lua
w.tp_btn = w:AddChild(ImageButton("images/ui.xml", "blank.tex"))
w.tp_btn.image:SetTint(1, 1, 1, 0)     -- 全透明，视觉上还是底图星星
w.tp_btn.image:ScaleToSize(150, 60)    -- ⚠️ 必须 .image:ScaleToSize！星星区域：条目中心右侧约 x=120
w.tp_btn:SetPosition(120, 0)
w.tp_btn.scale_on_focus = false
w.tp_btn.ignore_standard_scaling = true
w.tp_btn:SetOnClick(function() ... SelectEntry(data_index); DoTeleport() ... end)
```
- apply_fn 里对应改成 `widget.tp_btn:Show()`（不要有 drag 相关残留）
- 条目本体点击仍只选择（高亮），回车传送保留

## 坑：ScaleToSize 是 Image 的方法，ImageButton 上没有

```lua
w.tp_btn:ScaleToSize(150, 60)   -- ❌ nil method，进游戏即崩：
-- "[string ...]:110: attempt to call method 'ScaleToSize' (a nil value)"（item_ctor_fn 里炸，整个界面起不来）
w.tp_btn.image:ScaleToSize(150, 60)   -- ✅ 正确：对内部 image 调
```
ImageButton 有 SetScale / SetSize（后者是 scale 变体？实际用 `SetPosition` + image:ScaleToSize 或 SetScale 即可），
但 ScaleToSize 只定义在 Image 上。透明热区按钮（blank.tex 全透明 tint）靠 image:ScaleToSize 定点击范围，
**热区尺寸不生效时点击区域会按 blank.tex 原始尺寸算，导致星星区域点不到**。

教训：用户对"动作按钮放哪"有强偏好——**行内图标比底部独立按钮好**。且**图标长什么样不能靠猜**：用户说"按下去的凹键"时，用 PIL 列扫描（按 8 列统计 alpha>100 像素数 + 黄色像素数）定位装饰在底图还是独立图，比分析界面截图可靠。装 pillow：`python311 -m pip install pillow -i https://pypi.tuna.tsinghua.edu.cn/simple`（墙内直连超时）。

## 坑：DST Image/Widget 没有 SetShown 方法

```lua
widget:SetShown(bool)   -- ❌ nil method，进游戏即崩：
-- "attempt to call method 'SetShown' (a nil value)"（apply_fn 第一行就炸）
widget:Show() / widget:Hide()   -- ✅ 唯一合法写法
```
这是神魔环源码里的写法（它自扩展过 ImageButton），移植到原版 DST 时不能用。
条件显隐一律写 if/else 分支调 Show/Hide。

## 工作流坑：patch 删行时 new_string 不能还包含那行

第一次"修复" SetShown 时，old_string 是 SetShown 行、new_string 是"SetShown 行 + Show/Hide 分支"——
结果坏行原样保留，错误照旧。正确做法：old_string 含坏行，new_string **只含**替换后的 Show/Hide 分支。
改完必须 grep 确认坏调用已消失（`grep -n SetShown 文件`）再让用户重启测试，不要只看 patch 成功。

## 坑：鼠标点击 ImageButton 映射成 CONTROL_ACCEPT → 误触发"确认"逻辑

ScrollingGrid 版传送框上线后，用户报"点了会自动传送"：鼠标点击条目时 DST 会把点击
同时映射成 CONTROL_ACCEPT 事件，焦点不在条目上时事件冒泡到 Screen:OnControl 的
CONTROL_ACCEPT 分支 → 直接 DoTeleport（构造时默认 selected_index=1 更让"点哪传哪"）。

修复：CONTROL_ACCEPT 分支用 `TheInput:IsMouseDown(MOUSEBUTTON_LEFT)` 区分来源——
鼠标点击（左键按下中）只选择不传送，键盘/手柄回车才传送：
```lua
if control == CONTROL_ACCEPT and self.selected_index then
    -- 鼠标点击会映射成 CONTROL_ACCEPT，但点击只应选择条目
    if not self.drag_mode and not TheInput:IsMouseDown(MOUSEBUTTON_LEFT) then
        self:DoTeleport()
    end
    return true
end
```
配套：底部加回确认按钮（images/teleport/mingsheng_teleport_confirm.tex, 282x103,
scale 0.5, 位置 (0,-185)），SetOnClick → DoTeleport，恢复原版"点击选择→点确认/回车传送"交互。
`TheInput:IsMouseDown` 在 `data/databundles/scripts/input.lua`（~line 293）确认存在。

## Lua 语法检查（DST 无独立 luac）

DST 不提供 luac/lua.exe 可执行文件（Lua 内嵌在引擎里）。改完 .lua 先用 Python luaparser 验语法：
```bash
# hermes venv 没有 pip；用系统 Python311
"C:/Users/Administrator/AppData/Local/Programs/Python/Python311/python.exe" -m pip install luaparser
python -c "from luaparser import ast; ast.parse(open(r'D:\SteamLibrary\...\x.lua', encoding='utf-8').read()); print('SYNTAX OK')"
```
注意：luaparser 认识不了 DST 全局（TEMPLATES 等），但纯语法错误（括号不配对、end 缺失）能抓出来。写文件后必跑，避免进游戏才炸。
