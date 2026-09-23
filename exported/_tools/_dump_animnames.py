# -*- coding: utf-8 -*-
"""从生产 anim.bin 里把所有「长度前缀字符串」抓出来，看重名图层到底怎么编号"""
import zipfile, struct, os, collections
M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
d = zipfile.ZipFile(os.path.join(M, "anim", "musha.zip")).read("anim.bin")
print("anim.bin", len(d), "字节")
found = []
i = 0
while i < len(d) - 8:
    ln = struct.unpack("<I", d[i:i+4])[0]
    if 1 <= ln <= 40 and i + 4 + ln <= len(d):
        s = d[i+4:i+4+ln]
        if all(32 <= c < 127 for c in s) and s[0:1].isalpha():
            found.append((i, s.decode()))
            i += 4 + ln
            continue
    i += 1
print("抓到长度前缀字符串", len(found), "个")
# 打印姓名表（连续成片的那段，一般在末尾）
tail = [f for f in found if f[0] > len(d) - 4000]
print("末尾 4000 字节内的字符串 %d 个：" % len(tail))
for off, s in tail[:120]:
    print("   @%d %s" % (off, s))
