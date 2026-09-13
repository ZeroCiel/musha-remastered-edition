# EFFECT.LDT 结构分析与修改指南

## 文件基本信息

- 路径: `D:\彩虹岛\resource\ROWID\DATA\LDT\EFFECT.LDT`
- 列数: 70 列
- 行数: 约18787+ (实际数据行数，含空行)
- 所有列类型: **全部为 type=0 (string)** — 即没有 int/float 列，所有数据都是变长 `\x00` 分隔字符串
- 列头部偏移: 12
- 列名区大小: 70 × 64 = 4480 字节
- 列类型区偏移: 12 + 4480 = 4492
- 列类型区大小: 70 × 4 = 280 字节
- **数据区偏移: 12 + 70×64 + 70×4 = 4772**
- 数据区以 `\x00\x00\x00` (连续多个00) 作为行分隔

## 关键列定义 (前15列)

| 索引 | 列名 | 说明 |
|------|------|------|
| 0 | `_Name` | 效果名称（含控制字节/编码前缀） |
| 1 | `_Description` | 效果描述文字 |
| 2 | `_Attack_Type` | 攻击类型 |
| 3 | `_BuffID` | BUFF ID（数字，存为string） |
| 4 | `_BuffLv` | BUFF等级 |
| 5 | `_BuffElv` | BUFF强化等级 |
| 6 | `_BuffID_Check` | BUFF ID校验 |
| 7 | `_BuffLv_Check` | BUFF等级校验 |
| 8 | `_BuffElv_Check` | BUFF强化等级校验 |
| 9 | `_Buff_Icon` | BUFF图标文件ID |
| 10 | `_Buff_IconIndex` | BUFF图标索引 |
| 11 | `_Buff_Name` | BUFF显示名称 |
| 12 | `_Buff_Description` | BUFF显示描述 |
| 13 | `_EffectType` | 效果类型 |
| 14 | `_Require1_Type` | 条件1类型 |

其他列: `_EffectValueType`, `_SaveCheck`, `_Broadcast` 等，全部 string 类型。

## 行数据结构

每行数据以连续 `\x00` 字节分隔字段。行内字段顺序对应列索引。

### 典型行示例（爱丽丝的祝福）

**Row 19388** (显示名称行):
```
field[0] = \x0c          (控制字节)
field[1] = 爱丽丝的祝福    (显示名称，_Name)
field[2] = 经验值获得 200%， 任务奖励UP！ 50%  (效果描述，_Description)
```

**Row 19384** (效果描述行，通过BuffID关联):
```
field[0] = 63000912  (BuffID，以4字节int嵌入在string中)
field[1] = (爱丽丝增益效果) 经验值获得 200% (60分钟)  (描述，_Description)
```

## 修改方法

### 原则
- EFFECT.LDT全部是string列 → 修改时**必须保持等长**（新字段长度=旧字段长度）
- 如果新内容比旧内容短：用空格填充到等长（显示上可能有多余空格）
- 如果新内容比旧内容长：需要压缩措辞或拆分行
- **必须先备份**：`EFFECT.LDT` → `EFFECT.LDT.bak_before_<描述>`

### Python修改步骤

```python
import struct
from pathlib import Path

# 1. 备份
src = 'EFFECT.LDT'
bak = f'EFFECT.LDT.bak_before_mod'
Path(bak).write_bytes(Path(src).read_bytes())

# 2. 读取
data = bytearray(Path(src).read_bytes())

# 3. 搜索目标字符串（GBK编码）
# 例如搜索 "200%" → b'200%' (ASCII)
# 中文搜索：'爱丽丝'.encode('gbk') → b'\xb0\xae\xc0\xf6\xcb\xbf'

# 4. 等长替换
old = b'200%'
new = b'20% '  # 补空格到等长
idx = data.find(old)
if idx >= 0:
    data[idx:idx+len(old)] = new

# 5. 或针对特定行的特定字段精确替换
# 找到行范围后，在行内定位旧字符串
row_start = 436028  # 行数据区起始
row_end = 436079    # 行数据区结束
row_data = data[row_start:row_end]
fields = row_data.split(b'\x00')
# 修改特定字段
# ...

# 6. 写回
Path(src).write_bytes(data)
```

### 搜索技巧

由于70列全是string，可以采用以下方法搜索：

1. **按数值搜索**：将EffectID（如63000912）的4字节小端表示作为二进制搜索
   ```python
   target = struct.pack('<I', 63000912)  # → b'PQ\xc1\x03'
   idx = data.find(target)
   ```

2. **按GBK中文搜索**：直接在文件二进制中搜索GBK编码
   ```python
   kw = '爱丽丝'.encode('gbk')
   idx = data.find(kw)
   ```

3. **扫描所有行**：遍历数据区，按 `\x00\x00\x00` 分隔提取每一行

### 行扫描示例

```python
data_off = 4772
pos = data_off
row_num = 0
while pos < len(data):
    # 跳过连续00
    while pos < len(data) and data[pos] == 0:
        pos += 1
    if pos >= len(data): break
    
    row_start = pos
    # 找行结束：连续3个以上00
    while pos < len(data):
        if pos+2 < len(data) and data[pos]==0 and data[pos+1]==0 and data[pos+2]==0:
            break
        pos += 1
    row_end = pos
    row_num += 1
    
    row_data = data[row_start:row_end]
    fields = row_data.split(b'\x00')
    # 处理fields...
    
    # 跳过行尾00
    while pos < len(data) and data[pos] == 0:
        pos += 1
```

## 与EFFECT.LDT关联的其他表

EffectID（如63000912）会出现在以下LDT文件中作为引用：
- **ITEM_3.LDT** — 道具效果引用
- **CREATION_INFO_BURNING.LDT** — 创角BUFF配置
- **QUEST_2.LDT** — 任务奖励BUFF
- **CP_EVENT_MISSION.LDT** — 活动任务BUFF
- **CASH_SHOP_BURNING.LDT** — 燃烧服商城BUFF道具

全局搜索EffectID的方法：
```python
import struct, glob
target = struct.pack('<I', EFFECT_ID)
for fpath in glob.glob('*.LDT'):
    if target in open(fpath, 'rb').read():
        print(f'{fpath} contains {EFFECT_ID}')
```

## 实际案例：爱丽丝的祝福 200%→20%

### 修改项
| 行 | 字段 | 旧值 | 新值 |
|---|---|---|---|
| 19384 | field[1] | (爱丽丝增益效果) 经验值获得 200% (60分钟) | (爱丽丝增益效果) 经验值获得 20% (60分钟) |
| 19388 | field[1] | 爱丽丝的祝福" | 爱丽丝祝福20%（等长11→11） |
| 19388 | field[2] | 经验值获得 200%， 任务奖励UP！ 50% | 经验值获得 20% ， 任务奖励UP！ 20% |

### 备份文件
`EFFECT.LDT.bak_before_fix_exp` — 200%→100%的原备份
`EFFECT.LDT.bak_before_20pct` — 100%/200%→20%的备份

## 注意

- EFFECT.LDT不是固定行宽，变长string不能直接通过行号×行宽定位
- 行号可能随插入/删除变化，修改前先按内容找目标行
- 修改后不需要打包（SPF），因为原文件结构不变，只改了string内容
- 改完后重启GS生效
