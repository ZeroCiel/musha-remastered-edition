# DST 种瓜得瓜（Reap What You Sow）农场系统内部机制

> 来源：2026-08-23 明生mod「卜算·生存」催熟/腐烂修复排查（测试文档三连 bug：催熟不清压力、无法巨大化、腐烂不恢复）。
> 新版 DST 脚本打包在 `data/databundles/scripts.zip`（无散装 scripts 目录），用 `unzip -p scripts.zip <path>` 读取：
> - `scripts/prefabs/farm_plants.lua` — 农场植物 prefab（阶段表、压力测试、魔法生长、腐烂逻辑）
> - `scripts/components/farmplantstress.lua` — 压力组件
> - `scripts/components/growable.lua` — 通用生长组件
> - `scripts/components/crop.lua` 是老版 crop 组件（草/浆果用），**不是**农场作物

## 组件与阶段
- 农场作物组件：`growable`（核心阶段）+ `farmplantstress`（压力）+ `farmplanttendable`（照料）。没有 `crop` 组件。
- stage 是 1-based：1=seed, 2=sprout, 3=small, 4=med, 5=full, 6=rotten
- `loopstages = true`, `loopstages_start = 2`：rotten 阶段结束 self-sow 回 sprout（腐烂作物自然再生长，不再巨大化）
- `growable:SetStage(n)` 会调用该阶段 `fn`（MakeRotten/MakePickable/PlayStageAnim 等状态切换都在这）
- 判定"是否农场作物"：`inst.components.growable ~= nil`（配合 farmplantstress 存在）

## 巨大化判定（关键时机）
- 在 **full 阶段（stage 5）的 pregrowfn** 里判定，不在 SetStage 时：
  ```lua
  inst.is_oversized = inst.force_oversized or (not inst.no_oversized and inst.components.farmplantstress:GetFinalStressState() == FARM_PLANT_STRESS.NONE)
  ```
- full 的 pregrowfn 在"full 停留时间到、即将转 rotten"时执行。想催熟出巨大：
  1. 完美照料（见下）+ `inst.force_oversized = true`
  2. 手动调 full 的 pregrowfn 触发判定（会做 MakeStressCheckpoint(true) + CalcFinalStressState）
  3. `g:StopGrowing()` 防止进 rotten
- `force_oversized` 只在这一刻被读——催熟跳阶段到 full 但没触发 full pregrowfn 等于白设（这是原实现 bug 根因之一）

## 压力机制（farmplantstress）
- 压力源：killjoys（杂草/腐烂/花园废料）、family（同种相邻）、overcrowding（过密）、season（季节）、moisture（水分）、nutrients（肥料）、happiness（照料）
- `MakeCheckpoint`：遍历 stressors，当前 stressed=true → stress_points+1；stressed=false（照料好）→ 不加分但**重置回 true**（每阶段都要重新照料）
- `Reset()`：stress_points=0，但**把所有 stressor 置回 true**！只 Reset 不照料 = 下个 checkpoint 全压力爆炸
- **完美照料配方**（催熟出巨大的前置）：
  ```lua
  sp:Reset()
  for name in pairs(sp.stressors) do sp:SetStressed(name, false) end
  ```
  这样每阶段 checkpoint 都 0 压力 → final stress == NONE → 巨大化。每次催熟都要做（每阶段结束 stressor 又变回 true）。
- final stress 档位：<=1 NONE（可巨大）、<=6 LOW（1果2种）、<=11 MODERATE（1果1种）、否则 HIGH（1果0种）

## 腐烂作物
- 腐烂 = stage 6 + `farm_plant_killjoy` + `pickable_harvest_str` tag（MakeRotten(true)）；loot 变 spoiled_food（oversized 腐烂另有 loot_oversized_rot）
- oversized 腐烂后 `StopGrowing()`（不再自播）；普通腐烂 self-sow 回 sprout 但 `no_oversized = true`（永久失去巨大化资格）
- 原版 `dig_up` 挖掉腐烂作物：`lootdropper:DropLoot()`（掉 spoiled_food）+ 播 dig_fx（`dirt_puff`）+ Remove
- **恢复腐烂作物**（旧方案：重置成 sprout 幼苗重新长）：
  ```lua
  g:StopGrowing()                    -- 必须先停，否则 SetStage 后旧 task 残留
  inst.no_oversized = nil            -- 清永久禁巨大化
  inst.force_oversized = nil
  inst._grow_from_rotten = nil       -- 不播 rot_to_sprout 转场
  g:SetStage(2)                      -- sprout：fn 自动清 killjoy tag、移除 pickable、播 sprout 动画
  g:StartGrowing()                   -- 无参会用当前阶段 time 函数重启生长
  ```
