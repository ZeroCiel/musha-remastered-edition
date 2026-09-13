# DST 面板迁移：HUD Widget → 真 Screen + TEMPLATES.ScrollingGrid

照搬明生神行传送界面的架构。**用户明确说过"照搬这个"——遇到可滚动面板/列表，先读
`mods/mingsheng/scripts/screens/mingsheng_teleportscreen.lua` 再动手，不要手搓固定行。**

## 何时用
- 面板要有滚动列表（任务多行、传送点、商店条目）
- HUD Widget 拿不到滚轮事件 / 滚轮误触发关闭面板
- 需要黑幕点关、ESC 关、右侧滚动条

## 滚动条默认常显（用户要求"不超过行数也显示"）
原生 TrueScrollList 在 `RefreshView` 里 `if self:CanScroll()` 为假就 `scroll_bar_container:Hide()`
（`CanScroll() == (end_pos > 1)`），即条目不满一屏时滚动条消失。
要强制常显，在创建 list 之后**覆写实例的 RefreshView**（注意 `GetPositionScale` 会 `/(end_pos-1)`，
`end_pos<=1` 时除零产生 nan 会让滑块飞出屏幕，必须自己兜底）：
```lua
local base_refresh = self.list.RefreshView
self.list.RefreshView = function(list, ...)
    base_refresh(list, ...)
    list.scroll_bar_container:Show()                 -- 强制常显
    if list.end_pos <= 1 then                        -- 不可滚动：滑块置顶，避免 nan
        list.position_marker:SetPosition(0, list:GetSlideStart())
    end
end
```
- 滚动条相关字段：`scroll_bar_container`（整条容器）、`position_marker`（滑块）、`scroll_bar`（点击热区）。
- 想挪滚动条：opts 里 `scrollbar_offset`（相对裁剪区右缘的像素偏移）。
- 只 `Show()` 不改 CanScroll，滚轮/方向键在不满屏时自然无效（`OnControl` 里 `Scroll` 无害），
  **不要**去把 `CanScroll` 改成恒 true，否则 `GetPositionScale` 的除零会传播到别处。

## 滚动条外观定制（取消三角 / 换轨道配色 / 换滑块）
原生滚动条 = 上下三角箭头 + 灰轨道 + 贴图滑块。要改成「蜡黄竖轨 + 黄色高条滑块、无箭头」，
在创建 list 之后对实例字段直接改造（`up_button`/`down_button`/`up_button_controllerhint`/
`down_button_controllerhint`/`scroll_bar_line`(轨道 Image)/`position_marker`(滑块 ImageButton)/
`scroll_bar`(透明点击热区)）：
```lua
local list = self.list
local MARK_W, MARK_H = 23, 36
-- 1) 取消三角
list.up_button:Hide(); list.down_button:Hide()
list.up_button_controllerhint:Hide(); list.down_button_controllerhint:Hide()
-- 2) 轨道：改成蜡黄深陷色竖条
list.scroll_bar_line:ScaleToSize(12, list.scrollbar_height)
list.scroll_bar_line:SetTint(0.62, 0.54, 0.33, 0.82)
-- 3) 滑块：换成纯色高条
list.position_marker:SetTextures("images/global.xml", "square.tex")
list.position_marker:ForceImageSize(MARK_W, MARK_H)
list.position_marker:SetScale(1, 1, 1)   -- ★必须：BuildScrollBar 原生给滑块设了 SetScale(0.3)
list.position_marker:SetImageNormalColour(0.95, 0.82, 0.35, 0.95)
list.position_marker:SetImageFocusColour(1, 0.9, 0.45, 1)
list.position_marker.scale_on_focus = false
list.position_marker.ignore_standard_scaling = true
list.position_marker.focus_scale = {1,1,1}
list.position_marker.normal_scale = {1,1,1}
list.position_marker.image:SetTint(0.95, 0.82, 0.35, 0.95)  -- 兜底：创建时可能不在 normal 态
-- 3b) 装饰：滑块上叠 3 道白杠当"握把纹"（子 Image，加完即随滑块移动）
for i = 1, 3 do
    local bar = list.position_marker:AddChild(Image("images/global.xml", "square.tex"))
    bar:SetSize(MARK_W - 12, 2.5)
    bar:SetPosition(0, (2 - i) * 7)   -- +7 / 0 / -7
    bar:SetTint(1, 1, 1, 0.9)
end
-- 4) 取消三角后必须重算滑块行程（否则到不了两端）
list.GetSlideStart = function(l) return l.scrollbar_height/2 - MARK_H/2 end
list.GetSlideRange = function(l) return math.max(1, l.scrollbar_height - MARK_H) end
-- 5) 点击热区宽度跟着滑块
list.scroll_bar.image:ScaleToSize(MARK_W, list.scrollbar_height)
-- 6) 整条滚动条平移：容器 x/y 都是局部坐标，用 GetPositionXYZ 取数（见坑）
local px, py, pz = list.scroll_bar_container:GetPositionXYZ()
list.scroll_bar_container:SetPosition(px + 12, py + 20, pz)
```
要点/坑：
- **`GetSlideStart` / `GetSlideRange` 必须覆写**：原生 `GetSlideStart = scrollbar_height/2 - arrow_button_size`、
  `GetSlideRange = scrollbar_height - 2*arrow_button_size`（`arrow_button_size=30` 是 truescrolllist 模块级 local）。
  隐藏箭头后不改，滑块会被那 30px 卡住、滑不到两端；`DoDragScroll`（拖拽映射）也调这两个函数，一起校正。
