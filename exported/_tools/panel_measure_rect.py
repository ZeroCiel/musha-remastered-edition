# -*- coding: utf-8 -*-
"""测量合并图内容框内纸边界（行/列扫描 RLE）"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import read_png

SRC = os.path.join(HERE, "_panel_probe", "merged_full.png")
im = read_png(SRC)
W, H = im.w, im.h

def g(x, y):
    i = (y*W + x)*4
    p = im.px
    return (p[i], p[i+1], p[i+2])

def rle(seq, tol=12):
    out = []
    for c in seq:
        if out and sum(abs(p-q) for p, q in zip(out[-1][0], c)) <= tol:
            out[-1][1] += 1
        else:
            out.append([c, 1])
    return " | ".join("%d,%d,%d*%d" % (c[0], c[1], c[2], n) for c, n in out)

print("== row y=430 x175..1165 ==")
print(rle([g(x, 430) for x in range(175, 1166)]))
print()
print("== col x=600 y=60..760 ==")
print(rle([g(600, y) for y in range(60, 761)]))
print()
print("== col x=260 y=60..760 ==")
print(rle([g(260, y) for y in range(60, 761)]))
