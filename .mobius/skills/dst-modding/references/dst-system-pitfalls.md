# DST 系统坑合集（2026-08 测试轮）

## Farm growable 阶段判断（补充 farm-plant-system.md）

- `Growable:DoGrowth()` 门槛：`targettime == nil and pausedremaining == nil`（完全停止）→ 直接 return false 不推进。
  调用前若 `not IsGrowing()` 要先 `StartGrowing()` 重启（但 StartGrowing 里 timefn 返回 nil 会静默失败，targettime 仍 nil）。
- **阶段判断用 `stages[stage].name`，不要用 `current == max_stage - 1`**：
  randomseed 只有 2 阶段（seed/sprout），evergreen 4 阶段——`max_stage-1` 会把它们的中间阶段误判成 full，整批不推进。
  farm 作物 6 阶段：seed/sprout/small/med/full/rotten（GROWTH_STAGES，loopstages=true 从 2 回绕）。
- 腐烂阶段名 = "rotten"，成熟 = "full"，最终形态（randomseed 的 sprout、树最高阶段）`current >= max_stage` 直接跳过。
- 巨大化动画：bank 里是 `grow_oversized`（过渡）+ `crop_oversized`（循环）。
  **直接 `PlayAnimation("oversized")` 会报 "Could not find anim [FROMNUM]"，贴图/碰撞一起消失**。
- full 的 pregrowfn = `MakeStressCheckpoint(inst, true)`（farm_plants.lua local 函数），内部设 `inst.is_oversized`，
  巨大化判定 = `force_oversized or (not no_oversized and stress == NONE)`。先跑 pregrowfn 再 SetStage 才能播对动画。
- 巨大化腐烂（is_oversized）会 `StopGrowing` 不自播；普通腐烂自播但 no_oversized=true（以后不能巨大化）——mod 恢复时清掉即可。

## 传送/UI 类

- **传送界面误触**：默认 `SelectEntry(1)` + 鼠标点击映射成 CONTROL_ACCEPT（抬起时 IsMouseDown=false）→ 点边框就传送。
  解法：不默认选中；ACCEPT 仅键盘/手柄。
- **传送后回走**：`Physics:Teleport` 后要 `locomotor:ClearPath()` + `player:ClearBufferedAction()`，
  单人直传和联机 RPC 服务端两处都要加。
- **记录点绑定实体**：waypoint 存 `ent.GUID`，`GetWaypoints` 时用 `TheSim:FindFirstEntityWithGuid` 惰性验证，
  实体（木牌/星石）被摧毁自动移除记录点（倒序遍历 + reorder + SyncToReplica）。

## Atlas / 命名贴图

- `images/names_<build>.xml` 和 `names_gold_<build>.xml` 的 **Element name 必须是 `<build>.tex`**（如 mingsheng.tex），
  不是 `names_mingsheng.tex`。写错日志报 "Could not find region 'mingsheng.tex' from atlas .../names_mingsheng.xml"。
- 检查资产：正则扫 `Asset("ATLAS|IMAGE|ANIM", "path")` vs 文件存在；`ghost_`/`names_` 开头的 Asset 是
  `"anim/ghost_"..build..".zip"` 动态拼接（非缺失，正则误报）。
- mod 引用原版动画（spear/swap_spear/statue_ruins_fx）Asset 路径能解析——原版 anim 在 `data/anim/`（不在 databundles/anim）。

## 物品变活物（告示者/伯尼式）

- 饥荒"物品不消耗 + 本体战斗"的正解是**伯尼式单实体形态切换**（物品→坐姿玩偶→战斗体→掉落），
  "背包留一个 + 地上另生成战斗体"= 复制物品，做不到。
- 明生告示者现状：变身器 = 下地右键激活 → `SpawnPrefab(shadow_mingsheng/illusion_mingsheng)` 随从 180s（消耗本体）。
  文档 §2.5.1 要 1200 血独立战斗体【待作者确认】——未拍板前不要主动实现（订单外 3~4 天工作量）。

## 温度/保温

- `temperaturelock:StartLock(duration, temp)` 只是锁温，不是持续抗冷抗热。
- 等效 WX-78 冷热电路：`temperature.inherentinsulation`（抗冷）+ `inherentsummerinsulation`（抗热），
  定时器到期移除；重复使用先 Cancel 旧任务并减回，防叠加。
