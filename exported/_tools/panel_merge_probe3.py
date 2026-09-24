# -*- coding: utf-8 -*-
"""右星逐行轮廓 y355..400 / 左小星精确 bbox"""
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

def star_px(c):
    gold = c[0] > 200 and c[1] > 150 and c[2] < 125
    blk = c[0] < 90 and c[1] < 90 and c[2] < 90
    wht = c[0] > 238 and c[1] > 238 and c[2] > 235
    return gold or blk or wht

def runs(ys, xs, cond):
    out = []
    cur = None
    for x in xs:
        if cond(x, ys):
            if cur is None: cur = [x, x]
            else: cur[1] = x
        else:
            if cur: out.append(tuple(cur)); cur = None
    if cur: out.append(tuple(cur))
    return out

print("== right star per-row runs (x1075..1150) ==")
for y in range(320, 400, 3):
    r = runs(y, range(1075, 1151), lambda x, yy: star_px(g(x, yy)))
    if r: print(" y=%d %s" % (y, r))

print("== left small star per-row runs (x210..245), peach/gold body+halo ==")
def peach(c):
    return c[0] > 240 and c[1] > 195 and c[1] < 245 and c[2] < 205
for y in range(272, 306):
    r = runs(y, range(210, 246), lambda x, yy: peach(g(x, yy)))
    if r: print(" y=%d %s" % (y, r))
