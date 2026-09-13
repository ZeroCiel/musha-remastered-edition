# S2 Server2 目录迁移（2026-05-28）

## 背景

用户创建了一个新的 S2 服务端副本 `D:\LaTale\Server2\`，从旧版包（原在 D:\Server\）复制或重新配置而来。

## 目录结构

```
D:\LaTale\Server2\
├── BIN2\                    # 服务端exe (2022-06-06版，他乡CHD版)
│   ├── LataleMgmtServer.exe    (498KB, 2022-06-06)
│   ├── LataleAS.exe            (498KB, 2022-06-06)
│   ├── LataleLoginServer.exe   (2.1MB, 2024-05-24 自编译版)
│   ├── LataleLobbyServer.exe   (2.1MB, 2022-06-06)
│   ├── LataleBayServer.exe     (361KB, 2022-06-06)
│   ├── LataleRoomServer.exe    (350KB, 2022-06-06)
│   ├── Latalegameserver_101.exe (2.68MB, 2022-06-06)
│   ├── configure.ini
│   ├── configure_share.ini
│   └── CHDS.dll / apphelp.dll / 其他运行时DLL
├── resource\                # 空目录
├── SPF\                     # 解包后的SPF目录
│   ├── ROWID.SPF            # 文本数据包
│   ├── BARY.SPF             # UI包
│   └── ...其他SPF
├── 彩虹岛樱花网关.exe        # 5.1MB (2021-09-22)
├── 一键启动服务.bat          # 路径写死 D:\Server\BIN2
└── 停止服务.bat
```

## 启动脚本路径修复

一键启动服务.bat 和 start_server.bat 都写死了 `cd /d D:\Server\BIN2`。迁移后需要改为：

```bat
cd /d D:\LaTale\Server2\BIN2
```

同时也改了 `start "" "D:\Server\彩虹岛樱花网关.exe"` → `start "" "D:\LaTale\Server2\彩虹岛樱花网关.exe"`。

## configure.ini 路径批量替换

两个 INI 文件中有约 50 处 `resourceDir = D:\Server\SPF\` 需要替换为 `D:\LaTale\Server2\SPF\`。

**替换方法（Python/patch，replace_all=True）：**

```python
# configure.ini — 24处
patch("configure.ini", "D:\\Server\\SPF\\", "D:\\LaTale\\Server2\\SPF\\", replace_all=True)
# configure_share.ini — 26处
patch("configure_share.ini", "D:\\Server\\SPF\\", "D:\\LaTale\\Server2\\SPF\\", replace_all=True)
```

另外有一行特殊情况：`ResourceDir= D:\Server\SPF文件\`（含乱码中文字"文件"）— 也需要修正。

**替换后验证：** `search_files(pattern="D:\\Server", file_glob="*.ini")` 应返回 0 条。

## 网关启动

- 彩虹岛樱花网关.exe 是 GUI 程序，不能通过 git-bash terminal 启动
- 必须让用户手动在 Windows 桌面双击
- 确认就绪：`netstat -ano | grep ":5217 "` 显示 LISTENING

## 后台服务启动（从 Hermes terminal 用 background 模式）

与旧包不同，这次的 exe 可以直接在 git-bash 下以 background 模式启动（不需要 cmd.exe /c 或 PowerShell）：

```bash
cd /d/LaTale/Server2/BIN2
./LataleMgmtServer.exe       # background mode ✅
./LataleAS.exe                # background mode ✅
./LataleLoginServer.exe       # background mode ✅
./LataleLobbyServer.exe       # background mode ✅
./LataleBayServer.exe         # background mode ✅
./LataleRoomServer.exe        # background mode ✅
./Latalegameserver_101.exe    # background mode ✅
```

**注意：** 前台模式 (`terminal` 不带 background) 运行这些 exe 会导致 git-bash 卡住/Ctrl+C 中断。必须使用 `background=true`。

**⚠️ 绝对不要用 `cmd.exe //c 'start /B LataleXXX.exe'`** — 这会启动一个 cmd.exe 包装器进程，git-bash 终端会被这个包装器搞死（后续所有 terminal 调用返回 [Command interrupted] exit_code=130），必须重置整个 Hermes 连接才能恢复。正确做法是 `terminal(command="./LataleXXX.exe", background=true)` 直接启动 exe。如果 exe 在 background 模式下也不工作，可以用 `cmd.exe //c 'start exe.exe'` 包装后以 background 模式运行——这会开独立窗口但 git-bash 不卡死。

**启动顺序：** MgmtServer 必须第一个启动（其他服务连它的 10001 端口注册）。

## 端口对照

| 服务 | 端口 |
|------|------|
| 网关 OSP | 5217 |
| 网关商城 | 5317 |
| MgmtServer | 10001 |
| AS | 10020 |
| LoginServer | 19999 |
| LobbyServer | 10002 |
| BayServer | 10006 |
| RoomServer | 10007 |
| GS 101 | 20001 |

## Server2 与旧 D:\Server 的差异

| 方面 | D:\Server\ (旧) | D:\LaTale\Server2\ (新) |
|------|----------------|------------------------|
| exe 版本 | 2017原始版 (VMProtect) | 2022-06-06 他乡CHD版 |
| 路径问题 | INI乱码中文路径+ResourceDir指向D:\Server | INI中ResourceDir指向D:\Server\SPF (写死) |
| Gateway | 从PowerShell Start-Process可启动 | 同样需要用户手动双击 |
| 修复量 | 56处乱码路径替换 | 50处ResourceDir替换 |
| LoginServer | 旧版exe (OSPMode=7) | 有自编译版 (OSPMode=0? 待确认) |

## 关键经验

1. 迁移S2他乡包到新目录时，**核心动作是两个 INI 文件的 ResourceDir 批量替换** — 这是最常见的故障点
2. 启动脚本（.bat）也写死了旧目录路径 — 需要一并修复
3. Gateway（彩虹岛樱花网关）**不能**从 git-bash 启动 — 让用户手动双击
4. 后台 exe 用 Hermes terminal `background=true` 模式直接启动 `./xxx.exe` 可以正常工作（不同于需要 cmd.exe /c 的旧包）
5. 路径修复后仍报错的排查：检查 configure_share.ini 中 SecurityPath 等非 ResourceDir 路径是否也用了旧目录
