# DST mod 运行环境 / 配置读取 / 数据同步（实测坑，2026-09）

## 1. `_G` 在 mod 沙箱里是 nil，用 `GLOBAL`
modmain.lua 运行在 mod 沙箱环境，**全局表是 `GLOBAL` 不是 `_G`**。
> ⚠️ **组件文件不一样，别照抄这条**：`scripts/components/*.lua` 里连 `GLOBAL` 都是未声明变量
> （strict 直接报 `variable 'GLOBAL' is not declared`），要用**裸顶层符号** `TheWorld`/`STRINGS`。
> 详见 §4.1。
- ❌ `_G.xxx = 1` → `attempt to index global '_G' (a nil value)`
- ✅ `GLOBAL.xxx` / `rawset(GLOBAL, "xxx", v)`
- 历史代码里 `_G.json` 能跑是因为它出现在 `setmetatable(env, {__index = GLOBAL...})` **之后**，
  此时 `_G` 才通过 metatable 解析；在这之前访问 `_G` 必崩。

## 2. modmain 是 strict 模式：新增全局必须 rawset
DST 的 modmain 环境挂了 strict.lua。给不存在的全局赋值会直接报错：
`attempt to assign to undeclared variable 'xxx'`。
- ❌ `GLOBAL.__my_flag = 1`
- ✅ `rawset(GLOBAL, "__my_flag", 1)`，读用 `rawget(GLOBAL, "__my_flag")`
- 这条也解释了为什么老代码 `_G.__musha_open_panel_rpc_index = ...` 看似"能用"——
  它不是赋值给 GLOBAL 的新键，而是写进了 `_G` 指向的那个表（在 setmetatable 之后 `_G` 已可解析）。

## 3. 组件文件里不能直接调 GetModConfigData
```
[string "scripts/modutil.lua"]:35: modname must be supplied manually if calling
GetModConfigData from outside of modmain or modworldgenmain.
```
`scripts/components/*.lua` 不是 modmain/modworldgenmain 环境，`GetModConfigData(key)` 缺 modname 会 assert 崩。
**标准解法：modmain 读一次缓存到 GLOBAL，组件 rawget 读缓存。**
```lua
-- modmain.lua（可放在文件顶部，GetModConfigData 在 modmain 环境合法）
local function CacheConfig()
    local n = GetModConfigData("my_option")
    if type(n) == "number" and n >= 3 and n <= 5 then
        rawset(GLOBAL, "__my_option", math.floor(n))
    else
        rawset(GLOBAL, "__my_option", 4)
    end
end
CacheConfig()

-- scripts/components/xxx.lua
local function GetOption()
    local n = rawget(GLOBAL, "__my_option")
    if type(n) == "number" then return n end
    return 4  -- 兜底默认
end
```
另一条路是 `GetModConfigData(key, ModIndex:GetModActualName(fancyname))`，但缓存法更省事、更少踩坑。

**更稳的第三条路（实测最终采用，推荐）**：modmain 读到配置后，直接写到**目标组件的实例字段**，
组件内读 `self.xxx`。完全绕开 GLOBAL / strict 的所有争议：
```lua
-- modmain 的 InitMushaPlayer 内
local n = GetModConfigData("musha_daily_quest_count")
if type(n) == "number" and n >= 3 and n <= 5 then q.daily_count_override = math.floor(n) end

-- scripts/components/musha_quest.lua
function MUSHA_QUEST:GetDailyCount()
    local n = self.daily_count_override
    if type(n) == "number" and n >= 3 and n <= 5 then return math.floor(n) end
    return 4  -- 兜底默认
end
```

## 4. mod 组件能被 AddComponent 直接加载
`inst:AddComponent("my_action")` 会在 mod 内 `scripts/components/my_action.lua` 找到组件。仓库里已有同类用法
（musha_jobbook 用 musha_action）就说明路径 OK，不必额外 modimport。

