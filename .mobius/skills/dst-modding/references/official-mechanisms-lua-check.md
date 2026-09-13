# DST 官方机制速查 + Lua 验证工具

## 天体改月相（ms_setmoonphase）
- 官方 `components/clock.lua` 已监听 `ms_setmoonphase` 事件（OnSetMoonPhase，`_ismastersim` 才注册）
- 传参：`TheWorld:PushEvent("ms_setmoonphase", {moonphase="new"/"full", iswaxing=true})`
- MOON_PHASES 合法值：new / quarter / half / threequarter / full
- 结论：mod 无需自己写监听，PushEvent 字段正确即生效（评审说"事件无监听"是没查官方代码）
- 注意：客户端无监听，action fn 必须在服务端执行；洞穴献祭可能不同步

## 查理袭击免疫（grue）
- 查理袭击 = `components/grue.lua`（玩家夜晚黑暗袭击），不是独立组件
- 免疫接口：`inst.components.grue:AddImmunity(source)` / `RemoveImmunity(source)`（Winona 技能树同款）
- 抵抗力接口：`inst.components.grue:SetResistance(n)` —— level > resistance 才攻击
  - grue level 从 0 开始，每 5~11s +1，进光/白天重置为 nil
  - SetResistance(1) = 挡第 1 次袭击（resistedgrue），第 2 次起恢复被咬 → 恰好"免疫一次"
- 明生实现：梦魇告示在知天命容器 → `grue:SetResistance(1)`，取出 → `SetResistance(0)`（mingsheng_ztm.lua SetDamage）

## Lua 语法批量验证（Windows 无 luac）
- 系统 Python311：`C:\Users\Administrator\AppData\Local\Programs\Python\Python311\python.exe`
- `pip install luaparser` 后：
  ```python
  from luaparser import ast
  ast.parse(open(path, encoding='utf-8').read())
  ```
- 官方文件（speech_wilson.lua 等）解析 OK 说明工具可靠；报 "syntax errors: None" = 真实语法错误
- 对照法：同时解析官方文件排除误报

## speech 文件批量编辑的坑（python 脚本 replace）
- 替换 `key = "value"` 行时 old_string 必须带行尾逗号，否则把原行逗号吞掉导致下一个字段语法断裂
- 插入块到 `DESCRIBE =` 后时：必须插在 `DESCRIBE =\n{` 的 `{` **之后**（表内），否则字段全在表外
- 注意同名字段重复（如 ANNOUNCE_CRAFTING_FAIL）：后定义覆盖先定义，中文会被后面的英文覆盖
- 改完必须跑 luaparser 全量验证

## 全局配置跨文件传递
- modmain 里定义 `GLOBAL.MINGSHENG_TUNING = ...`（写入真全局）
- prefab 文件（strict 模式）没有 `GLOBAL` 变量名，直接写 `MINGSHENG_TUNING.xxx` 访问（env __index 查全局）
- 配置初始化必须放在 modmain 顶部、任何数值引用（local COOLDOWN_SECONDS 等）之前
