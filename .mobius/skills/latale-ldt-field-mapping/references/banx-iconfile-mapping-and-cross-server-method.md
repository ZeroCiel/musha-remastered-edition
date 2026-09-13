# BANX 图标文件跨服对比方法

## 背景

他乡端（D:\LaTale\彩虹岛S2 他乡彩虹岛）和怀旧端（D:\彩虹岛）的 BANX 图标资源不同，需要对比 ITEM_2 的 _Icon 和 _IconIndex 来确定缺少哪些贴图。

## 方法

### 1. 提取两端 IconFile 集合

```python
import struct

def get_icons(d):
    cc = struct.unpack('<I', d[4:8])[0]
    rc = struct.unpack('<I', d[8:12])[0]
    # 找列索引
    icon_idx = iconidx_idx = -1
    for i in range(cc):
        off = 12+i*64
        name = d[off:off+64].split(b'\x00')[0].decode('ascii', errors='replace').strip()
        if name == '_Icon': icon_idx = i
        if name == '_IconIndex': iconidx_idx = i
    
    ct = [struct.unpack('<I', d[8204+i*4:8204+i*4+4])[0] for i in range(cc)]
    
    icons = {}
    pos = 8716
    for ri in range(rc):
        if pos+4 > len(d): break
        pos += 4
        ic = ii = 0
        for ci in range(cc):
            if pos+4 > len(d): break
            t = ct[ci]
            if t == 1:
                slen = struct.unpack('<H',d[pos:pos+2])[0]
                pos += 2 + slen
            else:
                v = struct.unpack('<I',d[pos:pos+4])[0]
                if ci == icon_idx: ic = v
                elif ci == iconidx_idx: ii = v
                pos += 4
        if ic:
            if ic not in icons: icons[ic] = set()
            icons[ic].add(ii)
    return icons
```

### 2. 对比

```
only_in_ta = sorted(ta_icons.keys() - his_icons.keys())  # 全新IconFile
for ic in common:
    extra = ta_icons[ic] - his_icons[ic]  # 已有IconFile中多出的索引
```

### 3. 他乡端GLOBALRES映射

解包目录: `D:\LaTale\彩虹岛S2 他乡彩虹岛\解包目录\BANX\DATA\GLOBALRES\`

文件名格式: `{IconIndex:04d}.PNG` (如 IconIndex=204 → 0204.PNG)
最大编号: 0923.PNG (共996个文件, 含TEMP_/ULTRA_/VSSVER等)

注意: IconFile (如10001212) 和 GLOBALRES 文件名之间没有直接的数字映射关系——映射在 BANX.SPF 的内部索引中。所以只能通过 Index 号定位具体PNG，不能通过 IconFile 值推算。

### 4. 当前端局限

怀旧端图标在 `D:\彩虹岛\BANX.SPF` 压缩包中，没有解包工具无法直接查看是否有特定图标。

### 5. 已知差异（本端无而他乡端有）

详见 `session-20260529-banx-cross-server-icon-diff.md`。
