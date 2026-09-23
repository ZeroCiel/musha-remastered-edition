# -*- coding: utf-8 -*-
"""快速看几张候选图（ASCII + 主色），找出"洛可可 torso 测试图"到底是哪张"""
import os, sys, colorsys, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png

CAND = [
    r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\图片\4db54644-e5bf-4f5d-858d-d275975ed3d9.png",
    r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\图片\134ae705-4b45-4d72-a2ec-fcbc79cdf560.png",
    r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\图片\85c74359-428e-4fca-a82c-d9709b75cd91.png",
    r"D:\Backup\Pictures\Screenshots\屏幕截图 2026-09-18 005108.png",
]
def cls(r, g, b):
    h, s, v = colorsys.rgb_to_hsv(r/255, g/255, b/255)
    d = h*360
    if s < 0.15: return "." if v > 0.75 else ("#" if v > 0.4 else "@")
    c = "r" if d<20 or d>=340 else "o" if d<45 else "y" if d<70 else "g" if d<160 else "c" if d<200 else "b" if d<265 else "p"
    return c if v < 0.3 else c.upper()

for p in CAND:
    if not os.path.exists(p):
        print("缺失:", p); continue
    im = read_png(p)
    cols = 46
    rows = max(1, int(cols * im.h / im.w * 0.5))
    print("=" * 60)
    print(os.path.basename(p), "%dx%d" % (im.w, im.h))
    for ry in range(rows):
        line = []
        for rx in range(cols):
            x0, x1 = int(rx*im.w/cols), max(int(rx*im.w/cols)+1, int((rx+1)*im.w/cols))
            y0, y1 = int(ry*im.h/rows), max(int(ry*im.h/rows)+1, int((ry+1)*im.h/rows))
            R=G=B=A=n=0
            for y in range(y0, y1, max(1,(y1-y0)//12 or 1)):
                for x in range(x0, x1, max(1,(x1-x0)//12 or 1)):
                    i = (y*im.w+x)*4
                    a = im.px[i+3]
                    if a < 100: continue
                    A += a; R += im.px[i]; G += im.px[i+1]; B += im.px[i+2]; n += 1
            line.append(" " if n == 0 else cls(R//n, G//n, B//n))
        print("  " + "".join(line))
