# Musha backlog（2026-09-10 深夜更新）

## 🧹 2026-10-18 收尾批（opencode 执行「把上次没做完的做完」+ 加通用闹钟）

- [x] **积压全部入库（4 提交：代码/资产/文档/账本）**：09-28 晚两框 + 批1(09-29) + 批2(09-30 英文) + 批3(10-02 日语) + 批4(10-04 发布) + 10-04 文档校正 + 10-05 精灵日志 + 10-12 精灵开关回关 + 10-14 ㉙登记。
- [x] **`GetOpenSlotForItem` 2 处死代码已修**（musha_actions / musha_mail）——原拟换 `GetSpecificSlotForItem` 因 `usespecificslotsforitems=false` 恒 nil，改手写「第一个已解锁空格」循环（state ㉚.2；82 文件过检）。
- [x] **musha_mail_x 图集补注册 2 行**（modmain）。
- [x] **10-10 导航图标换图补记**（nav 六对 png+tex、equip 未换、xml 图集未动）随资产批入库。
- [x] **通用闹钟上线**：共享文件 `%APPDATA%\app\hermes-alarms.json`（opencode/工作台/hermes 三方可读写），`state=armed` 且（`done:true` 或到点）响、响完置 `fired`；工作台侧 = 其仓 REQ-049，opencode 侧 = 独立响铃器进程兜底。
- [x] **bigportraits 拍板 = 先放着**（2026-10-18）：保持 modified 不入库、不改回，等有接线打算再说。
- [x] **垃圾三类已清**（2026-10-18 拍板「清掉三类」）：`anim/musha_v2_gaiguo210x216.zip`、`images/8030e666-*` UUID×6、`release/` 全删；`_vibex交接/` 不在三类内 → 保留。
- [x] **推送点头已给**（2026-10-18）：四批 + 本补记共 5 提交推 Gitee；进游戏验收清单照旧（完全重启 DST）⚠ 仍待做。
- 遗留：㉙ UI exe **路线 b（解析面板 lua 坐标表）已拍板（2026-10-18），待用户说开工**；月牙斩实测提醒；`hp_regen_mult` 留/删待拍板。

## 🔨 2026-10-14 新增任务：**UI 独立 exe（输出到现实显示 + 可编辑重新排版）**（用户口述加任务，未开工）

- [ ] **把 musha 的 UI 做成一个真实可运行的 Windows exe**（用户原话：「能让 UI 被输出显示到现实的 exe，可以编辑重新排版」）
  - 目标：**不进 DST** 就能在 Windows 上双击打开 exe，看到面板 UI 的真实显示效果
  - 要求 ① **显示**：UI 渲染到现实（exe 独立运行，不依赖游戏）
  - 要求 ② **可编辑**：控件能改（文字 / 尺寸 / 开关等）
  - 要求 ③ **可重新排版**：布局可拖拽 / 重排，调整结果能保存下来
  - 候选路线（**均未拍板，开工前先让用户选路线**——按项目习惯先定路线再动手）：
    a. 网页复刻：HTML/CSS 按面板坐标表排版 → WebView2 / Electron / Tauri 打包 exe（编辑器最省事）
    b. 解析面板 lua 的坐标 / 控件表自动生成可编辑视图（数据真源，但 DST widget API 只能模拟）
    c. 图上摆位：以面板底图（panel_bg / page_bg）为画布，控件以图片层拖放，导出坐标回填 lua
  - 验收：exe 双击即开、显示与游戏内一致；控件可编辑；布局可重排并**保存 / 导出**
  - 关联：面板 = Screen + ScrollingGrid、导航 6 页（主页/技能/信箱/设置/礼包/图鉴）；UI 底图不压暗（AGENTS 铁律 5 例外）；不动 `anim/`、不打包任何美术（铁律 2）

## 🔧 2026-09-29 用户口头批（面板修复 + 转职锁 + 若干决策，未落地）
- ⚠️ **提醒：月牙斩（剑气斩 slash_qi）还没实测** —— 用户原话"提醒我 月牙斩没测试"；
  特效 `scripts/prefabs/musha_slash_qi_fx.lua`（L143 `USE_ENGINE_FACING`）+ 施法
  `scripts/musha_weapon_skill.lua`（`musha_sword → slash_qi`）**都要完全重启 DST 后实测**
- [x] **09-29 第二批 · 月牙斩「发出去看不见」→ 根因 + 修法** ✅：
  根因 = **常量与 zip 不配对** —— `USE_ENGINE_FACING=false`（代码点名播 `slash_dir0..7`），
  但 `anim/crescent_cyan8.zip` 是**官方名包**（md5 `D8AAF5F2…`，anim.bin 里只有
  `slash` / `slash_down` / `slash_upright`…，**没有 slash_dir\***）→ 名字对不上 = 黑屏。
  正是该文件头 :125 自己写的坑（09-27 把 true 改 false 时漏换包）。
  修法（用户拍板"**先只改代码试官方名**"）：按两份 scml 的 file id 逐条对齐，
  `ART.cyan8` 的 `dirs/pre/fly/hit` → `slash_downright / down / downleft / left / upleft / up / upright / right`；
  方向源仍是 `DirIndexFromRotation`，选图语义不变。
  回退 = 改回 `slash_dir*` + 把 `anim/_bak_crescent_cyan8_点名_20260926.zip` 拷回来（**必须成对**）；
  仍黑屏 → 换"重出点名包"路线（改 scml 动画名 → DST Mod Tools 导出，工具在
  `C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Mod Tools\mod_tools`）。
- [x] **09-29 第二批 · 技能树节点连线太长** ✅：`musha_skill_tree.lua` `COL_DX 168 → 132`
  （同行横线 = COL_DX−NODE：92 → **56**，与跨行竖线 56 等长）；只动列距，行距/图标格不碰。
  顺带记一笔未修的隐患：跨行前置画横线用 `(x2-NODE/2)-x1`，同列时算出 **-38 负宽**（被节点卡盖住看不出）
- [x] **09-29 第二批 · 主页两框「铺满上下面板」** ✅：量 `images/panel_bg_alt.png`（stdlib 手解 PNG）
  得内纸 = content **x -408..575、y +369.5..-350.5**（与文档"内纸 -408..575 / 下沿 -351"对上）→
  上框 **983x308 @(83.5,215)**（y 61..369）、下框 **983x420 @(83.5,-158)**（y -368..52）；
  两框同宽同左右缘、缝仍 9px；下沿盖住任务滚槽 -366。
  图按新尺寸重生成：`exported/_tools/gen_home_frames.py` FRAMES 改 → `art_update.py publish`
  （旧图已备份 `exported/_tools/_art_backup/home_frame_*_20260929_*`），tex 已转码 → 要完全重启
- [x] **09-29 第二批 · 酒馆板「拉长50 左移80」** ✅：`musha_tavern_screen.lua`
  `BOARD_H 590 → 640`、`BOARD_OFFSET -361 → -441`；只拉框不动行坐标（用户拍板）
- ❌ **09-29 答复 · 近卫「嘲讽」没做**：全 mod `嘲讽/taunt/仇恨/aggro` 0 实现
  （`musha-职业估期与排期.md:23` 也标 ❌）；近卫现有 = 钢铁意志 + 生命偷取 + MP 盾（非技能）。
  技能全表见本轮答复（4 棵树：战士/刺客/剑士/近卫；法师·游侠·药剂师·元素法师·吟游诗人·月影猎手**无技能树**）
- [x] **任务行加「放弃」（用户 09-29：「请给任务面板的任务加上 放弃喵」）** ✅ 已落地：
  只在**展开的每日任务详情子行**右端出红色「放弃」按钮（转职行/已完成不给丢，两步才丢不手滑）。
  服务端 `MUSHA_QUEST:AbandonQuest`（`musha_quest.lua` AcceptQuest 之后）= 从进行中删除 +
  **插回酒馆可接列表最前**（进度清零、可立刻重接、`AVAIL_MAX=4` 不会被挤掉）+ `SyncToPanel`；
  RPC `musha_abandon_quest`（`musha_rpcs.lua` 接取 handler 之后，talker 回话）；
  面板 `musha_panel_screen.lua` ctor `w.drop`（**加在 `w.clicker` 之后**，z 序压住它才不会顺手收起行）
  + `BuildQuestItems` 详情行带 `id`；文案 key `ABANDON`（中英各 1，key 数仍一一对应）。
  酒馆板「进行中」那栏**还没加**（用户只点了"任务面板"）→ 要的话再补