- `SetTextures(atlas, normal)` 只给 2 个参数时 focus/disabled/down 全回落 normal —— 正好全用同一张纯色图。
- 滑块尺寸用 `ImageButton:ForceImageSize(w,h)`（内部走 `image:ScaleToSize`）；配
  `ignore_standard_scaling=true` + `focus_scale/normal_scale={1,1,1}` 防止悬停/聚焦被放大。
- 纯色底（`square.tex`）上色首选 `SetImageNormalColour`/`SetImageFocusColour`：它们在按钮状态刷新
  （OnGainFocus/OnLoseFocus）时会重新应用。`image:SetTint` 只作**兜底**——创建瞬间按钮未必处于
  normal 态，`SetImageNormalColour` 可能不生效，补一句 `image:SetTint` 保证初始就是对的颜色。
- 移动整条滚动条：ScrollingGrid opts 的 `scrollbar_offset` 是**数字**，容器 x = `scissor_x + scissor_width + offset`。
- ★**`position_marker` 原生被 `SetScale(0.3, 0.3, 1)`**（BuildScrollBar 里设的）。改尺寸后必须
  `SetScale(1,1,1)`，否则 `ForceImageSize(36,23)` 实际渲染成 ~11x7，看着"没生效"。
- ★**`Widget:GetPosition()` 返回的是一个 Vector3 对象，不是数字**。`local px, py = w:GetPosition()`
  后做 `px + 12` 会崩：`vector3.lua:10: attempt to index local 'rhs' (a number value)`。
  要取分量用 **`GetPositionXYZ()`**（返回 x,y,z 三个数）→ `w:SetPosition(px+12, py+20, pz)`。
  同类：`GetWorldPosition()` 也是 Vector3。
- 给 ImageButton 加装饰子 Image（如握把纹）：直接 `AddChild`；子节点会随按钮一起被 `SetPosition`（滑块定位）移动。
- **`scrollbar_height_offset`（opts）= 把轨道加长到裁剪区之外**，容器锚点在中心 → 实际上下各伸出
  `offset/2`px。用户说「竖轨上下都突出一点点」时设 `scrollbar_height_offset = 2*N`（N = 单侧突出像素）。
  它同时放大 `list.scrollbar_height`，覆写的 `GetSlideStart/Range` 会自动跟着用满这条加长的轨。
  值别设太大，会让竖轨顶到面板贴图的装饰边框。
- **握把可以自由分层**：`position_marker` 只当底（`SetImageNormalColour` 上色），再往上面 `AddChild`
  叠「上下外框条 + N 道白杠」当握把纹。子 Image 随滑块移动，尺寸/间距/道数随便调。
  用户是逐轮微调风格的（"5 道杠挤在一起""上下淡黄外框"），改的时候一次把尺寸+间距+颜色给完。

## 用户口述的"竖栏 + 黄色高条" = 滚动条
用户若描述"右侧一根竖栏往下到底""一个黄色小高条/握把，用来拉动/拉伸列表"——那就是他在描述
**滚动条的轨道 + 滑块**。别当成装饰性 Image 去手搓（会跟原生滚动条打架），直接上 ScrollingGrid。

