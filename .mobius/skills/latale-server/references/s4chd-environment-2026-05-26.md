# S4CHD 环境记录（2026-05-26）

## 来源

用户2026-05-26从B站"解密3000"或相关渠道获取。作者出售S4源码（99元），但当前拿到的似乎是已编译的服务端+客户端包，非源码。

## 目录：D:\LaTale\S4chd\

### bin2/ 服务端exe

| 文件 | 大小 | 日期 | 备注 |
|------|------|------|------|
| LataleMgmtServer.exe | 582KB | 2025-10-13 | |
| LataleAS.exe | 343KB | 2025-08-05 | |
| LataleLoginServer.exe | 264KB | 2023-04-11 | 版本较早，留意兼容性 |
| LataleLobbyServer.exe | 317KB | 2025-10-13 | |
| LataleBayServer.exe | 318KB | 2025-02-24 | |
| LataleRoomServer.exe | 355KB | 2024-08-24 | |
| LataleGameServer.exe | 4.17MB | 2025-10-17 | 单个exe，不是_101版本 |
| LataleToolServer.exe | 497KB | 2025-10-13 | |
| LaS4服务端.exe | 3.6MB | 2026-05-24 | 一键启动版，可能集成所有服务 |

### configure.ini 路径修正

原始路径 `D:\S4chd\resource\` → 应改为 `D:\LaTale\S4chd\resource\`。

共6处，分布在不同的服务端段中（GS_1026、GS_1027、GS_1152、Lobby、Mgmt、Room）。

### resource/ 目录

**当前为空** — 没有SPF文件，也没有解包的DATA/LDT目录。

需要从 客户端 目录复制SPF文件过来，或修改configure.ini中的ResourceDir指向客户端目录。

### 客户端SPF

| SPF | 大小 | 备注 |
|-----|------|------|
| ROWID.SPF | 148MB | 文本数据、字符串 |
| BARY.SPF | 614MB | UI、接口 |
| MAKO1298.SPF | 523MB | |
| METALGENI.SPF | 492MB | |
| ZENNE.SPF | 345MB | |
| RYUMS.SPF | 678MB | |
| HOSHIM.SPF | 475MB | |
| DALBONG.SPG | 870MB | 最大包 |
| AJJIYA.SPF | 161MB | |
| BANX.SPF | 185MB | |
| CLAIRE.SPF | 32MB | 声音包 |
| CVOICE.SPF | 25MB | 语音包 |
| JINSSAGA.SPF | 65MB | |

### 工具

- 解包-打包.EXE（375KB, 2024-11-27） — 界面是中文，可能有打包功能。不同于SFP v1.6。
- LDT修改器.exe（602KB, 2025-04-25） — 图形化LDT编辑器，可直接打开修改LDT文件。

### 启动计划（待执行）

1. 修正configure.ini路径
2. 准备SPF资源（复制或解包）
3. 启动顺序同S2：Mgmt → AS → Login → Lobby → Bay → Room → GS
4. 测试客户端能否登录

### 与S2他乡版的差异

| 方面 | S2他乡 | S4CHD |
|------|--------|-------|
| 版本 | Season 2 | Season 4 |
| exe来源 | 2017第三方修改版 | 可能是近期编译版 |
| SPF加密 | 有（他乡魔改校验） | 未知 |
| 打包工具 | SFP v1.6（打包灰色） | 解包-打包.EXE（待验证） |
| 附带工具 | 无 | LDT修改器.exe + 解包-打包.EXE |

### Division Failed 诊断

2026-05-25 发现 MgmtServer 启动时报 `Division Failed!!!` 退出。
完整诊断流程和 exe 字符串偏移见 `references/division-failed-diagnosis-2026-05-25.md`。

**一句话诊断**：先确认 resource 目录下有 SPF 文件（从客户端/复制过来），再检查进程端口绑定。
即使 resource 有 SPF，如果 ROWID.SPF 内的 PVP_DIVISION.LDT 数据异常，Division 仍可能失败。
