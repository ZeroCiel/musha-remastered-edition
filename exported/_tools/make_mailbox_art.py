# -*- coding: utf-8 -*-
"""信箱美术 → 可进游戏的 build

输入：图片/信箱.png（1024x1536，带 alpha）
输出：
  exported/musha_mailbox/musha_mailbox-0.png     贴图帧（320 宽，高度按比例算）
  exported/musha_mailbox/musha_mailbox.scml      Spriter 工程（单帧 idle）
  exported/musha_mailbox/_preview_信箱_洋红底.png  预览（黑十字 = 游戏里的落地点）

口径（跟进阶祭坛一套，但落地点按"竖长物体"重算）：
  · DST 贴图原点 = 落地点，必须画对位置，否则游戏里浮空/沉地
  · 祭坛是俯视的宽扁台子 → 落地点在"底面椭圆中心"
  · 信箱是"杆 + 箱"的竖长物体 → 落地点＝**杆底往上一点点**（杆底踩地）
    所以画布高度不写死 320，按内容算；pivot_y 由"杆底距顶部多少像素"反推
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import Image, read_png, write_png

M = os.path.abspath(os.path.join(HERE, "..", ".."))
# ★ 2026-09-20 用户把源图搬进 `参考图\` 并重做了（DST 暗色调版）：参考图\信箱-重做.png
#   旧的 图片\信箱.png 已不在（被搬走改名）；两个都探一下，也可用命令行第 2 个参数指定
SRC = os.path.join(M, "参考图", "信箱-重做.png")
SRC_FALLBACK = os.path.join(M, "图片", "信箱.png")
D = os.path.join(M, "exported", "musha_mailbox")
NAME = "musha_mailbox"

CANVAS_W = 320          # 画布宽（跟祭坛一致）
TARGET_H = 260          # 内容目标高 ≈ 2.6 个世界单位（玩家约 2.4）
BOTTOM_PAD = 20         # 内容底边距画布底部
GROUND_UP = 4           # 落地点在内容底边往上几像素（杆底踩地）

# ★ 2026-09-20 用户反馈「信箱太小，起码 2.5 倍」→ 加整体缩放开关：
#   python make_mailbox_art.py 2.5
#   画布 / 贴图 / scml 声明 一起 ×2.5（= 游戏里渲染尺寸 ×2.5），贴图跟着变清晰；
#   比在 prefab 里 SetScale(2.5) 好（那个是把同一张图放大 → 糊）。
#   pivot 保持同一相对位置（落地点仍是"杆底往上一点"），prefab 代码不用动。
SCALE = 1.0


def content_bbox(im, thr=0):
    x0, y0, x1, y1 = im.w, im.h, -1, -1
    for y in range(im.h):
        base = y * im.w * 4
        for x in range(im.w):
            if im.px[base + x * 4 + 3] > thr:
                if x < x0: x0 = x
                if y < y0: y0 = y
                if x > x1: x1 = x
                if y > y1: y1 = y
    return x0, y0, x1, y1


def downscale_box(im, x0, y0, x1, y1, ow, oh):
    """预乘 alpha 面积平均（边缘不出白边）"""
    sw, sh = x1 - x0 + 1, y1 - y0 + 1
    out = Image(ow, oh)
    for oy in range(oh):
        sy0 = y0 + int(oy * sh / oh); sy1 = y0 + int((oy + 1) * sh / oh)
        if sy1 <= sy0: sy1 = sy0 + 1
        for ox in range(ow):
            sx0 = x0 + int(ox * sw / ow); sx1 = x0 + int((ox + 1) * sw / ow)
            if sx1 <= sx0: sx1 = sx0 + 1
            ar = ag = ab = aa = n = 0
            for y in range(sy0, sy1):
                base = y * im.w * 4
                for x in range(sx0, sx1):
                    i = base + x * 4
                    a = im.px[i + 3]
                    ar += im.px[i] * a; ag += im.px[i + 1] * a; ab += im.px[i + 2] * a
                    aa += a; n += 1
            j = (oy * ow + ox) * 4
            if aa:
                out.px[j] = ar // aa
                out.px[j + 1] = ag // aa
                out.px[j + 2] = ab // aa
            out.px[j + 3] = aa // n
    return out


def main():
    scale = SCALE
    if len(sys.argv) > 1:
        try:
            scale = float(sys.argv[1])
        except ValueError:
            print("用法: python make_mailbox_art.py [缩放倍数，如 2.5]")
            return
    canvas_w = int(round(CANVAS_W * scale))
    target_h = int(round(TARGET_H * scale))
    bottom_pad = int(round(BOTTOM_PAD * scale))
    ground_up = int(round(GROUND_UP * scale))
    print("整体缩放 x%.3f → 画布宽 %d 内容目标高 %d 落地点抬高 %d" % (scale, canvas_w, target_h, ground_up))
    os.makedirs(D, exist_ok=True)
    src_path = SRC if os.path.exists(SRC) else SRC_FALLBACK
    if len(sys.argv) > 2:
        src_path = sys.argv[2]
    print("源图 =", src_path)
    src = read_png(src_path)
    print("源图", src.w, "x", src.h)
    bb = content_bbox(src)
    cw, ch = bb[2] - bb[0] + 1, bb[3] - bb[1] + 1
    print("内容框", bb, "→", cw, "x", ch)

    k = target_h / float(ch)
    ow, oh = max(1, int(round(cw * k))), target_h
    if ow > canvas_w - 20:                      # 太宽就按宽反算
        ow = canvas_w - 20
        oh = max(1, int(round(ch * ow / float(cw))))
    small = downscale_box(src, bb[0], bb[1], bb[2], bb[3], ow, oh)

    ch_canvas = oh + bottom_pad * 2
    cv = Image(canvas_w, ch_canvas)
    dx = (canvas_w - ow) // 2
    dy = ch_canvas - bottom_pad - oh
    for y in range(oh):
        for x in range(ow):
            i = (y * ow + x) * 4
            cv.px[((y + dy) * canvas_w + (x + dx)) * 4:((y + dy) * canvas_w + (x + dx)) * 4 + 4] = small.px[i:i + 4]

    png_path = os.path.join(D, NAME + "-0.png")
    write_png(png_path, cv)

    ground_y = ch_canvas - bottom_pad - ground_up      # 距顶部像素（落地点）
    pivot_y = 1.0 - ground_y / float(ch_canvas)
    pivot_x = 0.5
    print("画布", canvas_w, "x", ch_canvas, " 内容", ow, "x", oh, " 落地点 y =", ground_y,
          " pivot =", round(pivot_x, 4), round(pivot_y, 4))

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
""" % (NAME, NAME, canvas_w, ch_canvas, pivot_x, round(pivot_y, 6), NAME)
    scml_path = os.path.join(D, NAME + ".scml")
    open(scml_path, "w", encoding="utf-8").write(scml)

    # 洋红底预览 + 落地点十字
    pv = Image(canvas_w, ch_canvas)
    for i in range(0, canvas_w * ch_canvas * 4, 4):
        pv.px[i] = 255; pv.px[i + 1] = 0; pv.px[i + 2] = 255; pv.px[i + 3] = 255
    for y in range(ch_canvas):
        for x in range(canvas_w):
            a = cv.px[(y * canvas_w + x) * 4 + 3]
            if a:
                j = (y * canvas_w + x) * 4
                ia = 255 - a
                for m in range(3):
                    pv.px[j + m] = (cv.px[j + m] * a + pv.px[j + m] * ia) // 255
                pv.px[j + 3] = 255
    for dd in range(-16, 17):
        for (x, y) in ((canvas_w // 2 + dd, ground_y), (canvas_w // 2, ground_y + dd)):
            if 0 <= x < canvas_w and 0 <= y < ch_canvas:
                j = (y * canvas_w + x) * 4
                pv.px[j:j + 4] = bytes((0, 0, 0, 255))
    write_png(os.path.join(D, "_preview_信箱_洋红底.png"), pv)
    print("写好：", png_path)
    print("写好：", scml_path)
    print("写好：", os.path.join(D, "_preview_信箱_洋红底.png"))


if __name__ == "__main__":
    main()