- [x] **调试开关（作者 SteamID 判定）**：命中 → 开发模式 = 0 级就能测、可自由切换职业、
  进游戏自带**全制造**（`builder:GiveAllRecipes()`）；口径"**（启动本地）的时候都属于这个模式**"
  = 房主/本地 listen server 一律开；作者 SteamID64 已在库内
  `scripts/musha_crash_bridge.lua:28 SID_FALLBACK = "76561198220617051"`（兜底同值）
  ✅ **09-29 已落地**（用户拍板"对，但只认 SteamID"→ 不按本地房主自动开）：
  `scripts/musha_dev_mode.lua`（新）+ `modmain` 尾部全制造钩子 + `GLOBAL.c_musha_job`
  控制台切职业 + 组件 `DevOn()` 放开 `unlock_requirements` 等级门槛（`:1011` / `:1102`）。
  ⚠️ 两个坑写在文件头：`TheNet:GetUserID()` 是 **Klei ID** 不是 SteamID64；
  SteamID64 ≈7.66e16 **超 double 安全整数**（2^56 附近 ulp=16）→ 引擎值要带容差比，
  同时认 SteamID3 账号 ID `260351323`；读不到就当没命中，**绝不回退常量**（否则别人机器全开）
- [ ] **兔子洞（爱丽丝穿洞去地下，不走路程入口）** —— 结论**能实现**，走现成跨 shard 迁移：
  `TheWorld:PushEvent("ms_playerdespawnandmigrate", {player=..., portalid=..., worldid=...})`
  （引擎样板 `data/databundles/scripts/consolecommands.lua:1366 c_migrateto`；
  落点判定 `scripts/components/playerspawner.lua:243` worldid ≠ 当前世界 → 走迁移出生）。
  **前提**：世界必须开着洞穴 shard（没开洞穴就没有 Caves shard → 不可用，得有兜底）；
  要指定"兔子洞出口"落点 → 洞穴侧放自定义 worldmigrator（mod 双 shard 都加载，可行）；
  迁移有几秒 despawn/spawn，战斗/骑乘中状态要处理
- [x] **剑士转职 bug（用户处方）**：战士→剑士 **没发放技能书、技能直接可用**。
  现状链路 `CompleteAdvance:1774` / `SetCarrerSpecial:851` → `GrantAdvanceGift:1280` →
  `GiveCareerBook:1256`（`CAREER_BOOK.saber = "musha_skillbook_saber"` `:1253`，资源/PrefabFiles:439 都在）；
  真因**待复现**：`CanUpgradeSkill` 只查 `req`/`unlock_requirements`/技能点，
  **没查"读过书没有"** → 剑士可直接花技能点把 slash_qi 0→1，书形同虚设。
  处方：加 learned 变量 → **false（没学过）就 lock** → 读了书才解锁 → 重新检验
  ✅ **09-29 已落地**：`userdata.book_learned` / `book_lock_armed` 两个变量；
  `CanUpgradeSkill`（原 `:960` 只看 `cur==0`，等级被别的路径抬上去就绕过 → 改看变量）、
  `GetSkillView` `book_need` 同步改判据、`UnlockSkillByBook` **先置变量再提等级**（顺序反了锁解不开）、
  `UnlockSkillWithItem` 同理；`GrantAdvanceGift` 发书**前**先 `ArmBookLock()`（清 0 + 上锁，一次性记账）
- [x] **旧存档迁移规则（用户口述，含糊处待确认）**：更新时玩家职业相符但**旧档没有该变量** → ?
  ；职业相符但其它不符 → **忽略**；**新存档必须有验证**；"条件必须超过等级 2，否则重新锁定、
  **赠送解锁的技能书**、而且必须从 0 级开始"
  ✅ **09-29 已按拍板落地**（问题1答"旧档 slash_qi 当前等级>2 才保留"）：
  `MigrateBookUnlock()` 在 `OnLoad` 末尾跑**一次**（`book_learned` 是 table = 新档/已迁移 → 直接 return，
  构造函数里 `book_learned = {}` 就是"新档验证"）；职业相符：`lv>2` → 保留解锁；
  否则 **清 0 + 重新锁定 + 延后 2 秒补发剑士技能书**；职业不符 → 只置默认锁、不补书、不动点数
- ✅ **更新日志可以中文**："白马非马"**找不出对应准确翻译 → 保持中文不硬翻**；
  且"**兼容可以作为功能去说明**——兼容玩家双方的语言特点"→ 混排是卖点，写进工坊介绍
- [x] **创意工坊介绍要补**：现有装备/物品**没有说明，人家不知道玩什么**；
  口径"不需要写太复杂或没用的东西，**只介绍特色**"
  ✅ **09-29 已起草**（`README.md` 两处）：① 新增 `## 装备与物品` 节（武器 / 道具 / 建筑三组，
  只写特色、数值与图鉴 16 条对齐）② 新增 `### 工坊描述 · 玩法版（复制即用）` 可粘贴块
  （一句话 → 职业 → 装备物品 → 图鉴入口 → **双语兼容当特性** → 免费声明）。
  **对外发布仍须你点头**（逐批问的老规矩）。
  顺手修：`## 支持语言` 原写 한국어/日本語/Русский 已支持，与实际"借英文"不符、
  也和新块里的"其余语言暂用英文"打架 → 改成"暂用英文显示（日文汉化进行中）"。
  ⏳ 另发现：`README.md` 版本行仍写 **0.7.9 半**（modinfo 已 0.7.13），**未动**，等你说改不改。
- [ ] **日语做**；**装备页跳过**（维持）；**删除「装备页移到右侧面板计划」** —— 用户：
  "不打开技能就能看到，但要求**等经费**，我现在不想去测试那个东西" → 从计划里销掉
- [x] **新物品：重置职业用**，**不开放任何制作条件**（= 不可制作，获取方式待定）
  ✅ **09-29 已落地**（用户答"我测试需要用到，仅作者用，本地模式/使用者属于测试安全员都允许使用"）：
  `scripts/prefabs/musha_job_reset.lua`（新，**不加配方**，美术借原版 gems.zip + 回城石图标占位）+
  动作 `MUSHA_RESET_JOB`（`musha_actions.lua` 新增 AddAction/ComponentAction/Stategraph 三处）+
  组件 `ResetJobForTest()`（职业清空 + 等级/经验/技能点/技能树全归 0 + 技能书锁归零，
  **不碰 ud.mail 信箱**）+ 中英 `S.NAMES.MUSHA_JOB_RESET` / `S.ACTIONS.MUSHA_RESET_JOB` / DESCRIBE。
  权限在 prefab 服务端判：`musha_dev_mode.CanUseTestItem()` = 作者 / 测试安全员白名单 / 本地房主模式；
  获取 = 控制台 `c_give("musha_job_reset")`

## 🧪 0.7.13 批（2026-09-28 用户拍板"这条更新写入 0.7.13"）
- [x] **酒馆委托板底图 = 木框花**：modmain 注册 tavern_frame atlas（09-27 已 publish 未注册
  → 开板报 Invalid resource handle，本轮修）；"接任务的底图用这个"（用户贴图 = 木框花同款）
- [x] **同一委托最多 3 人同时接取**：`AcceptQuest` 加 `CountQuestTakers` 校验（返回 takers_full）；
  RPC talker 报"该委托已被 3 人同时接取"；`SyncToPanel` 推 `tk` → 板上奖励行显示 "n/3"；
  进度每人一份组件数据 → 天然独立不共享
- [ ] **金色任务共享** —— 用户："后面会尝试让金色任务共享，现在先**暂停**" → 挂起（0.7.14+ 再议）
- [x] modinfo name/version → **0.7.13**；changelog 新增 0.7.13 节（中英 4+4 行）
- [x] **两框重叠 79px 已修**（09-28 用户回「修」）：按实测坐标收口（分隔线 y=82、经验条
  y 77..153 右 413.5、徽标底 80）→ 上框 **760×224 @(65,173)**（y 61..285、x -310..440，
  加宽到 760 让经验条右下角躲开 r=50 圆角；早先口头方案 724×199 会让经验条戳出框底，已弃）、
  下框 **780×462 @(122,-179)**（y -410..52、与上框缝 9）、`QLIST_Y` -140→**-176**（视口
  40..-392，框内留 12/18）、空文案 -115/-175 → **-157/-217**；2 图重生成 + publish ✓。
  已知小瑕疵：滚动条滑块贴到视口最顶端时，右上角可能越出下框 r=50 圆角 ~10px（半透明白，
  不显眼；要根治得动滑块轨位或圆角，未动）
- [ ] **下个版本重画主页两框底板** —— 用户 09-28："alpha 底板透明度设置 0.6，下个版本重画这个，
  大概是透明度不够" → 本轮已把 tint 0.7 → **0.6** 临时压；重画 = 图本身带半透明质感
  （毛玻璃/花纹），不再全靠 SetTint 整体压

## ✅ 2026-09-28 晚落地（用户拍板：甲 / 每日不批发 / 英文直译 hotel / DEBUG 关）
- [x] **主页上下两框**（"白底的bg附加椭圆框"）：`home_frame_top` 724×228 @(52,171)、
  `home_frame_bottom` 780×546 @(122,-137) —— `exported/_tools/gen_home_frames.py`
  （白身+棕描边，r=50 大圆角=椭圆观感；纯椭圆会削任务行四角）→ publish → modmain 注册 →
  panel 创建入 `pages.home` 组，`SetTint(1,1,1,0.7)` 同任务行胶囊
