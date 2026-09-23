# -*- coding: utf-8 -*-
"""粗搜最佳对齐（缩放+平移），把截图坐标稳准地换算到 237x304 画布

思路：拿画布合成图的"实心像素"当模板，在截图里搜 (scale, dx, dy) 使
      "画布像素落到截图内容上"的比例最大（搜索范围 ±10%、±16px 精调）。
      —— 比"内容 bbox 对齐"稳，因为截图里的水印/棋盘格/阴影不会影响打分。
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
OUT = os.path.join(M, "exported", "_test_out", "嘴巴位置")
os.makedirs(OUT, exist_ok=True)
CW, CH = 237, 304
HEAD = os.path.join(M, "exported", "musha v3", "headbase_hat", "headbase_hat-1.png")
FACE = os.path.join(M, "exported", "musha v3", "face", "face-4.png")
CLIP1 = r"C:\Users\Administrator\AppData\Local\hermes\images\clip_20260920_165623_3.png"
CLIP2 = r"C:\Users\Administrator\AppData\Local\hermes\images\clip_20260920_165737_4.png"


def canvas_art():
    h = read_png(HEAD); f = read_png(FACE)
    out = Image(CW, CH, bytearray(h.px))
    for y in range(min(f.h, CH)):
        for x in range(min(f.w, CW)):
            i = (y * f.w + x) * 4
            a = f.px[i + 3]
            if a < 16: continue
            o = (y * CW + x) * 4
            if a == 255:
                out.px[o:o + 4] = f.px[i:i + 4]
            else:
                fl = a / 255.0
                for c in range(3):
                    out.px[o + c] = int(f.px[i + c] * fl + out.px[o + c] * (1 - fl))
                out.px[o + 3] = 255
    return out


class Mask:
    def __init__(self, im, pred):
        self.w, self.h, self.px = im.w, im.h, im.px
        self.m = bytearray(im.w * im.h)
        for i in range(0, im.w * im.h * 4, 4):
            if pred(im.px[i], im.px[i + 1], im.px[i + 2], im.px[i + 3]):
                self.m[i // 4] = 1

    def at(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.m[y * self.w + x]
        return 0

    def bbox(self):
        w, h, m = self.w, self.h, self.m
        x0, y0, x1, y1 = w, h, -1, -1
        for y in range(h):
            row = y * w
            for x in range(w):
                if m[row + x]:
                    if x < x0: x0 = x
                    if x > x1: x1 = x
                    if y < y0: y0 = y
                    if y > y1: y1 = y
        return (x0, y0, x1, y1)


ART = lambda r, g, b, a: a > 128 and (max(r, g, b) - min(r, g, b) > 30 or (r + g + b) / 3.0 < 165)

c = canvas_art()
cm = Mask(c, ART)
cb = cm.bbox()
print("画布内容 bbox=%s  %dx%d" % (str(cb), cb[2] - cb[0] + 1, cb[3] - cb[1] + 1))
# 画布模板点（每 3 像素取一个）
pts = [(x, y) for y in range(cb[1], cb[3] + 1) for x in range(cb[0], cb[2] + 1) if cm.at(x, y)]
pts = pts[::3]
print("模板点数 =", len(pts))


def fit(clip_path, tag):
    cl = Mask(read_png(clip_path), ART)
    cbb = cl.bbox()
    print("\n== %s 内容 bbox=%s  %dx%d" % (tag, str(cbb), cbb[2] - cbb[0] + 1, cbb[3] - cbb[1] + 1))
    base = (cbb[2] - cbb[0] + 1) / float(cb[2] - cb[0] + 1)
    best = None
    for si in range(-12, 13):
        s = base * (1 + si * 0.008)
        # 以 bbox 左上角对齐为起点
        bx = cbb[0] - cb[0] * s
        by = cbb[1] - cb[1] * s
        for oy in range(-16, 17, 2):
            for ox in range(-16, 17, 2):
                hit = 0
                for (x, y) in pts:
                    if cl.at(int(bx + x * s + ox + 0.5), int(by + y * s + oy + 0.5)):
                        hit += 1
                r = hit / float(len(pts))
                if best is None or r > best[0]:
                    best = (r, s, bx + ox, by + oy)
    r, s, bx, by = best
    print("   ★ 最佳对齐：缩放 %.4f  偏移(%.1f,%.1f)  命中率 %.1f%%" % (s, bx, by, 100 * r))
    return dict(s=s, bx=bx, by=by, hit=r, mask=cl, bbox=cbb, scale_base=base)


def map_pt(f, p):
    return (f["bx"] + p[0] * f["s"], f["by"] + p[1] * f["s"])


f2 = fit(CLIP2, "clip2")
f1 = fit(CLIP1, "clip1")

print("\n【换算到 237x304 画布】")
inv = lambda f, p: ((p[0] - f["bx"]) / f["s"], (p[1] - f["by"]) / f["s"])
for name, p in (("红箭头尖端", (303, 311)), ("箭头尖端再往左上 8px", (297, 305))):
    q = inv(f2, p)
    print("  %s %s → 画布 (%.1f, %.1f)  ≈ 整数 (%d, %d)" % (name, str(p), q[0], q[1], round(q[0]), round(q[1])))


def mark(base, pts, path, k=2):
    im = Image(base.w * k, base.h * k)
    for y in range(im.h):
        for x in range(im.w):
            i = ((y // k) * base.w + (x // k)) * 4
            o = (y * im.w + x) * 4
            if base.px[i + 3] > 0:
                im.px[o:o + 4] = base.px[i:i + 4]
            else:
                im.px[o:o + 4] = bytes((70, 72, 80)) + b"\xff"
    for (px, py), col in pts:
        for dy in range(-16, 17):
            for dx in range(-16, 17):
                if abs(dx) <= 1 or abs(dy) <= 1 or abs(abs(dx) - abs(dy)) <= 1:
                    X, Y = int(px * k) + dx, int(py * k) + dy
                    if 0 <= X < im.w and 0 <= Y < im.h:
                        o = (Y * im.w + X) * 4
                        im.px[o:o + 4] = bytes(col) + b"\xff"
    write_png(path, im)


q = inv(f2, (303, 311))
mark(c, [((q[0], q[1]), (255, 30, 30))], os.path.join(OUT, "画布_嘴目标_红十字_2x.png"))
print("\n预览（2 倍，红十字 = 换算出来的嘴目标位置）→", os.path.join(OUT, "画布_嘴目标_红十字_2x.png"))
