#!/usr/bin/env python3
"""Extract Latale SPF archives. FINFO entries at end, 140B each, read backwards."""
import struct, os, sys

ENTRY_SIZE = 140  # 128B filename + 4B offset + 4B size + 4B ResID

def extract_spf(spf_path, out_dir):
    with open(spf_path, 'rb') as f:
        data = f.read()
    
    file_size = len(data)
    entries = []
    ptr = file_size - ENTRY_SIZE * 2  # skip sentinel
    
    while ptr >= 0:
        path_raw = data[ptr:ptr+128]
        null_pos = path_raw.find(b'\x00')
        if null_pos < 0: null_pos = 128
        path = path_raw[:null_pos].decode('latin-1', errors='replace')
        
        content_pos = struct.unpack_from('<i', data, ptr + 128)[0]
        content_size = struct.unpack_from('<i', data, ptr + 132)[0]
        index = struct.unpack_from('<i', data, ptr + 136)[0]
        
        if content_pos == 0 or not path.strip():
            break
        
        entries.append({
            'path': path.strip(), 'pos': content_pos,
            'size': content_size, 'index': index,
        })
        ptr -= ENTRY_SIZE
    
    entries.reverse()
    
    if not entries: return []
    
    os.makedirs(out_dir, exist_ok=True)
    extracted = 0
    for entry in entries:
        safe_path = entry['path'].replace('/', os.sep).replace('\\', os.sep).lstrip(os.sep)
        out_path = os.path.join(out_dir, safe_path)
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        file_data = data[entry['pos']:entry['pos'] + entry['size']]
        with open(out_path, 'wb') as f:
            f.write(file_data)
        extracted += 1
    
    print(f"提取完成: {extracted}/{len(entries)} → {out_dir}")
    return entries

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <SPF文件> <输出目录>")
        sys.exit(1)
    extract_spf(sys.argv[1], sys.argv[2])
