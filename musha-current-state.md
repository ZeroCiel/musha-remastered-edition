# Musha 短卡（2026-09-14）—— 新会话只读这张，**别整读 musha-log-2026-09.md**

> 用法：开工先扫「队列」→ 按「命令」跑校验 → 需要历史/踩坑细节再 `grep` 档案（`musha-log-2026-09.md`）。
> 维护规则：新内容写这张；被替换掉的老条目搬进档案，别删。

## 🚨 特别重要（2026-09-25 用户指令，所有会话遵守）
**皮肤/版本优先级：一律优先使用仓库的 Musha 原版本皮（`exported/musha/`），暂时禁止使用 v2（`exported/musha v2/`）——直到 AI 重画完成、用户另行通知切换为止。** 此条涉及面板/BG 及一切角色素材的取用口径。
另：主页 BG（panel_bg.png）用户将自行重修；变体底图已交付 `images/panel_bg_alt.png`（主页+技能页切换用，1741x1157 透明底）。panel_screen.lua 头部坐标对齐等 opencode 与用户定稿后进行。

## 项目
`D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha`（作者的 DST mod，作者 Ciel/雪儿）
面板 = Screen + ScrollingGrid，导航 7 页：主页 / 技能 / 装备 / 信箱 / 设置 / 礼包 / 图鉴

## 📄 相关文档（2026-09-17 新增两份）
- `musha-药剂师大锅-design.md` — 药剂师（法师分支）大锅：设定图 9 条调整清单 + 素材规格 + **771 行现成抄本** `references/norse_mythology_portablepot.lua`（官方 `stewer` 组件）+ 分 P1~P4
- `musha-职业估期与排期.md` — 近卫/法师线：**设计要求 vs 代码现状对照表** + 估期（近卫最小 2.5~3.5 天 / 全套 7~9 天；法师线 5~7 天起，全套 16~22 天）+ 关键路径
- ⚠️ 近卫**盾机制（MP 当护盾）全项目 0 行**；元素法师/药剂师 0 行；`class_traits.mage/elementalist` 只有数值雏形

## 📋 新功能构想清单（2026-09-26 用户口述，待排期）
时光沙漏 / 老奶奶的指针(树洞触发回秋天) / 强化胡萝卜 / 魔法杖(光炮+法力) / 缩小药 /
引导书(寻宝) / 兔子背包(8格5页) / 茶杯猫(猪王交易100金永久失配方) / 爱丽丝计划(星图)。
**明细与拆件见 `musha-新功能构想_20260926.md`**（mod 根目录），排期等用户拍板。

## 📌 队列（2026-09-14 收工状态）

### 🔴🔴 铁律（2026-09-18 用户拍板）：**美术/动画没定稿前，不许打包**
- 用户原话：「musha 的动画打包太早了，仓库拉一下原版的 musha 动画回来，**直到我满意完动画再打包**」
- 执行口径：**不要**再跑 `scml.exe` 去覆盖 `anim/musha.zip`、**不要**装任何皮肤 zip 进 `anim/`，
  直到用户明确说"定稿/可以打包"。要给他看效果 → 编译到 `exported/_tools/_test_out/<版本>/`，
  或直接开 `参考图\02_单姿态大图.png` 给他看。
- **动画由用户自己管**（他 09-18 明确说了），工具/脚本不要动 `anim/` 下的任何 zip。
- **目录分工（B 方案，用户选"B 为主"）**：
  · `exported/musha/` = **已发布/原版**（等于仓库版本）；还原 = `git checkout -- exported/musha/`
  · `exported/musha_rococo/` = **洛可可皮肤迭代**（新目录，含 `README_这个目录是什么.md`；已从当前工作区拷一份）
  · `exported/musha_rococo_v13/` = 2026-09-18 从 v13 zip 生成留档（含参考图）
  · 产物一律出 `exported/_tools/_test_out/<版本>/`
  · ⚠️ 用户目前**没让**把 `exported/musha/*.png`（122 处未提交改动）还原成原版 —— 想还原要等他点头
- 已办（2026-09-18 23:31）：`anim/musha.zip`（491771B）+ `exported/musha/musha.zip`（1760923B）
  都从 git 仓库 `git checkout -- ` 拉回原版了；原版 anim zip 另有一份备份 `anim/_bak_musha_原版_20260918.zip`（md5 52c43abb… 与仓库一致）。
- 📌 **不做 AI 出图流水线**（用户 09-18：GPT 的管理能力不成熟、"直接设置图片没有能用的"）→ `fit_ai_art.py` 继续暂存，别主动做。


### ★★ 2026-09-18 晚（近卫开工口径 + 技能树 UI 规格，**下次开工先看这里**）
- ✅ **`#12` 转职链已写码（2026-09-19 凌晨，语法 57 文件全过）——两枚方向徽记**
  · 新物品：`scripts/musha_crest.lua`（共用实现）+ `scripts/prefabs/musha_crest_{saber,guardian}.lua`
    （prefab 里 `pcall(require,"musha_crest")` 兜底，失败退化"哑徽记"，绝不因一个 require 禁 mod）
  · 组件新增（`musha_profession_component.lua:1175~1310`）：`GetAdvanceChoices / GetAdvanceBind /
    IsAdvanceBindUsed / GrantAdvanceCrests / UseAdvanceCrest / VoidSameBindCrests`
    + userdata 三个字段 `advance_crest_bind / advance_crest_used / advance_choice_pending`（`:270-272`，随 userdata 自动存档）
  · 动作：`ACTIONS.MUSHA_USE_CREST`（`actions/musha_actions.lua` 注册 + tag `musha_crest` 路由 + 两个 stategraph）
  · 仪式改（`components/musha_quest.lua:496`）：**仪式不再直接进阶** → 发两枚徽记，用掉一枚才落地；
    `advance_ceremony_pending` **保留到选定方向**（祭坛期间不补卷/不接新任务）
  · 面板提示（`musha_quest.lua:861`）：仪式后那行假任务改成"选定方向：用掉手里的徽记（剑士 / 近卫）"
  · 文案：`languages/{chinese,english}.lua` 各 6 条（动作名 + 「剑士徽记 / 近卫徽记」名与简介，写明不可更改）
  · 防错：用一枚 → 立刻设职业+发赠礼+清待办+**收走背包里另一枚**；另一枚在箱子/地上/别人手里时
    右键一律判"作废"并消失（**兜底规则只看 doer 已进阶，不依赖实体字段 → 掉线重进也不会两枚都能用**）
- ⏳ **这一批还没做**：① 面板"两条树都打锁"（未选方向时同时列剑士/近卫两棵树）
  ② 近卫徽记的美术（`images/inventoryimages/musha_jobbook_guardian` 还没转 tex → 现在退回通用技能书图标）
  ③ 近卫机制 P3（盾 / 嘲讽 / 反击 25% / 400 血 / 无硬直）
- ✅ **近卫口径（用户拍板）**：转职方向确认选 **C**；但落地方式按用户改的——
  **祭坛最后交互时返还两本书（剑士 / 近卫），两本都能看到、共用绑定 ID，
  用掉一本另一本自动作废**（我用"作废校验"实现，不追着删实体）+ 用掉=不可逆（写进书的简介）；
  命名建议 **「剑士徽记 / 近卫徽记」**（别跟"解锁剑气斩的技能书 musha_skillbook_saber"混）。
  近卫职业书美术**现成**：`exported/jobbook_guardian_未上线/`（icon 64² + 世界贴图 128²，**差 tex/xml**）。
- ✅ **近卫工期（用户拍板）：P1 + P3 同时做**（P2 盾原型是 P3 的地基，必然一起）。
  顺序：① 修 `#4` 钢铁意志口径错（`musha_profession_component.lua:679`，现在实际减伤 60~75%）
  ② 清 `#10` 生命偷取重复实现（`:209` onhitother 一份 + OnAttackOther 里旧的一份）
  ③ `#12` 转职链（两本书 + 作废校验 + 面板两条树打锁）④ 盾原型 → 嘲讽 / 反击 25% / 队友护盾 / 400 血 / 无硬直
- ✅ **技能树 UI 规格已成文：`musha-技能树UI-spec.md`**
  横拖看目录 · **只显示图标** · hover 才出说明（复用 `musha_item_info.lua` 悬停面板）· **竖线=前置依赖**
  · 文字用**旧版框架 `scripts/widgets/musha_text.lua`（MushaText：直设字号、不走 LOC.GetTextScale）**
  · 要加布局表 `SKILL_TREE_POS`（x/y 坐标 + `req = {前置技能=最低等级}`）；法师多技能全靠这张表 → **这是法师的前提**
  · 分步：S1 只读树 1.5~2 天 → S2 加点 0.5~1 天 → S3 拖入快捷栏生效 2~3 天（明生拖拽抄本）
- ⏳ **待用户**：① 完整「musha 2.0 旧版源码」在哪个路径（盘上只有 musha_text.lua / beta 容器段 / 0.7.6 设定文档）
  ② 技能图标（64²）要不要我先画占位 ③ 竖线要正交折线还是斜线直连
- 📌 用户口径：**剑气斩那本技能书美术要重做**（他自己找 ChatGPT 出一本"技能相关"的）
- ✅ 已办：**rococo v13 全身皮已编译装到 `anim/musha.zip`**（407KB；原版备份 `anim/_bak_musha_原版_20260918.zip`）；
  工程在 `exported/musha_rococo_v13/`（画面尺寸跟 v13 的 build.xml 走；5 个符号画布变了：hair/hand/torso-9/torso_pelvis/hairpigtails-2）
- 🛠️ 新工具：`exported/_tools/replace_art.py`（换图→用**原 scml 名**编译→`--install` 装到 anim/，
  带 md5 差异报告 / 尺寸校验 / 备份 / `--dry`）

### ★★ 2026-09-18 皮肤模板 + 天使皮肤（本轮新增，**模板可复用**）
- **`musha_cloth_v01_SCML_ready`（Downloads 里那份）是什么**：Mod Tool 导出的 **build 源**
  （build.xml + animation.xml + 156 张 PNG），不是"新衣服"——里面 **torso/torso_pelvis/skirt 是素布衣 v01**，
  其余 129 张与工程老图逐字节相同；`tail/hairfront/hair_hat/skirt` 是 **100x100 全透明占位**
  （真实画布 250x100 / 400x400 / 400x400 / 160x120，**出图必须按真实尺寸**）。
- ✅ **新工具 3 个（都在 `exported/_tools/`）**：
  · `buildxml_to_scml.py` —— build 源 → Spriter .scml（口径已逐元素对齐：pivot_x=0.5-x/w、
    pivot_y=0.5+y/h；x=tx、y=-ty；sx=hypot(a,b)、angle=-atan2(b,a)、sy=sign(det)·hypot(c,d)）
  · `musha_scml_render.py` —— scml → 拼装预览 PNG（可指定第几个 key；纯标准库）
  · `make_skin_template.py` —— 一条命令出整套模板 + 参考图 + README（源目录/输出目录/名字 [--from-scml 现有工程.scml]）
- ✅ **模板已生成：`exported/musha_cloth_v01/`**（19 符号 / 156 图 / 39 个 key）
  ⚠️ **实测 animation.xml 里 39 帧完全相同 → 单姿态模板**（DST 角色 build 惯例，动作由 bank 提供）；
  所以 `exported/musha/musha.scml` 那 40 个重复 key 是对的、不是坏文件。
  · `README_模板.md` = 符号表（帧数 / 各帧画布尺寸 / 画什么 / 哪些是占位）
  · `参考图/` = 每符号帧表（带帧号+尺寸+pivot 红十字）19 张 + `00_全符号总览.png` + `01_角色姿态总表.png`
  · **编译验证**：`scml.exe` 编出 zip 的 `build.bin` 与原 `anim/musha.zip` **逐字节一致**（只差 build 名），
    anim.bin 同尺寸同结构同图层名；渲染内容框与老工程完全重合（只剩布衣美术差异）
- 📌 **每个"姿态 key"里其实排着 3 列部件**（x≈-325 / 0 / +352，各 33/31/34 层 = 3 个朝向变体，
  用不同符号帧拼的）→ 画皮肤时**3 列都要画**，别以为"一帧一张"。
- 📌 **天使皮肤已记录：`musha-天使皮肤计划.md`**（设定/配色/12 个要画的符号/给 ChatGPT 的可粘贴提示词/落地步骤/3 条待拍板）
- ⏳ 探针脚本（`_check_cloth_*` `_fit*` `_cmp_render*` `_dump_animnames*` …）还留在 `_tools/`，**要删等用户点头**。
- ⚠️ 两份工程（`exported/musha/musha.scml` 40 个 key、`exported/musha/musha.zip` 里的 animation.xml 39 帧）
  **数据上都只有一套姿态**（实测逐帧完全相同）→ 单姿态模板是 DST 角色 build 的正常结构，不是坏文件。

### 🔴 2026-09-18 用户睡前提的两条（**下次开工先看这里**）
**1. 月牙斩"方向错位"** ← 用户实测结论
- ✅ **2026-09-26 已根治（详见 ⑲）**：根因 = 8 张方向图指向**不均匀**（对官方标签偏 +8.4~+42.7°，
  按世界格中心投影 + K_SCREEN=0.5 压扁所致），不是引擎；已按官方写法重做（reorient 0.0° 复测 +
  官方名 scml 重编 + 成对切换 `USE_ENGINE_FACING=true`）。下面 09-18 的点名播修法降级为历史/回退参考。
- 刚做的处理（已提交）：**切回"代码按方向点名播"** —— `USE_ENGINE_FACING = false`，
  且 `anim/crescent_cyan8.zip` 已换成**点名声版**（slash_dir0..7，编译实测确认）。
  8 面（引擎挑面）版备份：`anim/_bak_crescent_cyan8_8面_20260918.zip` +
  `exported/crescent_moon/crescent_cyan8_bak_官方名.scml`
- ⚠️ **常量与 zip 必须配对**：只改常量不换包 = 月牙看不见（包里没有那个动画名）
- 方向口径（就两处，别再翻别的地方）：
  ① 代码 `DirIndexFromRotation(rot)` = `floor(((-rot)%360)/45)`（0 = 世界 +X，每 45° 一格往 +Z）
  ② 素材第 k 格按**格中心** `45k + 22.5°` 画（`exported/_tools/crescent_gen.py`，8 张 dir 图）
- 如果点名播**还是偏**，按这个顺序修：
  (a) 先看日志 `方向图 → slash_dirX` 与实际飞行方向差多少；
  (b) 偏 **45° 整数倍** → 改 `crescent_gen.py` 的 `PHASE_DEG` 重出 8 张 + 重编 zip（**别动 Transform 旋转**：
      DST 的飞行方向 = 实体自身旋转，一动就偏航，见铁律第 7 条）；
  (c) 若是"左右镜像"样 → 改 `DirIndexFromRotation`（取反 / 加常数，一处）。
**2. 技能解锁 / 技能学习这条链"没完成"**
- 已实现：`musha_skillbook`（通用技能书）、`musha_skill_scroll`（通用技能卷轴）、
  `musha_skillbook_saber`（剑士技能书，二转赠礼）→ 右键 → `pc:UnlockSkillByBook()`
  → 解锁本职业"技能书解锁技"（剑士 = 剑气斩 Lv1）→ **成功才消耗**；
  面板侧 Lv0 显示锁 + `book_lock`（不能用技能点买）
- 未完成 / 待定：
  ① **"上拉选技能"列表** = 用户选 **A（只列未解锁）**，但整体**搁置到元素法师做完**（要"眼前一亮"）
  ② 用户报过"没学也能看到剑气斩（已解锁）"→ 我判断是旧档残留（旧代码二转直接 +1 级），
     用户说"判断错了、我再试试" → **待他复测**（新档 / 清档后应显示为锁着）
- ✅ **2026-09-18 已按用户要求补完（两条入口都做了）**：
  ① **面板技能页**：「锁」(图片) 和「+」**两处都能点** → 都走新的 RPC `musha_skill_unlock`
     → `pc:UnlockSkillWithItem(tree, name)`：从背包里找 1 本技能书（白名单
     musha_skillbook / musha_skill_scroll / musha_skillbook_saber，或挂 tag
     `musha_skillbook`/`musha_scroll` 的），把它 0 级的"技能书解锁技"提到 Lv1，**消耗那一本**；
     没有书 → 台词"需要一本技能书（背包里没有）"
  ② **背包里右键那本书**：各 prefab 自己的 OnUse → `pc:UnlockSkillByBook()`（原有路径，不变）
  · 🐛 **顺手补了服务端的漏**：`CanUpgradeSkill` 原来**没有**拦"技能书解锁技 0 级" →
    花 1 技能点也能买（面板画着锁但点加号能买到）→ 这就是用户报的"没学也能看到已解锁"。
    现在 0 级 + 属"技能书解锁技" → 直接返回"需要一本技能书才能解锁"（客户端改包也绕不过）
  · 面板文案：锁悬停 = "点这里（或 +）用背包里的技能书解锁 · 需要 N 本"；+ 故意画灰（别让玩家以为花点能买）
  · ⏳ 待实测（用户）：锁/+ 点击 → 扣书解锁；没书 → 台词；技能点买不动
- 📌 顺带记：**生命树枝贴图用户说"有更新，但之后再改"** → 现在别动它的美术。

### ★★ 2026-09-17 晚（用户口径 + 本批改动，全部**未跑语法校验**）
【用户口径】技能卷轴 = **普通技能学习专用**（大部分时候可制作 或 可掉落）；
**珍惜技能 = boss 掉落**（另一条线，未做；美术参考 `图片/珍惜技能.png`）
- ✅ **技能卷轴 `musha_skill_scroll`（新物品）**：右键「展开卷轴」(复用 MUSHA_UNROLL_SCROLL)
  → `pc:UnlockSkillByBook()` 解锁本职业技能（剑士 = 剑气斩 Lv1）→ **成功才消耗**；
  没解锁成功给台词（already / noskill）。tag = `musha_scroll`（动作路由现成的，没加新动作）
  · 简称/简介：`S.NAMES.MUSHA_SKILL_SCROLL` = "技能卷轴"；
    DESCRIBE = "记载着普通技能要诀的卷轴。展开后习得其中的技能。"（中英都改了）
  · 配方：**莎草纸×2 + 蜘蛛丝×2 / 科学机器 / builder_tag=musha / CHARACTER 页**
  （材料是我按"5 天内能凑齐"定的，要改就改 modmain 那一段）
  · 素材自检：`asset_exists` 探 anim zip 和 icon xml/tex，缺哪个都退回**原版莎草纸**（不会禁 mod）
  · 美术：`图片/技能卷轴_图标.png` → 已缩 64×64 → `images/inventoryimages/musha_skill_scroll.png`
    （**还差你用 Mod Tool 转 .tex/.xml**）；`图片/技能卷轴_地上.png` → 72×72 + scml →
    已命令行编出 `exported/musha_skill_scroll/anim/musha_skill_scroll.zip`
    （**还差拷进 `anim/`**——用户说"等会做"）
- ✅ **二转赠礼改为"发一卷技能卷轴"**（原来是直接 0→1 级）：
  `musha_profession_component.lua` 新增 `GiveSkillScroll()` / `GrantAdvanceGift(career)`；
  开关 `ADVANCE_GIFT_IS_SCROLL`（false = 回旧行为）。两个调用点已改成走统一入口。
- ✅ **就职仪式**（设定文档第三条，用户"5 对了"）：第 3 轮任务完成**不再自动进阶**，
  改成"回祭坛右键 → 做就职仪式"（`quest:DoAdvanceCeremony()`：进阶落地 + 发赠礼 + 面板刷新）。
  开关 `musha_quest.lua` 顶部 `CEREMONY_ON_FINAL_ROUND`（false = 回旧自动进阶）。
  连带：仪式待办期间祭坛不补卷、不接新任务；`advance_ceremony_pending` 进存档。
  · 用户说「我跳过了前两轮，得重新测试一轮」→ 实测要**完整跑 3 轮**才看得到仪式。
- ✅ **剑气斩 8 面 scml（引擎挑面 A/B 实测用）**：
  `exported/crescent_moon/crescent_cyan8.scml` 已换成**官方后缀名**版
  （slash_downright/down/downleft/left/upleft/up/upright/right）；
  备份 = `_bak_scml_点名声_20260917.scml` + `anim/_bak_crescent_cyan8_点名声_20260917.zip`；
  我用 `mod_tools/scml.exe` 编好并**已覆盖 `anim/crescent_cyan8.zip`**（包内动画名实测已被削成基础名 `slash`）。
  代码 `USE_ENGINE_FACING = true`、`FACING_DEBUG = true` → 重启即测（日志打"旋转角→实际播哪一面"）。
  回退一步：常量改 false + 备份 zip 拷回去。
- ✅ **设置页删掉「生命恢复」**（`hp_regen_mult`，0 消费方）：面板 SETTINGS_UI 那一行 +
  `musha_player_settings.lua` 的 SPEC 都清了（设置页 7→**6 行**，ROW_Y0=134 没动）。
- ⏳ **等用户"等会做"**：① 把 `exported/musha_skill_scroll/anim/musha_skill_scroll.zip` 拷进 `anim/`
  ② 跑语法校验 ③ Mod Tool 转技能卷轴图标 tex
- 用户点名**跳过/延后**：装备页右侧显示（8）、近卫盾+法师/药剂师+武器技能4选2（9）、
  生命树枝升级（11，等元素法师发布后做、含药剂师）、图鉴/任务扩编（12，暂时忽略）。
  美术：**除职业书外全跳过**（职业书"全部重做 + 清掉不符合的"仍挂着）。
### ★★ 2026-09-17 深夜（用户实测反馈后的第二波）
- 🐛🐛 **崩溃已修（我的错）**：就职仪式发技能卷轴时 `inv:GiveItem(scroll, true)` ——
  `GiveItem(item, slot, ...)` 的**第 2 个参数是槽位号(number)**，不是 bool →
  `inventory.lua:1088 attempt to compare boolean with number`（用户实测：第 3 轮做完右键祭坛即崩）。
  已改成 `inv:GiveItem(scroll)`；并且 `DoAdvanceCeremony` 里那一步改成 **pcall 包起来**
  （赠礼再出问题也不会把"仪式待办"卡死 → 不会每次右键都崩同一个地方）。
  半途崩掉的存档能自愈：carrer_special/has_advanced 已写、pending 还在 → 再右键一次祭坛就正常走完。
- 🐛 **「第 3 轮做完没反应」**：第 3 轮完成时 `advance_quest` 被清成 nil，面板上那行转职任务**直接消失**。
  已在 `SyncToPanel` 里加一支**假任务行**：`{id="ceremony", n="就职仪式：回祭坛右键完成", p=1,t=1,done=true}`
  → 面板会显示一行打勾的提示，直到仪式做完。
- ✅ **祭坛"保证是满的"**（用户：「主动去转职…起码保证祂是满的」）：
  · 祭坛 prefab 落成/读档 `DoTaskInTime(0)` **先塞一卷**（不再等开坛"发现"）
  · modmain 补卷守卫撤掉两道（留着注释）：① 手上有卷就不补 ② 手头有在跑任务就不补
  → "转职任务没接到（没提示）"的根因大概率就是坛子空着（没卷轴可展开 → 自然没台词）
- ✅ **生命树枝合并包（用户选 4A）**：`exported/musha_lifebranch/musha_lifebranch.scml` = 合并版
  （bank/build = musha_lifebranch，symbol = idle + swap_lifebranch）；旧世界单帧版备份
  `musha_lifebranch.scml.bak_世界单帧_20260917`；代码 `LIFE_ART_MERGED=true` +
  `OverrideSymbol("swap_object","musha_lifebranch","swap_lifebranch")`。
  ⏳ 等用户编译覆盖 `anim/musha_lifebranch.zip`（旧的 `anim/swap_lifebranch.zip` 之后不用了）
- ⏳ 用户未答：技能书上拉选技能列表（A 只列未解锁 / B 所有未满级）→ 我默认 B，等一句确认
- 提问约定：**问 musha 待办时不要把明生条目混在一起列**。

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
### 📦 2026-09-17 收一收：09-14 ~ 09-16 那一簇老条目已归档
（按维护规则整段搬进 `musha-log-2026-09.md` 的「📦 2026-09-17 归档」段，正文一字未改）
· 搬走 = 旧编号条目 1~6 + 2a~2n + 09-16 傍晚那几批（月牙方向图、剑气斩多面向、重剑四轮、能量条换色、图鉴/技能页/祭坛/生命树枝…）
  那些**都已落地或被取代**，细节看档案。
· ⚠️ 里面**还活着的尾巴**（要动先看这几条，别整读档案）：
  · 剑气斩「飞满 12 格不消失」仍未查（OnMiss / Cleanup / 3 秒兜底）→ 2e
  · 礼包页「框框有问题」症状未细说（搁置，等你说清）→ 3c
  · 仍等重导的素材：便签地上/手中 `musha_note_item.zip`、中式布衣 `musha.zip` → 3d / 3e
  · 礼包双轨（游戏时间 / 节日）待实测；**生命树枝升级机制未做**（等元素法师后）→ 5 / 11
  · 发布前核对：技能页剑士树两条（剑气斩 / 我，活着）+ 加点扣点 → 2b
  · 武器技能「4 选 2」UI 暂缓 → 6；装备页要移到右边单独显示（现在导航里隐藏）→ 2g

## 🔧 命令（每次改完必跑）
- 语法校验：`wsl -d Ubuntu2204 -e bash -lc 'bash /mnt/d/wsl-dl/lua-syntax-check.sh'`（期望「检查 N 个文件：全部通过」）
  · `luac5.1` 只在 WSL 里，Windows 侧找不到，别去 C:/D: 盘 find
- 方向图**重定向**（对齐官方朝向；重跑 `crescent_gen.py` 后必过）：`python exported/_tools/crescent_reorient.py`
  （⚠️ 必须用 Python311：`C:\Users\Administrator\AppData\Local\Programs\Python\Python311\python.exe` —— PATH 上的 python 是 hermes venv、没 PIL；旧命令 `exported/crescent_cyan/make_dirs.py` 的目录已不存在）
- 角色造型换衣（中式素布衣）：`python exported/_tools/cn_cloth.py [--apply 1..5|--revert]` ← **首选**
  旧稿：`draw_cloth.py`（布纹重画）/ `gray_cloth.py`（纯去色）
  （纯标准库；配套 `exported/_tools/{pnglib,ascii_view,palette_scan}.py` —— 没视觉模型时用 ascii_view 看图）
- **发布前素材自检**：`python exported/_tools/check_assets.py`
  （扫全项目 `Asset("类型","路径")`，报"声明了但文件不存在"的项 —— 这类缺失会让 RegisterPrefabs 阶段 assert，
   整个 mod 被禁；2026-09-14 生命树枝、2026-09-16 便签各踩过一次）
- **打包**：首选 `art_manager.exe`「打包 anim」按钮（校验 scml → scml.exe 逐编 → 产物复核，静默失败逐条明示，见 ⑫）；tex 走「发布 PNG」/`art_update.py publish`。旧 GUI `D:\饥荒开发\tool\DST Mod Tool.exe` 降为备选。
- **皮肤模板（build 源 → Spriter 工程 + 参考图）**：`python exported/_tools/make_skin_template.py <源目录> <输出目录> <名字> [--from-scml 现有工程.scml]`
  · 只转换：`python exported/_tools/buildxml_to_scml.py <源目录> <输出目录>`
  · 拼装预览：`python exported/_tools/musha_scml_render.py <x.scml> <out.png> --keys 0,5,20 --scale 0.5`
  · 命令行编译：`"<DST Mod Tools>/mod_tools/scml.exe" <工程>/<名>.scml <出参目录>` → `<出参>/anim/<名>.zip`
- 原版写法定要看**当前版本**：`unzip -o -q data/databundles/scripts.zip "scripts/xxx.lua" -d /tmp/gd`
  （`data/databundles/scripts/` 那个旧解包目录行号对不上）

## 🗂 Gitee（用户账号 cielciel / 命名空间 ZeroCiel）
- ★ **2026-09-25 推送成功**：4 个本地提交（7238023、1017bc3、0de7040、45eff68）已全部推上 origin/master。
  · HTTPS + 私人令牌；**用户名必须写 `cielciel`**（写 ZeroCiel 报 `The token username invalid`）
  · `git push https://cielciel:<令牌>@gitee.com/ZeroCiel/musha-remastered-edition.git master`
  · 令牌不落盘、不写进任何仓库文件；改 SSH 或换令牌问用户。
