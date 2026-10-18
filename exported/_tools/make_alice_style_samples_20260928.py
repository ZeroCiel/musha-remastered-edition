# -*- coding: utf-8 -*-
"""爱丽丝计划 · 画风样张四张（寻找爱丽丝风格：Q版软萌/细梅紫描边/赛璐璐/腮红/星屑）
输出：图片/爱丽丝_画样/  4 张单图 + 1 张拼版
"""
import math, random, os
from PIL import Image, ImageDraw, ImageFont

S = 4
N = 384 * S
OUTLINE = (74, 50, 66, 255)
random.seed(52210)

def wob(pts, amp):
    return [(x + random.uniform(-amp, amp), y + random.uniform(-amp, amp)) for x, y in pts]

def stroke(d, pts, width, fill=None, close=True, amp=None, color=OUTLINE):
    pts = wob(pts, amp if amp is not None else width * 0.3)
    if fill:
        d.polygon(pts, fill=fill)
    d.line(pts + [pts[0]], fill=color, width=width, joint="curve") if close else d.line(pts, fill=color, width=width, joint="curve")

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
        pts.append((cx + rx * math.sin(a) ** 3,
                    cy - ry * (13 * math.cos(a) - 5 * math.cos(2 * a) - 2 * math.cos(3 * a) - math.cos(4 * a)) / 16))
    return pts

def star(d, cx, cy, r, color):
    pts = []
    for i in range(8):
        a = math.pi / 4 * i - math.pi / 2
        rr = r if i % 2 == 0 else r * 0.38
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    d.polygon(pts, fill=color)

def new_canvas():
    im = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)

def finish(im, name):
    out = im.resize((384, 384), Image.LANCZOS)
    OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "图片", "爱丽丝_画样")
    os.makedirs(OUT, exist_ok=True)
    out.save(os.path.join(OUT, name + ".png"))
    return out

# ══════════ ① 柴郡猫（大头 Q 版：脸内巨笑） ══════════
im, d = new_canvas()
BODY = (181, 138, 214, 255); BODY_D = (143, 107, 176, 255)
cx, cy = N // 2, 620
# 卷尾
tail = [(cx + 150, cy + 260), (cx + 290, cy + 240), (cx + 330, cy + 110), (cx + 240, cy + 40), (cx + 170, cy + 100), (cx + 210, cy + 180)]
d.line(wob(tail, 4), fill=BODY_D, width=32, joint="curve")
d.line(wob(tail, 3), fill=BODY, width=16, joint="curve")
for tx, ty in ((315, 205), (330, 120), (255, 55)):
    d.line(wob([(cx + tx - 15, cy + ty - 6), (cx + tx + 15, cy + ty + 10)], 2), fill=OUTLINE, width=11)
# 小身子（坐姿椭圆）
d.polygon(wob([(cx - 130, cy + 180), (cx - 160, cy + 300), (cx - 60, cy + 380), (cx + 60, cy + 380), (cx + 160, cy + 300), (cx + 130, cy + 180)], 4), fill=BODY_D)
stroke(d, rounded_rect_pts(cx - 130, cy + 170, cx + 130, cy + 385, 70), 14, fill=BODY)
# 大头（占一半）
head = [(cx - 250, cy + 20), (cx - 262, cy - 170), (cx - 130, cy - 290), (cx, cy - 330), (cx + 130, cy - 290), (cx + 262, cy - 170), (cx + 250, cy + 20), (cx + 130, cy + 130), (cx - 130, cy + 130)]
stroke(d, head + [head[0]], 16, fill=BODY)
# 耳朵
for sgn in (-1, 1):
    ear = [(cx + sgn * 150, cy - 265), (cx + sgn * 215, cy - 400), (cx + sgn * 255, cy - 240)]
    stroke(d, ear + [ear[0]], 14, fill=BODY)
    d.polygon(wob([(cx + sgn * 180, cy - 320), (cx + sgn * 212, cy - 380), (cx + sgn * 240, cy - 275)], 3), fill=(240, 170, 190, 255))
# 头条纹
for dx in (-150, -40, 70, 175):
    d.polygon(wob([(cx + dx, cy - 322), (cx + dx + 55, cy - 322), (cx + dx + 40, cy - 255), (cx + dx - 12, cy - 255)], 3), fill=BODY_D)
