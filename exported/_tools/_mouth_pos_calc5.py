# -*- coding: utf-8 -*-
"""最终版2：对称打分（双向覆盖）定缩放 + 在 clip1 里找"现在的嘴"

对称打分 = (画布模板点落到图内容上 + 图内容点落到画布上) / 总点数
  → 缩放太小/太大都会被扣分（旧版只算单向，会偏向"缩小"）
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
        n = 0
        for i in range(0, im.w * im.h * 4, 4):
            if pred(im.px[i], im.px[i + 1], im.px[i + 2], im.px[i + 3]):
                self.m[i // 4] = 1; n += 1
        self.n = n

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


c = canvas_art()
cm = Mask(c, ART)
cpts = [(x, y) for y in range(CH) for x in range(CW) if cm.at(x, y)][::3]
cf = find_yellow(c)
print("画布 花心=(%.1f,%.1f) 面积%d  内容点 %d" % (cf[1][0], cf[1][1], cf[0], len(cpts)))


def fit(path, tag, smin=0.9, smax=1.6):
    im = read_png(path)
    m = Mask(im, ART)
    fy = find_yellow(im)
    print("\n== %s %dx%d 花心=(%.1f,%.1f) 面积%d  内容点 %d" % (tag, im.w, im.h, fy[1][0], fy[1][1], fy[0], m.n))
    # 图侧采样点
    ipts = []
    for y in range(im.h):
        for x in range(im.w):
            if m.at(x, y):
                ipts.append((x, y))
    ipts = ipts[::max(1, len(ipts) // 8000)]
    best = None
    s = smin
    while s <= smax:
        bx = fy[1][0] - cf[1][0] * s
        by = fy[1][1] - cf[1][1] * s
        # 画布→图
        hit1 = 0
        for (x, y) in cpts:
            if m.at(bx + x * s, by + y * s):
                hit1 += 1
        # 图→画布
        hit2 = 0
        for (x, y) in ipts:
            if cm.at((x - bx) / s, (y - by) / s):
                hit2 += 1
        score = (hit1 / float(len(cpts))) * (hit2 / float(len(ipts)))
        if best is None or score > best[0]:
            best = (score, s, bx, by, hit1 / float(len(cpts)), hit2 / float(len(ipts)))
        s += 0.005
    sc, s, bx, by, r1, r2 = best
    print("   ★ 缩放 %.4f 偏移(%.1f,%.1f)  画布→图 %.1f%%  图→画布 %.1f%%  合分 %.3f" % (s, bx, by, 100*r1, 100*r2, sc))
    return dict(s=s, bx=bx, by=by, im=im, mask=m, flower=fy[1], score=sc)


f2 = fit(CLIP2, "clip2（参考图+箭头）")
f1 = fit(CLIP1, "clip1（原来的图）", 1.5, 2.6)
inv = lambda f, p: ((p[0] - f["bx"]) / f["s"], (p[1] - f["by"]) / f["s"])
fwd = lambda f, p: (f["bx"] + p[0] * f["s"], f["by"] + p[1] * f["s"])

print("\n【参考嘴位置 → 画布】")
for name, p in (("红箭头尖端", (303, 311)), ("尖端再往左上 10px", (295, 303))):
    q = inv(f2, p)
    print("  %s %s → (%.1f, %.1f) ≈ (%d, %d)" % (name, str(p), q[0], q[1], round(q[0]), round(q[1])))
q_ref = inv(f2, (303, 311))

# 反向校验
for nm, cp in (("花心", cf[1]), ("内容左下", (0, 303)), ("内容右上", (232, 2))):
    q = fwd(f2, cp)
    print("  校验 %-8s 画布%s → clip2(%.0f,%.0f) 在内容上=%s" % (nm, str(cp), q[0], q[1], "是" if f2["mask"].at(q[0], q[1]) else "否"))

# ---- 在 clip1 里找"现在的嘴" ----
im1 = read_png(CLIP1)
# 眼睛在画布 (137..171,158..198) → clip1 坐标
e0 = fwd(f1, (137, 198)); e1 = fwd(f1, (171, 158))
print("\nclip1 里眼睛大致 (%.0f,%.0f)-(%.0f,%.0f)" % (e0[0], e1[1], e1[0], e0[1]))
sx0, sy0 = int(e0[0] - 10), int(e0[1] + 10)
sx1, sy1 = int(e1[0] + 40), int(e1[1] + 110)
print("嘴搜索窗 clip1 = (%d,%d)-(%d,%d)" % (sx0, sy0, sx1, sy1))
rows = []
best = None
for y in range(max(0, sy0), min(im1.h, sy1)):
    for x in range(max(0, sx0), min(im1.w, sx1)):
        i = (y * im1.w + x) * 4
        if im1.px[i + 3] < 128: continue
        luma = (im1.px[i] + im1.px[i+1] + im1.px[i+2]) / 3.0
        if luma < 170:
            if best is None:
                best = [x, y, x, y, 1]
            else:
                best[0] = min(best[0], x); best[1] = min(best[1], y)
                best[2] = max(best[2], x); best[3] = max(best[3], y); best[4] += 1
            rows.append((x, y))
print("暗像素 %d 个，bbox=%s" % (len(rows), str(best)))
# 打字符地图（每 4px 一格）
if rows:
    gx0, gy0 = min(r[0] for r in rows), min(r[1] for r in rows)
    gx1, gy1 = max(r[0] for r in rows), max(r[1] for r in rows)
    grid = [[" "] * ((gx1 - gx0) // 4 + 1) for _ in range((gy1 - gy0) // 4 + 1)]
    for (x, y) in rows:
        grid[(y - gy0) // 4][(x - gx0) // 4] = "#"
    print("   字符地图（每格 4px，左上 = clip1(%d,%d)）:" % (gx0, gy0))
    for r in grid:
        print("     " + "".join(r))

if best:
    mc1 = ((best[0] + best[2]) / 2.0, (best[1] + best[3]) / 2.0)
    mc = inv(f1, mc1)
    print("\n现在的嘴（clip1 像素 %s）→ 画布 (%.1f, %.1f) ≈ (%d, %d)" % (str(mc1), mc[0], mc[1], round(mc[0]), round(mc[1])))
    print("★ 需要移动 = (%+d, %+d)" % (round(q_ref[0]) - round(mc[0]), round(q_ref[1]) - round(mc[1])))


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


print("\n预览 →", mark(c, [((q_ref[0], q_ref[1]), (255, 30, 30))],
                        os.path.join(OUT, "画布_参考嘴位置_红十字_2x.png")))
