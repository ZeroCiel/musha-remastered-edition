# 武器绑定的技能（剑气斩 slash_qi）—— 实现方案 v1
2026-09-13 · 目标：写完就能上架 Steam（本期），近卫排下一期（3~7 天后）

## 一、现状（已经有的，不用重做）
- 特效 prefab `scripts/prefabs/musha_slash_qi_fx.lua` ✓ 已在 PrefabFiles 里注册
  - 直飞、命中自毁、`inst.cast_hit` 回调口子已经留好（文件头注释写明等"主动技框架⑤"接）
  - 素材：占位 = 原版 `shadow_thrall_projectile_fx`；自己的 `exported/slash_fx` 打包成 `anim/slash_fx.zip` 后把 `USE_CUSTOM_FX` 改 true
- 键位系统 `scripts/components/musha_keyhandler.lua` ✓ 默认 `skill_1~skill_5` = 1~5 键，可改键、存本地
- 服务端技能数据/加点 `musha_profession_component.lua` ✓
  - `CanUpgradeSkill(tree,key)` / `UpgradeSkill(tree,key)` / `GetSkillInfo(tree,key)`（里面有 `current_level`）/ `GetAllSkillLevels()`
  - 武器精通只在 `carrer_special == "saber"`（剑士）时生效（component 607~614 行）
- 武器 prefab `musha_sword` ✓（`weapon:SetDamage(42)`、tag `musha_weapon`）
- 技能数据 `scripts/skills/musha_skill_data.lua:72` 有 `slash_qi` 条目（数值是草案，冷却/倍率这次定死）

## 二、缺的三块（本期要写）
1. **施放通道**：客户端按键 → 服务端施放；**主机（自己当服主）直接施放，不走 RPC**
2. **校验 + 冷却**：手里拿着对应武器 + 该技能已学（等级>0）+ 冷却好了（可选：扣能量）
3. **伤害结算**：命中时按"武器伤害 × 倍率"结账，剑气范围内命中的怪物吃伤害

## 三、v1（能跑优先，建议先上这个）
| 项 | v1 做法 |
|---|---|
| 触发 | 技能快捷键 `skill_1`（默认 1 键，可改键）；手里必须拿着 `musha_sword` |
| 方向 | 朝鼠标指向的世界坐标；没有鼠标（手柄/无光标）= 朝角色面向 |
| 施放 | 施法者前 0.5 格 `SpawnPrefab("musha_slash_qi_fx")` → 填 `fx.cast_hit` → `complexprojectile:Launch(target_pos, doer)` |
| 伤害 | `武器伤害 × 1.2`（常量在文件头，方便调）；命中判定用 `FindEntities` 扫剑气落点半径 ~1.5 |
| 冷却 | 6 秒（常量）；冷却中按键只回一句提示（走 STRINGS，中英都有） |
| 音乐 | 出手/命中各一个音效（先借原版暗影系，回头换） |
| 门禁 | 见"待拍板 3"；默认建议 = 剑士（转职后）才能用 |

## 四、v2（下一期或之后）
- 剑气**穿透**路径上多只怪（v1 只打落点范围）
- 消耗能量球（要等能量系统接口确认，现在能量只在 `prefabs/musha.lua` 里）
- 换成自己的 `slash_fx` 素材 + 命中"炸开"第二帧
- 技能页显示冷却倒计时 + 快捷栏图标

## 五、顺手要修的 bug
`musha_keyhandler.lua:119`
```lua
if TheWorld and TheWorld.ismastersim then return end  -- 仅客户端
```
→ **主机自己当服主时按技能键完全没反应**（TheWorld.ismastersim 为真就 return）。
改成：主机也响应，只是不走 RPC、直接调服务端施放函数。

## 六、用户已拍板（2026-09-13）
- **战士技能预算**：主战主动技**只有 1 个**（正常，不再加）；其余全是**被动 or 耍戏（gimmick）**
- **武器绑定技能 = 4 个候选，玩家 4 选 2**；**不通用**（每个只跟它自己那把武器生效，不跨武器、不按职业给）
  → 技能页要加「武器技能 4 选 2」的选择 UI（本期一起做）
