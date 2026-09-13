# 跨版本 SPF 替换 → 服务启动失败（Lobby/Bay 等）

## 场景描述

用户尝试将**不同版本/地区**的 SPF 资源包替换到现有服务端，导致某些服务（典型：LobbyServer、BayServer、RoomServer）启动失败或加载资源时报错。

常见错误模式：

1. **台服 SPF 替换旧版他乡 S2 服务端** — 服务加载过程中报错闪退
2. **国服 S4 LDT 整文件覆盖到台服/韩服 SPF** — 服务端加载地图/商城/全局字符串时崩溃

## 根因分析

### 1. CRC/版本校验不一致

他乡服务端的 exe 可能在加载某些 SPF 内文件时做了基本的 CRC 校验或版本号校验（在 exe 代码中硬编码）。直接替换 SPF 文件会让这些校验失败。

### 2. LDT 索引/结构不兼容

不同版本的游戏（S2 vs S4，台服 vs 国服 vs 韩服）之间的 LDT 文件可能：

- **行数不同** — 增加/删除了商品、道具、地图条目
- **列数/列类型不同** — 国服 S4 的 CASH_SHOP.LDT 比 S2 多几列（_MaxOz、_MaxMile 等）
- **ID 映射不同** — 同一 ItemID 在不同版本中对应不同物品
- **字符串编码不同** — 台服 euc-kr(CP949)，国服 GBK，韩服 euc-kr

服务端在加载这些 LDT 到内存时，按预期结构读取，遇到不匹配的结构（列数不对、字段大小不对）会导致缓冲区内存越界、断言失败、或 return false 导致服务退出。

### 3. SPF 打包方式不同

- **标准 SPF**：无加密，纯归档格式（LaTaleTools 可读写）
- **加密 SPF**（他乡版）：B站工具宣称的\"加密 + 打残 + 打乱 + 超级加密\"，删除了客户端不需要的 LDT 文件
- **商业服 SPF**（国服/台服官方）：可能有自定义加密（如国服\"解密3000\"工具专门解国服 SPF）

把加密版 SPF 放到标准服务端，或把标准 SPF 放到魔改服务端，都会导致加载失败。

## 受影响的服务

| 服务 | 典型症状 |
|------|---------|
| **AS** | 报 `GLOBAL_SYS.LDT : FAILED!`（SPF 路径不对或文件加载失败） |
| **LobbyServer** | 启动后闪退，console 无有效输出，端口 10002 不绑定 |
| **BayServer** | 同上，端口 10006 不绑定 |
| **RoomServer** | 同上，端口 10007 不绑定 |
| **GameServer** | 报 `LoadConfigure() : FAILED !` 或 `INVALID SECTION INFO` 或加载 LDT 后闪退 |

**注意**：Lobby/Bay/Room 这三个服务在 SPF 不兼容时，启动失败的现象非常相似——console 窗口出现然后快速消失，进程不在 tasklist 中，端口不绑定。

## 排查步骤

### 第 1 步：还原 SPF，确认是 SPF 问题

1. 还原 SPF 目录为原版（未修改的版本）
2. 重启全部服务
3. 验证 Lobby/Bay/Room 能否正常启动

如果还原后恢复正常 → **确定是 SPF 替换导致的问题**。

### 第 2 步：确认是哪个 LDT 导致崩溃

如果必须修改某个 LDT 文件，用**二分法**排查：

1. 用 LaTaleTools 或 Python 脚本解包 SPF
2. 逐个替换 LDT 文件，每次替换后重启服务
3. 先替换一半 → 如果崩了，这半有问题 → 减半排查（经典的二分查找法）

**高风险文件**（已验证）：
- `ATTACK_TREE.LDT` — 替换后服务崩溃
- `BEATTACKED.LDT` — 替换后服务崩溃
- `GLOBAL_SYS.LDT` — 大量游戏平衡参数，结构和 ID 敏感

