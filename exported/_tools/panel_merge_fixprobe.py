# -*- coding: utf-8 -*-
"""右角异物定位：原图 vs 合并图 的列/行像素对比"""
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

def rle(seq, tol=14):
    out = []
    for c in seq:
        if out and sum(abs(p-q) for p, q in zip(out[-1][0], c)) <= tol:
            out[-1][1] += 1
        else:
            out.append([c, 1])
    return " | ".join("%d,%d,%d*%d" % (c[0], c[1], c[2], n) for c, n in out)

print("== original row270 x1098..1145 ==")
print(rle([g(a, x, 270) for x in range(1098, 1146)]))
print("== original row290 x1098..1145 ==")
print(rle([g(a, x, 290) for x in range(1098, 1146)]))
print("== original col x1108 y255..335 ==")
print(rle([g(a, 1108, y) for y in range(255, 336)]))
print("== merged col x1108 y255..335 ==")
print(rle([g(b, 1108, y) for y in range(255, 336)]))
print("== original row350 x1100..1145 (right star zone) ==")
print(rle([g(a, x, 350) for x in range(1100, 1146)]))
print("== original star bbox scan: gold pixels x1095..1148 y325..372 ==")
xs, ys = [], []
for y in range(325, 373):
    for x in range(1095, 1149):
        c = g(a, x, y)
        if c[0] > 200 and c[1] > 150 and c[2] < 120:
            xs.append(x); ys.append(y)
if xs:
    print("gold bbox x %d..%d  y %d..%d  n=%d" % (min(xs), max(xs), min(ys), max(ys), len(xs)))