- 因此原来的问题 ③（谁能学）作废：不按职业，按武器 + 玩家自选 2 个

## 六点五、素材备选（2026-09-13 发现）
`exported/水蓝色月牙斩击/` 里躺着 `crabking_claw_swipe_fx.scml` + `.zip`（原版蟹王爪击特效，**真·月牙形状**，含编译好的 zip）。
v1 现在用的是即梦图抠背的 `slash_fx`。→ 待用户定：剑气斩用哪个（真月牙 / 抠背图）。
另：武器**升级机制延后**，抄"可移动携带的火堆"设计（记录未找到，见 `musha-dayrewards-plan.md`）。

## 八、v1 已落地（2026-09-13 写完，等进游戏实测）
- `scripts/musha_weapon_skill.lua`（**新建**）：技能表 + 服务端施放 + 伤害结算 + 客户端入口
  常量在文件头：`CAST_KEY=KEY_F` / `COOLDOWN=6` / `DAMAGE_MULT=1.2` / `HIT_RADIUS=1.6` / `MAX_RANGE=12`
  技能表 `SKILLS`：现在只有 `musha_sword = 剑气斩`（生命树枝 / 水晶剑 以后各加一行，key 用武器 tag 或 prefab 名）
- `scripts/rpcs/musha_rpcs.lua`：新增 RPC `musha_weapon_skill_cast`（客机只发瞄点，服务端自己校验）
- `modmain.lua` ~118 行：按键挂载（`AddSimPostInit` 里注册；主机/客机同一入口）
- 伤害走 `combat:CalcDamage(doer, target, 倍率)` → **武器精通会一起算进去**；这 API 万一不叫这名，
  自动退回"武器伤害 × 倍率"并在日志打一行提醒
- 顺手修了老 bug：`musha_keyhandler.lua:119` 主机（自己当服主）按技能键完全没反应

- **触发方式（2026-09-13 v2：改走原版，用户问"能用他们的吗"→ 能，而且白拿）**
  做法：武器 prefab 上加 **`spellcaster` 组件 + `castonpoint` tag**（见 `scripts/prefabs/musha_sword.lua`）：
  ```lua
  inst:AddTag("castonpoint")                     -- ⚠️ 必须在 SetPristine 之前，否则客机看不到
  ...
  inst:AddComponent("spellcaster")
  inst.components.spellcaster.canuseonpoint = true
  inst.components.spellcaster:SetSpellFn(function(item, target, pos) ... end)   -- pos 是 Position，要 pos:Get()
  ```
  原版自动给你：`ACTIONS.CASTSPELL`（`rmb=true` / **`distance=20`** = 站着放不用走过去）、右键点地摆动作、
  网络同步、服务端校验、角色施法动作、骑牛/开船自动屏蔽（原版 componentactions.lua:2155-2180）。
  → **自己造的 AddAction + AddComponentAction + stategraph 三件套已删**（会多冒一个右键项），别再改回来
- F 键保留为快捷方式（可选）：删 modmain 里那块 `Safe("武器技能按键", ...)` 即可，不影响右键

**进游戏要实测这 6 条**
1. 拿剑 → 右键地面 → 菜单里要有「施放·技能」；点下去剑气朝那个点飞
2. 手里没剑 → 右键地面**不该**出现这个选项（= 绑定生效）
3. 打中怪 → 掉血；日志会打 `[Musha] 剑气斩 命中 N 个目标`（N=0 说明判定半径/朝向要调）
4. 连放 → 6 秒内只放一次，并回一句"冷却中（还剩 X 秒）"
5. 按 F 也一样能放（快捷方式）
6. 怪扎堆 → 一次剑气能同时打到落点 1.6 半径内的多只

**还没做的**
- F 键和原版按键的冲突要实测（冲突就改 `CAST_KEY`；以后接 `musha_keyhandler` 换成可改键）
- 武器技能「4 选 2」的选人 UI + 存 userdata
- 剑气素材二选一：即梦抠背图 `slash_fx` / 真月牙 `crabking_claw_swipe_fx`

## 八、v3 定调（2026-09-13，用户拍板）
- **保留右键点地那条原版路由**，不改成自造 action
- **不要女武神那套突进 sg**（`aoeweapon_lunge` 的位移冲刺）：剑气斩是**原地**放的
- 右键菜单文字从「施法」改成武器技能名

