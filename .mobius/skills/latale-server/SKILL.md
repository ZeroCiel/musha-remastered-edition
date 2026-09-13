---
name: latale-server
description: "Complete 彩虹岛 (Latale) private server management — server deployment, database, compilation (VS2012/2013/2022), binary hex-patching, LDT/SPF resource editing, EXE swapping, localization, account registration, gateway configuration, web services, and the skill/learn system (SKILL.LDT / LEARN_SKILL.LDT structure, class/job validation)."
---

# 彩虹岛 (Latale) 私服管理

管理彩虹岛物语私服全套 — 数据库、网关、服务端编译、SPF 合并、常见问题。

## S2/S4 网关数据库连接配置

彩虹岛私服各版本连接 SQL 的方式和配置位置不同，**不匹配是最常见的"服务器连不上"原因**。

### 配置位置

**S2 端** — `Latale_ODBC.ini`（位于 `bin2/` 目录）：
```ini
[AccountDB]
IP = 127.0.0.1,1433      ← 注意：端口必须与 SQL 实际监听端口一致
ID = sa
PW = 123456

[GameDB]
IP = 127.0.0.1,1433
ID = sa
PW = 123456
```

**经验**：如果 SQL Server 实例换了端口（如装了新实例或 LiteSQL 不同版本），`Latale_ODBC.ini` 没同步改端口，S2网关就连不上。见 `references/s2-gateway-port-config.md`。

**S4 端（加密配置）** — `Global_ODBC.inis`（需通过启动器解密，或 INISViewer）
**S4 端（明文配置）** — `Latale_ODBC.ini` 或 `Global_ODBC.ini`

### 端口不匹配排查

SQL Server 实例实际监听端口 ≠ `Latale_ODBC.ini` 中写的端口 → 网关/GS 连不上 SQL，启动后闪退或无响应。

**快速诊断：**
1. 查 SQL 实际监听端口：`netstat -ano | findstr "LISTENING"` 找到 `sqlservr.exe` 的端口
2. 查配置文件中的端口：`grep "IP = " bin2/Latale_ODBC.ini`
3. 不匹配则改 `.ini` 中的端口号（如 `127.0.0.1,59157`）

**命名实例默认端口**：命名实例（如 `JSQL2008`）通常用动态端口，第一次启动时分配。如果改了实例的 TCP/IP 端口，需要确保：
- SQL Server 配置管理器中 TCP/IP 已启用
- IPAll → TCP Port 设定了固定端口而非空（动态端口）
- 重启 SQL 服务后生效

**SQL Browser 服务**：命名实例可以通过 SQL Browser 服务自动发现端口（默认 1434 UDP），但私服环境通常禁用了 Browser 服务，必须手动指定端口。

### 数据库文件跨版本兼容性

| SQL 版本 | master.mdf 数据库版本号 |
|----------|----------------------|
| 2008 R2 (10.50) | 661 |
| 2012 (11.x) | 706 |
| 2014 (12.x) | 782 |
| 2016 (13.x) | 852 |
| 2017+ (14.x) | 869+ |

**规则**：高版本的 mdf **不能**被低版本 SQL 读取。SQL2008 R2 最大支持版本 663，SQL2014 及以上版本的数据库文件（版本 782+）在 2008 上会报错：
```
数据库 'XXX' 的版本为 782，无法打开。此服务器支持 663 版及更低版本。
```

**恢复策略**：要么升级 SQL 实例，要么在兼容版本上用 `BACKUP DATABASE` + `RESTORE` 降级（需高版本→低版本时选择兼容级别并在低版本上 restore）。

## 远程服务器连接（虚拟组网穿透）

远程服务器（云电脑/托管机）通常没有公网端口转发，需通过虚拟组网连接。推荐优先级：**Radmin VPN > EasyN2N > ngrok/frp**。

### Radmin VPN（推荐）

比 N2N 更稳定，UDP 打洞成功率高，P2P 直连延迟低（~100ms 可玩）。

**安装**：https://www.radmin-vpn.com/（英文原版个人免费，中文站是收费版）

**使用**：
1. 两边都装 Radmin VPN
2. 一边创建网络，另一边加入
3. 跑 `ipconfig` 看 Radmin 分配的虚拟 IP
4. 双向 ping 通即连接成功

**Radmin IP 形态**：`26.x.x.x` 段，与 N2N 的 `192.168.x.x` 段不同。

**连接稳定性**：如果 Radmin 能 ping 通但游戏连接 5 秒掉线：
- **首选诊断**：在远程机上本地启动客户端测试（不经过网络）
  - 远程机本地不掉线 → 100% 是网络隧道问题
  - 远程机本地也掉线 → 查服务端配置（`KickOutInterval`、会话表等）
- 可能原因：Radmin UDP 隧道不稳定，游戏维持连接的心跳包丢失。服务端 `KickOutInterval = 10`（秒）配置下，心跳超时就被踢。

**LoginServer IP校验现象**（2026-06-05 发现）：
- `PublicIP=127.0.0.1` → 客户端能上登录窗口，但频道列表为空（客户端拿到127.0.0.1的Lobby连不上）
- `PublicIP=Radmin虚拟IP` → 客户端登录后立刻被踢（LoginServer检测到客户端源IP与PublicIP不匹配）
- 推测：LoginServer在发服务器列表封包时填入PublicIP，后续校验客户端连接来源是否与PublicIP一致
- 绕开方法：保持PublicIP=127.0.0.1，在本机用 netsh 做端口转发
  ```powershell
  netsh interface portproxy add v4tov4 listenport=41470 connectport=41470 connectaddress=26.201.194.1
  ```

### EasyN2N（小黄鸭）穿透方案

### EasyN2N（小黄鸭）穿透方案

**原理**：N2N 虚拟局域网，两端加入同一中转节点和组名，获得虚拟 IP 后互相 ping 通。

**配置要素**：
- 中转节点：`43.138.138.38:40063`（示例）
- 组名（小组名称）：如 `XKGMnq`
- 虚拟IP（可手动指定）：建议手动填写，避免重启后 IP 变化
- 自动分配：取消勾选"自动分配"，手动填 IP

**验证连通**：
```
# 从本地 ping 远程虚拟 IP
ping 192.168.25.240

# 从远程 ping 本地虚拟 IP
ping 192.168.25.238
```

