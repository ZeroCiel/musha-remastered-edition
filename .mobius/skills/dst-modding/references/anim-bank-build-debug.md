# DST 动画 bank/build 调试（出现错误的角色动画）

## 症状
mod prefab 显示成错误的角色动画。例如：告示者(gaoshizhe)召唤的仆从出现时是"威尔逊暗影从地爬出"，而它应该用伯尼熊(Bernie)动画。

## 机制（关键）
- `AnimState:SetBank(name)` 加载动画数据文件 `anim/<name>.zip`（游戏 `data/anim/` 或 mod `anim/` 目录）
- `AnimState:SetBuild(name)` 加载同名 zip 里的 build.bin（贴图符号）
- bank 决定动作，build 决定外观。build.bin 由 Spriter SCML 编译，若 SCML 源拿错（如从 wilson 复制改造），build 符号就是 wilson 系 → 模型显示成威尔逊
- bank 名不存在时 DST 会回退默认 bank（wilson），同样表现为"别的角色"的动画

## 排查清单
1. **先验证 bank 名**，不要猜。原版代码位置：
   `grep -rn "SetBank" "D:/SteamLibrary/steamapps/common/Don't Starve Together/data/databundles/scripts/prefabs/bernie*.lua"`
   - 注意：原版 Lua 在 `data/databundles/scripts/`，不是 `data/scripts/`（那里只有 anim/images/sound 资源）
   - 已核实：`bernie_active.lua:131` 和 `bernie_inactive.lua:248` 都是 `SetBank("bernie")`；`bernie_big.lua:634` 是 `SetBank("bernie_big")`
   - 伯尼的 bank 就是 `"bernie"`，别猜成 `"bernnie"`（双 n 是错的）
2. **grep 全部 prefabs 的 SetBank，不要只看物品本体**。召唤物/仆从是独立 prefab：
   `grep -n "SetBank" mods/<mod>/scripts/prefabs/*.lua`
   告示者本体改对后仍见 wilson → 是 `shadow_mingsheng`/`illusion_mingsheng` 仆从还写着 `SetBank("wilson")`（2026-08 实测根因就在这，本体早已是 bernie）
3. **确认 mod 编译 zip 结构**：`unzip -l mods/<mod>/anim/<name>.zip` 应有 anim.bin + build.bin + atlas-0.tex
4. **检查 anim.bin / build.bin 内容**，判断编译源：
   - anim.bin 魔数头 `ANIM`，build.bin 魔数头 `BUILD`
   - git-bash 无 `strings` 命令，用 python re 提取干净标识符：
     `re.findall(rb'[a-z_][a-z0-9_]{2,}', data)`（比 `[ -~]{4,}` 干净，能滤掉二进制噪声）
   - 判定：动画名/符号名是 bernie 系（idle_loop_nodir、bernie_face、swap_bernie 等）说明编译源正确
   - 若 build.bin 符号是 wilson 系（没有 bernie 的 swap_bernie 等符号），说明 SCML 源错了，需拿伯尼的 SCML 重新编译
5. **符号不匹配的补救**：`OverrideSymbol` 换符号（参见 `bernie-and-finiteuses.md` 的 Bernie 黑影全色修复）

## bank 切换完整流程（wilson → bernie 实测）
换 bank 不只是改 prefab 里 SetBank/SetBuild，SG（stategraph）里所有 PlayAnimation 的动画名都要映射到新 bank 的动画集，否则播放不存在的动画会失败/卡状态。

### 伯尼 bank 动画集（bernie.zip anim.bin 实测）
activate / deactivate / dead_loop / death / hit / idle_loop / idle_loop_nodir / inactive / knockback / taunt / walk_loop / walk_pre / walk_pst
- 没有 run_*、atk*、minion_spawn、emoteXL_*、boat_jump_*、idle —— 这些名字在 bernie bank 下会失败
- **普通伯尼没有攻击动画**：攻击只能用 taunt（嘲讽挥动）/ hit 凑合
- **大伯尼 bernie_big.zip 有官方 atk**（SGberniebig.lua:105 实测），还有 run_* 系列、death_pst、sit，build 符号含 body、big_* 系——想要真攻击动作可换 `SetBank("bernie_big")` + `SetBuild("bernie_build")`（外观变大熊），或重编译 mod zip 把 atk 合进现有 build
- 官方攻击动画命名分类（grep 官方 prefabs/SG 统计）：atk 系（atk/atk_pre/atk_pst/atk1-3 连击/atk_loop/atk_leap 跳扑，熊獾 bearger 用 atk/atk1/atk2）、punch 系（punch/punch_a/b/c/toolpunch）、bite 系（bite/bite_light_pre/bite_heavy_pre）、爪击（attack_doubleclaw/swipe）、特殊（attack_book/were_atk/atk_ground_projection/teleport_atk）

### 映射表（wilson 系 → bernie 系）
| wilson | bernie |
|---|---|
| minion_spawn | activate |
| idle / idle_loop | idle_loop（有） |
| run_pre | walk_pre |
| run_loop | walk_loop |
| run_pst | walk_pst |
| atk（近战） | taunt |
| atk_pre + atk（远程） | taunt + hit |
| emoteXL_pre_dance0 | activate |
| emoteXL_loop_dance0 | idle_loop_nodir（循环） |

### prefab 侧改动
- SetBank("wilson") → SetBank("bernie")；SetBuild("mingsheng") → SetBuild("gaoshizhe")（mod 自编译全色伯尼熊 build）
- PlayAnimation("idle") → PlayAnimation("idle_loop_nodir")（bernie 没有 "idle"）
- assets 要加 `Asset("ANIM", "anim/gaoshizhe.zip")`，换掉的旧 zip 加载删掉
- combat.hiteffectsymbol = "body" → "bernie_torso"（伯尼 build 没有 body 符号）

### hop 状态必须删
- `CommonStates.AddHopStates` 用 boat_jump_pre/loop/pst，bernie bank 没有 → 上船必炸
- 原版 SGbernie.lua 没有 OnHop / AddHopStates（伯尼根本不跳船）→ 把 events 里的 `CommonHandlers.OnHop()` 和文件末尾的 hop_timelines + AddHopStates 调用整个删掉

### 坑：批量 patch 相似文件前先读目标文件
两个 SG 结构不完全相同——SGillusion 的攻击事件是自定义 `EventHandler("doattack", ...)`，SGshadow 用的是 `CommonHandlers.OnAttack()`。按 shadow 的结构去 patch illusion 会吞掉 EventHandler 开头行造成 Lua 语法错误。改完必须重新读文件验证 events 表完整。

## 告示者(gaoshizhe)现状记录（2026-08 已修复）
- `mingsheng_gaoshizhe.lua`（本体物品）: `SetBank("bernie")` + `SetBuild("gaoshizhe")` — 正确
- `shadow_mingsheng.lua` / `illusion_mingsheng.lua`（仆从）: 已从 wilson/mingsheng 改为 bernie/gaoshizhe + idle_loop_nodir，SG 动画名按上表映射，hop 已删
- `anim/gaoshizhe.zip` 编译源确认正确：动画名含 idle_loop_nodir/activate 等，build 符号含 bernie_face/swap_bernie —— 不是 wilson 源
- **2026-08 用户拍板：熊不需要保持暗虚影** —— 两个仆从的 `SetMultColour` 覆盖已删（shadow 的 (0,0,0,0.8) 黑化和 illusion 的 (1,1,1,0.6) 半透明都去掉），显示全色伯尼熊；只保留 `SetLightOverride`（暗处可见性，不影响颜色）
