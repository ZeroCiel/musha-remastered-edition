# -*- coding: utf-8 -*-
"""决定性一量：眼睛落在「脸的浅色区」的什么高度 + 出 2 倍放大对照图

脸区 = 头部图里最大的一块浅色连通域（皮肤/face area）
结论口径：眼睛中心在脸区高度的百分之多少（从脸区上沿往下算）
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
P = lambda *a: os.path.join(M, *a)
OUT = P("exported", "_test_out", "v2v3_对比")
os.makedirs(OUT, exist_ok=True)

HEADS = {"v2": P("exported", "musha v2", "headbase_hat", "headbase_hat-1.png"),
         "v3": P("exported", "musha v3", "headbase_hat", "headbase_hat-1.png")}
FACES = {"v2": P("exported", "musha v2", "face", "face-4.png"),
         "v3": P("exported", "musha v3", "face", "face-4.png")}
PIVOT = {"v2": (0.57805907, 0.26644737), "v3": (0.59924653, 0.27162049)}


def light_comps(im, luma=165, min_area=800):
    w, h, px = im.w, im.h, im.px
    lab = bytearray(w * h)
    for i in range(0, w * h * 4, 4):
        if px[i + 3] < 128 or (px[i] + px[i + 1] + px[i + 2]) / 3.0 < luma:
            lab[i // 4] = 1
    out = []
    for y in range(h):
        for x in range(w):
            p = y * w + x
            if lab[p]: continue
            lab[p] = 1
            st = [(x, y)]; area = 0; x0 = x1 = x; y0 = y1 = y
            while st:
                cx, cy = st.pop(); q = cy * w + cx; area += 1
                if cx < x0: x0 = cx
                if cx > x1: x1 = cx
                if cy < y0: y0 = cy
                if cy > y1: y1 = cy
                for nx, ny in ((cx-1,cy),(cx+1,cy),(cx,cy-1),(cx,cy+1)):
                    if 0 <= nx < w and 0 <= ny < h and not lab[ny*w+nx]:
                        lab[ny*w+nx] = 1; st.append((nx, ny))
            if area >= min_area:
                out.append((area, (x0, y0, x1, y1)))
    out.sort(reverse=True)
    return out


def eye_block(im, luma=150, min_area=100):
    w, h, px = im.w, im.h, im.px
    best = None
    lab = bytearray(w * h)
    for i in range(0, w * h * 4, 4):
        if px[i + 3] < 128 or (px[i] + px[i + 1] + px[i + 2]) / 3.0 < luma:
            lab[i // 4] = 1
    for y in range(h):
        for x in range(w):
            p = y * w + x
            if lab[p]: continue
            lab[p] = 1; st = [(x, y)]; area = 0; x0 = x1 = x; y0 = y1 = y
            while st:
                cx, cy = st.pop(); q = cy * w + cx; area += 1
                if cx < x0: x0 = cx
                if cx > x1: x1 = cx
                if cy < y0: y0 = cy
                if cy > y1: y1 = cy
                for nx, ny in ((cx-1,cy),(cx+1,cy),(cx,cy-1),(cx,cy+1)):
                    if 0 <= nx < w and 0 <= ny < h and not lab[ny*w+nx]:
                        lab[ny*w+nx] = 1; st.append((nx, ny))
            if area >= min_area and (best is None or area > best[0]):
                best = (area, (x0, y0, x1, y1))
    return best[1] if best else None


def overlay(base, top, ox=0, oy=0):
    out = Image(base.w, base.h, bytearray(base.px))
    for y in range(top.h):
        ty = y + oy
        if ty < 0 or ty >= out.h: continue
        for x in range(top.w):
            tx = x + ox
            if tx < 0 or tx >= out.w: continue
            i = (y * top.w + x) * 4
            a = top.px[i + 3]
            if a < 16: continue
            o = (ty * out.w + tx) * 4
            if a == 255:
                out.px[o:o + 4] = top.px[i:i + 4]
            else:
                f = a / 255.0
                for c in range(3):
                    out.px[o + c] = int(top.px[i + c] * f + out.px[o + c] * (1 - f))
                out.px[o + 3] = 255
    return out


def zoom(im, k=2):
    out = Image(im.w * k, im.h * k)
    for y in range(out.h):
        for x in range(out.w):
            i = ((y // k) * im.w + (x // k)) * 4
            o = (y * out.w + x) * 4
            out.px[o:o + 4] = im.px[i:i + 4]
    return out


res = {}
for ver, hp in HEADS.items():
    im = read_png(hp)
    comps = light_comps(im)
    if not comps:
        print(ver, "找不到脸区"); continue
    area, fb = comps[0]
    fp = read_png(FACES[ver])
    eb = eye_block(fp)
    pv = PIVOT[ver]
    if ver == "v2":   # v2 face 文件 305x384 ≠ 声明 237x304 → 按 pivot 比率折算
        off = (int(round(pv[0] * 237 - pv[0] * fp.w)), int(round(pv[1] * 304 - pv[1] * fp.h)))
    else:
        off = (0, 0)
    ec = ((eb[0] + eb[2]) / 2.0 + off[0], (eb[1] + eb[3]) / 2.0 + off[1])
    res[ver] = (im, fp, off, fb, eb, ec)
    fh = fb[3] - fb[1] + 1
    print("== %s" % ver)
    print("   脸区（最大浅色块）面积 %d  bbox=%s  %dx%d  中心(%.1f,%.1f)"
          % (area, str(fb), fb[2] - fb[0] + 1, fh, (fb[0] + fb[2]) / 2.0, (fb[1] + fb[3]) / 2.0))
    print("   眼睛块 %s 折算到头部画布中心(%.1f,%.1f)" % (str(eb), ec[0], ec[1]))
    print("   ★ 眼睛中心在脸区里的位置：横向 %.0f%%  纵向 %.0f%%（从脸区上沿往下算）"
          % (100.0 * (ec[0] - fb[0]) / (fb[2] - fb[0] + 1), 100.0 * (ec[1] - fb[1]) / fh))

# 2 倍放大对照：左 v2头+脸  右 v3头+脸
left = overlay(res["v2"][0], res["v2"][1], res["v2"][2][0], res["v2"][2][1])
right = overlay(res["v3"][0], res["v3"][1], res["v3"][2][0], res["v3"][2][1])
lv, rv = zoom(left, 2), zoom(right, 2)
sheet = Image(lv.w + rv.w + 12, max(lv.h, rv.h))
for y in range(sheet.h):
    for x in range(sheet.w):
        o = (y * sheet.w + x) * 4
        sheet.px[o:o + 4] = b"\x46\x48\x50\xff"
for y in range(lv.h):
    for x in range(lv.w):
        i = (y * lv.w + x) * 4; o = (y * sheet.w + x) * 4
        sheet.px[o:o + 4] = lv.px[i:i + 4]
for y in range(rv.h):
    for x in range(rv.w):
        i = (y * rv.w + x) * 4; o = (y * sheet.w + lv.w + 12 + x) * 4
        sheet.px[o:o + 4] = rv.px[i:i + 4]
p = os.path.join(OUT, "2倍_左旧版v2_右现役v3.png")
write_png(p, sheet)
print("\n2倍放大对照（左=v2 旧版 头+脸，右=v3 现役 头+脸）→", p)

# 再出一张：把 v2 的脸 叠到 v3 的头上（换算版），看五官会不会歪
v3im, v3fp, _, _, _, _ = res["v3"]
v2fp = res["v2"][1]
try:
    from PIL import Image as _I  # 没有 PIL 就走下面纯标准库缩放
    raise ImportError
except Exception:
    pass
sc = Image(237, 304)
for y in range(304):
    for x in range(237):
        i = ((y * v2fp.h) // 304 * v2fp.w + (x * v2fp.w) // 237) * 4
        o = (y * 237 + x) * 4
        sc.px[o:o + 4] = v2fp.px[i:i + 4]
mix = zoom(overlay(v3im, sc, 0, 0), 2)
sheet2 = Image(lv.w + mix.w + 12, max(lv.h, mix.h))
for y in range(sheet2.h):
    for x in range(sheet2.w):
        o = (y * sheet2.w + x) * 4
        sheet2.px[o:o + 4] = b"\x46\x48\x50\xff"
for y in range(lv.h):
    for x in range(lv.w):
        i = (y * lv.w + x) * 4; o = (y * sheet2.w + x) * 4
        sheet2.px[o:o + 4] = lv.px[i:i + 4]
for y in range(mix.h):
    for x in range(mix.w):
        i = (y * mix.w + x) * 4; o = (y * sheet2.w + lv.w + 12 + x) * 4
        sheet2.px[o:o + 4] = mix.px[i:i + 4]
p2 = os.path.join(OUT, "2倍_左v2原配_右v2脸缩到237x304叠v3头.png")
write_png(p2, sheet2)
print("另一张（左=v2 原配，右=旧脸缩到同族后叠在现役头上）→", p2)
