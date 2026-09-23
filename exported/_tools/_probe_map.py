# -*- coding: utf-8 -*-
"""探针3：连通块 + 粗字符地图（看结构用）。
每格取该格里最常出现的块标签；标签 a=第1大块 b=第2大 ... z=第26大，%d 超过26的用数字，
'#'=描边/暗部，'.'=透明。用法: python _probe_map.py <img.png> [--cols 78] [--min 500]
"""
import sys, os, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png

LUMA_BARRIER = 150
ALPHA = "abcdefghijklmnopqrstuvwxyz0123456789"


def label_map(im, min_area=500):
    w, h, px = im.w, im.h, im.px
    lab = [0] * (w * h)              # -1 透明, -2 屏障, >0 块号
    for i in range(0, w * h * 4, 4):
        if px[i + 3] <= 8:
            lab[i // 4] = -1
        elif (px[i] + px[i + 1] + px[i + 2]) / 3.0 < LUMA_BARRIER:
            lab[i // 4] = -2
    comps = []
    cid = 0
    for y in range(h):
        for x in range(w):
            p = y * w + x
            if lab[p]:
                continue
            cid += 1
            stack = [(x, y)]
            lab[p] = cid
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
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if 0 <= nx < w and 0 <= ny < h:
                        nq = ny * w + nx
                        if not lab[nq]:
                            lab[nq] = cid
                            stack.append((nx, ny))
            comps.append((area, (x0, y0, x1, y1), (sr // area, sg // area, sb // area), cid))
    comps.sort(reverse=True)
    keep = [c[3] for c in comps if c[0] >= min_area][:len(ALPHA)]
    remap = {cid: ALPHA[i] for i, cid in enumerate(keep)}
    return lab, comps, remap


def ascii_map(im, lab, remap, cols=78):
    w, h = im.w, im.h
    cw = max(1, w // cols)
    ch = max(1, int(cw * 2.0))
    rows = []
    for by in range(0, h, ch):
        line = []
        for bx in range(0, w, cw):
            cnt = collections.Counter()
            for y in range(by, min(by + ch, h)):
                for x in range(bx, min(bx + cw, w)):
                    cnt[lab[y * w + x]] += 1
            top = cnt.most_common(1)[0][0]
            if top == -1:
                line.append(".")
            elif top == -2:
                line.append("#")
            else:
                line.append(remap.get(top, "*"))
        rows.append("".join(line))
    return rows


if __name__ == "__main__":
    cols = 78
    if "--cols" in sys.argv:
        cols = int(sys.argv[sys.argv.index("--cols") + 1])
    minA = 500
    if "--min" in sys.argv:
        minA = int(sys.argv[sys.argv.index("--min") + 1])
    path = sys.argv[1]
    im = read_png(path)
    lab, comps, remap = label_map(im, minA)
    print("== %s (%dx%d)  格=%dpx  最小块=%d" % (os.path.basename(path), im.w, im.h, max(1, im.w // cols), minA))
    print("   图例: " + "  ".join("%s=面积%d %dx%d 均色%s" % (remap[c[3]], c[0], c[1][2] - c[1][0] + 1,
          c[1][3] - c[1][1] + 1, c[2]) for c in comps if c[3] in remap))
    for r in ascii_map(im, lab, remap, cols):
        print("   " + r)