### 术语对照（用户用词很松，同一轮里会换词）
- **竖条 / 长条 / 竖栏 / 竖轨** = 轨道 `scroll_bar_line`（不动的细长条）
- **拉条 / 握把 / 拉动的显示条 / 滑块** = 可拖的 `position_marker`
- **"拉伸条" / "长条拉伸的"** = 歧义，轨道和滑块他都这么叫过。**别停下来问**——按上下文挑一个改，
  回话里写明"我改的是竖条(轨道)/握把"，补一句"要挪到另一条说一声"，用户一句话就能纠正。
- **N 道杠 / 上下两条框 / 外框** = 叠在 `position_marker` 上的装饰子 Image（握把纹），**默认属于滑块**，
  除非用户明说"轨道上的"。曾把这套装饰误加到 `scroll_bar_line` 上（技术上可行，Image 能 AddChild），
  被要求挪回滑块。

## 设计语言词典（用户口述外观时的黑话 —— 直接照这个取色）
- **"夹心巧克力"** = 三明治结构：上下两层外框条（等长）+ 中间夹心（白杠或填充色）。
- **"像人的脸色那样深陷"** = 发灰的黄（sallow）：比纯黄暗、比纯灰暖，读起来像凹陷进去的内面。
  ★**别用纯深灰当底** —— 用户会嫌"盖起来像沙僧"（一块平灰 = 秃头盖住了设计）。参考值 `(0.62,0.56,0.42)`。
- **"蜡黄感但不要太褪色"** = 要蜡一样的黄，别调成苍白/发白。低饱和会被判"褪色"。
  参考值 `(0.85,0.74,0.40)`（偏亮的蜡笔黄）。
- **"孩童色"** = 用户自造词，含义不稳定（≈偏亮的蜡笔色/糖果色？）。**按"偏亮、饱和度够的蜡黄"取值实现**，
  回话里给出 RGB + "要是你指别的，给个色号/发张参考图"。别猜死，也别为它发 clarify。
- **形容词类比 = 只当"取色/明暗"描述，别加几何或纹理**。"类似黄色星星那种像素感觉"这种不是在要像素方块贴图，
  只是在形容"亮、饱和的黄"。本次把它做成"像素星星亮黄"并在回话里主动提"要不要加方块纹理" → 被回
  「不是————类似于淡黄色就行，浅淡黄也行」。正解：改成柔和纯色（淡黄 `(0.98,0.91,0.64)`），回话里**只报色值**，
  不要主动推销额外的纹理/装饰。同理"夹心巧克力""像人的脸色"都只是颜色/层次比喻。
- **"淡黄 / 浅淡黄"** = 低饱和的柔和亮黄，参考 `(0.98,0.91,0.64)`。用户说"不要那么亮/不要那个感觉"就往这把值压。
- 数字反馈惯例：`右移22像素` / `左移8.7` / `左移3厘米`。**"厘米"基本是随口** —— 按 px 算，
  回话点一句"按 3px 算的，要 3 厘米(≈113px) 说一声"。

## 本类任务的正确回话格式（用户偏好）
改完一次性列清：**①哪个元素 ②具体数值/色值 ③一句"不对说一声/给个数我改"**。
不要把"我打算怎么改"先说出来问一遍 —— 直接改。这次因为先发了 clarify 被用户取消，
多花了一轮；直接实现反而更快。
- **回退请求同理**：用户会说「颜色错误，不如前面第三版」。他按「我改了几轮」计数 → 每轮改完在 backlog 记
  一行「第N版 = 元素 + 色值/尺寸」，他报版本号就照表还原（本次"第三版"= 握把本体透明那版）。
- **一行多子句要先拆元素归属**：像「上下淡黄外框，深灰内框，5 条杠挤在一起」这种，3 道杠可能归拉条、
  5 道杠可能归竖条。先判断每个子句属于哪个元素，回话里写明「X 加在 A 上、Y 加在 B 上」，他一句话就能纠正。

## 语法校验
每轮改完跑 `scripts/lua_syntax_check.py`。注意 luaparser 入口是 **`from luaparser import ast; ast.parse(src)`**，
**`luaparser.parse` 不存在**（会 `AttributeError: module 'luaparser' has no attribute 'parse'`）。