## 九、v4 定调（2026-09-14）★ 现行方案
- 触发方式改用**女武神战矛那条 AoE 路线**：`aoetargeting`（SetPristine **之前**加）+ `aoespell`（服务端）+ `WS.DoCast`
- 三条硬要求 + 完整行号级查证 → 见 `musha-rightclick-spec.md`（新建，权威参考）
- 显示名走正规范式 `STRINGS.ACTIONS.CASTAOE.MUSHA_SWORD`（原版 strfn 就是按 prefab 大写取的）
- 仍然**不加** tag `aoeweapon_lunge` → 不位移；想试冲刺版加上那个 tag 即可（一行）
- v3 的 `ACTIONS.CASTSPELL.stroverridefn` 改名法**已废弃**（法杖路线的 hack）

## 十、v4 之后进游戏要实测（按顺序）
1. 拿剑 → 右键按一下 → **应出现瞄准圈**（没出 = aoetargeting 没在 pristine 前加 / 客机读不到）
2. 瞄准圈状态下点地面 → 菜单要有「剑气斩」（没有 = STRINGS.ACTIONS.CASTAOE.MUSHA_SWORD 没挂上）
3. 点下去 → 剑气朝那个点飞、怪掉血（日志 `[Musha] 剑气斩 命中 N 个目标`）
4. 冷却中 → 回一句"冷却中（还剩 X 秒）"
5. 按 F 也能放（快捷方式，不走 AoE 瞄准）

## 十、v5（2026-09-14）两个报告的问题 + 根因
1. **动作**：AoE 默认落 SGwilson 的 `castspell` 状态 = 播 staff_pre/staff（举杖念咒），
   PerformBufferedAction 压在 53 帧（≈1.8s）才触发 → "举杖举半天"。
   → 修：modmain 里包一层 SGwilson / SGwilson_client 的 CASTAOE handler.deststate，
   带 `musha_weapon` tag 的武器 → 走 `combat_lunge_start`（原版突进前两段 lunge_pre→lunge_lag，
   武器向前劈、快、**不位移**）；其它物品照原版。
   要位移冲刺版：还得加 tag `aoeweapon_lunge` + aoeweapon_lunge 组件 + PushEvent("combat_lunge")，三样齐才行。
2. **剑气压不出去（"小虫掉地上一下就没了"）**：`FX_GRAVITY = 0` 是元凶。
   complexprojectile 的命中判定（components/complexprojectile.lua:187~200）是
   `velocity.y += gravity*dt` → `if velocity.y < 0 and y <= 0.05 then Hit()`，
   重力 0 → 弹道算不出落点 → 一出膛就贴地 Hit。
   → 修：`FX_GRAVITY = -35`（原版暗影抛射体同值）+ 出手点抬高 `Vector3(0.25, 2, 0)` + 速度 15 + 兜底 2.5s。

## 十一、v6~v9（2026-09-14）剑气特效定型 ★ 现行
1. **飞行机制换成原版 `projectile` 组件**（不是 complexprojectile）= 直线飞、靠近即命中：
   `SetHoming(false)` 直线 + `SetRange(12)` 飞满自灭 + `SetHitDist` + `SetLaunchOffset`；
   参考：遗迹守卫 mod 的 `mecha_x_projectile.lua`、原版 blowdart/boomerang。
   · 它只认**实体**目标 → 落点用一个隐形实体 `musha_skill_point` 当靶子
     （无 health/combat → combat.lua:1122 CanHitTarget 不通过 → DoAttack 直接 return，安全）
   · 两个组件**互斥**（共用 "projectile" tag）：别同时加 complexprojectile
   · complexprojectile 为什么淘汰：命中判定是"velocity.y<0 且贴地"，重力 0/够不到落点时永远不命中
