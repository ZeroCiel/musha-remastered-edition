# -*- coding: utf-8 -*-
"""原图 vs 合并图 右角/左角对比（上下拼）"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import read_png, Image, write_png

SRC = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\images\panel_bg.png"
MERGED = os.path.join(HERE, "_panel_probe", "merged_full.png")

a = read_png(SRC)
b = read_png(MERGED)

def crop_zoom(x0, y0, x1, y1, z, img):
    o = Image((x1-x0)*z, (y1-y0)*z)
    for yy in range(y1-y0):
        for xx in range(x1-x0):
            c = img.get(x0+xx, y0+yy)
            for dz in range(z):
                for dx in range(z):
                    o.put(xx*z+dx, yy*z+dz, c)
    return o

def vstack(ims, gap=8):
    w = max(i.w for i in ims)
    h = sum(i.h for i in ims) + gap*(len(ims)-1)
    o = Image(w, h)
    o.px[:] = bytes([40, 40, 40, 255]) * (w*h)
    y = 0
    for i in ims:
        for yy in range(i.h):
            for xx in range(i.w):
                o.put(xx, y+yy, i.get(xx, yy))
        y += i.h + gap
    return o

# 右角（含那根垂线）：x1095..1150, y255..380
v = vstack([crop_zoom(1095, 255, 1150, 380, 4, a),
            crop_zoom(1095, 255, 1150, 380, 4, b)])
write_png(os.path.join(HERE, "_panel_probe", "cmp_right_corner.png"), v)

# 左角（含星）：x185..275, y270..375
v = vstack([crop_zoom(185, 270, 275, 375, 4, a),
            crop_zoom(185, 270, 275, 375, 4, b)])
write_png(os.path.join(HERE, "_panel_probe", "cmp_left_corner.png"), v)
print("ok")