**找符号的姿势（路径带单引号，search_files 会假阴性）**：mod 根目录叫 `Don't Starve Together`，
`search_files(pattern=..., target="content", path=<该目录>)` 经常**直接返回 `total_count: 0`**，
看起来像"项目里没有这个符号"，其实有。别据此下结论 —— 改用
`terminal`：`cd "/d/SteamLibrary/steamapps/common/Don't Starve Together/mods/musha" && grep -rn "关键词" scripts/ modmain.lua`。
（`target="files"` 的按文件名查找在该路径下是正常的，只有内容搜索会中招。）

## 行内字段别用 `.name`
行 widget 内的字段别叫 `.name`（Widget 构造时 `self.name = name`，会被覆盖）——用 `.label` / `.stat`。

## 参考实现（可照搬）
- 界面：`mods/mingsheng/scripts/screens/mingsheng_teleportscreen.lua`（437 行）
- 打开：`mods/mingsheng/scripts/prefabs/mingsheng.lua` — net_bool dirty → `TheFrontEnd:PushScreen(screen(inst))`
- 引擎模板：`data/databundles/scripts/widgets/redux/templates.lua:1961 TEMPLATES.ScrollingGrid`
- 底层：`data/databundles/scripts/widgets/truescrolllist.lua`（TrueScrollList）

## 关键 API 事实
- ScrollingGrid opts：`context, widget_width, widget_height, num_visible_rows, num_columns,`
  `item_ctor_fn, apply_fn, scrollbar_offset, scrollbar_height_offset, peek_percent, allow_bottom_empty_row`
- **滚轮滚动 = `CONTROL_SCROLLBACK` / `CONTROL_SCROLLFWD`**，由 TrueScrollList:OnControl 处理，
  `TheInput` 把鼠标滚轮翻译成这两个 control。**滚轮不走 OnMouseButton。**
- 鼠标键常量（constants.lua:393-397）：`MOUSEBUTTON_LEFT=1000` / `RIGHT=1001` / `MIDDLE=1002` /
  `SCROLLUP=1003` / `SCROLLDOWN=1004`
- scissor 裁剪区：`scissor_width = widget_width*num_columns + scissor_pad`，
  `scissor_height = widget_height*num_visible_rows + peek_height`，`scissor_x=-w/2, scissor_y=-h/2`。
  **列表 widget 的位置就是裁剪区中心。**
- 关闭三件套：全屏黑幕 ImageButton（`SetScale(50,50)` + tint 透明 + SetOnClick PopScreen）
  + 关闭按钮 + `OnControl` 里 `CONTROL_CANCEL → TheFrontEnd:PopScreen()`
- 焦点：`self.default_focus = self.list`（键盘/手柄滚）
- 条目：`item_ctor_fn(context, index)` 建行；`apply_fn(context, widget, data, index)` 填数据，
  data 为 nil 时 `widget:Hide()`
- Screen 基类 `widgets/screen.lua`：`Class(Screen, function(self, owner) Screen._ctor(self, "Name") ... end)`；
  OnControl 里先 `MyScreen._base.OnControl(self, control, down)`
- 打开 `TheFrontEnd:PushScreen(require("screens/xxx")(owner))`；关闭 `TheFrontEnd:PopScreen()`
- ★**Screen 没有 `self.name` 字段**（`Screen._ctor(self, "XxxScreen")` 的字符串不会存进 `self.name`）→
  想在 `TheFrontEnd.screenstack` 里认出自己的屏幕，得在构造函数里自己打标记（如 `self.musha_panel = true`）。
- ★**打开入口千万别写成"标志为真就静默 return"**：`owner._xxx_open = true` 设在构造开头、只在 `OnDestroy` 清，
  只要构造中途报错一次就**永久锁死**（Screen 没入栈 → OnDestroy 不跑）——症状是"按了完全没反应、日志零报错"。
  完整剖析 + 可照抄的防死锁写法 → **`references/screen-open-debugging.md`**

## 位置换算（把旧固定行的坐标搬到 ScrollingGrid）
首行中心 y = list_y + (scissor_height/2 - widget_height/2)；末行中心 = 首行 - (VISIBLE_ROWS-1)*widget_height。
水平：行内容以 list_x 为中线。搬迁时先算出旧布局的首行/末行中心，反推 list 位置，一次到位。