### 4.1 ⚠️ 组件文件里**不能用 `GLOBAL`**，要用裸顶层符号（2026-09-10 实测踩坑）
组件文件同样挂了 strict，但 **`GLOBAL` 不是组件 env 的已声明变量**，一读就炸：
```
../mods/musha/scripts/components/musha_profession_component.lua:694:
  variable 'GLOBAL' is not declared
scripts/strict.lua:23 in () ?  (Lua) <21-26>
```
（和 §1 的 modmain 情况**正好相反**：modmain 里写 `GLOBAL.`，组件里写**裸**符号。）
- ❌ 组件里：`GLOBAL.TheWorld` / `GLOBAL.STRINGS` → 崩
- ✅ 组件里：`TheWorld` / `STRINGS` / `SpawnPrefab` / `pcall` → 正常
- 仓库里现成的正确写法：`scripts/components/musha_skillui.lua:140` → `if TheWorld.ismastersim then`
- 踩坑背景：给 `AddExperience` 加"经验倍率"时读 `GLOBAL.TheWorld.components.musha_world_settings`，
  玩家每天升级（`worldstate` 的 `isday` 事件 → `AddExperience`）必炸，表现为**每到天亮就崩一次**。
- 速查：`grep -rn "GLOBAL\." scripts/components/*.lua` 应为**空**；`scripts/rpcs/*.lua` 和
  `modmain.lua` 才是该出现 `GLOBAL.` 的地方。

## 5. Lua 语法校验（无 luac 时的替代）
DST 目录里没有 `luac`，本机 venv 也没装 luaparser。用**系统 Python** 跑：
```bash
"C:/Users/Administrator/AppData/Local/Programs/Python/Python311/python.exe" - <<'PYEOF'
from luaparser import ast
for f in [r"modmain.lua", r"scripts\components\musha_quest.lua"]:
    code = open(f, encoding="utf-8", errors="replace").read()
    try:
        ast.parse(code); print(f, "SYNTAX OK")
    except Exception as e:
        print(f, "ERROR:", e)
PYEOF
```
（luaparser 4.1.0 装在系统 Python；hermes venv 里没有，execute_code 沙箱也没有。）

## 6. 服务端 → 客户端面板数据同步（replica 模式）

### 6.0 铁律：`AddReplicableComponent("xxx")` 必须在 modmain 顶层调用
mod 组件要在客户端存在 replica，**必须在 modmain 顶层调用 `AddReplicableComponent("组件名")`**
（放在所有 AddComponent 之后、`scripts/components/xxx_replica.lua` 与组件同名 + `_replica` 后缀）。
- 少了这行 → 客户端**根本不会创建** `inst.replica.xxx` → 所有读 `inst.replica.xxx` 的 UI 永远拿到 nil
  → 表现为「面板/UI 完全不显示数据」，而且**日志里没有任何报错**，极难排查。
- 实测坑：modmain 大重写时漏掉一行 `AddReplicableComponent("musha_profession_component")`，
  职业面板整块空白（职业名/等级/经验/任务全空），控制台零报错。
- 秒查手法：跟 git 历史对比 `git show HEAD:modmain.lua | grep AddReplicableComponent`；
  或直接 `grep -c AddReplicableComponent modmain.lua`，数量应 ≥ replica 组件数。
- 机制（entityreplica.lua）：`REPLICATABLE_COMPONENTS` 白名单只有原版组件；mod 组件靠
  `AddReplicableComponent` 加进白名单，之后 `AddComponent` 里的 `ReplicateComponent` 才会给实体打
  `_组件名` tag 并在客户端生成 replica。

### 6.1 诊断顺序：「UI 不显示」先查 replica，再查字段
面板不显示时的排查优先级（省几十轮猜测）：
1. `grep AddReplicableComponent modmain.lua` —— 有没有漏注册（最快命中）。
2. 面板读的字段名 vs 组件实际写入的字段名 —— 重构后常见「面板还在读已废弃字段
   `quests_for_advance`，组件已改写成 `daily_quests`」→ 恒为空。
3. 组件是否真的被 AddComponent 到玩家身上（modmain 的 InitMushaPlayer 里）。
4. 服务端是否调过 `replica:DoUpdata(...)` 推过至少一次数据。
5. 最后才怀疑 netvar/dirty 链路。

musha 这套用 net_string + dirty 事件：
- 服务端组件改 `self.userdata` 后，调 `pc.inst.replica.musha_profession_component:DoUpdata(pc.userdata)`
  （DoUpdata 内部 `self.gamedata:set(json)`），netvar 变化自动给全端发 `gamedata_dirty`。
- 面板 widget 监听 `gamedata_dirty` → 从 `replica.cached_data.userdata` 读。
- 组件 `Class(function(self,inst) ... end, nil, {userdata = DoUpdata, ...})` 的第三个参数是
  **props 表**（不是事件表），别以为能 `pc:DoUpdata()`——直接用 replica 那条路径最稳，
  并套 `pcall(function() ... end)` 防单机/无 replica 时炸。
