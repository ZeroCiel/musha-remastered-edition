"""musha 基础剑 → 重剑 v2（去卡通化：抗锯齿 + 多档金属明暗 + 细长比例）。

上一版被吐槽"太卡通"，原因三条（这次逐条解决）：
  ① 平涂 + 硬黑描边 → 像塑料玩具：本版 2 倍超采样后缩小（边缘抗锯齿），描边改用深板岩色(48,52,62)而非纯黑
  ② 颜色只有 3 档、没有金属过渡 → 本版每段刃面拆成 5 条纵向明暗带（刃口亮/倒角/中脊高光/中段/背暗）
  ③ 比例太胖太短 → 本版刃长/刃宽 ≈ 3.2，护手收窄、宝石收小、柄加长

产出（exported/musha_sword_v2/）：
  musha_sword.png / musha_sword.scml / musha_sword.zip   ← 定稿用的那一版（默认 B 厚重重剑）
  icon_musha_sword_64.png                                 ← 64x64 背包图标（斜 45°）
  _tools/_test_out/sword_preview.png                      ← 三版对照（A 细长优雅 / B 厚重重剑 / C 冷钢发光）

用法：python make_musha_sword.py
"""
import os, sys, math, zipfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import Image, write_png

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.normpath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(MOD, "exported", "musha_sword_v2")
SS = 2                     # 超采样倍数（抗锯齿）
CANVAS = 768 * SS          # 绘制画布（缩回 768 出图；刃加长后 512 装不下）
GRIP_Y = 470 * SS          # 握把中心 y
LINE = (48, 52, 62)        # 描边：深板岩（比纯黑柔和）
ART_SCALE = 0.76           # 剑在图里的实际大小（基准：能正常显示的树枝实体 326px 高；0.76 → 约 395px）
ROT_DEG = 0.0              # 整体旋转角：进游戏若发现"歪了/躺了"，改这个数（如 -35）重跑即可

STYLES = {
    # 布色：刃口亮 / 倒角 / 中脊 / 中段 / 背暗     护手三档             柄            宝石
    "A": dict(name="细长优雅",
              blade=(214, 220, 228), cham=(178, 186, 199), ridge=(228, 234, 242), mid=(148, 156, 170), back=(112, 120, 136),
              gold=(178, 152, 96), gold_hi=(206, 184, 132), gold_sh=(128, 104, 60),
              grip=(74, 62, 58), grip_sh=(48, 38, 36),
              gem=(148, 62, 68), gem_hi=(196, 140, 144),
              blade_len=1.25, blade_w=0.84, guard_w=0.82, gem_scale=0.74),
    "B": dict(name="厚重重剑",
              blade=(212, 219, 229), cham=(174, 183, 197), ridge=(228, 234, 242), mid=(146, 155, 170), back=(110, 119, 135),
              gold=(184, 156, 96), gold_hi=(212, 190, 134), gold_sh=(132, 108, 62),
              grip=(78, 62, 54), grip_sh=(50, 40, 34),
              gem=(158, 60, 56), gem_hi=(206, 142, 138),
              blade_len=1.30, blade_w=0.94, guard_w=0.96, gem_scale=0.84),
    "C": dict(name="冷钢发光",
              blade=(186, 198, 218), cham=(148, 162, 188), ridge=(210, 222, 240), mid=(116, 132, 160), back=(84, 98, 126),
              gold=(140, 146, 162), gold_hi=(182, 190, 206), gold_sh=(92, 98, 116),
              grip=(58, 58, 70), grip_sh=(38, 38, 48),
              gem=(78, 158, 186), gem_hi=(160, 214, 230),
              blade_len=1.26, blade_w=0.88, guard_w=0.90, gem_scale=0.80, glow=True),
}

_cur = {"img": None, "w": 0}


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


def ell(cx, cy, rx, ry, color, seg=40):
    poly([(cx + rx * math.cos(2 * math.pi * k / seg), cy + ry * math.sin(2 * math.pi * k / seg)) for k in range(seg)], color)


def band(x_lo, x_hi, y0, y1, color):
    """纵向明暗带"""
    poly([(x_lo, y0), (x_hi, y0), (x_hi, y1), (x_lo, y1)], color)


