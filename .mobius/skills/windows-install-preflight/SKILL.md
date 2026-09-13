---
name: windows-install-preflight
description: 墙内 Windows（老笔记本）上安装/部署大件之前的前置体检与路线选择——磁盘空间扫描与清理（du 顶层扫描、pagefile、一键重装残留、Temp、回收站）、运行时盘点（node/python/git/docker）、虚拟化与 WSL 状态判定（HypervisorPresent=False ≠ BIOS 没开 VT-x）、WSL2 vs Docker Desktop 路线取舍、"用户说删了其实没删"的核验规矩。触发词：帮我装/跑X、空间不够、C盘满了、腾空间、磁盘清理、docker 装不上、wsl、虚拟化没开、下载这么大怎么跑、显卡不够能不能跑、接模型、模型接入、配API key、agent OS 起不来。
---

# Windows 装机前置体检（墙内老笔记本）

## 触发条件
用户说「帮我装个 X」「同步一下这个我试试」「下载那么大怎么跑」「空间不够」时——
**先体检，再动手**。这台机器（Win11 专业版 22631，i5-6300HQ，**8 G 内存**）
的常态是 C 盘 92~95% 占用、D 盘 80~98% 占用，不体检直接开工会中途炸。

## 四步体检（按顺序，都只读、都快）

### 1. 空间
```bash
df -h /c /d
ls -lh /c/pagefile.sys /c/hiberfil.sys /c/swapfile.sys 2>/dev/null   # 虚拟内存/休眠文件
du -sh /c/Users/<user>/AppData/Local/Temp
du -sh '/c/$Recycle.Bin' '/d/$Recycle.Bin'
```
顶层大户扫描**几百万文件、要几分钟 → 后台跑，别前台等**：
```bash
{ echo "=== C ==="; du -sh /c/* 2>/dev/null | sort -rh | head -25;
  echo "=== D ==="; du -sh /d/* 2>/dev/null | sort -rh | head -25; } > ~/disk_scan.txt
```
（background=true + notify_on_complete=true。前台 `wait` 会被钳到 60 s，要再 wait 一次。）

可删目标目录的判据、实测大户清单 → `references/disk-space-triage.md`

### 2. 运行时盘点
```bash
node --version; npm --version; python --version; py --version; git --version; docker --version
```
**逐个实测，别假设**——这台机器有 node v24 / npm 11 / Python 3.11 / git，但 docker 从来没装。

### 3. 虚拟化 / WSL 状态（★ 最容易误判的一步）
```bash
net session >/dev/null 2>&1 && echo 管理员 || echo 普通用户   # 改系统功能要不要 UAC
powershell -NoProfile -Command "(Get-CimInstance Win32_ComputerSystem).HypervisorPresent"
powershell -NoProfile -Command "Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, VirtualizationFirmwareEnabled, SecondLevelAddressTranslationExtensions, VMMonitorModeExtensions | Format-List"
powershell -NoProfile -Command "Get-WindowsOptionalFeature -Online | Where-Object {\$_.FeatureName -match 'Hyper-V|Subsystem|VirtualMachinePlatform|Containers'} | Select-Object FeatureName, State | Format-Table -AutoSize"
```

★ **`HypervisorPresent = False` 只说明 Hyper-V/虚拟化功能没启用，不等于 BIOS 里没开 VT-x。**
判据看 `Win32_Processor`：`VirtualizationFirmwareEnabled` / `VMMonitorModeExtensions` / `SecondLevelAddressTranslationExtensions`
—— 实测 i5-6300HQ 三个全 `True`（BIOS 早就开着），
而 `Get-WindowsOptionalFeature` 里 `VirtualMachinePlatform` / `Microsoft-Windows-Subsystem-Linux` /
`Microsoft-Hyper-V-All` **全 Disabled**。所以只需启用功能 + 重启，**不用让用户进 BIOS**。

### 4. 下载源连通性
海外源先测，别假定。实测：
- `desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe` → **200**（慢，12 s）
- `desktop.docker.com/win/stable/amd64/...` → **000**
- `winget search Docker.DockerDesktop` → 有，4.90.0
- GitHub 直连被墙时的降级 → skill `gfw-network-troubleshooting`

## 路线选择：WSL2 直跑 vs Docker Desktop（墙内）

跑一个 **Linux 原生项目**（依赖 tmux / apt 那一套）时：