2. **素材三选一** `FX_ART`（jimeng = 自己的 slash_fx，单帧 anim ✓已打包 / crescent = 原版真月牙 crabking_claw_swipe_fx，动画名 atk1 / vanilla = 暗影抛射体）
3. **消散** = 炸开 FX（`FX_BURST`，默认 hitsparks_fx）+ 本体 alpha 淡出 0.18s + **本地粒子 12 个**
4. **特效性能铁律（重要，新特效一律照此）**：
   · DST 没开放通用粒子发射器（AddParticleEmitter 不存在），"粒子"只能靠现成 FX 或自画帧
   · 粒子必须**客户端本地生成**：`CreateEntity()` + **不 AddNetwork** + `SetCanSleep(false)` + 自毁
     （照原版 hitsparks_fx/explode_small 的 `--[[Non-networked entity]]` 写法）
   · 触发用 `net_event:push()` 通知各端各自出特效，服务端不发粒子数据
   · 客户端直接 CreateEntity 时要的 build 必须在 **modmain 里全局声明**（否则客户端不一定加载过）
   · 反面教材：把粒子做成联网实体 = 某些"粒子算法"mod 吃 CPU 的根因

## 七、还差的（本期）
1. 触发方式（原问题 ①）：a 技能快捷键 / b 右键武器 / c 都支持 ← 默认按 a
2. 命中口径（原问题 ②）：a 只打落点范围（先上架） / b 沿途穿透 ← v1 按 a
3. 4 个武器技能分别是什么（用户待给：武器 → 技能名/效果）
4. 武器技能「4 选 2」的选择 UI + 存哪（userdata）
   ⏸ **2026-09-14 用户拍板：暂不开放，看后期**（选择 UI / 存 userdata 都不做；
   眼下先把已有的一条（musha_sword → 剑气斩）打磨到能上架）。

## 十二、v10（2026-09-14）本轮落地 —— 用户口述 5 条
1. **冲击波 → 月牙**：`musha_slash_qi_fx.lua` 的 `FX_ART` **改成 `cyan`** —— 用户自己画的亮青月牙
   （`anim/crescent_cyan.zip`，已打包；bank/build=`crescent_cyan`、动画名 `anim`），并在 modmain 全局声明了该 zip。
   旧素材仍留在表里备用：`jimeng`（即梦抠背图，观感像刀光/冲击波）/ `crescent`（原版真月牙
   `crabking_claw_swipe_fx`）/ `vanilla`（原版暗影抛射体）。换素材永远只改 FX_ART 这一行。
2. **冷却期右键无效（官方口径）**：不再靠"弹一句话"，而是把武器的 `rechargeable` 与
   `aoetargeting:SetEnabled()` 绑一起 —— 查证 `components/playercontroller.lua:1609 TryAOETargeting`
   与 `components/aoespell.lua CanCast()`：`IsEnabled()` 为假时右键**根本不进瞄准圈**。
   · 开始冷却（OnDischarged）→ SetEnabled(false)（原版还会顺手 StopTargeting，把正瞄的圈收掉）
   · 冷却结束（OnCharged）→ SetEnabled(true)
   · 读档兜底：包了一层 `rechargeable.OnLoad` 手动刷（OnLoad 里的 SetCharge 不触发回调）+ 装上武器时刷
   · ⚠️ `SetEnabled` 内部带 `if TheWorld.ismastersim` → 只在服务端调，客机读 net_bool 同步
3. **冷却不再弹提示**：`musha_weapon_skill.lua DoCast()` 里那句
   `"剑气斩 冷却中（还剩 X 秒）"` 已删，改为静默 `return false`。
4. **攻击动画改"抬手"**：施法动作从 `combat_lunge_start`（前倾低扫）换成 **`quickcastspell`**
   （SGwilson 原版：`atk_pre` 抬手举武器 → `atk` 挥出；**第 5 帧**就 PerformBufferedAction，16 帧解除 busy）
   → 手感 = 抬手就出招，比原来更快。
   换动作只改 `modmain.lua` 顶部一行 **`MUSHA_AOE_CAST_STATE`**（注释里列了 6 个候选状态的观感）。
5. **Gitee 推送**：实测确认那把 SSH 公钥在 Gitee 上是**仓库级部署公钥（只读）** ——
   `ssh -T git@gitee.com` 回 `Hi Anonymous (DeployKey)!`、`git push` 回 `DeployKey does not support push code`。
   两条解法见状态卡「版本管理（Gitee）」一节。

