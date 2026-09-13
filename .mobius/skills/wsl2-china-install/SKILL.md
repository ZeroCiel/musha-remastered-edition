---
name: wsl2-china-install
description: 墙内 Windows 上从零装 WSL2 + Ubuntu，绕开会卡死的 Microsoft Store 路线——手动装内核 MSI、清华镜像下 rootfs、sha256 校验门、wsl --import、一键配置（apt/pip/npm 换国内源、免密 sudo、Node 全局 bin PATH 坑）。当需要 WSL/Linux 环境、Docker 替代方案、在墙内装 Linux 发行版、或要在 WSL 里跑 Linux-only 项目（如 Mobius agent OS 这类写死 tmux 的服务）时使用。含无人值守长流程装机的做法与汇报风格。
---

# 墙内 Windows 装 WSL2 + Ubuntu（不碰 Store）

## 为什么不用官方路线
- `wsl --update` 在 Win11 22631（inbox wsl.exe 10.0.22621.4745）实测**卡死 10 分钟以上**——它走 Microsoft Store 拉 MSIX，Store 这条路墙内常不通。
- `wsl --install -d Ubuntu` 同理。
- **可行路线**：手动装内核 MSI + 手动下载 rootfs 用 `wsl --import` 导入。全程不需要 Store，也**不需要交互式设用户名密码**（import 出来的系统只有 root，用户自己建）。

## 步骤 0 — 前置体检（管理员权限的 shell）
```bash
# wsl.exe 输出是 UTF-16LE，必须转码，否则全是乱码
wsl.exe --status 2>&1 | iconv -f UTF-16LE -t UTF-8
wsl.exe -l -v   2>&1 | iconv -f UTF-16LE -t UTF-8

# 功能是否已启用（一次只查一个 FeatureName，传数组会 ParameterBindingException）
for f in Microsoft-Windows-Subsystem-Linux VirtualMachinePlatform; do
  powershell -NoProfile -Command "(Get-WindowsOptionalFeature -Online -FeatureName $f).State"
done

# Hypervisor 是否在跑（True = BIOS 虚拟化没问题；VirtualizationFirmwareEnabled 常误报 False，别信它）
powershell -NoProfile -Command "(Get-CimInstance Win32_ComputerSystem).HypervisorPresent"

# 是否有挂起重启（改完功能必须重启才生效）
powershell -NoProfile -Command "Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'"
```
没启用就 `dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart`（VirtualMachinePlatform 同理），然后**重启**。Hyper-V 不用开。

## 步骤 1 — 内核（关键：别用 wsl --update）
手动下官方 MSI（微软 CDN 墙内可达，但慢，约 24~42 KB/s）：
```
https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi
# 大小恒为 17,104,896 字节；文件头应为 d0cf 11e0 a1b1 1ae1（OLE 复合文档）
```
```bash
cmd //c "msiexec /i D:\path\wsl_update_x64.msi /qn /norestart /l*v D:\path\msi.log"
```
验证：`C:\Windows\System32\lxss\tools\kernel` 出现（约 70MB）。
之后 `wsl --status` 应显示「内核版本： 5.10.16」而不再报「未找到 WSL 2 内核文件」。

## 步骤 2 — rootfs（清华镜像 + sha256 校验门）
```
# 清华（推荐，实测 300~550 KB/s，比微软源快 8~14 倍）
https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cloud-images/wsl/jammy/current/ubuntu-jammy-wsl-amd64-ubuntu22.04lts.rootfs.tar.gz
# 中科大备用
https://mirrors.ustc.edu.cn/ubuntu-cloud-images/wsl/jammy/current/<同名文件>
# 校验和（同目录）
https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cloud-images/wsl/jammy/current/SHA256SUMS
```
jammy 版本固定为 **341,130,963 字节**，sha256 `1483cc5c1dce13064f774834cbffdff226559fd522a67a381a8ea77d63fb4109`。

