# -*- coding: utf-8 -*-
"""原参考图(305x384) ↔ 画布(237x304) 精确对齐，然后把"箭头指的位置"换算到画布

关键事实（已量到）：
  · 参考图 305x384，内容 279x357
  · clip2 截图（带红箭头）里的内容也是 279x357 → **clip2 = 参考图 1:1 贴上去的**（偏移约 +52/+31）
    ⇒ 箭头尖端 clip2(303,311) → 参考图坐标 (251,280)
  · 画布头图内容 225x283 → 参考图是"原图"，画布是缩放/裁切后的版本（比例约 0.79）
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
OUT = os.path.join(M, "exported", "_test_out", "嘴巴位置")
os.makedirs(OUT, exist_ok=True)
REF = os.path.join(M, "参考图", "原参考图_Image3_20260920.png")
CW, CH = 237, 304
YELLOW = lambda r, g, b, a: a > 150 and r > 205 and g > 165 and b < 165 and r - b > 55


def canvas_art():
    h = read_png(os.path.join(M, "exported", "musha v3", "headbase_hat", "headbase_hat-1.png"))
    f = read_png(os.path.join(M, "exported", "musha v3", "face", "face-4.png"))
    out = Image(CW, CH, bytearray(h.px))
    for y in range(min(f.h, CH)):
        for x in range(min(f.w, CW)):
            i = (y * f.w + x) * 4
            a = f.px[i + 3]
            if a < 16: continue
            o = (y * CW + x) * 4
            if a == 255: out.px[o:o + 4] = f.px[i:i + 4]
            else:
                fl = a / 255.0
                for c in range(3): out.px[o + c] = int(f.px[i + c] * fl + out.px[o + c] * (1 - fl))
                out.px[o + 3] = 255
    return out


class Dark:
    """描边（深色）点集 + 膨胀查询"""
    def __init__(self, im, luma=150, dilate=2):
        self.w, self.h = im.w, im.h
        self.m = bytearray(im.w * im.h)
        for y in range(im.h):
            for x in range(im.w):
                i = (y * im.w + x) * 4
                r, g, b, a = im.px[i], im.px[i+1], im.px[i+2], im.px[i+3]
                if a > 128 and (r + g + b) / 3.0 < luma:
                    self.m[y * im.w + x] = 1
        self.d = bytearray(self.m)
        for y in range(im.h):
            for x in range(im.w):
                if self.m[y * im.w + x]:
                    for dy in range(-dilate, dilate + 1):
                        for dx in range(-dilate, dilate + 1):
                            ax, ay = x + dx, y + dy
                            if 0 <= ax < im.w and 0 <= ay < im.h:
                                self.d[ay * im.w + ax] = 1

    def near(self, x, y):
        x, y = int(x), int(y)
        return 0 <= x < self.w and 0 <= y < self.h and self.d[y * self.w + x] == 1

    def points(self, step=1):
        return [(x, y) for y in range(self.h) for x in range(self.w) if self.m[y * self.w + x]][::step]


def flower(im):
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
            if area >= 25 and (best is None or area > best[0]):
                best = (area, (sx / float(area), sy / float(area)))
    return best


c = canvas_art()
dc = Dark(c, 150, 2)
cf = flower(c)[1]
ref = read_png(REF)
dr = Dark(ref, 150, 2)
rf = flower(ref)[1]
print("画布花心 (%.1f,%.1f)   参考图花心 (%.1f,%.1f)" % (cf[0], cf[1], rf[0], rf[1]))
cpts = dc.points(2)
rpts = dr.points(4)
print("画布描边点 %d  参考图描边点 %d" % (len(cpts), len(rpts)))

best = None
s = 1.10
while s <= 1.45:
    bx = rf[0] - cf[0] * s
    by = rf[1] - cf[1] * s
    h1 = sum(1 for (x, y) in cpts if dr.near(bx + x * s, by + y * s)) / float(len(cpts))
    h2 = sum(1 for (x, y) in rpts if dc.near((x - bx) / s, (y - by) / s)) / float(len(rpts))
    sc = h1 * h2
    if best is None or sc > best[0]:
        best = (sc, s, bx, by, h1, h2)
    s += 0.005
sc, s, bx, by, h1, h2 = best
print("★ 对齐：缩放 %.4f 偏移(%.1f,%.1f)  画布→参考 %.1f%%  参考→画布 %.1f%%" % (s, bx, by, 100*h1, 100*h2))

# 箭头尖端：clip2(303,311) = 参考图 (303-52, 311-31) = (251,280)
ARROW_REF = (251, 280)
q = ((ARROW_REF[0] - bx) / s, (ARROW_REF[1] - by) / s)
print("\n箭头尖端（参考图 %s）→ 画布 (%.1f, %.1f) ≈ (%d, %d)" % (str(ARROW_REF), q[0], q[1], round(q[0]), round(q[1])))
print("   （同点位在参考图 → 画布 的落点是否在画布内容上：%s）"
      % ("是" if c.px[(min(CH-1, max(0, round(q[1]))) * CW + min(CW-1, max(0, round(q[0])))) * 4 + 3] > 128 else "否"))

# 参考图里箭头附近有什么（嘴？）—— 打字符地图
print("\n参考图 (215..285, 245..315) 字符地图（#=深色 +=彩色 o=浅色）：")
print("     " + "".join(str(x//10%10) for x in range(215, 286)))
for y in range(245, 316, 2):
    row = ""
    for x in range(215, 286):
        i = (y * ref.w + x) * 4
        if ref.px[i+3] < 128: row += " "
        else:
            l = (ref.px[i]+ref.px[i+1]+ref.px[i+2])/3.0
            mx, mn = max(ref.px[i], ref.px[i+1], ref.px[i+2]), min(ref.px[i], ref.px[i+1], ref.px[i+2])
            row += "#" if l < 150 else ("+" if mx-mn > 45 else "o")
    print("%4d %s" % (y, row))


def mark(base, marks, path, k=3):
    im = Image(base.w * k, base.h * k)
    for y in range(im.h):
        for x in range(im.w):
            i = ((y // k) * base.w + (x // k)) * 4
            o = (y * im.w + x) * 4
            if base.px[i + 3] > 0: im.px[o:o + 4] = base.px[i:i + 4]
            else: im.px[o:o + 4] = bytes((70, 72, 80)) + b"\xff"
    for (px, py), col in marks:
        for dy in range(-12, 13):
            for dx in range(-12, 13):
                if abs(dx) <= 1 or abs(dy) <= 1 or abs(abs(dx) - abs(dy)) <= 1:
                    X, Y = int(px * k) + dx, int(py * k) + dy
                    if 0 <= X < im.w and 0 <= Y < im.h:
                        o = (Y * im.w + X) * 4
                        im.px[o:o + 4] = bytes(col) + b"\xff"
    write_png(path, im)
    return path


print("\n预览 →", mark(c, [((q[0], q[1]), (255, 30, 30))], os.path.join(OUT, "画布_红十字=参考嘴位置(新)_3x.png")))
print("参考图对照 →", mark(ref, [(ARROW_REF, (255, 30, 30))], os.path.join(OUT, "原参考图_红十字=箭头位置_2x.png"), k=2))
