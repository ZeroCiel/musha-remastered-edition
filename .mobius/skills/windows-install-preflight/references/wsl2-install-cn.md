# 墙内 Windows 手动装 WSL2（Store 不通时的确定性路线）

实测机器：Win11 22631 / i5-6300HQ / 8 G 内存。
背景：`wsl.exe --update`、`wsl --install -d Ubuntu` 都走 Microsoft Store，
这台机器上**挂满 420 s 超时、零进度**。下面是绕开 Store 手动做完的完整路数。

---

## 0. 前置核验（重启后做，全只读）

```bash
cmd //c ver                                                    # 系统版本
powershell -NoProfile -Command "(Get-Item C:\Windows\System32\wsl.exe).VersionInfo.FileVersion"
for f in Microsoft-Windows-Subsystem-Linux VirtualMachinePlatform HypervisorPlatform; do
  echo -n "$f : "; powershell -NoProfile -Command "(Get-WindowsOptionalFeature -Online -FeatureName $f).State" | tr -d '\r' | head -1
done
powershell -NoProfile -Command "Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'"
powershell -NoProfile -Command "(Get-CimInstance Win32_ComputerSystem).HypervisorPresent"
wsl.exe --status 2>&1 | iconv -f UTF-16LE -t UTF-8 | tr -d '\r'   # 看"内核版本"一行
```

判据：
- `Microsoft-Windows-Subsystem-Linux` + `VirtualMachinePlatform` = **Enabled**
- `RebootPending` = **False**（= 重启已生效）
- `HypervisorPresent` = **True**（★ `Win32_Processor.VirtualizationFirmwareEnabled` 常报 False，别被误导）
- `wsl --status` 出现 `内核版本： 5.10.16` = 内核就位；报"未找到 WSL 2 内核文件"= 还没装

★ `Get-WindowsOptionalFeature -FeatureName A,B` 传数组会报
`无法将 System.Object[] 转换为 FeatureName`。**一次查一个**。

---

## 1. 内核：手动装 MSI（不走 `wsl --update`）

```bash
curl -sL -m 900 -o /d/wsl-dl/wsl_update_x64.msi \
  "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
# 正确大小恰好 17,104,896 字节；文件头应为 D0CF11E0（OLE 复合文档）
xxd -l 8 /d/wsl-dl/wsl_update_x64.msi
cmd //c "msiexec /i D:\wsl-dl\wsl_update_x64.msi /qn /norestart /l*v D:\wsl-dl\msi.log"
ls -la /c/Windows/System32/lxss/tools/kernel      # 出现约 70 MB 的文件 = 成功
```
这个 MSI 只有 ~17 MB，**慢也值得等**（实测 24~42 KB/s，约 10 分钟）；
`/l*v` 写的日志是 UTF-16，看尾巴用 `iconv`。
MSI 装完 `wsl --status` 就会列出 `内核版本： 5.10.16`。

---

## 2. 发行版：清华镜像的 Ubuntu rootfs + `wsl --import`

官方 `aka.ms/wslubuntu2204` 指向 Store 包（AppxBundle，~500 MB，还要解包再 import），
**直接用 Ubuntu 云镜像的 WSL rootfs tarball 更省事**（一个 tar.gz，可直接 import）。

源（清华，实测 342 KB/s；中科大同样有）：
```
https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cloud-images/wsl/jammy/current/ubuntu-jammy-wsl-amd64-ubuntu22.04lts.rootfs.tar.gz
```
- 大小 **341,130,963 字节**
- sha256 **1483cc5c1dce13064f774834cbffdff226559fd522a67a381a8ea77d63fb4109**
- 同目录有 `SHA256SUMS`，**下下来核对**，别信自己的 memory

```bash
# 下载（★ 绝不要加 -C - 续传，见 SKILL.md 的坑）
curl -L --retry 3 -m 2400 -o "$TAR" "$BASE/$FNAME" \
  -w "http=%{http_code} 下载=%{size_download} 用时=%{time_total}s\n"
stat -c %s "$TAR"                      # 必须 == 341130963
sha256sum "$TAR"                       # 必须 == 上面那个值
```
校验不过 → `rm -f` 换 `mirrors.ustc.edu.cn` 重下，最多 3 轮。

