# -*- coding: utf-8 -*-
"""把截图里"嘴巴参考位置"换算到 237x304 画布坐标

输入：clip1（原来的图，带棋盘格透明底） / clip2（参考图，带红色箭头）
输出：箭头尖端 → 画布像素坐标；clip1 里现役嘴的位置 → 画布坐标；两张带标记的预览图

对齐方法（两条独立映射互校）：
  A 内容 bbox 映射：两张图的"粉发人物"外接框 与 画布合成图的外接框 对齐
  B 眼睛块映射：图里最大的深色块（睫毛/眼睛）中心 + 尺寸比
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
OUT = os.path.join(M, "exported", "_test_out", "嘴巴位置")
os.makedirs(OUT, exist_ok=True)

CW, CH = 237, 304
CLIP1 = r"C:\Users\Administrator\AppData\Local\hermes\images\clip_20260920_165623_3.png"
CLIP2 = r"C:\Users\Administrator\AppData\Local\hermes\images\clip_20260920_165737_4.png"
HEAD = os.path.join(M, "exported", "musha v3", "headbase_hat", "headbase_hat-1.png")
FACE = os.path.join(M, "exported", "musha v3", "face", "face-4.png")


def canvas_art():
    h = read_png(HEAD)
    f = read_png(FACE)
    out = Image(CW, CH, bytearray(h.px))
    for y in range(min(f.h, CH)):
        for x in range(min(f.w, CW)):
            i = (y * f.w + x) * 4
            a = f.px[i + 3]
            if a < 16:
                continue
            o = (y * CW + x) * 4
            if a == 255:
                out.px[o:o + 4] = f.px[i:i + 4]
            else:
                fl = a / 255.0
                for c in range(3):
                    out.px[o + c] = int(f.px[i + c] * fl + out.px[o + c] * (1 - fl))
                out.px[o + 3] = 255
    return out


def is_art(r, g, b, a):
    """非透明 + 不是白底/灰水印 → 算画面内容"""
    if a < 40:
        return False
    mx, mn = max(r, g, b), min(r, g, b)
    if mx - mn > 28:          # 有彩色（粉发/肤色/描边）
        return True
    return (r + g + b) / 3.0 < 150     # 或者够暗（描边）


def art_bbox(im, x0=0, x1=None):
    x1 = im.w if x1 is None else x1
    bx0, by0, bx1, by1 = im.w, im.h, -1, -1
    for y in range(im.h):
        for x in range(x0, x1):
            i = (y * im.w + x) * 4
            if is_art(im.px[i], im.px[i + 1], im.px[i + 2], im.px[i + 3]):
                if x < bx0: bx0 = x
                if x > bx1: bx1 = x
                if y < by0: by0 = y
                if y > by1: by1 = y
    return (bx0, by0, bx1, by1)


def dark_block(im, bb, luma=140, min_area=80):
    """在给定区域内找最大深色块（眼睛/睫毛）"""
    x0, y0, x1, y1 = bb
    w, h, px = im.w, im.h, im.px
    lab = {}
    best = None
    for sy in range(y0, y1 + 1):
        for sx in range(x0, x1 + 1):
            if (sx, sy) in lab:
                continue
            i = (sy * w + sx) * 4
            r, g, b, a = px[i], px[i + 1], px[i + 2], px[i + 3]
            if a < 60 or (r + g + b) / 3.0 >= luma:
                lab[(sx, sy)] = 1
                continue
            st = [(sx, sy)]; lab[(sx, sy)] = 1
            area = 0; ax0 = ax1 = sx; ay0 = ay1 = sy
            while st:
                cx, cy = st.pop(); area += 1
                if cx < ax0: ax0 = cx
                if cx > ax1: ax1 = cx
                if cy < ay0: ay0 = cy
                if cy > ay1: ay1 = cy
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if x0 <= nx <= x1 and y0 <= ny <= y1 and (nx, ny) not in lab:
                        ii = (ny * w + nx) * 4
                        rr, gg, bbb, aa = px[ii], px[ii + 1], px[ii + 2], px[ii + 3]
                        if aa >= 60 and (rr + gg + bbb) / 3.0 < luma:
                            lab[(nx, ny)] = 1; st.append((nx, ny))
                        else:
                            lab[(nx, ny)] = 1
            if area >= min_area and (best is None or area > best[0]):
                best = (area, (ax0, ay0, ax1, ay1))
    return best


def red_arrow(im):
    w, h, px = im.w, im.h, im.px
    pts = []
    for y in range(h):
        for x in range(w):
            i = (y * w + x) * 4
            if px[i + 3] > 150 and px[i] > 190 and px[i + 1] < 80 and px[i + 2] < 80:
                pts.append((x, y))
    if not pts:
        return None
    # 逐行宽度 → 箭头尖端在"宽度从 0 长起来"的那端
    rows = {}
    for x, y in pts:
        rows.setdefault(y, []).append(x)
    ys = sorted(rows)
    print("   箭头逐行宽度：")
    for y in ys:
        print("     y=%3d  x=%3d..%3d  宽 %d" % (y, min(rows[y]), max(rows[y]), len(rows[y])))
    return pts, rows, ys


c_art = canvas_art()
cb = art_bbox(c_art)
print("画布合成图(237x304) 内容 bbox:", cb, " 尺寸 %dx%d" % (cb[2] - cb[0] + 1, cb[3] - cb[1] + 1))
c_eye = dark_block(c_art, (cb[0] + (cb[2] - cb[0]) // 3, cb[1], cb[2], cb[3]))
print("画布 眼睛块:", c_eye)

maps = {}
for tag, path in (("clip1", CLIP1), ("clip2", CLIP2)):
    im = read_png(path)
    bb = art_bbox(im)
    eye = dark_block(im, (bb[0] + (bb[2] - bb[0]) // 3, bb[1], bb[2], bb[3]))
    print("== %s %dx%d  内容 bbox=%s (%dx%d)  眼睛块=%s" %
          (tag, im.w, im.h, str(bb), bb[2] - bb[0] + 1, bb[3] - bb[1] + 1, str(eye)))
    # A 内容 bbox 映射
    sx = (cb[2] - cb[0] + 1) / float(bb[2] - bb[0] + 1)
    sy = (cb[3] - cb[1] + 1) / float(bb[3] - bb[1] + 1)
    # B 眼睛映射
    if eye and c_eye:
        e1, e2 = eye[1], c_eye[1]
        kx = (e2[2] - e2[0] + 1) / float(e1[2] - e1[0] + 1)
        ky = (e2[3] - e2[1] + 1) / float(e1[3] - e1[1] + 1)
        ec1 = ((e1[0] + e1[2]) / 2.0, (e1[1] + e1[3]) / 2.0)
        ec2 = ((e2[0] + e2[2]) / 2.0, (e2[1] + e2[3]) / 2.0)
    maps[tag] = dict(im=im, bb=bb, eye=eye, A=(sx, sy, cb[0], cb[1], bb[0], bb[1]),
                     B=(kx, ky, ec2, ec1))
    print("   A 内容映射: 缩放(%.4f, %.4f) 偏移由 bbox 左上对齐" % (sx, sy))
    if eye and c_eye:
        print("   B 眼睛映射: 缩放(%.4f, %.4f)  眼睛中心 图%s → 画布%s" % (kx, ky, ec1, ec2))


def to_canvas(tag, px, py, which="A"):
    m = maps[tag]
    if which == "A":
        sx, sy, cx0, cy0, bx0, by0 = m["A"]
        return (cx0 + (px - bx0) * sx, cy0 + (py - by0) * sy)
    kx, ky, ec2, ec1 = m["B"]
    return (ec2[0] + (px - ec1[0]) * kx, ec2[1] + (py - ec1[1]) * ky)


# ---- 箭头（clip2）----
im2 = maps["clip2"]["im"]
arr = red_arrow(im2)
if arr:
    pts, rows, ys = arr
    # 尖端 = 宽度最小的那一端（相邻两行宽度从 1~2 开始长）
    ys_sorted = ys
    tip = None
    for i in range(len(ys_sorted) - 1):
        w_this = len(rows[ys_sorted[i]]); w_next = len(rows[ys_sorted[i + 1]])
        if w_next - w_this >= 3:
            tip = (min(rows[ys_sorted[i]]), ys_sorted[i])
            break
    if tip is None:
        tip = (min(rows[min(ys)]), min(ys))
    print("\n★ 箭头尖端（图2 像素）= %s" % str(tip))
    a = to_canvas("clip2", tip[0], tip[1], "A")
    b = to_canvas("clip2", tip[0], tip[1], "B")
    print("   → 画布坐标 A(内容映射) = (%.1f, %.1f)" % a)
    print("   → 画布坐标 B(眼睛映射) = (%.1f, %.1f)" % b)

# ---- clip1 里现役的"嘴"（脸区右下、眼睛下方的细线/小块）----
im1 = maps["clip1"]["im"]
bb1 = maps["clip1"]["bb"]
eye1 = maps["clip1"]["eye"]
# 脸区：内容 bbox 的右半、眼睛块下方
fx0 = eye1[1][0] - 10 if eye1 else bb1[0] + (bb1[2] - bb1[0]) // 2
fx1 = bb1[2]
fy0 = eye1[1][3] + 2 if eye1 else bb1[1] + (bb1[3] - bb1[1]) // 2
fy1 = bb1[3]
print("\nclip1 嘴搜索区 = (%d,%d)-(%d,%d)" % (fx0, fy0, fx1, fy1))
m1 = dark_block(im1, (max(0, fx0), max(0, fy0), fx1, fy1), luma=170, min_area=12)
print("clip1 找到的候选嘴块:", m1)
if m1:
    mc = ((m1[1][0] + m1[1][2]) / 2.0, (m1[1][1] + m1[1][3]) / 2.0)
    print("   嘴中心（图1 像素）=%s → 画布 A(%.1f,%.1f)  B(%.1f,%.1f)" %
          (str(mc), *to_canvas("clip1", mc[0], mc[1], "A"), *to_canvas("clip1", mc[0], mc[1], "B")))


def mark(base, pts, path, k=2):
    im = Image(base.w * k, base.h * k)
    for y in range(im.h):
        for x in range(im.w):
            i = ((y // k) * base.w + (x // k)) * 4
            o = (y * im.w + x) * 4
            im.px[o:o + 4] = base.px[i:i + 4] if base.px[i + 3] > 0 else b"\x40\x42\x4a\xff"
    for (px, py), col in pts:
        for dy in range(-12, 13):
            for dx in range(-12, 13):
                if abs(dx) <= 1 or abs(dy) <= 1 or abs(abs(dx) - abs(dy)) <= 1:
                    X, Y = int(px * k) + dx, int(py * k) + dy
                    if 0 <= X < im.w and 0 <= Y < im.h:
                        o = (Y * im.w + X) * 4
                        im.px[o:o + 4] = bytes(col)
    write_png(path, im)
    print("写出:", path)


if arr:
    a = to_canvas("clip2", tip[0], tip[1], "A")
    mark(c_art, [((a[0], a[1]), (255, 40, 40))], os.path.join(OUT, "画布_参考嘴位置_红十字.png"))
    mark(c_art, [((a[0], a[1]), (255, 40, 40))], os.path.join(OUT, "画布_参考嘴位置_红十字_1x.png"), k=1)