- ★ **同账号下还有两个有用的老仓库（2026-09-18 发现，可直接 clone 参考）**：
  · `ZeroCiel/Musha-beta`（2022-02-16）= **Musha 2.0 旧版**：`main/` 编号式结构 + `scripts/widgets/`（`my_image.lua` = 旧"文字框架"，图片控件自带 Text 子控件；`_animbutton.lua`；`Norse_mythology_System.lua` = 旧 Wiki/技能页）、`main/08.Musha_Skill.lua`、`main/Old Data/old_Skill.lua`(236KB 技能数据)
    → 已 clone 到 `D:\wsl-dl\Musha-beta`，关键 5 个文件抄进 `references/musha_beta_2.0/`
  · `ZeroCiel/norse_mythology`（2022-06，原 Musha 三期代码转型）→ 已 clone 到 `D:\wsl-dl\norse_mythology`（`references/norse_mythology_portablepot.lua` 就是从这来的）
  · 另有 `ZeroCiel/magic-ring`（新神魔环，见 skill magic-ring-shop-port）
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
| ★ **职业系统设定原文**（转职流程/四职业/六分支：剑士·近卫·药剂师·元素法师·吟游诗人·月影猎手） | `.mobius/skills/dst-modding/references/musha_jobsystem.md` |
| 武器技能 v1~v11 全过程 | `musha-weapon-skill-plan.md` |
| 右键点地技能两条路线 + 硬要求 | `musha-rightclick-spec.md` |
| 天数奖励（未做） | `musha-dayrewards-plan.md` |
| 装备/属性面板设计 | `musha-design-equip-panel.md` |
| 可移动携带建筑（生命树枝升级用） | `references/portable-structure-notes.md` |
| 方向图生成（8 面 + 投影补偿） | 技能 `dst-modding` → `references/directional-art-projection-compensation.md` |
| ★ **皮肤模板 / 天使皮肤**（模板/尺寸表/给 ChatGPT 的出图单） | `musha-天使皮肤计划.md` + `exported/musha_cloth_v01/README_模板.md` |

## 🎨 美术（2026-09-17 用户口述拍板）
| 项 | 决定 |
|---|---|
| 祭坛里的职业任务卷轴图标 | **不用管**（占位 = 原版莎草纸 papyrus，先放着） |
| 祭坛本体美术 | **没想好**（未定，别动） |
| 职业书美术 | **全部重做**（例外：技能书解锁的"专用卷轴"那一类不用重做） |
| 不符合的美术 | **清掉**（随重做一起处理；删文件前先列清单给用户勾） |

**现有美术盘点（重做/清理用）**
- 职业书**图标 png 只有 3 张**：warrior(05-20)、mage(05-19)、ranger(05-17)；**rogue 只有 tex/xml，png 源已丢**
- 职业书世界贴图 zip（09-04 编译）：`musha_jobbook.zip` + `musha_jobbook_{warrior,mage,ranger}.zip`
- 技能书：只有图标 `musha_skillbook.png`(05-17)，**没有独立世界贴图**
- 便签：图标 `musha_note.png`(05-15) + 世界贴图 `musha_note.zip` / `musha_note_item.zip`(09-16，"一卷系绳的纸")
- ❌ **进阶职业（剑士/近卫/药剂师/元素法师/吟游诗人/月影猎手）的图标 + 职业书美术全缺**

## ⏳ 待拍板
- ★ **转职链缺口**（2026-09-17 查设定文档发现）：设定原文《5级一转：进阶职业》写的是
  「在建筑**容器栏**内检查**任务卷轴** → 完成 **3 个任务卷轴**逐步进行 → **回到建筑进行最终交互，完成就职仪式**」
  · 前两条 = 本次祭坛容器改版正好对上 ✔
  · ❌ **缺第三条**：现在代码是第 3 轮任务一完成就**自动进阶**（`CompleteAdvanceQuest`），
    没有"回祭坛做最终交互 / 就职仪式"这一步 → 要不要补？（补了更贴设定、也更符合用户要的仪式感）
- **祭坛改版待拍板**（2026-09-17）：
  · 卷轴美术 —— 现在占位=原版莎草纸；要不要出专属"转职卷轴"图标 + 世界贴图（我可程序化画，或写外包需求单）
  · 等级不够时祭坛要不要**提前给**卷轴（现在给：接取时才提示"需要 5 级"；也可以改成不到 5 级坛里空空）
  · 要不要给"取出卷轴 / 展开卷轴"加音效或光效（要查原版音效路径，别瞎猜）
  · ✅ 已定：旧占位 statuemaxwell 兼容**已删**（容器只加在祭坛自己的建筑上）
  · ⚠️ 职业书美术缺进阶职业那一批（warrior/mage/ranger/rogue 才有）→ 近卫职业书要配套美术
- ~~生命恢复 `hp_regen_mult` 现在 0 消费方：留 or 删~~ → **2026-09-17 已删**
- 设置页 6 行要不要居中/下移（给数字）—— 用户未点，先不动
- 上线前清理清单 —— 发布前逐条过（✅ 2026-09-16 核过一遍）：
  · ❌ **未清**：测试用剑士转职书 —— 3 处（`modmain.lua:303` PrefabFiles 里的 `musha_jobbook_saber`
    + `scripts/prefabs/musha_jobbook_saber.lua` + STRINGS 的 `MUSHA_JOBBOOK_SABER`）；**删之前先确认祭坛 3 轮流程能走通**
  · ✅ 已无：dev_test_gift（全项目 grep 不到）
  · ❌ **未补**：进阶祭坛配方图标仍是占位（`modmain.lua:423-424` 用的 `musha_note` 图）→ 缺 1 张祭坛图标
  · ✅ 已清：设置页空行（`mp_regen_mult` 行已删，SETTINGS_UI 现有 6 行都是实的）
- 更新日志：`scripts/musha_changelog.lua`（源）+ 面板内联兜底（`musha_panel_screen.lua:111` 起）**两份都要同步**；
  0.7.7 条目已写（2026-09-16，5 行）。⚠️ 信箱页 `MAIL_PER_PAGE = 3`，**单条行数太多会掉出框外**（每页约 4~5 行/条为上限）
### ★★ 2026-09-17 23:00（用户口述决定，**先记下不改**）
- ✅ **生命树枝合并包已验证可用**（用户："能看到了"）；但"**太大**" → scml 里给 swap 那个 object
  加 `scale_x/scale_y = 0.45`（实测图里树枝本体 372x380 px ≈3.8 单位 → 0.45 ≈1.7 单位，跟矛差不多）。
  ⏳ 等用户重编 `anim/musha_lifebranch.zip`；要更大改 0.6 / 更小 0.35（就这两个数）。
  顺手删了 scml 里两条**空引用**（swap_lifebranch-1/-2.png 根本不存在；根目录那份与 -0 字节相同）。
- 📌 **职业书美术**：战士那本**换成 ChatGPT 给的那本**（图还没给我 → 要路径/再贴一次）；
  **法师 / 游侠两本 = 仅作展示，不上线**（当废案展示），除非以后改转职计划。
- 📌 **生命树枝 / 重剑贴图：保留**（不换新贴图）。
- 📌 **「选择职业」开场弹窗/规则：保留**（先不动，**做完法师再议**）。
- ❓ 待问清：用户报「2转没法放职业技能书 需要检查一下」—— 具体指"二转该发一本职业技能书但没发"
  还是"面板里职业技能书没位置"？→ **用户已答：A**「我指的是剑气斩，二转完成应该给一本属于剑气斩的技能树」
### ★★ 2026-09-17 23:20（职业书美术 + 二转赠礼改成职业技能书）
- ✅ **ChatGPT 三本书大图切完**：源图 `images/591fb365-dd9b-42d8-8180-4819ffdb5d9e.png`（1508x680）
  经视觉确认三本依次是 **战士 WARRIOR(红) / 剑士 SWORDSMAN(蓝) / 近卫 GUARDIAN(白蓝)**（不是法师/游侠！）
  工具：`exported/_tools/make_jobbook_art.py`（自动按空列切三本 + 按"书/字幕"空白带切掉底部字幕，
  预乘 alpha 缩图）→ 预览 `exported/_tools/_test_out/jobbook_art_preview.png`
  · **战士** → `images/inventoryimages/musha_jobbook_warrior.png`(64²，旧图备份到
    `images/inventoryimages/_bak/musha_jobbook_warrior_旧版_20260917.png`) +
    `exported/musha_jobbook_warrior/{png 128², scml}` → 打包覆盖 `anim/musha_jobbook_warrior.zip`
  · **剑士** → `images/inventoryimages/musha_skillbook_saber.png`(64²) +
    `exported/musha_skillbook_saber/{png 128², scml}` → 打包成 `anim/musha_skillbook_saber.zip`
  · **近卫** → 只导出备用：`exported/jobbook_guardian_未上线/`（**没接任何代码**，等以后真要上近卫再说）
- ✅ **二转赠礼 = 职业技能书**（用户选 A）：新物品 `musha_skillbook_saber`（"剑士基础技能书"，
  名字/简介走现成的 `STRINGS.MUSHA_SKILLBOOK_SWORDSMAN`，中英都有）；右键 → 解锁剑气斩 Lv1 → 消耗。
  组件侧 `ADVANCE_GIFT_MODE = "career_book"`（可选 "scroll" 通用卷轴 / "level" 旧行为直接+1级）
  + `CAREER_BOOK = { saber = "musha_skillbook_saber" }`（其它职业没书 → 自动退回通用技能卷轴）
  `modmain` PrefabFiles 已加 `musha_skillbook_saber`。素材没打包时自动退回通用技能书图标/贴图（不崩）。
- ⏳ 用户要打包的清单：① musha_jobbook_warrior.png → tex/xml（覆盖）
  ② musha_skillbook_saber.png → tex/xml（新增）③ 两个 scml → 各自 zip
  ④ 生命树枝 scml（scale 0.45）重编覆盖 anim/musha_lifebranch.zip
  ⑤ （顺手）musha_skill_scroll.zip
### ★★ 2026-09-17 23:50（用户口述：发布目标 + 挂起项 + 卷轴美术）
- 📌 **技能书"上拉选技能"列表 = 选 A（只列未解锁的技能），但整体搁置**：
  用户：「大框架等法师做完再做，要**眼前一亮**的感觉」→ 技能选择 UI / 职业大框架 /
  这些都要等**元素法师 + 药剂师**一起更新那一版才加。
- 📌 **剑气斩 8 面（引擎挑面）**：用户觉得"很浪费精力、没有官方示例，有时候会想偷懒"——
  → 结论：**不做硬要求**。要按"文字设定里原来（物质/方向）的规矩"重新研究、得有能参考的东西才往下写。
  · 现状留档：引擎挑面版已上线可测（`USE_ENGINE_FACING = true` + 官方后缀名 scml + 已编 zip），
    点名播版（`false` + `_bak_scml_点名声_20260917.scml`）一步可回退。
  · 我的建议（等用户拍）：**就留在"点名播 8 图"**——它已经能跑，而且不依赖引擎那层黑箱。
- 📌 **发布目标**：用户「一般是想**更新完月光**就发布」→ 问我要**进度差**（详见下条"上线差距"）。
- ✅ **转职卷轴的专属美术到货**：`图片/任务卷轴.png`（2048²，用户说"参考**彩虹岛**风格"）→
  `exported/_tools/make_advance_scroll_art.py` → 64² 图标 `images/inventoryimages/musha_advance_scroll.png`
  + 72² 地上贴图/scml `exported/musha_advance_scroll/`。
  prefab 侧已接（asset_exists 自检，没打包就退回原版莎草纸）→ 等打包 tex/xml + anim zip。
- 📌 用户口径：「**任务卷轴 / 技能卷轴 这两个是"通用"道具**」→（不绑职业、不属于某个进阶职业专属）。
### ★★ 2026-09-18 00:40（发布准备，0.7.9）
- ✅ **版本号 = 0.7.9**（用户定）：`modinfo.lua` 的 version + name、`musha_changelog.lua`、
  面板内联兜底（`musha_panel_screen.lua:111` 起）**四处统一**
  · 更新日志 0.7.9 条目 5 行：祭坛改版 / 二转赠礼技能书 + 通用技能卷轴 / 新美术三件 / 生命树枝修复 / 崩溃与提示修复
- ✅ **上线前清理**：测试用剑士转职书下架（PrefabFiles 移除 + prefab 改名
  `musha_jobbook_saber.lua._bak_上线前下架_20260917` + 中英 STRINGS 注释）；
  modmain **33 处 [Musha TRACE] 改走 `MUSHA_TRACE` 开关**（默认 false；定位闪退改 true）
- 🐛 **发布级隐患已修**：`musha_skillbook_saber.lua` 的兜底包 `anim/musha_skillbook.zip` **根本不存在**
  （老技能书只有图标、没世界贴图）→ 无条件登记会让**整个 mod 被禁**；已改成先探再登记
- ⏳ **剑气斩**：用户说"再测试一下" → **保持引擎挑面版（USE_ENGINE_FACING = true）不动**，
  等他实测结论；要切回点名播必须**同时**换 zip（`_bak_scml_点名声_20260917.scml` 重编）
- 素材：5 个新道具的图标（png+tex+xml）与 anim zip 都已由用户打包到位；语法校验 54 文件全过
- 剩：祭坛配方图标仍是 musha_note 占位（美术跳过）；上传工坊由用户操作（ModUploader / dst_mod_publisher）

---

## 2026-09-19 · 祭坛贴图换成「任务卷轴」（临时占位）

- `exported/_tools/altar_tex_swap.py`：把 `图片/任务卷轴.png`（2048²）缩成 **240×215** 内容、居中落在
  (160,150)，装进 `exported/musha_advance_altar/musha_advance_altar-0.png`（320×320，原点=图正中心）。
- 旧贴图备份 → `exported/musha_advance_altar/_bak/musha_advance_altar-0_原美术.png`
- scml.exe 编译 → 装进 `anim/musha_advance_altar.zip`（18844 → 26238 B）；
  旧 zip 备份 → `anim/_bak_musha_advance_altar_原美术_20260919.zip`
- `musha_advance_altar.lua` 的 `USE_CUSTOM_MODEL` 早就是 true，**代码一行没动**。
- 验：bank/build/anim 名对得上（build.bin=`musha_advance_altar`，anim.bin=`idle`）。
- 待用户实测：祭坛会不会浮空/沉地（落地点=图片正中心）、大小（嫌大改 `ALTAR_SCALE`）。
- ⚠️ scml.exe 必须吃 **Windows 路径**（bash 里用 `cygpath -w`），给 MSYS 的 `/d/...` 会报「Could not open」。


### 2026-09-19 · v2 部件贴图现状（用户口中的「被雷电击中」）
- `exported/musha v2/` 扫出 **33 / 135 张是灰阶（黑白线稿，R=G=B、大量纯黑纯白、无色）**：
  `leg-0~10` / `foot-0~7` **整组都是**；另加 `headbase-3`、`headbase_hat-3`、`hair-3`、
  `hairpigtails-3,4`、`torso-10`、`torso_pelvis-10`、`arm_upper-5,6`、`arm_upper_skin-2`、
  `arm_lower-3,4`、`hand-11,12`
- 同一部件的其它朝向是正常带色的
- ★ **用户纠正（2026-09-19）**：这批黑白线条**不是**待上色的线稿 —— 是**雷电/闪电特效**的图（**背景效果**那一层），
  由 **stategraph（sg）动画**驱动，结构很简单（用户说「**砍一刀**」= 单帧/单次斩击量级）。
  火花的锯齿主干+分叉缩小看**很像骨架**，所以称为「看似骨骼」。
  原话：「黑白线条 背景效果 这个看似骨骼 其实是雷电相关的 sg 动画 很简单 砍一刀」
- 用户用「**被雷电击中**」形容这种状态；查法：`dst-art-pipeline/scripts/png_grayness_check.py <目录> --list-bad`
- ⚠️ 我曾误判为"待上色线稿"，已纠正；动手前先问用户这批要接哪条 sg / 要不要拆独立特效 build

