"""
LDT Binary Read/Write Tool
Provides: parse_ldt_header(), read_rows(), build_ldt()

Usage:
    import sys; sys.path.insert(0, r'C:\\Users\\Administrator\\Temp')
    from ldt_writer import parse_ldt_header, read_rows, build_ldt

    with open('file.LDT', 'rb') as f: data = f.read()
    header = parse_ldt_header(data)
    rows = read_rows(data, header)
    # modify rows...
    new_data = build_ldt(header, new_rows, data)
    with open('file.LDT', 'wb') as f: f.write(new_data)
"""

import struct, csv

def parse_ldt_header(data):
    """返回{col_count, row_count, col_names, col_types, data_start}"""
    unk = struct.unpack('<I', data[0:4])[0]
    col_count = struct.unpack('<I', data[4:8])[0]
    row_count = struct.unpack('<I', data[8:12])[0]
    col_names = []
    for i in range(col_count):
        offset = 12 + i * 64
        name_bytes = data[offset:offset+64]
        name = name_bytes.split(b'\x00')[0].decode('ascii', errors='replace').strip()
        col_names.append(name)
    col_types = []
    for i in range(col_count):
        offset = 8204 + i * 4
        t = struct.unpack('<I', data[offset:offset+4])[0]
        col_types.append(t)
    return {
        'col_count': col_count,
        'row_count': row_count,
        'col_names': ['_RowId'] + col_names,
        'col_types': [3] + col_types,
        'data_start': 8716,
    }

def read_rows(data, header):
    """读取所有行，返回list[list[str]]"""
    rows = []
    pos = header['data_start']
    types = header['col_types']
    for _ in range(header['row_count']):
        row = []
        for t in types:
            if pos + 4 > len(data): break
            if t in (0, 2, 3):
                val = struct.unpack('<i' if t == 3 else '<I', data[pos:pos+4])[0]
                row.append(str(val))
                pos += 4
            elif t == 4:
                val = struct.unpack('<f', data[pos:pos+4])[0]
                row.append(str(val))
                pos += 4
            elif t == 1:
                if pos + 2 > len(data): break
                slen = struct.unpack('<H', data[pos:pos+2])[0]
                pos += 2
                if slen > 0 and pos + slen <= len(data):
                    s = data[pos:pos+slen].decode('gbk', errors='replace')
                    row.append(s)
                    pos += slen
                else:
                    row.append('')
        rows.append(row)
    return rows

def build_ldt(header, rows, orig_data):
    """从行数据重建LDT二进制"""
    buf = bytearray()
    buf.extend(orig_data[:12])
    for i in range(header['col_count']):
        offset = 12 + i * 64
        buf.extend(orig_data[offset:offset+64])
    buf.extend(orig_data[12 + header['col_count'] * 64:8204])
    for i in range(header['col_count']):
        offset = 8204 + i * 4
        buf.extend(orig_data[offset:offset+4])
    buf.extend(orig_data[8204 + header['col_count'] * 4:8716])

    row_count = 0
    types = header['col_types']
    for row in rows:
        item_id = int(row[0]) if row[0] else 0
        if item_id == 0 and all(v in ('0','false','','0.0') for v in row[1:]):
            continue
        for ci, val in enumerate(row):
            t = types[ci]
            try:
                if t == 0: buf.extend(struct.pack('<I', int(val) if val else 0))
                elif t == 3: buf.extend(struct.pack('<i', int(val) if val else 0))
                elif t == 2: buf.extend(struct.pack('<I', 1 if val.lower() in ('true','1') else 0))
                elif t == 4: buf.extend(struct.pack('<f', float(val) if val else 0.0))
                elif t == 1:
                    if val:
                        gbk = val.encode('gbk', errors='replace')
                        buf.extend(struct.pack('<H', len(gbk)))
                        buf.extend(gbk)
                    else:
                        buf.extend(struct.pack('<H', 0))
            except:
                buf.extend(struct.pack('<H', 0) if t == 1 else struct.pack('<i', 0))
        row_count += 1
    struct.pack_into('<I', buf, 8, row_count)
    return bytes(buf)

def csv_to_rows(csv_path, header):
    """读取CSV（导出工具格式）为行列表"""
    rows = []
    with open(csv_path, 'r', encoding='utf-8-sig') as f:
        reader = csv.reader(f)
        next(reader)  # skip header
        for r in reader:
            rows.append(r)
    return rows
