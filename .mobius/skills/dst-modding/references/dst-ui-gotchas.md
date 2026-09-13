# DST UI 通用坑（对齐 / 缩放 / 多页 / 遍历）2026-09 实测

面板类改造踩过的坑，按"症状 → 根因 → 写法"记。都验证过。

---

## 1. Text 左对齐：光 `SetHAlign` 无效，必须配 `SetRegionSize`

**症状**：用户说"文字不要居中 / 参差 / 向左排列"，但你代码里明明写了 `SetHAlign(ANCHOR_LEFT)`。

```lua
-- ❌ 无效：每行绕自己的中心点摆 → 行越长起点越靠左，看着就是居中+参差
local t = Text(UIFONT, 24, "…")
t:SetHAlign(ANCHOR_LEFT)
t:SetPosition(-280, y)

-- ✅ 正确
local t = Text(UIFONT, 22)
t:SetString("· " .. line)
t:SetRegionSize(800, 28)          -- 先给"文字区域"
t:SetHAlign(ANCHOR_LEFT)
t:SetPosition(-2, y)              -- 左边缘 = x - regionW/2 = -402
```

- 原理：TextWidget 没设 region 时，region 就等于字符串本身宽度，HAlign 没有可对齐的空间。
- DST 官方代码**一律成对出现**：`screens/kitcoongamescreen.lua:77-80`、`screens/bugreportscreen.lua:43-45`。
  查证手法：`grep -rn "SetHAlign(ANCHOR_LEFT)" screens/ widgets/ | head` 然后看邻居有没有 `SetRegionSize`。
- 左边缘 = `x - regionW/2`。想要左边距 M、框内半宽 H：`regionW = 2*(H - M)`、`x = 0`。
- ⚠️ 设了 region 之后，**单行长度必须 ≤ regionW**，超了会被截/压。中文按 `1 字 ≈ 1 字号 px` 估。
  内容超宽时优先缩短文案，别硬拉 region 宽度（否则边距没了）。
- 相关 API 位置：`widgets/text.lua` — `SetHAlign`(→SetHAnchor) / `SetRegionSize` / `EnableWordWrap`。

---

## 2. ImageButton 上 `SetScale` 会被 hover 覆盖

ImageButton 聚焦时会 `SetScale(focus_scale)`。只调 `SetScale(0.7)`，鼠标一悬停就被拉回 1。

```lua
b:SetScale(s, s, s)
b.scale_on_focus = false
b.normal_scale = { s, s, s }
b.focus_scale  = { s, s, s }
```

- **`SetScale` 连子节点（文字）一起缩**。28pt 缩到 40% ≈ 11pt，中文会糊。
  要"只缩框不缩字"：改 `ForceImageSize(w, h)` + 单独设字号，别用 `SetScale`。
- 父容器 `SetScale` 是绕**父容器原点**缩的，子节点位置会一起缩。子节点相对父原点往下排时，
  缩完是"从原点往下压紧"，不是整体居中缩——布置坐标时按这个算。

---

## 3. 遍历"混合形态"的容器表 → 先判类型

多页面板很容易这么存：
```lua
self.pages = {}
self.pages.home = { self.list, self.title, ... }   -- 一组 widget 的数组表
self.pages.mail = SomeWidget("mail")               -- 单个容器 Widget
```

一律 `for _, w in ipairs(group) do` 时，对**单个 Widget** 而言 `w[1]` 是 nil →
**循环体一次都不执行** → 那一页永远保持 `Hide()` 状态。

**症状**：用户报"XX 页里面的内容不显示"，但框/背景在、控制台**零报错**。极难查。

```lua
-- ✅ 判据：Widget 通过 metatable 有 .Show；纯数组表没有
local is_array = (type(group) == "table" and group.Show == nil)
if is_array then
    for _, w in ipairs(group) do
        if w and w.Show and w.Hide then
            if show then w:Show() else w:Hide() end
        end
    end
elseif group and group.Show and group.Hide then
    if show then group:Show() else group:Hide() end
end
```

推广：**任何"可能是 widget 也可能是 widget 数组"的表，遍历前先判类型**。

---

## 4. 多页面板切页：只 Show/Hide，不重建 Screen

- `SetActivePage(name)`：遍历 pages 做 Show/Hide + 更新导航高亮 + 更新 `default_focus`。
- **切回"主页"要补调一次 `Refresh()`**：空状态字样（"暂无任务"）的可见性归 Refresh 管，
  否则会被 `Show()` 一起放出来。
- 页面内动态内容（列表 / 日志）在**切到该页时**再重建：`container:KillAllChildren()` 然后重新 `AddChild`。
  `KillAllChildren()` 在 `widgets/widget.lua:291`，存在。
- 导航做成"右上三角 + 点开展开列表"这种折叠菜单时，展开态放内容**上面**会挡内容，
  记得"选完自动收起 + 再点三角收起"。

---

## 5. 局内设置（改完立刻生效）的最小落地

详细设计见 `references/in-game-settings-component.md`；这里只记最省事、已验证的几招：

- **世界级组件挂 TheWorld**：`AddPrefabPostInit` 要把 `"world"` / `"forest"` / `"cave"` **三个都挂**。
  `prefabs/world.lua` 里虽然注册了名为 `"world"` 的 Prefab，但运行时世界实体是 `forest`/`cave`。
  挂世界 prefab 才能保证组件在**存档 Load 阶段就存在**，`OnSave/OnLoad` 才生效（惰性 AddComponent 会丢存档数据）。
- **同步别开新 netvar**：把设置快照塞进**已有同步通道的副本**——`userdata` 浅拷贝一份再加字段：
  ```lua
  local d = {}
  for k, v in pairs(self.userdata) do d[k] = v end
  d.settings = self:GetSettingsView()      -- 浅拷贝 → 存档里的 userdata 不脏
  pcall(function() self.inst.replica.X:DoUpdata(d) end)
  ```
  复用现成的 `replica:DoUpdata → net_string dirty → PushEvent` 链路，**零新增网络变量**。
- **权限**：服务端对指定玩家实体判定用 `player.Network:IsServerAdmin()`（客户端侧的 `TheNet:GetIsServerAdmin()` 只在"本机"有意义）。
  玩家级设置各改各的，不校验。
- **RPC 传参**：bool 统一传 1/0。**Lua 里 `0` 也是真值**，组件里判 `value = (value == true or value == 1)`，
  不要写 `value and true or false`。
- 客户端开面板时发一条 `*_request_*` RPC 拉一次最新值。

---

## 6. UI 微调类任务的交互偏好（用户明确纠正过）

- **只改用户点名的那个元素**。用户说"图标缩小到 40%"，不要顺手把旁边的列表一起缩——
  实测被纠正（"2 错了"）。改错了要立刻撤回并说明"上一版做成 X 是错的"。
- **方向/扩缩类词要说明按哪种理解算**："左右扩 20" = 每边各 20（总 +40）还是总共 +20？
  一句话把假设摊开（"我按每边各 20 算的，逐边累计"），用户才能一句话纠正。
- **累加式微调要留痕**：同一个值被反复挪（左移 8.7 → 右移 12 → 左移 3 …）时，
  在注释里写清"累计值"和"历史演变"，否则下一轮自己都算不清。
- 用户的输入会有同音/形近字（"文字底线" = "文字底色"）。读着别扭时**按最可能的意思做完 + 说明假设**，
  不要反问、不要卡住不动。
- 效果不确定的（字号会不会太小、浅底上淡色会不会糊）**做完主动提示风险 + 给替代方案**，别等用户自己发现。
- 用户说"试试 X"、"这样如何"= 让你先做出来看，不是让你先论证。
