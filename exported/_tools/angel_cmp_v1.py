# -*- coding: utf-8 -*-
"""天使改装 v1 · 出对比图（纯标准库）
产物：exported/_test_out/angel_v1_对比/ 下 3 张
"""
import os, sys, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import Image, read_png, write_png, blit

MUSHA = os.path.abspath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(MUSHA, "exported", "musha_cloth_v01")
DST = os.path.join(MUSHA, "exported", "_test_out", "angel_v1")
OUT = os.path.join(MUSHA, "exported", "_test_out", "angel_v1_对比")
RENDER = os.path.join(HERE, "musha_scml_render.py")
BG = (46, 48, 56)


def scale_nn(im, k):
    out = Image(im.w * k, im.h * k)
    for y in range(out.h):
        sy = y // k
        for x in range(out.w):
            sx = x // k
            i = (sy * im.w + sx) * 4
            j = (y * out.w + x) * 4
            out.px[j:j + 4] = im.px[i:i + 4]
    return out


def flatten(im, bg=(238, 238, 234)):
    out = Image(im.w, im.h)
    for i in range(0, len(im.px), 4):
        a = im.px[i + 3]
        for k in range(3):
            out.px[i + k] = (im.px[i + k] * a + bg[k] * (255 - a)) // 255
        out.px[i + 3] = 255
    return out


def crop(im, x0, y0, x1, y1):
    x0 = max(0, x0); y0 = max(0, y0); x1 = min(im.w, x1); y1 = min(im.h, y1)
    out = Image(x1 - x0, y1 - y0)
    for y in range(out.h):
        i = ((y0 + y) * im.w + x0) * 4
        j = y * out.w * 4
        out.px[j:j + out.w * 4] = im.px[i:i + out.w * 4]
    return out


def bbox(im, bg=BG, tol=12):
    x0, y0, x1, y1 = im.w, im.h, -1, -1
    for y in range(im.h):
        for x in range(im.w):
            i = (y * im.w + x) * 4
            if abs(im.px[i] - bg[0]) + abs(im.px[i + 1] - bg[1]) + abs(im.px[i + 2] - bg[2]) > tol:
                if x < x0: x0 = x
                if y < y0: y0 = y
                if x > x1: x1 = x
                if y > y1: y1 = y
    return x0, y0, x1, y1


def hcat(ims, pad=10, bg=(30, 30, 36)):
    W = sum(i.w for i in ims) + pad * (len(ims) + 1)
    H = max(i.h for i in ims) + pad * 2
    cv = Image(W, H)
    for i in range(0, W * H * 4, 4):
        cv.px[i:i + 3] = bytes(bg); cv.px[i + 3] = 255
    x = pad
    for im in ims:
        blit(cv, im, x, pad + (H - pad * 2 - im.h) // 2)
        x += im.w + pad
    return cv


def render(scml, out):
    r = subprocess.run([sys.executable, RENDER, scml, out],
                       capture_output=True, text=True)
    print(r.stdout.strip().splitlines()[-1] if r.stdout else r.stderr[-300:])


def main():
    os.makedirs(OUT, exist_ok=True)
    ro = os.path.join(OUT, "_orig_full.png")
    ra = os.path.join(OUT, "_angel_full.png")
    render(os.path.join(SRC, "musha.autosave.scml"), ro)
    render(os.path.join(DST, "musha.autosave.scml"), ra)
    o, a = read_png(ro), read_png(ra)

    # 1) 全身并排
    sheet = hcat([o, a])
    p1 = os.path.join(OUT, "01_全身对比_左原版_右天使.png")
    write_png(p1, sheet)
    print("写好", p1, sheet.w, sheet.h)

    # 2) 头部放大 x2（按角色内容框取上 40%）
    b = bbox(o)
    cx = (b[0] + b[2]) // 2
    hh = b[3] - b[1]
    y1 = b[1] + int(hh * 0.46)
    x0, x1 = cx - int((b[2] - b[0]) * 0.30), cx + int((b[2] - b[0]) * 0.30)
    co = scale_nn(crop(o, x0, max(0, b[1] - 20), x1, y1 + 10), 2)
    ca = scale_nn(crop(a, x0, max(0, b[1] - 20), x1, y1 + 10), 2)
    p2 = os.path.join(OUT, "02_头部放大x2_左原版_右天使.png")
    write_png(p2, hcat([co, ca]))
    print("写好", p2)

    # 3) 眼睛特写 x6
    eo = flatten(scale_nn(read_png(os.path.join(SRC, "face", "face-0.png")), 6))
    ea = flatten(scale_nn(read_png(os.path.join(DST, "face", "face-0.png")), 6))
    p3 = os.path.join(OUT, "03_眼睛特写x6_左原版_右天使.png")
    write_png(p3, hcat([eo, ea]))
    print("写好", p3)

    # 4) 头发特写 x4
    ho = flatten(scale_nn(read_png(os.path.join(SRC, "hairpigtails", "hairpigtails-0.png")), 4))
    ha = flatten(scale_nn(read_png(os.path.join(DST, "hairpigtails", "hairpigtails-0.png")), 4))
    p4 = os.path.join(OUT, "04_双马尾x4_左原版_右天使.png")
    write_png(p4, hcat([ho, ha]))
    print("写好", p4)


if __name__ == "__main__":
    main()
