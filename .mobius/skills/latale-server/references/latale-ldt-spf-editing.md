# Latale LDT/SPF Resource Editing

## CASH_SHOP.LDT 二进制记录结构 (S2 他乡/Server2 版本)

S2 他乡/Server2 的 CASH_SHOP.LDT 不是标准列类型LDT格式，而是**270字节固定长度二进制记录格式**。

### 文件头
```
Offset 0x00: uint32 (0)
Offset 0x04: uint32 field_name_padding_size (通常 0x40=64)
Offset 0x08: uint32 field_count (S2他乡: 4143)
```
字段名从 offset 12 开始，每个字段名填充到 field_name_padding_size 字节。
字段名按顺序对应记录的每个字段。
数据区从 `12 + field_count × field_name_padding_size` 开始。
S2他乡Server2：header_size = 12 + 4143 × 64 = 265164，data_start = 429197（header后有额外padding）。

### 记录结构 (270 bytes fixed)

每条记录270字节，结构如下：

**前置固定字段 (24 bytes = 6 × 4-byte int32 LE):**

| 偏移 | 字段 | 示例(暖呼呼粉嫩大衣) |
|------|------|---------------------|
| 0-3 | `_CategoryView` | 1709 |
| 4-7 | `_CategoryIndex` | 1 |
| 8-11 | `_CategoryIndex2` | 7 |
| 12-15 | `_PositionIndex` | 22 |
| 16-19 | `_Suggest` | 0 (排序/推荐序号) |
| 20-23 | `_EventType` | 991708 |

**字符串字段:**
| 偏移 | 字段 | 格式 |
|------|------|------|
| 24-25 | name_len | uint16 LE |
| 26... | `_Name` | GBK编码，长度由前2字节指定 |
| after_name+padding | desc_len | uint16 LE (通常是0) |
| ... | `_Description` | 同格式 |
| ... | iconfile_len | uint16 LE |
| ... | `_IconFile` | 同格式 |

**定长字段 (后续全部4字节 int32 LE):**
然后是固定字段序列（~59个×4=236字节），完整字段名见文件头。

**关键字段:**
- `_IconIndex` — 图标索引
- `_Gender` — 性别限制
- `_PriceType` — 货币类型 (0=金币? 1=点券?)
- `_CashPrice` — 点券价格
- `_SalePrice` — 折扣价
- `_ItemID1~8` — 道具ID（最多8个一组，分别对应ItemCount1~8）
- `_ItemRare1~8` — 强化等级
- `_ItemCount1~8` — 数量
- `_PriceRate1~8` — 价格倍率
- `_ClassID` — 职业限制
- `_MotionID` — 动作ID
- `_Buy_Disable` / `_Give_Disable` — 购买/赠送限制
- `_Limited_Time_Type` — 限时类型
- `_Cap_Point` / `_Cap_Check` — 上限
- `_World_Amount` — 世界总量

### Python 解析示例
```python
import struct

s2_path = "D:\\LaTale\\Server2\\ROWID\\DATA\\LDT\\CASH_SHOP.LDT"
with open(s2_path, "rb") as f:
    s2 = f.read()

header_size = 12 + 4143 * 64
data_start = 429197  # S2他乡Server2 实际数据起始偏移
rec_size = 270

# 按名称查找记录
idx = s2.find("暖呼呼粉嫩大衣".encode('gbk'))
rec_start = data_start + ((idx - 26 - data_start) // rec_size) * rec_size
rec = s2[rec_start:rec_start + rec_size]

# 解析前置字段
cv = struct.unpack('<I', rec[0:4])[0]   # _CategoryView
ci = struct.unpack('<I', rec[4:8])[0]   # _CategoryIndex
sg = struct.unpack('<I', rec[16:20])[0] # _Suggest

# 解析名称
name_len = struct.unpack('<H', rec[24:26])[0]
name = rec[26:26+name_len].decode('gbk')
```

