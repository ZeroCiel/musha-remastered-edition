# -*- coding: utf-8 -*-
"""J 扑克牌士兵（正面）—— 寻找爱丽丝！画风（Steam appid 1489410）
参考其扑克牌兵：白牌身+两颗叠红桃+牌顶红恶魔兜帽头+银三叉戟+小短腿。
J 版：兜帽上小金冠 + 牌角 J。Q 版软萌、细描边、赛璐璐软阴影。
拆件输出（可绑骨）：card / head / trident / arm_l / arm_r / leg_l / leg_r + preview_正面.png
"""
import math, random, os
from PIL import Image, ImageDraw, ImageFont

S = 4
W, H = 512 * S, 576 * S
CX = W // 2
OUTLINE = (74, 50, 66, 255)          # 软梅紫描边（比纯黑柔）
CARD = (249, 245, 234, 255)
CARD_SH = (233, 226, 209, 255)
HEART = (226, 84, 96, 255)
HEART_D = (185, 52, 64, 255)
HOOD = (217, 80, 94, 255)
HOOD_D = (176, 58, 72, 255)
FACE = (252, 246, 232, 255)
GOLD = (240, 196, 92, 255)
GOLD_D = (200, 152, 56, 255)
SILVER = (196, 205, 216, 255)
SILVER_D = (150, 160, 174, 255)
SHOE = (94, 70, 86, 255)
BLUSH = (246, 160, 160, 120)

random.seed(1489410)

def wob(pts, amp):
    return [(x + random.uniform(-amp, amp), y + random.uniform(-amp, amp)) for x, y in pts]

def stroke(d, pts, width, fill=None, close=True, color=OUTLINE):
    pts = wob(pts, width * 0.35)
    if fill:
        d.polygon(pts, fill=fill)
    if close:
        d.line(pts + [pts[0]], fill=color, width=width, joint="curve")
    else:
        d.line(pts, fill=color, width=width, joint="curve")

def rounded_rect_pts(x0, y0, x1, y1, r):
    pts = []
    def arc(cx, cy, a0, a1):
        n = max(4, int(abs(a1 - a0) / 12))
        for i in range(n + 1):
            a = math.radians(a0 + (a1 - a0) * i / n)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    arc(x1 - r, y0 + r, -90, 0); arc(x1 - r, y1 - r, 0, 90)
    arc(x0 + r, y1 - r, 90, 180); arc(x0 + r, y0 + r, 180, 270)
    return pts

def heart_pts(cx, cy, rx, ry, n=44):
    pts = []
    for i in range(n):
        a = 2 * math.pi * i / n
        x = rx * math.sin(a) ** 3
        y = -ry * (13 * math.cos(a) - 5 * math.cos(2 * a) - 2 * math.cos(3 * a) - math.cos(4 * a)) / 16
        pts.append((cx + x, cy + y))
    return pts

def tube(pts, w):
    """沿折线生成管状多边形（圆头略去，端点方形，接缝被牌/头遮住）"""
    out = []
    for i in range(len(pts) - 1):
        (ax, ay), (bx, by) = pts[i], pts[i + 1]
        nx, ny = -(by - ay), (bx - ax)
        L = math.hypot(nx, ny); nx, ny = nx / L * w, ny / L * w
        seg = [(ax + nx, ay + ny), (bx + nx, by + ny), (bx - nx, by - ny), (ax - nx, ay - ny)]
        out.append(seg)
    # 合并：简单串联（相邻段共享端点区域，描边覆盖接缝）
    allp = list(out[0])
    for seg in out[1:]:
        allp += seg[1:]
    return allp

layers = {}
def layer(name):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    layers[name] = im
    return im, ImageDraw.Draw(im)

OW = 14  # 描边宽（4x 空间 → 3.5px 成品）

