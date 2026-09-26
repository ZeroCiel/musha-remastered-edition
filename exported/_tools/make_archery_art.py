#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""射箭动画原型 · 素材生成器（程序化画弓箭手 5 姿势 + 一支箭）
输出 exported/_test_out/sp_archery/：archer-0..4.png（100x120）+ arrow-0.png（44x10）
之后用 sp_model_tool.write_scml 编成 双符号动画（姿势换帧 + 箭位移关键帧）。
风格：Q 版侧脸朝右，深色描边（dilate 出 1px 轮廓），DST 调不用纯黑。
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
OUT = os.path.join(HERE, "_test_out", "sp_archery")
os.makedirs(OUT, exist_ok=True)

OUT_C = (58, 46, 46, 255)
SKIN = (255, 219, 186, 255)
HAIR = (72, 52, 40, 255)
TUNIC = (150, 110, 70, 255)
BELT = (96, 72, 48, 255)
PANTS = (84, 74, 66, 255)
BOW = (168, 118, 56, 255)
STRING = (238, 238, 238, 255)
SHAFT = (190, 150, 95, 255)
FEATHER = (220, 84, 80, 255)
TIP = (206, 206, 216, 255)
SHADOW = (30, 24, 24, 70)

W, H = 100, 120
HEAD = (46, 34, 13)          # cx, cy, r
SHOULDER_F = (47, 52)        # 前肩（持弓臂）
SHOULDER_B = (39, 52)        # 后肩（钩弦臂）


def bezier(p0, p1, p2, n=14):
    pts = []
    for i in range(n + 1):
        t = i / n
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
        pts.append((x, y))
    return pts


def line(d, pts, w, c):
    d.line(pts, fill=c, width=w, joint="curve")
    for p in (pts[0], pts[-1]):
        d.ellipse([p[0] - w / 2, p[1] - w / 2, p[0] + w / 2, p[1] + w / 2], fill=c)


def blob(d, xy, r, c):
    d.ellipse([xy[0] - r, xy[1] - r, xy[0] + r, xy[1] + r], fill=c)


def body(d):
    """头 + 身体 + 腿（站姿固定，姿势差异全在手臂/弓）"""
    blob(d, (HEAD[0], HEAD[1]), HEAD[2], SKIN)
    # 头发：头顶+后脑勺
    d.pieslice([HEAD[0] - HEAD[2] - 2, HEAD[1] - HEAD[2] - 2,
                HEAD[0] + HEAD[2] + 2, HEAD[1] + HEAD[2] + 2], 150, 330, fill=HAIR)
    # 侧脸眼睛（朝右）
    d.ellipse([HEAD[0] + 5, HEAD[1] - 3, HEAD[0] + 9, HEAD[1] + 1], fill=OUT_C)
    # 身体（袍子）
    d.polygon([(37, 47), (57, 47), (61, 78), (33, 78)], fill=TUNIC)
    d.rectangle([33, 66, 61, 71], fill=BELT)
    # 腿脚
    line(d, [(43, 78), (41, 106)], 6, PANTS)
    line(d, [(51, 78), (54, 106)], 6, PANTS)
    d.rectangle([35, 104, 47, 110], fill=PANTS)
    d.rectangle([50, 104, 62, 110], fill=PANTS)


def bow(d, grip, nock=None, string_sag=0):
    """弓：竖放。grip=握弓点；nock=弦拉到的点(None=弦松弛)。返回搭弦点。"""
    bx, gy = grip
    top, bot = (bx - 2, gy - 28), (bx - 2, gy + 28)
    limb = bezier(top, (bx + 8, gy), bot)
    line(d, limb, 4, BOW)
    blob(d, (bx + 1, gy), 3, BOW)                       # 握把
    if nock is None:
        spts = bezier(top, (bx - 4 + string_sag, gy), bot)   # 松弦微微内凹
    else:
        spts = [top, nock, bot]
    line(d, spts, 1, STRING)
    return nock if nock else (bx - 4, gy)


def arrow_at(d, tail, tip):
    """箭：尾羽在 tail，箭头在 tip（水平朝右）"""
    y = tail[1]
    d.line([(tail[0] + 3, y), (tip[0] - 6, y)], fill=SHAFT, width=2)
    d.polygon([(tip[0] - 6, y - 3), (tip[0], y), (tip[0] - 6, y + 3)], fill=TIP)
    d.polygon([(tail[0], y - 4), (tail[0] + 7, y), (tail[0], y + 4)], fill=FEATHER)


