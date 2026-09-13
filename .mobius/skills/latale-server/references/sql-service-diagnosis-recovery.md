# SQL 服务掉线诊断与恢复（LiteSQL / SQL Server）

## 现象

服务端提示"数据库无法连接"或客户端登录时报数据库错误。

## 诊断步骤

### 1. 检查 SQL 进程

```cmd
tasklist | findstr sqlservr
tasklist | findstr LiteSQL
```

- `sqlservr.exe` 存在 → SQL Server 正在运行
- `LiteSQL.exe` 存在 → LiteSQL 管理器正在运行
- **两者都不存在** → SQL 服务已退出

### 2. 检查端口

```cmd
netstat -ano | findstr "2433"
netstat -ano | findstr "59157"
```

S4chd 的 Global_ODBC.ini 配的是 **2433** 端口。旧版（S2他乡）配的是 **59157**。

### 3. 检查数据库文件

数据库文件位置：
- `D:\LaTale\S4chd\数据库\LiteSQL2014_Release\MSSQL\DATA\`
- `D:\LaTale\S4chd\数据库\LiteSQL2022\MSSQL\DATA\`

关键文件：`dbLaTaleAccount.mdf`（账号库，~23MB）、`dbLaTaleWorld_2.mdf`（角色库）

## 常见根因

**sqlservr.exe 进程静默退出**（非崩溃，无 dmp）。PID 消失，端口释放。

可能原因：
1. 系统内存不足被 OOM killer 杀掉
2. 多个 SQL 实例冲突（端口占用）
3. 重装系统后 SQL 未重新启动
4. 系统更新后 SQL 服务未自动恢复

## 恢复步骤

### 情况 A：LiteSQL 方式（推荐）

LiteSQL 是免安装 SQL Server 管理器，非 Windows 服务。

```cmd
cd /d D:\LaTale\S4chd\数据库\LiteSQL2014_Release
LiteSQL.exe
```

或直接双击 `LiteSQL.exe`。

- 等 5-10 秒后验证端口：`netstat -ano | findstr 2433`
- 检查 SQL 进程：`tasklist | findstr sqlservr`
- LiteSQL 窗口不要关闭，关闭即停 SQL。

**LiteSQL2022 版本也在同目录下**，如果 2014 版本启动失败可以试 2022 版本。但需注意 Global_ODBC.ini 中的端口是否匹配。

### 情况 B：JSQL2008 方式（旧版）

旧版 S2 服务端依赖 `C:\\JSQL2008\\` 的硬编码路径。

```cmd
cd /d C:\\JSQL2008
jstart.bat
```

如果服务未注册，先运行 `jinstall.bat`（需管理员权限）。

验证：`sc query MSSQL$JSQL2008` → 应显示 `STATE: 4 RUNNING`

**如果启动后立即关闭（错误 1814）**：ERRORLOG 中报 `FCB::Open failed: Could not open file e:\\sql10_main_t.obj.x86fre\\...\\model.mdf`。

这是 model 数据库路径被写死为编译机路径。修复方法：
1. 用 `-T3608` 跳过 model 恢复启动：`start /B "" "C:\\JSQL2008\\MSSQL10_50.JSQL2008\\MSSQL\\Binn\\sqlservr.exe" -sJSQL2008 -T3608`
2. 用 sqlcmd 连接后 `ALTER DATABASE model MODIFY FILE (NAME = modeldev, FILENAME = 'C:\\JSQL2008\\MSSQL10_50.JSQL2008\\MSSQL\\DATA\\model.mdf')`
3. 同样修改 modellog
4. 停止进程，正常用 `net start "MSSQL$JSQL2008"` 启动

详见 skill 本体 `JSQL2008 model 路径错误导致启动后自动关闭` 节及 `references/jsql2008-model-path-fix.md`。

### 验证恢复成功

1. 端口监听恢复
2. 服务端 exe 启动后不再报 ODBC/数据库错误
3. 客户端登录正常

## S4chd 数据库文件验证

**数据库共通性**：S2/S3/S4 使用同一套数据库结构，账号完全通用。

| 数据库文件 | 用途 | 通用性 |
|-----------|------|--------|
| `dbLaTaleAccount.mdf` | 账号库（用户名+密码） | ✅ S2/S3/S4 通用 |
| `dbLaTaleWorld_2.mdf` | 角色库（角色数据+物品） | ✅ S2/S3/S4 通用 |

所有版本的表结构从未变过，因为都源于同一套官方源码。同一个 LiteSQL 实例上注册的账号，换 LoginServer 端口就能在不同版本间登录。
