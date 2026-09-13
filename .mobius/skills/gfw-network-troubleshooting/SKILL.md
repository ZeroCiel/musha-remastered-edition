---
name: gfw-network-troubleshooting
description: 墙内Windows环境下诊断海外游戏/服务连不上的流程——代理栈排查(Clash Verge/Steamcommunity_302)、出口网络识别(手机热点/Radmin VPN)、游戏服务器域名解析、连通性失败分类(超时/RST/TLS指纹JA3)、机场订阅有效性、修复方案(TUN/WARP/UU加速器)，以及给下载工具(yt-dlp等)配代理走Clash的步骤。GitHub 仓库拉取(git clone 443 超时 → codeload 下 zip / --resolve 逐 IP 探测 / hosts 钉可达 IP)。触发词：无法进入游戏页面/无法匹配/海外服务连不上/Steam打不开/YouTube下载不了/yt-dlp翻墙下载/git clone 超时/github 连不上/同步仓库/搜不到资料/这是什么/B站链接/某个作品叫什么/你看过吗。
---

# GFW 网络连通性诊断（墙内 Windows）

## 触发条件
用户报海外游戏/服务连不上：无法进入游戏页面、无法匹配、Steam 打不开、下载超时等。主机是 Windows，terminal 走 git-bash，网络在墙内。

## 诊断步骤（只读、快速；用户会拒绝深层探测命令，别跑危险命令）

1. 代理栈清单
   - 端口：netstat -ano | grep -i listen | grep -E '789|1053'
   - 进程：tasklist | grep -iE 'mihomo|clash|verge'
   - 系统代理：reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" | grep -iE 'ProxyEnable|ProxyServer'
   - Clash Verge Rev 装在 C:\Program Files\Clash Verge，混合端口默认 7897；ProxyEnable=0 + ProxyServer 残留 7897 = 以前开过现在没开

2. hosts 劫持检查（Steamcommunity_302）
   - grep -c '#S302' /c/Windows/System32/drivers/etc/hosts（此机器 900 行左右）
   - S302（D:\Steamcommunity_302，进程 steamcommunity_302.cli）把 steam/google/youtube 等域名劫持到 127.0.0.1:80/443 本地转发
   - curl 结果 remote=127.0.0.1 且 200 = 走了 S302 本地转发，不代表公网真实连通性；**curl google 200 且 0.03s 不一定真通**

3. 出口网络识别
   - route print | head：Radmin VPN(26.0.0.0/8 网关 26.0.0.1, metric 高) + 手机 USB 共享(Remote NDIS 192.168.42.x, DNS 192.168.42.129)
   - ping -n 2 1.1.1.1：>200ms = 出口是手机热点，国际路由差（实测 279ms）
   - ipconfig //all 输出中文乱码 → 用 grep -aE 'DNS|IPv4|Default Gateway' 过滤
   - 真实出口验证：`curl -s -m 8 http://ip-api.com/line/?fields=query,country,isp`（明文输出，比 ip.sb 稳）
   - IPv6 出口：`curl http://ip.sb`（返回 2408/2409 等公网 IPv6 = IPv6 通）

4. 解析目标服务器真实域名
   - nslookup 轮询候选域名；游戏公司域名常配通配符 DNS（如 *.nimblelion.com → AWS Global Accelerator 13.248.x.x / 76.223.x.x 特征段）
   - 候选域名 NXDOMAIN 时换公司根域子域继续试；无 AAAA 记录 = IPv6 路线不通，别浪费时间
   - 通配符全同 IP = 子域名由游戏配置决定，DNS 看不出 API/匹配服区别

