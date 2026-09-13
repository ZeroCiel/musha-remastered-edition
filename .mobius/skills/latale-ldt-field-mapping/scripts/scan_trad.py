"""
扫描所有LDT中指定关键词的分布情况（用于决定改哪个文件）
用法: python scan_trad.py <关键词>
示例: python scan_trad.py 愛麗絲
"""
import struct, os, sys

keyword = sys.argv[1] if len(sys.argv) > 1 else '愛麗絲'
ldt_dir = r'D:\彩虹岛\resource\ROWID\DATA\LDT'

kw_gbk = keyword.encode('gbk')
results = []
for fname in sorted(os.listdir(ldt_dir)):
    if not fname.endswith('.LDT') or fname.endswith('.bak'):
        continue
    fpath = os.path.join(ldt_dir, fname)
    with open(fpath, 'rb') as f:
        data = f.read()
    found = 0
    pos = 8716
    col_count = struct.unpack('<I', data[4:8])[0]
    row_count = struct.unpack('<I', data[8:12])[0]
    string_col_indices = set()
    for i in range(col_count):
        t = struct.unpack('<I', data[8204 + i*4:8204 + i*4 + 4])[0]
        if t == 1:
            string_col_indices.add(i)
    if not string_col_indices:
        continue
    for ri in range(row_count):
        pos += 4  # _RowId
        for ci in range(col_count):
            if pos + 4 > len(data):
                break
            t = struct.unpack('<I', data[8204 + ci*4:8204 + ci*4 + 4])[0]
            if t == 1:
                if pos + 2 > len(data):
                    break
                slen = struct.unpack('<H', data[pos:pos+2])[0]
                pos += 2
                if slen > 0 and pos + slen <= len(data):
                    if kw_gbk in data[pos:pos+slen]:
                        found += 1
                    pos += slen
            elif t in (0, 2, 3, 4):
                pos += 4
            else:
                pos += 4
    if found > 0:
        results.append((fname, found))

if results:
    print(f"'{keyword}' 分布情况 ({len(results)}个文件, 共{sum(c for _,c in results)}处):")
    for fname, cnt in results:
        print(f"  {fname}: {cnt}")
else:
    print(f"没有文件包含 '{keyword}'")
