# -*- coding: utf-8 -*-
"""用"描边对齐"验证 clip2 映射：只比深色描边，背景/发色差异不影响

输出：最佳缩放/偏移 + 描边命中率（高 → 映射可信）；再给箭头尖端的画布坐标
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
OUT = os.path.join(M, "exported", "_test_out", "嘴巴位置")
os.makedirs(OUT, exist_ok=True)
CW, CH = 237, 304
HEAD = os.path.join(M, "exported", "musha v3", "headbase_hat", "headbase_hat-1.png")
FACE = os.path.join(M, "exported", "musha v3", "face", "face-4.png")
CLIP2 = r"C:\Users\Administrator\AppData\Local\hermes\images\clip_20260920_165737_4.png"
YELLOW = lambda r, g, b, a: a > 150 and r > 205 and g > 165 and b < 165 and r - b > 55


def canvas_art():
    h = read_png(HEAD); f = read_png(FACE)
    out = Image(CW, CH, bytearray(h.px))
    for y in range(min(f.h, CH)):
        for x in range(min(f.w, CW)):
            i = (y * f.w + x) * 4
            a = f.px[i + 3]
            if a < 16: continue
            o = (y * CW + x) * 4
            if a == 255:
                out.px[o:o + 4] = f.px[i:i + 4]
            else:
                fl = a / 255.0
                for c in range(3):
                    out.px[o + c] = int(f.px[i + c] * fl + out.px[o + c] * (1 - fl))
                out.px[o + 3] = 255
    return out


c = canvas_art()
# 画布描边点
edge_c = []
for y in range(CH):
    for x in range(CW):
        i = (y * CW + x) * 4
        if c.px[i + 3] < 128: continue
        if (c.px[i] + c.px[i + 1] + c.px[i + 2]) / 3.0 < 140:
            edge_c.append((x, y))
edge_c = edge_c[::2]
print("画布描边点 %d" % len(edge_c))

im2 = read_png(CLIP2)
ed = bytearray(im2.w * im2.h)
for y in range(im2.h):
    for x in range(im2.w):
        i = (y * im2.w + x) * 4
        if im2.px[i + 3] < 128: continue
        if im2.px[i] > 190 and im2.px[i + 1] < 80 and im2.px[i + 2] < 80: continue   # 红箭头
        if (im2.px[i] + im2.px[i + 1] + im2.px[i + 2]) / 3.0 < 150:
            ed[y * im2.w + x] = 1
# 膨胀 2 像素
ed2 = bytearray(ed)
R = 2
for y in range(im2.h):
    for x in range(im2.w):
        if ed[y * im2.w + x]:
            for dy in range(-R, R + 1):
                for dx in range(-R, R + 1):
                    ax, ay = x + dx, y + dy
                    if 0 <= ax < im2.w and 0 <= ay < im2.h:
                        ed2[ay * im2.w + ax] = 1


def find_yellow(im, minpx=40):
    w, h, px = im.w, im.h, im.px
    seen = bytearray(w * h); best = None
    for y in range(h):
        for x in range(w):
            p = y * w + x
            if seen[p]: continue
            i = p * 4
            if not YELLOW(px[i], px[i+1], px[i+2], px[i+3]):
                seen[p] = 1; continue
            st = [(x, y)]; seen[p] = 1; area = 0; sx = sy = 0
            while st:
                cx, cy = st.pop(); area += 1; sx += cx; sy += cy
                for nx, ny in ((cx-1,cy),(cx+1,cy),(cx,cy-1),(cx,cy+1)):
                    if 0 <= nx < w and 0 <= ny < h:
                        q = ny * w + nx
                        if not seen[q]:
                            ii = q * 4
                            if YELLOW(px[ii], px[ii+1], px[ii+2], px[ii+3]):
                                seen[q] = 1; st.append((nx, ny))
                            else:
                                seen[q] = 1
            if area >= minpx and (best is None or area > best[0]):
                best = (area, (sx / float(area), sy / float(area)))
    return best


cf = find_yellow(c)[1]
f2 = find_yellow(im2)[1]
print("画布花心 (%.1f,%.1f)   clip2 花心 (%.1f,%.1f)" % (cf[0], cf[1], f2[0], f2[1]))

best = None
s = 1.00
while s <= 1.55:
    bx0 = f2[0] - cf[0] * s
    by0 = f2[1] - cf[1] * s
    for oy in range(-14, 15, 1):
        for ox in range(-14, 15, 1):
            bx, by = bx0 + ox, by0 + oy
            hit = 0
            for (x, y) in edge_c:
                X, Y = int(bx + x * s), int(by + y * s)
                if 0 <= X < im2.w and 0 <= Y < im2.h and ed2[Y * im2.w + X]:
                    hit += 1
            r = hit / float(len(edge_c))
            if best is None or r > best[0]:
                best = (r, s, bx, by)
    s += 0.01
r, s, bx, by = best
print("★ 描边对齐：缩放 %.4f 偏移(%.1f,%.1f)  命中率 %.1f%%" % (s, bx, by, 100 * r))


def inv(p):
    return ((p[0] - bx) / s, (p[1] - by) / s)


print("\n【红箭头尖端 → 画布坐标】")
for nm, p in (("尖端 (303,311)", (303, 311)), ("尖端正上方 6px (303,305)", (303, 305))):
    q = inv(p)
    print("   %-22s → (%.1f, %.1f) ≈ (%d, %d)" % (nm, q[0], q[1], round(q[0]), round(q[1])))
q = inv((303, 311))


def mark(base, marks, path, k=3, box=None):
    im = Image(base.w * k, base.h * k)
    for y in range(im.h):
        for x in range(im.w):
            i = ((y // k) * base.w + (x // k)) * 4
            o = (y * im.w + x) * 4
            if base.px[i + 3] > 0:
                im.px[o:o + 4] = base.px[i:i + 4]
            else:
                im.px[o:o + 4] = bytes((70, 72, 80)) + b"\xff"
    # 5 像素网格
    for cy in range(0, base.h, 5):
        col = (120, 130, 150) if cy % 25 else (255, 220, 90)
        for x in range(im.w):
            Y = cy * k
            if 0 <= Y < im.h:
                o = (Y * im.w + x) * 4
                im.px[o:o + 4] = bytes(col) + b"\xff"
    for cx in range(0, base.w, 5):
        col = (120, 130, 150) if cx % 25 else (255, 220, 90)
        for y in range(im.h):
            X = cx * k
            if 0 <= X < im.w:
                o = (y * im.w + X) * 4
                im.px[o:o + 4] = bytes(col) + b"\xff"
    for (px, py), col in marks:
        for dy in range(-9, 10):
            for dx in range(-9, 10):
                if abs(dx) <= 1 or abs(dy) <= 1 or abs(abs(dx) - abs(dy)) <= 1:
                    X, Y = int(px * k) + dx, int(py * k) + dy
                    if 0 <= X < im.w and 0 <= Y < im.h:
                        o = (Y * im.w + X) * 4
                        im.px[o:o + 4] = bytes(col) + b"\xff"
    write_png(path, im)
    return path


marks = [((q[0], q[1]), (255, 30, 30))]
p = mark(c, marks, os.path.join(OUT, "画布_网格5px_红十字=参考嘴位置_3x.png"))
print("\n预览（3 倍，5px 网格，黄线每 25px；红十字 = 换算出的参考嘴位置）→", p)
print("画布尺寸 237x304；红十字 ≈ (%d, %d)" % (round(q[0]), round(q[1])))
