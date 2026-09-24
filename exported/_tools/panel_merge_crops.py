# -*- coding: utf-8 -*-
"""裁出分隔带/左右边框的放大片，供人工（AI 视觉）确认结构"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import read_png, Image

PNG = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\images\panel_bg.png"
OUT = os.path.join(HERE, "_panel_probe")
os.makedirs(OUT, exist_ok=True)
im = read_png(PNG)
W, H = im.w, im.h

def crop_zoom(x0, y0, x1, y1, z):
    cw, ch = (x1 - x0), (y1 - y0)
    out = Image(cw * z, ch * z)
    for y in range(ch):
        for x in range(cw):
            c = im.get(x0 + x, y0 + y)
            for dz in range(z):
                for dx in range(z):
                    out.put(x * z + dx, y * z + dz, c)
    return out

def vstack(ims, gap=6):
    w = max(i.w for i in ims)
    h = sum(i.h for i in ims) + gap * (len(ims) - 1)
    out = Image(w, h)
    out.px[:] = bytes([30, 30, 30, 255]) * (w * h)
    y = 0
    for i in ims:
        for yy in range(i.h):
            for xx in range(i.w):
                out.put(xx, y + yy, i.get(xx, yy))
        y += i.h + gap
    return out

def save(im_, name):
    from pnglib import write_png
    p = os.path.join(OUT, name)
    write_png(p, im_)
    print("wrote", p)

# 1) 分隔带全宽 x2（左角+中段+右角）
save(crop_zoom(160, 285, 1170, 350, 2), "divider_band_x2.png")

# 2) 右边框对比 x4：上框中段 vs 下框中段 vs 分隔区右角
save(vstack([
    crop_zoom(1105, 140, 1165, 180, 4),   # 上框右边（直段）
    crop_zoom(1105, 430, 1165, 470, 4),   # 下框右边（直段）
    crop_zoom(1105, 290, 1165, 345, 4),   # 分隔区右角
]), "right_border_cmp_x4.png")

# 3) 左边框对比 x4
save(vstack([
    crop_zoom(165, 140, 225, 180, 4),
    crop_zoom(165, 430, 225, 470, 4),
    crop_zoom(165, 290, 225, 345, 4),
]), "left_border_cmp_x4.png")
