# -*- coding: utf-8 -*-
"""天使皮肤 · 眼型挑选表 v1

在 face-0 原眼眶里重画 6 种眼型，一张表看全，左上角小方点 = 编号。
 1 = 只换色（完全保留原形状，粉紫→金）
 2 = 细线圆眼（线宽减半 + 眼睛缩到 0.86 + 去睫毛）
 3 = 下垂软眼（外眼角下垂，温柔）
 4 = 细长上挑（挺括）
 5 = 星星眼（虹膜里白色四角星）
 6 = 小圆眼（缩到 0.70，留大量眼白，偏孩童/书页感）

产物：exported/_test_out/angel_eye_pick_v1/挑眼型_6选1.png（3列2行，按阅读顺序 1~6）
"""
import os, sys, math
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import Image, read_png, write_png, blit
import angel_kin_v1 as K

MUSHA = os.path.abspath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(MUSHA, "exported", "musha_cloth_v01")
OUT = os.path.join(MUSHA, "exported", "_test_out", "angel_eye_pick_v1")
BG = (242, 242, 238)


def dist(p, c):
    return ((p[0] - c[0]) ** 2 + (p[1] - c[1]) ** 2 + (p[2] - c[2]) ** 2) ** 0.5


def draw_eye(layer, cx, cy, rx, ry, sx, k=1.0, tilt=0.0, lash_w=1.1, iris_frac=0.60,
             star=False, flick=False, iris_outline=1.0, hl=True, lid_alpha=62):
    """sx: +1 右眼（外眼角在右）/-1 左眼"""
    rx *= k
    ry *= k
    iy = cy + ry * 0.06
    r = ry * iris_frac
    layer.disc(cx, cy, rx * 0.94, ry * 0.92, (253, 251, 247))
    layer.disc(cx, iy, r, r, (232, 180, 62))
    layer.disc(cx, iy - r * 0.36, r * 0.92, r * 0.58, (253, 220, 124))
    layer.disc(cx, iy + r * 0.56, r * 0.86, r * 0.40, (190, 132, 34))
    if iris_outline > 0:
        ring = [(cx + (r + 0.4) * math.cos(2 * math.pi * t / 40.0),
                 iy + (r + 0.4) * math.sin(2 * math.pi * t / 40.0)) for t in range(41)]
        layer.stroke(ring, iris_outline, (96, 62, 26))
    # 瞳孔（浅棕，不纯黑）
    layer.disc(cx, iy, r * 0.36, r * 0.36, (86, 54, 24))
    if star:
        for a in (0, math.pi / 2, math.pi, 3 * math.pi / 2):
            for s in (1, -1):
                layer.stroke([(cx + r * 0.30 * math.cos(a) * s, iy + r * 0.30 * math.sin(a) * s),
                              (cx + r * 0.72 * math.cos(a) * s, iy + r * 0.72 * math.sin(a) * s)],
                             max(0.9, r * 0.16), (255, 255, 255), alpha=215)
    if hl:
        layer.disc(cx - r * 0.42 * 1.0, iy - r * 0.34, r * 0.26, r * 0.26, (255, 255, 255))
        layer.disc(cx + r * 0.36, iy + r * 0.44, r * 0.11, r * 0.11, (255, 255, 255), 190)
    # 上眼线（细）
    top = []
    n = 31
    for i in range(n):
        a = math.pi + math.pi * i / (n - 1)
        xl = math.cos(a) * (1.0 if sx > 0 else -1.0)
        yl = math.sin(a)
        top.append((cx + rx * xl, cy + ry * yl + tilt * ry * max(0.0, xl)))
    layer.stroke(top, lash_w, (48, 34, 26))
    if flick:
        ex = cx + sx * rx
        layer.stroke([(ex, cy + tilt * ry),
                      (ex + sx * rx * 0.20, cy - ry * 0.22 + tilt * ry * 0.7),
                      (ex + sx * rx * 0.36, cy - ry * 0.44 + tilt * ry * 0.4)],
                     lash_w * 1.5, (48, 34, 26), taper=0.5)
    if lid_alpha:
        lid = []
        for i in range(21):
            a = math.pi * 1.24 + math.pi * 0.52 * i / 20.0
            xl = math.cos(a) * (1.0 if sx > 0 else -1.0)
            lid.append((cx + rx * 1.02 * xl, cy - ry * 0.34 + ry * 0.66 * math.sin(a)))
        layer.stroke(lid, 0.9, (48, 34, 26), alpha=lid_alpha)