### ★★ 最大的坑：不要用 `curl -C -` 续传
清华镜像**忽略 Range 请求头**。用 `-C -` 续传时服务器直接回整份 200，curl 把完整文件**追加**到已有片段后面 → 文件变成 341MB+X（实测 456MB），内容交错损坏。

后果尤其阴险：
- `sha256sum` 当然不符；
- 但 **`wsl --import` 不做任何完整性检查，照样返回退出码 0**；
- 之后进去执行任何命令都是 `exit code 127` + 乱码，`wsl -l -v` 却显示发行版正常。

**正确做法**：
```bash
curl -L --retry 3 -m 2400 -o "$TAR" "$URL"          # 不加 -C
[ "$(stat -c %s "$TAR")" = 341130963 ] || 重下
[ "$(sha256sum "$TAR" | cut -d' ' -f1)" = "<上面的sha>" ] || 重下   # 不符就删掉换镜像重来
```
修不回一个坏文件——别想着 `tail -c` 截取尾部或按偏移切开，交错写入的位置对不上，直接重下。

## 步骤 3 — 导入 + 冒烟测试
```bash
mkdir -p /d/WSL
wsl.exe --import Ubuntu2204 "D:\\WSL\\Ubuntu2204" "D:\\wsl-dl\\ubuntu-jammy.rootfs.tar.gz" --version 2
# 必须冒烟测试，别急着跑配置
wsl.exe -d Ubuntu2204 -u root -- echo WSLREADY     # 必须回 WSLREADY
wsl.exe -d Ubuntu2204 -u root -- uname -r
```
发行版放 **D 盘**（C 盘常年紧张）；`.wslconfig` 写 C:\Users\<user>\.wslconfig：
```ini
[wsl2]
memory=3072MB
processors=3
swap=4096MB
swapFile=D:\\wsl-swap.vhdx
```

## 步骤 4 — 配置脚本（在 WSL 内以 root 跑）
脚本写到 Windows 侧再用 `wsl` 调用时**必须先去掉 CRLF**，否则变量名尾带 `\r` 各种诡异失败：
```bash
wsl.exe -d Ubuntu2204 -u root -- bash -c "sed -i 's/\r\$//' /mnt/d/wsl-dl/setup.sh; bash /mnt/d/wsl-dl/setup.sh"
```
配置要点（都换成国内源）：
- apt：`sed -i 's|http://archive.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g; s|http://security.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list`
- pip：`/root/.config/pip/pip.conf` + `/home/<user>/.config/pip/pip.conf` → `index-url = https://pypi.tuna.tsinghua.edu.cn/simple`
- npm：`npm config set registry https://registry.npmmirror.com`
- Node：**别用 apt**（Ubuntu 22.04 自带的 nodejs 是 12.x）。下清华的官方二进制包：
  `https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/v18.20.8/node-v18.20.8-linux-x64.tar.xz` → 解到 `/usr/local/lib/nodejs/`

### ★ Node 全局 bin 的 PATH 坑
从 `node:18-bookworm` 那类镜像搬过来的习惯会踩：手动解包 Node 后，`npm install -g` 的 prefix 是按 **symlink 的真实路径**推算的，全局包会落到
`/usr/local/lib/nodejs/node-v18.20.8/bin/`，那里**不在 PATH 里** → `claude`、`codex`、`pm2` 全都「装了但 command not found」。

修法（一次修彻底）：
★ **目录名带 `-linux-x64` 后缀**（`node-v18.20.8-linux-x64`）。写死成不带后缀的名字会让下面的
`for` glob **不展开** → `ln` 把 `/usr/local/bin/*` 当成"多源单目标"解析，报
`ln: target '/usr/local/bin/uvx': Not a directory`。**看到这个报错 = glob 没展开 = 路径取错了**，
而且此时 `ls "$D/bin"` 是**空的**（因为目录压根不存在）——先看这个更快。
★ 更彻底的治理：`echo 'prefix=/usr/local' > /etc/npmrc` —— 之后所有 `npm i -g` 直接落
`/usr/local/bin`，不再依赖软链，也不会再踩这一类坑。