### 字段值对照表 (竖线分隔格式)
如果用户用竖线分隔的数据呈现，顺序为（参考暖呼呼粉嫩大衣）：
```
1709|1|7|22|0|991708|1|暖呼呼粉嫩大衣||10001212|200|0|1|88|0|1|51776811|1|1|1|0|1|0|0|0|1|0|0|0|1|0|0|0|1|0|0|0|1|0|0|0|1|0|0|0|1|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|1|1|0|
```
对应关系：_CategoryView | _CategoryIndex | _CategoryIndex2 | _PositionIndex | _Suggest | _EventType | _Name | _Description | _IconIndex | _Gender | _PriceType | _CashPrice | _SalePrice | _EventIcon | _ItemID1 | _ItemRare1 | _ItemCount1 | _PriceRate1 | _ItemID2 | _ItemRare2 | _ItemCount2 | _PriceRate2 | ...

注意：`_ItemID1` 的值（1709）和 `_CategoryView` 的值相同是巧合。第一个 ItemID 就是 1709，第二个是 51776811。

### S4chd vs S2 格式差异
S4chd (99元端) 的 CASH_SHOP.LDT 文件格式不同：
- 文件头 field_size=68, field_count=4309
- 记录格式可能不同（需要逆向分析）
- S4chd 的数据不直接从 header_end 开始，中间有额外padding

## 时装贴图位置

彩虹岛的时装/装备贴图分布在 SPF 包的 `CHARLAYER` 目录下（客户端 SPF 包内部），包含：
- 时装（服装、外套、帽子、手套、鞋子等）
- 脸型
- 皮肤
- 发型

SPF 包对应关系：
- `BARY.SPF` — 巴里大陆（含大量时装贴图）
- `ZENNE.SPF` / `RYUMS.SPF` / `MAKO1298.SPF` — 也包含 CHARLAYER 内容

解包后，贴图通常在 `CHARLAYER/` 子目录下。特定道具贴图通过 ItemID 关联。
注意：单机版 `D:\彩虹岛单机` 使用的是 SPF 打包模式（pack=1），所有 CHARLAYER 内容在 SPF 包里封着。可以用 `SFP解包打包v1.6.exe` 或 `今昔破解版.exe` 解包查看。

## 跨端EXE替换启动流程

当要把A端的服务端exe搬到B端运行时：

### 步骤
1. **比较目录结构** — 确认两个端的 bin2/ 目录结构
2. **复制exe** — 只复制A端的核心exe（MgmtServer, LoginServer, AS, LobbyServer, BayServer, RoomServer, GameServer）
3. **修 configure.ini** — 所有 `ResourceDir` 路径指向B端的实际资源位置
4. **修 Global_ODBC.ini** — 确认数据库连接字符串（端口、数据库名）指向正确的SQL实例
5. **启动测试** — 按顺序启动：Mgmt→AS→Login→Lobby→Bay→Room→GS
6. **监控日志** — 检查各服务启动日志中的错误

### 常见问题
- **Port冲突** — A端和B端可能用不同端口（如Login: 19999 vs 20200）
- **pack模式不一致** — A端pack=1但B端用pack=0，反之亦然。需要统一
- **CHDS保护** — 如果A端exe有CHDS壳，直接搬过去会退出。需要用无壳版本
- **exe版本号不匹配** — VS2005编译exe不能直接替换VS2013编译的配置体系

## LDT File Format

Based on `LaTaleTools.Library.Ldt.fs` reverse-engineering:

### Header (first 12+ bytes)
```
Offset 0x00: uint32 magic (usually 0)
Offset 0x04: uint32 columnCount = raw + 1  (includes virtual _RowId)
Offset 0x08: uint32 rowCount
```

### Column Names
Start at offset 12, each entry is 64 bytes fixed-width, null-terminated UTF-8 string.
Number of entries = columnCount - 1 (excluding virtual _RowId).

### Column Types
Start at offset 8204, each entry is 4 bytes (int32).
Types: 0=Unsigned, 1=String, 2=Bool, 3=Signed, 4=Float