VARIANTS = {
    1: None,                                                     # 只换色
    2: dict(k=0.86, tilt=0.0, lash_w=1.1, iris_frac=0.60, lid_alpha=62),
    3: dict(k=0.92, tilt=0.20, lash_w=1.1, iris_frac=0.62, lid_alpha=48),
    4: dict(k=0.90, rx_k=1.10, ry_k=0.76, tilt=-0.16, lash_w=1.2, iris_frac=0.66, flick=True),
    5: dict(k=0.90, tilt=-0.04, lash_w=1.1, iris_frac=0.62, star=True, lid_alpha=40),
    6: dict(k=0.70, tilt=0.0, lash_w=1.0, iris_frac=0.56, lid_alpha=56),
}


def make(idx):
    im = read_png(os.path.join(SRC, "face", "face-0.png"))
    im = K.recolor(im, "face")
    if VARIANTS[idx] is None:
        return im
    opt = dict(VARIANTS[idx])
    comps = K.components(im)
    eyes = [c for c in comps if (c[3] - c[1]) > 12 and (c[4] - c[2]) > 12]
    eyes = sorted(eyes[:2], key=lambda c: c[1])
    if len(eyes) < 2:
        print("!! 认不出眼圈", idx)
        return im
    for c in eyes:
        for (x, y) in c[5]:
            im.px[(y * im.w + x) * 4 + 3] = 0
    layer = K.SS(im.w, im.h, 4)
    rxk = opt.pop("rx_k", 1.0)
    ryk = opt.pop("ry_k", 1.0)
    for n, c in enumerate(eyes):
        cx = (c[1] + c[3] + 1) / 2.0
        cy = (c[2] + c[4] + 1) / 2.0
        rx = (c[3] - c[1] + 1) / 2.0
        ry = (c[4] - c[2] + 1) / 2.0
        draw_eye(layer, cx, cy, rx * rxk, ry * ryk,
                 sx=(1.0 if n == 1 else -1.0), **opt)
    new = layer.resolve(im.w, im.h)
    for y in range(im.h):
        for x in range(im.w):
            a = new.px[(y * im.w + x) * 4 + 3]
            if a == 0:
                continue
            nx = K.pxl(new, x, y)
            ox = K.pxl(im, x, y)
            na = a + ox[3] * (255 - a) // 255
            col = tuple((nx[m] * a + ox[m] * ox[3] * (255 - a) // 255) // na for m in range(3)) if na else nx[:3]
            K.pxset(im, x, y, tuple(col) + (na,))
    return im


def scale_nn(im, k):
    out = Image(im.w * k, im.h * k)
    for y in range(out.h):
        for x in range(out.w):
            i = ((y // k) * im.w + (x // k)) * 4
            j = (y * out.w + x) * 4
            out.px[j:j + 4] = im.px[i:i + 4]
    return out


def flatten(im, bg=BG):
    out = Image(im.w, im.h)
    for i in range(0, len(im.px), 4):
        a = im.px[i + 3]
        for m in range(3):
            out.px[i + m] = (im.px[i + m] * a + bg[m] * (255 - a)) // 255
        out.px[i + 3] = 255
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    K_ = 5
    pad = 14
    cells = []
    for idx in range(1, 7):
        cell = flatten(scale_nn(make(idx), K_))
        # 左上角标号小方点
        for d in range(idx):
            x0 = 10 + d * 14
            for y in range(10, 22):
                for x in range(x0, x0 + 9):
                    i = (y * cell.w + x) * 4
                    cell.px[i:i + 4] = bytes((70, 70, 68, 255))
        cells.append(cell)
        write_png(os.path.join(OUT, f"眼型{idx}.png"), cell)
    cw, ch = cells[0].w, cells[0].h
    cols, rows = 3, 2
    W = pad + cols * (cw + pad)
    H = pad + rows * (ch + pad)
    cv = Image(W, H)
    for i in range(0, W * H * 4, 4):
        cv.px[i:i + 3] = bytes((188, 188, 184)); cv.px[i + 3] = 255
    for n, cell in enumerate(cells):
        r, c = divmod(n, cols)
        blit(cv, cell, pad + c * (cw + pad), pad + r * (ch + pad))
    p = os.path.join(OUT, "挑眼型_6选1.png")
    write_png(p, cv)
    print("写好", p, cv.w, "x", cv.h)


if __name__ == "__main__":
    main()
