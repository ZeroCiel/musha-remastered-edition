# -*- coding: utf-8 -*-
"""补探：左上小星 bbox / 右角星 bbox / 行372 干净度 / 行270 在左角的色段"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import read_png

SRC = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\images\panel_bg.png"
im = read_png(SRC)
W, H = im.w, im.h

def g(x, y):
    i = (y*W + x)*4
    p = im.px
    return (p[i], p[i+1], p[i+2])

def rle(seq, tol=14):
    out = []
    for c in seq:
        if out and sum(abs(p-q) for p, q in zip(out[-1][0], c)) <= tol:
            out[-1][1] += 1
        else:
            out.append([c, 1])
    return " | ".join("%d,%d,%d*%d" % (c[0], c[1], c[2], n) for c, n in out)

# 1) 左上小星：淡橙 = r 高、g 中、b 明显低于纸底(>200)的像素，x200..245 y270..300
print("== left small star scan (peach: r>240 and b<200 and g>190) ==")
xs, ys = [], []
for y in range(268, 302):
    for x in range(200, 246):
        c = g(x, y)
        if c[0] > 240 and 190 < c[1] and c[2] < 200:
            xs.append(x); ys.append(y)
if xs:
    print("bbox x %d..%d y %d..%d n=%d" % (min(xs), max(xs), min(ys), max(ys), len(xs)))
print("row283 x205..240:", rle([g(x, 283) for x in range(205, 241)]))
print("row290 x205..240:", rle([g(x, 290) for x in range(205, 241)]))

# 2) 右角星完整 bbox（金/黑/白晕）
print("== right star bbox x1075..1150 y318..375 ==")
xs, ys = [], []
for y in range(318, 376):
    for x in range(1075, 1151):
        c = g(x, y)
        gold = c[0] > 200 and c[1] > 150 and c[2] < 125
        blk = c[0] < 90 and c[1] < 90 and c[2] < 90
        wht = c[0] > 238 and c[1] > 238 and c[2] > 235
        if gold or blk or wht:
            xs.append(x); ys.append(y)
if xs:
    print("bbox x %d..%d y %d..%d n=%d" % (min(xs), max(xs), min(ys), max(ys), len(xs)))

# 3) 行372 / 行368 干净度
for row in (368, 372, 373):
    print("row%d x1104..1142:" % row, rle([g(x, row) for x in range(1104, 1143)]))
print("row372 x1090..1105:", rle([g(x, 372) for x in range(1090, 1106)]))

# 4) 行270 左角色段（B 锚）
print("row270 x191..240:", rle([g(x, 270) for x in range(191, 241)]))
# 5) 小星区域行270 是否无星
print("row276 x205..240:", rle([g(x, 276) for x in range(205, 241)]))
