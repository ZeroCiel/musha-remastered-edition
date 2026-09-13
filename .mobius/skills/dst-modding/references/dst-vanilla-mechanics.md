# DST 官方机制速查（明生 mod 实战验证）

## 月相系统（ms_setmoonphase）
- **官方 clock 组件本来就监听 `ms_setmoonphase` 事件**（components/clock.lua `OnSetMoonPhase`）——mod 只要 `TheWorld:PushEvent("ms_setmoonphase", {moonphase="new"/"full", iswaxing=true})` 就生效，**不需要自己加监听**
- 合法 moonphase 值（MOON_PHASE_NAMES）：`new / quarter / half / threequarter / full`
- 评审文档说"事件无监听"是误判——先查官方代码再下结论。实测在**地表主世界**测，洞穴 shard 可能不同步

## 查理袭击 = grue 组件
- 玩家被黑暗袭击由 `components/grue.lua` 驱动（player_common 给玩家挂 grue 组件）
- **免疫接口**：
  - `grue:SetResistance(n)`——level > resistance 才攻击。level 每 5~11s +1（从 0 起），进光重置。SetResistance(1) = 挡第一次袭击（resistedgrue），level 2 起恢复被咬 = **"免疫一次"**
  - `grue:AddImmunity(source)` / `RemoveImmunity(source)`——常驻免疫（Winona 技能树 `AddImmunity("winona_charlie_2")` 同款）
- 搜"查理免疫"记得搜 Resistance/grue，别只搜 charlie/nightmare/SetInvincible

## 角色状态台词（speech 文件）
- 官方所有角色 speech 文件**都没有** ANNOUNCE_INSANITY/HIT/LOWHEALTH/DARKNESS 等状态字段（这些走通用 fallback）
- **在 mod 的 speech 文件里添加这些字段即可生效**（talker GetString 查 STRINGS.CHARACTERS.<char>.ANNOUNCE.X，缺失才回退通用）——添加不冲突
- 挂载：`STRINGS.CHARACTERS.mingsheng = require "speech_mingsheng"`（注意原先可能挂的是 speech_wilson）
- 死亡/复活：`respawnfromghost` 是官方标准复活事件（作祟/给予/范围复活都走它）；满状态 = `health:SetPenalty(0)` + SetCurrentHealth(max) + sanity/hunger SetPercent(1)
- 给予复活防时序坑：先消耗物品，再 `owner:DoTaskInTime(0, ...)` 延时 1 帧 PushEvent，防止复活瞬间物品栏清空把施法物品带走

## 角色标签 / 配方
- 角色 prefab 用 `local Character = "mingsheng"` + `inst:AddTag(Character)` 加角色 tag——AddComponentAction 的 builder_tag、FindEntities 过滤器、配方角色专属都靠它
- 配方材料名确认：龙鳞=`dragon_scales`、蟾蜍皮=`toadstool_cap`、触手皮=`tentaclespots`、彩虹宝石=`opalpreciousgem`（先 `ls prefabs/ | grep` 确认再写配方）

## 调试开关
- 统一调试 print：modmain 顶部覆盖全局 `print`，按前缀过滤（`[DEBUGBOSS]`/`[gaoshizhe]`），`MINGSHENG_DEBUG = false` 时屏蔽——比逐行删 print 安全
- 注意覆盖全局 print 会影响前台调试输出，只过滤自己前缀的调用，其他原样转发
