# -*- coding: utf-8 -*-
"""技能书概念图 → 三本书封面图标候选（只出预览，不装进 mod）2026-09-17"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import Image, read_png, write_png, blit, contact_sheet
M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
SRCF = os.path.join(M, "exported", "_src_art", "concept_技能书_战士剑士近卫_20260917.png")
OUT = os.path.join(M, "exported", "_src_art", "_cuts"); os.makedirs(OUT, exist_ok=True)
SIZE = 64
COLS = [("战士", 39, 496), ("剑士", 535, 997), ("近卫", 1023, 1497)]
BOOKY = (30, 560)     # 书封面所在行段（含边框）

def crop(im, x0, y0, x1, y1):
    w, h = x1 - x0, y1 - y0
    out = Image(w, h)
    for y in range(h):
        s = ((y0 + y) * im.w + x0) * 4
        d = (y * w) * 4
        out.px[d:d + w * 4] = im.px[s:s + w * 4]
    return out

def bbox(im, thr=16):
    px = im.px; minx, miny, maxx, maxy = 10**9, 10**9, -1, -1
    for y in range(im.h):
        base = y * im.w
        for x in range(im.w):
            if px[(base + x) * 4 + 3] > thr:
                if x < minx: minx = x
                if x > maxx: maxx = x
                if y < miny: miny = y
                if y > maxy: maxy = y
    return (minx, miny, maxx, maxy)

def scale(im, tw, th):
    out = Image(tw, th); sx = im.w / tw; sy = im.h / th
    for ty in range(th):
        y0 = int(ty * sy); y1 = min(im.h, max(y0 + 1, int((ty + 1) * sy + 0.999)))
        for tx in range(tw):
            x0 = int(tx * sx); x1 = min(im.w, max(x0 + 1, int((tx + 1) * sx + 0.999)))
            sa = 0; sr = sg = sb = 0.0; n = 0
            for y in range(y0, y1):
                base = y * im.w
                for x in range(x0, x1):
                    i = (base + x) * 4; a = im.px[i + 3]; n += 1
                    if a:
                        w_ = a / 255.0
                        sr += im.px[i] * w_; sg += im.px[i+1] * w_; sb += im.px[i+2] * w_; sa += a
            o = (ty * tw + tx) * 4
            if n == 0 or sa == 0: continue
            out.px[o + 3] = min(255, int(sa / n)); k = sa / 255.0
            out.px[o] = min(255, int(sr / k)); out.px[o+1] = min(255, int(sg / k)); out.px[o+2] = min(255, int(sb / k))
    return out

def zoom(im, z):
    out = Image(im.w * z, im.h * z)
    for y in range(im.h):
        for x in range(im.w):
            i = (y * im.w + x) * 4
            for dy in range(z):
                for dx in range(z):
                    j = ((y * z + dy) * out.w + (x * z + dx)) * 4
                    out.px[j:j+4] = im.px[i:i+4]
    return out

im = read_png(SRCF)
made = []
for name, x0, x1 in COLS:
    c = crop(im, x0, BOOKY[0], x1 + 1, BOOKY[1])
    bb = bbox(c)
    tight = crop(c, bb[0], bb[1], bb[2], bb[3])
    icon = Image(SIZE, SIZE)
    k = min((SIZE - 2) / tight.w, (SIZE - 2) / tight.h)
    tw, th = max(1, int(tight.w * k)), max(1, int(tight.h * k))
    s = scale(tight, tw, th)
    blit(icon, s, (SIZE - tw) // 2, (SIZE - th) // 2)
    p = os.path.join(OUT, "icon_技能书_%s_64.png" % name)
    write_png(p, icon)
    full = os.path.join(OUT, "book_%s_full.png" % name)
    write_png(full, tight)
    cov = sum(1 for i in range(3, len(icon.px), 4) if icon.px[i] > 40) * 100 // (SIZE * SIZE)
    print("  %s: 书封面 %dx%d -> 64x64 覆盖 %d%%  (全尺寸存 %s)" % (name, tight.w, tight.h, cov, os.path.basename(full)))
    made.append((name, icon, tight))

rows = [("64图标", [zoom(i, 4) for _, i, _ in made]),
        ("原尺寸", [zoom(t, 1) for _, _, t in made])]
p2 = r"C:\Users\Administrator\Desktop\技能书三本_切图候选_20260917.png"
contact_sheet(rows, p2, pad=10, bg=(58,58,66))
print("预览 →", p2)