### SSH 连不上时的完整排查（2026-06-05 验证）

**坑：ping 通 ≠ SSH 能连。** 即使两边 EasyN2N 都显示"已连接"且虚拟 IP 能 ping 通，SSH 仍可能被 Windows 防火墙拦截。

**步骤：**
1. 远程机上确认 SSH Server 在运行：
   ```powershell
   Get-Service sshd
   ```
2. 检查 SSH 监听接口：
   ```powershell
   netstat -ano | findstr :22
   ```
   - `0.0.0.0:22` = 监听所有接口（正确）
   - `127.0.0.1:22` = 只监听本地，虚拟网卡连不上
3. 检查 Windows 防火墙规则：
   ```powershell
   netsh advfirewall firewall show rule name=all | findstr /i "ssh 22"
   ```
4. **首选操作：重启 sshd 服务**（比关防火墙更安全、更可能解决问题）
   ```powershell
   Restart-Service sshd
   ```
   **原理**：sshd 在系统启动时绑定到当时的网络接口（如物理网卡），N2N/Radmin 虚拟网卡是后来才激活的，sshd 不会自动重新 bind 到新接口。所以 ping 能通（底层网络层没问题），但 SSH 连接被传输层拒绝（sshd 没在虚拟网卡上监听）。重启 sshd 让它重新扫描所有可用接口即可解决。
5. **终极测试**——临时关防火墙：
   ```powershell
   netsh advfirewall set allprofiles state off
   ```
   关掉后如果能 SSH，就是防火墙问题。**一定要开回来**：
   ```powershell
   netsh advfirewall set allprofiles state on
   ```
6. 如果关防火墙后能连，加一条新规则（注意用 netsh 而非 New-NetFirewallRule，避免多行粘贴陷阱）：
   ```powershell
   netsh advfirewall firewall add rule name="OpenSSH N2N" dir=in action=allow protocol=TCP localport=22
   ```

**2026-06-05 真实案例**：SSH 监听 `0.0.0.0:22`，有 OpenSSH Server 防火墙规则，但 SSH 仍然 `Connection refused`。最终发现远程机 SSH 服务需要**重启**或 N2N 虚拟网卡需要先重启连接才能绑定新接口。如果 EasyN2N 刚启动时 ping 不通、重启后突然通了，说明虚拟网卡驱动绑定有延迟或顺序依赖。

**经验法则：**
- 远程机上 EasyN2N 启动后，查 `ipconfig` 确认 N2N 虚拟 IP 已经出现
- 从远程机 ping 本地虚拟 IP 确认双向连通
- 如果双向 ping 通但 SSH 被拒 → **先重启 sshd 服务**，不要急着折腾防火墙：
  ```powershell
  Restart-Service sshd
  ```
  **原理**：sshd 在系统启动时绑定到当时的网络接口（如物理网卡），N2N/Radmin 虚拟网卡是后来才激活的，sshd 不会自动重新 bind 到新接口。所以 ping 能通（底层网络层没问题），但 SSH 连接被传输层拒绝（sshd 没在虚拟网卡上监听）。重启 sshd 让它重新扫描所有可用接口即可解决。关闭防火墙是第二排查步骤。
- 如果重启 sshd 还不行 → 关防火墙测试 → 还不行再加防火墙规则
  ```powershell
  Restart-Service sshd
  ```
  **原理**：sshd 在系统启动时绑定到当时的网络接口（如物理网卡），N2N 虚拟网卡是后来才激活的，sshd 不会自动重新 bind 到新接口。所以 ping 能通（底层网络层没问题），但 SSH 连接被传输层拒绝（sshd 没在虚拟网卡上监听）。重启 sshd 让它重新扫描所有可用接口即可解决。
  **验证步骤**：
  ```powershell
  # 1. 检查 sshd 是否在运行
  Get-Service sshd

  # 2. 确认 SSH 监听在 0.0.0.0（所有接口）
  netstat -ano | findstr :22

  # 3. 从远程机自身测试 SSH 到虚拟 IP
  ssh PC@192.168.25.240 echo ok

  # 4. 从本地测试
  ssh -o StrictHostKeyChecking=no PC@192.168.25.240 echo ok
  ```

**PowerShell 多行粘贴陷阱**...
- **N2N 连接稳定性**：UDP 打洞可能不稳定，如果双向 ping 通但游戏连接仍然卡住/断连，需要考虑改用 frp/TCP 隧道方案
**SSH 密码认证**：Windows SSH Server 默认支持密码登录。方法：

**首选（sshpass）：**
```bash
sshpass -p "密码" ssh -o StrictHostKeyChecking=no PC@192.168.25.240 "命令"
```

**备选（管道传密码）：** 当 sshpass 未安装时：
```bash
# bash/msys2 环境（注意编码）
echo "密码" | ssh -o PasswordAuthentication=yes -o StrictHostKeyChecking=no PC@192.168.25.240 "命令" 2>&1

# 或交互式
ssh -o PasswordAuthentication=yes -o StrictHostKeyChecking=no PC@192.168.25.240
# 然后会提示输入密码
```

**坑**：git-bash/MSYS2 下管道传密码时中文系统可能有 UnicodeDecodeError，用 `2>&1` 重定向可以绕过。`sshpass` 需要额外安装（`apt install sshpass` 或 `pacman -S sshpass`）。

### ngrok 备选方案（2026-06-05 实测）

当 N2N 不可用时：
1. 下载：`winget install ngrok` 或手动下载（注意 PowerShell 多行粘贴会断参数）
   ```powershell
   # 正确的一行命令
   Invoke-WebRequest -Uri "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip" -OutFile "$env:TEMP\ngrok.zip"
   ```
2. 解压后配置 authtoken：
   ```powershell
   Expand-Archive -Path "C:\ngrok.zip" -DestinationPath "C:\ngrok" -Force
   $env:Path += ";C:\ngrok"
   ngrok config add-authtoken 你的token
   ngrok tcp 22
   ```
3. **坑**：免费 ngrok 的 TCP 隧道需要绑信用卡验证（ERR_NGROK_8013）
   - 错误信息：`You must add a credit or debit card before you can use TCP endpoints on a free account`
   - 需要去 https://dashboard.ngrok.com/settings#id-verification 绑卡
   - 如果用户不想绑卡，改用 frp 或 N2N

