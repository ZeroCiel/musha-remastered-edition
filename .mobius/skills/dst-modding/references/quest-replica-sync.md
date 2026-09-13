# DST 任务系统 + replica 同步 + 面板数据流（Musha 实测 2026-09）

> 场景：职业面板显示任务列表，服务端组件推进任务进度，客户端面板要实时刷新。
> 教训：这套 mod 里"服务端组件 ↔ replica ↔ 客户端 widget"的数据同步链路坑极多，
> 大多数"任务接了没反应 / 面板不刷新 / 打开面板崩"都源于此。

## 1. 数据同步正确姿势（replica push）

组件间典型链路：服务端组件(musha_profession_component) 持有 `self.userdata` 全量数据表 →
写入 replica 的 net_string → dirty 事件 → 客户端 replica 缓存 → widget 刷新。

```lua
-- 服务端组件侧：改完 userdata 后推送（必须推，否则面板/客机看不到）
pc.userdata.quests_for_advance = quest_ids
if pc.inst and pc.inst.replica and pc.inst.replica.musha_profession_component then
    pcall(function()
        pc.inst.replica.musha_profession_component:DoUpdata(pc.userdata)
    end)
end
```

- replica 定义：`self.gamedata = net_string(inst.GUID, "musha_gamedata", "gamedata_dirty")`
  → `gamedata:set(json)` 后所有端触发 `gamedata_dirty` 事件。
- 客户端 widget 监听 dirty：`owner:ListenForEvent("gamedata_dirty", fn)`，从
  `owner.replica.musha_profession_component.cached_data.userdata` 读数据。
- **面板数据源 = replica.cached_data.userdata**（不是服务端组件的 userdata 直接可见）。

## 2. 陷阱：Class 第三参数不是事件表

```lua
Musha_Profession_Component = Class(ctor, nil, { userdata = DoUpdata, ... })
```
- Class 第三参数(props) 是**方法表**(走 __index)，不是事件监听表。
- 这里的 `userdata = DoUpdata` 表示方法名是 `userdata`，即 `pc:userdata(data)` 会调 DoUpdata。
- **但是**构造器里 `self.userdata = { ... }` 把同名方法遮蔽成了数据表！所以
  `pc:DoUpdata(...)` 和 `pc:userdata(...)` 都可能不是你以为的东西。
- 安全做法：不猜，直接走 `inst.replica.X:DoUpdata(data)`（replica 侧同名方法一定存在）。

## 3. 断链审计清单（任务"接了没反应/永远卡死"排查顺序）

任务系统组件 musha_quest 常犯四类断链，逐个 grep 验证：

1. **监听已注册但方法不存在** → 事件触发即 LUA ERROR（定时炸弹）。
   例：`ListenForEvent("areatrigger", fn→self:OnAreaTrigger)` 但方法未定义。
   修复：补空方法或删监听。凡加监听必同时确认目标方法存在。
2. **方法已定义但无调用点** → 任务永远卡在 0 进度。
   例：`OnCollected/OnDayPassed/OnHealUsed` 有实现，但没有谁调它们。
   修复思路：收集类挂已存在的拾取 PushEvent；天数类 `inst:WatchWorldState("startday", fn)`；
   技能类等技能系统真正启用后接。
3. **引用了不存在的对象**：`pc.mydata.xxx` 但组件只有 `self.userdata` → nil 索引崩。统一 userdata。
4. **改完服务端数据没推送 replica** → 面板/客机不刷新。见 §1，每次 MarkDone / CompleteAdvance /
   接任务后都要 DoUpdata。
5. **旧档兼容**：OnLoad 恢复 current_quests 后把任务 ID 同步回 pc.userdata 并推送，
   否则早期存档"任务在跑但面板空白"。

## 4. 进度同步到面板（进度版 x/y 显示）

- 面板要显示 `progress/target` 时，progress 存服务端 `current_quests[i].progress`，replica 读不到。
- 方案：`SyncProgressToPanel()` 遍历 current_quests 组装
  `pc.userdata.quests_advance_progress = { [i]={p=..., t=...} }` 再 DoUpdata 推送。
- 在每个 `q.progress = q.progress + 1` 之后调用一次（可脚本批量插入同缩进调用）。
- 面板 status 显示优先级：done → "✓"，有 prog → "p/t"，否则 "进行中"。

## 5. SCENE 建筑交互动作链（雕像/祭坛类占位）

完整链路：`AddAction("MUSHA_QUEST_INTERACT", ...)` 动作 fn 里调用
`act.target.components.musha_action:InteractScene(act.doer)` →
组件方法 `UseItem(doer)` → `SetFn(OnXxx)` 里写业务。

```lua
AddPrefabPostInit("statuemaxwell", function(inst)  -- 原版建筑当"占位祭坛"
    if not TheWorld.ismastersim then return end
    inst:AddTag("musha_altar")                       -- SCENE ComponentAction 靠 tag 显动作
    inst:AddComponent("musha_action")
    inst.components.musha_action:SetFn(OnAltarInteract)
end)
```
- ComponentAction SCENE：`if inst:HasTag("musha_altar") then insert(ACTIONS.X) end`
- Stategraph 处理：`AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.X, "doshortaction"))`
- **占用原版建筑占位不用复制动画**：AddPrefabPostInit 打 tag 即可，别新建 prefab 引原版 anim（mod 引用不到）。

## 6. 面板任务行 UI：滑入动画（MoveTo/uianim）

- 每行做成 Widget 容器（不是裸 Text），行内 name/status 相对 (0,0) 摆放。
- 滑入：目标 y 已知，先把行 SetPosition 到 `target_y - 90`，再
  `row.inst.components.uianim:MoveTo(Vector3(from), Vector3(to), 0.30 + i*0.08, done_fn)` 逐行错开。
- **面板关着时数据到了也要能播**：用 pending 标记，`ShowPanel()` 里 Refresh 后补播。
- 只播一次的判断：`has_task 从 false→true`（_prev_has_task），避免每次 dirty 重播。

## 7. UI 全尺寸背景图（防变形）

背景图被代码硬压成小卡（SetScale 误用）→ 图上圆形装饰被拉变形、比例不对。
- 修复：`Image:SetSize(原图宽, 原图高)` 1:1 显示，不做压缩。
- 整卡缩放留给容器：`content:SetScale(PANEL_ZOOM)`，PANEL_ZOOM 单值可整体微调
  （用户迭代调 0.87→0.93 时只改一个常量）。
- 全尺寸后内容坐标/字号要按比例重排（旧小卡坐标 × 放大系数），不要整卡 scale 拉伸文字（发糊）。
- 图上自带元素坐标换算：图上右上红叉 px≈(1140,90) → widget 坐标
  `x = px_x - W/2`、`y = H/2 - px_y`（中心原点系）。

## 8. Lua 语法检查（比括号配平强）

luaparser 可做真 AST 语法检查（括号配平查不出 if/end 错位）：

```bash
"C:/Users/Administrator/AppData/Local/Programs/Python/Python311/python.exe" - <<'PY'
from luaparser import ast
for f in [r"path\file.lua"]:
    ast.parse(open(f, encoding="utf-8", errors="replace").read())
    print(f, "OK")
PY
```
- 注意：luaparser 装在系统 Python311，不在 hermes venv；execute_code 沙箱也找不到，
  要用完整路径在 terminal 跑。
