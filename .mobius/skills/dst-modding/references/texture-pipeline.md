# DST 贴图管线 & 共用背景图横版化（2026-09 bookpage_bg 实测）

## png → tex/xml 机制（换图不生效的根因）
- DST 游戏加载的是 `images/` 下编译产物 `.tex` + atlas `.xml`（modmain Assets 引 xml+tex），**不是 png**。
- png 比 tex 新 → 游戏**不会**自动重编。用户"换了封面但游戏里没变"= tex 还是旧编译。
- 强制重建流程：
  1. 把旧 `.tex` + `.xml` 一起移走（mv 到 `_bak/`，保留回滚；旧 png 备份也可留在 _bak）
  2. 重启游戏加载 mod → 引擎缺 tex 时从同名 png 自动编译生成新 tex+xml
  3. 启动后验证 tex 时间戳/尺寸匹配新 png
- 只删 tex 留 xml 不行：xml 的 uv 是旧图在 atlas 里的坐标，新图尺寸变了会裁错区域，必须 tex+xml 一起重建。
- 备用手动编译：Steam 工具 Don't Starve Mod Tools 的 autocompiler（用户已装在 C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Mod Tools）。

## 共用背景图的影响
- 例：bookpage_bg 被 `musha_skillui.lua`（技能书）与 `musha_panel_screen.lua`（职业面板）共同引用 → 换 png = 两个界面一起变。
- 竖版图（1000×1467, 0.68:1）→ 横版图（1232×832, 1.48:1）：Image 尺寸常量 + 全部布局重排。
- `Image:SetScale(a,b)` 强拉到指定逻辑尺寸（比例不匹配 = 变形）；`SetScale(s)` 等比缩放。图上自带厚边框/角花时，删掉代码叠的 border/角星/文字✕ 防双边框。
- 本次落地参考：skillui 卡 592×400（页1 行距47/其他页60）、panel 卡 503×340（PANEL_H=340 → BG_SCALE=340/832）；假头像灰块/表演 MP 条一并删。
- 图上元素坐标换算（透明点击区盖图上按钮/红叉）：逻辑 = (px - 图中心px) × (渲染宽/原图宽)。
  - panel 右上红叉 ≈ px(1140,90) → (214,133)；skillui → (250,158)。坐标是估算，最终要进游戏截图微调（AI 无视觉时尤其如此）。
- 内容安全区估算：右侧装饰/水印列从图宽 ~85% 起 → 内容别超 0.8W；右上叉区 x>0.87W && y>0.34H 避让。
- panel 有 OnGameDataChanged 与 self:Refresh 两份重复刷新逻辑，改坐标/尺寸要两处同步。

## 多 patch 并行坑（2026-09 实测，重要）
- 对同一 .lua 一次发多个 patch/replace_all 调用会**并行执行**，fuzzy 匹配互相串改把文件改乱（症状：行被插到错误位置、if/else 结构碎掉、出现 `).4)` 之类残片）。
- 规则：同一文件的多处修改**必须串行**（一次一个 patch），或直接 read_file 拿全量原文后整文件 write_file 重写。
- 文件乱了之后：不要再在上面小修（错误会叠加），先 read_file 全文核对损坏范围，再整体重写为正确版本。
- 无 luajit/lua 时结构校验：Python 剥掉注释/字符串后数 if/function/for/while vs end 配平（if+function+for+while 数量必须等于 end 数量）。
