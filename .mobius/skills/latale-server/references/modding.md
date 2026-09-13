# 彩虹岛资源修改与本地化

## Extractor_Suite (exrpg.com)

**安装路径**：`C:\Program Files (x86)\exrpg.com\Bin32\Latale_Extractor.exe`

### 配置文件

`C:\Program Files (x86)\exrpg.com\Bin32\config.ini`：
```ini
[Latale_Extractor]
LastFilePath=D:\Server\SPF\ROWID.SPF      # 要打开的 SPF 文件
LastOutDir=D:\Server\SPF\extracted        # 提取输出目录
AutoTranslate=False                       # 自动翻译（繁→简？）
ListItemSplit=True
```

### 支持的文件类型

工具声明支持：`PNG, MP3, WAV, LDT` 文件提取。

- LDT 文件是游戏的**数据表**载体（物品、技能、NPC、UI文字等）
- PNG 是图片资源
- MP3/WAV 是音频

### GUI 操作流程

1. 菜单 **「资源(R)」→「提取全部资源(E)」** — 解包所有文件
2. 菜单 **「资源(R)」→「提取所选资源(A)」** — 选择性解包
3. 支持按 ID 搜索、按值搜索

### 语言

工具自带多语言支持（Language/Latale_Extractor/ 目录）：
- `2052.ini` — 简体中文
- `1028.ini` — 繁体中文
- `1033.ini` — 英文

## SPF 文件格式

来自 `LaTaleServer-` 源码 (`SPResourceBaseDEF.h`)：

```c
#define MAX_RES_NAME 128

struct FINFO {
    char szFileName[MAX_RES_NAME];  // 文件名 (128 bytes)
    int  iOffset;                   // 文件偏移
    int  iSize;                     // 文件大小
    RESID ResID;                    // 资源 ID
};

struct F_SPF_HEADER {
    int  iHeaderSize;               // 头部大小
    int  iFileID;                   // 文件 ID
    char* szDesc[32];              // 32 个描述字符串
};
```

**注意**：SPF 文件头的前 4 字节为 `00 00 00 00`，紧接着是文件计数和索引表。

## LaTaleServer- 源码仓库

GitHub: `https://github.com/Zxblll843192/LaTaleServer-`

本地克隆: `D:\LaTaleServer-\`

### 仓库结构

| 目录 | 内容 |
|---|---|
| `Common/` | 公共工具库（压缩、连接器、日志） |
| `LataleAS/`, `LataleGameServer/`, etc. | 各服务器 VS 工程 |
| `LataleMapLoader/` | **SPF 读取代码**（SPResourceBase, SPStream） |
| `include/` | 头文件（SPFXDEF.h 等） |
| `tool/` | 辅助工具源码 |
| `tool/Tool_UploadLDT/` | **LDT 上传/编辑工具**（MFC GUI） |

### 关键文件

| 文件 | 内容 |
|---|---|
| `LataleMapLoader/SPResourceBaseDEF.h` | SPF 文件头格式定义 |
| `LataleMapLoader/SPResourceBase.h` | SPF 资源管理器 |
| `LataleMapLoader/SPStream.h` | SPFileStream 文件读取 |
| `include/SPFXDEF.h` | SPFX 特效系统定义 |

## 繁→简本地化路线

```
SPF 解包 → 得 LDT 文本表 → OpenCC 转换 → 重新打包
```

### 步骤

1. **解包**：用 Extractor_Suite 打开 SPF → 提取全部资源 → 得 LDT 文件
2. **找文本表**：搜索包含中文的 LDT（STRING.LDT, ITEM_*.LDT 等）
3. **转换**：用 OpenCC（开放中文转换）批量繁→简
4. **打包**：用 Extractor_Suite 或自写工具重新打包 SPF

### 已知限制

- S2 客户端仅内置 TAIWAN（繁中）资源，不支持 CHINA locale
- 修改后需要验证客户端版本校验通过（LoginServer 已设 `SkipVersionCheck=1`）
- 部分文本在图片中（需单独处理）

## Troubleshooting

| 现象 | 原因 | 解决 |
|---|---|---|
| SPF 提取时崩溃 | SPF 版本不匹配 | 尝试不同 SPF 文件 |
| LDT 文件乱码 | 编码问题 | LDT 通常为 UTF-16 或 ANSI |
| 重新打包后客户端不认 | SPF 校验码变化 | 关闭版本校验或重新计算 hash |