# ============ 牌身（含两颗叠红桃 + J 角标） ============
card, dc = layer("card")
CW, CH = 430, 575
x0, y0, x1, y1 = CX - CW, 480, CX + CW, 480 + 2 * CH
pts = rounded_rect_pts(x0, y0, x1, y1, 88)
stroke(dc, pts, OW, fill=CARD)
# 软阴影：右缘+底缘内衬
dc.polygon(wob(rounded_rect_pts(x1 - 80, y0 + 70, x1 - 20, y1 - 50, 55), 4), fill=CARD_SH)
dc.polygon(wob(rounded_rect_pts(x0 + 36, y1 - 105, x1 - 34, y1 - 36, 55), 4), fill=CARD_SH)
# 两颗叠红桃（游戏兵同款：上大下小）
h1 = heart_pts(CX + 6, 980, 150, 138)
stroke(dc, h1, OW, fill=HEART)
h2 = heart_pts(CX - 40, 1290, 108, 98)
stroke(dc, h2, OW - 2, fill=HEART)
# J 角标（左上，小而雅）
try:
    fj = ImageFont.truetype(r"C:\Windows\Fonts\times.ttf", 120)
except OSError:
    fj = ImageFont.load_default()
dc.text((x0 + 46, y0 + 40), "J", font=fj, fill=HEART_D)
dc.polygon(wob(heart_pts(x0 + 150, y0 + 210, 44, 40), 2), fill=HEART_D)

# ============ 兜帽头（牌顶坐着）+ 小金冠 ============
head, dh = layer("head")
hx, hy = CX + 10, 400          # 头中心
hr = 205
head_shape = [(hx - hr, hy + 90), (hx - hr + 10, hy - 60), (hx - 120, hy - 175),
              (hx, hy - 205), (hx + 120, hy - 175), (hx + hr - 10, hy - 60), (hx + hr, hy + 90)]
stroke(dh, head_shape, OW, fill=HOOD)
# 兜帽两角（恶魔小耳）
for sgn in (-1, 1):
    ear = [(hx + sgn * (hr - 60), hy - 120), (hx + sgn * (hr + 20), hy - 260), (hx + sgn * (hr - 150), hy - 150)]
    stroke(dh, ear, OW - 2, fill=HOOD_D)
# 脸窗 + 大豆眼 + 小嘴 + 腮红
dh.polygon(wob(rounded_rect_pts(hx - 140, hy - 60, hx + 140, hy + 120, 70), 4), fill=FACE)
for ex in (hx - 62, hx + 62):
    dh.ellipse([ex - 30, hy - 20, ex + 30, hy + 66], fill=OUTLINE)
    dh.ellipse([ex - 14, hy - 6, ex + 2, hy + 18], fill=(255, 255, 255, 220))
dh.arc([hx - 34, hy + 34, hx + 34, hy + 78], 20, 160, fill=OUTLINE, width=9)
for bx in (hx - 118, hx + 88):
    dh.ellipse([bx, hy + 30, bx + 58, hy + 62], fill=BLUSH)
# 兜帽阴影（下缘）
dh.arc([hx - hr + 20, hy + 20, hx + hr - 20, hy + 190], 20, 160, fill=HOOD_D, width=22)
# 小金冠（坐兜帽顶，两角之间）
cpts = [(hx - 120, hy - 190), (hx - 120, hy - 268), (hx - 55, hy - 220), (hx, hy - 300),
        (hx + 55, hy - 220), (hx + 120, hy - 268), (hx + 120, hy - 190)]
stroke(dh, cpts + [(hx - 120, hy - 190)], OW - 2, fill=GOLD)

# ============ 三叉戟（右手持，银色；叉齿朝上） ============
tri, dt = layer("trident")
tx = CX + CW + 80                 # 杆在牌右缘外侧
ty = 800                          # 叉头横杆高度 ≈ 右手
shaft_top, shaft_bot = ty + 20, 1620
dt.rounded_rectangle([tx - 15, shaft_top, tx + 15, shaft_bot], radius=14, fill=SILVER, outline=OUTLINE, width=OW - 2)
# 横杆 + 三根朝上的叉齿（中齿最高，圆头）
dt.rounded_rectangle([tx - 150, ty - 10, tx + 150, ty + 26], radius=16, fill=SILVER, outline=OUTLINE, width=OW - 2)
for px, ph in ((tx - 132, 120), (tx, 210), (tx + 132, 120)):
    dt.rounded_rectangle([px - 13, ty - ph, px + 13, ty - 6], radius=12, fill=SILVER, outline=OUTLINE, width=OW - 2)
    dt.ellipse([px - 13, ty - ph - 22, px + 13, ty - ph + 2], fill=SILVER)
    dt.ellipse([px - 13, ty - ph - 22, px + 13, ty - ph + 2], outline=OUTLINE, width=OW - 2)