| | Docker Desktop | **WSL2 直跑** |
|---|---|---|
| 依赖源 | Docker Hub（墙内基本拉不动，国内 accelerator 也倒光了） | apt / npm / pip **全可换国内源** |
| 占空间 | 本体 ~3 G（C 盘）+ 镜像 10~15 G | 只要发行版本身 |
| 常驻内存 | WSL2 后端 VM 吃 2~4 G | 同等或更省（无 daemon） |
| 官方支持 | 官方一键脚本走这条 | 官方 README 的"直接部署"段就是这条 |
| 代价 | 装完还要配 registry 加速，且可能卡在拉基础镜像 | **启用 WSL 必须重启一次电脑** |

**8 G 内存的老笔记本 → 优先 WSL2 直跑。** 理由要讲给用户听：
绕开 Docker Hub、省 3 G 空间、少一个常驻服务。

启用（管理员）：
```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
# 重启后用 Get-WindowsOptionalFeature 逐项核验（见下），再装发行版
```

核验功能是否真的启用（★ 一次只能查一个 feature，传数组会报
`无法将 System.Object[] 转换为 FeatureName`）：
```bash
for f in Microsoft-Windows-Subsystem-Linux VirtualMachinePlatform HypervisorPlatform; do
  echo -n "$f : "; powershell -NoProfile -Command "(Get-WindowsOptionalFeature -Online -FeatureName $f).State" | tr -d '\r' | head -1
done
```
重启是否生效看 `RebootPending` 注册表项；`wsl.exe --status` 里出现
`内核版本： 5.10.16` 才算 WSL2 内核就位（之前会报"未找到 WSL 2 内核文件"）。

### ★ 装发行版：别走 `wsl --install -d Ubuntu`（实测卡死）

墙内这台机器上 `wsl.exe --update` / `wsl --install` 走 **Microsoft Store** 那条路，
实测**挂满 420 s 超时、什么都没装成**（Store 侧不通）。确定性路线是手动两件套：

1. **内核**：下 `wsl_update_x64.msi`（17,104,896 字节）→
   `cmd //c "msiexec /i D:\...\wsl_update_x64.msi /qn /norestart"` → 成功标志
   `C:\Windows\System32\lxss\tools\kernel` 出现（约 70 MB）。
2. **发行版**：从**清华镜像**下 Ubuntu rootfs tarball → `wsl --import`。

全程步骤、URL、sha256、坑 → `references/wsl2-install-cn.md`
可直接改三个变量复用的脚本 → `scripts/wsl2-import-ubuntu-cn.sh`

★ **手动 `wsl --import` 反而更好**：它跳过"设 Linux 用户名/密码"的交互，
用户一个字都不用敲。进镜像后用脚本自己建用户 + 免密 sudo + 写 `/etc/wsl.conf`
（见 references）。对"不想记密码"的用户是最优解，要主动讲这层好处。

之后在 WSL 里：换 apt 源 → `apt install tmux git python3 ...` →
npm 走 `registry.npmmirror.com`、pip 走清华源。

★ **Node 若是手装 tarball**（不是 apt 装的）：全局 CLI 必须软链 `<node>/bin/*` 进
`/usr/local/bin`，并把 `prefix=/usr/local` 写进 `/etc/npmrc` —— 否则 `npm i -g <cli>`
报成功、`command -v` 却找不到（实测 claude / codex 双双中招）。细节 → references。
配置脚本的自检段要打 `command -v` 循环，别只 echo "OK"（这个循环才是抓出该坑的东西）。

### 装完最后一哩：接模型（别让用户点表单）

项目自带 Web 后台「模型接入」时，**读源码找出 admin REST API 直接写进去**，
比让用户对着表单猜字段快得多（实测他直接选"你把 key 发我、我直接写好"）。
端点/请求体/报错原文/Codex 可用 TOML/冒烟测试 → `references/agent-os-model-wiring.md`

- ★ **模型 ID 先问 API**：`curl .../v1/models` —— 实测 DeepSeek 是
  `deepseek-flash` / `deepseek-v4-pro`，**根本没有 `deepseek-chat`**，凭印象填必错
- ★ **Codex CLI 0.144.6 已废弃 `wire_api = "chat"`**（加载配置直接报错），只认 `responses`。
  接国产模型前先探端点支不支持 `/v1/responses`；不支持就改走 Claude Code 标签，
  别硬填 chat。同一个 key 实测两种协议都可能通（`/v1/responses` + `/anthropic/v1/messages`）
