# -*- coding: utf-8 -*-
"""v2 / v3 侧脸头 + face-4 对比：算像素差、最佳平移、五官块位置

用法: python _cmp_v2v3_headface.py
输出：数值报告 + 对照图（exported/_test_out/v2v3_对比/）

判定思路：
  · 「侧脸歪了」= headbase_hat-1 的轮廓/内容在版本间移动或形状不同
  · 「五官歪了」= face-4 里的眼睛/眉毛块，相对头部内容中心的位置在版本间不同
  · 「像素差」= 两版对齐后仍不同的像素占比（对齐后还差很多 = 是画得不一样，不是挪位）
"""
import sys, os, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
P = lambda *a: os.path.join(M, *a)

PAIRS = [
    ("headbase_hat-1", P("exported", "musha v2", "headbase_hat", "headbase_hat-1.png"),
                       P("exported", "musha v3", "headbase_hat", "headbase_hat-1.png")),
    ("face-4        ", P("exported", "musha v2", "face", "face-4.png"),
                       P("exported", "musha v3", "face", "face-4.png")),
    ("headbase-1    ", P("exported", "musha v2", "headbase", "headbase-1.png"),
                       P("exported", "musha v3", "headbase", "headbase-1.png")),
]


def bbox(im):
    x0, y0, x1, y1 = im.w, im.h, -1, -1
    for y in range(im.h):
        r = y * im.w * 4
        for x in range(im.w):
            if im.px[r + x * 4 + 3] > 8:
                if x < x0: x0 = x
                if x > x1: x1 = x
                if y < y0: y0 = y
                if y > y1: y1 = y
    return (x0, y0, x1, y1)


def opaque_count(im):
    n = 0
    for i in range(3, im.w * im.h * 4, 4):
        if im.px[i] > 8:
            n += 1
    return n


def dark_blocks(im, luma=150, min_area=40, top=6):
    """深色块（描边/眼睛/眉毛）连通块，按面积排"""
    w, h, px = im.w, im.h, im.px
    lab = bytearray(w * h)
    for i in range(0, w * h * 4, 4):
        if px[i + 3] <= 8 or (px[i] + px[i + 1] + px[i + 2]) / 3.0 < luma:
            lab[i // 4] = 1
    out = []
    for y in range(h):
        for x in range(w):
            p = y * w + x
            if lab[p]:
                continue
            lab[p] = 1
            st = [(x, y)]
            area = 0
            x0 = x1 = x; y0 = y1 = y
            while st:
                cx, cy = st.pop()
                q = cy * w + cx
                area += 1
                if cx < x0: x0 = cx
                if cx > x1: x1 = cx
                if cy < y0: y0 = cy
                if cy > y1: y1 = cy
                if cx > 0 and not lab[q - 1]: lab[q - 1] = 1; st.append((cx - 1, cy))
                if cx < w - 1 and not lab[q + 1]: lab[q + 1] = 1; st.append((cx + 1, cy))
                if cy > 0 and not lab[q - w]: lab[q - w] = 1; st.append((cx, cy - 1))
                if cy < h - 1 and not lab[q + w]: lab[q + w] = 1; st.append((cx, cy + 1))
            if area >= min_area:
                out.append((area, (x0, y0, x1, y1)))
    out.sort(reverse=True)
    return out[:top]


def diff_stats(a, b, shift=(0, 0), thresh=24):
    """不同像素数（含 alpha 有无）。shift = b 相对 a 的平移"""
    dx, dy = shift
    bad = 0
    tot = 0
    for y in range(a.h):
        for x in range(a.w):
            bx, by = x + dx, y + dy
            if bx < 0 or by < 0 or bx >= b.w or by >= b.h:
                continue
            ia = (y * a.w + x) * 4
            ib = (by * b.w + bx) * 4
            aa, ab = a.px[ia + 3], b.px[ib + 3]
            if aa <= 8 and ab <= 8:
                continue
            tot += 1
            if aa <= 8 or ab <= 8:
                bad += 1
                continue
            if (abs(a.px[ia] - b.px[ib]) > thresh or
                    abs(a.px[ia + 1] - b.px[ib + 1]) > thresh or
                    abs(a.px[ia + 2] - b.px[ib + 2]) > thresh):
                bad += 1
    return bad, tot


def best_shift(a, b, r=14):
    best = (0, 0, 10 ** 9, 0)
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            bad, tot = diff_stats(a, b, (dx, dy))
            if bad < best[2]:
                best = (dx, dy, bad, tot)
    return best


def sheet(a, b, path, title=""):
    """左右并排 + 叠加（不同处标红）"""
    W = a.w + b.w + 8
    H = max(a.h, b.h) + 0
    im = Image(W, H)
    for y in range(a.h):
        for x in range(a.w):
            i = (y * a.w + x) * 4
            j = (y * W + x) * 4
            im.px[j:j + 4] = a.px[i:i + 4]
    for y in range(b.h):
        for x in range(b.w):
            i = (y * b.w + x) * 4
            j = (y * W + a.w + 8 + x) * 4
            im.px[j:j + 4] = b.px[i:i + 4]
    write_png(path, im)


out_dir = P("exported", "_test_out", "v2v3_对比")
os.makedirs(out_dir, exist_ok=True)

for name, pa, pb in PAIRS:
    if not (os.path.exists(pa) and os.path.exists(pb)):
        print("!! 缺文件:", pa if not os.path.exists(pa) else pb)
        continue
    a, b = read_png(pa), read_png(pb)
    ba, bb = bbox(a), bbox(b)
    ca = ((ba[0] + ba[2]) / 2.0, (ba[1] + ba[3]) / 2.0)
    cb = ((bb[0] + bb[2]) / 2.0, (bb[1] + bb[3]) / 2.0)
    print("=" * 66)
    print("[%s] v2 = %s" % (name.strip(), os.path.basename(pa)))
    print("          尺寸 %dx%d  不透明 %d  内容 %dx%d 中心(%.1f,%.1f)"
          % (a.w, a.h, opaque_count(a), ba[2] - ba[0] + 1, ba[3] - ba[1] + 1, ca[0], ca[1]))
    print("[%s] v3 = %s" % (name.strip(), os.path.basename(pb)))
    print("          尺寸 %dx%d  不透明 %d  内容 %dx%d 中心(%.1f,%.1f)"
          % (b.w, b.h, opaque_count(b), bb[2] - bb[0] + 1, bb[3] - bb[1] + 1, cb[0], cb[1]))
    print("   内容尺寸差 = %+d x %+d    中心差 = (%+.1f, %+.1f)"
          % ((bb[2] - bb[0]) - (ba[2] - ba[0]), (bb[3] - bb[1]) - (ba[3] - ba[1]), cb[0] - ca[0], cb[1] - ca[1]))

    bad0, tot0 = diff_stats(a, b, (0, 0))
    print("   原样叠加：不同 %d / 覆盖 %d = %.1f%%" % (bad0, tot0, 100.0 * bad0 / max(1, tot0)))
    bx, by, badb, totb = best_shift(a, b)
    print("   最佳平移 (%+d,%+d)：不同 %d = %.1f%%   ← 对齐后还差这么多"
          % (bx, by, badb, 100.0 * badb / max(1, totb)))

    print("   v2 深色块 top:" + "  ".join("a=%d bb=%s" % (s, t) for s, t in dark_blocks(a)[:4]))
    print("   v3 深色块 top:" + "  ".join("a=%d bb=%s" % (s, t) for s, t in dark_blocks(b)[:4]))
    sheet(a, b, os.path.join(out_dir, "对照_%s.png" % name.strip()))
print("\n对照图 →", out_dir)
