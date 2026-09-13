# SPF 文件格式 (Latale SPF Archive)

## 整体结构
```
[文件数据区][FINFO条目表(末尾)][哨兵140B]
```

## FINFO 条目 (每条 140 字节)
```
[128B: szFileName (null-terminated, latin-1)]
[4B:   iOffset    (little-endian int32)]
[4B:   iSize      (little-endian int32)]
[4B:   ResID      (little-endian int32)]
```

## 读取方法
```python
ENTRY_SIZE = 140
ptr = file_size - ENTRY_SIZE * 2  # 跳过哨兵
while ptr >= 0:
    path = read_null_terminated(data, ptr, 128)
    offset = struct.unpack_from('<i', data, ptr + 128)[0]
    size   = struct.unpack_from('<i', data, ptr + 132)[0]
    res_id = struct.unpack_from('<i', data, ptr + 136)[0]
    if offset == 0 and not path: break  # 哨兵
    entries.append(...)
    ptr -= ENTRY_SIZE
entries.reverse()
```

## 打包方法
1. 按任意顺序 concatenate 所有文件数据
2. 记录每个文件的 offset 和 size
3. 在末尾按 **倒序** 写入所有 FINFO 条目
4. 最后追加 140 字节全零哨兵

## S2 vs 国服 ROWID.SPF
| | S2 私服 | 国服(盛大) |
|---|---|---|
| 文件数 | 250 | 667 |
| 大小 | ~144MB | ~297MB |
| 相同名文件 | 196 | 196 |
| 结构兼容 | 101 | 101 |

## 关键脚本
- `spf_extract.py` — 解包 SPF → 目录
- `merge_spf.py` — 合并国服 LDT 到 S2 SPF（仅结构兼容文件）
- 位于 `D:\彩虹岛\`
