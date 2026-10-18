# Musha 面板多页化 + 局内设置系统 — 设计稿（v2）

2026-09-10 · 状态：**已实现**（2026-10-04 按代码校正）· v2 变更：页面改 5 个、导航改"右侧三角展开列表"

## 0. 目标
1. 面板从单页改成 **5 页（09-10 定稿）**：主页 / 技能 / 信箱 / 设置 / 图鉴。
   → **2026-10-04 实测校正：实际 6 页 = 主页 / 技能 / 信箱 / 设置 / 礼包 / 图鉴**（**没有装备页**）。
   依据：`scripts/screens/musha_panel_screen.lua:1669` `page_order = { "home", "skill", "mail", "set", "gift", "dex" }`；
   `equip` 在 `:1668` 被注释保留（原话：以后要做"右边单独显示"时把 equip 加回这个表）。
   **下文各处"5 页 / 五个 / 五页"均为 09-10 定稿原文，不再逐处改**，以本行与代码为准。
2. 现有 `images/bookpage_bg.png` 一张图**多页共用**；技能页缺美术，等画师改图后补。
3. 做一个**局内可改**的设置系统：**组件** + 面板设置页，改规则立刻生效。

---

## 1. 现有代码基线（改造前）
- `scripts/screens/musha_panel_screen.lua` — Screen 版面板，单页（职业名+Lv / 经验条 / ScrollingGrid 任务列表 / 关闭）。
- `scripts/widgets/musha_panel_registered.lua` — 注册入口，`musha_open_skill_panel` 事件（技能书右键）开。**B 键入口 2026-09-24 已移除**（代码注释保留可恢复）。
- 数据流：服务端 `pc.userdata` → `replica.musha_profession_component:DoUpdata(userdata)` → `gamedata:set(json)` → net_string dirty → `PushEvent("…_dirty")` → 面板 `Refresh()`。
- 渲染：`PANEL_ZOOM=0.93`，BG 1232x832，列表 ITEM_W=860 / ITEM_H=78 / 可视 6 行。

---

## 2. 五个页面（用户 2026-09-10 定稿）

| # | 页面 | 图标（后续美术） | 现阶段文字 | 内容 |
|---|---|---|---|---|
| 1 | 主页 | 小房子 | 主页 | 职业名 / Lv / 经验条 / 任务列表（＝现有内容原样搬入） |
| 2 | 技能 | 树枝（绿色） | 技能 | **技能树**（加点；部分解锁规则照旧）· 美术待定 |
| 3 | 信箱 | 信箱 | 信箱 | 更新日志（查看更新日志） |
| 4 | 设置 | 齿轮 | 设置 | mod 页面的规矩：怪物生成 / 任务数量 / 生命恢复 / 能量恢复 等 |
| 5 | 图鉴 | 装备栏图标 | 图鉴 | 装备规则总览：**装备栏图标 + 文字说明**，可上下滚动，不做点击跳转 |

---

## 3. 导航方式：右侧三角 + 展开列表（不放一排 5 个）

- 面板**右侧**放一个**三角形按钮**（▶/▼），点一下**展开竖向列表**，共 5 项。
- 展开态：三角旋转 90°（▶→▼）；当前页那一项高亮。
- 收起：再点三角 / 点列表任意项（选完自动收）/ 点面板空白处。
- **现阶段全用文字**（图标美术还没出），列表项就是 5 行文字：主页 / 技能 / 信箱 / 设置 / 图鉴。
- 实现：三角 = ImageButton（`square.tex` 拼两个三角形，或后续换美术）；列表 = 一个 Widget + 5 个 Text，绝对定位。
- **代码要留退路**：把 tab 渲染抽成 `BuildNav()` / `SetActivePage(name)` 两个函数。将来美术到位、想换成"一排 5 个图标"（1232 宽其实放得下：每个 90px 也才 450px），只改这两处，不动页面逻辑。

