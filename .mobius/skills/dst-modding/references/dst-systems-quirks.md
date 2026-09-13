# DST 官方系统机制速查（2026-08 S1 实现期发现）

## grue 组件（查理袭击 / 黑暗袭击）
- 玩家夜晚被黑暗袭击 = grue 组件（`player_common.lua` 挂载，`SetSounds("dontstarve/charlie/warn","dontstarve/charlie/attack")`）
- level 机制：进黑暗 level=0，之后每 5~11s level+1；`level > resistance` 才 Attack；免疫时触发 `resistedgrue` 事件
- **`SetResistance(1)` = 挡一次袭击**（level 0→1 那次被挡，level 2 起恢复攻击）——正好是"受击消耗一次"型免疫
- **`AddImmunity(source)` / `RemoveImmunity(source)` = 常驻免疫**（官方用法：Winona 技能树 `winona_charlie_2`、月岩帽 `lunarplanthat`）
- 排查教训：搜"免疫查理"别只搜 charlie/nightmare/SetInvincible——本会话漏了 `SetResistance` 得出"功能不存在"的错误结论。搜免疫类功能时先 grep 官方 `components/<组件名>.lua` 的方法名清单再下结论

## 月相（ms_setmoonphase）
- 官方 `components/clock.lua` **本来就监听** `ms_setmoonphase` 事件（`OnSetMoonPhase`，仅 _ismastersim 注册）
- 合法值：MOON_PHASE_NAMES = {new, quarter, half, threequarter, full}；payload 格式 `{moonphase="new"/"full", iswaxing=true}`
- 评审报告说"事件无监听"是误判——断言"断路"前先 grep 官方代码，mod 里 PushEvent 到 TheWorld 会走官方监听
- 洞穴世界 PushEvent 可能不同步，实测要在主世界地表

## 台词系统（speech_*.lua）
- 挂载：`STRINGS.CHARACTERS.<char> = require "speech_<char>"`（modmain 里，别挂 speech_wilson 当占位）
- 官方 speech 文件**没有**状态字段（ANNOUNCE_INSANITY/HIT/LOWHEALTH/DARKNESS 等全部缺失，所有角色都没有）——但**添加**这些字段就能生效（talker 的 GetString 回退机制：查到就用，查不到回退通用）
- 死亡公告不在 speech 文件（走通用 STRINGS），角色死亡台词一般用 ANNOUNCE_HIT 重伤兜底
- 台词库 docx 导出：`python-docx` 读 `Document.tables`，每表两列（场景 | 台词），导出后手工映射到 speech 字段

## 其他 API 事实
- **ImageButton 没有 SetTint**（只有 Image 有）——用 `self.image:SetTint(r,g,b,a)`，报错 `attempt to call method 'SetTint' (a nil value)` 即此坑
- `health.absorb` 已弃用 → 防御用 `health.externalabsorbmodifiers:SetModifier(inst, 0.6)`（abigailforcefield 同款写法）
- 随从伤害协同（V5.1 规则）：`math.max(基础攻击, 知天命面板×0.5)`
- 稀有配方材料 prefab 名：龙鳞=`dragon_scales`、蟾蜍皮=`toadstool_cap`、触手皮=`tentaclespots`、彩虹宝石=`opalpreciousgem`（知天命配方：4 者组合，TECH.NONE 角色专属）

## patch 工具工作流教训
- patch 的模糊匹配可能吞掉相邻代码块（本会话 old_string 匹配错位，误吞 moonrocknugget PostInit 的前半截并产生重复块）
- 大段替换前先 read_file 确认上下文唯一；替换后立即 grep 该区域检查：重复定义 / 截断的 `if ... then` 无闭合
- 修复后跑括号平衡检查：`python -c "src=open(f,encoding='utf-8').read(); [print(o, src.count(o), c, src.count(c)) for o,c in [('(',')'),('{','}'),('[',']')]]"`
