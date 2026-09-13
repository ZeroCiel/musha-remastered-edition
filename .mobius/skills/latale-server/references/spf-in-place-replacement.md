# SPF In-Place File Replacement

When you modify a file inside an SPF archive and the **file size hasn't changed** (e.g., toggling Bool fields, changing int32 values, replacing strings with same-length strings), you can do an in-place binary replacement without rebuilding the SPF.

## When to use

The file size inside the SPF **must match exactly** — the SPF directory entry has a fixed `content_size` field at a specific offset. If the file size changes, every subsequent entry's `content_pos` would shift, requiring a full SPF rebuild.

Use cases that preserve file size:
- Toggling `_CategoryView` between 0 and 1 (Bool = 4 bytes, no change)
- Changing int32 values to another int32
- Replacing a string with another string of the same byte length (after EUC-KR encoding)

## SPF Directory Entry Format

Formats vary between SPF versions. The ROWID.SPF (150MB, 286 entries) uses this verified format:

**File Header (12 bytes):**
| Offset | Size | Field |
|--------|------|-------|
| 0x00 | 4 | Magic (0) |
| 0x04 | 4 | Column count + 1 (but for SPF, seems to be 2 = version?) |
| 0x08 | 4 | Entry count (286 for ROWID.SPF) |

**Directory entries (140 bytes each, starting at offset 12):**
| Offset | Size | Field |
|--------|------|-------|
| 0 | 1 | Entry type (0x03 = regular file) |
| 1 | 128 | File path (null-terminated ASCII, padded) |
| 129 | 4 | Content position (uint32, absolute offset into SPF file) |
| 133 | 4 | Content size (uint32) |
| 137 | 4 | Index/marker (uint32, 50331667 = 0x03000013) |

Total entry size: 140 bytes. Entry count at offset 8 in header.

## Algorithm

```python
import struct

def replace_in_spf(spf_path, target_filename, new_data):
    """
    Replace a file inside an SPF archive in-place.
    
    Args:
        spf_path: Path to the .SPF file
        target_filename: Filename to find (e.g. 'CASH_SHOP.LDT')
        new_data: bytes object with the new file content
    
    Returns:
        True if replaced, False if not found
    """
    with open(spf_path, 'rb') as f:
        spf = bytearray(f.read())
    
    entry_count = struct.unpack('<I', spf[8:12])[0]
    
    for i in range(entry_count):
        off = 12 + i * 140
        try:
            path_end = spf.find(b'\x00', off + 1)
            path = spf[off + 1:path_end].decode('ascii', errors='replace')
        except:
            continue
        
        if target_filename in path:
            content_pos = struct.unpack('<I', spf[off + 129:off + 133])[0]
            content_size = struct.unpack('<I', spf[off + 133:off + 137])[0]
            
            assert len(new_data) == content_size, \
                f"Size mismatch: new={len(new_data)}, original={content_size}"
            
            spf[content_pos:content_pos + content_size] = new_data
            
            with open(spf_path, 'wb') as f:
                f.write(spf)
            
            print(f"Replaced {path} at offset 0x{content_pos:x} ({content_size} bytes)")
            return True
    
    print(f"File '{target_filename}' not found in SPF")
    return False
```

## Verified Example: CASH_SHOP.LDT in ROWID.SPF

| Property | Value |
|----------|-------|
| SPF file | `D:\Server\SPF\ROWID.SPF` |
| Target | `DATA/LDT/CASH_SHOP.LDT` |
| Content offset | 0x0C708A (815,242) |
| Content size | 0x1181A9 (1,147,305 bytes) |
| Entry offset | 0x8FB134C |
| Operation | Toggle all `_CategoryView` from 0→1 (941 changes) |

The replacement was done after modifying the extracted LDT file in `D:\Server\SPF\extracted\DATA\LDT\CASH_SHOP.LDT`, then writing back to ROWID.SPF at the exact content offset.

## Refresh Required

After replacing the file in the SPF, restart all server processes that read it:
- GameServer reads CASH_SHOP.LDT at startup
- Gateway may also cache the data
- Run `netstat -ano` to verify old processes are dead before restarting
