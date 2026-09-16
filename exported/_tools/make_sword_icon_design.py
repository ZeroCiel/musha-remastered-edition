# -*- coding: utf-8 -*-
"""重画剑图标（DTS 立绘规约版）：竖直/微倾 + 粗描边 + 左上受光 + 亮青能量刃
产出：
  exported/musha_sword_v2/icon_design_c1..c4.png   （64x64 实际尺寸，可直接转 tex）
  桌面/剑图标设计图_20260916.png                    （对照图：每行 1 个候选，含 4x 放大 + 实际尺寸）
  项目内同步一份 exported/musha_sword_v2/icon_design_sheet_20260916.png
"""
import sys, os, math
TOOLS = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\exported\_tools"
sys.path.insert(0, TOOLS)
from pnglib import Image, read_png, write_png, blit, contact_sheet

OUT = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\exported\musha_sword_v2"
DESKTOP = r"C:\Users\Administrator\Desktop"

SS = 4                     # 超采样
N = 64 * SS                # 绘制画布 256
LINE = (20, 24, 44)
GOLD_HI, GOLD, GOLD_D, GOLD_DD = (255, 228, 142), (214, 170, 62), (166, 122, 34), (112, 78, 20)
E_CORE, E_BRIGHT, E_MID, E_DEEP = (236, 250, 255), (120, 214, 255), (56, 150, 224), (32, 104, 180)
GRIP, GRIP_D, GRIP_HI = (44, 40, 66), (28, 26, 44), (72, 66, 100)
SLOT_BG = (222, 216, 200)


def poly(img, pts, color):
    if len(pts) < 3:
        return
    ys = [p[1] for p in pts]
    y0, y1 = int(math.floor(min(ys))), int(math.ceil(max(ys)))
    n = len(pts)
    for y in range(max(0, y0), min(img.h - 1, y1) + 1):
        xs = []
        for i in range(n):
            ax, ay = pts[i]
            bx, by = pts[(i + 1) % n]
            if ay == by:
                continue
            if (ay <= y < by) or (by <= y < ay):
                t = (y - ay) / float(by - ay)
                xs.append(ax + (bx - ax) * t)
        xs.sort()
        for i in range(0, len(xs) - 1, 2):
            for x in range(max(0, int(math.floor(xs[i]))), min(img.w - 1, int(math.ceil(xs[i + 1]))) + 1):
                img.put(x, y, color + (255,) if len(color) == 3 else color)


def rot(pts, ang, cx, cy):
    th = math.radians(ang)
    c, s = math.cos(th), math.sin(th)
    out = []
    for x, y in pts:
        dx, dy = x - cx, y - cy
        out.append((cx + dx * c - dy * s, cy + dx * s + dy * c))
    return out


def draw_icon(tilt=0.0, bw=36.0, energy=True, tall=1.0, wings=True):
    """tilt=倾斜角(度，正=剑尖往右倒)；bw=刃宽；energy=是否画能量刃芯
    ★ 2026-09-16 修：原来给死像素数、总高 245+ 超出画布 → 剑尾水晶被裁掉；
      现在按"整把剑的总长"统一算 fit，再整体居中，保证剑尖到柄尾水晶都装得下。"""
    img = Image(N, N)
    cx, cy = N / 2.0, N / 2.0

    blade_len = 150.0 * tall
    gh = 16.0
    grip_len = 44.0
    pom_d = 24.0
    total = blade_len + gh + grip_len + pom_d + 10.0
    fit = (N * 0.94) / total
    y0 = (N - total * fit) / 2.0
    def Y(u):
        return y0 + u * fit
    def W(u):
        return u * fit

    hw = bw / 2.0
    cut = 22.0
    y_tip = Y(0.0)
    y_guard = Y(blade_len)
    y_grip0 = Y(blade_len + gh)
    y_grip1 = Y(blade_len + gh + grip_len)
    y_pom = Y(blade_len + gh + grip_len + pom_d / 2.0)

    def R(pts):
        return rot(pts, tilt, cx, cy)

    def stroke(pts, grow=3.2):
        g = []
        for x, y in pts:
            dx, dy = x - cx, y - cy
            L = math.hypot(dx, dy) or 1
            g.append((x + dx / L * grow, y + dy / L * grow))
        return g

    # ---- 剑身（金底 + 斜切刀尖）----
    blade = [(cx - hw, y_guard), (cx - hw, y_tip + W(cut)), (cx + hw, y_tip), (cx + hw, y_guard)]
    poly(img, R(stroke(blade, 3.5)), LINE)
    poly(img, R(blade), GOLD)
    poly(img, R([(cx + hw * 0.22, y_guard), (cx + hw * 0.22, y_tip + W(cut * 0.6)),
                 (cx + hw, y_tip + W(3)), (cx + hw, y_guard)]), GOLD_D)
    poly(img, R([(cx - hw, y_guard), (cx - hw, y_tip + W(cut)),
                 (cx - hw * 0.74, y_tip + W(cut * 0.8)), (cx - hw * 0.74, y_guard)]), GOLD_HI)
    poly(img, R([(cx - hw, y_tip + W(cut - 3)), (cx + hw, y_tip - W(2)),
                 (cx + hw, y_tip + W(2)), (cx - hw, y_tip + W(cut + 3))]), GOLD_HI)

    if energy:
        for w_, col in ((bw * 0.46, E_DEEP), (bw * 0.34, E_MID), (bw * 0.20, E_BRIGHT), (bw * 0.085, E_CORE)):
            poly(img, R([(cx - w_ / 2, y_guard - W(5)), (cx - w_ / 2, y_tip + W(cut * 0.95)),
                         (cx + w_ / 2, y_tip + W(cut * 0.3)), (cx + w_ / 2, y_guard - W(5))]), col)

    # ---- 护手 ----
    guard = [(cx - bw * 0.62, y_guard - gh * fit * 0.5), (cx + bw * 0.62, y_guard - gh * fit * 0.5),
             (cx + bw * 0.62, y_guard + gh * fit * 0.5), (cx - bw * 0.62, y_guard + gh * fit * 0.5)]
    poly(img, R(stroke(guard, 3.5)), LINE)
    poly(img, R(guard), GOLD)
    poly(img, R([(cx - bw * 0.62, y_guard + 2), (cx + bw * 0.62, y_guard + 2),
                 (cx + bw * 0.62, y_guard + gh * fit * 0.5), (cx - bw * 0.62, y_guard + gh * fit * 0.5)]), GOLD_D)
    if wings:
        for sgn in (-1, 1):
            w1 = [(cx + sgn * bw * 0.62, y_guard - gh * fit * 0.5),
                  (cx + sgn * (bw * 0.62 + 9), y_guard - gh * fit * 0.5 - 9),
                  (cx + sgn * (bw * 0.62 + 9), y_guard + gh * fit * 0.2),
                  (cx + sgn * bw * 0.62, y_guard + gh * fit * 0.5)]
            poly(img, R(stroke(w1, 3.0)), LINE)
            poly(img, R(w1), GOLD_HI if sgn < 0 else GOLD)

    # ---- 握把 ----
    grip = [(cx - 11, y_grip0), (cx + 11, y_grip0), (cx + 11, y_grip1), (cx - 11, y_grip1)]
    poly(img, R(stroke(grip, 3.0)), LINE)
    poly(img, R(grip), GRIP)
    poly(img, R([(cx - 11, y_grip0), (cx - 4, y_grip0), (cx - 4, y_grip1), (cx - 11, y_grip1)]), GRIP_HI)
    poly(img, R([(cx + 4, y_grip0), (cx + 11, y_grip0), (cx + 11, y_grip1), (cx + 4, y_grip1)]), GRIP_D)
    for k in range(3):
        yy = y_grip0 + W(8 + k * 13)
        poly(img, R([(cx - 11, yy), (cx + 11, yy), (cx + 11, yy + 3), (cx - 11, yy + 3)]), GOLD_DD)

    # ---- 柄尾水晶（菱形）----
    dia = [(cx, y_pom - pom_d * fit / 2), (cx + 11, y_pom), (cx, y_pom + pom_d * fit / 2), (cx - 11, y_pom)]
    poly(img, R(stroke(dia, 3.0)), LINE)
    poly(img, R(dia), E_MID)
    poly(img, R([(cx, y_pom - pom_d * fit / 3), (cx + 6, y_pom), (cx, y_pom + pom_d * fit / 3), (cx - 6, y_pom)]), E_CORE)
    return img


