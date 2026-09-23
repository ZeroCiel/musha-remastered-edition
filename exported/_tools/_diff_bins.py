# -*- coding: utf-8 -*-
"""逐字节对比，看差异到底集中在哪（验证「只有名字不同」）"""
import zipfile, os, struct, hashlib

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
NEW = os.path.join(M, "exported", "_tools", "_test_out", "scmltest2", "out", "anim", "cloth_v01.zip")
PROD = os.path.join(M, "anim", "musha.zip")

def get(p, n):
    return zipfile.ZipFile(p).read(n)

for name in ("build.bin", "anim.bin"):
    a, b = get(NEW, name), get(PROD, name)
    n = min(len(a), len(b))
    diffs = [i for i in range(n) if a[i] != b[i]]
    print("=" * 60)
    print(f"{name}: 新 {len(a)} / 生产 {len(b)}；不同字节 {len(diffs)} 处（按 %.1f%%~%.1f%% 位置）"
          % (100.0 * diffs[0] / n if diffs else 0, 100.0 * diffs[-1] / n if diffs else 0))
    # 差异区间
    ranges = []
    for i in diffs:
        if ranges and i - ranges[-1][1] <= 8:
            ranges[-1][1] = i
        else:
            ranges.append([i, i])
    print(f"  差异区间 {len(ranges)} 段：")
    for r0, r1 in ranges[:14]:
        print("    @%-8d..%-8d (%d 字节)  新=%s  生产=%s"
              % (r0, r1, r1 - r0 + 1, a[r0:r1+1][:24].hex(), b[r0:r1+1][:24].hex()))
    if len(ranges) > 14:
        print("    …还有 %d 段" % (len(ranges) - 14))
    if not diffs and len(a) == len(b):
        print("  ✅ 完全相同")
