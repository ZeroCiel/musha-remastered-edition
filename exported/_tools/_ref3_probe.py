# -*- coding: utf-8 -*-
"""看新的原参考图 Image (3)：尺寸/内容/花心/眼睛/嘴，并和 画布 / clip2(带箭头截图) 对齐

用法: python _ref3_probe.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
REF = os.path.join(M, "参考图", "原参考图_Image3_20260920.png")
CANVAS = None
YELLOW = lambda r, g, b, a: a > 150 and r > 205 and g > 165 and b < 165 and r - b > 55
ART = lambda r, g, b, a: a > 128 and (max(r, g, b) - min(r, g, b) > 30 or (r + g + b) / 3.0 < 165)


def canvas_art():
    from pnglib import Image
    h = read_png(os.path.join(M, "exported", "musha v3", "headbase_hat", "headbase_hat-1.png"))
    f = read_png(os.path.join(M, "exported", "musha v3", "face", "face-4.png"))
    out = Image(237, 304, bytearray(h.px))
    for y in range(min(f.h, 304)):
        for x in range(min(f.w, 237)):
            i = (y * f.w + x) * 4
            a = f.px[i + 3]
            if a < 16: continue
            o = (y * 237 + x) * 4
            if a == 255: out.px[o:o + 4] = f.px[i:i + 4]
            else:
                fl = a / 255.0
                for c in range(3): out.px[o + c] = int(f.px[i + c] * fl + out.px[o + c] * (1 - fl))
                out.px[o + 3] = 255
    return out


def bbox_art(im):
    x0, y0, x1, y1 = im.w, im.h, -1, -1; n = 0
    for y in range(im.h):
        for x in range(im.w):
            i = (y * im.w + x) * 4
            if ART(im.px[i], im.px[i+1], im.px[i+2], im.px[i+3]):
                n += 1
                if x < x0: x0 = x
                if x > x1: x1 = x
                if y < y0: y0 = y
                if y > y1: y1 = y
    return (x0, y0, x1, y1), n


def comps(im, pred, minpx=40, top=8):
    w, h, px = im.w, im.h, im.px
    seen = bytearray(w * h); out = []
    for y in range(h):
        for x in range(w):
            p = y * w + x
            if seen[p]: continue
            i = p * 4
            if not pred(px[i], px[i+1], px[i+2], px[i+3]):
                seen[p] = 1; continue
            st = [(x, y)]; seen[p] = 1; area = 0; x0 = x1 = x; y0 = y1 = y; sr = sg = sb = 0
            while st:
                cx, cy = st.pop(); q = cy * w + cx; area += 1
                sr += px[q*4]; sg += px[q*4+1]; sb += px[q*4+2]
                if cx < x0: x0 = cx
                if cx > x1: x1 = cx
                if cy < y0: y0 = cy
                if cy > y1: y1 = cy
                for nx, ny in ((cx-1,cy),(cx+1,cy),(cx,cy-1),(cx,cy+1)):
                    if 0 <= nx < w and 0 <= ny < h:
                        qq = ny * w + nx
                        if not seen[qq]:
                            ii = qq * 4
                            if pred(px[ii], px[ii+1], px[ii+2], px[ii+3]):
                                seen[qq] = 1; st.append((nx, ny))
                            else:
                                seen[qq] = 1
            if area >= minpx:
                out.append((area, (x0, y0, x1, y1), (sr//area, sg//area, sb//area)))
    out.sort(reverse=True)
    return out[:top]


im = read_png(REF)
bb, n = bbox_art(im)
print("原参考图 %s" % os.path.basename(REF))
print("  尺寸 %dx%d  内容像素 %d  bbox=%s (%dx%d)" % (im.w, im.h, n, str(bb), bb[2]-bb[0]+1, bb[3]-bb[1]+1))
yl = comps(im, YELLOW, minpx=25, top=3)
print("  黄色块(花心候选):", [(a, b) for a, b, c in yl])
print("  深色块 top8（含描边/眼睛/嘴）:")
for a, b, c in comps(im, lambda r, g, b, al: al > 128 and (r+g+b)/3.0 < 150, minpx=60, top=8):
    print("     面积%-6d bbox=%-24s %dx%-4d 均色rgb%s 中心(%.0f,%.0f)"
          % (a, str(b), b[2]-b[0]+1, b[3]-b[1]+1, str(c), (b[0]+b[2])/2.0, (b[1]+b[3])/2.0))
