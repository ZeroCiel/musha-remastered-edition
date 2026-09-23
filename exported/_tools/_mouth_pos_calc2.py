# -*- coding: utf-8 -*-
"""用两个稳定地标（花心=黄色块、眼睛虹膜=紫色块）把截图坐标换算到 237x304 画布

做法：两图各找"黄色花心"和"紫色虹膜"中心 → 算距离比 = 缩放，向量夹角 = 旋转角
      再据此把图2 红箭头尖端映射到画布坐标；并做人眼可查的对齐叠加图。
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


def blob(im, pred, minpx=60, region=None, label=""):
    w, h, px = im.w, im.h, im.px
    x0, y0, x1, y1 = region if region else (0, 0, w - 1, h - 1)
    seen = {}
    best = None
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if (x, y) in seen: continue
            i = (y * w + x) * 4
            if not pred(px[i], px[i + 1], px[i + 2], px[i + 3]):
                seen[(x, y)] = 1; continue
            st = [(x, y)]; seen[(x, y)] = 1; area = 0
            ax0 = ax1 = x; ay0 = ay1 = y; sx = sy = 0
            while st:
                cx, cy = st.pop(); area += 1; sx += cx; sy += cy
                if cx < ax0: ax0 = cx
                if cx > ax1: ax1 = cx
                if cy < ay0: ay0 = cy
                if cy > ay1: ay1 = cy
                for nx, ny in ((cx-1,cy),(cx+1,cy),(cx,cy-1),(cx,cy+1)):
                    if x0 <= nx <= x1 and y0 <= ny <= y1 and (nx, ny) not in seen:
                        ii = (ny * w + nx) * 4
                        if pred(px[ii], px[ii+1], px[ii+2], px[ii+3]):
                            seen[(nx, ny)] = 1; st.append((nx, ny))
                        else:
                            seen[(nx, ny)] = 1
            if area >= minpx and (best is None or area > best[0]):
                best = (area, (ax0, ay0, ax1, ay1), (sx / float(area), sy / float(area)))
    if best is None:
        print("   !! %s 没找到" % label)
    return best


YELLOW = lambda r, g, b, a: a > 150 and r > 205 and g > 165 and b < 165 and r - b > 55
# 虹膜：紫（蓝>红>绿），且够饱和
IRIS = lambda r, g, b, a: a > 150 and b > 150 and b - g > 35 and r - g > 5 and r < b and (r + g + b) < 620


def landmarks(im, tag):
    w, h = im.w, im.h
    fl = blob(im, YELLOW, minpx=40, label=tag + " 花心")
    # 虹膜：只在图片中/右半、上部找（避开左边蓝色发带）
    ir = blob(im, IRIS, minpx=120, region=(int(w * 0.35), int(h * 0.15), w - 1, int(h * 0.85)), label=tag + " 虹膜")
    print("== %s %dx%d" % (tag, w, h))
    for name, b in (("花心", fl), ("虹膜", ir)):
        if b:
            print("   %s 面积%-5d bbox=%-22s 中心(%.1f,%.1f)" % (name, b[0], str(b[1]), b[2][0], b[2][1]))
    return fl, ir


c = canvas_art()
print("### 画布合成（237x304）")
cfl, cir = landmarks(c, "canvas")
print("### clip1（原来的图）")
kfl, kir = landmarks(read_png(CLIP1), "clip1")
print("### clip2（参考图 + 红箭头）")
im2 = read_png(CLIP2)
afl, air = landmarks(im2, "clip2")


def solve(tag, fl, ir, ref_fl, ref_ir, im, tips):
    if not (fl and ir and ref_fl and ref_ir):
        print("!! %s 地标不全，跳过" % tag); return None
    v1 = (ir[2][0] - fl[2][0], ir[2][1] - fl[2][1])          # 图里的 花→眼 向量
    v2 = (ref_ir[2][0] - ref_fl[2][0], ref_ir[2][1] - ref_fl[2][1])  # 画布里的向量
    d1 = math.hypot(*v1); d2 = math.hypot(*v2)
    s = d2 / d1
    ang = math.degrees(math.atan2(v2[1], v2[0]) - math.atan2(v1[1], v1[0]))
    print("\n## %s → 画布：" % tag)
    print("   花→眼 距离 %.2f → %.2f  缩放 %.4f   夹角差 %.2f°" % (d1, d2, s, ang))
    ca, sa = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    def f(p):
        dx, dy = (p[0] - fl[2][0]) * s, (p[1] - fl[2][1]) * s
        return (ref_fl[2][0] + dx * ca - dy * sa, ref_fl[2][1] + dx * sa + dy * ca)
    for name, p in tips:
        q = f(p)
        print("   %s %s → 画布 (%.1f, %.1f)  ≈ 整数 (%d, %d)" % (name, str(p), q[0], q[1], round(q[0]), round(q[1])))
    return f


# 红箭头尖端（上一轮量到 (303,311)，是三角尖）
tips2 = [("箭头尖端", (303, 311)), ("箭头尖端往左上再 6px", (299, 306))]
f2 = solve("clip2", afl, air, cfl, cir, im2, tips2)

# 叠加验证：把画布按映射贴回 clip2，看差多少
if f2:
    chk = Image(im2.w, im2.h, bytearray(im2.px))
    hits = 0; miss = 0
    for y in range(CH):
        for x in range(CW):
            i = (y * CW + x) * 4
            if c.px[i + 3] < 128: continue
            q = f((x, y))
            X, Y = int(round(q[0])), int(round(q[1]))
            if 0 <= X < im2.w and 0 <= Y < im2.h:
                j = (Y * im2.w + X) * 4
                if im2.px[j + 3] > 60:
                    hits += 1
                else:
                    miss += 1
    print("   叠加验证：画布实心像素落到图2 内容上的 %d / 落空的 %d （落空率 %.1f%%）" % (hits, miss, 100.0 * miss / max(1, hits + miss)))


def mark(base, pts, path, k=2, clear=False):
    im = Image(base.w * k, base.h * k)
    for y in range(im.h):
        for x in range(im.w):
            i = ((y // k) * base.w + (x // k)) * 4
            o = (y * im.w + x) * 4
            a = base.px[i + 3]
            if a > 0:
                im.px[o:o + 4] = base.px[i:i + 4]
            else:
                im.px[o:o + 4] = bytes((70, 72, 80)) + b"\xff"
    for (px, py), col in pts:
        for dy in range(-14, 15):
            for dx in range(-14, 15):
                if abs(dx) <= 1 or abs(dy) <= 1 or abs(abs(dx) - abs(dy)) <= 1:
                    X, Y = int(px * k) + dx, int(py * k) + dy
                    if 0 <= X < im.w and 0 <= Y < im.h:
                        o = (Y * im.w + X) * 4
                        im.px[o:o + 4] = bytes(col) + b"\xff"
    write_png(path, im)


if f2:
    q = f2((303, 311))
    mark(c, [((q[0], q[1]), (255, 30, 30))], os.path.join(OUT, "画布_嘴目标位置_红十字_2x.png"))
    print("\n预览图 →", os.path.join(OUT, "画布_嘴目标位置_红十字_2x.png"))
