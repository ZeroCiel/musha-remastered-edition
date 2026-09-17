# Musha 短卡（2026-09-14）—— 新会话只读这张，**别整读 musha-log-2026-09.md**

> 用法：开工先扫「队列」→ 按「命令」跑校验 → 需要历史/踩坑细节再 `grep` 档案（`musha-log-2026-09.md`）。
> 维护规则：新内容写这张；被替换掉的老条目搬进档案，别删。

## 项目
`D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha`（作者的 DST mod，作者 Ciel/雪儿）
面板 = Screen + ScrollingGrid，导航 7 页：主页 / 技能 / 装备 / 信箱 / 设置 / 礼包 / 图鉴

## 📄 相关文档（2026-09-17 新增两份）
- `musha-药剂师大锅-design.md` — 药剂师（法师分支）大锅：设定图 9 条调整清单 + 素材规格 + **771 行现成抄本** `references/norse_mythology_portablepot.lua`（官方 `stewer` 组件）+ 分 P1~P4
- `musha-职业估期与排期.md` — 近卫/法师线：**设计要求 vs 代码现状对照表** + 估期（近卫最小 2.5~3.5 天 / 全套 7~9 天；法师线 5~7 天起，全套 16~22 天）+ 关键路径
- ⚠️ 近卫**盾机制（MP 当护盾）全项目 0 行**；元素法师/药剂师 0 行；`class_traits.mage/elementalist` 只有数值雏形

## 📌 队列（2026-09-14 收工状态）

### ★ 2026-09-17 祭坛改版（已写码 + 语法校验全过，**待进游戏实测**）
【用户要求】"打开祭坛发现里面的卷轴才能接任务，不是触碰祭坛那一下，多走一步，仪式感"
- 新流程：右键祭坛（动作 **MUSHA_OPEN_ALTAR** "打开祭坛"）→ 打开**祭坛容器**（1 格）
  → 里面躺着 **转职卷轴 `musha_advance_scroll`** → 取出来 → 右键卷轴（**MUSHA_UNROLL_SCROLL** "展开卷轴"）→ 才接取本轮任务
- ★ 架构（用户 2026-09-17 拍板"容器要按 Musha-beta 的写法、加在自身的建筑上"）：
  · `scripts/musha_containers.lua` — 容器参数集中登记（照 beta 的 `main/05.Musha_Containers.lua`，本地留档 `references/musha_beta_containers.lua`）
  · `scripts/prefabs/musha_advance_altar.lua` — **容器组件 + WidgetSetup + 开/关动作都在建筑自己身上**（照 beta 的 forge/arrowrest/icebox）
  · `modmain.lua` 祭坛段只留"后厨"：`GLOBAL.MUSHA_AltarRefillScroll`（补卷）+ `GLOBAL.MUSHA_AltarUseScroll`（接取）
- 改动文件：modmain.lua、scripts/musha_containers.lua（新）、scripts/prefabs/musha_advance_scroll.lua（新）、
  scripts/prefabs/musha_advance_altar.lua、scripts/actions/musha_actions.lua、scripts/components/musha_action.lua、
  scripts/languages/{chinese,english}.lua
- 动作改名：`MUSHA_QUEST_INTERACT`("查看任务") → `MUSHA_OPEN_ALTAR`("打开祭坛")；新增 `MUSHA_UNROLL_SCROLL`("展开卷轴")
- 补卷规则：空坛 + 该玩家【有基础职业 / 未进阶 / 身上没有没用掉的卷轴 / 当前没有在跑的转职任务】→ 补 1 卷（台词"祭坛深处…"）
- ⚠️ 旧的"右键祭坛直接接任务"**已删除**（`OnAltarInteract` 整段没了）
- ⚠️ **旧占位兼容已删除**：以前所有 `statuemaxwell`(麦斯威尔雕像) 都被当祭坛（`AddPrefabPostInit` 外挂），
  现在不挂了 —— 老存档里那座雕像就是普通雕像，重新造一座进阶祭坛即可
- ⚠️ 卷轴**接取失败不消耗**（等级不够会说"需要 5 级才能接取转职任务"）
- 待实测：①开坛有没有卷轴 ②拿卷轴→展开→任务进面板 ③第 2/3 轮再来还给不给 ④卷轴满地丢会不会重复给
- ⚠️ 美术：卷轴目前 = **原版莎草纸 papyrus 占位**（贴图+图标）；用户 2026-09-17 提醒"职业书图标/美术也没更新"——
  本次**一行美术都没改**（只动代码）。职业书美术现状：只有 warrior/mage/ranger/rogue 四本（png 5月、tex 9-04），**进阶职业（剑士/近卫…）的图标/职业书美术还没有**
1. ✅ **【已完成 2026-09-14 19:55】月牙方向图（对称"光斩"版）已切上线**
   素材链：`exported/crescent_cyan/make_lightslash.py`（画**关于飞行轴严格对称**的光弧，上下不对称 0.00%）
   → `python exported/crescent_cyan/make_dirs.py crescent_light.png`（派生 8 方向 + scml）
   → 用户用 DST Mod Tool 导 `anim/crescent_cyan8.zip`（2.7 MB，19:53）
   → `musha_slash_qi_fx.lua:28` `FX_ART = "cyan8"`（**已切**）
   · ★ 2026-09-14 修掉"8 方向整体歪"的根因：`make_dirs.py` 原来靠 `analyse()` 的"质心−两尖中点"**估**底图凸面朝向，
     对弓形弧有 ~20° 系统偏差 → 8 张图**一致偏 ~32°**（屏幕上就是"整体歪"）。现在 CONFIG 里 **`BASE_ANGLE_DEG = 0.0` 显式指定**
     （别删！我们的图画成朝 +x，这数值是已知量）。自检：`python check_dirs.py`（实测偏差 从 +32° → +1~10°，大部分 1~3°）
   · 旧的非对称版全套备份：`exported/crescent_cyan/dirs/_old_asym/`（8 张 png + scml + 旧 zip）
   · 进游戏若发现：整体偏角 → `make_dirs.py` 的 `PHASE_DEG`；45° 整数倍的偏移 → `FX_DIRS` 那边 `DIR_START_DEG`（不用重导）；
     顺序反了 → `DIR_CCW`；压扁程度 → `K`（默认 0.5）
   · 想改光斩形状 → `make_lightslash.py` 顶部 CONFIG（XS/YS 扁宽↔瘦高、E 厚度、GLOW* 辉光）→ 重跑两步
2. 【进游戏实测】剑气斩全链路：**前提 = 剑士 + 角色 3 级 + 技能页加点学会「剑气斩」**（没学 → 右键不进圈）
   → 右键第一下进瞄准圈 → 点地出「剑气斩」→ 抬手(atk_pre→atk) →
   月牙直线飞（速度 22.5）→ 命中掉血 + 炸开 + 12 粒子 → **能量球掉 18 点** → 冷却 6 秒（rechargeable）
   ★ 冷却期**右键完全没反应、不弹字**；能量不够 / 没学技能时**同口径静默**（右键不进圈）；月牙朝向应沿飞行方向
   ★ 加点后（7/12 级）能量应变成 16 / 14；存档重进等级不丢

2a. 【⏳ 2026-09-14 v10b 已改，待重测】剑气两个体感 bug：
    · 「看起来像从地上发出去」= 特效那行 `SetOrientation(ANIM_ORIENTATION.OnGround)` 把贴图**平铺在地面**上
      → 已改成**不调这个方法**（用引擎默认朝向 = 面向摄像机 = 立着飞）。
      ⚠️ **坑：U59 这个版本 `ANIM_ORIENTATION.Billboard` 是 nil**，写 `SetOrientation(ANIM_ORIENTATION.Billboard)`
      直接崩（calling 'SetOrientation' on bad self）。想立着就**别调**，或 `ANIM_ORIENTATION.Billboard or ANIM_ORIENTATION.Default`。
      ⚠️ 连带：默认朝向**不吃 Transform:SetRotation** → 月牙朝向完全靠方向图（8 张），单图不顶用。
    · 「不会击中目标」= 两个高度坑（都在 3D 判定上）：
      ① 落点靶子 `marker` 高度写死 0，而出手点是 `LaunchOffset(1, 1.25, 0)` → 最近也差 1.25 > hitdist 1.0
         → **永远判不中**（飞满射程当 Miss）。已改成靶子 y = 角色 y + `fx.musha_launch_y`（新字段）。
      ② `TheSim:FindEntities(x,y,z,r)` 是 **3D 球**，球心用了 fx 自身高度 1.25 → 地面判定圈 1.6 缩成 1.0。
         已改成用 `y=0` 扫怪。
    · 待定：现有 8 张方向图是**按"贴地投影补偿"**生成的 → 立着飞时朝向会偏。测完若确认歪，
      照 `references/directional-art-projection-compensation.md` 关掉补偿重生成（顺带按用户草图重画月牙形状）。

