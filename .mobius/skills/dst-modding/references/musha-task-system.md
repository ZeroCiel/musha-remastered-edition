# Musha 任务系统架构 + replica 同步机制（2026-09 重构后现状）

> 适用于 mods/musha 的后续任务/职业面板开发。SSOT 文档见 mod 内 mush-backlog.md（设计+进度），本文件记**可复用的架构知识与坑**。

## 双任务模型（重构定稿）
- **每日任务 daily_quests**：数组、可累积、上限 10。每天 startday 自动补发到配置数
  `musha_daily_quest_count`（modinfo 3~5，默认 4；GetDailyCount 用 GetModConfigData 读）。
  规则：discover(探索/发现类) 未完成 → 隔日作废；survive 跨天 progress+1；其他类型保留到做完。
- **转职任务 advance_quest**：单任务槽 + `advance_round`(1..3)。雕像/祭坛接取，一次只接 1 个，
  难度池随轮次 1→2→3 递进（ADVANCE_POOL_BY_ROUND）。第 3 轮完成 → CompleteAdvanceQuest：
  `pc.userdata.carrer_special = target; has_advanced = true` + SpawnPrefab("musha_skillbook") 发书。
  接取时跳过 heal_skill（技能系统 _musha_skills.lua.bak 未启用，接了必卡）。
- 数据字段在 `pc.userdata`：`daily_quests[{id,p,t,done}]`、`advance_quest`、`advance_round`、
  `advance_target`。旧字段 quests_for_advance/quests_for_advance_done 清空兼容（面板新版不用）。

## replica 同步机制（核心坑，反复踩）
- 客户端面板读的是 `inst.replica.musha_profession_component.cached_data.userdata`，不是服务端组件。
- 服务端**改了 userdata 之后必须主动推送**，否则面板不刷新：
  ```lua
  pc.inst.replica.musha_profession_component:DoUpdata(pc.userdata)
  ```
  replica 的 DoUpdata 内部 json.encode → `self.gamedata:set(json)` (net_string，第三参="gamedata_dirty")
  → 全端 gamedata_dirty 事件 → replica OnGameDataDirty → cached_data 更新 → 面板监听的 dirty 事件触发。
- `pc.mydata` 不存在（会 nil 索引崩）；正确字段是 `pc.userdata`。搜索代码时两词都查，旧代码混用。
- profession_component 里 `userdata = DoUpdata` 挂在 Class props 上 = 类方法表不是事件表；
  实例构造里又显式 `self.userdata = {...}` 遮蔽了方法 —— 别依赖 `pc:userdata(...)`，直接走 replica.DoUpdata。

## 任务完成/进度推送的落点
- 每次进度+1、done 变化、轮次推进、接取/作废后都要 DoUpdata 推送。重构版统一在 quest:SyncToPanel()。
- OnLoad 读档后也要 SyncToPanel()（旧档 quest 有任务但 userdata 未同步的兼容）。

## 事件驱动清单（哪些事件真的在推）
- craftitem(制造/科学机)、harvest(cookpot)、killed(蜘蛛/猪/火犬)、musha_item_collected(modmain 在
  nightmarefuel/宝石入包时 Push，collect 类)、WatchWorldState("startday")、modmain 5s 轮询
  TheSim:FindEntities(发现类，30/20 码)。heal_skill 无驱动源（技能系统禁用）。
- areatrigger 是历史遗留监听，handler 空实现防崩；发现任务实际走 5s 轮询。

## 祭坛/雕像占位技巧（原版 prefab 挂 mod 交互）
进阶祭坛 prefab 从未实现 → 用 AddPrefabPostInit 给原版 prefab 打 tag + 挂组件：
```lua
AddPrefabPostInit("statuemaxwell", function(inst)
  if not GLOBAL.TheWorld or not GLOBAL.TheWorld.ismastersim then return end
  inst:AddTag("musha_altar")
  inst:AddComponent("musha_action")
  inst.components.musha_action:SetFn(OnAltarInteract)
end)
```
SCENE 右键动作链必须四件套齐：AddAction("MUSHA_QUEST_INTERACT",...fn) + AddComponentAction("SCENE","musha_action", HasTag 判断)
+ AddStategraphActionHandler + **组件必须实现 fn 里调用的方法**（曾缺 InteractScene → 点击即崩）。
测试用控制台 c_spawn("statuemaxwell")。

## ScrollingGrid 滚动列表（参考明生传送）
`mods/mingsheng/scripts/screens/mingsheng_teleportscreen.lua` = 现成模板：
TEMPLATES.ScrollingGrid({...}) + item_ctor_fn + apply_fn + SetItemsData。参数 widget_width/height、
num_visible_rows、scrollbar_offset、allow_bottom_empty_row。任务列表(每日行+转职行混排)用它做滚动框，
行数 > 可视区才需要。玩家要的接取滑入动画用 row:MoveTo/V3 或 uianim（Widget 自带 uianim）。

## UI 无视觉通道迭代工作流（用户偏好）
- 我(deepseek)读不了用户游戏截图(视觉通道不支持本地图，转了 RGB/压缩也不行)。
- 用户的做法：截图 → 发腾讯元宝分析 → **把元宝文字分析粘回来** → 我照文字意见改坐标/字号。
  元宝评 UI 会给：符合点/问题点/建议(如 进度语义、对比度、层级、按钮权重)+建议坐标方向。
- 别反复试 vision_analyze(本地图/URL 都读不到)；直接请用户贴文字描述或元宝分析。
- 用户微调用封闭短指令：如"叉号左移10"、"LV右移12"、"灰条靠右长10"。逐条累加执行，别一次大改。
- 面板整体缩放用一个 PANEL_ZOOM 常量，用户报"太大/太小/0.87/0.93"就改一个数。

## 背景图 1:1 与变形根因
- DST Image:SetScale(x,y) 是**倍数**(Widget 继承, UITransform)，不是像素尺寸；
  传 (592,400) 会被当 592x400 倍缩放 → 巨大/或语义混乱。原图 1232x832 被硬压成小卡靠的是别的误用。
- 要 1:1 原图全尺寸用 `img:SetSize(BG_W, BG_H)`(ImageWidget:SetSize 是像素尺寸语义)。
- 变形/比例不对排查顺序：先确认代码没把原图 SetScale 成非等比目标(圆形装饰变椭圆=非等比拉伸)，
  再确认整卡 PANEL_ZOOM 是否 1，最后看图上装饰坐标(红叉等在图上 px → 卡中心坐标 = px - 图宽/2)。

## Lua 语法快速检查（luaparser）
改完多个 .lua 后用系统 Python 的 luaparser 做真语法检查(不是简单括号配平)：
`"C:/Users/Administrator/AppData/Local/Programs/Python/Python311/python.exe"` (venv 里没有 luaparser；
execute_code 沙箱也 import 不到 → 用 terminal + 系统 python)。
