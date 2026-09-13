# DST UI 坑：ImageButton / Screen / 纯 square.tex 手搓描边框

面向"用内置 square.tex 手搓面板 UI"的场景（Musha 职业面板就是这套）。

---

## 1. ImageButton 默认 hover 放大 1.2 倍 → 底色"爆出来"

`widgets/imagebutton.lua` 构造函数里默认：

```lua
self.scale_on_focus = true
self.focus_scale   = {1.2, 1.2, 1.2}
self.normal_scale  = {1, 1, 1}
```

`OnGainFocus` 里的触发条件：

```lua
if not self.ignore_standard_scaling and self.image_focus == self.image_normal
   and self.scale_on_focus and self.focus_scale then
    self.image:SetScale(self.focus_scale[1], self.focus_scale[2], self.focus_scale[3])
end
```

**关键陷阱**：只传一个贴图的按钮

```lua
local b = parent:AddChild(ImageButton("images/global.xml", "square.tex"))
```

`SetTextures` 里 `self.image_focus = focus or normal` → **image_focus 等于 image_normal** →
上面那个判定 **必然成立** → 鼠标一移上去底图被放大到 1.2 倍。

而如果用 `AddChild` 在按钮上叠了白色描边线（常见手搓法），那些线是**子控件、不跟着缩放**，
于是底色块涨出描边一圈 —— 用户原话就是"底色会爆出来、外框看起来很大/对不上"。

**修法**：

```lua
b.scale_on_focus = false
```

Klei 自己在源码那一行上方写着：
`-- Common bug: you probably want scale_on_focus = false or customize scaling.`

**附带**：`SetImageFocusColour()` 会让 hover 整块变色，别设得跟 normal 差太远，
否则一样是"爆"的感觉（例：normal (0.70,0.62,0.42) → focus 只给 (0.78,0.70,0.48)）。

---

## 2. Screen 类没有 `name` 字段 → 屏幕栈里认不出自己的屏幕

想在 `TheFrontEnd.screenstack` 里判断"我的面板在不在栈顶"时：

```lua
-- ❌ 恒为 false：widgets/screen.lua 根本没有 self.name
local top = TheFrontEnd.screenstack[#TheFrontEnd.screenstack]
if top.name == "MushaPanelScreen" then ... end
```

`widgets/screen.lua` 里 grep 不到 `self.name`（`Screen._ctor(self, "XXX")` 那个参数并不存成字段）。

**正确做法**：进构造函数时自己打标记。

```lua
-- Screen 构造函数里
self.musha_panel = true

-- 判断处
local function PanelIsOnTop()
    local fe = TheFrontEnd
    local stack = fe and fe.screenstack
    if not stack then return false end
    local top = stack[#stack]
    return top ~= nil and top.musha_panel == true
end
```

---

## 3. "面板按了没反应"的排查法

症状：按快捷键 / 右键道具毫无反应，**连报错弹窗都没有**。
原因：打开函数里那些"提前 return"都是静默的，不打日志。

**日志位置**：`D:\Backup\Documents\Klei\DoNotStarveTogether\client_log.txt`
（这台机器 Documents 被重定向到 `D:\Backup\Documents`；`C:\Users\<user>\Documents\Klei` 不存在）

**判据**：在面板模块**模块顶层**放一条 print，例如

```lua
print("[Musha Panel] 文件开始加载 (Screen 版)")   -- 模块第 8 行，require 成功就会打
```

- 日志里有它 → 模块被 require 了，问题在构造 / 显示
- 日志里没有 → **打开函数在 require 之前就 return 了**

**最常见的静默死锁**：用 owner 上的布尔标志防重复打开（`owner._xxx_open`），
而这个标志是**在 Screen 构造函数里设 true** 的 → 只要构造中途报错一次，
标志就永久残留 true，之后每次打开都在第一行静默 return，
快捷键分支还会反过来去 `TheFrontEnd:PopScreen()` 关掉别人。

**修法（三件一起做）**：

1. 检查标志时，先确认屏幕**真的**在栈里；不在就清掉标志继续开
2. `screen(owner)` 构造也用 `pcall` 包住，失败时清标志 + print 错误
3. 每一步都 print（owner 无效 / TheFrontEnd 不存在 / 已在栈顶 / require 失败 / 构造失败），
   一次就能定位卡在哪

### 3.1 读 client_log.txt 的三个坑（实测踩过）

**① 文件在游戏运行期间实时增长 —— tail 一次就下结论必错。**
同一个文件隔几分钟两次 `wc -l` 行数不同（实测 11365 → 11802）。
我第一次读到"日志停在 07:40"其实是读到了**旧尾部**，据此差点判错方向。
规矩：**用户每做一次操作就重新读一次**，先 `wc -l` 确认又长了多少，再看新增段。

