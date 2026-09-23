# -*- coding: utf-8 -*-
"""画风一致性体检：把候选图放一起量调色板/描边/柔化程度，并拼一张对照总表

用法: python _style_audit.py
"""
import sys, os, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
DL = r"D:\Backup\Downloads"
OUT = os.path.join(M, "exported", "_test_out", "画风体检")
os.makedirs(OUT, exist_ok=True)

FILES = [
    ("01_参考_侧脸_Image3", os.path.join(M, "参考图", "原参考图_Image3_20260920.png")),
    ("02_Image2_1024x1289", os.path.join(DL, "Image (2).png")),
    ("03_原图_1789801942248", os.path.join(DL, "1789801942248.png")),
    ("04_Image1_384x384", os.path.join(DL, "Image (1).png")),
    ("05_Image_384x384", os.path.join(DL, "Image.png")),
    ("06_测试_305x384", os.path.join(M, "参考图", "测试.png")),
    ("07_现役侧脸头_237x304", os.path.join(M, "exported", "musha v3", "headbase_hat", "headbase_hat-1.png")),
    ("08_现役face4_237x304", os.path.join(M, "exported", "musha v3", "face", "face-4.png")),
    ("09_旧的侧脸头_v2", os.path.join(M, "exported", "musha v2", "headbase_hat", "headbase_hat-1.png")),
]


def stats(path, step=2):
    im = read_png(path)
    w, h, px = im.w, im.h, im.px
    op = semi = 0
    dark = 0
    hist = collections.Counter()
    darksum = [0, 0, 0]
    xs = [w, -1]; ys = [h, -1]
    for y in range(0, h, step):
        for x in range(0, w, step):
            i = (y * w + x) * 4
            a = px[i + 3]
            if a <= 8: continue
            op += 1
            if a < 250: semi += 1
            r, g, b = px[i], px[i+1], px[i+2]
            l = (r + g + b) / 3.0
            hist[(r >> 4 << 4, g >> 4 << 4, b >> 4 << 4)] += 1
            if l < 150:
                dark += 1
                darksum[0] += r; darksum[1] += g; darksum[2] += b
            if x < xs[0]: xs[0] = x
            if x > xs[1]: xs[1] = x
            if y < ys[0]: ys[0] = y
            if y > ys[1]: ys[1] = y
    oc = tuple(s // max(1, dark) for s in darksum) if dark else (0, 0, 0)
    top = hist.most_common(8)
    return dict(im=im, w=w, h=h, op=op, semi=semi, dark=dark, hist=hist, outline=oc, bbox=(xs[0], ys[0], xs[1], ys[1]))


res = {}
for name, path in FILES:
    if not os.path.exists(path):
        print("!! 缺:", path); continue
    s = stats(path)
    res[name] = s
    tot = s["op"] or 1
    b = s["bbox"]
    print("== %s  %dx%d" % (name, s["w"], s["h"]))
    print("   内容 %dx%d  不透明(抽样) %d  半透明占 %.1f%%  深色(描边)占 %.1f%%  描边均色 rgb%s"
          % (b[2]-b[0]+1, b[3]-b[1]+1, s["op"], 100.0*s["semi"]/tot, 100.0*s["dark"]/tot, str(s["outline"])))
    print("   主色 top8:", "  ".join("rgb%s:%d" % (c, n) for c, n in s["hist"].most_common(8)))

# 调色板相似度（两两，用主色集合的加权 Jaccard 近似）
names = list(res)
print("\n【主色板重叠度（拿各自 top20 色，重合权重和 / 较小那方的总权重）】")
tops = {n: res[n]["hist"].most_common(20) for n in names}
for i in range(len(names)):
    for j in range(i+1, len(names)):
        a, b2 = dict(tops[names[i]]), dict(tops[names[j]])
        inter = sum(min(a[k], b2[k]) for k in a if k in b2)
        small = min(sum(a.values()), sum(b2.values())) or 1
        print("   %-22s vs %-22s  重合 %.0f%%" % (names[i], names[j], 100.0*inter/small))

# 对照总表：每个缩到高 300，横排
CELL_H = 300
cells = []
for n in names:
    im = res[n]["im"]
    k = CELL_H / float(im.h)
    cw = max(1, int(im.w * k))
    out = Image(cw, CELL_H)
    for y in range(CELL_H):
        sy = min(im.h-1, int(y / k))
        for x in range(cw):
            sx = min(im.w-1, int(x / k))
            i = (sy * im.w + sx) * 4
            o = (y * cw + x) * 4
            a = im.px[i+3]
            if a == 0:
                out.px[o:o+4] = bytes((70, 72, 80)) + b"\xff"
            elif a == 255:
                out.px[o:o+4] = im.px[i:i+4]
            else:
                f = a / 255.0
                for c in range(3):
                    out.px[o+c] = int(im.px[i+c]*f + 70*(1-f))
                out.px[o+3] = 255
    cells.append((n, out))
W = sum(c.w + 8 for _, c in cells) + 8
sheet = Image(W, CELL_H + 16)
for y in range(sheet.h):
    for x in range(W):
        o = (y*W+x)*4
        sheet.px[o:o+4] = bytes((70, 72, 80)) + b"\xff"
x0 = 8
for n, c in cells:
    for y in range(c.h):
        for x in range(c.w):
            i = (y*c.w+x)*4
            o = ((y+8)*W + (x0+x))*4
            sheet.px[o:o+4] = c.px[i:i+4]
    x0 += c.w + 8
p = os.path.join(OUT, "画风对照总表_左到右=01..09.png")
write_png(p, sheet)
print("\n对照总表（从左到右 = 01..09，顺序同上）→", p)
print("顺序:", " | ".join(n for n, _ in cells))