```bash
mkdir -p /d/WSL
wsl.exe --import Ubuntu2204 "D:\\WSL\\Ubuntu2204" "D:\\wsl-dl\\ubuntu-jammy.rootfs.tar.gz" --version 2
```
- 发行版数据落在 **D 盘**（`ext4.vhdx`，初始约 430 MB，往上长），别放 C 盘
- ★ `wsl --import` **不校验 tar 完整性**，坏 tar 也 exit 0 → 所以校验门必须在 import 之前
- import 后**先冒烟测试再跑配置**：
  `wsl.exe -d Ubuntu2204 -u root -- echo WSLREADY`（坏系统这里就会 127 + UTF-16 乱码）

---

## 3. 内存/swap 限制（8 G 机器必做）

`C:\Users\<user>\.wslconfig`（`swapFile` 用双反斜杠，跟官方文档一致）：
```ini
[wsl2]
memory=3072MB
processors=3
swap=4096MB
swapFile=D:\\wsl-swap.vhdx
```

---

## 4. 装完立刻在镜像里做的事（手动 import 的额外收益）

`wsl --import` **不需要**用户设 Linux 用户名/密码（对比 `wsl --install` 的交互向导）——
所以对"不想记密码"的用户是**卖点**：自己建用户 + 免密 sudo，他一个字不用敲。

```bash
useradd -m -s /bin/bash -G sudo mobius
echo 'mobius:mobius' | chpasswd
printf 'mobius ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/mobius
chmod 0440 /etc/sudoers.d/mobius
printf '[user]\ndefault=mobius\n' > /etc/wsl.conf    # 之后 wsl 直接进 mobius
# 生效需要 wsl --terminate <distro>，否则默认用户还是 root
```
其余：apt 换清华源 → 装基础包 → pip 走清华、npm 走 npmmirror →
`/etc/locale.gen` 开 en_US.UTF-8 → `pip install uv`。
Windows 侧脚本传给 WSL 跑之前先 `sed -i 's/\r$//'`（write_file 会写 CRLF）。

---

## 5. 派生依赖表的技巧（跑官方 Docker 项目但不装 Docker）

要跑的项目只有 `Dockerfile`（且 `FROM <私有 base 镜像>`）时，
**去找 `deploy/onekey/Dockerfile*-base`** —— base 镜像的 apt/npm 清单就在那里，
照抄即可，不用瞎猜。实例（Mobius）：
- base = `node:18-bookworm`
- apt：`nano tmux proxychains-ng git curl ca-certificates tini python3 python3-pip make g++ procps less locales iproute2 psmisc openssh-server ffmpeg unzip`
- 全局 npm：`@anthropic-ai/claude-code@2.1.195`、`@openai/codex@0.144.6`（版本被作者钉死，照抄）
- code-server 4.19.1 deb 走**国内源** `serve.nutshellai.cn`（作者自己镜像的，快）
- `FROM` 的 base 镜像拉不到时，`proxychains4` 是必需包；`node-pty` / `better-sqlite3`
  是原生模块，**必须**有 `make` `g++` `python3` 才能 `npm install` 成功
- 代码别在 `/mnt/c/...` 下跑 `npm install`（跨文件系统极慢）→ 先 `cp -r` 进 WSL ext4

---

## 5.5 镜像里手装 Node 的两个必踩坑（症状都长得像"装失败"，其实装成功了）

官方 base 镜像自带 node，手动 import 的发行版里就得自己接管线。实测两个坑都踩满。

### 坑 A：全局 CLI `npm i -g` 报成功，但 `command -v` 找不到

Node 从 tarball 解到 `/usr/local/lib/nodejs/node-v18.20.8-linux-x64` 后，
**只把 node/npm/npx 三个软链进 `/usr/local/bin` 是不够的**：
npm 的全局 prefix 由 npm 可执行文件的真实路径推出 → 落在那个私有 node 目录，
于是 `npm install -g <cli>` 把二进制丢进 **`<node>/bin/`**（不在 PATH 里）。

日志还会骗人：`added 4 packages in 11m` 看着完全成功，脚本自己的检查却报
`!! claude 没装上 / !! codex 没装上`（实测 claude-code、codex 两个都中招）。

