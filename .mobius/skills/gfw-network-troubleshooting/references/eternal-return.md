# 永恒轮回 (Eternal Return) 网络排障笔记

Steam AppID 1170950，Nimble Neuron 出品，游戏服务器走 AWS Global Accelerator（韩国区域）。官方公告合集发布于 2020-10-16（"无法进入游戏页面或无法配对时"）。

## 服务器域名 / IP（2026-08 实测）
| 域名 | 解析 IP |
|---|---|
| er-api / er-match / game / er-api-live .nimblelion.com | 13.248.169.48 (AWS GA 13.248.0.0/16) |
| match / live / api / er-live .nimblelion.com | 76.223.54.146 (AWS GA 另一 anycast) |

- `*.nimblelion.com` 通配解析全部指到 AWS GA——客户端实际用哪个子域名 DNS 看不出
- **无 AAAA 记录**（`nslookup -type=AAAA` 报无 IPv6）→ IPv6 出口通也救不了，必须 IPv4 可达
- `api.eternalreturn.game`、`live.eternalreturn.game` 等子域不存在（Non-existent domain），别浪费时间
- 定位方法：nslookup 轮询 nimblelion.com 子域；AWS Global Accelerator 特征段 = 13.248.x.x / 76.223.x.x

## 机器当时状态（2026-08 诊断实录）
- 出口 = 手机 USB 共享热点（Remote NDIS 192.168.42.x / DNS 192.168.42.129），ping 1.1.1.1 = 279ms，国际路由差
- Clash Verge Rev 已装未运行（7897 未监听，ProxyEnable=0，ProxyServer 残留 127.0.0.1:7897）
- Steamcommunity_302 运行中：127.0.0.1:80/443 → 内部端口（443→49851、80→44160），api.steampowered.com 经它转发 200 正常；hosts 900 行 #S302；302 不劫持 nimblelion.com
- Radmin VPN 网卡默认路由 26.0.0.1（metric 高）；公网 IPv6 2408:845d:...（联通）
- 机场订阅（file.13171876.xyz）已 404 = 欠费停服

## 本次诊断结果（2026-08-11）
| 状态 | 结果 |
|---|---|
| 直连 er-api（手机热点） | 10s 超时（curl 000）→ GFW/出口路由问题 |
| 手机开 VPN + USB 共享 | 出口 IP 不变（220.200.127.111 联通）→ USB tethering 不走手机 VPN |
| 电脑装 Cloudflare WARP 后 | 出口变 Cloudflare US 104.28.165.129；TCP 到 13.248.169.48:443 通；TLS 握手被服务器 EOF（schannel SEC_E_ILLEGAL_MESSAGE / openssl unexpected eof） |

结论：TCP 已通 TLS 层被拒疑为 JA3 指纹/IDC 段封锁——curl 不能作为游戏连通判据，最终验证 = 用户直接启动游戏。

## 最终结果（2026-08-11 晚）
- 游戏客户端在 WARP 下能正常登录进大厅，亚洲2 延迟 71ms（之前直连 300-800）→ WARP 方案成功
- 但 **WARP 免费版被对局服务器拒**（Cloudflare IDC 段被反作弊封）：登录/大厅可过，匹配/对局被拒或跳 ping
- 用户实际玩法：WARP 绕过登录 → 切回原网络（手机热点直连）→ 大厅稳定 71ms，打架跳 ping
- 对局跳 ping 未根治：正解是 UU 加速器专线（节点被游戏服务器认可）或宽带 Wi-Fi；机场续费后（机场节点通常不被封）也可
- 教训：WARP 免费版是"登录/大厅加速器"不是"对局加速器"；对局质量取决于专线或出口质量

## 官方排障步骤（玩家侧，2020-10 官方中文公告）
1. 确认主画面右上地球图标旁的服务器已选择（有时不可选）
2. 重启路由器
3. 能进游戏但无法匹配 → 改 IPv6 设置：`Win+R` → `ncpa.cpl` → 网卡属性 → 取消勾选 TCP/IPv6 → 重启；若出网络问题 `cmd` 里 `netsh winsock reset` 再重启
4. 防火墙/杀软放行游戏，必要时临时禁用
5. 关掉 VPN 软件
6. 改 Google Public DNS（8.8.8.8 / 8.8.4.4）：ncpa.cpl → IPv4 属性 → 手动 DNS
7. 路由器 DNS 改手动 8.8.8.8/8.8.4.4；取消 Super DMZ；删多余端口转发
8. Steam 兼容性疑难解答：库右键游戏 → 管理 → 浏览本地文件 → EternalReturn.exe 属性 → 兼容性 → 运行兼容性疑难解答 → 测试程序；Steam 登入错误就保存设置后重开

## 关键判断
- Steam 登录/社区由 Steamcommunity_302 本地转发负责（api.steampowered.com 通过 127.0.0.1:443 → 302 → 官方服务器，返回 200 即正常）
- 进不去游戏页面的根因几乎总是 `er-api.nimblelion.com` 不可达（直连超时或代理死了），不是游戏本身问题
- 修复路径按优先级：Clash TUN 全局（需有效节点）→ UU/雷神等游戏加速器专线 → Cloudflare WARP → 换宽带 Wi-Fi
