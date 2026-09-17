"""工坊预览图：把 图片/想充当封面.png（1329x1024）做成 Steam 工坊要的 1280x720 preview.png
   —— dst_mod_publisher 的表单里 previewFile 默认就找 `preview.png`，所以放 mod 根目录最省事。

做法：等比缩到"填满"，居中裁掉多余上下，再压在深色底上（避免透明边）。
用法：python exported/_tools/make_workshop_preview.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import Image, read_png, write_png

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.normpath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(MOD, "图片", "想充当封面.png")
DST = os.path.join(MOD, "preview.png")
W, H = 1280, 720
BG = (26, 20, 16)          # 深棕黑底（和职业面板的暖色调一致）


def cover_fit(im, w, h):
    """等比缩放到填满 w×h，居中裁切；预乘 alpha 的区域平均"""
    s = max(float(w) / im.w, float(h) / im.h)
    dw, dh = max(w, int(round(im.w * s))), max(h, int(round(im.h * s)))
    tmp = Image(dw, dh)
    # 先把源图按 s 缩放（box filter 预乘 alpha）
    for ty in range(dh):
        sy0, sy1 = ty / s, (ty + 1) / s
        iy0, iy1 = int(sy0), max(int(sy1), int(sy0) + 1)
        for tx in range(dw):
            sx0, sx1 = tx / s, (tx + 1) / s
            ix0, ix1 = int(sx0), max(int(sx1), int(sx0) + 1)
            sa = sr = sg = sb = n = 0
            for yy in range(iy0, iy1):
                if yy < 0 or yy >= im.h:
                    continue
                rb = yy * im.w * 4
                for xx in range(ix0, ix1):
                    if xx < 0 or xx >= im.w:
                        continue
                    i = rb + xx * 4
                    a = im.px[i + 3]
                    n += 1
                    if a == 0:
                        continue
                    sa += a
                    sr += im.px[i] * a
                    sg += im.px[i + 1] * a
                    sb += im.px[i + 2] * a
            if n == 0:
                continue
            j = (ty * dw + tx) * 4
            if sa == 0:
                tmp.px[j:j + 4] = bytes((0, 0, 0, 0))
            else:
                tmp.px[j:j + 4] = bytes((min(255, sr // sa), min(255, sg // sa),
                                         min(255, sb // sa), min(255, sa // n)))
    # 居中裁
    ox, oy = (dw - w) // 2, (dh - h) // 2
    out = Image(w, h)
    for y in range(h):
        src_off = ((y + oy) * dw + ox) * 4
        row = tmp.px[src_off:src_off + w * 4]
        o = y * w * 4
        out.px[o:o + w * 4] = row
    # 压到纯色底（预览图不该有透明区）
    for i in range(0, w * h * 4, 4):
        a = out.px[i + 3]
        if a == 255:
            continue
        if a == 0:
            out.px[i], out.px[i + 1], out.px[i + 2], out.px[i + 3] = BG[0], BG[1], BG[2], 255
        else:
            ia = 255 - a
            out.px[i] = (out.px[i] * a + BG[0] * ia) // 255
            out.px[i + 1] = (out.px[i + 1] * a + BG[1] * ia) // 255
            out.px[i + 2] = (out.px[i + 2] * a + BG[2] * ia) // 255
            out.px[i + 3] = 255
    return out


def main():
    im = read_png(SRC)
    print("源图:", SRC, im.w, "x", im.h)
    out = cover_fit(im, W, H)
    write_png(DST, out)
    print("预览图:", DST, "%dx%d" % (W, H), "%.0f KB" % (os.path.getsize(DST) / 1024.0))
    print("\n形状自检（亮度档）:")
    ramp = " .:-=+*#%@"
    for y in range(0, H, 40):
        row = []
        for x in range(0, W, 20):
            i = (y * W + x) * 4
            lum = (out.px[i] * 299 + out.px[i + 1] * 587 + out.px[i + 2] * 114) // 1000
            row.append(ramp[min(9, lum * 10 // 256)])
        print("   |" + "".join(row) + "|")


if __name__ == "__main__":
    main()