- ★ TOML 里**必须有 `api_key` 行**（哪怕真 key 放在 `secret_value` 里）——
  占位符只认 `<API_KEY>` 和 `REPLACE_WITH_ENV_OR_SECRET_MANAGER`
- ★ 费用要**主动报**：Codex 每开一个新会话先烧 ~1 万 token（实测"只回复两个字"= 10,563），
  与任务大小无关 → 建议按任务分渠道（便宜快模型干简单活 / 强模型干难活）

## ★ 核验规矩：用户说「删了」≠ 真的删了

实测：用户回「**1删了 5删了 C盘清理了**」，核验发现**两个目录都还在原地**
（7.7 G / 2.0 G），C 盘 Temp 也还是 3.3 G。磁盘只多了 2 G。
两个回收站都**不大**（D 153 M / C 533 K）→ 说明根本没删进去，
多半是删除被占用/权限挡了，或用户以为自己删了。

**规矩：收到「删了/清理了」一律先核验再说。**
```bash
for p in '/d/目标1' '/d/目标2'; do
  [ -e "$p" ] && { printf "还在: %s  " "$p"; du -sh "$p" | cut -f1; } || echo "已删除: $p"
done
du -sh '/d/$Recycle.Bin' '/c/$Recycle.Bin'; df -h /c /d
```
核验完再问是否代删；代删用 `rm -rf`（git-bash 里路径含 `$$` 必须**单引号**，
否则 `$$` 被展开成 PID），清 Temp 用 `rm -rf <Temp>/* 2>/dev/null`（被占用的会自动跳过）。

## 用户偏好（回话方式）
- **中文、极简、结论先行**；列**编号清单**让用户按编号回（实测他回「1删了 5删了」）
- 给**封闭选项 A/B/C** 让他拍板（实测选 A 时就是选了你推荐的那个）
- **安装类任务**：下载安装包 → 交给他双击，别代跑向导；每完成一步报路径 + 校验字节数
- **系统级操作**（启功能、删数据）可以直接做，但**必须说清做了什么、需不需要重启**
- ★ **但「删第三方 app 的目录」是例外，先要一句确认**：实测代删 Steam 应用残壳时
  用户把 `rm -rf` **直接拦下**了。被拦下就**停手、把路径原样写给他让他自己决定，
  绝不换个写法重试**。这类"删别人的东西"的最佳分工是：**我诊断 + 报告 + 给出路径，
  关键动作他自己点**（这次他自己在 Steam 里把 WE 移库，一次就成了）。
- 用户说「显卡不够怎么跑」这类担忧时，先**拆穿不必要的顾虑**（API 型项目不吃显卡），
  再讲真正的瓶颈（磁盘/内存）——别顺着他的担忧往下答
- 用户在意 token/费用：一次给完，别逐条挤
- **长下载 / 长安装别让用户盯着**：用户说过"等太久我先睡一会"「11 起来了」——
  信号是要**无人值守**。做法：把"下载→校验→导入→配置"写成一个
  **幂等**的 bash 脚本（每步都能重跑，日志 `tee` 到文件），
  `terminal(background=true, notify_on_complete=true)` 挂上，然后告诉他
  "去睡，跑完我收到通知"，并给出**日志文件绝对路径**让他自己也能看。
  步骤失败要能自愈（换镜像重试）+ 明确退出码，别留半成品。
- **「装完了」后面还有「启动起来」** —— 启动/构建脚本的输出用 `> log 2>&1` 落盘，
  **别用 `| tail -N`**：管道会缓冲，日志文件会 0 字节挂到进程结束，看着像卡死
  （实测 start.py 挂 100 s 日志仍是 0 字节）。想看它此刻在干什么：
  `ps -eo pid,etime,pcpu,rss,comm,args --sort=-pcpu`（一眼看出是 `tsc --noEmit` 在
  116% CPU / 711 MB 编译，而不是死循环）。
  启动排障三件（真端口看启动日志不看 `.env`、可选组件失败会中断整条启动、
  非交互配置脚本会自取默认值并打印凭据）→ `references/wsl2-install-cn.md` §8