### Row Data
Start at offset 8716 (0x220C).

Each cell is read sequentially per column:
- **Unsigned (0)**: 4 bytes LE uint32
- **Signed (3)**: 4 bytes LE int32
- **Bool (2)**: 4 bytes LE int32 (0/1)
- **Float (4)**: 4 bytes LE float32
- **String (1)**: 2 bytes LE string length + string data (EUC-KR for Korean/S2, GBK for guofu/S4)

### Reading LDT in Python

```python
import struct

with open('file.LDT', 'rb') as f:
    data = f.read()

col_count = struct.unpack('<I', data[4:8])[0] + 1
row_count = struct.unpack('<I', data[8:12])[0]

# Column types
col_types = []
for n in range(col_count - 1):
    t = struct.unpack('<I', data[8204 + n * 4:8204 + n * 4 + 4])[0]
    col_types.append(t)

# Read rows
data_start = 8716
pos = data_start
for row_idx in range(row_count):
    for col_idx in range(col_count):
        ct = col_types[col_idx - 1] if col_idx > 0 else 3
        if col_idx == 0:  # _RowId
            val = struct.unpack('<i', data[pos:pos+4])[0]
            pos += 4
        elif ct == 1:  # Str
            str_len = struct.unpack('<H', data[pos:pos+2])[0]
            val = data[pos+2:pos+2+str_len].decode('euc-kr', errors='replace')
            pos += 2 + str_len
        elif ct in (0, 2, 3):  # U32/Bool/S32
            val = struct.unpack('<i', data[pos:pos+4])[0]
            pos += 4
        elif ct == 4:  # Float
            val = struct.unpack('<f', data[pos:pos+4])[0]
            pos += 4
```

## CASH_SHOP.LDT Editing

Key columns for shop management:
- `_CategoryView` (Bool, col 1): 0=hidden, 1=visible. Set to 1 to enable items.
- `_CategoryIndex` (S32, col 2): Category tab ID.
- `_Name` (Str, col 7): Display name (Korean EUC-KR or GBK).
- `_CashPrice` (S32, col 13): Cash price.
- `_SalePrice` (S32, col 14): Sale price.
- `_ItemID1..8` (S32, cols 16,20,24...): Item IDs bundled in this product.
- `_ItemCount1..8` (S32, cols 18,22,26...): Quantity per item.

### Batch-Enable All Hidden Items
```python
# Parse all rows, find CategoryView=0, set to 1
# Then repack into SPF (see SPF Repacking section)
```

Categories observed in S2:
- Cat 1: Recommended/New (1922 items)
- Cat 2: Decoration/Style (39 items)
- Cat 3: Hairstyles (33 items)
- Cat 6: Outfit Sets (256 items)
- Cat 7: Weapons (1893 items)

## Commercial SPF Tools (Author-Encrypted SPFs)

### Background: The "Decrypt 3000" Author

