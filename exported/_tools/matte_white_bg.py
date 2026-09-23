# -*- coding: utf-8 -*-
"""抠白底：把「和画面边缘连通的近白/浅灰」判为背景 → alpha=0，边缘加 1px 羽化

为什么不能直接"凡是白都删"：花蕊/花瓣、眼睛高光、皮肤高光都是白的，
所以必须用**从四条边洪水填充**，只删"连到边上的白"。

用法: python matte_white_bg.py <输入.png> <输出.png> [白阈值=235] [羽化=1]
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image


def is_bg(r, g, b, a, thr):
    if a < 8:
        return True
    mx, mn = max(r, g, b), min(r, g, b)
    return mn >= thr and (mx - mn) <= 14        # 近白/浅灰且低饱和


def main():
    src, dst = sys.argv[1], sys.argv[2]
    thr = int(sys.argv[3]) if len(sys.argv) > 3 else 235
    feather = int(sys.argv[4]) if len(sys.argv) > 4 else 1
    im = read_png(src)
    w, h, px = im.w, im.h, im.px
    n = w * h
    bg = bytearray(n)
    stack = []
    for x in range(w):
        for y in (0, h - 1):
            p = y * w + x
            i = p * 4
            if not bg[p] and is_bg(px[i], px[i+1], px[i+2], px[i+3], thr):
                bg[p] = 1; stack.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            p = y * w + x
            i = p * 4
            if not bg[p] and is_bg(px[i], px[i+1], px[i+2], px[i+3], thr):
                bg[p] = 1; stack.append((x, y))
    # 连通扩散
    while stack:
        cx, cy = stack.pop()
        for nx, ny in ((cx-1,cy),(cx+1,cy),(cx,cy-1),(cx,cy+1)):
            if 0 <= nx < w and 0 <= ny < h:
                q = ny * w + nx
                if not bg[q]:
                    ii = q * 4
                    if is_bg(px[ii], px[ii+1], px[ii+2], px[ii+3], thr):
                        bg[q] = 1; stack.append((nx, ny))
    removed = sum(bg)
    # 非背景像素：alpha 保持；背景：alpha=0；交界外圈加羽化
    if feather:
        ring = []
        for y in range(1, h-1):
            for x in range(1, w-1):
                p = y * w + x
                if bg[p]:
                    continue
                if bg[p-1] or bg[p+1] or bg[p-w] or bg[p+w]:
                    ring.append(p)
        for p in ring:
            i = p * 4
            l = (px[i] + px[i+1] + px[i+2]) / 3.0
            if l > 210:                       # 边上偏白的像素 = 抗锯齿过渡 → 半透明
                px[i+3] = min(px[i+3], 150)
    for p in range(n):
        if bg[p]:
            px[p*4+3] = 0
    write_png(dst, im)
    op = sum(1 for p in range(n) if px[p*4+3] > 8)
    print("抠底: %s → %s" % (os.path.basename(src), os.path.basename(dst)))
    print("   %dx%d  删掉(背景) %d px (%.1f%%)  留角色 %d px (%.1f%%)  羽化边 %d px"
          % (w, h, removed, 100.0*removed/n, op, 100.0*op/n, len(ring) if feather else 0))


if __name__ == "__main__":
    main()
