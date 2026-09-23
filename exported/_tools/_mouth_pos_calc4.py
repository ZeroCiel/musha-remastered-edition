# -*- coding: utf-8 -*-
"""最终版：以"花心"为锚点、在缩放范围里搜最佳匹配 → 换算红箭头尖端到画布坐标

为什么用花心当锚：截图里有白底/水印/棋盘格，bbox 不可靠；花心（黄色块）两图都能稳定找到。
再顺手在画布上找出"现在的嘴"（眼睛下方那片细线），给出位移量。
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
OUT = os.path.join(M, "exported", "_test_out", "嘴巴位置")
os.makedirs(OUT, exist_ok=True)
CW, CH = 237, 304
HEAD = os.path.join(M, "exported", "musha v3", "headbase_hat", "headbase_hat-1.png")
FACE = os.path.join(M, "exported", "musha v3", "face", "face-4.png")
CLIP1 = r"C:\Users\Administrator\AppData\Local\hermes\images\clip_20260920_165623_3.png"
CLIP2 = r"C:\Users\Administrator\AppData\Local\hermes\images\clip_20260920_165737_4.png"

ART = lambda r, g, b, a: a > 128 and (max(r, g, b) - min(r, g, b) > 30 or (r + g + b) / 3.0 < 165)
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


class Mask:
    def __init__(self, im, pred):
        self.w, self.h = im.w, im.h
        self.m = bytearray(im.w * im.h)
        for i in range(0, im.w * im.h * 4, 4):
            if pred(im.px[i], im.px[i + 1], im.px[i + 2], im.px[i + 3]):
                self.m[i // 4] = 1

    def at(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.m[int(y) * self.w + int(x)]
        return 0


def find_yellow(im, minpx=40):
    w, h, px = im.w, im.h, im.px
    seen = bytearray(w * h); best = None
    for y in range(h):
        for x in range(w):
            p = y * w + x
            if seen[p]: continue
            i = p * 4
            if not YELLOW(px[i], px[i + 1], px[i + 2], px[i + 3]):
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


c = canvas_art()
cm = Mask(c, ART)
pts = [(x, y) for y in range(CH) for x in range(CW) if cm.at(x, y)][::3]
cf = find_yellow(c)
print("画布 花心 = (%0.1f, %0.1f) 面积 %d   模板点 %d" % (cf[1][0], cf[1][1], cf[0], len(pts)))


def fit(path, tag):
    im = read_png(path)
    m = Mask(im, ART)
    yl = find_yellow(im)
    if yl is None:
        print("!! %s 找不到花心" % tag); return None
    fy = yl[1]
    print("\n== %s %dx%d  花心=(%.1f,%.1f) 面积%d" % (tag, im.w, im.h, fy[0], fy[1], yl[0]))
    best = None
    s = 0.80
    while s <= 3.0:
        bx = fy[0] - cf[1][0] * s
        by = fy[1] - cf[1][1] * s
        hit = 0
        for (x, y) in pts:
            if m.at(bx + x * s, by + y * s):
                hit += 1
        r = hit / float(len(pts))
        if best is None or r > best[0]:
            best = (r, s, bx, by)
        s += 0.005
    r, s, bx, by = best
    print("   ★ 缩放 %.4f  偏移(%.1f,%.1f)  命中率 %.1f%%" % (s, bx, by, 100 * r))
    return dict(s=s, bx=bx, by=by, hit=r, im=im, mask=m, flower=fy)


f2 = fit(CLIP2, "clip2（参考图+箭头）")
f1 = fit(CLIP1, "clip1（原来的图）")
if not f2:
    sys.exit(1)

inv = lambda f, p: ((p[0] - f["bx"]) / f["s"], (p[1] - f["by"]) / f["s"])
fwd = lambda f, p: (f["bx"] + p[0] * f["s"], f["by"] + p[1] * f["s"])

print("\n【换算到 237x304 画布】")
targets = {}
for name, p in (("红箭头尖端", (303, 311)), ("箭头尖端再往左上偏 10px", (295, 303))):
    q = inv(f2, p)
    targets[name] = q
    print("  %s %s → 画布 (%.1f, %.1f)  ≈ (%d, %d)" % (name, str(p), q[0], q[1], round(q[0]), round(q[1])))

# 反向校验：画布地标 → clip2 落点
for nm, cp in (("花心", cf[1]), ("画布内容左下 (0,303)", (0, 303)), ("画布内容右上 (232,2)", (232, 2))):
    q = fwd(f2, cp)
    ok = f2["mask"].at(q[0], q[1])
    print("  校验 %-18s 画布%s → clip2 (%.0f,%.0f)  落点在内容上=%s" % (nm, str(cp), q[0], q[1], "是" if ok else "否"))

# ---- 现在的嘴在哪（画布上）----
# 眼睛块 (137,158)-(171,198)；嘴应在脸右下、眼睛下方：搜索 x 130..205, y 200..250 的暗像素
best = None
reg = (128, 196, 210, 258)
for y in range(reg[1], reg[3]):
    for x in range(reg[0], reg[2]):
        i = (y * CW + x) * 4
        if c.px[i + 3] < 128: continue
        luma = (c.px[i] + c.px[i + 1] + c.px[i + 2]) / 3.0
        if luma < 175:
            if best is None:
                best = [x, y, x, y, 1]
            else:
                best[0] = min(best[0], x); best[1] = min(best[1], y)
                best[2] = max(best[2], x); best[3] = max(best[3], y); best[4] += 1
print("\n画布上'现在的嘴'候选（%s 区内的暗像素）: %s" % (str(reg), str(best)))

t = targets["红箭头尖端"]
print("\n★ 结论（画布 237x304 坐标）")
print("   参考嘴位置  ≈ (%.1f, %.1f)" % (t[0], t[1]))
if best:
    print("   现在的嘴    ≈ (%d, %d)" % ((best[0] + best[2]) // 2, (best[1] + best[3]) // 2))
    print("   需要移动    = (%+d, %+d)" % (round(t[0]) - (best[0] + best[2]) // 2, round(t[1]) - (best[1] + best[3]) // 2))


def mark(base, marks, path, k=2):
    im = Image(base.w * k, base.h * k)
    for y in range(im.h):
        for x in range(im.w):
            i = ((y // k) * base.w + (x // k)) * 4
            o = (y * im.w + x) * 4
            if base.px[i + 3] > 0:
                im.px[o:o + 4] = base.px[i:i + 4]
            else:
                im.px[o:o + 4] = bytes((70, 72, 80)) + b"\xff"
    for (px, py), col in marks:
        for dy in range(-16, 17):
            for dx in range(-16, 17):
                if abs(dx) <= 1 or abs(dy) <= 1 or abs(abs(dx) - abs(dy)) <= 1:
                    X, Y = int(px * k) + dx, int(py * k) + dy
                    if 0 <= X < im.w and 0 <= Y < im.h:
                        o = (Y * im.w + X) * 4
                        im.px[o:o + 4] = bytes(col) + b"\xff"
    write_png(path, im)
    return path


marks = [((t[0], t[1]), (255, 30, 30))]
if best:
    marks.append((((best[0] + best[2]) / 2.0, (best[1] + best[3]) / 2.0), (40, 160, 255)))
p = mark(c, marks, os.path.join(OUT, "画布_红十字=参考嘴位置_蓝十字=现在的嘴_2x.png"))
print("\n预览图（红十字=参考嘴位置，蓝十字=现在的嘴）→", p)
