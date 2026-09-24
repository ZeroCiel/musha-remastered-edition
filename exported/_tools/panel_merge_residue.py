# -*- coding: utf-8 -*-
"""残留明细：左区30px变色星点 / 右星bbox精确 / 原图y329-343弧位"""
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

def starish(c):
    r, gg, bb = c
    if r > 190 and gg > 140 and bb < 125: return True
    if r < 100 and gg < 100 and bb < 100: return True
    if r > 235 and gg > 235 and bb > 230: return True
    return False

def rle(seq, tol=14):
    out = []
    for c in seq:
        if out and sum(abs(p-q) for p, q in zip(out[-1][0], c)) <= tol:
            out[-1][1] += 1
        else:
            out.append([c, 1])
    return " | ".join("%d,%d,%d*%d" % (c[0], c[1], c[2], n) for c, n in out)

print("== left altered starish px (merged starish, != original), x191..230 y329..358 ==")
n = 0
for y in range(329, 359):
    for x in range(191, 231):
        mb, ab = g(b, x, y), g(a, x, y)
        if starish(mb) and mb != ab:
            n += 1
            if n <= 40:
                print("   (%d,%d) orig=%s merged=%s" % (x, y, ab, mb))
print("   total:", n)

print("== right star precise bbox (starish incl halo), x1085..1130 y335..375 ==")
xs, ys = [], []
for y in range(335, 376):
    for x in range(1085, 1131):
        if starish(g(a, x, y)):
            xs.append(x); ys.append(y)
print("   bbox x%d..%d y%d..%d n=%d" % (min(xs), max(xs), min(ys), max(ys), len(xs)))

print("== original rows (arc zone) x1104..1140 ==")
for y in (329, 332, 336, 340, 343):
    print(" y=%d:" % y, rle([g(a, x, y) for x in range(1104, 1141)]))

print("== left big star precise bbox, x205..275 y325..372 ==")
xs, ys = [], []
for y in range(325, 373):
    for x in range(205, 276):
        if starish(g(a, x, y)):
            xs.append(x); ys.append(y)
print("   bbox x%d..%d y%d..%d n=%d" % (min(xs), max(xs), min(ys), max(ys), len(xs)))

print("== original left rows x191..240 (arc + star zone) ==")
for y in (329, 332, 336, 340, 345):
    print(" y=%d:" % y, rle([g(a, x, y) for x in range(191, 241)]))