```bash
D=$(ls -d /usr/local/lib/nodejs/node-v*-linux-x64 | head -1)   # ★ 不要手拼版本号
for b in "$D"/bin/*; do ln -sf "$b" "/usr/local/bin/$(basename "$b")"; done
echo 'prefix=/usr/local' > /etc/npmrc     # 根治：以后 npm i -g 直接落进 PATH
```
`/etc/npmrc` 是全局配置（比只改 root 的 `~/.npmrc` 覆盖面全），改完对所有用户生效。

★ **那个目录名带 `-linux-x64` 后缀**。手拼成 `node-v18.20.8` 会**静默空转**：
glob 不展开 → `ln -sf <未展开的pattern> /usr/local/bin/*` 又被 shell 展开成多个参数 →
报 `ln: target '/usr/local/bin/uvx': Not a directory`。
**看到这个 `Not a directory` 报错就是 glob 没匹配上**，先 `ls -d <目录>` 确认真实路径，
别去怀疑 `ln` 的用法。

### 坑 B：`npm install` 跑错目录 / 网络超时

- **仓库根有 `package-lock.json` 不代表有 `package.json`**。实测目标仓库根目录只有
  lock 文件，真正的 `package.json` 在 `<repo>/mobius/`，前端在 `<repo>/mobius/frontend/`。
  跑之前先确认（跑错只会得到 `ENOENT: Could not read package.json`，白等一轮）：
  ```bash
  for p in . mobius mobius/frontend; do
    echo "$p/package.json : $([ -f "$REPO/$p/package.json" ] && echo 有 || echo 无)"; done
  ```
- 带宽被别的大件下载抢走时 npm 会 `ETIMEDOUT (errno -110)` + 一大段
  "If you are behind a proxy..." 的误导话术 —— **这是暂时性的，不要改代理/npm 配置**，
  包一个重试轮即可：
  ```bash
  for r in 1 2 3; do
    sudo -u <user> bash -lc "export PATH=/usr/local/bin:\$PATH; cd <dir> && npm install \
      --registry=https://registry.npmmirror.com \
      --fetch-retries=5 --fetch-retry-maxtimeout=120000 2>&1 | tail -6" && break
    sleep 15
  done
  ```
- 原生模块（`node-pty`、`better-sqlite3`）**必须**有 `make` `g++` `python3` 才装得过。
- 代码别在 `/mnt/c/...` 下 `npm install`（跨文件系统极慢）→ 先 `cp -r` 进 ext4。

### 配置脚本的自检段（值得保留的写法）
每装完一批就打印 `command -v` 结果，别只 print "OK"：
```bash
for c in tmux git curl python3 pip3 node npm npx claude codex uv; do
  printf "  %-9s " "$c"; command -v $c || echo "(缺)"; done
```
—— 上面这个循环就是抓出坑 A 的东西；只 echo 一句"装好了"会把问题留到使用者手里。

---

## 6. 本轮踩坑速查

| 现象 | 真因 | 处置 |
|---|---|---|
| `wsl --update` 卡 420 s 无输出 | 走 Store，Store 不通 | 手动 MSI + 手动 import |
| rootfs 341 MB 变 456 MB | `-C -` 续传，服务器忽略 Range → 整个文件被追加 | 重下，别续传 |
| `wsl --import` exit 0 但系统坏 | import 不校验 tar | 校验门放 import 前 + 冒烟测试 |
| 配置步骤 `exit 127` + UTF-16 乱码 | 上一个坑的后果（bash 根本没跑起来） | 重装发行版 |
| 重装前必须先卸 | 同名发行版不能重复 import；坏系统的 `ext4.vhdx` 会占着盘（实测 430 MB） | `wsl.exe --unregister Ubuntu2204` 后再 `--import` |
| wsl.exe 输出乱码 | 输出是 UTF-16LE | `iconv -f UTF-16LE -t UTF-8 | tr -d '\r'` |
| 下载只有 24 KB/s | 微软 blob 慢 / Steam 抢带宽 | 换清华源；让用户暂停 Steam |
| 脚本报 `claude 没装上`（但 npm 说 added 4 packages） | 只软链了 node/npm/npx，npm 全局 prefix 还在私有 node 目录 | 软链 `<node>/bin/*` + `/etc/npmrc` 写 `prefix=/usr/local` |
| `ln: target '...': Not a directory` | glob 没匹配（node 目录名带 `-linux-x64`，版本号手拼错了） | `ls -d /usr/local/lib/nodejs/node-v*-linux-x64` 取真实路径 |
| `npm install` → `ENOENT Could not read package.json` | 跑错目录（仓库根只有 lock 文件） | 先确认 `package.json` 的真实路径再 npm install |
| `npm install` → `ETIMEDOUT (errno -110)` | 带宽被别的大件下载抢走（暂时性） | 重试轮 + `--fetch-retries=5`，**别改代理/npm 配置** |
| 启动日志文件 0 字节、进程却在跑 | `| tail -N` 管道缓冲，攒到结束才吐 | 改成 `> log 2>&1`；用 `ps -eo ... --sort=-pcpu` 看它在干什么 |
| `uv venv --python 3.12` 报 `Invalid tar file` / `operation timed out` | uv 去 GitHub 下独立 Python（墙外，拿到半截） | 系统 python 建 venv 绕过 / `UV_PYTHON_INSTALL_MIRROR` |
| 按 `.env` 里的端口 curl 返回 000 | 实际端口是另一个（`VITE_PORT` 而非 `MOBIUS_PORT`） | 以**启动日志打印的 URL** 为准，再 curl `/api/v2/health` |