**低风险文件**（结构稳定，可安全替换）：
- `GLOBAL_STRING.LDT` — 纯 UI 文本，行结构简单
- `WORLD_MAP_STAGE.LDT` — 世界地图文本
- `SKILL_TXT.LDT`, `SKILL_CONTENT.LDT` — 技能描述文本

### 第 3 步：检查 LDT 结构兼容性

用 Python 检查两个版本 LDT 的列数和列类型是否一致：

```python
import struct

def check_ldt_structure(path):
    with open(path, 'rb') as f:
        data = f.read()
    col_count = struct.unpack('<I', data[4:8])[0] + 1
    row_count = struct.unpack('<I', data[8:12])[0]
    
    col_types = []
    for n in range(col_count - 1):
        t = struct.unpack('<I', data[8204 + n*4:8204 + n*4 + 4])[0]
        col_types.append(t)
    
    return {'cols': col_count, 'rows': row_count, 'types': col_types}

# 比较两个版本的 LDT
old = check_ldt_structure('s2/CASH_SHOP.LDT')
new = check_ldt_structure('s4/CASH_SHOP.LDT')
print(f"Old: {old['cols']} cols, {old['rows']} rows")
print(f"New: {new['cols']} cols, {new['rows']} rows")
print(f"Types match: {old['types'] == new['types']}")
```

如果列数或类型序列不一致 → **不能整文件替换**。

## 安全替换策略

### 方案 A：仅替换文本字段（不替换结构）

1. 解包两边的 SPF
2. 用 Python LDT 解析器分别读取原版和目标版的 LDT
3. 只提取字符串字段（如 _Name、描述、对话文本），逐条替换到原版 LDT
4. 确保不修改行数、列数或数字字段（如 ItemID、价格、类型）

```python
# 伪代码：替换 CASH_SHOP.LDT 中的商品名
old_rows = read_ldt('s2/CASH_SHOP.LDT')  # 原版
new_rows = read_ldt('s4/CASH_SHOP.LDT')  # 国服/台服

# 按 _RowId 建立映射
id_map = {row[0]: row for row in new_rows}

for i, old_row in enumerate(old_rows):
    if old_row[0] in id_map:
        # 只替换文本字段（列索引 7 = _Name）
        old_row[7] = id_map[old_row[0]][7]

write_ldt('s2/CASH_SHOP.LDT.modified', old_rows)
```

### 方案 B：Pack=0 模式（目录模式）

当 LDT 文件大小变化时，无法做 SPF 原位替换（in-place replacement）。改为目录模式：

```ini
[LataleGameServer_101]
ResourceDir = D:\Server\SPF\extracted\
Pack = 0
```

注意：必须为每个服务段的 `Pack=` 单独修改。部分服务（AS、樱花网关）可能不支持 Pack=0 模式。

### 方案 C：社区 Hermes 工具（针对本区版本的文本编辑）

- 用 Hermes 工具打开本区版本的 SDF/SPF
- 逐条修改文本（不改变 ID、行数、结构）
- 保存后工具会按原格式重新打包
- 文件放在本区 SPF 中，服务端兼容

## ⚠️ 禁止的操作

| ❌ 操作 | 后果 |
|---------|------|
| 国服 S4 的 LDT 整文件覆盖到台服 S2 的 SPF | 启动失败，结构不兼容 |
| 台服 SPF 整包替换到旧版他乡服务端 | Lobby/Bay/Room 等服务启动不绑定端口 |
| 不同加密程度的 SPF 互相替换 | 加载时 CRC/解密失败 |
| 只替换 ROWID.SPF（不替换整个 SPF 目录） | 部分 SPF 文件版本不匹配 |

## 保留原版（务必）

每次修改 SPF 前，**备份原版**：
```bash
cp -r D:\Server\SPF D:\Server\SPF.bak.$(date +%Y%m%d)
```

还原时只需要：
```bash
rm -rf D:\Server\SPF
cp -r D:\Server\SPF.bak.$(date +%Y%m%d) D:\Server\SPF
```

然后重启全部服务。