def draw_sword(img, ox, oy, s, st, rot=0.0):
    _cur["img"] = img
    th = math.radians(rot)
    c, sn = math.cos(th), math.sin(th)

    def P(pts):
        out = []
        for (x, y) in pts:
            rx, ry = x * c - y * sn, x * sn + y * c
            out.append((ox + rx * s, oy + ry * s))
        return out

    BW = 54 * st["blade_w"]          # 刃半宽（根部）
    BWt = 40 * st["blade_w"]         # 刃半宽（近尖）
    GUARD = 78 * st["guard_w"]       # 护手半宽
    L0 = -66                         # 刃根
    L1 = L0 - 232 * st["blade_len"]  # 刃身直线段结束
    TIP = L1 - 60                    # 刃尖（收得更利一点）
    RIDGE = 9
    CH = 13                          # 倒角宽

    # ── 刃身主体（细长的六边形轮廓：根宽 → 近尖稍窄 → 收成尖）──
    blade = [(-BW, L0), (-BWt, L1), (-10, TIP), (10, TIP), (BWt, L1), (BW, L0)]
    poly(P(blade), st["mid"])
    # 左侧倒角+刃口（亮）
    poly(P([(-BW, L0), (-BWt, L1), (-BWt + CH, L1), (-BW + CH, L0)]), st["cham"])
    poly(P([(-BW, L0), (-BWt, L1), (-BWt * 0.72, L1), (-BW + 4, L0)]), st["blade"])
    # 中脊高光
    poly(P([(-RIDGE, L0), (-RIDGE * 0.8, L1), (RIDGE * 0.8, L1), (RIDGE, L0)]), st["ridge"])
    poly(P([(-3, L0), (-2, L1), (2, L1), (3, L0)]), st["blade"])
    # 右侧背暗 + 刃尖暗面
    poly(P([(BW - CH, L0), (BWt - CH, L1), (BWt, L1), (BW, L0)]), st["back"])
    poly(P([(10, TIP), (BWt, L1), (BWt - CH, L1), (10, TIP - 6)]), st["back"])
    # 血槽（细，一条）
    poly(P([(-4, L0 - 8), (-2, L1 + 10), (2, L1 + 10), (4, L0 - 8)]), st["back"])
    # 刃根金线
    poly(P([(-BW, L0), (BW, L0), (BW, L0 - 9), (-BW, L0 - 9)]), st["gold_sh"])
    poly(P([(-BW, L0 - 9), (BW, L0 - 9), (BW, L0 - 14), (-BW, L0 - 14)]), st["gold"])

    # ── 护手：收窄的斜肩 + 两端小尖 ──
    guard = [(-GUARD, -20), (-GUARD * 0.42, -46), (GUARD * 0.42, -46), (GUARD, -20),
             (GUARD, -34), (GUARD * 0.44, -60), (-GUARD * 0.44, -60), (-GUARD, -34)]
    poly(P(guard), st["gold"])
    poly(P([(-GUARD, -20), (-GUARD * 0.42, -46), (GUARD * 0.42, -46), (GUARD, -20),
            (GUARD, -27), (GUARD * 0.44, -53), (-GUARD * 0.44, -53), (-GUARD, -27)]), st["gold_hi"])
    poly(P([(-GUARD, -20), (GUARD, -20), (GUARD, -12), (-GUARD, -12)]), st["gold_sh"])
    poly(P([(-GUARD - 9, -26), (-GUARD + 5, -10), (-GUARD - 3, 3)]), st["gold_sh"])
    poly(P([(GUARD + 9, -26), (GUARD - 5, -10), (GUARD + 3, 3)]), st["gold_sh"])

    # ── 宝石（收小，椭圆 + 高光）──
    gs = st["gem_scale"]
    ell(ox, oy - 32 * s, 13 * gs * s, 17 * gs * s, st["gem"])
    ell(ox - 4 * gs * s, oy - 38 * gs * s, 4 * gs * s, 6 * gs * s, st["gem_hi"])

    # ── 柄（细长 + 缠绳斜纹）──
    for k in range(7):
        yy = -6 + k * 8
        poly(P([(-13, yy), (13, yy + 3), (13, yy + 6), (-13, yy + 3)]), st["grip_sh"])
    poly(P([(-13, -8), (13, -8), (13, 50), (-13, 50)]), st["grip"])
    poly(P([(5, -8), (13, -8), (13, 50), (5, 50)]), st["grip_sh"])
    # ── 柄头（小一点的多面球）──
    ell(ox, oy + 62 * s, 20 * s, 17 * s, st["gold"])
    ell(ox - 4 * s, oy + 57 * s, 9 * s, 7 * s, st["gold_hi"])
    ell(ox, oy + 72 * s, 20 * s, 8 * s, st["gold_sh"])

    if st.get("glow"):
        # 冷钢版的发光刃边：沿左刃口叠一条亮带
        poly(P([(-BW + 1, L0), (-BWt + 1, L1), (-BWt + 6, L1), (-BW + 6, L0)]), (222, 240, 255))
    _cur["img"] = None


