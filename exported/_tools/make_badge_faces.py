# -*- coding: utf-8 -*-
"""表情 → 能量徽章中心图标（2026-09-16）

源：images/emotes/666.png（2×2 四格：高兴/愉悦/满足/沮丧）+ normal.png（正常）
目标：exported/energy/heart/heart-0..4.png（取代原来的绿心/金心），
      heart-0 = 能量最满 … heart-4 = 能量最低。

要点：
- 缩放用"预乘 alpha 的盒式滤波"（否则缩小时透明底的白色会渗进边缘 → 白毛边）
- normal.png 是白底线稿 → 从四边泛洪把背景抠成透明（脸内部的眼白/高光不受影响）
- 尺寸统一 FACE×FACE（正方形居中），原心是 37×29
"""
import sys, os, shutil
from collections import deque
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import Image, read_png, write_png, blit, contact_sheet

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
EMO = os.path.join(M, "exported", "_src_art")
HEART = os.path.join(M, "exported", "energy", "heart")
BAK = os.path.join(M, "exported", "energy", "_bak_金心_20260916", "heart")
DESKTOP = r"C:\Users\Administrator\Desktop"
FACE = 44          # 出图尺寸（正方形）
OUTLINE_KEEP = True

# ---------------- 工具 ----------------
def bbox(im, x0=0, y0=0, x1=None, y1=None, thr=16):
    x1 = im.w if x1 is None else x1; y1 = im.h if y1 is None else y1
    minx, miny, maxx, maxy = 10**9, 10**9, -1, -1
    px = im.px
    for y in range(y0, y1):
        base = y * im.w
        for x in range(x0, x1):
            if px[(base + x) * 4 + 3] > thr:
                if x < minx: minx = x
                if x > maxx: maxx = x
                if y < miny: miny = y
                if y > maxy: maxy = y
    if maxx < 0:
        return (0, 0, 0, 0)
    return (minx, miny, maxx, maxy)

def crop(im, x0, y0, x1, y1):
    w, h = x1 - x0 + 1, y1 - y0 + 1
    out = Image(w, h)
    for y in range(h):
        s = ((y0 + y) * im.w + x0) * 4
        d = (y * w) * 4
        out.px[d:d + w * 4] = im.px[s:s + w * 4]
    return out

def scale_to(im, tw, th):
    """预乘 alpha 盒式滤波缩放（避免白毛边）"""
    out = Image(tw, th)
    sx = im.w / tw; sy = im.h / th
    for ty in range(th):
        y0 = int(ty * sy); y1 = min(im.h, max(y0 + 1, int((ty + 1) * sy + 0.999)))
        for tx in range(tw):
            x0 = int(tx * sx); x1 = min(im.w, max(x0 + 1, int((tx + 1) * sx + 0.999)))
            sa = 0; sr = sg = sb = 0.0; n = 0
            for y in range(y0, y1):
                base = y * im.w
                for x in range(x0, x1):
                    i = (base + x) * 4
                    a = im.px[i + 3]
                    n += 1
                    if a:
                        w_ = a / 255.0
                        sr += im.px[i] * w_; sg += im.px[i + 1] * w_; sb += im.px[i + 2] * w_
                        sa += a
            o = (ty * tw + tx) * 4
            if n == 0 or sa == 0:
                continue
            out.px[o + 3] = min(255, int(sa / n))
            k = sa / 255.0
            out.px[o] = min(255, int(sr / k)); out.px[o + 1] = min(255, int(sg / k)); out.px[o + 2] = min(255, int(sb / k))
    return out

