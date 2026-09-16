"""musha 基础剑 → 星灵（Protoss）灵能巨剑。

用户 2026-09-16 定调：星际争霸神族风 —— 金色/青铜金属剑身 ＋ 蓝白灵能发光刃 ＋ 水晶悬浮感。
上一版（按参考图画的单色灰钢重剑）备份在：本目录 make_musha_sword_steel.py，
出图备份 exported/_bak_musha_sword_steel/。

风格要点（Protoss 的视觉语汇）：
  · 金色/青铜重金件（不是灰钢），暖金三档明暗
  · 蓝白灵能能量：外光晕 → 中蓝 → 浅蓝 → 白核，四层叠出"发光"的错觉（不用半透明，避免缩放脏边）
  · 几何硬边、对称、翼状护手、菱形水晶
  · 刃根金色"发射座" + 中央能量通道贯穿到刃尖（能量从护手射出）
  · 柄尾一颗水晶，与柄之间**留空隙** = 悬浮感

工程约定（照"能在手里显示"的 swap_lifebranch 实证样板）：
  · 画布方形、**pivot = 握把中心**（手抓这点、剑身朝上）
  · 实体尺寸对齐基准：树枝实体 346x326 → 剑定在 ≈390 高
  · 2 倍超采样后缩小 = 抗锯齿；再用 shade_post 叠整体明暗渐变
  · 出图目录按 Spriter/DST Mod Tool 规范：`musha_sword/musha_sword-0.png`（idle 用）
    + `BUILD/BUILD-0.png`（BUILD 用，**必须有图，空动画没用**）；scml 的 file 路径写 `文件夹/文件名`
  · scml 两个动画：`idle`（世界/掉落形态）+ `BUILD`（用户规范：做武器/动画都要带）；两者 timeline 都叫 musha_sword
    （BUILD 没有自己的符号，别污染 build）
  · 手持显示 = ① timeline 名 = 符号名 = build 名 ② pivot 落在握把 ③ 图按子文件夹规范放对 ④ zip 用 Mod Tool 编译过
  · ★ **不要再手写 zip**：DST 的 anim 包是二进制的（内含 anim.bin / build.bin / atlas-0.tex），
    xml+png 手写包引擎读不了。出图后必须用 DST Mod Tool 打开本 scml 编译成 anim/musha_sword.zip

产出（exported/musha_sword_v2/）：musha_sword.png(768²) / musha_sword.scml / icon_musha_sword_64.png
预览：exported/_tools/_test_out/sword_preview.png

用法：python make_musha_sword.py   → 然后 Mod Tool 编译 scml 出 anim/musha_sword.zip
"""
import os, sys, math, zipfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import Image, write_png

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.normpath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(MOD, "exported", "musha_sword_v2")

SS = 2                     # 超采样倍数（抗锯齿）
CANVAS = 768 * SS          # 绘制画布（缩回 768 出图）
GRIP_Y = 470 * SS          # 画图用的握把锚点 y（绘制坐标 = 从上往下数）
# ★★ pivot 口径（2026-09-16 踩坑，别改回去）
#   scml 里 pivot_x / pivot_y 都是图片内的归一值，但 **pivot_y 是「从图片底部往上数」**，
#   跟绘制坐标（y 从上往下）方向相反 → 往 scml 写必须先翻转：pivot_y = 1 - y/CANVAS。
#   写错的表现：武器"被握在剑身上"、手里位置整体偏一截（2026-09-16 这次的 bug 就是旧码漏了翻转）。
GRIP_PIVOT_X = 0.498494    # 量图实测：柄中轴 x = 383.5/768 ≈ 0.4993（取主图声明值，误差 1px）
GRIP_PIVOT_Y = 0.364458    # 量图实测：柄身窄段 y 468~508 → 中心 488/768 = 0.6354（从上数）
                           #           → 从下往上 = 0.3646（取主图声明值）
ART_SCALE = 0.72           # 实际大小（0.72 → 剑身约 390px 高）
ROT_DEG = 0.0              # 整体旋转角：进游戏发现歪了/躺了，改这里重跑