### frp 备选方案

ngrok 需要绑卡时改用 frp，免费且不需绑卡。

### 客户端 IP 配置

让本地彩虹岛客户端连到远程服务端，需要改两个文件：

**`IP.ini`**（客户端根目录）：
```
[PublicIP]
IP=192.168.25.240    ← 远程机在虚拟局域网中的 IP
```

**`登陆.bat`**（或对应的 .bat 启动脚本）：
```
start LaTaleClient.exe /Windowed /LoginServer:192.168.25.240:19999 /Run:VHIGH /LOCALE:TAIWAN /PUBLISHER:GAMEFLIER
```

注意 `19999` 是 LoginServer 端口，按实际 GS 配置修改。客户端目录通常只有 `.SPF` 包文件和一些 `.DAT`/`.ini`/`.bat`，没有多余的配置文件——`IP.ini` 和 `登陆.bat` 就是入口。

### 客户端连接远程 GS 掉线诊断

**症状**：客户端连上 LoginServer，进入选线/角色界面 5 秒后断开，不重启客户端不能重连。

**排查顺序：**
1. **远程机本地测试** — 在远程机上直接双击客户端启动（不经过虚拟组网），正常不掉线 → 问题在网络隧道
2. **防火墙检查** — 本地和远程机的防火墙都可能拦截游戏心跳包
3. **服务端 `KickOutInterval`** — `configure.ini` 中 `KickOutInterval = 10`（秒），客户端心跳没在间隔内到达就被踢
4. **断线后不能重连原因**：服务端会话表没释放旧连接，新连接被拒绝。必须重启客户端换本地端口才能重建

### 频道列表为空（登录后看不到频道/线路）

**现象**：客户端能通过 LoginServer 验证（输入账号密码通过），但进入选线界面后频道列表空白，无法继续。

**排查顺序：**
1. **MS（MgmtServer）端口引用没同步改** — 最常见原因。如果改了所有服务端口（如 19999→41470、10001→41471），但 `configure.ini` 和 `configure_share.ini` 中的 `[MS] Port = 10001` 没有同步改成新端口（41471），GS 就注册不到 MS，LobbyServer 从 MS 拉频道列表为空
   - 修复：两个文件里的 `[MS] Port =` 都改成新 MS 端口
   - 重启所有 GS 后生效
2. **PublicIP=127.0.0.1** — LobbyServer 返回给客户端的频道地址是 127.0.0.1，客户端连不上
   - **但如果把 PublicIP 改成外网/Radmin IP，LoginServer 可能会做 IP 校验踢人**
   - **推荐绕开方案**：保持所有 PublicIP=127.0.0.1，在本地用 netsh 端口转发
     ```powershell
     netsh interface portproxy add v4tov4 listenport=41470 connectport=41470 connectaddress=远程机IP
     netsh interface portproxy add v4tov4 listenport=41472 connectport=41472 connectaddress=远程机IP
     ```
   - 然后客户端连 `127.0.0.1:41470`，LoginServer 看到来源 IP 为 127.0.0.1（本地回环），通过校验
3. **GS没全部启动** — 检查 tasklist 确认所有 GS 进程存活
4. **GS崩溃** — 改端口后 GS_101 可能出现 Runtime Error（需要检查 ResourceDir 路径是否有效、运行库是否齐全）

### 断线后不能重连（特殊检测）

客户端断线后不重启客户端就不能重连 → 怀疑服务端有**端口/IP检测**或来源端口黑名单。重连时服务端发现同一来源IP和旧会话关联，拒绝新连接。重启客户端换本地端口可绕过。

### 典型案例

### 服务端端口映射（店家给外网端口时）

当云电脑/服务器商只提供有限端口段（如 41470~41479），但服务端监听的是默认端口（19999、10001~10007等），需要做端口映射。

**方案A：改服务端配置文件端口（推荐）**
修改 `configure.ini` 和 `configure_share.ini` 中每个服务的 `port=` 为新端口，然后重启所有 GS。

**端口映射表（S2标准 → 41470~41479 示例）：**
| 服务 | 原端口 | 新端口 |
|------|-------|-------|
| LoginServer (S2) | 19999 | 41470 |
| LoginServer (S4/S4chd) | 20200 | — |
| MgmtServer(MS) | 10001 | 41471 |
| LobbyServer | 10002 | 41472 |
| GameServer_101 | 10003 | 41473 |
| GameServer_151 | 10005 | 41474 |
| BayServer | 10006 | 41475 |
| RoomServer | 10007 | 41476 |
| GameServer_102 | 20003 | 41477 |
| ASServer | 10020 | 41478 |
| 备用 | - | 41479 |

**⚠️ 改端口时需要同时改的点（缺一不可）：**
1. `configure.ini` — 所有 `[服务名]` 段的 `port =` 字段
2. `configure_share.ini` — 所有 `[服务名]` 段的 `port =` 字段
3. 两个文件中的 **`[MS] Port =`** 必须改为新 MS 端口（因为 GS 通过 MS 注册自己，MS端口改了引用也必须同步改）
   - **没改MS引用端口 → GS注册不到MS → LobbyServer从MS拉频道列表为空 → 客户端登录后看不到频道列表**
4. 所有服务的 **`PublicIP`** 必须改成客户端能访问的IP（虚拟局域网IP或公网IP），不能是 `127.0.0.1`
5. `BAY_0/1`、`ROOM_0/1` 等引用端口也要同步更新

**操作用记事本手动改**（两个文件都是 GBK 编码，不要用自动化工具）。

**方案B：netsh 端口转发（不改配置）**
更安全，但需要每条映射都手动加一条规则：
```powershell
netsh interface portproxy add v4tov4 listenport=41470 connectport=19999 connectaddress=127.0.0.1
```

### 远程机 Hermes Agent 作为替代管理途径

如果远程机已经装了 Hermes Agent 但卡在 Nous Portal OAuth 认证，**不需要交费也无需完成 Portal 登录**。直接改提供商跳过认证：
```powershell
hermes config set model.provider deepseek
hermes config set model.default deepseek-chat
hermes config set model.api_key sk-你的Key
```
注意：之前 `hermes model` 选择了 Nous Portal（default=1）导致启动时自动弹 Portal 认证页，切到别的提供商（DeepSeek/OpenRouter/Anthropic 等）就跳过了。