2b. 【发布前】技能页核对：剑士树应显示「剑气斩」+「我，活着」两条，加点按钮可点、扣技能点

2n. 【✅ 2026-09-16 三处改动】①伤害真凶 ②冷却改按等级 ③图鉴缩小+标题上排
    · ★★ 伤害「只有 20.2」真凶：`externaldamagemultipliers:SetModifier` 要的是**倍率**
      （原版范例 mermking_gear_buffs.lua 传 1.05），我们传了**加成值本身**（精通 0.48）
      → 伤害被乘 0.48（42 × 0.48 = 20.2 与日志一致，越精通越弱）。
      已修两处（都传 1 + effect）：`musha_profession_component.lua` 的 warrior_weapon_proficiency、
      saber_hunt_bonus。⚠️ 同类可疑未改（等用户发话）：guardian 的 iron_will 传给
      `externalabsorbmodifiers` 传 0.25+增益（那是"受伤倍率"→ 实际减伤 60~75%）、
      life_leech 传给 externaldamagemultipliers（生命偷取不该走伤害乘区 → 近卫伤害会被打到 5%）。
    · 冷却改按技能等级：`musha_weapon_skill.lua` 新增 `COOLDOWN_BY_LEVEL = { 12, 9, 7.6 }` +
      `GetCooldown(doer, def)`（单武器覆盖用 def.cooldowns）；兜底 COOLDOWN 6 → 12。
    · 图鉴：DEX_W 840 → 760、DEX_VISIBLE 4 → 3；标题原来被 PageTip 落在 (0,0) 页面正中
      → 挪到 (0,248)；列表 y -108 → -20（3 行 ×128 = 384，占 -212..+172）。
      dex 文案里的冷却数字同步改成 12/9/7.6。
    · 月牙"竖着"的滚转对照图：桌面 `光斩滚转对照_20260916.png`（roll 0 / -90 / +90 三版）等用户挑。
2m. 【✅ 2026-09-16 崩已修】生命树枝「每 24 秒 +0.1 精神」那条周期任务崩：
    `o.components.sanity:IsDead()` —— **sanity 组件没有 IsDead**（只有 health 有）→ 必崩
    "attempt to call method 'IsDead' (a nil value)"。已改成用 health 判死（跟回血那条同口径）+ 保留 playerghost 检查。
2l. 【✅ 2026-09-16 图鉴框框位置已修】`musha_panel_screen.lua` 只动两个数：
    · `self.dex_list:SetPosition(-20, -108)` → `(0, -108)`：卡片外框（848 宽）原来占
      -444..+404（行宽从 ITEM_W 860 改 856 时位置没跟改）→ 左框线跑出内页白底 16px、右边空 24px；
      现在左右各 4px 对称。
    · `scrollbar_offset` 30 → 10（x 右移 20，滚动条绝对位置不变）。
    · ⚠️ 隐患（**未改，等用户发话**）：DEX_VISIBLE=4 × widget_height 128 = 512 高，
      内页白底只有 566 高还要留标题/底部说明 → 图鉴条目到 4 条以上时第 4 行会掉出白页底边。
2k. 【⏳ 待重导 + 实测 2026-09-16 22:****】剑气斩定稿方案（引擎挑面放弃，改点名播）
    · 实测判读（用户 01:09 日志）：两次施法旋转都对（-165.5°→世界165.5°=dir4；103.6°→256.4°=dir6）
      → 飞行方向已正常；但"引擎挑面"**挑错了**（月牙朝向怪）
    · 决定性证据：原版 4044 个脚本里**没有任何一处**用带后缀的名字 PlayAnimation
      （扫 `PlayAnimation("*_(up|down|side|...)")` = 0 命中）→ 后缀只是编译期标记，
      运行时只能靠引擎按旋转挑面，而那层映射本机无法验证 → **放弃引擎挑面**
    · 现在：`USE_ENGINE_FACING = false`（默认）；scml 动画名改回**无后缀点名声** `slash_dir0..7`
      （生成器 `crescent_gen.py` 也同步改了）；方向 = `DirIndexFromRotation(引擎旋转)`；
      动画 = 代码点名播（ART.cyan8.dirs 已更新）
    · ★ 另一个自埋的 bug：分桶公式我写成 `floor((b+22.5)/45)`，而素材格中心是 `45k+22.5`
      → 每格上半段整整偏一格（最大 45°）。已改回 `floor(b/45)`
    · 用户要做：用桌面 `光斩素材_第4版_20260916\crescent_cyan8.scml`（名字已是 slash_dir0..7）
      重导 → 覆盖 `anim/crescent_cyan8.zip` → 打 8 方向 + 贴日志（应打 `方向图 → slash_dirX`）
2j. 【⏳ 待重导 + 实测 2026-09-16 21:35】剑气斩：素材换第 4 版 + 修掉"旋转改飞行方向"
    · 素材：改用 `crescent_variants.py` **最底下那版（第 4 版 厚版+零辉光）**；参数已搬进
      `crescent_gen.py`（E=138 = 0.4182R、YS_TOP 0.95 / YS_BOT 1.15 = 上窄下宽、零辉光）
      → 重跑生成 `exported/crescent_moon/`（8 张 dir + scml，官方名 slash_*）；旧素材备份
      `exported/crescent_moon/_bak_细新月_20260916_2130/`；预览图桌面 `光斩新素材_20260916.png`
    · ★★ 真凶（我改坏的）：DST `Physics:SetMotorVel` **沿实体自身旋转飞**（locomotor.lua:723 /
      projectile.lua:170+458+289 三处证据）→ 我为挑面去 `SetRotation(自算角)` 把**飞行方向改了**
      （日志实测旋转全 0.0° = 全朝一个方向飞）。已修：引擎模式下服务端**一个字都不碰旋转**，
      只 `PlayAnimation("slash")`；方向序号改成从引擎旋转反推（`DirIndexFromRotation`），只给客机挑面用。
    · ⚠️ 引擎模式**不能用 FX_ROT_OFFSET 修朝向**（会连带偏航）→ 偏 45° 整数倍就改 `PHASE_DEG` 重出素材
      或对调 scml 里 slash_* 名字重导。详见 skill `references/official-multi-facing-packing.md` 第 7 条。
    · 小事故：生成器路径写错（MSYS `/d/...` 喂给 Windows python）→ 多出 `D:\d\SteamLibrary\...` 复制目录，
      内容已搬回，那个目录等用户发话再删。
2i. 【⏳ 待用户重导 + 实测 2026-09-16】剑气斩已切「官方多面向（引擎挑面）」方案：
    · 规则来源：官方编译器 `Don't Starve Mod Tools/mod_tools/tools/scripts/buildanimation.py`
      （后缀 _down/_side/_up/_upright… → 编译器写「朝向位掩码」，名字去后缀；
       引擎 = 基础名 + 当前朝向掩码匹配；官方 boat_cannon 就是 PlayAnimation("idle")+SetEightFaced()）
    · scml 已改名（图没动，原文件备份 `_bak_scml_anim0_20260916.scml`）：
      `exported/crescent_moon/crescent_cyan8.scml` → slash_downright / slash_down / slash_downleft /
      slash_left / slash_upleft / slash_up / slash_upright / slash_right（脚本 `_tools/official_facing_names.py`）
    · lua：`musha_slash_qi_fx.lua` 顶部 `USE_ENGINE_FACING=true`（false 回退旧「代码选图」，不用重导）、
      `FACING_ANIM="slash"`、`FACING_DEBUG=true`（实测完改 false）；fn 里加了 `Transform:SetEightFaced()`
    · **用户要做**：Mod Tool 打开上面那个 scml → 导出 → 覆盖 `anim/crescent_cyan8.zip`；
      进游戏放剑气斩打 8 个方向，把日志 `[Musha] 剑气斩 引擎挑面：dirX 旋转=..° → 实际播 slash_XXX` 贴回来
    · 若整圈偏 45° 整数倍 → 只改 lua `FX_ROT_OFFSET`（不用重导素材）
    · 参考文档：skill dst-modding / `references/official-multi-facing-packing.md`
