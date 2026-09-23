# -*- coding: utf-8 -*-
"""把一张新的「头/部件」图放进现有画布，并按现役锚点重算 pivot。

原理（与 dst-art-pipeline 一致）：
  画布(file w/h) + 中心点(pivot) 是唯一能动的两个旋钮。
  现役 pivot 像素 P = (pivot_x*W, (1-pivot_y)*H) 就是"锚点"在画布里的位置
  （headbase-1 实测 P=(137,223) = 脖子/连接点）。P 必须保持不动，
  所以新图要缩放 + 平移，使它的锚点落在同一个画布像素上。

锚点怎么找：用「被描边围住的浅色大块」= 脸块(含颈)，
  锚点相对脸块的位置比例（rel）从现役图量出来，1:1 搬到新图上。

用法:
  python fit_side_head.py --src 新图.png --ref "musha v3/headbase/headbase-1.png" \
      --dst 出图.png [--canvas 237x304] [--scale content-w|content-h|face-h|fit] [--preview 预览.png]
纯标准库。
"""
import sys, os, argparse, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image, contact_sheet

LUMA_BARRIER = 150
MIN_FACE = 300


def alpha_bbox(im, thr=8):
    x0, y0, x1, y1 = im.w, im.h, -1, -1
    for y in range(im.h):
        base = y * im.w * 4
        for x in range(im.w):
            if im.px[base + x * 4 + 3] > thr:
                if x < x0: x0 = x
                if x > x1: x1 = x
                if y < y0: y0 = y
                if y > y1: y1 = y
    return (x0, y0, x1, y1)


def crop(im, bb):
    x0, y0, x1, y1 = bb
    w, h = x1 - x0 + 1, y1 - y0 + 1
    out = Image(w, h)
    for y in range(h):
        si = ((y0 + y) * im.w + x0) * 4
        out.px[y * w * 4:(y + 1) * w * 4] = im.px[si:si + w * 4]
    return out


