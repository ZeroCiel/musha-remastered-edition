"""musha 基础剑 → 重剑（按用户 2026-09-16 给的第 1 张参考图重画）。

参考图特征（靠像素统计 + 灰度图读出来的，不是猜）：
  · **单色灰钢**（主色 RGB(96~196) 全灰，唯一有色点缀是刀柄上一小块暗红 RGB(48,24,24)）
  · 宽厚刃身、**斜切刀尖**（刃尾是一整片斜的切面，不是对称尖）
  · 刃身有一条**倒角棱线**贯穿；刃根附近有**台阶状缺口**（工业感）
  · 刀柄极简：短缠柄 + **尾部一个圆环**（没有大十字护手、没有宝石）
  · 明暗对比强（亮面 ~196 / 暗面 ~90），不是平涂

工程约定（照"能在手里显示"的 swap_lifebranch）：
  · 画布方形、**pivot = 握把中心**（手抓这点、剑身朝上）
  · 实体尺寸对齐基准：树枝实体 346x326 → 剑定在 ≈390 高（重剑大一圈，但别离谱）
  · 2 倍超采样后缩小 = 抗锯齿；再用 shade_post 叠整体明暗渐变

产出（exported/musha_sword_v2/）：musha_sword.png / .scml / .zip / icon_musha_sword_64.png
预览：exported/_tools/_test_out/sword_preview.png

用法：python make_musha_sword.py
"""
import os, sys, math, zipfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import Image, write_png

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.normpath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(MOD, "exported", "musha_sword_v2")

SS = 2                     # 超采样倍数（抗锯齿）
CANVAS = 768 * SS          # 绘制画布（缩回 768 出图）
GRIP_Y = 470 * SS          # 握把中心 y（= pivot 所在）
ART_SCALE = 0.72           # 实际大小（0.72 → 剑身约 390px 高）
ROT_DEG = 0.0              # 整体旋转角：进游戏发现歪了/躺了，改这里重跑

# ── 参考图的单色灰钢配色（全部中性灰，仅一处暗红点缀）──
HI    = (206, 210, 218)
STEEL = (172, 177, 186)
MID   = (134, 139, 148)
SH    = (98, 103, 112)
DEEP  = (70, 74, 82)
WRAP  = (78, 74, 74)
WRAPS = (54, 52, 54)
ACC   = (124, 58, 54)      # 刀柄那点暗红
LINE  = (50, 52, 58)       # 描边（深板岩，不纯黑）

_cur = {"img": None}


def poly(pts, color, alpha=255):
    img = _cur["img"]
    if img is None or not pts:
        return
    W, H = img.w, img.h
    ys = [p[1] for p in pts]
    y0, y1 = int(math.floor(min(ys))), int(math.ceil(max(ys)))
    n = len(pts)
    for y in range(max(0, y0), min(H, y1 + 1)):
        yc = y + 0.5
        xs = []
        for i in range(n):
            x1, y1_ = pts[i]
            x2, y2_ = pts[(i + 1) % n]
            if (y1_ <= yc < y2_) or (y2_ <= yc < y1_):
                xs.append(x1 + (x2 - x1) * (yc - y1_) / float(y2_ - y1_))
        xs.sort()
        for k in range(0, len(xs) - 1, 2):
            for x in range(max(0, int(math.floor(xs[k]))), min(W, int(math.ceil(xs[k + 1])))):
                i = (y * W + x) * 4
                img.px[i:i + 4] = bytes((color[0], color[1], color[2], alpha))


def ell(cx, cy, rx, ry, color, seg=48):
    poly([(cx + rx * math.cos(2 * math.pi * k / seg), cy + ry * math.sin(2 * math.pi * k / seg)) for k in range(seg)], color)


def ring(cx, cy, r_out, r_in, color, seg=48):
    """圆环：外圈正向 + 内圈反向 → even-odd 扫描线自然挖空"""
    pts = [(cx + r_out * math.cos(2 * math.pi * k / seg), cy + r_out * math.sin(2 * math.pi * k / seg)) for k in range(seg)]
    pts += [(cx + r_in * math.cos(-2 * math.pi * k / seg), cy + r_in * math.sin(-2 * math.pi * k / seg)) for k in range(seg)]
    poly(pts, color)


