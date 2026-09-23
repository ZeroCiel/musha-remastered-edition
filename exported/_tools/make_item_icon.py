# -*- coding: utf-8 -*-
"""通用「物品/建筑图标」生成器：任意一张带 alpha 的图 → 64x64 物品栏图标

口径（和信差包图标那套一致）：
  · 按内容框裁掉四周留白 → 等比缩到 inner 以内 → 居中放 64x64
  · 预乘 alpha 面积平均（缩小时边缘不出白边）
  · ★ 只出 PNG。要进游戏：png.exe <图.png> <图片所在目录> → 同名 .tex + .xml
用法：python make_item_icon.py <源图.png> <输出png> [inner=58] [icon=64]
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import Image, read_png, write_png
from make_mailbox_art import content_bbox, downscale_box


def main():
    src_p = sys.argv[1]
    out_p = sys.argv[2]
    inner = int(sys.argv[3]) if len(sys.argv) > 3 else 58
    icon = int(sys.argv[4]) if len(sys.argv) > 4 else 64
    im = read_png(src_p)
    bb = content_bbox(im, thr=8)
    cw, ch = bb[2] - bb[0] + 1, bb[3] - bb[1] + 1
    k = min(inner / float(cw), inner / float(ch))
    ow, oh = max(1, int(round(cw * k))), max(1, int(round(ch * k)))
    small = downscale_box(im, bb[0], bb[1], bb[2], bb[3], ow, oh)
    cv = Image(icon, icon)
    dx, dy = (icon - ow) // 2, (icon - oh) // 2
    for y in range(oh):
        for x in range(ow):
            i = (y * ow + x) * 4
            if small.px[i + 3] == 0:
                continue
            o = ((y + dy) * icon + (x + dx)) * 4
            cv.px[o:o + 4] = small.px[i:i + 4]
    os.makedirs(os.path.dirname(os.path.abspath(out_p)), exist_ok=True)
    write_png(out_p, cv)
    print("源内容 %dx%d → 图标 %dx%d（内容 %dx%d，居中）  写出 %s" % (cw, ch, icon, icon, ow, oh, out_p))


if __name__ == "__main__":
    main()