def outline(im):
    """dilate 出 1px 深色描边（垫底）"""
    a = im.getchannel("A")
    edge = a.filter(ImageFilter.MaxFilter(3))
    ol = Image.new("RGBA", im.size, (0, 0, 0, 0))
    op, ep, ap = ol.load(), edge.load(), a.load()
    for y in range(im.height):
        for x in range(im.width):
            if ep[x, y] > 0 and ap[x, y] == 0:
                op[x, y] = OUT_C
    base = Image.new("RGBA", im.size, (0, 0, 0, 0))
    base.alpha_composite(ol)
    base.alpha_composite(im)
    return base


def frame(pose):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    grip_up = (70, 52)
    if pose == 0:      # 持弓立正（弓竖在体侧）
        body(d)
        line(d, [SHOULDER_F, (56, 68), (60, 76)], 5, SKIN)
        line(d, [SHOULDER_B, (46, 66), (52, 74)], 5, SKIN)
        bow(d, (60, 76), nock=None)
    elif pose == 1:    # 举弓（前臂平伸，箭还没搭）
        body(d)
        line(d, [SHOULDER_F, (58, 52), grip_up], 5, SKIN)
        line(d, [SHOULDER_B, (50, 44), (56, 50)], 5, SKIN)
        bow(d, grip_up, nock=None)
    elif pose == 2:    # 拉弦（搭箭，弦拉到脸颊）
        body(d)
        line(d, [SHOULDER_F, (58, 52), grip_up], 5, SKIN)
        line(d, [SHOULDER_B, (33, 44), (48, 50)], 5, SKIN)
        nk = bow(d, grip_up, nock=(48, 52))
        arrow_at(d, nk, (nk[0] + 38, 52))
    elif pose == 3:    # 满弦（再多拉 4px，肘抬更高）
        body(d)
        line(d, [SHOULDER_F, (58, 52), grip_up], 5, SKIN)
        line(d, [SHOULDER_B, (31, 40), (44, 50)], 5, SKIN)
        nk = bow(d, grip_up, nock=(44, 52))
        arrow_at(d, nk, (nk[0] + 38, 52))
    elif pose == 4:    # 放箭（弦回弹微震，后手甩开，箭已离手）
        body(d)
        line(d, [SHOULDER_F, (58, 52), grip_up], 5, SKIN)
        line(d, [SHOULDER_B, (30, 46), (24, 38)], 5, SKIN)
        blob(d, (24, 38), 2, SKIN)
        bow(d, grip_up, nock=None, string_sag=-3)
    # 地面影
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([28, 106, 66, 114], fill=SHADOW)
    sh = sh.filter(ImageFilter.GaussianBlur(1.5))
    out = outline(im)
    out.alpha_composite(sh)
    return out


def make_arrow():
    im = Image.new("RGBA", (44, 10), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.line([(4, 5), (35, 5)], fill=SHAFT, width=2)
    d.polygon([(35, 2), (42, 5), (35, 8)], fill=TIP)
    d.polygon([(4, 1), (12, 5), (4, 9)], fill=FEATHER)
    d.polygon([(8, 1), (15, 5), (8, 9)], fill=FEATHER)
    # 1px 描边
    a = im.getchannel("A")
    edge = a.filter(ImageFilter.MaxFilter(3))
    ol = Image.new("RGBA", im.size, (0, 0, 0, 0))
    op, ep, ap = ol.load(), edge.load(), a.load()
    for y in range(im.height):
        for x in range(im.width):
            if ep[x, y] > 0 and ap[x, y] == 0:
                op[x, y] = OUT_C
    im.alpha_composite(ol)
    return im


def main():
    for i in range(5):
        p = os.path.join(OUT, "archer-%d.png" % i)
        frame(i).save(p)
        print("写出", p)
    p = os.path.join(OUT, "arrow-0.png")
    make_arrow().save(p)
    print("写出", p)
    # 对照表（放大 3 倍）
    K = 3
    sheet = Image.new("RGBA", ((W * K + 10) * 5 + 10, H * K + 30), (70, 70, 78, 255))
    dd = ImageDraw.Draw(sheet)
    for i in range(5):
        fr = Image.open(os.path.join(OUT, "archer-%d.png" % i))
        bg = Image.new("RGBA", fr.size, (0, 0, 0, 0))
        bg.alpha_composite(fr)
        bg = bg.resize((W * K, H * K), Image.NEAREST)
        x = 10 + i * (W * K + 10)
        sheet.alpha_composite(bg, (x, 24))
        dd.text((x, 6), "pose %d" % i, fill=(255, 255, 255, 255))
    sheet.save(os.path.join(OUT, "_poses_preview.png"))
    print("姿势预览 →", os.path.join(OUT, "_poses_preview.png"))


if __name__ == "__main__":
    main()