- [x] **空任务引导恢复**（09-28 早"两行都藏"被晚间推翻）：空列表 →
  「请去酒馆接受相关任务 》」+ hint「每日委托在酒馆接取 · 转职任务从酒馆取卷轴」；
  无职业分支保留（暂无职业/使用职业书）；`quest_empty/quest_hint` 加回 pages.home 组、
  位置移入下框中心 (122,-115)/(122,-175)
- [x] **任务列表滚动条**（甲："不显示竖条"）：`scroll_bar_line` 构造段 + RefreshView 覆写双处 Hide；
  滑块（握把）/滚轮/拖拽保留
- [x] **酒馆英文名 Tavern→Hotel 直译**（用户："英文直译 hotel，中文就这么写"）：
  english.lua NAMES/DESCRIBE×2/ACTION 共 4 处 + musha_changelog `lines_en` 3 处；
  中文「酒馆」全部不动；代码标识符（musha_open_tavern_panel 等）不动
- [x] **DEBUG_QUEST = false**（musha_quest.lua:15，release blocker 销一项）
- [x] **每日不批发口径核实**：服务端 09-28 已合规（`GrantNewDayQuests` = 只补酒馆可接列表，
  `AddDailyQuests` 无调用方）；面板过时文案"每日任务明日自动发放"已清除
- [ ] 参考图《面板底框_参考图重绘》接线 → **用户 09-28 拍板：留 0.8.0**
- ⚠️ 变更须**完全重启 DST**（2 tex 新增 + 多 lua）

## 🗓 2026-10-02 开工：英文第二批（全部翻完）+ 文案迁 STRINGS（用户 09-28 拍板）
- 范围（"英文下批全部翻了"）：**面板剩余中文全翻** —— 主页任务空状态提示、任务名 / 每日委托文案（服务端下发）、
  设置页、礼包页、图鉴页、信箱兜底日志**保持中文不动**（`musha_panel_screen.lua:169-183`）
- **机制：搬进 STRINGS，不写在面板控件里**（用户："可以先写 STRING. 然后日记稍后加载吧？"）
  - 项目已有的语言机制：`modmain.lua:984-989` 按 `Profile:GetLanguageID()`（21/22/23=中文）`modimport`
    `scripts/languages/chinese.lua` / `english.lua`（`GLOBAL.STRINGS`）；两个文件**现在只放物品名和描述**，
    没有面板 UI 文案 → 新文案进这里（`STRINGS.MUSHA_PANEL_*` / `MUSHA_SKILL_*` / `MUSHA_CHANGELOG_*`）
  - modmain 两端各自跑 → **每个客户端按自己的语言加载**，语言跟人走（这是 STRINGS 比字段版强的地方）
  - ⚠️ 关键坑（10-02 必改）：`GetSkillView` 在**服务端**执行，读的是服务端的 `TUNING.MUSHA_UI_LANG`；
    专用服务器上 `Profile` 为 nil → `loc=nil` → `english.lua` → 中文玩家会看到英文技能
    → 正解：**服务端只发 key + 数值**（`entry.lvl_val = level_effects[cur]`），**客户端本地**
    `string.format(STRINGS..., v)` 格式化
  - 更新日志：已是数据源 `musha_changelog.lua` + 面板 `pcall(require, "musha_changelog")` 懒加载（不在控件里 ✓）；
    10-02 二选一：**保留 `lines_en` 字段**（省事、行数可控）或迁 `STRINGS.MUSHA_CHANGELOG_*`（统一机制）——
    开工时看迁移量定，我倾向保留数据文件（它是内容数据不是 UI 标签）
- 09-28 已完成的字段版（`lines_en` / `*_en`）先用着；10-02 若决定迁 STRINGS，**同一批一起搬**，别改两遍
- 之后接：日文（`*_jp`，和 tavern_frame 同批，见下一节）

## 🎯 2026-09-28 用户拍板：这两件归入 0.8.0（0.7.12 这批先不动）
- [x] ~~**tavern_frame（木框花 350×590）下个版本用上**~~ ✅ 0.7.13 批已做（modmain 注册 atlas + 直接作为委托板底图上场）
  - 现状：`images/tavern_frame.{png,tex,xml}` 已 publish（09-27），但 `modmain.lua` 里**没注册**这个 atlas
    → `musha_tavern_screen.lua:136` 开酒馆时 client_log 实测报（09-28 00:02:30）：
    `Invalid resource handle for atlas '../mods/musha/images/tavern_frame.xml'`
  - 0.8.0 要做：modmain 补 Asset 注册 → 再决定怎么接进酒馆屏（现版先留着报 warning，不炸）
- [ ] **日文（jp）翻译**：和 tavern_frame 同批做
  - 英文机制 0.7.12 已落地（更新日志 `lines_en`、技能 `*_en`、详情标签/按钮按 `UI_LANG` 分支）；
    日文照同一套路再开一份字段，ko/ru/jp 目前和导航横幅一样借英文（`musha_panel_screen.lua:2442` 同口径）
- 备注（0.7.12 已完成、只作留痕）：英文 = 更新日志 8 条 + 技能 7 条（name/tip/fmt）+ 详情页标签 + 「加点 / 用技能书解锁」按钮词

## ⏸ 2026-09-12 待确认设计：祭坛「卷轴 → 获取任务」两步流程
- 🛑 **2026-09-12 晚最新**：用户"祭坛回家弄"，并说
  "原来设定没错 但是**右键直接查看**和**任务栏里使用**是另一回事 让我想想"
  → 设定文档不用改；岔路在交互入口（右键祭坛 vs 面板任务栏里使用），
  用户在想 → **卷轴流程暂不写码**（下面路线1 已拍板但仍等这条定）
- 用户原话："而且应该最好是 预设空间 里面有一个卷轴，然后右键选择获取任务，再给予转职任务的。"
- 🧩 **晚二轮设定（最新）**："右键职业书接取 / 每次箱子里只有1个、不会同时显示3个 / 最好无法取出 /
  设置下材料（我定，5天内能集齐就行）" → 详见 `musha-current-state.md` 同名段（含配方方案 A/B/C
  与"职业书被消耗"的硬冲突）
- 即：现在的"右键祭坛 = 直接接任务"一步到位，要改成 **祭坛里有卷轴 → 右键卷轴/祭坛「获取任务」→ 才给转职任务**
- 和设定文档对得上：`musha_jobsystem.md`「5级一转」段写着
  "在建筑容器栏内检查任务卷轴 / 完成3个任务卷轴逐步进行 / 回到建筑进行最终交互，完成就职仪式"
- 现状（2026-09-12 查）：
  - 动作名 = `STRINGS.ACTIONS.MUSHA_QUEST_INTERACT` = "查看任务"（`scripts/languages/*.lua`）
  - **没有任何"卷轴"prefab**（全项目 grep 卷轴/scroll = 0 个任务卷轴，只有面板滚动条）
  - 祭坛 `musha_advance_altar.lua` 现在**没有容器**（只有 tag + musha_action + inspectable）
  - 接任务入口唯一：祭坛右键 → `OnAltarInteract` → `quest:AcceptAdvanceQuest()`（直线给任务）
- 三条候选路线（等用户点）：
  1. **卷轴物品 + 祭坛容器**（贴设定文档）：新建 `musha_advance_scroll` 物品 + 祭坛挂 container；
     容器里预置卷轴，右键祭坛开容器 → 右键卷轴「获取任务」→ 接本轮任务（卷轴消耗），3 轮 = 3 个卷轴
  2. **卷轴物品，不进容器**：祭坛右键「取出卷轴」（改动作名）→ 卷轴进背包 → 右键卷轴「获取任务」
  3. **纯表现 + 文案**：不改流程，只把动作名改「获取任务」、祭坛上加个卷轴视觉（美术待补）
- ⚠️ 未写码 —— 这是玩法流程改动，按用户习惯先定路线再动手

## 🐛 2026-09-12 修：转职祭坛没有等级门槛（不到 5 级就能接）
- 用户报："任务祭坛有问题 不到5级就能接"
- 根因：`OnAltarInteract`（modmain.lua:451）只查三项 —— 有基础职业 / 未进阶 / 职业方向存在，
  **等级一个字都没判**；`AcceptAdvanceQuest` 里也只有"已有进行中/轮次已满"两个条件 → 1 级就能接。
- 修法（单点、服务端权威，`scripts/components/musha_quest.lua`）：
  - 文件头新增常量 `local ADVANCE_MIN_LEVEL = 5`（对齐设定文档「5级一转」，
    见 `.mobius/skills/dst-modding/references/musha_jobsystem.md`）
  - `MUSHA_QUEST:AcceptAdvanceQuest()` 开头加等级判定，不够就返回
    `false, "需要 5 级才能接取转职任务（当前 N 级）"`
  - 失败原因由 modmain 的 `OnAltarInteract` 原样丢给 `talker:Say` → 玩家右键立刻看到差在哪
  - 放服务端而不是放 UI 的 `SetCanUseCheck`：UI 只是"动作显不显示"，判定必须在服务端，
    否则客户端改包就能绕过（而且 5 级是硬门槛，动作该照常显示、点了给原因）
