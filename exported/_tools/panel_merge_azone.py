# -*- coding: utf-8 -*-
"""A区(y304..328)里原图的星样像素分布 —— 决定 A 是否需要星体保护"""
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

def starish(c):
    r, gg, bb = c
    if r > 190 and gg > 140 and bb < 125: return True
    if r < 100 and gg < 100 and bb < 100: return True
    if r > 235 and gg > 235 and bb > 230: return True
    return False

hits = [(x, y, g(x, y)) for y in range(304, 329) for x in range(191, 1143) if starish(g(x, y))]
print("A-zone starish px total:", len(hits))
print("by y:", sorted(Counter(t[1] for t in hits).items()))
print("by x-range groups:")
xs = sorted(set(t[0] for t in hits))
groups = []
for x in xs:
    if groups and x <= groups[-1][1] + 3:
        groups[-1][1] = x
    else:
        groups.append([x, x])
for gp in groups:
    print("   x%d..%d" % (gp[0], gp[1]))
for t in hits[:60]:
    print("  ", t)
