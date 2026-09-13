# 彩虹岛 SPF/LDT 本地化

## 工具矩阵

| 工具 | 路径/来源 | 用途 | 优势 |
|---|---|---|---|
| **LaTaleTools** ★ | `https://github.com/thyjack/LaTaleTools` (.NET 9/F#) | SPF/LDT/TBL 提取 + Web 预览 | 直读 SPF、Web 界面浏览内容、现代代码 |
| Extractor_Suite | `C:\Program Files (x86)\exrpg.com\Bin32\Latale_Extractor.exe` | SPF → PNG/MP3/WAV/LDT 提取 | GUI 操作简单 |
| ldt_tool.py | 本地脚本 | LDT 解析/扫描/文本抽样 | Python，可编程 |
| LaTaleServer- 源码 | `D:\LaTaleServer-\` (clone from Zxblll843192) | LDT/SPF 格式参考 | 含 Tool_UploadLDT |

### Extractor_Suite 操作
- 菜单：「资源(R)」→「提取全部资源(E)」
- 配置：`C:\Program Files (x86)\exrpg.com\Bin32\config.ini`（可预设 LastFilePath/LastOutDir）
- 语言文件：`Language\Latale_Extractor\2052.ini`（简中 UI）
- 桌面快捷方式：`Latale Extractor.lnk`

### LaTaleTools 操作
```bash
git clone https://github.com/thyjack/LaTaleTools.git
cd LaTaleTools
# 配置 LaTaleBinaryPath 指向 SPF 目录
dotnet user-secrets set LaTaleBinaryPath "D:\Server\SPF"
dotnet run --project LaTaleTools.WebApp
# 浏览器打开 http://localhost:5126
```

## LDT 格式

### 文件头 (8716 bytes)
```
Header {
    i32 DB_ID              // offset 0
    i32 nFields            // offset 4
    i32 nData              // offset 8
    byte[8192] FieldNames  // offset 12, 128×64B null-padded
    i32[128] FieldTypes    // offset 8204
}
```

### 字段类型
| 值 | 名称 | 存储 | 说明 |
|---|---|---|---|
| 0 | NA | i32 | 空 |
| 1 | String | null-term byte[] | ★ 文本字段 |
| 2 | TF | i32 | 布尔 |
| 3 | Num | i32 | 整数 |
| 4 | Per | f32 | 浮点 |
| 5 | FID | i32 | 文件 ID |
| 6 | Alias | i32 | 别名 |
| 7 | Num64 | i64 | 64位 |
| 255 | PrimaryKey | i32 | 主键 |

### ⚠️ 文本编码：GBK
LDT 中 String 字段使用 **GBK/GB18030 编码**（不是 UTF-8！）。
```
UTF-8: "սʿ"  →  GBK: "战士"  ✓
```

### 关键文本 LDT
| 文件 | 行数 | 内容 |
|---|---|---|
| `GLOBAL_STRING.LDT` | 3500 | ★ UI文字、系统提示、职业描述 |
| `GLOBAL_MOB.LDT` | 7295 | 怪物名（15个文本字段） |
| `CLASS_STRING.LDT` | ? | 职业名 |
| `HELP.LDT` / `HELP_CONTENT.LDT` | 185/214 | 帮助文本 |
| `GUIDE_BOOK.LDT` | 1825 | 指南 |
| `INDUN_MISSION.LDT` | 1500 | 副本任务 |

## SPF 格式

```c
F_SPF_HEADER { i32 iHeaderSize; i32 iFileID; char* szDesc[32]; }
FINFO { char szFileName[128]; i32 iOffset; i32 iSize; RESID ResID; }
```
源码参考：`LataleMapLoader/SPResourceBaseDEF.h`

## 当前 S2 客户端

- 路径：`D:\彩虹岛\彩虹岛S2\`
- 启动：`_单机登陆-爱游网单整理.bat` → `/LOCALE:TAIWAN /PUBLISHER:GAMEFLIER`
- IP：`IP.ini` → `127.0.0.1`
- LDT 文本已是 GBK 简中（私服翻译），**不需 Trad→Simp 字形转换**
- `/LOCALE:CHINA /PUBLISHER:SHANDA` 不可用（客户端缺 CHINA 资源包）

## 台服↔国服命名差异（核心问题）

不仅是字形，而是**语义/命名体系完全不同**：
| 台服 | 国服 |
|---|---|
| 耶比妹妹 | 龙猫妹妹 |
| （待对比） | （待对比） |

## FontLink 注册表方案（VMProtect 加壳客户端字体修复）

LaTale S2 客户端（`LaTaleClient.exe`）是 **VMProtect 加壳**的，无法通过直接修改 exe 二进制来替换字体名或 UI 字符串。所有代码段在运行时解密，静态修改无效。

**适用范围**：此方案仅修复**字体渲染**（让系统用正确字体显示繁体/简中字符），不改变文本内容本身。LDT 中的韩文编码字符串仍需通过 LDT 编辑来翻译。

### FontLink 原理

Windows FontLink 是一个注册表机制：当系统尝试用字体 A 渲染文本时，如果 A 缺少某个 glyph，会按注册表定义的 fallback 链查找字体 B、C……的 glyph。

```powershell
$path = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\FontLink\SystemLink"
$fonts = @("Gulim", "Dotum", "Batang", "Gungsuh", "Tahoma", "Microsoft Sans Serif", "Arial")
$value = @("msyh.ttc,Microsoft YaHei", "simsun.ttc,SimSun")

foreach ($font in $fonts) {
    New-ItemProperty -Path $path -Name $font -PropertyType MultiString -Value $value -Force
}
```

### 前提条件

- 系统中已安装 `msyh.ttc`（微软雅黑）和 `simsun.ttc`（宋体）——Win10/11 默认包含
- 需要**重启游戏客户端**才能生效（无需重启系统）
- 注册表写入需要管理员权限

### 局限

- 只影响 glyph 回退，不影响布局或编码
- 游戏仍使用韩文编码（EUC-KR）的逻辑来测量文字宽度，简中字符的宽度/间距可能不准
- 文本内容（物品名、描述等）本身若存储为韩文，不会自动变成中文

### 替代方案：DLL 注入 Hook

如果 FontLink 效果不够好（例如需要拦截 `CreateFontW` 统一替换字体名，或拦截 `TextOutW` 做编码转换），需要写原生 C/C++ DLL 进行 API Hook：

| 目标函数 | 作用 |
|----------|------|
| `CreateFontW`/`CreateFontA` | 替换字体名（Gulim→Microsoft YaHei） |
| `CreateFontIndirectW/A` | 同上 |
| `TextOutW`/`DrawTextW` | 字符编码转换 |
| `GetTextMetricsW` | 修正文字度量 |

工作量：约 1-2 天（含 DLL 编写、注入器、调试）。

## 国服文本替换路线

1. 下载国服盛大客户端
2. Extractor_Suite 或 LaTaleTools 提取国服 SPF → LDT
3. `ldt_tool.py` 对比两套 LDT 文本字段
4. 建立台↔国命名映射表（可能需要逐 ID 对应）— ⚠️ **国服 S4 与台服 S2 的 ItemID 不同**，不能简单用 ID 匹配
5. 选择性替换（保留私服专属内容）
6. SPF 重新打包（待研究）
7. 游戏内验证

### ⚠️ 已知限制

- 国服 S4 和台服 S2 的 ItemID 体系不同，同一个物品在两个版本中可能有不同的 ID 编号
- CASH_SHOP.LDT 的列结构也不同（国服 71 列 vs 台服 65 列），不能直接替换文件
- 机器翻译（韩→简中）质量很差，游戏术语（如"凯尔/守护/光明"等）完全译不准

## 区服改名

游戏内显示的服务器名称存储在 `dbLataleAccount.dbo.tblsWorldList` 表：
```sql
UPDATE tblsWorldList SET name='梦境' WHERE wid=1
-- 列: wid, name, lobbySID, ip, port, enable, sortIndex
```
修改后重启网关生效。
