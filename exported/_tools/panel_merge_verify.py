# -*- coding: utf-8 -*-
"""merged 残留探针：右角暗像素 / 星外星点 / 手术区外差异"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import read_png

SRC = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\images\panel_bg.png"
MERGED = os.path.join(HERE, "_panel_probe", "merged_full.png")
a = read_png(SRC); b = read_png(MERGED)

def g(img, x, y):
    i = (y*img.w + x)*4
    p = img.px
    return (p[i], p[i+1], p[i+2])

def runs_of(pts):
    out = []
    for p in pts:
        if out and p[0] == out[-1][1] + 1 and p[1] == out[-1][2]:
            out[-1][1] = p[0]
        else:
            out.append([p[0], p[0], p[1]])
    return out

def starish(c):
    r, gg, bb = c
    if r > 190 and gg > 140 and bb < 125: return True
    if r < 100 and gg < 100 and bb < 100: return True
    if r > 235 and gg > 235 and bb > 230: return True
    return False

# 1) merged 右角暗像素 (max<140)，x1104..1150 y255..375
print("== merged dark px (max<140) x1104..1150 y255..375 ==")
dark = []
for y in range(255, 376):
    for x in range(1104, 1151):
        c = g(b, x, y)
        if max(c) < 140:
            dark.append((x, y))
for r in runs_of(sorted(dark, key=lambda t: (t[1], t[0]))):
    print("  x%d..%d y%d n? " % (r[0], r[1], r[2]))
print("  total dark:", len(dark))
if dark:
    ys = [t[1] for t in dark]; xs = [t[0] for t in dark]
    print("  bbox x%d..%d y%d..%d" % (min(xs), max(xs), min(ys), max(ys)))
    # 按列汇总
    from collections import Counter
    print("  by col:", sorted(Counter(t[0] for t in dark).items()))

# 2) 原图同窗口暗像素
dark0 = [(x, y) for y in range(255, 376) for x in range(1104, 1151) if max(g(a, x, y)) < 140]
print("== original dark count in same window:", len(dark0))
if dark0:
    xs = [t[0] for t in dark0]; ys = [t[1] for t in dark0]
    print("  bbox x%d..%d y%d..%d" % (min(xs), max(xs), min(ys), max(ys)))

# 3) 星体外的星点（应为0）：x1121..1142 y329..358 里 merged 是星样的像素
print("== starish px outside star bbox (x1121..1142, y329..358) ==")
bad = [(x, y, g(b, x, y)) for y in range(329, 359) for x in range(1121, 1143) if starish(g(b, x, y))]
print("  count:", len(bad))
for t in bad[:20]:
    print("   ", t)

# 4) 左侧同检：x231..260 y329..358 merged 的星点应只剩左星本体(原样)；查与原图差异
print("== left C-zone: merged starish outside left star x191..230 handled? ==")
badL = [(x, y, g(b, x, y)) for y in range(329, 359) for x in range(191, 231)
        if starish(g(b, x, y)) and g(b, x, y) != g(a, x, y)]
print("  altered starish px:", len(badL))

# 5) 手术区外整体差异校验（A/B/C 覆盖 = y282..358 x191..1142 + y304..328 全）
print("== diff outside surgery zones (should be 0) ==")
def in_zone(x, y):
    if 304 <= y <= 328 and 191 <= x <= 1142: return True
    if 282 <= y <= 303 and (191 <= x <= 230 or 1104 <= x <= 1142): return True
    if 329 <= y <= 358 and (191 <= x <= 230 or 1104 <= x <= 1142): return True
    return False
diff = [(x, y) for y in range(0, 769, 1) for x in range(0, 1199, 1)
        if (not in_zone(x, y)) and g(a, x, y) != g(b, x, y)]
print("  count:", len(diff), diff[:10])