## 2026-09-19 14:21 换头 v3（正面换 -0/-4、侧面换 -1）★ 现役值
- 源图：`参考图\正面.png` 与 `参考图\侧面.png`（都是 1024x1289）。**参考图 里现在只剩 侧面.png**；
  正面/眼睛两张的抠底版留在 `exported\_test_out\face_eyes\`（正面.png / 眼睛_基础版本.png）
- 用户 14:15 贴的新版形象参考（粉发+白花+蓝丝带+深绿金边衣+黑靴，Q版全身）
- 换进 `musha v2` 共 6 张（headbase / headbase_hat 的 -0/-4/-1）：
```
headbase-0/-4   240x300   pivot(0.52500000, 0.28666667)   内容228x282 放(6,9)  脸中心x=126(52.5%) 下巴底217.6
headbase-1      237x304   pivot(0.57805907, 0.26644737)   内容225x286 放(6,9)  脸中心x=166.5(70.3%) 下巴底221.6
-2 背面 / -3 骨头 未换（仍 206x241 / 225x263）
```
- ★ 正/侧**同一个缩放 s=0.23438**（源图同尺寸同代重绘）→ 游戏里头大小一致
- ★ 锚点法（新）：正面图已知脸块取众数皮肤色 (254,255,239)±14 → 侧面图四连通找脸块 → 按**原版脸块比例**搬偏移
  （-0: 脸中心+0.00714fw / 下巴底-0.04676fh；-1: 脸中心-0.37872fw / 下巴底+0.01952fh）
- 备份：`_bak_换头前_20260919_142145\`(6 图) + `_bak_musha_v2.scml_20260919_142145`
- 编译：`_test_out\head_v2_fix\pack_v2_musha_r5\anim\musha.zip` 497431B
  build.bin 10 条全对（240x300×4 / 237x304×2 / 206x241×2 / 225x263×2）**anim/ 未动**（491771B）
- 待办：眼睛 `face-0_新.png`(150x100，scml 一个数都不用改) —— 用户自己整理「基础眼睛+侧面」后交 ChatGPT 出全部帧；
  **爱心眼按用户口径保留**（属于这版）


## 2026-09-19 15:09 侧脸眼睛 fit（face-4）★ 已落盘
- 源：`参考图\眼睛侧面.png`（1024x1024，自带上 alpha 不用抠底）= 侧脸单眼特写
  块：眼 353x311 @(294,313) / 眉 241x78 / 嘴 39x15 / 鼻 10x18；线色深褐(90,29,45)
- 目标：原版 `face-4`（50x75，工程唯一在用的侧脸帧）基准 = 眼30x29@(13,13) 眉26x14@(22,1) 嘴15x6@(35,58)
- ★ **不能整体等比缩**（新图嘴/眼 = 0.11，老图 = 0.5，比例差 4.5 倍）→ 按块分别对位：
  眼 353x311→30x26(×0.085) 眉 241x78→26x8(×0.108) 嘴 39x15→15x6(×0.385)，各落到原版对应框
  自检：三块落点 x[13..42]/x[22..47]/x[35..49] y[14..39]/y[7..14]/y[58..63]（嘴与原版完全重合）
  鼻子**没放**（原版 face-4 没有鼻子块）
- 落盘：`exported\musha v2\face\face-4.png` 50x75 2400B；备份 `_bak_侧脸_20260919_150951\`
- scml 不用改（声明就是 50x75 + pivot 0.990988,0.8533387）
- 产物：`_test_out\head_v2_fix\pack_v2_musha_r8\anim\musha.zip` 450169B（anim/ 未动 491771B）
- 复核物：`_test_out\face_eyes\face-4_对照_左原版_右新版.png`、`face-4_新侧面_标注_洋红底_6x.png`
- 未动：face-0（正面，用户自己弄）、face-5/6/7（同组另 3 帧，工程不引用）


## 2026-09-19 15:2x 侧脸眼睛改用「理想原图」的（face-4 v2）★ 已落盘
- 源：`D:\Backup\Downloads\1789801942248.png`（1024x1289 全身体、**白底 100% 不透明、无 alpha**）
- ⚠️ 这张**不能靠颜色自动找眼睛**：淡粉发丝和皮肤几乎同色（r-g 24 vs 36），紫色只有缎带的 (144,128,192)
  → 最后靠「彩色标尺网格（10% 一条，红橙黄绿青蓝紫粉棕）+ vision 读格」定位
- 眼框 = x[615..781] y[600..761]（166x161，纵横比 1.031 ≈ 原版 face-4 眼的 30x29=1.034 ✓）
  抠法：框内从四边漫水只抠"与边缘连通的肤色"（眼内部不动），去掉 665px
- 贴法：整眼缩到 30x29 贴进原版眼的框 (13,13)（含厚睫毛/眼白/虹膜；**不是**只贴虹膜）
- 落盘 `exported\musha v2\face\face-4.png`；备份 `_bak_侧脸理想眼_20260919_152820\face-4_上一版.png`
- 产物：`_test_out\head_v2_fix\pack_v2_musha_r9\anim\musha.zip`（anim/ 未动 491771B）
- 复核：`_test_out\face_eyes\face-4_对照2_左原版_右理想眼.png`、`理想原图_眼_30x29.png`、`1789801942248_标尺网格.png`
- 未定：框往右可能切了眼白（sclera 到 x~800）；眉/嘴仍是上一版（ChatGPT 重绘那套）——要一起换说一声


## 2026-09-19 15:38 侧脸 face-4 按比例放大 K=1.297（★现役值）
- 缘由：新头（headbase-1）比原版头大 → face-4 贴图没跟着放大 = "眼睛小一号"的根源
- 比例怎么来的（两条口径独立算出同一个数）：
  ① 理想原图 1789801942248.png 与我们的侧面源图（参考图\侧面.png）**同为 1024x1289 同构图**
     → 眼 166x161 × 我的缩放 s0.23438 = 38.9x37.7
  ② 占脸比：理想图的眼 = 脸的 49.7%宽/43.6%高；新脸 78.3x86.5 → 38.9x37.7  ← 与①一致
  ③ (脸块高比 86.5/73=1.185 偏低，因"可见脸块"口径不同，不采用)
  K = 38.9/30 = 1.297
- 改法：face-4 画布 50x75 → **65x97**；三部件**从原始源图重采**（避免二次插值）：
  眼 源(615,600,780,760)166x161 → 39x38 落 x[17..55] y[17..54]
  眉 源 眼睛侧面.png(376,213,616,290)241x78 → 34x10 落 x[29..62] y[9..18]
  嘴 源 眼睛侧面.png(691,731,729,745)39x15 → 20x8 落 x[46..65] y[75..82]
- scml：`<file id="4" name="face/face-4.png" width="65" height="97" pivot_x="0.990988" pivot_y="0.8533387">`
  ★pivot 归一化值不变（等比缩放天然不变），像素锚点自动 = 原值×1.297 ✓
- 备份 `_bak_侧脸放大1297_20260919_153823\`（含旧图 + scml）
- 产物 `_test_out\head_v2_fix\pack_v2_musha_r10\anim\musha.zip` 449895B（anim/ 未动 491771B）
  核对：65x97 记录 1 次 ✓ / 50x75 从 9 降到 8 ✓
- 复核：`_test_out\face_eyes\face-4_对照3_左50x75老_右65x97新.png`
- ★ 待用户确认他算的比例；若不同 → 只改 K 一个数重做（图+scml+编译一条龙）


## 2026-09-19 15:5x 豆包版侧脸眼睛落盘（face-4 = 65x97，第三版）
- 源：豆包出的 1024x1536（白底 100% 不透明 → 四边漫水抠掉 92.2%，水印在右下角不影响）
- 豆包实测三块：眼(含睫毛) 498x427 @x[157..654] y[493..919] | 眉 343x118 | 嘴(w形) 102x47
- ★ 豆包仍是「写实比例」，和 face-4 需要的 Q 版比例差得远（所以必须逐块对位）：
  眉/眼宽 0.69 vs 需要 0.87 ； 嘴/眼宽 0.20 vs 需要 0.51（嘴小了 60%）；
  眼→嘴 纵距/眼宽 0.72 vs 需要 1.12（嘴太靠上）；眼→眉 +0.07/-0.57 vs +0.24/-0.56（位置基本对）
- 逐块缩进 65x97：眉 343x118→34x12 @(29,9) | 眼 498x427→39x33 @(17,19) | 嘴 102x47→20x9 @(46,74)
  （眼按宽对齐=39，等比下来高 33 < 目标 38 → 垂直居中；要拉满 39x38 说一声，非等比拉伸即可）
- 落盘 `exported\musha v2\face\face-4.png` 65x97 3583B md5 d9a80b40bc
  备份 `_bak_侧脸豆包版_20260919_155304\`（含上一版「理想图抠的 65x97」+ scml）
- scml 未改（画布仍 65x97；pivot 0.990988,0.8533387）
- 产物 `_test_out\head_v2_fix\pack_v2_musha_r11\anim\musha.zip` 449611B（anim/ 未动 491771B）
- 复核 `_test_out\face_eyes\face-4_对照4_左原版_中理想图抠的_右豆包版.png`


## 【2026-09-19 19:00】face-4 拆成两个部件（face + face_mouth_4）

用户拍板「2」= 拆部件。已落盘（只动 `exported/musha v2/`，未进 anim/）：

### 做了什么
1. `face/face-4.png`（65x98）= **眉 + 眼 + 下颌/下巴轮廓线**，原来的 5x3 小嘴已抹掉（透明）
2. 新建 `face_mouth/face_mouth-0.png`（19x8，pivot 0.5/0.5）= 独立的嘴
3. `musha_v2.scml` 改动：
   - 新 `folder id=19 face_mouth` + `file id=0`（19x8，pivot 0.5/0.5）
   - 新 `timeline id=98 name="face_mouth_4"`，39 个 key 全带 object（与 tl17 同步）
   - 39 个 mainline key 各加一条 `object_ref id=98 timeline=98 z_index=88 name="face_mouth_4"`
   - `face/face-4.png` 声明 65x**97** → 65x**98**（对齐实际像素）
   - tl17 (`face_4_38`) 的 O 由 `(406.85, 183.899)` → **`(418.91, 197.33)`**（让豆包的眼落回原版眼在游戏里的位置）
   - 新嘴对象 O = **`(399.7, 134.199)`** = 原版嘴在游戏里的同一个位置
4. 备份：`_bak_拆部件_20260919_184436/`（含 scml + 旧 face-4.png）
5. 编译 `_test_out/head_v2_fix/pack_v2_musha_r14/anim/musha.zip` 450360 B；build.bin 核对：`19 x 8 1 帧`（新嘴）✓、`65 x 98 1 帧`、`237x304 x2`、`240x300 x4`；157 图元

### ★ 坐标系（钉死，别再推）
- `P.x = O.x + fx - piv_left`；`P.y = O.y - (fy - piv_top)`（piv_top = h*(1-pivot_y)）
- 头像素 ← P：`hx = P.x - 226.0`；`hy = 343.699 - P.y`（由 headbase-1 O=(363,120.699)、piv=(137.0,223.0)、face-4 O=(406.85,183.899) 反推）
- 原版基准：原版 face-4 眼(27.0,26.7)→原头(147.85,122.92)；嘴(42.4,60.7)→原头(163.25,156.92)
- 验证法：把原版 arts 代进公式，眼落 (147.9) ≈ 脸块中心 (148.8) ✓

### 待办
- 用户要在 Spriter 里 File→Revert 看效果（⚠️ 别 Save，会覆盖新 O）
- 占位嘴是「原版黑线 ×1.297」= 19x8；让豆包画一张 ~19x8 的嘴替换 `face_mouth-0.png`，位置不用它管
- 可选：新头脸块比原版宽 1.44 倍（54→78）而脸层只放大 1.30 倍 → 眼可能偏小 11%，要放大就改 face-4 声明 w/h 等比 72x109


## 【2026-09-19 22:00】两条结论（别再重复踩）

### ★ headbase-1 里本来就有五官 → 叠 face 层 = 双眼睛
headbase-1 是拿 `exported/_test_out/face_eyes/侧面_抠底.png`（1024x1289）整张缩下来的：
`头 = 源 × 0.2352 + 偏移(-3.4,-2.6)`，内容 226x287 落在 237x304 画布里。
→ **眼睛、嘴都还在头里**。再把 face-4 叠上去就是两只眼错位重叠（脸层在 y143~173 那条横带整片暗色，
正好盖住头的虹膜），这就是"怪怪的"。

量化判据（可复用）：把原设缩到同尺寸，与「头单独」逐像素比 —
脸区 x110-215 y110-225 的 11076 个不透明像素里只有 **8.2%** 不同 ⇒ 头单独≈原设。
对照图：`exported/_test_out/head_v2_fix/对照_原设_vs_头单独_vs_头加脸层_vs_差异.png`

⇒ 想走"五官单独调"的路线，**头必须先换成豆包那张「重绘脸轮廓（不画五官）」的版本**
（`D:/Backup/Downloads/按最后一张重绘脸轮廓（不画五官） (1)~(7).png`），否则白干。
用户 2026-09-19 晚决定：头这块他自己处理（去问 ChatGPT / 分图层），**不要替他动 headbase**。

### 自动保存文件已全部清走
16 个（含 `anim/` 里 3 个 `*.autosave.zip`）→ `_bak_autosave_20260919_220246/`（保留原路径结构）。
用户已在 Spriter 里关掉自动保存。已确认无任何脚本引用 autosave。
`anim/musha.zip` 491771 B 未动。


## 【2026-09-19 23:00】嘴层已删 + 硬教训：别给 build 加新符号

### 已删（备份 `exported/musha v2/_bak_删嘴层_20260919_225738/`）
上一轮"拆部件"加的嘴层 `face_mouth_4` **全部撤掉**：folder 19 / timeline 98 / mainline 39 条引用，
`face_mouth/` 目录一起挪进备份。
复核：v2 的 mainline key0 **98 条 object_ref 与原版逐条完全一致**（名字 + z_index 全同），撞号 0，
folder 19 / timeline 98 与原版同数。编译 `_test_out/head_v2_fix/pack_v2_musha_r16/anim/musha.zip` 464555 B。

### ⛔ 用户明令（原话："加嘴的图层 没用 官方动画没改 以后不要这么做"）
**不要为了"以后好单独调位置"往 build 里加新符号 / 拆图层。**
- DST 能不能显示某符号由**动画（anim.bin / 各 state）有没有引用它**决定；只往 build.bin 加精灵 =
  游戏里不显示（官方动画没改）
- 新 object 还要占 z_index → 实测 `face_mouth_4` z=88 撞 `hairpigtails_3` z=88，
  把整个图层顺序搞乱（用户就是先发现"图层乱了"）
- ⇒ 改衣服 / 改五官，**就在原有符号的图里改**

### 当前 order 基线（原版 musha.scml，要对比就照这个）
`face_4_38`（侧面眼睛）z=**87**；上方 hairpigtails_4 89 / tail 90-95 / hairfront 97，
下方 face 86 / hair_hat_2 85 / headbase_hat 83 / headbase 81。`face_4_38` 在 39 个 key 里全出现。

### 下一步
用户要"重置整个衣服套装"，并打算升级到 **v3 工作区**（v2 留给可能的美术更新）。
衣服三件：`torso` 11帧(160x120等) / `torso_pelvis` 11帧(80x68等) / `skirt` 5帧(声明160x120，现为透明占位)。
模板用**原版 `exported/musha/` 里那套**（别用官方 sample_build 的尺寸，两套不通）。
换完要出「原版 vs 新版」对照图 + 逐像素差异百分比。

## 【2026-09-19 23:3x】v3 工作区整理完成（上一轮被误关窗口打断）

用户「刚刚是让你整理v3」（会话被误关，重新接上）。

- ❗ 打断痕迹：`exported/musha v3/` 第一轮只拷到字母序 `leg` 就断了 —— 缺 **skirt / swap_icon / tail / torso / torso_pelvis** 5 个目录，
  且 `musha_v2.zip` 是 **0 字节**空壳（拷到一半被中断）。文件本身都没坏。
- ✅ 已补完：5 个目录 + zip（2178658 B）补进 v3 → `diff -rq "musha v2" "musha v3"`（排除 `_bak`）**0 处不同**，
  即 v3 = v2 的逐字节副本，**不含** v2 的 `_bak_*` 历史。
- ✅ 新增 `exported/musha v3/README_这个目录是什么.md`（用途 / 内容 / 编译命令 / 衣服尺寸表 / 铁律）。
- ✅ 编译自检：`scml.exe musha_v2.scml → exported/_test_out/v3_check/anim/musha_v2.zip` = **464558 B**
  （r16 那个是 464555 B，差 3 B = build 名不同所致），工程可用。
- ⚠️ **build 名 = scml 文件名**（实测）：`musha_v2.scml` → build `musha_v2`；r16 之所以对，是因为拷到
  `v2_pack_src_r16/` 时**改名成了 `musha.scml`**。→ 要出能进游戏的包，必须先改名 `musha.scml` 再编。
- ★ **衣服三件尺寸表**（v3 与原版 `exported/musha/` 逐字节相同 = 还没动过）：
  · torso 11 帧：160x120 ×6(-0,-1,-2,-6,-7,-8) / 120x120 ×3(-3,-4,-5) / 90x120(-9) / 80x120(-10)
  · torso_pelvis 11 帧：80x68 ×9(-0..-8 同一张图) / 90x67(-9) / 90x68(-10)
  · skirt 5 帧：**实际 100x100 ×5（同一张 579 B 全透明占位）**，但 **scml 声明 160x120** ⚠️ 不一致 → 重画时一起改
  · tail 12 帧：100x100 透明占位（与实际声明 250x100 不符），不在本次范围
- ⏳ 下一步：等用户说开工 → 按上表出「逐帧透明占位 + 参考图（带 pivot 红十字）」模板给他/豆包画，
  画完在 v3 里编 `musha.scml` 出对照图 + 逐像素差异百分比；**anim/ 一行都没动**。

## 【2026-09-20 00:50】侧面头换成新剪裁的「无五官侧脸」（用户拍 C：零裁剪）

- 源：`图片/19720075-d2c2-403e-9e9c-07d47a224fca.png`（814x991，**透明底**，用户自己裁掉多余像素；内容 791x990）
- 工具 **`exported/_tools/fit_side_head.py`**（探针 `_probe_side_head.py`/`_probe_comp.py`/`_probe_map.py`）：
  口诀 =「**现役 pivot 像素就是锚点像素**」。现役 headbase-1 量出 **P=(137,223)**、脸块 80x119 @(126,126)
  → rel=(0.13750,0.81513) → 1:1 搬到新图得锚点 (497.075,701.53) → `--scale content-w`=0.28571
  → `--origin 0,21`（不给 origin 就是旧做法：pivot 保持原值但要裁 5px）
- ★ **结果：零裁剪**（左0 上0 右0 下0），写入后内容 226x283；
  **新脸块 64x114 中心 (165.5,184.5) vs 现役脸块 80x119 中心 (165.5,185.0) → 偏差 (0.0,-0.5)px**（脸落在旧位置）
- ★ **pivot 由 (0.57805907,0.26644737) → (0.59924653,0.27162049)** = 像素 (142.02,221.43)，**三处一起改**：
  `folder 4 file 1`(headbase-1) + `folder 17 file 1`(headbase_hat-1) + `folder 8 file 4`(face-4)
  · 为什么必须连 face-4 一起：这三份是**「同画布 237x304 + 同 pivot + 同 O=(363,120.699)」的 1:1 叠加族**
    （用户 2026-09-20 已在 Spriter 里把 face-4 改成 237x304 + 同 pivot + 同 O）→ 只改头的 pivot
    会让眼睛层错开 5px、还把叠加族拆散
  · ★ build.bin 实测佐证：三份 237x304 帧的 (x,y) 由 (-18.5,-71.0) → (-23.521,-69.427)，
    恰好 = pivot 位移 (+5.02,-1.57) 的镜像 ✓
- 落盘：`musha v3/headbase/headbase-1.png` + `headbase_hat/headbase_hat-1.png`（**md5 `d18726fa`**，
  原来两份逐字节相同 `bb22113e`）；备份 `_bak_新侧脸_20260920_004342/`（旧图）+
  `_bak_侧脸pivot_20260920_004703/musha_v2.scml`（旧 scml）
- 编译 `_test_out/side_head_v1/out_r2/anim/musha.zip` **470886 B**；237x304 ×3 / 240x300 ×4 ✓；`anim/` 未动
- 复核图（`exported/_test_out/side_head_v1/`）：`渲染_对照C.png`（上=旧头 下=新侧脸）、`渲染_差异图C.png`、
  `v2_C/对照_现役_vs_新版C.png`（2x + 红十字 = pivot 像素）
- 残留（重绘自身的比例差，不是摆位错）：新画的脸**窄 20%**（64 vs 80）、脸—脖子距**短 5px**；
  face-4 眼睛块实测在 (138,176)-(171,197)，落新脸块 (134,128)-(197,241) 内 ✓

## 【2026-09-20 01:00】信箱放大 2.5×（用户：截图里太小，「起码 2.5 倍」）

- 做法：**美术侧整体 ×2.5**（不是 prefab 里 SetScale —— 那是把同一张图放大 → 糊）
  `exported/_tools/make_mailbox_art.py` 加了个缩放开关：`python make_mailbox_art.py 2.5`
  （画布 / 贴图 / scml 声明一起 ×2.5；pivot 相对位置不变 → 落地点逻辑不变，prefab 代码不用动）
- 数值：内容目标高 260 → **650**（画布 320x300 → **800x750**），落地 y 690、pivot 仍 (0.5, 0.08)
- 落盘 `exported/musha_mailbox/`（PNG + scml + 洋红底预览都重出）；旧版备份
  `exported/musha_mailbox/_bak_1x_20260920_005659/`
- 编译装包：`anim/musha_mailbox.zip` 59798 B → **85079 B**（build.bin 320x300 → **800x750** ✓，
  build 名仍 `musha_mailbox` ✓）；旧包备份 `anim/_bak_musha_mailbox_1x_20260920_005730.zip`
- 复核图：`exported/_test_out/mailbox_25x/信箱_对照_截图1x_vs_2.5x.png`
  （按截图实测口径 0.651 屏幕px/声明px 把新图贴在你截图旁边，杆底同一条地面线）
- ⏳ **待用户改的代码（我没动）**：`scripts/prefabs/musha_mailbox.lua:47` 的
  `MakeObstaclePhysics(inst, 0.6)` —— 视觉 ×2.5 后碰撞半径还是 0.6 → 玩家能走进信箱里，
  建议 0.6 → **1.5**（`MAILBOX_SCALE` 保持 1.0 不用改）
- ✅ **已按用户重做的源图再走一遍（暗黑调）**：`参考图\信箱-重做.png`（1024x1536，用户 01:08 放进 参考图\，
  旧的 `图片\信箱.png` 已被搬走/改名 → 脚本 SRC 改成优先读 `参考图\信箱-重做.png`，第 2 个参数可指定源图）
  · 重跑：`python exported/_tools/make_mailbox_art.py 2.5` → 画布 800x750、内容 378x649、pivot 仍 (0.5,0.08)
  · 色调实测：平均亮度 **166.6 → 128.8**、亮度<60 的近黑 **2.4% → 27.0%** ✓（DST 暗黑调）
  · 装包 `anim/musha_mailbox.zip` 85079 → **75347 B**（= 暗调版）；旧(旧源图2.5x)包备份
    `anim/_bak_musha_mailbox_25x旧源图_20260920_011016.zip`；旧美术备份
    `exported/musha_mailbox/_bak_旧源图2.5x_20260920_010953/`
  · 复核图 `exported/_test_out/mailbox_25x/信箱_对照_截图1x_vs_新源图2.5x.png`
- ★★ **用户 01:1x 定规矩（已写入 skill dst-art-pipeline + 记忆）**：
  ① **所有出图必须 DST 暗黑色调**（不只人物：道具/建筑/图标都要）；
     客观判据：不透明像素平均亮度 ≈128、亮度<60 的近黑占 ≈28%、饱和 ≈28
  ② **非人物 / 非模型的美术问题「遇到就主动审阅」**，别只做几何对位
  ③ `参考图\` 已更新（除衣服）：`信箱-重做.png`（已用）/ `信差包.png` / `魔法少女-祭坛.png` / `face4.png`
     ⏳ 还没做的：信差包、魔法少女祭坛（现役是"任务卷轴"占位美术）、face4（五官）

## 【2026-09-20 01:20】祭坛 / 信差包 / face4 三件美术 + UI 面板审计

用户口径：人物 Q 版不用管（他自己处理）；**这三张参考图都做**；**UI 面板要不要全部升级由我审 + 定规则**。

### ① 祭坛（用 `参考图\魔法少女-祭坛.png` 替换"任务卷轴"占位）
- 新工具 `exported/_tools/make_altar_art.py [内容目标高] [源图]`（默认 480）
- 画布 **533x532**、内容 477x480、**pivot (0.5, 0.063910)**（落地点 = 底座最下缘往上 5px；旧占位是"图片正中心"，口径改了）
- 480 声明px ≈ 4.8 世界单位 ≈ 2.1 个玩家高（玩家实测 ≈224 声明px）
- 装包 `anim/musha_advance_altar.zip` → **137279 B**；旧包备份 `anim/_bak_musha_advance_altar_任务卷轴_20260920_011435.zip`；
  旧美术备份 `exported/musha_advance_altar/_bak_任务卷轴_20260920_011416/`
- 复核图 `exported/_test_out/altar_new/祭坛_对照_截图_vs_新版(480).png`
- ⚠️ 尺寸想改：脚本的 TARGET_H（重新出图+编译）或 prefab `ALTAR_SCALE`（`musha_advance_altar.lua:29`，不重编）

### ② 信差包（用 `参考图\信差包.png` 出地上/手里贴图）
- 新工具 `exported/_tools/make_mailbag_art.py [内容目标高] [源图]`（默认 120；原版 papyrus 地上贴图是 204x102 做参照）
- 画布 **192x142**、内容 168x120、**pivot (0.5, 0.112676)**；装包 `anim/musha_mailbag.zip` **17093 B**
  （以前这个包不存在 → prefab 一直退回原版莎草纸；现在 `HAS_ANIM` 会自动变 true，**代码一行没动**）
- ⚠️ 图标 `images/inventoryimages/musha_mailbag.png`（64²，用**旧亮源图**做的、平均亮度 162.7）→
  要不要一起换暗调版见下面 UI 审计；换的话 tex/xml 得你重转

### ③ face4（用 `参考图\face4.png`）
- 直接装进 1:1 叠加族：`musha v3/face/face-4.png`（237x304 ✓ 同族画布、pivot 不动 = 0.59924653/0.27162049）
- 旧图备份 `musha v3/_bak_face4新_20260920_0115/face-4.png`
- 实测眼睛块 (137,158)-(171,198) ⊂ 新头脸块 (134,128)-(197,241) ✓ 对得上
- 编译自检 `exported/_test_out/side_head_v1/out_r3/anim/musha.zip` 485867 B（237x304 ×3 / 240x300 ×4 ✓）；
  **`anim/musha.zip` 没动**（角色包按铁律等你定稿）
- 复核图 `exported/_test_out/face4_new/对照_头单独_vs_头+新脸层.png`

### ④ UI 面板审计（结论 + 规则已写进 skill dst-art-pipeline）
实测（不透明像素）：`bookpage_bg` **234.6**/纯白 1.5%、`musha_note_bg` **196.3**/饱和 94.4、`bar.png` 176.0、
`nav_*` 143~153/近黑 19~28% ✅合格；图标里 `musha_note` 197.6/近黑 1.0%、`musha_skillbook`(=`book_skill`) 172.2、
`musha_mailbag` 162.7、`musha_advance_scroll` 162.8、`musha_jobbook_warrior` 151.1、`musha_sword` 145.5 偏亮；
**`musha_lifebranch` 平均亮度 10.0 / 近黑 100% → 疑似错图，单独查**。
- 新工具 `exported/_tools/ui_tone_pass.py`（线性压亮 + 去糖 + 压纯白 + 暖色 + 暗角）
- 样张（**没覆盖现役**）：`exported/_test_out/ui_audit/bookpage_bg_暗调样张.png`（234.6→170.2）、
  `musha_note_bg_暗调样张.png`（196.3→167.9）、6 张图标样张
- 对照图：`exported/_test_out/ui_audit/UI_暗调_前后对照.png`、`图标_暗调_前后对照.png`

## 【2026-09-20 01:40】信差包图标 / 信差包「发送」RPC / 邮箱叉号格 / 面板底图候选

用户口径修正：**面板底板不要按暗黑调压**（他要"阳光的 / 星星光亮那一点的，色彩风格"）；
**便签底图 = Ciel 原名风格，改不了、不动**；**生命树枝图标没坏**（回头改）；人物 Q 版他自己处理。

### ① 信差包物品栏图标（用户："忘了做，请帮我做一个"）
- `exported/_tools/make_mailbag_icon.py` 源路径改成优先 `参考图\信差包.png`（源图现在在 `图片\`，有 fallback）
- 重出 `images/inventoryimages/musha_mailbag.png`（64²，平均亮度 **162.7 → 146.1**、近黑 1.8% → 7.4%）
- ★★ **新发现：`mod_tools/png.exe <图片.png> <输出目录>` 能直接转 .tex + .xml**（以前记的"tex 只能走 GUI"是错的）
  → 已连 tex/xml 一起出好（5566B / 172B），用户不用再转；旧三件备份 `images/inventoryimages/_bak_mailbag图标_20260920_013325/`

### ② 信差包「发送」RPC
- `scripts/rpcs/musha_rpcs.lua` 末尾新增 `musha_mailbag_send`：客户端按钮 →
  `SendModRPCToServer(GLOBAL.GetModRPC("musha","musha_mailbag_send"), bag)`（bag 可省略 → 服务端自动找身上的包）
- 服务端走 **同一个** `MushaMail:MailBag()`（和关包 onclosefn 一条路，不会两套规则）
- ⚠️ 关包照旧会寄（prefab onclosefn 没动）；这条 RPC 是给"不关包也想寄"的按钮用

### ③ 邮箱叉号格（用户："叉号没做"）
- 新图 `images/musha_mail_x.png`（64²，暗槽底+粗叉；`exported/_tools/make_slot_lock_art.py`）→ png.exe 转 tex/xml
- `scripts/musha_containers.lua`：`musha_mailbox.widget.slotbg[4..12]` 填叉号图（1~3 留 nil = 原版格子）
- `scripts/prefabs/musha_mailbox_shadow.lua`：登记 ATLAS+IMAGE（带 FileOK 存在性自检，缺文件不炸 mod）
- ⚠️ slotbg 是**静态**的（照默认解锁 3 格填死）→ 升级套件后叉号不跟着退；
  动态做法（netvar 同步 unlocked + 客户端 AddClassPostConstruct 重填）已写在 `musha_containers.lua` 末尾注释
- Lua 语法校验：**68 个文件全部通过**

### ④ 面板底图候选（3 个，等用户挑）
- 新工具 `exported/_tools/make_panel_variant.py`（提亮+暖色+右上阳光晕+四芒星闪光+高光软压缩）
- 平均亮度：现役 234.6 → **A 阳光 226.2 / B 阳光+星光 223.6 / C 星光 214.1**
- 产物 `exported/_test_out/ui_audit/面板候选{A_阳光,B_阳光星光,C_星光}.png` + `面板候选_四联对照.png`
- 上一轮那套"UI 压暗"样张作废（用户否了）；boardpage_bg **没覆盖现役**

### 交付夹（用户要"单独一个文件夹"）
`musha\交付_20260920_检查用\`（00_先看这里.txt + 11 张对照图 + `素材_可打包\` 全部 png/tex/xml/scml）
⚠️ 上一版交付夹被用户删掉了（他看完就清）→ 这版重建，含两轮全部内容。

## 【2026-09-20 01:55】祭坛配方图标 + face0 眼睛专用版 + 眼睛换皮决定

用户口径：**面板底图候选先忽略**（"2忽略"）；**碰撞他自己进游戏测**；**祭坛他进游戏看，不用外面预览**；
**改色不用我做**（颜色他自己来）；人物 Q 版他自己处理。

### ① 祭坛配方图标（用户："祭坛没有配[方图标]"）
- 新图 `images/inventoryimages/musha_advance_altar.png`（64²，内容 52x58，祭坛本体缩的）→ png.exe 一并转 tex/xml
- 新工具 `exported/_tools/make_item_icon.py <源图> <出图> [inner=58] [icon=64]`（通用物品/建筑图标生成器）
- `modmain.lua` 祭坛配方那两行：atlas/image 由 `musha_note` 占位 → **musha_advance_altar**
- `scripts/prefabs/musha_advance_altar.lua`：登记 ATLAS+IMAGE（带 FileOK 自检）
- 复核图 `exported/_test_out/ui_audit/祭坛配方图标_新旧.png`；Lua 语法 68 文件全过

### ② face0「眼睛专用版」存了一份
- `exported/musha v3/face/face-0_眼睛_默认版_20260920.png`（= 现役 face-0.png 逐字节副本，150x100，
  内容 106x69 @(24,23)，pivot 0.55699605/0.64100397 → pivot 像素 (83.55, 35.90)）
- 用途：以后「眼睛换皮」的默认档底稿；改色由用户做，我不动颜色

### ③ 眼睛换皮：**决定做**（用户问"要不要做？你来决定"）
- 现状问题：眼睛看着"人+妖结合体"；face-0（正面眼睛层）是独立 PNG → 天然适合换皮
- 机制（可行、项目和原版都验证过）：
  · ⛔ **不能靠"往 build 里加一个眼睛符号"** —— 官方动画没引用就不显示（用户明令那条）
  · ✅ 走 **`AnimState:OverrideSymbol("face", "musha_eyes_<风格>", "face")`**：
    另做一个只含一帧的小 build（和 face-0 同画布 150x100 + 同 pivot），换皮时覆盖符号；
    项目里武器/手持就用的这招（skill dst-art-pipeline 有记录）
  · 玩家可调（"后期开放设置"）：设置页加一行「眼睛风格」，值走 netvar（net_tinybyte），
    各端收到就 OverrideSymbol / 清掉覆盖 → 复用现成的 SPEC/SETTINGS_UI 那套
- 我需要用户给的：**每个风格的 face-0 尺寸图（150x100，同画布，pivot 不用管我会量）**
  → 我负责打包成 build + 接 OverrideSymbol + 设置页那一行
- ⚠️ 换皮只影响玩家自己看到/服务端 Set 的可见性：OverrideSymbol 是**外观改动，只在本地生效**，
  多人要一致得走 netvar 广播（= 上面那条，各端自己 Override）

### ④ 用户问的"像素/算力"那条（回答已给）
量眼睛/嘴/鼻子/脸沟这些点 = 逐像素扫一遍图，**毫秒级**（237x304 的图 7 万像素，纯 Python 0.2~0.5 秒）：
  · 脸块/五官块定位 = 描边做屏障的连通块扫描（microwave 级）
  · 缩放+落位 = 面积平均重采样，79 万像素约 2~3 秒
  · 真正难的**不是算力**，是"重绘过的脸无法用刚性变换对齐"（五官间距是刚性不变量，差 >1.5px 就是数学上无解）
    → 所以流程才是"逐块缩进原版那个框"，而不是"整体缩放 + 平移"

## 【2026-09-20 02:1x】邮包系统四连修（碰撞 / 寄出不清包 / 发送按钮 / 出生给包开关）

用户报的：① 碰撞改 0.3 ② 寄出去的邮件在包里不自动清除、也不能一键清空 ③ 没有发送按钮 ④ 出生不带信差包

### ① 碰撞
- `scripts/prefabs/musha_mailbox.lua`：`MakeObstaclePhysics(inst, 0.6)` → **0.3**（用户实测后定的）

### ② ★★「寄出去了但包里没清掉」的真根因（重要，写下来）
- 老 `M.MoveItem` 靠 `item.components.inventoryitem.owner` 找回"原容器"再 `RemoveItem`；
  **物品躺在容器（信差包）里时 owner 不一定指向那个容器** → 摘不掉；
  紧接着 `GiveItem` 到收件箱又成功了 → 同一件东西**同时挂在包和收件箱上** = 看着"没清掉"
- 修法：新 `M.TakeFromSlot(container, slot)`（容器自己 `RemoveItemBySlot(slot)`，一定拿得掉）
  `MailBag` / `StashToBuffer` / `Pump` 三条路径全改成**先按格拿走再决定往哪送**；
  兜底顺序：收件箱 → 待寄区 → 放回原格 → 玩家背包 → 掉在包旁边（**绝不消失**）

### ③「发送」按钮（原版就有这个钩子，别自己写 widget）
- `widget.buttoninfo = { text, position, fn }` —— 原版 `containerwidget.lua:52~80` 支持挂一个按钮
- 加在 `scripts/musha_containers.lua` 的 `params.musha_mailbag.widget`：文字「发送」、位置 (0,-95,0)
- 按下 = 把包里能寄的全寄走（和关包同一个 `MailBag`）；**主机自己按**直接调 `GLOBAL.MushaMailBagSend`，
  客机按走 RPC（`musha_mailbag_send`）
- ⚠️ 原版只支持**一个** buttoninfo →「发送」和「一键清空」是同一条动作，合成一个按钮
  （要拆成两个按钮得自己写 widget 类，等用户点头）

### ④ 出生给信差包（做成开关，默认关）
- `modmain.lua` 里 `GIVE_STARTER_MAILBAG = false`；改 true = 玩家出现时身上没有包就发一个
- ⚠️ 现写法是"身上没有就给"（死了丢了会再给）；要严格"一辈子只给一次"得存 userdata —— 等用户定

- Lua 语法校验：**68 个文件全部通过**；改动文件：musha_mail.lua（模块）/
  components/musha_mail.lua / musha_containers.lua / musha_rpcs.lua / musha_mailbox.lua / modmain.lua

## 【2026-09-20 03:2x】信差包定案：出生自带（便签那套）+ 配方谁都能做

用户定："musha专属暂时不用 / **跨世界不给** / 你看过便签吗？**出生自带** / 假如玩家要有 让 musha 给他做"

### 结论：不做全服自动补发，改用**便签同款 = 原版 starting_inventory**
`scripts/prefabs/musha.lua`（跟便签一字不差的写法）：
- `local item = {"musha_note", "musha_mailbag"}` ← 第 6 个参数（player_common 里 deprecated 但仍生效）
- `TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.MUSHA = {"musha_note", "musha_mailbag"}`
- `TUNING.STARTING_ITEM_IMAGE_OVERRIDE["musha_mailbag"] = {atlas="images/inventoryimages/musha_mailbag.xml", image="musha_mailbag.tex"}`
  （角色选择界面"开局携带物品"预览读这张表：defaultskinselection.lua:54 / templates.lua:2125）

### ★ 为什么这套天生满足"跨世界不给"（原版源码实证，别自己造轮子）
- 给东西的入口只有一个：`player_common.lua:1480 OnNewSpawn` → `GivePlayerStartingItems(inst, inst.starting_inventory)`
  · 顶部注释：**"only if it is a new spawn"**，之后 `inst.starting_inventory = nil`（用完即弃）
- `player_common.lua:1265-1269 OnLoad`：注释 **"If this character is being loaded then it isn't a new spawn"**
  → 显式 `inst.OnNewSpawn = nil` + `inst.starting_inventory = nil`
  ⇒ **读档 / 下洞穴 / 换世界 / 掉线重连 都不给**；只有真正"新出生"给
- 死亡后重生 = 同一实体复活（不是 new spawn）→ 不给
- 引擎侧入口：`networking.lua:249 SpawnNewPlayerOnServerFromSim` → `player:OnNewSpawn(...)`

### 配方（已加，见上一节）
`草8 + 木板2 + 蜘蛛丝2`｜科学机器｜CHARACTER 页｜**没加 builder_tag → 谁都能做**（用户说 musha 专属暂时不用）
→ "假如玩家要有，让 musha 给他做" = 配方谁都能做，musha 帮别人做即可；老玩家没包也走这条路

### `modmain.lua` 的全服补发开关：**关掉**
`GIVE_STARTER_MAILBAG = false`（代码 + `musha_mail:GrantStarterBag()` 保留，一行就能开回来）
组件里的 `starter_bag` 存档字段留着不用，无害。

- Lua 语法校验：**68 个文件全部通过**

## 【2026-09-20 03:2x】★ 修「信箱绑定没用 / 第一次摸过的不认 / 读档全废」

用户实机反馈："进游戏——发现绑定没用 触摸绑定也没用 第一次摸过的不认 重载 读档 没用了"

### 根因（client_log 实证 + 原版源码实证）：**实体级 OnSave 写法错**
```
[00:16:51] [Musha] 玩家 KU_Tz7vY-dt 绑定收件箱于信箱      ← 当场绑定成功
[00:21:39] Missing reference: 127799 - musha_mailbox_shadow -> 3 nil
[00:21:39] Missing reference: 127799 - musha_mailbox_shadow -> KU_Tz7vY-dt nil
```
- `musha_mailbox_shadow.lua` 原写法 `inst.OnSave = function(_, data) return {owner_userid=..., unlocked=...} end`
- 原版契约（entityscript.lua:1924-1932）：**实体级 OnSave 的返回值 = 引用列表(GUID)**，
  要存的数据必须**写进传进来的 `data`**（组件级才是"返回表=数据"，两者相反！）
  → 于是 `unlocked=3` / `owner_userid=<uid>` 被当成 GUID 解析 → 存档里啥也没写 + 刷 Missing reference
- 读档后 `owner_userid = nil` → `Mail.FindShadow` 要求 `e.owner_userid == userid` 永远不成立
  → 玩家 `has_mailbox=true`（组件存档是好的）却没箱子可认 → 「绑定没用 / 摸哪个都不认」
  （死亡、重进、换世界每次都一样，等于永久锁死）

### 修了什么（3 个文件）
1. `scripts/prefabs/musha_mailbox_shadow.lua` — OnSave 改成 `data.owner_userid = ...; data.unlocked = ...`；
   OnLoad 照旧读 `data`。**这才是持久化的根修**
2. `scripts/musha_mail.lua` — 新增 `M.ClaimNearbyShadow(x,y,z,uid)`（脚边优先"我自己的"，其次**认领没主的孤儿影子**）
   与 `M.FindMyShadowAnywhere(uid)`（半径 5000 全世界搜一次，用来区分"在别的信箱那儿"和"真没了"）
3. `scripts/components/musha_mail.lua` — `UseMailbox` 改成三步：
   ① 脚边（我的 / 孤儿→认领）② 全世界找我的（在别处 → 提示"不在这儿"）③ **真没了 → 就地重建**（自愈）
   print 会带「（重建：原有收件箱已丢失）」
4. `modmain.lua` — 客机开局 2 秒拉一次 `musha_request_settings`：
   光标动作名（触摸/触摸（绑定）/触摸（打开）/升级）读客户端缓存，以前只有开一次面板才刷新

### 老存档怎么自愈（不用清档）
旧影子的 `owner_userid` 已经丢了 → 玩家**再摸一次那个信箱**：
`ClaimNearbyShadow` 发现脚边有个没主的影子 → 认领、写上 uid → 之后正常存档。
（提示语仍显示"收件箱绑定好了"，日志会带「重建」字样。）

- Lua 语法校验：**68 个文件全部通过**
- 教训写进技能：`dst-modding/references/world-component-persistence.md`（实体级 vs 组件级 OnSave 契约）
  + `container-and-mail-pitfalls.md` 第 5 节
- 同类残留（未修，dead code）：`scripts/prefabs/tome.lua` 的 `function inst:OnSave()` 也返回表

## 【2026-09-20 04:0x】信箱面板 4x3（12 格全可用）+ 信差包「发送」按钮不显示

用户："信箱面板改4x3 遗漏最后一格 设计为12就好 / 信差包 没有发送按钮"

### ① 信箱面板 → 4 列 x 3 行 = 12 格，12 格全都能解锁
- `scripts/musha_containers.lua`：`params.musha_mailbox.widget.slotpos` 从原版 shadowchester 的
  **3 列 x 4 行**（竖高）改成 **4 列 x 3 行**：格距 75、单格 64，
  X = ±112.5 / ±37.5，Y = 75 / 0 / -75（行优先：1~4 顶行 … 9~12 底行）
- ★ 底板（animbank/animbuild）**先摘掉**：原版 data/anim 里**没有 4x3 的容器底图**
  （实测只有 ui_chester_shadow_3x4 / ui_fish_box_3x4 / ui_woby_3x4 / ui_portal_*_3x4 这些 3 列 4 行）
  → 3x4 的旧占位框跟 4x3 的格子对不上，留着反而难看；摘掉后格子自己带底图（`inv_slot.tex`）功能完全正常
  → 用户画好 4x3 底板后填回 animbank/animbuild（或 bgatlas+bgimage 挂静态底图）一行即可
- "遗漏最后一格" → 是**第 12 格原来永远叉着**（旧设计 BOX_UNLOCK_STEPS 到 11 为止）：
  `scripts/musha_mail.lua` 改成 `{5, 7, 9, 12}`、`KITS[4].to = 12` → 3 → 5 → 7 → 9 → **12**（最后一档 +3）
  收件箱 `unlocked` 上限注释同步改成 12

### ② 信差包「发送」按钮不显示 → **buttoninfo 放错层了**
- 原版 `widgets/containerwidget.lua:28` 取的是 `container:GetWidget()`，
  即 `WidgetSetup()` 从 **`params.<名>.widget`** 复制出来的表；第 54 行读 `widget.buttoninfo`
- 我们原来写在 `params.musha_mailbag.buttoninfo`（顶层）→ **永远读不到，也不报错**
- 修：挪进 `widget` 里（原版 containers.lua:316/363/414/465/503 全是 `params.<名>.widget.buttoninfo`）
- 顺带确认：原版容器 widget **只支持一个** buttoninfo；手柄模式会自动隐藏按钮

- Lua 语法校验：**68 个文件全部通过**

### ③ UI 大方向（用户转来的方案，2026-09-20 记档，**本轮没动面板**）
用户拍板的原则：**功能结构 = DST/RPG 工具界面；洛可可只当视觉语言（不做结构）**
- 主页只干三件事：我是谁（职业/等级/经验）、我的成长目标（职业任务）、我能去哪（左侧导航）
  → **技能不要塞主页**；技能 = 单独一页，职业路线 = 技能树页
- 左侧导航默认展开、**点一下可以收起来**（收起后主内容占满）
- 技能树页：导航收起 + 技能树**向右伸展**；点某个技能才在右侧出「技能详情」
- 反例（已否决）：花+蝴蝶+城堡+云+彩虹+大量丝带+发光+花园 → 那是宣传图，不是操作界面
- 一句话标准："像一个认真做出来的游戏 UI，只是这个游戏恰好很漂亮"

## 【2026-09-20 04:3x】新功能：回城石（绑定任意目标 + 回家 + 3 次 / 360s 冷却）

用户需求原文："做一个回城石，绑定于任何单位之上，只要这个东西还存在，我就可以通过右键石头回家。
冷却 360 秒，可以使用 3 次，3 次之后自动移除。配方 绿宝石或者红宝石 + 2 个金子，其余的写任意。"

### 玩法（我的理解，用户可纠）
- **绑定**：手上拿着石头，对**任何东西**（建筑/生物/玩家/树/地上的东西）用（右键）→ 绑定它；可换绑，**换绑不重置次数与冷却**
- **回家**：背包里右键石头 → 传送到绑定目标的**当前位置旁边**（目标会动就跟着动）
- 目标不存在了（被拆/被杀/在另一个分片）→ 用不了 + 提示，**不扣次数**
- 冷却 360s｜3 次｜第 3 次用完石头自动消失

### 新文件
- `scripts/components/musha_recall.lua` — 全部逻辑与存档（绑定 GUID / 次数 / 冷却）
- `scripts/prefabs/musha_recall_stone.lua` — 物品（借原版宝石素材占位）
- `scripts/actions/musha_actions.lua` — 动作 11 `MUSHA_RECALL_HOME`（INVENTORY 右键 = 回家）
  动作 12 `MUSHA_BIND_STONE`（USEITEM = 拿着石头对目标用 = 绑定，priority 2 / mount_valid）
  + INVENTORY 与 **USEITEM** 两条 ComponentAction + 双端 SG handler
- `modmain.lua` — PrefabFiles 加 `musha_recall_stone`；**两条配方**（见下）

### ★ 关键实现点（都写进技能了）
1. **物品级数据必须靠组件存档**（`inst.xxx = ...` 不存）→ 绑定/次数/冷却全在 `musha_recall` 组件 OnSave
2. **绑定实体 → 存 GUID**，读档用 `LoadPostPass(newents)` 换回实体；运行时兜底 `Ents[guid]`
   （服务器上 Ents 是全世界实体，不受加载范围限制）
3. **DST 合成原料是 prefab 名精确匹配，不吃 tag**（`Container:GetCraftingIngredient` = `v.prefab == item`）
   → "红宝石**或**绿宝石" 做成**两条配方**，第二条用 `config.product = "musha_recall_stone"` 覆盖产物
   （recipe.lua:98），合成栏里显示为「回城石」/「回城石（绿宝石）」
4. `Ingredient` 真实签名 = `(type, amount, atlas, deconstruct, imageoverride)`（recipe.lua:5）—— 别照 wiki 写
5. `FindWalkableOffset(pos, 随机角, 半径, tries, check_los, ignore_walls)` —— 原版口径是 `(pos, 角, r, 8, true, false)`
6. USEITEM 自定义动作：`AddAction` + `AddComponentAction("USEITEM", 自己的组件, fn)`（**never 挂原版组件**）+ 双端 SG handler

### 配方（"其余的写任意"= 我拍的，随时改）
- 红宝石 x1 + 金块 x2 + 石头 x10 ｜ **炼金引擎** ｜ 谁都能做（要 musha 专属加 `builder_tag = "musha"`）
- 绿宝石 x1 + 金块 x2 + 石头 x10（第二条，产物同上）

### 素材（占位，等用户画）
- 地上/手上：借原版 `anim/gems.zip`（bank=gems build=gems 动画=redgem_idle）
- 图标：借原版红宝石（`images/inventoryimages.xml` / `redgem.tex`）
- 做好后丢 `anim/musha_recall_stone.zip` + `images/inventoryimages/musha_recall_stone.*` → **自动切，代码不用改**

### 没做（等用户点头）
- 悬停面板显示"剩余 X 次 / 冷却 Xs"（现在只在台词里说）→ 要做就得动 `widgets/musha_item_info.lua` + 一张动态值表
- 传送特效/音效（素材等用户）
- 跨世界（洞穴↔地面）传送 —— v1 只在本分片内；目标在别的世界时提示"它好像不在这个世界了"

- Lua 语法校验：**70 个文件全部通过**（新增 2 个）

## 【2026-09-20 05:0x】量：v2 / v3 的 face-4 与侧脸头（用户问"五官歪了还是侧脸歪了，原图哪个该重画"）

工具：`exported/_tools/_cmp_v2v3_measure.py`（实心内容 alpha>=128 口径）、`_cmp_face_on_head.py`（脸区+眼睛判读 + 2 倍放大图）
对照图：`exported/_test_out/v2v3_对比/`（`对照总表.png`、`2倍_左旧版v2_右现役v3.png`、`2倍_左v2原配_右v2脸缩到237x304叠v3头.png`）

### ① face-4 尺寸（用户问的"像素大了多少"）
- **v2 `face/face-4.png` 实际 305x384**，但 v2 的 scml 里声明的是 **237x304** → **大了 +68 宽 / +80 高**
  且**不是等比放大**（1.287x 宽 / 1.263x 高）→ 这份 v2 图**本来就不对版**（跟头不同族）
- v3 `face/face-4.png` = **237x304** ✓ 与声明一致；且与 `参考图/face4.png` **完全同内容**
  （实心像素 2391 / bbox (24,98,205,227) / 眼睛块 (137,158,171,198) 三项全同）→ 现役五官层就是他最新给的那张参考图

### ② 眼睛块大小
- v2：42x58（实心 1418px）｜ v3：35x41（实心 852px）→ **v2 的眼睛宽 1.20x、高 1.41x** —— 不是同一版眼睛画法

### ③ ★ 五官位置（横向没歪，纵向差 34px）
| | 眼睛中心在【脸区】横向 | 纵向（从脸区上沿往下） |
|---|---|---|
| v2 旧版 | 70% | **69%** |
| v3 现役 | 69% | **55%** |
- 横向差 1% → 对齐 ✓；纵向差 **14% 脸高 ≈ 33~34px** → 旧版眼睛明显更靠下
- 折成头部口径：v2 眼睛在头部实心高度 67.6% 处，v3 在 55.5% 处；相对头部内容中心 (+42.2,+49.7) vs (+42.0,+16.0)

### ④ 侧脸轮廓确实也变了（但只差"胖瘦/宽窄"，不是位置）
- v2 头实心 221x280 bbox(7,9,227,288)；v3 头实心 225x283 bbox(0,21,224,303)
- 轮廓宽度剖面（从上往下 10/25/40/50/60/75/90/97%）：
  v2 → 80/179/210/209/197/179/153/80 ｜ v3 → 93/186/207/206/**182**/**160**/153/88
  → **v3 下半张脸（60~75%）收窄 15~19px**、**头顶（10%）宽 13px**
- 最佳平移 (+2,+10) 对齐后仍有 **56.8%** 像素不同（阈值 24）→ 两版是**画得不一样**，不是纯挪位

### ⑤ 结论
- **横向没歪**（眼睛都在脸前部 70% 处）；问题在**纵向**：旧版眼睛低了 ~34px（脸高 14%）
- **该重画的是 face-4（五官层）**，且必须按 **237x304 同族**画；侧脸头不用重画
  （但 v3 头相对旧头"下颌窄、头顶宽"，所以任何按旧头对齐的旧五官必然歪）
- 待用户定：眼睛要落在脸区的 **55%（现役）** 还是 **69%（旧版）**——按侧脸解剖 55% 更合理（眼睛在鼻梁以上）

## 【2026-09-20 05:4x】把"参考图的嘴位置"换算到画布（用户要挪嘴）

用户给了两张截图：clip1 = 原来的图（457x580，带棋盘格透明底）、clip2 = 参考图（385x460，有红箭头指着他喜欢的嘴位置）。
要求：把嘴巴挪到参考位置，"尽量贴近原来"。

### 量出来的事实
- **clip1 = 当前画布的 2.000x 放大**（对齐偏移 +2.5/-24.5，命中率 99.9%）→ clip1 就是现在这份画布合成图
- **clip2 = 另一张画**：最佳对齐缩放 1.26，但描边命中率只有 **73.9%**（整体 85%）→ 不是同一张图（AI 重绘版，脸更饱满）
  ⇒ 把红箭头尖端 (303,311) 硬换算过来 ≈ 画布 **(200,229)**，但那里在当前画布上是**透明的（脸外）** → 不能用
- 当前画布侧脸前沿（鼻子→上唇）实测：(199,196) → (195,204) → (190,212) → (185,220) → (182,226)
  再往下 y≈228 前沿退回 x≈158~166（下巴往里拐）→ 脸的前缘只到 y≈227
- 现役眼睛块 (137,158)-(171,198)；"原来的嘴" ≈ 轮廓末端附近 (188~193, 224~228)（就是旧截图里那条短线）
- 建议落点：嘴中心 ≈ **(186, 223)**，宽 12~16px（贴轮廓内侧，别盖住轮廓线）—— 比原来的嘴往上收 3~5px

### 工具/产物
- `exported/_tools/_mouth_pos_calc*.py`（1~6 版迭代：bbox 对齐→双地标→对称打分→描边对齐）
- `exported/_test_out/嘴巴位置/脸区_6倍_5px网格_左上角=画布(130,190).png`（他可以直接在图上读坐标；蓝框=眼睛块）
- `exported/_test_out/嘴巴位置/画布_网格5px_红十字=参考嘴位置_3x.png`（红十字是硬换算结果，仅供参考）

## 【2026-09-20 18:0x】拿到真正的"原参考图"（D:\Backup\Downloads\Image (3).png）

用户："下载 Image (3) 这个 原参考图" → 已复制到 `参考图/原参考图_Image3_20260920.png`

### ★ 关键结论（把前面几轮的谜解开了）
- **原参考图 = 305x384，内容 279x357**；画布那份头图（237x304）就是它**缩到 1/1.275** 的版本
  （拟合：`ref = (8.6, -18.0) + canvas × 1.275`，描边吻合 66~68% —— 缩放+重新采样过，不是像素级同图）
- **带红箭头的截图（clip2）= 这张参考图 1:1 贴上去的**（偏移 +52/+31，花心对得上）
  ⇒ 箭头尖端 clip2(303,311) = 参考图坐标 **(251, 280)**
- ★ 参考图里，箭头尖端其实落在**轮廓线外侧约 10px**（那一行轮廓在 x≈235~241）
  → 箭头指的是参考图的 **唇/下巴拐角** ≈ 参考图 **(233, 282)**（轮廓由陡转平的那个角）
- 换算到画布：箭头 → (190,234)｜拐角 → (176,235)｜**两个点都在当前画布的脸外**
- 原因：当前画布的脸在 **y≈228 以下"往里收了"**（前沿 x 从 176 直接退到 159），
  参考图那一带的唇/下巴更往外饱满 → 按参考的位置放嘴，嘴会悬空
- 建议（贴现有轮廓内侧的嘴中心）= 参考图 (222,272) → 画布 **(167,227)** ✓ 在脸内（那一行前沿 x=176）

### 两条路（等用户选）
(a) 只挪嘴：画布 (167,227) 附近，宽 12~16px
(b) 真按参考：先把 y 228~240 的前沿从 x≈159 往外补到 ~175（补下巴/唇），再把嘴放到 (176,235)

### 产物
- `exported/_test_out/嘴巴位置/原参考图_红=箭头_绿=唇拐角_蓝=建议嘴_2x.png`
- `exported/_test_out/嘴巴位置/画布_红=箭头换算_绿=拐角换算_蓝=建议嘴_3x.png`（带 5px 网格）
- 脚本：`exported/_tools/_mouth_pos_ref3.py`（对齐拟合 + 换算 + 标记出图）

## 【2026-09-20 18:2x】画风体检：参考图 vs 现有各图（用户问"相通吗/画风对得上吗/换脸多久"）

工具：`exported/_tools/_style_audit.py`（调色板/描边/柔化统计 + 拼对照总表）
总表：`exported/_test_out/画风体检/画风对照总表_左到右=01..09.png`

### 素材清单（都在 D:\Backup\Downloads\ 或 mod 里）
- 01 `参考图/原参考图_Image3_20260920.png` 305x384 = 侧脸原参考（**白底不透明**！白占 ~50%）
- 02 `Image (2).png` 1024x1289（**已透明**）—— ★ 异类：跟谁都只有 22~61% 重合
- 03 `1789801942248.png` 1024x1289 = 原图（白底不透明）
- 04 `Image (1).png` 384x384、05 `Image.png` 384x384（两者 100% 相同，白底）
- 06 `参考图/测试.png` 305x384（已透明，内容=85x241 窄条 = 抠出来的一竖条五官/脸）
- 07 现役 v3 头 237x304、08 现役 face-4、09 旧 v2 头 237x304

### 只算角色像素的主色板重合度
参考(01) ↔ 原图(03) **84%**｜↔ 旧 v2 头(09) **75%**｜↔ 现役 v3 头(07) 58%｜↔ 04/05 63%｜↔ 02 **38%**
描边均色：01 rgb(102,31,47) / 03 rgb(94,27,44) / 09 rgb(103,37,48) —— 同一套；
**07 现役头 rgb(113,36,61) 且描边占比只有 17.4%（参考/原图是 26%）** ← 缩放 1/1.275 把笔触洗淡了

### 结论
1. 参考图与"原图/旧侧脸/384 那两张"是**同一套画**（同描边色同调色板）✓；**02_Image2 是异类**（另一次生成，别混用）
2. 画风对不上（58%）的原因很具体 = **现役头是参考缩小来的，缩放让描边变细变淡**，不是两套画
3. 参考图是**白底不透明**（04/05/03 也是）→ 要拿去用必须先**抠白底**；只有 02/06/现役是透明 PNG
4. 换头工时估：抠底+缩到 237x304+对齐 pivot+改 scml 三处+编译+校验+出 2 倍对照 ≈ **30~45 分钟**（1 小时内可完成，不含 face-4）
   · 辫子/发层（hairpigtails/hairfront/hair_hat）是独立图层 → 建议只换"头+脸+耳"，辫子沿用现役层（否则工时翻倍）
   · face-4 即使不算，换头后也要跟同一个变换（上次错位 34px 就是这个原因）

## 【2026-09-20 18:3x】参考图换头：抠底 + 出候选 + 备份（**未编译**）

- 抠白底工具：`exported/_tools/matte_white_bg.py`（从四边洪水填充近白/浅灰 → alpha=0，边缘 1px 羽化；
  参考图白底占 40.9%，角色 59.1%，羽化边 1347px）
- 装配工具：`exported/_tools/fit_side_head.py`（按现役脸块 rel 求锚点 → 缩放到画布 → 反推 pivot）
- **候选 A（锚点对齐）**：scale 0.7668 origin(16.6,9.7) → pivot (0.59924051, 0.27161184)，与现役几乎相同，F1 89.2%
- **候选 D（轮廓最优）**：scale 0.7668 origin(10.0,17.0) → pivot (0.57128609, 0.24745124)（头在画布里挪 ~(+6.6,-7.4)px），F1 93.8%
- 另三份（B content-h / C content-w / C2 fit）pivot 都保持现役
- 备份：`exported/_bak_侧脸候选_20260920_1830/`（候选 + 抠底源图 + 现役两份 + README_侧脸候选.txt）
- 总览图：`exported/_test_out/侧脸换头/★总览_现役+各候选_2倍.png`
  （左→右：现役 | B | C | C2 | A | D | 差异图）
- ⚠️ 编译进 anim/ 之前必须：改 scml 三处 pivot（headbase-1 / headbase_hat-1 / face-4 是同族）+ face-4 跟同一变换

## 【2026-09-20 18:3x】★★ 换头落地：发现直播工程 ≠ v3 + 已同步安装

**决策**：用户 18:2x 拍板「新头D_轮廓最优 用这个吧」→ D 已换入 v3 的 headbase-1 / headbase_hat-1，
**scml 一字未改**（理由：D 的画已落在现役同一格位 —— 脸区 F1 98.1%/零位移、整头 F1 93.7%；
D 自带的脚本 pivot (0.57128609,0.24745124) 会把头在游戏里整体挪 (+6.6,-7.4)px，故弃用，保现役 pivot）。
→ A（锚点对齐）与 D（轮廓最优）**游戏内表现完全相同**（两者 art 与 pivot 同步平移），别再当两个方案挑。

**★ 字节级发现（本轮最大收获）**
1. 游戏里现役 `anim/musha.zip`（490294 B, 09-20 00:02）= **`exported/musha/` 老工程**编的。
   验证法：现编 `exported/musha/musha.scml` → build.bin / anim.bin / atlas-0.tex **逐字节相同**。
2. `exported/musha v3/` 那套（大头 237x304 + face-4 叠层）**从来没进过游戏**。
3. 两套工程（live `musha/musha.scml` vs `musha v3/musha_v2.scml`）**只差 9 个文件声明**：
   headbase-0/-1/-2/-4、headbase_hat-0/-1/-2/-4、face/face-4（尺寸+pivot），其余 147 个文件完全一致。
   → 装 v3 = **纯换头**，不动身体/衣服/头发。
   live 旧值：headbase-1/hat-1 = 206x187 pivot(0.61431795,0.088638455)；-0/-4 = 225x225；
   -2 = 206x187；face-4 = 50x75（小帧，不是叠层）
   v3 新值：-1/hat-1 = 237x304 pivot(0.59924653,0.27162049)；-0/-4 = 240x300；-2 = 206x241；
   face-4 = 237x304 同 pivot（叠层族）
4. **头符号只出现在一个动画里**：headbase-0/-1/-2 与 headbase_hat-0/-1/-2 全部只被 `BUILD_PLAYER` 引用
   （各 39/39/78 帧）；face 层只有 face-0 与 face-4 在用，其余 31 张 face-* 是死图（引用 0 次）。
5. ⚠️ **autocompiler 认的是 `exported/<名>/<名>.scml`** → 启动游戏会按 `exported/musha/musha.scml`
   重刷 `anim/musha.zip`（00:02 那次就是这么来的）。所以换头必须落到 live 工程，否则下次启动被打回。

**已做（都是非破坏性，先备份）**
- 备份：`exported/_bak_换头D_20260920_182837/`（v3 的 headbase-1/hat-1/face-4/scml + 换前 anim 包）
        `exported/_bak_同步新头到live_20260920_183215/`（live 工程 9 张图 + musha.scml）
- 同步：v3 的 9 张头部图 → `exported/musha/`（含 D）；`exported/musha/musha.scml` 那 9 行改成 v3 值
- 编译：`scml.exe exported/musha/musha.scml` → 内部名 musha ✔ / 240x300×4 / 237x304×3 / 206x241×2 ✔
- 安装：新包 517659 B → `anim/musha.zip`（旧 490294 B 已备份）；anim.bin 与旧包**逐字节一致**（动画没动）
- 工具缺口记：`fit_side_head.py --scale` 不接受数值，量化最优 scale 只能自写脚本落位

**遗留**
- headbase-0/-2 仍是旧画（上一版把画布同步放大了而已）→ BUILD_PLAYER 那 3 帧会看到旧脸；要一起换需同变换重做
- face-4 按现役格位未动（脸区零位移，不用动）
- user 尚未进游戏验证；验证点＝头大小/脖子接缝/嘴巴位置

## 【2026-09-20 19:5x】新功能：横排技能树 UI（向右拖动版）—— S1+S2 一次做完

用户原话：「你去写技能树 向右拖动那种」。规格 = `musha-技能树UI-spec.md`（2026-09-18 定稿）。

### 数据层（服务端）
- `scripts/components/musha_profession_component.lua`
  1. **新增 `SKILL_TREE_POS`**（在 BOOK_UNLOCK_SKILL 下面）：
     `tree -> skill -> { x=列, y=行, req = { 前置key = 最低等级 } }`
     · warrior: combat_recovery(0,0) -> weapon_proficiency(1,0) 需 combat_recovery>=1
     · saber:   slash_qi(0,0) -> last_stand(1,0) 需 slash_qi>=1
     · guardian: iron_will(0,0) -> life_leech(**0,1**) 需 iron_will>=1（竖线那种连法）
     · rogue:   backstab(0,0)
  2. **`CanUpgradeSkill` 加前置拦截**（服务端硬拦，防改包）-> 缺前置返回「需要先把「X」学到 N 级」
  3. **`GetSkillView` 每条补 4 个客户端字段**：`tree_x / tree_y / pre(数组: key,name,need,cur) / pre_ok`；
     `can` 也加上了 `pre_ok`
  4. ⚠️ 坑：`SKILL_ORDER`/`SKILL_UI` 原来定义在 `CanUpgradeSkill`（第 847 行）**之后**，
     而新加的判定要用它们 -> 在文件上方**前向声明** `local SKILL_ORDER` / `local SKILL_UI`，
     并把原地的 `local SKILL_ORDER = {` / `local SKILL_UI = {` 改成纯赋值（否则新声明会遮蔽前向声明）

### UI 层（客户端）
- **新文件 `scripts/widgets/musha_skill_tree.lua`**（横排技能树控件，自包含）：
  · 裁剪 = `Widget:SetScissor(-w/2,-h/2,w,h)`；树整体挂 `canvas` 平移
  · 拖动 = 最底层放一块**透明 ImageButton 接盘**：`SetOnDown` 记起点 + `SetWhileDown` 跟手
    （点图标 = 图标自己的按钮，点空白 = 拖树；两张不会互相抢）
  · ⚠️ **屏幕像素要除以 `canvas:GetWorldScale().x`** 才是控件本地单位（面板有 PANEL_ZOOM 0.93，
    不换算会"拖了不动/跟不上手"）
  · ⚠️ **`Widget:GetPosition()` 返回 Vector3**（不是 x,y 两个数）
  · 滚动：`OnControl` 接 `CONTROL_SCROLLBACK/SCROLLFORWARD` -> 横向；两侧小箭头 +/-130；
    `ScrollToShow()` 把选中项滚进视野
  · 节点 = 76px 卡片 + 图标（`images/skill_icons/<id>.xml`；没转 tex 的退回灰块+技能名）
    + 等级角标 `2/3` + 状态角标（书=技能书锁 / 锁=前置未达标 / 满=满级）
  · 连线 = `square.tex` 拉伸的正交线：同行一条横线；跨行=先竖后横。金=前置已达标 / 灰=未达标
  · 点节点 = 选中（`on_select` 回调），**加点不放节点上**（防误点）
- `scripts/screens/musha_panel_screen.lua`（技能页）：
  · 右栏新增「技能详情」面板（232x380，默认收起）：名称/等级/当前/下一级/条件(等级+点数+前置)/tip
    + **加点 or 用技能书解锁**按钮（满级隐藏按钮、不可用灰掉且 SetClickable(false)）
    —— 按钮复用面板已有的 `SendSkillUpgrade` / `SendSkillUnlock`
  · 右上两颗小按钮 **横排 / 竖排**（默认横排）= spec 第六节的临时双版开关；旧版竖排列表整套保留
  · `SetSkillMode(mode)`（切版式：树/详情/旧网格/子页标签/底部提示 一起 Show/Hide）
  · `ShowSkillDetail(e)`（按字数折行的中文排版 `Wrap()`）
  · `RefreshSkill` 里给树喂**全量** skills（不分未学习/已学习子页）
  · `SetActivePage("skill")` -> 走 SetSkillMode + 默认焦点给树（导航上一步已自动收起，树往右伸展）
- 参考抄本（从官方 scripts.zip 抽出来放工程里）：`references/dst_official/_ref_skilltreewidget.lua`
  （官方 redux 技能树）/ `_ref_skilltreebuilder.lua` / `_ref_truescrollarea.lua`（SetScissor + 拖动滚动条）
  —— ⚠️ 官方那套是**固定面板**（625x384 底图、不可拖），不能照抄，只抄它的状态/工具函数

### 验证
- Lua 语法校验（`.mobius/skills/dst-modding/scripts/lua_syntax_check.py`）**全部通过**
- **没进游戏**：拖动灵敏度 / scissor / tooltip 换行 这三处只能用户实测
- 图标：6 张已有 tex/xml（战斗恢复/武器精通/剑气斩/我，活着/钢铁意志/生命偷取）；背刺还没有图 -> 占位

### 【2026-09-20 20:0x】★ v2 face-4 已按用户要求**还原**
- 用户原话：「mushav2 face4先还原 原来的尺寸1 我去调整」→ 自己回 Spriter 调。
- `exported/musha v2/musha_v2.scml` 的 face-4 行已**还原成原值**：
  `width="237" height="304" pivot_x="0.57805907" pivot_y="0.26644737"`（文件 1022615 B = 原版字节数）
- 我改过的那版（`width="210" height="216" pivot_x="0.62531540" pivot_y="0.26012422"`，
  由 Spriter 的 x 353.07617 / y -122.06480 / scale 0.88565,0.71116 反算）**没删**，另存在
  `exported/_bak_v2scml_face4_20260920_194555/musha_v2_改过210x216.scml`，要贴回来一句话的事。
- face-4.png 全程没动（mtime 09-20 16:10 = 用户自己那版）。

## 【2026-09-20 21:44】★ 用户口径「主模型设置为v2」→ v2 的头部/脸已接进主工程（游戏加载的那套）

用户原话：「主模型设置为v2 然后 信箱的配方你加了吗?」

### v2 vs 主工程(exported/musha) 的真实差异（逐文件 md5 对过）
- **只有 8 张图不同**：headbase-1 / headbase_hat-1（v2 = D 之前的旧头，主工程 = 用户批准的 D）、
  face/face-4（v2 = 用户 21:37 自己调的 270x273 新版）、hairpigtails-0..4（v2 = 579B 空白占位，主工程 = 真图 15212B）
- 声明差异里**大量是小数精度**（`0.833` vs `0.83300006`）→ 值相同，忽略
- 真正不同的声明：face-4（v2 270x273 / 主 237x304）、headbase-1+hat-1 的 pivot
  （v2 `0.578059/0.266447` vs v3 传下来的 `0.59924653/0.27162049`）、
  **hair_hat / hairfront / hairpigtails / skirt / tail 全是 100x100**（v2 那套是 Spriter 默认占位尺寸，主工程是原版尺寸）

### 已做（备份 `exported/_bak_v2toMAIN_20260920_214429/`）
1. `face/face-4.png` 换成 v2 那张（用户 21:37 版，**图 270x273 + 声明 270x273 = 1:1，不会再被拉伸**）
2. `headbase-1` / `headbase_hat-1` 的 pivot 改成 v2 值 `0.578059 / 0.266447`（≈ 挪 5px），
   **头的画保留 D**（v2 里那张是 D 之前的）
3. `scml.exe exported/musha/musha.scml` 重编 → 内部名 musha ✔ / 240x300×4 · 237x304×2 · **270x273×1** ✔
4. 装进 `anim/musha.zip`（523511 B，旧 517659 B 已备份）

### 没跟着搬的（会掉东西，留在主工程）
- `hairpigtails`：v2 是 579B 空白占位 → 搬过去**辫子会消失**（主工程有真图）
- `hair_hat / hairfront / skirt / tail`：v2 声明 100x100（Spriter 默认），主工程是原版尺寸
→ 用户要整套以 v2 为准时再动，先问

### ★★ 新事实：Spriter 的对象框用的是 **PNG 原生像素**，不是 scml 声明的 w/h
用户把 face-4 从「图 305x384 + 声明 237x304」改成「图 270x273 + 声明 270x273」才自洽：
- Spriter 里看到的框 = 图片自身像素 × 对象 scale（`scml.exe` 才按声明 w/h 缩放）
- 所以「图上盘多大」和「scml 写多大」不一样时，**画师在 Spriter 里调的和进游戏看到的不是一个东西**
  → 换件正解：**图缩到目标尺寸 + scml 声明同尺寸**（1:1），别再指望"图随便多大、声明说了算"

### 信箱配方（用户问的，已存在）
`modmain.lua:527` `AddRecipe2("musha_mailbox", {boards 4, cutgrass 8, goldnugget 2}, SCIENCE_ONE,
{placer=musha_mailbox_placer, min_spacing=2, atlas=images/inventoryimages/musha_mailbox.xml,
image=musha_mailbox.tex, **builder_tag="musha"}, {"CHARACTER"})`
→ 科学机器 · 木板4+草8+金块2 · CHARACTER 页 · **只有 musha 能做**（builder_tag）
信差包 `AddRecipe2("musha_mailbag", {cutgrass 8, boards 2, silk 2}, SCIENCE_ONE, {"CHARACTER"})`（谁都能做）

## 【2026-09-20 22:xx】新工具：把原版角色的编译动画拆成逐帧 PNG（威尔逊站立已出图）

用户需求：「请帮我把威尔逊的图 站立的动画拆出来」

### 素材在哪（★ 以后查角色动画先看这条）
- **build 包** = `data/anim/<角色>.zip` → `build.bin` + `atlas-0.tex`（**没有 anim.bin**，只有图）
- **动画包** = `data/anim/player_*.zip` → 有的只有 `anim.bin`（共用动画，引用各角色 build）
  · 通用站立：`player_idles.zip` → `idle`(2帧静态) / `idle_loop`(66帧循环) / `idle_inaction`(49) / `idle_sanity_*` …
  · 角色专属待机：`player_idles_<角色>.zip` → 威尔逊 `idle_wilson`(77帧) + `idle_wilson_beard`(77帧)
  · 每个动画在包里存 3 份（3 个朝向掩码），名字一样 → 取第一个即可
- 无 ktech / krane（Mod Tools 里只有 scml.exe / autocompiler.exe / png.exe）→ 自己解

### 新工具 `exported/_tools/dump_anim_frames.py`（纯标准库）
```
python dump_anim_frames.py list   <anim.zip> [更多]
python dump_anim_frames.py render <build.zip> <anim.zip> <动画名> <出参目录> [--scale 2] [--sheet] [--show-all]
```
- 内部：解 build.bin（BILD v6：符号/帧/uv 顶点/末尾 hash→名字表）+ anim.bin（ANIM v4：
  动画→帧→元素(符号hash, build帧号, 图层hash, a,b,c,d,tx,ty,z)）+ 复用 skill 的 `tex2png.py` 解图集(DXT5)
- 元件落点 = anim 的 tx/ty + build 帧的 x/y（x,y 是元件中心）；z 越大越靠前
- **默认按图层过滤掉游戏里隐藏的层**（`HIDE_DEFAULT`）：ARM_carry / LANTERN_OVERLAY / SWAP_FACE /
  BEARD / HAT / HEAD_HAT / HAIR_HAT / SWAP_BODY*(_TALL) ＋ 名字里带 swap/carry/overlay 的一律不画
  （不滤的话会多出一条"抱东西的胳膊"飘在身体右边 → 这是 DST 的 AnimState:Hide("ARM_carry") 机制，
   编译数据里照样画着，靠运行时隐藏）
- `--show-all` 可全画（看游戏内部到底塞了多少东西）

### ★★ 两条血坑（第一版全踩了，图出来是散架的）
1. **v 不要翻转**：tex2png 解出的图集（自上而下）与 build.bin 顶点里的 u/v 是同一套朝向。
   翻了以后 headbase/hair/foot 采样区的不透明率从 61%/58%/27% → **0%**（采到图集空白处）。
2. **anim 的 y 是朝下的**（= scml 里 object y 取反，见 build-compile-and-anim-decode.md 的口径）：
   渲染要按 "y 越大越靠下"；按 y 朝上再翻一次 → 人上下颠倒且部件散开。
   自检口径：**foot 的 ty(-10) 比 leg 的 ty(-40) 大 → 脚在腿下面 ✓**；headbase(-120) 最小 → 在最上面 ✓

> **⚠️ 2026-09-25 更正（详见文末 ⑬ 段）**：上面这批出图**方向其实一直是上下颠倒的** —— anim 图集
> 解码视图是垂直倒序存储（引擎加载自带翻转，四路 MAE 实锤），当时只验了"placement 对、像素倒"没看出来。
> 工具已补「sprite 级翻转 + 逐 quad/分页采样」双修。**09-20 这批产物别当方向参考**；
> 游戏内素材本来全是正的、源图无需改。

### 产物
- `exported/_test_out/威尔逊站立/idle_loop/`（66 帧 + `_idle_loop_总览.png`）
- `exported/_test_out/威尔逊站立/idle/`（2 帧静态站姿 + 总览）
- `exported/_test_out/威尔逊站立/idle_wilson/`（77 帧威尔逊专属待机 + 总览）
- scale=2 渲染；目录里那份 `atlas-0.tex` 是解码用的原图集副产物（没删，用户要清就清）
- 结构自检：图集 rect 尺寸与该帧 w/h 逐符号一致；不透明率 27~61%（都采到真图）；内容质量分布"上重下轻"✓

### 顺带发现（对做 musha 动作有用）
**共用动画包里带着 mod 角色的元件**：`player_idles.zip` 的元素里有 `skirt` / `tail` / `hairpigtails`
（威尔逊 build 里没有这些符号 → 本工具自动跳过）。也就是说原版共用动画**预置了这些槽位**，
musha 的裙子/尾巴/辫子能被原版 idle/walk 这类共用动画直接驱动。

## 【2026-09-20 22:xx】★ 修：技能树页面报 `RefreshSkill (a nil value)`

用户在游戏里点技能页 → Lua 报错（日志 `musha_panel_screen.lua:1905 SetSkillMode → attempt to call
method 'RefreshSkill' (a nil value)`）。原因：面板里的方法真名是 **`RefreshSkills`**（带 s），
我在 `SetSkillMode` 里写成了 `self:RefreshSkill(nil)` → nil 调用。
修：改成 `self:RefreshSkills(nil)`，并把多余 if/else 合成一行。
**只改 Lua 的话必须重启游戏**（不是重进世界）。



## 2026-09-20 晚 · 用户定案与提醒（多则，逐条照抄意图）

1. **face-5 / face-7 = 「笑」时显露的两张脸**（用户明示：「face-5 face-7 这两张 笑会显露出来」）。
   face 层 33 张里目前在用的至少是：face-0、face-4（现役侧脸）+ **face-5、face-7（笑）**。
   → 以后重画/换脸清单必须含这两张，别只做 face-0/face-4。

2. **模型固定 = v2**（用户再确认：「v2 现在暂时不变，模型固定指示用 v2」）。主工程 `exported/musha/`
   已按 v2 接（face-4 图 + headbase-1 / headbase_hat-1 的 pivot）。

3. **站立/侧面/摇头的「眼睛规则」改从「原始 musha」的动画里看**（不再用威尔逊拆图）。
   本地已知的「原始 musha」动画包只有一个：`anim/_bak_musha_原版_20260918.zip`
   （= `D:\Backup\Downloads\musha.zip`，md5 `52c43abb4ff0f0c511b29bb0cfa25126`，491771 B），
   **内部只有 1 个动画 `BUILD_PLAYER`（39 帧 / 40fps / root=1549510938）**，没有 idle/摇头。
   → 待用户指认真正的「原始 musha」来源（gitee 仓库？工坊原版 mod？某个压缩包？）。
   ⚠️ 用户网是**手机热点**，任何 `git fetch/pull`、下载、联网查询**必须先问**。

4. **版本 = 0.7.9 半版本**（用户原话「记录 0.79.半版本 因为 UI 动画美术未完成」）→ 准备上传更新，
   上传包/更新日志要写明是**半版本**（UI、动画、美术均未完成）。上一版正式号是 0.7.9。

5. **用户给的 QQ 图 `62760bf6430f135c7ba7b50c37ecacae.png` 色调评估**（二次元 Q 版侧身金发少女立绘，花饰+挎包+短靴）：
   高明度、低反差、高纯色的赛璐璐平涂；暖金/奶油白/粉瞳；暗部用暖棕不用黑。
   → **与 DST 互斥，属「重绘级」而非「降饱和」级**：发色要改脏稻草/褪色黄褐，肤色改灰黄苍白，
   粉瞳改暗红/琥珀，暗部要吃掉大面积（DST 近黑占比≈28%）。**待用户决定要不要我出一版改造稿。**

6. **待办**：写一个**游戏内直接测脸的调试**（强制显示 face-5 / face-7 笑表情），
   省得为了看两张脸真去触发表情。用户原话：「或者你写个调试 到时候在游戏里直接测试也好」。

## 【2026-09-21 01:xx】回城石冷却表现 + modinfo 版本号

1. **`modinfo.lua` version 改成 `"0.7.9半"`**（用户拍：可标半版本，写 0.7.9.5 也行）→ 已提交 `fe1a16e`，
   和更新日志 `musha_changelog.lua:13` 的 `ver = "0.7.9半"` 对齐。`name` 字段**没动**（仍是「Musha 0.7.9 职业系统重制版」）。
   ⚠️ 面板内联兜底 `scripts/screens/musha_panel_screen.lua:113` 起的备用列表**还是老内容**（缺 0.7.9半 那条）——
   只有 `require("musha_changelog")` 失败才走到，**用户没让补 → 未动**。
2. **回城石冷却 = 用原版，不做自定义动画**（用户问「我们自己做冷却动画 还是如何」→ 本轮定：原版）：
   · `prefabs/musha_recall_stone.lua`：SetPristine 前 `AddTag("rechargeable")` + 服务端 `AddComponent("rechargeable")`
   · `components/musha_recall.lua`：`GetCooldownLeft()` 改读 `rechargeable:GetTimeToCharge()`；
     用后 `StartCooldown()` → `Discharge(360)`（原版自己存档）；老档的自研 `cooldown_end` 在 OnLoad 迁移成剩余回充时间，
     `cooldown_end` 只留作「组件被摘掉」时的兜底。**常量仍是 `COOLDOWN = 360` / `MAX_USES = 3`，冷却是可重复的（次数才是消耗品）**。
   · 效果：物品栏 / 背包 / 快捷栏图标自动出**深蓝扇形遮罩**，360 秒转满 → 播 `frame_pst`（= 沃尔特回旋镖 / 沃尔特盾 / 旺达怀表那套）；
     客机可见（tag 在 pristine 里，事件走 `rechargechange` / `rechargetimechange`）。**不需要额外美术、不需要自己写 UI**。
   · ⚠️ 用户 AI 设计图里那张「冷却中 = 暗蓝 + 沙漏」**没采用**：引擎用的是扇形（能看出还剩多久），
     要换成沙漏图标得 `inventoryitem:ChangeImageName()` + 另一张 tex，**等用户点头再做**。
   · 语法校验 73 文件全过。

## 【2026-09-21 01:xx】面板新稿 → 主页美术「减法」定案（用户）

用户对（AI 出的）面板新稿的取舍，原话口径：
- ✅ **保留**：上方木牌兔子 / 下方木牌兔子 / **当前职业徽章**（「那是我的个人倾向，后来要再改，我负责」
  → 主页架构**不许依赖某套徽章画法**）/ 木·纸面板 / 任务进度条
- ❌ **删除**：右侧彩虹 / 背景小人·场景 / **人物立绘** / 天使翅膀 / 大量花朵 / 魔法特效
- ⏳ **待定（不锁死）**：任务行前的 ⭐ 任务标记 —— 方案已定 = **0 新素材**：
  用原版图集 `images/global_redux.xml` 的 `star_checked.tex`（实心）/ `star_uncheck.tex`（空心），
  一行 `Image(...)` 就能画（保险起见在 modmain 补 `Asset("ATLAS", "images/global_redux.xml")`）；
  不要了就删那一行代码。同理右上「关闭 X」可用现成 `images/global_redux.xml` 的 `close.tex`。
- 📌 **现役底图（给画稿的人用）**：面板 `images/bookpage_bg.png` = **1644x1109**；
  便签 `images/musha_note_bg.png` = **1800x1011**（都有 tex/xml，**这就是那个"仓库里搜不到的原图"**）。
  界面尺寸：页 890x600、PANEL_ZOOM 0.93；导航**现网 6 项** = 主页/技能/信箱/设置/礼包/图鉴（装备页收起）。
- 🧭 **导航形态**：用户拍板**左边** → ✅ 已实现（提交 `006b39a`）：三角+列表整体镜像到左侧并**默认展开常驻**，
  开关在 `musha_panel_screen.lua` 顶部 `NAV_LEFT` / `NAV_ALWAYS_SHOW`；实测左框带竖线在 content x≈-563、
  纸面左缘≈-519 → 按钮 114x40 落在 -515..-401，**主页任务行 860 不用缩**（之前估的 730 是错的）。
- 📌 便签/引导相关的 `images/musha_note_bg.png` **不许动**（用户 09-21 明确：那是引导用的）。
- 教训口径：下一版设计稿以「减法」为主；AI 出的稿只是参考，**先对代码现状再谈美术**。

## 【2026-09-21 01:xx】面板分层重做 —— 任务清单（用户要求重列）

**★ 规格口径（用户拿去喂 ChatGPT/豆包）**：整张画布 **2464x1664**（= 现有 1232x832 的 2 倍），
居中纸面区 **1780x1200**（= 890x600 的 2 倍，比例 **1.483**），四周框带 = 左右各 342px、上下各 232px。
**面板尺寸/比例不许改**（改了 7 页内容 + 导航槽坐标全废）；嫌大只调 `PANEL_ZOOM`（0.93 → 0.86 一行）。
纸面区里不画四角装饰、不写字。**`images/musha_note_bg.png`（1800x1011，比例 1.780）不许动**
—— 它属于**便签/引导**，跟面板无关；比例也跟面板对不上（塞进去会横向压 17% 或切掉上下 17%）。

**导航槽（2x 画布像素）**：槽中心 x=316，6 槽中心 y = 618 / 532 / 446 / 360 / 274 / 188（间距 86），
槽 228x80，图标 56x56 在槽内偏左 82px。

任务（编号回指用）：
| # | 事项 | 谁 | 状态 |
|---|---|---|---|
| 1 | 纸面层（按 2464x1664 / 纸面 1780x1200 出图） | 用户/AI 出图 | 待 |
| 2 | 框层（木框 + 四角装饰，含星星） | 用户/AI 出图 | 待 |
| 3 | 顶部木牌兔子层（content y ≈ +330~+410，宽 ≤420） | 用户/AI 出图 | 待 |
| 4 | 底部兔子装饰层（content y ≈ -380） | 用户/AI 出图 | 待 |
| 5 | 左导航底座 + 选中标记（**拆两张**） | 用户提取中 | 待 |
| 6 | 职业徽章 3 张 `images/panel_badge_{warrior,saber,guardian}.png`（建议 128²） | 用户发挥 | 待 |
| 7 | 主页：徽章槽 + 粉色「当前职业」横幅 + 座右铭行（每个职业一句，文案待用户给） | 我（纯 square.tex） | 可做 |
| 8 | 任务标（蓝底黄字「职业成长任务」） | 我（纯拼）或用户出图 600x88 | 可做 |
| 9 | 任务行加细进度条（行宽 860，两块 square 叠） | 我 | 可做 |
| 10 | 可选装饰层（壁挂等）+ 设置页开关（默认关） | 我 | 可选 |
| 11 | 面板整体 zoom 0.93 → 0.86（若嫌太大） | 我，一行 | 等定 |
| 12 | 回城石实测（绑定 / 回家 / 深蓝扇形冷却 360s / 3 次自毁） | 用户 | 待测 |
| 13 | 剑气斩方向（现为「代码点名播 8 图」版）复测 | 用户 | 待测 |
| 14 | 技能解锁链：「没学也能看到剑气斩」复测（新档/清档） | 用户 | 待测 |
| 15 | 技能树 UI S1（只读树 + `SKILL_TREE_POS` 布局表） | 我 | 待开工 |
| 16 | 近卫 P1+P3（钢铁意志口径 #4 / 生命偷取重复 #10 / 盾·嘲讽·反击 25%·400 血·无硬直） | 我 | 待开工 |
| 17 | 面板「两条树都打锁」（未选方向时同时列剑士/近卫） | 我 | 待做 |
| 18 | 游戏内测脸调试（强制 face-5 / face-7 笑表情） | 我 | 待做（用户点名要） |
| 19 | 回城石专属素材**已到位且名字全对**（`anim/musha_recall_stone.zip` = bank/build `musha_recall_stone` + anim `idle`；图标 `musha_recall_stone.xml` 元素名对）→ 只需**重启游戏**；仍不换再看日志 | 用户重启 / 我查日志 | 待确认 |
| 20 | 信箱升级：**套件放在「背包」容器里时 `M.FindKit` 扫不到**（`scripts/musha_mail.lua:59-72` 只 `inv:ForEachItem` 主物品栏 15 格 + 手，不扫穿戴背包容器）→ 右键信箱不变成「升级」 | 我 | 待修 |
| 21 | 升级后**容器图/叉号不更新**：方案已写在 `scripts/musha_containers.lua:137-149`（shadow 的 `unlocked` 走 netvar + 客户端 `AddClassPostConstruct("widgets/containerwidget")` 按真实 unlocked 重填槽底图） | 我 | 待做 |
| 22 | 用户口径（2026-09-21）：**容器图一旦要改，必须从组件里改，而且必须是 replica** —— 照他 musha 3.0 / 北欧神话（`references/norse_mythology_portablepot.lua`，用 `fueled:GetCurrentSection()` 分档驱动 `PlayAnimation(anim..level)`）那套「强化」写法：**等级存组件、表现由等级驱动、客户端读 replica** | 口径 | 已记 |
| 23 | 头发要加一层**厚厚的黑边**（美术层，他管） | 用户/美术 | 待 |
| 24 | 「想要在信箱里改图」+「常规首段目前没有」（**含义待确认**：我理解为信箱页要能放插图、且引导/常规版首段文案还缺） | 待定 | 待确认 |

### ★ 2026-09-21 02:xx 修：技能页崩溃（用户截图报错）+ 全工程「未声明全局」扫查
用户截图报错：`musha_skill_tree.lua:189: variable 'CONTROL_SCROLLFORWARD' is not declared`
→ 原版常量叫 **CONTROL_SCROLLFWD**（constants.lua:149 = 32；SCROLLBACK = 31）。写错 → 技能页里**任何一次按键/滚轮**都会崩。
修完顺手写了个扫描脚本 `~/musha_globals_check.py`（查「裸读的、全工程没人定义的 ALL_CAPS 全局」= strict.lua 必报的那类），
又揪出 2 个同类隐患，一并修掉：
| 文件 | 问题 | 修法 |
|---|---|---|
| `scripts/widgets/musha_skill_tree.lua:189` | `CONTROL_SCROLLFORWARD` 不存在 | 改 `CONTROL_SCROLLFWD` |
| `scripts/components/musha_keyhandler.lua` | `KEY_COMMA`/`KEY_QUOTE` 原版**没有**（只有 PERIOD/SLASH/SEMICOLON）；`MOUSEBUTTON_LAST` 也没有 | 本地补 `local KEY_COMMA=44 / KEY_QUOTE=39`；鼠标判断改 `key >= MOUSEBUTTON_LEFT` |
| `scripts/widgets/musha_item_info.lua:172` | 裸读 `MUSHA_LIVE_STATS` —— **这个全局全工程从未定义**（只有这处 + modmain 一句注释）→ 被 pcall 吞掉，武器「最终伤害」一直是死的 | 改调 modmain 的 `MushaGetLiveWeaponStats(inst, ThePlayer)`（主机会显示实时最终伤害；客机 weapon 组件为 nil 自动退回静态表） |
- 语法 73 文件全过；全局扫描现在只剩 `modmain.lua -> TRACE`（误报：`local function TRACE`）。
- ⚠️ 改完**必须重启游戏**（不是重进世界）。
- 待确认（用户 09-21 口述，未回话）：技能页「红框不该显示」、「文字要鼠标移上去才看得见 很奇怪」、
  「横排文字显示方式错了（他说他自己弄）」。游戏里现有三处框：节点描边（灰/金/选中深橙）、右栏详情外描边（灰）、加点按钮粉框
  —— 没有红色框，怀疑他指的是 ChatGPT 稿里那个红框或选中态深橙框，等他指认。

### ★★ 2026-09-21 02:xx 信箱「读档后超过 3 格的东西会丢」→ 确认会丢，已修（重要）
用户问：重载后之前存进超出限度（3 格以上）的内容会被加载还是消失？**答：旧代码会丢。**
根因（原版加载顺序，entityscript.lua:1954-1988）：
`OnPreLoad` → **各组件 OnLoad**（容器就是在这里把物品往格子里塞）→ **最后**才跑实体 `inst.OnLoad`。
我们原来把 `unlocked` 的恢复写在实体 OnLoad 里 → 容器塞物品时 `unlocked` 还是 prefab 里的默认 3
→ `params.musha_mailbox.itemtestfn` 把第 4~12 格判为"未解锁"→ `Container:OnLoad`（container.lua:996-1005）
里的 `GiveItem(inst, k)` **直接返回 false（无兜底槽）** → 物品不进箱子、变散落实体 ⇒ 玩家看到"东西没了"。
⚠️ 关键认知：不是"格子超限被裁掉"，而是**塞的时候门槛还没放下来**；只要物品在第 4~12 格，读档必中招。
修法（双保险，提交 `7ec645f`）：
1. `unlocked` / `owner_userid` 提前到 **`inst.OnPreLoad`** 恢复（它在所有组件 OnLoad 之前）
2. 加载期间 `inst._loading = true` → `itemtestfn` 一律放行，实体 OnLoad 里解除
3. 顺带确认：容器**真格数 = 12**（`params.musha_mailbox` 没写 numslots → 取 `#slotpos` = 12），所以格子本身不会少
遗留（与 #21 同源）：未解锁格的**叉号底图是静态的**（`musha_containers.lua:117-120` 按默认 3 格写死 slotbg）
→ 升到 5/7/9/12 后叉号不跟着退；要按用户口径（组件 + replica）做成 netvar + 客户端 containerwidget 重填。

### ✅ 2026-09-21 02:xx 收件箱：叉号格随升级动态变化（任务 21 完成，用户说"一起吧"）
口径落地（用户："容器图一旦要改变，必须从组件里改，还得是 replica"）：
- **新组件 `scripts/components/musha_maillevel.lua`**：构造函数里建 `net_smallbyte(inst.GUID,
  "musha_mailbox.unlocked", "musha_mailbox_unlocked_dirty")`，**双端都挂**（prefab 的 SetPristine 之前 AddComponent），
  只有服务端能 `SetUnlocked()`，客户端 `GetUnlocked()` 读同步值（读不到/0 → 退 3）。
  ⚠️ 为什么不用官方 replica：DST 的 replica 是**白名单制**（`entityreplica.lua` 的 REPLICATABLE_COMPONENTS
  只认 builder/container/health/… 官方名）→ 第三方组件名进不去，所以用"组件双端 + netvar"等价实现。
- `prefabs/musha_mailbox_shadow.lua`：SetPristine 前 AddComponent；建档 / OnPreLoad 恢复时都 `SetUnlocked`
- `scripts/musha_mail.lua`：新增 `M.SetShadowUnlocked(shadow, n)`，**建档（:111）和升级（:175）都走它**（不再直接写裸字段）
- `modmain.lua`：`AddClassPostConstruct("widgets/containerwidget")` 包住 `Open` → 若 container 带
  `musha_mail_shadow` tag，就按组件的同步值重填每个 `slot.bgimage`（已解锁 = `images/hud.xml/inv_slot.tex`；
  未解锁 = `images/musha_mail_x.xml`），并监听 `musha_mailbox_unlocked_dirty` 在开着时也重填。
- 语法 74 文件全过；全局扫描仍只剩 TRACE 误报。
- 待用户实测：升到 5/7/9/12 后**打开收件箱**看叉号是否跟着退（客机也要看），读完档再确认一次。

### 2026-09-21 02:xx 技能页三条 UI 口径（用户截图点名，提交 `c75e686`）
1. **竖排说明改常显**：原来四行说明"只在悬停时显示"（09-21 前的口径）→ 用户："恢复鼠标不在上面也可显示"。
   `musha_panel_screen.lua` 里去掉四个 `:Hide()`，`row.SetHover` 只管卡片提亮 + 第三行两套字号二选一（`row._l3`）。
2. **横排树不显示职业名**：`musha_skill_tree.lua` 去掉组标题 `MakeText(..., tree_name, ...)`（树之间只靠淡底 + 空一列分隔）；
   节点 hover 文本第一行也从「名字（树 · 等级）」改成「名字（等级）」。
3. 待定：竖排行首的 `[战士]` 标签**暂留**（未学习页会同时列多棵树，靠它区分）—— 用户没点名，要删说一声。
4. 右栏「技能详情」框：竖排行内现在信息已全（名字/等级/消耗/学完后/提示）→ 竖排模式本来就不弹它；
   只有横排点节点时才用（横排是图标，没地方放字）。

### ★ 2026-09-21 拆图工具（用户：ChatGPT 不给分层，只能手动抠 → 我来拆）
用户原话：「拆不开…得先抠图刮痧 然后重新拆开 都得截图拉出来然后手动做」→ 已给工具 + 已拆好现成的。
- **工具 `exported/_tools/cutout.py`**（纯 PIL、无 numpy；一张 1500px 图约 3 秒）：
  · `--key auto|black|white|magenta|#RRGGBB` 自动认底色（四角中位色；底色很黑时走亮度阈值）→ 抠成透明
  · 默认**自动拆连通块**（每个元素一张 PNG）+ 出 `00_contact.png` 拼版预览 + `pieces.json`（记原图坐标）
  · `--nine` 面板九宫格切（左右/上下边框自动量）、`--grid R C` 均匀切
- **已拆好的成品**（都在 `图片/` 下，该目录 .gitignore 已忽略）：
  · `图片/_拆件_面板稿_20260921/`（黑底那张面板稿 → 8 件）：木牌招牌+兔子 / 内容框(1020x647) /
    竖导航 ×2 / 红剑徽章 / 蓝交叉剑徽章 / 青绿十字徽章 / 兔子装饰
  · `图片/_拆件_徽标_20260921/`（三职业徽标那张 → 3 件，已补成 **256x256 正方形**）：
    `panel_badge_warrior_256.png`（战士·红剑）/ `panel_badge_saber_256.png`（剑士·蓝交叉剑）/
    `panel_badge_guardian_256.png`（近卫·青绿十字）
- 📌 给 ChatGPT 提要求的口径（能拆的前提）：**元素之间留空隙、不重叠、底色单一、不要阴影/发光溢出到背景**。
- ⚠️ 内容框那件比例 1.576，面板纸面是 1.483 → 直接当纸面层要横向压 6%（可接受）或重画。

### ★★ 2026-09-21 14:xx 修「客机开信箱必崩」+ 收件箱参数按 prefab 名重做（用户截图报错）
用户截图报错：`scripts/components/container.lua:4: attempt to index field 'container' (a nil value)`
（client_log 实证：`backup/client_log/client_log_2026-09-21-13-47-37.txt:1180`，栈 = AddComponent → container _ctor → setter）
**两个根因，都是"没按原版契约写"**：
1. **container 组件不能加在 SetPristine 之前**。原版 chest/backpack 都在**服务端段**加。
   我们原来加在 pristine → **客机构造这个影子实体**时容器构造函数里 `self.canbeopened = true`
   触发属性 setter → `container.lua:4 self.inst.replica.container:SetCanBeOpened()` → 客机 replica 还没建 → 崩。
   修：container 移到服务端段；pristine 只加 `_container` tag（客机靠 tag 建 container_replica）。
2. **params 的 key 必须等于实体 prefab 名**。客机 `container_replica` ctor 走 `containers.widgetsetup(self)`，
   取的是 `params[container.inst.prefab]`。我们原来挂在 `musha_mailbox` 下、实体却叫 `musha_mailbox_shadow`
   → 客机取不到参数（widget = nil）→ 就算不崩也开不出格子。
   修：`scripts/musha_containers.lua` 里改成 `MakeMailboxParams(unlocked)` 生成 **5 张表**
   （`musha_mailbox_shadow` / `_u5` / `_u7` / `_u9` / `_u12`，各自 slotbg 标对应叉号格），
   `params.musha_mailbox` 保留为别名；`WidgetSetup("musha_mailbox_shadow")`。
3. **叉号格随档位变化**（任务 21）改成原版 firepit.lua:131 那套「换容器 widget」：
   服务端 `container:WidgetSetup(档位名)`（Container:WidgetSetup 内部会自动调 replica 的那份）；
   客机由 `musha_maillevel` 组件监听 netvar → 对 `inst.replica.container` 做同样 WidgetSetup。
   → **上一版写在 modmain 的 `AddClassPostConstruct("widgets/containerwidget")` 钩子已删**（要逐个改格底图、
   跟 widget 内部结构绑死，脆）。
4. 顺带核对：`musha_mailbag`（params key = prefab 名 ✓，container 在服务端段 ✓）、
   `musha_advance_altar`（同样 ✓）都没这俩毛病，只有影子信箱中招。
- ⚠️ 换档时箱子如果正开着，已建好的格子还是旧图 → 关掉重开一次即更新（升级本来就得重开）。
- 语法 74 文件 / 全局扫描全过。

### 2026-09-21 14:xx 技能页去职业名（补两处）+ 收件箱「开着但放不进东西」（提交 `68ada9d`）
1. 技能页**职业名彻底清掉**（用户截图指着还没清的）：右栏详情等级行改成「等级 %d / %d」；
   竖排行首的 `[战士]/[剑士]` 标签置空（`tag = ""`）。横排 hover 与组标题上一轮已去。
2. 收件箱放不进东西：找到一条**客机必中**的原因 —— `itemtestfn` 里读 `inst.unlocked`
   是**服务端专用字段**，客机上恒为 nil → `or 3` → 客机永远只认 3 格 → 升级后"箱子开着也放不进"。
   改成：**客机不做限制**（视觉由 widget 档位表管、能不能放由服务端判）；服务端照旧按 `inst.unlocked` 拦。
3. 客机档位应用补了重试：除了监听 `musha_mailbox_unlocked_dirty`，还在 0/1/3 秒各补一次
   `ApplyWidget()`（首帧 netvar 可能还没同步 → 会先套 3 格那套）。
4. 待用户回：**是"第 1~3 格也放不进"还是"只有第 4 格往后放不进"** ——
   后者=没升级时叉号格本来就放不进（设计如此，先塞前 3 格 / 拿套件右键信箱升级再重开箱）。

### 2026-09-21 15:xx 右键自动存入信箱功能（提交 `a5c2b8e`）
新增功能：右键背包物品直接存入信箱
- 新增 `MUSHA_PUT_MAILBOX` 动作，支持右键背包物品直接存入信箱
- 修改 `musha_mail.lua` 组件，添加 `PutItemToMailbox` 函数处理自动存入逻辑
- 中英文语言文件新增动作字符串常量
- 状态图添加新动作处理器
- 客机不做物品放置限制，由服务端统一控制

解决升级后格子×问题，支持右键快捷操作。

### 2026-09-21 14:xx 技能页「只留横排」+ 信箱三条（提交 `f8e71de`）
用户拍板（先说要砍横排，随即改口）：「直接横排 不要竖排了」→
- `musha_panel_screen.lua`：**不再创建"横排/竖排"两颗切换按钮**；`SetSkillMode()` 里强制 `mode="tree"`。
  竖排列表的控件（skill_grid/skill_tabs/skill_foot/skill_empty）**代码留着当退路**，但永久隐藏、无入口。
信箱三条：
1. **关闭时动作名不显示"关闭"** → `musha_actions.lua` 的 `MUSHA_OPEN_MAILBOX.strfn` 新增 ⓪ 分支：
   用 `doer.replica.inventory:GetOpenContainers()` 找带 `musha_mail_shadow` tag 的容器，找到就返回
   `S("CLOSE", "触摸（关闭）")`（STRINGS 里没 CLOSE 键 → 走这个默认字，之后要改文案在语言文件加键即可）。
2. **带套件但档位不对应该开箱**（用户 09-21 口径）→ `components/musha_mail.lua`：
   `UseMailbox` 改成"只有 `UpgradeMailbox()` 返回 true（=真升级了）才 return"，其余继续走正常开/绑定/关箱；
   `UpgradeMailbox` 的三条失败路径（还不是我的收件箱 / 已满级 / 套件档位不对）**全部改成 return false 且不提示**。
3. **锁格设计保持现状**（用户选 1）：没升级的格子打叉 + 放不进。
4. ❓未决（已问用户）："右键移动物品进去没用，需要手动" —— 原版 DST 往容器放东西的正规手势是**拖拽**／
   拿着物品对容器用；`itemtile.lua:463` 那套 **Shift(交易) + 左键**是原版"放进开着的容器"的写法，
   **右键物品 = 使用**，所以"右键塞进箱子"不是原版行为。要的话可以给收件箱加这个快捷（属于新增交互）。

### ★★ 2026-09-21 21:xx 修「进世界必崩」—— ui_elements 假合并图集（用户报 client_log 崩）

**崩溃实证**：`client_log.txt:84`
`[string "scripts/util.lua"]:641: Could not find an asset matching images/ui_elements.tex in any of the search paths.`
栈：`RegisterPrefabs` → `LoadAssets` → 加载 mod Assets 时 assert。

**根因（设计层面的错，不是少转一张图）**：
`modmain.lua:112-113` 注册了 `images/ui_elements.xml` + `images/ui_elements.tex`，
把它当**合并图集**用（一个 xml 里塞 5 个 SubTexture：angel_new / purse / sponsor_frame /
close_button_red / wechat_qr）。但 `images/ui_elements.tex` **从来没被转出来过**——
这 5 个元素其实**各自都是独立的单元素图集**（`images/angel_new.{png,xml,tex}` 等全都在，
每个 xml 只有一张全图 tex，SubTexture 名 == 文件名）。
→ 合并图集是"只画了 xml、没拼图也没转 tex"的半成品，硬注册不存在的资源 = 必崩。

**已改（3 个文件，都备份了）**：
1. `modmain.lua:112-113` → 删掉假合并图集注册，改成注册**真实存在的 4 张独立图集**
   （angel_new / purse / sponsor_frame / close_button_red；wechat_qr 无代码引用，先不注册留备用）。
   加了注释说明这段历史，避免以后有人又去拼合并图集。
2. `scripts/screens/musha_panel_screen.lua` 4 处引用 `images/ui_elements.xml` → 改成各自图集：
   `:487` 红叉 → `images/close_button_red.xml`；`:515` 天使女孩 → `images/angel_new.xml`；
   `:521` 荷包 → `images/purse.xml`；`:527` 赞助框 → `images/sponsor_frame.xml`。
3. `images/ui_elements.xml` 删除（SubTexture 坐标本来就是错的，x/y 全 0 没法用）。
   备份在 `images/_bak_ui_elements.xml_20260921_ui_elements`。
   ⚠️ 上一段会话最后给 ui_elements.xml 加 wechat_qr 条目那步是**无效操作**——
   它只是改了个没被加载的 xml，没转 tex，也没修注册，所以没解决崩溃。

**验证**：
- `grep ui_elements` 全工程无残留（只剩 modmain 里那两行解释注释）。
- Lua 括号配对：modmain `()` 452/452、`{}` 65/65、`[]` 21/23
  （`]]` 那个 -2 是 `:325` 一段被 `]]` 注释掉的旧代码收尾，误报，非真不配对）。
- 全 Assets 扫了一遍：注册的图片资源**全部真实存在**
  （`images/skilltree.xml` 不是本 mod 的，是**官方技能树图集**，
  见 `data/databundles/scripts/prefabs/global.lua:480`，合法引用）。

**遗留 / 待确认**：
- `images/wechat_qr.{png,tex,xml}` 已转好但**没有任何代码引用**（赞助二维码功能没接上）。
  上次会话只把 wechat_qr 条目加进了 ui_elements.xml（现已删）——要上赞助面板得重新接。
- ⚠️ **还没进游戏实测**（改了 Lua，按铁律第 8 条要退到桌面重开，不是重进世界）。

### ★ 2026-09-21 21:xx 信箱右键存入：用户提醒「这是新增交互，不是 bug 修复」
用户反馈：之前会话里我（AI）自己提的"不能从背包右键直接移入信箱"是**功能设计选择**，
不是缺陷。`2026-09-21 15:xx 右键自动存入信箱功能（a5c2b8e）`那条里的措辞要改：
- 已实现的 `MUSHA_PUT_MAILBOX`（右键背包物品直接存入信箱）是**新增便捷交互**，
  原版没有这行为（右键物品 = 使用）。
- 对外说明（更新公告 / 玩家反馈口径）应该写成"新增功能"，**不要**说成"修了右键放不进去的 bug"。

## 【2026-09-24】商业化口径定案：认领价作废 → 裸捐赠 + 公开交付（Klei 规则已核验）

### 演变三步（今天一天走完）
1. 面板赞助页原写「勋章商店 ¥2000/¥500」→ 撞元宝红线（不卖数值 / 不卖 VIP / 不动战力）→ 撤成纯自愿赞助
2. 又改成「功能认领（¥2000 商店功能 / ¥500 荣耀勋章功能，认领后全服免费上架）」→ 用户转来分析：**踩 Klei 线**
3. 讨论中出现「Patreon 分层交付物（测试版抢先 / 投票权 / 开发日志换赞助）」改口方案 → **同样违规，未采纳**

### ★ Klei 原文核验（09-24 代理下查实，三份证据）
- 公告《Clarification of Workshop Rules and Monetization》2022-02-04 官方中文页：
  「Mod 不得出售或包含任何类型的付费功能及特权或**提供以换取金钱的功能**。MOD创建者**被允许提供捐赠链接**，
  但**不允许提供服务或内容以换取金钱支持或以其他方式激励捐赠**。」
- 通用 UGC 指南（support.klei.com …/360029556052）：
  「Mods that contain paywalls or sort of paid content… Including **"supporter early access"** or anything
  provided in exchange for money.」→ **"赞助者抢先体验"被逐字点名**（所以 Patreon 方案里的测试版优先 = 直接违规）
- commissions：公告评论区通行解读 = 合规（禁的是卖 mod / 入场费 / 内购；kleiforums 至今有公开接单帖）。
  ⚠️ 属**社区解读非官方条文**；剩余风险只在"游戏内打广告"的形状贴 Myth 先例
  （Myth 是在选单界面放二维码卖兑换码被点名的）
- 处罚实态：Myth = 警告 → 无视 → 新规点名 → **强制解除付费墙**；无公开处罚条款清单，手段 = 警告 / 改免费 / 工坊下架

### 判定表（落地 5 处，均需重启游戏生效）
| 方案 | 判定 | 依据 |
|---|---|---|
| 功能认领 ¥2000/¥500 | ❌ 已撤，全域残留 0 | "提供以换取金钱的功能" |
| Patreon 分层交付物 | ❌ 未采纳 | 禁回报激励捐赠 + 指南点名 supporter early access |
| 裸捐赠链接（面板荷包钮） | ✅ 保留 | 公告明文"被允许提供捐赠链接" |
| 公开交付（日志 / 路线图 / 公开测试招募 / 功能免费上架） | ✅ 保留 | 与钱零挂钩，不构成交换——这就是防"塌房"的交代 |

已改 5 处：README 赞助节（裸捐赠 + 公共交付 + 致谢不作诱因 + 公告口径引文）、README 工坊短版、
面板 `qr_hint`「自愿捐赠 · 无任何回报 ~ 点任意处关闭」、`t1`「自愿赞助（内容全员免费）」、
上段注释（记录认领价作废 + 规则出处）。changelog 赞助行"愿者上钩"措辞 = 天然合规，未动。

### 立场记录（**内部后手，不进公开文档**——"路牌不解释自己"）
「开门 vs 吆喝」论证：真想收钱直接甩二维码即可，犯不着在天使身上缝荷包；
荷包钮无档位 / 无解锁 / 无 VIP 标 / 无 FOMO / 无 guilt trip = **开门**。违规的是**吆喝**：
赞助档位、满额解锁、VIP 角标、礼包绑赞助者。→ 公开文档只留事实句（免费 / 无附加条件 / 无游戏内权益），
**不写自我辩护段**（越解释越像心虚、主动邀请审视）；此论证留着被质疑（工单 / 抬杠）时再拿。

### 挂起（等用户）
- **SPONSORSHIP.md 并不存在**（对面讨论一直按它存在在说）；现有实体 = README 商业化节。
  要不要按「四行事实句 + 公开交付」另立独立 SPONSORSHIP.md —— 等用户定
- 面板下段「服务器定制接单」+ README 商业层段：**用户与元宝讨论中，冻结待拍板**
  （讨论方向 = 付费定制走工坊之外（私单 / 委托 / B 端），与"面板撤入口"同向）
- 荣耀勋章设计文档：仍等用户明确指示（README 里只作为免费路线图功能出现）
- 天使 `SetSize(300,360)` vs ELEMENTS 120x160：等发版后修
- 09-24 其余改动（导航木牌条高 ×1.2 / 蓝色更新预告横幅移除 / 更新日志 8 条 / 图鉴 16 条 /
  信箱满档 12 口径清扫）见当日会话，**全部未提交**

## 【2026-09-25】荷包斜挂 + 认领价去留二选一（待拍板）

- 荷包（用户："图片 荷包在这，挂天使裙上斜放，可点击打开，二维码不变"）：
  `musha_panel_screen.lua` 加 `self.purse:SetRotation(15)`（官方 `Widget:SetRotation` 已从
  scripts.zip 核实存在；正=逆时针顶往左倾，嫌歪改这一个数 ±15）。点击链路
  （热区 → 两段式面板 → 收款码）与二维码**未动**；源图 `图片/荷包.png` 与线上
  `images/purse.png` 同字节（125123 B，09-21 已同步）→ 无需重导。
- 用户表态想保留 ¥2000 商店 / ¥500 徽章认领价（"作者不吃饭，大家都没有烟火人情"）→
  已给三选一：①价签移出工坊（Gitee/群私下挂定制菜单，成交走定制单、功能进公版免费，推荐）
  ②纯现口径 ③写回 mod 内（风险自担）。**等拍板**；事实层结论不变：mod 内价签 =
  公告点名"提供以换取金钱的功能"，出事形态 = 警告 + 强制撤价（Myth 同款结局）。
- 09-25 追加：① 天使 `SetSize` 300x360 → **360x480**（3 倍 / 底线 2.8，基准=编辑模式 120x160；
  ELEMENTS 已同步 sx/sy/w/h；比例失真 13.6% → 2%；脚底≈-459 踩出≈43px，嫌大退 336x448）。
  ② 用户给出"白马非马 / 香炉不是收银台"立场并问"克雷来找我怎么回" → 已交付：
  公开声明四条（免费裸捐/无附加回报/定制在坊外/原皮占位）+ 态度收尾一句；话术顺序=先事实后态度。
  ③ 荷包可点→二维码**保留**（公告明文允许捐赠链接 + 用户本轮明示"二维码不变"）。
- 09-25 追加②：**佛谛上板 / 上 MD**（用户："写在赞助面板上……整合下面的，佛谛不改；MD和GiteE都请更新"）：
  · 面板两处：赞助面板底条加"白马非马，但不能白马无马，白马无马，观音没有如来。"（原话含标点一字未改，
    字号 20 / y=-126）；收款码下加"作者不吃饭，大家都没有烟火人情"（`qr_note`，已接进 show/hide 链）。
  · README 赞助节尾新增 **作者的话** 整段引用（商业模式 / 魔鬼与爱物 / 白马非马 / 观音如来 四段原文照录，
    含悬空"——"与"，。"原样）+ 收尾行"摆的是观音的炉，不是如来的殿——作者不吃饭…香照烧"；工坊短版补同一收尾行。
  · Gitee 推送**待用户点头**（热点规矩：联网 git 必先问；推送前需先提交，仓库内 09-21 夜至今改动全部未提交）。
- 09-25 追加③：**措辞纠偏**（用户："切忌勿写香炉、勿写香灰……何必再添如来。教'你'是学网，教'人'是学忘"）：
  · 上轮自造"摆的是观音的炉/如来殿/添香随缘/香照烧"收尾 = 违禁实词（香炉/香灰系）→ README 与工坊短版**已删**；
    把"不写佛谛/如来来而不来/既要观音又非如来"当经文引进 README = 误读（那是指引非经文）→ **引用里已撤出**。
  · 保留：截图原话两句（商业模式/魔鬼与爱物 + 白马非马…观音没有如来）+ 烟火行"作者不吃饭，大家都没有烟火人情"；
    面板佛谛行（=截图原话）与 qr_note 无香/炉/灰字样，**不动**。
  · 往后口径：公开文本不写比喻实词（写明了唐僧就是太上）、不堆佛典（读后徒呼奈何）、不摆对抗姿态（一分高下则无后来）。
- 09-25 追加④：用户"最后一句删掉（脑子空了）" → 烟火行"作者不吃饭，大家都没有烟火人情"**三处全删**：
  README 赞助节尾、工坊短版尾、面板收款码下 `qr_note`（含 show/hide 接线还原）。README 引用现以
  截图原话 `白马非马……观音没有如来。——` 原样收尾（悬空破折号保留，一字未动）。面板佛谛行保留。
- 09-25 追加⑤：用户"这三句话，请写进赞助面板里" → `spons_panel` 重排：底框 560x300 → **640x440**，
  标题 y118 → 190，新增 `pquote`（UIFONT 18 / 手动 \n 5 行 / **与 README 引用同款全文一字未改**，
  用户消息里的"……"是聊天省略非原文），两段按钮 y40 / -60 → **-55 / -145**；
  原底条佛谛行 `pnote` 因内容已并入 `pquote` 而**删除**（防重复）。重启游戏生效。
- 09-25 追加⑥：荷包微调（用户："左移27像素 下移6像素"）：`purse` + 赞助热区 `spons_hot` 同步
  560,-342 → **533,-348**，编辑模式 ELEMENTS `purse` 同步。同轮用户问"商店功能¥2000/徽章¥500(原)加上了么"
  → 答：**未加**（09-25 判定后清零，全库扫描 mod 内 0 处价签）；用户新增第三项认领「种植能力 +¥200」
  并要求归进"前者按钮"→ 落点（工坊外 Gitee / mod 内·违规 / 维持无价签 / 等元宝）→ **已拍板**。
- 09-25 追加⑦：**认领价四选一 → 用户选「写回 mod 面板按钮」（Klei 线风险在选项里写明、自担）**；
  同轮更正"种植 200 和勋章是一个功能" → 徽章＋种植**同一颗钮**，不并入商店。落地（`spons_panel` 内）：
  · 底框 640x440 → **640x560**（±320/±280）；ptitle 250 / pquote 165 / 捐赠钮 55 /
    认领① -35 / 认领② -125 / 定接单钮 -215（钮间 6px、底边距 23px）。
  · 认领① = "认领：商店功能 ¥2000"；认领② = 两行"认领：荣耀勋章 ¥500（原）" + "+ 种植能力 ¥200"
    （UIFONT 26 + `SetHAlign(ANCHOR_MIDDLE)`，两行 ≈68px < 钮高 84）。
  · 两钮 → 同一张收款码，提示行新增 `qr_hint2`"功能认领 · 扫码后私聊作者确认 ~ 点任意处关闭"
    （close/open 两处链路都已挂）；t1 上方注释同步改为"原作废口径经四选一改回"。
  · README / Gitee 本轮**未动**（四选一只选了面板）。重启游戏生效。
- 09-25 追加⑧：**赞助面板改两层结构（用户原话："支付的这两个部分塞进里面去和赞助模式写在一起，
  单独在外面写是摆着要钱"）**：
  · 一级面板（`spons_panel`，底框 640x500 ±320/±250）只剩两颗栏钮：
    ptitle 190 / **第一栏 `spons_sec`「商业/赞助 模式（全员免费）」** 95（金底）/
    定接单钮 `spons_bot` -5（棕底）/ **`pquote` 作者的话沉到 -170**（用户：
    "上面那段话移到底部，不高于任何的商业显示"）。
  · 二级页（`spons_sub`，底框 640x500）：stitle 215 / 自愿赞助 110 / 认领① 10 /
    认领② -90 / **新增「← 返回」钮 `spons_back` -200**（200x48 深灰）。
  · 链路：`spons_sec` → 隐一级 Show 二级；`spons_back` → 隐二级 Show 一级；
    二级三颗支付钮 → 隐**两层**出收款码；`open_sponsor` 每次都回一级（隐 sub）；
    `close_sponsor` 关闭列表已加 `spons_sub`；Refresh 闸门只管 spons_hot/sponsor_frame，不受影响。
  · 一句话：一级面"商业/赞助 模式"是个**入口**，价签全藏二级页 —— 一级面上不再摆钱。
    重启游戏生效。README / Gitee 本轮未动。
- 09-25 追加⑨：**三项同轮微调（用户原话）**：
  · 「字体改大4号」→ 答案定为**只改作者的话**：`pquote` UICONTROLFONTS 18 → **22**；
    行宽按 27 全角重排（22×27=594 < 640），5 行文字一字未改。
  · 「认领 这类字体 全部改为变动」→ 答案定为**"认领"二字全改"变动"**（文字层面）：
    钮①"变动：商店功能 ¥2000"、钮②"变动：荣耀勋章 ¥500（原）+ 种植能力 ¥200"、
    `qr_hint2`"功能变动 · 扫码后私聊作者确认…"。面板可见 `认领` 字样 = 0（注释里的历史记录不动；
    信箱 `ClaimNearbyShadow` 的"认领孤儿影子"是另一含义，不动）。
  · 荷包 ×1.5 + 天使按形象 ×1.2（用户："总体比例重新算一遍"）：
    purse 32x48 → **48x72**；angel 360x480 → **432x576**（仍 3:4，中心 (480,-352) 不动，
    脚底随之下探 ≈-480）；挂点 = 原偏移(+53,+4)×1.2 → **(544,-347)**；
    赞助热区同比 48x64 → **72x96** 同位；`musha_edit_mode.lua` ELEMENTS angel/purse 两行同步。

- **⑩ 2026-09-25（四）：导航评估落地 / 技能栏变方位 / 荷包挪腿上 / 天使 1.8**
    - 用户四条：「天使 比例按 2.0 算 请改成 1.8」「标题导航栏 你需要评估一下 再更改」「技能栏需要变动方位」「荷包位置不对 像人一样 放大腿裙子内侧」+ 问「底板美术你有想法吗？还是把那两个主体页框框合并？」
    - **天使**：432x576 按 2.0 计 → ×0.9 → **390x520**（仍 3:4；仍高于 2.8 底线=336x448）。`musha_panel_screen.lua` L595、`musha_edit_mode.lua` ELEMENTS 同步。
    - **荷包+热区**：挂点 (544,-347) → **(600,-306)**，挪到大腿/裙子内侧（按截图比例估位，进游戏不准再报方向微调）；热区 72x96 同位；edit_mode ELEMENTS 同步。
    - **导航栏评估结论**（09-24 的 ×1.2 列账自己写了：末底 −306.1 压进左下花丛兔子 29px）：
      等比 **218.88x109.44 → 200x100**（2:1 不压图，仍比原始 182.4x91.2 大 9.7%），
      GAP2 −10.9 → **−8.4**（步距 91.6，视觉缝仍 ≈18px=09-24 目标），TOP_Y = 416−50=366；
      首顶 296 不变（让开木牌），**末底 −306 → −262 > −277**（让开花丛兔子），左缘 −600（余16）。
    - **技能栏方位**：① 树容器默认 **−124 → 0（居中）**，点节点出右栏详情时左移回 −124、收详情回中（`ShowSkillDetail` 两分支）；
      ② `musha_skill_tree.lua` 记 raw_w/raw_h，内容不满一屏时画布 hoff/voff 挪到视口正中（**够一屏时偏移恒 0，滚动/箭头/拖动与旧版逐像素一致**）——修掉"节点挤左上、右下大片空"。
    - **编辑钮**：(450,347) → **(425,347)**，避开底图红叉金环左缘（≈502）啃边 8px 的问题，净空 ≈17。
    - 招牌/红叉/兔子/两个底框都是 `images/panel_bg.png` **烤死的**——标题与框体要动只能改图（见下条待办）。
    - 待办（等用户选）：panel_bg 两个主体页框（上横幅框 + 下横线框）是否合并改图；技能页白框与底图对齐方式。**→ 09-25 均已完成，见 ⑪**
    - 全部改动 **完全重启游戏** 后生效。
    重启游戏生效。

- **⑪ 2026-09-25（四）：panel_bg 两框合并成一整页（★已发布 + 页框已接线）+ 美术贴图统一接口 + 管理窗口 exe**
    - ⑩ 的待办已拍板：用户选「**改图合并成一整页**」（抹掉 panel_bg.png 上下两框之间的隔断，合成一个大框），先出预览过目再接线。
    - 合并手术：主脚本 `exported/_tools/panel_merge_frames.py`（配套探针 `panel_merge_probe*/_fixprobe/_residue/_azone/_awhite.py`、对比 `panel_merge_cmp.py`、校验 `panel_merge_verify.py`）。
      动作区 x191-1142 / y282-358：中缝直条按列插值（上锚行 270/301、下锚行 **372**）抹掉 y304-328 的金带+白线+中缝+顶线；四角圆弧纵复制拉直；边框线连续成一页。
      三颗星特护：左上淡橙小星 x216-231 y284-299（B 区绕开）；左大星+白晕（A 区只保纯白像素=全 A 区仅 51 个、全是星晕 x227-243 y322-328）；右四角星 bbox x1094-1121 y343-368 原样保留。
      过程修掉四伤：锚点 368 压右星尾（改 372）；左上小星被 B 切半；A 啃左星星晕；右弧 37px 金色碎点（保区收紧到星 bbox）。
      校验全过：手术区外全图差异 0；右星 65 个描边暗点与原图逐一相同。
    - 预览文件：`exported/_tools/_panel_probe/merged_full.png`（1199x769 单幅）、`merged_side_by_side.png`（2408x769 左原右新）。
    - **★ 已发布**（09-25 用户「修完我进去看看」）：`art_update.py publish merged_full.png panel_bg`
      — 旧图备份 `exported/_tools/_art_backup/panel_bg_20260925_040326/`，`images/panel_bg.{png,tex,xml}` 已是合并图。
    - **★ 页框接线已做（只动框、内容坐标一动不动）**：
      skill/gift/mail/equip/dex 五页各挂 `Widget("page_frame")` 子控件于 root 相对 **(61,4)**、框尺寸 **932×638**。
      算法：底图 1199×769 → content，内纸 x[-405,527] y[-348,290]、中心 (60.6,−28.7)；root 在 (0,−33)，
      故 (61,4) 让框正好压内纸四边 —— 原 890×600 居中白框 vs 偏右 +61 的底纸 = 「框套框」成因（09-24 诊断）。
      skill/gift/equip/dex 的**冷白占位底撤掉**、skill 内圈细线撤掉（占位让位给真纸面）；
      信箱页金属框+四铆钉挂到 frame（932/638），橙灰底 840→**780×550**（新内纸左缘 −405，840 宽会压金边 15px；尺寸同 set_bg）。
      设置页无页框不动；home 无页框不动；**所有内容坐标（礼包标题 −295、任务行、技能行…）全部原位** —— 用户逐像素调过的东西不许平移。
      全部改动 **完全重启游戏** 后生效。
    - **新统一接口 `exported/_tools/art_update.py`**（用户原话：「给 agent 留个接口 可以更新贴图」）：
      `status` 列 images 里 png 新于 tex / 缺 tex｜`convert <png> [--out xx.tex]` 原地转换｜`publish <png> <图名>` 备份→拷入 images→转换。
      旧图自动备份到 `exported/_tools/_art_backup/<图名>_<时间戳>/`（png+tex+xml）；转换器 `D:/SteamLibrary/steamapps/common/Don't Starve Mod Tools/mod_tools/png.exe`，底层用法 `png.exe <in.png> <out.tex>`（同名 xml 自动生成，同图转换 MD5 逐字节一致）。
      文档在 `exported/_tools/README_ART.md`；控制台输出故意用英文（GBK 控制台显示 UTF-8 中文会乱码）。三条命令+备份+清理已实测通过，status 全绿（27 张）。
    - **管理窗口 exe**（用户：「那个工具，请加个 exe 做成管理窗口，我随时来看」）：
      `exported/_tools/art_manager.exe`（源码同目录 `art_manager.cs`；系统自带
      `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe` 离线编译 /target:winexe，源码须 UTF-8 带 BOM；**不依赖 Python/网络**）。
      功能：列 `images/` 全贴图状态（OK/STALE/MISSING，与 art_update.py 同口径）、发布 PNG（对话框多选 → 备份→拷入→png.exe 转换）、
      打开 images/备份/工具目录、日志框。重编译命令写在 .cs 头部；`art_manager.cfg` 首行可覆盖 png.exe 路径。
      无界面自检（已实测）：`--dump <file>` → 27 张全绿；`--publish <png> <图名>` → tex 2796368B 与同源一致、新图无旧图不建备份（语义同 python 版），测试残留已清。
      桌面已建快捷方式「musha 贴图管理.lnk」。
    - **跨 agent/会话没有推送通知机制**——新会话/子 agent 靠本状态文档与 README_ART.md 发现工具；接线与贴图改动一律**完全重启游戏**才生效。
- **⑫ 2026-09-25（四）：Gitee 推送完成 + art_manager 升级「scml 校验 + anim 自动打包」+ 部署 D:\饥荒开发**
    - **★ Gitee 推送**：4 提交已推上 origin/master（凭据用法见上方 Gitee 段）。之后要不要再推一律先问用户（手机热点）。
    - **需求来源（用户原话）**：「部署完美术开发工具（含自动打包）就把 exe 打包到 D:\饥荒开发，仅支持本体 mod」
      「官方打包老是出错，有一些错乱的 scml 没打包好，但是也不告知开发者」。
    - **art_manager.exe 升级**（源码 `exported/_tools/art_manager.cs`，重编译命令在 .cs 头部）：
      · 「校验 scml」/「打包 anim（校验+编译）」两个按钮 + `--check <报告文件>` / `--pack <出参目录> <报告文件>` CLI。
      · 校验口径：XML 可解析（报行/列）、根节点 spriter_data、`<folder>/<file>` 贴图文件逐个存在、
        `<animation>` **按动画段隔离**校验 timeline 引用（timeline id 每段从 0 重编，全局比对=假阳性，初版踩过）、
        同名 zip 覆盖预警；同文件同消息去重防刷屏。**ERROR 的 scml 打包时跳过并写明**（官方是静默产坏包）。
      · 打包：先删旧 `anim\<名>.zip` 逼出真产物 → `scml.exe <工程.scml> <mod根>` 逐个编译（2 参，进度走 stderr，
        异步收双流防堵死，300s 超时强杀）→ 核对产物存在 + 新鲜 + 非空；退出码=失败数，报告文件明示每条原因。
      · 路径自适应（exe 放哪都认得出本体）：`art_manager.cfg`（png=/scml=/mod=，兼容旧单行）→ exe 相对位
        `..\..`（_tools 下）→ 硬编码 `mods\musha`；png.exe/scml.exe 同目录推导。备份目录恒为
        `mod\exported\_tools\_art_backup`（部署副本与仓内副本共用一处备份）。
    - **实测全过**：`--check` 16 个 scml 全绿（0 ERROR/0 WARN，初版把 16 全误报成空工程=标签名 bug，已修）；
      `--pack` 全量 16/16 成功、0 失败、378s（musha 主工程 83s、祭坛 60s），产物到临时目录 —— 严守
      「美术未定稿不许打包进 anim/」铁律，真打包只由用户在 GUI 里点。
    - **部署完成**：`D:\饥荒开发\art_manager.exe`（27136B）。从部署位跑 `--check` 全绿（路径回退验证）、GUI 启动 3s 存活。
      桌面快捷方式「musha 贴图管理.lnk」指向仓内 _tools 副本，两副本功能一致。
    - 本轮改动（art_manager.cs/.exe、状态文档、README_ART）**尚未 git 提交**，等用户拍板后随下次推送一起。
- **⑬ 2026-09-25（五）：接球「两个重大发现」→ dump_anim_frames.py 双修（图集倒存翻转 + 逐 quad 分页采样）**
    - 来源：`exported/_tools/夜间报告_20260925.md`（另一会话夜间全链路：`sp_model_tool.py` 窗口化/逐帧截图/
      视觉审片/scml 总成，两轮审片过）+ 用户转告「修了 opencode 工具链的历史坑，有空转告 opencode」。
      报告 L42 明写「opencode 的文件没动，只在此存档」→ 唯一遗留 = `dump_anim_frames.py`，本轮接住闭环。
    - **发现①：anim 图集解码视图是垂直倒序存储的（引擎加载自带翻转；图标 tex 0xfffc 家族不翻）**。
      证据 = 回城石 / 信差包 / musha 脸 / 官方 wilson swap_icon 四路 MAE（13~35 vs 79+ 完胜）。
      dump 预览因此一直上下颠倒（placement 对、像素倒）；**游戏内素材全是正的，别因此改源图**；
      09-20 那批 dump 产物不可当方向参考（该条目已加更正注）。回城石昨晚的修复**无需任何改动**（用户确认）。
    - **发现②：scml.exe 把大图切瓦片分散打包（每 6 顶点 = 1 个 quad）+ 素材多时分页图集**
      （顶点第 6 个 float = 所在页码）。按整帧 u/v 包围盒采样会串邻瓦片/别页 —— 审片「双挂坠」穿帮的根源；
      单 quad（未切块）时两法完全等价。
    - **dump_anim_frames.py 修复（本轮）**：
      · `flip_v_rows`：翻**每个 sprite 的采样像素**、布局（anim y 朝下落点）一动不动。
        （首版翻成品整帧 = 布局镜像头脚互换，A/B/C 三联目测证伪后改；与 sp 的 `crop FLIP_TOP_BOTTOM` 同口径。）
      · 逐 quad 采样：`parse_build` 存 `f["verts"]`，绘制段每 6 顶点一组（x,y 定位、u,v 取图、sampler 定页）
        采样贴回；**全部图集页都解码**（原来只读 atlas-0，分页 build 会取错图）。`f["uv"]` 包围盒仅留空值兜底。
      · 文件头结论补齐四条：①u/v 不翻 ②y 朝下 ③图集倒存→翻采样像素 ④逐 quad 按页。
    - **验证**：musha.zip `BUILD_PLAYER` frame_00/10 与 sp_model_tool（已过两轮视觉审片的参考实现）对拍
      **逐姿态一致**（正面腮红 / 背面辫子 / 侧脸精灵耳+紫瞳）；wilson `idle_wilson` 77 帧出图无回归、直立。
      A=原版（像素倒）/ B=成品整帧翻（废图）/ C=sprite 翻 三联对照存 `Temp\opencode`（临时）。
    - 夜间报告另记 scml.exe 相对路径坑（cwd 相关）；本仓 `art_manager --pack` 走**绝对路径**已 16/16 全过 —— 两口径并存无冲突。
    - 口径：凡解包图集出图的工具一律「翻采样像素 + 逐 quad 按页」；两发现档案 = 夜间报告 +
      `README_模型工具.md`。sp 侧 `--export` 逐帧图 + `REVIEW_TASK.md` 审片任务书 → 过审再编译进 anim/。
    - 本轮改动：`exported/_tools/dump_anim_frames.py`（+ 状态文档）—— **未提交**，与 ⑫ 的改动一起等拍板。



## ⑭ 2026-09-25 新版底图换页任务（进行中：水印修复迭代，未 publish、未接线）

- **用户原话目标**：主页一张 bg，其他技能页时底页 bg 要换；找 zcode 修、图包没修好 → 交给自家 AI。
- **源图**：`图片\其他版本背景的bg 大小疑问 面板字体待修.png`（1888x1312，豆包生成，09-25 11:34 写入；名字本身就是 zcode 备注：大小疑问 + 面板字体待修）。
- **摸底结论（全部数值验证过）**：
  - 大小答案：游戏内与现役同框拉伸到 1232x832（新图 1.439→1.481 横向 +2.9%；现役 1.559→1.481 横向 -5%）→ 同量级，**不裁不缩直接用**。
  - 接线对齐：内容纸横向 ±3px、导航条/外框基本重合（50/50 叠合图目检）→ 五页页框 (61,4)/932x638 **不用动**。
  - 红叉：横向比例已对齐（0.9566 vs 0.9560）；纵向上新叉比现役低 ~27px → **非主页页把 close_btn 改 (562,320)**（80x80 热区正好罩新叉 74x70）；主页保持 (563,347)。改法放 SetActivePage，按页 profile。
  - 分工（按文件名+用户原话推定，**待确认**）：主页=现役横线纸版，其余页=新版。
- **水印「豆包AI生成」修复**：位置 x[1657..1860] y[1243..1287]，半透明白字+深棕描边，压底带/花瓣/奶油边。
  - v1 整块克隆 → 右边界接缝跳变 155（天然 3）✗ 作废。
  - v2 亮字掩膜+逐行插值 → 描边没入掩膜，端点被描边污染 → 填成灰影 ✗。
  - v3 加深描边掩膜 → 叶绿被横扫出涂抹、奶油区字底残影、单端点长条填平出拖影。
  - **v4 现状**：core 判据 b>med+20（三种底色验算）+ 深描边（跳过泛绿像素、6px 邻域、sum<ref-55）+ 逐行水平插值（横条纹/暗线按行原样重建）+ 花瓣白压白排除。字形主体已消；**仍剩横纹拖影 + 奶油区字底残影（residual bright=428）** → 等 v5 收尾。
  - 脚本（全在 Temp\opencode，纯本地）：`wm_fix4.py`（主流程，出 new_nowm4.png）；诊断 `wm_phase1*`/`wm_arc_trace.py`/`wm_probe.py`/`wm_verify.py`；裁片 `wm_after4_d2.png`（目检用）。已作废：wm_fix2/3。
- **待办顺序**：v5 消残影 → 目检+给用户过目（art_update.py 规矩：publish 前预览）→ `art_update.py publish` 出 tex/xml → 面板接线（SetActivePage 换贴图 + close_btn 按页 profile，编辑模式冲突已想过：SetActivePage 不在编辑态时才重设）→ lua 平衡校验 → 完全重启进游戏验收。
- **「面板字体待修」**：新版木牌 Musha 字=亮黄泡泡字，旧版=米黄渐变柔字；修法三选（整块移植旧牌/只调色向旧版/先不修进游戏看）**待用户拍板**，尚未动手。
- **vibeX/gitee 拉取结果**（用户当轮授权的 fetch 已执行）：master 零新提交（只是把我们自己推的 45eff68 同步到位）；远端仅 hook + master 两条 head，hook = 9-21 老祖先分支（eea8e98 右键存信箱），**编辑模式重做没推上来** → 无可审阅/可合并；需让 vibeX 推上来或告知仓库。本地工作区仍有未提交改动（见 ⑫⑬），真有 incoming 时先提交再拉。
- **⚠️ 用户热点流量超支（09-25）**：本轮起**禁止任何联网**（fetch/push/pull/websearch 全停），只做本地操作，直到用户解禁。


## ⑮ 2026-09-25 晚：换页 bg 暂停（图作废/分工改口径）+ 酒馆配方图标重做完成

### 换页 bg 线 → 暂停，等即梦新图
- **新图作废**：`图片\其他版本背景的bg 大小疑问 面板字体待修.png` 被（zcode 或谁）画了 6 层任务栏搞坏，用户说白跑了、自己去**即梦**重出；**水印修复线（v4，见 ⑭）就此停止，不再修图**。
- **分工新口径（用户原话）**：主页 = 原版 bg；技能树页 = 另一张（即梦重出）；其余页 = 合并版本（上下一致，不分 2 个框）。
  - 待确认：主页「原版」指哪个文件 —— A) 合并前两框版（git `239ec44`）B) bookpage_bg V2（现存）C) 用户取回的文件。
  - 好消息：**合并前版本本地 git 就有**（`45eff68` 合并版 / `239ec44` 两框版），不用跑远路取。
