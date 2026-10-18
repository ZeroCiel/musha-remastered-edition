# -*- coding: utf-8 -*-
"""J 扑克牌士兵（正面）—— 饥荒墨线手绘风，按可绑骨的拆件输出
输出：图片/扑克牌士兵_J/  card/crown/arm_l/arm_r/leg_l/leg_r + preview_正面.png
画布 2048x2304（超采样 4x → 512x576），全部透明底，部件按绝对位置对齐可直接合成
"""
import math, random, os
from PIL import Image, ImageDraw, ImageFont

S = 4
W, H = 512 * S, 576 * S          # 2048 x 2304
CX = W // 2
INK = (40, 32, 26, 255)          # 暖黑墨线
CARD = (245, 238, 218, 255)      # 牌面米白
CARD_EDGE = (226, 214, 186, 255) # 牌缘阴影
RED = (181, 72, 77, 255)         # 红桃 muted
GOLD = (201, 161, 59, 255)       # 王冠 muted gold
GOLD_D = (166, 128, 40, 255)
GLOVE = (248, 244, 232, 255)

random.seed(20260928)            # 可复现的手绘抖动

def wob(pts, amp):
    """给折线点加确定性抖动 → 手绘墨线感"""
    out = []
    for i, (x, y) in enumerate(pts):
        out.append((x + random.uniform(-amp, amp), y + random.uniform(-amp, amp)))
    return out

def ink_stroke(d, pts, width, fill=None, close=True):
    """抖动多边形：可选填充 + 墨线描边"""
    pts = wob(pts, width * 0.55)
    if close:
        d.polygon(pts, fill=fill)
        d.line(pts + [pts[0]], fill=INK, width=width, joint="curve")
    else:
        d.line(pts, fill=INK, width=width, joint="curve")

def rounded_rect_pts(x0, y0, x1, y1, r, step=14):
    """圆角矩形轮廓点列"""
    pts = []
    def arc(cx, cy, a0, a1):
        n = max(4, int(abs(a1 - a0) / 12))
        for i in range(n + 1):
            a = math.radians(a0 + (a1 - a0) * i / n)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    arc(x1 - r, y0 + r, -90, 0)
    arc(x1 - r, y1 - r, 0, 90)
    arc(x0 + r, y1 - r, 90, 180)
    arc(x0 + r, y0 + r, 180, 270)
    return pts

def heart_pts(cx, cy, rx, ry, n=40):
    pts = []
    for i in range(n):
        a = 2 * math.pi * i / n
        x = rx * 16 * math.sin(a) ** 3 / 16
        y = -ry * (13 * math.cos(a) - 5 * math.cos(2 * a) - 2 * math.cos(3 * a) - math.cos(4 * a)) / 16
        pts.append((cx + x, cy + y))
    return pts

def rot_pts(pts, cx, cy, deg):
    a = math.radians(deg)
    ca, sa = math.cos(a), math.sin(a)
    return [(cx + (x - cx) * ca - (y - cy) * sa, cy + (x - cx) * sa + (y - cy) * ca) for x, y in pts]

layers = {}
def layer(name):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    layers[name] = im
    return im, ImageDraw.Draw(im)

# ============ 牌身（含脸 + 角标 J + 中央大桃心） ============
card, dc = layer("card")
CW, CH, CXc = 440, 660, CX          # 半宽/半高/中心
x0, y0, x1, y1 = CXc - CW, 320, CXc + CW, 320 + 2 * CH
pts = rot_pts(rounded_rect_pts(x0, y0, x1, y1, 70), CXc, (y0 + y1) / 2, 1.2)
ink_stroke(dc, pts, 22, fill=CARD)
# 牌缘阴影（右侧+底部内衬）
sh = rot_pts(rounded_rect_pts(x1 - 90, y0 + 60, x1 - 24, y1 - 40, 50), CXc, (y0 + y1) / 2, 1.2)
dc.polygon(wob(sh, 6), fill=CARD_EDGE)
sh2 = rot_pts(rounded_rect_pts(x0 + 40, y1 - 110, x1 - 40, y1 - 34, 50), CXc, (y0 + y1) / 2, 1.2)
dc.polygon(wob(sh2, 6), fill=CARD_EDGE)

# 脸（牌上半，饥荒式豆豆眼 + 小弧嘴）
for ex in (CXc - 78, CXc + 78):
    dc.ellipse([ex - 34, 700, ex + 34, 830], fill=INK)
    dc.ellipse([ex - 12, 716, ex + 6, 742], fill=(245, 240, 225, 255))  # 眼高光
smile = [(CXc - 92, 940 + 26 * math.sin(i / 8 * math.pi)) for i in range(9)]
dc.line(wob(smile, 3) + [(CXc + 92, 940)], fill=INK, width=14, joint="curve")