# ── 星灵配色：暖金 ＋ 蓝白灵能 ──
GOLD_HI = (255, 228, 142)   # 金最高光
GOLD    = (214, 170, 62)    # 金主色
GOLD_D  = (166, 122, 34)    # 金暗部
GOLD_DD = (112, 78, 20)     # 金最深
ENERGY_CORE = (236, 250, 255)   # 能量白核
ENERGY      = (120, 214, 255)   # 能量亮蓝
ENERGY_MID  = (56, 150, 224)    # 能量中蓝
ENERGY_DEEP = (32, 104, 180)    # 能量深蓝（通道最外档 = 光往金身上溢出）
GLOW        = (22, 62, 132)     # 外光晕（深蓝，刃轮廓外一圈）
GRIP        = (44, 40, 66)      # 柄（暗紫）
GRIP_D      = (28, 26, 44)
GRIP_HI     = (72, 66, 100)
LINE  = (20, 24, 44)            # 描边（深藏青，不纯黑）

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

    def dia(cx, cy, rx, ry):
        """菱形（Protoss 水晶的基本形）"""
        return P([(cx, cy - ry), (cx + rx, cy), (cx, cy + ry), (cx - rx, cy)])

    BW, BWt = 56, 48          # 刃半宽（根部 / 近尖）
    L0, L1 = -74, -392        # 刃身：根 → 左刃口末端
    R1 = -350                 # 右刃口末端（比左边短 → 斜切刀尖）

    # ① 灵能外光晕（刃轮廓外扩一圈，画在最底层 → 只露一圈蓝边）
    poly(P([(-BW - 10, L0), (-BWt - 10, L1 - 10), (BWt + 10, R1 - 10),
            (62, -186), (46, -186), (46, -145), (64, -145), (BW + 10, L0)]), GLOW)

    # ② 刃身：金色金属底（保留斜切刀尖 + 刃身台阶缺口）
    blade = [(-BW, L0), (-BWt, L1), (BWt, R1),
             (52, -186), (36, -186), (36, -156), (54, -156), (BW, L0)]
    poly(P(blade), GOLD)
    # 左刃口 = 蓝白能量刃（外亮内过渡到金身；只占刃宽一小条，主体留金）
    poly(P([(-BW, L0), (-BWt, L1), (-BWt + 7, L1 + 6), (-BW + 7, L0)]), ENERGY)
    poly(P([(-BW + 7, L0), (-BWt + 7, L1 + 6), (-BWt + 13, L1 + 11), (-BW + 13, L0)]), ENERGY_MID)
    # 右背面收暗（两档，立体感）
    poly(P([(30, L0), (30, R1 + 10), (BWt, R1 + 6), (BW, L0)]), GOLD_D)
    poly(P([(44, L0), (44, R1 + 18), (BWt, R1 + 8), (BW, L0)]), GOLD_DD)
    # 斜切刀尖的斜端面（能量刃尾，整片发光）
    poly(P([(-BWt, L1), (BWt, R1), (BWt - 13, R1 + 12), (-BWt + 13, L1 + 12)]), ENERGY)
    # 右刃口镶一道细能量边（比左边细，保持左侧为主刃口）
    poly(P([(BW, L0), (BWt, R1), (BWt - 5, R1 + 5), (BW - 5, L0)]), ENERGY_MID)

    # ③ 中央灵能通道（深蓝 → 中蓝 → 浅蓝 → 白核，四段叠出"发光的槽"）
    poly(P([(-13, L0), (-13, L1 + 14), (13, R1 + 14), (13, L0)]), ENERGY_DEEP)
    poly(P([(-9, L0), (-9, L1 + 11), (9, R1 + 11), (9, L0)]), ENERGY_MID)
    poly(P([(-5.5, L0), (-5.5, L1 + 8), (5.5, R1 + 8), (5.5, L0)]), ENERGY)
    poly(P([(-2.2, L0), (-2.2, L1 + 6), (2.2, R1 + 6), (2.2, L0)]), ENERGY_CORE)

    # ④ 刃根金色发射座（能量由此射出）+ 座上一道发光缝
    poly(P([(-BW, L0), (BW, L0), (BW, L0 - 16), (-BW, L0 - 16)]), GOLD_D)
    poly(P([(-BW + 5, L0 - 3), (BW - 5, L0 - 3), (BW - 5, L0 - 11), (-BW + 5, L0 - 11)]), GOLD_HI)
    poly(P([(-BW + 12, L0 - 16), (BW - 12, L0 - 16), (BW - 12, L0 - 22), (-BW + 12, L0 - 22)]), ENERGY)

    # ⑤ 护手：金色带翼
    poly(P([(-62, -28), (62, -28), (50, -72), (-50, -72)]), GOLD)
    poly(P([(-62, -28), (62, -28), (58, -40), (-58, -40)]), GOLD_HI)
    poly(P([(-58, -40), (58, -40), (52, -52), (-52, -52)]), GOLD_D)
    poly(P([(-58, -52), (58, -52), (50, -72), (-50, -72)]), GOLD_DD)
    for sgn in (-1, 1):       # 两翼（对称硬边）
        poly(P([(sgn * 80, -36), (sgn * 58, -36), (sgn * 54, -18), (sgn * 76, -18)]), GOLD_HI)
        poly(P([(sgn * 76, -18), (sgn * 54, -18), (sgn * 50, -6), (sgn * 72, -6)]), GOLD_D)

    # ⑥ 护手中央灵能水晶（蓝框 + 白核 + 高光点）
    poly(dia(0, -50, 27, 40), ENERGY_MID)
    poly(dia(0, -50, 20, 31), ENERGY)
    poly(dia(0, -50, 10, 17), ENERGY_CORE)
    poly(dia(-6, -62, 3.5, 6), (255, 255, 255))      # 高光点

    # ⑦ 柄：暗紫 + 三道金环
    poly(P([(-16, -44), (16, -44), (16, 54), (-16, 54)]), GRIP)
    poly(P([(7, -44), (16, -44), (16, 54), (7, 54)]), GRIP_D)
    poly(P([(-16, -44), (-11, -44), (-11, 54), (-16, 54)]), GRIP_HI)
    for yy in (-38, -6, 26):
        poly(P([(-16, yy), (16, yy), (16, yy + 8), (-16, yy + 8)]), GOLD_D)
        poly(P([(-16, yy), (16, yy), (16, yy + 4), (-16, yy + 4)]), GOLD_HI)
    poly(P([(-16, 46), (16, 46), (16, 54), (-16, 54)]), GOLD_DD)

    # ⑧ 柄尾悬浮灵能水晶（与柄之间留空隙 = 悬浮感）
    poly(dia(0, 100, 25, 33), GLOW)
    poly(dia(0, 100, 18, 27), ENERGY)
    poly(dia(0, 100, 8, 15), ENERGY_CORE)

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
               GRIP_Y - 430 * SS * ART_SCALE, GRIP_Y + 140 * SS * ART_SCALE, 90 * SS)
    outline(img, LINE, passes=2)
    return downsample(img, SS)


