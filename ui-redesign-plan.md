# Musha UI 版面统一改造规划（2026-09-04）

目标：把 Musha 全部游戏内界面统一成新横版暖黄书页风格（bookpage_bg.png 1232x832：
暖黄奶油纸 + 金橙木框 + 星星花瓣角花）。

## 当前状态盘点

| 界面 | 文件 | 触发 | 背景 | 状态 |
|---|---|---|---|---|
| 技能书弹窗 | components/musha_skillui.lua | skillbook 物品 | bookpage_bg | ✅ 已横版化（卡 592x400） |
| 职业面板 | widgets/musha_panel_screen.lua | B 键 / musha 角色 | bookpage_bg | ✅ 已横版化（卡 503x340） |
| 笔记剧情页 | widgets/musha_note_screen.lua | note 物品 | musha_note_bg(1800x1011, 5月旧图) | ⏳ 独立旧风格，未统一 |
| HUD 注册 | widgets/musha_panel_registered.lua | controls 后置 | — | 只是挂载，无视觉 |
| note 注册 | widgets/musha_note_registered.lua | controls 后置 | — | 只是挂载，无视觉 |
| 杂项素材 | images/bar.png、names_musha.tex | 经验条/名称 | — | 未审 |

## 验证进度
- [x] bookpage_bg 新 png 已就位（9-3 09:19，1232x832）
- [x] DST 自动编译成功：bookpage_bg.tex/xml 已生成（9-4 04:28），新封面游戏内生效
- [x] 代码横版适配两处（skillui / panel_screen）
- [x] 2026-09-04 用户反馈卡片太小 → 整卡放大：skillui PANEL_ZOOM=1.4（渲染约 829x560）、panel_screen PANEL_ZOOM=1.25 + 内容容器缩放 + 卡中心 -340→-380（渲染约 629x425）。结构校验通过，待用户游戏内看效果
- [x] 2026-09-08 用户要求 UI 居中 → 两处根坐标改 (0,0)：panel_screen SetPosition(-380,36)→(0,0)，skillui root SetPosition(0,50)→(0,0)
- [x] 2026-09-08 用户反馈变形 → 根因：原图 1232x832 被代码硬压成 503x340/592x400 小卡（SetScale 误用）导致比例变形。已改：两处背景图 SetSize(1232,832) 原图 1:1 全尺寸，PANEL_ZOOM 归一，内容坐标/字号按全尺寸重排（skillui ×2.08，panel 标题64/经验700宽/任务行距115），红叉点击区移到图上真实位置 (524,326)。语法检查通过，待进游戏看效果
- [ ] 截图给元宝排版（图上装饰：右上红叉/右侧按钮列/角花需与文字避让）→ 等用户带排版意见回来改坐标
- [ ] 放大效果确认 → 不够大/太大改 PANEL_ZOOM 常量（skillui.lua / panel_screen.lua 顶部各一个）
- [ ] 文字随 scale 放大若发糊 → 改回坐标逐项放大+大字号渲染方案
- [ ] 图上"豆包AI"水印 + 右侧按钮列素材清理（用户出图侧处理）
- [ ] 用户游戏内截图微调坐标（我视觉通道不可用，需用户文字/截图反馈）

## 待用户确认（回来从这里继续）
1. [已答 B：卡片放大 → 已执行 PANEL_ZOOM] 放大后的观感：A) 再大点/小点（改 PANEL_ZOOM）B) 文字发糊 C) 位置挡画面（改 panel SetPosition）
2. 技能书/职业面板横版运行效果：哪叠了/哪出界/哪压装饰 → 一句话描述或关键坐标
3. 笔记页 note_screen 是否也要换暖黄书页风（需要新背景图素材，代码适配另算）
4. 杂项 bar.png / names_musha 是否一并统一

## 已知风险
- 图中右侧按钮列（家/眼睛/铃/齿轮）与右下水印在成品素材清理前会露出
- 图上红叉位置 = 估算（px1140,90），若实际偏差，close 点击区需微调（skillui CLOSE_X/Y、panel 214,133）
- C 盘空间不足会阻断 DST/Steam 更新（当前 488M，建议搬 StarSavior 18G 去 D）
