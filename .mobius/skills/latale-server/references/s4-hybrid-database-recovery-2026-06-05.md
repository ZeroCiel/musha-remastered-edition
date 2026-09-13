# S4 Hybrid Database Recovery (2026-06-05)

## Background

用户本机有三个SQL引擎:
- `C:\JSQL2008` — JSQL2008（第三方封装的SQL Server 2008 R2, 端口59157）
- `D:\LaTale\S4chd\数据库\LiteSQL2014_Release\` — LiteSQL 2014 (端口2433)
- `D:\LaTale\S4\数据库\LiteSQL2022\` — LiteSQL 2022 (端口2433, 时间过期)

所有数据库的数据文件（master.mdf, dbLataleAccount.MDF, dbLataleWorld_2.mdf等）都在 `C:\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\Data\` 下共享。

## 崩溃时序

1. LiteSQL2014 本来在运行（端口2433）
2. 手动停了2014，把 LiteSQL2022 端口从2433改为59157后启动
3. LiteSQL2022时间过期（授权到期），启动后 master 被它尝试初始化但失败
4. 切回 LiteSQL2014 改端口59157启动 — master.mdf 已被2022损坏
5. 切回 JSQL2008 — 报错1814，无法启动

## 修复

**关键发现**：三个SQL引擎共享 `C:\JSQL2008\` 的数据文件。当其中一个损坏master后，数据文件（dbLataleAccount.MDF, dbLataleWorld_2.mdf）本身并未丢失。

**恢复方案**：启动任一功能正常的 LiteSQL 版本，将端口设为59157即可。LiteSQL自动读取 `C:\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\Data\` 下的数据文件。

**已验证方案**：
1. 修改 `D:\LaTale\S4chd\数据库\LiteSQL2014_Release\SConfig.ini` → `ServPort=59157`
2. 杀掉所有旧SQL进程：`taskkill //F //IM LiteSQL.exe; taskkill //F //IM sqlservr.exe`
3. 启动 LiteSQL2014 的 `LiteSQL.exe`
4. 验证：`netstat -ano | grep 59157` → LISTENING
5. SQL验证：`sqlcmd -S 127.0.0.1,59157 -U sa -P 123456 -Q "SELECT name FROM sys.databases"` → 能看到 dbLataleAccount 和 dbLaTaleWorld_2 均为 ONLINE

## JSQL2008 第三方引擎性质

JSQL2008不是标准SQL Server 2008安装，而是第三方封装的绿色版（通过 jinstall.bat 注册服务、JSQL_Helper.exe 管理）。包含的配套文件：
- jinstall.bat / jstart.bat / jstop.bat / juninstall.bat — 服务启停脚本
- JSQL_Helper.exe — 管理界面
- jinstall.reg — 注册表配置导入

不能通过微软官方升级路径升级到SQL 2014。

## RunAsDate_cn.exe 绕过时间验证

LiteSQL2022 授权过期时用 RunAsDate_cn.exe 绕过：
- GUI操作（推荐）：双击 RunAsDate_cn.exe → 选 LiteSQL.exe → 设日期 01-01-2024 → 确定
- 命令行（不稳定，日期格式因系统区域而异）：`RunAsDate_cn.exe /f LiteSQL.exe /d 01-01-2024`
- 配置在 RunAsDate_cn.cfg 中，需要改路径（Filename=D:\LaTale\S4\数据库\LiteSQL2022\LiteSQL.exe）
- **注意**：RunAsDate_cn.exe 本身也是GUI程序。中文路径在cmd/msys2下可能乱码。在资源管理器双击最可靠。