---

## 7. 回答用户必问的两句话（"能用了没" / "还要多少 G"）

装到一半用户一定会问这两句。**别用"正在装"糊过去**，给可核对数字。

### "WSL 可以用了吗" —— 区分「能执行命令」和「配置完了」

手动 import 完**立刻**就能进去，但里面还是裸 Ubuntu（没 tmux/node/python），
目标项目跑不起来。三行体检：

```bash
wsl.exe -l -v 2>&1 | iconv -f UTF-16LE -t UTF-8 | tr -d '\r'    # Running / Stopped
wsl.exe -d Ubuntu2204 -u root -- echo HELLO-WSL                  # 能执行命令
wsl.exe -d Ubuntu2204 -u root -- bash -c \
  "cat /etc/os-release | head -2; echo 已装包数: \$(dpkg -l | grep -c '^ii'); \
   echo apt进程: \$(ps -eo comm | grep -cx apt-get); df -h / | tail -1"
```

回话就给**脚本步骤原样的进度条**（`[✓]1/9 … [→]2/9 … [ ]3/9…`）
+ 当前卡在哪步 + **卡的原因**（本例：apt 被 Steam 抢带宽，第 2 步停了 20 分钟）。

### "还要多少 G" —— 三行算给他

`df -h /d` 余量 → 已占（`ext4.vhdx` **实际字节** + `wsl-swap.vhdx` + 可回收的 tar/脚本）
→ 待装各项估算。实测基线（Ubuntu 22.04 + 690 个包 → `ext4.vhdx` 1.92 G）：

```
apt 剩下部分 ~0.3G / Node18 ~0.1G / code-server ~0.4G / claude+codex ~0.4G / 项目依赖 ~0.5~1G
────────────────────────────
整套装完约 5~6 G
```

- ★ **`ext4.vhdx` 只涨不缩**（本项目里 `wsl --unregister` 是唯一回收手段）
- `swapFile` 按需长，上限 = `.wslconfig` 里的值（本例 4 G）；rootfs tarball（342 M）import 后即可删
- ★ 同一块盘上的其它大件要**先算总账再动手**：本例壁纸 19 G + WSL 6 G 会把 24 G 的 D 盘挤爆
  → 算法与话术见 skill `steam-app-repair` 的「容量账」段

### 环境备注（本轮落地值，复用即可）

- 发行版名 `Ubuntu2204`，数据 `D:\WSL\Ubuntu2204\ext4.vhdx`（不放 C 盘）
- 免密用户 `mobius`（sudo 无需密码），`/etc/wsl.conf` 默认用户已切
- 装完 `wsl --terminate <distro>` 默认用户才生效

---

## 8. 首次启动（`start.py` 这类项目）—— 四个会骗人的点

**装完 ≠ 跑起来。** 这轮把项目拉起来时踩的四个坑，全属于"日志/配置在骗人"这一类。

### 8.1 别用 `| tail -N` 去看长构建 —— 它攒到最后才吐