def draw_sword(img, ox, oy, s, rot=0.0):
    _cur["img"] = img
    th = math.radians(rot)
    c, sn = math.cos(th), math.sin(th)

    def P(pts):
        return [(ox + (x * c - y * sn) * s, oy + (x * sn + y * c) * s) for (x, y) in pts]

    BW, BWt = 56, 48          # 刃半宽（根部 / 近尖）
    L0, L1 = -74, -392        # 刃身：根 → 左刃口末端
    R1 = -350                 # 右刃口末端（比左边短 → 形成斜切刀尖）

    # ① 刃身（含右刃一道台阶缺口 + 斜切刀尖）
    blade = [(-BW, L0), (-BWt, L1), (BWt, R1),
             (52, -186), (36, -186), (36, -156), (54, -156), (BW, L0)]
    poly(P(blade), MID)
    # 左刃口亮带（参考图里刃口是一条明显的亮边）
    poly(P([(-BW, L0), (-BWt, L1), (-BWt + 12, L1 - 4), (-BW + 12, L0)]), HI)
    poly(P([(-BW + 12, L0), (-BWt + 12, L1 - 4), (-BWt + 22, L1 - 8), (-BW + 22, L0)]), STEEL)
    # 倒角棱线（贯穿刃身的那条线）
    poly(P([(-24, L0 - 6), (-18, L1 + 26), (-12, L1 + 26), (-18, L0 - 6)]), SH)
    poly(P([(-18, L0 - 6), (-12, L1 + 26), (-6, L1 + 26), (-12, L0 - 6)]), DEEP)
    # 右背暗面 + 刃尖切面（切面偏亮，参考图里刃尾那片是亮点）
    poly(P([(30, L0), (30, R1 + 10), (BWt, R1 + 6), (BW, L0)]), SH)
    # 斜切刀尖的切面（在刃内部、贴着斜端面的一条亮带）
    poly(P([(-BWt, L1), (BWt, R1), (BWt - 15, R1 + 13), (-BWt + 15, L1 + 13)]), HI)
    # 刃根台阶（金饰位置在参考图里是钢本色，做成一道横向加强条）
    poly(P([(-BW, L0), (BW, L0), (BW, L0 - 12), (-BW, L0 - 12)]), DEEP)
    poly(P([(-BW + 4, L0 - 12), (BW - 4, L0 - 12), (BW - 4, L0 - 18), (-BW + 4, L0 - 18)]), STEEL)

    # ② 护手：极简钢领（参考图没有大十字护手，只有一道加宽）
    guard = [(-58, -30), (58, -30), (48, -68), (-48, -68)]
    poly(P(guard), STEEL)
    poly(P([(-58, -30), (58, -30), (58, -40), (-58, -40)]), DEEP)
    poly(P([(-58, -40), (58, -40), (52, -50), (-52, -50)]), MID)
    poly(P([(-64, -34), (-52, -34), (-50, -22), (-62, -22)]), SH)
    poly(P([(64, -34), (52, -34), (50, -22), (62, -22)]), SH)

    # ③ 柄：短缠柄（深灰） + 一小段暗红缠绳
    poly(P([(-15, -46), (15, -46), (15, 52), (-15, 52)]), WRAP)
    poly(P([(6, -46), (15, -46), (15, 52), (6, 52)]), WRAPS)
    for k in range(6):
        yy = -40 + k * 15
        poly(P([(-15, yy), (15, yy + 5), (15, yy + 9), (-15, yy + 4)]), WRAPS)
    poly(P([(-15, 6), (15, 6), (15, 16), (-15, 16)]), ACC)      # 暗红缠绳（参考图唯一彩色处）
    poly(P([(-15, 20), (15, 20), (15, 30), (-15, 30)]), ACC)

    # ④ 柄尾圆环（参考图的标志性细节）
    ring(ox, oy + 92 * s, 34 * s, 17 * s, STEEL)
    ring(ox, oy + 92 * s, 34 * s, 17 * s, HI)
    ring(ox, oy + 92 * s, 32 * s, 19 * s, MID)
    ell(ox, oy + 118 * s, 8 * s, 8 * s, ACC)                    # 环上一个暗红小点
    _cur["img"] = None


def shade_post(img, ox, oy, top_y, bot_y, half_w):
    """整体明暗渐变（去平涂）：刃尖亮 → 柄沉；右侧背光衰减"""
    w, h, px = img.w, img.h, img.px
    span = float(bot_y - top_y) if bot_y != top_y else 1.0
    for y in range(h):
        t = (y - top_y) / span
        t = 0.0 if t < 0 else (1.0 if t > 1 else t)
        fv = 1.06 - 0.18 * t
        for x in range(w):
            i = (y * w + x) * 4
            if px[i + 3] == 0:
                continue
            dx = (x - ox) / float(half_w)
            f = fv * (1.0 - 0.07 * dx if dx > 0 else 1.0 - 0.02 * (-dx))
            for c in range(3):
                v = int(round(px[i + c] * f))
                px[i + c] = 255 if v > 255 else (0 if v < 0 else v)


def _outline_once(img, color):
    w, h, px = img.w, img.h, img.px
    snap = [(px[(y * w + x) * 4 + 3] > 0) for y in range(h) for x in range(w)]
    for y in range(h):
        for x in range(w):
            if snap[y * w + x]:
                continue
            hit = False
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    X, Y = x + dx, y + dy
                    if 0 <= X < w and 0 <= Y < h and snap[Y * w + X]:
                        hit = True; break
                if hit:
                    break
            if hit:
                i = (y * w + x) * 4
                px[i:i + 4] = bytes((color[0], color[1], color[2], 255))


def outline(img, color=LINE, passes=2):
    for _ in range(passes):
        _outline_once(img, color)