```bash
D=$(ls -d /usr/local/lib/nodejs/node-v*-linux-x64 | head -1)   # ★ 必须这么取，见上
for b in "$D"/bin/*; do ln -sf "$b" /usr/local/bin/$(basename "$b"); done
printf 'export PATH=%s/bin:$PATH\n' "$D" > /etc/profile.d/nodejs.sh
```

### 免密 sudo + 默认用户
```bash
useradd -m -s /bin/bash -G sudo <user>
echo '<user>:<pw>' | chpasswd
printf '%s ALL=(ALL) NOPASSWD:ALL\n' <user> > /etc/sudoers.d/<user>
chmod 0440 /etc/sudoers.d/<user>
printf '[user]\ndefault=%s\n' <user> > /etc/wsl.conf
wsl.exe --terminate Ubuntu2204   # 改完 wsl.conf 必须 terminate 才生效
```
给用户一个「不用记密码」的体验：默认用户 + NOPASSWD，日常一次密码都不用敲。

## 跨文件系统访问（Windows ↔ WSL）
- **WSL 看 Windows 盘**：`D:\xxx` → `/mnt/d/xxx`（agent 能直接读/写 Windows 侧项目，不必先搬）
- **Windows 看 WSL**：资源管理器地址栏直接粘 `\\wsl.localhost\<发行版名>\home\<用户>\...`
  （Win11 实测可列目录；旧写法 `\\wsl$\<发行版名>\...` 同样可用）
- ★ **别在 `/mnt/*` 下跑 `git` / `npm install` / 编译**（9p 跨文件系统极慢，会拖死 agent）→ 先 `cp -r` 进 ext4
- ★ **从 Windows 侧用 PowerShell 查 UNC 路径，别内联在命令行里**：`\\` 经 git-bash → PowerShell
  传参**会被吃掉一层**，实测报 `找不到路径 C:\wsl.localhost\Ubuntu2204\...`（根被换成当前盘符）
  —— 看着像 WSL 坏了，其实是转义问题。写成 `.ps1` 再 `powershell -NoProfile -ExecutionPolicy Bypass -File x.ps1`：
  ```powershell
  Get-ChildItem -LiteralPath "\\wsl.localhost\Ubuntu2204\home\<用户>" | Select-Object -First 5 -ExpandProperty Name
  ```
  同理任何「UNC / 反斜杠路径 + PowerShell」的探测都走 `-File`，不要内联成一行。
- **反向也常踩**：`wsl.exe -- bash -c "...$VAR..."` 里 `$VAR` 被**外层 Windows bash 提前展开** → 用 `bash -lc` 或把脚本落到 `/mnt/d/` 再 `bash 文件`（见陷阱表）。
- 跨系统传脚本**每次先 normalize 行尾**，别假设：`.sh` 进来先 `sed -i 's/\r$//'`；
  反之给 Windows 的 `.bat` 要 **CRLF + GBK**（见陷阱表末两行）。

