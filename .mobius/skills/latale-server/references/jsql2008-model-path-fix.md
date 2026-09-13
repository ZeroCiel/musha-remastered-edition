# JSQL2008 SQL Server 2008 R2 绿色版 — model 路径错误修复

## 背景

JSQL2008 是第三方打包的 SQL Server 2008 R2 (10.50.6000.34) 绿色免安装版。它注册为 Windows 服务 `MSSQL$JSQL2008`，端口 59157。

2026-06-06 发现：本机之前装了 SQL2014 和 SQL2022，它们覆盖了 JSQL2008 的 master.mdf。新 master 中记录的 model 数据库文件路径是构建机上的临时路径，导致 SQL 启动后立即关闭。

## 诊断过程

### 1. 发现服务但无法启动

```
wmic service where 'name like "%SQL%"' get name,pathname
→ MSSQL$JSQL2008  C:\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\Binn\sqlservr.exe -sJSQL2008
```

`net start MSSQL$JSQL2008` → 错误 1814（`The named resource could not be found`）

### 2. ERRORLOG 分析

ERRORLOG 路径：`C:\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\Log\ERRORLOG`

关键错误行（用 `cat -v` 读取 UTF-16LE 编码的日志）：

```
Error: 17204, FCB::Open failed: Could not open file e:\sql10_main_t.obj.x86fre\sql\mkmastr\databases\objfre\i386\model.mdf
Error: 5120, Unable to open the physical file "e:\sql10_main_t.obj.x86fre\sql\mkmastr\databases\objfre\i386\model.mdf"
Error: 17207, FileMgr::StartLogFiles: OS error 2 occurred while creating or opening file 'e:\sql10_main_t.obj.x86fre\sql\mkmastr\databases\objfre\i386\modellog.ldf'
Database 'model' cannot be opened due to inaccessible files
Error: 945, Could not create tempdb
```

**根本原因**：`e:\sql10_main_t.obj.x86fre\` 是微软构建编译机的路径。SQL Server 2008 R2 的 master 数据库中硬编码了 model 和 msdb 的原始文件路径，当 master.mdf 被用不当方式复制/覆盖后，这些路径没有更新。

### 3. 实际文件位置

```
C:\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\DATA\model.mdf       ← 存在
C:\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\DATA\modellog.ldf    ← 存在
C:\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\DATA\MSDBData.mdf    ← 存在
C:\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\DATA\MSDBLog.ldf     ← 存在
```

## 修复方案

详见 SKILL.md 中的 `JSQL2008 model 路径错误导致启动后自动关闭` 节。

核心思路：`-T3608` 跳过非 master 数据库恢复 → 用 `ALTER DATABASE ... MODIFY FILE` 修正路径。

## 经验教训

1. **不要跨版本复制 master.mdf** — 不同版本的 SQL Server 的 master.mdf 格式可能不同，即使版本号相同，内部路径记录也可能被污染
2. **绿色版 master 路径脆弱** — JSQL2008 这种绿色版没有标准安装流程，master 中的文件路径非常容易被破坏
3. **ERRORLOG 是 UTF-16LE 编码** — 在 git-bash 里用 `cat -v` 读取，或者用 PowerShell 的 `Get-Content` 读取
4. **多 SQL 实例共存时，优先用 LiteSQL 管理** — LiteSQL2014/2022 是独立引擎，不依赖系统服务注册表，更适合多版本切换