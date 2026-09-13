# DST UI Widget Patterns — 屏幕/遮罩/点击处理

DST Screen 和 Widget 开发的常见模式和坑。

## ImageButton 构造函数签名

```lua
ImageButton = Class(Image, function(self,
    atlas,        -- .xml 图集
    tex,          -- .tex 纹理名
    focus_tex,    -- 聚焦态纹理 (nil=同 tex)
    disabled_tex, -- 禁用态纹理 (nil)
    hover_tex,    -- 悬停态纹理 (nil)
    pushed_tex,   -- 按下态纹理 (nil)
    focus_color,  -- 聚焦颜色 {r,g,b,a}
    normal_color, -- 普通颜色 {r,g,b,a}
    scale)        -- 缩放 (1=原始)
```

### 陷阱：无参 ImageButton()

```lua
-- ❌ 危险: 无参调用创建默认按钮 (frontend.xml/button_long.tex)
--    自带 "选择" 点击行为, 会拦截所有鼠标事件!
self.btn = self:AddChild(ImageButton())

-- ✅ 正确: 显式传入纹理
self.btn = self:AddChild(ImageButton(
    "images/xxx.xml", "xxx.tex",
    nil, nil, nil, nil,
    {1,1,1,1}, {1,1,1,1}, 1
))
```

### 陷阱：SetColour 不一定可用

```lua
-- ❌ 可能在 ImageButton 上报 nil
self.btn.image:SetColour(0, 0, 0, 0.6)

-- ✅ 用构造函数参数染色
ImageButton(atlas, tex, nil, nil, nil, nil,
    {0, 0, 0, 0.6},   -- focus_color 染黑半透明
    {0, 0, 0, 0.6},   -- normal_color 染黑半透明
    1)
```

## 锚点系统 (Anchor)

SetVAnchor / SetHAnchor 接受数字而非常量：

| 值 | VAnchor (纵向) | HAnchor (横向) |
|----|---------------|---------------|
| 0 | ANCHOR_BOTTOM | ANCHOR_LEFT |
| 1 | ANCHOR_MIDDLE | ANCHOR_MIDDLE |
| 2 | ANCHOR_TOP | ANCHOR_RIGHT |

```lua
-- ❌ 不存在! ANCHOR_BOTH 不是合法的锚点值
widget:SetVAnchor(ANCHOR_BOTH)  -- → nil, 报错

-- ✅ 用 SCALEMODE_FILLSCREEN 配合 ANCHOR_MIDDLE 铺满
widget:SetVAnchor(1)  -- ANCHOR_MIDDLE
widget:SetHAnchor(1)  -- ANCHOR_MIDDLE
widget:SetScaleMode(SCALEMODE_FILLSCREEN)  -- 撑满屏幕
```

## 全屏遮罩 + 点击关闭 模式

需求: 面板外点击关闭, 面板内正常交互。

```lua
-- 1. 遮罩 (先创建=在下层), ImageButton 可点击
self.overlay = self:AddChild(ImageButton(
    "images/xxx/your_bg.xml",
    "your_bg.tex",
    nil, nil, nil, nil,
    {0, 0, 0, 0.6}, {0, 0, 0, 0.6}, 1
))
self.overlay:SetVAnchor(1)
self.overlay:SetHAnchor(1)
self.overlay:SetScaleMode(SCALEMODE_FILLSCREEN)
self.overlay:SetOnClick(function()
    TheFrontEnd:PopScreen()
end)

-- 2. 面板容器
self.root = self:AddChild(Widget("root"))
self.root:SetHAnchor(ANCHOR_MIDDLE)
self.root:SetVAnchor(ANCHOR_MIDDLE)
self.root:SetPosition(0, 0)

-- 3. ★ 关键: root 消费鼠标事件, 防止穿透到遮罩
--    子 Widget (条目/按钮) 先处理 → 正常交互
--    root 自身区域 → 消费, 不传递到遮罩
--    root 之外 → 遮罩 OnClick 触发 → 关闭
self.root.OnMouseButton = function(widget, button, down, x, y)
    return true
end
```

## 事件传播顺序

DST 的 Widget 事件传播: **后创建先处理** (类似 DOM 的捕获阶段反向)

```
Screen
  ├── overlay (先创建, 下层)  ← 事件最后到达这里
  └── root (后创建, 上层)
        ├── bg (Image)
        ├── close_btn (ImageButton)  ← 点击事件先到这里
        └── entries
```

无 `root.OnMouseButton` 的情况:
- 点击条目 → 条目处理 ✓
- 点击面板空白 → 穿透到 overlay → **误关闭!**

有 `root.OnMouseButton` return true:
- 点击条目 → 条目先处理 ✓
- 点击面板空白 → root 消费, 不穿透 ✓
- 点击面板外 → overlay 接收到 → 关闭 ✓