## 陷阱速查
| 症状 | 原因 | 解法 |
|---|---|---|
| `wsl --update` 长时间无输出 | 走 Store | 手动装内核 MSI |
| `wsl.exe` 输出乱码 | UTF-16LE | `iconv -f UTF-16LE -t UTF-8` |
| `--version` 报用法错误 | inbox wsl.exe 太老（22621.4745） | 正常，用 `--status` 代替 |
| import 返回 0 但里面啥都跑不了 | tar 损坏，import 不校验 | sha256 校验门，重下 |
| 全局 npm 包装了但找不到 | prefix 落在 `/usr/local/lib/nodejs/*/bin` | 全量 symlink + profile.d |
| 配置脚本变量诡异失效 | CRLF | `sed -i 's/\r$//'` |
| 在 `/mnt/c/...` 下跑 npm install 极慢 | 跨文件系统 | 先 `cp -r` 进 `~` |
| 安装/启动链在中途 `exit code 2`，前面步骤明明都成功 | 某一步在 GitHub 下运行时超时（如 uv 拉 python-build-standalone） | 别重试硬等：改用系统解释器 + 国内源跳过该步 |
| `bash: -c: line 1: syntax error near unexpected token '('` | git-bash 调 `wsl.exe -- bash -c '...'` 时 外层 Windows bash **先展开了 `$VAR`**（如 `$PATH`） | 用 `bash -lc`（串里别写 `$VAR`），或写脚本到 `/mnt/d/...` 再 `bash 文件` |
| 后台跑的脚本日志一直 0 字节、看不到进度 | 管道里的 `tail -N` 会缓冲到命令结束 | 直接 `cmd > log 2>&1`，再 `tail` 那个文件 |
| Windows 侧 PowerShell 查 `\\wsl.localhost\...` 报「找不到路径 `C:\wsl.localhost\...`」 | git-bash → PowerShell 传参吃掉一层反斜杠 | 写成 `.ps1` 用 `-File` 跑，别内联（见「跨文件系统访问」） |
| 中文 `.bat` 报「不是内部或外部命令」、`timeout /t N` 报 GNU timeout 用法错 | cmd 对 **UTF-8 批处理有解析 bug**（会把中文行拆成多条命令）；PATH 里 Git 的 `timeout.exe` 抢先 | `.bat` 存 **GBK**（`iconv -f UTF-8 -t GBK`，**别加 `chcp 65001`**）+ 用 `ping -n N 127.0.0.1 >nul` 代替 `timeout`；行尾 CRLF |
| 配置值"改了但没生效" / grep 看值是 `***` | ① 服务把 env 在启动时固化（见 `references/mobius-agent-os.md` 的 PM2 一节）；② Hermes 日志层把含 PASSWORD/SECRET/TOKEN/KEY 的赋值**脱敏** | 改完必须走服务自己的重启入口；读值用布尔断言 `grep -qx "K=v" f && echo OK` 或 `sed 's/PASSWORD/PW/g'` 打印原文 |

## 验证清单
```bash
wsl -l -v                                  # VERSION 2，STATE Running
wsl -- whoami                              # 默认用户
wsl -- bash -lc 'for c in tmux git curl python3 pip3 node npm; do command -v $c; done'
wsl -- df -h /
```

## 空间预算（8G 内存 / 小硬盘机器参考）
Ubuntu 22.04.5 裸系统 + 常用包 ≈ 1.8~2.0 GB（vhdx 动态增长，**不会自动缩**）；
再装 Node + code-server + 全局 CLI + 一个 Node 项目依赖 ≈ 总共 5~6 GB。
swap vhdx 上限按 `.wslconfig`，实际按需增长。

## 无人值守长流程（这台机器上实测最省事的方式）

装机 + 配置 + 装依赖整条链要跑几十分钟，用户不该盯着。做法：

1. 把整条链写成**幂等** bash 脚本，落到 Windows 盘（如 `D:\wsl-dl\setup.sh`）——
   可重复跑、跳过已完成步骤，断电/中断后重跑不炸。
2. 执行前**三道预处理**：`sed -i 's/\r$//'` 去 CRLF → `bash -n` 过语法 → 再真跑。
3. 用 `terminal(background=True, notify_on_complete=True)` 跑，脚本内 `exec > >(tee -a log)`
   把日志落盘，用户随时可查；报告用 `[n/N]` 步骤打印，汇报时直接贴步骤表。
4. **每步设门，别让坏输入流进下一步**：sha256 校验门（不通过就删掉换镜像重下）→
   冒烟测试门（`echo WSLREADY`）→ 通过了才进配置。失败自动重试/换源，最多 3 轮。
5. ★ **别和 Steam 抢带宽**：开始前让用户暂停 Steam 下载队列，实测速度差 5~8 倍
   （Steam 侧处置见 `steam-app-repair`）。两个大下载并跑时把 ETA 直接告诉用户。
