# DST 滚动列表与 UI 行滑入动画（实测模式）

## ScrollingGrid（官方模板，明生传送/神魔环商店同款）
`local TEMPLATES = require "widgets/redux/templates"`
```lua
self.list = self.root:AddChild(TEMPLATES.ScrollingGrid({}, {
    context = { screen = self },
    widget_width = 387, widget_height = 65,
    num_visible_rows = 4, num_columns = 1,
    item_ctor_fn = item_ctor_fn,   -- 造行：返回 Widget，行内塞 Image/Text/ImageButton
    apply_fn = apply_fn,           -- 填数据：widget.data/data_index，空数据就 widget:Hide()
    scrollbar_offset = 10, scrollbar_height_offset = 0,
    peek_percent = 0, allow_bottom_empty_row = true,
}))
self.list:SetPosition(-5, -15)
self.list:SetItemsData(self.items)   -- 刷新 = 重设数据
```
- 参考实现：`mods/mingsheng/scripts/screens/mingsheng_teleportscreen.lua`（含行拖拽排序：只交换 order 字段、退出拖拽再按 order 重排）
- 行内图片要 `w.image.scale_on_focus = false` + `ignore_standard_scaling = true`，否则聚焦会被缩放
- 透明热区点击：`ImageButton("images/ui.xml","blank.tex")` + `image:SetTint(1,1,1,0)` + `ScaleToSize(w,h)`

## 行滑入动画（Widget 自带动画，无需手写逐帧）
Widget 构造时自带 `uianim` 组件，`Widget:MoveTo(from, to, time, fn)` / `ScaleTo` / `TintTo` 可直接用（Vector3 参数）。
```lua
local row = self.content:AddChild(Widget("quest_row_" .. i))
row.name = row:AddChild(Text(UIFONT, 40))
row.status = row:AddChild(Text(UIFONT, 34))
row.target_y = 60 - (i-1)*115
row:Hide()

function self:PlayQuestSlideIn()
    if self._quest_slide_playing then return end
    self._quest_slide_playing = true
    for i = 1, 3 do
        local row = self.quest_slots[i]
        if row and row.shown then
            local from_y = row.target_y - 90
            row:SetPosition(0, from_y)
            row.inst.components.uianim:MoveTo(
                Vector3(0, from_y, 0), Vector3(0, row.target_y, 0),
                0.30 + (i-1)*0.08,                 -- 逐行错开
                i == 3 and function() self._quest_slide_playing = false end or nil)
        end
    end
end
```
要点：
- **行必须是容器 Widget**（`row.name` / `row.status` 挂行下、坐标相对行 0,0），才能整行位移；文字直接挂 content 就用绝对坐标没法整体滑
- 行位置用 `row.target_y` 记目标值，动画只是 `SetPosition(目标-偏移)` → MoveTo 到目标
- 触发条件用"状态从无到有"（`has_task and not self._prev_has_task`），并设 `_prev_has_task`
- **面板关着时也要能播**：挂 `self._quest_slide_pending = true`，在 `ShowPanel()` 里 `self:Refresh(); self:Show()` 之后补播
- 防重入用 `_quest_slide_playing` 标志，最后一行的完成回调里清掉

## 不要把两个刷新函数写成两份
面板常有 `OnGameDataChanged`（dirty 监听）和 `self:Refresh()` 两份重复代码，改一处漏一处必出 bug。
把公共逻辑抽成 `self:UpdateXxx(...)`（如 `UpdateQuestRows`），两处都只调它。

## 面板数据在 replica 上，UI 改造要先对字段
UI 读的是 `replica.cached_data.userdata.<字段>`；服务端改了字段名（如 quests_for_advance → daily_quests）
而 UI 没跟着改，表现就是"面板显示空/暂无任务"——**不是存档问题，别让用户重开档**。排查顺序：
先让用户跑聊天命令看服务端真实数据，再对比 UI 读的字段名。
