# -*- coding: utf-8 -*-
"""UI 图「DST 暗调」批处理：压亮度 / 降饱和 / 压纯白 / 加暗角（纯标准库）

用途：面板底图、便签底图、背包图标这类 UI 图，把「奶白 + 糖果色」压成 DST 的旧纸/暗木调。
不动 alpha，不动尺寸。

用法：
  python ui_tone_pass.py <in.png> <out.png> [--target-lum 185] [--max 236] [--sat 0.45] [--vignette 0.22]
      --target-lum  目标平均亮度（不透明像素）
      --max         最亮像素上限（压纯白；0=不压）
      --sat         保留多少比对饱和（1=不变，0.45=明显去糖）
      --vignette    四角压暗幅度（0=不加）
"""
import os, sys, math
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import Image, read_png, write_png


def stats(im, thr=200):
    tot = n = dark = 0
    for i in range(0, im.w * im.h * 4, 4):
        if im.px[i + 3] < thr: continue
        r, g, b = im.px[i], im.px[i + 1], im.px[i + 2]
        lum = (r * 299 + g * 587 + b * 114) // 1000
        tot += lum; n += 1
        if lum < 60: dark += 1
    return (tot / max(1, n), 100.0 * dark / max(1, n), n)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    def opt(name, d):
        return float(sys.argv[sys.argv.index("--" + name) + 1]) if "--" + name in sys.argv else d
    inp, outp = args[0], args[1]
    target_lum = opt("target-lum", 185)
    mx = opt("max", 236)
    sat_k = opt("sat", 0.45)
    vig = opt("vignette", 0.22)

    im = read_png(inp)
    l0, d0, n0 = stats(im)
    # 压亮度：**线性缩放**（比 gamma 曲线干净：不会把暗部压死、不出条带）
    #   想要更狠的暗部可以加 --gamma 2.2 之类，默认 1.0 = 纯线性
    s_lin = (target_lum / l0) if l0 > 1 else 1.0
    g = opt("gamma", 1.0)
    tint = (1.0, 0.975, 0.92) if opt("warm", 1) else (1.0, 1.0, 1.0)

    out = Image(im.w, im.h)
    cx, cy = im.w / 2.0, im.h / 2.0
    rmax = math.hypot(cx, cy)
    for y in range(im.h):
        for x in range(im.w):
            i = (y * im.w + x) * 4
            a = im.px[i + 3]
            if a == 0:
                continue
            r, gg, b = im.px[i], im.px[i + 1], im.px[i + 2]
            lum = (r * 299 + gg * 587 + b * 114) / 1000.0
            newL = 255.0 * (lum / 255.0) ** g * s_lin
            # 保留部分色相：new = newL + (原色 - 原亮度) * sat_k，再乘暖色调
            nr = (newL + (r - lum) * sat_k) * tint[0]
            ng = (newL + (gg - lum) * sat_k) * tint[1]
            nb = (newL + (b - lum) * sat_k) * tint[2]
            if vig > 0:
                k = math.hypot(x - cx, y - cy) / rmax          # 0 中心 1 角
                f = 1.0 - vig * (k ** 2.2)
                nr *= f; ng *= f; nb *= f
            if mx > 0:
                nr = min(nr, mx); ng = min(ng, mx); nb = min(nb, mx)
            out.px[i] = max(0, min(255, int(round(nr))))
            out.px[i + 1] = max(0, min(255, int(round(ng))))
            out.px[i + 2] = max(0, min(255, int(round(nb))))
            out.px[i + 3] = a
    os.makedirs(os.path.dirname(os.path.abspath(outp)), exist_ok=True)
    write_png(outp, out)
    l1, d1, n1 = stats(out)
    print("linear=%.4f gamma=%.2f sat=%.2f vig=%.2f max=%d warm=%d" % (s_lin, g, sat_k, vig, mx, opt("warm", 1)))
    print("  平均亮度 %.1f → %.1f   近黑 %.1f%% → %.1f%%   不透明 %d → %d"
          % (l0, l1, d0, d1, n0, n1))
    print("  写出", outp)


if __name__ == "__main__":
    main()