## BayServer / RoomServer 崩溃诊断（2026-06-04 新增）

### pack=1 vs pack=0 策略
- **pack=1（必须）**：读SPF包。SPF中的ITEM_2.LDT是原始版本，不会被后面修改的目录文件影响。
- **pack=0**：读resource/目录下的LDT。如果目录ITEM_2被二进制改坏，BayServer立即崩。
- 用户当前必须用pack=1。

### BayServer SIGSEGV（exit code 139）
**症状**：日志停在 `GlobalSys::Init() : [OK]`，无后续日志，无dmp生成。
**根因**：二进制修改ITEM_2.LDT字符串字段时破坏了`\x00`边界：
- 新名字比原名短，用`\x00`清零剩余字节 → 后续字段起始被当作空字符串
- BayServer加载到损坏的行时段错误
**修复**：从BARY.rar恢复原版ITEM_2.LDT覆盖，重新打包BARY.SPF。
**教训**：改LDT字符串必须等长，短了用0x20（空格）填空，不要用0x00！

### RoomServer LoadQuizInfoLDT() FAILED
**症状**：RoomServer日志输出`LoadQuizInfoLDT() : [FAILED]`后立即退出。
**根因**：QUIZ_INFO.LDT不存在于SPF包中。pack=1模式只读SPF，找不到文件就直接失败。
**检查**：确认此文件是否应该在SPF中。如果源端也没有此文件，RoomServer可能依赖它但被删了。

### CashCheck 0→1 安全改法
**公式**：`DATA_OFF + ((name_pos - DATA_OFF) // ROW_SIZE) * ROW_SIZE + CC_COL * 4`
- ITEM_2.LDT: DATA_OFF=8512, ROW_SIZE=500, CC_COL=10
- 用道具名（GBK）在二进制中搜索定位
- int字段固定4字节，改起来安全

---

### LiteSQL 数据库引擎管理

彩虹岛S2/S4端使用 LiteSQL（绿色免安装版 SQL Server）作为数据库引擎。常见版本：

**LiteSQL2014** — 传统版本，端口 2433  
**LiteSQL2022** — 新版，端口默认 2433，支持 SQL2008R2/2014/2019/2022

**多版本数据库恢复**见 `references/s4-hybrid-database-recovery-2026-06-05.md`。

#### 切换数据库端口

本机 SQL2008 使用端口 59157（实例 JSQL2008）。要把 LiteSQL 改成 59157 端口：

1. 编辑 `SConfig.ini` 的 `ServPort=59157`
2. 停掉旧 LiteSQL 进程（taskkill //F //IM LiteSQL.exe，还要杀 sqlservr.exe）
3. 启动新 LiteSQL

#### 多版本数据库冲突 — JSQL2008 master 损坏后恢复

**症状**：`net start MSSQL$JSQL2008` 报错误 1814，或 ERRORLOG 中显示 master 数据库无法启动。

**常见原因**：在同一台机器上启动了另一个版本的 LiteSQL，它覆盖/write-lock 了 JSQL2008 共享的 `master.mdf`。

#### JSQL2008 model 路径错误导致启动后自动关闭

**症状**：`net start MSSQL$JSQL2008` 报错误 1814，或 `sc start` 后进程启动几秒后自动消失。ERRORLOG 中关键报错：

```
Error: 17204, FCB::Open failed: Could not open file e:\sql10_main_t.obj.x86fre\sql\...\model.mdf
Error: 17204, FCB::Open failed: Could not open file e:\sql10_main_t.obj.x86fre\sql\...\MSDBData.mdf (也可能出现)
```

**根因**：这是 SQL Server 2008 R2 绿色版/便携版的已知问题。master 数据库的 `sys.master_files` 中记录了 model/msdb 等数据库文件的路径，但这个路径是**编译构建机上的临时路径**（`e:\sql10_main_t.obj.x86fre\...`），而不是实际安装路径。master.mdf 被其他版本 SQL（如 SQL2014/2022）覆盖后，新 master 里的路径记录变成了错的。

**修复前提**：`C:\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\Data\` 目录下有对应的 `.mdf`/`.ldf` 文件（`model.mdf`, `modellog.ldf`, `MSDBData.mdf`, `MSDBLog.ldf` 等）。

**修复步骤（使用 -T3608 跟踪标志绕过 model 启动）：**

1. 先注册/修复服务（如果注册表已被清理）：
   ```cmd
   reg import "C:\JSQL2008\jinstall.reg"
   sc create "MSSQL$JSQL2008" binpath= "C:\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\Binn\sqlservr.exe -sJSQL2008" start= auto displayname= "SQL Server (JSQL2008)"
   sc config "MSSQL$JSQL2008" start= auto
   ```

2. 用 `-T3608` 跟踪标志启动（跳过 model/msdb/tempdb，只恢复 master）：
   ```cmd
   start /B "" "C:\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\Binn\sqlservr.exe" -sJSQL2008 -T3608
   ```

3. 验证启动成功：ERRORLOG 中看到 `Recovering only master database because traceflag 3608 was specified` 即为生效。

4. 连接 SQL 并修正路径：
   ```cmd
   sqlcmd -S .\JSQL2008 -E -Q "ALTER DATABASE model MODIFY FILE (NAME = modeldev, FILENAME = 'C:\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\DATA\model.mdf')"
   sqlcmd -S .\JSQL2008 -E -Q "ALTER DATABASE model MODIFY FILE (NAME = modellog, FILENAME = 'C:\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\DATA\modellog.ldf')"
   ```

5. 同样检查并修正 msdb（如果也有路径错误）：
   ```cmd
   sqlcmd -S .\JSQL2008 -E -Q "SELECT name, physical_name FROM sys.master_files WHERE database_id = 4"
   ```

6. 停止 sqlservr.exe 进程，然后正常启动服务：
   ```cmd
   taskkill /F /IM sqlservr.exe
   net start "MSSQL$JSQL2008"
   ```

7. 验证：用 sqlcmd 或客户端连接测试。

**坑点**：
- `-T3608` 是 trace flag 3608 — 文档上说它会跳过所有非 master 数据库的恢复。但 model 路径错误时 master 还是能正常加载。
- 在 git-bash 里执行包含 `$` 的 cmd/reg/net 命令时，需要用 cmd.exe 或者单引号转义（如 `MSSQL$JSQL2008` 中 `$` 会被 bash 展开）
- 推荐把所有修复命令写进 `.cmd` 批处理文件执行，避免 bash 转义问题

**数据库文件完整性**：只要 `C:\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\Data\` 下 `dbLataleAccount.MDF`、`dbLataleWorld_2.mdf` 等数据文件还在，数据就没丢。损坏的只是 master 库。

**恢复方案**：切换到 LiteSQL2014（或任意可用的 LiteSQL 版本），改端口为 59157 后启动，它会自动 attach 同一目录下的数据文件。因为三个SQL引擎共享 `C:\JSQL2008\` 的数据文件。

**详细恢复步骤**见 `references/s4-hybrid-database-recovery-2026-06-05.md`。

#### LiteSQL2022 时间过期（"注册无效,授权已过期"）

LiteSQL2022 的时间验证通过 `RunAsDate_cn.exe` 绕过：
```
# 配置 RunAsDate_cn.cfg：
# Filename=D:\LaTale\S4\数据库\LiteSQL2022\LiteSQL.exe
# DateTimeMode=1, DateTime=01-01-2024 00:00:00
# AddTimeUnit=4, AddTimeValue=-1

