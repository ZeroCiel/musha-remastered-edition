# -*- coding: utf-8 -*-
"""panel_bg 两框合并（2026-09-25 用户拍板「改图合并成一整页」）

结构（探针实测）：
  上框底边   y304..317（金带+白线）  左右带圆角弧（左弧 y284起 x194->230，右弧 y292起 x1142->1128）
  中缝       y316..323 页面底色（250,241,193）
  下框顶线   y324..328（细线）        左弧 y326(x214)->y340(x203) 收直；右弧 y326(x1112)->y356(x1132) 收直
  左侧竖边   上=白线x194+金x200-206   下=细线x203   （页面金边 x181-187 通条，保留）
  右侧竖边   上=白x1130+金x1133-1142  下=白x1116+金线x1134-1137（页面边 x1143-1158 保留）

手术（全部只动 x191..1142）：
  A 直条 y304..328：按列从「上锚行」向「下锚行 368」插值 -> 纸面连续、金带/白线/中缝/顶线全消，
     框边风格在缝里从上框式平滑过渡到下框式。
     上锚行：x191-230 与 x1104-1142 用 y270（直段+弧起前），x231-1103 用 y301。
  B 上弧 y282..303：左右角 x191-230 / x1104-1142 直接纵复制锚行 270 -> 弧钩抹直。
  C 下弧 y329..358：纵复制锚行 368 -> 下框弧抹直；
     左角 x215-230 遇星保留原像素（金色/黑描边/白高光判定），星右半 x231-260 不在手术区。
页边金条/深线、上框顶边、下框底边、翅膀与星本体均不动。
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import read_png, Image, write_png

SRC = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\images\panel_bg.png"
OUT_DIR = os.path.join(HERE, "_panel_probe")
os.makedirs(OUT_DIR, exist_ok=True)

im = read_png(SRC)
W, H = im.w, im.h
src = im.px
out = bytearray(src)

ROW_TOP_L, ROW_TOP_M, ROW_TOP_R = 270, 301, 270
ROW_BOT = 372          # 09-25 二改：368 被右角金星黑描边污染（星体 y341-370），372 实测干净
SMALL_STAR = (216, 231, 284, 299)   # 左上淡橙小星 x/y 范围（B 区绕开）

def sget(x, y):
    i = (y * W + x) * 4
    return src[i], src[i+1], src[i+2], src[i+3]

def oput(x, y, c):
    i = (y * W + x) * 4
    out[i], out[i+1], out[i+2], out[i+3] = c[0], c[1], c[2], c[3]

def lerp2(a, b, t):
    return (int(a[0] + (b[0]-a[0]) * t + 0.5),
            int(a[1] + (b[1]-a[1]) * t + 0.5),
            int(a[2] + (b[2]-a[2]) * t + 0.5),
            a[3])

def starish(c):
    r, g, b = c[0], c[1], c[2]
    if r > 190 and g > 140 and b < 125: return True    # 星体金
    if r < 100 and g < 100 and b < 100: return True    # 黑描边
    if r > 235 and g > 235 and b > 230: return True    # 白高光/白晕
    return False

def top_row(x):
    if x <= 230: return ROW_TOP_L
    if x <= 1103: return ROW_TOP_M
    return ROW_TOP_R

# ---- 锚点行 372 干净度自检（防星晕/横线混入锚点）----
def _rle(seq, tol=14):
    o = []
    for c in seq:
        if o and sum(abs(p-q) for p, q in zip(o[-1][0], c)) <= tol:
            o[-1][1] += 1
        else:
            o.append([c, 1])
    return " | ".join("%d,%d,%d*%d" % (c[0], c[1], c[2], n) for c, n in o)
for seg in ((191, 270), (215, 262), (600, 660), (1090, 1143)):
    print("row372 x%d..%d:" % seg, _rle([sget(x, ROW_BOT)[:3] for x in range(seg[0], seg[1])]))

# ---- A: 直条 y304..328 ----
# 白判据保护（实测 A 区白像素仅 51 个 = 左星星晕 x227-243 y322-328，其余旧框线都不是纯白）
def is_white(c):
    return c[0] > 235 and c[1] > 235 and c[2] > 230
for y in range(304, 329):
    t = (y - 304) / 24.0
    for x in range(191, 1143):
        p = sget(x, y)
        if is_white(p):
            oput(x, y, p)
            continue
        a = sget(x, top_row(x))
        b = sget(x, ROW_BOT)
        oput(x, y, lerp2(a, b, t))

# ---- B: 上弧 y282..303（纵复制 270；左上淡橙小星 x216-231 y284-299 绕开）----
for y in range(282, 304):
    for x in range(191, 216):
        oput(x, y, sget(x, ROW_TOP_L))
    for x in range(1104, 1143):
        oput(x, y, sget(x, ROW_TOP_L))
# 小星右侧 x216..230：星体行(284..299)原样保留，仅抹 y300..303 的弧尾
for y in range(300, 304):
    for x in range(216, 231):
        oput(x, y, sget(x, ROW_TOP_L))

# ---- C: 下弧 y329..358（纵复制 372；两侧角星体保护：左大星 x215-260 / 右星 x1096-1120）----
for y in range(329, 359):
    for x in range(191, 215):
        oput(x, y, sget(x, ROW_BOT))
    for x in range(215, 231):
        p = sget(x, y)
        oput(x, y, p if starish(p) else sget(x, ROW_BOT))
    for x in range(1104, 1143):
        # 右星保区 bbox 实测 x1094..1121 y343..368（含晕/描边AA）：区内原样保留，
        # 区外一律纵复制 372 —— 弧线(y329-341 在 x1116-1127)与星点碎屑全消
        if x <= 1121 and y >= 342:
            oput(x, y, sget(x, y))
        else:
            oput(x, y, sget(x, ROW_BOT))

merged = Image(W, H, out)
write_png(os.path.join(OUT_DIR, "merged_full.png"), merged)
print("wrote merged_full.png", W, H)

# 分隔区放大 x2 供检查
def crop_zoom(x0, y0, x1, y1, z, img):
    o = Image((x1-x0)*z, (y1-y0)*z)
    for yy in range(y1-y0):
        for xx in range(x1-x0):
            c = img.get(x0+xx, y0+yy)
            for dz in range(z):
                for dx in range(z):
                    o.put(xx*z+dx, yy*z+dz, c)
    return o

write_png(os.path.join(OUT_DIR, "merged_divider_x2.png"),
          crop_zoom(160, 265, 1170, 375, 2, merged))
write_png(os.path.join(OUT_DIR, "merged_left_corner_x4.png"),
          crop_zoom(180, 270, 280, 370, 4, merged))
write_png(os.path.join(OUT_DIR, "merged_right_corner_x4.png"),
          crop_zoom(1090, 270, 1160, 370, 4, merged))
print("wrote crops")
