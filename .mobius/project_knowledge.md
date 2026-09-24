# 项目宏观规划

> 由 Mobius 系统宏观规划模式维护，请勿手动删除结构标题

## 项目目标

- Musha：DST 角色 mod（作者 Ciel/雪儿），主打**多职业 RPG 成长**（职业 / 等级 / 任务 / 技能）。
- 当前版本 **0.7.6「职业系统重制版」**；API 10，仅 DST（不兼容单机/巨人国/海难/哈姆雷特）。
- 交付渠道：Steam 创意工坊 + 手动安装。质量目标：职业→任务→技能→设置形成完整闭环，UI 统一"暖黄书页 + 孩童风"。
- backlog = `musha-backlog.md`（条目级进度），设计稿 = `musha-panel-tabs-and-settings-design.md` / `ui-redesign-plan.md`。

## 核心模块

- **角色与职业**：4 基础职业（战士/法师/游侠/刺客）+ 6 进阶（剑士/近卫/药剂师/元素法师/吟游诗人/月影猎手）；服务端 `musha_profession_component` + replica，等级/经验为累计制 `exp_table`。
- **任务系统**（`components/musha_quest.lua`）：每日任务（每日 N 个，可累积，上限 10）+ 转职任务（雕像接取，一次 1 个，3 轮进阶）；8 类事件推进，discover 类跨天作废。
- **面板 UI**（`screens/musha_panel_screen.lua`）：真 Screen + `TEMPLATES.ScrollingGrid`，5 页 = 主页/技能/信箱/设置/图鉴；入口 = 技能书/职业书右键（`musha_open_skill_panel` 事件）+ 控制台命令；**B 键入口 2026-09-24 已按用户要求移除**（B 是原生键，抢它会跟原版打架），左竖排导航常驻（NAV_ALWAYS_SHOW，x=-500）。
- **局内设置系统**：`musha_world_settings`（刷怪开关/倍率、每日任务数、经验倍率）+ `musha_player_settings`（生命/精力恢复倍率、调试）；经 ModRPC 修改、随存档保存。
- **技能系统**：`scripts/skills/musha_skill_data.lua` + `components/_musha_skills.lua.bak`（未启用；启用后恢复 heal_skill 任务类）。
- **物品/prefab**：职业书、便签（note）、技能书、剑/矛、tome；多语言 zh/en/ko/ru（ja 计划中）。

## 当前阶段

- v0.7.6 开发中；面板架构改造 A（HUD Widget → 真 Screen + ScrollingGrid）已完成。
- **P1 五页框架 + 三角导航 + 设置组件 + 设置页**：代码已写，**待进游戏验证**（权限/切页/写入）。
- **P2 信箱页**：已完成（橙框 + 内层橙灰底 + 可点页码）。
- 待验证风险点：`player.Network:IsServerAdmin()` 服务端可用性；`AddPrefabPostInit("world"/"forest"/"cave")` 触发；设置页 7 行布局；三角用字符 ">" 待美术化。
- 正式发布前必须确认 `musha_quest.lua` 的 `TEST_DAILY_COUNT` 已回 nil（现为 nil）。

## 近期任务

- **P0 验证**：进游戏跑通 P1/P2 —— 五页切换、设置页读写与权限、信箱翻页、任务列表滚动/滚动条。
- **P1 图鉴页（P3）**：手写 `MUSHA_DEX` 表（装备图标 + 名称 + 规则说明），`ScrollingGrid` 展示，不做点击跳转。
- **P2 任务扩编**：13 种 → 约 30（季节任务按季节过滤、行走 move 任务按位置采样），长期目标 50。
- **P3 技能页（P4）**：等画师美术；先把现有技能书 UI 整页搬入 `page_skill`，不重排不重画。
- **P4 刷怪器（P5）**：`musha_spawner` 挂 TheWorld，OnUpdate 按倍率自建刷怪 + 怪物血量/伤害 hook（原版刷新率运行期不可改）。
- **代码卫生**：modmain `[Musha TRACE]` print 清理；`musha_skill_data` 法师/游侠数据仍是 TODO；README 配置表与 modinfo 不同步。

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
- 每日任务数量最终定 3 还是 4（modinfo/局内设置已支持）。
- 设置项清单是否继续扩充（现 7 项）。
- 图鉴数据源：手写表（推荐先做）vs 从 prefab/TUNING 自动抓属性。
- 更新日志内容来源与填写方式（信箱页现为占位）。
- 美术清单（待画师）：技能页背景/框体、5 个导航图标、设置控件素材、（可选）真三角按钮。
- 周边统一：note 剧情页是否换书页风、`bar.png`/`names_musha` 是否一并统一。