### 3.1 容器结构
```
root
├── black / black_clicker            （不变）
└── content (PANEL_ZOOM 0.93)
    ├── bg                   bookpage_bg（五页共用同一张；技能页将来换图）
    ├── close_btn            （不变，右上红叉）
    ├── nav_triangle         [新增] 右侧三角（默认 ▶）
    ├── nav_list             [新增] 展开的 5 项列表（默认 Hide）
    └── pages                [新增：五个容器，切页只 Show/Hide]
        ├── page_home        现有内容：标题 / 经验条 / 任务 ScrollingGrid
        ├── page_skill       占位：灰底 + 居中"技能页 · 美术待定"
        ├── page_mail        更新日志滚动列表
        ├── page_set         设置项 ScrollingGrid
        └── page_dex         图鉴滚动列表
```
- **切页逻辑**：不重建 Screen，只 `Show()/Hide()` 对应 page 容器 + 换列表高亮 + 更新 `default_focus`。
- 关闭行为保持：黑幕点击 / 红叉 / ESC(`CONTROL_CANCEL`)。

---

## 4. 设置组件（服务端权威）

### 4.1 世界级：`scripts/components/musha_world_settings.lua`（挂 TheWorld）
```
monster_spawn_enabled = true
monster_spawn_mult    = 1.0     -- 档位 0.5 / 1 / 2 / 3
daily_quest_count     = 4       -- 2..8
exp_mult              = 1.0     -- 0.5 / 1 / 2 / 3
```
- 存档：组件自带 `OnSave()` / `OnLoad(data)`，随**世界存档**走 → 多存档天然隔离。

### 4.2 玩家级：`scripts/components/musha_player_settings.lua`（挂玩家）
```
hp_regen_mult = 1.0    -- 0.5 / 1 / 2 / 5
mp_regen_mult = 1.0    -- 0.5 / 1 / 2 / 5
panel_scale   = 1.0    -- 面板缩放微调（可选）
show_debug    = false  -- 显示调试信息（可选）
```
- 乘在 `musha_profession_component` 的 `class_traits`（`health_regen` / `mp_regen_base`）上；改完调一次 `ApplyProfessionData()` 立即生效。

### 4.3 权限
- **世界级**：只有房主（host）能改；非房主整行变灰 + 提示"仅房主可改"。
- **玩家级**：各人改各人的。

---

## 5. 同步与指令（照搬 profession 那套）
- 服务端改值 → replica `DoUpdata(JSON)` → net_string dirty → `PushEvent("musha_settings_dirty")`（全端）。
- 面板 `ListenForEvent("musha_settings_dirty")` → 重读刷新。
- 客户端点控件 → `SendModRPCToServer(GetModRPC("musha","musha_set_setting"), scope, key, value)`。
- 服务端 `AddModRPCHandler("musha", "musha_set_setting", fn)` → **先验权限** → 改值 → 回推。
  （注意：3 参签名 + `GetModRPC(namespace,name)`，backlog 里踩过坑。）

---

## 6. 设置页控件
- 每行：左 `名称(Text)` + 右 `控件`。行高 78，可视 6 行 → **直接复用 `TEMPLATES.ScrollingGrid`**（任务列表同款，滚动条样式白送）。
- 三种控件，全部 `square.tex` 拼，不依赖新美术：
  1. 开关：两个 ImageButton（开/关），选中态高亮
  2. 档位：`<  1x  >` 左右箭头循环离散档位
  3. 数字：`-  4  +`，范围钳制（如 2..8）
- 点一下立刻发 RPC；权限失败 → 行闪烁 + 提示。
- 非房主：世界级那几行整体降透明度并禁点。

---

## 7. 信箱页（更新日志）
- 数据源：`scripts/musha_changelog.lua`，`modimport` 进来：
```lua
MUSHA_CHANGELOG = {
  { ver = "0.7.6", date = "2026-09-10", lines = { "…" } },
  { ver = "0.7.5", date = "…",         lines = { "…" } },
}
```
- 显示：ScrollingGrid，每行 = `v0.7.6  2026-09-10` + 下面若干行文本。
- 可选（P2）：记录"已读到哪个版本"（存玩家设置），有新版本 → 导航栏上小红点。
- ⚠️ 用户 2026-09-10：**目前没有更新日志内容** → P2 先只做空页 + 占位文字，内容以后填。

---

