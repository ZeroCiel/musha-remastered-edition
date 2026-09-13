---
name: game-local-config-editing
description: 本地游戏配置与键位文件编辑。定位Steam安装目录、区分老版/重制版、修改keyboard.ini等数字键码配置文件、从exe提取UTF-16LE内置帮助文本验证键位语义。触发：改某游戏本地键位、keyboard.ini、键码配置、从游戏exe读内置手册（如"救人按哪个键"）。详情见 references/pbbg-keyboard.md。
---

# 本地游戏配置/键位编辑

## 何时用
- 用户要求修改某款本地游戏的键位或配置文件（尤其老版Steam游戏无游戏内改键的）
- 遇到 keybind.ini / keyboard.ini 等纯数字键码配置
- 需要从游戏exe里读内置帮助/手册文本来验证游戏机制（如"救人按哪个键"、"超必杀怎么触发"）

## 流程
1. **定位安装目录**: 常见 Steam 库 `C:\Program Files (x86)\Steam\steamapps\common`、`D:\SteamLibrary\steamapps\common`; 也可 `reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v InstallPath`。先列目录找游戏文件夹。
2. **识别版本**: 老版(2015及以前)通常是 `bin/` + 数字键码 ini + 无扩展名资源目录; 重制版(UE5等)一般游戏内 Options→Controls 可改键。老版才需要改文件。
3. **先读原始字节再写**: `python -c "print(repr(open(f,'rb').read()))"` 确认行尾(CRLF/LF)、有无尾随空行、行数。写回必须保持同格式，否则游戏可能读不出。
4. **先备份**: `cp xxx.ini xxx.ini.bak`。
5. **验证键位行语义（本技能最关键的教训）**: 数字键码 ini 的"第N行=哪个动作"**不能信二手/AI转述的行序表**——本会话就因轻信旧文本把一行标成超必杀，实际用户实测是换线。验证手段：
   - 从exe提取内置帮助文本（UTF-16LE字符串，见 scripts/extract_utf16_strings.py），看动作的按键宏定义（如 BTN_L=弱攻 BTN_LB=换线）
   - 或让用户进游戏实测每个键再确认
6. **改动范围最小化**: 菜单键(确认/返回/暂停)可能被菜单界面硬编码，默认值不要动。
7. **注意组合键动作**: 有些动作是组合键（如 Overdrive=弱攻+中攻同按），不是每个动作都有独立行；先在帮助文本里确认哪些是单独键。
8. **写回后验证**: 用 python 二进制精确写回（`.encode()` 拼好 `\r\n`，不要用文本编辑器改写），读回字节确认与备份差异只在你改的行。改完直接进游戏生效，通常不用重启 Steam。

## Windows 虚拟键码速查 (VK，不是 scan code)
W=87 S=83 A=65 D=68 | J=74 K=75 L=76 U=85 I=73 O=79 | Y=89 T=84 B=66 G=71 H=72 | 方向键 ↑38 ↓40 ←37 →39 | 数字键1=49 2=50 | Enter=13 空格=32

## 用户沟通偏好（本类任务实测）
- 直接改好 + 给键位表 + 参考建议（为什么这么排），**不要先问一堆问题**
- 改写前后输出一份 `行号|键码|键名` 对照表给用户确认，别只说"改好了"
- 回答"确定是哪个键"时必须给确定答案 + **物理位置**（如"主键盘顶排数字键 1/2，Q 正上方，不是小键盘"），不要用"暂停/确认 1/2"这种含糊写法，用户会追问
- 改完告知还原方法（把备份文件拷回即可）

## 陷阱
- `strings`(ASCII) 在部分游戏exe里什么都找不到，必须用 UTF-16LE 正则提取（日式引擎/老游戏常见，文本以 `char\0` 形式存放）
- Steam 指南页面内容 JS 渲染，curl 抓 HTML 拿不到标题/正文；`ISteamRemoteStorage/GetPublishedFileDetails` POST API 可通但结果多为模板帖，别指望拿到键位表
- store.steampowered.com / steamcommunity.com 经 Steamcommunity_302 本地劫持(127.0.0.1:80/443)可达，但内容完整性受JS渲染限制
- 游戏内帮助文本的"按钮列表显示顺序" ≠ ini 行序，别拿帮助页顺序推断行号
- 改完告诉用户无需重启Steam，直接进游戏生效

## 支持文件
- `references/pbbg-keyboard.md` — Phantom Breaker: Battle Grounds (老版2015) 完整笔记：默认键位表、行序实测记录（含换线教训）、exe确认的机制、推荐布局、版本区别
- `scripts/extract_utf16_strings.py` — 从exe提取UTF-16LE字符串并按正则过滤（用法见文件头）
