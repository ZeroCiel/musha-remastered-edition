# MgmtServer "Division Failed!!!" 诊断记录（2026-05-25）

## 现象

S4CHD 的 MgmtServer.exe (582KB, 2025-10-13) 启动后在 `Bin2\Log\` 中无成功日志，
控制台输出 `GUILD infos loading... Division Failed!!!` 然后退出（或卡住不绑端口）。

## 诊断流程（本次会话验证的步骤）

### 步骤1：检查 SPF 文件存在性

GS 启动日志显示成功运行时需要加载：
- `D:\LaTale\S4chd\resource\AJJIYA.SPF` (SPF Version 2022091501)
- `D:\LaTale\S4chd\resource\ROWID.SPF` (SPF Version 0)
- `D:\LaTale\S4chd\resource\JINSSAGA.SPF` (SPF Version 2022100601)

如果 resource 目录为空 → 从 `客户端\` 目录复制所有 .SPF 文件过来。

### 步骤2：检查 SPF 是否包含需要的 LDT

ROWID.SPF 尾部包含文件列表，内含 `DATA/LDT/PVP_DIVISION.LDT`、`DATA/LDT/GUILD_MISSION.LDT` 等。
用以下方法验证：

```python
with open(spf_path, 'rb') as f:
    data = f.read()
idx = data.find(b'PVP_DIVISION')
# or
idx = data.find(b'GUILD_MISSION')
```

如果文件列表中没有这些 LDT → SPF 被裁剪过（他乡版特征）。

### 步骤3：检查进程状态

```cmd
tasklist | findstr Mgmt
netstat -ano | findstr 10001    # 或配置的 Mgmt 端口
```

- 进程活着 + 端口监听 = 正常启动
- 进程活着 + 端口不监听 = 初始化卡住（Division Failed 后可能卡死循环而非退出）
- 进程已退出 = 初始化失败后 exit(0) 或 return false

### 步骤4：检查日志文件

`Log\YYYYMMDD_LataleMgmtServer_1.log`

- 成功信号：应包含 `CLataleLoginServerApp::OnStartup(0)`（虽然类名写错，但表示初始化成功）
- 失败模式：只有 `COSPLogConnector is started` 和 `COSPLogThread::OnStartup`，无 OnStartup(0)
- 注意：日志类名写的是 `CLataleLoginServerApp` 而非 `CLataleMgmtServerApp`（编译时错打标签），不影响功能

## 已知的 Division 字符串位置（exe 逆向）

MgmtServer.exe (582KB) 内字符串位置：

```
"Division Failed!!! \n"   @ 0x73f81
"Guild Failed!!! \n"      @ 0x73f99
"MapEvent Failed!!! \n"   @ 0x73faf
"GUILD infos OK!!! \n"    @ 0x73fc2
"PVP infos OK!!! \n"      @ 0x73fd6
"GUILD infos loading..."  @ 0x73f68
"Press any Key to continue...." @ 0x79756
"DATA/LDT/GUILD_MISSION.LDT"    @ 0x73a59
```

Exe 的 Division 失败路径：
1. 加载 GUILD_MISSION.LDT（来自 SPF）
2. 检查 Division 数据 → 失败 → 输出 Division Failed!!!
3. 检查 Guild 数据 → （失败继续）→ 输出 Guild Failed!!!
4. 检查 MapEvent → 输出 MapEvent Failed!!!
5. 通过所有检查 → 输出 GUILD infos OK!!! + PVP infos OK!!!

## 之前能跑的环境（2026-05-25 凌晨 02:18-03:32）

- Mgmt/AS/Login/Lobby/Bay/Room/GS 全部成功启动
- 用户 Ciel 成功登录（日志有 `CHAR_CS_GETLIST :[Ciel]!=[123]`）

## 当前可能的原因

1. **SPF 版本不匹配** — 客户端 SPF 是给客户端用的，部分 LDT 结构可能不被 MgmtServer 期望
2. **exe 编译版本问题** — MgmtServer.exe 是 2025-10-13 版，可能需要特定小版本的 LDT 格式
3. **ROWID.SPF 中的 PVP_DIVISION.LDT 数据异常** — 内容问题而非文件缺失