# 或者在目录下直接双击 SQL2022.lnk（已配置好）
```

**注意**：RunAsDate_cn.exe 本身也是GUI程序。中文路径在 cmd/msys2 下可能乱码导致找不到 exe，在资源管理器双击最可靠。

**命令行参数格式**（如果GUI起不来）：`RunAsDate_cn.exe /f LiteSQL.exe /d 01-01-2024`。但日期格式在不同系统上可能报"日期格式无效"，在资源管理器中双击 `RunAsDate_cn.exe` 用图形界面选目标程序和日期的成功率更高。

#### SQL Server 安装介质真实版本判断

不要信 exe 文件名！`SQLEXPR_x64_CHS.exe` 可能是 SQL2022（16.0）不是 2008 R2。

**判断方法**：解压后读取 `MEDIAINFO.XML`：
```xml
<Property Id="BaselineVersion" Value="16.0.1000.6" />  <!-- 16.x = SQL2022, 13.x = SQL2016, 12.x = SQL2014, 10.x = SQL2008R2 -->
```

或打开解压目录下的 `x64\setup\setup.exe` 看属性→详细信息→产品版本。

**SQL2022 Express 静默安装已知问题**：
- `TCPPORT` 参数名不被识别，应用 `TcpPort`（首字母大写）
- 如果之前手动删过 `SQLBrowser` 服务（`sc delete`），安装器的 `FinalCalculateSettingsAction` 会尝试查询该服务的启动账户，报"系统找不到指定的文件"
- 自解压 `SQLEXPR_x64_CHS.exe /ConfigurationFile=...` 可能不按预期工作，建议用解压后的 `x64\setup\setup.exe` 跑
- 完整踩坑记录见 `references/sql-reinstall-attempt-2026-06-06.md`

#### JSQL2008 完整卸载流程

JSQL2008 是第三方打包的 SQL Server 2008 R2 绿色版（非 MSI 安装），卸载时不能走控制面板：

```bash
# 1. 停服务
sc stop "MSSQL$JSQL2008"
sc delete "MSSQL$JSQL2008"

# 2. 杀所有相关进程
taskkill //F //IM JSQL_Helper.exe
taskkill //F //IM JSQL_Helper.exe_1.exe
taskkill //F //IM sqlservr.exe      # 可能有多实例，全杀

# 3. 确认进程已消失
ps -W | grep -i "jsql"

# 4. 删除目录
rm -rf /c/JSQL2008/
# 或用 Windows cmd（如果 bash 删不掉）:
# cmd //c "rd /s /q C:\JSQL2008"
```

**注意**：如果提示 `Device or resource busy`，说明还有进程占用该目录。确认所有 JSQL/sqlservr 进程已杀光后再试。如果杀光后仍然删不掉，重启后直接删除即可。

#### master.mdf 跨实例克隆陷阱

不要从一台 LiteSQL 复制 master.mdf + mastlog.ldf 到另一台用。即使版本相同，LSN 不匹配会直接崩：

```
Error: 9003, Severity: 20, State: 9.
The log scan number (258:422:0) passed to log scan in database 'master' is not valid.
Cannot recover the master database. SQL Server is unable to run.
```

mastlog.ldf 记录了 master.mdf 的最后 LSN，两个文件是一对。复制 master 后必须连 mastlog 一起复制（且必须是同一时间点的文件集）。只覆盖 master.mdf 保留旧 mastlog.ldf 也不行。

**正确的搬库方式**：\n1. `BACKUP DATABASE` + `RESTORE DATABASE`（推荐）\n2. 或完整复制 Data/ 全部文件（master+model+msdb+tempdb+业务库），保证同一时间点\n3. 或在新实例上 `CREATE DATABASE ... FOR ATTACH` 只附加业务库\n\n**JSQL_Helper 一键包备份恢复（最快路径）**：\n当你有完整的 `C:\\JSQL2008 备份\\` 目录（通过 JSQL_Helper 一键包做的备份），直接覆盖即可：\n```bash\n# 1. 停 SQL 服务\nnet stop MSSQL$JSQL2008\n\n# 2. 覆盖 DATA 目录（包含 master+model+msdb+业务库全套 mdf/ldf）\ncp -f \"/c/JSQL2008 备份/MSSQL10_50.JSQL2008/MSSQL/DATA/*\" \"/c/JSQL2008/MSSQL10_50.JSQL2008/MSSQL/DATA/\"\n\n# 3. 启动 SQL 服务\nnet start MSSQL$JSQL2008\n```\n**优点**：比 backup/restore 快，不需要 sqlcmd 工具，直接覆盖立即可用。\n**前提**：备份必须是同一版本 SQL Server 的 mdf 文件（检查 `MSSQL10_50.` = SQL2008 R2，`MSSQL12.` = SQL2014 等）。