```bash
# ✗ 日志文件会 0 字节挂到进程结束，看着像卡死（实测挂了 100 s 还是 0 字节）
wsl.exe -d D -u u -- bash -lc 'cd ~/proj && python3 start.py --detach 2>&1 | tail -80' | tee log
# ✓ 直接落盘，边跑边能 tail
wsl.exe -d D -u u -- bash -lc 'cd ~/proj && python3 start.py --detach 2>&1; echo "===EXIT=$?==="' > log 2>&1
```
`tail` / `tr` 这类管道会缓冲；只有 `>` 到文件才有流式输出。

**想看它此刻在干什么**（比等日志快得多）：
```bash
wsl.exe -d <distro> -u <user> -- bash -lc \
  'ps -eo pid,etime,pcpu,rss,comm,args --sort=-pcpu | grep -viE "ps -eo|grep" | head -12'
```
实测一眼看出卡在 `tsc --noEmit`（116% CPU / 711 MB）→ **是在编译，不是死循环**。
另可看 `tmux ls` / `pm2 list` 判断服务是否已起。

### 8.2 服务真正的端口看**启动日志**，别信 `.env` 里的名字

`.env` 里 `MOBIUS_PORT=33314`，但服务实际监听的是 **`VITE_PORT=33316`** ——
33314 根本没人用（curl 返回 000）。启动成功的日志会自己把地址打出来：
```
frontend:       http://0.0.0.0:33316
backend health: http://0.0.0.0:33316/api/v2/health
code-server:    127.0.0.1:33317
```
**先读日志里的 URL，再 `curl` 那个端口 + `/api/v2/health` 验证 200**，别按 `.env` 猜。
（WSL2 → Windows 的 localhost 转发对该端口自动生效，浏览器直接开。）

### 8.3 可选组件失败会**中断整条启动**

`start.py` / `start_product.py` 是**逐步串行**的：编译前端 → promote → 装可选运行时 →
起 PM2 → 起 code-server。**任何一步非零退出就整条中止，核心服务一个都不起**
（实测：实验性可选的 aimux 桥失败 → `exit code 2` → 后端/前端全没起）。

排障顺序：**读它停在哪一步 → 判断那步是不是核心功能 → 可选的就让它"假装已完成"跳过**。

本轮实例（可选组件要 GitHub 上的独立 Python）：
```bash
VENV=<proj>/.venv-aimux
uv venv "$VENV" --python /usr/bin/python3.10          # 用系统 python，不下载
uv pip install --python "$VENV" --no-cache \
  --index-url https://pypi.tuna.tsinghua.edu.cn/simple/ '<pkg>==<ver>'
```
★ **动手绕之前先读那个 setup 脚本的幂等判据**：本例它只检查
`<venv>/bin/<cli>` 可执行 + `lib/python*/site-packages/<pkg>-<ver>.dist-info` 存在，
**完全不校验 Python 版本** —— 所以用 3.10 建 venv 装同一版本即可，脚本直接 exit 0，
一步都不碰 GitHub。判据里若有版本约束就不能这么绕，改用
`UV_PYTHON_INSTALL_MIRROR`（见 skill `gfw-network-troubleshooting`）。

### 8.4 首次配置脚本多数是**非交互**的（别忙着造 TTY）

`conf_prepare.py` 这类脚本在 `sys.stdin.isatty()` 为假时**自动取默认值**：
```
Using APP_DIR=... (stdin is not interactive).
Using MOBIUS_DATA_PATH=... (stdin is not interactive).
```
直接跑就行，不需要 `expect` / PTY。
★ **它会把随机生成的凭据打印出来 —— 那才是要交给用户的东西**：
```
JWT_SECRET=3b78be...442b
MOBIUS_BOOTSTRAP_USERS=admin:NEJMRdceiSP2W05p2jd0jsgM:admin:管理员
```
配置完必须再跑一次自检（本例 `conf_check.py` → `Configuration OK`）才算就绪。

★ **模型 API 这类凭据多数项目是在 Web 后台配的**（本例：管理中心 → 模型接入 →
Codex / Claude Code 两个标签），**不是改配置文件** —— 先翻 `docs/tutorial/`，
别自己对着 `.env` 的变量名猜格式。同理，`.env` 里的 `MODEL_ACCESS_PATH`
只是个待生成的文件路径，不代表格式。

★ 但**确认"是后台配"之后别停在"让用户去点"**：后台通常是 REST API，
读源码找端点就能直接写进去（端点、请求体字段、报错原文、Codex 可用 TOML、
端到端冒烟命令 → `references/agent-os-model-wiring.md`）。