- ✅ 语法校验通过（luac5.1 -p 全量 36 个 lua）
- [ ] 待测：3~4 级右键祭坛 → 提示"需要 5 级"；5 级右键 → 正常接第 1/3 轮

## 🏗️ 2026-09-12 技能页子页（未学习 / 已学习）+ 删空设置「能量恢复」
- [x] **删掉空设置「能量恢复」**（用户："如果没有开放能量恢复的设定就删除吧"）
  - `scripts/screens/musha_panel_screen.lua` 的 `SETTINGS_UI`：删掉 `mp_regen_mult` 那一行 → 设置页 7 行 → **6 行**
  - `scripts/components/musha_player_settings.lua` 的 `SPEC`：删掉 `mp_regen_mult`
    （`OnLoad` 本来就按 SPEC 过滤 → 旧存档里存过的这个键会被丢弃，不报错）
  - 原因：MP/能量系统整体不存在（全项目无 MP 组件/字段/消费方），该设置纯空转
  - ⚠️ **`hp_regen_mult`「生命恢复」保留**（用户只点名了能量恢复）—— 虽然它现在也是 0 消费方，
    但"战斗恢复"常驻 tick 已经存在，接上只要一行（= 上次说的①）
  - ⚠️ 设置页行数 7→6 后 `ROW_Y0 = 134` 未动（用户调过两轮的值不擅自改）→ 底部空出一格
- [x] **技能页拆两个子页：未学习 / 已学习**（用户："原来保留为未学习，通过上方文字项目切换"）
  - 顶部新增两个文字项目（`ImageButton` 150x36 @ y=200，x = ±85）：
    选中 = 白底 + 深墨字 `(0.24,0.19,0.13)` + 深橙下划线；未选中 = 浅灰底 + 灰字 `(0.52,0.46,0.38)`
    （书页风，和技能页的白框/淡白底一套；配色常量 = `SKILL_TAB_ON` / `SKILL_TAB_OFF`）
  - 筛选规则：**未学习 = 技能等级 0**，**已学习 = 等级 ≥ 1**
  - 未学习行：技能名 / 需要 Lv.N · 消耗 N 技能点 / 学完后：<效果> / （有 tip 补一句灰字）
  - 已学习行：技能名 / 等级 x/max / 当前：<效果> / 下一级：<效果>（满级写"已满级"）
    —— **已学习行也保留粉加号**（学过的还能继续升级）
  - 空状态文案：没职业="还没有职业"；未学习空="该职业的技能已全部学习"；已学习空="还没有学习任何技能"
  - 实现：`self.skill_tab` + `SetSkillTab()` + `RefreshSkillTabs()`；
    `RefreshSkills(md)` 里 `if md then self.skill_md = md end` → **切子页传 nil 复用上次数据**（不用重拉服务端）
  - ✅ 语法校验通过（`luac5.1 -p` 全量：36 个 lua 全过）
- [ ] 待定（用户："部分主动技能怎么使用——我要想想"）：主动技能（背刺/吸血/钢铁意志等）的**释放方式**
      还没定（快捷栏？技能书？蓄力？）→ 想好再动，本轮不做
- [ ] 待测（用户出门买菜去了，回来进游戏看）：技能页两个文字项目点击切换、未学习/已学习筛选、
      设置页少了"能量恢复"那行（7→6 行，底部会空出一格 —— 要居中/下移给个数字）
- [ ] 待用户拍板：`hp_regen_mult`「生命恢复」现在是 0 消费方，**留 or 删**（用户只点名删了能量恢复）

## 🏗️ 2026-09-12 进阶祭坛：真 prefab 落地（原为 statuemaxwell 占位）
- [x] 新建 `scripts/prefabs/musha_advance_altar.lua`（prefab 名 `musha_advance_altar`）
      - 名字/描述自动取 `STRINGS.NAMES.MUSHA_ADVANCE_ALTAR`（中英都有："进阶祭坛"/"Advance Altar"）
      - 占位动画 = **复用原版麦斯威尔雕像**：`SetBank("statue_maxwell")` + `SetBuild("statue_maxwell_build")`
        + `PlayAnimation("idle_full")`，assets 引 `anim/statue_maxwell.zip` + `anim/statue_maxwell_build.zip`
        （游戏 data/anim/ 里就有，已核实存在；视觉与旧占位一致 → 零回归）
      - ★ **模型移植点**集中在文件头 3 个常量 ALTAR_BANK / ALTAR_BUILD / ALTAR_ANIM + assets 表，
        换模型只需改这两处，其余逻辑不动
      - 碰撞体积：`MakeObstaclePhysics(inst, 1.1)`
      - **不加** "structure" tag（会被 Deerclops 当建筑砸；祭坛不该被破坏）
- [x] `modmain.lua`：PrefabFiles 加 `musha_advance_altar`；祭坛绑定抽成 `BindAltar(inst)`，
      同时挂新 prefab + 旧占位 `statuemaxwell`（老存档里摆着的雕像继续能用）
- [x] 🐛 **修了一个真 bug**：原占位把 `AddTag("musha_altar")` + `AddComponent("musha_action")`
      写在 `ismastersim` 早退**之后** → 客机（含主机自己的客户端 sim）根本没有 tag/组件
      → SCENE 右键**不出** MUSHA_QUEST_INTERACT。现在 tag/组件在 SetPristine 前加（两端都有），
      旧占位也在 BindAltar 里补上了
- [x] 面板空状态文案去掉"（麦斯威尔雕像）"（`scripts/commands/musha_panel.lua`）
- [ ] 待测：`c_spawn("musha_advance_altar")` → 右键应出"查看任务"；无职业提示 / 有职业接 1 个转职任务 / 3 轮进阶

## 🏗️ 2026-09-12 技能页（只做战士）：白框纸感底 + 加点按钮
- 目标：技能页从"一行占位文字"变成**真技能树界面**；本轮只上 **战士** 两个技能
  （用户明确：技能书学习的那套【后面再做处理】）
- 战士技能树（组件 `self.warrior`，本来就有数据，只是没 UI）：
  - `combat_recovery` 战斗恢复：3 级，脱战后每秒回 0.11 / 0.18 / 0.22 点血（受击或攻击暂停）；
    解锁门槛 0 / 3 / 5 级；**消费者已存在**（OnLostTarget → DoPeriodicTask(1) 回血，L156）
  - `weapon_proficiency` 武器精通：3 级，武器伤害 +30% / +48% / +63%；门槛 3 / 5 / 7 级；
    **消费者已存在**（combat.externaldamagemultipliers "warrior_weapon_proficiency"，L547-558）
- 服务端（`musha_profession_component.lua`）：
  - [x] 新增 `SKILL_ORDER` + `SKILL_UI`（技能名 / 数值 → 人话描述 / fmt 函数）
        和 `GetSkillView()`：组装当前职业技能页数据（名字、等级、当前效果、下一级效果、
        需求等级、消耗、能否加点）
  - [x] `PushSettings()` 里加 `d.skills = self:GetSkillView()` —— 复用已有的
        userdata 推送通道，客户端 `md.skills` 直接可读
  - [x] 加分/升级后自动推面板：`UpgradeSkill` 成功 / `AddExperience` 升级 / `SetCarrerBase`
        / `SetCarrerSpecial` / `CompleteAdvance`（原来只有设置改动会推）
  - [x] 🐛 修 `UpgradeSkill` 里 `skill_point_cost[next_level]` 的 next_level **未定义**
        （读 nil 恒返回 nil）→ 自定义消耗从来没生效（背刺 2/4 点一直被按 1 点算）
- 客户端（`screens/musha_panel_screen.lua`）：
  - [x] 新 `MakePlusButton(parent, size, enabled, onclick)`：**粉红色框 + 白色加号**
        （加号用两根白杠拼，不依赖字体；禁用时整颗去色变灰且不挂 onclick）
  - [x] 技能页：**外层全白压边**（6px）+ **内层淡白书页底**（冷白 tint square.tex）
        + 内圈一道白细线；顶部"战士 · 等级 N · 可用技能点 M"；底部"技能书学习的技能 · 后续开放"
  - [x] `RefreshSkills(md)`：按 md.skills 重建行（名字 / 等级·需求·消耗 / 当前效果 /
        下一级效果 / 加点按钮）；左对齐文本用 `SetRegionSize + SetHAlign(ANCHOR_LEFT)`
  - [x] 加点按钮 → RPC `musha_skill_upgrade`（服务端那个 handler 已存在，直接复用）
  - [x] 🐛 修：清空技能行不能用 `w:Remove()`（Widget 没有 Remove，那是 EntityScript 的）
        → 换 `skill_body:KillAllChildren()`（照信箱页写法）。原报错：
        `:1049 attempt to call method 'Remove' (a nil value)`
  - [x] 🐛 修：文字位置算错 —— DST 的 Text 设了 region 之后，`SetPosition` 是**区域中心**，
        不是文字左缘（原版 consolescreen / morguescreen 都是 ± region_w/2 这么算的）。
        原来按"左缘=position"写 → 文字被算到卡片左外侧 ~210px（用户反馈"要往右移"）。
        现在 `SkillText()` 统一 `SetPosition(SKILL_TXT_X + SKILL_TXT_W/2, y)`，
        左缘 = 卡片左缘 + 40；尺寸/边距全提到文件头常量（SKILL_ROW_W/H/GAP/BTN/TXT_W/TXT_X）