- 报进度时给**可核对的数字**（`143 MB / 325 MB (44%)`、`exit=0`、sha256 前缀），
  别只说"正在下载中"。他信数字不信形容词。

## 坑
- `du -sh /c/*` 前台会卡好几分钟 → 后台 + notify
- git-bash 里 `$Recycle.Bin` / `$$...` 这种路径**必须单引号**，否则被 shell 展开（`$$` 会变成 PID）
- ★ **给 WSL 里的服务做 Windows 侧「一键启动器」（.bat）**时两个坑（实测各踩一次）：
  ① **.bat 必须存成 GBK**（`iconv -f UTF-8 -t GBK 源 > 目标`）—— cmd 对 UTF-8 批处理有解析 bug，
     会把含中文的行拆成多条命令、报「XX 不是内部或外部命令」；**别加 `chcp 65001`**。
  ② **别用 `timeout /t N` 当等待** —— 会命中 Git for Windows 的 GNU `timeout`，报
     `timeout: invalid time interval '/t'`；改用 `ping -n N 127.0.0.1 >nul`（`-n N` ≈ 等 N-1 秒）。
  骨架：`wsl.exe -d <distro> -- echo ok`（顺带把 WSL 拉起来）→
  `curl.exe -s -o nul -m 5 http://localhost:<port>/health` 判断是否已在跑（`if not errorlevel 1`）→
  没跑就 `wsl.exe -d <distro> -u <user> -- bash -lc "cd ~/<proj> && python3 start.py --detach"` →
  `for /l %%i in (1,1,60)` 轮询端口 → `start "" http://localhost:<port>`。
  完整实测样例（含端口探测与就绪等待）→ skill `mobius-agent-os` 的「Windows 一键启动器」
- **交付「装完能用」要给用户一条最短路径**：桌面快捷方式/启动器 + 账号密码 + 一句话「重启电脑后服务不会自己起，双击这个」。
  实测用户明确要「桌面启动吧」。别只交付服务本身。
- ★ **git-bash 里调 `wsl.exe -d X -- bash -c '...'` 时，字符串里的 `$VAR` 会被外层 Windows bash 先展开**：
  实测 `export PATH=/usr/local/bin:$PATH; ...` 里的 `$PATH` 被换成一大串带括号的 Windows 路径 →
  `bash: -c: line 1: syntax error near unexpected token '('`（同一个坑连踩两次）。
  用 `bash -lc`（字符串里别出现 `$VAR`），或更稳的：**把脚本写到 `/mnt/d/...` 再 `bash 那个文件`**。
- `df -h` 数字会滞后（实测同一盘先读到 3.0 G、几分钟后是 13 G）→ 关键决策前**再测一次**
- 清 Temp 后仍有残留（200 M 级）是正常的（被占用文件删不掉）
- 别把「用户没装 X」当成 bug 去修——那只是状态；**cap 成"体检结论 + 安装步骤"**
- Windows 上真需要 Linux 工具链时，**别急着说"Windows 原生跑不了"**——
  WSL2 就是解法，先看虚拟化状态再下结论
- ★★ **`.env` 改了但 `pm2 restart` 不生效 = PM2 生态配置把 env 在启动那刻快照了**（同类项目通病）：
  `ecosystem.config.js` 用 `envKeys` 白名单 + `inheritedEnv` 在 PM2 启动时拷一份，
  `pm2 restart --update-env` 只刷新「当前 shell 里存在的变量」（而你的 shell 里并没有它们）→
  行为不变、`pm2 list`/uptime 却完全正常，**极易误判成「配置写法错了」**。
  正解是**重跑项目的启动脚本**（让它重新 `load_dotenv` 再重建 PM2 应用），代价是重编前端。
  **判据用接口行为，别用 `pm2 status`。** 实例 → skill `mobius-agent-os` 坑 4
- ★ **Hermes 终端会对输出脱敏**含 `PASSWORD|SECRET|TOKEN|KEY` 的赋值行（显示成 `***`）→
  于是 `--- 改前 ---` / `--- 改后 ---` 长得一模一样，**没法确认 sed 到底生效没**。
  三种读法：① 布尔判定 `grep -qx 'X=false' f && echo YES`；
  ② 换形再读 `sed -n '145p' f | sed 's/PASSWORD/PW/g'`；
  ③ 看长度 `awk -F= '/^X=/{print length($2)}' f`。
  更稳的是**直接行为验证**（调接口看返回码变化），别读文件。**别以为文件内容真的是 `***`。**
