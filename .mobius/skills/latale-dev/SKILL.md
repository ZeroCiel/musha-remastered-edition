---
name: latale-dev
description: 彩虹岛私服开发 — 目录结构、工具路径、服务端配置、LDT编辑和打包流程
category: gaming
---

# 彩虹岛私服开发

## 项目路径
- 单机端：D:\\LaTale\\S2\\（原 D:\\彩虹岛\\，2026-06-03 迁移，用他乡SPF+怀旧端Loading界面）
  - 关键LDT：D:\\LaTale\\S2\\resource\\ROWID\\DATA\\LDT\\
  - 旧路径仍可能有残留文件，迁移后所有新版操作走新路径
- S4端（他乡端主力）：D:\\\\LaTale\\\\S4\\\\
  - SKILL.xls：D:\\\\LaTale\\\\S4\\\\resource\\\\ROWID\\\\DATA\\\\XLS\\\\SKILL.xls
  - SKILL2.xls参考源：D:\\\\LaTale\\\\彩虹岛S2\\\\ROWID\\\\DATA\\\\XLS\\\\SKILL2.xls
  - 网关.exe启动后需手动补起LoginServer/LobbyServer（详见references/s4-server-process-structure.md）
- S4国服简体参考端：D:\\\\LaTale\\\\S4chd\\\\
  - 正确简体中文数据：D:\\\\LaTale\\\\S4chd\\\\resource\\\\ROWID\\\\DATA\\\\XLS\\\\SKILL s4.xls（3937个ID）
- S1对比端：D:\\\\LaTale\\\\彩虹岛S1\\\\
- 开发工具：D:\\LaTale\\
- 数据库：JSQL2008 (C:\\JSQL2008)

### S4端服务进程结构
详见 `references/s4-server-process-structure.md`。
S4端有独立的LoginServer和LobbyServer，但网关.exe不自动启动它们，需手动补起或创建.vmp副本。
- 数据库：JSQL2008 (C:\\JSQL2008)

### 路径迁移检查（复制端目录时必查）
当服务端目录迁移到新路径后，以下地方需要检查修正：
1. **configure_share.ini** — `resourceDir=` 行指向新路径（见下方详细排查步骤）
2. **彩虹岛编辑器导出脚本** — gen_fashion_export.py 等工具内硬编码的 LDT_DIR 路径
3. **ldt_writer.py** — 如果路径硬编码了旧目录
4. **数据库备份/恢复路径** — 如果有引用绝对路径

### 数据库恢复后 Bay/Room 崩溃修复

mdf 文件覆盖恢复后 Bay/Room 报 `m_GameDB.DriverConnect : [FAILED]` 时，是库处于 EMERGENCY 模式或孤立用户问题。修复步骤详见 `references/database-operations.md` 的数据库恢复章节。

### 可用的数据库恢复源

`C:\JSQL2008x\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\DATA\` 存放着同版本（SQL 2008 R2）的彩虹岛数据库 mdf/ldf 文件，可直接停服→覆盖→修复使用。版本不兼容（SQL 2014 的 782 版 vs 当前 663 版）时无法打开，需用同版本源。

## CASH_SHOP宠物分类体系（2026-06-04 完整确认）

宠物在商城中分为**三类**（从怀旧端CASH_SHOP.xls反向验证）：

| 分类 | 说明 | _CategoryIndex | _CategoryIndex2 | _CategoryIndex3 |
|------|------|---------------|----------------|----------------|
| 宠物领养券 | 限时/永久宠物券 | 2 | 7 | 0 |
| 宠物用品 | 拼图/重置/辅助剂 | 2 | 8 | 0 |
| 宠物本体 | 活体宠物（非券） | 7 | 23 | 0 |
| 宠物装备 | 宠物穿的帽子/衣服/鞋等 | 7 | 22 | 0 |
| 宠物其他 | 混合宠物相关 | 7 | 24 | 0 |

**判断宠物 vs 同名时装的法则**：
- **宠物本体**：名称就是动物名（"白虎""熊猫""企鹅"），无装备部位后缀
- **宠物装备**：名称以"帽子/衣服/靴子/手套"等结尾（Cat=7,22/24）
- **同名时装**：同一动物图案的时装（如"白虎花纹野性衬衫""白虎花纹运动鞋""钮扣兔上衣"），Cat=1,1,x（普通时装）
- 容易混淆的案例：企鹅帽子（Cat=7,24宠物装备）vs 白虎帽子（Cat=7,22宠物装备）vs 钮扣兔帽子（Cat=1,2,5时装）
- **严格按类型判断**：宠物装备在ITEM_2中_Type=5或_Pet_ClassID>0；同名时装_Type=1,_SubType=2

**修改CASH_SHOP.xls时注意**：批量改分类时，一定要**排除同名时装**。用关键词匹配PET_NAMES时，时装类名称通常带"花纹""野性""迷你裙"等服装部位关键词，不要简单用动物名匹配。

## GS crash from CashCheck 0→1（上架引发的连带事故）

当把ITEM_2中道具的CashCheck从0改为1后，**GS启动时会完整加载该道具的全部数据列**，可能暴露之前被隐藏的坏数据。

### 典型报错
```
Item Info Loading.........DATA/LDT/ITEM_2.LDT : FAILED !    iItemID = 30371402, EffectID = 16777216
Item Info Loading.........SetID does not exist in SETITEM_B     iSetID(65536)
```

### 根因
ITEM_2.LDT中该道具的EffectID/SetID等int字段被填入了**无效大数值**（65536=0x10000, 16777216=0x1000000），这些是编辑器/打包工具在保存时产生的位标记污染。CashCheck=0时GS跳过该道具，不触发校验；CashCheck=1后GS完整加载，触发崩溃。

### 排查流程
1. 从报错中提取 iItemID 值
2. 在 ITEM_2.xls 中定位该行
3. 搜索该行中所有值为 65536 或 16777216 的列 → 改为0
4. 同步改 ITEM_2.LDT 的对应二进制列
5. SETITEM_B.LDT可能不存在于这个端（只有SETITEM.LDT），SetID=65536本身就是无效值，直接改0

### 预防
批量改CashCheck 0→1前，先搜索LDT中所有值为65536/16777216的int列并清0，再改CashCheck。或者在彩虹岛编辑器中全表搜索替换这些无效值。

## 彩虹岛编辑器XLS文件格式

彩虹岛编辑器导出的`.xls`文件实际上是**TAB分隔的文本文件**（魔数 `Type\t3\t3`），GBK编码。

### 结构
- 第1行: 字段类型号（如 `3 3 3 1 1...`）
- 第2行: 字段名（如 `_Name _Description _Icon...`）
- 第3行起: 数据行

### 安全批量修改方法（二进制级）

**改名（等长或更短）**:
```python
data = bytearray(open('ITEM_2.xls', 'rb').read())
data.replace('耶比'.encode('gbk'), '龙猫'.encode('gbk'))
open('ITEM_2.xls', 'wb').write(data)
```

**改数值列**:
```python
lines = data.split(b'\n')
for i in range(2, len(lines)):
    parts = lines[i].split(b'\t')
    if len(parts) > col_idx and parts[col_idx].strip() == b'0':
        parts[col_idx] = b'1'
        lines[i] = b'\t'.join(parts)