5. 连通性测试与失败分类
   - `curl -sS -m 10 -o /dev/null -w "%{http_code} remote=%{remote_ip} t=%{time_total}s" https://域名/`
   - 10s 超时(000) = GFW IP 封锁 / 国际出口路由差（手机热点典型症状）
   - 0.3~1s 快速失败(000) = RST 拒绝（GFW 干扰或服务器防火墙）
   - **TCP 通但 TLS 失败**：schannel 报 SEC_E_ILLEGAL_MESSAGE，或 openssl s_client 报 `unexpected eof while reading` = 服务器 TLS 指纹(JA3)反作弊或封 IDC 段。**curl/openssl 连不上 ≠ 游戏连不上**——游戏客户端自带 TLS 栈/指纹可能正常。最终判据：让用户直接启动游戏
   - remote_ip=127.0.0.1 = 本地劫持；nslookup 显示 ::ffff:127.0.2.2 = WARP/本地 DNS 映射，别信，用 curl 实测

6. 机场订阅有效性（代理配置在但没节点时）
   - Clash Verge Rev 配置目录：~/AppData/Roaming/io.github.clash-verge-rev.clash-verge-rev/profiles/*.yaml
   - 读 yaml 里 `proxy-providers:` 的 `url:`，`curl -s -L -k <url>` 验证（订阅链接常 http 308 重定向 + 证书异常，用 -L -k 跟随再判断）
   - **404/403 = 订阅文件被删 = 没交费/停服**（铁证，别继续折腾代理客户端）；占位符 `url: "订阅地址"` = 没填

7. 修复方向（按顺序给封闭选项）
   - Clash Verge 开 TUN 模式：游戏流量不走系统代理，只有 TUN 全局接管有效
   - **手机 VPN 陷阱**：安卓 USB 共享热点流量不走手机 VPN（VPN 只管手机本机应用），出口 IP 不变
   - Cloudflare WARP（免费不限量）：下载 `https://1111-releases.cloudflareclient.com/windows/Cloudflare_WARP_Release-x64.msi`，装完登录 → 连接；验证 ip-api.com 显示 Cloudflare, Inc. + 美国。GUI 弹不出时用命令行：exe 在 `C:\Program Files\Cloudflare\Cloudflare WARP\`，`warp-cli.exe status` / `warp-cli.exe connect`（等 5s 后 status 变 Connected / Network: healthy）
     - **WARP 免费版重大局限**：出口是 Cloudflare IDC 段（104.28.x.x），反作弊严格的对局服务器会拒（封数据中心 IP）。实测永恒轮回：登录/大厅能过（71ms），对局（匹配/打架）被拒或跳 ping。先问用户是"登录过不去"还是"对局跳 ping"：前者 WARP 直接解，后者直接上加速器
   - 游戏加速器专线（UU/雷神等）：新用户有免费体验，节点被游戏服务器认可，最适合"没交费"场景
   - 换宽带 Wi-Fi：手机热点国际出口差是常见根因（~280ms）

## 变体：给具体工具配代理（yt-dlp 等下载器案例）

有一类请求不走上面的完整诊断：**某个具体工具**（yt-dlp 等）在墙内连不上外网视频站，而代理栈本身是好的（Clash Verge 在跑）。缺的只是让该工具走代理：

1. 找 Clash 混合端口：`netstat -ano | grep -i listen | grep -v '\[::\]'`，定位 `verge-mihomo.exe` 监听的端口——默认 7897（HTTP 混合），可能 1053。Clash Verge 装在 `C:\Program Files\Clash Verge\`。
2. 先验证代理端口可用：`curl -x "http://127.0.0.1:7897" -s -o /dev/null -w "%{http_code}" https://www.google.com` → 200/502 = 通；`000` + exit 35 = 该端口只吃纯 HTTP 不吃 HTTPS（换 socks5 或换端口）。
3. 给工具指过去：`yt-dlp --proxy "http://127.0.0.1:7897" <URL>`；HTTP 不通就试 `--proxy "socks5://127.0.0.1:7897"`。
4. 常见报错对照：`WinError 10061` = 端口不对/代理没开；`HTTP Error 410 Gone` = 视频已删；1080p+ 报 ffmpeg 缺失 = 装 release 包（带 `bin\ffmpeg.exe`），720p 及以下单视频流不需要。

完整命令集（格式选择、音频提取/转 mp3、ffmpeg 安装渠道、更多 FAQ）见 `references/yt-dlp-proxy-setup.md`。要点：代理端口判断以"进程+端口监听"为准（同诊断主流程），工具报错先查代理端口再查工具参数。

## 变体：代理全挂但要「找参考图 / 参考色」

用户说「你去找找 <参考物>」时，代理栈可能根本没开（海外直连 `000`），但国内站点是通的。
**别直接回「查不到」**：先跑一条可达性判定，再用 `cn.bing.com` 图搜抓原图 URL + Pillow 取主色，
能覆盖大部分「要个颜色/要张参考图」的请求。命令集、已踩的坑（百度 acjson 返回 0、花瓣 567、
关键词被中文搜索带偏）、拿不到时的封闭选项收场话术 → `references/domestic-web-research-fallback.md`；
一键脚本 → `scripts/cn_bing_images.py`。
关键认知：**WARP / GUI 进程在跑 ≠ 有可用代理端口** —— 一律用 `curl -x` 实测，别信「进程在」。

## 变体：墙内拉 GitHub 仓库（`git clone` 不通时的降级路径）

**症状**：`curl -sI https://github.com/<owner>/<repo>` 偶尔 200（碰运气），
但 `git ls-remote https://github.com/<owner>/<repo>` 稳定
`fatal: unable to access ...: Failed to connect to github.com port 443 after 21s`。

**先排除本地因素**（实测四项都干净 → 问题纯在墙，别再去折腾本机）：
`git config --global --list | grep -i proxy` 空 · `env | grep -i proxy` 空 ·
`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings"`
（`ProxyEnable=0x0` + ProxyServer 残留 7897 = 以前开过没开）· hosts 里无 github 劫持。

**降级 1（先拿到代码，最省事）：走 `codeload.github.com` 下 zip**

```bash
curl -L --retry 3 -o "$HOME/Downloads/<repo>-main.zip" \
  "https://codeload.github.com/<owner>/<repo>/zip/refs/heads/main"
```

- codeload 是 GitHub 的归档下载域名，**`github.com` 不通时它照样 200**（实测可达，~1 MB/s）
- 返回 200 而非 404 顺带确认了默认分支名就是 `main`
- 缺点：**解压出来没有 `.git`**，将来不能 `pull`
- 解压别依赖 `unzip`（git-bash 未必有）：
  `python -c "import zipfile;zipfile.ZipFile(p).extractall(d)"`

**降级 2（要能 `git pull`）：逐 IP 探测 + 写 hosts**

```bash
for ip in 20.205.243.166 20.27.177.113 4.237.22.38 140.82.112.3 140.82.113.3; do
  printf '%-18s ' "$ip"
  curl -s -o /dev/null -w "%{http_code} %{time_total}s\n" --max-time 8 \
    --resolve github.com:443:$ip "https://github.com/<owner>/<repo>"
done
```

- 实测可达：`140.82.113.3`（3.4s）、`4.237.22.38`（3.2s）；不可达：`20.205.243.166`、`20.27.177.113`（000 超时）
- 把通的那个写进 `C:\Windows\System32\drivers\etc\hosts` → `git clone/pull` 恢复
- ⚠️ GitHub IP 会变：写 hosts 是拿"以后可能失效"换"现在能用"，**动系统文件前先问用户**

★ **proxy 型加速镜像会时好时坏，别把\"全废\"当结论背下来 —— 用前先探一条（1 秒）**

★ 2026-09-12 复测：`ghfast.top` **200**、`gh-proxy.com` **200**、`ghproxy.net` **200**，
且从 `ghfast.top` 下 **138 MB 的 release 附件**实测 **1.9 MB/s、73 秒完成**（比 codeload 和大学镜像都快）。
同一批域名在更早的复测里是 403/000，`github.moeyy.xyz` / `bgithub.xyz` 本次 **000**。
→ **\"哪些镜像活着\"是时效性事实，不是稳定事实。** 一行命令先探，别照着旧结论直接放弃：
`bash scripts/github_mirror_probe.sh <owner> <repo> <tag> <filename>`（探完取首个 200）

分工：
- **拿仓库源码** → 走 `codeload.github.com`（最稳，见上）
- **拿 Release 附件 / 大文件** → 先探加速镜像（首选），再考虑大学镜像的 `github-release` 转发
- 镜像返回 200 之后，**下完仍要核 Content-Length + sha256**（见本节末尾「下载源的体积判据」）

★ **但"proxy 型镜像全废" ≠ "所有 GitHub 镜像都废"** —— 大学镜像站的
`github-release` 转发是活的。**要分清两条路：「仓库源码」走 codeload；
「Release 附件」走大学镜像。** 实测（探测 `/<tag>/` 目录）：

| 镜像 | HTTP | 备注 |
|---|---|---|
| `mirrors.nju.edu.cn/github-release/<owner>/<repo>` | **200** | 有 astral-sh/python-build-standalone |
| `mirrors.ustc.edu.cn/github-release/<owner>/<repo>` | **200** | 同上 |
| `mirrors.tuna.tsinghua.edu.cn/github-release/<owner>/<repo>` | 404 | **清华只镜像部分仓库**，别默认它全有 |

**用例：工具自己去 GitHub Releases 拉运行时**——这类请求平时看不到 URL，
只在报错里露个文件名。典型：`uv venv --python 3.12` 时系统没有 3.12 →
uv 去下 `cpython-3.12.x-...-install_only_stripped.tar.gz` → 墙内 3 次重试全超时：

```
error: Request failed after 3 retries in 264.0s
  Caused by: Failed to extract archive: ...install_only_stripped.tar.gz
  Caused by: Invalid tar file ... operation timed out
```

★ **`Invalid tar file` 是"半截下载"的特征，不是包坏了** —— 别去换版本/换工具，先想墙。

两条修法：
1. 正规：`UV_PYTHON_INSTALL_MIRROR=https://mirrors.nju.edu.cn/github-release/astral-sh/python-build-standalone/releases/download`
   （uv 会在其后拼 `/<tag>/<file>`）
2. 更省事（本例采用）：**先读调用方脚本的幂等判据** —— 它若只认
   "`<venv>/bin/<cli>` 可执行 + `lib/python*/site-packages/<pkg>-<ver>.dist-info` 存在"、
   **不校验 Python 版本**，就用系统自带 python 建 venv 绕过去，一步不碰 GitHub。
   完整配方 → skill `windows-install-preflight` 的 `references/wsl2-install-cn.md` §8.3

**下载源的体积判据**（任何官网直链都适用）：`curl -sI <url> | grep -i content-length`
先拿字节数，下完 `ls -l` 比对，一致才算下全（微信安装包实测 283,125,176 字节）。

## 用户偏好（墙内游戏玩家）
- 直接给结论 + 封闭选项，别绕圈子；中文极简
- **根因找到就停手**：层层探测被用户拒绝过——找到"服务器连不上 + 代理死了"就立即给方案，不要继续做更深的网络层测试；用户拒绝某个命令就停手，改为让用户直接启动游戏验证
- 用户习惯自己装软件（双击跑向导），给下载渠道名即可（uu.163.com、1.1.1.1 官网），不要代装
- 但**"帮我装个 X 电脑版"这类请求，下载安装包再交给他双击是对的**（实测微信电脑版被接受）：
  ① 先查是否已装（`ls "/c/Program Files/Tencent/WeChat"` / `Program Files (x86)` / `$LOCALAPPDATA`、桌面快捷方式）
  ② 探官网直链的 `Content-Length` 拿体积
  ③ 后台 `curl -L --retry 3` 下到 `~/Downloads`，`ls -l` 校验字节数
  ④ 只回**路径 + 向导里要注意的两处**（安装位置 / 开机自启勾选）+ 首次登录要手机扫码
  **不要代跑安装向导**；双击没反应或被杀软拦时再介入

## 坑
- 禁止 bash /dev/tcp 原始套接字探测——用户会拒绝该命令（实测被 block）
- 别跑完整 tracert：烂路由上会卡 60s+；最多 -h 12 或直接跳过，用 curl 超时分类代替
- hosts 劫持只影响 HTTP(S) 域名流量，不影响游戏本体 UDP 连接；游戏直连问题要查出口网络本身
- ★★ **hosts 劫持是按「网络命名空间」生效的 —— WSL2 / Docker 里的 127.0.0.1 不是 Windows 的 127.0.0.1**
  实测：S302 把 `github.com` 钉到 `127.0.0.1:443` 后，Windows 侧一切正常（S302 自己的本地端口接住），
  但 **WSL 里跑的服务日志一直刷 `connect ECONNREFUSED 127.0.0.1:443`**（Mobius 后端的 desktop-sync 就是这样，
  它想从 GitHub Releases 同步桌面端安装包 → 永远失败，且看 Windows 侧完全查不出问题）。
  **判据**：Windows 侧访问该域名正常 + WSL/容器内报 `ECONNREFUSED 127.0.0.1:<80|443>` = 宿主劫持，不是墙、不是服务端问题。
  **修法**：① 在 WSL 里改用宿主 IP（`ip route show default | awk '{print $3}'`）而不是 localhost；
  ② 或让该服务改用**不被劫持的域名/镜像**（本例直接把产物手动喂进本地目录，最省事）。
- 判断代理是否有效以"进程+端口监听"为准，系统代理 ProxyEnable 与游戏无关
- **提安装方案前先 `df -h /c /d` 看剩余空间**：这台机器 C/D 盘常年紧（实测 C 剩 7.8G/94% 占用、D 剩 3.0G/98%），
  Docker Desktop(~3G) + 镜像(10~15G) 会直接卡死；Docker Hub 墙内也拉不动，要装先配国内 registry 加速源
  （顺带实测：`desktop.docker.com/win/main/amd64/...` → 200 但慢(12s)，`win/stable/amd64` → 000；
  `winget search Docker.DockerDesktop` 有 4.90.0。腾空间/清盘清单 → skill `windows-install-preflight`）
- 用户说"帮忙装/跑 X"时，**先读官方一键脚本内容再判断依赖**
  （`curl -s <script-url> | head -60`），别按 README 的推荐顺序猜——
  实测 Mobius 的 Windows 一键脚本本质就是"查 Docker → clone → build → compose up"，
  而它后端依赖 tmux（Linux 专有）→ Windows 上**不能原生跑**，只能 Docker **或 WSL2**。
  ★ **别急着下"只能 Docker"的结论**：WSL2 就是真 Linux、自带 tmux，
  而且 apt/npm/pip 全都能换国内源**绕开 Docker Hub**，8 G 内存老笔记本反而首选它。
  路线取舍 / 虚拟化前置体检（`HypervisorPresent=False` ≠ BIOS 没开 VT-x）/ 磁盘腾挪
  → skill `windows-install-preflight`

## 支持文件
- references/eternal-return.md — 永恒轮回完整案例：域名/IP、机器状态、诊断结果、WARP 对局被拒实录、官方排查要点
- references/yt-dlp-proxy-setup.md — 工具级代理配置全命令集：yt-dlp 走 Clash Verge 的格式选择/音频提取/ffmpeg 安装/常见报错（原 yt-dlp-proxy-setup 技能归档于此）
- `references/domestic-web-research-fallback.md` — 代理全挂时的国内检索替代：可达性判定命令、cn.bing 图搜抓原图、不可用渠道（百度 acjson/花瓣）、收场话术；**百度文本搜索可用性**（词越多越搜不到，2~3 词最佳，1~2 轮为上限）、**B站 BVID 免登录反查**（view / tags / reply 三个 API，靠标签+评论认本体）、认不出时的汇报纪律
- scripts/cn_bing_images.py — 一键「国内图搜 → 下载 → 主色量化」，无需代理（`python cn_bing_images.py "关键词"`）
- `scripts/github_mirror_probe.sh` — 一条命令探 GitHub **Release 附件**的可用源（直连 / 6 个加速镜像 / 南大·中科大·清华 github-release 转发），取首个 200；脚本尾部带「下载后核验清单」（Content-Length → sha256 → zip 魔数 `PK`）。**加速镜像可用性是时效性事实，每次现探，别背结论。**
