# 彩虹岛 S2 远程 GS 连接配置与虚拟组网经验

## 客户端配置

### 配置文件
彩虹岛 S2 客户端的连接配置在两个地方：

1. **IP.ini**（客户端根目录）
```ini
[PublicIP]
IP=服务端IP
```

2. **登陆.bat**（客户端根目录）
```bat
start LaTaleClient.exe /Windowed /LoginServer=服务端IP:19999 /Run:VHIGH /LOCALE:TAIWAN /PUBLISHER:GAMEFLIER
```

LoginServer 默认端口 **19999**，确认远程 GS 上该端口已监听：
```powershell
netstat -ano | findstr 19999
```

### 连接状态验证
本地 `netstat -ano | findstr 19999` 出现 `ESTABLISHED` 说明 TCP 连接已建立，但进不了游戏说明后续验证/心跳有问题。

## 虚拟组网方案对比

### 1. EasyN2N (P2P VPN)
- **优点**：免费，无账号
- **缺点**：UDP 打洞不稳定，P2P 直连成功率低，依赖 SuperNode
- **典型问题**：两边显示"已连接"但互相 ping 不通；游戏连接几秒后掉线
- **免费 SuperNode**：`n2n.s1.bugxia.com:16540`（IP 172.31.22.239）

### 2. Radmin VPN
- **优点**：免费（英文原版，中文站收费），比 N2N 稳定，自动打洞 + 中继
- **缺点**：需要注册账号
- **下载**：https://www.radmin-vpn.com/
- **典型延迟**：~100ms 内可玩

### 3. SSH 直连（需公网端口）
- **条件**：远程机公网 IP + 端口映射
- **云电脑服务商场景**：通常只转发了 RDP 端口（3389），22 端口不通
- **可通过管理面板加端口转发**，或 frp/ngrok 穿透

## 游戏连接掉线诊断

### "连上 5 秒掉线，不重启客户端不能重连"

**根因分析**：
1. **网络不稳定**（最常见）— VPN/P2P 隧道抖动导致游戏心跳包丢失，服务端踢掉客户端
2. **服务端会话表未释放** — 断线后旧 session 还在，新连接被拒绝，重启客户端换本地端口才能重连
3. **LoginServer IP/端口白名单** — 检查客户端来源 IP 是否在允许范围内

**排查步骤**：
1. 在**远程机上本地启动客户端**测试 — 如果不掉线，100% 是网络隧道问题
2. 检查樱花网关（LoginServer）窗口日志 — 有没有"同一账户重复登录"/"IP限制"等提示
3. 检查 GS 配置中是否有 SessionTimeOut / ClientCheckTime 参数

### 云电脑/服务器商场景特征
- 内网 IP 通常为 172.x.x.x 段
- 公网 IP 是 NAT 共享 IP（运营商级 NAT）
- 默认只开放 RDP 端口
- 2G 内存跑完整 GS 集群会资源吃紧，可能间接导致连接不稳定