## 8. 图鉴页（装备规则总览）— 用户 2026-09-10 定
- **贴装备栏图标** + 文字说明：每行 = 装备图标 + 名称 + 规则文字。
- 列表**可上下滚动**（复用 `ScrollingGrid`，和任务列表同一套）。
- **不做点击跳转 / 详情弹窗**。
- **实现难度：低**。架构现成，真正的工作量只有"装备数据从哪来"：
  - 方案 A（推荐先做）：手写一张表 `MUSHA_DEX = { {icon="…", name="…", text="…"}, … }`，
    放 `scripts/musha_dex.lua`，modimport 进来。图标用装备自己的 `inv_image`。
  - 方案 B（以后再说）：从 prefab / TUNING 自动抓属性生成表。要逐个 prefab 适配，工作量大，先不碰。

---

## 9. 怪物生成（独立模块，单独一期）
- 设置页只存数值；真正生效需要一个自建刷怪器 `musha_spawner`（挂 TheWorld）：`OnUpdate` 每 N 秒按 `monster_spawn_mult` 决定是否在玩家附近按白名单 `SpawnPrefab`。
- 原版刷新率在 worldgen 阶段定死，运行期改不动 → 只能"自己刷"。
- 改**已存在**怪物的血量/伤害：遍历现有 + 对新生成的用 `AddPrefabPostInit`（只对新生成生效）。
- → **P4**，本期只落设置项 UI 与存盘。

---

## 10. 分期
| 期 | 内容 | 依赖 |
|---|---|---|
| P1 | 设置组件（world+player）+ RPC + 存盘 + 面板五页框架（右侧三角导航）+ 设置页 | 无 |
| P2 | 信箱页（changelog 表 + 滚动显示）+ 可选未读红点 | P1 的切页框架 |
| P3 | 图鉴页（先手写表；要不要自动抓属性看你） | 装备数据源确定 |
| P4 | 技能页（等画师图） | 美术 |
| P5 | 刷怪器 + 怪物血量/伤害倍率 hook | P1 设置项 |

## 11. 给画师的清单
1. **技能页**背景/框体（主要缺口；尺寸对齐 bookpage_bg 1232x832 或只画内容区）。
2. **5 个导航图标**：小房子 / 绿色树枝 / 信箱 / 齿轮 / 图鉴（+ 三角展开钮可选）。
3. （可选）设置页控件素材：左右箭头、开关钮、加减号。

## 12. 确认记录
### 已定（用户 2026-09-10）
1. ✅ **导航位置**：面板**右上**放三角，点开在它下方竖向展开 5 项列表。
2. ✅ **世界级设置权限**：**房主 + 管理员**都能改。
4. ✅ **技能页 = 技能树**：加点形式；部分解锁规则照旧（沿用原来的解锁条件）。
5. ✅ **图鉴 = 装备栏图标 + 文字说明**，可滚动，不做点击跳转。
6. ✅ **更新日志暂无内容** → 信箱页先留空占位。
### 待确认
3. **设置项清单**还要加什么？（现列：怪物生成开关+倍率、每日任务数量、经验倍率、生命恢复倍率、能量恢复倍率）
7. ✅【D】第一页要**书页风**，替代掉简单版的第一页（用户 2026-09-10）。
   → 判断：**这页其实已经做完了**。现在面板底图就是 `bookpage_bg.png`（1232x832 书页），
     主页只要把现有内容（标题/Lv/经验条/任务列表）原样搬进 `page_home` 即可，不需要重做。
8. 🔒【本设计已拍板·防反复】先做**能用的小版本**，不做大而美：
   - 技能页＝把现有技能书 UI（`scripts/components/musha_skillui.lua`，卡片 1232x832 + 技能格）**整页搬进** `page_skill`，不重画不重排。
   - 信箱页＝空页占位；图鉴页＝空页占位（手写表可后补）。
   - 真正新写的只有：五页框架 + 右上三角导航 + 设置组件 + 设置页。
   - 理由：骨架先跑通（游戏里能看见、能摸），判断才准；纯靠想象比大而美必然反复。
   - 技能页"做大"要同时动 美术素材 + 布局 + 交互 三样，所以显得折腾 → 等美术到位再单开一期。