- 即梦图到位后**很可能要重算 bg 大小**——测量管线现成：红叉/内纸/导航地标测量 + `overlay_5050.py` 叠合（⑭ 里全流程可复用）。
- **`images/panel_bg.png` 12:45 被外部改动**（1023854B，未提交；提交版=45eff68）。游戏读 `.tex`（04:04 版）→ **进游戏不受影响**；坏 png 只在下次 convert/publish 才生效。恢复：`git checkout 45eff68 -- images/panel_bg.png`。
- vibeX 编辑模式：截至 09-25 11:45 fetch **远端零新提交、无可审对象**；封网期间无法复查。
- ⚠️ 用户热点流量超支：只做本地操作，联网全停到解禁。

### 酒馆（祭坛）配方图标重做 ✅ 20:58 完成
- **scml 审查结论：没问题**。`exported/musha_advance_altar/musha_advance_altar.scml`（1184B）：单帧静态 idle，唯一引用 `hotel.png`（1549×1015，scale 0.49，pivot 0.485/0.132）——已从旧祭坛帧换成酒馆新画（scml 09-24 改）；旧帧 `musha_advance_altar-0.png` 闲置未引用；结构合法无断链。
- 渲染验证：`dump_anim_frames.py render anim/musha_advance_altar.zip ... idle` → **40 帧全同**（1470437B×40，静态）；`idle_00.png` 1557×1023 目检 = 完整酒馆（挂账牌/酒桶/炊烟），透明底干净。
- **新图标 128×128**（模组惯例全是 64²；128²=pow2 更清晰，UI 显示尺寸不变零风险）：idle_00 裁 alpha bbox → LANCZOS 缩放 → 可见区居中（paste 不带 mask，带 mask 会把 alpha 平方吃掉微光）。
- 入位：`images/inventoryimages/musha_advance_altar.png`（16778B）+ `art_update.py convert`（同目录默认出 tex/xml；**`--out` 会被 main() 参数剥离吞掉，勿用**）→ tex=21960B、xml 188B。
- 核验：`Element name="musha_advance_altar.tex"` = modmain L581/582（atlas/image）、`musha_dex.lua` L137 引用 → **lua 零改动**；uv 0.00390625 = 128² 半像素 ✓。
- 旧三件套备份：`exported/_tools/_art_backup/musha_advance_altar_20260925_205708/`。
- **生效需完全重启 DST**；进游戏看制作栏酒馆配方 + 图鉴图标。


