# SPF/SDF/LDT 加密问题澄清

## 核心结论：编译版服务端使用的 SPF/LDT **没有加密**

源码确认：
- `SPLDTFile::LoadLDTFile()` (`LataleMapLoader/SPLDTFile.cpp`) — **纯二进制读取**。读 Header → 字段标签 → 数据行，0行解密/解密/CRC校验代码。
- `SPResourceBase::Init()` (`LataleMapLoader/SPResourceBase.cpp`) — 打开 SPF 文件，从尾部往前读版本号、Header、目录条目。纯读取，无加解密。
- `FINFO` 结构体：`char szFileName[128]` + `int iOffset` + `int iSize` + `RESID ResID` — 无加密字段。

**所以：你从源码（VS2013）编译出来的任何服务端 exe，读取的都是标准无加密 SPF/LDT。** 直接用 LaTaleTools 或任意标准 SPF 解包器打包的文件，编译版都能认。

## 混淆来源：他乡作者的 SPF 加密

### 加密只影响他乡 exe，不影响编译版

他乡作者（B站"解密3000"）同时卖两样东西：
1. **他乡私服服务端 exe**（他乡编译版，VMProtect 加壳）
2. **SPF 加密服务**（把标准 SPF 打乱/打残/超级加密）

他加密 SPF 的目的：让买家不能把端拿走改内容自己开。

**加密原理**：不是改了 SPF 格式本身，而是在他乡 exe 里加了自定义的校验/解密逻辑。标准 SPF 读取代码不认识加密后的 SPF 文件格式，所以编译版读加密 SPF 会崩。

**反过来的推论**：他的解包工具（`SFP解包打包v1.6.exe`、`今昔破解版.exe`，在 `D:\Backup\Documents\`）能解密他加密的 SPF，但**重打包后他服务端 exe 认不认取决于他的 exe 有没有重打包校验**。

### 工具文件详情

| 文件 | 大小 | 日期 | 类型 |
|------|------|------|------|
| `SFP解包打包v1.6.exe` | 1.24MB | 2019-04-07 | PE32 GUI (Delphi/MFC) |
| `今昔破解版.exe` | 1.45MB | 2017-06-08 | PE32 GUI |
| `今昔破解补丁.exe` | 696KB | 2017-06-08 | PE32 GUI |
| `LDT及SFP工具.zip` | 2.6MB | 2026-01-17 | 含LDT作用.xls + LDT破解版.zip + SFP解包打包v1.6.rar + 图解 |

位置：`D:\Backup\Documents\` 和 `D:\Backup\Downloads\LDT及SFP工具.zip`

**补丁包结构**：
- `LDT及SFP工具.zip\SFP解包打包v1.6.rar` — 解包工具本体
- `LDT及SFP工具.zip\LDT破解版.zip` — LDT 编辑工具
- `LDT及SFP工具.zip\LDT作用.xls` — LDT 文件功能说明表
- `LDT及SFP工具.zip\*.jpg` — 图解（宝石位置、战斗装备、现金装备等）

## ID 序号跨版本问题

不同地区版本的 LDT（台服/韩服/日服/国服）中，道具 ID、地图 ID、任务 ID 的数值**可能不同**。

**但这对服务端启动没有影响**——原因：
- 服务端启动时只是**加载 LDT 文件到内存**，把每行的 ID 作为 key 存起来
- ID 的范围/值不影响加载本身，只要 LDT 格式正确（字段数对齐、类型匹配、行数据无越界）
- ID 不匹配会导致的是**运行时数据不一致**（客户端问"道具10001"，服务端说"没有"），而不是服务端启动崩溃

**真正的崩溃风险**：
1. LDT 格式不匹配（字段数/类型不同）→ 解析时内存越界或 assert 失败
2. LDT 间有交叉引用（item 引用 monster 表的 ID），加载顺序不对时出现空指针
3. 他乡 exe 可能 SKIP 某些错误 LDT，编译版严格解析

## 实践结论：不用管加密，直接编编译版

1. 编译版服务端（Mgmt/Login/Lobby/AS/Bay/Room/GS）全部从 VS2013 源码编译
2. 用标准 SPF 工具打包（LaTaleTools 或任何不加密的打包器）
3. LDT 文本修改：用 Python 直接读写二进制 LDT，只改字符串字段不改变字段数/类型
4. 无需处理 SPF 加密问题——编译版不认识加密格式，也不需要它