# 大眼
for sgn in (-1, 1):
    ex = cx + sgn * 118
    d.polygon(wob([(ex - 66, cy - 168), (ex + 66, cy - 168), (ex + 50, cy - 90), (ex - 50, cy - 90)], 3), fill=(255, 255, 255, 255))
    d.ellipse([ex - 30, cy - 156, ex + 30, cy - 90], fill=OUTLINE)
    d.ellipse([ex - 14, cy - 144, ex + 4, cy - 122], fill=(255, 255, 255, 220))
# 巨笑（脸内：宽月牙白牙 + 中缝）
grin = [(cx + math.cos(math.pi * i / 16) * 185, cy + 30 + math.sin(math.pi * i / 16) * 66) for i in range(17)]
grin_low = [(x, y + 40) for x, y in grin]
stroke(d, grin + list(reversed(grin_low)), 13, fill=(255, 252, 240, 255))
d.line([(cx - 172, cy + 40), (cx + 172, cy + 40)], fill=OUTLINE, width=9)
# 腮红 + 胡须
d.ellipse([cx - 235, cy - 20, cx - 155, cy + 30], fill=(240, 170, 190, 160))
d.ellipse([cx + 155, cy - 20, cx + 235, cy + 30], fill=(240, 170, 190, 160))
for sgn in (-1, 1):
    for dy in (-8, 22):
        d.line([(cx + sgn * 225, cy + 5 + dy), (cx + sgn * 345, cy - 10 + dy)], fill=OUTLINE, width=7)
# 星屑
for sx, sy, r in ((80, 150, 16), (330, 90, 12), (330, 480, 18), (60, 470, 12), (150, 40, 10)):
    star(d, sx, sy, r, (255, 240, 200, 220))
cheshire = finish(im, "① 柴郡猫")

# ══════════ ② 茶杯猫 ══════════
im, d = new_canvas()
CREAM = (247, 234, 217, 255); ORANGE = (235, 170, 110, 255); PINKC = (244, 178, 196, 255)
cx, cy = N // 2, N // 2 + 20
# 蒸汽
for sx in (-60, 0, 60):
    steam = [(cx + sx, cy - 250 + 0), (cx + sx - 26, cy - 300), (cx + sx + 26, cy - 350), (cx + sx, cy - 400)]
    d.line(wob(steam, 4), fill=(255, 255, 255, 150), width=12, joint="curve")
# 猫头（杯里探出）
head = [(cx - 175, cy - 60), (cx - 195, cy - 210), (cx - 90, cy - 300), (cx + 90, cy - 300), (cx + 195, cy - 210), (cx + 175, cy - 60)]
stroke(d, head + [head[0]], 16, fill=CREAM)
for sgn in (-1, 1):
    ear = [(cx + sgn * 110, cy - 285), (cx + sgn * 150, cy - 380), (cx + sgn * 190, cy - 275)]
    stroke(d, ear + [ear[0]], 13, fill=CREAM)
    d.polygon(wob([(cx + sgn * 128, cy - 300), (cx + sgn * 150, cy - 350), (cx + sgn * 170, cy - 295)], 3), fill=(246, 170, 180, 255))
d.polygon(wob([(cx - 40, cy - 300), (cx + 60, cy - 290), (cx + 20, cy - 210)], 3), fill=ORANGE)  # 橘斑
# 眯眯眼（开心 ^^）+ 腮红 + 小鼻
for sgn in (-1, 1):
    ex = cx + sgn * 85
    d.arc([ex - 45, cy - 210, ex + 45, cy - 110], 200, 340, fill=OUTLINE, width=13)
