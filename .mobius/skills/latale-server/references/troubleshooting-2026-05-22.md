# 自建服务器排障记录 — 2026-05-22

## 问题链

### 1. 樱花网关 IP 校验失败
**现象**：网关启动后报 `【通用_启动】配置IP与数据库IP不一致，运行失败` 8 次。
**根因**：`configure.ini` GS181 和 `configure_share.ini` LobbyServer 残留外网 PublicIP（121.204.252.173 / 183.136.213.131）
**修复**：全部改为 127.0.0.1

### 2. LoginServer ODBC 连接失败
**现象**：`Error=[IM008] [Microsoft][ODBC SQL Server Driver]对话失败`
**根因**：三个 ODBC ini 文件用 `Ciel/123456` 但 Ciel 不是 SQL Server 登录名（仅存在于 tbluAccount 表）
**修复**：ODBC ini 中 Ciel→sa，并 `ALTER LOGIN sa WITH PASSWORD='123456'` 重置 sa 密码

### 3. 客户端连接失败
**现象**：服务端全部正常，客户端报"连接失败"
**根因**：客户端 `_单机登陆-爱游网单整理.bat` 和 `IP.ini` 指向 `192.168.200.128`（旧IP），非 127.0.0.1
**修复**：
- `IP.ini`: IP=127.0.0.1
- bat: `/LoginServer:127.0.0.1:19999`

### 4. 账号在线注册失败
**现象**：`【游戏】在线注册失败 错误代码|-1|账号|Ciel`
**根因**：Ciel 账号已存在于 tbluAccount，网关在线注册无法覆盖
**解决**：换全新账号名登录，或通过 SQL 直接注册

### 5. 通讯锁（二级密码）提示
**现象**：进入游戏弹"请拨打通讯锁进行验证"
**根因**：`tbluAccount.jqm` 列存储通讯锁 PIN
**修复**：`UPDATE tbluAccount SET jqm='' WHERE ID='账号'`

### 6. 服务端进程秒退
**现象**：从 bash 终端后台启动 MgmtServer/AS 等进程，端口不监听，MgmtServer 秒退显示 `OnCleanup`
**根因**：Latale 服务端是 Windows 控制台程序，需要网关的启动环境/依赖顺序
**解决**：通过网关 GUI「控制台→一键启动」拉起

## 配置修改后必须重启网关

网关不自动重载配置。修改 configure.ini/share.ini/ODBC 后必须：
1. `taskkill /F /IM 彩虹岛樱花网关.exe`
2. 重新启动网关
3. 网关重新初始化时读取新配置
