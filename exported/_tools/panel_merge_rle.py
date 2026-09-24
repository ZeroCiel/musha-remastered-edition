# -*- coding: utf-8 -*-
"""RLE 色段探针：把关键行/列的颜色段打出来，精确定位两框边框线"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import read_png

PNG = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\images\panel_bg.png"
im = read_png(PNG)
W, H = im.w, im.h

def col(x, y):
    i = (y * W + x) * 4
    p = im.px
    return (p[i], p[i+1], p[i+2])

def rle(items, tol=12):
    out = []
    for c in items:
        if out and sum(abs(a - b) for a, b in zip(out[-1][0], c)) <= tol:
            out[-1][1] += 1
        else:
            out.append([c, 1])
    return out

def fmt(runs, off=0):
    parts = []
    for c, n in runs:
        parts.append("%s*%d" % (",".join("%d" % v for v in c), n))
    return " | ".join(parts)

def row(y, x0, x1):
    print("ROW y=%d x%d..%d:" % (y, x0, x1))
    print("  " + fmt(rle([col(x, y) for x in range(x0, x1 + 1)]), x0))

def vcol(x, y0, y1):
    print("COL x=%d y%d..%d:" % (x, y0, y1))
    print("  " + fmt(rle([col(x, y) for y in range(y0, y1 + 1)]), y0))

print("===== LEFT side rows =====")
for y in (160, 250, 300, 310, 318, 326, 340, 450, 600, 700):
    row(y, 165, 230)

print("===== RIGHT side rows =====")
for y in (160, 250, 300, 310, 318, 326, 340, 450, 600, 700):
    row(y, 1100, 1165)

print("===== LEFT border columns =====")
for x in (178, 187, 200):
    vcol(x, 130, 350)

print("===== RIGHT border columns =====")
for x in (1117, 1135, 1145):
    vcol(x, 130, 350)

print("===== divider full-width spot checks (is band uniform along x?) =====")
for y in (310, 318, 326):
    row(y, 400, 470)
    row(y, 700, 770)
