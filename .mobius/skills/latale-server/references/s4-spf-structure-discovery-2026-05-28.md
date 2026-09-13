# S4CHD SPF Structure Discovery (2026-05-28)

## SPF Header Types

S4CHD standard SPF files do NOT have a uniform `SPF\x00` header. Instead, they embed raw asset data directly, and the SPF "header" is the actual content type:

| SPF File | Size | Header | Content Type |
|----------|------|--------|-------------|
| AJJIYA.SPF | 154MB | `00000000 64000000...` | Data/index (zero header) |
| BANX.SPF | 177MB | `89504E47` (PNG) | Images |
| BARY.SPF | 586MB | `89504E47` (PNG) | Images |
| CLAIRE.SPF | 30MB | `89504E47` (PNG) | Images |
| CVOICE.SPF | 23MB | `89504E47` (PNG) | Images |
| DALBONG.SPF | 830MB | `494433` (ID3) | Audio (MP3/OGG) |
| HOSHIM.SPF | 453MB | `4658204D6F64656C` (FX Model) | 3D Models |
| JINSSAGA.SPF | 62MB | `89504E47` (PNG) | Images |
| MAKO1298.SPF | 498MB | `89504E47` (PNG) | Images |
| METALGENI.SPF | 469MB | `52494646` (RIFF) | WAV/AVI |
| ROWID.SPF | 141MB | `00000000 02000000` | LDT data container |
| RYUMS.SPF | 646MB | `89504E47` (PNG) | Images |
| ZENNE.SPF | 329MB | `34120100` | File index/directory |

Key insight: S4 SPF is NOT encrypted (unlike hisxiang S2 SPF). The non-standard headers are because the SPF "archive" is really just data files concatenated with a simple offset table — the first file's content starts immediately at offset 0.

## ROWID.SPF Structure

ROWID.SPF is the primary LDT data container. It contains most of the server-side configuration LDT files.

**Header (12 bytes):**
- Offset 0: 4 bytes — unknown (usually 0)
- Offset 4: 4 bytes — entry count (usually 2: `_Abuse` section + LDT section?)
- Offset 8: 4 bytes — offset to directory entries

**Directory Entry Format (140 bytes each):**
- 1 byte: entry marker (0x03 = regular file)
- 128 bytes: path string (null-terminated, padded), ASCII encoding, format `DATA/LDT/FILENAME.LDT`
- 4 bytes: content position (uint32 offset into SPF)
- 4 bytes: content size (uint32) — may be overestimated, actual data may be shorter
- 4 bytes: unknown index/marker

## LDT File Content Discovery

To find which SPF contains a specific LDT file, scan the entire binary for the string pattern `DATA/LDT/<FILENAME>`:

```python
import os

def find_ldt_in_spfs(spf_dir, target_filename):
    """Find which SPF archive contains a specific LDT file."""
    for fname in os.listdir(spf_dir):
        if not fname.upper().endswith('.SPF'):
            continue
        fpath = os.path.join(spf_dir, fname)
        with open(fpath, 'rb') as f:
            data = f.read()
        pattern = f'DATA/LDT/{target_filename}'.encode()
        if pattern in data:
            idx = data.find(pattern)
            print(f'{fname}: {target_filename} at offset 0x{idx:x}')
```

Then extract LDT content by finding the directory entry (140 bytes before the filename string):

```python
# The directory entry is typically 140 bytes:
# [1 byte marker][128 bytes path][4 bytes position][4 bytes size][4 bytes index]
# The path starts at entry_offset + 1
entry_offset = filename_offset - 1  # 1 byte before filename is the marker
marker = data[entry_offset]
path = data[entry_offset+1:entry_offset+129].rstrip(b'\x00').decode('ascii')
content_pos = struct.unpack('<I', data[entry_offset+129:entry_offset+133])[0]
content_size = struct.unpack('<I', data[entry_offset+133:entry_offset+137])[0]

# Read the actual content
ldt_data = data[content_pos:content_pos+content_size]
```

## LOCALIZE.LDT Content (2026-05-28)

Found in ROWID.SPF at path `DATA/LDT/LOCALIZE.LDT`.

**Content**: This is a **keyword filter/ban list** (敏感词/脏词库), NOT localization text. It contains lists of profanity, slurs, and inappropriate terms used for chat filtering.

Decoded as GBK, the first entries are: 妈逼, 阴蒂, 龟头, 操, 操你妈, 勃起, 精子, 精虫, 射精, 早泄, 阳萎, 中出, 奸淫, 奸杀, 贱人, 阴茎, 阴道, 包皮, 屁眼, 乳头, 奶头, etc.

The file is ~48MB (possibly overestimated — actual filtering data is likely smaller).

## Conclusion

S4CHD SPF files are NOT encrypted and can be read directly. The challenge is understanding the ROWID.SPF container format to locate and extract individual LDT files for modification. The `解包-打包.EXE` tool (GUI) is the recommended way, but binary scanning works when automation is needed.
