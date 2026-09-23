# -*- coding: utf-8 -*-
import zipfile, struct, os, collections, sys
sys.dont_write_bytecode = True
M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
for tag, path in (("生产", os.path.join(M, "anim", "musha.zip")),
                  ("我编的", os.path.join(M, "exported", "_tools", "_test_out", "scmltest2", "out", "anim", "cloth_v01.zip"))):
    d = zipfile.ZipFile(path).read("anim.bin")
    found = []; i = 0
    while i < len(d) - 8:
        ln = struct.unpack("<I", d[i:i+4])[0]
        if 1 <= ln <= 40 and i + 4 + ln <= len(d):
            s = d[i+4:i+4+ln]
            if all(32 <= c < 127 for c in s) and s[0:1].isalpha():
                found.append((i, s.decode())); i += 4 + ln; continue
        i += 1
    tbl = [s for off, s in found if off >= 153800]
    c = collections.Counter(tbl)
    print("== %s: 图层名表 %d 条；重名 %s" % (tag, len(tbl), {k: v for k, v in c.items() if v > 1}))
    print("   ", tbl)
