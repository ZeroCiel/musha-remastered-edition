"""看一眼美术给的 技能卷轴 PNG（4096²）长什么样：alpha 统计 + 内容 bbox + ASCII 缩略。
纯标准库，不依赖 PIL。用法：python _inspect_scroll.py
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.normpath(os.path.join(HERE, "..", ".."))

FILES = ["图片/技能卷轴_图标.png", "图片/技能卷轴_地上.png", "图片/任务卷轴.png"]

for rel in FILES:
    p = os.path.join(MOD, rel)
    if not os.path.exists(p):
        print("MISSING", p)
        continue
    im = read_png(p)
    w, h, px = im.w, im.h, im.px
    print("=" * 70)
    print(rel, "%dx%d" % (w, h))
    amin, amax = 255, 0
    opaque = 0
    for i in range(3, len(px), 4):
        a = px[i]
        if a < amin: amin = a
        if a > amax: amax = a
        if a > 8: opaque += 1
    print("  alpha min/max = %d/%d  非透明像素 = %.1f%%" % (amin, amax, 100.0 * opaque / (w * h)))
    # 内容 bbox：优先用 alpha，全不透明则用"非近白"像素
    use_alpha = amax > 8 and amin < 250
    x0, y0, x1, y1 = w, h, -1, -1
    for y in range(h):
        base = y * w * 4
        for x in range(w):
            i = base + x * 4
            if use_alpha:
                keep = px[i + 3] > 8
            else:
                r, g, b = px[i], px[i + 1], px[i + 2]
                keep = not (r > 244 and g > 244 and b > 244)
            if keep:
                if x < x0: x0 = x
                if x > x1: x1 = x
                if y < y0: y0 = y
                if y > y1: y1 = y
    print("  判定口径 =", "alpha" if use_alpha else "非近白")
    if x1 < 0:
        print("  内容为空？")
        continue
    print("  内容 bbox = x %d..%d (宽 %d)  y %d..%d (高 %d)" % (x0, x1, x1 - x0 + 1, y0, y1, y1 - y0 + 1))
    corners = [im.get(0, 0), im.get(w - 1, 0), im.get(0, h - 1), im.get(w - 1, h - 1)]
    print("  四角像素 =", corners)

    # ASCII 缩略（按 bbox 取，亮度 12 档）
    AW, AH = 72, 34
    ramp = " .:-=+*#%@$&"
    bx0, by0 = max(0, x0), max(0, y0)
    bw, bh = max(1, x1 - x0 + 1), max(1, y1 - y0 + 1)
    for ay in range(AH):
        row = []
        for ax in range(AW):
            sx = bx0 + int((ax + 0.5) * bw / AW)
            sy = by0 + int((ay + 0.5) * bh / AH)
            i = (sy * w + sx) * 4
            r, g, b, a = px[i], px[i + 1], px[i + 2], px[i + 3]
            if a < 8:
                row.append(" ")
                continue
            lum = (r * 299 + g * 587 + b * 114) // 1000
            row.append(ramp[min(len(ramp) - 1, lum * len(ramp) // 256)])
        print("   |" + "".join(row) + "|")
