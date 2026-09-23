# -*- coding: utf-8 -*-
"""天使改装 v1 · 一张表看全部部件（左=原版 右=天使）"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import Image, read_png, write_png, blit

MUSHA = os.path.abspath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(MUSHA, "exported", "musha_cloth_v01")
DST = os.path.join(MUSHA, "exported", "_test_out", "angel_v1")
OUT = os.path.join(MUSHA, "exported", "_test_out", "angel_v1_对比", "05_部件对比表_左原版_右天使.png")
BG = (250, 250, 248)


def scale_nn(im, k):
    out = Image(int(im.w * k), int(im.h * k))
    for y in range(out.h):
        for x in range(out.w):
            i = ((y * im.h // out.h) * im.w + (x * im.w // out.w)) * 4
            j = (y * out.w + x) * 4
            out.px[j:j + 4] = im.px[i:i + 4]
    return out


def flatten(im, bg=BG):
    out = Image(im.w, im.h)
    for i in range(0, len(im.px), 4):
        a = im.px[i + 3]
        for k in range(3):
            out.px[i + k] = (im.px[i + k] * a + bg[k] * (255 - a)) // 255
        out.px[i + 3] = 255
    return out


ROWS = [("face", "face-0.png", 4), ("hair", "hair-0.png", 4), ("hairpigtails", "hairpigtails-0.png", 2),
        ("headbase", "headbase-0.png", 1.2), ("cheeks", "cheeks-0.png", 3), ("torso", "torso-0.png", 2)]

pad = 8
items = []
for sym, fn, k in ROWS:
    a = flatten(scale_nn(read_png(os.path.join(SRC, sym, fn)), k))
    b = flatten(scale_nn(read_png(os.path.join(DST, sym, fn)), k))
    items.append((a, b))
W = max(a.w + b.w for a, b in items) + pad * 4
H = sum(max(a.h, b.h) for a, b in items) + pad * (len(items) + 1)
cv = Image(W, H)
for i in range(0, W * H * 4, 4):
    cv.px[i:i + 3] = bytes((214, 214, 210)); cv.px[i + 3] = 255
y = pad
for a, b in items:
    gap = 40
    x0 = pad + max(0, (W - pad * 2 - a.w - b.w - gap) // 2)
    blit(cv, a, x0, y)
    blit(cv, b, x0 + a.w + gap, y)
    for yy in range(y, y + max(a.h, b.h)):
        for xx in (x0 + a.w + gap // 2,):
            i = (yy * W + xx) * 4
            cv.px[i:i + 4] = bytes((120, 120, 118, 255))
    y += max(a.h, b.h) + pad
write_png(OUT, cv)
print("写好", OUT, cv.w, "x", cv.h)
