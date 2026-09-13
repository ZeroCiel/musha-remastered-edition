# S2 端口映射表

当云电脑/服务器商只给有限端口段（如 41470~41479），而服务端监听默认端口时，需要端口映射。

## 常用映射

| 服务 | 进程名 | 原端口 | 外网端口 |
|------|--------|-------|---------|
| LoginServer | LataleLoginServer.exe | 19999 | 41470 |
| MgmtServer(MS) | LataleMgmtServer.exe | 10001 | 41471 |
| LobbyServer | LataleLobbyServer.exe | 10002 | 41472 |
| GameServer_101 | Latalegameserver_101.exe | 10003 | 41473 |
| GameServer_151 | Latalegameserver_151.exe | 10005 | 41474 |
| BayServer(商城) | LataleBayServer.exe | 10006 | 41475 |
| RoomServer(副本) | LataleRoomServer.exe | 10007 | 41476 |
| GameServer_102 | Latalegameserver_102.exe | 20003 | 41477 |
| ASServer | LataleAS.exe | 10020 | 41478 |
| 备用 | - | - | 41479 |

## 改配置文件法

修改 `configure.ini` 和 `configure_share.ini` 中每个服务的 `port=` 字段。

**注意**：
- 只改服务的 `port=XXXX`（小写），不改 `Port=XXXX` 或 `PORT=XXXX`（那些是内部引用地址）
- 两个文件都要改，保持一致
- 改完后重启所有 GS 进程
- `configure_share.ini` 中 `PublicIP` 建议一并改为 `127.0.0.1`（旧值可能是以前的公网 IP）

## netsh 端口转发法（不改配置，更安全）

```powershell
netsh interface portproxy add v4tov4 listenport=41470 connectport=19999 connectaddress=127.0.0.1
netsh interface portproxy add v4tov4 listenport=41471 connectport=10001 connectaddress=127.0.0.1
netsh interface portproxy add v4tov4 listenport=41472 connectport=10002 connectaddress=127.0.0.1
netsh interface portproxy add v4tov4 listenport=41473 connectport=10003 connectaddress=127.0.0.1
netsh interface portproxy add v4tov4 listenport=41474 connectport=10005 connectaddress=127.0.0.1
netsh interface portproxy add v4tov4 listenport=41475 connectport=10006 connectaddress=127.0.0.1
netsh interface portproxy add v4tov4 listenport=41476 connectport=10007 connectaddress=127.0.0.1
netsh interface portproxy add v4tov4 listenport=41477 connectport=20003 connectaddress=127.0.0.1
netsh interface portproxy add v4tov4 listenport=41478 connectport=10020 connectaddress=127.0.0.1
```

**注意**：端口转发需要管理员权限，重启后失效（可以用计划任务开机自启）。
