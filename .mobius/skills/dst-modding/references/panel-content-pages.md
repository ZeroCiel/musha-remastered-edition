# 面板内容页：多页外壳 / 信箱翻页页 / 图鉴页 / 内容源放 scripts/

配套：
- 导航（三角+抽屉）与图标按钮本体、UI 微调工作流 → `references/panel-nav-and-icon-buttons.md`
- 列表/滚动 → `references/screen-scrolling-grid.md`；设置页 → `references/in-game-settings-component.md`

（musha 0.7.6，2026-09-10 P1/P2 实测）

## 1. 多页外壳（主页/技能/信箱/设置/图鉴）
- `self.pages = { home=…, skill=…, mail=…, set=…, dex=… }`
- ★ **主页不要搬容器**：把现有那堆 widget（标题/等级/经验条/任务列表/空状态文字）直接收进一个
  数组当 `pages.home`，`SetActivePage` 统一 Show/Hide。改动最小，不用 re-parent、不会漏改坐标。
- 其它页各 `content:AddChild(Widget("musha_page"))` 建容器，建完立刻 `Hide()`。
- `SetActivePage(name)`：只 Show/Hide + 换导航高亮 + 更新 `default_focus`，**不重建 Screen**。
- ★ **空状态可见性坑**：有些 widget 的显隐归 `Refresh()` 管（"暂无任务 / 暂无职业"这类），
  切页时 `Show()` 会把它们翻出来 → **切回 home 要补一次 `self:Refresh()`**。
- 某页内容要现算（如信箱重绘）时，在 `SetActivePage` 里顺手调那一页的 Refresh 函数。

## 2. 信箱页（更新日志）：橙框条 + 橙灰底 + 底部翻页
用户口述"背景橙灰色、要有个框、底部可翻页、框外有橙色框条主体"的落地（全用 `square.tex`）：
- ① **外圈橙色框条** = 4 条边（上下 `760x6`、左右 `6x456`），色 `(0.88,0.52,0.18)`
- ② **内层橙灰底** = 一块比外框内缩一个边框宽度的实心块 `(0.78,0.68,0.56,0.94)`
- ③ **内容容器** `Widget`；翻页时 `KillAllChildren()` 清空重填（`Widget:KillAllChildren()` 确实存在）
- ④ **底部翻页** = `<` + 页码 + `>`：
  ```lua
  self.mail_page = math.max(1, math.min(maxpage, (self.mail_page or 1) + dir))
  ```
  到头/到尾钳住不越界，所以"只有 1 条时页码 1/1、点按钮不动也不报错"是**预期**，不用当 bug 修。
- 每条 = 版本头（橙色 `(0.82,0.42,0.12)`，格式 `v0.7.6    2026-09-10`）+ 若干深色正文行（`· ` 开头）。
- 每页条数写成一个常量（`MAIL_PER_PAGE = 3`）。用户说"**长度限制由你决定**"= 这个数就是你的决定权，
  声明出来让他一个数就能改。

## 3. 内容源放 `scripts/` 下：require 的坑与兜底
- 静态数据表放 `<mod>/scripts/xxx.lua`，**末尾必须 `return {…}`**。
- ★★★ **构造函数里跑的任何辅助子系统（编辑模式/日志/持久化）必须整体 pcall。**
  2026-09-24 真实事故：`io.open` 路径非法抛 `invalid filepath` → 没包 pcall → 炸掉**整个面板构造**
  → `OpenMushaPanel` 的 pcall 兜住后直接 return，**面板永远打不开**（连查两三天）。
  详见 `references/panel-open-failure-io-open-invalid-filepath.md`。
- ★ 面板是 `pcall(require, "screens/xxx")` 进来的 → mod 的 `scripts/` 就是 require 根，
  所以 `require("musha_changelog")` 命中 `scripts/musha_changelog.lua`（不用写 `scripts/` 前缀）。
- ★★ **必须 pcall + 内联兜底**。否则日志文件里一个语法错就会让**整个面板打不开**：
  ```lua
  local DATA
  do
      local ok, d = pcall(require, "musha_changelog")
      if ok and type(d) == "table" then DATA = d end
  end
  if type(DATA) ~= "table" then DATA = { …最小兜底（同一条）… } end
  ```
- 内容表格式：**倒序数组**（最新在最上面）`{ ver=, date=, lines={…} }`。
  用户会自己往这个文件里加条目，注释里把格式写清楚。

## 4. 图鉴页（装备规则总览）
- 结构直接复用任务列表同款 `TEMPLATES.ScrollingGrid`（滚动/裁剪/滚动条全白送），滚动条外观都不用再定制。
- 每行 = 装备图标（用装备自己的 `inv_image`）+ 名称 + 规则文字。
  用户明确**不做点击跳转** → 详情弹窗和交互事件全省。
- 数据源：先**手写一张表**最省事；"从 prefab/TUNING 自动抓属性"要逐个 prefab 适配，别一开始碰。
