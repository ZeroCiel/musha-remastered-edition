# git-bash (Hermes terminal) 启动 Latale exe 的致命陷阱

## 症状

用 `cmd.exe //c 'start /B LataleXXX.exe'` 启动后，**所有后续 terminal 调用立即返回 `[Command interrupted] exit_code=130`**，即使是 `echo test` 这种简单命令也不行。`process(action='list')` 显示空列表。整个 Hermes 会话不可恢复。

## 根因

`cmd.exe //c` 在 git-bash/MSYS 下通过 CreateProcess 创建 cmd.exe 包装器。`start /B` 在 cmd.exe 中创建子进程后立即返回，但 cmd.exe 退出时 MSYS 的 subprocess 跟踪机制被破坏（句柄泄漏或 fork 状态损坏），导致当前 shell 永久失去响应。

## 正确做法

### ✅ 直接 background（首选）
```bash
terminal(command="./LataleMgmtServer.exe", background=true)
terminal(command="./LataleAS.exe", background=true)
```
大部分 2022 版他乡 exe 可以直接在 git-bash 下以 background 模式启动，不需要 cmd.exe 包装。

### ✅ cmd.exe 包装 + background（备选）
如果 exe 不支持直接 background（需要 cmd.exe 环境如 CHDS.dll 依赖），用：
```bash
terminal(command="cmd.exe //c 'start LataleXXX.exe'", background=true)
```
这样 cmd.exe 本身也是后台进程，不会破坏 git-bash。

### ❌ 绝对不要用
```bash
terminal(command="cmd.exe //c 'start /B LataleXXX.exe'")  # 前台 — 会卡住
terminal(command="cmd.exe //c 'start /B LataleXXX.exe'", background=true)  # 后台 — 搞死git-bash
```

## 发生后的恢复

一旦终端被搞死，无法在当前会话恢复。需要：
1. 用户手动关闭 Hermes（/exit 或关闭窗口）
2. 重新启动 Hermes
3. 所有临时 terminal 状态丢失

所以**务必避免** `start /B` 这种写法。
