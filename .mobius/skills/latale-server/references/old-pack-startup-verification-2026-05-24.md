# 旧版 2017 服务端包 (D:\Server) 启动验证

验证日期：2026-05-24（两轮验证）

## 包来源

`D:\Server\` 是一套独立的 2017 年他乡团队第三方编译的彩虹岛服务端运行包。包含：
- VMProtect 加壳的 exe（依赖 CHDS.dll）
- 完整 SPF 资源包（来自 S2 七职业版）
- 彩虹岛樱花网关.exe（中文第三方网关，负责 OSP 认证）

## 初始状态（问题发现）

运行中的旧进程（之前遗留的）：

| PID | 进程 | 端口 | 状态 |
|-----|------|------|------|
| 3036 | 彩虹岛樱花网关 | 5217, 5317 | ✅ 运行 |
| 3368 | LataleLoginServer | 19999 | ✅ 运行，但不断重试连 AS(10020) |
| 6848 | LataleAS | - | 进程存在但端口未绑定 |
| 7336 | LataleMgmtServer | - | 进程存在但端口未绑定 |
| 7360 | LataleLobbyServer | - | 同上 |
| 2668 | LataleBayServer | - | 同上 |

症状：AS/Lobby/BayServer 日志均报 `GLOBAL_SYS.LDT : FAILED!`，LoginServer 每秒重试连 10020 端口。

## 根本原因：ResourceDir 路径损坏

`configure.ini` 和 `configure_share.ini` 中的所有 `ResourceDir` 指向 `D:\彩虹岛\Server\SPF\`。

问题：INI 文件是 GBK 编码，但"彩虹岛"三个中文字符被错误保存为 UTF-8 编码（每个汉字 3 字节 = `\xef\xbf\xbd`，共 15 字节表示 3 个汉字）。exe 读取时无法识别该路径。

实际文件内容（二进制）：
```
D:\<5个EFBFBD>\Server\SPF\
```

### 修复方法（二进制替换）

不能用文本编辑器或字符串正则——字符已损坏。必须按字节精确替换：

```python
old_path = b'D:\\' + b'\xef\xbf\xbd' * 5 + b'\\Server\\SPF\\'
new_path = b'D:\\Server\\SPF\\'

for fname in ['configure.ini', 'configure_share.ini']:
    path = f'D:\\Server\\BIN2\\{fname}'
    with open(path, 'rb') as f:
        data = f.read()
    data = data.replace(old_path, new_path)
    # Also fix: D:\CHD2019\SPF and C:\Server\DATA\
    data = data.replace(b'D:\\CHD2019\\SPF', b'D:\\Server\\SPF')
    data = data.replace(b'C:\\Server\\DATA\\', b'D:\\Server\\SPF\\')
    with open(path, 'wb') as f:
        f.write(data)
```

共修复了 56 处路径。

## 全链路启动验证

### 第一次验证（2026-05-24，无网关）

启动顺序（严格按序）：
1. MgmtServer (10001)
2. AS (10020)
3. LoginServer (19999)
4. LobbyServer (10002)
5. BayServer (10006)
6. RoomServer (10007)
7. Latalegameserver_101 (20001)

结果：**所有服务启动成功，进程间连接全部建立。**

连接拓扑：
```
MgmtServer(7256:10001) — 枢纽
  ├─ AS(15580:10020)           → 连 Mgmt(54495→10001)
  ├─ LoginServer(1656:19999)   → 连 AS(63739→10020)
  ├─ LobbyServer(10084:10002)  → 连 Mgmt(31638→10001)
  ├─ BayServer(7388:10006)     → 连 Mgmt(64701→10001) — 但向 5317 发 SYN_SENT
  └─ RoomServer(16352:10007)
  └─ GameServer(688)           → 进程活着但不绑 20001
