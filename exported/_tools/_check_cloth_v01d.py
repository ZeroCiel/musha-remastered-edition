# -*- coding: utf-8 -*-
"""musha_cloth_v01 三份素材三角对照：zip(Downloads) / exported/musha 项目 / _bak_musha_outfit / _src_art"""
import os, hashlib, struct, sys, colorsys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
Z = r"C:\Users\Administrator\AppData\Local\Temp\clothv01"
PROJ = os.path.join(M, "exported", "musha")
BAK = os.path.join(M, "exported", "_bak_musha_outfit")
SRC = os.path.join(M, "exported", "_src_art")

def md5(p):
    return hashlib.md5(open(p, "rb").read()).hexdigest()[:8]

print("=== _src_art 里有什么 ===")
for root, dirs, files in os.walk(SRC):
    rel = os.path.relpath(root, SRC)
    if files:
        print("  ", rel, "->", len(files), "个:", files[:8])

def where(sym, fn):
    cands = [("zip", os.path.join(Z, fn)),
             ("proj", os.path.join(PROJ, sym, fn)),
             ("bak", os.path.join(BAK, sym, fn))]
    out = []
    for tag, p in cands:
        out.append((tag, md5(p) if os.path.exists(p) else "----"))
    return out

print("\n=== 服装 5 件套 逐帧三方对照（zip / 项目 / _bak原图）===")
for sym, n in [("torso", 11), ("torso_pelvis", 11), ("skirt", 5), ("arm_upper", 7), ("arm_lower", 7), ("arm_upper_skin", 3)]:
    print(f"  --- {sym} ---")
    for i in range(n):
        fn = f"{sym}-{i}.png"
        print(f"    {fn:22s} " + "  ".join(f"{t}={h}" for t, h in where(sym, fn)))

def ascii_view(path, cols=44, title=""):
    from pnglib import read_png
    im = read_png(path)
    rows = max(1, int(cols * im.h / im.w * 0.5))
    lines = []
    for ry in range(rows):
        line = []
        for rx in range(cols):
            x0, x1 = int(rx*im.w/cols), max(int(rx*im.w/cols)+1, int((rx+1)*im.w/cols))
            y0, y1 = int(ry*im.h/rows), max(int(ry*im.h/rows)+1, int((ry+1)*im.h/rows))
            R=G=B=A=n=0
            for y in range(y0, y1):
                for x in range(x0, x1):
                    i = (y*im.w+x)*4
                    a = im.px[i+3]
                    if a < 120: continue
                    A += a; R += im.px[i]; G += im.px[i+1]; B += im.px[i+2]; n += 1
            if n == 0:
                line.append(" ")
            else:
                r,g,b = R//n, G//n, B//n
                h,s,v = colorsys.rgb_to_hsv(r/255, g/255, b/255)
                d = h*360
                c = "." if s < 0.18 else ("r" if d<20 or d>=340 else "o" if d<45 else "y" if d<70 else "g" if d<160 else "c" if d<200 else "b" if d<265 else "p")
                line.append(c if v < 0.3 else c.upper())
        lines.append("".join(line))
    print(f"  [{title}] {path.split(os.sep)[-1]} {im.w}x{im.h}")
    for l in lines: print("   ", l)

print("\n=== 看图：torso-8 / skirt-0（zip vs 项目）===")
for fn, sym in [("torso-8.png", "torso"), ("torso-0.png", "torso"), ("skirt-0.png", "skirt")]:
    if os.path.exists(os.path.join(Z, fn)):
        ascii_view(os.path.join(Z, fn), 44, "ZIP")
    p = os.path.join(PROJ, sym, fn)
    if os.path.exists(p):
        ascii_view(p, 44, "PROJ")
