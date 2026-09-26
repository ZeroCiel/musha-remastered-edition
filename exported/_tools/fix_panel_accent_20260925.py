#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""panel_bg 底部内衬线重画成实线（修正上一版的虚线点）
暖奶油色判定（r>230, g>218, 195<b<248, r-b>15）才可覆盖 → 白花瓣/绿叶/花蕊被排除，
边框上方阴影带（暖色）可覆盖；by(x) 必须落在 720-738（真边框带），花丛区自动跳过。
"""
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
P = os.path.join(HERE, "..", "..", "images", "panel_bg.png")
im = Image.open(P).convert("RGBA")
px = im.load()


def is_gold(c):
    r, g, b, a = c
    return a > 200 and r > 195 and 140 < g < 228 and b < 190


def warm(c):
    r, g, b, a = c
    return a > 200 and r > 230 and g > 218 and 170 < b < 248 and (r - b) > 15


SRC_Y0, SRC_Y1 = 114, 123
drawn = skipped = 0
for x in range(216, 1124):
    by = None
    for y in range(700, 746):
        if is_gold(px[x, y]):
            by = y; break
    if by is None or not (720 <= by <= 738):
        skipped += 1; continue
    col = [px[x, y] for y in range(SRC_Y0, SRC_Y1 + 1)]
    if not any(is_gold(c) for c in col):
        skipped += 1; continue
    cy = by - 6
    for k, dy in enumerate(range(-4, 5)):
        yy = cy + dy
        sy = SRC_Y0 + k
        c = px[x, sy]
        if warm(px[x, yy]) or is_gold(px[x, yy]):
            px[x, yy] = c
            drawn += 1
        else:
            skipped += 1
print("重画 %d px，跳过 %d px" % (drawn, skipped))
im.save(P)
print("已保存", P)