def down(img):
    out = Image(64, 64)
    for y in range(64):
        for x in range(64):
            r = g = b = a = 0
            for j in range(SS):
                for i in range(SS):
                    c = img.get(x * SS + i, y * SS + j)
                    r += c[0]; g += c[1]; b += c[2]; a += c[3]
            k = SS * SS
            out.put(x, y, (r // k, g // k, b // k, a // k))
    return out


def slot(icon, bg=SLOT_BG, zoom=1):
    """把图标放到浅色格子里（模拟游戏里的物品格）+ 可选放大"""
    w = icon.w * zoom
    im = Image(w, w)
    for i in range(0, w * w * 4, 4):
        im.px[i:i + 3] = bytes(bg)
        im.px[i + 3] = 255
    if zoom == 1:
        blit(im, icon, 0, 0)
    else:
        for y in range(icon.h):
            for x in range(icon.w):
                c = icon.get(x, y)
                if c[3] == 0:
                    continue
                for j in range(zoom):
                    for i in range(zoom):
                        im.put(x * zoom + i, y * zoom + j, c)
    return im


CAND = [
    ("C1 竖直·能量通道", dict(tilt=0.0, bw=34.0, energy=True)),
    ("C2 竖直·宽刃重剑", dict(tilt=0.0, bw=42.0, energy=True)),
    ("C3 微倾15°", dict(tilt=15.0, bw=34.0, energy=True)),
    ("C4 微倾15°·宽刃", dict(tilt=15.0, bw=40.0, energy=True)),
    ("C5 竖直·无能量(纯金)", dict(tilt=0.0, bw=36.0, energy=False)),
]

rows = [("当前", [slot(read_png(os.path.join(OUT, "icon_musha_sword_64.png"))),
                  slot(read_png(os.path.join(OUT, "icon_musha_sword_64.png")), zoom=4)])]
for i, (label, kw) in enumerate(CAND, 1):
    icon = down(draw_icon(**kw))
    p = os.path.join(OUT, "icon_design_c%d.png" % i)
    write_png(p, icon)
    rows.append((label, [slot(icon), slot(icon, zoom=4)]))

sheet = os.path.join(OUT, "icon_design_sheet_20260916.png")
contact_sheet(rows, sheet, pad=10, bg=(70, 60, 50))
os.makedirs(DESKTOP, exist_ok=True)
desk = os.path.join(DESKTOP, "剑图标设计图_20260916.png")
with open(sheet, "rb") as f:
    data = f.read()
with open(desk, "wb") as f:
    f.write(data)
print("行序：第1行=现在用的图标，之后 C1竖直 / C2竖直宽刃 / C3微倾15 / C4微倾15宽刃 / C5纯金无能量")
print("单张 64x64：exported/musha_sword_v2/icon_design_c1..c5.png")
print("对照图（项目内）：%s" % sheet)
print("对照图（桌面）：%s" % desk)