The hexiang (他乡) S2 server suite at `D:\Server\` uses SPF files that have been **encrypted/modified by a third-party author** associated with the "解密3000" (Decrypt 3000) tool, who also posted Bilibili tutorials about SPF encryption.

Key characteristics of these modified SPFs:
- **"加密" (Encryption)**: Non-standard SPF format. Standard tools (LaTaleTools, SPF unpackers) cannot open them
- **"打残" (Crippling)**: Even if decrypted, LDT internal ID order is shuffled to prevent direct use
- **"打乱" (Scrambling)**: EFFID/item/enhancement tables have randomized ordering
- **"超级加密" (Super Encryption)**: Removes client-unnecessary LDTs from ROWID.SPF to shrink file size. Hexiang ROWID.SPF: ~150MB vs standard S4: ~310MB

### Available Tools on This Machine

Located at `D:\Backup\Documents\`:

| Tool | Size | Date | Description |
|------|------|------|-------------|
| SFP解包打包v1.6.exe | 1.2MB | 2019-04-07 | SPF unpack/repack tool (GUI, MFC-based) |
| 今昔破解版.exe | 1.4MB | 2017-06-08 | Cracked version of author's tool |
| 今昔破解补丁.exe | 696KB | 2017-06-08 | Crack patch companion |

Also at `D:\Backup\Downloads\LDT及SFP工具.zip` (2.6MB, 2026-01-17):
- LDT破解版.zip — Separate LDT editing tool
- LDT作用.xls — LDT field/column documentation spreadsheet
- SFP解包打包v1.6.rar — Same tool in RAR archive
- Multiple JPG reference images for gem positions, equipment slots, cash shop layout

### Compatibility Rule: Use Author's Tools for Author's SPFs

The **most important rule**: If the SPF was encrypted by Author X, you MUST use Author X's tool to unpack and repack it. Mixing tools (e.g., author tool unpack → standard tool repack) breaks the encryption wrapper, causing the server EXE to reject the file.

**Expected behavior when using author's own tools:**
1. **Unpack** with SFP解包打包v1.6.exe → extracts all LDT files
2. **Edit** LDT files with appropriate editor (see LDT section)
3. **Repack** with the same tool → produces a SPF matching original encryption
4. The server EXE should accept the repacked SPF **IF** the file index/version header is preserved

**Pitfall**: Even with the author's tool, there's no guarantee it preserves the exact binary structure. The hexiang server EXEs (CHDS.dll + VMProtect) may also perform runtime integrity checks on the SPF directory. If a tool update changed something, the server may still reject it. Always **test on a backup copy** first.

### If Author's Tools Fail

If the packed SPF still causes the server to reject it:
1. **Restore original SPF backup** (keep .bak copies)
2. Stick with **pack=1 mode** (SPF archive) — don't switch to pack=0 with extracted files
3. For text changes, use **SPF-level replacement** (see SPF Archive Format below) to swap individual LDTs within the original SPF structure
4. As a last resort, **FontLink registry** (see Font Configuration section) can make the client display Chinese characters without modifying any game files

## SPF Archive Format

Based on `LaTaleTools.Library.Spf.fs`:

### File Entry (140 bytes)
```
1 byte:  type (0x03 for regular files)
128 bytes: path (null-terminated, EUC-KR)
4 bytes:  content_position (uint32 LE, offset in file)
4 bytes:  content_size (uint32 LE)
4 bytes:  index (uint32 LE)
```

### Directory Location
The directory entries are stored at the end of the SPF file.
Each entry is 140 bytes. The directory grows backward from the end.
The first entry (lowest position) has content_position=0 as a sentinel.

### Replacing a File In-Place (same size)
```python
idx = spf_data.find(b'\x03' + b'DATA/LDT/CASH_SHOP.LDT')
content_pos = struct.unpack('<I', spf_data[idx+129:idx+133])[0]
content_size = struct.unpack('<I', spf_data[idx+133:idx+137])[0]
spf_data[content_pos:content_pos+content_size] = new_data
```

Only works when new_data size == content_size.

### Replacing a File With Size Change (append + remap)

When file sizes differ (e.g., replacing S2 GLOBAL_STRING.LDT 110KB → 300KB guofu version), do NOT try in-place. Instead:

1. **Zero out old data** (optional — keeps file clean for debugging)
2. **Append new data** to end of SPF
3. **Update directory entry** to point to new position + new size

```python
import struct, re

with open('ROWID.SPF', 'rb') as f:
    spf = bytearray(f.read())

# Find entry
search = b'\x03DATA/LDT/GLOBAL_STRING.LDT'
idx = spf.find(search)

# Read old metadata
old_pos = struct.unpack('<I', spf[idx+129:idx+133])[0]
old_size = struct.unpack('<I', spf[idx+133:idx+137])[0]

# Zero old data (optional)
spf[old_pos:old_pos+old_size] = b'\x00' * old_size

