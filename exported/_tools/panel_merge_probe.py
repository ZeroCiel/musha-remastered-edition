# -*- coding: utf-8 -*-
"""panel_bg 合并两框前的几何探针：找上下两框边框线的精确位置（输出纯 ASCII，GBK 控制台安全）"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import read_png

PNG = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\images\panel_bg.png"
im = read_png(PNG)
W, H = im.w, im.h
print("size", W, H)

def px(x, y):
    i = (y * W + x) * 4
    p = im.px
    return (p[i], p[i+1], p[i+2], p[i+3])

def scan_v(x, y0, y1, thr=18):
    prev = px(x, y0)
    out = []
    for y in range(y0 + 1, y1 + 1):
        c = px(x, y)
        d = abs(c[0]-prev[0]) + abs(c[1]-prev[1]) + abs(c[2]-prev[2])
        if d > thr:
            out.append((y, prev[:3], c[:3]))
        prev = c
    return out

def scan_h(y, x0, x1, thr=18):
    prev = px(x0, y)
    out = []
    for x in range(x0 + 1, x1 + 1):
        c = px(x, y)
        d = abs(c[0]-prev[0]) + abs(c[1]-prev[1]) + abs(c[2]-prev[2])
        if d > thr:
            out.append((x, prev[:3], c[:3]))
        prev = c
    return out

print("-- vertical edges (band region y=250..390)")
for x in (250, 450, 650, 900, 1050):
    e = scan_v(x, 250, 390)
    print("x=%d:" % x, ["y=%d %s->%s" % t for t in e])

print("-- vertical edges (top box top y=80..160)")
for x in (250, 650, 1050):
    e = scan_v(x, 80, 160)
    print("x=%d:" % x, ["y=%d %s->%s" % t for t in e])

print("-- vertical edges (bottom box bottom y=680..760)")
for x in (250, 650, 1050):
    e = scan_v(x, 680, 758)
    print("x=%d:" % x, ["y=%d %s->%s" % t for t in e])

print("-- horizontal edges y=150 (inside top box)")
print(["x=%d %s->%s" % t for t in scan_h(150, 150, 1199)])

print("-- horizontal edges y=310 (top box bottom border)")
print(["x=%d %s->%s" % t for t in scan_h(310, 150, 1199, 12)])

print("-- horizontal edges y=320 (band between boxes)")
print(["x=%d %s->%s" % t for t in scan_h(320, 150, 1199, 12)])

print("-- horizontal edges y=335 (bottom box top border area)")
print(["x=%d %s->%s" % t for t in scan_h(335, 150, 1199, 12)])

print("-- horizontal edges y=450 (inside bottom box)")
print(["x=%d %s->%s" % t for t in scan_h(450, 150, 1199)])

print("-- sample colors")
for name, xy in [("top paper", (650, 180)), ("band bg", (650, 320)),
                 ("bot paper", (650, 360)), ("lined paper", (650, 420)),
                 ("page bg (outside boxes)", (650, 95)), ("left rail", (100, 400))]:
    print(name, px(*xy))