## ⑯ 2026-09-25 夜：五条反馈落地（天使/荷包/星星）+ bg 新口径 v3

用户五条（原话要点）：天使太虚、荷包偏离页面、战士旁少一颗星、bg 准备换**通用一张**（技能树滚动另做，zode 在做，等通知）、当前职业[缺的东西]要按职业参考设计考虑。

### 已改（需完全重启 DST 生效）
1. **天使虚化**：`musha_panel_screen.lua` `SetTint(1,1,1,0.7)` → **0.95**。已验原图 `images/angel_new.png` 700×954 实心（46% 全不透明像素、线条干脆）→ 虚的锅全在 tint。
2. **荷包偏离页面**：`(600,-306)` → **`(475,-358)`**，三处同步：构造（L608）、`spons_hot` 热区（L849）、`musha_edit_mode.lua` ELEMENTS（x/y+desc）。
   - 几何：页面右缘 +527；旧位 48×72 旋转15° 右缘≈630（整个飘在木框外）；新位右缘≈507（余 20），底 -399 > -416。
   - 挂点 = 天使裙面正中（美术坐标 341,488；天使 390×520@(480,-352) 换算），不碰她的手（手在美术 px>500=框外区）。
   - 嫌歪/微调 → 编辑模式直接拖（ELEMENTS 已同步）。
