# LDT Python读写工具

`C:\Users\Administrator\Temp\ldt_writer.py`

基于LaTaleTools的读取逻辑逆向，实现LDT二进制文件的读写。

## 核心函数

### parse_ldt_header(data) → dict
解析LDT文件头，返回：
- `col_count`: 列数（不含_RowId）
- `row_count`: 行数
- `col_names`: 完整列名列表（含_RowId作为第0列）
- `col_types`: 类型列表（0=uint,1=string,2=bool,3=int,4=float）
- `data_start`: 数据区起始偏移

### read_rows(data, header) → list[list]
读取所有行数据，返回二维列表，每行按col_types顺序排列。

### build_ldt(header, rows, orig_data) → bytes
从修改后的rows重建LDT二进制数据。
- `header`: 原文件解析的header
- `rows`: 修改后的数据列表
- `orig_data`: 原LDT的完整二进制（用于复制头部和填充区）

## 类型处理

| col_types值 | Python类型 | 存储方式 |
|------------|-----------|---------|
| 0 (uint) | str数字 | 4字节小端uint32 |
| 1 (string) | str | 2字节长度 + GBK编码内容 |
| 2 (bool) | 'true'/'false' | 4字节(1/0) |
| 3 (int) | str数字 | 4字节小端int32 |
| 4 (float) | str浮点数 | 4字节小端float32 |

## 使用示例

```python
import sys
sys.path.insert(0, r'C:\Users\Administrator\Temp')
from ldt_writer import parse_ldt_header, read_rows, build_ldt

with open('ITEM_3.LDT', 'rb') as f:
    data = f.read()

header = parse_ldt_header(data)
rows = read_rows(data, header)

# 修改第5行（index 4）的第2列（_Name，类型string）
rows[4][2] = rows[4][2].replace('艾丽斯', '爱丽丝')

new_data = build_ldt(header, rows, data)
with open('ITEM_3.LDT', 'wb') as f:
    f.write(new_data)
```

## 批量繁简转换脚本

`C:\Users\Administrator\Temp\batch_t2s.py` — 自动扫描所有有string列的LDT，全量繁转简。
内置t2s映射表覆盖常用简繁差异字约2000个。

`C:\Users\Administrator\Temp\fix_remaining_trad.py` — 针对指定词汇（用户feedback）的精准替换。

## 备份策略

每次写回自动在原文件同目录生成 `.bak` 后缀备份。
繁转简操作生成 `.bak_trad` 后缀备份。
