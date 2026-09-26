#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""panel_bg.png 检修（2026-09-25，用户标注：星星去掉 + 上下边框对不上）
1) 摘除纸面内 9 颗星星/光点（4 向最近纸色插值，保留纵向渐变；被摘补丁存 _tmp 便于回滚）
2) 重建断线：左右金竖线在"两框合并"接缝处（y≈305-500）中断、顶/底双金线局部断缺——
   按健康段剖面补画，装饰（翅膀/花/招牌）压线处跳过
原版备份：exported/_tools/_tmp/panel_bg_backup_20260925.png（git 里 panel_bg.png 也是干净的）
"""
import os
import sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
P = os.path.join(HERE, "..", "..", "images", "panel_bg.png")
BAK = os.path.join(HERE, "_tmp", "panel_bg_backup_20260925.png")
os.makedirs(os.path.dirname(BAK), exist_ok=True)

im = Image.open(P).convert("RGBA")
if not os.path.exists(BAK):
    im.save(BAK)
    print("备份 →", BAK)
px = im.load()
W, H = im.size


def is_paper(c):
    r, g, b, a = c
    return a > 200 and r > 235 and g > 225 and b > 200


def is_line(c):
    r, g, b, a = c
    return a > 200 and r > 195 and 150 < g < 225 and 80 < b < 190


# ── 1) 摘星 ──────────────────────────────────────────────
STARS = [
    (212, 130, 235, 155), (884, 141, 901, 158), (972, 200, 1001, 229),
    (1056, 245, 1065, 252), (1067, 261, 1073, 270), (1097, 261, 1103, 268),
    (217, 284, 231, 298), (218, 339, 253, 363), (1099, 354, 1117, 366),
]
os.makedirs(os.path.join(HERE, "_tmp", "removed_stars"), exist_ok=True)
PAD = 3
for i, (x0, y0, x1, y1) in enumerate(STARS):
    x0, y0, x1, y1 = x0 - PAD, y0 - PAD, x1 + PAD, y1 + PAD
    im.crop((x0, y0, x1 + 1, y1 + 1)).save(
        os.path.join(HERE, "_tmp", "removed_stars", "star_%02d.png" % i))
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            # 4 向最近的纸面像素
            acc, wt = [0, 0, 0], 0
            for dx, dy, dw in ((1, 0, 1), (-1, 0, 1), (0, 1, 1), (0, -1, 1)):
                xx, yy = x, y
                step = 0
                while 0 <= xx + dx < W and 0 <= yy + dy < H and step < 120:
                    xx += dx; yy += dy; step += 1
                    if not (x0 <= xx <= x1 and y0 <= yy <= y1) and is_paper(px[xx, yy]):
                        w = dw / step
                        c = px[xx, yy]
                        acc[0] += c[0] * w; acc[1] += c[1] * w; acc[2] += c[2] * w
                        wt += w
                        break
            if wt:
                px[x, y] = (round(acc[0] / wt), round(acc[1] / wt), round(acc[2] / wt), 255)
print("摘星 9 颗完成")


# ── 2) 断线重建 ──────────────────────────────────────────
def presence_x(y, x0, x1):        # 竖线上某 y 是否有线
    return any(is_line(px[x, y]) for x in range(x0, x1 + 1))


def presence_y(x, y0, y1):        # 横线上某 x 是否有线
    return any(is_line(px[x, y]) for y in range(y0, y1 + 1))


def missing_runs(vals):
    runs, cur = [], None
    for i, v in enumerate(vals):
        if not v:
            cur = [i, i] if cur is None else [cur[0], i]
        else:
            if cur and cur[1] - cur[0] >= 3:
                runs.append(cur)
            cur = None
    if cur and cur[1] - cur[0] >= 3:
        runs.append(cur)
    return runs


def stamp_column(x0, x1, y0, y1, src_y):
    """把 (x0..x1, src_y) 的一行线剖面竖直盖印到 y0..y1"""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px[x, y] = px[x, src_y]


def stamp_row(y0, y1, x0, x1, src_x):
    for x in range(x0, x1 + 1):
        for y in range(y0, y1 + 1):
            px[x, y] = px[src_x, y]


def paper_guard_x(x0, x1, y):
    return is_paper(px[x1 + 3, y]) or is_paper(px[x0 - 3, y])


def paper_guard_y(y0, y1, x):
    return is_paper(px[x, y1 + 3]) or is_paper(px[x, y0 - 3])


# 左竖线（健康段 y 200-300 的剖面；线心 x≈198-206）
LX0, LX1 = 195, 210
pres = [presence_x(y, LX0, LX1) for y in range(140, 700)]
for a, b in missing_runs(pres):
    y0, y1 = 140 + a, 140 + b
    if paper_guard_x(LX0, LX1, (y0 + y1) // 2):
        stamp_column(LX0, LX1, y0, y1, 250)
        print("左竖线补画 y %d-%d" % (y0, y1))

# 右竖线
RX0, RX1 = 1128, 1144
pres = [presence_x(y, RX0, RX1) for y in range(140, 700)]
for a, b in missing_runs(pres):
    y0, y1 = 140 + a, 140 + b
    if paper_guard_x(RX0, RX1, (y0 + y1) // 2):
        stamp_column(RX0, RX1, y0, y1, 250)
        print("右竖线补画 y %d-%d" % (y0, y1))

# 顶双横线（两道）
for (Y0, Y1, tag) in ((106, 116, "顶A"), (116, 124, "顶B")):
    pres = [presence_y(x, Y0, Y1) for x in range(215, 1125)]
    for a, b in missing_runs(pres):
        x0, x1 = 215 + a, 215 + b
        if paper_guard_y(Y0, Y1, (x0 + x1) // 2):
            stamp_row(Y0, Y1, x0, x1, 600 if Y0 < 112 else 300)
            print("%s补画 x %d-%d" % (tag, x0, x1))

# 底双横线
for (Y0, Y1, tag) in ((707, 717, "底A"), (725, 733, "底B")):
    pres = [presence_y(x, Y0, Y1) for x in range(215, 1125)]
    for a, b in missing_runs(pres):
        x0, x1 = 215 + a, 215 + b
        if paper_guard_y(Y0, Y1, (x0 + x1) // 2):
            stamp_row(Y0, Y1, x0, x1, 600)
            print("%s补画 x %d-%d" % (tag, x0, x1))

im.save(P)
print("已保存", P)