**恢复损坏 master**：
1. 从 `Binn/Templates/master.mdf` 恢复模板文件
2. 删除 `mastlog.ldf` 让 SQL 启动时重建
3. 启动后业务库需要重新附加（模板 master 里没有业务库记录）

#### 多版本冲突

同一台机器上 **同时只跑一个 LiteSQL**（两个版本抢 2433 端口）。切换前先杀掉另一边的进程：
```
taskkill //F //IM LiteSQL.exe
taskkill //F //IM sqlservr.exe   # sqlservr 可能有多进程，全部杀掉
```

---

### S4CHD 服务端结构（2026-05-28 更新）

**配置加密确认**：S4CHD 的 `configure.inis` / `Global_ODBC.inis` 是加密格式（不是明文 ini），需要通过 `LaS4服务端.exe` 启动器解密读取。不能直接用原生 exe 启动。

目录结构：
```
D:\\LaTale\\S4chd\\
├── bin2\\\\                    # 服务端exe + 加密配置 (.inis)
│   ├── LaS4服务端.exe       # 启动器（解密...）

## 新下载端启动前评估

**每次下载新端后，先做评估而不是直接启动。** 关键检查点见下方「S4端配置脏数据诊断」和「S4端启动阻塞点（常见）」两节（交叉引用陷阱、路径替换清单、阻塞点逐项排查）。

### 常见交叉引用陷阱

下载的 S4 端（D:\\LaTale\\S4\\）的 `configure.ini` 常引用 S4chd 或其他版本的加密 `.inis`：
```
[ConfigurePath]
Share=D:\\LaTale\\S4chd\\bin2\\configure_share.inis
```
此外可能混有重复段（如两个 `[MS]` 段不同端口），说明配置被乱拼过。

### S4端拷贝到新目录的路径替换清单

把 S4chd（或任何完整端）的 `configure.ini` + 加密 `.inis` + `resource/` 拷贝到新目录后，**必须改三处**，少一处就崩：

1. **`[ConfigurePath]`** — 三个路径（Share/ODBC/IPFILTER）全部改成指向新目录
2. **所有 `ResourceDir=` / `resourceDir=`** — configure.ini 里两种大小写写法都有可能，都要改
3. **数据库 Global_ODBC.ini**（如果有明文版本）— 数据库IP/端口按实际改

验证命令：
```bash
grep -n "旧目录名" /d/LaTale/S4/bin2/configure.ini
# 预期：无输出（干净）
```

### S4端配置脏数据诊断

从网络下载的 S4 端或拷贝自其他版本的副本，`configure.ini` 常被卖家/使用者手动修改过，留下各种脏数据：

**典型脏数据模式：**
1. **乱码路径** — 如 `D:\\�ʺ絺\\bin2\\SPF������_\\`，这是韩文/繁中编码在简体系统上显示的结果
2. **重复段** — 两个 `[MS]` 段不同端口（如 10021 和 10024），说明配置是从不同文件拼接的
3. **孤儿段** — 只有 `[LataleMgmtServer_11]` 或 `[LataleGameServer_181]` 片段缺少完整配置
4. **注释乱码** — 韩文/日文注释在简体中文系统上显示为乱码（不影响功能）

**修复：** 从已知完好的版本（如 S4chd 99元端）拷贝完整 `configure.ini` 覆盖，然后改路径。不要手动逐行修复。

### S4端 vs S4chd端 区别

| 特性 | S4端（LaS4服务端.exe版） | S4chd端（原生exe版） |
|------|------------------------|--------------------|
| 配置 | 加密 .inis，需启动器解密 | 明文 .ini，exe直读 |
| exe状态 | 正常无壳 | 正常无壳 |
| 登录器/网关 | 有拉网等配套 | 无配套工具 |
| resource/ | 通常少量SPF | 完整SPF+LDT |

### S4端启动阻塞点（常见）

**阻塞1：中文 exe 名无法从命令行启动**
`LaS4服务端.exe` 在 msys2/bash 下报 `No such file or directory`，cmd 下报「不是内部或外部命令」。
- 修复：把 exe 复制为英文名 `LaS4.exe`，用英文名调用
- 原因：MSYS2 对中文文件名的 PATH 解析有 bug，cmd 的代码页也可能不匹配

**阻塞2：ConfigurePath 引用其他版本的 .inis**
S4端的 `configure.ini` 里 `[ConfigurePath]` 段常指向 S4chd 的加密配置：
```
[ConfigurePath]
Share=D:\\LaTale\\S4chd\\bin2\\configure_share.inis
```
如果 S4chd 不在本机或 `.inis` 格式不兼容，启动器 LaS4服务端.exe 读不到配置，不会启动任何 GS 进程。
- 修复：把引用路径改成指向本版本 S4 目录的 `.inis` 文件

**阻塞3：[MS] 段重复**
configure.ini 里可能出现两个 `[MS]` 段（不同端口），这是配置被人手动乱拼过的信号。
- MS 端口不统一会导致 GS 注册到错误 MS，LobbyServer 拉频道列表为空
- 修复：删掉多余的重复段，只保留端口正确的一组

**阻塞4："Server must using encrypt INI file"**
exe 启动时输出：
```
Load configure from Security INI.
Server must using encrypt INI file.
```
这说明 exe 硬编码走加密读取路径，但找到的 `.inis` 文件格式损坏或不兼容此编译版本的加密密钥。即使 `[ConfigurePath]` 指向明文 `.ini`，exe 也不认。
- 修复：用完整端的配套 `.inis` 文件覆盖（相同编译版本的 exe + .inis 配对使用）
- 不要尝试把 `.ini` 硬改成 `.inis` 后缀——加密算法不是单纯文件扩展名判断

**阻塞5：孤儿段指向 `C:\Server\DATA\`**
configure.ini 或 .inis 中可能出现 `resourceDir = C:\Server\DATA\` 或 `ResourceDir = C:\Server\DATA\`，这是卖家编译 exe 时遗留的路径。
- `[LataleMgmtServer_11]` 等孤儿段最容易带这个路径
- 此路径不存在于本机，exe 读不到资源就直接崩
- 修复：在加密 `.inis` 中修改路径（需 INISViewer 解密后编辑），或删掉孤儿段

### S4端手动启动完整工作流（推荐，比网关可靠）

当 `LaS4服务端.exe` 启动器弹窗报错或 `网关.exe` 自动启动后 GameServer 不存活时，**手动逐个启动 GS exe 反而能全活**。这是经过验证的可靠替代方案。

**前提**：configure.ini 的 `[ConfigurePath]` 已修正为指向本版本目录（见阻塞2修复）。

**启动顺序（严格按此顺序）：**
```
# 1. 数据库（如果还没启动）
D:\LaTale\S4\数据库\LiteSQL2014_Release\LiteSQL.exe