## 挪「列表本体」vs 挪「列表里的子元素」
用户分轮次、分元素给位移（「任务框上移 6」「竖条右移 12」「任务整体右移 4」）。
关键事实：**滚动条整条 `scroll_bar_container` 是列表 widget 的子节点** ——
`self.list:SetPosition()` 一动，任务行和滚动条会一起走。
- 用户只说挪「任务 / 任务框」→ 他多半**不想**让刚调好的滚动条跟着动：
  挪完 list 后**在滚动条容器上补一个反向偏移**把滚动条按回原位，回话写明
  「竖条我抵消了 -N 保持不动，要一起动说一声」。
- 用户说「X 和 Y 同步」→ 两个元素给同一个位移量。
- 同一轮里 list 位移 + 滚动条补偿一次改完再回话，别拆两轮。
- 口述的元素名可能不在面板顶部：**「上面灰条 / 长条」= 头部那条灰色经验条（`exp_bg`+`exp_fill`）**，
  不是任务行里的东西。听到没见过的元素名，先按「面板上唯一符合该描述的元素」改，回话点明改的是哪个。

### 带填充的进度条：挪底条必须同步改「填充基准」
经验条 = 底条 `exp_bg`（构造时固定位置）+ 填充 `exp_fill`（宽度随进度）。
填充位置**是在 `Refresh()` 里按 `base + width*pct` 算出来的**，构造函数里那份只是初始值。
只挪底条不改 Refresh 的基准 → 底条移了、填充还锚在旧位置，肉眼立刻看出错位。
```lua
-- 构造函数（初始态）
self.exp_bg:SetPosition(-3, 150)          -- 原 -15
self.exp_fill:SetPosition(-468, 150)      -- 原 -480
-- Refresh()
self.exp_fill:SetPosition(-468 + 465*pct, 150)   -- ★基准必须同步改
```

### 进度条文字/填充的语义（exp vs exp_to_next）—— 别把「差额」当「总量」
面板"职业经验 x/y"曾显示成 **40/5**，被用户当场质疑"等级是不是计算有问题"。根因是**服务端字段语义 ≠ 面板假设**，
不是等级算法错。`musha_profession_component.lua` 里：
- `exp_table = {0, 5, 12, 20, 30, 45, 60, 80, ...}` 是**累计**阈值（`exp_table[level+1]` = 升到下一级所需的累计经验）
- `userdata.exp` = 累计经验；升级判定 `while exp >= exp_table[level+1] do level = level + 1 end`
- `userdata.exp_to_next = exp_table[level+1] - exp` = **还差多少升级（差额，不是本级总需求）**

所以面板不能拿 `exp_to_next` 当分母。正确写法：
```lua
local exp      = md.exp or 0
local exp_next = exp + (md.exp_to_next or 0)   -- 下一级阈值 = 累计 + 差额
self.exp_text:SetString("职业经验 " .. exp .. "/" .. exp_next)
local pct = exp_next > 0 and math.min(exp / exp_next, 1) or 0
```
服务端自己的调试串就是这个格式（`GetDebugString`/`ShowExperienceInfo` 里 `exp_to_next + exp`），面板对齐它即可。

排查"等级/经验对不上"的次序：
1. **先怀疑显示层**（差额当总量、分母取错）—— 本次的真凶就在这里。
2. 等级只在 `AddExperience` 里 `+1`，全库 `grep -n "userdata.level ="` 只有那一处，等级算法本身没问题。
3. `PenaltyExp` / `RemoveExp` 只减经验；它们的**调用点只在废弃文件** `musha_quest.lua.bak_0908`，现役 `musha_quest.lua` 不调用。
4. 若 `level` 高于 `exp_table` 反推出的等级（如 Lv.5 但 exp=40 < `exp_table[6]`=45）→ 旧存档用老 `exp_table` 留下的，
   或历史上扣过经验。**别擅自加"按经验重算等级"的校正**（会把旧档虚高的等级压回去）——把这个选项讲给用户，他要再加。

## 坑
- **Screen 文件必须放 `scripts/screens/`**，用 `require("screens/xxx")`。
  HUD 面板是另一套（`AddClassPostConstruct("widgets/controls")` + `self:AddChild(panel)`），**不可混用**。
