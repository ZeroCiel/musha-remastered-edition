# -*- coding: utf-8 -*-
"""精确量：face-4（v2/v3）的"实心内容"几何 + 相对头部的位置关系

- 实心内容 = alpha >= 128（滤掉 AI 图常见的淡淡半透明噪点）
- 报告：尺寸、实心 bbox、bbox 中心相对各自 scml 声明的 pivot、五官(深色)块
- 头部：实心 bbox + 每 10% 高度的轮廓宽度（看侧脸形状差异）
- 最后算：眼睛块中心 相对 头部内容中心 的位置（这才是"五官歪没歪"）
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
P = lambda *a: os.path.join(M, *a)

PIVOT = {  # scml 里各版本 headbase_hat-1 / face-4 声明的 pivot 比率
    "v2": (0.57805907, 0.26644737),
    "v3": (0.59924653, 0.27162049),
}
FILES = {
    "v2 head": P("exported", "musha v2", "headbase_hat", "headbase_hat-1.png"),
    "v3 head": P("exported", "musha v3", "headbase_hat", "headbase_hat-1.png"),
    "v2 face": P("exported", "musha v2", "face", "face-4.png"),
    "v3 face": P("exported", "musha v3", "face", "face-4.png"),
    "v2 head(非hat)": P("exported", "musha v2", "headbase", "headbase-1.png"),
    "v3 head(非hat)": P("exported", "musha v3", "headbase", "headbase-1.png"),
    "v3 face4旧备份": P("exported", "musha v3", "_bak_face4新_20260920_0115", "face-4.png"),
    "参考图face4": P("参考图", "face4.png"),
}


def solid_bbox(im, th=128):
    x0, y0, x1, y1 = im.w, im.h, -1, -1
    n = 0
    for y in range(im.h):
        r = y * im.w * 4
        for x in range(im.w):
            if im.px[r + x * 4 + 3] >= th:
                n += 1
                if x < x0: x0 = x
                if x > x1: x1 = x
                if y < y0: y0 = y
                if y > y1: y1 = y
    return (x0, y0, x1, y1) if x1 >= 0 else None, n


def dark_blocks(im, luma=150, min_area=30, top=5, th=128):
    w, h, px = im.w, im.h, im.px
    lab = bytearray(w * h)
    for i in range(0, w * h * 4, 4):
        if px[i + 3] < th or (px[i] + px[i + 1] + px[i + 2]) / 3.0 < luma:
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


def widths(im, bb, th=128):
    x0, y0, x1, y1 = bb
    hh = y1 - y0 + 1
    rows = []
    for f in (0.1, 0.25, 0.4, 0.5, 0.6, 0.75, 0.9, 0.97):
        yy = min(y1, y0 + int(round(f * hh)))
        lo, hi = None, None
        for x in range(x0, x1 + 1):
            if im.px[(yy * im.w + x) * 4 + 3] >= th:
                if lo is None: lo = x
                hi = x
        rows.append((f, (hi - lo + 1) if lo is not None else 0, yy))
    return rows


report = {}
for name, path in FILES.items():
    if not os.path.exists(path):
        print("!! 缺:", path); continue
    im = read_png(path)
    bb, n = solid_bbox(im)
    ver = "v2" if name.startswith("v2") else "v3"
    pv = PIVOT.get(ver, PIVOT["v3"])
    ppx = (pv[0] * im.w, pv[1] * im.h)
    c = ((bb[0] + bb[2]) / 2.0, (bb[1] + bb[3]) / 2.0) if bb else (0, 0)
    report[name] = dict(im=im, bb=bb, n=n, ppx=ppx, c=c, ver=ver)
    print("== %-14s %dx%d  实心像素 %d" % (name, im.w, im.h, n))
    print("   实心 bbox %s  %dx%d  中心(%.1f,%.1f)" % (str(bb), bb[2] - bb[0] + 1, bb[3] - bb[1] + 1, c[0], c[1]))
    print("   scml声明 pivot(%s, %s) → 像素(%.1f,%.1f)   中心相对pivot (%+.1f, %+.1f)"
          % (pv[0], pv[1], ppx[0], ppx[1], c[0] - ppx[0], c[1] - ppx[1]))
    print("   深色块(五官/描边) top3:", "  ".join("a=%d %s" % (a, b) for a, b in dark_blocks(im, top=3)))

# ---- 五官（眼睛）块中心 相对 头部内容中心 ----
print("\n" + "=" * 70)
print("【五官位置判读】眼睛块中心 - 头部实心内容中心（负=y 在上方）")
for ver in ("v2", "v3"):
    hd = report.get(ver + " head"); fa = report.get(ver + " face")
    if not (hd and fa): continue
    eb = dark_blocks(fa["im"], top=1)[0][1]
    ec = ((eb[0] + eb[2]) / 2.0, (eb[1] + eb[3]) / 2.0)
    if ver == "v2":
        # v2 face 文件 305x384，但 scml 声明 237x304 → 按 pivot 比率等效到头部画布
        off = (PIVOT["v2"][0] * 237 - PIVOT["v2"][0] * fa["im"].w,
               PIVOT["v2"][1] * 304 - PIVOT["v2"][1] * fa["im"].h)
        ec_head = (ec[0] + off[0], ec[1] + off[1])
        note = "（v2 face 文件 305x384 ≠ 声明 237x304，按 pivot 比率折算：平移(%+.1f,%+.1f)）" % off
    else:
        ec_head = ec
        note = ""
    print(" %s：眼睛块 bbox=%s 中心(%.1f,%.1f) → 折算到头部画布(%.1f,%.1f)" % (ver, str(eb), ec[0], ec[1], ec_head[0], ec_head[1]))
    print("      头部内容中心(%.1f,%.1f) → 眼睛相对头部中心 (%+.1f, %+.1f) %s"
          % (hd["c"][0], hd["c"][1], ec_head[0] - hd["c"][0], ec_head[1] - hd["c"][1], note))
    hb = hd["bb"]
    print("      头部内容高 %d → 眼睛在头部高度的 %.1f%% 处（从头顶往下算）"
          % (hb[3] - hb[1] + 1, 100.0 * (ec_head[1] - hb[1]) / (hb[3] - hb[1] + 1)))

# ---- 侧脸轮廓宽度对比 ----
print("\n【侧脸轮廓宽度对比（看侧脸歪不歪）】")
for ver in ("v2", "v3"):
    hd = report.get(ver + " head")
    if not hd: continue
    print(" %s head:" % ver, "  ".join("%d%%→%dpx" % (int(f * 100), w) for f, w, _ in widths(hd["im"], hd["bb"])))
