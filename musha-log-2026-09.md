# Musha 历史档案（2026-09 及以前）—— **别整读这张！**

> 这是原来那张「状态卡」的完整历史内容（决策过程 / 踩坑全过程 / 已完成的改动记录）。
> 新会话只需要读 **musha-current-state.md**（短卡）。
> 要看某段历史 → 用 grep 定位行号再小段读，例：
> `grep -n "冷却\|aoetargeting\|礼包" musha-log-2026-09.md`
>
> 维护规则：新东西写进短卡；短卡里被替换掉的老条目**搬到这里**，别删。

---

# Musha 当前状态卡（2026-09-12 深夜）—— 新会话先读这一张，别读整份 backlog

## 项目
D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha
用户自己的 DST mod（作者 Ciel/雪儿），面板 = Screen + ScrollingGrid，5 页（主页/技能/信箱/设置/图鉴）
进度文档：musha-backlog.md（顶部有新到旧的完整决策记录）

## 📌 本轮队列（2026-09-14 · 下次开工先扫这里）
【用户要做：打包 / 导出】→ ✅ 2026-09-14 用户已全部打包完（我这边接线也全做完）
1. **亮青月牙 · 方向图已就绪**（2026-09-14 我用程序生成，**不用即梦额度**）：
   `exported/crescent_cyan/dirs/`（生成器 = 同目录 `make_dirs.py`，纯标准库 python 跑）
   · `crescent_cyan8.scml` + `crescent_dir0..7.png`（8 张，世界 +X 起每 45°）+ `_preview_all8.png` + `README.txt`
   · **打包**：DST Mod Tool 打开 `crescent_cyan8.scml` → 导出 → `anim/crescent_cyan8.zip`
     然后把 `musha_slash_qi_fx.lua` 顶部 **`FX_ART` 从 "cyan" 改成 "cyan8"**（表已填好，含 dirs=anim_0..7）
   · 原理：贴图是平铺地面的，直接转贴图会被"地面投影"压扁（= "光和面倾斜"）；
     生成器在美术空间做反向补偿 `P⁻¹·R·P`，投影后画面正好是"月牙朝该方向"的样子
   · 校准一个数就够：`PHASE_DEG`（8 张整体偏角）/ `K`（压扁程度，默认 0.5）/ 代码 `DIR_CCW`（顺序反了就取反）
   · 代码侧已备好：`ART.cyan8`（dirs 表）+ `FX_DIRS = ART.dirs`；`DIR_MIRROR` 改成**按 ART 项开关**
     （cyan8 = 8 张全量 → 自动 false；以后手画半圈再加 `mirror = true`）
   · modmain 里 `anim/crescent_cyan8.zip` 的 assets 是**条件登记**（文件不在就不登记，免得整个 mod 被禁）
   · 现状：`FX_ART` 仍是 **"cyan"**（单图，已放大 2 倍）→ 方向图打包完再改 "cyan8"
   （换 B/C 版：把 `crescent_b_thick.png` / `crescent_c_double.png` 复制成 `crescent_cyan-0.png` 再导一次）
2. ✅ 生命树枝：`anim/musha_lifebranch.zip` + `anim/swap_lifebranch.zip` 已打包（prefab 自检测，已生效）
   ⏳ 还缺图标：`images/inventoryimages/musha_lifebranch.{png→tex,xml}`（现在的 prefab 会走"无图标"分支，不崩）
3. ✅ 进阶祭坛：`anim/musha_advance_altar.zip` 已打包 → altar prefab 的 `USE_CUSTOM_MODEL` 已改 `true`
4. ✅ 导航图标 7 张全打包完（nav_* .tex/.xml 都是 87KB 真图，不是空壳）
【进游戏要实测】
5. 剑气斩全链路：右键第一下出瞄准圈 → 再点地面出「剑气斩」→ 角色**抬手（atk_pre→atk）** →
   剑气（现在 = **用户自己的亮青月牙** `anim/crescent_cyan.zip`）直线飞出 → 命中掉血
   （日志 `[Musha] 剑气斩 命中 N 个目标`）+ 炸开 + 12 个本地粒子 → 冷却 6 秒（走武器 rechargeable）
   ★ 冷却期**右键应该完全没反应、也不弹字**（2026-09-14 新口径，见 plan 文档 v10）
6. 月牙观感（**2026-09-14 三改**）：
   · 速度：`FX_SPEED` 45 → **22.5（减半）**；命中判定 `FX_HIT_DIST` 0.6 → **1.0**
     （减速后每帧还走 0.75 单位，判定圈太小会"跨帧跳过去"→ 技能空放）
   · 朝向："发出去方向会不同变换" 已修：**去掉 SetFourFaced**（单帧贴图设四面向会被引擎按方位吸附），
     改成原版会飞贴图那套 = `AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)` + 背景层
     （样板：`prefabs/blowdart.lua:44`、`prefabs/crabking_claw.lua` 的 swipefn），
     出手时 `Transform:FacePoint(落点靶子)` 摆正 → 弧口仍不正就改 `FX_ROT_OFFSET`（度）
   · **月牙只有 1 张图，"三面"不存在**：zip 里打进的是 **A 细版**（`crescent_cyan-0.png` 与
     `crescent_a_thin.png` 内容相同）；B 厚版 / C 双弧 都**没进包** → 所以看着"都一样"。
     要换版本：把 `crescent_b_thick.png` 或 `crescent_c_double.png` 复制成 `crescent_cyan-0.png`，
     用 DST Mod Tool 重导一次 scml（代码不用动）
   · FX_ART 仍可切：cyan（现在）/ crescent（原版真月牙）/ jimeng（旧图）/ vanilla
   · **2026-09-14 再调**：① 放大到 **2 倍**（cyan 的 scale 0.45 → **0.90**）
     ② 用户判定"光和面倾斜"= 单图靠 3D 旋转的必然结果（对比洛克人 ZERO 的斩击后确认）；
     要**按方向各画一张**（8 面最好，至少 4 面）→ 代码里已留好开关：
     `musha_slash_qi_fx.lua` 的 **`FX_DIRS`**（表）+ **`DIR_MIRROR = true`（默认开 = 左右自动镜像）**：
     表里只写**半圈**的图 → 另半圈代码用 `AnimState:SetScale(-1,1)` 水平镜像（原版 FX 就这么干）。
     8 面 = 只画 4 张（anim_0/45/90/135）；4 面 = 只画 2 张（anim_0/90）。
     写出名字即启用"按方向选动画、贴图不旋转"；`FX_DIRS = nil` → 退回现在的"单图 + 旋转"。
     角度口径：第 1 项 = 世界 +X、往 +Z 排（反了改 DIR_CCW）；镜像轴不对改 DIR_START_DEG。
     ③ 角度美术未到之前，B/C 版（厚/双弧）依然只靠"换 -0.png 重导"切换
7. 后摇 / 动作：现在 = `quickcastspell`（抬手 atk_pre → 挥出 atk，第 5 帧出手，16 帧解除 busy）。
   想换动作只改 `modmain.lua` 一行 `MUSHA_AOE_CAST_STATE`（注释里列了 6 个候选的观感：
   quickcastspell / combat_lunge_start / castspell / attack / channeling / powerup）
【本期未做，等定】
8. ⏸ 武器技能「4 选 2」的选择 UI + 存 userdata —— **2026-09-14 用户：暂不开放，看后期**
9. 天数奖励系统（存活天数用 `inst.components.age:GetAgeInDays()`）+ 能量水晶 / 水晶剑美术
10. 生命树枝升级机制（满级 18~24）—— 原版样板已找到：`portablefirepit` + `portablestructure`
    （见 `references/portable-structure-notes.md`）
11. Gitee 推送：**实测确认**那把公钥是仓库级**只读部署公钥** →
    `ssh -T git@gitee.com` 回 `Hi Anonymous (DeployKey)!`；`git push` 回 `DeployKey does not support push code`
    → 两条解法（推荐 A，30 秒）：见下「🗂 版本管理（Gitee）」

## 关键参考文档（2026-09-14 新增）
- 🔧 **语法检查（本项目习惯）**：`wsl -d Ubuntu2204 -e bash -lc 'bash /mnt/d/wsl-dl/lua-syntax-check.sh'`
  （脚本内部用真 `luac5.1`；`luac5.1` **只在 WSL 里**，Windows 侧没有，别在 C:/D: 盘找。
  2026-09-14 起 musha 共 **53** 个 .lua，全过）
- `musha-rightclick-spec.md` —— 右键点地技能的两条原版路线 + 三条硬要求（行号级查证）
- `references/portable-structure-notes.md` —— 可移动携带建筑（portablestructure）公式 + 原版样板清单
- `musha-weapon-skill-plan.md` —— 武器技能 v1~v9 全过程（v9 = 直线抛射体 + 本地粒子 + rechargeable 冷却）

## 已落地（能用）
- 🔧 **查原版 API 的正确姿势（2026-09-13 踩坑）**：`data/databundles/scripts/` 那个解包目录是**旧版**，
  行号和实际跑的对不上（追 traceback 会找错地方）。要看当前版本，把 `data/databundles/scripts.zip` 解出来读：
  `unzip -o -q scripts.zip "scripts/componentactions.lua" -d /tmp/gd`
- 🔧 **DST 组件动作（AddComponentAction）当前版本写法**：`actions` 是**数组**，要 `table.insert(actions, ACTIONS.XXX)`；
  旧教程里的 `actions[ACTIONS.XXX].valid = true` 会报 `attempt to index field 'XXX' (a nil value)`（已踩）
