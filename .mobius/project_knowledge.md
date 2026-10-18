# 项目宏观规划

> 由 Mobius 系统宏观规划模式维护，请勿手动删除结构标题

> ✅ **2026-10-04 刷新**（上一版横幅：09-13 生成、09-24 重跑仅改 1 行、冻结在 0.7.6 时代）：本次按代码/文档实测更新——版本 **0.7.13**、面板 **6 页**、**界面三语 zh/en/ja**、「当前阶段」「近期任务」改成**指向 SSOT 的指针**、「待决策」里已拍板的 3 条标为 ✅。**进度一律以根目录 `musha-current-state.md` 为准、索引看 `星图集成.md`**；「技术决策记录」一节核对仍有效；结构标题未删。

## 项目目标

- Musha：DST 角色 mod（作者 Ciel/雪儿），主打**多职业 RPG 成长**（职业 / 等级 / 任务 / 技能）。
- 当前版本 **0.7.13「职业系统重制版」**（`modinfo.lua:1` name 与 `modinfo.lua:6` version 已统一）；API 10，仅 DST（不兼容单机/巨人国/海难/哈姆雷特）。
- 交付渠道：Steam 创意工坊 + 手动安装。质量目标：职业→任务→技能→设置形成完整闭环，UI 统一"暖黄书页 + 孩童风"。
- backlog = `musha-backlog.md`（条目级进度），设计稿 = `musha-panel-tabs-and-settings-design.md` / `ui-redesign-plan.md`。

## 核心模块

- **角色与职业**：4 基础职业（战士/法师/游侠/刺客）+ 6 进阶（剑士/近卫/药剂师/元素法师/吟游诗人/月影猎手）；服务端 `musha_profession_component` + replica，等级/经验为累计制 `exp_table`。
- **任务系统**（`components/musha_quest.lua`）：每日任务（每日 N 个，可累积，上限 10）+ 转职任务（祭坛卷轴接取，一次 1 个，**3 轮**进阶；`ADVANCE_MIN_LEVEL = 5`）；8 类事件推进，discover 类跨天作废。
- **面板 UI**（`screens/musha_panel_screen.lua`）：真 Screen + `TEMPLATES.ScrollingGrid`，**6 页 = 主页/技能/信箱/设置/礼包/图鉴**（实测 `page_order` 见 `:1669`；`equip` 装备页已注释、未启用）；入口 = 技能书/职业书右键（`musha_open_skill_panel` 事件）+ 控制台命令；**B 键入口 2026-09-24 已按用户要求移除**（B 是原生键，抢它会跟原版打架），左竖排导航常驻（NAV_ALWAYS_SHOW，x=-500）。
- **局内设置系统**：`musha_world_settings`（刷怪开关/倍率、每日任务数、经验倍率）+ `musha_player_settings`（生命/精力恢复倍率、调试）；经 ModRPC 修改、随存档保存。
- **技能系统**：`scripts/skills/musha_skill_data.lua` + `components/_musha_skills.lua.bak`（未启用；启用后恢复 heal_skill 任务类）。
- **物品/prefab**：职业书、便签（note）、技能书、剑/矛、tome；**界面三语 zh / en / ja**（`scripts/languages/{chinese,english,japanese}.lua`，2026-10-02 加日语，其余语种一律英文回退）+ **台词五份** `speech_musha_{zh,en,ko,ru,jp}`。

## 当前阶段

> **2026-10-04 改为指针**：本节原写 v0.7.6 时代的阶段（P1/P2 待验证），已全部过时。**阶段与进度一律看 `musha-current-state.md`（尾部 ㉘ 起 = 09-29 → 10-04 四批）**；本文件只放**宏观规划与技术决策**，不放进度（防第三本账）。

- 现版本 **0.7.13**；面板架构改造 A（HUD Widget → 真 Screen + ScrollingGrid）已完成，六页框架已过多轮进游戏验收。
- 历史验证点（**未复核**，只作记录）：`player.Network:IsServerAdmin()` 服务端可用性；`AddPrefabPostInit("world"/"forest"/"cave")` 触发；设置页行数布局。
- 发布前确认 `musha_quest.lua` 的 `TEST_DAILY_COUNT` 已回 nil（**未复核**）。

## 近期任务

> **2026-10-04 复核**：下表是 09-13 时代的任务单，已按现状标注（✅=实测已落地 / ⏳=仍开放 / ❓=未复核）。**任务与进度以 `musha-current-state.md` + `musha-backlog.md` 为准。**

- ✅ **P0 验证**：六页切换 / 设置页读写与权限 / 信箱翻页 / 任务列表滚动 —— 已多轮进游戏验收（09-29 批仍有部分等完全重启验收）。
- ✅ **P1 图鉴页（P3）**：已手写落地 `scripts/musha_dex.lua`（`ScrollingGrid` 展示，不做点击跳转）。
- ⏳ **P2 任务扩编**：13 种 → 约 30（季节任务按季节过滤、行走 move 任务按位置采样），长期目标 50。
- ✅ **P3 技能页（P4）**：技能树加点已进面板（`scripts/widgets/musha_skill_tree.lua`），不是整页搬旧 UI。
- ❓ **P4 刷怪器（P5）**：`musha_spawner` 是否已实现**未复核**。
- ❓ **代码卫生**：modmain `[Musha TRACE]` print 清理 / `musha_skill_data` 法师游侠数据 TODO / README 配置表与 modinfo 同步 —— **未复核**。

## 技术决策记录

- 面板用**真 Screen**（非 HUD Widget），任务/设置/图鉴列表统一 `TEMPLATES.ScrollingGrid`。
- 设置同步走已有 `userdata 副本 → net_string dirty → PushEvent` 通道，**不新增网络变量**，不动存档 userdata；开面板时补发 `musha_request_settings` 拉最新值。
- 组件文件 env 无 `GLOBAL` → 用裸 `TheWorld`/`STRINGS`；组件内不能直接调 `GetModConfigData`。
- ModRPC：`AddModRPCHandler(namespace,name,fn)` 为 3 参；取索引用 `GetModRPC(namespace,name)`（无 `GetModRPCIndex`）。
- DST `Text` 左对齐必须同时 `SetRegionSize(w,h)`，单设 `SetHAlign` 无效。
- 换图流程：png 经 Mod Tools autocompiler 编 tex；**删 tex + xml 启动即崩**。
- 设计定稿：**先做能跑的小版本，不做大而美**；技能页整页搬、信箱先用占位，等美术到位再单开一期。
- UI 视觉定稿方向：书页底 + 孩童风，柔和淡黄（非亮黄像素感）。

## 待决策事项

- 等级/经验自洽校正：是否在服务端按 `exp_table` 每次重算等级（代价：旧档虚高等级会被压回）——用户暂缓。
- ✅ 每日任务数量：**已定 4**（设计稿 §4.1 `daily_quest_count = 4`；09-29 批另定"同一任务最多 3 人同时接取、各自记进度、互不共享"）。
- 设置项清单是否继续扩充（现 7 项）。
- ✅ 图鉴数据源：**已定手写表**（方案 A，`scripts/musha_dex.lua`），自动抓属性以后再说。
- ✅ 更新日志内容与填写方式：**已定 `scripts/musha_changelog.lua`**（信箱页 `require("musha_changelog")` 读它；每条带 `lines_en` 英文；顶条 0.7.13）。
- 美术清单（待画师）：技能页背景/框体、导航图标（zh/en 两套已在 `images/nav_*.xml`）、设置控件素材、（可选）真三角按钮。
- 周边统一：note 剧情页是否换书页风、`bar.png`/`names_musha` 是否一并统一。
