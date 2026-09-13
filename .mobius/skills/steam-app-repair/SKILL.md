---
name: steam-app-repair
description: Steam 应用更新/安装失败修复（Windows）：文件验证错误、某些文件似乎无法安装、缺文件被杀毒删、点了「开始游戏」没反应/UI 窗口永不出现（Files Missing → steam://rungameid 触发 Steam 自修）；创意工坊下载卡在暂存把库盘撑爆、订阅数爆盘。查磁盘空间/distribution 暂存/杀毒白名单；appmanifest_<appid>.acf 丢失 → 日志狂刷 Mbps 却零写盘的永久空转（只能重装或移库）。Wallpaper Engine 实测案例
---

# Steam App 更新/安装失败修复（Windows）

触发：Steam 更新某游戏/应用后弹"文件验证错误 / 某些文件似乎无法安装"，或启动报缺 exe/dll、被杀毒删文件。

## 快速检查清单（按序，命中最常见原因最快）
1. **关掉目标应用进程**：WE 类要查 wallpaper32/64、wallpaperui、wallpaperservice；`tasklist | grep -i wallpaper`（`wallpaperui.exe` 也含 "wallpaper"，一条 grep 全覆盖）。进程占用 = 更新拷贝失败。
   ★ **主进程在 ≠ 界面在**：WE 的 UI 是**独立进程** `bin\wallpaperui.exe`。
   ★ 别去找 `ui32/ui64.exe` —— **当前版本目录里根本没有这两个文件**（实测 WE 根目录只有
   `launcher.exe`、`wallpaper32/64.exe`，UI 在 `bin\wallpaperui.exe`）。
   一眼体检应用是否残缺（三件套齐了才算完整）：
   ```bash
   W="/c/Program Files (x86)/Steam/steamapps/common/wallpaper_engine"
   for f in launcher.exe wallpaper64.exe bin/wallpaperui.exe bin/steam_api64.dll; do
     printf "  %-24s " "$f"; [ -f "$W/$f" ] && echo "在 ($(stat -c %s "$W/$f") 字节)" || echo "★ 没了"
   done
   ```
   ★ **`log.txt` 不存在 = 该 app 从那时起压根没成功启动过**（launcher 起不来就不会写日志），
   这比看日志内容更早一步定位问题。
   用启动时间分辨**老僵尸**还是**刚被拉起来**：
   ```bash
   powershell -NoProfile -Command "Get-Process wallpaper64 -EA SilentlyContinue | Select Id,StartTime,@{N='MB';E={[math]::Round(\$_.WorkingSet64/1MB)}}"
   ```
   （实测 StartTime 就在一分钟前 = 用户刚点的、程序自己挂了；很久以前 = 文件早被换掉的僵尸。）
2. **磁盘空间**：`df -h /c /d`。C 盘 100% 时 Steam 更新写盘必失败——先腾空间再动别的（这步经常才是根因，日志会骗人，见坑1）。
3. **杀毒**：火绒托盘"退出"后 HipsDaemon **服务仍在实时防护**（tasklist 见 HipsDaemon.exe）；要停就停服务，或火绒信任区加 Steam 整个目录。杀毒误删的典型症状是启动器日志明写 "usually this means your anti-virus deleted ... by mistake"。
4. **看应用自身日志定根因**：WE 例 `wallpaper_engine/log.txt`：
   - `InstallDistribution: ... fs::copy error` 满屏 → 拷贝失败（磁盘满 / 占用 / 杀毒拦）
   - `VerifyFileHashes dst file not found: ...` → 具体缺哪些文件，照单补
5. **从 distribution/ 暂存目录补拷**：Steam 下载先落到 app 目录的 `distribution/`（完整新版），由 launcher/installer 拷到主目录。缺什么直接补：
   ```
   cd <app目录> && cp -rf distribution/. .
   comm -23 <(ls distribution/bin|sort) <(ls bin|sort)   # 查缺，空=齐
   ```
   补完校验零缺失后删 distribution 腾空间。