def components(im, min_area=MIN_FACE):
    w, h, px = im.w, im.h, im.px
    lab = [0] * (w * h)
    for i in range(0, w * h * 4, 4):
        if px[i + 3] <= 8:
            lab[i // 4] = -1
        elif (px[i] + px[i + 1] + px[i + 2]) / 3.0 < LUMA_BARRIER:
            lab[i // 4] = -1
    out = []
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
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if 0 <= nx < w and 0 <= ny < h:
                        nq = ny * w + nx
                        if not lab[nq]:
                            lab[nq] = 1
                            stack.append((nx, ny))
            if area >= min_area:
                out.append(dict(area=area, x0=x0, y0=y0, x1=x1, y1=y1,
                                w=x1 - x0 + 1, h=y1 - y0 + 1,
                                col=(sr // area, sg // area, sb // area)))
    return out


def pick_face(im):
    """脸块 = 浅暖色(皮肤) 且面积最大 且 在右半边 的块"""
    cands = []
    for c in components(im):
        r, g, b = c["col"]
        cx = (c["x0"] + c["x1"]) / 2.0
        if r >= 238 and g >= 222 and b >= 195 and r >= g >= b - 12 and cx > im.w * 0.5:
            cands.append(c)
    if not cands:
        raise SystemExit("找不到脸块（浅暖色大块）—— 手工量吧")
    cands.sort(key=lambda c: -c["area"])
    return cands[0]


def resample(im, s):
    """预乘 alpha 的面积平均缩放（缩小时质量好，不出白毛边）"""
    dw, dh = max(1, int(round(im.w * s))), max(1, int(round(im.h * s)))
    out = Image(dw, dh)
    for dy in range(dh):
        sy0 = dy / s
        sy1 = (dy + 1) / s
        y0 = int(sy0); y1 = min(im.h, int(sy1) + 1)
        for dx in range(dw):
            sx0 = dx / s
            sx1 = (dx + 1) / s
            x0 = int(sx0); x1 = min(im.w, int(sx1) + 1)
            ar = ag = ab = aa = 0.0
            for y in range(y0, y1):
                wy = min(y + 1, sy1) - max(y, sy0)
                if wy <= 0:
                    continue
                base = y * im.w * 4
                for x in range(x0, x1):
                    wx = min(x + 1, sx1) - max(x, sx0)
                    if wx <= 0:
                        continue
                    wt = wx * wy
                    i = base + x * 4
                    a = im.px[i + 3]
                    ar += im.px[i] * a * wt
                    ag += im.px[i + 1] * a * wt
                    ab += im.px[i + 2] * a * wt
                    aa += a * wt
            o = (dy * dw + dx) * 4
            if aa <= 0:
                continue
            out.px[o] = min(255, int(round(ar / aa)))
            out.px[o + 1] = min(255, int(round(ag / aa)))
            out.px[o + 2] = min(255, int(round(ab / aa)))
            out.px[o + 3] = min(255, int(round(aa / ((sx1 - sx0) * (sy1 - sy0)))))
    return out


def mark(im, x, y, col=(255, 0, 0), arm=6, scale=1):
    for d in range(-arm * scale, arm * scale + 1):
        for px, py in ((x + d, y), (x, y + d)):
            if 0 <= px < im.w and 0 <= py < im.h:
                im.put(px, py, (col[0], col[1], col[2], 255))
    return im


def upscale(im, k):
    out = Image(im.w * k, im.h * k)
    for y in range(out.h):
        for x in range(out.w):
            o = (y * out.w + x) * 4
            i = ((y // k) * im.w + (x // k)) * 4
            out.px[o:o + 4] = im.px[i:i + 4]
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    ap.add_argument("--ref", required=True)
    ap.add_argument("--dst", required=True)
    ap.add_argument("--canvas", default="237x304")
    ap.add_argument("--pivot-pixel", default="137,223")
    ap.add_argument("--scale", default="content-w", choices=["content-w", "content-h", "face-h", "fit"])
    ap.add_argument("--origin", default=None,
                    help="显式摆放原点 'x,y'（给了就由锚点反推 pivot，实现「零裁剪」）")
    ap.add_argument("--preview", default=None)
    a = ap.parse_args()

    CW, CH = [int(v) for v in a.canvas.lower().split("x")]
    PX, PY = [float(v) for v in a.pivot_pixel.split(",")]

    ref = read_png(a.ref)
    rf = pick_face(ref)
    rbb = alpha_bbox(ref)
    print("现役 %s  %dx%d  内容=%dx%d @(%d,%d)" % (os.path.basename(a.ref), ref.w, ref.h,
          rbb[2] - rbb[0] + 1, rbb[3] - rbb[1] + 1, rbb[0], rbb[1]))
    print("  脸块 %dx%d @(%d,%d) 均色%s" % (rf["w"], rf["h"], rf["x0"], rf["y0"], rf["col"]))
    relx = (PX - rf["x0"]) / float(rf["w"])
    rely = (PY - rf["y0"]) / float(rf["h"])
    print("  锚点像素 P=(%.0f,%.0f)  相对脸块 rel=(%.5f, %.5f)" % (PX, PY, relx, rely))

    src0 = read_png(a.src)
    bb = alpha_bbox(src0)
    src = crop(src0, bb)
    sf = pick_face(src)
    print("新图 %s  %dx%d  内容=%dx%d 已裁到内容" % (os.path.basename(a.src), src0.w, src0.h, src.w, src.h))
    print("  脸块 %dx%d @(%d,%d) 均色%s" % (sf["w"], sf["h"], sf["x0"], sf["y0"], sf["col"]))
    ax = sf["x0"] + relx * sf["w"]
    ay = sf["y0"] + rely * sf["h"]
    print("  → 新图里的锚点 = (%.2f, %.2f)" % (ax, ay))

    # 各种候选缩放
    cands = {
        "content-w": (rbb[2] - rbb[0] + 1) / float(src.w),
        "content-h": (rbb[3] - rbb[1] + 1) / float(src.h),
        "face-h": rf["h"] / float(sf["h"]),
        "fit": min(PX / ax, PY / ay, (CW - PX) / (src.w - ax), (CH - PY) / (src.h - ay)),
    }
    s = cands[a.scale]
    print("  缩放候选: " + "  ".join("%s=%.5f" % (k, v) for k, v in cands.items()))
    print("  采用 scale(%s) = %.5f" % (a.scale, s))

    small = resample(src, s)
    if a.origin:
        ox, oy = [float(v) for v in a.origin.split(",")]
        PXn, PYn = ox + ax * s, oy + ay * s
        note = "（--origin 摆放 → pivot 由锚点反推）"
    else:
        ox, oy = PX - ax * s, PY - ay * s
        PXn, PYn = PX, PY
        note = "（原点由 pivot 反推 → pivot 保持原值）"
    canvas = Image(CW, CH)
    clip = dict(left=0, top=0, right=0, bottom=0)
    for y in range(small.h):
        dy = int(round(oy)) + y
        if dy < 0:
            clip["top"] += 1; continue
        if dy >= CH:
            clip["bottom"] += 1; continue
        for x in range(small.w):
            dx = int(round(ox)) + x
            if dx < 0:
                if y == 0: pass
                continue
            if dx >= CW:
                continue
            i = (y * small.w + x) * 4
            if small.px[i + 3] == 0:
                continue
            o = (dy * CW + dx) * 4
            canvas.px[o:o + 4] = small.px[i:i + 4]
    cl = int(max(0, -round(ox))); ct = int(max(0, -round(oy)))
    cr = int(max(0, round(ox) + small.w - CW)); cb = int(max(0, round(oy) + small.h - CH))
    print("  摆放 origin=(%.2f,%.2f)  缩放后内容 %dx%d%s" % (ox, oy, small.w, small.h, note))
    print("  ★ 裁掉: 左%d 上%d 右%d 下%d 像素" % (cl, ct, cr, cb))

    nbb = alpha_bbox(canvas)
    print("  写入后内容 bbox=(%d,%d)-(%d,%d)  %dx%d  (现役内容 %dx%d @(%d,%d))"
          % (nbb[0], nbb[1], nbb[2], nbb[3], nbb[2] - nbb[0] + 1, nbb[3] - nbb[1] + 1,
             rbb[2] - rbb[0] + 1, rbb[3] - rbb[1] + 1, rbb[0], rbb[1]))
    nf = pick_face(canvas)
    print("  写入后脸块 %dx%d @(%d,%d) 中心(%.1f,%.1f)   → 现役脸块中心(%.1f,%.1f)  偏差(%.1f,%.1f)"
          % (nf["w"], nf["h"], nf["x0"], nf["y0"], (nf["x0"] + nf["x1"]) / 2.0, (nf["y0"] + nf["y1"]) / 2.0,
             (rf["x0"] + rf["x1"]) / 2.0, (rf["y0"] + rf["y1"]) / 2.0,
             (nf["x0"] + nf["x1"]) / 2.0 - (rf["x0"] + rf["x1"]) / 2.0,
             (nf["y0"] + nf["y1"]) / 2.0 - (rf["y0"] + rf["y1"]) / 2.0))
    print("  ★ 新 pivot(TARGET) = (%.8f, %.8f) = 像素(%.2f, %.2f)  画布 %dx%d" % (PXn / CW, 1 - PYn / CH, PXn, PYn, CW, CH))

    tmp = a.dst + ".tmp"
    write_png(tmp, canvas)
    os.replace(tmp, a.dst)
    print("  已写出 %s (%d B)" % (a.dst, os.path.getsize(a.dst)))

    if a.preview:
        k = 2
        l = upscale(mark(read_png(a.ref), int(PX), int(PY)), k)
        r = upscale(mark(read_png(a.dst), int(round(PXn)), int(round(PYn))), k)
        contact_sheet([("现役 " + os.path.basename(a.ref) + "  pivot像素(%.0f,%.0f)" % (PX, PY), [l]),
                       ("新版 摆放后  pivot像素(%.0f,%.0f)" % (PXn, PYn), [r])], a.preview, pad=10)
        print("  对照图 %s" % a.preview)


if __name__ == "__main__":
    main()