- 行 widget 内的字段别叫 `.name`（会覆盖 Widget 内置 `self.name`）——用 `.label` / `.stat`。
- ScrollingGrid 会预建 `num_visible_rows + 2` 个行 widget 并复用，`apply_fn` 必须完整设置
  所有可变状态（底框色/描边色/文字/显隐），不能只改差异。
- 从 HUD Widget 迁移时，删掉旧的 `OnMouseButton` 关面板逻辑，改由 Screen 的 OnControl/黑幕处理。
- 迁移清单：①新建 `scripts/screens/<name>.lua` ②重写注册文件为"监听打开事件→PushScreen，
  键盘键→开/关切换" ③旧 widget 文件挪到 `_bak_<日期>/` ④核对 modmain 的 modimport 路径。

## "滚轮关面板" bug（迁移前的临时修法）
HUD 面板 `OnMouseButton(button, down, x, y)` 里 `if down then self:HidePanel() end`
会把滚轮(1003/1004)当鼠标键 → 一滚就关。
临时修：`if down and button == MOUSEBUTTON_LEFT then`（只左键关）。
正解：换成 Screen + ScrollingGrid，滚轮自然走 CONTROL_SCROLLBACK/FWD。

## 找参考色 / 参考图（用户会说「你去找找 X」）
本机常态：**没有代理在跑**（Clash Verge 未启动、WARP 不在代理模式），google / www.bing 直连拿不到；
**国内出口是通的**。可用通道（实测过的）：
- 图搜走 `https://cn.bing.com/images/search?q=<urlencoded>&form=HDRSC2`（不报反爬）。图片直链在返回的 HTML 里，
  正则 `murl&quot;:&quot;(.*?)&quot;`（退路 `"murl":"(.*?)"`），抓到后再下载。
- `image.baidu.com` 页面 200，但它的 `search/acjson` 接口返回 0 条，别投时间；花瓣直链常返回 567，跳过。
- **主色自己算，别让视觉模型看图**（贵、输出还啰嗦）：PIL 缩到 160px，按 `//24*24` 量化后 `Counter` 取前 6 色，
  印成 `#RRGGBB(占比%)`。十几行就够：
  ```python
  im = Image.open(p).convert("RGB"); im.thumbnail((160, 160))
  px = list(im.getdata()); tot = len(px)
  q = Counter((r // 24 * 24, g // 24 * 24, b // 24 * 24) for r, g, b in px)
  ```
- 关键词会被游戏宣传图污染（搜「彩虹糖果」能出一屏《永劫无间》）→ **先看图再下结论**；不对就直说没找到，
  给 2–3 个候选色号收尾（这是用户的硬要求，见 SKILL.md 工作流偏好④）。
- 用完删除临时脚本/下载目录（用户会清盘）。

## 面板多页化（一屏多页 + 导航抽象）

用户要把单页面板扩成多页。本例最终定 **5 页：主页 / 技能 / 信箱 / 设置 / 图鉴**，共用同一张 `bookpage_bg`（他说"这张图有三个用途"）。