6. **验证**：Steam 开着时直接跑主 exe 冒烟，看进程存活 + 版本文件正常（WE 例 version.json 里 success:false 消失即修复）。

## 文件缺失：让 Steam 自己修（首选，比第 5 步手动补拷快）

**症状**：应用目录里成批文件不见了。WE 实测：`launcher.exe`、`bin\wallpaperui.exe`、
`bin\steam_api64.dll` 全没，只剩一个旧日期的 `wallpaper64.exe` 残留；
**连 `log.txt` 都没了** = 它从那以后压根没成功启动过。用户点「开始游戏」时
只会看到主进程半死不活挂着、UI 窗口永不出现。

★ **触发手段：用 Steam 协议拉一次应用 = 让 Steam 跑一次完整性校验**：

```bash
cmd //c "start steam://rungameid/<appid>"      # WE = 431960
```

`Steam/logs/content_log.txt` 会立刻报出真因并自动开始修：

```
AppID 431960 state changed : Update Required,Fully Installed,Update Queued,Files Missing,Update Running,Update Started,
AppID 431960 update started : download 0/217007296, store 0/0, reuse 0/0, delta 0/0, stage 0/547026424
Downloading 584 chunks for depot 431961
```

- 看到 `Files Missing` → 就是文件被删/丢，Steam 自己重下（本例 217 MB 下载 / 547 MB 展开），
  **不用再走第 5 步手动补拷**（手动补拷只在 Steam 不肯重下时才用）
- 拉起后**没有新进程、还只有旧僵尸** = 修复还在下载，不是失败；**等**就好
  —— ★ 但**必须先确认 manifest 在**（见下一节）。manifest 丢了就是空转，等到天亮也不会好
- 修之前**先清掉旧僵尸**，否则修完起冲突：`taskkill //F //PID <pid>`
- 无人值守（等文件齐 → 自动拉起 → 报进程/日志）→ `scripts/steam-repair-watch.sh`
  —— 监视脚本别只等文件出现就收工，**要带超时并报「还缺什么 + 当前速率」**，
  超时就按下一节判定是空转而不是没下完

### ★ 别无条件「等就好」——先确认 `appmanifest_<appid>.acf` 还在

Steam 能自己修的前提是**该库里那份 app manifest 还在**。manifest 丢了，
Steam 会进入**永久空转**：`content_log.txt` 一直刷 Mbps（实测 5~10 Mbps 刷了**两小时**），
**硬盘一个字节都不写**，app 目录大小纹丝不动。这种情况「等」是等不出来的。

两条命令 30 秒定性：

```bash
S="/c/Program Files (x86)/Steam/steamapps"
ls -la "$S/appmanifest_<appid>.acf"        # ★ 不存在 ⇒ 空转，别再等
ls -la "$S"/appmanifest_*.acf | head       # 对比：别的游戏 manifest 都好好的
```

```bash
# 90 秒增量法：日志说在下，盘上到底有没有长？
W="$S/common/<app目录>"
S1=$(du -sm "$W"|cut -f1); D1=$(du -sm "$S/downloading"|cut -f1)
sleep 90
echo "app $(( $(du -sm "$W"|cut -f1) - S1 ))M / 暂存 $(( $(du -sm "$S/downloading"|cut -f1) - D1 ))M"
grep -a "Current download rate" "/c/Program Files (x86)/Steam/logs/content_log.txt" | tail -2 | sed 's/.*rate: //'
```

实测：日志刷 `7.5 Mbps`，增量 **0 M / 0 M**，`steamapps/downloading/` 还是空的
→ 定性「下载 → 提交失败 → 重下」死循环。
★ **速率数字完全不可信，只信盘上增量**；`Current download rate` 高 ≠ 在安装。

