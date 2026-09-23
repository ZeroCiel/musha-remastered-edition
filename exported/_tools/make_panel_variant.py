# -*- coding: utf-8 -*-
"""面板底图「阳光 / 星光」变体（用户 2026-09-20：不要暗调，要阳光的或星星亮一点、色彩风格）

在现役 bookpage_bg.png 上就地加工（不改尺寸、不动 alpha）：
  1. 整体提亮 + 轻微暖色（旧纸 → 被阳光照着的纸）
  2. 右上角一团暖光晕（additive，二次衰减；可选）
  3. 星光：散布四芒星闪光（白/金/淡紫）、越靠上越多越大（可选）

用法：python make_panel_variant.py <in.png> <out.png> [--glow 0.55] [--stars 90] [--lift 1.06] [--warm 1.03]
      --glow 0=不要光晕；--stars 0=不要星光
"""
import os, sys, math, random
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import Image, read_png, write_png


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]

    def opt(n, d):
        return float(sys.argv[sys.argv.index("--" + n) + 1]) if "--" + n in sys.argv else d

    inp, outp = args[0], args[1]
    glow = opt("glow", 0.55)
    stars = int(opt("stars", 90))
    lift = opt("lift", 1.06)
    warm = opt("warm", 1.03)
    knee = opt("knee", 0.5)     # 高光软压缩：>200 的部分乘 knee（防"爆白丢纸纹"）

    im = read_png(inp)
    W, H = im.w, im.h
    # 光晕中心：右上（阳光从右上打进来）
    gx, gy = W * 0.80, H * 0.12
    grmax = math.hypot(max(gx, W - gx), max(gy, H - gy))

    # ---- 1+2：提亮、暖色、光晕 ----
    for y in range(H):
        for x in range(W):
            i = (y * W + x) * 4
            if im.px[i + 3] == 0:
                continue
            r, g, b = im.px[i], im.px[i + 1], im.px[i + 2]
            r = r * lift * warm
            g = g * lift * (warm * 0.995)
            b = b * lift * (warm * 0.95)
            if glow > 0:
                d = math.hypot(x - gx, y - gy) / grmax
                k = max(0.0, 1.0 - d) ** 2.2 * glow * 255.0
                r += k * 1.00; g += k * 0.78; b += k * 0.42
            if knee > 0:
                r = 200 + (r - 200) * knee if r > 200 else r
                g = 200 + (g - 200) * knee if g > 200 else g
                b = 200 + (b - 200) * knee if b > 200 else b
            im.px[i] = max(0, min(255, int(r)))
            im.px[i + 1] = max(0, min(255, int(g)))
            im.px[i + 2] = max(0, min(255, int(b)))

    # ---- 3：星光（四芒星 + 柔光点）----
    if stars > 0:
        rnd = random.Random(20260920)
        cols = [(255, 252, 236), (255, 240, 190), (238, 220, 255), (255, 255, 255)]
        for _ in range(stars):
            x = rnd.randrange(0, W)
            # 上密下疏（面板上半是"天"，下半是留白）
            y = int(H * (rnd.random() ** 1.7))
            big = rnd.random() < 0.22
            R = (rnd.uniform(9, 22) if big else rnd.uniform(3.5, 8))
            col = cols[rnd.randrange(0, len(cols))]
            # 柔光
            rad = int(R * 1.9)
            for dy in range(-rad, rad + 1):
                for dx in range(-rad, rad + 1):
                    d = math.hypot(dx, dy)
                    if d > rad:
                        continue
                    k = (1.0 - d / rad) ** 2.4
                    px, py = x + dx, y + dy
                    if not (0 <= px < W and 0 <= py < H):
                        continue
                    j = (py * W + px) * 4
                    if im.px[j + 3] == 0:
                        continue
                    f = 0.42 * k
                    im.px[j] = min(255, int(im.px[j] + (col[0] - im.px[j]) * f))
                    im.px[j + 1] = min(255, int(im.px[j + 1] + (col[1] - im.px[j + 1]) * f))
                    im.px[j + 2] = min(255, int(im.px[j + 2] + (col[2] - im.px[j + 2]) * f))
            # 四芒星芒（横竖两条细线，外粗内细）
            for t in range(int(R * 2.6)):
                for (dx, dy) in ((t, 0), (-t, 0), (0, t), (0, -t)):
                    px, py = x + dx, y + dy
                    if not (0 <= px < W and 0 <= py < H):
                        continue
                    j = (py * W + px) * 4
                    if im.px[j + 3] == 0:
                        continue
                    f = max(0.0, 1.0 - t / (R * 2.6)) ** 1.6 * 0.75
                    im.px[j] = min(255, int(im.px[j] + (255 - im.px[j]) * f))
                    im.px[j + 1] = min(255, int(im.px[j + 1] + (252 - im.px[j + 1]) * f))
                    im.px[j + 2] = min(255, int(im.px[j + 2] + (230 - im.px[j + 2]) * f))
            # 星心
            im.put(x, y, (255, 255, 250, im.px[(y * W + x) * 4 + 3]))

    os.makedirs(os.path.dirname(os.path.abspath(outp)), exist_ok=True)
    write_png(outp, im)
    tot = n = 0
    for i in range(0, W * H * 4, 4):
        if im.px[i + 3] < 200:
            continue
        tot += (im.px[i] * 299 + im.px[i + 1] * 587 + im.px[i + 2] * 114) // 1000
        n += 1
    print("写好 %s  (%dx%d, 平均亮度 %.1f, glow=%.2f stars=%d)" % (outp, W, H, tot / max(1, n), glow, stars))


if __name__ == "__main__":
    main()
