# Phantom Breaker: Battle Grounds (老版 2015) 键位笔记

Steam appid 249070。安装: `D:\SteamLibrary\steamapps\common\Phantom Breaker Battle Grounds`
结构: `bin/`(pbbg_win32.exe + keyboard.ini + steam_api.dll) + `data/`(数字ID无扩展名资源, 非标准图片格式, 扫描文件头无PNG/JPG等——挖不动，别浪费时间)。
老版无游戏内完整改键，必须编辑 `bin\keyboard.ini`。改完直接进游戏生效，不用重启Steam。

## keyboard.ini 格式
- 14 行，每行一个十进制 Windows 虚拟键码 + `\r\n`，文件末尾无尾随空行（2026-08 实测 56 字节，无 BOM）。
- 写回必须保持 CRLF、行数不变；备份 `cp keyboard.ini keyboard.ini.bak`。

## 默认键位表（完整 14 行，位置映射）
| 行 | 默认键 | VK码 | 功能 |
|----|--------|------|------|
| 1  | W | 87 | 上 |
| 2  | S | 83 | 下 |
| 3  | A | 65 | 左 |
| 4  | D | 68 | 右 |
| 5  | G | 71 | 弱攻 |
| 6  | H | 72 | 中攻 |
| 7  | J | 74 | 强攻 |
| 8  | B | 66 | SP攻击 |
| 9  | Y | 89 | 换线 Line Movement（实测确认，见下） |
| 10 | U | 85 | 远程(Outrange) |
| 11 | T | 84 | 换道(Phantom Break) |
| 12 | I | 73 | Overdrive |
| 13 | 1 | 49 | 暂停（主键盘顶排 Q 正上方，不是小键盘） |
| 14 | 2 | 50 | 确认/返回 |

第13/14行是游戏默认菜单键，疑似硬编码，**保持不动**——改了容易卡确认框。

## 行序语义实测记录（2026-08-15 会话，写入 JKL+UIO 布局后用户进游戏测试）
- 已写入布局: `87,83,65,68, 74,75,76,85, 73,79,84,89, 49,50` = W A S D / J K L U / I O T Y / 1 2；备份在 `bin/keyboard.ini.bak`
- 用户按 I（改后布局中 I 在第9行）→ **换线（换街道/前后线）**。=> 改后第9行 = Line Movement 换线，由此推断默认第9行(Y)也是换线位
- 改后第10/11/12行(O/T/Y)语义**未确认**（依赖默认键位表推断）
- 注意: 帮助页"按钮列表显示顺序"(Move/Weak/Medium/Strong/Overdrive/Outrange/Line/Pause) ≠ ini 行序，别拿帮助页顺序推断行号；二手/AI 转述的行序表不可信，以 exe 内置帮助文本或用户实测为准

## 从exe帮助文本确认的机制（UTF-16LE字符串提取，见 scripts/extract_utf16_strings.py）
- **救人**: 合作模式站在昏迷队友旁连续按任意攻击键即可救活（Reviving: "Continuously press an attack button while standing near a player's unconscious character"）
- **起身**: 倒地时连按任意键快速起身；起身时按←可向后退着起身
- **Line Movement 换线** = BTN_LB 单独键（"Move to the opposite line"）
- **Outrange Attack 远程** = BTN_RB 单独键 或 M+H（中攻+强攻）
- **Overdrive 强化** = L+M（弱攻+中攻同按），组合键非单独键；激活后对手减速、我方连攻
- **Phantom Break 超必杀** = 200%爆气槽，角色最强攻击（"Uses 200% of the Burst Gauge"），无单独键说明
- **EX Attack** = H+SP，100%爆气槽
- 按键宏: BTN_L=弱 BTN_M=中 BTN_H=强 BTN_SP=SP BTN_LB=换线 BTN_RB=远程 BTN_ST=Start BTN_SEL=Select；KEY_L/R/U/D=左/右/上/下
- 其他机制：Counterbalance（两人同时冲刺/对拼触发）、Guard Break（持续防御崩防，崩防期无防御）、Slip Shift（对手攻击命中前瞬间按→空掉攻击，仅地面）、Reflection（命中前瞬间按 SP 弹反）、Dash（方向键连按两下）

## 推荐布局（已写入，2026-08，备份 keyboard.ini.bak）
JKL 三连攻（街霸式指法）+ UIO 技能列（SP/超必杀/远程，在攻击键正上方一排，手腕不横移）+ Y Overdrive + T 换道，左手 WASD+T，右手 JKL+UIO+Y。原 B(SP) 位左手要绕过 WASD 够不着。菜单键 1/2 保持默认。若后续实测发现行10-12语义不符，微调对应行号即可（每行换键码值）。

## 版本区别
- 老版 (2015)：本机安装的就是这个，无游戏内改键，只能改 bin\keyboard.ini
- Ultimate (2025 UE5 重制)：游戏内 Options → Controls，UI 反人类——**按 T 键切换选项卡**才能看到 Keyboard 页（社区反馈，未实测）；手柄在 Controller 页

## 网络取证经验（本会话）
- Steam 指南/商店页 HTML 可抓（Steamcommunity_302 本地劫持），但指南正文 JS 渲染，curl 拿不到
- `ISteamRemoteStorage/GetPublishedFileDetails` POST API 可用但指南多为模板帖，无键位价值
- 优先走 exe 本地字符串，不要浪费时间爬社区
