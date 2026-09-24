# -*- coding: utf-8 -*-
"""原图 | 合并图 并排对照（横拼，中间留黑缝）"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import read_png, Image, write_png

SRC = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\images\panel_bg.png"
MERGED = os.path.join(HERE, "_panel_probe", "merged_full.png")
a = read_png(SRC)
b = read_png(MERGED)

gap = 10
o = Image(a.w + gap + b.w, max(a.h, b.h))
o.px[:] = bytes([20, 20, 20, 255]) * (o.w * o.h)
for yy in range(a.h):
    for xx in range(a.w):
        i = (yy*a.w + xx)*4
        o.put(xx, yy, (a.px[i], a.px[i+1], a.px[i+2], a.px[i+3]))
for yy in range(b.h):
    for xx in range(b.w):
        i = (yy*b.w + xx)*4
        o.put(a.w+gap+xx, yy, (b.px[i], b.px[i+1], b.px[i+2], b.px[i+3]))
write_png(os.path.join(HERE, "_panel_probe", "merged_side_by_side.png"), o)
print("wrote merged_side_by_side.png", o.w, o.h)