# Append new data
new_data = open('NEW_GLOBAL_STRING.LDT', 'rb').read()
new_pos = len(spf)  # append at end
spf.extend(new_data)

# Update directory entry
struct.pack_into('<I', spf, idx+129, new_pos)
struct.pack_into('<I', spf, idx+133, len(new_data))

with open('ROWID.SPF', 'wb') as f:
    f.write(spf)
```

**Warning:** This leaves a zero-filled hole in the SPF. Works fine — game servers only follow directory entries, they don't scan the file sequentially. The file just gets bigger with each replacement.

For batch replacement of multiple files (like 6 text LDTs), process all entries in order, appending each new data block sequentially after the last write position.

## Resource Loading Modes

configure.ini controls how the server reads resources:
- `pack = 1`: Read from SPF archive at ResourceDir
- `pack = 0`: Read from extracted directory at ResourceDir

To switch to extracted mode:
```
ResourceDir = D:\Server\SPF\extracted\
pack = 0
```
The extracted directory must mirror the SPF layout: `DATA/LDT/*.LDT`

### Critical: Each configure.ini Section Has Its Own ResourceDir/pack

Each server section in configure.ini (`[LataleGameServer_101]`, `[LataleRoomServer]`, `[LataleLobbyServer]`, etc.) has its own `resourceDir=` and `Pack=` settings. The **section-level settings override the global defaults**. When switching to pack=0, you must update EVERY section, not just the first few.

**Bulk fix (Python):**
```python
content = content.replace('Pack= 1', 'Pack= 0')
content = content.replace('pack= 1', 'pack= 0')
content = content.replace('ResourceDir = D:\\Server\\SPF\\', 'ResourceDir = D:\\Server\\SPF\\extracted\\')
content = content.replace('resourceDir= D:\\Server\\SPF\\', 'resourceDir= D:\\Server\\SPF\\extracted\\')
```

### Pitfall: pack=0 → pack=1 Switch Without Restoring All Sections

If you change from pack=0 back to pack=1 but some sections still point to the extracted directory, services crash with `.../LDT/GLOBAL_SYS.LDT : FAILED ! (This LDT is Not Exist.)`.

This happens when:
1. You switched to pack=0 and forgot to update some sections
2. You switched back to pack=1 but missed reverting the same sections
3. The extracted directory is missing files that the SPF has

**Always verify ALL sections are updated when switching modes.** If in doubt, restore both the SPF and configure.ini from backup simultaneously, then restart everything.

## S4 SPF Structure (non-hexiang encrypted)

S4 99元完整端 (D:\LaTale\S4chd\resource) 的 SPF 包不是标准 SPF 格式，也不是他乡加密格式：
- 文件头直接是内部数据格式（PNG 图片、ID3 音频、RIFF WAV、FX 模型等）
- ROWID.SPF 和 AJJIYA.SPF 是数据包（包含 LDT 文件）
- ZENNE.SPF (329MB) 是文件目录索引

### ROWID.SPF — LDT 资源包

ROWID.SPF 包含所有 DATA/LDT/*.LDT 文件。文件结构：
- 头部 8 字节：0x00000000 + 文件数（4字节小端）
- 文件条目：偏移(4B) + 大小(4B) + 标志(4B) + 文件名(0x100+ 字节)
- LOCALIZE.LDT 位于偏移 0x2361

### LOCALIZE.LDT 内容

LOCALIZE.LDT (~48MB) 包含：
1. **脏词过滤表**（文件开头）— `☆☆` 分隔的敏感词列表（GBK编码）
2. **多种 LDT 子表**（脏词表之后）— 本地化文本、地区配置等

本地化模式值传闻：
- 10 = 原始值
- 20 = 台湾（台服模式）
- 18 = GSP（本地模式）

注：具体字段位置未精确定位，需要进一步解析 LDT 子表结构。

### 标准 S4 SPF 文件列表

| SPF 文件 | 大小 | 内容类型 |
|----------|------|----------|
| AJJIYA.SPF | 154MB | Zero-header 数据包 |
| ROWID.SPF | 141MB | Zero-header 数据包（LDT） |
| ZENNE.SPF | 329MB | SFP_V1 目录索引 |
| DALBONG.SPF | 830MB | ID3（音频） |
| METALGENI.SPF | 469MB | RIFF（WAV/AVI） |
| BANX/BARY/CLAIRE/etc | 多 | PNG（图片/UI） |
| HOSHIM.SPF | 453MB | FX（模型） |

### 解包方法

S4 标准 SPF 可用 `解包-打包.EXE`（图形界面，位于 D:\LaTale\S4chd\resource\）或 LaTaleTools（F# 开源工具）处理。ROWID.SPF 可用 Python 直接按偏移提取。

## Chinese S4 LDT Porting Matrix

Which guofu (Chinese S4) LDT files can replace S2 files directly:

| LDT File | Compatible? | Notes |
|----------|------------|-------|
| GLOBAL_STRING.LDT | ✅ | Same 3 cols. Different row count. Direct replace. |
| WORLD_MAP_STAGE.LDT | ✅ | 18 cols same. GF has +1 col at end. Direct replace. |
| SKILL_TXT.LDT | ✅ | 4 cols same. Direct replace. |
| NPCTALK.LDT | ✅ | 34 cols same. GF has +3 cols at end. Direct replace. |
| UI_TOOLTIP.LDT | ✅ | 6 cols same. Direct replace. |
| LOCALIZE.LDT | ✅ | 3 cols same. Direct replace. |
| MAP_INFO.LDT | ❌ | S2 has 4 cols, GF has 47 cols. Structure differs. |
| GLOBAL_SYS.LDT | ❌ | Column types differ. |
| CASH_SHOP.LDT | ⚠️ | 65 vs 71 cols. GF has extra pages/oz/mile columns. NOT a direct replacement but S4 shop data can be ported by ItemID if names were Chinese (they aren't — both store Korean text). |
| ITEM_1/2/3.LDT | ❌ | ItemID ranges differ between S2 and S4. Direct replacement breaks inventory. |

IMPORTANT: Even S4 LDTs store Korean text in EUC-KR, not GBK Chinese. The display language difference comes from the client EXE's locale handling, not from LDT content. The only LDTs with actual Chinese text are the text-only ones (GLOBAL_STRING, NPCTALK, SKILL_TXT, WORLD_MAP_STAGE descriptions, etc.) which are encoded in GBK in the S4 files.

## Font Configuration (No EXE Modification)

LaTaleClient.exe is VMProtect-packed — font strings are not accessible for editing.
Use Windows FontLink registry instead:

```powershell
$path = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\FontLink\SystemLink"
$fonts = @("Gulim", "Dotum", "Batang", "Gungsuh", "Tahoma", "Microsoft Sans Serif", "Arial")
$value = @("msyh.ttc,Microsoft YaHei", "simsun.ttc,SimSun")
foreach ($font in $fonts) {
    New-ItemProperty -Path $path -Name $font -PropertyType MultiString -Value $value -Force
}
```

Requires game restart to take effect. Only affects rendering — doesn't change stored text.

## Process Management on Windows via Agent

The agent runs inside git-bash (MSYS2), which causes issues with Windows PE executables.

**DO NOT:**
- Use `terminal(background=true, notify_on_complete=true)` with cmd.exe /c wrappers — the wrapper exits instantly, the EXE keeps running, generating false notifications.
- Use `taskkill /F` with leading `/` — git-bash treats `/F` as a filesystem path. Use `cmd.exe //c 'taskkill /F /IM xxx.exe'` instead.

**DO:**
- Launch Chinese-named EXEs via `PowerShell Start-Process`.
- Verify process liveness via `netstat -ano` port binding, not `tasklist` or `Get-Process` (which can return None on Chinese Windows).
- Use `PowerShell Get-Process -Name LaTaleClient` for cross-checking when port monitoring is insufficient.