def downsample(im, f):
    w2, h2 = im.w // f, im.h // f
    out = Image(w2, h2)
    for y in range(h2):
        for x in range(w2):
            r = g = b = a = 0
            for dy in range(f):
                for dx in range(f):
                    i = ((y * f + dy) * im.w + (x * f + dx)) * 4
                    r += im.px[i]; g += im.px[i + 1]; b += im.px[i + 2]; a += im.px[i + 3]
            n = f * f
            j = (y * w2 + x) * 4
            out.px[j:j + 4] = bytes((r // n, g // n, b // n, a // n))
    return out


def render():
    img = Image(CANVAS, CANVAS)
    draw_sword(img, CANVAS / 2, GRIP_Y, SS * ART_SCALE, rot=ROT_DEG)
    shade_post(img, CANVAS / 2, GRIP_Y,
               GRIP_Y - 430 * SS * ART_SCALE, GRIP_Y + 130 * SS * ART_SCALE, 90 * SS)
    outline(img, LINE, passes=2)
    return downsample(img, SS)


os.makedirs(OUT, exist_ok=True)
main_img = render()
png = os.path.join(OUT, "musha_sword.png")
write_png(png, main_img)
pivot_y = GRIP_Y / float(CANVAS)

SCML = '''<?xml version="1.0" encoding="UTF-8"?>
<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="r11">
 <folder id="0" name="musha_sword">
  <file id="0" name="musha_sword.png" width="{w}" height="{h}" pivot_x="0.5" pivot_y="{py:.6f}" />
 </folder>
 <entity id="0" name="musha_sword">
  <animation id="0" name="idle" length="1000" interval="100">
   <mainline>
    <key id="0" time="0">
     <object_ref id="0" timeline="0" key="0" z_index="0" name="musha_sword" />
    </key>
   </mainline>
   <timeline id="0" name="musha_sword">
    <key id="0" time="0" spin="0">
     <object folder="0" file="0" scale_x="1" scale_y="1" />
    </key>
   </timeline>
  </animation>
 </entity>
</spriter_data>
'''.format(w=main_img.w, h=main_img.h, py=pivot_y)
open(os.path.join(OUT, "musha_sword.scml"), "w", encoding="utf-8").write(SCML)
BUILD = '<Build name="musha_sword.scml">\n <Symbol name="symbol0">\n  <Frame framenum="0" duration="1" image="musha_sword" w="%d" h="%d" x="0.000000" y="0.000000"/>\n </Symbol>\n</Build>\n' % (main_img.w, main_img.h)
ANIM = '<Anims>\n <anim name="idle" root="musha_sword" numframes="1000" framerate="40">\n  <frame idx="0" w="%d" h="%d" x="0.000000" y="0.000000">\n   <element name="symbol0" layername="musha_sword" frame="0" z_index="1" m_a="1.000000" m_b="0.000000" m_c="0.000000" m_d="1.000000" m_tx="0.000000" m_ty="0.000000"/>\n  </frame>\n </anim>\n</Anims>\n' % (main_img.w, main_img.h)
with zipfile.ZipFile(os.path.join(OUT, "musha_sword.zip"), "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("build.xml", BUILD)
    z.writestr("animation.xml", ANIM)
    z.write(png, "musha_sword.png")

# 背包图标（斜 45°，超采样后缩）
big = Image(256, 256)
draw_sword(big, 140, 148, 0.30, rot=-42)
outline(big, LINE, passes=1)
write_png(os.path.join(OUT, "icon_musha_sword_64.png"), downsample(big, 4))

# 预览（1 倍 + 对照参考图的灰度缩略）
pv = Image(main_img.w + 24, main_img.h)
for y in range(pv.h):
    for x in range(pv.w):
        v = 92 if ((x // 14) + (y // 14)) % 2 == 0 else 126
        i = (y * pv.w + x) * 4
        pv.px[i:i + 4] = bytes((v, v, v + 5, 255))
for y in range(main_img.h):
    for x in range(main_img.w):
        i = (y * main_img.w + x) * 4
        if main_img.px[i + 3] == 0:
            continue
        j = (y * pv.w + x + 12) * 4
        for c in range(3):
            pv.px[j + c] = main_img.px[i + c]
        pv.px[j + 3] = 255
pvpath = os.path.join(HERE, "_test_out", "sword_preview.png")
write_png(pvpath, pv)

# 尺寸自检
xs = []; ys = []
for y in range(main_img.h):
    for x in range(main_img.w):
        if main_img.px[(y * main_img.w + x) * 4 + 3] > 40:
            xs.append(x); ys.append(y)
soft = sum(1 for i in range(3, len(main_img.px), 4) if 0 < main_img.px[i] < 255)
print("剑身：%s (%dx%d)" % (png, main_img.w, main_img.h))
print("实体范围：%dx%d 宽高（基准树枝 346x326）  抗锯齿边缘像素=%d" % (
    max(xs) - min(xs) + 1, max(ys) - min(ys) + 1, soft))
print("pivot_y = %.6f（握把中心）  预览：%s" % (pivot_y, pvpath))
