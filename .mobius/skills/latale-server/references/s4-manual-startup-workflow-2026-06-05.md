# S4端手动启动工作流（网关不靠谱时使用）

## 背景

2026-06-05 实测：D:\LaTale\S4\ 端的 `网关.exe` 和 `LaS4服务端.exe` 启动器都无法让 GameServer 存活。
- LaS4服务端.exe：弹窗后无反应（可能读取加密 .inis 失败）
- 网关.exe：一键改路径后自动拉起了 AS、BayServer、MgmtServer、RoomServer，但 LoginServer、LobbyServer、ToolServer、GameServer 没起来
- **手动逐个启动反而全活了**

## 配置修复

启动前需要修 `configure.ini` 的 `[ConfigurePath]` 引用：

**改之前（指向S4chd）：**
```
[ConfigurePath]
Share=D:\LaTale\S4chd\bin2\configure_share.inis
ODBC=D:\LaTale\S4chd\bin2\Global_ODBC.inis
IPFILTER=D:\LaTale\S4chd\bin2\IPFiltering.inis
```

**改之后（指向自身）：**
```
[ConfigurePath]
Share=D:\LaTale\S4\bin2\configure_share.inis
ODBC=D:\LaTale\S4\bin2\Global_ODBC.inis
IPFILTER=D:\LaTale\S4\bin2\IPFiltering.inis
```

## 手动启动命令

```powershell
# 在 cmd 中执行（逐个开窗口）
start D:\LaTale\S4\bin2\LataleAS.exe /Debug 1
start D:\LaTale\S4\bin2\LataleBayServer.exe /Debug 1
start D:\LaTale\S4\bin2\LataleLobbyServer.exe /Debug 1
start D:\LaTale\S4\bin2\LataleLoginServer.exe /Debug 1
start D:\LaTale\S4\bin2\LataleMgmtServer.exe /Debug 1
start D:\LaTale\S4\bin2\LataleRoomServer.exe /Debug 1
start D:\LaTale\S4\bin2\LataleToolServer.exe /Debug 1
start D:\LaTale\S4\bin2\LataleGameServer.exe /ServerID 101 /Debug 1
start D:\LaTale\S4\bin2\LataleGameServer.exe /ServerID 102 /Debug 1
start D:\LaTale\S4\bin2\LataleGameServer.exe /ServerID 151 /Debug 1
```

## 端口映射（S4端）

| 服务 | 端口 |
|------|------|
| LoginServer | 20200 |
| MS | 10001 (以及10021/10024可能有重复段) |
| LobbyServer | 10002 |
| LobbyServer(World2) | 20002 |
| GameServer_101 | 11023 |
| GameServer_102 | 11024 |
| GameServer_103 | 11025 |
| GameServer_104 | 11026 |
| GameServer_105 | 11027 |
| GameServer_151(Indun) | 11151 |
| GameServer_152(Indun) | 11152 |
| GameServer_181(PVP) | 11181 |
| BayServer | 10006 |
| RoomServer | 10007 |
| ASServer | 10020 |
| ToolServer | 9001 |

## S4端 resource/ 目录内容（原始状态）

只有3个SPF：
- AJJIYA.SPF（50MB）
- JINSSAGA.SPF（65MB）
- ROWID.SPF（148MB）

相比S2的完整resource目录（BANX、GUSTAV、HOSHIM、MAKO1298、METALGENI等），缺少大量地图/怪物/UI资源。如果想用S2素材替换S4，需要把S2的SPF拷到S4的resource/目录下覆盖，但exe读LDT的列结构可能不兼容（S4版LDT可能有新增字段）。

## 客户端登录参数（S4端）

```
start LaTaleClient.exe /Full /LoginServer:127.0.0.1:20200 /Run:VHIGH /LOCALE:GSP /PUBLISHER:GSP
```

## 经验教训

1. **网关不靠谱 → 手动启动**：自动拉起的进程可能部分存活部分崩，手动启动能看到每个exe的控制台窗口，容易定位问题
2. **configure.ini的[ConfigurePath]经常引用别的版本路径**：新下载的端往往指向S4chd或其他版本，需要改成自身目录
3. **[MS]段可能有重复**：配置被人乱拼过，需要去重
4. **中文exe名启动问题**：msys2/bash下中文文件名解析失败，cmd下代码页可能也不匹配。解决办法是把exe复制成英文名再调用