def shade_post(img, ox, oy, top_y, bot_y):
    """整把剑的明暗渐变：越靠刃尖越亮、越靠柄越沉；左右再做一点点侧光衰减。
       （平涂色块太多会像塑料，这一步是"去卡通"的关键）"""
    w, h, px = img.w, img.h, img.px
    span = float(bot_y - top_y) if bot_y != top_y else 1.0
    for y in range(h):
        t = (y - top_y) / span
        t = 0.0 if t < 0 else (1.0 if t > 1 else t)
        fv = 1.05 - 0.16 * t
        for x in range(w):
            i = (y * w + x) * 4
            if px[i + 3] == 0:
                continue
            dx = (x - ox) / (96.0 * SS)
            f = fv * (1.0 - 0.05 * dx if dx > 0 else 1.0 - 0.02 * (-dx))
            for c in range(3):
                v = int(round(px[i + c] * f))
                px[i + c] = 255 if v > 255 else (0 if v < 0 else v)


def outline(img, color=LINE, passes=1):
    for _ in range(passes):
        _outline_once(img, color)


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


def render(key):
    st = STYLES[key]
    img = Image(CANVAS, CANVAS)
    draw_sword(img, CANVAS / 2, GRIP_Y, SS * ART_SCALE, st, rot=ROT_DEG)
    shade_post(img, CANVAS / 2, GRIP_Y, GRIP_Y - 430 * st["blade_len"] * SS * ART_SCALE, GRIP_Y + 80 * SS * ART_SCALE)
    outline(img, LINE, passes=2)
    return downsample(img, SS), st


def to_scml(img, pivot_y):
    return '''<?xml version="1.0" encoding="UTF-8"?>
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
'''.format(w=img.w, h=img.h, py=pivot_y)


MAIN = "B"                     # 定稿默认
os.makedirs(OUT, exist_ok=True)
main_img, _ = render(MAIN)
png = os.path.join(OUT, "musha_sword.png")
write_png(png, main_img)
pivot_y = GRIP_Y / float(CANVAS)
open(os.path.join(OUT, "musha_sword.scml"), "w", encoding="utf-8").write(to_scml(main_img, pivot_y))
BUILD = '<Build name="musha_sword.scml">\n <Symbol name="symbol0">\n  <Frame framenum="0" duration="1" image="musha_sword" w="%d" h="%d" x="0.000000" y="0.000000"/>\n </Symbol>\n</Build>\n' % (main_img.w, main_img.h)
ANIM = '<Anims>\n <anim name="idle" root="musha_sword" numframes="1000" framerate="40">\n  <frame idx="0" w="%d" h="%d" x="0.000000" y="0.000000">\n   <element name="symbol0" layername="musha_sword" frame="0" z_index="1" m_a="1.000000" m_b="0.000000" m_c="0.000000" m_d="1.000000" m_tx="0.000000" m_ty="0.000000"/>\n  </frame>\n </anim>\n</Anims>\n' % (main_img.w, main_img.h)
with zipfile.ZipFile(os.path.join(OUT, "musha_sword.zip"), "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("build.xml", BUILD)
    z.writestr("animation.xml", ANIM)
    z.write(png, "musha_sword.png")
print("定稿[%s]：%s (%dx%d)" % (MAIN, png, main_img.w, main_img.h))

# ── 背包图标（斜 45°，超采样后缩）──
ist = dict(STYLES[MAIN])
big = Image(256, 256)
draw_sword(big, 150, 150, 0.40, ist, rot=-45)   # 图标保持斜 45°，与手持无关
outline(big)
write_png(os.path.join(OUT, "icon_musha_sword_64.png"), downsample(big, 4))
print("图标：icon_musha_sword_64.png")

# ── 三版对照预览（横向，1/2 缩放）──
imgs = []
for k in ("A", "B", "C"):
    im, st = render(k)
    imgs.append((k, st["name"], downsample(im, 2)))
pad = 12
W = sum(im.w for _, _, im in imgs) + pad * (len(imgs) + 1)
H = max(im.h for _, _, im in imgs) + pad * 2
pv = Image(W, H)
for y in range(H):
    for x in range(W):
        v = 92 if ((x // 14) + (y // 14)) % 2 == 0 else 128
        i = (y * W + x) * 4
        pv.px[i:i + 4] = bytes((v, v, v + 5, 255))
x = pad
for _, _, im in imgs:
    for y in range(im.h):
        for xx in range(im.w):
            i = (y * im.w + xx) * 4
            if im.px[i + 3] == 0:
                continue
            j = ((y + pad) * W + (x + xx)) * 4
            a = im.px[i + 3] / 255.0
            for c in range(3):
                pv.px[j + c] = int(im.px[i + c] * a + pv.px[j + c] * (1 - a))
            pv.px[j + 3] = 255
    x += im.w + pad
pvpath = os.path.join(HERE, "_test_out", "sword_preview.png")
write_png(pvpath, pv)
print("三版对照（左→右：A 细长优雅 / B 厚重重剑[当前] / C 冷钢发光）：", pvpath)
