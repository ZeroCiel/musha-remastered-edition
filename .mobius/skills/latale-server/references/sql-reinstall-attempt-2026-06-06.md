# SQL Server 重装尝试记录（2026-06-06）

## 背景

JSQL2008 实例的 master.mdf 被 SQL2014/2022 覆盖过，model 数据库路径指向错误编译路径（`e:\sql10_main_t.obj.x86fre\...`），SQL 启动后立即自动关闭。
使用 `-T3608` 跳过 model 修复的方案之前已试过但 master 本身也被污染，最终决定：**删干净重装**。

## 清理流程（成功）

```bash
# 1. 停服务
net stop MSSQL$JSQL2008
sc delete MSSQL$JSQL2008

# 2. 删注册表
reg delete "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL10_50.JSQL2008" /f
reg delete "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" /v JSQL2008 /f
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\MSSQL$JSQL2008" /f

# 3. 杀进程
taskkill /f /im sqlservr.exe

# 4. 删目录
rm -rf /c/JSQL2008/
```

**坑**：`Device or resource busy` 表示 sqlservr.exe 进程还在后台占着 master.mdf。必须 kill 后再删。
在 git-bash 里 `net stop "MSSQL$JSQL2008"` 会因 `$` 被 bash 展开而失败。用 `\` 转义或写 .cmd 批处理文件执行。

## 重装尝试（失败）

### 安装介质

`C:\lataledb\SQLEXPR_x64_CHS.exe` — 文件名暗示是 SQL2008 R2 Express，但实际是 **SQL2022 Express**。
验证方法：解压后的 `MEDIAINFO.XML` 中 `<Property Id="BaselineVersion" Value="16.0.1000.6" />`。
不要信 exe 文件名！

### 静默安装配置

```ini
[OPTIONS]
QUIETSIMPLE="True"
IACCEPTSQLSERVERLICENSETERMS="True"
ACTION="Install"
UpdateEnabled="False"
INSTANCENAME="JSQL2008"
FEATURES=SQLENGINE
SECURITYMODE="SQL"
SQLSYSADMINACCOUNTS="BUILTIN\Administrators"
SAPWD="123456"
ERRORREPORTING="False"
SQMREPORTING="False"
INSTANCEDIR="C:\JSQL2008"
SQLUSERDBDIR="C:\JSQL2008\MSSQL16.JSQL2008\MSSQL\DATA"
SQLUSERDBLOGDIR="C:\JSQL2008\MSSQL16.JSQL2008\MSSQL\DATA"
TCPENABLED="1"
NPENABLED="1"
SQLSVCSTARTUPTYPE="Automatic"
BROWSERSVCSTARTUPTYPE="Disabled"
```

### 已知参数陷阱

| 你的配置 | 问题 | 说明 |
|---------|------|------|
| `TCPPORT=59157` | ❌ SQL2022 不识别 | SQL2022 参数名应为 `TcpPort`（首字母大写），不是 `TCPPORT` |
| 不指定 `BROWSERSVCSTARTUPTYPE` | ❌ 如果之前 `sc delete SQLBrowser` 清过服务，安装器在 `FinalCalculateSettingsAction` 查 SQLBrowser 服务启动账户时会报"系统找不到指定的文件" | 该服务虽然被删了，但安装器的 SQLBrowser 配置模块仍尝试查询它的旧配置，结果拿到空路径 |
| 自解压包没有 `/Extract` 参数 | ❌ `SQLEXPR_x64_CHS.exe /ConfigurationFile=...` 执行的是旧的引导参数逻辑，不是真正的 setup | 建议用解压后的 `x64\setup\setup.exe` 直连 |

### 静默安装失败现象

- 所有 4 次尝试的 exit code 都是 `-2068119551`（1211 facility / error 1）
- `Detail.txt` 中错误全部出现在 `FinalCalculateSettingsAction`，堆栈指向 `SqlBrowserPublicConfig.CalculateUserNamePassword()`
- 解决方案：先删 SQLBrowser 服务残留 → 重启 → 再试；或用已解压的 setup.exe 而不是 .exe 引导器

### 当前状态

JSQL2008 已卸载干净。系统上只剩 `SQLWriter` 服务存活。
建议：
- 方案A：找一个真正的 SQL Server 2008 R2 Express 安装包（文件名 `SQLEXPR_x86_x64_CHS.exe`，Version 10.x）
- 方案B：用 `C:\lataledb\SQLEXPR_x64_CHS\` 下已解压的文件，是 SQL2022 Express，可以手动双击 setup 装
- 方案C：恢复旧备份的业务库（`account.bak` + `world.bak` 在 `C:\lataledb\`），选一个完全不同的 SQL 版本实例

## 2026-09-01 安装成功记录（同一台机器，SQL2022 Express 默认实例）

**最终成功状态**：MSSQLSERVER 服务 RUNNING，1433 监听，sqlcmd 可连，`dbLaTaleAccount-332`/`dbLaTaleWorld_2-332` 恢复 ONLINE，sa 可登录（SAPWD 来自 ConfigurationFile.ini）。

**这次实际踩的坑链（按出现顺序，每个都是独立拦路虎）：**

1. **已装的 OLE DB Driver 残留 → MSI 1706/1603**：`SQL_SNAC_SDK_msoledbsql_Cpu64` 失败，日志 `MSI Error: 1706 找不到产品 Microsoft OLE DB Driver for SQL Server 的安装包`。原因：注册表里有旧版 OLE DB Driver 18.7.4.0 但安装源缓存丢失，SQL setup 试图升级它时无法解析源。**修法：先卸载残留**：`msiexec /x {产品GUID} /qn /norestart`（GUID 从 `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall` 查 DisplayName="Microsoft OLE DB Driver for SQL Server"）。
2. **SQLBrowser 服务被 sc delete 过 → 引擎安装时 `ScoException: 指定的服务未安装`（Win32 1060）**：错误出现在 `SqlBrowserConfigEngAction_install_ConfigNonRC_Cpu64`，日志 `SQL Server Browser Install for feature SQL_Engine_Core_Inst failed`。注意：6 月的 `CalculateUserNamePassword` 报错点这次正常跳过了（"service does not exist" 正常处理），卡在**安装 SQL Browser 服务**的 action。**修法：手动重建服务**：`sc create SQLBrowser binpath= "\"C:\Program Files\Microsoft SQL Server\160\Tools\Binn\SqlBrowser.exe\"" start= disabled displayname= "SQL Server Browser"`。
3. **C 盘空间不足（SQL 需 ~1GB）**：报 `目录 C:\Program Files\Microsoft SQL Server\ 中的可用空间不足。此操作需要 0MB... 总共需要 994MB。可用空间为 201MB`（错误 -2054422471/1420/57）。**修法：清 C 盘**。本机大头：`C:\Users\Administrator\AppData\Local\Temp`（7.3G！）+ `Setup Bootstrap\Log` 旧失败日志（861M）+ 回收站。
4. **SQLSVCACCOUNT="NT AUTHORITY\SYSTEM" → RPC 1722**：日志 `Sco: Unable to return managed service account info about user NT AUTHORITY\SYSTEM, Win32 Error code 1722`（RPC 服务器不可用，即使 RpcSs/RpcEptMapper 都 RUNNING），随后 `InputSettingValidationException@1204@2`。**修法：SQLSVCACCOUNT 改用虚拟账户** `NT Service\MSSQLSERVER`（SQL 2012+ 推荐，setup 内部处理不触发 RPC 账户查询）。同时删掉 AGTSVCACCOUNT 行。
5. **注册表实例残留 → 配置验证失败**：Instance Names\SQL 里 `MSSQLSERVER → MSSQL12.MSSQLSERVER`（SQL2014 实例 ID，历史残留），安装器以为已有同名实例走升级路径 → `InputSettingValidationException@1204@2`（ConfigurationValidationFailure，查 `MSSQL12.MSSQLSERVER\ConfigurationState` 时挂）。**修法：清注册表残留**（只清目标实例，别碰其他实例如 S4chd/JSQL2008）：
   ```bash
   reg delete "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER" /f
   reg delete "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.MSSQLSERVER" /f   # 之前失败安装的 2022 残留
   reg delete "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQLServer" /f          # 无版本前缀的旧键
   reg delete "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" /v MSSQLSERVER /f
   reg add "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server" /v InstalledInstances /t REG_MULTI_SZ /d "S4chd" /f  # 重建列表
   ```
   再删残留目录 `rm -rf "C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER"`。

**经验**：SQL2022 静默安装失败是"坑链"——修完一个立刻露出下一个。每次失败后看 `Setup Bootstrap\Log\<最新>\Detail.txt`（GBK 编码，Python `decode('gbk')` 读），找 `错误结果: -xxxx / 结果设备代码 / 结果错误代码` + `failed during execution` 的 action 名 + 前面的 Sco/Win32 异常行。常用错误码：`-2068119551`(1211 SQLBrowser 配置)、`-2068052310`(1212 msoledbsql 源)、`-2054422471`(1420 磁盘)、`-2068578302`(1204 输入配置验证)。