2h. 【参考资料 2026-09-16】官方多面向怎么打包（拆 boat_cannon 实测）→ skill dst-modding/`references/official-multi-facing-packing.md`：命名 `<动作>_<朝向>`（官方只 5 个后缀 down/downside/side/upside/up）、代码只写 `PlayAnimation("idle")`+`Transform:SetEightFaced()`、同一个 symbol 第 N 张图 = 第 N 个朝向、z_index 每朝向单独重排、同图 angle=-180 复用当另一侧；
    渲染对照图 `exported/boat_cannon_ref/官方boat_cannon_朝向表_20260916.png`（桌面也有）；工具 `exported/_tools/boat_scml_render.py`（纯标准库按 scml 拼装，可复用做我们素材的预览/校验）
2e. 【⏳ 2026-09-14 用户报 / **明天改**】剑气斩剩下三个问题（用户原话）：
    · **✅ 大小已定 0.50**（用户「太大」0.90 → 「太小」0.25 → 定 **0.50** ≈4.8 单位 ≈ 角色 2.8 倍，
      对齐用户给的洛克人 X5 觉醒 Zero 绿月牙比例）
    · **✅ 「老是像往下飞」已定位并修**（用户判断"是画的问题"——其实**是生成脚本抄错符号**）：
      生成脚本里"世界方向→屏幕方向"的 y 分量原本是负号（旧脚本遗留）→ 等价于把画面沿水平轴镜像
      （角度 α → -α），**不动的只有 α=0/180，也就是世界 135°/315°** —— 而用户实测"**只有左下对**"，
      左下正好是世界 135°，**就是这个不动点**。→ 符号改回正号、8 张已重新生成。
      旧那套歪的备份在 `exported/crescent_cyan/_bak_wrongdir/`。**需要用户重导一次 scml**。
    · **⏳ 「到距离不会消失」仍未查** → 飞满 FX_RANGE(12) 应走 OnMiss → Cleanup；
      怀疑点：OnMiss 没被调 / Cleanup 里 marker 无效提前 return / 3 秒兜底 DoTaskInTime 没生效
    · 「正经按原设来做贴图」→ 生成脚本 `exported/_tools/crescent_gen.py`（顶部 CONFIG 调形状/颜色/辉光）

2g. 【⏳ 待做 / 用户 2026-09-14 定】装备系统 + 发布节奏：
    · **装备页已从面板导航隐藏**（`musha_panel_screen.lua` 的 `page_order` 去掉 "equip"；
      页面代码全保留，加回即可）—— 用户要"以后做在**右边**单独显示"
    · **近卫**：用户计划 **3 ~ 7 天内发布**（时间不紧，别拖）

2f. 【✅ 2026-09-14 已按用户要求改】职业书两处：
    · **一转职业书**（`musha_jobbook_warrior`）：转职成功后 `inst:Remove()` **吃掉** ✓
      （连带：以前"书留手里、5 级右键同一本接二转"那条路取消；二转一律去进阶祭坛）
    · **剑士转职书**（`musha_jobbook_saber`，测试专用）：**不再发** `musha_skillbook`（技能面板）✓
    · ⚠️ **同日已删**：`scripts/components/musha_quest.lua:432`（正式二转·祭坛 3 轮任务完成）
      原来也发一本 `musha_skillbook` —— 用户 2026-09-14 拍板「删吧」，已移除。
      **现在全项目只有 ① 一处给技能书**（一转时给一本）。
2c. 【✅ 图标已转 / ⏳ 手持等重导】生命树枝 —— 2026-09-14 拆成两条线：
    · **图标 tex 已打包**（`images/inventoryimages/musha_lifebranch.{tex,xml}` 9/14 19:51）✓
    · **手上不显示 = swap 素材"符号名"起错了**（根因，2026-09-14 查实）：
      DST 的 anim.zip 里能被 `OverrideSymbol` 覆盖的符号名 = **scml 的 timeline 名**
      （旁证：角色 build 的符号就叫 arm_upper/hair/tail —— 全是 timeline 名）。
      原 scml 里 `timeline name="idle"` → 符号名叫 idle，而代码找的是 "swap_lifebranch" → 对不上 → 手上空白。
      （剑没事是因为它用原版 swap_spear，人家 timeline 名就是 swap_spear。）
      → 已改 `exported/musha_lifebranch/swap_lifebranch.scml`：timeline 名 idle → swap_lifebranch（animation 名仍 idle）
      → **等你用 DST Mod Tool 重导覆盖 `anim/swap_lifebranch.zip`**，代码不用动
    · 备用判断：`client_log.txt` 里若出现 `[Musha] 生命树枝：素材还没打包…` = prefab 自检没过（另一条线）
2c2.【⚠️ 同一坑，剑也欠一次】自制剑素材 `exported/musha_sword/`（5 月那套）按现在的认知有 3 个坑，
     接之前必须重做 scml：① zip 名 `musha_sowrd` 与 scml 里 entity 名 `musha_sword` 不一致
     （编译出的 bank 名 = entity 名）② timeline 名 = `swap_sowrd-0`（怪名，OverrideSymbol 得照着写）
     ③ 图 728×1844 竖长、pivot 0.28/0.83（不是中心）→ 握把不在画布中心，当手持用会偏。
     剑暂时继续用原版战矛占位（能跑），等美术定稿再换。
