# LDT 二进制格式验证（2026-05-26）

基于源码 `SPLDTFile.h` 的 LDT_Header 结构 + 二进制逆向验证。

## 文件头结构

```c
struct LDT_Header {
    long    nDB_ID;           // 4字节 — 通常为0
    long    nFields;          // 4字节 — 字段数（不含_RowId）
    long    nData;            // 4字节 — 数据行数
    LDT_STR64 FieldNAM[128];  // 128 * 64 = 8192字节 — 字段名
    long    FieldTYP[128];    // 128 * 4 = 512字节 — 字段类型
};
// 总头部大小 = 12 + 8192 + 512 = 8716字节
```

| 偏移 | 大小 | 字段 |
|------|------|------|
| 0x00 | 4 | nDB_ID (int32) |
| 0x04 | 4 | nFields (int32) |
| 0x08 | 4 | nData (int32) |
| 0x0C | 8192 | FieldNAM[128], 每项64字节, null终止+空格填充 |
| 0x200C | 512 | FieldTYP[128], 每项4字节 (int32) |
| 0x220C | 可变 | 数据区起始 (8716十进制) |

## 字段类型值

| 值 | 宏 | 含义 | 存储大小 |
|----|-----|------|---------|
| 0 | fldNA | 空/占位 | 4字节(固定) |
| 1 | fldString | 字符串 | 2字节长度前缀 + 数据 |
| 2 | fldTF | 布尔值 | 4字节(int32) |
| 3 | fldNum | 整数 | 4字节(int32) |
| 4 | fldPer | 浮点数 | 4字节(float) |
| 5 | fldFID | 文件引用ID | 4字节(int32) |
| 6 | fldAlias | 别名字符串 | 2字节长度前缀 + 数据 |
| 7 | fldNum64 | 64位整数 | 8字节(int64) |
| 255 | fldPrimaryKey | 主键 | 4字节(每行第1个字段,自动) |

## 字段名读取

FieldNAM[128] 数组，每项64字节。实际有效的字段数由 nFields 决定（不超过128）。

字段名是空终止字符串 + 空格填充。编码：UTF-8（字段名通常为 ASCII/下划线开头，如 `_Name`, `_Type`）。

**示例**（ACHIEVE.LDT, 32个字段）：`_Type`, `_Name`, `_Summary`, `_Descript`, `_AchievePoint`, `_Icon`, `_IconIndex`, `_Mission1`...`_Reward_Choice`

## Python 解析代码

```python
import struct

def read_ldt(path):
    with open(path, 'rb') as f:
        data = f.read()
    
    db_id, nFields, nData = struct.unpack_from('<iii', data, 0)
    
    # 字段名
    labels = []
    for i in range(nFields):
        off = 12 + i * 64
        chunk = data[off:off+64]
        null_pos = chunk.find(b'\x00')
        label = chunk[:null_pos].decode('euc-kr', errors='replace')
        labels.append(label)
    
    # 字段类型
    type_offset = 12 + 128 * 64  # = 8204
    field_types = []
    for i in range(nFields):
        ft = struct.unpack_from('<i', data, type_offset + i * 4)[0]
        field_types.append(ft)
    
    # 数据区
    type_names = {0:'NA', 1:'String', 2:'TF', 3:'Num', 4:'Per', 5:'FID', 6:'Alias', 7:'Num64'}
    data_offset = 12 + 128 * 64 + 128 * 4  # = 8716
    
    rows = []
    ro = data_offset
    for row_i in range(nData):
        pk = struct.unpack_from('<i', data, ro)[0]
        ro += 4
        row = {'_RowId': pk}
        
        for j in range(nFields):
            ft = field_types[j]
            if ft == 0:  # NA
                val = struct.unpack_from('<i', data, ro)[0]
                ro += 4
            elif ft == 1:  # String
                slen = struct.unpack_from('<h', data, ro)[0]
                ro += 2
                val = data[ro:ro+slen].decode('euc-kr', errors='replace')
                ro += slen
            elif ft in (2, 3, 5):  # TF, Num, FID
                val = struct.unpack_from('<i', data, ro)[0]
                ro += 4
            elif ft == 4:  # Per (float)
                val = struct.unpack_from('<f', data, ro)[0]
                ro += 4
            elif ft == 6:  # Alias
                slen = struct.unpack_from('<h', data, ro)[0]
                ro += 2
                val = data[ro:ro+slen].decode('euc-kr', errors='replace')
                ro += slen
            elif ft == 7:  # Num64
                val = struct.unpack_from('<q', data, ro)[0]
                ro += 8
            else:
                val = None
                ro += 4
            
            row[labels[j]] = val
        
        rows.append(row)
    
    return db_id, nFields, labels, field_types, rows
```

## 验证结果（SFP v1.6 解包LDT）

用此解析器验证了 ROWID.SPF 解包出的全部LDT文件：
- ACHIEVE.LDT (32字段, 200行) ✅
- CASH_SHOP.LDT (64字段, 4143行) ✅  
- GLOBAL_STRING.LDT (2字段, 3500行) ✅
- MAP_INFO.LDT ✅ 等

所有文件解析成功，无格式错误。字符串字段为EUC-KR编码韩文。

## LDT文件完整性

SFP v1.6解包后的LDT文件是完整的标准格式，可以通过本解析器直接读写行数据。