d.polygon([(cx - 14, cy - 150), (cx + 14, cy - 150), (cx, cy - 124)], fill=(236, 130, 140, 255))
d.line([(cx, cy - 124), (cx, cy - 100)], fill=OUTLINE, width=8)
d.arc([cx - 46, cy - 120, cx + 46, cy - 40], 30, 150, fill=OUTLINE, width=10)
d.ellipse([cx - 150, cy - 150, cx - 84, cy - 96], fill=(246, 160, 160, 150))
d.ellipse([cx + 84, cy - 150, cx + 150, cy - 96], fill=(246, 160, 160, 150))
# 杯身
cup = [(cx - 220, cy - 40), (cx - 190, cy + 170), (cx + 190, cy + 170), (cx + 220, cy - 40)]
stroke(d, cup + [cup[0]], 16, fill=PINKC)
d.polygon(wob([(cx + 150, cy - 30), (cx + 180, cy - 20), (cx + 165, cy + 150), (cx + 120, cy + 150)], 4), fill=(232, 150, 172, 255))
# 杯耳
d.arc([cx + 210, cy - 20, cx + 330, cy + 120], 270, 90, fill=OUTLINE, width=18)
# 杯口沿 + 托盘 + 心心印花
stroke(d, [(cx - 235, cy - 45), (cx + 235, cy - 45)], 18, fill=(240, 200, 110, 255))
stroke(d, rounded_rect_pts(cx - 260, cy + 175, cx + 260, cy + 225, 24), 14, fill=(240, 200, 110, 255))
dc2 = heart_pts(cx - 60, cy + 70, 52, 48)
d.line(dc2 + [dc2[0]], fill=(231, 105, 125, 255), width=11, joint="curve")
# 爪爪搭杯沿
for sgn in (-1, 1):
    px = cx + sgn * 120
    d.ellipse([px - 46, cy - 92, px + 46, cy - 8], fill=CREAM)
    d.ellipse([px - 46, cy - 92, px + 46, cy - 8], outline=OUTLINE, width=13)
teacup = finish(im, "② 茶杯猫")

# ══════════ ③ Q 扑克牌士兵（黑桃 · 银冠 · 紫兜帽） ══════════
im, d = new_canvas()
CARD = (226, 221, 238, 255); CARD_SH = (205, 199, 222, 255)
SPADE = (58, 52, 78, 255); HOOD = (122, 96, 168, 255); HOOD_D = (96, 72, 138, 255)
SILVER = (208, 216, 228, 255)
cx, cy = N // 2, N // 2 + 30
card = rounded_rect_pts(cx - 200, cy - 130, cx + 200, cy + 290, 44)
stroke(d, card + [card[0]], 14, fill=CARD)
d.polygon(wob(rounded_rect_pts(cx + 130, cy - 100, cx + 185, cy + 250, 26), 3), fill=CARD_SH)
# 黑桃
spade = [(cx - 40, cy + 40), (cx - 90, cy - 60), (cx - 20, cy - 130), (cx + 40, cy - 145), (cx + 100, cy - 60), (cx + 50, cy + 40)]
spade = [(cx - 20 + (p[0] - cx), p[1]) for p in spade]
d.polygon(wob(spade, 4), fill=SPADE)
d.polygon(wob([(cx - 20, cy + 20), (cx + 34, cy + 120), (cx - 74, cy + 120)], 3), fill=SPADE)
# Q 角标
try:
    fq = ImageFont.truetype(r"C:\Windows\Fonts\times.ttf", 92)
except OSError:
    fq = ImageFont.load_default()
d.text((cx - 175, cy - 105), "Q", font=fq, fill=SPADE)
# 兜帽头（紫）
hx, hy = cx, cy - 210
hh = [(hx - 130, hy + 70), (hx - 138, hy - 50), (hx - 70, hy - 140), (hx, hy - 165), (hx + 70, hy - 140), (hx + 138, hy - 50), (hx + 130, hy + 70)]
stroke(d, hh + [hh[0]], 14, fill=HOOD)
for sgn in (-1, 1):
    stroke(d, [(hx + sgn * 100, hy - 100), (hx + sgn * 135, hy - 215), (hx + sgn * 40, hy - 130)] + [(hx + sgn * 100, hy - 100)], 12, fill=HOOD_D)
d.polygon(wob(rounded_rect_pts(hx - 92, hy - 45, hx + 92, hy + 82, 46), 3), fill=(250, 244, 230, 255))
for ex in (hx - 42, hx + 42):
    d.ellipse([ex - 20, hy - 12, ex + 20, hy + 34], fill=OUTLINE)
    d.ellipse([ex - 9, hy - 2, ex + 3, hy + 12], fill=(255, 255, 255, 220))
d.arc([hx - 24, hy + 26, hx + 24, hy + 62], 20, 160, fill=OUTLINE, width=8)
# 银冠
crown = [(hx - 78, hy - 150), (hx - 78, hy - 212), (hx - 36, hy - 178), (hx, hy - 240), (hx + 36, hy - 178), (hx + 78, hy - 212), (hx + 78, hy - 150)]
stroke(d, crown + [crown[0]], 12, fill=SILVER)
# 手臂 + 小腿
for sgn in (-1, 1):
    arm = [(cx + sgn * 185, cy - 20), (cx + sgn * 260, cy + 60), (cx + sgn * 275, cy + 130)]
    stroke(d, arm, 13, fill=CARD)
    d.ellipse([cx + sgn * 250 - 36, cy + 118, cx + sgn * 250 + 36, cy + 182], fill=(250, 244, 230, 255))
    d.ellipse([cx + sgn * 250 - 36, cy + 118, cx + sgn * 250 + 36, cy + 182], outline=OUTLINE, width=12)