- [x] 2026-09-12 加点按钮调色（用户："加点有问题 应该改成粉色加点按钮"）：
  - 底色 (0.99,0.90,0.93) 太白 → 看着像"白按钮描了条粉边"；改成明确粉底 `(0.98,0.72,0.80)`，
    框用深粉 `(0.92,0.30,0.45)` 压边，加号纯白加粗（7px）
  - 禁用态不再整颗变灰（灰了看不出是"加点"）→ 改成暗一档的粉 `(0.90,0.74,0.78)`
  - 禁用态**也挂 onclick**：原来不挂 → 点了毫无反应；现在由服务端拒绝并回一句
    "技能升级失败: 技能点不足 / 需要等级N才能学习"（RPC handler 里本来就有这句）
- ⚠️ 美术待补：整页现在是纯 square.tex 拼的占位（用户晚些补图）
- [x] 2026-09-12 **战士"战斗恢复"改成常驻 tick**（用户："脱离战斗后回血应当一直保持，写个task"）：
  - 旧写法：`OnLostTarget` 里起 `DoPeriodicTask`，`OnAttackOther`/`GetAttacked` 里 `Cancel()`
    → 被打一下任务就 Cancel，而"丢目标"事件不一定再来 → **回血永久停**（这是真 bug）
  - 新写法：组件构造时起一个**常驻 tick**（`self.healthtask = inst:DoPeriodicTask(REGEN_TICK, ...)`），
    每秒自检 `CombatRecoveryTick()`：服务端 + 战士 + 技能等级>0 + 活着 + 未满血 +
    没有攻击目标 + 距上次交手 > REGEN_COMBAT_GRACE(3s) → `health:DoDelta(heal)`
  - 交手打点：`OnAttackOther`/`GetAttacked` 里 `self.last_combat_time = GetTime()`（不再 Cancel 任务）
  - 常量：`REGEN_TICK = 1`（每 1 秒判定一次）、`REGEN_COMBAT_GRACE = 3`（脱战 3 秒后恢复回血）
  - ⚠️ 方法必须定义在 `Class(...)` **之后**（之前写会 `attempt to index nil`）
  - 数值提醒：技能表 level_effects 是 **每秒 0.11 / 0.18 / 0.22 点**（1 级≈11 秒回 1 点血），
    用户可能觉得"看不出来"——要明显得改技能表数值，不是改 task
- ✅ 语法校验升级：装了 `lua5.1` 用 `luac5.1 -p` 全量校验（比 luaparser 准，36 个 lua 全过）；
  靠它抓到本次补丁把 `Class(function() ... end, nil, {` 的 `end` 吃成了 `}`（报错在块末尾）
- ⏳ 后续：技能书学习路径（那 5 个主动技能数据在 `scripts/skills/musha_skill_data.lua`，未接）；
  其它职业（剑士/近卫/刺客已有树，法师/游侠/进阶职业没数据）；技能名走 STRINGS（现在硬编码中文）

## 🏗️ 2026-09-10 面板架构改造 A：HUD Widget → 真 Screen + ScrollingGrid（照搬明生）
- 起因：musha 面板原是 HUD Widget，任务区手搓固定 6 行，没滚动；滚轮被 OnMouseButton 当成鼠标键关面板
- [x] 新建 `scripts/screens/musha_panel_screen.lua`（Screen 版）：
      Class(Screen) + `TheFrontEnd:PushScreen`；任务区 = `TEMPLATES.ScrollingGrid`
      （自带滚动条/滚轮滚动/scissor 裁剪）；黑幕点击关 + 红叉关 + CONTROL_CANCEL(ESC/B) 关
- [x] 布局：ITEM_W=860 ITEM_H=78 VISIBLE_ROWS=6；list 位置 (-48,-125)
      → 首行中心 y=70、末行 -320，与旧布局一致；x 中心 -48（旧 ROW_X 32 + bg -80）
- [x] 行内字段改名 w.label / w.stat（避免覆盖 Widget 内置 self.name）
- [x] `scripts/widgets/musha_panel_registered.lua` 重写：不再 AddChild 到 HUD，改 ListenerForEvent → PushScreen；B 键开/关
- [x] 旧 Widget 版备份到 `_bak_20260910/musha_panel_screen.lua.widget_old`
- [x] 修复"滚轮关面板"根因：不再用 OnMouseButton 拦截，滚轮走 TrueScrollList 的 CONTROL_SCROLLBACK/FWD
- [ ] 待测：技能书右键开面板（B 键入口 2026-09-24 已移除）；任务多时滚轮滚动 + 拖动滚动条；黑幕/ESC 关闭
- 说明：旧的手搓"竖栏+黄色高条"装饰已被真滚动条替代（用户描述的就是滚动条）；滑入动画暂未迁移
- 明生参考：`mods/mingsheng/scripts/screens/mingsheng_teleportscreen.lua`（437行）+ `mods/mingsheng/scripts/prefabs/mingsheng.lua:92`
- [x] 滚动条默认常显：覆写 `self.list.RefreshView`，强制 `scroll_bar_container:Show()`；end_pos<=1 时滑块置顶（防除零 nan）
- ⚠️ [测试用] `musha_quest.lua` 顶部 `TEST_DAILY_COUNT = 8`（每日固定发 8 个测滚动，上限仍 DAILY_MAX=10）
      → **正式发布前必须改回 nil**，恢复走 mod 配置 3/4/5
- [x] 滚动条外观定制（取消三角/蜡黄竖轨/淡黄握把条）：
      scrollbar_offset 10→30（右移20）+ 容器再右移12上移20；隐藏 up/down_button + 手柄提示；
      竖轨 scroll_bar_line 宽 12 色 (0.62,0.54,0.33,0.82)；
      握把 position_marker = square.tex 36宽x23高，淡黄 (0.97,0.90,0.55)，中间 3 道白杠(1,1,1,0.9)；
      重置被原生设的 0.3 缩放；覆写 GetSlideStart/Range 用满轨
- [x] 滚动条再右移 22（容器合计 +34）；scrollbar_height_offset 0→20（竖轨上下各突出 10px）
- [x] 微调：容器左移 8.7、下移 8.7（累计 +25.3 / +11.3）；握把改款 = 深灰内框(0.32,0.32,0.32)
      + 上下两道淡黄外框(36x3, y=±10) + 中间 5 道白杠挤紧(22x1.6, 间距3, y=+6/+3/0/-3/-6)
- [x] 再调：容器左移 3（累计 +22.3/+11.3）；握把去灰(本体透明)回 3 道白杠 + 上下等长蜡黄框；
      竖轨(长条)改"之前说的设计"：黄灰深陷底(0.55,0.50,0.38) + 上下蜡黄框(0.88,0.78,0.48, 12x4)
      + 中间 5 道杠挤紧(12x2, 间距4, y=+8/+4/0/-4/-8)
- [x] 定版：竖条=蜡黄偏亮"孩童色"(0.85,0.74,0.40)，撤掉那 5 道杠；
      拉动的显示条(握把)=黄灰深陷底(0.62,0.56,0.42) + 上下蜡黄框(0.88,0.78,0.48, 36x3 等长)
      + 中间 5 道白杠挤紧(22x1.6, 间距3, y=+6/+3/0/-3/-6)
- [x] 回退+调色：握把改回"第三版"=本体透明(不盖) + 上下蜡黄框 + 5 道白杠；
      竖条暂定糖果亮黄 (0.97,0.82,0.42)（待"日本画彩虹糖果"参考图定稿）
- [x] 布局：任务列表(任务框)上移 6（list y -125→-119，滚动条随之上移）；
      竖条再右移 12（容器 +22.3→+34.3）；经验条(上面灰条+长条填充)整条右移 12 同步
      （exp_bg -15→-3，exp_fill -480→-468）
- [x] 任务列表再整体右移 4（list x -48→-44）；竖条容器同步抵消 -4（+34.3→+30.3）保持不动
- [x] 任务列表再右移 5、上移 6（list -44/-119 → -39/-113）；竖条反向抵消（+30.3/+11.3 → +25.3/+5.3）钉住；
      竖条颜色 → 淡黄像素星星感 (0.99,0.88,0.42)
- [x] 竖条颜色定稿方向：不要像素星星那种亮黄，就柔和淡黄/浅淡黄 → (0.98,0.91,0.64)
      整体风格：书页底 + 孩童风
- [x] 修面板经验显示 bug：exp_to_next 是"还差多少升级"(exp_table[lv+1]-exp)，不是本级总需求。
      面板原来拿它当分母 → 显示 "40/5"。改为 exp/(exp+exp_to_next) → "40/45"，进度条同步。
      服务端 exp_table={0,5,12,20,30,45,...} 累计制；level 只在 AddExperience 里 +1，逻辑本身没问题。
