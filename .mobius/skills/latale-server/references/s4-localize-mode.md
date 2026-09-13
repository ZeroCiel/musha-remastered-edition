# S4 LOCALIZE.LDT 模式控制

## 文件位置

`D:\LaTale\S4chd\resource\ROWID.SPF` → 内部路径 `DATA/LDT/LOCALIZE.LDT`

## 提取方法

ROWID.SPF 中的 LOCALIZE.LDT 位于偏移 0x2361，大小约 48MB（0x30000ac）。
文件头部约 4KB 是**脏词过滤表**（敏感词库，GBK编码中文）。

```python
with open('ROWID.SPF', 'rb') as f:
    data = f.read()
offset = 0x2361
ldt = data[offset:offset + 0x30000ac]
with open('LOCALIZE.LDT', 'wb') as f:
    f.write(ldt)
```

## 模式值对照

据 RageZone/社区说法，LOCALIZE.LDT 中的某个字段控制本地化模式：

| 值 | 含义 |
|----|------|
| 10 | 台湾 (TW / 台服) |
| 18 | GSP (本地模式) |
| 20 | 台湾 (另一种说法 — 需验证) |

GSP 相关字符串出现在文件偏移 0x1429bf0：
`[GSP] ??? ???? ??? ?? ?? ?? ???`

## ROWID.SPF 格式（S4版，非加密）

S4CHD 的 SPF 格式与 S2 他乡版不同 — **S4的是标准格式，非加密**。

ROWID.SPF 头部分析：
- 前4字节: 0x00000000 (magic)
- 第5-8字节: 文件条目数
- 条目: 每个 140 字节 (1字节标记 + 128字节路径 + 4字节偏移 + 4字节大小 + 4字节索引)

包含文件示例：
- `DATA/LDT/LOCALIZE.LDT` (48MB)
- `DATA/LDT/GLOBAL_STRING.LDT`
- 以及其他 LDT 文件

其他 SPF（BARY, RYUMS, MAKO1298等）是纯图片/音频/模型数据包，不包含LDT。

## 提取全部LDT

ROWID.SPF 是 S4 的主要数据包（含全部 LDT 文件）。遍历其140字节条目可提取所有文件。
