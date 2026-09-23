# -*- coding: utf-8 -*-
"""信差包（地上 / 手里贴图）美术 → 可进游戏的 build

源图：参考图/信差包.png（1606x979，透明底）
输出：exported/musha_mailbag/musha_mailbag-0.png / musha_mailbag.scml / _preview_洋红底.png

口径（道具类，跟 papyrus 那种原版道具一个量级）：
  · 原版 papyrus 地上贴图声明 = 204x102；信差包是包 → 内容高取 120 左右
  · 落地点 = **包底中心**（躺在地上）→ pivot_y 由「底面往上一点点」反推；pivot_x = 0.5
  · 内容高按 100 声明px ≈ 1 世界单位 换算

用法：python make_mailbag_art.py [内容目标高] [源图]
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import Image, read_png, write_png
from make_mailbox_art import downscale_box, content_bbox

M = os.path.abspath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(M, "参考图", "信差包.png")
D = os.path.join(M, "exported", "musha_mailbag")
NAME = "musha_mailbag"

TARGET_H = 120          # 内容目标高（声明px）★ 嫌大/嫌小改这个
PAD_X = 12
PAD_TOP = 10
PAD_BOTTOM = 12
GROUND_UP = 3           # 落地点在内容最下缘往上几像素


def main():
    target_h = int(sys.argv[1]) if len(sys.argv) > 1 else TARGET_H
    src_path = sys.argv[2] if len(sys.argv) > 2 else SRC
    os.makedirs(D, exist_ok=True)
    print("源图 =", src_path)
    src = read_png(src_path)
    bb = content_bbox(src)
    cw, ch = bb[2] - bb[0] + 1, bb[3] - bb[1] + 1
    k = target_h / float(ch)
    ow, oh = max(1, int(round(cw * k))), target_h
    small = downscale_box(src, bb[0], bb[1], bb[2], bb[3], ow, oh)
    canvas_w = ow + PAD_X * 2
    canvas_h = oh + PAD_TOP + PAD_BOTTOM
    cv = Image(canvas_w, canvas_h)
    for y in range(oh):
        for x in range(ow):
            i = (y * ow + x) * 4
            if small.px[i + 3] == 0:
                continue
            o = ((y + PAD_TOP) * canvas_w + (x + PAD_X)) * 4
            cv.px[o:o + 4] = small.px[i:i + 4]
    ground_y = PAD_TOP + oh - 1 - GROUND_UP
    pivot_x, pivot_y = 0.5, 1.0 - ground_y / float(canvas_h)
    print("源内容 %dx%d → 画布 %dx%d 内容 %dx%d 落地点 y=%d pivot=(%.6f, %.6f)"
          % (cw, ch, canvas_w, canvas_h, ow, oh, ground_y, pivot_x, pivot_y))
    write_png(os.path.join(D, NAME + "-0.png"), cv)

    scml = """<?xml version="1.0" encoding="UTF-8"?>
<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="r7">
    <folder id="0" name="%s">
        <file id="0" name="%s-0.png" width="%d" height="%d" pivot_x="%s" pivot_y="%s"/>
    </folder>
    <entity id="0" name="%s">
        <animation id="0" name="idle" length="1000" interval="100">
            <mainline>
                <key id="0">
                    <object_ref id="0" timeline="0" key="0" z_index="0"/>
                </key>
            </mainline>
            <timeline id="0" name="idle">
                <key id="0" spin="0">
                    <object folder="0" file="0" x="0" y="0"/>
                </key>
            </timeline>
        </animation>
    </entity>
</spriter_data>
""" % (NAME, NAME, canvas_w, canvas_h, pivot_x, round(pivot_y, 6), NAME)
    sp = os.path.join(D, NAME + ".scml")
    open(sp, "w", encoding="utf-8").write(scml)

    pv = Image(canvas_w, canvas_h)
    for i in range(0, canvas_w * canvas_h * 4, 4):
        pv.px[i:i + 4] = bytes((255, 0, 255, 255))
    for y in range(canvas_h):
        for x in range(canvas_w):
            a = cv.px[(y * canvas_w + x) * 4 + 3]
            if a:
                j = (y * canvas_w + x) * 4
                ia = 255 - a
                for m in range(3):
                    pv.px[j + m] = (cv.px[j + m] * a + pv.px[j + m] * ia) // 255
                pv.px[j + 3] = 255
    for dd in range(-12, 13):
        for (x, y) in ((canvas_w // 2 + dd, ground_y), (canvas_w // 2, ground_y + dd)):
            if 0 <= x < canvas_w and 0 <= y < canvas_h:
                pv.px[(y * canvas_w + x) * 4:(y * canvas_w + x) * 4 + 4] = bytes((0, 0, 0, 255))
    write_png(os.path.join(D, "_preview_信差包_洋红底.png"), pv)
    print("写好：", os.path.join(D, NAME + "-0.png"))
    print("写好：", sp)


if __name__ == "__main__":
    main()
