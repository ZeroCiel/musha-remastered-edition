# -*- coding: utf-8 -*-
"""弧线位置探针：追踪上下两框左右边框线的 x 随 y 的移动，确定弧线起止（输出纯 ASCII）"""
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

def near(c, ref, tol=40):
    return sum(abs(a-b) for a, b in zip(c, ref)) <= tol

WHITE = (255, 250, 205)      # 上框白线
GOLD  = (250, 220, 130)      # 上框金线/下框金线
DARKL = (40, 10, 5)          # 深棕描边
LINET = (205, 178, 110)      # 下框左侧细线

def find_x(y, x0, x1, ref, tol=40, step=1):
    hits = [x for x in range(x0, x1+1, step) if near(col(x, y), ref, tol)]
    return (hits[0], hits[-1]) if hits else None

print("== TOP box bottom-left corner: white line x (y250..312) ==")
for y in range(250, 313, 4):
    print(" y=%d white=%s gold=%s" % (y, find_x(y, 190, 240, WHITE), find_x(y, 195, 240, GOLD, 60)))

print("== TOP box bottom-right corner: gold band x (y250..312) ==")
for y in range(250, 313, 4):
    print(" y=%d gold=%s" % (y, find_x(y, 1100, 1150, GOLD, 70)))

print("== BOTTOM box top-left corner: line x (y324..364) ==")
for y in range(324, 365, 4):
    print(" y=%d line=%s" % (y, find_x(y, 190, 240, LINET, 70)))

print("== BOTTOM box top-right corner: white/gold x (y324..364) ==")
for y in range(324, 365, 4):
    print(" y=%d white=%s gold=%s" % (y, find_x(y, 1100, 1150, WHITE, 55), find_x(y, 1100, 1150, GOLD, 60)))

print("== sanity: anchor rows clean? ==")
for y in (260, 270, 301, 331, 370, 374, 376):
    print(" y=%d row-sample x231=%s x600=%s x1103=%s" % (y, col(231, y), col(600, y), col(1103, y)))
