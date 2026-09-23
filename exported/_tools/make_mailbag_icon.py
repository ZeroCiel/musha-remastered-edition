# -*- coding: utf-8 -*-
"""信差包图标：图片/信差包.png → images/inventoryimages/musha_mailbag.png (64x64)

口径：
  1. 白底抠除用**背景漫水填充**（只抠"从边缘连得到的近白像素"）
     → 包里本来就有的白色高光/白纸不会被误抠
  2. 按内容框裁掉四周留白，等比缩到 58x58 以内，居中放 64x64
  3. 缩小时用**预乘 alpha 的面积平均**，边缘不会出白边

⚠️ 本脚本只出 PNG。要进游戏还得用 Mod Tool 把 png 转成 .tex + .xml
   （项目分工：我出 png，用户转 tex）——转好后 prefab 里的素材自检会自动切到专属图标。
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import Image, read_png, write_png

M = os.path.abspath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(M, "参考图", "信差包.png")   # ★ 2026-09-20 源图搬进 参考图\ 并重做（暗调版）
SRC_FALLBACK = os.path.join(M, "图片", "信差包.png")
OUT = os.path.join(M, "images", "inventoryimages", "musha_mailbag.png")
ICON = 64
INNER = 58


def near_white(r, g, b):
    return min(r, g, b) > 222 and (max(r, g, b) - min(r, g, b)) < 26


def cut_white_bg(im):
    """从四边漫水填充，抠掉连通的近白背景"""
    w, h = im.w, im.h
    alpha = bytearray([255]) * (w * h)
    seen = bytearray(w * h)
    stack = []
    for x in range(w):
        for y in (0, h - 1):
            stack.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            stack.append((x, y))
    while stack:
        x, y = stack.pop()
        k = y * w + x
        if seen[k]:
            continue
        seen[k] = 1
        i = k * 4
        if not near_white(im.px[i], im.px[i + 1], im.px[i + 2]):
            continue
        alpha[k] = 0
        if x > 0: stack.append((x - 1, y))
        if x < w - 1: stack.append((x + 1, y))
        if y > 0: stack.append((x, y - 1))
        if y < h - 1: stack.append((x, y + 1))
    out = Image(w, h, bytearray(im.px))
    for k in range(w * h):
        out.px[k * 4 + 3] = alpha[k]
    return out


def bbox(im):
    x0, y0, x1, y1 = im.w, im.h, -1, -1
    for y in range(im.h):
        base = y * im.w * 4
        for x in range(im.w):
            if im.px[base + x * 4 + 3] > 0:
                if x < x0: x0 = x
                if y < y0: y0 = y
                if x > x1: x1 = x
                if y > y1: y1 = y
    return x0, y0, x1, y1


def downscale_box(im, x0, y0, x1, y1, ow, oh):
    sw, sh = x1 - x0 + 1, y1 - y0 + 1
    out = Image(ow, oh)
    for oy in range(oh):
        sy0 = y0 + int(oy * sh / oh); sy1 = y0 + int((oy + 1) * sh / oh)
        if sy1 <= sy0: sy1 = sy0 + 1
        for ox in range(ow):
            sx0 = x0 + int(ox * sw / ow); sx1 = x0 + int((ox + 1) * sw / ow)
            if sx1 <= sx0: sx1 = sx0 + 1
            ar = ag = ab = aa = n = 0
            for y in range(sy0, sy1):
                base = y * im.w * 4
                for x in range(sx0, sx1):
                    i = base + x * 4
                    a = im.px[i + 3]
                    ar += im.px[i] * a; ag += im.px[i + 1] * a; ab += im.px[i + 2] * a
                    aa += a; n += 1
            j = (oy * ow + ox) * 4
            if aa:
                out.px[j] = ar // aa
                out.px[j + 1] = ag // aa
                out.px[j + 2] = ab // aa
            out.px[j + 3] = aa // n
    return out


def main():
    src_path = sys.argv[1] if len(sys.argv) > 1 else (SRC if os.path.exists(SRC) else SRC_FALLBACK)
    print("源图 =", src_path)
    src = read_png(src_path)
    print("源图", src.w, "x", src.h)
    cut = cut_white_bg(src)
    bb = bbox(cut)
    cw, ch = bb[2] - bb[0] + 1, bb[3] - bb[1] + 1
    print("抠底后内容", cw, "x", ch, "位置", bb)
    k = min(INNER / float(cw), INNER / float(ch))
    ow, oh = max(1, int(round(cw * k))), max(1, int(round(ch * k)))
    small = downscale_box(cut, bb[0], bb[1], bb[2], bb[3], ow, oh)
    icon = Image(ICON, ICON)
    dx, dy = (ICON - ow) // 2, (ICON - oh) // 2
    for y in range(oh):
        for x in range(ow):
            i = (y * ow + x) * 4
            j = ((y + dy) * ICON + (x + dx)) * 4
            icon.px[j:j + 4] = small.px[i:i + 4]
    write_png(OUT, icon)
    print("写好图标", OUT, ICON, "x", ICON, "内容", ow, "x", oh)


if __name__ == "__main__":
    main()
