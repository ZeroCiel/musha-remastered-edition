#!/usr/bin/env python3
"""
Rainbow Island (Latale) LDT Parser + Localization Tool
Parses .LDT binary files. Default encoding: GB18030 (Simp Chinese).
"""
import struct, os, sys

DEFAULT_ENCODING = 'gb18030'

# LDT Binary Format:
# Header: i32 DB_ID | i32 nFields | i32 nData
# FieldNames: 128 x 64B strings
# FieldTypes: 128 x i32
# Data: variable per field type
# Field Types: 0=NA, 1=String(null-term), 2=TF, 3=Num, 4=Per, 5=FID, 6=Alias, 7=Num64, 255=PK

HEADER_SIZE = 12 + 128*64 + 128*4  # 8716

def parse_ldt(path):
    """Parse LDT file, return (header, rows)"""
    with open(path, 'rb') as f:
        raw = f.read()

    nDB_ID, nFields, nData = struct.unpack_from('<iii', raw, 0)
    
    field_names = []
    for i in range(min(nFields, 128)):
        name = raw[12+i*64:12+i*64+64].split(b'\x00')[0].decode('latin-1', errors='replace')
        field_names.append(name)
    
    type_offset = 12 + 128*64
    field_types = [struct.unpack_from('<i', raw, type_offset+i*4)[0] for i in range(min(nFields, 128))]
    
    rows = []
    pos = HEADER_SIZE
    for _ in range(nData):
        row = {}
        for col in range(nFields):
            ft = field_types[col]
            nm = field_names[col]
            
            if ft == 1:  # String (null-terminated)
                end = raw.find(b'\x00', pos)
                if end < 0:
                    end = pos + 256
                row[nm] = raw[pos:end]
                pos = end + 1
            elif ft in (3, 5, 6, 255):
                row[nm] = struct.unpack_from('<i', raw, pos)[0]
                pos += 4
            elif ft == 4:  # float
                row[nm] = struct.unpack_from('<f', raw, pos)[0]
                pos += 4
            elif ft in (0, 2):
                row[nm] = raw[pos:pos+4]
                pos += 4
            elif ft == 7:  # Num64
                row[nm] = raw[pos:pos+8]
                pos += 8
            else:
                pos += 4
        
        rows.append(row)
    
    return {
        'db_id': nDB_ID, 'n_fields': nFields, 'n_data': nData,
        'field_names': field_names, 'field_types': field_types,
        'raw': raw,
    }, rows

def show_ldt_info(path, encoding=DEFAULT_ENCODING):
    """Display LDT file structure"""
    header, rows = parse_ldt(path)
    print(f"\n{'='*60}")
    print(f"  {os.path.basename(path)}")
    print(f"  DB_ID={header['db_id']} | 字段={header['n_fields']} | 行={len(rows)}")
    str_fields = [i for i in range(header['n_fields']) if header['field_types'][i] == 1]
    if str_fields and rows:
        print(f"  文本字段: {[header['field_names'][i] for i in str_fields]}")
        for r in range(min(3, len(rows))):
            for sf in str_fields:
                val = rows[r][header['field_names'][sf]]
                try:
                    s = val.decode(encoding, errors='replace')
                except:
                    s = str(val)
                if len(s) > 80: s = s[:80] + '...'
                print(f"    [{r}][{header['field_names'][sf]}]: {repr(s)}")

if __name__ == '__main__':
    if len(sys.argv) > 1:
        show_ldt_info(sys.argv[1])
    else:
        print(f"Usage: {sys.argv[0]} <LDT文件路径>")
        sys.exit(1)