dt.ellipse([tx - 20, shaft_bot - 34, tx + 20, shaft_bot + 10], fill=GOLD_D)   # 柄尾

# 握持手套（画在戟杆之上）
hand, dhd = layer("hand")
dhd.ellipse([tx - 52, ty + 40, tx + 52, ty + 150], fill=FACE)
dhd.ellipse([tx - 52, ty + 40, tx + 52, ty + 150], outline=OUTLINE, width=OW - 2)

# ============ 手臂 ×2 + 腿 ×2 ============
def arm(side, hold=False):
    im, da = layer(f"arm_{side}")
    sgn = -1 if side == "l" else 1
    sx = CX + sgn * (CW - 30)
    if hold:
        pts = [(sx, 900), (sx + sgn * 120, 830), (tx - sgn * 26, 820)]
    else:
        pts = [(sx, 940), (sx + sgn * 150, 1040), (sx + sgn * 190, 1180)]
    stroke(da, tube(pts, 30), OW - 2, fill=CARD)
    if not hold:
        hx2, hy2 = pts[-1]
        da.ellipse([hx2 - 56, hy2 - 50, hx2 + 56, hy2 + 56], fill=FACE)
        da.ellipse([hx2 - 56, hy2 - 50, hx2 + 56, hy2 + 56], outline=OUTLINE, width=OW - 2)
    return im

def leg(side):
    im, dl = layer(f"leg_{side}")
    sgn = -1 if side == "l" else 1
    hx = CX + sgn * 140
    pts = [(hx, 1560), (hx + sgn * 30, 1760), (hx + sgn * 60, 1850)]
    stroke(dl, tube(pts, 34), OW - 2, fill=FACE)
    fx, fy = hx + sgn * 60, 1900
    dl.ellipse([fx - 74, fy - 36, fx + 74, fy + 46], fill=SHOE)
    dl.ellipse([fx - 74, fy - 36, fx + 74, fy + 46], outline=OUTLINE, width=OW - 2)
    return im

arm("l"); arm("r", hold=True); leg("l"); leg("r")

# ============ 合成（戟最后？戟在手前、手压杆） ============
order = ["arm_l", "leg_l", "leg_r", "arm_r", "card", "head", "trident", "hand"]
comp = Image.new("RGBA", (W, H), (0, 0, 0, 0))
for k in order:
    comp = Image.alpha_composite(comp, layers[k])

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "图片", "扑克牌士兵_J")
os.makedirs(OUT, exist_ok=True)
final = comp.resize((W // S, H // S), Image.LANCZOS)
final.save(os.path.join(OUT, "preview_正面.png"))

# 旧墨线版留档
old = os.path.join(OUT, "preview_正面.png")
for f in os.listdir(OUT):
    if f in ("card.png", "crown.png", "arm_l.png", "arm_r.png", "leg_l.png", "leg_r.png"):
        os.replace(os.path.join(OUT, f), os.path.join(OUT, "_旧墨线版_" + f))

for k in order:
    bb = layers[k].getbbox()
    if not bb:
        continue
    pad = 20
    box = (max(0, bb[0] - pad), max(0, bb[1] - pad), min(W, bb[2] + pad), min(H, bb[3] + pad))
    part = layers[k].crop(box).resize(((box[2] - box[0]) // S, (box[3] - box[1]) // S), Image.LANCZOS)
    part.save(os.path.join(OUT, f"{k}.png"))
    print(k, part.size)
print("preview OK", final.size)