- 🎯 本期目标：写完**武器绑定的技能（剑气斩）**就能上架 Steam；**近卫**排下一期（约 3~7 天后）。
  方案见 `musha-weapon-skill-plan.md`（现状/缺的三块/v1 做法/要顺手修的键位 bug/已拍板项）。
- 🎯 新增：**天数奖励系统**（游戏内天数 1/3/10/16/30 送 红宝石×2 / 生命护符 / 生命树枝 / 能量水晶 / 礼包+水晶剑）
  + **缺的美术清单**（用户去画）→ 见 `musha-dayrewards-plan.md`。
  已定的两条：节日礼包按**现实时间**、天数奖励按**游戏内天数**；发放建议复用礼包页 + `musha_claim_gift` RPC。
  战士技能预算修订：主战主动技只有 1 个，其余被动/耍戏；**武器绑定技能 4 选 2、不通用**。
- 面板七页 + 右上三角导航 + 信箱更新日志 + 设置页（**现 7 行**）
- 🆕 2026-09-13 **装备页从"图鉴"里拆出来单独一页**：原 `dex` 页（页名图鉴、内容其实是装备·属性：头/身/手三格 + 12 行属性）
  改 key 为 `equip`、导航标签"装备"，页面内容没动；新建 `dex` = 图鉴**占位页（"内容待定"）**。
  导航现在 **7 行**：主页 / 技能 / 装备 / 信箱 / 设置 / 礼包 / 图鉴（行距 43 不变）。
- 🆕 2026-09-13 导航图标**七张画好**（`images/nav_{home,skill,equip,mail,set,gift,dex}.png`，底板统一：蜡黄渐变 + 深棕描边）：
  主页=用户原图；技能=用户给的枝干线稿（抠白+缩80%+加粗+染深棕）；装备=胸甲；信箱=信封；设置=齿轮（底板薄荷绿→蜡黄、
  齿轮按 154:143 放大对齐主页，文件名 `nav_set`）；礼包=礼物盒；图鉴=放大镜。
  接线（**已去掉开关，改成唯一真源清单**）：`scripts/musha_nav_icons.lua` 列出七张，`modmain.lua` 按它注册 assets，
  `musha_panel_screen.lua` 按它画图标（图标 28x28 放 x=-41、文字右移 8）；**缺 tex 时 pcall 兜住**，该行只显示文字+日志一行。
  打包进度：nav_home / nav_mail / nav_set 已打包可用；nav_skill / nav_equip / nav_gift / nav_dex 待打包（用户整批转一次即可）。
  步骤见 `images/nav_icons_README.txt`；总览图 `images/_nav_all7.png`、实际大小 `images/_nav_real28.png`；
  工作文件 `images/_nav_plate_clean.png`（抹掉房子的干净底板，以后画新图标直接用）。
  坑：用户那批工具转出来的中文名（主页/技能/信箱/设置.tex）xml 只有 15 字节=空壳，没用；已删。无代码引用的 `_fx_slash_*.tex`
  （1.4M）也删了。`bookpage_bg V2.tex`(5.3M) 与 `bookpage_bg.tex` 内容重复，待用户定要不要删。
