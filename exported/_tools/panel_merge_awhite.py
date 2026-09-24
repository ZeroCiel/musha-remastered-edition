# -*- coding: utf-8 -*-
"""A区 白判据像素分布（星晕/翅膀高光）——决定 A 是否加白保护"""
import os, sys
from collections import Counter
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import read_png

SRC = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\images\panel_bg.png"
im = read_png(SRC)
W = im.w

def g(x, y):
    i = (y*W + x)*4
    p = im.px
    return (p[i], p[i+1], p[i+2])

def white(c):
    return c[0] > 235 and c[1] > 235 and c[2] > 230

hits = [(x, y) for y in range(304, 329) for x in range(191, 1143) if white(g(x, y))]
print("A-zone white px total:", len(hits))
print("by y:", sorted(Counter(t[1] for t in hits).items()))
xs = sorted(set(t[0] for t in hits))
groups = []
for x in xs:
    if groups and x <= groups[-1][1] + 3:
        groups[-1][1] = x
    else:
        groups.append([x, x])
print("x groups:", [tuple(gp) for gp in groups])

# 左星晕重点：x215..260 y324..328
focus = [(x, y, g(x, y)) for y in range(324, 329) for x in range(215, 261) if white(g(x, y))]
print("left-star halo white in A(y324..328, x215..260):", len(focus))
for t in focus[:30]:
    print("  ", t)
