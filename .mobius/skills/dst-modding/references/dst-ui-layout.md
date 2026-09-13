# DST 自定义 UI 面板布局（2026-09-01 Musha 职业面板实测）

## DST UI 坐标规则（简版）

- Widget 坐标是**逻辑像素/局部坐标**，不是严格 1080p 像素；受屏幕分辨率、HUD 缩放、全屏/窗口影响，但 Widget 按父级空间 + 锚点走。
- `SetSize(w, h)`：给 Image/按钮/区域定"占用/贴图表现尺寸"。Image 会拉伸贴图，保持比例需宽高按原图比。
- `SetScale(sx, sy, sz)`：缩放整个 widget 及**所有子节点**（继承）。
- `SetPosition(x, y, z)`：相对父节点的局部位置，不是屏幕绝对像素（除非父是屏幕/root 且锚点合适）。
- 锚点：`SetHAnchor` / `SetVAnchor`（LEFT/CENTER/RIGHT、TOP/MIDDLE/BOTTOM），`SetHRegPoint`/`SetVRegPoint`、`SetScaleMode`。要做"靠右下/不随屏幕乱跑"用锚点；面板类**不建议 SCALEMODE_FILLSCREEN 全屏铺**。
- 常用可参考：`scripts/widgets/widget.lua`、`image.lua`、`text.lua`、`imagebutton.lua`、`screens/playerhud.lua`、`widgets/redux/templates.lua`（RectangleWindow/StandardButton/ScrollingGrid）。

## 核心原则（元宝方案 C，落地验证可行）

**把"内容设计坐标"和"背景图坐标/屏幕坐标"解耦，用根容器统一缩放；背景只是装饰层，内容层按自己的锚点排。不要让头部/经验条直接按背景图尺寸去算绝对坐标。**

```lua
-- 根容器：统一缩放 + 锚点定位
self:SetScaleMode(SCALEMODE_FILLSCREEN)
self:SetHAnchor(0) / self:SetVAnchor(0)
self:SetPosition(330, -90, 0)  -- 屏幕右下区
self:SetScale(0.62)            -- 整体大小由这一个数控制

-- 背景装饰层（先 AddChild，绘制在底层；不参与内容坐标计算）
self.bg = self:AddChild(Image("images/bookpage_bg.xml", "bookpage_bg.tex"))
self.bg:SetSize(1000, 1467)
self.bg:SetScale(0.36)
self.bg:SetPosition(70, 0)
self.bg:SetTint(1, 1, 1, 0.5)  -- 半透明垫底

-- 内容层（全部挂 root，围绕 (0,0) 按逻辑区排，比如 860x490）
self.job_text = self:AddChild(Text(UIFONT, 54))  -- 注意是 self 不是 bg
self.job_text:SetPosition(-20, 205)
-- ...头像/等级/经验条/任务槽同理
```

- 先 AddChild 背景 → 后 AddChild 内容 = 内容浮在背景上（绘制顺序按添加顺序）。
- 内容元素全部挂 root（不是挂 bg），坐标围绕内容逻辑区中心 (0,0)，与背景尺寸无关。
- 经验条/进度条填充用 `SetSize(400 * pct, h)` 动态改宽度即可，别改父级 scale。

## 常见坑

1. **元素按"假想大纸"坐标排，实际渲染尺寸小 → 全部溢出**：症状=面板头部（职业名/等级/经验条）飘在纸页外面，只有下半截正常。根因=元素 SetPosition 是按更大背景尺寸算的，而背景实际渲染 = SetSize × SetScale（如 1000×1467 × 0.54 = 540×792），元素 y=530 超出上边界 396、x=300 超出右边界 270。
2. **竖版背景图装不下横版内容**：内容包围盒 860 宽 × 490 高，背景书页比例 0.68 竖版。硬拉 SetSize 成横版会严重变形。三选一：A 换横版/方背景或右侧独立内容区；B 重新设计成竖排、内容宽限制在书页内（480~520）；C 书页仅装饰背板、内容浮前面、根容器缩放（无需新美术，改动最小，推荐）。
3. **背景一套 scale、文字一套 scale、条一套 scale → 对齐飘**：统一在根容器做一次 SetScale，子元素只设逻辑坐标。
4. **文字不糊**：Text 用游戏字体（UIFONT/NEWFONT/TALKINGFONT），字号按逻辑像素，父级 scale 会一起缩。
5. **任务槽/动态数据**：在槽位 text:SetString() / bg:SetTint() 里更新，数据从组件/network 变量读，别只存客户端。

## 案例：Musha 职业面板落地坐标（内容逻辑区 860x490，root scale 0.62）

| 元素 | 坐标 | 说明 |
|---|---|---|
| 头像 | (-330, 130) 140x140 | 左上 |
| 职业名 | (-20, 205) UIFONT 54 | 顶中 |
| 等级 | (300, 205) UIFONT 42 | 右上 |
| 经验条 | (-20, 130) 400x16 | 职业名下方 |
| 经验数值 | (400, 130) UIFONT 28 | 条右侧 |
| 分隔线 | (-60, -15) | 中部 |
| 任务标题 | (-60, -55) UIFONT 36 | |
| 任务槽 1-3 | name (-240, -115/-170/-225)，status (100, 同y) | 竖排 |