os.makedirs(OUT, exist_ok=True)
main_img = render()
png = os.path.join(OUT, "musha_sword.png")
write_png(png, main_img)
# ★ Spriter / DST Mod Tool 规范（2026-09-16 用户两次纠正后的定稿）：
#   ① 图必须放进**子文件夹**，文件名带帧号 `名-0.png` `名-1.png` `名-2.png`，
#      scml 的 `<file name>` 写 **`文件夹/文件名`** 全路径。
#   ② 子文件夹用 **`swap_` 前缀** —— swap 是"**手上**"的表示格式。
#      样板：旧工程 exported/musha_sword/swap_sowrd/swap_sowrd-0/1/2.png
#            exported/musha_lifebranch/swap_lifebranch/swap_lifebranch-0.png
#   ③ 不要建与 build 同名的文件夹（如 `musha_sword/`）—— 用户明确说不需要。
#   ④ BUILD 动画用**同一份 swap 帧**（跟 idle 一样指向 folder 0）——"BUILD 也可以"。
SWAP = "swap_sword"                      # ★ 命名规矩（照 musha_lifebranch → swap_lifebranch）：
                                         #   swap_ 前缀 + **去掉 musha**；只有 scml 保留 musha 名
FRAME_DIR = os.path.join(OUT, SWAP)
os.makedirs(FRAME_DIR, exist_ok=True)
for _i in range(3):                      # 3 帧（照旧工程 -0/-1/-2 的格式）
    write_png(os.path.join(FRAME_DIR, "%s-%d.png" % (SWAP, _i)), main_img)
_bd = os.path.join(OUT, "BUILD")         # 上一版误建的 BUILD 空目录，清掉
if os.path.isdir(_bd) and not os.listdir(_bd):
    os.rmdir(_bd)
