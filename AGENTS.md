# AGENTS.md — DST 角色 mod 项目总纲

> 这份文件是给**任何 AI 工具**看的（通义千问 / Qwen Code CLI、通义灵码、Codex、Claude Code、Cursor、Hermes）。
> 接手本项目前先读这份，再读根目录 `musha-current-state.md`（项目现状）。
> 本文件是**手写**的规矩，别让工具自动改写；自动同步的部分在 `context/`。

---

## 0. 项目一句话

**Don't Starve Together（饥荒联机版）的角色 mod**，仓库 `musha-remastered-edition`（Gitee，零 Ciel / ZeroCiel），
在 Steam 创意工坊发布。当前版本 **0.7.13（半版本 —— UI / 动画 / 美术尚未完成，所以只发半版本）**。

在做的东西：职业 + 技能树系统、邮包/信箱、回城石、进阶祭坛、转职卷轴/技能书、角色美术重制（侧脸头 / UI 面板 / 图标贴图）。

---

## 1. 路径速查（都是 Windows 路径）

| 什么 | 路径 |
|---|---|
| mod 工作目录 | `D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha` |
| 原版脚本（可直接读的参考源码） | `...\Don't Starve Together\data\databundles\scripts\` |
| 原版动画包 | `...\data\anim\*.zip`（角色图 `wilson.zip` 等 / 时间轴 `player_*.zip`） |
| 美术工程（Spriter/scml） | `mods\musha\exported\<工程名>\` |
| **编译产物（游戏真正读的）** | `mods\musha\anim\*.zip` |
| 美术/解码小工具 | `mods\musha\exported\_tools\`（纯标准库 Python） |
| 官方 Mod Tools | `D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools\mod_tools\`（`scml.exe` / `autocompiler.exe` / `png.exe`；**是 common 下的兄弟目录，不在 DST 目录内**） |
| 项目现状（最重要的一份） | `mods\musha\musha-current-state.md` |
| 设计文档 | `mods\musha\musha-*.md`（技能树UI-spec / 信箱邮包设计 / 职业估期与排期 / backlog …） |
| 发布配置 | `mods\musha\dstpub.json`、`modinfo.lua` |

---

## 2. 铁律（违反 = 返工，别自作主张）

**美术 / 动画**
1. **scml 里只有「画布大小」和「中心点(pivot)」是能改的。** 在模板/时间线里挪 object 的 x/y **没有意义**（动画是固定好的）；加新符号不会显示，还会白占 z_index；图层顺序只有少量情况有效、且不确定。
2. **美术未定稿不许打包进 `anim/`。**
3. **角色模型固定用「原版皮」，不要用 v2 皮。** v2 那套（头部/脸/导航按钮）是隐藏草稿，**不许打包进 `anim/`、不许推进 `images/`、不许作为皮肤交付**；主模型文档下所有 agent 一律不要再打包 v2 进 musha 的皮。
4. **所有世界物件美术（道具/建筑/手上贴图）必须是 DST 暗黑调**：不透明像素 **平均亮度 ≈128**、**亮度<60 的近黑占比 ≈28%**、**饱和 ≈28**。
5. **例外**：UI 面板底图要「阳光的、星星光亮的」风格，**不许压暗**；便签底图 `musha_note_bg.png` 是原名风格，**不许动**。
6. **改图集/贴图前先 `cp` 备份**成 `_bak_<名>_<日期>`；**改完 `exported/<工程>/` 必须同步 `exported/musha/`**（否则 autocompiler 一启动就把 `anim/` 打回旧包）。
7. 编译 scml 用 `scml.exe`，**它只吃 Windows 路径**（git-bash 里要 `cygpath -w`）。
8. 别为了"调位置"去拆图层或加符号；调位置只能改**画布 + 中心点**。

**代码**
9. **改任何 Lua 后必须重启游戏**（退到桌面重开），不是"重进世界"。
10. 原版组件/机制优先，特效尽量本地做；世界物件美术必须暗黑调（见 4）。
11. 实体级 `inst:OnSave(inst, data)` 必须**往 `data` 写字段**（返回值被当 GUID 列表）；组件级 `OnSave` **返回表**才是对的 —— 两者相反。
12. 容器 widget 只支持**一个** `buttoninfo`，且必须写在 `params.<name>.widget.buttoninfo`。

**流程 / 协作**
13. **删除类命令（`rm` 等）先问**；破坏性/批处理操作先问。
14. 报价型交付：订单外的增强做成**可切换开关**，默认贴订单字面；范围/返修/验收先钉死（V5.1 文档为验收基准）。
15. 交付说明用**中文**，放单独文件夹。
16. 美术改动的交付格式：**`file:line` + 旧值/新值**（不要只给图）。

---

## 3. 常用命令

```bash
DST="D:/SteamLibrary/steamapps/common/Don't Starve Together"

# 编译 scml（实测通过：进工程目录跑、参数用相对路径；scml.exe 在 common 下兄弟目录，绝对路径参数须 cygpath -w）
cd "$DST/mods/musha/exported/crescent_moon"
"/d/SteamLibrary/steamapps/common/Don't Starve Mod Tools/mod_tools/scml.exe" crescent_cyan8.scml .

# Lua 语法预检（WSL + 真 luac5.1；默认查 modmain + scripts/，期望 74 全过；可加参数指定文件/目录）
wsl -d Ubuntu2204 -e bash -lc 'bash /mnt/d/wsl-dl/lua-syntax-check.sh'

# 解原版动画成逐帧 PNG（看图/抄姿势）
python "$DST/mods/musha/exported/_tools/dump_anim_frames.py" list   <anim.zip>
python "$DST/mods/musha/exported/_tools/dump_anim_frames.py" render <build.zip> <anim.zip> <动画名> <出参目录>
# ⚠️ 别整套全渲（几十 MB）；先 list 定到具体几帧

# 刷图集 tex → png（纯标准库，技能库自带；不在 _tools 里）
python "D:/AI-Workspace/skills/dst-art-pipeline/scripts/tex2png.py" ...
```

---

## 4. 当前进度

**先读 `musha-current-state.md`**（项目现状，本目录根下，多轮追加，最权威）。
本文件只放**长期不变的规矩**，不放进度 —— 进度会变，规矩不会。

---

## 5. 沟通与协作偏好（重要）

- **中文**，结论先行，**按编号分条列改动**（用户会用编号回指，比如回"2 错了"= 第 2 条整条判错，要撤回重做）。
- **一次只改被点名的那个元素**，别顺手多改。
- 用户说"**我来试试**" = **全部停止**，别继续动。
- 用户说"**不用编译这么多 / 快没流量了**" = 立刻停手；**联网、下载、大批量渲染前先问**。
- 不确定就问，别绕圈子；直接给结论比兜圈子好（附上原因）。
- 美术：用户审美偏「孩童风 / 书页感」；用比喻形容颜色时**只是在说颜色** —— 别加纹理、别加新元素。

---

## 6. 环境

- Windows（i5-6300HQ / 8G / GTX950M + HD530，C/D 盘常年紧张）；终端是 **git-bash**，不是 PowerShell。
- Python 3.11；Node v24 + npm（`node -v` 可用）。
- 游戏进程 `dontstarve_steam_x64.exe`。
- **网络：出口是手机热点，流量紧张 —— 任何联网动作先问。**
- 本机 AI 侧：Hermes（主模型 DeepSeek，fallback 智谱 GLM）。**API key 一律放 `~/AppData/Local/hermes/.env`，永远不要写进本文件或任何会提交进 git 的文件。**
