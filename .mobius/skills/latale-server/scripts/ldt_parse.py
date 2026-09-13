#!/usr/bin/env python3
"""
LDT file parser for Latale (彩虹岛) CASH_SHOP.LDT and similar files.

Usage:
  python ldt_parse.py CASH_SHOP.LDT              # Show summary and all hidden items
  python ldt_parse.py CASH_SHOP.LDT --unhide     # Generate unhidden version to stdout
  python ldt_parse.py CASH_SHOP.LDT --unhide -o output.LDT  # Write unhidden file
  python ldt_parse.py BEAUTY_SHOP.LDT            # Parse other LDT types

Based on LaTaleTools.Library.Ldt.fs format specification.
"""

import struct
import sys
import os

# Type names
TYPE_NAMES = {0: 'U32', 1: 'Str', 2: 'Bool', 3: 'S32', 4: 'Float'}


def read_ldt(data):
    """Parse LDT binary data into column names, types, and rows."""
    col_count = struct.unpack('<I', data[4:8])[0] + 1
    row_count = struct.unpack('<I', data[8:12])[0]
    
    # Column names (65 columns * 64 bytes each, starting at offset 12)
    col_names = ['_RowId']
    for n in range(col_count - 1):
        name_off = 12 + n * 64
        end = data.find(b'\x00', name_off)
        if end == -1 or end - name_off > 64:
            name = data[name_off:name_off+64].decode('utf-8', errors='replace').strip('\x00 ')
        else:
            name = data[name_off:end].decode('utf-8', errors='replace')
        col_names.append(name)
    
    # Column data types (at offset 8204)
    col_types = []
    for n in range(col_count - 1):
        t = struct.unpack('<I', data[8204 + n * 4:8204 + n * 4 + 4])[0]
        col_types.append(t)
    
    # Read rows starting at offset 8716
    rows = []
    pos = 8716
    while pos < len(data) and len(rows) < row_count:
        row = []
        try:
            for ci in range(col_count):
                ct = col_types[ci - 1] if ci > 0 else 3  # _RowId is S32
                if ci == 0:
                    val = struct.unpack('<i', data[pos:pos+4])[0]
                    pos += 4
                elif ct == 1:  # String
                    slen = struct.unpack('<H', data[pos:pos+2])[0]
                    val = data[pos+2:pos+2+slen].decode('euc-kr', errors='replace').rstrip('\x00')
                    pos += 2 + slen
                elif ct == 0:  # U32
                    val = struct.unpack('<I', data[pos:pos+4])[0]
                    pos += 4
                elif ct == 2:  # Bool
                    val = struct.unpack('<i', data[pos:pos+4])[0] == 1
                    pos += 4
                elif ct == 3:  # S32
                    val = struct.unpack('<i', data[pos:pos+4])[0]
                    pos += 4
                elif ct == 4:  # Float
                    val = struct.unpack('<f', data[pos:pos+4])[0]
                    pos += 4
                else:
                    val = None
                    pos += 4
                row.append(val)
        except struct.error:
            break
        rows.append(row)
    
    return col_names, col_types, rows, col_count, row_count


def rebuild_ldt(data, rows, col_count, col_types):
    """Rebuild LDT binary data with modified rows."""
    result = bytearray(data[:8716])  # Keep header and column defs unchanged
    
    pos = 8716
    for row in rows:
        for ci in range(col_count):
            ct = col_types[ci - 1] if ci > 0 else 3
            val = row[ci]
            if ci == 0:
                result.extend(struct.pack('<i', val))
            elif ct == 1:  # String
                encoded = val.encode('euc-kr')
                result.extend(struct.pack('<H', len(encoded)))
                result.extend(encoded)
            elif ct == 0:  # U32
                result.extend(struct.pack('<I', val))
            elif ct in (2, 3):  # Bool/S32
                int_val = 1 if val is True else (0 if val is False else val)
                result.extend(struct.pack('<i', int_val))
            elif ct == 4:  # Float
                result.extend(struct.pack('<f', val))
            else:
                result.extend(b'\x00\x00\x00\x00')
    
    return bytes(result)


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <CASH_SHOP.LDT> [--unhide] [-o output.LDT]")
        sys.exit(1)
    
    path = sys.argv[1]
    do_unhide = '--unhide' in sys.argv
    
    output_path = None
    if '-o' in sys.argv:
        idx = sys.argv.index('-o')
        if idx + 1 < len(sys.argv):
            output_path = sys.argv[idx + 1]
    
    with open(path, 'rb') as f:
        data = f.read()
    
    col_names, col_types, rows, col_count, row_count = read_ldt(data)
    
    print(f"File: {os.path.basename(path)}")
    print(f"Columns: {col_count}, Rows: {row_count}")
    print(f"Column types: {[TYPE_NAMES.get(t, f'?{t}') for t in col_types]}\n")
    
    # Find CategoryView and CategoryIndex column indices
    cat_view_idx = None
    cat_idx_idx = None
    name_idx = None
    for i, s in enumerate(col_names):
        if s == '_CategoryView':
            cat_view_idx = i
        elif s == '_CategoryIndex':
            cat_idx_idx = i
        elif s == '_Name':
            name_idx = i
    
    if cat_view_idx is None:
        print("Not a CASH_SHOP.LDT file (no _CategoryView column)")
        # Show first few rows for any LDT
        for i, row in enumerate(rows[:5]):
            print(f"\nRow {i}:")
            for j, val in enumerate(row[:10]):
                print(f"  {col_names[j]}: {val}")
        return
    
    # Group by CategoryIndex
    from collections import defaultdict
    cats = defaultdict(list)
    for row in rows:
        cats[row[cat_idx_idx]].append(row)
    
    print("=== Category Summary ===")
    for cat_idx in sorted(cats.keys()):
        items = cats[cat_idx]
        visible = sum(1 for r in items if r[cat_view_idx] == 1)
        hidden = sum(1 for r in items if r[cat_view_idx] == 0)
        print(f"  Cat {cat_idx:3d}: {len(items)} items ({visible} visible, {hidden} hidden)")
    
    if do_unhide:
        modified = False
        for row in rows:
            if row[cat_view_idx] == 0:
                row[cat_view_idx] = 1
                modified = True
        
        if modified:
            new_data = rebuild_ldt(data, rows, col_count, col_types)
            unhidden_count = sum(1 for r in rows if r[cat_view_idx] == 1)
            print(f"\n✅ Unhidden all items. Total visible: {unhidden_count}/{len(rows)}")
            
            if output_path:
                with open(output_path, 'wb') as f:
                    f.write(new_data)
                print(f"   Written to: {output_path}")
            else:
                sys.stdout.buffer.write(new_data)
        else:
            print("\nNo hidden items found.")
    
    # Always show hidden items detail
    print(f"\n=== Hidden Items ===")
    has_hidden = False
    for cat_idx in sorted(cats.keys()):
        items = cats[cat_idx]
        hidden = [r for r in items if r[cat_view_idx] == 0]
        if not hidden:
            continue
        has_hidden = True
        print(f"\n--- Cat {cat_idx} ({len(hidden)} hidden) ---")
        for r in hidden[:20]:
            name = r[name_idx] if name_idx and name_idx < len(r) else '?'
            item_ids = [r[16 + i*4] for i in range(8) if 16 + i*4 < len(r) and r[16 + i*4] > 0]
            print(f"  RowID={r[0]}, Name={name}, Items={item_ids[:3]}")
    
    if not has_hidden:
        print("  (none)")


if __name__ == '__main__':
    main()
