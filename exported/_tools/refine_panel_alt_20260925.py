#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""panel_bg_alt 精修（2026-09-25）
1) 全周长描边扫描：内面板四条深色描边找断口，用同侧健康段剖面补画
2) 右侧翅膀区：描边断口重建 + 渗到金框上的粉色清理
3) 擦除翅膀下 ^ 形杂点 (1560,515)-(1582,533)
4) 翅膀增艳：饱和度 x1.32（区域内饱和像素，40px 边缘羽化）
"""
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
P = os.path.join(HERE, "..", "..", "images", "panel_bg_alt.png")
im = Image.open(P).convert("RGBA")
px = im.load()
W, H = im.size


def darkness(x, y):
    r, g, b, a = px[x, y]
    return (r + g + b) if a > 200 else 765


def is_paper(c):
    r, g, b, a = c
    return a > 200 and r > 235 and g > 225 and b > 200


# ── 0) 定位内面板四条边 ──
def dark_run_y(y, x0, x1):
    xs = [x for x in range(x0, x1) if darkness(x, y) < 400]
    return (xs[0], xs[-1]) if xs else None


def dark_run_x(x, y0, y1):
    ys = [y for y in range(y0, y1) if darkness(x, y) < 400]
    return (ys[0], ys[-1]) if ys else None


mid_y = 600
L = dark_run_y(mid_y, 280, 380)
R = dark_run_y(mid_y, 1560, 1680)
mid_x = 800
T = dark_run_x(mid_x, 140, 240)
B = dark_run_x(mid_x, 950, 1060)
print("内面板边框: 左%s 右%s 顶%s 底%s" % (L, R, T, B))

# ── 1) 描边连续性扫描 + 断口补画 ──
def repair_v(x0, x1, y_from, y_to, sample_y, thr=430):
    fixed = 0
    prof = [(x, darkness(x, sample_y)) for x in range(x0, x1)]
    for y in range(y_from, y_to + 1):
        if min(darkness(x, y) for x in range(x0, x1)) > thr:
            for x, d in prof:
                if d < 400:
                    r, g, b, a = px[x, sample_y]
                    px[x, y] = (r, g, b, a)
                    fixed += 1
    return fixed


def repair_h(y0, y1, x_from, x_to, sample_x, thr=430):
    fixed = 0
    prof = [(y, darkness(sample_x, y)) for y in range(y0, y1)]
    for x in range(x_from, x_to + 1):
        if min(darkness(x, y) for y in range(y0, y1)) > thr:
            for y, d in prof:
                if d < 400:
                    r, g, b, a = px[sample_x, y]
                    px[x, y] = (r, g, b, a)
                    fixed += 1
    return fixed


n = repair_v(R[0] - 6, R[1] + 6, 240, 660, 200)
print("右边框补画 %d px" % n)
n = repair_v(L[0] - 6, L[1] + 6, 150, 980, 600)
print("左边框补画 %d px" % n)
n = repair_h(T[0] - 6, T[1] + 6, 350, 1600, 800)
print("顶边框补画 %d px" % n)
n = repair_h(B[0] - 6, B[1] + 6, 350, 1600, 800)
print("底边框补画 %d px" % n)

# ── 2) 金框带渗色清理：描边右侧带上的粉色（b>185）→ 用健康框带覆盖 ──
fixed = 0
for y in range(240, 660):
    for x in range(R[1] + 2, min(R[1] + 46, W)):
        r, g, b, a = px[x, y]
        if a > 200 and b > 185 and r > 225:      # 粉/白渗色（框带黄 b<175）
            px[x, y] = px[x, 200]
            fixed += 1
print("金框带渗色清理 %d px" % fixed)

# ── 3) ^ 杂点擦除（4 向纸色插值）──
x0, y0, x1, y1 = 1558, 513, 1584, 538
for y in range(y0, y1 + 1):
    for x in range(x0, x1 + 1):
        acc, wt = [0, 0, 0], 0
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            xx, yy, step = x, y, 0
            while 0 <= xx + dx < W and 0 <= yy + dy < H and step < 120:
                xx += dx; yy += dy; step += 1
                if not (x0 <= xx <= x1 and y0 <= yy <= y1) and is_paper(px[xx, yy]):
                    w = 1.0 / step
                    c = px[xx, yy]
                    acc[0] += c[0] * w; acc[1] += c[1] * w; acc[2] += c[2] * w
                    wt += w
                    break
        if wt:
            px[x, y] = (round(acc[0] / wt), round(acc[1] / wt), round(acc[2] / wt), 255)
print("^ 杂点擦除完成")

# ── 4) 翅膀增艳（饱和度 ×1.32，40px 边缘羽化）──
RX0, RY0, RX1, RY1 = 1330, 290, 1612, 620
BOOST = 0.32
n = 0
for y in range(RY0, RY1 + 1):
    for x in range(RX0, RX1 + 1):
        r, g, b, a = px[x, y]
        if a < 200:
            continue
        dist = min(x - RX0, RX1 - x, y - RY0, RY1 - y)
        t = min(1.0, dist / 40.0)
        f = 1.0 + BOOST * t
        lum = 0.299 * r + 0.587 * g + 0.114 * b
        nr = round(min(255, max(0, lum + (r - lum) * f)))
        ng = round(min(255, max(0, lum + (g - lum) * f)))
        nb = round(min(255, max(0, lum + (b - lum) * f)))
        if (nr, ng, nb) != (r, g, b):
            px[x, y] = (nr, ng, nb, a)
            n += 1
print("翅膀增艳 %d px" % n)

im.save(P)
print("已保存", P)