- [ ] ⏸【待定·用户暂缓】等级/经验自洽校正：是否在服务端每次读写经验时按 exp_table 重算等级。
      收益：数字永远自洽（不再出现 Lv.5 但 exp 40 < 45）。代价：旧档"虚高"等级会被压回（Lv.5→Lv.4）。
      用户说"暂时记录，等会看"。代码位置：musha_profession_component.lua UpdateExpToNext() / AddExperience()。
- 术语：竖条 = 轨道(track) = list.scroll_bar_line；拉动的显示条 = 握把 = list.position_marker。

## 📐 2026-09-10 面板多页化 + 局内设置系统（设计稿，未实现）
- 设计文档：`musha-panel-tabs-and-settings-design.md`（本目录）
- 要点：面板拆 **5 页**（主页/技能/信箱/设置/图鉴），共用现有 bookpage_bg 一张图；
  导航=右侧三角▶点开展开 5 项列表（现阶段纯文字，图标等画师）；技能页美术待定。
  做 world/player 两个设置组件 + ModRPC + 存盘 + 设置页 UI。图鉴页=所有装备规则总览。
- 分期：P1 组件+五页框架+设置页 → P2 信箱 → P3 图鉴 → P4 技能页(等美术) → P5 刷怪器。
- 待用户拍板：三角位置 / 权限 / 设置项清单 / 技能页形态 / 图鉴数据源 / 更新日志来源。

## 🏗️ 2026-09-10 P1 落地：面板五页 + 局内设置系统（代码已写，待进游戏验证）
**新增文件**
- `scripts/components/musha_world_settings.lua` — 世界级设置组件（挂 TheWorld，OnSave/OnLoad 随世界存档）
  SPEC：monster_spawn_enabled(bool) / monster_spawn_mult(0,0.5,1,2,3) / daily_quest_count(1..10) / exp_mult(0.5,1,2,3)
- `scripts/components/musha_player_settings.lua` — 玩家级设置组件（挂 musha 玩家）
  SPEC：hp_regen_mult(0.5,1,2,5) / mp_regen_mult(0.5,1,2,5) / show_debug(bool)

**改动文件**
- `modmain.lua` — ①AddPrefabPostInit("world"/"forest"/"cave") 挂世界设置组件（保证存档 Load 阶段已存在）
  ②InitMushaPlayer 补挂 musha_player_settings ③每日任务数改"先读世界设置 → 再读 modinfo"，范围放宽 1..10
- `scripts/components/musha_profession_component.lua` — 新增 `EnsureWorldSettings/PlayerIsAdmin/GetSettingsView/PushSettings/SetMushaSetting`；
  `AddExperience` 接 `exp_mult` 经验倍率
- `scripts/rpcs/musha_rpcs.lua` — 新增 `musha_set_setting`(scope,key,value；世界级校验 player.Network:IsServerAdmin())、`musha_request_settings`
- `scripts/screens/musha_panel_screen.lua` — 五页容器 + 右上三角(> / v)展开 5 项列表 + 设置页（7 行；bool=开/关按钮、choice=< 值 >、number=- 值 +）
  `SetActivePage(name)` 只 Show/Hide 不重建；`RefreshSettings(md)` 读 `md.settings`
- `scripts/components/musha_quest.lua` — `TEST_DAILY_COUNT` 8 → **nil**（交给局内设置）

**同步方式（关键）**：设置快照由 `PushSettings()` 塞进 **userdata 的副本**一起走已有的
`replica:DoUpdata → net_string dirty → PushEvent` 通道 → **没有新增任何网络变量**，不动存档里的 userdata。
开面板时客户端发 `musha_request_settings` 拉一次最新值。

**⚠️ 待进游戏验证 / 风险点**
1. 权限：`player.Network:IsServerAdmin()` 在**服务端**是否可用（用于判定房主/管理员）。若不生效 → 改判定（备选 TheNet:GetIsHosting + 用户 id 名单）。
2. `AddPrefabPostInit("world")` 是否真触发（world.lua 里 Prefab 名叫 "world"，但运行时世界是 "forest"/"cave" —— 已同时挂 forest/cave 兜底）。
3. 设置页 7 行位置（ROW_GAP=62, Y0=80）；导航三角 **(536,310)**、展开列表 (458,266)。
4. 三角用字符 ">" 表示（怕 bp50 没有 ▶/▼）；要真三角形得等美术。
   三角：蜡黄底 (0.70,0.62,0.42) + 白色细框 + 淡黄符号 (0.97,0.92,0.70)；70% 缩放；位置 (536,310)。
   展开列表行项：淡黄底 (0.96,0.90,0.62) + **白框**(4条 2px) + 深色字 (0.32,0.26,0.18)；
   **尺寸 114x40（原 150x52 的 76%）、行距 43**；字号仍 28pt 不缩；
   悬停底变亮 (1.00,0.97,0.80) 当反馈；当前页字深橙 (0.85,0.30,0.08)。
5. 设置页**没做滚动**（行少直接排）；以后加项超 7 行要换 ScrollingGrid。

**待办**：P2 信箱（changelog 表 + 滚动）/ P3 图鉴（装备表）/ P4 技能页（等美术）/ P5 刷怪器（怪物生成真正生效）

### ✅ 2026-09-10 P2 信箱页做完（用户口述设计）
- 用户澄清：那套"橙灰底 + 框 + 底部翻页 + 外部橙框条"是**信箱**的；**技能页另设计，不用底框**。
- 实现（`musha_panel_screen.lua` 的 `self.pages.mail`）：
  - ① 外圈**橙色框条**（4 条边，粗 6，色 0.88,0.52,0.18）
    尺寸演变（都按"每边各扩"算）：
      初版 760x456 → ① 左右各+20 / 高+30 / 下移13 → 800x486 (y=-13)
      → ② 左右各+28 / 上下各+40 / 再下移20 → **856x566 (y=-33)**（当前）
     内容起点 y=175；翻页在 -PAGE_H/2+28。
  - 第三次调（用户）：左右/上下再各 +10 → **876x586**；文字改成**真左对齐**；
    "1/1" 去掉，底部改成一排**可点页码** `< [1 2] >`；翻页按钮外观改成"三角那套"（蜡黄底 + 白框，
    用 `StyleLikeTriangle()` 统一刷）。
  - ⚠️ **DST 的 Text 光 `SetHAlign(ANCHOR_LEFT)` 是没用的**——必须同时 `SetRegionSize(w,h)`，
    否则 TextWidget 的 region = 字符串本身，文字会绕着自己的中心点摆 → 视觉上就是"居中/参差"。
    DST 自己全这么写（见 `screens/kitcoongamescreen.lua:77-80`、`screens/bugreportscreen.lua:43-45`）。
    左边缘 = `x - regionW/2`；本例 REGION_W=800、x=-2 → 左边缘 -402（框内半宽 432，留 30 边距）。
  - 因为设了 region，正文行长度要 ≤ REGION_W：已把最长那条日志缩短（"…每日任务数…改完立刻生效" → "…任务数量…"）。
  - ② 内层**橙灰底** (0.78,0.68,0.56,0.94)
  - ③ 内容容器 `mail_content`（RefreshMail 填）
  - ④ 底部**翻页**：`<  [1] [2]  >`（数字可点直接跳页；原 "1/3" 文字已删）
  - 第四次调（用户）：整体再扩 7/边 → **890x600**；文字整体上移 10（`mail_content` y 40→50）；
    页面数字缩小（页码按钮 28x22、字 16pt；`<`/`>` 44x26、字 20pt）。
  - 外框升级"魔兽UI质感"：用户嫌单条横线太简单 → 改成**三层描边 + 四角铆钉**
    （`FrameLines()` 工具：最外深棕黑 6px → 橙色主框 16px → 内侧金色高光 3px；四角 14x14 金铆钉）。
    ⚠️ 纯 square.tex 只能做"层次感"，真板甲质感得有美术贴图。
    内层橙灰底相应缩到 `PAGE_W-50 / PAGE_H-50`，避免压住边框。
  - 第五次调：**翻页按钮上移 14**（`PY = -PAGE_H/2 + 32` → `+46`）。
    原因：内层橙灰底只到 y=±275，而原 PY=-268 时按钮下缘到 -281，
    **溢出压在外框的橙条(±294~±278)和金色高光(±278~±275)上** → 按钮周围露出外框色，看着发脏。
    现在按钮范围 -267~-241，完整坐在橙灰底内。教训：任何落在信箱页里的控件，
    纵向必须留在 ±275 以内（金线内侧），否则会吃到底框。
  - 第六次调：`mail_content` y 50 → **53.4**（文字框再上移 3.4）。
  - 🐛 修 **hover 时按钮底色"爆出来"/整体变大**（翻页 `<` `>` + 页码）：
    根因在 DST `widgets/imagebutton.lua` —— `ImageButton` 默认
    `self.scale_on_focus = true`、`self.focus_scale = {1.2, 1.2, 1.2}`；
    而"只传一个贴图"的按钮 `SetTextures` 里 `image_focus = focus or normal` → 等于 normal，
    `OnGainFocus` 的判定 `image_focus == image_normal and scale_on_focus` **必然成立**
    → 鼠标一移上去 `self.image:SetScale(1.2,1.2,1.2)`，**只有底图放大**，
    而我们叠的 4 条白框是 child 子控件、不跟着缩放 → 底色块爆到白框外面。
    源码那一行上面 Klei 自己写着：`-- Common bug: you probably want scale_on_focus = false`。
    修法：`StyleLikeTriangle()` 里加 `b.scale_on_focus = false`；
    focus 色也从 (0.86,0.78,0.56,1) 收到 (0.78,0.70,0.48,1)（只微亮，不许跳变）。
    ⚠️ 设置页那些 `MakeTextButton` 直接建的按钮**没走** StyleLikeTriangle，同一个坑还在（用户未点名，暂不动）。
  - 第七次调：**外框改"条状金属"**（用户：框体大部分想要魔兽UI那种长方形条形的质感）。
    新增工具 `MetalBand(parent, w, h, inset, thick, r, g, b, steps, a)`：
    在同一段 inset 区间里拆成 `steps` 条细分，亮度按 `k = 1 - (i-1)/steps*0.55` 从外到内递减
    → 用多档纯色骗出"斜面 + 受光"的长条厚度感（square.tex 的能力上限）。
    信箱外框改为：深棕黑 5px 压边 → **橙主条 16px 走 4 档渐变** → **金高光 3px 走 2 档**；
    四角铆钉从纯金块改成"暗金块 + 顶部 3px 高光条"（像被光照到的金属钉）。
    ⚠️ 真魔兽 UI 是手绘 9-slice 贴图（金属纹理/渐变/描边），square.tex 做不到；
    要再上一档需程序生成 PNG 边框 → 用 DST Mod Tools autocompiler 编 .tex。
  - 用户拍板 **A**：条状金属**只做信箱**，任务框/设置页/技能页保持原样。
  - 第八次调：**设置页 7 行整体上移 30**（`ROW_Y0` 80 → **110**，`ROW_GAP` 62 不变）。
  - 第九次调：设置页再上移 24（`ROW_Y0` → **134**）；新增**橙灰底板** `set_bg` 780x500 @(0,-52)
    色 (0.78,0.68,0.56,0.94)（和信箱内层同色）；设置项文字全改**橙字** (0.85,0.32,0.08)
    （name / val 全亮，tag「世界/个人」淡一档 alpha 0.78）。按钮内部字保持不变（蜡黄底上橙字看不清）。

