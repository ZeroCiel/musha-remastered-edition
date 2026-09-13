# SPF Size-Change Rebuild (2026-05-24)

## Problem

Replacing a file inside an SPF archive when the replacement has a **different size** than the original. In-place overwrite is impossible because the byte layout would shift all subsequent entries.

## Solution: Append + Remap

1. Zero out the old data block
2. Append the new data **at the end of the SPF file**
3. Update the 140-byte directory entry to point to the new position and size

## Latest Verification (2026-05-24)

6 text LDTs were replaced in ROWID.SPF using this technique:

| File | Original Size | New Size | Result |
|------|--------------|----------|--------|
| GLOBAL_STRING.LDT | 110,575 | 300,079 | ✅ |
| LOCALIZE.LDT | 9,983 | 12,732 | ✅ |
| NPCTALK.LDT | 4,730,058 | 13,841,665 | ✅ |
| SKILL_TXT.LDT | 784,234 | 588,812 | ✅ |
| UI_TOOLTIP.LDT | 48,507 | 141,139 | ✅ |
| WORLD_MAP_STAGE.LDT | 55,192 | 50,665 | ✅ |

**Total growth**: 150,704,964 → 165,640,056 bytes (+14.9MB)

All replacements were **guofu (Chinese S4) simplified-Chinese versions** of these text-only LDTs. Sizes differ because S4 has more rows/content.

## Python Implementation

```python
import struct, re

with open('ROWID.SPF', 'rb') as f:
    spf = bytearray(f.read())

files_to_replace = {
    'DATA/LDT/GLOBAL_STRING.LDT': 'path/to/new/global_string.ldt',
    'DATA/LDT/WORLD_MAP_STAGE.LDT': 'path/to/new/world_map.ldt',
    # ... add more as needed
}

new_data_pos = len(spf)

for entry_off, path, old_pos, old_size in find_entries(spf, files_to_replace.keys()):
    # Zero old data
    spf[old_pos:old_pos+old_size] = b'\x00' * old_size
    
    # Read new data
    with open(files_to_replace[path], 'rb') as f:
        new_content = f.read()
    
    # Append
    spf.extend(new_content)
    
    # Update directory
    struct.pack_into('<I', spf, entry_off+129, new_data_pos)
    struct.pack_into('<I', spf, entry_off+133, len(new_content))
    
    new_data_pos += len(new_content)

with open('ROWID.SPF', 'wb') as f:
    f.write(spf)
```

## Caveats

- Creates zero-filled holes in the SPF. Does NOT affect gameplay — servers use directory entries, not sequential scanning.
- Always backup original SPF before modifying (`shutil.copy2`).
- Verify by checking that the server starts and the replaced text appears correctly in-game.
- After replacement, set `pack = 1` in configure.ini (read from SPF) not `pack = 0` (extracted directory).

## ROWID.SPF Entry Finder

```python
import re, struct

with open('ROWID.SPF', 'rb') as f:
    data = f.read()

entries = []
for m in re.finditer(b'\\x03', data):
    off = m.start()
    if off + 140 > len(data):
        break
    path = data[off+1:off+129].rstrip(b'\\x00')
    if not path:
        continue
    try:
        path_str = path.decode('ascii', errors='replace').strip()
        if not path_str or len(path_str) < 3:
            continue
    except:
        continue
    
    content_pos = struct.unpack('<I', data[off+129:off+133])[0]
    content_size = struct.unpack('<I', data[off+133:off+137])[0]
    
    if 0 < content_pos < len(data) and content_size > 0:
        entries.append((off, path_str, content_pos, content_size))

print(f"Total entries: {len(entries)}")
```

## Key Insight

The SPF format uses directory-based (not sequential) file access. Each entry has an explicit position + size. This means:
- **Old data blocks can be safely abandoned** (zeroed or left as-is — server won't read them)
- **New data blocks can go anywhere** (typically appended to end)
- **No need to rebuild the entire SPF** — just update the directory entry
- **File size always grows** (old data still occupies space unless zeroed)

This makes SPF patching practical even for large (150MB+) archives with thousands of entries.