3. **战士旁星星**：新增 `job_star`（`Text(UIFONT,30)` "★"，金 0.98/0.78/0.15）。
   - Refresh 里按标题估宽（CJK=64、ASCII=32、≥3字节按64）→ 中心 = 左缘(-110)+宽+缝30 → "战士"≈47，"战士 → 近卫"≈269（宁右勿压）。
   - 无职业 title="" 隐藏；**可见性对齐 job_text:IsVisible()**（防别的页 Refresh 漏星）；已加入 `pages.home` 表。
   - ⚠️ 若游戏里 ★ 变豆腐 → UIFONT 缺 U+2605，改走贴图星（需素材）。

### bg 新口径 v3（覆盖 ⑮ 的三档方案）
- **所有页通用一张底图**（不再分主页/技能树/其余三档）；**技能树页滚动单独做**；zode 出图，等用户通知。
- **给 zode 的硬要求（转达）**：通用底图必须**职业无关**——战士徽章 / 职业名 / "当前职业"角标 / 经验条这类**因职业而异**的东西不能烤进底图（烤死=换职业穿帮）；这些归代码层（`job_icon`/`job_text`/`job_star`/exp 条）或做成可换覆盖件。
- 已目检 `images/panel_bg.png`（12:45 外部改动版）= 黄框空页 + 任务行 + 翼水印，**无职业元素** ✓ 当前底图职业无关成立。

