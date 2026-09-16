#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""月牙形状候选对照 —— 用户 2026-09-16:"一轮月 上窄下宽 朝向右面 像洛克人zero横向发射月牙光 青色 青亮色"

一次出 4 个候选（A/B/C/D）+ 旧对称版(E)，拼成一张对照图，另打 ASCII 便于无视觉环境核对。
选定后再把参数搬进 crescent_gen.py 的 CONFIG 正式出图。

用法：python crescent_variants.py
产出：exported/_test_out/crescent_variants.png（对照图，5 行）
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import crescent_gen as cg

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "_test_out", "crescent_variants.png")

CW, CH = 420, 340          # 每个候选的画布（宽 x 高）—— 竖立月牙要够高，别被裁
SS = 2                     # 超采样
COL_BODY = (0.30, 0.86, 1.00)      # 亮青
COL_CORE = (1.00, 1.00, 1.00)      # 白刃口
CORE_MIX = 0.85

# 每个候选的参数：YS_TOP, YS_BOT, R2RATIO(内圆半径比, <1 = 一臂细一臂粗), TILT(度), 说明
VARIANTS = [
    # 2026-09-16 第五轮：用户"1、3 对；2 有点怪；4 不对"，并标红框指出**辉光**让它"像满月"
    #   → 保留 1/3 的形状，把辉光压掉/去掉。glow=1 原样，0.35 弱光，0.0 无光
    ("1 现样(带辉光·像满月)",  dict(ys_top=0.98, ys_bot=1.06, r2=1.00, tilt=0.0, xs=1.05, e=33.0, glow=1.00)),
    ("2 同1·辉光压到35%",     dict(ys_top=0.98, ys_bot=1.06, r2=1.00, tilt=0.0, xs=1.05, e=33.0, glow=0.35)),
    ("3 同1·零辉光(最干净)",   dict(ys_top=0.98, ys_bot=1.06, r2=1.00, tilt=0.0, xs=1.05, e=33.0, glow=0.00)),
    ("4 厚版+零辉光",         dict(ys_top=0.95, ys_bot=1.15, r2=1.00, tilt=0.0, xs=1.05, e=46.0, glow=0.00)),
]
SHOW_ASCII = {0, 2}        # 只打这几版的 ASCII（省输出）


def sample(x, y, cx, cy, R, E, XS, p):
    """返回 (r,g,b,a) 0..255；p = 参数字典（E/XS/r2/内弧/切平 也走这里）"""
    XS = p.get("xs", XS)
    E = p.get("e", E)
    u = (x - cx) / XS
    dy = y - cy
    if p["tilt"]:
        th = math.radians(p["tilt"])
        c, s = math.cos(th), math.sin(th)
        u, dy = (u * c - dy * s), (u * s + dy * c)
    if dy < 0:
        k = cg.clamp(-dy / (R * p["ys_bot"]))
        ys = p["ys_bot"] + (p["ys_top"] - p["ys_bot"]) * k
    else:
        ys = p["ys_bot"]
    v = dy / ys
    d_out = math.hypot(u, v) - R
    f_in = R * p["r2"] - math.hypot(u + E, v)
    sd = d_out if d_out > f_in else f_in
    if p.get("cut") is not None and u < p["cut"]:
        sd = 999.0                                   # 左边直接切平（当体外处理，连辉光一起切）
    if p.get("vtop") is not None and v < -p["vtop"] * R:
        sd = 999.0                                   # 切掉上尖（"左边那两条胳膊"）
    if p.get("vbot") is not None and v > p["vbot"] * R:
        sd = 999.0                                   # 切掉下尖
    t = cg.clamp(-d_out / E)
    body = cg.clamp((0.8 - sd) / 1.6)
    _g = p.get("glow", 1.0)
    glow = _g * (cg.GLOW1[0] * math.exp(-max(sd, 0.0) / cg.GLOW1[1])
                 + cg.GLOW2[0] * math.exp(-max(sd, 0.0) / cg.GLOW2[1]))
    core = (1.0 - t) ** 1.6 * CORE_MIX
    col = cg.mix(COL_BODY, COL_CORE, cg.clamp(core))
    a = cg.clamp(body * (0.80 + 0.20 * (1.0 - t)) + glow * (1.0 - 0.6 * body))
    return (int(col[0] * 255), int(col[1] * 255), int(col[2] * 255), int(a * 255))


def render(p, R=110.0, E=26.0, XS=1.45):
    cx, cy = (CW - 1) / 2.0, (CH - 1) / 2.0
    inv = 1.0 / (SS * SS)
    px = []
    for y in range(CH):
        for x in range(CW):
            r = g = b = a = 0.0
            for j in range(SS):
                for i in range(SS):
                    rr, gg, bb, aa = sample(x + (i + .5) / SS - .5, y + (j + .5) / SS - .5, cx, cy, R, E, XS, p)
                    r += rr; g += gg; b += bb; a += aa
            px.append((int(r * inv + .5), int(g * inv + .5), int(b * inv + .5), int(a * inv + .5)))
    return px


def ascii_of(px):
    rows = []
    for yy in range(0, CH, 12):
        line = ""
        for xx in range(0, CW, 8):
            a = 0
            for y in range(yy, min(yy + 12, CH)):
                for x in range(xx, min(xx + 8, CW)):
                    v = px[y * CW + x][3]
                    if v > a:
                        a = v
            line += " " if a < 40 else ("." if a < 140 else ("o" if a < 230 else "#"))
        rows.append(line.rstrip())
    while rows and rows[0] == "":
        rows.pop(0)
    while rows and rows[-1] == "":
        rows.pop()
    return rows


os.makedirs(os.path.dirname(OUT), exist_ok=True)
all_px = []
report = []
for _vi, (name, p) in enumerate(VARIANTS):
    px = render(p)
    all_px.append(px)
    b = [i for i, q in enumerate(px) if q[3] > 40]
    xs = [i % CW for i in b]; ys = [i // CW for i in b]
    w = (max(xs) - min(xs) + 1) if b else 0
    h = (max(ys) - min(ys) + 1) if b else 0
    report.append((name, w, h, ascii_of(px) if _vi in SHOW_ASCII else None))

# 拼成一张（竖排，每行之间 12px 间隔 + 行底色区分）
GAP = 12
total_h = CH * len(all_px) + GAP * (len(all_px) - 1)
sheet_px = [(30, 34, 40, 255)] * (CW * total_h)
for k, px in enumerate(all_px):
    oy = k * (CH + GAP)
    for y in range(CH):
        for x in range(CW):
            i = (y * CW + x)
            q = px[i]
            if q[3] == 0:
                continue
            j = ((oy + y) * CW + x)
            sheet_px[j] = q
cg.write_png(OUT, CW, total_h, sheet_px)

for name, w, h, rows in report:
    print("=== %s   实体 %dx%d  比例 %.2f:1" % (name, w, h, (float(w) / h if h else 0)))
    for r in (rows or []):
        print("   " + r)
print("对照图：%s" % OUT)
