# -*- coding: utf-8 -*-
"""探针2：把图按「深色描边」切成连通块，报每块的面积/bbox/均色。
脸块 = 被描边围住的那一大块浅色区域（新图没有五官，所以是一整块）。
用法: python _probe_comp.py <A.png> [B.png ...] [--top N] [--min AREA]
纯标准库。
"""
import sys, os, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png

LUMA_BARRIER = 150   # 亮度低于它的算「描边/暗部」，作为分割屏障


def components(im, min_area=200, top=12):
    w, h, px = im.w, im.h, im.px
    lab = bytearray(w * h)          # 0=未访问 1=屏障 2+=已归属
    for i in range(0, w * h * 4, 4):
        if px[i + 3] <= 8:
            lab[i // 4] = 1
            continue
        if (px[i] + px[i + 1] + px[i + 2]) / 3.0 < LUMA_BARRIER:
            lab[i // 4] = 1
    comps = []
    for y in range(h):
        for x in range(w):
            p = y * w + x
            if lab[p]:
                continue
            lab[p] = 1
            stack = [(x, y)]
            area = 0
            x0 = x1 = x; y0 = y1 = y
            sr = sg = sb = 0
            while stack:
                cx, cy = stack.pop()
                q = cy * w + cx
                area += 1
                sr += px[q * 4]; sg += px[q * 4 + 1]; sb += px[q * 4 + 2]
                if cx < x0: x0 = cx
                if cx > x1: x1 = cx
                if cy < y0: y0 = cy
                if cy > y1: y1 = cy
                if cx > 0 and not lab[q - 1]: lab[q - 1] = 1; stack.append((cx - 1, cy))
                if cx < w - 1 and not lab[q + 1]: lab[q + 1] = 1; stack.append((cx + 1, cy))
                if cy > 0 and not lab[q - w]: lab[q - w] = 1; stack.append((cx, cy - 1))
                if cy < h - 1 and not lab[q + w]: lab[q + w] = 1; stack.append((cx, cy + 1))
            if area >= min_area:
                comps.append((area, (x0, y0, x1, y1), (sr // area, sg // area, sb // area)))
    comps.sort(reverse=True)
    return comps[:top]


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    top = 12
    if "--top" in sys.argv:
        top = int(sys.argv[sys.argv.index("--top") + 1])
        args = [a for a in args if a != str(top)]
    for p in args:
        im = read_png(p)
        print("== %s (%dx%d)" % (os.path.basename(p), im.w, im.h))
        for area, bb, col in components(im, top=top):
            print("   面积 %-7d bbox=%-22s %dx%-4d 均色 rgb%s  中心(%.0f,%.0f)"
                  % (area, str(bb), bb[2] - bb[0] + 1, bb[3] - bb[1] + 1, col,
                     (bb[0] + bb[2]) / 2.0, (bb[1] + bb[3]) / 2.0))
        print("")