- **明生「卜算·生存」腐烂处理最终方案（2026-08-23 定稿）：ROTTEN_MODE 三模式开关，默认 giant**。用户预期来回变过（恢复幼苗→不满意→清掉→又改口→恢复巨大），最终落成文件顶部常量、三种行为并存，boss 验收要哪种改一行：
  ```lua
  -- 腐烂作物处理模式：
  --   "giant"   = 恢复巨大（直接变巨大化成熟作物，可收获）——默认
  --   "remove"  = 清掉（掉落对应种子 + 移除，方便重种）
  --   "restore" = 恢复幼苗（变回 sprout 重新生长）
  local ROTTEN_MODE = "giant"
  ```
  - **giant 模式实现（关键顺序：先跑 full 的 pregrowfn 再 SetStage(full)）**：
    ```lua
    PerfectTend(inst)
    inst.force_oversized = true
    inst.no_oversized = nil
    inst._grow_from_rotten = nil
    g:StopGrowing()
    local full_index = max_stage - 1          -- 普通作物 = 5 (full)
    local full_data = stages[full_index]
    if full_data ~= nil and full_data.pregrowfn ~= nil then
        full_data.pregrowfn(inst, full_index, full_data)  -- MakeStressCheckpoint(true) + is_oversized 判定 → force_oversized=true 生效
    end
    g:SetStage(full_index)  -- full 的 fn：MakePickable(true) 可收获 + 按 inst.is_oversized 播 oversized 动画
    g:StopGrowing()         -- 保持 full 防再腐烂
    ```
    顺序不能反：SetStage(full) 的 fn 里 PlayStageAnim 读 `inst.is_oversized`，先 SetStage 再跑 pregrowfn 会播成 full 动画不是 oversized。
  - **remove 模式**：掉该作物种子 + 移除（贴原版 dig_up，但种子替代烂菜，方便立即重种）：
    ```lua
    if inst.components.lootdropper ~= nil then
        local seed_prefab = "seeds"   -- 默认种子
        if inst.plant_def ~= nil and inst.plant_def.seed ~= nil then
            seed_prefab = inst.plant_def.seed   -- 作物专属种子：carrot→carrot_seeds，randomseed→seeds
        end
        inst.components.lootdropper:SetLoot({ seed_prefab })  -- 必须先 SetLoot 覆盖，腐烂默认 loot 是 spoiled_food
        inst.components.lootdropper:DropLoot()
    end
    -- 播当前阶段 dig_fx（dirt_puff）
    inst:Remove()
    ```
  - **restore 模式**：即上面"恢复腐烂作物"旧方案代码（StopGrowing → 清 no_oversized/force_oversized/_grow_from_rotten → SetStage(2) → StartGrowing）。
- **boss 订单依据（V5.1 §2.4 卜算告示表）**：生存 = "半径 10 格地皮：作物进下一阶段、枯萎恢复、耕地补满三种肥力与水分"——**订单完全没写腐烂作物/巨大化**。字面"进下一阶段"（rotten 的下一阶段 = loopstages 回绕 sprout）对应 restore；giant/remove 都是订单外增强。教训：报价型交付加订单外效果前，先翻订单文档确认有没有条款；boss 严格验收时 restore 最安全，爽点增强属订单外。
- 教训：腐烂作物这类"废料状态"物品，玩家对工具类道具的预期是**清掉/恢复成有用状态**，不是"救活成幼苗重新等"——且预期会变，做成可切换模式比钉死一种行为稳妥。

## 推进阶段（催熟）
- **正确姿势：`growable:DoGrowth()`** —— 内部 GetNextStage → 调**下一阶段**的 pregrowfn → SetStage → 未到最终阶段时自动 StartGrowing() 续期
- 手写 `stages[current].pregrowfn(inst)` + `SetStage(current+1)` 是错的：调的是当前阶段 pregrowfn，full 的判定 pregrowfn 永远不触发
- `DoGrowth()` 在 stopped 状态（targettime==nil 且 pausedremaining==nil）直接 return false —— 先 `StartGrowing()` 或 `Resume()` 再 DoGrowth

