# -*- coding: utf-8 -*-
"""祭坛贴图临时替换：把 图片/任务卷轴.png 装成祭坛的 320x320 贴图帧

口径（照 exported/musha_advance_altar/README.txt）：
  · 贴图原点 = 图片正中心 (160,160) = 游戏里的落地点
  · 内容缩放后居中偏上放，底边压在落地点附近
  · 缩小时用预乘 alpha 的面积平均，避免边缘出黑边
产物：
  exported/musha_advance_altar/musha_advance_altar-0.png       （旧的原图先备份到 _bak/）
  exported/musha_advance_altar/_preview_altar_任务卷轴_洋红底.png  （带中心十字，核对落地点）
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import Image, read_png, write_png

M = os.path.abspath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(M, "图片", "任务卷轴.png")
D = os.path.join(M, "exported", "musha_advance_altar")
BAK = os.path.join(D, "_bak")
TARGET_W = 240          # 内容目标宽度（原祭坛底椭圆 262px 宽，这个略小一点更保险）
CX, CY = 160, 150       # 内容中心落点（画布 320x320；y 略高于中心=底边压住落地点）


def content_bbox(im, thr=0):
    x0, y0, x1, y1 = im.w, im.h, -1, -1
    for y in range(im.h):
        row = y * im.w * 4
        for x in range(im.w):
            if im.px[row + x * 4 + 3] > thr:
                if x < x0: x0 = x
                if y < y0: y0 = y
                if x > x1: x1 = x
                if y > y1: y1 = y
    return x0, y0, x1, y1


def downscale_box(im, x0, y0, x1, y1, ow, oh):
    """预乘 alpha 面积平均"""
    sw, sh = x1 - x0 + 1, y1 - y0 + 1
    out = Image(ow, oh)
    for oy in range(oh):
        sy0 = y0 + int(oy * sh / oh)
        sy1 = y0 + int((oy + 1) * sh / oh)
        if sy1 <= sy0: sy1 = sy0 + 1
        for ox in range(ow):
            sx0 = x0 + int(ox * sw / ow)
            sx1 = x0 + int((ox + 1) * sw / ow)
            if sx1 <= sx0: sx1 = sx0 + 1
            ar = ag = ab = aa = n = 0
            for y in range(sy0, sy1):
                base = y * im.w * 4
                for x in range(sx0, sx1):
                    i = base + x * 4
                    a = im.px[i + 3]
                    ar += im.px[i] * a
                    ag += im.px[i + 1] * a
                    ab += im.px[i + 2] * a
                    aa += a
                    n += 1
            j = (oy * ow + ox) * 4
            if aa:
                out.px[j] = ar // aa
                out.px[j + 1] = ag // aa
                out.px[j + 2] = ab // aa
            out.px[j + 3] = aa // n
    return out


def main():
    os.makedirs(BAK, exist_ok=True)
    src = read_png(SRC)
    print("源图", src.w, "x", src.h)
    bb = content_bbox(src)
    print("内容框", bb, "→", bb[2] - bb[0] + 1, "x", bb[3] - bb[1] + 1)
    cw = bb[2] - bb[0] + 1
    ch = bb[3] - bb[1] + 1
    ow = TARGET_W
    oh = max(1, int(round(ch * ow / float(cw))))
    small = downscale_box(src, bb[0], bb[1], bb[2], bb[3], ow, oh)
    cv = Image(320, 320)
    dx = CX - ow // 2
    dy = CY - oh // 2
    for y in range(oh):
        ty = dy + y
        if ty < 0 or ty >= 320: continue
        for x in range(ow):
            tx = dx + x
            if tx < 0 or tx >= 320: continue
            i = (y * ow + x) * 4
            a = small.px[i + 3]
            if a == 0: continue
            j = (ty * 320 + tx) * 4
            if a == 255:
                cv.px[j:j + 4] = small.px[i:i + 4]
            else:
                ia = 255 - a
                for k in range(3):
                    cv.px[j + k] = (small.px[i + k] * a + cv.px[j + k] * ia) // 255
                cv.px[j + 3] = max(cv.px[j + 3], a)
    # 备份旧贴图
    old = os.path.join(D, "musha_advance_altar-0.png")
    if os.path.exists(old):
        import shutil
        shutil.copy2(old, os.path.join(BAK, "musha_advance_altar-0_原美术.png"))
        print("旧贴图已备份 → _bak/musha_advance_altar-0_原美术.png")
    write_png(old, cv)
    print("写好贴图", old, cv.w, "x", cv.h, "内容", ow, "x", oh, "放在", (dx, dy))

    # 洋红底预览 + 中心十字（核对落地点）
    pv = Image(320, 320)
    for i in range(0, 320 * 320 * 4, 4):
        pv.px[i] = 255; pv.px[i + 1] = 0; pv.px[i + 2] = 255; pv.px[i + 3] = 255
    for y in range(320):
        for x in range(320):
            a = cv.px[(y * 320 + x) * 4 + 3]
            if a:
                j = (y * 320 + x) * 4
                ia = 255 - a
                for k in range(3):
                    pv.px[j + k] = (cv.px[j + k] * a + pv.px[j + k] * ia) // 255
                pv.px[j + 3] = 255
    for d in range(-14, 15):
        for (x, y) in ((160 + d, 160), (160, 160 + d)):
            if 0 <= x < 320 and 0 <= y < 320:
                j = (y * 320 + x) * 4
                pv.px[j:j + 4] = bytes((0, 0, 0, 255))
    p = os.path.join(D, "_preview_altar_任务卷轴_洋红底.png")
    write_png(p, pv)
    print("写好预览", p)


if __name__ == "__main__":
    main()