## SetPosition 覆盖规则\n\nDST Widget 的 `SetPosition` 是**完全覆盖**，不是增量偏移。多次调用以最后一次为准。\n\n```lua\n-- ❌ 想偏移 X, 结果 Y 也被覆盖了\nentry:SetPosition(-300, 0)                         -- 第一次\n-- ... 中间代码 ...\nentry:SetPosition(0, start_y + (i-1) * spacing)   -- 第二次, 完全覆盖第一次!\n\n-- ✅ 正确: 只调一次, 把所有计算合并\nentry:SetPosition(offset_x, start_y + (i-1) * spacing)\n```\n\n如果确实需要 X 偏移 + Y 排序，在单次 SetPosition 中完成：\n```lua\nlocal x_offset = -300\nentry:SetPosition(x_offset, start_y + (i-1) * spacing)\n```\n\n## 布局坐标公式\n\n条目列表的常见布局公式，所有值可调：\n\n```lua\nlocal start_y = 134   -- 第1条 Y (越大越靠上, DST Y轴向上)\nlocal spacing = -45   -- 间距 (负数, Y轴向下递减)\n-- entry[i] y = start_y + (i-1) * spacing\n-- confirm y  = start_y + (n-1) * spacing + spacing * 0.5  (动态, 跟在最后条下方)\n```\n\nDST 屏幕坐标: 原点=屏幕中心, **正Y=上**, 正X=右。

### 动态布局: 确认按钮跟在可见区域最后一条下方

```lua
-- ✅ 按钮固定在可见区域底部 (不随总条目数飘移)
local MAX_VISIBLE = 4
self.confirm_btn:SetPosition(0, start_y + (MAX_VISIBLE - 1) * spacing + spacing * 0.5)

-- ❌ 不要用总条目数 — 条目数变化时按钮位置乱飘
local last_y = start_y + (#self.entries - 1) * spacing
```

## Text 防换行 & 截断

DST 的 `Text` 默认不限制宽度, 长文本会自动换行。控制方式:

```lua
local text = entry:AddChild(Text(NEWFONT, 32, name))
text:SetRegionSize(200, 40)           -- 固定宽度 (px), 超出区域则裁剪
text:SetHAlign(ANCHOR_LEFT)           -- 左对齐
text:SetVAlign(ANCHOR_MIDDLE)         -- 垂直居中
```

**⚠️ `SetTruncateString` 不存在于 DST Text widget！** 截断靠 `SetRegionSize` 限制宽度实现——超出区域的文本自然被裁剪不可见，无需额外方法。

## Image 暗化遮罩 (SetTint)

背景图如果预画了固定数量的槽位/装饰，用深色 tint 将其压暗到几乎不可见:

```lua
self.bg = self.root:AddChild(Image("images/xxx/bg.xml", "bg.tex"))
self.bg:SetPosition(0, 0)
self.bg:SetScale(0.42, 0.42, 1)
self.bg:SetTint(0.06, 0.06, 0.10, 0.92)  -- 近乎黑色, 预画槽位看不见
```

适用场景: 背景图有预画 UI 元素但你想动态创建, 深色遮罩让动态元素成为唯一视觉焦点。

## 纹理加载

模组只能使用在 `modmain.lua` Assets 中声明的纹理：

```lua
Assets = {
    Asset("ATLAS", "images/xxx/my_atlas.xml"),
    Asset("IMAGE", "images/xxx/my_image.tex"),
}
```

`images/global.xml` / `square.tex` 等 DST 内置资源不会自动加载到模组环境中。如需全屏遮罩, 复用模组自己的纹理染黑即可。

## ImageButton 作列表条目 (状态管理)

避免手动拼装 `Widget + Image(bg) + Image(highlight)`，直接用 ImageButton 的 built-in 状态：

```lua
-- ✅ ImageButton 的 selected 纹理 = 高亮态, 自动切换
local entry = self.root:AddChild(ImageButton(
    "images/xxx/slot.xml",            -- atlas
    "slot.tex",                       -- normal (默认槽位背景)
    nil,                              -- focus (nil=用normal)
    nil,                              -- disabled
    nil,                              -- down
    "slot_highlight.tex",             -- selected ★ (高亮纹理!)
    {0.32, 0.32},                     -- scale
    {0, 0}                            -- offset
))

-- 点击处理
entry:SetOnClick(function()
    self:SelectEntry(i)
end)

-- 选中/取消选中 (ImageButton 自动切换纹理)
-- DST Button API: Select() / Unselect(), 不是 SetSelected()!
function SelectEntry(index)
    if self.selected then
        self.entries[self.selected]:Unselect()  -- 恢复 normal
    end
    self.selected = index
    self.entries[index]:Select()                -- 显示 selected(高亮)
end
```

### 🔥 陷阱: scale_on_focus 覆盖自定义缩放

ImageButton 构造函数默认 `scale_on_focus = true` + `focus_scale = {1.2, 1.2, 1.2}` +
`normal_scale = {1, 1, 1}` + `move_on_click = true`。

**完整生命周期:**
```
构造: SetTextures → image:SetScale(image_scale)        ← 你的 {0.2}
悬停: OnGainFocus → image:SetScale(focus_scale)        ← 覆盖成 1.2!
离开: OnLoseFocus → image:SetScale(normal_scale)       ← 覆盖成 1.0!
```