```

GameServer 内存约 25MB，Responding=True，但 netstat 无 20001 LISTEN。原因：GameServer 需要等网关 OSP 握手完成后才注册到 MgmtServer。

### 第二次验证（2026-05-24，有网关）

启动顺序：
1. 彩虹岛樱花网关.exe（PowerShell Start-Process）
2. MgmtServer → AS → LoginServer → Lobby → Bay → Room → GS

结果：**全套 8 个进程全部运行，进程间连接全部 ESTABLISHED。**

```
网关(7192:5217,5317,19730)
  ├─ 5217 — LoginServer  ✅ ESTABLISHED (OSPMode=7 OSP 通道)
  └─ 5317 — BayServer     ✅ ESTABLISHED

LoginServer(5404:19999) → 网关(11144→5217) ✅
                        → AS(11143→10020)   ✅

AS(14360:10020) → MgmtServer(11088:11136→10020) ✅

MgmtServer(11088:10001) → AS(14360:10020)  ✅
                         → Lobby(11084:11148→10001) ✅
                         → Bay(10548:11152→10001)    ✅

RoomServer(12156:10007)
Latalegameserver_101 — 进程活着但未绑定 20001
```

关键 netstat 数据（确认全通）：
```
TCP    0.0.0.0:5217           0.0.0.0:0              LISTENING       7192
TCP    0.0.0.0:5317           0.0.0.0:0              LISTENING       7192
TCP    0.0.0.0:10001          0.0.0.0:0              LISTENING       11088
TCP    0.0.0.0:10002          0.0.0.0:0              LISTENING       11084
TCP    0.0.0.0:10006          0.0.0.0:0              LISTENING       10548
TCP    0.0.0.0:10007          0.0.0.0:0              LISTENING       12156
TCP    0.0.0.0:10020          0.0.0.0:0              LISTENING       14360
TCP    0.0.0.0:19999          0.0.0.0:0              LISTENING       5404
TCP    127.0.0.1:11144        127.0.0.1:5217         ESTABLISHED     5404   # Login→网关 OSP
TCP    127.0.0.1:11143        127.0.0.1:10020        ESTABLISHED     5404   # Login→AS
TCP    127.0.0.1:11136        127.0.0.1:10020        ESTABLISHED     11088  # Mgmt→AS
TCP    127.0.0.1:11148        127.0.0.1:10001        ESTABLISHED     11084  # Lobby→Mgmt
TCP    127.0.0.1:11152        127.0.0.1:10001        ESTABLISHED     10548  # Bay→Mgmt
TCP    127.0.0.1:11151        127.0.0.1:5317         ESTABLISHED     10548  # Bay→网关
```

**LoginServer trace 确认 OSP 握手成功**：
```
[2026/05/24 10:55:42] OSP Return : [12] [* 3 200 O ]
```
`200 O` = OSP 认证成功。

网关日志来自旧 log（2026-05-24 第一次启动）：
```
10:39:48  【樱花初始化】1.获取数据库信息
10:39:49  【樱花初始化】2.数据库连接成功
10:39:51  【樱花初始化】5.获取网关数据 获取完成
10:39:52  【樱花初始化】6.获取表格完成
10:39:53  【游戏返回】登陆服务器 反馈成功
10:39:56  全部初始化完成！
10:39:56  秒表线程i 创建成功
10:42:04  【游戏回复登陆成功】账号|Ciel|IP|127.0.0.1|端口|2333
```

## 关键发现

### 1. 启动顺序是强约束

MgmtServer 必须先启动。LoginServer 连 AS，AS 再连 MgmtServer。如果 MgmtServer 未就绪，LoginServer 虽然能绑定 19999 端口接受 TCP 连接，但后续查询服务器列表返回空 → 客户端卡"连接中"。

### 2. 网关是登录必备

这套旧包的 LoginServer 在 `configure_share.ini` 中配置了 `OSPMode=7`（自定义 OSP 模式）。LoginServer 启动后会主动连接网关的 5217 端口进行 OSP 认证握手。**没有网关时，客户端 TCP 能连 19999 但认证协议走不通。** LoginServer 日志显示不断重试：
```
FD_CONNECT=[0, 10061] : Dest=[127.0.0.1:5217:...]
```

### 3. 裸连确认不可用

经过两轮验证确认：**旧版 LoginServer 裸连不可用。** 客户端身份认证和会话路由完全依赖网关（彩虹岛樱花网关.exe）。

验证方法：
1. 全套服务（无网关）：客户端打开 LaTale Client 窗口但 TCP 不连 19999
2. 全套服务（有网关）：客户端打开后显示登录界面，输入账号后通过网关路由

LoginServer 的 19999 端口不直接处理客户端登录包——只接受来自网关的 OSP 路由连接。

### 4. 中文路径编码问题

他乡团队版本的 INI 文件包含中文路径，在 GBK 编码下存储时中文字符被损坏。修复必须用二进制字节替换。

### 5. 进程启动工具的已知限制

详见 SKILL.md 主文档的"从终端工具启动 Windows exe 的陷阱"章节。

### 6. GameServer 启动延迟

Latalegameserver_101.exe 启动后进程活着（~25MB）但需要额外时间（或等网关 OSP 握手完成后）才绑定 20001 端口。

### 7. 第二次会话（2026-05-24）的新发现

- **客户端能通过网关进入服务器选择界面**：全套服务（含网关）启动后，用户双击 LaTaleClient.exe，成功看到了服务器列表并进入了选频道的界面。
- **GameServer INVALID SECTION INFO 错误**——详见 SKILL.md 中 `INVALID SECTION INFO` 章节。修复：在 configure.ini 中添加 `[LataleGameServer]` 段（不带 _101 后缀）。
- **`start /B /WAIT` 的迷惑性**：在 git-bash 下用 `cmd.exe //c 'start /B /WAIT exe.exe'` 启动后，cmd.exe 包装器进程会结束（触发 proc_xxx completed 通知），但实际目标 exe 仍继续在后台运行——进程端口绑定不会释放。不要被 completed 通知误导，始终以 netstat 端口状态为准。

