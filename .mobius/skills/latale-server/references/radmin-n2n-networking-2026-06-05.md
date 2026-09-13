# Radmin VPN + S2 端口映射经验 (2026-06-05)

## 背景

远程彩虹岛 S2 服务器（云电脑）无公网端口转发（22/19999等端口都不通公网）。需通过虚拟组网穿透连接。

## 方案对比

| 方案 | 结果 | 原因 |
|------|------|------|
| EasyN2N (43.138.138.38:40063) | 两边都能连SuperNode但彼此发现不了 | P2P打洞失败，SuperNode中转也没生效 |
| ngrok TCP | 免费版需要绑信用卡验证 | ERR_NGROK_8013 |
| SSH直连公网IP | 超时 | 无端口转发 |
| Radmin VPN | **成功** | P2P打洞成功，延迟~90ms |

## Radmin VPN 配置

1. https://www.radmin-vpn.com/ 下载英文版（免费）
2. 两台机器都装，加入同一网络
3. 分配的虚拟IP段：`26.x.x.x`

## S2 端口映射（店家给41470~41479时）

### 需改的文件
- `configure.ini` — 各服务 `port =` 字段
- `configure_share.ini` — 各服务 `port =` 字段 + `[MS] Port =` 引用

### 映射表
| 服务 | 原端口 | 新端口 |
|------|-------|-------|
| LoginServer | 19999 | 41470 |
| MgmtServer(MS) | 10001 | 41471 |
| LobbyServer | 10002 | 41472 |
| GameServer_101 | 10003 | 41473 |
| GameServer_151 | 10005 | 41474 |
| BayServer | 10006 | 41475 |
| RoomServer | 10007 | 41476 |
| GameServer_102 | 20003 | 41477 |
| ASServer | 10020 | 41478 |

### 容易漏改的点
1. **`[MS] Port =` 引用** — configure.ini 和 configure_share.ini 里的 `Port = 10001` 指向 MS，MS端口改了这里也一定要改，否则 GS 注册不到 MS，频道列表为空
2. **`BAY_0/1`、`ROOM_0/1` 的 PORT 引用** — 也要同步改
3. **`PublicIP`** — 如果改成 Radmin IP，LoginServer 会校验客户端来源IP并踢人。保持 127.0.0.1 用 netsh 端口转发更安全

## LoginServer IP 校验坑

- PublicIP=127.0.0.1 → 能上登录窗口，但频道列表空白（客户端拿到127.0.0.1连不上Lobby）
- PublicIP=Radmin虚拟IP → 能连但立刻被踢
- 推测：LoginServer会校验客户端连接来源IP是否等于PublicIP，不匹配就踢

## 绕开方案：本地 netsh 端口转发

在本地电脑（管理员 PowerShell）：
```powershell
netsh interface portproxy add v4tov4 listenport=41470 connectport=41470 connectaddress=26.201.194.1
netsh interface portproxy add v4tov4 listenport=41472 connectport=41472 connectaddress=26.201.194.1
netsh interface portproxy add v4tov4 listenport=41473 connectport=41473 connectaddress=26.201.194.1
```

然后客户端连 127.0.0.1:41470，流量通过 netsh 转发到远程机，LoginServer 看到来源IP为127.0.0.1（本地回环），通过校验。

## GS_101 Runtime Error

启动GS_101时出现 `Runtime Error! ... This application has requested the Runtime to terminate it in an unusual way.`

可能原因：
- 配置文件改端口后，exe 读取到不一致的数据导致初始化失败
- 运行库缺失（需安装 VC++ 运行库合集）
- 配置文件中 ResourceDir 路径不存在（如 `D:\�ʺ絺\resource\` 这种乱码路径）