_md = os.path.join(OUT, "musha_sword")   # 上一版误建的 musha_sword 目录，清掉
if os.path.isdir(_md):
    for _f in os.listdir(_md):
        os.remove(os.path.join(_md, _f))
    os.rmdir(_md)
pivot_y = GRIP_PIVOT_Y      # ← 口径见文件头注释（旧代码误写成 GRIP_Y/CANVAS = 漏了 y 翻转）
pivot_x = GRIP_PIVOT_X

SCML = '''<?xml version="1.0" encoding="UTF-8"?>
<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="r11">
 <folder id="0" name="swap_sword">
  <file id="0" name="swap_sword/swap_sword-0.png" width="{w}" height="{h}" pivot_x="{px:.6f}" pivot_y="{py:.6f}" />
  <file id="1" name="swap_sword/swap_sword-1.png" width="{w}" height="{h}" pivot_x="{px:.6f}" pivot_y="{py:.6f}" />
  <file id="2" name="swap_sword/swap_sword-2.png" width="{w}" height="{h}" pivot_x="{px:.6f}" pivot_y="{py:.6f}" />
 </folder>
 <entity id="0" name="musha_sword">
  <animation id="0" name="idle" length="1000" interval="100">
   <mainline>
    <key id="0" time="0">
     <object_ref id="0" timeline="0" key="0" z_index="0" name="swap_sword" />
    </key>
   </mainline>
   <timeline id="0" name="swap_sword">
    <key id="0" time="0" spin="0">
     <object folder="0" file="0" scale_x="1" scale_y="1" />
    </key>
   </timeline>
  </animation>
  <animation id="1" name="BUILD" length="1000" interval="100">
   <mainline>
    <key id="0" time="0">
     <object_ref id="0" timeline="0" key="0" z_index="0" name="swap_sword" />
    </key>
   </mainline>
   <timeline id="0" name="swap_sword">
    <key id="0" time="0" spin="0">
     <object folder="0" file="0" scale_x="1" scale_y="1" />
    </key>
   </timeline>
  </animation>
 </entity>
</spriter_data>
'''.format(w=main_img.w, h=main_img.h, px=pivot_x, py=pivot_y)
open(os.path.join(OUT, "musha_sword.scml"), "w", encoding="utf-8").write(SCML)
# ⚠️ 不再手写 zip：DST 的 anim 包是二进制（anim.bin / build.bin / atlas-0.tex），
#    xml+png 那种包引擎读不了（会加载失败）。必须用 DST Mod Tool 打开这个 scml 编译。
_oldzip = os.path.join(OUT, "musha_sword.zip")
if os.path.isfile(_oldzip):
    os.remove(_oldzip)

# 背包图标（斜 42°，超采样后缩）
big = Image(256, 256)
draw_sword(big, 140, 146, 0.30, rot=-42)
outline(big, LINE, passes=1)
write_png(os.path.join(OUT, "icon_musha_sword_64.png"), downsample(big, 4))

# 预览（棋盘底 + 1 倍图）
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

# 自检
xs = []; ys = []
for y in range(main_img.h):
    for x in range(main_img.w):
        if main_img.px[(y * main_img.w + x) * 4 + 3] > 40:
            xs.append(x); ys.append(y)
soft = sum(1 for i in range(3, len(main_img.px), 4) if 0 < main_img.px[i] < 255)
print("剑身：%s (%dx%d)" % (png, main_img.w, main_img.h))
print("实体范围：%dx%d 宽高（基准树枝 346x326）  抗锯齿边缘像素=%d" % (
    max(xs) - min(xs) + 1, max(ys) - min(ys) + 1, soft))
print("pivot_x = %.6f  pivot_y = %.6f（握把中心，y 从下往上数）  预览：%s" % (pivot_x, pivot_y, pvpath))

# 配色自检（确认是"暖金 + 蓝白灵能"而不是灰钢）
from collections import Counter
cnt = Counter()
for i in range(0, len(main_img.px), 4):
    if main_img.px[i + 3] < 128:
        continue
    r, g, b = main_img.px[i], main_img.px[i + 1], main_img.px[i + 2]
    if b > r + 30:
        cnt["蓝白灵能"] += 1
    elif r > b + 30:
        cnt["暖金"] += 1
    else:
        cnt["中性灰"] += 1
tot = sum(cnt.values()) or 1
print("配色占比：" + "  ".join("%s %.0f%%" % (k, v * 100.0 / tot) for k, v in cnt.most_common()))