- ★**不要为每页重建 Screen**。做法：`content` 下放 N 个 page 容器 Widget，切页只 `Show()/Hide()` + 换导航高亮 + 更新 `self.default_focus`。关闭三件套（黑幕 / 红叉 / ESC）不动。
- ★**导航一定要抽成 `BuildNav()` / `SetActivePage(name)` 两个函数**。本例用户的诉求变过：先说"一排 5 个图标放不下"，改成"右侧一个三角 ▶，点开竖向展开 5 项列表，现阶段纯文字"。抽成函数后，美术到位想换回一排 5 个（书页 1232 宽其实放得下：每个 90px 才 450px）只改这一处，页面逻辑零改动。
- **展开式导航的两个坑**：①列表会盖在内容上（尤其主页的任务列表）→ 必须做"点别处自动收起 / 选完自动收"；②三角按钮的点击热区要铺满一格，否则难点中。
- 新页先用**占位**（灰底 + "美术待定"），别等美术才开工。图鉴页这种"图标 + 文字说明 + 可滚动 + 不做点击跳转"的需求 = 直接复用 ScrollingGrid，工作量只在"数据从哪来"（先手写一张表 `modscripts` 侧 `MUSHA_DEX = {icon,name,text}`，别去自动抓 prefab 属性）。
- 若已经有现成的同类 UI（如技能书 `components/musha_skillui.lua`），**整页搬进新 page 容器**，不重画不重排——这是把"大而美"降级成"能做"的最省办法。
- ★★**切页遍历的坑（本次真凶，务必先看这条）**：`self.pages` 里混了**两种数据结构** ——
  `pages.home` 是「一组 widget 的数组表」，而 `pages.skill/.mail/.set/.dex` 是 `NewPage()` 返回的
  **单个容器 Widget**。若统写 `for _, w in ipairs(group) do w:Show()/Hide() end`，对 Widget 做 `ipairs` 时
  `w[1]` 是 nil → **循环体一次都不执行** → 这几页永远停在 `NewPage()` 里的 `Hide()`。
  症状 = 用户报"**框在、内容不在**"或整页空白，**日志零报错**（不是报错，是压根没执行）。
  ✅ 修法：先判形态，分两种走法
  ```lua
  if type(group) == "table" and group.Show == nil then   -- 数组表（主页）
      for _, w in ipairs(group) do if show then w:Show() else w:Hide() end end
  elseif group and group.Show and group.Hide then        -- 单个容器 Widget（其它页）
      if show then group:Show() else group:Hide() end
  end
  ```
  排查口诀：**UI 整块不出现又没有报错 → 先怀疑"Show 根本没被调用"，别去查内容和数据。**
- **切回主页要补一次 `Refresh()`**：空状态字样（"暂无任务"）的可见性由 `Refresh()` 管，
  切页只做 `Show()` 会把它们一律放出来 → 回到 home 时重跑一次 Refresh 覆盖掉。
- **导航按钮缩放的三件配套**（只 `SetScale` 不够，鼠标一悬停就被按钮自己的 focus 逻辑拉回 1）：
  ```lua
  b:SetScale(0.7, 0.7, 0.7)
  b.scale_on_focus = false
  b.normal_scale = {0.7, 0.7, 0.7}
  b.focus_scale  = {0.7, 0.7, 0.7}
  ```
  ★`SetScale` **连文字一起缩**（28pt × 0.4 ≈ 11pt，中文糊成一团）。用户要"框小、字不小"时**不能用 SetScale**，
  改成缩 `ForceImageSize(w,h)` + 行距、字号保持原值。
  本次过程：先说"图标缩小到 40%"（我整组缩了）→ 被纠正「三角放大到 70%」「里面展开的文字文本不会缩小」，
  最终把缩放**只留在三角**、列表整体不缩。→ 缩放/缩小的需求**只作用于他点名的那个元素**，别顺手整组缩。
- **列表项"白框" = 4 条 2px 边线子 Image**（和任务行描边同款）叠在 ImageButton 上；
  悬停反馈靠 `SetImageFocusColour` 把底色调亮（用户管这叫「物质的反馈」）。
- **信箱/日志页**（用户口述："橙灰底 + 要有个框 + 底部可翻页 + 框外部有个橙色框条主体"）：
  外圈橙框条（4 条边 Image）+ 内层橙灰底 Image + 内容容器 + 底部 `< n/N >` 翻页（首尾要钳住，别越界）。
  内容源独立成 `scripts/<name>_changelog.lua`（`return { {ver=,date=,lines={...}} }`，**倒序**数组），
  面板侧用 `pcall(require, "<name>_changelog")` 读（`require("screens/xxx")` 能跑就说明 mod 的 `scripts/` 在 require 根上），
  并准备**内联兜底表 + `print` 一句警告**：日志文件路径万一不对，面板照样能开，且日志里看得见。
  ★**把内容从内联表挪进独立文件时，用户会要求"过去的不用删除"** —— 保留历史条目，别只留最新那条。
  每页几条由面板常量（如 `MAIL_PER_PAGE`）决定；换页后内容容器 `KillAllChildren()` 重建最省事。
  - ★**多层外框页的坐标红线（本次实测的坑）**：外框是"往内叠"的（inset 0/6/22 三层 = 深棕黑 6px → 橙色主框 16px → 内金线 3px），
    内层底图必须同步内缩（本例 `SetSize(PAGE_W-50, PAGE_H-50)`）→ **内容可用区只剩 ±(PAGE_H/2-25) = ±275**。
    底部翻页原摆 `PY = -PAGE_H/2 + 32`（≈-268）配 26 高按钮 → 下缘到 **-281，溢出压在外框**上，
    用户报的「翻页会显示外框底色，颜色有问题」**不是配色问题，是位置溢出**；修法是整组上移到内缩后的边界里（`PY` 改 `+46`）。
    口诀：**加了厚外框之后，所有贴边控件的 Y 必须按"内层底图尺寸"重算，不能按整页尺寸算。**
  - 想用 `square.tex` 凑"魔兽UI 板甲质感"：只能做**层次**（三层描边 + 四角 14x14 铆钉，`FrameLines()` 通用函数），
    真板甲质感要美术九宫格贴图 —— **先跟用户讲明这一点**，别让他以为能拼出贴图效果。
