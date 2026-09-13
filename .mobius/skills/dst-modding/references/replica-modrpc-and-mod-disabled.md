# DST replica / ModRPC / 环境严格模式 / "mod 被禁用"连锁崩溃

本文件记录 2026-09 Musha 面板"不显示"→"人物文件不加载"整条排障链，全是可复用结论。

## 1. 客户端 replica 没生效 → UI 读不到数据（面板全空）
- 只 `AddComponent("xxx_component")` 不够。客户端要有 `inst.replica.xxx_component`，
  modmain 必须调 **`AddReplicableComponent("xxx_component")`**（放在组件注册之后）。
- 缺失症状：`inst.replica.xxx_component` 恒 nil；所有读 replica 的 UI（面板/状态卡）全空白，
  但服务端日志**无报错**，极难从行为定位。
- 实测：musha 重写 modmain 时漏了这行 → 整个职业面板空白。修复：`git show HEAD:modmain.lua | grep AddReplicableComponent`
  对比 git 备份版找回（备份版有、重写版漏）。
- 命名：组件 `foo` ↔ `scripts/components/foo_replica.lua`；客户端靠 `_foo` tag 触发
  `EntityScript:ReplicateEntity()` 自动挂载 replica（见 entityreplica.lua）。
- replica 文件内用 `net_string(inst.GUID, "name", "dirty_event")`；客户端监听 dirty → 解码缓存进
  `replica.cached_data`，UI 再读 cached_data。
- 数据流：服务端 `pc.userdata` → `replica:DoUpdata(userdata)`（内部 json.encode→net_string:set）
  → 全端 dirty → UI 刷新。

## 2. ModRPC 正确 API（写错会静默/报 lower 错）
- `AddModRPCHandler(namespace, name, fn)` —— **3 个参数**。只传 2 个（name, fn）时，fn 被当成 name，
  报 `bad argument #1 to 'lower' (string expected, got function)`（networkclientrpc.lua 的 __index_lower）。
  该错误被 `Safe()` 包住时只打印一行 `[Mod ERROR] RPC注册: ...`，不崩但 RPC 全失效。
- 取句柄：**`GetModRPC(namespace, name)`**。DST **没有** `GetModRPCIndex`（过时/臆造 API，调用即错）。
- 发送：`SendModRPCToServer(GetModRPC("modname","name"), ...)`；
  `player.Network:SendModRPCToClient(GetModRPC("modname","name"), ...)`。
- namespace 一般 = mod 目录名（= modimport 的 modname）。

## 3. modmain 与组件文件的严格模式（strict）
- modmain：`GLOBAL.x = v` 报 `assign to undeclared variable`；裸 `rawset` 不可用；`GLOBAL.rawset`
  在 `setmetatable(env,...)` 之前也不可用。
- **modmain 环境里 `_G` 不可用**（`attempt to index global '_G'`）。全局一律写 `GLOBAL`。
- **组件文件（scripts/components/*.lua）env 既无 `GLOBAL` 也无 `_G`**，也无裸 `rawset`。
  需要全局时在文件顶部 `local _ENV = _G`（部分老文件这么写），否则把逻辑收回 modmain。
- `GetModConfigData` **只能在 modmain 调**（组件里调会 assert：modname must be supplied manually）。
  传配置给组件的正确姿势：modmain 里 `comp.xxx_override = GetModConfigData(...)`，组件读 `self.xxx_override`。
  （试过写全局缓存 `_G`/`GLOBAL`/`rawset` 全部因 strict 失败——不要再用这条路。）

## 4. 缺组件文件 → mod 被整包禁用（"人物文件不加载"根因）
- `AddComponent("不存在的组件")` 抛 `module 'components/xxx' not found`。
- 若抛在 **PrefabPostInit 阶段**（典型：角色 PrefabPostInit），游戏打印
  `error calling PrefabPostInit: <prefab> in mod <mod>` 紧接 **`Disabling <mod> because it had an error.`**
  → 整个 mod 被禁用 → 它注册的 `PrefabFiles`（含角色本身）全部不加载。
- 因此"角色/人物文件不加载"的表层现象，根因常是 mod 早先崩过一次被禁用，**不是角色文件本身坏**。
- 危险改法：把 `if inst.components.X then return end`（早退）改成"缺哪个补哪个"时，
  会第一次真正执行到后面所有 AddComponent —— 里面可能藏着从未被执行过的坏行（本例 musha_rest 组件
  文件从来不存在），一改就炸。改早退逻辑前，先把该分支内所有 AddComponent/modimport 的目标核对一遍。

## 5. 排障套路（先读日志，再猜）
- DST 客户端日志：本机 `D:\Backup\Documents\Klei\DoNotStarveTogether\client_log.txt`。
  grep `ERROR` / `Disabling` / 你的 mod 名。**先读日志定位，比逐条试快一个数量级。**
- 改完 Lua 用 luaparser 语法校验；用户机器在
  `C:\Users\Administrator\AppData\Local\Programs\Python\Python311\python.exe`（系统 Python，非 venv）。
- 批量核对引用存在性：抓出 modmain 里所有 `AddComponent("x")` / `modimport "p"` / `PrefabFiles` 条目，
  逐个 `test -f` 对应路径，一次扫完再进游戏。
