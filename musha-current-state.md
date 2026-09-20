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
- 方向图生成：`python exported/crescent_cyan/make_dirs.py`（纯标准库，约 30 秒；Windows 侧无 PIL）
- 角色造型换衣（中式素布衣）：`python exported/_tools/cn_cloth.py [--apply 1..5|--revert]` ← **首选**
  旧稿：`draw_cloth.py`（布纹重画）/ `gray_cloth.py`（纯去色）
  （纯标准库；配套 `exported/_tools/{pnglib,ascii_view,palette_scan}.py` —— 没视觉模型时用 ascii_view 看图）
- **发布前素材自检**：`python exported/_tools/check_assets.py`
  （扫全项目 `Asset("类型","路径")`，报"声明了但文件不存在"的项 —— 这类缺失会让 RegisterPrefabs 阶段 assert，
   整个 mod 被禁；2026-09-14 生命树枝、2026-09-16 便签各踩过一次）
- **打包**：`D:\饥荒开发\tool\DST Mod Tool.exe`（GUI；tex 和 anim 都只能走它）
- **皮肤模板（build 源 → Spriter 工程 + 参考图）**：`python exported/_tools/make_skin_template.py <源目录> <输出目录> <名字> [--from-scml 现有工程.scml]`
  · 只转换：`python exported/_tools/buildxml_to_scml.py <源目录> <输出目录>`
  · 拼装预览：`python exported/_tools/musha_scml_render.py <x.scml> <out.png> --keys 0,5,20 --scale 0.5`
  · 命令行编译：`"<DST Mod Tools>/mod_tools/scml.exe" <工程>/<名>.scml <出参目录>` → `<出参>/anim/<名>.zip`
- 原版写法定要看**当前版本**：`unzip -o -q data/databundles/scripts.zip "scripts/xxx.lua" -d /tmp/gd`
  （`data/databundles/scripts/` 那个旧解包目录行号对不上）

## 🗂 Gitee（用户旧账号 ZeroCiel，卡在只读部署公钥）
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