# 2. 核心服务（无顺序依赖，可并行）
LataleAS.exe /Debug 1
LataleMgmtServer.exe /Debug 1
LataleBayServer.exe /Debug 1

# 3. 登录/大厅/房间/工具
LataleLoginServer.exe /Debug 1
LataleLobbyServer.exe /Debug 1
LataleRoomServer.exe /Debug 1
LataleToolServer.exe /Debug 1

# 4. GameServer（需要 MS 已就绪）
LataleGameServer.exe /ServerID 101 /Debug 1
LataleGameServer.exe /ServerID 102 /Debug 1
LataleGameServer.exe /ServerID 151 /Debug 1
```

**为什么手动启动比网关靠谱？**
- 网关.exe（LaS4服务端.exe）是 GUI 启动器，内部可能按固定间隔拉起各进程，如果有进程崩了不会重试或报错，后续依赖该进程的服务就卡住
- 手动启动能看到每个 exe 的控制台窗口，当场发现谁闪退了
- **已验证案例**：网关自动启动后 GameServer 不存活（"configure.ini don't exist!" 或 "Server must using encrypt INI file"），但手动逐个启动全活。说明 exe 读 `.inis` 加密配置是正常的，网关的进程管理方式不靠谱
- 网关的 OSP（端口5217/5317）跟游戏连接无关，不影响登录

**登录参数（S4端）：**
```
start LaTaleClient.exe /Full /LoginServer:127.0.0.1:20200 /Run:VHIGH /LOCALE:GSP /PUBLISHER:GSP
```

**验证启动成功：**
```powershell
# 确认所有进程存活
ps -W | grep latale
# 预期看到: AS, BayServer, MgmtServer, RoomServer, LoginServer, LobbyServer, ToolServer, GameServer(数量看配置了多少频道)
```

**参考**：`references/s4-manual-startup-workflow-2026-06-05.md`

## Skill/Learn System (SKILL.LDT / LEARN_SKILL.LDT)

See the dedicated reference at `references/skill-learn-system.md` for complete coverage of:

- **SKILL.xls structure** — column mapping, upgrade condition types
- **LEARN_SKILL.xls structure** — 50-column format, requeire group layout
- **⚠️ Core discovery**: Job/class restrictions are NOT enforced by LEARN_SKILL — GS determines learning eligibility in its compiled code, not via LDT data. CLASS_CHANGE/CLASS_EFFECT/CLASS_SWITCH may be the real gate.
- **Skill ID patterns** — prefix ranges for Warrior, Mage, Spirit, and advanced job skills
- **S3 vs current-end LEARN_SKILL differences** — field count, ID overlap, V1 value corruption
- **Binary edit warning** — LEARN_SKILL.LDT has mixed int+string columns; use the editor export→modify→import workflow only

## Legacy Game Server Binary Patching

Techniques for hex-patching precompiled private-server EXEs (typically VS2005-2015 era) to bypass initialization failures.

### When to Use

- Server EXE fails during startup due to **LDT/resource loading errors** (Division, PVP, Guild, MapEvent init failures)
- The failure is **non-essential** — skipping it doesn't affect core server function
- EXE is **console-mode** (not packed/protected by VMProtect/Themida)

### When Hex Patching Isn't Enough

Consider **source-based rebuild** when the EXE is:
- **VMProtect/Themida packed** — hex edits on encrypted code sections don't affect runtime behavior
- **CHDS-protected** — shell validates CHDS.dll at process entry, exits silently with exit code 0

See the extensive references for specific techniques:
- `references/latale-server-suite-startup-2026-05-24.md` — Server architecture, startup sequence
- `references/latale-ldt-spf-editing.md` — LDT file format, CASH_SHOP editing, SPF repacking (in-place + size-change rebuild)
- `references/latale-login-source-rebuild-2026-05-24.md` — Source-based rebuild for LoginServer
- `references/spf-rebuild-variable-size-2026-05-24.md` — Appending new data blocks when file size differs
- `references/latale-version-port-map.md` — Port mapping between S3, S4chd, and other builds
- `references/latale-database-port-config.md` — SQL instance locations, Global_ODBC.ini format
- `references/latale-cash-shop-ldt-binary-format.md` — CASH_SHOP.LDT binary record structure
- `references/latale-database-container-types.md` — tbluItem2 ContainerType values
- `references/latale-item-ldt-cross-version.md` — Column structure comparison across S1/S2
- `references/trad2simp-workflow-session-2026-05-27.md` — Traditional→Simplified Chinese conversion

### VMProtect Detection (Client EXEs)

| Sign | Description |
|------|-------------|
| `.vmp0`/`.vmp1` sections | More than 6 PE sections, encrypted code |
| GameGuard NPGL window | Helper process, then clean exit with no window |
| No crash dump | Exit is clean, not a crash |

**Only real fix**: Replace client with un-packed version from a different build.

### CHDS / Winlicense Shell Detection (Server EXEs)

| Sign | Description |
|------|-------------|
| Silent exit code 0 | No console output, no crash dump |
| No port binding | Process runs but no port bound (check `netstat`) |
| CHDS.dll/WinlicenseSDK.dll present | Validation DLL in same directory |

**Fix**: Replace with clean EXEs (e.g. S4chd 99元端), or keep the original gateway.

### Patch Strategies

**Strategy A: NOP getchar + change return value**
```python
data[0x13ed0:0x13ed3] = bytes([0xb0, 0x01, 0xc3])  # mov al,1; ret
data[0x13ec2:0x13ec2+6] = bytes([0x90] * 6)  # NOP
```

**Strategy B: Conditional jump → unconditional**
```python
data[0x13e61] = 0xEB  # JNZ → JMP
data[0x13e98:0x13e98+2] = bytes([0x90, 0x90])  # JE → NOP
```

**Strategy C: Patch Init() to return true**
```python
data[func_offset:func_offset+3] = bytes([0xb0, 0x01, 0xc3])
```

### Cross-Build EXE Swapping

1. Identify shell-wrapped vs clean by comparing sizes with known-good build
2. Copy only shell-wrapped EXEs from clean build
3. Update configure.ini ports and Global_ODBC.ini
4. Remove GameGuard directory on Win10/11
5. Watch for Windows Defender async crack detection

### Client Login Protocol Analysis Proxy

When VMP-packed LaTaleClient.exe launches but can't connect, use a Python MITM proxy to capture TCP traffic. See `references/client-proxy-packet-capture.md`.

### 火绒 Impact on Server EXEs

火绒's "清除恶意代码" feature byte-patches EXEs, corrupting encrypted VMP sections. Recovery requires clean backup. See `references/pe-section-diagnosis-method.md`.

### Traditional→Simplified Chinese Conversion for LDT

See `references/trad2simp-workflow-session-2026-05-27.md` for the complete batch-verification workflow. Core technique:

```python
# Binary replacement — only safe for equal-length GBK pairs
pairs = [(trad.encode('gbk'), simp.encode('gbk')) for trad, simp in trad2simp.items() if len(trad.encode('gbk')) == len(simp.encode('gbk'))]
for tg, sg in pairs:
    idx = 0
    while True:
        idx = data.find(tg, idx)
        if idx == -1: break
        data[idx:idx+len(tg)] = sg
        idx += len(sg)
