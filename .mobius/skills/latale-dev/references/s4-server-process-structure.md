# S4 服务进程结构

## 正常运行的进程列表 (2026-06-07 确认)

| 进程 | 说明 | 备注 |
|------|------|------|
| LataleMgmtServer.exe | 管理服务器 | 网关自动启动 |
| LataleAS.exe | 活动服务器 | 网关自动启动 |
| LataleBayServer.exe | 商城服务器 | 网关自动启动 |
| LataleRoomServer.exe | 房间服务器 | 网关自动启动 |
| LataleGameServer.exe ×3 | 游戏频道 | 网关自动启动（101/102/151） |
| Lataleloginserver.exe | 登录服务器 | ❌ 网关不自动启动，需手动 | 
| Latalelobbyserver.exe | 大厅服务器 | ❌ 网关不自动启动，需手动 |

## 网关.exe 启动列表

`网关.exe` 读配置找以下 exe：
- \bin2\LataleLoginServer.vmp.exe
- \bin2\LataleLobbyServer.vmp.exe
- \bin2\LataleAS.exe
- \bin2\LataleMgmtServer.exe
- \bin2\LataleBayServer.exe
- \bin2\LataleRoomServer.exe
- \bin2\LataleGameServer.exe /ServerID 101~105,151

## 为什么 Login/Lobby 不自动启动

网关写死了找 `.vmp.exe`（VMProtect加壳版），但端里只有无壳版。
修复：复制无壳版为 vmp 名
```bash
cp /d/LaTale/S4/bin2/Lataleloginserver.exe /d/LaTale/S4/bin2/LataleLoginServer.vmp.exe
cp /d/LaTale/S4/bin2/Latalelobbyserver.exe /d/LaTale/S4/bin2/LataleLobbyServer.vmp.exe
```

## bin2 目录可用 exe 列表

| exe | 大小 | 说明 |
|-----|------|------|
| Lataleloginserver.exe | ~2MB | 登录服务器（无壳） |
| Latalelobbyserver.exe | ~2MB | 大厅服务器（无壳） |
| LataleGameServer.exe | 4MB | 通用GS（带授权校验） |
| Latalegameserver_101.exe | 2.6MB | 快捷方式(lnk)指向S4chd的GS |
| Latalegameserver_102.exe | 2.6MB | 同上 |
| LataleGameServer101.exe | 4MB | 带机器码校验的GS |
| LataleAS.exe | 活动服务器 |
| LataleBayServer.exe | 商城服务器 |
| LataleMgmtServer.exe | 管理服务器 |
| LataleRoomServer.exe | 房间服务器 |

## 启动顺序

1. 樱花网关.exe（启动基础服务）
2. 手动补起 LoginServer + LobbyServer
3. 客户端登录测试