### 职业参考设计差距清单（待用户排优先级，本轮只补了星）
- ✅ 标题金星 —— 已补。
- ⬜ "当前职业"角标（参考稿右上粉飘带）—— 现无对应物。
- ⬜ Lv 徽标样式（参考稿是彩色描边 chip）—— 现在纯白文字。
- ⬜ 职业台词引语行（参考稿"以剑为誓…"）—— 现无。
- ⬜ 任务行进度条化（参考稿每行蓝条）—— 属任务区（用户说任务标题栏在改，另行）。

### 校验
- `lua_balance_f2.py`：panel_screen **OK**（depth/括号全 0）；edit_mode 1 处 `)` 下溢 = `jesc` 转义函数让校验器误报，**git HEAD 原版同在**（偏移仅差 8 字符），非本次改动问题。
- 荷包/星星改动全为本地文件操作，无联网。


## ⑰ 2026-09-25 夜：panel_bg_alt.png 定稿信号（核验✅）+ 任务栏底图选型 + 接线顺序结论

### 定稿信号（口径，按用户要求记档供 zode/用户核对）
- 文件：`images/panel_bg_alt.png`，**1741×1157**，**透明底**，面板内容即全图边界（含 **36px 呼吸边距**）。
- 徽章 / 称号 / Lv / 经验条 / 首行起点的对齐**按这个尺寸做**。
- **已核验**（alt_verify_g1.py）：尺寸 1741×1157 ✓；alpha bbox (36,36,1705,1121)=四边精确 36 ✓；框外全透明（角点 alpha 0）、框内实心（中心 255）✓；透明占比 18.9%（=36px 边距+圆角切角，账对得上）；纸面均亮度 237.5。

### landmark 扫描（alt_landmark_g2 / alt_rows_g3）
- 纵向色阶跳变 @ymid：外框 ≈ x61 与 x1680（左右对称 ✓）、框内边 ≈ 104/1666、导航分隔 ≈ x281、**内容框 ≈ x[317,1608]**。
- 横线：y114/207（Musha 牌/顶区）、y1102（底框）；低阈值补扫 y360–1120 仅 y1041/y1102（内容框底边/外框底边）。
- **结论：alt 没有烤任务行线** —— 内容纸是干净的。

### 接线顺序（由上条直接推出，重要）
- 现行任务行的"行底"= 老 panel_bg 里烤出来的；**alt 换上后行底会消失** →
  **alt 必须与任务栏行底图同批接线**（单换 alt = 任务区裸奔）。等任务栏图定稿后一次接完。

### 坐标换算（接线时用）
- 内容中心 native = (870.5, 578.5)（36..1705 / 36..1121 的中点）。
- `content_xy = (native_xy − 中心) × k`，k 由**展示尺寸**定：若维持 BG 1232×832 → kx=1232/1741=0.7076、ky=832/1157=0.7191（横纵差 1.6%，可忽略或改展示 1232×819 求等比）。
- 五个锚点（徽章/称号/Lv/经验条/首行起点）等设计侧按 1741×1157 给出 native 坐标后套公式；或我按 landmark（内容框 [317,1608]）+ 现役比例先出初值。PANEL_ZOOM=0.93 故事不变。

### 任务栏底图选型（用户问"三张选哪张 + 淡蓝要不要更透明"）
- 收到的是：面板参照图 + **两张淡蓝胶囊**（扁平哑光款 / 亮面高光款）；第三张若没传上来，放 `图片/` 再看。**推荐扁平哑光款**：
  1. 可展开=高度会变，扁平款中段均匀、拉伸不变形；亮面款顶部高光条/底部渐变一拉就糊；
  2. 行内文字（任务名、0/5）压均匀底色对比稳定，高光款的反光会从字下穿过；
  3. 扁平款 9-slice 友好（中段纯色，两端圆角切帽）。
- **透明度不改图、走代码**：图保持不透明，`SetTint` alpha 起手 **0.7**（一行数字、重启即调）；抢眼→0.6；底线 0.55（再低丢"可点容器"存在感）。展开/悬停可用同 knob 分级（0.8 / 0.85）。
- **硬前提**：① 即梦水印（"AI生成"角标 + "即梦AI" logo）必须干净导出，带水印不进图包；② 白底≠透明底，要 PNG alpha（以 panel_bg_alt 的 36px 透明边距为标准）。
- 候选图落盘 `图片/` 后我做体检（尺寸/水印/白底/中段均匀度）再定稿。

### 可展开（后期）要点
- 行 = 独立 widget（alt 无行线，天然支持）；固定宽 660，双态高（收起 / 展开自适应内容）；拉伸用扁平款 9-slice 或上下端盖；展开动画走高度/SetScale 过渡，行间距由 list 自动重排；热区随高度同步。
- 现行代码任务行 = 文本+进度件（行底靠 bg 烤线）→ 展开改造时给每行加 Image 底 + 排版重排。

### 待命状态
- bg 线：接线**就绪不抢跑**（等任务栏图定稿 + 用户点头 → alt+行底+五锚点一次接完 → 完全重启验收）。
- 天使/荷包/星星（⑯）等完全重启一起验。


## ⑱ 2026-09-26：黑线取证终局答复 + 换底板接线 + 去底板/荷包/赞助重排落地

### 黑线根因——终局答复（供用户回来核对；全部本地脚本取证，未联网）
**结论：导航缝里没有线。** 旧说法"主页缝透黑"是看走眼，更正。证据链：
- nav 六张 + nav_equip 留白区**任意** alpha>8 像素 = 0（nav_pad_any_p8；上一轮按颜色筛会漏亮棕，这轮不筛色）→ nav 牌画不进缝一个像素。
- 三版底图（HEAD / 12:45 / alt）缝芯 = 实心奶油 `(250,240,185,255)`，无透明窟窿、无半透明暗。
- f0/f1/f2 缝隙 run list：缝芯只有三条**竖**线 —— 左框 `[-600..-593]`、框内线 `[-565..-563]`、中缝分隔 `[-434..-431]`（全为 art）；其余暗像素 = 缝顶牌匾花饰下垂 + 内容侧（更新志文字 / 粉红装饰 / 页框左缘），nav 柱中段背景 = 实心奶油、code 未画横线。
- 全面板宽扫描（whole_width_p9，五缝高 ±6、全 x、≥40px 黑跑）：f1/f2 全 NONE，唯一例外 = f1 战士标题牌底边（-322..-199，画自带）。
- 全截图横线清单（line_inventory_pa，≥100px、全高程）里"黑"的定案：
  | 位置 | 根因 | 性质 |
  |---|---|---|
  | 面板顶黑带 cy356..416 全宽、下沿绕木牌不规则 | 底图顶部**本来就透明**（png 顶 50 行不透明占比 0→0.35、py55 起 0.98，牌+装饰只占 1/3 宽）→ 透出 self.black 0.6 压暗的世界 | 设计（牌浮出页顶）；alt 同款透明上沿（alt_top_alpha_pf 同曲线），换上后不变 |
  | 信箱页纸框黑描边 y≈295 横贯 -405..527 + 左右下边 | 代码 L1740 `FrameLines(0.15,0.10,0.06)`「深棕黑压边」5px | 代码、有意为之；嫌黑改一个颜色参数（等用户点头） |
  | 主页战士标题牌内深条 y112..128 | 标题牌美术 | 画 |
  | 面板底缘深线 cy-368..-406 | 底图美术自带（png 行 731-758 实测有） | 画 |
- 用户若指①顶黑带或②信箱页框，回来圈一下再定；不改也能用。

### 本轮已改 5 项（**需完全重启 DST** 生效）
1. **换底板接线（判决 = 映射 B 框贴合）**：modmain L112-113 注册 `panel_bg_alt` ATLAS/IMAGE（旧 panel_bg 注册保留可回滚）；panel L535-536 → `Image("images/panel_bg_alt.xml","panel_bg_alt.tex")` + `SetSize(1285.1, 887.2)`。
   - 验算：红叉 (1625,127) → (1625-870.5)×1285.1/1741=**556.9** ≈ 现役 close_btn (563,347) 的 x、(578.5-127)×887.2/1157=**346.2** ≈ 347 ✓（A 框贴合差 29px 弃）；margin (1285.1-1232)/2=26.6、(887.2-832)/2=27.7 透明外溢不可见；content/close_btn/nav/页框**零改动**。
   - xml 元素名 `panel_bg_alt.tex` 与 Image() 第二参一致（读文件核过）✓；tex/xml 21:56 已转好，本轮未再 convert。
2. **礼包/图鉴去底板**：gift card fill `alpha 0.95→0`（L3098）、dex `w.bg alpha 0.22→0`（L1919）；FrameLines 框线 / chip 全保留（"同一底色的设计"= 框线部分）。技能页卡片底不在指令范围（未动）。
3. **荷包微调**：`(475,-358)` → **`(478,-370)` 三处同步**（构造 L624、`spons_hot` 热区 L869、edit_mode L14 x/y+desc）；旋转 `15` → **`50`**（L628，按 DST 正数=逆时针下发；视觉反了改 **-20**，只此一处）。edit_mode 只管 x/y/w/h/visible、不接管 rotation。
4. **赞助面板（第四张版面）重排**：pbg `alpha 0.96→0.99`（L713，压任务字透穿撞引文）、btn1 `spons_sec 95→98`（L734）、btn2 `spons_bot -5→-19`（L791）；标题190 / 引文-170 沉底不动；认领钮在二级页未动（风险自担口径不碰）。
5. **校验**：`lua_balance_check` 三文件全 **BALANCED**；`editmode_balance_f3` HEAD/CURRENT 同深度，唯一 `)` 下溢 = jesc 误报（HEAD 同在，非本次改动）。

### 换 alt 的可见后果（已授权、属预期，记档防忘）
- 老 panel_bg 里烤的**任务行行底会消失**（alt 干净无行线；现行任务行 = 文本+进度件，行底全靠烤线）→ 等任务栏底图（推荐扁平哑光款、`SetTint` alpha 起手 0.7）落盘 `图片/` 后补行底。alt 先行是用户授权的，行底缺位不是 bug。
- 五锚点（徽章/称号/Lv/经验条/首行起点）为代码内容坐标；映射 B 下 alt 框≈旧框 → 不用改；重启后若视觉有偏，按上面 B 验算式微调。

### 排任务（等用户排期）
- **技能书 vs hermes**：图已目检 —— 黑 tooltip 条、右侧白缝、布局稀疏、占位图标；参照 hermes 重排（参照程度/优先级等拍板）。
- 信箱页框黑边要不要软化（L1740 颜色，一行）。
- git 提交/推送、AGENTS.md 刷新、0.7.10 changelog 口径、10:31 产物去留、图片/35 张源图入仓等一串沿以前各节，仍等拍板。

### 验收清单（用户回来）
- **完全重启 DST**（tex 变了）→ 面板：新底板上屏（红叉仍能点关）、礼包/图鉴无底板只剩框线、荷包 (478,-370) 斜 50（反向改 -20）、赞助面板两钮均布且底不透字。
- 顶黑带 / 信箱页框黑边看不顺眼就圈位置。

## ⑲ 2026-09-26：月牙斩按官方写法重做八个面（命名方向根因实测 + 工程归位 + 成对切换）

### 用户指令（原文）
「动画命名方向是错的 你要按官方的写法来做八个面，或者看看应该怎么导入——按软件工程的方式正常导入 才能使用。 否则就得做SG 发出去飞的是怎么做的了。」

### 根因（实测闭环，非猜测）：错的是**图的指向**，不是引擎
- 测量工具：`exported/_tools/crescent_reorient.py`（PCA 主轴 + 前后判别，flight = 弦向-90°；先在临时副本标定旋转符号约定，再施转，复测 ≤2° 才算过）
- 旧 8 张图对官方 nominal 标签的偏差（实测）：
  | dir | 官方名 | 旧飞行指向 | nominal | 偏差 |
  |---|---|---|---|---|
  | 0 | downright | 53.4° | 45 | +8.4 |
  | 1 | down | 132.7° | 90 | **+42.7** |
  | 2 | downleft | 171.4° | 135 | **+36.4** |
  | 3 | left | 194.8° | 180 | +14.8 |
  | 4 | upleft | 233.4° | 225 | +8.4 |
  | 5 | up | 312.7° | 270 | **+42.7** |
  | 6 | upright | 351.4° | 315 | **+36.4** |
  | 7 | right | 14.8° | 0 | +14.8 |
- 机理：生成器按**世界格中心** 45k+22.5° 经 `K_SCREEN=0.5` 压扁投影 → 屏幕指向间隔 79.3/38.7/23.4/38.7° **不均匀**；图与生成器意图自洽（差恒 +93° = 弦向口径 + 约3°"上窄下宽"倾斜）→ 根子在"世界格中心"这套口径本身。
- 推论：① **裸改名修不了**（left/right 各抢两张、down/up 无人指 = 撞名）→ 必须重定图的指向；② 09-16「引擎挑面失败」的证据被这张错图污染，不能据此怪引擎；③ 再跑 `crescent_gen.py` 会按旧口径把指向打回去 → 重跑后必须补过 `crescent_reorient.py`。