6. ★ 后台脚本里 **curl 不要省 `-s`**：进度条会往日志里刷上千行，把有用的输出冲没
   （改用 `-sS` + `-w` 自己打印摘要）。
7. ★ terminal 工具**拒绝带 `&`** 的命令 → 并行测速用 `xargs -P4` 或 `curl --parallel`。

### 汇报风格（这个用户）
- 先给**「能 / 不能」的直接结论**，再给数字，最后给下一步选项——别绕。
- 数字要成账：磁盘余量、端口、各目录占用、"还要多少 G"。用户会直接问"还要多少 G"。
- 进度用**编号块 + 代码块**呈现（`[✓]/[→]/[ ]` 步骤表），用户靠编号回指。
- 跑完主动提醒"存档 + 开新会话"省钱。

## 国内源速查

| 用途 | 源 |
|---|---|
| Ubuntu rootfs / cloud-images | `mirrors.tuna.tsinghua.edu.cn/ubuntu-cloud-images/`（中科大 `mirrors.ustc.edu.cn/` 同路径备用） |
| apt | `mirrors.tuna.tsinghua.edu.cn`（替换 archive/security.ubuntu.com） |
| pip | `pypi.tuna.tsinghua.edu.cn/simple` |
| npm | `registry.npmmirror.com` |
| Node 二进制 | `mirrors.tuna.tsinghua.edu.cn/nodejs-release/v18.20.8/node-v18.20.8-linux-x64.tar.xz`（解到 `/usr/local/lib/nodejs` → 见上面的 PATH 坑） |
| code-server deb | `serve.nutshellai.cn/publish/auto/tutorial/code-server_4.19.1_amd64.deb`（国内源，快） |
| claude-code / codex CLI | `npm i -g --registry=https://registry.npmmirror.com @anthropic-ai/claude-code@2.1.195 @openai/codex@0.144.6` |
| uv / poetry 要下载的独立 Python 运行时（python-build-standalone，源在 GitHub Releases） | 南大 `mirrors.nju.edu.cn/github-release/astral-sh/python-build-standalone`、中科大同名路径（★ **清华没镜像这个仓库，404**）；或干脆用系统解释器别下载（见 `references/mobius-agent-os.md` 的 aimux 一节） |

★ **通用规律**：任何靠 uv / poetry / rustup / nvm 之类**去 GitHub Releases 拉运行时**的步骤，
墙内都会以「重试 N 次全超时 + Invalid tar file」告终，而且常常**直接中断整条安装/启动链**。
优先改成「用系统已有的解释器 + 国内 PyPI/镜像」，而不是硬等它重试。

## 支持文件

- `scripts/setup-ubuntu-wsl.sh` — 导入后的全量配置脚本（apt/pip/npm/Node/code-server/全局 CLI/
  拷代码装依赖 9 步，幂等，Node PATH 坑已修）。用法见脚本头注释。
- `references/mobius-agent-os.md` — Mobius（自进化 Agent OS）在本机的落地记录：路径/端口（★ 网页是
  **33316**，`.env` 里的 `MOBIUS_PORT=33314` 没在监听）/账号、为什么必须 Linux（tmux）、依赖清单、
  `conf_prepare → conf_check → start.py --detach` 三步、**aimux 桥在墙内必失败并中断整条启动链的修法**、
  **管理后台 API 直接建模型渠道**（含 Codex 渠道 `wire_api` 只认 `responses`（`chat` 已被移除）、
  `config_toml` 必须带 `api_key` 占位符、渠道名只能纯字母、DeepSeek 双接口实测、每会话约 1 万 token 成本）、
  **改 `.env` 必须走 `start.py`（PM2 把 env 在启动那刻固化）**、**免密码登录**、
  **桌面客户端**（GitHub 加速镜像 → `desktop-builds` + `manifest.json`；登录必须填用户名否则 400）、
  **项目导入流程与工作区/`\\wsl.localhost` 路径**、`| tail -N` 憋日志与 `$VAR` 被外层展开两个工具坑、
  实测资源占用。