**处置：manifest 没了只能重装。** 让用户在 Steam 里对目标应用**卸载 → 安装**，
或走「属性 → 已安装文件 → 移动安装文件夹」捡到另一个库。
实测一次成功修复：用户把 WE 移到 `D:\SteamLibrary` 后，Steam 重写了
`appmanifest_431960.acf`（StateFlags=4）并装出完整 1.4 G，
**连 `config.json` 一起带过去了（用户配置没丢）**，WE 随即正常运行。

★ **老库里会留一个没有 manifest 的残壳**（实测只剩 `bin/`、`plugins/`、
`wallpaper64.exe`，共 7.1 M）。Steam 不再认它，要手动删——
**但删之前必须让用户点头**：实测这次 `rm -rf` 被用户直接拦下。
被拦下就**停在原地，把路径原样交给他自己决定，绝不换写法重试**。
（这也说明"诊断→报告→让他点关键动作"比"直接代删"更顺。）

### ★ 别习惯性甩锅杀毒——先证明它真在跑

"文件被删"这个症状很容易直接归因杀毒，实测**这台机器上根本不是**：
只有 Windows Defender **注册**着，但它的服务是 **Stopped**，也没有 360/火绒/管家。
先跑这两条再下结论，别让用户白折腾白名单：

```bash
powershell -NoProfile -Command "Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct | Select displayName,productState | Format-Table -AutoSize"
powershell -NoProfile -Command "Get-Service WinDefend,SecurityHealthService | Select Name,Status | Format-Table -AutoSize"
```

（注册在安全中心 ≠ 实时防护在跑；`WinDefend  Stopped` 就是没在跑。）



症状：应用 UI 起不来（主进程半死不活）、Steam 下载页一直转、库里看不到进度、
磁盘却一直在掉。典型是创意工坊内容太多 + 目标库盘满。

### 诊断三步
1. **暂存 vs 已安装 条目数对比**（一眼看出卡在暂存）
   ```bash
   W="/c/Program Files (x86)/Steam/steamapps/workshop"
   ls "$W/downloads/<appid>" | wc -l; du -sh "$W/downloads/<appid>"
   ls "$W/content/<appid>"   | wc -l; du -sh "$W/content/<appid>"
   ```
   实测：downloads **163 个 / 19 G**，content 只有 **2 个 / 117 M**
   → Steam 卡在「下载→暂存→停下」循环。**根因几乎总是目标库盘满**
   （暂存要解包，写不进去就永远停在这一步）。
2. **Steam 下载日志** `Steam/logs/content_log.txt` 尾部。卡死特征：
   `AppID <id> state changed : Fully Installed,Update Queued,` +
   `scheduler finished : staying in schedule (result Suspended, state 0xc)` 反复刷。
3. **订阅总数**：`steamapps/workshop/appworkshop_<appid>.acf`
   ★ **别数区块里的行**——`WorkshopItemDetails` 里有嵌套键，行数会翻十倍
   （实测数出 1481，真实 165）。可靠算法：`str.count('"manifest"')`
   （每个订阅项一条 manifest）或正则逐行匹配 `^\t\t"\d+"`。
   同文件 `SizeOnDisk` 只反映**已安装**部分（实测 122 MB），别当总量。
   一把出全部数字 → `scripts/steam-workshop-audit.py <appid>`

### 处理顺序（别反过来）
1. **先暂停该 appid 的下载**（Steam 底部下载页 → 暂停；或结束 `steam.exe`，
   重开 Steam 会自动续）—— 不暂停就边删边下，永远清不干净。
2. **把应用移到空间大的库**：库 → 右键应用 → 属性 → 已安装文件 → 移动安装文件夹。
   ★ **创意工坊内容跟着 app 所在的那个库走** —— 移完后续下载落到新库，不再吃 C 盘。
   app 本体很便宜（WE 826 MB，一分钟）。
