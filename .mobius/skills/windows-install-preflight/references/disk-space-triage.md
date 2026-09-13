# Windows 磁盘空间诊断与清理（实测）

场景：要装大件（Docker / 大项目依赖）而盘快满了，需要找出"能删什么"给用户拍板。
实测机器：Win11 专业版 22631，C: 121 G、D: 119 G。

## 命令集

```bash
# ① 当前空间（会滞后，关键决策前再测一次）
df -h /c /d

# ② 系统级大文件（一眼看出的最大单点）
ls -lh /c/pagefile.sys /c/hiberfil.sys /c/swapfile.sys 2>/dev/null

# ③ 常见"垃圾惯犯"（快，可直接前台）
du -sh /c/Users/<user>/AppData/Local/Temp
du -sh /c/Windows/SoftwareDistribution       # Windows 更新缓存
du -sh '/c/$Recycle.Bin' '/d/$Recycle.Bin'

# ④ 顶层大户（慢 → 后台跑 + notify_on_complete）
{ echo "=== C 盘顶层 ==="; du -sh /c/* 2>/dev/null | sort -rh | head -25;
  echo; echo "=== D 盘顶层 ==="; du -sh /d/* 2>/dev/null | sort -rh | head -25; } \
  > ~/disk_scan.txt 2>&1

# ⑤ 清回收站（两个盘一起）
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
```

★ `du -sh /c/*` 要遍历几十万文件，实测 2 分钟以上。
前台 `process wait` 会被钳到 60 s——要么后台 + notify，要么连着 wait 两次。

★ 路径含 `$` 的必须单引号：`'/d/$Recycle.Bin'`、`'/d/$$JZXiaoBaiReNew$$'`。
git-bash 里 `$$` 是当前 PID，不引号会被展开成数字，du 报"文件不存在"。

## 实测大户清单（用于建立直觉）

C 盘顶层：
| 大小 | 路径 | 判据 |
|---|---|---|
| 29 G | `/c/Program Files` | 已装软件，不动 |
| 21 G | `/c/Windows` | 系统，不动 |
| 19 G | `/c/Users` | 用户的 AppData 等，里面捞 |
| 16 G | `/c/Program Files (x86)` | 已装软件，不动 |
| **14 G** | `/c/pagefile.sys` | **虚拟内存文件，可挪到 D 盘或调小** |
| 7.4 G | `/c/ProgramData` | 看具体子目录 |
| 1.7 G | `/c/JSQL2008` | SQL Server 2008，不用可删 |
| **3.3 G** | `AppData/Local/Temp` | **纯垃圾，直接清** |
| 422 M | `/c/lataledb` | 用户的彩虹岛数据库，**不动** |

D 盘顶层：
| 大小 | 路径 | 判据 |
|---|---|---|
| 71 G | `/d/SteamLibrary` | 游戏，用户自己的项目区，不动 |
| **7.7 G** | `/d/$$JZXiaoBaiReNew$$` | **一键重装系统的 PE 包**（内含 `image/ pe/ driver/ main/ wifi_backup/`），垃圾，实测已删 |
| 7.6 G | `/d/models` | AI 模型文件（ComfyUI 在用），**先问** |
| 6.9 G + 5.5 G | `/d/LaTale`、`/d/LaTale332 S3最终版` | 用户的彩虹岛私服项目，**绝对不动** |
| 5.5 G | `/d/Backup` | 用户备份（DST 明生文档等），**不动** |
| 4.2 G | `/d/Photoshop` | 已装软件 |
| 2.0 G | `/d/pagefile.sys` | 系统文件 |
| 2.0 G | `/d/MyDrivers` | 驱动包（`backup/ hotfix/ software/ update/`），装完就没用，实测已删 |
| 102 M | `Windows Driver Kit (WDK) 8.1 Samples.zip` | 老开发包，可删 |