⏳ 用户点名但**尚未做**的待办（2026-09-11 上午）：
  1. **祭坛**（接取转职任务的地方）——用户"好像没做"。现状：用 `AddPrefabPostInit("statuemaxwell")` 给麦斯威尔雕像挂 musha_altar tag 占位，真正独立的"进阶祭坛" prefab 从未实现。
  2. **技能页**——用户"没做，晚上回来看看"。现在 `page_skill` 只有一行占位文字 `技能页 · 另设计（无底框）`。
  3. **图标**——导航三角/五个页面的图标还没加，用户"等会加上"。
- 内容源：**`scripts/musha_changelog.lua`**（独立文件，面板 `pcall(require, "musha_changelog")` 读取，读不到时用内联兜底）。
  当前只有 **1 条 = 0.7.6 上线**（用户要求"写一段，就写上线系统，明确 Musha 系统 0.7.6"）。
  格式：`{ ver=, date=, lines={...} }` 倒序数组。`MAIL_PER_PAGE = 3` 决定每页条数（"长度限制由我定"）。
- 方法：`RefreshMail()` 重绘一页；`MailTurn(dir)` 翻页；切到 mail 页时自动 RefreshMail。
- 技能页占位文案改成"技能页 · 另设计（无底框）"。

**🐛 2026-09-10 修复：切页不显示内容（信箱/设置/图鉴/技能全白）**
- 现象：用户报"信箱里面的内容显示不出来"。
- 根因：`SetActivePage()` 里一律 `for _, w in ipairs(group) do`。
  `self.pages.home` 是**一组 widget 的数组表**（能遍历），但 `.skill/.mail/.set/.dex` 是
  **单个容器 Widget**（`NewPage()` 返回的）—— 对 Widget 做 `ipairs` 时 `w[1]` 是 nil，
  循环体一次都不执行 → 这些页面**永远保持 NewPage 里的 Hide() 状态** → 框在、内容不在。
- 修：用 `group.Show` 是否存在区分两种形态（数组表 → ipairs；单个 Widget → 直接 Show/Hide）。
- 教训：`self.pages` 里混了两种数据结构，遍历前必须先判类型。
- 内容源补充：`scripts/musha_changelog.lua` 恢复成 **4 条**（0.7.6 上线 + 0.7.3~0.7.5 历史，倒序），
  面板内联兜底也同步成 4 条，并在 require 失败时 `print` 一条警告方便定位。

**🐛 2026-09-10 修复：组件里不能用 `GLOBAL`**
- 现象：每天天亮（worldstate `isday` → AddExperience）崩
  `musha_profession_component.lua:694: variable 'GLOBAL' is not declared`（strict.lua 拦的）
- 根因：**组件文件的 env 里 `GLOBAL` 未声明**（和 modmain 相反）。组件里要用**裸** `TheWorld` / `STRINGS`。
- 修：`GLOBAL.TheWorld` → `TheWorld`（AddExperience + EnsureWorldSettings）；
  顺手把原本就存在、同样会炸的 `GLOBAL.STRINGS`（GetJobName / GetAdvanceJobName）也改成 `STRINGS`。
- 速查：`grep -rn "GLOBAL\." scripts/components/*.lua` 应恒为空。
- 已把这坑写进 skill `dst-modding` → `references/dst-mod-env-and-config.md` §4.1

## 🔴 2026-09-10 "不显示"根因修复（面板无数据）
- [x] **根因：modmain 丢了 `AddReplicableComponent("musha_profession_component")`**（git 版有、重写版漏了）
  → 客户端根本不创建 replica → 面板 `owner.replica.musha_profession_component` 恒 nil → 整个面板读不到数据
  → 已补回（RPC注册之后，Safe 块）
- [x] modmain InitMushaPlayer 早退 bug：旧档玩家已有 profession 组件时整个函数 return，
      quest 组件不会补、每日任务不发放 → 改为逐组件 if not exists 补加 + `_musha_daily_inited` 防重
- [x] 面板读新字段：UpdateQuestRows(md) 读 daily_quests[] + advance_quest（原来还读已废弃的 quests_for_advance）
- [x] 面板任务行 3→6 行（每日最多5 + 转职1），行距 78，字号 34/30；每日黄字、转职红字带【转职N/3】前缀
- [x] quest.SyncToPanel 补同步任务名 `n`（面板不用再查 id 表）
- [x] RPC 注册修正：`AddModRPCHandler(namespace,name,fn)` 是3参（原来只传2参报 lower 错）；
      `GetModRPCIndex` 不是 DST API → `GetModRPC("musha", name)`。修 musha_rpcs.lua + modmain + skillui
- [x] 删 modmain 里死代码 `_G.__musha_open_skill_panel`（_G 在 modmain 环境不可用，真开面板走 PushEvent）
- [ ] 待测：重进游戏，面板应能显示职业/等级/经验 + 每日任务 4 个

## 🎨 2026-09-10 面板任务区视觉迭代（已改，待验证）
- [x] 滑入方向：自下而上 → **从右往左推送**（from_x=target_x+320 → target_x，逐行错开0.08s）
- [x] LV 徽标 + Lv 文字 右移 22px（234→256），再右移 8（256→264）
- [x] 任务行整体右移 12（ROW_X=12）
- [x] 任务行底框：每日黄底框(0.85,0.68,0.25,0.28)；转职灰底框(0.42,0.40,0.38,0.55)+顶部红条(0.85,0.22,0.18)840x6；完成行绿底
- [x] 每日"普通任务"行顶部白色小横条（1,1,1,0.7）840x4，宽度跟随 ROW_W 常量
- [x] 每日行文字改深色(0.28,0.2,0.1)适配黄底；转职行文字红色
- 底框/白条/红条宽度统一取 ROW_W=840，改尺寸一处生效
- [x] 任务行再右移 20（ROW_X 12→32）
- [x] ~~任务区整体外框~~ 理解错了，用户指每行各自一个框 → 已撤
- [x] 每个任务行独立"框体"：每行 4 条细线描边（叠在背景板上，FT=3），随行类型变色——每日金/转职红/完成绿；顶部标记条（白/红）下移到 y=26 避免压框线
- 结构：每行 = bg(背景板) + frame(4条描边) + bar(红条)/barw(白条) + name + status
- [x] 行框加粗到 4px + 外扩 4px 放大（FT=4, FOFF=4）；框线随类型变色（金/红/绿）
- [x] 右侧竖栏：x=388，y 106→-400，宽 12，蜡黄深陷色 (0.62,0.54,0.33,0.82)
- [x] 竖栏顶部黄色高条：23 宽 x 36 高（"拉伸任务"装饰握把），色 (0.95,0.82,0.35)
- [x] 修滚轮关闭面板 bug：OnMouseButton 原来任何键按下都 HidePanel，改为只有左键(1000)才关；滚轮(1003/1004)/右键不关
- [x] 竖栏+黄条再右移 12、上移 8（VBAR_X 388→400，TOP 106→114，BOT -400→-392）