```

**注意**：GS可能正占用XLS文件，改之前需关闭彩虹岛编辑器。直接用二进制替换字符串（如耶比→龙猫）安全，但涉及数值列时必须确认行列对应正确。

繁转简本地化记录见 `references/2026-06-04-localization-session.md`。

### XLS文本中的转义换行符坑
编辑器导出的 XLS 中，多行文本的换行存储为字面 `\\\\n`（两个字节 0x5C 0x6E），**不是**实际的换行符。所以在 Python 匹配时要搜 `b"\\\\n"`（原始字节 0x5C 0x6E）而不是 `b"\\n"`（换行符）。
通过 bytes.replace 做繁转简时，如果目标文本包含 `\\n`，必须用原始字节匹配。

### SAVEPOINT.LDT 列表处理（需编辑器导出）
SAVEPOINT.LDT 是 LDT 二进制格式，不能直接在二进制上做文本替换。必须：
1. 用彩虹岛编辑器打开 SAVEPOINT.LDT → 导出为 XLS（TAB分隔文本）
2. 在 XLS 上做繁转简（等长替换，GBK字节数不变）
3. 用编辑器写回 LDT
该表包含爱丽丝全部石塔储存点对话（123行，44列），全繁体。

**SAVEPOINT.xls 繁转简实测**（2026-06-06）：
- XLS格式：行0=Type, 行1=列名(44列), 行2起数据
- _ID(0), _NpcName(1/7/13/19), _Message(2/8/14/20), _Story(42) 为主要文本列
- bytearray.replace覆盖全表：共约1166处替换
- **完整繁转简映射表**见 `references/t2s-complete-mapping.md`
- 繁简相同的字（回/助/存/什/迎/本/告/步/域/冒）无需映射
- 验证方法：搜残留繁体字集合 `set('戰鬥劍遊龍驗訊隊體後裡嗎寶貓點擊練穫確認說請問遠魚鳥時間儲連線裝備覆亞東麵條敵殺聲響發現幫總風雲萬歲樂從擁關開於與並個將卻為還夠麼這幹兒牠們來帶爾聽盡頭邊變處對産業務報筆關係進僅限歡迎謝稱礦經歷冒險領域')`\n- 备份文件：SAVEPOINT.xls.bak\n- **常见遗漏繁体补充**：稱→称、礦→矿、經→经、歷→历、險→险、領→领、蕭→萧、蹤→踪。这些字在基础映射中可能被遗漏，需额外添加。

### 客户端连接远程 GS 配置（跨网络网关/虚拟组网）

远程彩虹岛 GS 通常部署在云电脑/服务器商处，本地客户端需要通过 VPN 或虚拟组网连接。详细的连接方式、配置文件、网络方案对比和掉线诊断见 `latale-server` skill 的远程连接章节。

**服务端 PublicIP 必须改成客户端能连的地址！**
- `configure.ini` 和 `configure_share.ini` 里所有 `PublicIP = 127.0.0.1` 都要改成远程机在虚拟组网中的 IP
- 否则客户端登录后拿到的 Lobby/GameServer 地址是 127.0.0.1，连不上

**MS 端口引用别忘了同步改**
- 如果改了 MS 端口（10001→41471），两个配置文件的 `[MS] Port = 10001` 也必须改成新端口
- 不然后果：GS 注册不到 MS → 频道列表为空

**快速指引**：
1. 装 Radmin VPN（英文原版免费，比 EasyN2N 稳定）或 EasyN2N，和远程机加入同一网络
2. 远程机上确认 LoginServer 已监听 19999 端口：`netstat -ano | findstr 19999`
3. 改本地客户端 `IP.ini` 和 `登陆.bat` 中的 IP 为远程机虚拟局域网 IP
4. 双击登陆.bat 测试
5. 如果连上5秒掉线且不重启客户端不能重连 → 在远程机本地启动客户端测试排除网络问题

### 坑
- EasyN2N 免费 SuperNode 不稳定，UDP 打洞成功率低
- Radmin VPN 比 N2N 更稳定，首选
- 云电脑通常只开 RDP 端口，22/19999 等端口需额外映射
- 如果远程机本地跑客户端不掉线，100% 是网络隧道问题，不是服务端配置问题

## 远程 GS 服务器管理（2026-06-04 配置）
远程彩虹岛GS服务器（Win10，2G内存，跑GS后资源吃紧）推荐用 OpenSSH Server 替代远程桌面：

**安装 OpenSSH：**
- `Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0`（4个波浪线！）
- 如果失败（0x800f0950系统精简版），手动下载 MSI：https://github.com/PowerShell/Win32-OpenSSH/releases
- 通过 RDP 驱动器重定向传安装包到远程服务器

**启动与配置：**
```powershell
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
netsh advfirewall firewall add rule name="OpenSSH Server" dir=in action=allow protocol=TCP localport=22
```
注意：PowerShell 的 `New-NetFirewallRule` 需要 `-Action Allow` 在同一行内，容易报错；推荐用 `netsh` 替代。

**常用命令：**
- 查内网IP：`ipconfig | findstr IPv4`
- 查公网IP：`(Invoke-WebRequest -Uri http://ip.sb -UseBasicParsing).Content`
- 停止/启动 sshd：`Stop-Service sshd` / `Start-Service sshd`

**云电脑/服务器商场景**（如 20252025.top 类服务）：
- 远程桌面用 `域名:端口` 连接，用户名 PC
- 内网IP通常是 172.x.x.x 段，公网IP是运营商NAT共享IP
- SSH 直连公网IP会超时（只转发了RDP端口）
- 需要服务商管理面板加端口映射，或用 frp/ngrok 隧道穿透
- 本地可能连不上 GitHub（网络受限），需要用户自己在远程服务器浏览器下载

**本地 Hermes gateway 替代方案：**
如果 SSH 配不通，可在远程服务器直接装 Hermes，起 gateway 监听某个端口，本地通过 gateway 远程控制。

## ITEM_1.xls 装备限制解析（2026-06-04 确认）

ITEM_1.xls 是武器/装备表，109列，第2行是字段名，第3行起数据。

### 装备限制列（0-based）

| 列索引 | 字段名 | 说明 |
|-------|--------|------|
| 14 | `_Type` | 物品大类（1=武器/装备） |
| 15 | `_SubType` | 子类 |
| 16 | `_PosID1` | 部位ID（13=弓类） |
| 39 | `_Require1_Type` | 限制类型1（0=无限制, 1=职业限制） |
| 40 | `_Require1_ID` | 限制ID1（类型=1时=ClassID） |
| 41 | `_Require1_Value1` | 限制参数1 |
| 42 | `_Require1_Value2` | 限制参数2 |
| 43 | `_Require2_Type` | 限制类型2 |
| 44 | `_Require2_ID` | 限制ID2 |
| 45 | `_Require2_Value1` | 限制参数2（注意：可能有数据污染值如2199024305160=位标记） |
| 46 | `_Require2_Value2` | 限制参数2 |
| 47~54 | R3,R4 | 第3、4组限制（很少用到） |

### 判断是否限定职业

雪女冰弓（_Num=700）示例：
- R1: type=0 id=0 → 无限制
- R2: type=**1** id=**1** → 职业限制，ClassID=1（游侠）
- 结论：只限游侠装备

### 坑
- col45 常见值 `'2199024305160` 是编辑器位标记污染，实际值应为0，不影响校验
- 搜索装备时 ITEM_1.xls 的 _Name 是中文（GBK），但 ITEM_2.xls 的 _Name 也是中文
- 雪女冰弓的 _Num=700，+0~+9 不同强化等级共10行

## ITEM_2.xls关键列（0-based）

| 索引 | 列名 | 说明 |
|------|------|------|
| 1 | `_Num` | 道具ID |
| 3 | `_Name` | 道具名（GBK） |
| 10 | `_CashPrice` | 价格 |
| 11 | `_CashCheck` | **可上架开关** |
| 14 | `_Type` | 物品大类 |
| 15 | `_SubType` | 子类 |

## CASH_SHOP.xls关键列（0-based）

| 索引 | 列名 | 说明 |
|------|------|------|
| 1 | `_CategoryView` | 1=可见 |
| 2 | `_CategoryIndex` | 商城大分类 |
| 3 | `_CategoryIndex2` | 子分类 |
| 4 | `_CategoryIndex3` | 细分类（发型=5, 衣服=4, 宠物=7/23/0） |
| 6 | `_Name` | 商城显示名 |
| 16 | `_ItemID1` | 道具ID |
| 62 | `_Buy_Disable` | 必须=1 |
| 63 | `_Give_Disable` | 必须=1 |
| 64 | `_Limited_Time_Type` | 0=永久, 1001=7天, 1002=30天 |

### ITEM_2.xls双路径问题（2026-06-04）

ITEM_2.xls 可能存在于两个不同路径：
- `D:\LaTale\S2\resource\ROWID\DATA\XLS\ITEM_2.xls` — 彩虹岛编辑器的DATA路径
- `D:\LaTale\S2\resource\ROWID\XLS\ITEM_2.xls` — 上层XLS路径（可能更旧或不同版本）

注意：这两个文件**可能不同步**。一个被编辑器修改后另一个还是旧版。当修改CASH_SHOP.xls需要ITEM_2的图标数据时，优先读 `DATA\XLS\` 下的版本。如果该路径找不到ITEM_2.xls，尝试上层路径或直接从LDT二进制搜索。

- LoginServer端口：19100
- Game Server：Latalegameserver_101/102/151
- pack=1（读SPF包）
- dbgls.dll (3.2MB)：VMP加壳易语言内挂+认证二合一，不能删不能换
- 关闭服务时不要关LaTaleClient.exe

### configure_share.ini 路径迁移坑（复制端目录时必查）
当把服务端目录复制到新路径后，`configure_share.ini` 里有大量散落的 `resourceDir` 路径需要修正。常见触发错误：`configure_share.ini don't exist!`（configure.ini里的Share路径指向不对）或部分GS启动失败。

**排查步骤：**
1. 先确认 `configure.ini` 的 `[ConfigurePath]` 下 Share/ODBC/IPFILTER 指向正确
2. 搜索 `configure_share.ini` 中所有 `resourceDir=` 行，检查是否有指向旧路径的
3. 特别注意 **GS段末尾的追加段**（181/103/104/105/106/107/108/109/110等），它们经常指向旧端 `D:\彩虹岛\bin2\SPF版本错误_\`
4. 旧路径表现为GBK乱码如 `D:\��ʺ絺\bin2\SPF������_\`（实际编码同路径，视觉乱码不用管，看文件是否存在即可）
5. 修正后批量搜索确认无残留旧路径

**修改技巧：** 只改 `resourceDir=` 的值，保留其他参数不变。如果有多组GS指向旧SPF路径，统一改成目标端的resource根目录。

## GameServer 启动失败排查

当 GameServer 启动报 `LoadConfigure() : FAILED` 或 `INVALID SECTION INFO` 时：

### 根因分析

报错原文：
```
INVALID SECTION INFO : INI_FILE=[D:\LaTale\S4\bin2\configure.ini] SECTION=[LataleGameServer]
LoadConfigure() : FAILED !
```

这说明 **exe 在找的 section 名和 ini 里实际有的 section 名不一致**。

**关键判断**：
- exe 的命名决定它读哪个 section
- `LataleGameServer.exe`（通用名）→ 读 `[LataleGameServer]` 节
- `Latalegameserver_101.exe`（带后缀名）→ 读 `[LataleGameServer_101]` 节（或自身自动加后缀）
- 带后缀的 exe 可能通过 exe 文件名中的 `_101` 自动拼接 section 名，不需要 ini 里专门写无后缀的节

### 排查步骤

1. **确认你启动的是哪个 exe**
   ```bash
   ls -la /d/LaTale/S4/bin2/
   ```
   看目录下有哪几个 GameServer exe

2. **在 configure.ini 里搜该 exe 要找的 section**
   如果 exe 名是 `LataleGameServer.exe` → 搜 `[LataleGameServer]`
   如果 exe 名是 `Latalegameserver_101.exe` → 搜 `[LataleGameServer_101]`

3. **注意 exe 命名规则决定 section 查找方式**
   - `LataleGameServer.exe`（通用名, ~2.6MB）→ 读 `[LataleGameServer]` 无后缀节
   - `Latalegameserver_101.exe`（下划线+小写g, ~2.6MB）→ 可能读 `[LataleGameServer_101]`（带后缀节）
   - `LataleGameServer101.exe`（4MB）→ 比前两个大很多，可能不同版本，也读 `[LataleGameServer]`（无后缀节）

4. **如果 exe 找了通用 section 但 ini 里没有**

   方案 A：在 configure.ini 追加一个无后缀的 `[LataleGameServer]` 节，内容与 `[LataleGameServer_101]` 一致，然后重启

   方案 B：改用带后缀的 exe（如 `Latalegameserver_101.exe`），它可能自带读 `_101` section 的逻辑

### LOCALIZE.LDT 不要碰（不控制服务器启动）

LOCALIZE.LDT 不是 locale 配置表——它只是一个 URL 列表，里面是 Gameflier（游戏橘子）的充值/客服外链：
- `http://w3.gameflier.com/buy/buy.asp`
- `http://la.gameflier.com/`
- `https://gfb.gameflier.com/Billing/...`

**这个文件既不是服务器启动依赖，也不控制语言/地域校验**。改它不会影响服务器启动或客户端连接。服务端 GS 报 LOCALIZE.LDT 加载失败时，实际原因是 SPF 包缺失或路径不对，不是文件内容问题。

### exe 授权校验（机器码验证）

`LataleGameServer101.exe`（4MB 版本）可能有单独的机器码授权校验：
- 报错："该授权文件的机器码与本机不匹配"
- 校验与 `configure.ini` 配置无关，是 exe 自身带的保护
- 需用不同 exe 绕过（如不带校验的 `Latalegameserver_101.exe` 2.6MB 版），或提供匹配的授权文件

**判断 exe 是否有保护**：
- `LataleGameServer.exe` (2.6MB) — 通常无保护，直接启动
- `Latalegameserver_101.exe` (2.6MB) — 通常无保护，直接启动
- `LataleGameServer101.exe` (4MB) — 可能有保护（体积大说明多嵌入了授权/壳代码）

### 常见场景：从怀旧端拷贝 ini/exe 到新S2端

怀旧端S1衍生版的 ini section 命名规则可能和S2不同：
- 怀旧端：section 叫 `[LataleGameServer]`（无后缀），exe 叫 `LataleGameServer.exe`
- S2（他乡端/新端）：section 叫 `[LataleGameServer_101]`（带后缀），exe 叫 `Latalegameserver_101.exe`

**拷贝 ini 到新端时，如果被目标端的文件覆盖了，section 命名规则就变了**。检查时先确认当前盘上的 ini 实际内容，不要假设拷贝过程成功了。

### 其他可能原因

- **exe 版本与 ini 不匹配**：不同版本（怀旧/S2/他乡）的 exe 读 ini 的格式不同。注意 exe 体积差异：如 `LataleGameServer.exe`(2.6MB) vs `LataleGameServer101.exe`(4MB) — 不同版本
- **数据库连接不通**：如果 LoadConfigure 后还有 ODBC 报错，检查 Latale_ODBC.ini / Global_ODBC.ini 的 IP/端口/密码
- **加密 INI 校验**：某些端 exe 强制读加密 .inis，纯文本 ini 会被拒绝（报 `Server must using encrypt INI file`）

## 数据库
- 连接：127.0.0.1,59157 / sa / 123456
- 账号库：dbLataleAccount
- 游戏库：dbLataleWorld_2
- Point表（dbLataleAccount）：Point.balance=点券，Point.bonus=红利
  - Point结构：id(int), UID(varchar), balance(int), bonus(int)。**UID存的是账号名（如'Ciel'），不是数字UID**。
  - 查点券用 `SELECT * FROM Point WHERE UID='Ciel'`
- 账号表（dbLataleAccount）：tbluAccount(ID=登录名, Name=显示名, PW=明文密码, UID=唯一数字ID)
- UID7角色历史：月(97/98级, charID=11541)、月咪(98级)、雪儿(5级 已删)、2333(1级 已删)、999(31级)、G大哥(1级, charID=11549)、月(新版3级, charID=11552)、咕西(1级, charID=11553)
- **角色名占用在dbLataleAccount库**：tbluUsedCharName(ID=账号名) + CharInfo(UID=) + SubCharInfo(UID=)，不在dbLataleWorld_2

### 角色清除完整流程（创角卡住/名字已使用）
1. 查账号UID和角色
2. **dbLataleWorld_2**：清tbluItem2(UID=) + 所有含CharID的表 + tbluWorldShared(UID=)
3. **dbLataleAccount**（最重要）：清tbluUsedCharName(ID=登录名) + CharInfo(UID=) + SubCharInfo(UID=) + tbluWorldPC(UID=)
4. 验证无误后重启客户端创角

### 数据库备份恢复陷阱
- mdf替换后Bay/Room报ODBC登录失败 → ALTER DATABASE SET MULTI_USER + sp_change_users_login 'Auto_Fix', 'sa'
- 跨版本（SQL 2014 mdf → 2008 R2）不兼容，报\"版本782，支持663及以下\"
- 可用的同版本恢复源：`C:\\JSQL2008x\\JSQL2008\\MSSQL10_50.JSQL2008\\MSSQL\\DATA\\`

详细内容全部在 `references/database-operations.md`。

### 用户偏好（说话方式）
- 沟通极度简洁单字（1/2/好/行/删/咕/停），反感AI绕弯子/选项/废话
- 「我先停/你自己查」= 立刻停手，改让用户手动操作
- 选项给A/B/C封闭式，说「你决定」就自己选一个执行
- 数据场景直接跑脚本出结论，不问「要不要查」
- 改文本类任务：用户说「这部分你本地化试试」直接改不要问，改完给摘要
- **「被删了/不见了」场景**：用户说xxx被删了/不见了，先列出2~3种可能情况让他选，不要绕圈子问「你指的是什么」。可能的分类：数据库tbluItem2 vs LDT文件 vs 玩家背包 vs 商城暂存栏。商城暂存栏不走数据库表，tbluCashShop只有ShopID和Cnt两列无UID，是exe内存管理的。
- **shell卡住/诡异错误时**：先清 Hermes 缓存目录（`rm -rf ~/AppData/Local/hermes/cache/*`），可能是服务器过载或缓存脏了。用户痛恨AI长篇分析无用功，修不好的直接告诉他\"无解\"比绕弯子强。
- **服务器过载提示**：当模型响应变慢或连续tool调用失败时，可能是DeepSeek API限流，清理缓存+等待即可恢复。
- 沟通极度简洁单字（1/2/好/行/删/咕/停），反感AI绕弯子/选项/废话
- 「我先停/你自己查」= 立刻停手，改让用户手动操作
- 选项给A/B/C封闭式，说「你决定」就自己选一个执行
- 数据场景直接跑脚本出结论，不问「要不要查」
- 改文本类任务：用户说「这部分你本地化试试」直接改不要问，改完给摘要
- **「被删了/不见了」场景**：用户说xxx被删了/不见了，先列出2~3种可能情况让他选，不要绕圈子问「你指的是什么」。可能的分类：数据库tbluItem2 vs LDT文件 vs 玩家背包 vs 商城暂存栏。商城暂存栏不走数据库表，tbluCashShop只有ShopID和Cnt两列无UID，是exe内存管理的。
- **shell卡住/诡异错误时**：先清 Hermes 缓存目录（`rm -rf ~/AppData/Local/hermes/cache/*`），可能是服务器过载或缓存脏了。用户痛恨AI长篇分析无用功，修不好的直接告诉他"无解"比绕弯子强。
- **服务器过载提示**：当模型响应变慢或连续tool调用失败时，可能是DeepSeek API限流，清理缓存+等待即可恢复。

### 尝试性修改工作流
用户偏好直接改一次→测服务端→看崩不崩。不要先出长篇方案再问「要不要实施」。改前备份原文件（.bak_xxx），改后让用户重启服务端测试。两次失败立刻换方案或只出思路不动手。

### 角色物品清除警告（商城已购栏陷阱）
⚠️ **致命坑**：`DELETE FROM tbluItem2 WHERE UID=X` 会删除该账号下**所有**角色的所有物品，包括：
- 背包里的物品
- 装备栏里的物品
- **商城已购栏（购买后未取出的物品）** —— 玩家把时装放到商城已购栏准备转移时，数据仍在tbluItem2中，会被一起删掉
- **仓库里的物品**
- **快捷栏里的物品**

商城已购栏不是走单独数据库表的，它只是tbluItem2中容器状态未变更的物品。删除前必须确认该账号下没有未领取的商城购买物品。

### 角色清除完整流程（创角卡住/名字已使用）
当创建角色卡在初始界面或提示「名字已使用」时：

**步骤1：清游戏库角色数据**（dbLataleWorld_2）
```sql
-- 查角色
SELECT uID, charID, charName, lv FROM tbluPC WHERE uID=账号UID
-- 如果tbluPC已空但tbluItem2有残留，删：
DELETE FROM tbluItem2 WHERE UID=账号UID
```

**步骤2：清账号库角色名占用**（dbLataleAccount）
```sql
-- 角色名占用记录（最重要！包含已删角色的历史名称）
DELETE FROM tbluUsedCharName WHERE ID='账号名'
-- 角色完整信息
DELETE FROM CharInfo WHERE UID=账号UID
-- 子角色信息
DELETE FROM SubCharInfo WHERE UID=账号UID
DELETE FROM tbluWorldPC WHERE UID=账号UID
DELETE FROM tbluWorldShared WHERE UID=账号UID
```

**步骤3：清其他角色关联表**（dbLataleWorld_2, CharID范围）
所有含CharID的表都要清，常见：tbluQuest, tbluSkill, tbluEffect, tbluQuickSlot, tbluWayPoint, tbluAchieve, tbluMission, tbluPCExt, tbluPCStyle, tbluPCProfession, tbluPCContainer, tbluPCEffect, tbluCoolTime, tbluEventMission, tbluFestival, tbluTitle, tbluCollectMob, tbluCollectItem, tbluMyPoint, tbluFriendList, tbluBlockList, tbluCardBinder, tbluSubPC, tbluPCIndun, tbluPCPVP, tbluRandomQuestList, tbluItem2Old, tbluLimitDropChar, tbluAchvMission

### 数据库备份恢复陷阱

**mdf/ldf备份版本不兼容**：JSQL2008是SQL Server 2008 R2（内部版本号663）。从SQL 2014（版本782）导出的mdf文件无法用sp_attach_db附加到这个实例上，报错"版本782，无法打开。此服务器支持663版及更低版本。不支持降级路径。" 备份彩虹岛数据库时用BACKUP DATABASE命令生成.bak文件，不要直接拷mdf/ldf。

**还原工作流（.bak文件）**：
```bash
sqlcmd -S "tcp:127.0.0.1,59157" -U sa -P "123456" -Q "BACKUP DATABASE [dbLataleWorld_2] TO DISK = N'D:\LaTale\backup\xxx.bak'"
sqlcmd -S "tcp:127.0.0.1,59157" -U sa -P "123456" -Q "RESTORE DATABASE [dbLataleWorld_2] FROM DISK = N'D:\LaTale\backup\xxx.bak' WITH REPLACE"
```

**mdf替换法（限同版本）**：
1. `net stop MSSQL$JSQL2008`
2. 复制旧mdf/ldf覆盖 `C:\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\DATA\`
3. `net start MSSQL$JSQL2008`
4. 如果报"可疑或恢复挂起"，用 `EXEC sp_resetstatus 'dbname'` 修复
5. 注意：SQL会校验mdf内部版本号，跨大版本（2008→2012→2014）不兼容

**跨实例恢复技巧**：
- `C:\JSQL2008x\JSQL2008\MSSQL10_50.JSQL2008\MSSQL\DATA\` 存放着同版本（2008 R2）的彩虹岛数据库mdf/ldf文件，与当前JSQL2008兼容
- 停服→复制覆盖→启动→修复即可

**ODBC登录失败修复（mdf替换后Bay/Room崩）**：
还原数据库后Bay/Room报 `m_GameDB.DriverConnect : [FAILED]`（`ODBC SQL Server Driver 登录失败`）的原因是数据库用户和服务器登录名映射失效。修复步骤：
```sql
-- 杀掉占用连接
DECLARE @sql NVARCHAR(MAX) = N''
SELECT @sql += 'KILL ' + CAST(spid AS VARCHAR(10)) + ';'
FROM sys.sysprocesses WHERE dbid = DB_ID(N'dbLataleWorld_2')
EXEC sp_executesql @sql

-- 如果数据库处于EMERGENCY模式，先改为ONLINE
ALTER DATABASE [dbLataleWorld_2] SET ONLINE
ALTER DATABASE [dbLataleAccount] SET ONLINE

-- 设多用户模式（如果报"单用户模式已有连接"，重启SQL Server服务后再试）
ALTER DATABASE [dbLataleWorld_2] SET MULTI_USER
ALTER DATABASE [dbLataleAccount] SET MULTI_USER

-- 修复孤立用户映射
USE [dbLataleWorld_2]
EXEC sp_change_users_login 'Auto_Fix', 'sa'
USE [dbLataleAccount]
EXEC sp_change_users_login 'Auto_Fix', 'sa'
```

### dbLataleAccount 关键表（角色名占用相关）

角色创建卡"名字已使用"时，不只是tbluPC的问题，还需要清以下表（都在dbLataleAccount库）：

| 表 | 作用 | 清除方式 |
|----|------|---------|
| `tbluUsedCharName` | 角色名占用记录（包含已删角色的历史名称） | `DELETE FROM tbluUsedCharName WHERE ID='账号ID'` |
| `CharInfo` | 角色完整信息（含Status标记O/X） | `DELETE FROM CharInfo WHERE UID=账号UID` |
| `SubCharInfo` | 子角色信息 | `DELETE FROM SubCharInfo WHERE UID=账号UID` |

**角色清除完整流程**：
1. 删游戏库角色相关数据：tbluPC, tbluItem2(UID=), tbluQuest, tbluSkill等所有CharID关联表
2. 删账号库角色名占用：tbluUsedCharName(ID=), CharInfo(UID=), SubCharInfo(UID=)
3. 商城（CASH_SHOP.LDT / tbluCashShop）不需要动
4. 重启客户端创角

**tbluCashShop表确认**：只有ShopID和Cnt两列，无UID/CharID列。两个库（dbLataleWorld_2和dbLataleAccount）中的此表都为空。商城暂存栏不是走数据库的，而是服务端exe内存管理。

### 角色物品恢复（误删后）

如果不小心执行了 `DELETE FROM tbluItem2 WHERE UID=X` 导致角色物品丢失：
- 没有日志表可以回滚（除非有.bak备份）
- 可以在ITEM_2.LDT中查道具定义，用GM工具重新发
- ITEM_2中查找方法：已知ItemID时用 `struct.pack('<I', item_id)` 在LDT中搜索4字节

## ITEM_2筛选工作流（2026-06-04 确立）

从编辑器导出的全量TXT（~10000行）逐步删除不需要的类别，每次保留item2_clean.txt。过滤步骤记录在 latale-ldt-field-mapping 的 references/item2-iterative-filtering-workflow.md。

**核心原则（2026-05-31 用户明确）**：只做LDT/SPF层面的事。所有exe/GS协议层面的大改动（S2→S3升级、时装幻化、地图碰撞）一律放弃。能做的是：合地图资源、合任务线、改道具/商城/商店这些纯数据和内容的工作。

## 文本本地化（繁转简）工作流（2026-06-04 确立）

需要将台服繁体文本转为国服简体时，按以下顺序排查：
完整繁转简映射表见 references/t2s-mapping-comprehensive.md。
GLOBAL_STRING消息ID对照表见 references/global-string-message-ids.md。

### 文件定位
用户的反馈通常是游戏里看到的文本，需要搜到它在哪个表里：
1. **提示消息/对话框** → `GLOBAL_STRING.xls`
2. **技能描述** → `SKILL_TXT.xls`
3. **NPC对话** → `NPCTALK.xls` / `NPC.xls`
4. **地图储存点对话** → `SAVEPOINT.xls`（需编辑器从SAVEPOINT.LDT导出）
5. **地图事件/石塔交互** → `MAPEVENT.LDT`（该表的部分文本可直接编辑LDT，无需转XLS）
6. **道具描述** → `ITEM_1/2/3.xls` 或对应 LDT
7. **效果/状态描述** → `EFFECT.LDT`

### 台服→国服常用术语对照
```
资讯→信息       连线→连接       帐号→账号
配戴→佩戴       装备窗→装备栏    初始化→重置/初始化（看语境）
回覆→回复       取消→取消（已一致） 功能→功能（已一致）
储存→储存       战斗→战斗       骑士→盾卫（基础职业）
剑斗士→双刀     游侠→游侠       法师→法师
技巧：先用 decode('gbk', errors='replace') 解码后搜关键词确定范围，
再用二进制 replace 做批量替换（注意bytearray模式）。
```

### 操作步骤
1. **先备份**：`cp 文件.xls 文件.xls.bak`
2. **二进制替换**：用 `bytearray` 打开文件，`.replace(old_gbk, new_gbk)`
   - 注意编码：`"繁体".encode("gbk")`
   - 注意优先逐词替换，不要整句替换（避免编码不一致导致遗漏）
3. **验证**：解码后搜繁体字符看是否有残留
4. **特殊表**：SAVEPOINT.LDT 是 LDT 二进制格式，必须用彩虹岛编辑器导出为 XLS 才能编辑。改完 XLS 后用编辑器写回 LDT。
5. **GLOBAL_STRING.xls** 特殊：`\\n` 在字节层面是 `5C 6E`（反斜杠+n），编码匹配时注意与 Python 字符串的转义区别。

### 批量替换示例
```python
with open("file.xls", "rb") as f:
    raw = bytearray(f.read())
for old, new in {"繁体": "简体"}.items():
    raw = raw.replace(old.encode("gbk"), new.encode("gbk"))
with open("file.xls", "wb") as f:
    f.write(raw)
```

### 当前本地化进度（2026-06-04）
- ✅ GLOBAL_STRING.xls：职业名本地化 + 消息文本12条
- ✅ SKILL_TXT.xls：配戴→佩戴
- ✅ NPCTALK.xls：配戴→佩戴、回覆→回复
- ✅ SAVEPOINT.xls：全部繁转简（需写回LDT）
- ⏳ 其他表有繁体文本但用户自行处理

## 任务分析工作流（2026-05-30 完善）

当用户需要分析任务系统的经验/地点/等级关联时，按以下步骤：

### 数据准备
1. 用彩虹岛编辑器打开 QUEST_REWARD_1.LDT → 导出全表为TXT（TAB分隔），放桌面
2. 用彩虹岛编辑器打开 QUEST_INFO_1.LDT → 导出全表为TXT（TAB分隔），放桌面
3. **编辑器导出格式**：TAB分隔、CRLF换行、无行号（行号=文件1-based行号）
   - QUEST_REWARD_1共33列：col0=RowId, col1=EXP, col2=Ely, col3=Fame
   - QUEST_INFO_1共29列：col0=_Icon1, col3=_Place_Info1(地点), col4=_NPC_Info1(NPC), col20=_Quest_BaseLV(接取等级), col21=_Quest_Kind(任务类型/等级要求), col24=_Quest_Next(后继RowId)

### 分析脚本（技能目录内）
技能目录下的两个脚本，接收路径参数：
```
python scripts/quest_analyzer.py <QUEST_REWARD_TXT路径>
python scripts/quest_analyzer_v2.py <REWARD_TXT> <INFO_TXT>
```
绝对路径示例（从桌面跑）：
```
python C:\Users\Administrator\AppData\Local\hermes\skills\gaming\latale-dev\scripts\quest_analyzer.py 111.txt
python C:\Users\Administrator\AppData\Local\hermes\skills\gaming\latale-dev\scripts\quest_analyzer_v2.py 111.txt 123.txt
```
- v1: 单表分析（EXP降序排列、量级分组、20亿模板块检测）
- v2: 关联分析（BaseLV分布、新手村异常、任务链追踪）

### 分析参考文档
详细的量化结论、表结构、异常判定标准、20亿模板规律见：
`references/quest-exp-analysis.md`

### 修改策略
1. 找到BaseLV<=10且EXP>1000万的异常任务 → 修正为合理值
2. 任务链用_Quest_Next串联，修改前确认不影响后续链
3. 行1002（"第十一座石塔的下落(7)"）20亿要降，但不是直接清零
4. 20亿模板行中BaseLV=1的才需要动，BaseLV乱码的不用管

### NPC→任务关联
新增/修改任务时，NPC关联信息见 `references/npc-quest-directory.md`
- S2有101个NPC关联到75个地点（从QUEST_INFO_1导出TXT解析）
- 某NPC的任务链可通过导出TXT搜NPC名查到
- S1的NPC信息嵌在QUEST.LDT string区，无独立索引

### 分析要点
- 先看BaseLV分布：所有20亿任务是否BaseLV=1（即1级可接）
- 看地点分布：新手村（贝罗斯/艾利亚斯）的任务是否也给了巨额经验
- 看任务链：用_Quest_Next列串联，确认修改单个任务不影响后续链
- **不要只盯印象中的"4个异常行"**——全表分析后再动手

### 异常判断标准
- BaseLV<=10 且 EXP>1000万 → 异常（新手不应该拿这么多）
- 贝罗斯/艾利亚斯村庄的引导/对话任务给百万级经验 → 异常
- 高等级地图（停等区/市中心/鲁米诺斯城等）的20亿经验不一定异常，但BaseLV=1就是问题
- 行链表：用_Quest_Next串联任务链，next=2通常是孤立任务，next=0是终点

## 任务系统文件结构

他乡端S2的任务系统实际由以下文件组成（QUEST.LDT/QUEST_REWARD.LDT主表数据无效）：
- **QUEST_INFO_1.LDT** (29列×1607行)：含_Quest_BaseLV(基础等级) / _Quest_Kind(类型)，**实际有效表**
- **QUEST_REWARD_1.LDT** (33列×1153行)：行索引与INFO对应，含_Reward_EXP / _Reward_Ely
- **QUEST_1.LDT** (108列×1153行)：_Name是int32索引ID（非直接文字）

**关键发现**：QUEST_REWARD_1.LDT 共1153行，1037行有非零EXP，总经验9579亿。其中**398个任务给20亿经验**（占比38%），主要分布在：
- 行108~295：零星系列任务（RowId=128201052等）
- 行687~1043：连续大块"第十一座石塔的下落"系列（RowId=164001000~164002094），全部20亿——这是非法改端遗留
- 行877~902：164001101~164001213系列，每个给20亿+1000万金币
- **唯一正常的低等级任务链是行1~22**（RowId=115003000~115042000），经验9000→6000万逐步递增

**任务系统结论**：这个端整个QUEST_REWARD_1几乎全废，大量20亿模板数据未清理。改动前必须全表分析，不要只盯着印象中的"4个异常行"。

## LDT工具
- 彩虹岛编辑器：D:\LaTale\小九三合一\彩虹岛编辑器.exe
- 写入脚本：C:\Users\Administrator\Temp\ldt_writer.py
- 繁简转换：batch_t2s.py
- LDT格式：偏移0=unk(4B),4=列数(4B),8=行数(4B),12=列名区(每列64B),8204=类型区(每列4B),8716=数据区。string=2字节长度+GBK

## LDT特殊格式表
某些LDT头部声明了标准列数量和行数，但**实际数据区全为零**，真实数据以二进制嵌入在标准数据区之后的区域（直到文件末的`END`标记）。
已知的此类表：
- **EXPERIENCE.LDT** — 经验表，文本嵌入
- **EVENT_CHECK.LDT** — 活动检查表，二进制嵌入在偏移0x2208
详见 `references/ldt-special-formats.md`

## EVENT_CHECK.LDT（活动检查表）
13列(Start_Year/Month/Day/Hour, End_Year/Month/Day/Hour, Event_id, Type, Type_id, Event_point, Use) × 3行。
标准头部数据区全零，真实数据在偏移0x2208（二进制嵌入）。
详见 `references/event-check-analysis.md`

## CREATION_INFO.LDT（创角赠送表）

82列 × 104行，全部int32。定义创号时送的物品(最多4组)、技能、快捷栏、出生坐标等。

⚠️ **二进制编辑有坑**：该表数据偏移=8716, 行大小=328B, 但二进制逐行读出来的_Class/_Gender值和编辑器TXT不一致（同一Class值出现多次，Gender值异常）。**改前必须用编辑器导出TXT确认数据关系**。

安全修改流程：
1. 编辑器打开CREATION_INFO.LDT → 导出全表TXT
2. 在TXT中修改对应Class行
3. 用 `ldt_writer.py` 写回LDT

职业ID和名称的完整映射、表结构详解见 `references/creation-info-analysis.md`

## CREATION_INFO_BURNING.LDT（燃烧创角表）
结构和CREATION_INFO.LDT一致，但有`_Ex_Stat/Limit/Min/Max`字段控制额外属性（燃烧经验倍率），`_Item_ID`出现具体BUFF道具ID如190180612（"燃烧标记"）。

## 彩虹岛职业系统
7个基础职业（剑士/法师/游侠/盾卫/督军/双刀/圣殿，Class=1~7），二转三转有更多分支（Class=8~52、73~75、81~84）。
完整映射表见 `references/creation-info-analysis.md`
当用户提到职业名称时，用Class ID在CREATION_INFO中查找对应行。

## SPF打包
- 工具1：D:\Backup\Documents\有SFP解包打包v1.6.exe（作者"解密3000"）
- 工具2：今昔破解版.exe
- 他乡包SPF加密只能用作者工具打包，Mix工具会破坏加密结构

## NPC交易系统
## CASH_SHOP追加规则
详见 cashshop-append-rules 技能

### 数据库切换bat（本地/联机）

`D:\LaTale\S4\bin2\` 目录下有两个bat用于切换SQL数据库连接：

- **切换本地数据库.bat** — 一键改Latale_ODBC.ini为127.0.0.1:59157
- **切换联机数据库.bat** — 手动输入远程IP和端口

原理：只改配置文件Latale_ODBC.ini中的IP和端口，不搬数据。
数据文件位置：`C:\JSQL2008\`
- dbLataleAccount.MDF = 41MB（账号库）
- dbLataleWorld_2.mdf = 32MB（世界库）
- dbLataleWorld_2_1.ndf = 57MB
- 日志文件（.ldf合计1.3GB）可收缩

需要完整迁移数据库时：停GS→SQL收缩日志→分离/备份→7z压缩→传输→远程挂载。

当彩虹岛服务端部署在远程云电脑/服务器商，本地客户端需要跨网络连接时：

### 虚拟组网方案对比

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| **Radmin VPN** | 免费、稳定、自动P2P打洞 | 英文原版免费（中文站收费） | ★★★★★ |
| EasyN2N | 自建/免费SuperNode可选 | UDP打洞不稳定，免费SuperNode不可靠 | ★★★ |
| 小黄鸭中转 | 可控中转节点 | 节点可能不稳定，组网互相发现困难 | ★★ |
| ngrok TCP | 无需组网直接暴露端口 | 免费版TCP需绑卡验证 | ★ |

**首选 Radmin VPN**：https://www.radmin-vpn.com/（英文原版免费）

### 服务端配置修改

当通过虚拟组网连接时，远程机的 configure.ini 和 configure_share.ini 需要：

1. **改所有 PublicIP**：从 `127.0.0.1` 改为**远程机在虚拟组网中的IP**（如 Radmin 分配的 26.201.194.1）
2. **改所有服务端口**（如果需要配合服务商的端口映射范围）
3. **MS引用端口同步**：`[MS] Port` 也要一起改

### 端口映射方案（服务商只开放10个端口时）

| 服务 | 原端口 | 映射建议（41470~41479） |
|------|-------|-----------------------|
| LoginServer | 19999 | 41470 |
| MgmtServer(MS) | 10001 | 41471 |
| LobbyServer | 10002 | 41472 |
| GameServer_101(频道1) | 10003 | 41473 |
| GameServer_151(副本) | 10005 | 41474 |
| BayServer(商城) | 10006 | 41475 |
| RoomServer(房间) | 10007 | 41476 |
| GameServer_102(频道2) | 20003 | 41477 |
| ASServer(活动) | 10020 | 41478 |
| 备用 | - | 41479 |

### ⚠️ PublicIP 陷阱：LoginServer IP校验

这是最常见的远程连接坑，**目前确认无配置层解决方案**。

#### 现象
- **PublicIP=127.0.0.1** → 能看到登录窗口但看不到频道（客户端拿到127.0.0.1的地址连不上）
- **PublicIP=虚拟组网IP（26.201.194.1）** → 连上2~3秒后被服务端主动中断（socket 收到 0 字节后 WinError 10053）

#### 根因
LoginServer 在 exe 层有 IP 校验逻辑——客户端连上来后，服务端比较**客户端源IP**和**配置文件 PublicIP**。不匹配就直接中断连接。这是应用层行为（不是防火墙），`netstat` 能看到 `ESTABLISHED` 但 2~3 秒后被主动关闭。

#### 确认为 exe 层硬编码的证据
1. `Cipher_Mode` 改 1→0 不影响（127.0.0.1 时能进选角说明不是加密问题）
2. `SkipVersionCheck=1` 已设
3. 配置中没有 `CheckClientIP`、`IPFilter` 相关字段
4. `KickOutInterval` 是踢人超时不是踢人开关
5. 服务端 `netstat` 能看到连接正常 ESTABLISHED，然后服务端主动 RST

#### 症状识别（全模式覆盖）

| 模式 | PublicIP | 结果 | 原因 |
|------|---------|------|------|
| Radmin/虚拟组网 | 127.0.0.1 | 能登录没频道 | 客户端拿到的IP连不上 |
| Radmin/虚拟组网 | 虚拟IP | 2~3秒被踢 | 源IP≠PublicIP校验失败 |
| 公网端口映射 | 公网IP | 2~3秒被踢 | 源IP≠PublicIP |
| 服务商NAT后 | 公网IP | 2~3秒被踢 | 源IP是NAT网关IP ≠ PublicIP |
| 本地测试（GS和客户端同机） | 127.0.0.1 | 正常 | 无网络层IP差异 |

#### 验证方法
Python socket 测试（保持10秒看是否被踢）：
```python
import socket, time
s=socket.socket(); s.settimeout(15)
s.connect(('IP',PORT))
print('Connected')
for i in range(10):
    try:
        s.send(b'keepalive')
        data = s.recv(1024)
        print(f'Second {i+1}: received {len(data)} bytes')
    except Exception as e:
        print(f'Second {i+1}: {e}')
        break
    time.sleep(1)
```
- 收到 0 字节后 `WinError 10053`（主机中止连接）= 服务端主动踢
- 正常保持在线上 = 连接没问题

#### 唯一已知的绕过方式
**服务端和客户端在本地同机测试，不走网络**——在远程机上直接双击客户端启动。如果远程机本地能正常游戏不掉线，100% 是跨网络 IP 校验问题。

目前无配置层解决方案。以下路径理论上可能绕过但均未验证：
- 改 GS exe 去掉 IP 校验（需要逆向）
- 找该版本的源码重新编译（如果源码可用）
- 在服务商侧做 SNAT（源地址转换），让客户端源 IP 变成 PublicIP 相同的地址

#### 诊断流程（当客户端连上远程GS时）

1. `ping` 远程机的虚拟组网IP（确认网络通）
2. 手动 socket 连 LoginServer 端口（确认端口通、服务端运行）
3. 保持连接 10 秒看是否被踢（区分网络问题 vs IP校验问题）
4. **关键区分测试**：在远程机本地启动客户端（不经过网络），正常不掉线 → 100% IP校验问题

### 防火墙配置

远程机上开放彩虹岛端口（如果服务端所有进程跑在同一台机器）：

```
netsh advfirewall firewall add rule name="Latale_4147X" dir=in action=allow protocol=TCP localport=41470
```

批量加：
```
for %i in (41470 41471 41472 41473 41474 41475 41476 41477 41478) do netsh advfirewall firewall add rule name="Latale_%i" dir=in action=allow protocol=TCP localport=%i
```

注意：防火墙不阻挡已建立的连接——如果TCP握手成功但被踢，是应用层问题不是防火墙问题。

### 排查流程

当客户端连不上远程GS时：

1. ping 远程机的虚拟组网IP（确认网络通）
2. 手动socket连 LoginServer 端口（确认端口通）
3. 如果端口通但连接3秒后被踢 → **LoginServer IP校验**
4. 在远程机本地启动客户端测试（排除网络问题）
5. 如果远程机本地玩不掉线 → 100%是网络隧道/组网/IP校验问题，不是服务端配置问题



## 服务端exe版本对比与野外同步异常

详见 `references/exe-version-comparison.md`。

不同版本端（他乡端4MB vs 普通端2.6MB vs S1端2MB）的exe和客户端exe必须配套使用，否则出现野外怪掉下来、打怪无伤害、掉线等问题。无配置层解决方案。

## BUFF/Effect 调查

⚠️ **行号偏差**：二进制算的行号（data_off + row * colCount * 4）和编辑器显示的行号通常对不上。因为string区在数据区之后，文本偏移和行号不是线性关系。找数据行应该用_Num（col1）或_BuffID（col3）的值搜，不要靠文本偏移估算行号。

### 排查工作流（减少无谓的遍历）
当用户要求移除某个BUFF（如"爱丽丝的祝福"200%经验）时，按此顺序快速定位：

1. **查EFFECT.LDT** → 全局搜文本，找到effect定义
2. **查CREATION_INFO.LDT** → 有没有Effect相关字段（该表无Effect字段）
3. **查GLOBAL_EVENT.LDT / EVENT_INFO.LDT** → 有没有活动事件配置
4. **全局搜该effect名称文本** → 看哪些表引用它
5. **如果以上都无触发逻辑 → 结论：服务端exe硬编码，不再继续遍历**。
   - 改EFFECT.LDT的效果参数（_EffectValueType 200→100）试探
   - 或者需要找人改exe

⚠️ **坑**：该端大量系统功能是服务端exe硬编码的，不要遍历全部几十个LDT表找触发逻辑。EFFECT.LDT全局搜命中后，再查3~4个最可能的表（CREATION_INFO / EVENT_INFO / GLOBAL_EVENT / GIFT_INFO）就够下结论了。

### "爱丽丝的祝福" 200%经验BUFF（排查记录）
创建角色自带，EFFECT.LDT中查到两条相关记录：

| 效果名 | 文本 | 位置 |
|--------|------|------|
| 爱丽丝的祝福 | 经验值获得 200%， 任务奖励UP！ 50% (60分钟) | EFFECT.LDT ~行1540 |
| 艾丽斯的祝福 | 经验值获得量增加 40% (30分钟) | EFFECT.LDT (另一行) |

**结论**：该BUFF不在LDT表中控制。EFFECT.LDT改 _EffectValueType 从200→100（已改），但可能不生效。

**全局搜索命中汇总**：
| 位置 | 内容 |
|------|------|
| EFFECT.LDT | 定义effect本身（200%经验，60分钟） |
| EFFECT.LDT (另一行) | "艾丽斯的祝福"40%经验（不同effect） |
| ITEM_3.LDT | 物品描述提及"获得艾丽斯的祝福时无法使用" |
| NPCTALK.LDT | NPC对话提及（温泉NPC） |
| PVP_EFFECT.LDT | PVP场中30%版本 |

## 扫荡任务设计（2026-05-30 调研记录）

S2（他乡端）的新手村（贝罗斯/艾利亚斯/古木林/奥亦奇/龙京）**没有任何野怪扫荡任务**（杀X只类型）。只有对话/跑腿/剧情任务和惠宗的捐献任务。S1有（"打败噗咻呼咻10只"等），但S2把这些全删了。

### 用户期望的扫荡模式

| 等级段 | 每只数量 | 奖励 | 链式 |
|--------|---------|------|------|
| 1~30级 | 30只/次 | 给30%等级经验 | 打完A自动出现B |
| 30~70级 | 70只/次 | 给140%等级经验 | 同上 |
| 70级+ | 99只/次 | 给140%等级经验 | 同上 |

### 实现方式确认

- **任务链**：QUEST_INFO_1的_Quest_Next字段支持链式串联（已完成A→出现B→出现C）
- **重复任务**：_Quest_Kind=1（惠宗捐献任务那种）看起来是可重复类型，但具体"反复按12345"的机制需要试改才知道
- **杀怪计数**：行35（水耕农场·"猎杀80只卡特"）能正常工作，说明服务端支持自动计数
- **怪物映射**：S2的MOBBASE.LDT(101列×6067行)和MOBARRANGE.LDT(18列×15079行)包含怪物名字→地图ID映射，但_Name字段是int32索引ID（type=0），实际名字需要编辑器导出TXT才能看

### 待调研的问题
1. 新手场(古木林/贝罗斯/艾利亚斯外围)对应哪些怪物ID → 需用编辑器打开MOBBASE导出看
2. 可重复任务的标记字段是什么（_Quest_Kind? _Mission_OnOff?）→ 需试改确认
3. S1的"噗咻呼咻"（古木丛林）"毒蚁G"（地下洞穴）"小豆羊"（艾尔诺勒平原）在S2中对应的怪物名是什么

### 相关引用文件
- `references/npc-quest-directory.md` — 可用于确定扫荡任务放在哪个NPC上
- `references/quest-exp-analysis.md` — 经验奖励的参考值
- `references/s1-vs-s2-tasks.md` — S1已有的扫荡任务做参考

### 推荐的实现步骤
1. 用编辑器导出MOBBASE的TXT，确认低等级怪物名和ID
2. 在QUEST_INFO_1先试改一行现有任务（如行3贝罗斯村庄·亚辉），改成"杀30只怪"看服务端是否正常计数
3. 如果OK，按三档规则批量追加任务链（_Quest_Next串联）
4. 每个扫荡任务在QUEST_REWARD_1中配对应的EXP/Ely奖励

## NPC交易系统

详见 `references/npc-trade-system.md` — NPCTRADE完整链路（DETAIL定价→LIST分类→TRADE商品→NPC绑定）、精灵石上架进度、坑点汇总。

## 经验表 (EXPERIENCE.LDT)

详见 `references/experience-table-analysis.md` — 经验曲线、Lv1~255对照、修改策略（A/B/C）、QUEST_REWARD双格式结构。

分析工具：
- `scripts/rewrite_exp_ldt.py` — 重写经验表
- `scripts/set_quest_reward_exp.py` — 修改任务奖励
- `scripts/analyze_quest_exp.py` — 任务+经验关联分析

## 改端能力边界

详见 `references/customization-boundaries.md`

## NPCTRADE_LIST.LDT 结构

40列，每2列为1组（_GroupID + _GroupName），共20组。
_ID 列 = NPC.LDT 中 EventType=4 的 TypeID 值。
每组的 _GroupID 映射到 NPCTRADE.LDT 的 _ID 列。
每组的 _GroupName 描述商品类型（如"交易1 ~ 10 Lv 初级武器"）。
详见 `references/npc-trade-system.md`。

### NPCTRADE.LDT 结构确认（2026-06-07 从xls导出确认）

53列（0-based）：
- col0=_BuyFactor（收购倍率）
- col1~50=_ID1~_ID50（50个商品ItemID，空位=0）
- col51=_CutInImage（NPC头像/显示图）
- col52=_Message（备注说明文本）

每行对应一个NPC的完整商店。

### 给NPC商店添加商品的工作流
1. 用彩虹岛编辑器打开 NPCTRADE.LDT → 导出 xls
2. 找到该NPC对应的行（通过 NPC.LDT 的事件链定位）
3. 在空的 ID 列填入精灵石的 ItemID（如 160100111 等）
4. 打开 NPCTRADE_DETAIL.LDT → 导出 xls → 添加精灵石的 _ItemRare/_ItemCount/_SellFactor
5. 写回 LDT，重启 GS

判断流程：先想"这是数据/内容还是逻辑/渲染？"
- 数据/内容 → LDT/SPF层，直接搞
- 逻辑/渲染 → 没有LDT字段控制的就是exe硬编码，放弃
不要花时间试exe层面的事（幻化、地图碰撞、选人界面交互、按键绑定、蓄能动画）。

**法师 Z/X 基础攻击是 exe 硬编码**：Z键（瞬发魔法）/X键（蓄能重攻击）是客户端exe的按键动作绑定，不在SKILL.LDT中定义。台服S3/S4改版中，X键蓄能动画在连线状态下不播放直接出"MISS"回避字样，是台服服务端exe的固有行为。没有源码就改不了。改LDT无效。断线时X键播蓄能动画但无伤害——正常限制，蓄能技必须服务端回包结算。

**SPF包结构**（S4端，确认）：
- ROWID=游戏内容/信息（含LDT表文件）
- AJJIYA=怪物/NPC/角色/宠物通用类型
- BANX=图标/NPC/怪物绘画
- CVOICE=漫画图片
- DALBONG=背景BGM
- HOSHIM=特效绘图
- JINSSAGA=地图信息
- MAKO1298/RYUMS=地图绘画
- METALGENI=怪物/技能音效
- ZENNE=怪物/NPC/时装图片
- BARY=载入图/地图
- CLAIRE=登录界面说明
- FREE=更新包可覆盖数据

**S4chd国服参考端**：`D:\LaTale\S4chd\resource\ROWID\DATA\XLS\SKILL s4.xls` 是简体中文国服正确数据源，优先用于修复DisableDescription等文本列。包含3937个ID，S4端仅3555个。

服务进程结构见 `references/s4-server-process-structure.md`。

他乡端 vs 怀旧端对比

他乡端（D:\LaTale\彩虹岛S2 他乡彩虹岛\解包目录\ROWID\DATA\LDT\）是S2的更新版本，怀旧端是S1衍生版。两个端的LDT文件结构一致但数据量不同。

### EFFECT.LDT 差异概览
| 项目 | 他乡端 | 怀旧端 |
|------|--------|--------|
| 大小 | 8.0MB | 5.7MB |
| 行数 | 26,570 | 18,787 |
| 非零BuffID | 12,016 | 8,480 |

他乡端多了约40%的效果定义。**怀旧端的"爱丽丝的祝福 200%经验"在他乡端不存在**——被替换为"暴走的爱丽丝图腾"（固伤型图腾效果）。两个端都有"艾丽斯增益效果 40% (30分钟)"。

搜索EFFECT.LDT中的效果名时，注意字符串以2B长度前缀+GBK编码存储在数据区后面，用二进制搜索文本即可定位。

详见 `references/hexiang-vs-huajiu-diff.md`

## LDT全string格式文本搜索（GLOBAL_STRING/SKILL等）

全string格式（类型区全0）的LDT文件（如GLOBAL_STRING.LDT, SKILL.LDT, SKILL_CONTENT.LDT），文本以\x00分隔存储，行间用\x00\x00分隔。

### 文本定位方法
1. `data.find('关键词'.encode('gbk'))` 搜到偏移
2. 往前/往后找\x00确认字符串边界
3. 提取附近\x00分隔的字符串即上下文

### GLOBAL_STRING.LDT 常见消息ID（行大小256）\nGLOBAL_STRING.LDT中系统消息有固定ID编号（80011/80012/90001等），在xls中第一列就是消息ID。通过编辑器导出xls可直接定位。常见消息范围：\n\n| 消息ID | 简体文本 | 原始繁体文本 |\n|--------|---------|------------|\n| 80011 | 因为玩家信息问题，连接服务器延迟。 | 因为玩家信息问题，连接服务器延迟。 |\n| 80012 | 因为角色信息问题，连接服务器延迟。 | 因为角色信息问题，连接服务器延迟。 |\n| 80013 | 服务器连接延迟。 | 服务器连接延迟。 |\n| 80014 | 服务器无回应。请稍后重新试一下。 | 服务器无回应。请稍后重新试一下。 |\n| 80015 | 操作失败，请联络工作人员。 | 操作失败，请联络工作人员。 |\n| 80016 | 未达App里要求的安全等级。 | 未达App里要求的安全等级。 |\n| 80017 | 抱歉，请稍后重新尝试。 | 抱歉，请稍后重新尝试。 |\n| 80018 | 对不起，?????或已?取?品 | 对不起，?????或已?取?品 |\n| 80019 | 由于检测到非法行为，???后再次游戏。 | 由于检测到非法行为，???后再次游戏。 |\n| 80020 | sndaId不同。 | sndaId不同。 |\n| 90001 | 密码键不一致。 | 密码键不一致。 |\n| 90002 | 安全模式已更新。请重新登录游戏，更新安全模式。 | 安全模式已更新。请重新登录游戏，更新安全模式。 |\n| 90011 | OTP 认证失败。 | OTP 认证失败。 |\n| 90012 | 超过了输入时间。 | 超过了输入时间。 |\n| 90013 | 认证键重复。 | 认证键重复。 |\n| 90014 | 由于系统错误，认证失败。 | 由于系统错误，认证失败。 |\n| 90015 | 不能使用特殊字元。 | 不能使用特殊字元。 |\n| 90016 | 只能输入数位。 | 只能输入数位。 |\n\n（部分ID的文本在编辑器导出XLS中查看，ID列就是消息编号）\n| ~行148 | [%s]获得了物品。 | 系统提示 |\n| ~行150 | 找不到对方。 | 聊天 |\n| ~行152 | 现在无法连接。 | 连接失败 |\n| ~行153 | 对方现在没有回应。 | 聊天 |\n| ~行160 | 彩虹岛有您更精彩~ | 聊天（ROWID.SPF偏移0xf752d2） |\n\n**修复方法**：用彩虹岛编辑器导出GLOBAL_STRING.LDT为XLS（TAB分隔GBK文本），直接改文本列，再写回LDT。注意部分文本（如\"彩虹岛有您更精彩~\"）存储在ROWID.SPF包内，不在LDT中。只能在ROWID.SPF解包后搜偏移0xf752d2修改，或在登录器/网关.exe中。\n\n**GLOBAL_STRING消息ID的文本翻译**：绝大多数80011~90016的文本繁简体一样（简体字即可），可以直接用。80018/80019有乱码，需从编辑器XLS中复制原始文本后手动校对。

**修复方法**：用彩虹岛编辑器导出GLOBAL_STRING.LDT为XLS（TAB分隔GBK文本），直接改文本列，再写回LDT。注意部分文本（如"彩虹岛有您更精彩~"）存储在ROWID.SPF包内，不在LDT中。

### ⚠️ 致命坑：LEARN_SKILL 职业ID（ClassID）映射

LEARN_SKILL.xls 中 Type=1 ID=1 是**职业限制条件**，V1 的值是职业ID。

**职业ID来自 CLASS_STRING.LDT，不是 SKILL.xls 里的职业编号！**

从怀旧端 CLASS_STRING.LDT 确认的映射（部分）：
- ID=1: 战士
- ID=2: 骑士
- ID=3: **法师**（但实测可能被归类为战士/盾卫）  
- ID=4: **游侠**（可能是真实的法师ID？待确认）
- ID=11: 魔导士
- ID=1001~1004: 可能是职业分组/转职体系中的ID（不是CLASS_STRING中定义的职业ID）

**当前端问题**（2026-06-08 发现）：
- LEARN_SKILL 中所有法师技能用 V1=1003，但 CLASS_STRING.LDT 中法师=3
- 1003 可能对应战士/盾卫职业组，导致法师学不了技能
- 实测把 V1=1003 → 3 后，游侠和魔导都能学（说明3不是纯法师专用）
- **用户怀疑 4 才是法师**，需要进一步查 CLASS_STRING 确认

**修复试探结论**：
- 全量改 1003→3 后，部分技能正常（如念力控制冰雪魔力火之祝福）
- 但用户反馈3"归类给了战士和盾卫"
- ⚠️ 等待用户确认正确职业ID后再做最终修改

### SKILL.LDT 结构与SKILL.xls的关联

SKILL.xls 中没有显式的"职业限制"列。技能学不学得了依赖：
1. LEARN_SKILL.xls（Type=1 ID=1=职业限制, Type=1 ID=3=等级限制, Type=3 ID=2=前置技能）
2. SKILL.xls 的 _Learn_Skill=1（允许从NPC学习）
3. CLASS_STRING.LDT（职业ID→职业名映射，影响GS对职业ID的解析）

**GS实际判断流程**：
1. 用户点击NPC学技能 → GS查 LEARN_SKILL 中该技能ID的条件
2. 职业条件 (Type=1 ID=1 V1=职业ID) → 与用户角色的ClassID比较
3. 角色ClassID由创建角色时的职业选择决定，存储在数据库
4. 如果 CLASS_STRING.LDT 不包含该职业ID，或映射关系错位 → 学习失败（没反应）

**2026-06-08 重要发现**：当前S4端 resource 目录下**没有 CLASS_STRING.LDT**！
怀旧端 D:\ROWID\DATA\LDT\CLASS_STRING.LDT 有职业映射数据。
可能GS读不到职业映射文件，导致任何职业条件判断都失败。
修复方案A：把怀旧端 CLASS_STRING.LDT 复制到当前端
修复方案B：修改 LEARN_SKILL 中所有 V1=1003 改为正确的职业ID

### SKILL.LDT 结构与SKILL.xls的关联

SKILL.xls 中没有显式的"职业限制"列。技能学不学得了依赖：
1. LEARN_SKILL.xls（Type=1 ID=1=职业限制, Type=1 ID=3=等级限制, Type=3 ID=2=前置技能）
2. SKILL.xls 的 _Learn_Skill=1（允许从NPC学习）
3. CLASS_STRING.LDT（职业ID→职业名映射，影响GS对职业ID的解析）

**GS实际判断流程**：
1. 用户点击NPC学技能 → GS查 LEARN_SKILL 中该技能ID的条件
2. 职业条件 (Type=1 ID=1 V1=职业ID) → 与用户角色的ClassID比较
3. 角色ClassID由创建角色时的职业选择决定，存储在数据库
4. 如果 CLASS_STRING.LDT 不包含该职业ID，或映射关系错位 → 学习失败（没反应）

## LEARN_SKILL.LDT 技能学习条件修复（2026-06-07）

LEARN_SKILL.LDT 定义学习技能时的学习名称、内容描述、习得提示、和错误提示。

**结构**：49列。第1行Type行，第2行列名，第3行起数据。
- col0=_ID（int32）
- col1=_Name（技能名称，type=1——注意是int型但存文本）
- col2~35=消耗/条件参数
- col36=_Description（点击"是"后可获得"XXX"）
- col37=_Message（"XXX" 习得）
- col38=_FX
- col39~40=_ErrorMessage_Ely/_ErrorMessage_Item
- col41~48=_ErrorMessage_Require1~8（等级不足、需要前置技能等错误提示）

**修复方式**：S4chd 国服端的 LEARN_SKILL.xls 本身就是完整的简体中文，直接复制整个文件覆盖。

**操作**：
```bash
cp "D:\\LaTale\\S4chd\\resource\\ROWID\\DATA\\XLS\\LEARN_SKILL.xls" "D:\\LaTale\\S4\\resource\\ROWID\\DATA\\XLS\\LEARN_SKILL.xls"
```

**路径**：
- S4: `D:\\LaTale\\S4\\resource\\ROWID\\DATA\\XLS\\LEARN_SKILL.xls`
- S4chd参考端: `D:\\LaTale\\S4chd\\resource\\ROWID\\DATA\\XLS\\LEARN_SKILL.xls`

### ⚠️ 坑
2026-06-07实测：之前用Python脚本`fix_learn_skill.py`替换了col1（_Name）共2591条，但用户发现col36~48（介绍和错误提示）仍然是乱码。**不要只局部替换Name列**——必须从S4chd整体复制整个文件。S4chd的LEARN_SKILL.xls本身是完整的简体中文版，所有49列都正确（Name列是十进制数字"纵膈横宇"等中文而非乱码）。

注意：S4chd的Name解码后显示为中文"纵膈横宇"等技能名，而S4原版的Name列是乱码如"�ݺ��޾�"——说明S4chd的LEARN_SKILL是干净数据源。直接复制即可，不需要逐列替换。

## NPC交易系统

完整的NPCTRADE系统（DETAIL定价→LIST分类→TRADE商品→NPC绑定）的链路图、文件结构、踩坑记录、精灵石上架进度全部在 **`latale-npctrade`** skill 中。这个skill只保留S2端LDT格式与S4端XLS格式的差异说明。

### LDT格式 vs XLS格式

S2怀旧端的NPCTRADE使用LDT二进制格式（需编辑器导出XLS编辑），S4端直接读写XLS文本文件。操作工具不同但链路一致。

### SKILL.xls

#### 核心发现
**Name 乱码** = 原始正确数据，GS 能认
**Name 中文** = 手动改坏，GS 报 `iSkillID not found`

同一技能种类的所有等级行共享同一个 Name 文本。

#### ⚠️ 致命坑：不要局部改 Name 列
Python `bytearray.replace()` 或任何逐列修改都会破坏整行格式。**必须按 ID 匹配、整行替换**。

#### 修复策略
从 SKILL2.xls 按 ID 取整行数据覆盖 SKILL.xls 对应行。

SKILL2.xls 路径：`D:\LaTale\彩虹岛S2\ROWID\DATA\XLS\SKILL2.xls`
当前 SKILL.xls 路径：`D:\LaTale\S4\resource\ROWID\DATA\XLS\SKILL.xls`

**流程**：
1. 用户给一个**种类代表 ID**（如 `3806404` 觉醒）
2. 查该 ID 的 Name 字节，找所有同 Name 行 → 得到该种类所有 ID
3. 从 SKILL2 按 ID 取整行，覆盖 SKILL.xls
4. 用户跑 GS 测试 → "pass"=继续下一批
5. 用户手动改中文，**记得提醒种类名**
6. 循环

**注意**：同一大类可能分多个子种类（觉醒50行 + 觉醒II 3行），需分别处理。必须全量找到该Name所有行，不能靠ID等间隔猜测。

**已替换的种类记录**见 `references/skill-row-replace-records.md`。

#### S4chd 国服参考端（2026-06-07 发现 + 验证）

`D:\\LaTale\\S4chd\\resource\\ROWID\\DATA\\XLS\\SKILL s4.xls` 是简体中文国服的正确 SKILL 数据文件，包含 **3937个ID**（S4端仅3555个）。

**优先级别**：S4chd国服 > SKILL2（S2端）> 手动。S4chd 是简体中文正版，优先用它覆盖。只有 S4chd 没有的 ID 才回退到 SKILL2 或手动。

**只替换 DisableDescription 列（col41）**：不要替换整行（否则会覆盖用户手动修好的 Name 和其他列可能已有的正确中文）。按 ID 匹配，只替换 DisableDescription 列（0-based col41）。

实操流程：
```python
# 1. 建S4chd ID→DisDesc字节映射
s4_disdesc = {}
with open(s4chd_path, 'rb') as f:
    for line in f.read().split(b'\\n')[2:]:
        if not line.strip(): continue
        parts = line.split(b'\\t')
        if len(parts) < 42: continue
        try: s4_disdesc[int(parts[0])] = parts[41]
        except: pass

# 2. 读当前SKILL.xls，按ID匹配替换col41
with open(skill_path, 'rb') as f:
    cur_lines = f.read().split(b'\\n')
for i in range(2, len(cur_lines)):
    line = cur_lines[i]
    parts = line.split(b'\\t')
    if len(parts) < 42: continue
    try:
        sid = int(parts[0])
        if sid in s4_disdesc:
            new_parts = parts[:41] + [s4_disdesc[sid]] + parts[42:]
            cur_lines[i] = b'\\t'.join(new_parts)
    except: continue
result = b'\\n'.join(cur_lines)
```

**效果验证**：S4chd 有的 ID 的 DisDesc 全部变成简体中文，用户手动改过的 Name 不受影响。剩余乱码仅限 S4chd 没有的 ID。

**修改后验证方法**：重新扫描 DisableDescription 是否还有乱码标记（`饭傈靛`、`胶懦`、`阿己`、`∝`、`⒀` 等）。扫描脚本方案：读 SKILL.xls → 取 col41（DisableDescription）→ GBK解码 → 搜乱码关键词。S4chd 有的 ID 会全部变成简体中文，如果没有变化说明 xls 没写回 LDT 或者 GS 缓存没清。

**残留乱码 ID 列表**（S4chd 没有，需手动修）：
1106036, 1109605, 7008572, 6600808, 3605615, 1211003, 1104003, 1105003, 1107100, 1107101, 1109303, 1105034, 1104035, 8003213, 8578579, 1104034, 1106035, 3103435, 8003212, 20213190

**Name 和 Description/DisableDescription 全部是正常简体中文**，是修复乱码的最佳参考源。不建议用整行覆盖（会冲掉用户手动修好的列）。

#### 原始乱码→应改中文对照（S4端 SKILL2 原始数据）

| 原始乱码（SKILL2） | 应改中文 | 代表ID | 行数 |
|---|---|---|---|
| `〖 阿己 〗` | 觉醒 | 3802404 | 50 |
| `〖 阿己 II 〗` | 觉醒 II | 3816404 | 4 |
| `〖 饭傈靛 〗` | 传奇 | 3802407 | 29 |
| `〖 饭傈靛 II 〗` | 传奇 II | 3816407 | 4 |
| `〖 积粮夯瓷 〗` | 生存本能 | 3812606 | 25 |

**⚠️ 注意**：这些乱码看似相似但实际上**每个种类的字节序列完全不同**，不能靠解码后的视觉判断归类。必须从 SKILL2 按 ID 取原始字节来确认。

**已替换的种类记录**见 `references/skill-row-replace-records.md`。

#### SKILL_USE 引用缺失 ID 时插入新行

GS 报 `SKILL_USE.LDT : FAILED ! Not Exist in Skill.LDT (iKey = XXX)` 时，说明该 ID 在 SKILL.xls 中不存在。

**修复步骤**：
1. 确认 SKILL2.xls（`D:\\\\LaTale\\\\彩虹岛S2\\\\ROWID\\\\DATA\\\\XLS\\\\SKILL2.xls`）中有该 ID
2. 找到该 ID 在 SKILL.xls 中的插入位置（按 ID 排序，找前后 ID）
3. 从 SKILL2 取整行数据插入到 SKILL.xls 的 `\\\\n` 分隔列表中
**例：8003213 插入在 9000001 之前，1109605 插入在 8000301 之前**

**尾部空列陷阱**：SKILL2.xls 每行末尾可能多一个 `\t`（空列），而当前 SKILL.xls 对应行可能没有。插入时整行字节直接插入即可（`\n` 分隔的字节列表 insert），Python 的 split/join 会保留尾部 tab。**不要用 strip() 或 rstrip() 处理行数据**。插完后验证行数 +2（2行头）与预期一致。

**批量扫描方案**（缺很多时）：一次性从 SKILL_USE.xls 提取所有引用 SkillID，对比 SKILL.xls 现有 ID 做差集，批量从 SKILL2 补入。S4端曾补入71个缺失ID，全部在 SKILL2 中找到。

**批量扫描脚本模式**：
```python
# 1. 读 SKILL.xls 的所有 ID
skill_ids = set()
for line in open('SKILL.xls', 'rb').read().split(b'\n')[2:]:
    if not line.strip(): continue
    try: skill_ids.add(int(line.split(b'\t')[0]))
    except: pass

# 2. 读 SKILL_USE.xls 的所有引用 SkillID（第2列）
use_ids = set()
for line in open('SKILL_USE.xls', 'rb').read().split(b'\n')[2:]:
    if not line.strip(): continue
    parts = line.split(b'\t')
    if len(parts) >= 3:
        try:
            ref_id = int(parts[2])
            if ref_id > 0: use_ids.add(ref_id)
        except: pass

# 3. 差集 = SKILL_USE 引用但 SKILL 没有的
missing = sorted(use_ids - skill_ids)

# 4. 从 SKILL2 逐行获取并插入
# （按ID排序，从后往前插入避免索引偏移）
```

SKILL_USE.xls 中 _SkillID 在第2列（0-based索引2），需要跳过头2行从第3行开始解析。提取后去重得到引用的 ID 集合。

**已替换的种类记录**见 `references/skill-row-replace-records.md`。

#### Description/DisableDescription 手动修改注意
用户自己手动改 Skill Name 从原始乱码回中文时，**Description 和 DisableDescription 的格式可能错乱**（位置没排列整齐）。用户偏好手动在彩虹岛编辑器中逐行排齐，不要用 Python 批量修。

常见的 Episode 文本格式参照（用户手工翻译经验）：
```
▲ 传奇技能 ▲\n\n "Episode 3. 在火山地带" 通关时自动学习
▲ 觉醒技能 ▲\n\n "Episode 4. 面倒" 通关时自动学习
▲ 生存本能 ▲\n\n "Episode 7. Epilogue" 通关时自动学习
```
注意：Episode 4 的真实中文名用户不确定（乱码显示为"面倒"可能是GBK错位），不要去查游戏资料——用户自己会决定。

#### ⚠️ 致命坑：不要用 Python 局部修改 Name/Description 列
2026-06-07验证：之前用 bytearray 把 `〖 积粮夯瓷 〗` 改为 `【 生存本能 】`（等长替换），GS 仍然报 `iSkillID not found`。**整行数据被 Python 的 split/join 破坏了**，不是 Name 文本的问题。

正确做法：从参考端（SKILL2）按 ID 取整行字节数据直接覆盖。

#### GBK 编码错位乱码推测
SKILL2.xls 中的某些文本（如 `饭傈靛`、`阿己`、`积粮夯瓷`、`鳖磨茄 肺瘤酒`）是 GBK 双字节编码偏移读取产生的结果。用户曾通过上下文推测：
- `〖 饭傈靛 〗` = 传奇
- `〖 阿己 〗` = 觉醒  
- `〖 积粮夯瓷 〗` = 生存本能
- `鳖磨茄 肺瘤酒` = ?（待查）
- `拳魂瘤措俊辑` = 在火山地带

这些正确的对应关系是用户人工辨认的，没有自动还原算法。

#### 格式保护原则
- 只改整行（按ID匹配），不改局部列
- 原始 GBK 编码保留不动
- 改前备份文件：`SKILL.xls.bak_{日期}_{用途}`

#### 跨端对比注意
不同版本的 SKILL.LDT ID 体系完全不同：
   - S4（他乡端）: 42列, 4853行, ID=8000301/1000015系列
   - 版本B（怀旧端）: 44列, 3268行, ID=3000217/7001131系列
   - 不能按行号对齐，也不能按ID匹配

SKILL2.xls（`D:\LaTale\彩虹岛S2\ROWID\DATA\XLS\SKILL2.xls`）和当前 S4 端同 ID 体系，可直接匹配。

### SKILL_CONTENT.LDT
- 列结构：_ID, _Description, _SubID, _Grid_Index, _Image_Setting, _SkillID
- col1=_Description是技能长描述，可能涉及多行文本
- 修复同SKILL.LDT：编辑器导出xls→改文本→写回
- D:\LaTale\彩虹岛S1\
- ITEM_1/2/3.LDT 109列，_Name是索引ID(type=1)非中文名
- 服务端exe 2016版
- configure.ini ResourceDir指向D:\S1彩虹岛\resource\
- **任务系统**：`QUEST.LDT` (126列大表) + `QUEST_REWARD.LDT` (33列×3028行)
  - QUEST_REWARD的33列格式与S2的QUEST_REWARD_1完全一致
  - S1任务奖励经验**普遍远低于S2**（没有20亿注入行，中位数经验仅1）
  - 详细对比见 `references/s1-vs-s2-tasks.md`

## xls导出规范
- _RowId作可见列放第1位(65列)
- 从2400起始
- 用xlwt(.xls)
- 已过滤基础发型
- 按套件分组，同系列异色合并
- _PositionIndex=CASH_SHOP商城排序序号