## 与编译版的关系

旧包和编译版 (`D:\LaTaleServer-\bin\`) 是两套独立的 exe：
- **旧包**：2017 年他乡团队编译，VMProtect 加壳，依赖 CHDS.dll，配置路径在 D:\Server\
- **编译版**：2026-05-24 从源码 VS2013 /MT 编译，无加壳，配置路径在 D:\LaTaleServer-\bin\

两套可以共存，互不冲突。旧包用来验证网络拓扑和端口配置；编译版是最终替换目标。

## 与编译版 LoginServer 卡登录症状的对比

| 场景 | 旧版 exe（裸连） | 旧版 exe（有网关） | 源码编译版 LoginServer |
|------|-----------------|-------------------|----------------------|
| TCP 连上去 | ❌ 客户端不直连 | ✅ 通过网关路由 | ✅ SessionCount=[1] |
| 能看到登录界面 | ❌ 卡在连接前 | ✅ 显示登录界面 | ✅ 显示登录界面 |
| 能输入账号 | ❌ | ✅ | ✅ |
| 能登录成功 | ❌ | ✅（有网关日志为证） | ❌（卡"连接中"） |

**旧版 exe 有网关时能完整走通**，证明服务端配置（端口、数据库）本身没问题。源码编译版卡登录是独立的问题——KEYLOGIN 本地模式缺失处理（已在源码中修复），或 LataleWorkerThread_Login.cpp（处理旧版协议）缺失导致登录包无人处理。

## 启动最佳实践（2026-05-24 更新）

### 可靠的一键启动脚本（PowerShell）

```powershell
# save as start_all.ps1
$BIN2 = 'D:\Server\BIN2'
$SRV = 'D:\Server'

Write-Host '[1/8] Starting gateway...'
Start-Process -FilePath "$SRV\彩虹岛樱花网关.exe" -WorkingDirectory $BIN2
Start-Sleep -Seconds 12

Write-Host '[2/8] Starting MgmtServer...'
Start-Process -FilePath "$BIN2\LataleMgmtServer.exe" -WorkingDirectory $BIN2
Start-Sleep -Seconds 5

Write-Host '[3/8] Starting AS...'
Start-Process -FilePath "$BIN2\LataleAS.exe" -WorkingDirectory $BIN2
Start-Sleep -Seconds 3

Write-Host '[4/8] Starting LoginServer...'
Start-Process -FilePath "$BIN2\LataleLoginServer.exe" -WorkingDirectory $BIN2
Start-Sleep -Seconds 1

Write-Host '[5-8/8] Starting Lobby/Bay/Room/GS...'
Start-Process -FilePath "$BIN2\LataleLobbyServer.exe" -WorkingDirectory $BIN2
Start-Process -FilePath "$BIN2\LataleBayServer.exe" -WorkingDirectory $BIN2
Start-Process -FilePath "$BIN2\LataleRoomServer.exe" -WorkingDirectory $BIN2
Start-Process -FilePath "$BIN2\Latalegameserver_101.exe" -WorkingDirectory $BIN2

Write-Host 'Done! Verify with: netstat -ano | findstr "10001 10020 19999 10002 10006 10007"'
```

### 端到端验证步骤

```cmd
# 检查所有必要端口都在 LISTENING
netstat -ano | findstr "10001 10020 19999 10002 10006 10007 5217 5317"

# 检查进程间连接（3 个 ESTABLISHED 方向）
netstat -ano | findstr "10001" | findstr ESTABLISHED   → Mgmt↔AS/Lobby/Bay
netstat -ano | findstr "10020" | findstr ESTABLISHED   → AS↔Mgmt/Login

# 检查 LoginServer OSP 握手成功
type D:\Server\BIN2\Log\2026????_Lataleloginserver_Trace.log | findstr "200 O"
# 如果看到 "200 O" → 已连上网关
```

### 常见启动失败模式

| 现象 | 原因 | 修复 |
|------|------|------|
| 10001 不在 LISTEN | MgmtServer 未启动或闪退 | 检查 configure.ini 中所有 ResourceDir 路径有效 |
| 10020 报 GLOBAL_SYS.LDT FAILED | ResourceDir 指向的 SPF 目录不存在 | 二进制替换 INI 中的损坏中文路径 |
| LoginServer 绑了 19999 但连 5217 报 10061 | 网关未启动 | 先启动网关，等 5217 端口出现 |
| GameServer 不绑定 20001 | 网关未就绪或 OSP 握手未完成 | 等 30 秒；确认 trace 有 `200 O` |
| 客户端打开后不连 19999 | 客户端直连不可用 | 必须通过网关路由 |
| cmd 启动中文 exe 报"拒绝访问" | MSYS 参数转义错误 | 用 PowerShell Start-Process |
| GameServer INVALID SECTION INFO | 配置段名不匹配 | 在 configure.ini 中添加 `[LataleGameServer]` 段（不带 _101 后缀） |

### 快速诊断：客户端卡"连接中"

```cmd
# LoginServer 端的 19999 有 ESTABLISHED 连接吗？
netstat -ano | findstr "19999" | findstr ESTABLISHED

# LoginServer 连上 AS 了吗？
netstat -ano | findstr "10020" | findstr ESTABLISHED

# AS 连上 MgmtServer 了吗？
netstat -ano | findstr "10001" | findstr ESTABLISHED

# LoginServer 连上网关了（OSP）？
netstat -ano | findstr "5217" | findstr ESTABLISHED
```

如果第二个或第三个是 SYN_SENT → 上游服务未启动。
如果第四个是 SYN_SENT → 网关未启动。