# 角标：J + 桃心（左上正、右下倒）
try:
    fj = ImageFont.truetype(r"C:\Windows\Fonts\times.ttf", 150)
except OSError:
    fj = ImageFont.load_default()
dc.text((x0 + 52, y0 + 60), "J", font=fj, fill=RED)
dc.polygon(wob(heart_pts(x0 + 116, y0 + 300, 62, 58), 4), fill=RED)
dc.polygon(wob(heart_pts(x1 - 116, y1 - 300, 62, 58), 4), fill=RED)

# 中央大桃心（描线装饰）
big = heart_pts(CXc + 14, 1300, 210, 196)
dc.polygon(wob(big, 7), outline=None)
dc.line(wob(big, 7) + [big[0]], fill=(181, 72, 77, 170), width=16, joint="curve")

# ============ 王冠（牌顶） ============
crown, dr = layer("crown")
cw = 380
cpts = [(CXc - cw, 380), (CXc - cw, 200), (CXc - cw / 2, 300), (CXc, 150),
        (CXc + cw / 2, 300), (CXc + cw, 200), (CXc + cw, 380)]
cpts = rot_pts(cpts, CXc, 300, -2)
ink_stroke(dr, cpts + [(cpts[0][0], 380)], 20, fill=GOLD)
dr.ellipse([CXc - 26, 300, CXc + 26, 352], fill=GOLD_D)      # 冠宝石
for sx in (CXc - cw, CXc, CXc + cw):
    dr.ellipse([sx - 16, 176, sx + 16, 208], fill=GOLD_D)    # 冠尖珠

# ============ 手臂 ×2（牌侧后方，白手套） ============
def arm(side):
    im, da = layer(f"arm_{side}")
    sgn = -1 if side == "l" else 1
    sx = CXc + sgn * (CW - 10)
    tube = [(sx, 900), (sx + sgn * 150, 980), (sx + sgn * 210, 1120)]
    pts = []
    for i in range(len(tube) - 1):
        (ax, ay), (bx, by) = tube[i], tube[i + 1]
        nx, ny = -(by - ay), (bx - ax)
        L = math.hypot(nx, ny); nx, ny = nx / L * 26, ny / L * 26
        pts += [(ax + nx, ay + ny), (bx + nx, by + ny)]
    pts += [(bx - nx, by - ny), (ax - nx, ay - ny)]
    ink_stroke(da, pts, 16, fill=CARD)
    hx, hy = sx + sgn * 250, 1180
    da.ellipse([hx - 66, hy - 58, hx + 66, hy + 66], fill=GLOVE)
    da.ellipse([hx - 66, hy - 58, hx + 66, hy + 66], outline=INK, width=16)
    return im

# ============ 腿 ×2（牌底后方，尖头鞋） ============
def leg(side):
    im, dl = layer(f"leg_{side}")
    sgn = -1 if side == "l" else 1
    hx = CXc + sgn * 150
    tube = [(hx, 1600), (hx + sgn * 20, 1900)]
    ax, ay = tube[0]; bx, by = tube[1]
    nx, ny = -(by - ay), (bx - ax); L = math.hypot(nx, ny); nx, ny = nx / L * 30, ny / L * 30
    pts = [(ax + nx, ay + ny), (bx + nx, by + ny), (bx - nx, by - ny), (ax - nx, ay - ny)]
    ink_stroke(dl, pts, 16, fill=CARD)
    fx, fy = bx + sgn * 70, 1960
    dl.ellipse([fx - 110, fy - 46, fx + 110, fy + 62], fill=INK)   # 墨色尖鞋
    return im

arm("l"); arm("r"); leg("l"); leg("r")

# ============ 合成（臂腿在牌后，王冠在牌上） ============
order = ["arm_l", "arm_r", "leg_l", "leg_r", "card", "crown"]
comp = Image.new("RGBA", (W, H), (0, 0, 0, 0))
for k in order:
    comp = Image.alpha_composite(comp, layers[k])

# ============ 输出（降采样 4x + 按包围盒裁件） ============
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "图片", "扑克牌士兵_J")
os.makedirs(OUT, exist_ok=True)
final = comp.resize((W // S, H // S), Image.LANCZOS)
final.save(os.path.join(OUT, "preview_正面.png"))

for k in order:
    bb = layers[k].getbbox()
    if not bb:
        continue
    pad = 24
    box = (max(0, bb[0] - pad), max(0, bb[1] - pad), min(W, bb[2] + pad), min(H, bb[3] + pad))
    part = layers[k].crop(box).resize(((box[2] - box[0]) // S, (box[3] - box[1]) // S), Image.LANCZOS)
    part.save(os.path.join(OUT, f"{k}.png"))
    print(k, part.size)

print("preview:", os.path.join(OUT, "preview_正面.png"), final.size)
