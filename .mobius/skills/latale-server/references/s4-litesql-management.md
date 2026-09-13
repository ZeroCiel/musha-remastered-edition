# S4端 LiteSQL 数据库引擎管理

## 背景

S4chd/S4 端使用 LiteSQL（绿色免安装版 SQL Server）作为数据库引擎。本机有两个版本：

| 版本 | 路径 | 默认端口 |
|------|------|---------|
| LiteSQL2014 | `D:\LaTale\S4\数据库\LiteSQL2014_Release\` | 2433 |
| LiteSQL2022 | `D:\LaTale\S4\数据库\LiteSQL2022\` | 2433 |

本机另有 JSQL2008（SQL2008，端口 59157，实例名 JSQL2008）作为主要数据库。

## 端口冲突

所有 LiteSQL 版本默认都监听 2433。不能两个同时跑。本机 GS 配置的数据库连接在 `Global_ODBC.ini`（S2明文）或 `Global_ODBC.inis`（S4加密）中。

### 改为 59157 端口（兼容SQL2008）

1. 编辑 `SConfig.ini`：`ServPort=59157`
2. 停掉旧 LiteSQL：`taskkill //F //IM LiteSQL.exe` + `taskkill //F //IM sqlservr.exe`（sqlservr可能多个）
3. 启动新 LiteSQL（见下方）

## LiteSQL2022 时间过期问题

### 症状
```
Lite SQL ver:2024.1.21.2545
注册无效,授权已过期.
序列号:BBF5-6392-411E-B05B
```

### 原因
LiteSQL 有时间验证，过期后拒绝启动。

### 修复方案：RunAsDate_cn.exe

LiteSQL2022 目录下自带 `RunAsDate_cn.exe`（时间绕过工具）。

**配置（RunAsDate_cn.cfg）：**
```ini
[General]
Filename=D:\LaTale\S4\数据库\LiteSQL2022\LiteSQL.exe
Params=
ShortcutName=SQL2022
DateTimeMode=1
AddTimeUnit=4
AddTimeValue=-1
DateTime=01-01-2024 00:00:00
```

**启动方式：**
- 最可靠：在资源管理器双击 `SQL2022.lnk`（预先配置好的快捷方式）
- 或在 `RunAsDate_cn.exe` 的图形界面中配置目标路径，然后点"创建桌面快捷方式"，后续双击快捷方式启动

**注意：** RunAsDate_cn.exe 本身也是 GUI 程序。中文路径在 cmd/msys2 下可能乱码导致找不到 exe。

## 切换数据库引擎的完整步骤

从 LiteSQL2014 切换到 LiteSQL2022（端口 59157）：

1. 检查 `SConfig.ini` 的 `ServPort=59157`
2. 杀掉所有旧 SQL 进程
3. 用 RunAsDate_cn.exe（或快捷方式）启动 LiteSQL2022\LiteSQL.exe
4. 验证端口监听：`netstat -ano | findstr 59157`
5. GS 配置（`Global_ODBC.ini` / `.inis`）中的连接字符串必须匹配：`127.0.0.1,59157`