- ★ **「后端自己去 GitHub 同步产物」的服务在墙内永远失败**（如 Mobius 的 desktop-sync 拉桌面端安装包）：
  日志签名 `connect ECONNREFUSED 127.0.0.1:443`（宿主 hosts 劫持 + WSL 的 127.0.0.1 不是 Windows 的）
  → 对应的网页下载入口永远 404。**别去修那个同步器**，手动把产物喂进它期望的本地目录、
  用项目自带的 manifest 生成脚本重建清单即可（实例 → skill `mobius-agent-os` 坑 5）

### 下载大文件的坑（WSL 镜像那轮实测）
- **别用 `curl -C -` 断点续传到国内镜像站**：服务器可能**忽略 Range 头**，
  直接把整个文件返回，curl 把它**追加**到已有部分后面 →
  文件变成"旧前缀+完整文件"的拼接垃圾（实测 341 MB 变 456 MB）。
  接着 `tar`/`wsl --import` 不会报错（exit 0），只是导出一个**坏系统**，
  直到 `bash` 跑出 exit 127 + UTF-16 乱码才发现。**宁可重下，不要续传。**
- **落盘后必须过校验门**：`stat -c %s` 对 Content-Length，再
  `sha256sum` 对镜像站的 `SHA256SUMS`。对不上就删掉换镜像重下（3 轮），
  **绝不把未校验的文件喂给 import**。
- `wsl.exe` 的输出是 **UTF-16LE**，git-bash 里直接读是乱码：
  `wsl.exe -l -v 2>&1 | iconv -f UTF-16LE -t UTF-8 | tr -d '\r'`
- 墙内下载源顺序（实测速度）：**清华 TUNA 342 KB/s > 中科大 USTC ≈ 清华 > 微软 blob 24~42 KB/s**。
  清华有全套 `ubuntu-cloud-images` 镜像，别去直连 `cloud-images.ubuntu.com`。
- 大文件下载会**互相抢带宽**（实测 Steam 同时在下创意工坊时掉到 26 KB/s）。
  下载前先 `tasklist | grep -i steam`，必要时让用户暂停 Steam 下载。
- **无人值守脚本里 curl 必须带 `-s`（或 `--no-progress-meter`）**：不带就会把
  进度条一行行刷进 `tee` 的日志（实测 install.log 被进度条占满，真正的
  时间戳行被淹没）。同理 `-w` 的自定义格式别和默认进度条叠着用。
- **并发任务要先给用户算「资源总账」**：用户会主动问「A 影响我们另一个计划吗」。
  同时进行两件下载/安装时，动手前把三样数字摆出来再排顺序 ——
  ① 带宽（谁在和谁抢，实测 550 KB/s → 70 KB/s，ETA 10 分钟 → 1.5 小时）
  ② 目标盘余量（A 的产出会不会把 B 要用的盘挤爆）
  ③ 内存/CPU（8 G 老笔记本，下载 + 渲染 + apt 装包同时上就卡成幻灯片）。
  然后给**串行顺序**建议（先把当前这条跑完，再动另一条），别让两条并行互相拖死。

## 支持文件
- `references/disk-space-triage.md` — 实测大户清单、可删/不可删判据、扫描命令集、回收站清理
- `references/wsl2-install-cn.md` — 墙内 WSL2 手动安装全流程（内核 MSI + 清华 rootfs + sha256 校验 + import + 免密用户 + 镜像内手装 Node 的 PATH/prefix 坑）；**§8 首次启动排障**（`| tail` 缓冲坑、真端口看启动日志不看 `.env`、可选组件失败中断整条启动、非交互配置脚本与凭据打印）
- `references/agent-os-model-wiring.md` — 装完接模型：走后台 admin REST API 直接写渠道
  （login/端点/请求体字段）、TOML 的 `api_key` 占位符与 `env_key` 一致性约束、
  **Codex 已只认 `wire_api="responses"`**、`codex --profile … exec` 端到端冒烟、
  Codex 每会话 ~1 万 token 固定开销、`codex doctor` 假警报清单
- `scripts/wsl2-import-ubuntu-cn.sh` — 幂等脚本：带校验门的下载 → import → 冒烟测试 → 配置
- 网络/GitHub 直连相关 → skill `gfw-network-troubleshooting`
