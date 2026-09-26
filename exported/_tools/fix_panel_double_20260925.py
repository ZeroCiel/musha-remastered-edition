#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""panel_bg 底边框统一成双线（2026-09-25，用户拍板：全部统一成双线）
1) 移除槽排容器底边线 y≈713（与新内衬线视觉重复）
2) 沿底边框 y≈729 的曲线，在内侧 6px 处（y≈723）画内衬线——列剖面直接从顶部
   内衬线（y=118）复制，风格/颜色/抗锯齿逐列一致；花丛等装饰压线处跳过
"""
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
P = os.path.join(HERE, "..", "..", "images", "panel_bg.png")
im = Image.open(P).convert("RGBA")
px = im.load()


def is_paper(c):
    r, g, b, a = c
    return a > 200 and r > 235 and g > 225 and b > 200


def is_gold(c):
    r, g, b, a = c
    return a > 200 and r > 195 and 140 < g < 228 and b < 190


# ── 1) 移除 y≈713 容器底边线（先量范围再抹）──
xs = [x for x in range(210, 1140) if any(is_gold(px[x, y]) for y in range(706, 721))]
if xs:
    x0, x1 = min(xs) - 2, max(xs) + 2
    print("容器底线 x 范围 %d-%d，抹除" % (x0, x1))
    for y in range(706, 721):
        for x in range(x0, x1 + 1):
            if is_gold(px[x, y]):
                # 左右找纸面像素插值
                acc, wt = [0, 0, 0], 0
                for dx, dw in ((-1, 1), (1, 1)):
                    xx, step = x, 0
                    while 0 <= xx + dx < im.width and step < 80:
                        xx += dx; step += 1
                        if not is_gold(px[xx, y]) and is_paper(px[xx, y]):
                            w = dw / step
                            c = px[xx, y]
                            acc[0] += c[0] * w; acc[1] += c[1] * w; acc[2] += c[2] * w
                            wt += w
                            break
                if wt:
                    px[x, y] = (round(acc[0] / wt), round(acc[1] / wt), round(acc[2] / wt), 255)

# ── 2) 沿底边框画内衬线（y = 底框 - 6）──
SRC_Y0, SRC_Y1 = 114, 123          # 顶部内衬线剖面（中心 118 ± 4）
drawn = skipped = 0
for x in range(216, 1124):
    # 底边框核心 y：y 700-745 里最上方的金像素
    by = None
    for y in range(700, 746):
        if is_gold(px[x, y]):
            by = y; break
    if by is None:
        skipped += 1; continue
    # 源剖面必须真的是内衬线（防招牌/装饰污染）
    col = [px[x, y] for y in range(SRC_Y0, SRC_Y1 + 1)]
    if not any(is_gold(c) for c in col):
        skipped += 1; continue
    cy = by - 6                     # 内衬线中心
    for k, dy in enumerate(range(-4, 5)):
        yy = cy + dy
        sy = SRC_Y0 + k
        c = px[x, sy]
        # 只画在纸面色上，保护花丛/已有装饰
        if is_paper(px[x, yy]) or is_gold(px[x, yy]):
            px[x, yy] = c
            drawn += 1
        else:
            skipped += 1
print("内衬线：画 %d px，跳过 %d px（装饰压线处）" % (drawn, skipped))
im.save(P)
print("已保存", P)