- 🆕 2026-09-13 体积清理（用户：多的删了）：`images/` **39M → 20M**。
  删：`bookpage_bg V2.tex/.xml`（与 bookpage_bg.* md5 完全相同，只是工具重名的副本）、中文名 tex 空壳、`_fx_slash_*.tex`。
  挪出 mod（没删，发布时不该打进包）：`images/_bak/`（8.5M，旧书页三件套）→ `C:\Users\Administrator\musha-backups\images_bak_20260913\`；
  `images/note_bg.{tex,xml,png}`（4.7M，全项目 0 引用，已被 musha_note_bg 取代）→ `C:\Users\Administrator\musha-backups\`。
- 技能页：战士技能树 + 粉加号加点；**新增「未学习 / 已学习」两个文字项目切子页**
- 进阶祭坛：真 prefab `musha_advance_altar`（动画占位=原版麦斯威尔雕像，移植点=文件头 3 个常量）
- 转职任务：**5 级门槛已补**（ADVANCE_MIN_LEVEL=5，musha_quest.lua）；3 轮制，第 3 轮完成 → 进阶 + 发技能书
- 每日任务：自动发放 N 个（设置页可改 1~10），跨天 discover 作废
- 战士「战斗恢复」：常驻 tick，脱战 3 秒后每秒回血

## 🧹 上线前清理清单（越攒越长，发布前逐条过）
1. **剑士转职书（测试专用，直通二转）** —— 删 3 处：
   `scripts/prefabs/musha_jobbook_saber.lua` + modmain 的 `PrefabFiles` 里那一项 + STRINGS 的 `MUSHA_JOBBOOK_SABER`
   （modmain 里已写注释提醒；正式二转走祭坛 3 轮任务）
2. `scripts/musha_gifts.lua` 里的 `dev_test_gift`（测试礼包：噩梦燃料x3 + 金块x5）
3. 美术占位：祭坛配方图标（现用 musha_note 的图）、剑士转职书图标/动画（借用战士职业书）、技能页整页占位
4. 设置页 6 行底部空一格（要不要居中等用户给数字）

## 📐 技能预算（2026-09-13 用户拍板，同日二次修订 —— 全局规则，防放飞）
- **每个职业的「正式」技能 = 1 个主动技 + 1 个武器技能（共 2 个）。其余全部转入「备份」：数据留档、不上技能页、不实现。**
- **战士基调 = 走 A（走位 + 平A）为主，不靠技能** —— 技能只是点缀，数值不许盖过平A。
- 剑士（saber）：
  - 主动技 = **剑气斩 / 月牙斩**（数据草案已加，特效 prefab `musha_slash_qi_fx` 已建，缺施法框架）
  - 武器技能 = **绑定月牙斩**（= 方案 c：**不另做技能**，"武器技能"就是月牙斩本身，按施法键消耗能量放月牙）
  - 被动 = **「我，活着」**（原名背水一战，已实现，血量≤50% 自动回满，冷却 80 秒）—— 已实现，保留生效
- 战士（warrior）现有两条被动 **战斗恢复 / 武器精通** 保留生效（不占额度、不动代码）
- ❌ **备份区（数据留档，不实现、不上页）**：
  - **旋风斩 whirlwind** —— 用户原话「极难做」
  - **横扫 slash** —— 用户原话「有待考虑，或看赞助」
  - **战吼 war_cry** —— 同上，无正式排期
  - 破甲 / 连击 / 吸血 / 命中强化 —— 已否决
- **后续所有职业统一按这个标准（1 主动 + 1 武器技能）**；**唯一的例外是魔法师**（可多）
- ⚠️ 数值提醒：`musha_skill_data.lua` 里的 `MUSHA_SKILLS_*` 表**没有任何消费方**（只 modimport，无代码读），
  所以"备份"= 改注释即可，不影响运行

### ✅ 2026-09-13 用户问「原来的战后回血呢」→ 还在，没删
- 战士被动 **「战斗恢复」combat_recovery** 完整保留：`musha_profession_component.lua:364`（数据）+ `CombatRecoveryTick()`:527（逻辑）
  - 3 级：11% / 18% / 22%（`level_effects`），解锁 0/3/5 级
  - 触发：服务端 + 战士 + 等级>0 + 活着 + 未满血 + **没有攻击目标** + 距上次交手 > `REGEN_COMBAT_GRACE` → 每秒 `health:DoDelta(heal)`
  - 技能页 `SKILL_ORDER.warrior = { "combat_recovery", "weapon_proficiency" }` → 战士技能页会显示这两条
  - 本轮摘掉的只有**剑士树**的「吸血 / 命中强化」，跟战士的战斗恢复无关

## 🎙 台词工程（2026-09-13 第一批已完成；做法 = **A：直接改现有语音文件**）
用户原话：「复查一遍翻译 看看是否有翻译错误，把musha台词改一改，做成灵动感，可以和原来不符，韩语翻译过来全是死感，做一份日语，剩下自行发挥」

### 🐛 先说挖出的真 bug：4 份台词文件**从来没被加载过**（已修）
- 原因：`AddModCharacter` 不会加载台词（DST 只对原版角色 `require speech_xxx`），而 modmain 里**没有任何引用**
  → `scripts/speech_musha_{zh,en,ko,ru}.lua`（约 6500 行）一直是死文件，Musha 说的全是 GENERIC 台词
- 修：`modmain.lua` 的「语言加载」Safe 块里按 `Profile:GetLanguageID()` 挂
  `STRINGS.CHARACTERS.MUSHA = require("speech_musha_" .. suffix)`，缺文件自动回退 en
  （语言 id：16=RU 19=KO **20=JA** 21/22/23=中文）
- 顺带：`STRINGS.MINGSHENG = require "speech_mingsheng"` 明生那边写法是对的，可作参照

### ✅ 第一批交付（全部 luac5.1 通过；45 个文件全过）
| 文件 | 改动 |
|---|---|
| `speech_musha_zh.lua` | ① 135 处纯英文台词 → 中文（原 140 → 剩 5，那 5 条是 PORTAL/CHEAT 之类可留）② ANNOUNCE 系 80 条全部改写成活泼口语（例：`ANNOUNCE_COLD` = "冷死了冷死了！Musha的耳朵要冻掉啦！"） |
| `speech_musha_ko.lua` | 199 条去「死感」重写（口语终结词尾、孩子气），键名/占位符/行数 0 变化 |
| `speech_musha_jp.lua` | **新建**（1710 行，键名与 en 100% 一致）：ANNOUNCE 78 + PLAYER 6 + MUSHA_* 77 共 165 条日文；其余保留英文待第二批 |
| `modmain.lua` | 台词挂载修复（见上）+ 日语 id 20 支持 |

### ✅ 日语版已 100% 完成（2026-09-13 夜）
- `speech_musha_jp.lua`：**1710 行 / 1060 个键**，与 en 母本键集合 **0 差异**
- 全部文案翻成日文（自称「ムシャ」、子ども口吻「〜なの」「〜だよ」）；**1125 条英文条目全翻完**，
  连漏网的单引号行（`FIRESTARTER`/`ATTACKER`/`GHOST`×2，值用 `'...'` 写的）也补了
- 复验：`luac5.1` 46 文件全过 ｜ 双反斜杠转义 0 处 ｜ 活动行里纯英文残留 **0**
- 备份链：`C:\Users\Administrator\speech_musha_jp.lua{,.bak,.batch2,.batch3,.prebatch2}`
- 桌面副本（给用户看的）：`C:\Users\Administrator\Desktop\speech_musha_jp.lua`

### ⏭ 剩下的台词活
- zh：DESCRIBE 约 500 条中文待"灵动化"（ANNOUNCE 已做完）
- ko：剩余长句
- ru：整段 DESCRIBE 缺失（要不要补待定）

## 🗂 版本管理（Gitee）—— 2026-09-14 实测结论
- `musha` 目录已是 git 仓库，remote = `git@gitee.com:ZeroCiel/musha-remastered-edition.git`（SSH）
- **根因定死了**：`~/.ssh/id_ed25519` 这把公钥在 Gitee 上是**仓库级「部署公钥」= 只读**
  · `ssh -T git@gitee.com` → `Hi Anonymous (DeployKey)! ... DeployKey only supports pull/fetch`
  · 真推一次 → `Auth error: DeployKey does not support push code`
  · 用户"重复设置只提示密匙已有"= Gitee 的公钥是**全局唯一**的，同一把不能既当部署公钥又当账号公钥
- ✅ **解法 A（推荐，30 秒，不用动本机）**：Gitee 网页 → 该仓库 → 管理 → **部署公钥** →
  找到 `musha-gitee` 那把 → 编辑 → 勾 **「启用推送权限」** → 保存 → 我再 `git push` 验证
- ✅ **解法 B（更干净，一把钥匙通吃所有仓库）**：
  1. 网页 → 仓库 → 管理 → 部署公钥 → **删掉** `musha-gitee`
  2. 头像 → 设置 → 安全设置 → **SSH 公钥** → 添加下面这把新钥匙
     （已在本机生成好了：`~/.ssh/id_ed25519_gitee`，无口令）
     ```
     ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICsrfD2DBoKCrNn521OboR+y1UiFFwZbr9Wvs7Pj6FEM musha-push-2026-09
     ```
     ⚠️ 必须**先删部署公钥**再添加，否则还是"密匙已有"（全局唯一）
  3. 说一声，我加 `~/.ssh/config`（Host gitee.com → IdentityFile id_ed25519_gitee, IdentitiesOnly yes）
     并跑 `ssh -T` + 真推验一次
- 待提交：**71 个文件**（多为 exported/anim 的 zip 变更）
- 📌 提醒：公钥/令牌是凭据，贴过聊天建议轮换

## 📌 队列（用户 2026-09-13 指定，做完台词就回去做）
1. **检查 Show Me 的问题**（悬停信息面板那套；`scripts/widgets/musha_item_info.lua`）
2. **装备栏抠出来单独放外置** —— 装备/属性那块从面板里拆出来，做成独立文件/独立窗口
3. 能量球 `exported/energy/heart/*.png`（叶子）已提亮（52/166/231 → 91/195/241），**等用户重打包 energy.zip 验证**

### 🎨 2026-09-13 UI 微调
- **能量条（能量球）着色 V2**：`#99d5ff` → **`#b5e8f5`（淡水蓝：更淡、偏青）**
  - 改的是贴图：`exported/energy/health_level/*.png`（23 张，按亮度比例整体重映射）
  - 备份：上一版淡蓝 `exported/energy/_v1_paleblue/`；最原始红版 `exported/energy/_orig_red/`
  - ⚠️ **贴图改完必须重新打包 energy 才生效**：DST Mod Tool 把 `exported/energy/energy.scml` 打成 zip → 覆盖 `anim/energy.zip`
  - 想再换色：改 `T`（目标色）重跑同一段脚本即可，10 秒；不用动 scml
- ⏸ **延后（2026-09-13 用户口头）**：**从 Show Me 移植过来的那套版本延后** —— 悬停信息面板 / 装备·属性面板
  先不继续推进、不再改（已实现的部分留着，bug 先不修）
- ⏸ **纯 Python anim 打包器：暂不做**（用户 2026-09-13：暂时不用）→ 能量/贴图仍走 DST Mod Tool 手动打包
- 💡 **待议点子（2026-09-13 用户口述，原话"走远了"，先不动）**：装备那一列别做成面板里的一页，
  改成**普通常驻 UI 窗口** —— ① 放屏幕**右下角、小地图附近** ② **支持拖拽** ③ 设置面板加个小开关，按一下才显示
  ④ 攻击时窗口里还能看到**敌人数据**（"走远了"= 本次不做，只记录）
- 礼包页位置（**最新 2026-09-14 第三次调**）：标题「礼包」`gift_head` **(x=-263, y=254)**
  （历史：-3 → 左移3 → 左移220 → 再左移40 + 上移12）；
  提示 `gift_hint` **跟随标题**：挂"标题右下角 -15,-15"+额外右移 120 → **(-126, 223)**
  （`musha_panel_screen.lua:862` 起；常量 GIFT_HEAD_X/Y、HEAD_HALF_W/H=32/16、HINT_GAP=15、HINT_EXTRA_X=120）
  · 礼包行容器 `gift_body` 仍是 `(0, 175)`（没动；历史：-20→180→170→175）
- **技能改名：背水一战 → 「我，活着」**（`SKILL_UI.saber.last_stand.name` + 触发字幕 `talker:Say("我，活着！")`）
- **悬停信息面板不再跟鼠标** → 固定钉屏幕**右下角**（`musha_item_info.lua:PinBottomRight()`，MARGIN=24；
  旧 `FollowMouse` 整段注释保留，想改回换名字即可）
  - 用户已实机确认「图鉴（悬停面板）能看到蜘蛛伤害」= 该功能**验证通过**（① 待验项可划掉）

### 📐 2026-09-13 新需求：装备/属性面板（网游式）
- 用户：「武器和装备一类最好我们也能看得到，做成网游面板那样的显示吧？」
- **设计稿已写：`musha-design-equip-panel.md`**（含版式/数据来源/分期 V1-V3/坑清单）
- ✅ **V1 已实现（2026-09-13）**：原「图鉴」页占位 → 改成「装备 · 属性」页
  - 左列 3 个装备格：头/身/手（图标 + 名字 + 关键数值一行）；右列 12 行属性
  - 12 行 = 生命 / 饥饿 / 理智 / 能量MP / 攻击力 / 减伤 / 移速 / 保暖 / 隔热 / 职业 / 等级·经验 / 技能点
  - 代码：`musha_panel_screen.lua` 的 `self.pages.dex` 块 + `MushaPanelScreen:RefreshEquip(md)`
    （`Refresh()` 和 `SetActivePage("dex")` 里各挂了一处）
- 🔧 2026-09-13 加固（用户报"装备部分不显示"，日志里**零报错** → 全是 pcall 静默失败）：
  - 12 行标签/占位符改为**建页时写死**（`ROW_LABELS` + 值默认 "—"）→ 刷新链路断了也不会一片空白
  - 装备读取改三条路兜底：`replica.inventory:GetEquippedItem` → `player_classified:GetEquips()[slot]`
    → `replica.inventory:GetEquips()[slot]`（客户端拿装备只有这几条路）
  - `item:GetDisplayName()` 从裸调用改 `pcall`（某些实体没这个方法 → 原来会整页炸）
  - 悬停面板 `GetMouseTarget` 改为**沿 parent 链找 `.item`**（原来只认 `widget.parent.item`，
    背包格能认、**装备栏格子认不到** → 悬停已装备物品不出面板）
  - `EQ.DEBUG = true` 诊断：打开装备页会打印 `[Musha Equip] md=… 数值表=… 装备 head=… body=… hands=…`
- 用户要求：**照 Show Me 那套"翻译过来改成我们格式"做**（他自己手写花了 3 天，别从零设计）
  - Show Me 源码：`mods/workshop-2188103687/modmain.lua`（**单文件 2449 行** + showme_chs.lua 等语言表）
  - 我们复用的读法：`c.armor.absorb_percent` / `c.insulator.insulation` / `c.weapon` / 静态数值表

### 🔑 2026-09-13 关键事实：DST 客户端**读得到 / 读不到**什么（血泪换来的，别忘）
| 想读 | 客户端能不能读 | 正确取法 |
|---|---|---|
| 玩家自己装备 | ✅ | `p.replica.inventory:GetEquippedItem("head"/"body"/"hands")` |
|   | ❌ | `p.components.inventory`（服务端专有）、`Inventory:GetEquips()`（**这版不存在**）|
| 物品图标 | ✅ | `item.replica.inventoryitem:GetAtlas()` / `:GetImage()` |
| 生命/饥饿/理智 | ✅ | `p.player_classified.currenthealth / maxhealth`（同名 netvar，`:value()`）|
|  | ✅ | 或 `p.replica.health / hunger / sanity`（**没有 GetMax**，最大值得走 player_classified）|
| 能量 MP | ✅ | `p.Musha_MP` / `p.Musha_MP_MAX`（本 mod 自己在 prefab 里加的 net_float）|
| 武器的伤害 / 护甲减伤 / 保暖 | ❌ | `item.components.weapon/armor/insulator` **客户端全是 nil**（写在 prefab 的 `master_postinit` 里，客户端只跑 `common_postinit`）→ 用 `musha_item_stats` 静态表 |
| 最终造成的伤害 | ❌ | 本版 `Combat:GetDamage()` **不存在**，伤害在 combat.lua 内部 `local CalcDamage()` 里算 → 要显示必须加 RPC 让服务端算 |
- `musha_item_stats.lua` 2026-09-13 补扫了 **39 条** `absorb`（护甲减伤）+ `speed`（移速倍率，<1 是减速）= 客户端读装备数值的唯一来源

### 🐑 2026-09-13 天使羊波波 —— **用户已明确搁置**（形态 = 宠物，先不做）

## 🗡 主动技能（⑤）资料与决策（2026-09-12 晚用户拍板）
### ✅ 2026-09-12 已落位的数据改动（`musha_profession_component.lua` + `musha_skill_data.lua`）
- 战士：❌ 狂暴 已删、❌ **铁壁 已删**（撞近卫钢铁意志）；🆕 **剑气斩 slash_qi**（草案 100/130/160%，3 级，需求 5/10/15）
- 剑士：🆕 **背水一战 last_stand** —— 血量 ≤50% 时回满，**仅 1 次**｜7 级可学｜**消耗 3 技能点**
  - 数据进 `self.saber.last_stand`（max_level 1 / unlock 7 / skill_point_cost {1}=3）
  - **存档接好了**：OnSave/OnLoad 都加了（含 `used` 标记）——不加这段的话重进游戏技能等级会归零（老坑）
  - SKILL_ORDER / SKILL_UI 都补了 → 技能页会显示「背水一战 / 血量低于 50% 时可回满生命（仅 1 次）/ 7 级可学·消耗 3 技能点」
- ❓ **待用户定（两个岔路）**：
  1 触发方式：a 被动自动触发（现在就能做）｜b 主动按键触发（要做主动技能框架）
  2 "仅限 1 次"的范围：每场战斗 1 次 / 每个存档 1 次 / 每天 1 次

### ✅ 2026-09-12 深夜用户拍板：last_stand 触发方式 = a 被动自动 + 冷却 80 秒（不是"仅1次"）
- `LAST_STAND_COOLDOWN = 80` / `LAST_STAND_THRESHOLD = 0.5` 两个常量在 `musha_profession_component.lua` 顶部（REGEN_TICK 旁）
- 实现：复用已有的 1 秒常驻 tick → `LastStandTick()`（服务端 + 剑士 + 等级>0 + 活着 + 血量 ≤50% + 冷却好）
  → `hp:SetPercent(1)` 回满 + talker「背水一战！」+ `PushEvent("musha_last_stand")`
  → 特效/音效素材（用户要画）接在这个位置，现在留空
- 存档：OnSave/OnLoad 从 `used` 改成 `cd_end`（GetTime() 绝对时间，跨存档有效；旧档 used 字段自动丢弃）
- 客户端数据：`PushSettings()` 新增 `d.cooldowns.last_stand = { total=80, end_at=, remain= }`
  ⚠️ remain 只是推送那一刻的快照，**不是实时**：客户端要实时倒计时要自己按本地时间倒数或改走 RPC
- 面板文案已更新：「血量低于 50% 时被动回满生命（冷却 80 秒）」/ tip「7 级可学 · 消耗 3 技能点 · 无需按键，自动触发」
- 语法检查 41 个文件全过；⏳ 待实机验证

### 📌 明天（2026-09-13）要做（用户要求提醒，已建 cron：2026-09-13 10:00 一次性）
1 技能冷却 UI（吃 `d.cooldowns`）
2 能量（MP）UI
3 **用户要画美术**：能量 / 冷却的图（图标 + 冷却圈素材）
4 打包 tex 通道（2026-09-12 查证）：本机 **ktech 两头都废** —— tex→png 报缺 RGBA 模块、
  png→tex 报缺 PNG 模块（根因都是 ktools/coder.xml 的格式→模块映射表是空的）
  → 打 tex 只能用 GUI（D:\饥荒开发\tool\DST Mod Tool.exe 的 pack tex / textool）或另写打包器
  → 已自建 tex→png 替代：`桌面\tex导出工具\tex2png.py`（纯 Python 解 DXT，21/21 通过）

### 🎨 2026-09-12 深夜 美术口径与素材进度
- **能量色拍板 = 淡蓝**：悬停面板 `COL.mp` 已从淡青改 `{0.70, 0.90, 1.00}`（⚠️ 与「隔热 淡蓝」色系撞，靠亮度区分）
- **染色工具**：`桌面\tex导出工具\recolor.py`（纯 Python，保明暗/透明，可调 --hue/--sat/--bright）
- **health 图集染蓝（进行中）**：`桌面\DST官方血条UI\anim\health\atlas-0_淡蓝.png` 已出预览
  （512x256，不透明 37262 px，其中红色 31548 px = 84.7% 已变淡蓝）
  该图集结构（连通块 29 个）：**24 块红色分段**（高度 11→55px 一排 = 等级条）+ 3 颗红心（右上，黑描边）
  + 1 个黑圆环 67x70（左下）+ 2 个 52x52 圆（中间，棕褐 / 近白）
  ❓ 用户说「除了 22 全部染蓝」—— **"22" 未对上**（是最大那块？第22块？还是第22帧？）待确认
- **面板底图 V2**：`musha/images/bookpage_bg V2.png` = 1644x1109（去掉水印）vs 旧 `bookpage_bg.png` 1232x832
  · 比例 1.4824 vs 1.4810（差 0.1%）→ 面板 `BG_W/BG_H = 1232x832` 基本不用改
  · ⚠️ 1109 > 旧图集画布高 1024 → 重打包要开 **2048x2048** 画布并重算 xml uv
    （旧 xml 裁 (0.5,192.5)-(1231.5,1023.5)）

### 🛠 2026-09-13 上午（三项 UI 改动，已过语法校验）
1 **技能页列表改成可滚动**（用户："未学习那个照信箱的，可以向下滚动"）
   - `musha_panel_screen.lua`：`self.skill_body`（普通 Widget 手排 y）→ **`self.skill_grid` = TEMPLATES.ScrollingGrid**
     配 `SKILL_item_ctor` / `SKILL_apply_fn`（item 复用；加点按钮按 id+can 变化才重建）
   - 新增常量：`SKILL_ITEM_W/H`（840x170）、`SKILL_VISIBLE = 2`；网格位置 `SetPosition(0, 130)`
   - `RefreshSkills` 尾部大段手排行代码删除 → 只留 `self.skill_grid:SetItemsData(list)`；空状态时传 `{}`
   - ⚠️ 配套重构：`SKILL_ROW_*` 常量块 + `SkillText()` **上移到文件顶部**（item_ctor 构造期要用；
     Lua 局部作用域：后面声明的 local 前面的闭包看不到）
   - 📌 注意：**信箱页其实是"翻页"（MAIL_PER_PAGE + 页码）不是滚动** —— 按用户原话"可向下滚动"做成滚动，
     若他要的是翻页需改
2 **测试礼包已删**（`scripts/musha_gifts.lua` 移除 `dev_test_gift`）→ 礼包页现在显示"当前没有可领取的礼包"
   （老存档 userdata.gifts 里那条记录不受影响）
3 **礼包框上移 5 像素**：`gift_body` y 170 → 175
4 语法校验：**41 个文件全部通过**

### ⏭ 能量页面：改为「官方挂载」（用户 2026-09-13 决定，等他给例子）
- 用户原话："能量页面 改成官方挂载 我去给你找下例子" → 暂不猜着写，等例子对齐再动手
- 我理解的"官方挂载" = 不塞在面板页里，照官方 HUD 做法挂（`AddClassPostConstruct("widgets/controls")` 或
  player_classified 那套，把能量条当 HUD 元素跟三围一起显示）
- 手上已有料：`musha/anim/energy.zip`（bank/build = energy，23 帧 anim，atlas 512x256，level 已染淡蓝，
  实测偏蓝 82%）；`d.cooldowns.last_stand` 已推给客户端

### ✅ 2026-09-13 能量条：按「官方挂载」落地（照用户给的例子 workshop-2254434122 遗迹守卫）
**例子读到的官方三件套**（比我原来猜的干净）：
- `Badge._ctor(self, anim, owner)` 里 anim **既是 bank 也是 build 名**，基类内部 `SetBank(anim)+SetBuild(anim)+PlayAnimation("anim")`，
  进度 `SetPercent("anim", 1-percent)`，数字 `math.ceil(val*max)` → **anim/energy.zip（bank/build=energy、动画=anim）严丝合缝**
- 数值同步走 **netvar**（prefab 里 `net_float`）+ Class setter 自动 set，**不用 RPC/PushSettings**
- 挂载点 = `AddClassPostConstruct("widgets/statusdisplays")`（**不是** widgets/controls，我原来猜错了）；
  位置照 stomach/brain/heart 推；hook `SetGhostMode` 处理死亡隐藏
**本次新增/改动**：
1 `scripts/components/musha_mp.lua`（新）—— 能量组件：`current`/`max` setter→netvar、`RefreshFromClass()` 读职业表算上限/回复、
   `Tick()` 每秒自检（换算上限 + 回能量）、`CanAfford/Spend` 给以后技能花费用、OnSave/OnLoad
2 `scripts/prefabs/musha.lua` —— common 加 `inst.Musha_MP`/`inst.Musha_MP_MAX`（net_float）；master `AddComponent("musha_mp")`；
   assets 加 `anim/energy.zip`
3 `scripts/widgets/musha_energy_badge.lua`（新）—— `Class(Badge)`：`Badge._ctor(self, "energy", owner)`；OnUpdate 读 netvar → SetPercent
4 `scripts/widgets/musha_energy_registered.lua`（新）—— 挂进 statusdisplays（HasTag musha）+ 位置 + SetGhostMode
5 `modmain.lua` —— Assets 加 `anim/energy.zip` + `Safe("能量条挂载")` modimport
- 语法校验：**44 个文件全部通过**；⏳ 待实机验证（球应该出现在三围旁边，满值，因为还没有技能消耗 MP）
- 职业表 MP 设定（`class_traits`，用户提醒"每个职业都不一样"）：上限 = `mp_base + mp_max_growth × 等级`
  warrior 80+2.5/级、guardian 240+3、mage 60+12(20级300)、rogue 80+2(20级120)、ranger 120+1.5(20级150)；
  回复 warrior 0.5+0.02/级、guardian 固定1.2、mage 2.4+0.08、rogue 1.1+0.112、ranger 0.84+0.35；
  二转树（saber/moonshadow/elementalist/bard）无 MP 字段 → 继承基础职业

### 🐛 2026-09-13 第二批修复（用户报的 4 条）
1 **剑士树摘掉「命中强化」+「吸血」**（用户："命中强化意义不存在"、"吸血战士不应该要"）
   - 命中强化 = 空数值（**DST 没有命中率，攻击必中**）；吸血 与近卫「生命偷取 life_leech」重复（违反"技能不重叠"）
   - 两条**没有任何消费方实现**（全项目只有定义 + 存档引用）→ 摘掉零风险
   - 改 4 处：`self.saber` 树定义（注释保留数据备查）、`SKILL_ORDER.saber = {"last_stand"}`、
     `SKILL_UI.saber`、OnSave/OnLoad（旧档里这两项直接丢弃，不报错）→ **剑士树现在只剩「背水一战」**
   - ❓ 待用户决定是否补新技能（候选：剑气斩 / 破甲 / 连击）
2 **「击败五只火猎犬」不计数** —— 真因：**火猎犬身上没有 "fire" tag**
   - 原版 `prefabs/hound.lua:643` `fnfire → fncommon("hound","hound_red_ocean",{"hound","icehound"},…)`
     → tag 实际是 `{"hound","icehound"}`（Klei 这写法很怪）→ `HasTag("hound") and HasTag("fire")` 永远为假
   - 修：改按 **prefab 名** `firehound` 认（原 tag 判定留作兜底）
3 **噩梦燃料"没被消耗"** —— 真因：进度来自 modmain 的 `SetOnPutInInventoryFn` 钩子，
   **该钩子在物品真正进包之前触发** → 完成那一刻第 7 个还没进包，当场只能扣到 6 个
   - 修：`CompleteDailyQuest` 里把 `ConsumeQuestItems` **延一帧**（`DoTaskInTime(0)`）再扣 + 加调试日志
4 语法校验：**44 个文件全部通过**；⏳ 待实机验证（记得验完把 `DEBUG_QUEST` 关回 false）

### 🐛 2026-09-13 任务判定修复（用户连着报两条"没效果"）
1 **「建造一个科学机器」**(id13 / craft_science) 从来没计过数
   - 根因：判定写的是 `data.recipe.name == "science_machine"`（自造名），
     而**原版科学机器的配方名是 `researchlab`**（`prefabs/scienceprototyper.lua:299` `createmachine(1,"researchlab",...)`）
   - 修（`musha_quest.lua:OnCrafted`)：同时认 recipe.name 与 item.prefab 的 `researchlab`/`sciencemachine`，
     并把 `researchlab2`（炼金引擎）也算完成
2 **「见到龙蝇」**(id1) / 「找到格罗姆」(id4) / 「找到海象营地」(id11) 发现类三条都失灵
   - 根因（`modmain.lua` 发现检测）：`inst._musha_discovered_xxx` 是**一次性标记且从不清除** →
     玩家早先路过龙蝇时标记已被打上，等任务日后抽到它时永远不再触发（主因）；
     另外海象那条查的 tag `"walrus"`，而**海象营地 prefab 是 `walrus_camp` 且不带这个 tag** → 营地永远不算
   - 修：改成每 5 秒扫周围 30 格、按 **prefab 名**认（dragonfly/glommer/walrus_camp/walrus），
     标记 **`WatchWorldState("startday")` 每天重置**（发现类本来隔日作废）
3 **「建造一个科学机器」修完还是没反应 → 真因是"事件听错了"**（用户提醒"建造监听有好几个不同"）
   - 原版 `builder.lua` 的事件链（读完整个文件后确认）：
     `unlockrecipe`{recipe} → 首次解锁配方（profession 组件的配方经验挂的就是它 ✓）
     `consumeingredients` → 扣料 · `makerecipe`{recipe} → 每次**发起**制作（物品+建筑都发，但是"发起"不是"完成"）
     **`builditem`{item,recipe,skin,prototyper}`（:739）→ 产物进背包（物品）**
     **`buildstructure`{item,recipe,skin}`（:819）→ 产物直接落地（建筑）**
     `refreshcrafting` / `techtreechange` / `hungrybuild` → 状态提示类
   - 科学机器是 **placer 配方**（`recipes.lua:371` `{placer="researchlab_placer"}`）→ 成功走 **buildstructure**，
     只听 builditem **永远收不到** → 上次我只改了配方名（`science_machine`→`researchlab`）所以还是没反应
   - 修（`musha_quest.lua`）：**两个事件都听**（DoBuild 里是 if/else 互斥，不会重复计数）；
     id13 命中 researchlab/researchlab2 的 builditem **或** buildstructure 都算；id7「制造20个物品」只记 builditem（真·物品）
   - 临时调试：`DEBUG_QUEST = true`（musha_quest.lua 顶部）→ 每次建造打
     `[Musha Quest] builditem|buildstructure: recipe=xxx prefab=yyy`，换天打当前任务列表。查完关掉
- 语法校验：**44 个文件全部通过**；⏳ 待实机验证

### ❌ 决策：不加「耐力（stamina）系统」（2026-09-13 用户问"给个准"，助理拍板）
- **结论：不做。** 理由：
  1 资源已经有 4 条（生命 / 饥饿 / 理智 / 新的能量MP），DST 玩家舒适区是 3 条视觉+1 条技能资源，
     再加耐力＝第 5 条 → 每时每刻要盯的东西太多，最容易被评价为"累"
  2 用户担心的"寿命"问题推演成立且更严重：DST 一天约 8 分钟，玩家节奏＝出门采集/打怪→做饭→过夜。
     耐力若强制睡眠，等于每天砍掉 1/4~1/3 可玩时间，而每日任务（杀20蜘蛛/5次锅/建科学机器）难度不变
     → **3 天一睡变 1 天一睡不是"受不住"，是任务根本做不完**
  3 数值面翻倍：MP 已按职业×等级算（每职业上限/回复不同），再叠一条耐力就要再乘一遍职业系数；
     一旦玩家觉得被卡，验收前返修 → 违反"范围/返修先钉死"的订单原则
- **若将来真要上，唯一可接受形态（分期 + 可开关，默认关）**：
  一期＝只显示 + 轻惩罚（消耗：奔跑/挥砍/采矿；耗尽只"移速 -20% / 不能奔跑"，**不强制睡眠、不扣血、不影响任务**）；
  二期＝等一期实测反馈再谈"强制休息"，且必须与饥饿/理智联动（睡一次同时回耐力）
- **硬规矩：不要开第 5 条资源条** —— 真要加就复用 `musha_mp` 组件（一条资源两种用途）
- 成本参考：官方只有 `sleeper`（怪）/ `grogginess` / `sleepingbaguser`，**玩家耐力要自己写**；
  组件+netvar+badge+消耗点 hook ≈ 半天~1 天。能做，但不划算 —— 现阶段优先把 MP/冷却/任务链打磨到能验收

### 官方技能/施法配套组件（2026-09-12 查证）
- `skilltreeupdater`（官方技能树：IsActivated / HasSkillTag / ActivateSkill → 推 `onactivateskill_server`）
- `spell` / `spellcaster` / `spellbook` / `spellbookcooldowns` / `aoespell`（法术/法术书 + 书页冷却）
- `channelcastable` / `channelcaster`（蓄力/持续施法）
- `cooldown`（通用冷却：StartCharging / GetTimeToCharged / IsCharged）
- `debuff` / `debuffable`（破甲/流血/挑衅这类）
- 最佳抄本：`prefabs/battlesongs.lua`（女武神战歌 = 释放即生效的团队 buff）
- 剑气斩释放链路（6 步）：按键 → RPC `musha_cast_skill` → 服务端校验 → 前摇动作 → spawn 剑气 effect 前推 →
  命中判定+伤害结算 → 挂 `cooldown` 冷却 → 面板显示剩余冷却
### 数据在哪
- **现役**：`scripts/skills/musha_skill_data.lua`（modmain 第 423 行 `modimport` 进来）——
  战士主动技能数据齐全（横扫/铁壁/战吼/旋风斩/剑气斩）+ 刺客背刺；
  UI 壳 `scripts/components/musha_skillui.lua` 会调 `GetJobSkillList`，但**全项目没人挂它** → 从没显示过
- **旧档案副本**：`musha/.mobius/skills/dst-modding/references/musha_skill_data.lua`
  多出：法师(火球术/寒冰护盾/闪现/闪电链)、游侠(精准射击/箭雨/陷阱/鹰眼)、刺客(潜行/毒刃/暗影步)
- **设定文档**：`hermes/skills/gaming/dst-modding/references/musha_jobsystem.md`（暴击40% / 猎杀150% /
  专属武器放剑气取代按键技能 / 位面武器暴击3倍）

### 用户 2026-09-12 的改动与意见
- ❌ **狂暴 berserk 已删**（"我记得没设计这个"）
- ❌ **铁壁 ironwall 已删干净**（2026-09-12 复查：lua 里 0 处残留，只剩 `musha_skill_data.lua:36` 一行墓碑注释
  ＋ `./.mobius/` 里的旧档案副本，那俩不影响运行）
- 🆕 **剑气斩 slash_qi 已加**（草案数值 100/130/160%，3 级，需求 5/10/15）——表现：**月牙飞出去、命中就结算伤害**
  （原定"冲击波"）；数值/冷却待定
- ⚠️ **战吼 与 女武神(Wigfrid) 撞了** —— 需要替代方案
- ⚠️ **铁壁 与 近卫(钢铁意志) 撞了** —— 都是减伤，需要替代方案
- 🚫 原则：**不要和同职业/其他职业重叠**

### 🌙 月牙/剑气 特效候选（原版 anim，可直接 `Asset("ANIM", "anim/xxx.zip")` 用）
1 `brilliance_projectile_fx` ← 光辉(亮茄系)能量抛射，**最像"飞出去的剑气"**
2 `shadow_thrall_projectile_fx` ← 暗影系抛射（黑红，适合暗影主题）
3 `crabking_claw_swipe_fx` / 4 `daywalker_swipe_fx` / 5 `sharkboi_swipe_fx` ← 三款**弧形挥砍光**
6 `wave_hurricane` / `wave` ← 冲击波/浪（原定"冲击波"直接有现成）
7 `wagboss_beam` ← 光束；8 `staff_projectile` ← 通用弹道
- ✅ **2026-09-12 用户已选定：2 `shadow_thrall_projectile_fx`（暗影系抛射，黑红）**
  → 已建 effect prefab：`scripts/prefabs/musha_slash_qi_fx.lua`（bank/build/anim 5 个常量在文件头，
    平飞 gravity=0 / speed=13 / 1.5 秒兜底自毁 / `inst.cast_hit` 回调留给 ⑤ 框架做伤害结算）
  → 已进 modmain `PrefabFiles`；语法检查 41 个文件全过
  → 素材实测存在：`data/anim/shadow_thrall_projectile_fx.zip`，动画 = `projectile_pre` / `projectile_loop` / `projectile_impact`
  → ⏳ 未实测：还没任何地方 spawn 它（等 ⑤ 主动技能框架），进游戏看不到东西是正常的
- 备选（没选）：1 `brilliance_projectile_fx` 3/4/5 `crabking_claw_swipe_fx`/`daywalker_swipe_fx`/`sharkboi_swipe_fx`
  6 `wave_hurricane`/`wave` 7 `wagboss_beam` 8 `staff_projectile`
- 做法：朝面向 spawn → 直线推进 → 命中结算；换素材只改文件头 3 行

## 进度小结（2026-09-12 晚）
- ✅ 已验证通过：**剑士转职书（测试）直通二转**（用户："3没问题"）
- ✅ ③ 技能页吃下二转树 —— **已做完**（用户进游戏后生效）：
  - 服务端 `GetSkillView()`：改成遍历 **基础树 + 二转树**（有 `carrer_special` 就一起进），
    每条多带 `kind`(base/special) 与 `tree_name`（战士/剑士…）
  - 面板：标题变「战士 → 剑士 · 等级 N · 可用技能点 M」；每行第二行加职业标签 `[剑士] …`
  - STRINGS 补 `MUSHA_JOB_SABER = 剑士`（代码树名是 saber，之前只有 SWORDSMAN → 不补会显示 "saber"）
  - ⚠️ 剑士两个技能（命中强化/吸血）解锁门槛 7 级起 → 5~6 级时按钮是暗粉（不可加）
- ⏳ 待验证：① 悬停信息面板 ② 礼包页位置（y=170） ③ 技能页二转树（重进游戏后看 4 行）
- ⏭ 剩 ④ 祭坛卷轴（一张卷贯穿 3 轮/不可取出/显示轮次）⑤ 主动技能+施法键（要先出设计稿）

## 刚改完、等你进游戏看
+- 🐛 2026-09-12 修「每帧刷 `vector3.lua:14 attempt to index local 'rhs' (a number value)`」：
  `TheInput:GetScreenPosition()` 返回的是 **Vector3**（不是两个返回值）→ 之前
  `local mx, my = TheInput:GetScreenPosition()` 得到 mx=Vector3、my=nil，拿 Vector3 去减数字就炸。
  已改 `local pos = TheInput:GetScreenPosition(); local mx, my = pos.x, pos.y`
  （日志顺便证明：**面板已经挂上了**（走到了 OnUpdate 且拿到 musha_sword）→ 上一条 Widget 修复生效）
+- 🐛 2026-09-12 修「悬停面板一直不显示（musha 也看不到）」—— **用户是对的，我之前的说法错了**
  - 实锤（用户 client_log.txt）：`[Musha ERROR] 悬停信息面板: ...musha_item_info.lua:36: variable 'Widget' is not declared`
    → 面板**从来没挂上过**，跟角色无关
  - 根因：DST 里 **Widget / Text / Image 不是全局**，是模块（`widgets/widget.lua` = local + return）
    必须 `require "widgets/widget"`；本 mod 的面板 screen / 明生 screen / musha_skillui 都是这么写的
  - 已修：musha_item_info.lua 文件头加 `local Widget/Image/Text = require ...` 三行
  - 📌 教训：写 widget 文件先 require 那三个；不要照 screen 文件的写法裸用
- 🔧 2026-09-12 悬停面板改成通用（用户问"普通也可以用吗"）：新增 `SHOW_FOR_ALL = true`
  → 现在**所有角色**都能看（false = 只有 musha）；注意"谁能看到"取决于谁装了 mod，
  要整房人都能看到得把 modinfo 的 `all_clients_require_mod` 改 true
+- 🎨 2026-09-12 悬停面板配色改口径（用户）：**普通伤害 = 淡红** `(0.98,0.62,0.62)`、
  **位面伤害 = 正红** `(0.96,0.28,0.28)`（红专属位面）；位面防御淡紫 / 保暖淡白 / 隔热淡蓝不变
- 🐛 2026-09-12 修「职业书能接二转任务」（用户问："为什么原来的职业书就可以接？不需要祭坛？"）：
  我按之前"右键职业书接取"那句实现的，现在按新纠正收回 ——
  `musha_jobbook_warrior.lua` 已有职业分支**不再 AcceptAdvanceQuest**，只提示
  "二转任务要去【进阶祭坛】接取（右键祭坛）" → **二转任务唯一入口回到祭坛**（OnAltarInteract，5 级门槛）
- ❓ 待用户定：剑士转职书开关打开后（MUSHA_ADVANCE_OPEN=true）应该是
  a 自己直接发二转任务，还是 b 只开启资格、任务仍旧去祭坛接？（我建议 b）
+- 🆕 2026-09-12 礼包页（用户选 b：面板导航里加一页）
  - `scripts/musha_gifts.lua`（新增）：礼包数据表 —— `id/name/desc/enabled/period/items`；
    现放 1 个测试礼包（噩梦燃料x3 + 金块x5，常驻、领一次）；**节日活动只改这张表**（enabled=true + period）
  - 面板：导航新增第 5 项「礼包」（`page_titles/page_order` 加 `gift`），页面 = 名字(左对齐)+说明+「领取」按钮/「已领取」灰字；
    `RefreshGift(md)` 读 `md.gifts`；`SendClaimGift()` → RPC
  - RPC `musha_claim_gift`（musha_rpcs.lua）：服务端校验 存在/enabled/活动时间/没领过 → 发物品 →
    记 `pc.userdata.gifts[id]` → `PushSettings()`（`musha_profession_component` 里 `d.gifts` 已加）
  - 活动时间预留：`period = { start_day=, end_day= }`（游戏内天数）；要按现实节日再加字段，判定位置在 RPC 里
- 🆕 2026-09-12 位面伤害（用户问"位面伤害也有对吗"）：**有**，已接进悬停面板
  - 事实：DST 有 `planardamage` / `planardefense` / `planarentity`；`Weapon:GetDamage()` 返回**两个值** =
    普通伤害 + 位面伤害（内部叫 sp damage，走 `SpDamageUtil`）
  - `musha_item_stats.lua` 重新生成：**180 条**，其中 105 条带位面字段（扫 `planardamage:SetBaseDamage` /
    `planardefense:SetBaseDefense`）→ 新增字段 `planar`(位面伤害) / `pdef`(位面防御)
  - 悬停面板显示：伤害(红) / 位面伤害(紫) / 位面防御(淡紫) / 保暖(淡白) / 隔热(淡蓝)；
    `MushaGetLiveWeaponStats` 也改成同时返回 `planar`
+- 🆕 2026-09-12 剑士转职书（战士二转，用户选 选项 A）：
  - `scripts/prefabs/musha_jobbook_saber.lua`（新增，`musha_jobbook_saber`）—— 判定链：
    没一转 → "先用职业书转职成基础职业"；不是战士 → "这本只给战士"；已二转 → "用不上了"；
    **总开关 `local MUSHA_ADVANCE_OPEN = false`**（文件头，翻 true 就通）→ 否则 "二转暂未开放"；
    开放后走 `quest:AcceptAdvanceQuest("saber")`（5 级门槛在组件里判）
  - 占位：动画/图标借用 `musha_jobbook_warrior`（美术补图后改 assets 3 行 + inventoryitem 2 行）
  - 已进 `PrefabFiles`；STRINGS 中英文都加了（`MUSHA_JOBBOOK_SABER` = 剑士转职书）
  - 测试：`c_spawn("musha_jobbook_saber")`
- 🔌 2026-09-12 预留接口：武器"最终伤害"（用户问的 weapon damage）
  - 事实：`Weapon:GetDamage(attacker,target)` **存在**（weapon.lua:95）但 **weapon 组件没有 replica**
    → 客机上 `inst.components.weapon` 是 nil → 客机调不到
  - 正确方向：**服务端算 → 推给客机显示**（客机算既没数据也不可信）
  - 已留：`MushaGetLiveWeaponStats(item, viewer)`（modmain，服务端算 基础×职业倍率）；
    同步建议复用 `PushSettings()` 的 userdata 通道；客户端 `musha_item_info.lua` 已优先读
    `MUSHA_LIVE_STATS.get(...)`，读不到退回静态表（现在显示的"伤害 42"就是兜底路径）
- ❓ 待用户定：「礼包」放哪 —— a 制造栏主标签加配方 / b musha 面板导航加"礼包"一页 / c 别的
+- 🆕 2026-09-12 悬停信息面板（用户：照 Show Me 改一份可用的，写进 musha 本体）
  - `scripts/musha_item_stats.lua`（新增）：**自动生成**的物品数值表 108 条（伤害/保暖/隔热），
    扫描 `data/databundles/scripts/prefabs` + mod 自己的 prefabs 里的 `SetDamage/SetInsulation/SetInsulationFromHeat`；
    值优先存 **TUNING 键名**（原版改数值会自动跟），musha_sword = 伤害 42
  - `scripts/widgets/musha_item_info.lua`（新增）：**纯客户端**悬停面板，挂在 `widgets/controls` 上；
    鼠标指到物品 → 光标旁显示：名称(白) / 伤害(**红**) / 保暖(**淡白**) / 隔热(淡蓝)；
    左对齐用 `SetRegionSize + SetHAlign(ANCHOR_LEFT)`；贴屏幕边会自动翻到另一侧；
    **只对 musha 玩家生效**；别的界面开着时不显示
  - `modmain.lua`：末尾加"物品数值表加载" + "悬停信息面板"两个 Safe 块（`TheNet:IsDedicated()` 跳过服务端）
  - ★ 关键认知：客户端**读不到** `weapon.damage` / `insulator.insulation`（这两组件没有 replica，服务端专有）
    → 必须静态表查（Show Me 也是这路子）
  - ⏭ 还没做：**musha 面板里加"信息页"**（表格：名字 + 伤害红 + 保暖淡白，可滚动）——
    要插进面板的 ScrollingGrid，等悬停效果确认后再动面板
  - 📌 宝藏值 / 能量回复：表里已留字段（`treasure` / `mp_regen`），有数值就直接填，悬停会自动多两行
  - ✅ 语法校验：38 个 lua 全过
+- 🐛 2026-09-12 修「采集/烹饪锅不计数」：**事件名两边对不上** —— modmain 的 stewer hook 推
+  `musha_cookpot_harvest`，而 `musha_quest` 监听的是 `"harvest"`（原版根本没这个事件）
+  → "收获五次烹饪锅"从来没计过数。已改：任务组件监听 `musha_cookpot_harvest`
+- 🐛 2026-09-12 顺带修真 bug：stewer hook 原来**不管锅里有没有菜，点一下就 +10 经验**
+  （对着空锅连点能刷经验）→ 现在只有"锅里有做好的菜被取走"才给经验 + 计数（`had_food` 判定，
+  且计数挪到 `oldHarvest` 之后调用）
+- 📌 目前 quest 组件监听的事件已全部核对为"原版真实存在"：builditem（制造）/ musha_cookpot_harvest（烹饪锅）/
+  musha_item_collected（噩梦燃料·宝石）/ killed / builditem / startday
+- 🐛 2026-09-12 修「制造不计数」：监听事件名写成 `craftitem`（**原版根本没这个事件**）→
+   实际是 `builditem`（`builder.lua:739 PushEvent("builditem", {...})`）→ 制造20个物品/建造科学机器从来没计过数。已改
+- 🐛 2026-09-12 修「捡一堆只算 1 个」：收集事件没带数量 → `ProgressQuests` 恒 +1。
+   现在 `ProgressQuests(fn, amount)` 支持数量，`OnCollected(item_type, count)` 收 count，
+   modmain 两个收集钩子（噩梦燃料 / 宝石）都带上 `count = stackable:StackSize()`
- ✅ 2026-09-12 用户选 **b**：完成收集类任务时**从物品栏扣除同等数量** —— 已实现
  `MUSHA_QUEST:ConsumeQuestItems(q)`：按 `CONSUME_BY_TYPE`（collect=nightmarefuel / collect_gems=红绿蓝）
  扣 `q.target` 个；整堆`item:Remove()`、部分`stackable:SetStackSize()`；
  **数量不够就扣多少算多少（不卡完成）**；每日任务 + 转职任务两条完成路径都调了
- ✅ 2026-09-12 用户定「宝石按你想的来 + 经验改 30」→ 已实现：
  **三色宝石 = 红/绿/蓝各一颗**（`target` 1→3、`exp` 25→**30**，`MUSHA_QUEST_TYPES` id=6）
  新增 `ProgressGemQuest(color)`：按**颜色种类**去重推进（同色再来不计数），进度=已集齐颜色数
  完成时 `ConsumeQuestItems` 走宝石分支：按收集到的颜色**各扣 1 颗**
  另抽出通用 `TakeItemsFromInventory(prefab, amount)`（整堆 Remove / 部分 SetStackSize，返回实拿数量）
- ❓ 仍待用户定（已问两次，不急）：暂无

    手里还剩 N 个没做完时次日 to_add=0 → 一个都不发。现在改成 `GrantNewDayQuests()`：
    **每天新增 GetDailyCount() 个**（做完的清掉、没做完的留着，总量封顶 DAILY_MAX=10）；
    另加 5 秒轮询 `CheckNewDay()` 按天号兜底（防 startday 世界状态没触发），与事件共用天号去重
- 技能页两个文字项目（未学习/已学习）点击切换是否正常
- 设置页少了「能量恢复」那行（7→6 行），底部会空一格
- 3~4 级右键祭坛 → 应弹「需要 5 级才能接取转职任务（当前 N 级）」

## ✅ 2026-09-12 晚 用户已拍板（回家按这个做）

### ✅ ① 职业书：**不消耗**；右键职业书「获取任务」—— 已改完
- `scripts/prefabs/musha_jobbook_warrior.lua`：删掉 `inst:Remove()`（书留下），重写 OnUseBook 分派：
  无职业 → 一转（SetCarrerBase + 事件 + 首次送技能书）；
  已有职业且**不是战士** → "职业不可更换"；
  已二转 → "用不上了"；
  战士 + 5 级 + 未二转 → `quest:AcceptAdvanceQuest("saber")`（等级门槛在组件里判，会回原因）
- ⚠️ 其余 3 本职业书（法师/游侠/刺客）**prefab 文件还不存在**（只有图标 + anim），等做了照着这个改

### ✅ ①b 基础职业书配方 = **草 x8**（一转前置）—— 用户 2026-09-12 改的口径
- `modmain.lua`：`AddRecipe2("musha_jobbook_warrior", 草x8, TECH.NONE, {..., builder_tag="musha"}, {"CHARACTER"})`
- **原先写的"老存档自动补发职业书"已撤掉**（用户："2 改一改"）—— 旧档要书就自己用 8 个草造一本
- ★ **配方必须在制造栏里看得见（2026-09-12 用户报"制造栏没有"）→ 按明生 mod 的新写法补两样：**
  `builder_tag = "musha"`（只有 musha 能造）+ **第 5 个参数 filters = {"CHARACTER"}**（进角色制造栏那一栏）
  —— 不出现在制造栏的根因：只写前 4 个参数会被丢进游戏的 `MODS` 过滤器，新制造栏里那栏不显眼/不显示
  参考：`mods/mingsheng/modmain.lua:424` 起（`AddRecipe2(..., {atlas,image,builder_tag}, {"CHARACTER"})`）
- ⚠️ filters 可用名（原版 CRAFTING_FILTERS）：CHARACTER / STRUCTURES / TOOLS / MAGIC / CONTAINERS / DECOR …

### ✅ ② 转职建筑配方 = **方案 A** —— 已改完
- `modmain.lua`：`AddRecipe2("musha_advance_altar", 石块12+木头8+金块6+硝石2, TECH.SCIENCE_ONE, {placer=...})`
- `scripts/prefabs/musha_advance_altar.lua`：末尾加 `MakePlacer("musha_advance_altar_placer", ...)` 并随 Prefab 一起返回
- ⚠️ 配方图标暂用 `musha_note` 的图占位（没有祭坛图标）→ 美术补图后改 modmain 里 atlas/image 两行

### ③ 技能页 = **一转 + 二转全部都要**（未做）
- 现在 `GetSkillView()`（musha_profession_component.lua:910）只读 `carrer_base` 那一棵树
- 要改成：基础职业树 + 进阶职业树（`carrer_special`）都进面板（技能页"未学习/已学习"两栏照旧筛）

### ④ 卷轴 = **同一张卷轴管 3 轮进度**（用户 2026-09-12 晚再确认：④无变化）
- 卷轴不是可搬运物品：不能拿进背包/不能丢地上/别人也拿不走；**一张卷轴贯穿 3 轮**（不换、不消耗）
- 显示当前是第几轮 / 当前轮任务

### ⑤ 主动技能 + 施法键（用户：设置页多一个功能，主动技能都允许用户个人设置）
- **现成钥匙**：`scripts/components/musha_keyhandler.lua`（222 行）就是一套完整的**可配置按键系统** ——
  skill_1~skill_5 + open_skillbook、本地持久化（TheSim:SetPersistentString("musha_keybinds")）、
  改键监听 `StartListeningForBind`、`KeyName()` 显示名 —— **但全项目没有任何地方挂它/调它（死代码，没接线）**
- 接线方案：客户端 keyhandler 按键 → `SendModRPCToServer` → 服务端校验（职业/已学/冷却/存活）→ 执行 → 回推冷却
- ★ **"需要允许"的答案**：`modinfo.lua` 现在是 `all_clients_require_mod = false`，
  而按键是**客户端**行为 → 客机没装 mod 就没有按键 → **必须改成 `true`**（这就是那道"允许"的闸门）
- 另外两道：按键只在 HUD 时响应（keyhandler 里已写，有别的 UI 打开不响应）；暂停时不响应
- "通过什么" = ModRPC（加一个 `musha_cast_skill`），不是网络变量、不用新开通道
- ★ **不需要重挂函数**（用户问的点）：TheInput handler 只注册一次，内部查 `KEYBINDS[key]` 表；
  改键 = 改表 + `RefreshKeyMap()` 清反查缓存 → **热生效，零重挂、零重启**
- ★ **三处分层（重要，别混）**：
  - 技能数值（每级效果/冷却）→ 服务端技能表 / TUNING（全局唯一，全房间一致）
  - 玩家个人设置（回血倍率/调试）→ `musha_player_settings`（服务端按玩家，进存档、会同步）
  - **键位 → 客户端本地 persistent string (`musha_keybinds`)**，各不相同、不进存档、不上传
  - ⚠️ TUNING 三坑：能改但只会影响"之后去读它的地方"；已 Spawn 的实体不会自动重读（Create 时读一次就固定）；
    而且它是全局的 → **多用户不同值做不到** → 键位绝不能放 TUNING
  - ⚠️ 主机双身份：主机同机既跑服务端也跑客户端 → 键位只在客户端侧注册/读写
    （OnRawKey 里已有 `if TheWorld.ismastersim then return end` 挡这个），**服务端侧绝不能写 musha_keybinds**（会进存档变全房共用）

## ⏸ 祭坛交互模型 —— 用户在想，先别写码（2026-09-12 晚）

### 🔤 术语修正（用户 2026-09-12 晚纠正，全项目统一）
- **0 级转职 = 一转**（基础职业：战士/法师/游侠/刺客），靠职业书
- **5 级转职 = 二转**（进阶职业：剑士/近卫/药剂师/元素法师/吟游诗人/月影猎手）
- **二转才是"正式职业开路"** —— 一转（基础职业）**大部分原本没有技能**
- 影响（待办，非本轮）：
  - 设定文档 `dst-modding/references/musha_jobsystem.md` 里写过"5级一转" → 已改标为二转
  - `musha_quest.lua` CompleteAdvanceQuest 注释/文案里的"一转技能书" → 应是**二转基础技能书**
  - **技能页重点应在二转职业**：现在面板技能页只做了「战士」（=基础职业=一转），
    而 saber(剑士)/guardian(近卫) 这些二转职业的树其实也有数据 → 技能页挂哪个转次等用户定
  - 祭坛那条链（3 轮任务）= **二转任务**
- 🧩 **2026-09-12 晚二轮设定（用户给的新决定，回家后做）**：
  1. **右键职业书接取** —— 转职任务的接取入口挂在「职业书」上（不是右键祭坛）
  2. **箱子里每次只有 1 个卷轴**，不会同时显示 3 个（= 按当前轮次只摆 1 个）
  3. **最好无法取出**（卷轴不能拿走/带走）
  4. **要设配方**：转职建筑得能造（现在只能 c_spawn），材料由我定，标准=**5 天之内能集齐**（用户："你认为合理…就行"）
- ⚠️ 已核实的一个硬冲突：`musha_jobbook_warrior.lua:50` 职业书在用掉时 `inst:Remove()` **被消耗**
  → 0 级转职完成后玩家手里**没有职业书**，5 级时"右键职业书接取"就无从点起
  → 三条可能：① 职业书改成**不消耗**（0 级转职只是"读"它，留在手里）；② 5 级时由祭坛**再发一本**；
     ③ 用户说的"职业书"其实是**卷轴**或**技能书**。**等用户回来点一条**。
- 现状：路线1（祭坛容器 + 卷轴物品）已拍板但**未写码**，等上面那条定。

## 🧱 转职建筑的配方（待用户点头，材料由我定：5 天内能集齐）
- 现在：祭坛 `musha_advance_altar` **没有配方**，只能 `c_spawn` → 要补 `AddRecipe` + 放置预览（placer）
- 方案 A（推荐｜科学机器解锁，最稳）：
  `石块 x12 + 木头 x8 + 金块 x6 + 硝石 x2`（挖矿/砍树顺手就有，5 天绰绰有余）
- 方案 B（炼金引擎解锁，魔法味）：
  `石块 x12 + 木头 x8 + 金块 x6 + 噩梦燃料 x4 + 红宝石 x1`（红宝石看脸，5 天不保证）
- 方案 C（炼金引擎解锁，折中）：
  `石块 x12 + 木头 x8 + 金块 x8 + 噩梦燃料 x4`（噩梦燃料 = 夜晚低 SAN 刷，可控）

## ⏭ 下次开工顺序（用户 2026-09-12 晚：这三件晚点做）
1. **③ 技能页吃下二转树** —— `GetSkillView()` 现在只读 `carrer_base`；要加成 基础树 + `carrer_special` 树
   （面板"未学习/已学习"两栏照旧筛），涉及 `musha_profession_component.lua:910` + 客户端 RefreshSkills
2. **④ 祭坛卷轴** —— 一张卷轴贯穿 3 轮、不可取出、显示当前轮次（做法见下面"祭坛卷轴流程"段）
3. **⑤ 主动技能 + 施法键** —— 接 `musha_keyhandler.lua`（现成死代码）+ 设置页键位栏 + RPC `musha_cast_skill`；
   **先出设计稿再写码**（技能名/效果/冷却/等级曲线 + modinfo 的 `all_clients_require_mod = true`）

## 下一步（已定路线，可直接开工）
**祭坛卷轴流程（路线1，用户已拍板）**：祭坛挂 container（建筑容器栏）+ 新建卷轴物品
`musha_advance_scroll` → 容器里预置卷轴 → 右键祭坛开容器 → 拿到卷轴 → 右键卷轴「获取任务」→
接本轮任务（卷轴消耗）→ 3 轮 = 3 个卷轴 → 第 3 轮完成后回祭坛做最终「就职仪式」。
参考：别的 mod 用 `inst.components.container:WidgetSetup("<name>")`（见 mods/mingsheng/.../mingsheng_ztm.lua:444）

## 待用户拍板
- 生命恢复 hp_regen_mult 现在 0 消费方：留 or 删（只删了能量恢复）
- 部分主动技能（背刺/吸血/钢铁意志）怎么释放 —— 用户"要想想"（快捷栏？技能书？蓄力？）
- 设置页 6 行要不要居中/下移（给数字）

## 语法校验（每次改完必跑）
wsl -d Ubuntu2204 -e bash -lc 'bash /mnt/d/wsl-dl/lua-syntax-check.sh'  → 期望「检查 36 个文件：全部通过」

## 铁律（踩过的坑）
- 组件文件里不能用 `GLOBAL`（用裸 TheWorld/STRINGS）；modmain 里才写 GLOBAL.
- AddReplicableComponent 必须在 modmain 调，丢了 → 客户端无数据、零报错
- Text 设了 region 后 SetPosition 是「区域中心」，左缘 = position - regionW/2
- Widget 没有 Remove（那是 EntityScript）→ 清子件用 KillAllChildren
- 热更新后客户端进游戏记得重新勾 mod