2c3.【⚠️ 2026-09-16 用户报「`exported/musha_sword_v2` 这里有问题」—— 现象待他补写】
     已按他要求把**出问题当时的原始数据**存档（我不改任何值）：
       `exported/musha_sword_v2/_SNAPSHOT_20260916.txt`
       （含 8 个文件的 md5/大小/时间、scml 全部原始数值、出图脚本 `make_musha_sword.py` 顶部参数与配色、
         上一版 `make_musha_sword_steel.py` / 更早 `_abc.py` 的位置、末尾留了「用户补写的问题」空档）
     关键原始值（改前对着看）：pivot 主图 0.498494/0.364458 ｜ swap 三张 0.5/0.611979 ｜
       idle key: x=-93 y=152 angle=218.621814 ｜ BUILD key 覆盖 pivot 0.501097/0.365935 ｜
       脚本 SS=2 CANVAS=768*2 GRIP_Y=470*2 ART_SCALE=0.72 ROT_DEG=0.0
     顺手量到两处不一致（未动）：① `musha_sword.zip`(09-16 01:24 编译) 比 `musha_sword.scml`(13:29 改) 旧 → 包与源不同步
       ② zip 内只有 build.xml/animation.xml/swap_sword-0..2.png，没有叫 musha_sword.png 的条目（两图 md5 相同=同一张）
     ★ 2026-09-16 13:38 **用户已自行更新 scml 并重编**（旧值见快照一~四节，差异见第六节）：
       三处改动 = swap 三张 pivot `0.5 / 0.611979` → **`0.500785 / 0.373626`**；BUILD 的 key 补上 `angle="0"`；文件 1849→1874B。
       其余值（主图 pivot、idle key x=-93 y=152 angle=218.621814、timeline 名、动画长度）**一个没动**。
       重编：`musha_sword.zip` 13:39（7 条目，比旧版多 musha_sword.png + icon）→ **已导出进包**
       `mods/musha/anim/musha_sword.zip`（编译产物 anim.bin + atlas-0.tex 5.6MB + build.bin，13:39）→ 可直接进游戏看。
       旧版 scml 另存 `exported/musha_sword_v2/_bak/scml_旧版_13-29.scml`（mod 的 autosave.scml 里装的也是旧版内容，别当新版用）。
       ⏳ 他当初说的「有问题」具体现象至今没写 → 下次见面问一句：这三处改动是否就是要的修复、还是另有症状。
     ★ 2026-09-16 13:55 两处落地（改完 luac5.1 校验：51 个文件全过）：
       ① `scripts/prefabs/musha_slash_qi_fx.lua` 的 cyan8 `scale` **0.50 → 0.63**（用户「光斩太小，一坨，看不清」）
          根因不是代码 = 换素材了：`crescent_moon` 实物 **639x595**，比 09-14 那版 `crescent_cyan` **705x809** 小 1.266 倍
          → 0.50 × 809/639 ≈ **0.63** = 只是还原到 09-14 认可的那个视觉大小。
          想更大：改 0.8 / 1.0（等比）。想「更清楚」得减薄形状 → `exported/_tools/crescent_gen.py` 顶部 E=99→60 重跑两步。
       ② `exported/_tools/make_musha_sword.py` **修根因 bug**：`pivot_y` 原写成 `GRIP_Y/CANVAS`（少了一步 y 翻转）
          → 现在写常量 `GRIP_PIVOT_X/Y = 0.498494 / 0.364458`，文件头加了「pivot_y 是从图片底部往上数」的口径注释。
          ⚠️ 该脚本跑一次会覆盖 scml 并删掉 zip → **别在 Mod Tool 存过之后重跑它**。
       ③ 武器 pivot 实况（量图核实）：柄身窄段 y 468~508、中心 488/768（从上数）= **0.3646（从下数）**、柄中轴 x≈0.4993。
          → 用户 13:38 改的 swap `0.500785/0.373626` **已经落在柄上**（离柄中心 7px，肉眼看不出）；
            主图 `0.498494/0.364458` 正好压柄中心。想让两组数值完全一致 → 把 swap 三张也改成主图那组（等用户说）。
     ★ 2026-09-16 傍晚 一批（都过 luac5.1 51 文件）：
       ① **宝石任务根因**：`modmain.lua` 的宝石钩子原来写 `ruby/emerald/sapphire` —— **原版没这三个 prefab**
          （原版叫 `redgem/greengem/bluegem`）→ AddPrefabPostInit 静默失效 → 「收集三色宝石」永远 0/3。
          已改 modmain 钩子 + `musha_quest.lua` 的 OnCollected 判断 / 扣件兜底表 / CONSUME_BY_TYPE（共 4 处）。
          ⚠️ 同类坑：职业剑配方原来写 `Ingredient("ruby", 4)`（不存在）→ 用户拍板**不给剑配方**，已把
          `JOB_WEAPONS` 整块注册取消（表留空 + 注释，将来要恢复记得材料名）。
       ② **图鉴**：`musha_dex.lua` 加第 2 条「剑」（含 icon_atlas/icon_tex）；面板 dex 卡片加**左侧 64×64 图标**、
          文字右移 110、行高按卡片真实尺寸（118→128，原来行与行互压=错位）、图标 y −6→−12。
       ③ **任务列表 UI（A 版最小改动）**：计数左移 22（250→228，别贴滚动条）+ 行底加浅分隔线（完成行自动变淡）。
          B 版（0/3 换成 N 个小方格）用户还没点，留着。
       ④ **剑图标重画**：新脚本 `exported/_tools/make_sword_icon_design.py`（DST 立绘规约：竖直、粗深色描边、
          左上受光、亮青能量通道、柄尾水晶）。产出 5 个候选 `exported/musha_sword_v2/icon_design_c1..c5.png`
          （C1 竖直 / C2 竖直宽刃 / C3 微倾15° / C4 微倾15°宽刃 / C5 纯金无能量），
          对照图**已放桌面**：`C:\Users\Administrator\Desktop\剑图标设计图_20260916.png`
          + 桌面文件夹 `剑图标候选_20260916\`（含 00_现在用的.png）。
          ✔ **用户 2026-09-16 挑 C4（微倾 15°·宽刃）**：已烘进 `images/inventoryimages/musha_sword.png`，
            并把 `exported/musha_sword_v2/icon_musha_sword_64.png` 同步成 C4；旧的斜 45° 版备份在
            `images/_bak/musha_sword_icon_斜45旧版.png`。**还差用户用 Mod Tool 转一次 `musha_sword.tex`**（覆盖）。
          （注：用户 14:19 已经转过一次 tex，那次转的是斜 45° 旧版 —— 所以现在必须再转一次才是 C4）
2d. 【✅ 已做】二转不再发技能书：删掉 `musha_profession_component:CompleteAdvance` 里的
    SpawnPrefab("musha_skillbook") + GiveItem（一转书给了的那本保留：musha_jobbook_warrior/saber 里那两处没动）
3. 【进游戏实测】能量球（挂在三围旁）；祭坛自定义模型（USE_CUSTOM_MODEL 已开）；生命树枝手持/图标

3b. 【🐛 2026-09-14 用户报「能量 UI 全坏了」—— 暂缓（用户原话：精力欠缺、懒得改），别主动动它】
    已核对：**文件/挂载链都不缺**（所以更像运行时报错，不是少东西）：
      · `modmain.lua:117` `Asset("ANIM","anim/energy.zip")`
      · `modmain.lua:285` `modimport "scripts/widgets/musha_energy_registered"`
        → `AddClassPostConstruct("widgets/statusdisplays")` → `widgets/musha_energy_badge.lua`
      · prefab 侧：`scripts/prefabs/musha.lua:75-76` net_float `Musha_MP`/`Musha_MP_MAX` + `:88` `AddComponent("musha_mp")`
    下次要查：① client_log 有没有 `[Musha] 能量条已挂载`（没有 = modimport 没跑到）
              ② 有没有 statusdisplays / musha_energy_badge / badge 的 LUA ERROR
              ③ 问清症状（不显示 / 位置错 / 数字不动）

3c. 【⏳ 2026-09-14 用户报「领取礼包的框框有问题」—— 用户先去玩，**搁置**】
    现象未细说（只说"框框有问题"）。回头先问清：外框错位 / 大小不对 / 点击没反应 / 还是行间距。
    相关：`musha_panel_screen.lua` 的 RefreshGift（每行 card + FrameLines + 状态位），`gift_body` 位置 (0, 78)。
3d. 【⏳ 2026-09-15 贴图已改成中式灰布衣，等用户重导 zip】musha **默认衣服 → 中国古代布衣**：
    · 改了 5 个部件共 **39 张 PNG**：`torso / torso_pelvis / arm_upper / arm_lower / arm_upper_skin`
      （`exported/musha/<part>/*.png`；项目包内 156 张 PNG 已同步，逐张校验 39/39 一致）
    · **定稿工具：`exported/_tools/cn_cloth.py`**（第 5 版思路：素布 + 墨线衣纹 + 交领 + 腰带）
      · 候选：1 亮麻 / 2 中麻 / 3 青灰｜4 中麻+交领 / 5 亮麻+交领+腰带（**v1 浅版，用户嫌"粗糙"**）
        ｜**6 精细中麻 / 7 精细加深（已用）/ 8 深青灰**（6~8 = 布色压深 + 明暗拉大 + **梯度墨线**）
      · `python cn_cloth.py` → 对照图 `_test_out/cn_cloth_variants.png`（每行：原图 |5|6|7|8）
      · `--apply N` 换候选 ｜ `--revert` 还原 ｜ 备份 `exported/_bak_musha_outfit/`（**是原图，别再覆盖**）
    · 画法：① 版型=原图 alpha（不动 → 不错位）② 外描边 d=1 深色、d=2~3 淡包边、其余素布
      ③ 交领右衽 = 按衣服 bbox 画的 V 形领缘（`V_HALF_W/V_TOP/V_DEPTH`）④ 腰带 = bbox 0.72H 一条 5px 带
      ⑤ 布面 = 原图明暗（分位压缩）+ 经纬纱痕 + 斑驳
    · ★ 两个坑（都踩过）：
      (a) **深度场截断**：BFS 距离上限写 6 → 衣服内部 71% 像素停在 0，被当"边缘半透明"染暗 → 整件发乌。现在 D_MAX=4096
      (b) **细线 vs 粗色块**：原图 50% 像素是深色，用"5x5 邻域计数"会把粗块的边缘也判成线 → 整件衣服被衣纹色盖住。
          正解 = **连通域厚度**（`thin_line_mask`）：域内最厚处 < 3px 才算细线（留衣纹），否则整块当布
    · 旧稿（只是灰化的，已弃）：`draw_cloth.py`（明暗映射）/ `gray_cloth.py`（纯去色）
    · **待办：DST Mod Tool → 打开 `exported/musha/musha.scml` → 编译 → 覆盖 `anim/musha.zip`** → 重启游戏
    · 没动的部件：`hand`（护手）、`leg`/`foot`、`hair*`/`face`/`headbase`
    · 知识点：护甲走 `swap_body` 另一份素材，改角色 build 贴图不影响穿甲外观
      （详见 skill `dst-modding` → `references/character-build-outfit-parts.md`）

3e. 【⏳ 2026-09-15 已做好，等用户导 zip】便签**地上/手中形态**（原来掉地上是空白）：
    · 病因：`anim/musha_note.zip` 里只有 **UI 那套**（1800x1011 底纸 + 9 行文字切片，动画只有 `anim`/`disappear`），
      而 `musha_note.lua` 播的是 `PlayAnimation("idle")` → **build 里没有 idle** → 名字对不上 → 场景里啥都不显示。
      两个 scml：`musha_note.scml`=UI 弹窗；`test.scml`=道具形态(NewAnimation)，**从来没被编译进去**。
      另：UI 那套 `anim`/`disappear` 全项目无任何代码调用（弹窗走 Image + `images/musha_note_bg`）。
    · 已做：新工程 `exported/musha_note_item/`（`make_note_item.py` 生成）
      · `musha_note_item.png` 64x64 一卷系绳的纸（程序化画，1px 描边；预览 `_test_out/note_item_preview.png` 4 倍）
      · `musha_note_item.scml`：动画 **`idle`**，timeline 名 **`swap_object`**（→ 地上显示 + 拿在手里也能显示）
      · `musha_note_item.zip`：Mod Tool 工程包（build.xml + animation.xml + png）
    · 代码改动（`scripts/prefabs/musha_note.lua`）：Asset 换成 `anim/musha_note_item.zip`；
      `SetBank/SetBuild("musha_note")` → `("musha_note_item")`。**语法校验 50 个文件全过**。
    · ⚠️ **2026-09-16 实景踩雷（同一坑第二次）**：把便签的 Asset 改成还没打包的 `anim/musha_note_item.zip` →
    进游戏直接 `Could not find an asset matching anim/musha_note_item.zip` → **整个 mod 被禁**。
    修法照抄生命树枝：`asset_exists()`（包 `softresolvefilepath`）+ 条件 `table.insert(assets, ...)` +
    bank/build 回退旧 build。**规则：凡是指向"新美术还没打包"的 Asset，一律先加自检再改。**
  · 项目里已有发布前自检脚本：`python exported/_tools/check_assets.py`（扫 Asset 声明 vs 实际文件）
    · ⚠️ **bank/build 名 = scml 文件名去掉 .scml**（已验证：`slash_fx.scml` → SetBank("slash_fx") 可用）
    · 旧的 `anim/musha_note.zip`（935KB）已不再被加载，文件仍在磁盘，要删随时删
    · **待办：DST Mod Tool → 打开 `exported/musha_note_item/musha_note_item.scml` → 编译/导出 → 存成 `anim/musha_note_item.zip`** → 重启游戏

3f. 【✅ 2026-09-15 已修，待实测】转职任务「存活5天」进度条一动不动：
    · 根因：`musha_quest.lua:OnNewDay()` 里 survive 类只遍历 `self.daily_quests`，
      而转职任务挂在 `self.advance_quest` 上；事件型推进（`ProgressQuests`）只覆盖
      kill/collect/craft/discover，**没有任何地方给转职的 survive 加天数** → 永远 0/5。
      （旁证：`AcceptAdvanceQuest` 里 `ADVANCE_POOL_BY_ROUND` 算出来没用，转职是从全池抽 → 会抽到 survive 类）
    · 修法：OnNewDay 里加 2b 段——advance_quest 若是 survive 且未完成，同样 +1；
      到目标即 `CompleteCurrentAdvance()`（内部推进轮次/第3轮进阶），末尾原有 `SyncToPanel()` 会刷新进度条
    · **语法校验 50 个文件全过**；其余类型（kill/collect/craft/discover/collect_gems）都已核对过：每日+转职都覆盖
    · 实测点：接到"存活5天"转职任务后，**过一天进一格**（第 5 天完成本轮；若已是第 3 轮则直接进阶）

3g. 【✅ 2026-09-16 已实现，待实测】生命树枝**装备被动**（原设定漏档、用户口述补上）：
    · 设定：**装备时**（武器位）每秒回 **0.2** 生命、每 **24 秒 +0.1** 精神。
      出处：用户 2026-09-16 口述（"脑内设定"）；原想做成**衣服（BODY 位）**，与「人格」冲突 → 定案放**武器位**。
    · 实现（`scripts/prefabs/musha_lifebranch.lua`）：顶部三常量 `LIFE_REGEN=0.2 / SANITY_REGEN=0.1 / SANITY_INTERVAL=24`
      + `start_regen()` 在 `on_equip` 起两个 `owner:DoPeriodicTask`、`on_unequip` 停、`onremove` 兜底取消（防任务泄漏）
      · 守卫：ghost/死亡/无组件 都不回；只有装备期间生效（背包里不生效）
    · **语法校验 50 个文件全过**；不用美术、不用重导 zip，重启即生效
    · 待用户拍板的小口径：① 0.1/24 秒是字面值（几乎无感，替代口径 b=0.1/秒、c=1/24秒）②要不要接上设置页那个空转的 `hp_regen_mult` 倍率
    · 升级机制（满级 18~24）仍未做——那是另一件事，卡在"升级怎么触发"没定

3h. 【✅ 2026-09-16 已做，待用户看图鉴页效果】面板**图鉴页**从"内容待定"占位做成真列表：
    · 内容源 = **`scripts/musha_dex.lua`**（数组表，卡片式：`{ name=, tag=, lines={最多3行} }`，加条目只改这个文件）
    · 面板侧：`MUSHA_DEX` require（顶部，仿 GIFTS）+ `dex_ctor/dex_apply` + `TEMPLATES.ScrollingGrid`（840x112 卡片，4 行/页，可滚动）
      + `RefreshDex()`（切到 dex 页时调用，已接进 `SetActivePage`）
    · 首条 = **生命树枝**：攻击 12（可升级满级 18~24）/ 装备时每秒回 0.2 生命、每 24 秒 +0.1 精神 / 来源第 10 天礼包页
    · **语法校验 51 个文件全过**（新文件计入）；不用导 zip，重启游戏即见
    · 想加条目（便签 / 进阶祭坛 / 剑气斩 / 礼包…）往 `musha_dex.lua` 里按模板加一段即可

3i. 【⏳ 2026-09-16 剑已画好，等用户导 zip】基础剑 → **重剑**（参考《艾尔之光》风格）：
    · 素材（新工程 `exported/musha_sword_v2/`，`make_musha_sword.py` 生成）：
      `musha_sword.png` 512² 剑身（宽刃+斜切刀尖+血槽/高光+V字护手+红宝石+缠绳柄+金柄头）
      ｜`musha_sword.scml`（bank/build=`musha_sword`，动画 `idle`，timeline 名 `musha_sword`）
      ｜`musha_sword.zip` 工程包 ｜`icon_musha_sword_64.png` 64x64 背包图标（斜 45°，4 倍超采样后缩）
      ｜预览 `_tools/_test_out/sword_preview.png`
    · ⚠️ 约定：**pivot = 握把中心**（手抓在这点、剑身朝上）——照"能在手里显示"的 `swap_lifebranch` 那套；
      旧剑（`exported/musha_sword/swap_sowrd`，728x1844、pivot 0.28/0.83）偏就是因为握把不在画布中心，**别再捡那份**
    · ★ 2026-09-16 第二轮（用户："太卡通了吧"）——三条根因逐条改掉，并加了两个旋钮：
      ① 比例太胖：刃长/刃宽 2.5:1 → **3.5:1**，画布 512 → 768（装得下加长的刃）
      ② 颜色糖果 / 平涂塑料感：金属色**整体去饱和** + 每块色带叠 **`shade_post` 整体明暗渐变**（刃尖亮→柄沉，右暗左亮）
      ③ 硬边描边：**2 倍超采样后缩小**（抗锯齿；实测半透明边缘像素 0 → 592），描边改深板岩(48,52,62)不纯黑
      · ★ **尺寸校准**：量了能正常显示的树枝，实体只有 **346x326**；剑定在 **130x393（1.21 倍高）**——
        重剑该比常规武器大一点，但不能再大（首版 516px 高会在手里显得巨大）
      · 两个新旋钮（`make_musha_sword.py` 顶部）：`ART_SCALE`(0.76 大小) / `ROT_DEG`(0 歪了改角度)；`MAIN` 切 A/B/C 三版：
        A 细长优雅 / **B 厚重重剑（定稿）** / C 冷钢发光｜对照图 `_test_out/sword_preview.png`
    · ★★ 2026-09-16 第三轮（用户给参考图："参考第一张图 重画"）：**按参考图重画，丢弃金饰/宝石路线**
      · 参考图特征（**没有视觉模型，靠像素统计+灰度图"读"出来的**，写下来免得下次重读）：
        单色灰钢（主色全灰 96~196，唯一彩色是柄上一小块暗红 RGB(48,24,24)）、宽厚刃、
        **斜切刀尖**（刃尾一整片斜面，非对称尖）、刃身一条**倒角棱线**、刃根**台阶缺口**、
        极简刀柄 + **尾部一个圆环**（无十字大护手/无宝石）、明暗对比强（亮 196 / 暗 90）
      · 新画法：钢色 5 档（206/172/134/98/70）+ 斜端面亮带 + 倒角棱线(双线) + 右背暗面 +
        刃根加强条 + 极简钢领 + 短缠柄(含暗红缠绳两道) + **柄尾圆环**（even-odd 多边形挖空）
      · 自检：实体 **96x381**（基准树枝 346x326 → 高 1.17 倍）｜亮度跨 6 档 32~223（不平涂）｜抗锯齿边缘 636px｜
        最大饱和度 0.57 = 那点暗红 ✓
      · 旧 A/B/C（金护手+宝石）版脚本已备份为 **`make_musha_sword_abc.py`**，想回头用那套就跑它
    · ★★ 2026-09-16 第四轮（用户："画成星灵武器可以吗" → 选定**星际争霸神族 Protoss 风**）：**当前定稿 = 星灵灵能巨剑**
      · 备份链：金饰A/B/C版 = `make_musha_sword_abc.py`；灰钢参考图版 = `make_musha_sword_steel.py`（出图在 `exported/_bak_musha_sword_steel/`）
      · 星灵版结构（`make_musha_sword.py`）：金剑身（4 档金 255,228,142/214,170,62/166,122,34/112,78,20）
        ＋ 左刃口蓝白能量条（ENERGY 外亮 →ENERGY_MID 过渡）+ 右刃口细能量边 ＋ 斜切刀尖端面整片发光
        ＋ **中央灵能通道 4 档**（32,104,180 → 56,150,224 → 120,214,255 → 236,250,255 白核）＋ 刃外一圈深蓝光晕
        ＋ 金色发射座(刃根)＋ 金色带翼护手 ＋ 护手中央菱形能量水晶(白核+高光点)
        ＋ 暗紫柄三道金环 ＋ **柄尾悬浮水晶**（与柄留空隙＝悬浮感）
      · Protoss 感的关键：几何硬边、左右对称翼、菱形水晶、能量由护手向上射出、金与蓝白对撞（不用半透明做发光，避免缩放脏边）
      · 自检：实体 **118x388**｜抗锯齿边缘 536px｜配色 **暖金 44% / 蓝白灵能 43% / 中性灰 13%**（灰是描边+暗部）
      · 想微调：金多/蓝少 → 改刃口条宽（现在 7/13）与通道宽（现在 13/9/5.5/2.2）；整体更亮 → 调 `shade_post` 的 1.06
    · 代码改动（`scripts/prefabs/musha_sword.lua`）：加 `asset_exists` 自检 →
      zip 在：`OverrideSymbol("swap_object","musha_sword","musha_sword")` + `SetBank/SetBuild("musha_sword")`+`idle`（世界形态）；
      zip 不在：回退原版战矛占位（**不会再出现"素材没打包 → 整个 mod 被禁"**）
    · **语法校验 51 个文件全过**；`check_assets.py` 里 musha_sword 那项已由自检覆盖
    · **待办：DST Mod Tool → 打开 `exported/musha_sword_v2/musha_sword.scml` → 编译 → 存成 `anim/musha_sword.zip`**；
      图标若要换新：`icon_musha_sword_64.png` 转 tex 覆盖 `images/inventoryimages/musha_sword.*`（现有图标是旧剑）
    · 调参：`make_musha_sword.py` 里 `GRIP_Y`（握把高度/入画位置）+ 各多边形尺寸 + 顶部色板常量

4. 【✅ 已解决 2026-09-14】图标 `images/inventoryimages/musha_lifebranch.{tex,xml}` 已转；手持已重导 `anim/swap_lifebranch.zip`（符号名 swap_lifebranch，见 2c）
5. 【✅ 代码侧已做，待实测】礼包双轨（2026-09-14 用户定规则）：
   · **游戏时间礼包**（`kind="cycle"`，按 `TheWorld.state.cycles`）→ 礼包页**常显**，没到天数锁住（灰字「第 X 天可领（还差 N 天）」）
   · **节日礼包**（`kind="festival"`，按**本机现实日期** `from`/`to`，例：国庆 2026-10-01 ~ 10-07）→ 只在窗口内出现，过了消失
   · 数据全在 `scripts/musha_gifts.lua`（第 1/3/10 天三条已填：红宝石×2 / 生命护符 / 生命树枝；第 16/30 天因物品没做先挂注释）；
     判定 = `rpcs/musha_rpcs.lua`（claim 时再查一遍，口径同面板）；渲染 = `screens/musha_panel_screen.lua:RefreshGift`
   · 实测点：第 1 天那条开新档就能领；国庆那条**现在（9 月）不该出现**
   · 另：生命树枝升级机制仍未做（样板 portablefirepit + portablestructure）
6. 【暂不开放】武器技能「4 选 2」选择 UI（用户 2026-09-14：看后期）

## 🔧 命令（每次改完必跑）
- 语法校验：`wsl -d Ubuntu2204 -e bash -lc 'bash /mnt/d/wsl-dl/lua-syntax-check.sh'`（期望「检查 N 个文件：全部通过」）
  · `luac5.1` 只在 WSL 里，Windows 侧找不到，别去 C:/D: 盘 find
- 方向图生成：`python exported/crescent_cyan/make_dirs.py`（纯标准库，约 30 秒；Windows 侧无 PIL）
- 角色造型换衣（中式素布衣）：`python exported/_tools/cn_cloth.py [--apply 1..5|--revert]` ← **首选**
  旧稿：`draw_cloth.py`（布纹重画）/ `gray_cloth.py`（纯去色）
  （纯标准库；配套 `exported/_tools/{pnglib,ascii_view,palette_scan}.py` —— 没视觉模型时用 ascii_view 看图）
- **发布前素材自检**：`python exported/_tools/check_assets.py`
  （扫全项目 `Asset("类型","路径")`，报"声明了但文件不存在"的项 —— 这类缺失会让 RegisterPrefabs 阶段 assert，
   整个 mod 被禁；2026-09-14 生命树枝、2026-09-16 便签各踩过一次）
- 打包：`D:\饥荒开发\tool\DST Mod Tool.exe`（GUI；tex 和 anim 都只能走它）
- 原版写法定要看**当前版本**：`unzip -o -q data/databundles/scripts.zip "scripts/xxx.lua" -d /tmp/gd`
  （`data/databundles/scripts/` 那个旧解包目录行号对不上）

## 🗂 Gitee（用户旧账号 ZeroCiel，卡在只读部署公钥）
- 根因：`~/.ssh/id_ed25519` 被加成**仓库级部署公钥**（只读）→ `DeployKey does not support push code`；
  Gitee 公钥**全局唯一**，所以"重复添加只提示密匙已有"
- 解法 A（推荐，30 秒）：仓库 → 管理 → 部署公钥 → 那把 `musha-gitee` → 编辑 → 勾「启用推送权限」
- 解法 B：先**删**部署公钥 → 头像 → 设置 → 安全设置 → SSH 公钥 → 贴新钥匙（已生成 `~/.ssh/id_ed25519_gitee`）
  `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICsrfD2DBoKCrNn521OboR+y1UiFFwZbr9Wvs7Pj6FEM musha-push-2026-09`
  → 之后我加 `~/.ssh/config`（IdentityFile + IdentitiesOnly）
- 本地提交照常做，推送权限不通**不影响开发**（本机已提交多个 commit）

## 📐 已定规则 / 现况数值
- **技能预算**：每职业正式技能 = 1 主动 + 1 武器技能；其余（旋风斩/横扫/战吼…）只留数据不实现
- **武器技能触发 = 女武神 AoE 那套**（aoetargeting + aoespell + CASTAOE），显示名走 `STRINGS.ACTIONS.CASTAOE.MUSHA_SWORD`
- **冷却口径**：冷却期关 `aoetargeting:SetEnabled(false)`（右键不进圈、不弹字）；武器自带 `rechargeable`
- **剑气斩 = 加点学习技能**（2026-09-14 用户拍板"改 3 级加点学习"）
  · 挂在【职业组件】剑士树：`musha_profession_component.lua` 的 `self.saber.slash_qi`
    — max_level 3、解锁门槛角色 **3 / 7 / 12** 级、每级 1 技能点、level_effects 存的是每次耗能量 **18 / 16 / 14**
    — 面板显示：`SKILL_ORDER.saber = { "slash_qi", "last_stand" }` + `SKILL_UI.saber.slash_qi`
    — 存档 OnSave/OnLoad 都带 slash_qi（漏了会重进游戏归零）
  · **没学过（等级 0）→ 右键不给进圈**（`musha_sword` 的 RefreshSkillGate = 冷却 OK **且** 已学）
    学到后职业组件 push `musha_skill_changed` → 剑上监听重新开门
  · 施放时再查一遍（`musha_weapon_skill.DoCast`）：没学 / 冷却 / 能量不够 → 一律**静默不放**（不弹字）
  · ★ 技能等级真源 = 职业组件（`WeaponSkill.GetSkillLevel`）；`components/musha_skills` 是 .bak 未启用，别去读
- **战士/剑士 技能上架清单**（2026-09-14 核对；技能页渲染源 = 职业组件 `SKILL_ORDER` + `SKILL_UI`，**不是** skills/musha_skill_data.lua）
  · 战士：战斗恢复 combat_recovery（3 级，脱战每秒 0.11/0.18/0.22，解锁 0/3/5）、武器精通 weapon_proficiency（3 级，武器伤害 +30/48/63%，解锁 3/5/7）
  · 剑士：剑气斩 slash_qi（3 级，解锁 3/7/12）、我，活着 last_stand（1 级，7 级 3 技能点，血量≤50% 回满，CD 80 秒）
  · 备份未上架（只在 `skills/musha_skill_data.lua`，技能页不显示、无消费方）：横扫 / 战吼 / 旋风斩
  · 加点链路：面板 +号 → RPC `musha_skill_upgrade` → `pc:UpgradeSkill`（等级门槛 → 扣技能点 → ApplyProfessionData → PushSettings）
- **剑气斩能量数值**：实现口 `musha_weapon_skill.lua:COST_BY_LEVEL`（18/16/14）+ `GetCost()`
  （数据侧同步写在 `skills/musha_skill_data.lua:slash_qi`；技能等级从职业组件读）
- **剑气斩伤害按等级走**（2026-09-14 用户拍板"接上"）：命中伤害 = 武器伤害 × **100% / 130% / 160%**
  → 实现口 `musha_weapon_skill.lua: MULT_BY_LEVEL = {1.00, 1.30, 1.60}` + `GetDamageMult()`；
    `DAMAGE_MULT = 1.2` 降级为兜底（只在拿不到技能等级时用）；命中日志会打 `（Lv2 ×1.30）` 方便实测核对
  ⚠️ 频率账：剑士 MP 回复 0.5+0.02/级 每秒 → 3 级时 ≈0.56/秒，18 点要 **≈32 秒**才回上来；
     而冷却只有 6 秒 → **实际卡点是蓝不是冷却** —— ★ 用户 2026-09-14 拍板：**就这样，不调**
     （理由原话：一天也用不了多少次，能量给多了技能就廉价；战士主战力靠走A平A，太依赖技能反而"没战力、太婴儿"）
- **施法动作**：`modmain.lua` 一行 `MUSHA_AOE_CAST_STATE = "quickcastspell"`（抬手，第 5 帧出手）
- 月牙 FX（`musha_slash_qi_fx.lua`）：`FX_ART = "cyan8"`（方向图版，8 张按飞行方向选图、贴图不旋转）
  · `FX_SPEED 22.5` / `FX_HIT_DIST 1.0` / `scale 0.90`；素材 `anim/crescent_cyan8.zip`（2.7 MB，比单图版大 2 MB）
  · 底图 `crescent_light.png` 是**对称光斩**（不是月亮）：凸面朝前、上下对称 → 8 方向观感一致
- **月牙底图美术规则**（2026-09-14 用户定）：月牙本质是**光斩不是月亮** → 底图要**关于飞行轴对称**
  （凸面朝前、上下对称的弓形弧），这样脚本旋转生成的 8 方向图每个方向观感一致（"每个方向对整"）
  · ★ 已重画：`crescent_light.png`（1024²，本体 ≈485x410，**上下不对称 0.00%**，由 `make_lightslash.py` 生成）
    工具：`make_lightslash.py`（画）/ `make_dirs.py`（派生 8 方向）。旧的非对称底图 `crescent_cyan-0.png`
    （最佳对称轴 ~51°、仍 34.5% 像素不匹配）保留在导出目录里，没删
  · 换底图流程：新图画成对齐的对称弓弧 → 覆盖 `crescent_cyan-0.png` → `python exported/crescent_cyan/make_dirs.py`
    → DST Mod Tool 导 `dirs/crescent_cyan8.scml` → 覆盖 `anim/crescent_cyan8.zip`（代码不用动）
- 礼包页：标题 `gift_head` **(-295, 254)**；提示 `gift_hint` 跟随标题右下 -15,-15 再 +120 → (-158, 223)
- **V2 底图实测锚点**（2026-09-14，对 images/bookpage_bg.png 1644x1109 做的像素分析；显示尺寸 1232x832）
  · 红叉（红色圆盘）**圆心 = 面板 (523, 360)** → `close_btn` 就放这个数（原 492,341 偏左 31 偏下 19）
  · 用户确认"对"的右上导航三角 = `nav_triangle` **(536, 310)**（46×46×0.7 蜡黄底 + "›" + 白框）
    ⚠️ 它就在红叉正下方 ~50 单位 → 截图里那个"淡色小方块"就是它，不是退出按钮，别混
  · 红框/描边线实测：左竖线 面板 x≈-538、右竖线 x≈+537（外侧 +557）、顶部横线 y≈+402
- 能量条 = 官方挂载（`statusdisplays` + Badge + netvar），不是面板里的一页
  · **2026-09-16 换色定稿「暖木青」**（方向 A：只换色不换形）：液面 淡蓝#A8D8F0 → **亮青#82D6E0**、
    中心 草绿#90D860 → **亮金#F8D284**；外圈 frame_circle 未动。
    源图 = `exported/energy/`（旧图备份 `_bak_淡蓝_20260916/`），已命令行重编 → `anim/energy.zip`（旧 zip 备份
    `anim/_bak_energy_淡蓝_20260916.zip`）。工具 `exported/_tools/recolor_energy_badge.py`（幂等，改配色只改 TARGET 重跑）。
  · ⚠️ **V1 教训**：暖米当空槽底 → 底亮度 190 比液面 175 还亮，满/空读不出来（原版 液213/底110）。换色后必须量"液面−底色"亮度差，>45 才算能读。
  · **两层圆盘（bg / bg2）= 油箱底，工作正常**（✅ 2026-09-16 查清，前一版笔记误判过）：
    scml 里它们的 object 坐标是 `x=-86.55 y=87.6`（作者故意写的），编译后 build 帧偏移 `+86.9/+88.5`，
    **最终位置 = 元素位移 + 符号帧偏移 ≈ (0,0) = 徽章正中心**；z_index 0/1 = 最底层 → 就是液面底下那层底槽。
    ⚠️ 所以**千万别去"归位"它们的 pivot**（试过：pivot 改 0.5/0.5 会让帧偏移归零、圆盘真的飘到画外）。
  · **中心图标 = 5 帧表情**（2026-09-16 上架）：`heart-0..4` = **满足/愉悦/高兴/正常/沮丧**（能量满→空，
    顺序用户 09-16 23:37 定稿，之前是高兴/愉悦/满足/正常/沮丧 → 只对调了 0 和 2）。
    44×44。源图：`images/emotes/666.png`（2×2 四格：左上高兴/右上愉悦/左下满足/右下沮丧）
    + `normal.png`（用户后来换成的"5 张脸+彩色笔刷文字"排版图，**正常=底部中间**那张、紫色标签）。
    生成器：`exported/_tools/make_badge_faces.py`（首版 4 张 + 白底泛洪抠白）
    / `update_badge_face_normal.py`（单换"正常"：**连通域泛洪**排除压在脸上的标签，覆盖 65% 与其余 4 张一致）
    / `preview_badge_faces.py`（改完顺序跑它更新预览）。
    ⚠️ 缩小必须**预乘 alpha 盒式滤波**（否则透明底的白色渗边=白毛边）。
    scml 的 heart 时间轴已从 4 组重映射成 5 组（23 个 key → 5/5/5/4/4），root 保持 (0.5,0.44)/83×86 不变。
- 悬停信息面板钉屏幕右下角（`musha_item_info.lua:PinBottomRight`）

## 🧱 铁律（踩过的坑，动手前扫一眼）
- **方向图别让脚本"猜"底图朝向**：`make_dirs.py` 的 `analyse()`（质心−两尖中点）对弓形弧有 ~20° 系统偏差，
  会让 8 张方向图**一致偏 ~32°**（看着就是整体歪，且每个方向歪得一样多）。底图朝哪是已知量 →
  用 CONFIG 的 `BASE_ANGLE_DEG` 显式指定；改完**一定**跑 `python check_dirs.py` 自检（量"每张实际朝哪个方向"）。
- **原版"多面"机制**（2026-09-14 查证）：`Transform:SetNoFaced/SetTwoFaced/SetFourFaced/SetSixFaced/SetEightFaced`
  只有 **1/2/4/6/8** 面（**没有 3 面**），作用 = "影响物体在相应朝向时展示的形态"。
  但原版**没有**"8 个方向各一张图"的先例：带方向的斩击特效（蟹王爪击/日行者/鲨鱼）**都只有 1 个动画**，
  靠引擎在地面里旋转；原版素材里 `xxx_1..xxx_8` 这种后缀是**变体**（月相雕像 idle_full_1~4、南瓜刻法 cut_arc_1~8、
  斧头温度档 idle_1~4），不是朝向。→ 想"8 方向各一张"只能自己按方向选动画（我们现在的路子）。
- **netvar 类型只能用原版有的这几个**（`scripts/netvars.lua`，2026-09-14 实测踩过）：
  `net_bool` / `net_tinybyte[0..7]` / `net_smallbyte[0..63]` / **`net_byte[0..255]`** / `net_ushortint` / `net_int` / `net_uint` /
  `net_float` / `net_string` / `net_hash` / `net_entity` / `net_event`(包装 net_bool，用 `:push()`)
  → **没有 `net_smallint`**！写错会 `variable 'net_smallint' is not declared` 直接崩在 SpawnPrefab。
  API：服务端 `nv:set(v)` 同步给全端（值变了才触发 dirty 事件，主机和客机都收到）；任意端 `nv:value()` 读；`nv:set_local(v)` 只改本地
- **AnimState 不会自动联网**：服务端 `PlayAnimation` 只影响主机自己的画面，客机看到的是 build 的默认动画。
  要给客机换动画必须走 netvar（样板：`musha_slash_qi_fx.lua` 的 `musha_qi.dir` = net_byte + dirty 事件，
  服务端只写序号、各端各自 `PlayAnimation`）。同理 `SetScale`/`SetMultColour` 这类外观改动也只在本地生效。
- 组件文件里**不能**用 `GLOBAL`（裸 TheWorld/STRINGS）；只有 modmain 写 `GLOBAL.`
- Widget/Text/Image 不是全局 → widget 文件头必须 `require "widgets/widget"` 等三个
- `assets` 里写**不存在的文件** → RegisterPrefabs 阶段 assert → **整个 mod 被禁**；新资源一律先探存在（`softresolvefilepath`）
- `AddComponentAction` 的 `actions` 是数组 → `table.insert(actions, ACTIONS.XXX)`（旧写法会 nil 报错）
- 客机读不到 `weapon/armor/insulator` 组件（服务端专有）→ 走静态表 `musha_item_stats`；
  能读的看档案里「客户端读得到/读不到」那张表
- 单帧贴图别设 `SetFourFaced/SetEightFaced`；会飞的贴图用 `SetOrientation(OnGround)` + 背景层
- 抛射体（`projectile`）命中是每帧比距离：`HitDist` 必须 > `Speed/30`，否则跨帧穿过 → 技能空放
- 改完任何 .lua 必跑语法校验；回话报「语法 N 个文件全过」
- 热更新客户端要重新勾 mod
- **改 build 素材不用开 Mod Tool GUI**（2026-09-16 试通）：命令行
  `"…/Don't Starve Mod Tools/mod_tools/scml.exe" <工程>/<名>.scml <出参目录>` → 出 `<出参>/anim/<名>.zip`，
  直接覆盖 `mods/<mod>/anim/<名>.zip` 即生效（不用动 lua）。重编是**确定性**的：
  同一套 PNG 两次编译 md5 完全一致 → 所以"新 zip 与旧 zip md5 不同"就能证明换色进了包。
- **编译产物可以反查**（改素材前先看清结构，别猜）：zip 里 `build.bin`（BILD v6）= 每个 symbol 的帧四边形
  x/y/w/h + 图集 UV；`anim.bin`（ANIM v4）= 每帧 element 列表，含 `layerhash`、变换矩阵 (a,b,c,d,tx,ty) 和 z。
  两文件末尾都有 hash→名字表，拿它把 hash 翻成符号名/图层名。
- ⚠️ **元件最终位置 = 元素 tx/ty + build 帧偏移，两者相加**（❗踩过：只看 anim.bin 的 tx/ty 得出"圆盘飘在徽章外"
  是错的 —— scml 写的 `x=-86.55 y=87.6` 正好被 build 帧偏移 `+86.9/+88.5` 抵消，实际在正中心）。
  要判位置必须**两个文件一起算**。z 越大越靠前（DST 按 z 降序画）。
- **scml 里 file 的 pivot 可以用负数/超过 1**（Spriter 允许，y 向上为正）。pivot 决定"帧偏移"，改它＝改元件落点；
  改完必重编 + 两个 bin 都解一遍复核。`pivot=0.5/0.5` 才是居中。

- **容器（container）四个坑**（2026-09-17 祭坛容器趟出来的）：
  · `containers.params.<名>` 要在 **modmain** 里登记（双端都要有），而且必须在 prefab 构造前 —— `WidgetSetup()` 会来查这张表
  · `container.onopenfn` 的第 2 个参数是 **`{ doer = doer }` 这张表**，不是 doer 本人（原版 container.lua:659）；`onclosefn` 才是 doer
  · 容器**只在服务端** `AddComponent("container")`（原版 chest/cookpot 都这样），客户端靠 replica 自动拿到 widget
  · 自定义 SCENE 动作（默认优先级）会**盖住**原版容器动作 `RUMMAGE`（priority = **-1**，中文显示"打开"）→
    想让右键显示自己的话（我们 = "打开祭坛"），就自己 AddAction + fn 里 `container:Open/Close`，别再依赖 RUMMAGE
- **借原版资源做占位**：`Asset("ANIM","anim/papyrus.zip")` 前先 `ls data/anim/` 确认真存在（清单里没有=整个 mod 被禁）；
  图标只改 `inventoryitem.imagename`，**atlasname 留空** = 走游戏默认大图集 images/inventoryimages.xml（原版物品就这么干）

## 📄 文档地图（要细节看这里）
| 问题 | 看哪 |
|---|---|
| 历史决策 / 踩坑全过程 | `musha-log-2026-09.md`（**grep 定位，别整读**） |
| 武器技能 v1~v11 全过程 | `musha-weapon-skill-plan.md` |
| 右键点地技能两条路线 + 硬要求 | `musha-rightclick-spec.md` |
| 天数奖励（未做） | `musha-dayrewards-plan.md` |
| 装备/属性面板设计 | `musha-design-equip-panel.md` |
| 可移动携带建筑（生命树枝升级用） | `references/portable-structure-notes.md` |
| 方向图生成（8 面 + 投影补偿） | 技能 `dst-modding` → `references/directional-art-projection-compensation.md` |

## ⏳ 待拍板
- **祭坛改版待拍板**（2026-09-17）：
  · 卷轴美术 —— 现在占位=原版莎草纸；要不要出专属"转职卷轴"图标 + 世界贴图（我可程序化画，或写外包需求单）
  · 等级不够时祭坛要不要**提前给**卷轴（现在给：接取时才提示"需要 5 级"；也可以改成不到 5 级坛里空空）
  · 要不要给"取出卷轴 / 展开卷轴"加音效或光效（要查原版音效路径，别瞎猜）
  · ✅ 已定：旧占位 statuemaxwell 兼容**已删**（容器只加在祭坛自己的建筑上）
  · ⚠️ 职业书美术缺进阶职业那一批（warrior/mage/ranger/rogue 才有）→ 近卫职业书要配套美术
- 生命恢复 `hp_regen_mult` 现在 0 消费方：留 or 删
- 设置页 6 行要不要居中/下移（给数字）
- 上线前清理清单 —— 发布前逐条过（✅ 2026-09-16 核过一遍）：
  · ❌ **未清**：测试用剑士转职书 —— 3 处（`modmain.lua:303` PrefabFiles 里的 `musha_jobbook_saber`
    + `scripts/prefabs/musha_jobbook_saber.lua` + STRINGS 的 `MUSHA_JOBBOOK_SABER`）；**删之前先确认祭坛 3 轮流程能走通**
  · ✅ 已无：dev_test_gift（全项目 grep 不到）
  · ❌ **未补**：进阶祭坛配方图标仍是占位（`modmain.lua:423-424` 用的 `musha_note` 图）→ 缺 1 张祭坛图标
  · ✅ 已清：设置页空行（`mp_regen_mult` 行已删，SETTINGS_UI 现有 6 行都是实的）
- 更新日志：`scripts/musha_changelog.lua`（源）+ 面板内联兜底（`musha_panel_screen.lua:111` 起）**两份都要同步**；
  0.7.7 条目已写（2026-09-16，5 行）。⚠️ 信箱页 `MAIL_PER_PAGE = 3`，**单条行数太多会掉出框外**（每页约 4~5 行/条为上限）