def fade_white_bg(im, thr=232):
    """从四边泛洪，把连通的白底抠成透明（脸内部的白不受影响）"""
    w, h = im.w, im.h
    px = im.px
    seen = bytearray(w * h)
    q = deque()
    def white(i):
        return px[i * 4] > thr and px[i * 4 + 1] > thr and px[i * 4 + 2] > thr
    for x in range(w):
        for y in (0, h - 1):
            if not seen[y * w + x] and white(y * w + x):
                seen[y * w + x] = 1; q.append(y * w + x)
    for y in range(h):
        for x in (0, w - 1):
            if not seen[y * w + x] and white(y * w + x):
                seen[y * w + x] = 1; q.append(y * w + x)
    while q:
        p = q.popleft()
        for nx, ny in ((p % w - 1, p // w), (p % w + 1, p // w), (p % w, p // w - 1), (p % w, p // w + 1)):
            if 0 <= nx < w and 0 <= ny < h:
                k = ny * w + nx
                if not seen[k] and white(k):
                    seen[k] = 1; q.append(k)
    cleared = 0
    for k in range(w * h):
        if seen[k]:
            px[k * 4 + 3] = 0; cleared += 1
    return cleared

def fit_center(src, size=FACE, pad=1):
    """等比缩放到 size-pad 内并居中到 size×size 透明画布"""
    bb = bbox(src)
    c = crop(src, bb[0], bb[1], bb[2], bb[3])
    inner = size - pad * 2
    if c.w >= c.h:
        tw = inner; th = max(1, int(round(c.h * inner / c.w)))
    else:
        th = inner; tw = max(1, int(round(c.w * inner / c.h)))
    s = scale_to(c, tw, th)
    out = Image(size, size)
    blit(out, s, (size - tw) // 2, (size - th) // 2)
    return out

def ascii_face(im, step=2):
    for y in range(0, im.h, step * 2):
        s = ""
        for x in range(0, im.w, step):
            i = (y * im.w + x) * 4
            r, g, b, a = im.px[i], im.px[i + 1], im.px[i + 2], im.px[i + 3]
            if a < 40: s += "."
            else:
                lum = (r * 3 + g * 6 + b) / 10
                s += " " if lum > 225 else ("-" if lum > 170 else ("o" if lum > 110 else ("+" if lum > 60 else "#")))
        print(s)

def main():
    os.makedirs(BAK, exist_ok=True)
    for f in sorted(os.listdir(HEART)):
        if f.endswith(".png"):
            shutil.copy2(os.path.join(HEART, f), os.path.join(BAK, f))
    print("旧心备份 →", BAK)

    sheet6 = read_png(os.path.join(EMO, "666.png"))
    W, H = sheet6.w, sheet6.h
    quads = [(0, 0, W // 2, H // 2), (W // 2, 0, W, H // 2), (0, H // 2, W // 2, H), (W // 2, H // 2, W, H)]
    names = ["高兴", "愉悦", "满足", "沮丧"]
    faces = []
    for (x0, y0, x1, y1), nm in zip(quads, names):
        bb = bbox(sheet6, x0, y0, x1, y1)
        c = crop(sheet6, bb[0], bb[1], bb[2], bb[3])
        faces.append((nm, fit_center(c)))
        print(f"  {nm}: 源 {bb[2]-bb[0]+1}x{bb[3]-bb[1]+1} → {FACE}x{FACE}")

    imn = read_png(os.path.join(EMO, "normal.png"))
    cleared = fade_white_bg(imn)
    bb = bbox(imn)
    print(f"  正常: 白底抠掉 {cleared} px ({cleared*100//(imn.w*imn.h)}%), 内容 bbox={bb} {bb[2]-bb[0]+1}x{bb[3]-bb[1]+1}")
    faces.append(("正常", fit_center(crop(imn, bb[0], bb[1], bb[2], bb[3]))))

    # 顺序：heart-0 能量最满 → heart-4 最低（情绪梯度：高兴→愉悦→满足→正常→沮丧）
    order = ["高兴", "愉悦", "满足", "正常", "沮丧"]
    d = dict(faces)
    for i, nm in enumerate(order):
        p = os.path.join(HEART, "heart-%d.png" % i)
        write_png(p, d[nm])
        print(f"  写出 heart-{i}.png ← {nm} ({os.path.getsize(p)}B)")

    # 预览：5 张 4 倍 + 各档徽章合成（环 + 液面 + 心）
    def zoom(im, z):
        out = Image(im.w * z, im.h * z)
        for y in range(im.h):
            for x in range(im.w):
                i = (y * im.w + x) * 4
                for dy in range(z):
                    for dx in range(z):
                        j = ((y * z + dy) * out.w + (x * z + dx)) * 4
                        out.px[j:j + 4] = im.px[i:i + 4]
        return out
    ring = read_png(os.path.join(M, "exported", "energy", "frame_circle", "frame_circle-0.png"))
    badge_row = []
    for i, val in enumerate((1.0, 0.85, 0.6, 0.35, 0.1)):
        cv = Image(100, 100)
        idx = int(round((1.0 - val) * 22))
        liq = read_png(os.path.join(M, "exported", "energy", "health_level", "health_level-%d.png" % idx))
        blit(cv, liq, 50 - liq.w // 2, 50 + 31 - liq.h)
        hh = read_png(os.path.join(HEART, "heart-%d.png" % i))
        blit(cv, hh, 50 - hh.w // 2, 50 - hh.h // 2)
        blit(cv, ring, 50 - ring.w // 2, 50 - ring.h // 2 + 1)
        badge_row.append(zoom(cv, 2))
    rows = [("表情", [zoom(d[nm], 4) for nm in order]),
            ("装进徽章", badge_row)]
    p1 = os.path.join(M, "exported", "energy", "_concept", "badge_faces_20260916.png")
    os.makedirs(os.path.dirname(p1), exist_ok=True)
    contact_sheet(rows, p1, pad=10, bg=(58, 58, 66))
    p2 = os.path.join(DESKTOP, "能量徽章表情_20260916.png")
    contact_sheet(rows, p2, pad=10, bg=(58, 58, 66))
    print("预览 →", p2)
    for i, nm in enumerate(order):
        print(f"\nheart-{i} = {nm} ASCII:")
        ascii_face(d[nm])

main()