- **"编号回话"约定**：用户会用**你上一条回话里的编号**来纠正（本次原话：「不透明 **2** 错了」= 第 2 点改反了）。
  → 每次回话用 `1. 2. 3.` 编号列清"改了哪个元素 / 什么值 / 一处提醒"，他一句话就能点名纠错，省一整轮。
  同理：多子句口述（"三角放大到 70% 没有底色 里面展开的文字不缩小"）要先判定**每个子句归属哪个元素**，
  回话里写明归属；本次我把"没有底色"安在三角上 → 被「不透明 **2** 错了」纠正（其实那句是说列表项）。
- ★**用户犹豫时替他拍板（别再抛选项）**：本次设计阶段他反复摇摆——「想做一个书页替代掉简单版本的第一页，又不确定对不对」
  「技能页大了是很好看 但很折腾」「大脑在疯狂的跟自己打架」。正确动作是：①给结论 + 理由；②把大活拆成"**先做能用的小版本**"
  （P1 骨架 → 后续分期 P2..P5）；③点破"你现在是拿想象比大而美，骨架先跑通、游戏里看得见摸得着，判断才有依据"；
  ④把这条写进设计稿并标 `🔒 已拍板·防反复`（他回头想反悔就翻这条）。他回一个字「开」直接开工。
  → **纠结 = 在要一个决定，不是在要更多方案。**
- **大活先写设计稿**：用户说"你先设计"时，把设计落成 mod 目录下的 md（本例 `musha-panel-tabs-and-settings-design.md`），
  并在 `musha-backlog.md` 加一行指针；设计稿末尾给**编号的"待确认"清单**，他会逐条回字母/短句（本次他一次回了 1/2/4/5/6 + 一条"没读懂"）。
  定稿后把已定项标 ✅ 就地存档，别重写整份。

## 局内可改设置的组件形态（服务端权威）

设计要点（背景见 `references/server-settings-and-tuning.md` §三）：

- 分**两个组件**：**world 级挂 TheWorld**（随世界存档 → 多存档天然隔离）、**player 级挂玩家**；各自实现 `OnSave()` / `OnLoad(data)`。
- 权限：**世界级只有房主 + 管理员能改**，非房主整行降透明度并禁点；玩家级各改各的。
- 链路照搬 profession 那套：服务端改值 → replica `DoUpdata(JSON)` → net_string dirty → `PushEvent("…_dirty")` → 面板刷新；客户端点控件 →
  `SendModRPCToServer(GetModRPC("musha","…"), …)` + 服务端 `AddModRPCHandler("musha","…",fn)`（**3 参**；**先验权限再改值**）。
- **设置页控件三件套**（开关 / `< 值 >` 档位 / `- 值 +` 数字）全用 `square.tex` 拼，行高与列表一致 → **直接复用 ScrollingGrid**，滚动条样式白送。
- 设置只负责"存值 + UI"；真正生效靠各自的"应用"函数（如改回血回蓝后调 `ApplyProfessionData()`），刷怪倍率则要自建刷怪器——别去改世界设置。
- ★**完整落地骨架（挂载时机 / 零新增网络变量的同步 / bool 走 RPC 要传 1/0 / 切页可见性坑 / 生效接线表 / 一期顺序）→ `references/in-game-settings-component.md`。**

## 相关参考
- `references/server-settings-and-tuning.md` —— 用户问过「游戏内是否允许更改所有服务器设置 / 能不能通过 TUNING 实现」：
  世界设置、`cluster.ini`、模组配置三类的入口与运行期限制，TUNING「读的时机」陷阱，推荐替代做法。
