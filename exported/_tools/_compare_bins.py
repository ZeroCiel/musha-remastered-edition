# -*- coding: utf-8 -*-
"""对比新编 zip 与生产 anim/musha.zip 的 build.bin / anim.bin"""
import zipfile, hashlib, os, struct, sys

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
NEW = os.path.join(M, "exported", "_tools", "_test_out", "scmltest2", "out", "anim", "cloth_v01.zip")
PROD = os.path.join(M, "anim", "musha.zip")

def info(p):
    z = zipfile.ZipFile(p)
    out = {}
    for n in z.namelist():
        d = z.read(n)
        out[n] = (len(d), hashlib.md5(d).hexdigest()[:12])
    return out

a, b = info(NEW), info(PROD)
print("新编:", os.path.basename(NEW))
for k, v in sorted(a.items()):
    print("   %-14s %9d  %s" % (k, v[0], v[1]))
print("生产:", os.path.basename(PROD))
for k, v in sorted(b.items()):
    print("   %-14s %9d  %s" % (k, v[0], v[1]))
for k in ("build.bin", "anim.bin"):
    if k in a and k in b:
        print(f"  {k}: {'完全相同' if a[k][1]==b[k][1] else '不同 (新 %d / 生产 %d 字节)'%(a[k][0], b[k][0])}")

# 轻量结构对比：BILD / ANIM 头里的计数
def head(p, name):
    z = zipfile.ZipFile(p); d = z.read(name)
    print(f"\n{name} @{os.path.basename(p)}: 魔数 {d[:4]!r} 版本 {struct.unpack('<I', d[4:8])[0]}")
    return d

dn, dp = head(NEW, "build.bin"), head(PROD, "build.bin")
an, ap = head(NEW, "anim.bin"), head(PROD, "anim.bin")
print("\nbuild.bin 前 8 个 int:", struct.unpack("<8i", dn[8:40]), " vs 生产", struct.unpack("<8i", dp[8:40]))
print("anim.bin  前 8 个 int:", struct.unpack("<8i", an[8:40]), " vs 生产", struct.unpack("<8i", ap[8:40]))