- 新增字段后旧字段要清空（`pc.userdata.old_field = {}`）避免面板读到过期数据。

## 7. 调试入口
- **client_log.txt 路径（本机实测）**：`D:\Backup\Documents\Klei\DoNotStarveTogether\client_log.txt`
  （Klei 文档目录在 D 盘 Backup 下，不是 `C:\Users\...\Documents\Klei`；`find /c /d -iname client_log.txt` 定位）。
- 用户报「不显示 / 崩了 / 某个功能没反应」这类模糊症状时，**先自己读 client_log.txt**，
  不要反问用户要信息（用户极简沟通，反感被反问）。`grep -n "Musha\|LUA ERROR" client_log.txt | tail`。
- 聊天命令（本 mod 内已有 `/musha`）可以打印服务端真实状态，是验证"数据有没有生成"的最快手段，
  比反复截图快。日志里 `[Musha TRACE] ...` 是定位加载阶段崩溃的探针，保留。

## 8. ModRPC 正确签名（旧代码常写错，报错很难懂）
```lua
-- ✅ DST 官方签名：3 个参数 (namespace, name, fn)
AddModRPCHandler("musha", "musha_skill_upgrade", function(player, skill_id) ... end)
-- ✅ 取 RPC id 表：GetModRPC(namespace, name)
SendModRPCToServer(GetModRPC("musha", "musha_skill_upgrade"), skill_id)
player.Network:SendModRPCToClient(GetModRPC("musha", "musha_data_update"), json_str)
```
- ❌ `AddModRPCHandler("musha_skill_upgrade", fn)`（只传 2 参）→ namespace 被当成 fn，
  报 `networkclientrpc.lua:1809: bad argument #1 to 'lower' (string expected, got function)`——
  报错点在引擎里，跟你的 mod 行号完全无关，看着莫名其妙。就是参数少了一个。
- ❌ **`GetModRPCIndex` 不是 DST API**（凭空杜撰的），正确是 `GetModRPC(namespace, name)`。
- ⚠️ `AddModRPCHandler` 一定要在 `Safe()`/pcall 里包着注册，一个写错会让后面所有 RPC 都注册不上
  （实测：第 1 个 handler 报错后，整个 RPC 块 abort，技能面板/加点全链路失效）。
- 在组件文件里用 RPC：文件顶部 `local _ENV = _G` 之后可直接用 `GetModRPC`/`SendModRPCToServer`；
  在 modmain 里用 `GLOBAL.` 前缀。

## 9. 玩家初始化早退陷阱（旧档玩家不补新组件 / 新逻辑不跑）
`AddPrefabPostInit("musha", InitPlayer)` 里如果写了「组件已存在就 return」这种早退：
```lua
if inst.components.musha_profession_component then return end   -- ❌ 整段初始化被跳过
inst:AddComponent("musha_profession_component")
inst:AddComponent("musha_quest")     -- 旧档永远补不上这个
inst:AddComponent("musha_rest")
```
后果：**新加的组件/初始化逻辑对旧存档玩家永远不生效**，表现为「以前能跑的档现在新功能没反应」，
且没有任何报错（就是安静地 return 了）。
- ✅ 正确写法：逐个组件按需补加，初始化逻辑用实例标志位防重入：
```lua
if not inst.components.musha_profession_component then inst:AddComponent("musha_profession_component") end
if not inst.components.musha_quest then inst:AddComponent("musha_quest") end
-- 注意：只补「文件确实存在」的组件，见下方 9.1

local q = inst.components.musha_quest
if q and not q._daily_inited then
    q._daily_inited = true
    inst:DoTaskInTime(1, function() if q.inst:IsValid() then q:OnNewDay() end end)
end
```

### 9.1 `AddComponent("xxx")` 的组件文件必须存在，否则整个 mod 被禁用
把「早退 return」改成「缺就补」之后，**每一行 AddComponent 都会真的执行**——包括那些写在
`first_time` 分支里、旧档从来没走到、因此从来没验证过的行。如果 `scripts/components/xxx.lua`
不存在（功能已废弃但代码没删），后果不是那个功能报错，而是**整个 mod 被游戏 disable**：
```
error calling PrefabPostInit: musha in mod musha: [string "scripts/entityscript.lua"]:54:
module 'components/musha_rest' not found:
  no file '../mods/musha/scripts/components/musha_rest.lua' (checked with custom loader)
Disabling musha (Musha 0.7.6 职业系统重制版) because it had an error.
```
- 实测坑：`musha_rest` 组件文件从来不存在（休息技能废弃、`musha_rest_enabled` 默认关），
  但那行 `AddComponent("musha_rest")` 一直躺在 `first_time` 分支里没人碰；改成「缺就补」后立刻炸。