这导致无论设 0.2/0.32/0.4，鼠标悬停就跳到 1.2 倍，离开变成 1.0 倍，与预期完全不符。

```lua
-- ❌ 构造函数设 scale 没有用，悬停/离开都会覆盖
local entry = self.root:AddChild(ImageButton(..., {0.2, 0.2}, ...))

-- ✅ 正确方案: 用 SetNormalScale/SetFocusScale 控制所有状态的大小
--    这两个方法写入 self.normal_scale / self.focus_scale，
--    OnGainFocus/OnLoseFocus 会读取它们来 SetScale，不会跳回默认值
entry:SetNormalScale(0.12, 0.12, 1)   -- 普通/离开 = 0.12
entry:SetFocusScale(0.15, 0.15, 1)    -- 悬停 = 0.15 (微放大，有交互反馈)

-- ⚠️ 不推荐: scale_on_focus = false
--    实测会导致高亮和点击反馈失效（ImageButton 的状态管理依赖 focus 缩放流程）
entry.scale_on_focus = false  -- 谨慎使用!
```
**注意:** 构造函数里的 `scale` 参数仍需传入（影响初始渲染），但真正的尺寸控制权在 `SetNormalScale`/`SetFocusScale`。

优势：
- 不需要手动 `Image:Hide()/Show()` 管理高亮
- ImageButton 原生支持 normal/focus/selected/down 多种状态
- `SetOnClick` 代替 `OnMouseButton` 原始回调
- 不需要先 `SelectEntry(1)` 自动选中第一条（用户点击才高亮）

## UI 缩放协调

DST 纹理 UV 比例不同导致尺寸失调。例如 slot 纹理 (0.899宽) 比 bg 纹理 (0.555宽) 宽很多：

| 元素 | UV宽度 | 缩放 | 有效宽 |
|------|--------|------|--------|
| bg 面板 | 0.555 | ×0.42 | 0.233 |
| slot 槽位 | 0.899 | ×0.32 | 0.288 |

规则：缩放面板 → 所有子元素坐标**等比缩放** (新值 = 旧值 × 新scale/旧scale)

```lua
-- bg 0.55→0.42 (×0.76), 全部坐标同步调整:
-- title:    110→84
-- close_btn: 225→171, 112→85
-- start_y:   45→34
-- spacing:   -38→-29
-- text_x:    -85→-65
-- star_x:    140→106
-- frame_sx:  0.42→0.32
```

## DST Action 系统: 物品消耗规则

### 基本: 返回值控制消耗

自定义 Action 的返回值决定物品是否消耗：

```lua
-- ❌ 总是返回 true → DST 无条件消耗物品!
AddAction("MY_ACTION", "使用", function(act)
    act.invobject.components.my_comp:UseItem(act.doer, act.target)
    return true  -- ← 不管用没用都消耗
end)

-- ✅ 根据实际使用结果决定
AddAction("MY_ACTION", "使用", function(act)
    if act.invobject and act.invobject.components.my_comp then
        return act.invobject.components.my_comp:UseItem(act.doer, act.target)
    end
    return false  -- 没组件 → 不消耗
end)
```

配套修改链路：
1. **Action**: `return UseItem(...)` 传递返回值
2. **Component.UseItem**: `return self.fn(self.inst, doer, target)` 传递返回值
3. **Prefab OnUse**: `return DoSomething(inst, doer)` 根据操作返回 true/false

### 🔥 核心矛盾: return true 自动消耗 vs return false 说"我做不到"

当打开 UI 界面（不需要消耗物品）时：

| 返回值 | DST 行为 | 问题 |
|--------|---------|------|
| `return true` | 动作成功 + **自动消耗物品** | 开界面就把物品吃了 |
| `return false` | 动作失败 + ThePlayer 说"**我做不到**" | 体验差 |

### 解决方案: `action.instant = true`

```lua
-- 1. 函数返回 true (避免"我做不到")
function TeleportToWaypoint(inst, doer)
    if #waypoints > 1 then
        TheFrontEnd:PushScreen(TeleportScreen(waypoints, doer))
        return true  -- ★ 返回 true, 不说"我做不到"
    end
    inst:Remove()
    return true
end

-- 2. Action 设 instant = true (阻止 DST 自动消耗)
AddAction("MINGSHENG_USEITEM", "...", function(act)
    if act.invobject and act.invobject.components.mingsheng_useitem then
        return act.invobject.components.mingsheng_useitem:UseItem(act.doer, act.target)
    end
    return false
end)
ACTIONS.MINGSHENG_USEITEM.instant = true  -- ★ 阻止 DST 自动消耗!
```

**效果:**
- 记录传送点: 函数内手动消耗 → return true → instant 阻止二次消耗 ✓
- 单传送点: 函数内手动消耗 → return true ✓
- 多传送点: 开界面(不消耗) → return true → instant 阻止消耗 ✓
- 关闭界面: 物品还在 ✓
- 确认传送: RPC 手动消耗 → 传送 ✓

**核心规则: `instant = true` + 所有消耗手动管理（函数内或 RPC 内）**
