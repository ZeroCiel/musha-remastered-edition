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
| ★ **职业系统设定原文**（转职流程/四职业/六分支：剑士·近卫·药剂师·元素法师·吟游诗人·月影猎手） | `.mobius/skills/dst-modding/references/musha_jobsystem.md` |
| 武器技能 v1~v11 全过程 | `musha-weapon-skill-plan.md` |
| 右键点地技能两条路线 + 硬要求 | `musha-rightclick-spec.md` |
| 天数奖励（未做） | `musha-dayrewards-plan.md` |
| 装备/属性面板设计 | `musha-design-equip-panel.md` |
| 可移动携带建筑（生命树枝升级用） | `references/portable-structure-notes.md` |
| 方向图生成（8 面 + 投影补偿） | 技能 `dst-modding` → `references/directional-art-projection-compensation.md` |

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