- ✅ 改这类初始化块之前，**先把每个 AddComponent 的目标文件核对一遍**：
```bash
for c in $(grep -o 'AddComponent("[a-z_]*")' modmain.lua scripts/prefabs/*.lua | sed 's/.*AddComponent("//;s/")//' | sort -u); do
  [ -f "scripts/components/$c.lua" ] && echo "  OK   $c" || echo "  缺失 $c"
done
```
  同样的核对适用于 `modimport "..."` 目标、`PrefabFiles = {...}` 目标、`require "components/..."`。
  完整脚本见 `scripts/mod_ref_audit.sh`（一把梭审计全部引用）。
- 旧代码里靠「早退 return」掩盖起来的死引用，只有在放宽早退时才会暴露——放宽早退 = 解除掩护，
  务必同步清理或补全引用。
- 注意区分两类「不跑」：① **OnLoad 型**——组件 OnSave 返回 nil / 旧档没存过该组件数据时，
  DST **不会调用 OnLoad**，所以把补发逻辑只写在 OnLoad 里也会静默失效；补发/自愈逻辑要放在
  InitPlayer 这种每局必跑的地方，而不是只放 OnLoad。
- 加 `print` 探针确认走了哪条分支（`first=false` 说明走了补加路径），日志一读就知道。
- **症状 → 根因映射**：一个失败的 PrefabPostInit 会 disable **整个 mod**，所以用户可能把症状描述成
  「人物文件不加载」「mod 像根本没装」「角色/物品全没了」——这些全是同一级联，根因永远是最上面那条
  PrefabPostInit 报错（顺着 `../mods/<mod>/modmain.lua(N,1)` 那行往回找）。别去查「人物 prefab 文件本身」
  或 PrefabFiles 配置，那多半没问题。修复后必须让用户**重进游戏**再取日志——日志时间戳早于改动时间的
  的就是旧崩溃，不要拿来当新证据（实测踩过：用户贴的 modmain.lua:186 报错是我已删除那行的旧日志）。

## 10. 工作流约定（用户明确要求）
- **测试用临时值**：为测试临时改的数值（每日任务数、上限、开关）必须在代码里用
  `⚠️ 测试用临时值 / 正式发布前改回` 注释标明常量（例：`local TEST_DAILY_COUNT = 8`，正式跑时置 `nil`
  回落配置），并在 `musha-backlog.md` 记一条 `→ 正式发布前必须改回`。用户会明确说"更新时改回去"，
  漏改算事故。
- **"照搬 X" = 先读 X 再动手**：用户说参考/照搬某个已实现功能（如明生）时，**先读那份实现**，
  不要手搓近似品；手搓前也要主动给出"照搬参考实现"的选项——用户会怪你"应该早说"。
- **UI 坐标微调**：用户习惯一条条给数值（"右移12 上移8"），一次改完，别边改边问。
- **模糊症状先读日志**：用户说"不显示/崩了"时先自己读 `client_log.txt`（见 §7），不要反问。

---

## 11. UI 相关坑 → 单独一份

`references/dst-ui-gotchas.md`（2026-09 实测）：
1. **Text 左对齐光 `SetHAlign` 无效**，必须配 `SetRegionSize`（否则文字绕自己中心摆 → 看着像居中/参差）。
2. **ImageButton `SetScale` 会被 hover 的 `focus_scale` 覆盖** → 要设 `scale_on_focus = false` + 两个 scale 表；
   且 `SetScale` 连子节点文字一起缩。
3. **混合形态容器表**（可能是 Widget 也可能是 widget 数组）遍历前必须判类型，
   否则对单个 Widget 做 `ipairs` 循环体一次不执行 → 页面永远不显示且**零报错**。
4. 多页切页只 Show/Hide 不重建 Screen；切回主页要补 `Refresh()`。
5. 局内设置组件的最小落地（`AddPrefabPostInit("world"/"forest"/"cave")`、设置快照塞进已有 userdata 副本、
   `player.Network:IsServerAdmin()`、bool 传 1/0）。
6. UI 微调类任务的交互偏好（只改点名的元素、扩缩要说明按哪种理解算、同音错字按最可能意思做完+说明假设）。
