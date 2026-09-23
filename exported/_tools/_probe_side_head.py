# -*- coding: utf-8 -*-
"""探针：量「新侧脸源图」和「现役 headbase-1」的尺寸/内容/主色/脸块
用法: python _probe_side_head.py <A.png> [B.png ...]
纯标准库（pnglib 在 _tools 下）。
"""
import sys, os, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png


def alpha_bbox(im):
    x0, y0, x1, y1 = im.w, im.h, -1, -1
    for y in range(im.h):
        row = y * im.w * 4
        for x in range(im.w):
            if im.px[row + x * 4 + 3] > 8:
                if x < x0: x0 = x
                if x > x1: x1 = x
                if y < y0: y0 = y
                if y > y1: y1 = y
    return (x0, y0, x1, y1)


def stats(path):
    im = read_png(path)
    n = im.w * im.h
    opaque = 0
    semi = 0
    clear = 0
    white_opaque = 0
    hist = collections.Counter()
    for i in range(0, n * 4, 4):
        a = im.px[i + 3]
        if a <= 8:
            clear += 1
        else:
            opaque += 1
            if a < 250:
                semi += 1
            r, g, b = im.px[i], im.px[i + 1], im.px[i + 2]
            if a > 250 and r > 245 and g > 245 and b > 245:
                white_opaque += 1
            hist[(r >> 3 << 3, g >> 3 << 3, b >> 3 << 3)] += 1
    bb = alpha_bbox(im)
    print("== %s" % os.path.basename(path))
    print("   尺寸 %dx%d  不透明 %d (%.1f%%)  半透明 %d  全透明 %d  不透明纯白 %d"
          % (im.w, im.h, opaque, 100.0 * opaque / n, semi, clear, white_opaque))
    if bb[2] >= 0:
        print("   内容 bbox=%s 尺寸=%dx%d 中心=(%.1f,%.1f)"
              % (bb, bb[2] - bb[0] + 1, bb[3] - bb[1] + 1, (bb[0] + bb[2]) / 2.0, (bb[1] + bb[3]) / 2.0))
    print("   主色 top12:")
    for c, cnt in hist.most_common(12):
        print("      rgb%s  %d (%.2f%%)" % ((c,), cnt, 100.0 * cnt / opaque))
    return im, bb


if __name__ == "__main__":
    for p in sys.argv[1:]:
        stats(p)
        print("")