## 📋 2026-09-10 任务扩编方向（已确认，未实现）
- 目标规模：当前 13 种 → 扩到约 30，后续规划到 50
- 新增 1：季节活动任务（秋/冬/春/夏专属，每日发放只抽当前季节+通用）
- 新增 2：移动散步任务（move 类型，服务端 2~3s 采样位置累计距离，分档 3000/6000/10000）
- 新增 3：季节通用细节——跨季未完成的季节任务作废（同 discover 规则）待定
- 搁置：职业联动任务（技能击杀/背刺/战斗恢复类）
- 候选清单：浆果/农作物收获(秋)、海象/冰块/保暖(冬)、花瓣/淋雨/蛙雨(春)、灰烬/西瓜/夏日装(夏)、行走(通用)
- 实现要点：MUSHA_QUEST_TYPES 加 season 字段；抽取按当前季节过滤；move 用位置轮询；pick/wet/frog/walrus 等新事件接入

## 📋 2026-09-08 任务系统重构第①步：服务端双任务模型（完成，语法通过）
- [x] musha_quest.lua 整体重写（备份 .bak_0908）：daily_quests 数组(可累积上限10) + advance_quest 单任务(3轮) 两套独立
- [x] 每日发放：OnNewDay → discover 未完成作废 → survive +1 → 补发至配置数(3~5默认4)；玩家初始化1秒后首日发放
- [x] 进度推进统一 ProgressQuests(match_fn)：每日+转职都检查；8类事件全部走新逻辑
- [x] 转职：AcceptAdvanceQuest(目标职业) 雕像接取每次1个，难度池随轮次 1→2→3 递进，跳过 heal_skill；第3轮完成 CompleteAdvanceQuest → carrer_special + 发 musha_skillbook
- [x] 面板数据字段：pc.userdata.daily_quests[{id,p,t,done}] + advance_quest + advance_round（旧 quests_for_advance 清空兼容）
- [x] modmain：雕像改 AcceptAdvanceQuest 单轮（去掉一次接3个旧逻辑，等级门槛暂放开）；发现轮询去掉 active 依赖；玩家初始化首日补发
- [x] musha_panel.lua 命令：quest.active → HasActiveQuest()，pc.mydata → userdata
- [ ] 待做②面板 UI：任务区改 ScrollingGrid 滚动（每日黄底行在上、转职灰框红条行在下同一列表），每日发任务时滑入
- [ ] 待测：每日任务自动发4个可累积；跨天 discover 作废；雕像接转职一次1个、3轮进阶
- [ ] 遗留：heal_skill 任务排除中（技能系统 _musha_skills.lua.bak 未启用）；旧 profession 组件转职方法(SetAdvanceQuest等)已无调用方但保留未删

## 📋 2026-09-08 任务系统最终设计（已定稿）
- [x] musha_action 组件补 InteractScene 方法（原 SCENE 动作调用它但方法缺失 → 点击祭坛即崩）
- [x] quest 组件补监听：musha_item_collected（modmain 已在发，collect 类任务现在能推进）、WatchWorldState startday（survive 类任务推进）
- [x] OnAreaTrigger 空方法补上（backlog #5 定时炸弹拆除，实际发现任务走 modmain 5s 轮询）
- [x] AbortQuests pc.mydata → pc.userdata（原 nil 索引崩）
- [x] StartQuests 接任务后同步写入 pc.userdata + 推送 replica（面板能显示任务列表）
- [x] MarkQuestDone / CompleteAdvance 补 DoUpdata 推送（面板 done 状态/进阶结果能刷新）
- [x] 进阶祭坛占位：AddPrefabPostInit("statuemaxwell") 挂 musha_altar tag + musha_action（原祭坛 prefab 从未实现）；交互链：SCENE 右键"查看任务" → 检查(有职业/未进阶/无进行中/≥7级) → 抽池2任务(跳过 heal_skill，技能系统 .bak 未启用) → 接任务
- [x] 任务列表放面板：任务区改造为 3 行容器(Widget row)，接任务瞬间逐行自下而上滑入(错开 0.08s)；面板关着时挂 pending，ShowPanel 时补播
- [x] 进度版任务显示：quest 每次进度推进(8 处)同步 quests_advance_progress{p,t} → 面板行尾显示 x/y；完成变 ✓
- [x] 空状态引导按职业分：无职业→"使用职业书开启职业之路"；有职业未接→"前往进阶祭坛（麦斯威尔雕像）接取"
- [x] OnLoad 一致性：读档后 quest 任务 ID 同步回 pc.userdata（旧档兼容）
- [ ] 待测试：进游戏 spawn statuemaxwell，右键接任务 → 面板任务行滑入 + 进度刷新 → 完成 3 任务 → 自动进阶
- [ ] 遗留：heal_skill 类任务因技能系统(_musha_skills.lua.bak 未启用)被抽池排除，技能系统恢复后再启用

## 📋 2026-09-08 任务系统最终设计（已定稿，待实现）
- 任务模型两套独立：
  - 每日任务：每天自动发 N 个（N = modinfo musha_daily_quest_count，3~5 可配默认4），可累积，列表最多保留 10 个（满 10 不再发/挤掉最旧待定）
  - 每日任务作废规则：探索/发现类(找到龙蝇/格罗姆/海象营地等 discover) 隔日作废；其他类型(击杀/制造/收集/锅/存活) 保留到做完
  - 转职任务：雕像(祭坛)接取，一次只接 1 个(显示当前轮次)，共 3 轮，第 3 轮完成 → 进阶
- 面板任务区 = 同一滚动列表(ScrollingGrid，参考明生传送 mingsheng_teleportscreen.lua)：固定大小框 + 下拉滚动 + 滚动条
- 行视觉区分：
  - 每日任务行：淡黄底板，右上角淡黑色小底板标"普通"
  - 转职任务行：淡灰主框，框顶同宽小红条，右侧标"（转职任务）"，行内显示第 x/3 轮
- 接取/发放时整行滑入动画（已有 PlayQuestSlideIn 可复用）
- 需要 UI 框体：是（滚动框限定范围，防行溢出卡片）
- 每日任务数量 modinfo musha_daily_quest_count 已加(3~5 默认4)——用户后改"每日抽3个"，实现按 3，配置项保留待用户定

## 📋 2026-09-08 任务 UI 视觉方案（并入上方最终设计）

## 📋 2026-09-08 用户新设计方向（未实现，等确认）
- 每日任务：每天抽 4 个（配置 3~5 可选，默认 4，modinfo 已加 musha_daily_quest_count）+ 当日时限逾期作废
- 雕像(祭坛) 仅限【转职任务】接取用——每日任务不走雕像、自动发放
- 转职任务：从雕像接，一次一轮只做一个（当前实现是一次接 3 个全做完才进阶）
- 待用户确认细节后重构：两套任务的存储/面板共存显示/转职判定时机
- 状态：任务系统主干已修通(接取→进度→完成→进阶)，改"每日N个+雕像接转职(一次1个)"是上层玩法重构

## 任务系统（musha_quest.lua）待修（老条目）

### 接了永远卡死的 4 个任务（handler 无调用点）
1. 存活5天（survive）— ✅ 已修 2026-09-08（WatchWorldState startday）
2. 获得七个噩梦燃料（collect）— ✅ 已修（musha_item_collected 监听）
3. 收集三色宝石（collect_gems）— ✅ 已修（同上）
4. 使用回复技能达到5次（heal_skill）— ⏳ 依赖技能系统（.bak 未启用），抽池已排除

### 潜在崩溃
5. musha_quest.lua:111 监听 "areatrigger" → OnAreaTrigger 未定义 — ✅ 已补空方法

## 代码卫生
6. modmain.lua 大量 [Musha TRACE] 调试 print — 未动（暂留定位用）

## 功能缺口（已知，非 bug）
7. scripts/skills/musha_skill_data.lua：MUSHA_SKILLS_MAGE / MUSHA_SKILLS_RANGER 还是 TODO，只有刺客/战士有数据。

## 职业面板（musha_panel_screen.lua + musha_skillui.lua）待修
- [已改 2026-09-03] bookpage_bg 换横版图(1232x832)，两处代码横版化：skillui 卡 592x400、panel 卡 503x340；删代码叠边框/角星/假头像/假MP条；关闭=透明点击区盖图上红叉（panel 214,133 / skillui 250,158，按图微调）
- 遗留：图上"豆包AI"水印+右侧装饰按钮列未清（素材处理）；panel 卡位 x=-340 横版后待用户进游戏确认；横版坐标按图内元素估算，需截图微调

---
审计时间：2026-09-01，版本 0.7.6