**判据速记**：
- 目录名里带 `image/pe/driver/main` 的一键重装残留、`MyDrivers` 这类纯安装包 → 可删
- 用户的游戏库 / 项目目录 / `Backup` → **一律不动，只在清单里标"不动"**
- 拿不准的（`models` 这种可能是创作工具在用的）→ **列出来让用户拍板，别自作主张**

## ★ 隐形吃货：藏在已装软件目录里的（顶层 du 看不出来）

顶层 `du` 只看得到 `/c/Program Files (x86)` 这种 16 G 的壳，**真正的暴涨在下面两层**。
实测一晚上 C 盘从 16 G 可用掉到 **1.2 G（100%）**，两处元凶：

| 大小 | 路径 | 说明 |
|---|---|---|
| **19 G** | `C:\Program Files (x86)\Steam\steamapps\workshop\downloads\<appid>` | **创意工坊下载暂存区**。实测 Wallpaper Engine（appid 431960）在下一堆 mp4 壁纸，一晚上涨到 19 G。每个子目录一个 item id，配 `state_<a>_<b>_<id>.patch` 状态文件 |
| 728 M | `C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache` | Windows 更新 P2P 交付缓存 |

判据：`workshop/downloads/` 是**暂存区**，下完会被搬到 `workshop/content/`。
删 `downloads/<appid>` 不会删已装好的内容，没下完的下次会重下 → **可以清**，
但**先问用户**（他可能在故意下壁纸）。更稳的做法是让他在 Steam「下载」页暂停。

定位手法 —— **找"最近 N 分钟新出现的大文件"**（比 du 快，直接命中）：
```bash
powershell -NoProfile -Command "Get-ChildItem -Path C:\ -Recurse -Force -File -ErrorAction SilentlyContinue | Where-Object { \$_.LastWriteTime -gt (Get-Date).AddMinutes(-30) -and \$_.Length -gt 100MB } | Select-Object -ExpandProperty FullName" 2>&1 | tr -d '\r'
```
★ 别在同一个 `Select-Object` 里同时选 `FullName` 和算好的 MB 列 —— 表格宽度会把
MB 那列截掉，看不见数字。**要么只输出 FullName，要么 `ConvertTo-Csv`。**

顺带：`tasklist | grep -i steam` 既查"谁在写盘"，也是**下载抢带宽**的元凶
（实测同时下 Steam 时 WSL 镜像掉到 26 KB/s）。

## 典型战果（供估算）
清 `$$JZXiaoBaiReNew$$`(7.7 G) + `MyDrivers`(2.0 G) + C 盘 Temp(3.3 G → 226 M)
→ **C: 7.0 G → 10 G 可用；D: 15 G → 25 G 可用**（约腾出 13 G）。

## ★ 用户说「删了」的核验（实测踩坑）
用户回「1删了 5删了 C盘清理了」后，实测：
- `$$JZXiaoBaiReNew$$` **还在** 7.7 G
- `MyDrivers` **还在** 2.0 G
- C 盘 Temp **还是** 3.3 G
- D 盘只多了 2 G；两个回收站都小（D 153 M / C 533 K）→ **根本没删进去**

核验脚本：
```bash
for p in '/d/目标1' '/d/目标2'; do
  if [ -e "$p" ]; then printf "还在: %s  " "$p"; du -sh "$p" 2>/dev/null | cut -f1;
  else echo "已删除: $p"; fi
done
du -sh '/d/$Recycle.Bin' /c/'$Recycle.Bin'; df -h /c /d
```
原因通常是：删除被占用/权限挡了，或用户以为自己删了。
**核验 → 报告"还在原地 + 大小" → 问是否代删**，不要直接信。

代为删除：
```bash
rm -rf '/d/$$JZXiaoBaiReNew$$' '/d/MyDrivers'      # 单引号！
rm -rf /c/Users/<user>/AppData/Local/Temp/* 2>/dev/null   # 被占用的自动跳过
```
删完 `du -sh` 复查 + `df -h` 报新空间。