## 推进失败的排查（2026-08-23 实测补）
- **别用 `current == max_stage - 1` 判断"成熟/full"**：阶段数因植物而异（农场作物 6、randomseed 2、evergreen 树 4）。randomseed 的 seed(1/2) 和 evergreen 的 med(3/4) 都会命中 `max_stage-1` 被误判成 full 分支 → StopGrowing 拦截 → 表现为"催熟不进阶段、树停在 3/4"。**按阶段名判断**：`current_data.name == "full"` 走巨大化分支、`== "rotten"` 走恢复分支，其余一律 DoGrowth；非 farm 植物/最终形态用 `current >= max_stage` 跳过（randomseed 的 sprout 是最终形态，DoGrowth 会重复 ReplaceWithPlant 换实体，必须跳过）。
- `StartGrowing()` 可能**静默启动失败**：若当前阶段 timefn 返回 nil，`targettime` 不会被设置，随后的 `DoGrowth()` 因 fully stopped 直接 return false → 表现为"催熟没反应"。用 `g:IsGrowing()` 判断不可靠，直接查 `g.targettime` / `g.pausedremaining`。
- **DST mod 脚本不热更新**：进世界时一次性加载，改完 lua 必须退回主菜单重进世界（或重启游戏）才生效。用户报"还是不行"时先看日志里 print 格式/新日志是否出现，确认加载的是新版文件再排查逻辑。
- 各阶段 timefn：seed=GetGerminationTime（`grow_time.seed` 表）、sprout/small/med=GetGrowTime（`grow_time` 同名 key，{min,max} 表；farmplantstress 缺失时也返回 nil）、full=GetSpoilTime（`grow_time.oversized`）、rotten=GetSelfRegrowTime（`grow_time.regrow`）。
- **full 的 `grow_time.full` 是数字不是 {min,max} 表**——GetGrowTime 对它取 `[1]/[2]` 会得 nil（full 阶段实际不走 GetGrowTime，但别套用该函数）。
- 随机种子 `GROWTH_STAGES_RANDOMSEED` 只有 2 阶段（seed/sprout）：`current >= max_stage` 会把 sprout(2/2) 当"腐烂"分支 SetStage(2) 原地重置 → 看起来"不进阶段"，其实 sprout 已是随机种子的最终形态。
- 调试姿势：加 `print("[tag] stage/growing/paused/targettime/loopstages + DoGrowth 返回值")`，主机档日志在 `文档\Klei\DoNotStarveTogether\client_log.txt`。

## 原版魔法生长（参考，勿直接抄）
- farm_plant 自带 `domagicgrowthfn` + `magicgrowable = true`；`growable:DoMagicGrowth(doer)` 触发
- 逻辑：`no_oversized = true`（**原版设计：魔法生长不能巨大化**）→ 每 3+random 秒 DoGrowth 一次直到长完；支持 `magic_growth_delay` 延迟
- mod 要"催熟+巨大化"就用完美照料 + force_oversized + DoGrowth 组合，别直接挂 domagicgrowthfn

## 特效/音效资源
- `farm_plant_happy` / `farm_plant_unhappy`：照料成功/失败绿光（prefab，SpawnPrefab + SetPosition 即可，自动消失）
- `dirt_puff`：翻土/阶段切换尘土（dig_fx）
- 巨大化音效 `farming/common/farm/grow_oversized`；动画名：`oversized` / `full` / `rot` / `rot_oversized` / `rot_to_sprout`
- 通用施法圈：`reticuleaoe`（治疗圈，0.5s 后 Remove）
- **引擎噪音别误判（2026-08-23 实测）**：播 `oversized`/阶段动画时日志可能出现 `Could not find anim [FROMNUM] in bank [farm_plant_xxx]`（DST 动画系统内部占位动画名）和 `FMOD Error: Can't play event 'farming/common/farm/grow_oversized'`（该事件在当前 build 不存在，只是没音效）。
- **⚠️ 但 FROMNUM 报错是危险信号：别用 `AnimState:PlayAnimation("oversized")` 直接播**。farm_plant 的 bank 里没有裸 `oversized` 动画（原版 PlayStageAnim 用的是 `grow_oversized` 过渡 + `crop_oversized` 循环）。直接播不存在的动画名会破坏动画链 → **巨大作物的贴图与碰撞体积消失，无法直接采摘**（测试报告实测，2026-08-23 修复）。正确写法：
  ```lua
  if inst.is_oversized then
      inst.AnimState:PlayAnimation("grow_oversized", false)
      inst.AnimState:PushAnimation("crop_oversized", true)
  end
  ```
  FROMNUM 错误出现 = 用了 bank 里没有的动画名，优先检查动画名而不是当噪音忽略。
- **已巨大化作物重复催熟别重播动画（2026-08-23 补）**：full 分支每次都执行 pregrowfn + 播 grow_oversized，已巨大化的作物每用一次道具就闪一次成长动画（用户报"重复播放贴图"）。修复：进入 full 分支时先记 `local was_oversized = inst.is_oversized == true`，pregrowfn 重算后再 `if inst.is_oversized and not was_oversized then` 才播动画——只有"刚变巨大"那一下播，重复使用只做 PerfectTend + StopGrowing（保持 full 不腐烂）。
