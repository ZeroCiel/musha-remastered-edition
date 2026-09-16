# -*- coding: utf-8 -*-
"""能量徽章（MP badge）概念图生成器 —— 2026-09-16

用途：出「能量 UI 换色 / 换外圈」对照图，给用户挑方向。
素材来源：exported/energy/ （原封不动读，不写回）

结构（按 z 从后到前）：
    bg2(奶油圆盘 60x60) → bg(暗橄榄圆盘 60x60) → health_level-*[23帧](液面 63x63)
    → heart-*[4帧](中心图标) → frame_circle(外环 75x78)
    液面帧号 = round((1-val)*22)  ← 原版 Badge:SetPercent(val) 内部就是 1-val
    两个圆盘在 scml 里 pivot 是负数(跑出画面)，这里按居中处理（可见效果就是"空槽底色"）
"""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import Image, blit, read_png, write_png, contact_sheet

B = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\exported\energy"
OUT_DIR = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\exported\energy\_concept"
DESKTOP = r"C:\Users\Administrator\Desktop"
CELL = 100          # 单元画布
ZOOM = 2            # 放大倍数
CX, CY = 50, 50     # 徽章中心

# ---------------- 素材装载 + 原色记录 ----------------
def avg(img):
    tot = [0, 0, 0]; n = 0
    px = img.px
    for i in range(0, len(px), 4):
        if px[i + 3] > 8:
            tot[0] += px[i]; tot[1] += px[i + 1]; tot[2] += px[i + 2]; n += 1
    n = max(n, 1)
    return (tot[0] // n, tot[1] // n, tot[2] // n)

SRC = {
    "disc2": "bg2/bg2-0.png",        # 奶油
    "disc":  "bg/bg-0.png",          # 暗橄榄
    "ring":  "frame_circle/frame_circle-0.png",
}
for i in range(23):
    SRC["liq%d" % i] = "health_level/health_level-%d.png" % i
for i in range(4):
    SRC["heart%d" % i] = "heart/heart-%d.png" % i

IMG = {k: read_png(os.path.join(B, v)) for k, v in SRC.items()}
BASE = {k: avg(IMG[k]) for k in ("disc", "disc2", "ring", "liq0", "liq11", "liq22", "heart0", "heart1", "heart2", "heart3")}

# scml 里的 pivot（液体/心的锚点必须照抄，否则液面不会"从下往上灌"）
PIV = {"liq": {}, "heart": {}}
import xml.etree.ElementTree as ET
for f in ET.parse(os.path.join(B, "energy.scml")).getroot().findall("folder"):
    for fl in f.findall("file"):
        n = fl.get("name"); px_ = float(fl.get("pivot_x")); py_ = float(fl.get("pivot_y"))
        W = int(fl.get("width")); H = int(fl.get("height"))
        if n.startswith("health_level/"):
            PIV["liq"][int(n.split("-")[1].split(".")[0])] = (px_, py_, W, H)
        elif n.startswith("heart/"):
            PIV["heart"][int(n.split("-")[1].split(".")[0])] = (px_, py_, W, H)

# ---------------- 染色 ----------------
def tint(img, target, base=None):
    """按通道比例把图染到 target（乘性，>1 会提亮，可用来把深底提亮成暖米）"""
    if target is None:
        return img
    if base is None:
        base = avg(img)
    k = [target[i] / max(base[i], 1) for i in range(3)]
    out = Image(img.w, img.h, bytearray(img.px))
    px = out.px
    for i in range(0, len(px), 4):
        if px[i + 3] == 0:
            continue
        for c in range(3):
            px[i + c] = min(255, int(px[i + c] * k[c]))
    return out

# ---------------- 基础绘图（超采样） ----------------
def paint(canvas, fn, color, ss=3, alpha=255):
    """fn(x,y)->bool 的填充；ss 超采样抗锯齿。color 不含 alpha"""
    xs = [p for p in range(canvas.w)]; ys = [p for p in range(canvas.h)]
    for y in ys:
        for x in xs:
            hits = 0
            for sy in range(ss):
                for sx in range(ss):
                    if fn(x + (sx + 0.5) / ss, y + (sy + 0.5) / ss):
                        hits += 1
            if hits == 0:
                continue
            a = int(alpha * hits / (ss * ss))
            i = (y * canvas.w + x) * 4
            ia = 255 - a
            for c in range(3):
                canvas.px[i + c] = (color[c] * a + canvas.px[i + c] * ia) // 255
            canvas.px[i + 3] = max(canvas.px[i + 3], a)

def ell_fn(cx, cy, rx, ry, rot=0.0):
    cr, sr = math.cos(-rot), math.sin(-rot)
    def fn(x, y):
        dx, dy = x - cx, y - cy
        u = dx * cr - dy * sr
        v = dx * sr + dy * cr
        return (u / rx) ** 2 + (v / ry) ** 2 <= 1.0
    return fn

def band_fn(cx, cy, r1, r2, wobble=0.0, waves=3, phase=0.0):
    """r1..r2 之间的环带；wobble 让半径随角度波动（藤蔓感）"""
    def fn(x, y):
        dx, dy = x - cx, y - cy
        d = math.hypot(dx, dy)
        r = (r1 + r2) / 2 + (wobble * math.sin(waves * math.atan2(dy, dx) + phase) if wobble else 0)
        return abs(d - r) <= (r2 - r1) / 2
    return fn

# ---------------- 藤蔓环（概念草稿，75x78 同尺寸） ----------------
VINE = dict(stem=(96, 132, 74), stem_hi=(146, 184, 108), leaf=(112, 164, 86),
            leaf_hi=(164, 206, 122), berry=(206, 96, 88), berry_hi=(240, 170, 160),
            dry_stem=(104, 92, 70), dry_leaf=(140, 126, 96), dry_hi=(176, 162, 128))
OUTLINE = (58, 42, 30)

def draw_vine_ring(canvas, cx, cy, R=33.0, dry=False):
    c = VINE
    stem = c["dry_stem"] if dry else c["stem"]
    stem_hi = c["dry_hi"] if dry else c["stem_hi"]
    leaf = c["dry_leaf"] if dry else c["leaf"]
    leaf_hi = c["dry_hi"] if dry else c["leaf_hi"]
    # 外描边（深棕，一圈稍宽的暗带）
    paint(canvas, band_fn(cx, cy, R - 2.6, R + 3.0, 2.2, 3, 0.0), OUTLINE, ss=3)
    # 藤蔓主体
    paint(canvas, band_fn(cx, cy, R - 1.6, R + 2.0, 2.2, 3, 0.0), stem, ss=3)
    # 内侧高光（细）
    paint(canvas, band_fn(cx, cy, R - 2.2, R - 0.9, 2.2, 3, 0.0), stem_hi, ss=3, alpha=190)
    # 叶子：每 45° 一片，内外交替，叶尖朝切向
    for i in range(8):
        a = math.radians(45 * i + 22.5)
        out = (i % 2 == 0)
        rr = R + (6.0 if out else -6.0)
        lx, ly = cx + rr * math.cos(a), cy - rr * math.sin(a)
        tang = a + math.pi / 2
        if not out:
            tang += math.pi
        rr2 = 8.2 if out else 7.2
        paint(canvas, ell_fn(lx, ly, rr2, 3.4, tang), OUTLINE, ss=3)
        paint(canvas, ell_fn(lx, ly, rr2 - 1.1, 2.4, tang), leaf, ss=3)
        paint(canvas, ell_fn(lx, ly, rr2 - 2.6, 0.9, tang), leaf_hi, ss=3, alpha=200)
    if not dry:
        # 三颗小果（挂在藤上）
        for i, deg in enumerate((70, 190, 310)):
            a = math.radians(deg)
            bx, by = cx + (R + 3.4) * math.cos(a), cy - (R + 3.4) * math.sin(a)
            paint(canvas, ell_fn(bx, by, 3.4, 3.4), OUTLINE, ss=3)
            paint(canvas, ell_fn(bx, by, 2.4, 2.4), c["berry"], ss=3)
            paint(canvas, ell_fn(bx - 0.8, by - 0.8, 1.0, 1.0), c["berry_hi"], ss=3)

# ---------------- 徽章合成 ----------------
def compose(val, liq_tint=None, heart_tint=None, disc_tint=None, disc2_tint=None,
            ring="orig", vine_dry=False):
    cv = Image(CELL, CELL)
    # 圆盘底（居中；scml 里那对负 pivot 就按居中处理）
    d2 = tint(IMG["disc2"], disc2_tint)
    blit(cv, d2, int(CX - d2.w / 2), int(CY - d2.h / 2))
    d1 = tint(IMG["disc"], disc_tint)
    blit(cv, d1, int(CX - d1.w / 2), int(CY - d1.h / 2))
    # 液面
    idx = int(round((1.0 - val) * 22))
    img = IMG["liq%d" % idx]
    px_, py_, W, H = PIV["liq"][idx]
    left = CX - px_ * W
    top = CY - (H - py_ * H)
    blit(cv, tint(img, liq_tint), int(round(left)), int(round(top)))
    # 中心图标（4 档跟随能量）
    hi = min(3, int(val * 4))
    h = IMG["heart%d" % hi]
    hpx, hpy, HW, HH = PIV["heart"][hi]
    blit(cv, tint(h, heart_tint), int(round(CX - hpx * HW)), int(round(CY - (HH - hpy * HH))))
    # 外环
    if ring == "orig":
        r = IMG["ring"]
        blit(cv, r, int(round(CX - 0.5 * r.w)), int(round(CY - (r.h - 0.514 * r.h))))
    else:
        draw_vine_ring(cv, CX, CY, 33.0, dry=vine_dry)
    return cv

def zoom(img, z):
    out = Image(img.w * z, img.h * z)
    for y in range(img.h):
        for x in range(img.w):
            i = (y * img.w + x) * 4
            c = img.px[i:i + 4]
            for dy in range(z):
                for dx in range(z):
                    j = ((y * z + dy) * out.w + (x * z + dx)) * 4
                    out.px[j:j + 4] = c
    return out

# ---------------- 配色方案 ----------------
P_CN = {  # 暖米 + 青（跟书页面板同族）
    "liq": (118, 198, 212), "heart": (236, 178, 96), "disc": (206, 188, 158), "disc2": (226, 212, 186),
}
P_PUR = {
    "liq": (178, 148, 236), "heart": (246, 222, 142), "disc": (58, 50, 74), "disc2": (74, 64, 92),
}
P_GOLD = {
    "liq": (250, 212, 116), "heart": (255, 244, 214), "disc": (94, 74, 44), "disc2": (116, 94, 58),
}

def row_of(palette, ring="orig", dry=False):
    return [zoom(compose(v, palette.get("liq"), palette.get("heart"), palette.get("disc"),
                         palette.get("disc2"), ring=ring, vine_dry=dry), ZOOM)
            for v in (1.0, 0.75, 0.5, 0.25, 0.0)]

rows = [
    ("现状", row_of({}, "orig")),
    ("暖米青", row_of(P_CN, "orig")),
    ("紫气", row_of(P_PUR, "orig")[:3] + row_of(P_GOLD, "orig")[3:]),
    ("藤蔓环", [zoom(compose(v, P_CN.get("liq"), P_CN.get("heart"), P_CN.get("disc"), P_CN.get("disc2"), ring="vine"), ZOOM)
                for v in (1.0, 0.5)] +
               [zoom(compose(0.2, (128, 130, 132), (168, 160, 150), (120, 112, 100), (140, 132, 118), ring="vine", vine_dry=True), ZOOM),
                zoom(compose(0.0, None, None, P_CN.get("disc"), P_CN.get("disc2"), ring="vine", vine_dry=True), ZOOM)]),
]

os.makedirs(OUT_DIR, exist_ok=True)
p1 = os.path.join(OUT_DIR, "energy_concept_20260916.png")
W, H = contact_sheet(rows, p1, pad=10, bg=(58, 58, 66))
p2 = os.path.join(DESKTOP, "能量UI方案_20260916.png")
W2, H2 = contact_sheet(rows, p2, pad=10, bg=(58, 58, 66))
print("写出:", p1, W, "x", H)
print("桌面:", p2)
print("行序: 1=现状  2=暖米青  3=紫气/金  4=藤蔓环(满/半/枯萎/空)")
# ASCII 自查：藤蔓环单张
v = compose(1.0, P_CN["liq"], P_CN["heart"], P_CN["disc"], P_CN["disc2"], ring="vine")
for y in range(4, 96, 3):
    s = ""
    for x in range(4, 96, 2):
        i = (y * v.w + x) * 4
        r_, g_, b_, a_ = v.px[i], v.px[i + 1], v.px[i + 2], v.px[i + 3]
        if a_ < 40: s += " "
        elif g_ > r_ + 18 and g_ > b_ + 18: s += "G"
        elif r_ > 180 and g_ > 150: s += "o"
        else:
            s += "#" if (r_ * 3 + g_ * 6 + b_) / 10 < 90 else "+"
    print(s)