```

Known danger: `設`/`計` characters cause GS crash when modified. EFFECT/PVP_EFFECT.LDT changes break fashion shop.

## Windows MSVC Toolchain & Compilation

For building Latale server executables from source. Centered around VS2012/2013/2022 compilation of the S2/S4chd codebase.

### Quick Reference

| _MSC_VER | VS Version | Toolset | CRT |
|----------|-----------|---------|-----|
| 1700 | VS2012 | v110 | msvcrt.lib / libcmt.lib |
| 1800 | VS2013 | v120 | msvcrt.lib / libcmt.lib |
| 1900 | VS2015 | v140 | vcruntime + ucrt |
| 1910+ | VS2017+ | v141+ | vcruntime + ucrt |

### Key Facts

- **_MSC_VER mismatch = link failure.** All .obj and .lib must share the same _MSC_VER.
- **CRT linkage must match.** `/MD` (msvcrt.dll) vs `/MT` (static libcmt) = LNK2038.
- **"Three-Compiler Whammy"**: when .lib from VS2012, VS2013, VS2015 are mixed, no single compiler can link. Must rebuild all from source with one version.
- **C1047 / LNK2038 cannot be bypassed** by `/FORCE:MULTIPLE` or `/LTCG`.

See:
- `references/three-compiler-whammy-2026-05-23.md` — Full diagnosis of cross-version link failure
- `references/vs2012-toolchain-trial.md` — VS2012 toolchain testing and rebuild
- `references/vs2012-full-compile-2026-05-23.md` — VS2012 full compile results
- `references/vs2013-full-rebuild-2026-05-24.md` — VS2013 full rebuild for LoginServer
- `references/vs2003-to-vs2022-migration.md` — Migrating VS2003-era code to modern toolchain
- `references/compilation.md` — Compilation guide
- `references/compilation-per-project-stdafx.md` — Per-project stdafx handling
- `references/latale-full-rebuild.md` — Detailed rebuild log including LoginServer
- `references/latale-mgmt-build-status.md` — MgmtServer compilation status and dep rebuild plan

### Stub Library Compilation Technique

When a legacy project links against a precompiled `.lib` with different `_MSC_VER`, produce a **stub library** from source:

1. Create a `.cpp` file including project headers
2. Provide empty class/function definitions for linker-needed symbols
3. Compile to static lib with `/c` then `lib.exe`

`scripts/MgmtStubs.cpp` and `scripts/symbol_stubs.asm` in the latale-server scripts directory contain working stub implementations.

### Direct MSVC from Python (Preferred)

```python
import subprocess, os
env = os.environ.copy()
env['PATH'] = r'D:\\VS2013\\VC\\bin;' + env['PATH']
env['INCLUDE'] = (
    r'D:\\VS2013\\VC\\include;'
    r'C:\\Program Files (x86)\\Windows Kits\\8.0\\Include\\shared;'
    r'C:\\Program Files (x86)\\Windows Kits\\8.0\\Include\\um;'
)
env['LIB'] = r'D:\\VS2013\\VC\\lib;'

proc = subprocess.Popen(
    [r'D:\\VS2013\\VC\\bin\\cl.exe', '/nologo', '/c', '/MT', '/O2',
     '/I..\\include', '/I..\\src',
     '/DWIN32', '/DNDEBUG', '/D_LATALE_SERVER',
     'source.cpp'], env=env)
```

### Windows Kits SDK Paths by VS Version

| VS Version | Windows Kits Path |
|------------|-------------------|
| VS2010/2012 | `C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v7.0A\\` |
| VS2013 | `C:\\Program Files (x86)\\Windows Kits\\8.0\\` |
| VS2015/2017 | `C:\\Program Files (x86)\\Windows Kits\\8.1\\` or `10\\` |
| VS2019/2022 | `C:\\Program Files (x86)\\Windows Kits\\10\\` |

### Repair Options for Broken VS/.NET

1. **SFC**: `sfc /scannow`
2. **DISM**: `dism /online /cleanup-image /restorehealth`
3. **.NET Repair Tool**: Microsoft's `NetFxRepairTool.exe`
4. **Windows in-place upgrade**

### Quick PE File Analysis

```python
import struct
with open(path, 'rb') as f:
    f.seek(0x3C); pe_offset = struct.unpack('<I', f.read(4))[0]
    f.seek(pe_offset + 4); machine = struct.unpack('<H', f.read(2))[0]  # 0x14c=i386
    f.seek(pe_offset + 92); subsystem = struct.unpack('<H', f.read(2))[0]  # 2=GUI, 3=CONSOLE
```