3. **清暂存**：`rm -rf "<旧库>/steamapps/workshop/downloads/<appid>"`。
   已下完的 `content/` 不受影响，下载中的 Steam 会重排到新库。
4. **砍订阅**：在应用自己的 UI 里是**网格浏览 + 右键取消订阅**，比 Steam
   列表页面逐个点快得多 → 先把应用修好能启动，再来砍。
   ★ **别抢先代删暂存**：实测用户自己砍完订阅（165 → 0）后，**Steam 自己**把
   `workshop/downloads/<appid>` 清到 **0**、`content/<appid>` 一并清空，并删掉了
   `appworkshop_<appid>.acf`（订阅列表文件随之消失）—— C 盘从 1.1 G 直接回到 **21 G**，
   **全程没人手动删过任何东西**。
   所以正确顺序是：**让他先砍 → 回来量一遍**（`du -sh` 那两个目录 + `ls appworkshop_<appid>.acf`
   + `df -h /c`）→ 只有确实没清干净，才在他点头后手动删第 3 步那个目录。
   ★ 这条和第 3 步是**互补**关系：第 3 步是「他还没砍订阅」时的主动清理，
   这里是「他已经在砍了」时的**先验证再动手**——别把用户已经在做、Steam 会自动收尾的活
   当成自己的活去干（本会话差点就代删了一个正要自己消失的目录）。

### 容量账（动手前必须算给用户看）
视频壁纸单张 100~200 MB，静态图几 MB。**实测 165 个订阅 ≈ 19 G**。
这台机器 D 盘常态只剩 24 G → 全下完只剩 ~5 G，会把同盘的其它项目
（WSL 发行版、DST、npm 依赖）一起挤爆。**先摆「条目数 × 平均大小 = 总占用」
对「目标盘余量」，再让用户决定砍到几张。** 实用区间：8 G 内存的笔记本留 10~20 张。

## 坑
- 磁盘满时日志文案极误导：`fs::copy error The operation completed successfully`（系统错误码 0 的文本）——先查 df，别信日志判断。
- 单文件大（CEF libcef.dll 50MB+）且 C 盘只剩几十 MB 时，拷贝会中途 "No space left on device"，表现为部分文件 OK 部分缺失——按缺清单分批补或先清盘。
- C 盘常年满的根治：Steam 库内右键应用 → 管理 → 移动安装文件夹 → 搬到有空间的库（库间移动不占用 C 下载缓存）；distribution/ 这类安装源删掉可回血数百 MB。
- 杀毒白名单要含整个 steamapps 或具体 app 目录，只加 exe 没用（dll 同样被删）。

## 环境备注（2026-09）
- 用户 Steam 双库：WE 等部分应用在 C:\Program Files (x86)\Steam（C 盘 121G 常年接近满），DST/主游戏在 D:\SteamLibrary（D 有空间）。
- C 库大户：StarSavior 18G、Wallpaper Engine ~900M、Molili ~900M。
- ★ **C 库真正的黑洞是创意工坊暂存**：`steamapps/workshop/downloads/431960`
  实测涨到 **19 G**（165 个订阅的暂存），一晚把 C 盘从 16 G 空闲吃到 1.2 G。
  C 盘告急时**先查这里**，比查游戏本体有用得多。

## 支持文件
- `scripts/steam-workshop-audit.py` — 只读体检：各库暂存/已装条目数与大小、
  订阅总数、盘余量、暂存大头清理候选。用法 `python scripts/steam-workshop-audit.py 431960`
- `scripts/steam-repair-watch.sh` — 无人值守修复监视：轮询等 app 关键文件补齐 →
  用 `steam://rungameid/<appid>` 拉起 → 30 s 后报进程/`content_log` 尾部。
  用法 `bash scripts/steam-repair-watch.sh [appid] [app目录] [日志目录]`，
  后台跑（`background=true, notify_on_complete=true`），日志默认 `~/steam-repair-watch.log`