for sgn in (-1, 1):
    stroke(d, [(cx + sgn * 95, cy + 275), (cx + sgn * 110, cy + 360)], 13, fill=CARD)
    d.ellipse([cx + sgn * 110 - 48, cy + 348, cx + sgn * 110 + 48, cy + 404], fill=SPADE)
    d.ellipse([cx + sgn * 110 - 48, cy + 348, cx + sgn * 110 + 48, cy + 404], outline=OUTLINE, width=11)
qsoldier = finish(im, "③ Q扑克牌士兵")

# ══════════ ④ “喝我”药水 ══════════
im, d = new_canvas()
GLASS = (222, 240, 248, 210); LIQ = (232, 130, 196, 235); LIQ_L = (250, 190, 232, 235)
cx, cy = N // 2, N // 2
# 挂绳标签（挂在瓶颈）
d.line(wob([(cx, cy - 200), (cx + 150, cy - 150), (cx + 175, cy - 60)], 3), fill=OUTLINE, width=7)
tag = rounded_rect_pts(cx + 185, cy - 70, cx + 365, cy + 40, 26)
stroke(d, tag + [tag[0]], 11, fill=(252, 246, 232, 255))
try:
    ft = ImageFont.truetype(r"C:\Windows\Fonts\msyh.ttc", 58)
except OSError:
    ft = ImageFont.load_default()
d.text((cx + 233, cy - 46), "喝我", font=ft, fill=(214, 90, 140, 255))
# 瓶身（圆润烧瓶）
body = [(cx - 60, cy - 210), (cx - 60, cy - 90), (cx - 205, cy + 10), (cx - 215, cy + 150),
        (cx - 120, cy + 260), (cx + 120, cy + 260), (cx + 215, cy + 150), (cx + 205, cy + 10), (cx + 60, cy - 90), (cx + 60, cy - 210)]
stroke(d, body + [body[0]], 14, fill=GLASS)
# 液体（2/3 高，波浪面）
liq = [(cx - 198, cy + 70), (cx - 208, cy + 155), (cx - 116, cy + 256), (cx + 116, cy + 256),
       (cx + 208, cy + 155), (cx + 198, cy + 70)]
wave = [(cx + 198 - i * (396 / 10), cy + 70 + (14 if i % 2 else -6)) for i in range(11)]
d.polygon(wob(liq + list(reversed(wave)), 4), fill=LIQ)
d.ellipse([cx - 120, cy + 40, cx + 120, cy + 105], fill=LIQ_L)
# 高光 + 气泡
d.line([(cx - 148, cy + 90), (cx - 172, cy + 190)], fill=(255, 255, 255, 200), width=16, joint="curve")
for bx, by, br in ((cx - 60, cy + 150, 13), (cx + 55, cy + 195, 9), (cx + 95, cy + 130, 7)):
    d.ellipse([bx - br, by - br, bx + br, by + br], outline=(255, 255, 255, 220), width=6)
# 瓶口 + 软木塞
stroke(d, rounded_rect_pts(cx - 58, cy - 300, cx + 58, cy - 200, 16), 12, fill=GLASS)
stroke(d, rounded_rect_pts(cx - 62, cy - 372, cx + 62, cy - 292, 18), 12, fill=(214, 168, 110, 255))
# 星屑
for sx, sy, r in ((90, 130, 15), (320, 110, 12), (330, 400, 17), (60, 420, 12)):
    star(d, sx, sy, r, (248, 178, 226, 220))
potion = finish(im, "④ 喝我药水")

# ══════════ 拼版 ══════════
PAD = 18
sheet = Image.new("RGBA", (384 * 2 + PAD * 3, 384 * 2 + PAD * 3), (30, 26, 36, 255))
for i, im2 in enumerate((cheshire, teacup, qsoldier, potion)):
    r, c = divmod(i, 2)
    sheet.alpha_composite(im2, (PAD + c * (384 + PAD), PAD + r * (384 + PAD)))
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "图片", "爱丽丝_画样")
sheet.save(os.path.join(OUT, "画样拼版.png"))
print("4 张样张 + 拼版完成 →", OUT)