### 落地（全本地可验证、未联网）
1. **工程归位**（= 用户要的"按软件工程方式正常导入"）：桌面 `光斩素材_第4版_20260916` → `exported/crescent_moon/`
   - 主工程 `crescent_cyan8.scml` = **官方后缀名版**；点名版 → `_bak_scml_点名声_20260926.scml`；原 8 图 → `_bak_dirs_原版_20260926/`
2. **重定指向**：`python exported/_tools/crescent_reorient.py` → 8 张全部转到 nominal（45/90/…/315/0），闭环复测 **0.0° 全过** + 对照图目检（8 格凸面全与箭头同向）
3. **官方编译**（CLI 不开 GUI）：工程目录下 `mod_tools/scml.exe crescent_cyan8.scml .` → `anim/crescent_cyan8.zip`（989,945 B）
4. **包内自检 PASS**：anim.bin 8 条 `slash` 掩码 = `[64,8,128,4,32,2,16,1]`，**与 scml 动画顺序逐条吻合**（slash_downright→file0 … slash_right→file7）；8 个后缀名字符串在；对照现役包 = `slash_dir0..7`
5. **成对切换**（铁律：常量与 zip 必须成对）：fx `USE_ENGINE_FACING = true`（现 **L143**，`FACING_DEBUG` 仍 true）+ 换包 md5 `D8AAF5F21E02FBEC296FEAB847BABC91`；旧点名包备份 `anim/_bak_crescent_cyan8_点名_20260926.zip`
   - 顺手修一处引擎模式隐患：消散粒子 `PlayAnimation(ART.fly)` → `USE_ENGINE_FACING and FACING_ANIM or ART.fly`（否则粒子点名失败 = 空白）
6. **Lua 校验**：WSL luac5.1 → **74 个文件全部通过**

### 用户验收 + 校准（FACING_DEBUG=true 已开）
- **完全重启 DST** → 放月牙斩 2~3 个已知方向（上 / 右下 / 左…）：**月牙凸面应与飞行方向一致**
- 日志会打旋转角；若整体偏 45° 整数倍或呈镜像 → 只**对调 scml 里 `slash_*` 的名字**后重编（一条命令），**别动 Transform 旋转**（旋转=飞行方向，MotorVel 沿自身旋转飞）
- 看不到月牙 = 配对被拆 → 按回退套件处理
- **回退（必须成对）**：`USE_ENGINE_FACING=false` + `_bak_crescent_cyan8_点名_20260926.zip` 拷回；点名版要连图一起回旧口径 → `_bak_dirs_原版_20260926/` 拷回再重编

### "否则就得做 SG" 的答复
- **不用做 SG**：飞行链已是原版口径 —— projectile 组件 + `RotateToTarget`（旋转即方向，铁律第 7 条）+ `SetMotorVel`，这套在跑；官方挑面只接管"贴图按旋转选面"这一层，两层互不干涉。

## ⑳ 2026-09-26 断电恢复：星图/mobius 收尾 + 标靶盘点 + 新 bug 两条（导出动画进行中）

### 断电后重跑（用户：「重新跑一下你的工作」）
- `.mobius/project_knowledge.md` **头部横幅已加**（用户拍板「1」，结构标题未删）：实证 = 09-13 生成、09-24 16:49 重跑**仅改 1 行**（面板入口 B 键移除），其余冻结在 0.7.6
- 星图同步：对比实录 1 按 git 实证改准、doc.mobius note 更新；校验 **68/68 全绿**
- 更正前一轮口误：文件里**没有 `_generated_at` 时间戳行**（当时乱码输出骗的）——「假新鲜时间戳」不成立；真相 = 09-24 重跑过但正文没跟上版本/任务

### 标靶盘点（用户：「里面标靶还有什么」→ 逐条实测）
- **已实现**：图鉴页（`scripts/musha_dex.lua` 在，且核心模块行自己写 5 页含图鉴 = 自相矛盾）／信箱页 P2／TRACE 清理（09-17 33 处改走 `TRACE()` 开关）／每日任务默认 4（`musha_world_settings.lua:16`）／技能页（在 5 页内）／`TEST_DAILY_COUNT=nil`（quest L138 实测）／4+6 职业、`DAILY_MAX=10` 均在
- **仍开放**：P0 验证（= ⑱⑲ 等你重启验收）／任务扩编 13→30（未核数）／刷怪器 P4（全仓实测无 `musha_spawner`）／`musha_skill_data.lua:91` TODO／README-与-modinfo 不同步（= 星图对比 3/4，已拍板下版一并修）／等级经验校正（暂缓）／changelog 来源／美术清单（待画师）／周边统一
- **过期口径**：版本行 0.7.6（实际 0.7.10）／「ja 计划中」（`speech_musha_jp.lua` 已存在）

### 新 bug（用户 09-26 报告，原话）
1. 「转职后 面板没更新 没变」——**09-26 已定位并修**：刷新链全通实测（UseAdvanceCrest `musha_profession_component.lua:1397` PushSettings→replica DoUpdata→`gamedata_dirty`→面板 `_on_dirty`→Refresh，标题/五子页都刷；`advance_quest` 在完成时 `musha_quest.lua:442` 已清不背锅）。**唯一卡旧态 = 职业头像**：`musha_panel_screen.lua` 09-22 拍板"二转后头像不变"按 `carrer_base` 取图 → 转完剑士徽章还是"战士"，用户 09-26 实测推翻该口径。修法（最小 diff）：L2432 改 `JOB_TEX[md.carrer_special] or JOB_TEX[md.carrer_base]`（special 空/没有自动退回基础）；L105 `DIRTY_EVENTS` 补 `musha_job_changed`（职业落地直达刷新，不再单押 gamedata_dirty）。备份 `screens/musha_panel_screen_20260926.bak`（168840B 与改前一致）；WSL luac **74 全过**。**待重启 DST 验收**（转职后看徽章换图）
2. 「左边斩出去 反的」——⑲ 预案正中：若确为镜像 → **只对调 scml 里 `slash_*` 的名字**后重编（别动 Transform 旋转）

### 导出动画（用户：「你需要导出动画让我看看」）
- 新工具 `exported/_tools/dump_facings.py`（伴生、不改 dump_anim_frames：8 面裸名都是 `slash`、朝向存在 facing 字节里，原工具点不了第 N 面）
- shipped 包 md5 `D8AAF5F21E02FBEC296FEAB847BABC91` ✓；f 序号↔官方名按 ⑲ 出厂记录 = f0=downright … f3=left … f7=right
- 渲染完成（断点续渲：f0/f1 跳过、图集跨面缓存）→ 8 面全出；**对照表实证：渲染 == 源图逐面全吻合、无翻转，左面 f3 凸面朝左 ✓ —— 素材层没错，左斩"反的"症结在引擎挑面层（⑲ 预案：FACING_DEBUG 日志 → 对调 scml slash_* 名字重编）**

## ㉑ 2026-09-26 贴叉叉 + 删旧 panel_bg + tex 重打（用户四点指示）

### 1. 贴叉（「把叉叉贴上去，叉叉已经可用了」= `images/close_button_red.png` 916x926 白底，09-21 就在）
- 工具 `exported/_tools/make_close_x_20260926.py`（可复现）：白洪泛抠底（边沿灌，X 白笔画被红圈包住不可达）→ `_tmp/close_x.png` 253x256；金星实测 = HSV 掩码 + **连通域岛链**（星=深棕描边包住的岛，框带触窗边全弃；左右臂被饱和度谷切断 → bbox 间隙≤16px 归并）→ 星 bbox **x1373..1451 y61..109**
- 定位 = 覆盖搜索（圆须罩整星+3px 描边，搜"圆顶高出星顶 extra"×最小 D）→ **圆心 (1412,98) D=94**（extra=7）；QC 目检过：金星零外露、抠图无白边、白 X 笔画完好
- 入库走 `art_update.py publish` → `images/close_x.{png,tex,xml}`（tex 87.5KB）+ 贴叉版 `panel_bg_alt.png`（旧三件自动备份 `_art_backup/panel_bg_alt_20260926_060807`）
- **双层设计**：底图烤叉（可见 + ChatGPT ui_preview 预览可见）+ 控件层叠同一张 close_x（各边 +4 content 盖死烤叉 → 不会双 X）→ 悬停 1.0↔1.24 缩放才有视觉（贴死在底图上的叉动不了）

### 2. tex 陈旧实锤与重打（⑱ 黑线没过的根子）
- `art_update.py status`：**panel_bg_alt STALE**（27 新 1 旧）；旧 xml UV 反推 = 4096x2048 装 **1741x1157 旧图 2 倍** → 游戏一直跑旧底图
- publish 重打后新 UV u2=0.7498×2048=1535.5 ✓ = **1536 新图**；status 复查 **29 全新 0 STALE 0 MISSING**

### 3. 旧 panel_bg 删除（「panel_bg 旧版本 去掉」）
- 备份 `_art_backup/panel_bg_old_20260926/`（png+xml+tex）→ 删 `images/panel_bg.{png,xml,tex}`
- `modmain.lua` L108-109 注册同步删（不删=缺资产报错）、L111 注释改口；close_x 两行注册插在 alt 后
- `modmain.lua` L121 `close_button_red` 预载**没动**（无代码引用，别人接的线）；UI_ELEMENTS 照旧

### 4. 关闭按钮接线（⚠️ 三处同步全做了）
- `musha_panel_screen.lua:572` 换 `ImageButton("images/close_x.xml","close_x.tex")`；ForceImageSize 80x80→**81.8x85.4**、SetPosition (563,347)→**(538.8,358.7)**、alpha 0/0.12→**1/1**；新增 `TweenCloseScale`（0.12s 8 步线性：GainFocus 1.0→1.24、LoseFocus 回落、OnClick 先 Cancel 再 PopScreen）——house L366 悬停缩放同款 API（SetOnGainFocus 本文件 6 处在用）
- `musha_edit_mode.lua:9` ELEMENTS.close_btn 同步 x/y/w/h + desc（防 apply_to_panel 构造后盖回）
- `星图集成.md` res.images note 改口（旧 panel_bg 已删 → 换图走 publish 管线）

### 5. 校验与验收
- 备份 `.20260926b.bak` 三份（panel_screen / edit_mode / modmain）；WSL luac5.1 → **74 全过**
- **待完全重启 DST 验收**：①右上红叉在（金星已被替换）②悬停放大 1.24 移开回落 ③点叉关面板 ④黑边/黑线随新 tex 生效（连带⑱两项）⑤EditMode 拖关闭标记跟新坐标

## ㉒ 2026-09-26 导航横幅重切（中英 12 张，用户「重切 那边图片切坏了 chatgpt用不了」）

### 1. 病根与范围
- 病根：旧切法按**固定 2列3行格子**切，横幅比格子大 → zh `nav_mail/set/gift/dex` 顶部混入**邻格碎屑**、两侧切损（`images/nav_*.png` 09-22 产物实锤）；en 同法更重（旧 h_ratio 0.602-0.867 = mail/set 带邻居碎片）
- 源：`图片/UI_zh.png`、`图片/UI_en.png`（均 1659×948；zh 白底+局部透明混合、en 纯透明）
- **只动像素层**：Lua/热区/edit_mode 零改动（按钮 200×100、NAV_GAP2=-8.4、2:1 口径全不变）

### 2. 新切法（工具 `exported/_tools/slice_nav_20260926.py`，analyze|cut|install × zh|en 可复现）
- ① mask=(alpha>16)&~白（白底实为透明 alpha=0，白件靠描边不丢）② **scipy 连通岛→质心落六宫格**（整兔一岛、跨谷耳尖按质心归本排；行谷 zh 373/644、en 366/635，列谷 zh 861.5、en 828.5，比例窗自适应）③ 联合包围盒**按岛 ID 剔异岛像素**（上下排 bbox 重叠 8~14px，zh 每格都中招 202~561px，不剔=带下排耳尖）→ contain 进 512×256（pad4、H_CAP 0.80、居中）
- 账：zh h_ratio 0.684-0.801（旧 0.711-0.773）→ 视觉缝 12.7-20.3px（设计 18、旧 14.5-20.1 同量级）；en 新 0.668-0.746（旧 0.602-0.867，反而更匀）
- QC：源图红框覆盖图 + QC 联络表各 2（`_tmp/nav_zh_20260926/qc_*`、`_tmp/nav_en_20260926/qc_*`）；岛清单 = 每宫一主岛 13.6~15.2 万 px + 零星星（全在主框内）→ 目检六格全幅完整零碎屑

### 3. 装车与 publish
- 备份：`_art_backup/nav_zh_old_20260926/`、`_art_backup/nav_en_old_20260926/`（各 6 张旧图）
- 覆盖：zh 17:34-17:37、en 18:21 → `art_update.py publish` **12 张 tex 全重打**；status 复查 **28 up-to-date 0 STALE 0 MISSING**
- **待完全重启 DST 验收**：导航六钮（中/英随语言）无碎屑无缺角、悬停/点击照旧

## ㉓ 2026-09-26 夜：09-26 崩溃修复 + 叉号 B 案 + 经验条装饰框化 + 导航靠左 + 崩溃桥（E2E 全绿）

### 1. 崩溃修复与荷包微调（行号为当前实测值）
- `musha_panel_screen.lua:559` `btn:IsValid()` → `btn.inst == nil or not btn.inst:IsValid()`；`:569` `btn:DoTaskInTime` → `btn.inst:DoTaskInTime`（ImageButton 本体无 IsValid/DoTaskInTime，父体回收后点叉即炸 = 09-26 L555 崩溃栈根因）；备份 `.20260926c.bak`
- 荷包 478,-370 → **482,-373** 三处一致：panel `:664`（purse）、`:909`（赞助热区同位）、`musha_edit_mode.lua:14`

### 2. 叉号 B 案（根因定案 + 落盘）
- 根因二合一：盘心 (1412,98) **锚星顶**比星 bbox 中心 (1412,85) 低 13px + 源图标 X 字形自带 +16px/916 图下偏（缩放后 +5px/253 图）
- `make_close_x_20260926.py` 三处改造：①底改读干净备份 `_art_backup/panel_bg_alt_20260926_060807/` ②字形上移 5px（坑：白 X 是红盘的洞，须 `binary_fill_holes` 再取 mask 否则清空）③放置 B 案：星 bbox 中心 + D=94 罩不住才 +2
- 重跑实测：close_x 盘/X 双心 (126,126) **off=(0,0)**；烤 extent x1366..1458 y38..131 **c=(1412,84.5)**；星区 uncovered=0；content **(538.8,370.0)** 与换算闭合
- publish：`close_x`、`panel_bg_alt` 双 tex 重打（旧 atlas 自动备份 `_art_backup/*_20260926_203725 / _203728`）
- Lua：panel `:578` SetPosition (538.8,358.7)→**(538.8,370.0)**（ForceImageSize 81.8×85.4 不变）+ `:541-548` 注释改 (1412,85)/(538.8,370.0)；edit_mode `:9` y=358.7→**370.0** + desc 同步
- QC 待用户目检：`Temp/opencode/qc_new_glyph.png`、`qc_new_baked.png`（十字线重合、跨框对称、无重影无补丁痕）

### 3. 经验条装饰框化（图片/进度条.png → images/exp_frame）
- 精测：2056×765、alpha 内容框 2031×523；暗槽用灰绿规（lum 40..100 且 R−G<10）取最大连通域 = **x385..1810 y346..451**（1426×106、fill 0.88 圆角），直线段 y373..426、安全 fill 区 x412..1788 y376..422（旧粗测 x59..2011 是整圈描边连通污染 → 作废）
- 设计（**邻居全不动**）：框 **295×76 @(−55,115)**（x −202.5..92.5 < 分隔线 99.5 ✓；y 77..153 = list 顶 74 / Lv 字 157 / 横幅隐藏态 75 三让）；槽显示 207×15.3、槽心 **(−45,115)**；fill 最大 **199.9×10、左缘 −144.5**；text 26 不变 @槽心
- 落盘：裁图 `_tmp/exp_frame.png` → publish 重打；modmain `:116-117` 注册 ATLAS/IMAGE；panel `:957-959` 创建块（Image exp_frame / 295×76 / −55,115）、`:2407`/`:2412` 灰罩 → (1,1,1,1)/(1,1,1,0.5) 保色降透、`:2488-2489` fill 几何、`:2491` → (1,1,1,0.45)；QC `Temp/opencode/expframe_design.png`
- art status：**29 up-to-date 0 STALE 0 MISSING**

### 4. 导航靠左（按导航实施，报告写明可回退）
- panel `:2210` nav_list x **−500 → −510**（仅 NAV_LEFT 分支；W=200 → 左缘 −610 > −616 余 6、右缘 −410 更让开任务行）
- 放大不建议的账：纵向可用 583、现盒 100 用 558、极限 ≈104（+4%）；×1.2(=120) 末底 −382 砸穿花丛 −277（09-24 回调同因）；可见占比均值 0.743 已 > 旧 0.736

### 5. 崩溃桥（本轮新功能，mod 侧+agent 侧全落地、E2E 实测全绿）
- 新文件：`scripts/musha_crash_bridge.lua`（纯 Lua SHA256/HMAC，用 DST 的 bit 库）+ `crash_bridge/watcher.ps1`（.NET HMACSHA256、1s 轮询）+ `crash_bridge/start_watcher.cmd`；modmain `:1304` 起接线（require + start(MODROOT) + install_hooks，全 pcall）
- 门禁：Lua 沙箱验不了 OS/Steam 证书 → **SteamID64 派生 key 的挑战-应答**：`key=SHA256_HEX("musha-crash-bridge/v1|76561198220617051")`（启动探 loginusers.vdf、失败退常数）；应答 = `HMAC_SHA256(ASCII(key), nonce)`；nonce **30s 滚动**留 [当前,上一个] 双格 → 过期/重放拒；**令牌不落盘**（盘上仅临时 challenge/应答）
- 挂接：`_G.DisplayError` 包装（mainfunctions.lua:1586，按决定）+ `_G.ScriptErrorWidget` 构造兜底（gamelogic:58 / frontend:1640 / mods.lua:653 的 SetGlobalErrorWidget 漏斗全收）；同错误文本去重只发一份
- 文件流：mod 写 `challenge.txt` → watcher 答 `agent_response.txt`（tmp+rename 防半写）→ 崩溃验过才写 `out_*.txt` → watcher 挪 `crash_inbox\`；`status.txt` / `last_event.txt` / `watcher.log` 诊断
- 测试：WSL lua5.1 **6 向量全 PASS**（sha256 空/abc/448/896 + HMAC RFC4231 #1#2）；端到端 = 真 watcher `handshake=ok` → `released outbox=…` → `outbox_left=0 inbox_count=1`；**两侧 key_fp 一致 = 1769f45d5e21871c**
- watcher 本会话已后台运行；重启电脑后双击 `crash_bridge/start_watcher.cmd` 再拉起

### 6. 校验与验收状态
- luac：**75 全过**（原 74 + 新模块）；art status 29 up-to-date
- **待完全重启 DST 一次验收**：㉑+㉒ 八项、崩溃修复、荷包 482,-373、叉号 B 案、经验条新框、导航 −510；崩溃桥进游戏后看 client_log 出现 `[musha-crash-bridge] ready … key_fp=1769f45d5e21871c` 即握手侧就绪
- git 仍未提交（HEAD=45eff68，未提交面持续扩大）；联网仍全停；月牙斩左斩等 FACING_DEBUG 日志

## ㉔ 2026-09-26 深夜：加点天使修复 + 荷包/进度条二调 + 转职称谓 + 崩溃桥真机修（用户「先修musha 修完马上更新」）

### 1. ★ 加点时天使冒面板（根因定案 + 修）
- **根因**：`job_warrior.png` 本体就是**带光环的天使女孩**（职业头像）；`Refresh()` 里
  `job_icon:Show()`/`job_star:Show()`/`quest_empty·quest_hint:Show()` 是**无条件**的
  （约 :2449/:2470/:2524-2525 区）→ 加点=服务端推数据=`_on_dirty`→`Refresh()`
  → 主页元素被从页面组里捞回来盖到技能页上（pages.home 整组都可能被这样露出来）
- **修**：`musha_panel_screen.lua` Refresh **收尾**（约 :2551-2557）按当前页重新收口：
  `active_page ~= "home"` → 把 `pages.home` 整组 Hide + 补一次 `RefreshHomeDecor()`
- 真机日志佐证：01:05:35 开面板 → 01:05:40 五连 FROMNUM 告警（=数据推送那刻）

### 2. 荷包二调 / 进度条二调 / 转职称谓（本轮点名五件）
- 荷包：`panel:664` y **-373 → -376**（下移3）；`panel:668` rotation **+50 → -60**（倒转60°）；
  热区 `panel:909` 同位 -376；`edit_mode:14` ELEMENTS 同步（x=482 y=-376 + desc）
- 进度条（拉长40% + 右移180）：框 `panel:963-964` **295×76@(-55,115) → 413×76@(125,115)**；
  槽心 **-45 → 139**（`exp_text:974`）；fill `panel:968` 初值 **-144.5 → -0.3**、
  `panel:2494-2495` 动态 **199.9→279.9 / -144.5+99.95·pct → -0.3+139.95·pct**；
  账：图整体横向 ×1.4 → 框内特征按中心等比（槽心偏移 +10→+14）；x -81.5..331.5、y 77..153 不变
  ⚠️ 分隔线 y=82 会被新框横穿（x99.5..331.5 段），等用户看图拍板要不要让
- 转职称谓「不要写战士 → 剑士 转职后直接写剑士」**三处**同改：
  `panel:2433`（主页标题）、`panel:2693`（技能页头）、`panel:3068-3071`（装备页 Row10 职业）

### 3. 崩溃桥真机挂了（client_log 实锤）+ 修
- 日志 01:02:21：`[musha-crash-bridge] start error … musha_crash_bridge.lua:90 attempt to call upvalue 'ror'`
- 根因：**DST 的 bit 库没有 ror**（全库 grep：47×band/33×bor/25×lshift/11×rshift、0×ror/rol）；
  WSL 测试垫片提供了 ror → 把洞掩盖了（E2E 全绿是假绿）
- 修：`musha_crash_bridge.lua:31-43` ror 缺席时用 `bxor(rshift(x,n), lshift(x,32-n))` 现搭
- 回归：新写 `Temp/opencode/bridge_test_nor.lua`（垫片**不给** ror = 真机同款）→
  6 向量全 PASS、**KEY_FP 仍 1769f45d5e21871c**

### 4. 顺手修：shu mod 存档崩溃（用户贴的日志，非 musha）
- `mods/shu/scripts/components/furaodipi_manager.lua:155` `data` nil：
  引擎 `entityscript.lua:1908` 是 `v:OnSave()` **无参 + 要返回表** → 原实现接参且不返回
  → 每次存档必炸，且地块数据**从来没存进去过**
- 修：`OnSave()` 无参、建 local data、`pairs(self.tiles or {})`、**return data**；备份 `.20260926a.bak`；luac -p 过

### 5. 校验与状态
- 备份三份 `.20260926d.bak`（panel / edit_mode / crash_bridge）+ shu 一份 `.20260926a.bak`
- WSL luac5.1：**75 全部通过**（含本轮全部改动）；shu 单文件 luac -p 过
- 本轮**纯 Lua 改动**（tex/图零改动）→ 用户按需完全重启 DST 验收：
  ①加点天使不再冒 ②荷包朝向/位置 ③进度条新长度位置 ④三处职业名直接写剑士
  ⑤client_log 应见 `[musha-crash-bridge] ready … key_fp=1769f45d5e21871c`（桥首次真正挂上）
- 未做（下一轮，等用户排队）：星图「爱丽丝计划」、小赫工作台任务核查、绘画AI推荐、
  美术工具代码门禁/代码管理、其他页位置重置、v2 皮隐藏打包
- 中间插曲：WSL 服务两次起不来（E_UNEXPECTED→RPC_S_CALL_FAILED→重启 vmcompute/hns 后恢复）

## ㉕ 2026-09-27：星图核对任务 + 爱丽丝计划入图（用户「星图里检阅是否核对任务」）

### 1. 全图核对（实测，非目测）
- `星图集成.md` JSON 块 `json.loads` 通过；**71 星、70 个 path 全部实测存在**（col.zcode 无 path 属设计）、无重 id
- mod 根目录 **20 份 MD 全部进图**（唯二除外：星图自身=图本身、无需自指）

### 2. 本次入图 / 刷新（改前全文重读，逐处断言唯一）
- 新增 `doc.new-features` → `musha-新功能构想_20260926.md`（9 项构想+拆件+swap_body 14 帧对照）
- 新增 `plan.alice` → 爱丽丝计划（=新功能构想 §9；已告知 zcode；两条路线未拍板；
  **星图侧已收录、工作台侧未整合**——TaskStarMap 接入归工作台侧、接不接用户拍板，已在 §六 记整合状态行）
- 新增 `sys.crash-bridge` → `scripts/musha_crash_bridge.lua`（09-26 ror 修、key_fp、验收口径）
- note 刷新：`doc.state` → ㉔ 在尾部；`tool.lua-check` → 期望 **75** 全过（含 §四.7）；
  `sys.panel` → ㉔ 五件待验收；`verified_on` → 2026-09-27（frontmatter+json 双处）

### 3. 给 Hermes 的「哪些 MD 不属实」答复（用户转达）——以星图 §四 为准
1. `.mobius/project_knowledge.md` = **stale**（v0.7.6 vs 实际 0.7.10，近期任务大半已实现）→ 改信 `musha-current-state.md`（§四.1，09-26 已加头部横幅）
2. `D:/Backup/Documents/Default Project/README.md` §2 过期（「EXE 待开发」→ `dsmod-packaging-tool` 已是完整工程）；§1 仍有效（§四.4）
3. `AGENTS.md` 六处失准（L4/L85 死链、L28/L66 工具路径、L69/L77 幽灵脚本）**09-26 已修净现属实**——但路径/校验命令以星图表为准（§四.2/6/7/8）
4. `modinfo.lua`（非 md）L1 name 0.7.9 vs L4 version 0.7.10，下版一次性全修（§四.3）
5. 技能三副本（非不属实、是漂移风险）：改一处必须同步其余（§四.5）
- 09-27 复核：除上述已知项，其余在图文档 path 全在、无新增失实项
  ⚠️ Hermes 会话里 `search_files` 搜不到 `musha-current-state.md`（其检索 cwd 不在 mod 目录）——**必须给绝对路径**：
  `D:/SteamLibrary/steamapps/common/Don't Starve Together/mods/musha/musha-current-state.md`

### 4. 小赫工作台任务核查（09-27 实测 `%APPDATA%\app`）
- 工作台运行时目录 = `%APPDATA%\app`（`name=app`）；`agent-endpoint.txt=127.0.0.1:8642` ✓；inbox 空、auto-dispatch 关
- `workspace-store.json` → `local-sessions` 共 **4 会话**（3 空 + 1 个 37 条消息的主会话，09-26 22:10 更新）
- 主会话里**已完整收到用户 09-26 大任务单**（人格功能/自动收集报告/爱丽丝计划/绘画AI/v2 皮/天使皮/页面位置/美术工具门禁）✓ 任务已到 hermes 手
- hermes 回复卡在两点：①读不到聊天图片路径 ②在等用户排优先级；另其源码主线/绑定档案 = `D:\exclusive-for-hermes-gitee`（repo-bind.json projectDir）——与星图 col.workbench 记的 master 目录**不是同一份**，更新/改码认 gitee 那份
- TaskStarMap（会话星）与本图 JSON 的接入仍未做（§六，归工作台侧、用户拍板）

## ㉖ 任务栏批次一（09-27 04:3x 落地，待完全重启验收）
- **用户拍板（本批口径）**：任务栏=面板主页任务列表区换底（粉书 musha_skillbook、透明0.6、周围深蓝实线）；行右端小三角 静止◀、点开向下插详情子行；详情=需要什么+奖励；猎犬=任务需求里显示；抽奖=1池120件不放回、抽空重置、3星/抽、面板新页；蔬菜组=随机一种 20个+40专属种子（只可种不可食）；星星=任务奖励、右键+3~7职业经验
- **落地十处**：panel_screen —— `QLIST_X/Y=122,-160` 常量（底图/框/列表共用）、`quest_bg` 粉书 ForceImageSize+SetTint(1,1,1,0.6)、`quest_bg_frame`=FrameLines 深蓝(0.10,0.18,0.35,1) 4px、行 ctor 加 `clicker`整行热区+`caret`◀▼(UIFONT字形)、`req/rwd` 详情文字、`hound`=UIAnim(bank=hound, build=hound_red, idle, scale0.45)、apply_fn 详情分支（深蓝淡底+藏三角）、`BuildQuestItems()`（展开插 detail 行，Refresh/点三角共用）、pages.home 收编 bg/frame；musha_quest —— SyncToPanel 日常/转职各加 `ty`+`exp`（json 通用通道）
- 语法 **76 文件全过（04:33）**；76=75+新建 `musha_rabbitbackpack.lua`（另一路 agent 03:03-03:19 动过 modmain/mail/languages/containers 与本批不冲突）
- **验收点**：底图放大糊不糊、◀▼字形（变方框→回退"<"/"v"）、猎犬大小/位置（scale 0.45 可调）、深蓝色值可调
- 未动（后续批次）：抽奖页 UI、星星 prefab、蔬菜/专属种子、任务奖励物品字段（随星星一起）
