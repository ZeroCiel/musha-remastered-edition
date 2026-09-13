# DST 系统 API 速查（明生 S1 实测 2026-08）

## Widget 颜色 API 坑
- `SetTint(r,g,b,a)` **只有 Image 有**（widgets/image.lua:142）。Widget / Button / ImageButton 都没有。
- ImageButton 内部是 `self.image`，要改色用 `btn.image:SetTint(...)`（官方自己也是这么调的）。
- Text 用 `SetColour`（不是 SetTint）。
- 症状：`attempt to call method 'SetTint' (a nil value)` 且报错行是 ImageButton → 改成 `.image:SetTint`。

## 月相（天体献祭类功能）
- **官方 clock 已监听 `ms_setmoonphase`**（components/clock.lua OnSetMoonPhase，`_ismastersim` 才注册）。mod 只要 `TheWorld:PushEvent("ms_setmoonphase", {moonphase="new"或"full", iswaxing=true})` 就能改月相，不需要自己再监听。
- MOON_PHASE 合法名：new / quarter / half / threequarter / full。字段名写错才不生效。
- 评审说"事件无监听/断路"时先 grep 官方 `ListenForEvent("ms_setmoonphase")` 再下结论——官方可能本来就有 handler。

## speech 系统（角色专属台词）
- 挂载：modmain 里 `STRINGS.CHARACTERS.<char> = require "speech_<char>"`（明生原来错误地挂 speech_wilson）。
- **GetString 回退机制**：talker 播台词查 `STRINGS.CHARACTERS.<char>.ANNOUNCE.*`，缺失时回退通用。所以**官方 speech 文件里没有的 ANNOUNCE 字段可以直接加**（如 ANNOUNCE_INSANITY/HIT/LOWHEALTH/DROWNING/RAIN/THUNDER——官方所有角色 speech 都没有这些，加了就生效，不会崩）。
- 物品检查台词：DESCRIBE 表里加 `DESCRIBE.mingsheng_xxx = "中文"`。
- 台词库 docx 迁移：8 张表每张是"场景|台词"两列；`python-docx` 导出后按场景映射到 ANNOUNCE/DESCRIBE 字段。表8（原版物品 40+ 条）通常可留 S2。
- 玩家死亡公告、角色通用状态台词不在 speech 文件里（官方各角色都没有这些字段），靠 ANNOUNCE 加字段实现。

## 数值/属性 API（对齐文档数值时）
- **dapperness 单位是 per-second**：`equippable.dapperness = 20/60` 就是 +20 理智/min（TUNING.DAPPERNESS_LARGE = 100/(day_time*3)，day_time≈480s）。别直接用 TUNING 常量当"每分钟"用。
- **生物防御**：`health.externalabsorbmodifiers:SetModifier(inst, 0.6)`（60% 减伤）。`health.absorb` 已 DEPRECATED。官方例：abigailforcefield.lua。
- **攻击系数**：`combat.damagemultiplier = 0.8`（不善战斗类被动）。
- 保暖：`insulator:SetInsulation(200)` 直接填数值（TUNING.INSULATION_LARGE=240，≠文档值 200）。
- 随从/召唤物数值同步：伤害协同 = `math.max(基础, 知天命面板×0.5)`。

## 配方材料 prefab 名（易记错）
- 彩虹宝石 = `opalpreciousgem`（不是 rainbowgem）
- 龙鳞 = `dragon_scales`（龙蝇掉落，不是 dragonfly_scales）
- 蟾蜍皮 = `toadstool_cap`（蟾蜍王）
- 触手皮 = `tentaclespots`
- Ingredient 4 参形式：`Ingredient(prefab, count, atlas, image)` 带图标。

## 查理袭击（grue 组件）免疫 API
- 查理袭击 = 玩家 `components.grue`（player_common.lua 挂载，音效 dontstarve/charlie/*）。
- **抵抗型**：`grue:SetResistance(n)`——grue level 从 0 开始、黑暗中每 5~11s +1，`level > (resistance or 0)` 才 Attack（否则推 `resistedgrue` 事件）。所以 `SetResistance(1)` = 挡 level 0→1 那次袭击后恢复 = **"免疫一次"**。进光/白天 level 重置。
- **完全免疫型**：`grue:AddImmunity(source)` / `RemoveImmunity(source)`（Winona 技能树同款；immunity 表不为空则不攻击）。
- 免疫类需求先 grep `SetResistance|Resistance|AddImmunity`，别只搜 charlie/nightmare/SetInvincible（曾漏搜误判功能不存在）。

## 批量改 Lua 表文件后的语法验证（必做）
DST 无 luac/luajit 可执行文件，用 python 的 `luaparser` 验证：
```bash
python311 -m pip install luaparser
```
```python
from luaparser import ast
ast.parse(open(path, encoding='utf-8').read())  # 抛 SyntaxException 即语法错
```
- 对照法排除误报：官方 speech_wilson.lua 等能解析 OK，则我们文件报错 = 真错误。
- 本会话踩过的三类插入 bug：①替换匹配串没带行尾逗号 → 吞掉原行逗号，后续字段断链；②插入块插到 `表名 =` 和 `{` 之间（表外），表结构全乱；③批量 replace 残留孤立逗号 `,`、重复 key（后定义覆盖先定义，如英文覆盖中文）。改完必须跑一遍 luaparser 再交付。
- 台词库 docx → speech 的迁移脚本改完同样验证。

## patch 批量改相似文件的坑（第二次踩，同 class）
modmain 里有多个结构相似的 PostInit 块（如两个 `AddPrefabPostInit("mingsheng_ztm", ...)`）。用长 old_string 覆盖一大片时若上下文与目标块之外的部分撞上，会把相邻块（如 moonrocknugget 的 `return`/`end` 尾巴）一起吞掉造成语法错误。
- 对策：old_string 取**最小必要上下文**（只包目标块的独特行，不要大段复制）；含重复模式的块先读文件确认唯一性；大 patch 后立刻重读验证括号/end 配对。
