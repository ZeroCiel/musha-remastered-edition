# Musha 短卡（2026-09-14）—— 新会话只读这张，**别整读 musha-log-2026-09.md**

> 用法：开工先扫「队列」→ 按「命令」跑校验 → 需要历史/踩坑细节再 `grep` 档案（`musha-log-2026-09.md`）。
> 维护规则：新内容写这张；被替换掉的老条目搬进档案，别删。

## 项目
`D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha`（作者的 DST mod，作者 Ciel/雪儿）
面板 = Screen + ScrollingGrid，导航 7 页：主页 / 技能 / 装备 / 信箱 / 设置 / 礼包 / 图鉴

## 📌 队列（2026-09-14 收工状态）
1. **【等你 GUI】月牙方向图**：`exported/crescent_cyan/dirs/crescent_cyan8.scml`
   → DST Mod Tool 导出 → `anim/crescent_cyan8.zip` → 然后把 `musha_slash_qi_fx.lua` 顶部
   `FX_ART` 由 `"cyan"` 改成 **`"cyan8"`**（一行；ART 表、FX_DIRS、modmain 条件登记都已接好）
   校准：`PHASE_DEG`（整体偏角）/ `K`（压扁程度，默认 0.5）/ `DIR_CCW`（顺序反了取反）
2. 【进游戏实测】剑气斩全链路：右键第一下进瞄准圈 → 点地出「剑气斩」→ 抬手(atk_pre→atk) →
   月牙直线飞（速度 22.5）→ 命中掉血 + 炸开 + 12 粒子 → 冷却 6 秒（rechargeable）
   ★ 冷却期**右键完全没反应、不弹字**；月牙朝向应沿飞行方向
3. 【进游戏实测】能量球（挂在三围旁）；祭坛自定义模型（USE_CUSTOM_MODEL 已开）；生命树枝手持/图标
4. 【缺素材】`images/inventoryimages/musha_lifebranch.{tex,xml}`（图标没打，现在走"无图标"分支不崩）
5. 【未做·等定】天数奖励系统；生命树枝升级机制（样板 portablefirepit + portablestructure）
6. 【暂不开放】武器技能「4 选 2」选择 UI（用户 2026-09-14：看后期）

## 🔧 命令（每次改完必跑）
- 语法校验：`wsl -d Ubuntu2204 -e bash -lc 'bash /mnt/d/wsl-dl/lua-syntax-check.sh'`（期望「检查 N 个文件：全部通过」）
  · `luac5.1` 只在 WSL 里，Windows 侧找不到，别去 C:/D: 盘 find
- 方向图生成：`python exported/crescent_cyan/make_dirs.py`（纯标准库，约 30 秒；Windows 侧无 PIL）
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
- **施法动作**：`modmain.lua` 一行 `MUSHA_AOE_CAST_STATE = "quickcastspell"`（抬手，第 5 帧出手）
- 月牙 FX（`musha_slash_qi_fx.lua`）：`FX_SPEED 22.5` / `FX_HIT_DIST 1.0` / `scale 0.90`（放大 2 倍）
- 礼包页：标题 `gift_head` (-263, 254)；提示 `gift_hint` 跟随标题右下 -15,-15 再 +120 → (-126, 223)
- 能量条 = 官方挂载（`statusdisplays` + Badge + netvar），不是面板里的一页
- 悬停信息面板钉屏幕右下角（`musha_item_info.lua:PinBottomRight`）

## 🧱 铁律（踩过的坑，动手前扫一眼）
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
- 生命恢复 `hp_regen_mult` 现在 0 消费方：留 or 删
- 设置页 6 行要不要居中/下移（给数字）
- 上线前清理清单（测试用剑士转职书 / dev_test_gift / 占位美术 / 设置页空行）—— 发布前逐条过
