# -*- coding: utf-8 -*-
"""只更新徽章中心第 4 档表情（heart-3 = 正常）—— 2026-09-16 第二版

用户新导出的 normal.png 是"5 张脸 + 5 段彩色笔刷文字"的排版图：
  左上高兴(橙) / 右上愉悦(粉/红) / 中左满足(绿) / 中右沮丧(蓝) / 底部中间正常(紫)★
"正常"标签（紫色笔刷）叠在脸 E 的左上角 → 用**连通域泛洪**只保留脸本身的像素。
其余 4 张（heart-0/1/2/4）不动，沿用首版从 666.png 切的图。

出图：exported/energy/heart/heart-3.png（44×44，跟其余 4 张同一口径）
"""
import os, sys, shutil
from collections import deque
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import Image, read_png, write_png, blit, contact_sheet

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
EMO = os.path.join(M, "exported", "_src_art")
HEART = os.path.join(M, "exported", "energy", "heart")
BAK = os.path.join(M, "exported", "energy", "_bak_金心_20260916", "heart")
DESKTOP = r"C:\Users\Administrator\Desktop"
FACE = 44
# 5 个脸的大致框（4× 降采样检测出来的），"正常"= 底部中间
BOXES = {
    "高兴": (160, 32, 536, 432), "愉悦": (756, 36, 1132, 432),
    "满足": (148, 468, 540, 868), "沮丧": (748, 476, 1124, 876),
    "正常": (436, 856, 808, 1240),
}

def crop(im, x0, y0, x1, y1):
    w, h = x1 - x0, y1 - y0
    out = Image(w, h)
    for y in range(h):
        s = ((y0 + y) * im.w + x0) * 4
        d = (y * w) * 4
        out.px[d:d + w * 4] = im.px[s:s + w * 4]
    return out

def keep_component(im, x0, y0, x1, y1):
    """只保留 (x0,y0)-(x1,y1) 里跟中心相连的那一坨（去掉压上来的文字块）"""
    w, h = x1 - x0, y1 - y0
    px = im.px
    def solid(x, y):                       # 全分辨率判"有内容"
        return px[(y * im.w + x) * 4 + 3] > 24
    # 从框内找种子：取最靠近框中心的不透明像素
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    seed = None
    for r in range(0, max(w, h) // 2):
        for dx, dy in ((0, 0), (r, 0), (-r, 0), (0, r), (0, -r), (r, r), (-r, -r), (r, -r), (-r, r)):
            x, y = cx + dx, cy + dy
            if x0 <= x < x1 and y0 <= y < y1 and solid(x, y):
                seed = (x, y); break
        if seed: break
    assert seed, "框内找不到内容"
    seen = set([seed]); q = deque([seed])
    while q:
        x, y = q.popleft()
        for nx, ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            if x0 <= nx < x1 and y0 <= ny < y1 and (nx, ny) not in seen and solid(nx, ny):
                seen.add((nx, ny)); q.append((nx, ny))
    out = Image(w, h)
    for (x, y) in seen:
        s = (y * im.w + x) * 4
        d = ((y - y0) * w + (x - x0)) * 4
        out.px[d:d+4] = px[s:s+4]
    return out, len(seen)

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
    """预乘 alpha 盒式滤波"""
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

def fit_center(src, size=FACE, pad=1):
    bb = bbox(src)
    c = crop(src, bb[0], bb[1], bb[2], bb[3])
    inner = size - pad * 2
    if c.w >= c.h:
        tw, th = inner, max(1, int(round(c.h * inner / c.w)))
    else:
        th, tw = inner, max(1, int(round(c.w * inner / c.h)))
    s = scale(c, tw, th)
    out = Image(size, size)
    blit(out, s, (size - tw) // 2, (size - th) // 2)
    return out

def ascii_face(im, step=2):
    for y in range(0, im.h, step * 2):
        s = ""
        for x in range(0, im.w, step):
            i = (y * im.w + x) * 4
            r, g, b, a = im.px[i], im.px[i+1], im.px[i+2], im.px[i+3]
            if a < 40: s += "."
            else:
                lum = (r * 3 + g * 6 + b) / 10
                s += " " if lum > 225 else ("-" if lum > 170 else ("o" if lum > 110 else ("+" if lum > 60 else "#")))
        print(s)

def main():
    im = read_png(os.path.join(EMO, "normal.png"))
    x0, y0, x1, y1 = BOXES["正常"]
    iso, kept = keep_component(im, x0, y0, x1, y1)
    bb = bbox(iso)
    print(f"正常脸：框内连通域 {kept} px，紧致框 {bb} = {bb[2]-bb[0]+1}x{bb[3]-bb[1]+1}")
    face = fit_center(crop(iso, bb[0], bb[1], bb[2], bb[3]))
    cov = sum(1 for i in range(3, len(face.px), 4) if face.px[i] > 40) * 100 // (FACE * FACE)
    print(f"→ heart-3.png 不透明覆盖 {cov}%")
    # 跟其余 4 张比"填充率"，确认裁剪口径一致
    for i in range(5):
        if i == 3: continue
        o = read_png(os.path.join(HEART, "heart-%d.png" % i))
        c = sum(1 for k in range(3, len(o.px), 4) if o.px[k] > 40) * 100 // (44 * 44)
        print(f"   对照 heart-{i} 覆盖 {c}%")
    os.makedirs(BAK, exist_ok=True)
    shutil.copy2(os.path.join(HEART, "heart-3.png"), os.path.join(BAK, "heart-3.png.old"))
    write_png(os.path.join(HEART, "heart-3.png"), face)
    print("已写出 heart-3.png（旧的备份到 _bak_金心_20260916/heart/heart-3.png.old）")

    # 预览：5 张表情 + 装进徽章
    def zoom(i2, z):
        out = Image(i2.w * z, i2.h * z)
        for y in range(i2.h):
            for x in range(i2.w):
                k = (y * i2.w + x) * 4
                for dy in range(z):
                    for dx in range(z):
                        j = ((y * z + dy) * out.w + (x * z + dx)) * 4
                        out.px[j:j+4] = i2.px[k:k+4]
        return out
    faces = [read_png(os.path.join(HEART, "heart-%d.png" % i)) for i in range(5)]
    ring = read_png(os.path.join(M, "exported", "energy", "frame_circle", "frame_circle-0.png"))
    row = []
    for i, val in enumerate((1.0, 0.85, 0.6, 0.35, 0.1)):
        cv = Image(100, 100)
        idx = int(round((1.0 - val) * 22))
        liq = read_png(os.path.join(M, "exported", "energy", "health_level", "health_level-%d.png" % idx))
        blit(cv, liq, 50 - liq.w // 2, 50 + 31 - liq.h)
        hh = faces[i]
        blit(cv, hh, 50 - hh.w // 2, 50 - hh.h // 2)
        blit(cv, ring, 50 - ring.w // 2, 50 - ring.h // 2 + 1)
        row.append(zoom(cv, 2))
    rows = [("5表情", [zoom(f, 4) for f in faces]), ("装进徽章", row)]
    p2 = os.path.join(DESKTOP, "能量徽章表情_20260916.png")
    contact_sheet(rows, p2, pad=10, bg=(58, 58, 66))
    contact_sheet(rows, os.path.join(M, "exported", "energy", "_concept", "badge_faces_20260916.png"), pad=10, bg=(58, 58, 66))
    print("预览 →", p2)
    print("\n新的 heart-3（正常）ASCII:")
    ascii_face(face)

main()