**② 日志时间戳 ≠ 系统时间。**
实测系统 10:13 时日志写的是 `[08:01]`（差约 2 小时）。
不要用时间戳判断"这是不是刚才那一局"。改用**内容分段**：
往回找到 `[Musha TRACE] 1 - modmain 开始`（或等价的启动标记），
从那里到文件末尾就是最新一局。

**③ 定位"某局突然不能用了"，最快的办法是逐条对比新旧两局。**
把**一个能用的旧局**和**一个不能用的新局**各自 grep 同一组标记 print，
列出两组、看缺了哪一条 —— 一步就能把范围缩到一个函数里
（实测这样直接锁定"打开函数没走到 `require`"）。

**代码生效**：最稳是彻底退出客户端重开。回主菜单重进也会 unload/reload mod
（日志里能看到 `unloading prefabs for mod musha`），但排查阶段别赌这一点。

---

## 4. 纯 square.tex 做"金属条 / 魔兽 UI 质感"

mod 里能用的贴图基本只有 `images/global.xml` 的 `square.tex`
（一张纯色方块，可 tint / alpha），**做不了圆角、渐变、纹理**。

### 4.1 画框：4 条边

```lua
-- inset = 往里缩多少才开始画，thick = 线粗
local function FrameLines(parent, w, h, inset, thick, r, g, b, a)
    local bw, bh = w - inset * 2, h - inset * 2
    for _, ln in ipairs({
        { 0, bh / 2 - thick / 2, bw, thick },
        { 0, -(bh / 2 - thick / 2), bw, thick },
        { -(bw / 2 - thick / 2), 0, thick, bh },
        { bw / 2 - thick / 2, 0, thick, bh },
    }) do
        local line = parent:AddChild(Image("images/global.xml", "square.tex"))
        line:SetSize(ln[3], ln[4])
        line:SetPosition(ln[1], ln[2])
        line:SetTint(r, g, b, a)
    end
end
```

### 4.2 金属条：把一根粗条拆成 N 根细条做伪渐变

一根纯色线太平；把同一段 inset 区间拆成 `steps` 根细条、亮度从外到内递减，
就能骗出"斜面 + 受光"的厚度感 —— 这是 square.tex 的能力上限。

```lua
local function MetalBand(parent, w, h, inset, thick, cr, cg, cb, steps, a)
    steps = math.max(1, steps or 3)
    local seg = thick / steps
    for i = 1, steps do
        local k = 1 - (i - 1) / steps * 0.55          -- 亮度系数 1.00 → 0.45
        FrameLines(parent, w, h, inset + (i - 1) * seg, seg, cr * k, cg * k, cb * k, a or 1)
    end
end
```

用法（Musha 信箱外框实际参数）：

```lua
FrameLines(root, W, H, 0,  5,  0.15, 0.10, 0.06, 1)    -- 最外深棕黑压边
MetalBand(root, W, H, 5,  16, 0.99, 0.63, 0.28, 4, 1)  -- 橙色主条，4 档渐变
MetalBand(root, W, H, 21, 3,  1.00, 0.88, 0.50, 2, 1)  -- 金色高光细条
```

### 4.3 铆钉

暗色方块 + 顶部一条 3px 高光条 = 像被光照到的金属钉。

### 4.4 上限

真"魔兽 UI"是**手绘 9-slice 贴图**（金属拉丝纹理 / 双层描边 / 宝石镶嵌），
square.tex 做不出来。要再上一档的路子：
程序生成 PNG 边框 → 用 **DST Mod Tools 的 autocompiler** 编成 `.tex` + `.xml` 塞进 mod。

**★ 用户问「可以做成那样吗？还是要我去找[素材]？」时的答法**（实测有效）：
不要让他去找素材。先答**「不用找，现有贴图能做什么」并直接做出来**，
再把能力上限一次讲清 + 给出唯一的升级路径（程序生成 PNG → autocompiler 编 .tex）。
这一次用户问的时候，回「不用你去找，能做」+ 当场叠出条状金属，用户直接接受了；
反过来若先回"那得找素材"，等于把一个免费能做的活推回给用户。
**风格铺开范围要主动给二选一**（实测用户选"只做被点名的那块"）：A 只做这一处 / B 全面板统一套。

---

## 5. 布局约束（信箱页踩过的）

- 内层底色块缩进后（`PAGE_W - 50`），**任何落在这页里的控件纵向都不能超出内层底色范围**
  （Musha 信箱：`±275`），否则会压到外框描边上，颜色发脏、像"露出外框底色"
- 底部按钮排（翻页 / 页码）的 y 要按 `-PAGE_H/2 + 距底像素` 算完再确认 `y - h/2 > -275`
