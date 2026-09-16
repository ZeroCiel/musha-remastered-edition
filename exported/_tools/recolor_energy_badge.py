# -*- coding: utf-8 -*-
"""能量徽章换色（方向A：只换色，不动外圈形态）—— 2026-09-16

配色 V2「暖木青」（跟面板书页/边框同族）
    液面  淡蓝 #A8D8F0 → 亮青   #82D6E0
    中心  草绿 #90D860 → 亮金   #F8D284
    空槽  暗橄榄 #606048 → 深木棕 #5C4630
    备用底 暖米 #C0A890 → 中木棕 #76583E
    外圈  frame_circle → 原样保留（方向A 不换形）

⚠️ V1 曾用"暖米"当空槽底 → 底(亮度190)比青液面(175)还亮，满/空读不出来
   （原版是 液213 / 底115，靠明暗读能量）。V2 改深木棕 + 提亮液面，差 125。

做法：亮度保形换色 —— 像素亮度相对该图平均亮度的比值不变，色相整体映射到目标色。
      描边/内阴影层次不糊，尺寸/文件名/alpha 全不变 → scml 不用改，重编 energy.zip 即可。
      幂等：源图从 _bak_淡蓝_20260916 读，重复跑不会叠加变色。

备份：exported/energy/_bak_淡蓝_20260916/（原图整套，可一键还原）
"""
import os, shutil, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import Image, read_png, write_png, blit, contact_sheet

E = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\exported\energy"
BAK = os.path.join(E, "_bak_淡蓝_20260916")
DESKTOP = r"C:\Users\Administrator\Desktop"

TARGET = {                              # V2 定稿
    "health_level": (130, 214, 224),
    "heart":        (248, 210, 132),
    "bg":           (92, 70, 48),
    "bg2":          (118, 88, 62),
}
V1 = {                                  # 用户先前看过的 V1（只用于对照，不写盘）
    "health_level": (118, 198, 212),
    "heart":        (236, 178, 96),
    "bg":           (206, 188, 158),
    "bg2":          (226, 212, 186),
}
N_LIQ, N_HEART = 23, 4

# ---------------- 载入 / 换色 ----------------
def load_set(base):
    """{ (folder, name): Image }"""
    out = {}
    for folder in ("bg", "bg2", "heart", "health_level", "frame_circle"):
        d = os.path.join(base, folder)
        if not os.path.isdir(d):
            continue
        for f in sorted(os.listdir(d)):
            if f.lower().endswith(".png"):
                out[(folder, f)] = read_png(os.path.join(d, f))
    return out

def avg_lum(img):
    tot, n = 0.0, 0
    px = img.px
    for i in range(0, len(px), 4):
        if px[i + 3] > 8:
            tot += (px[i] * 3 + px[i + 1] * 6 + px[i + 2]) / 10.0
            n += 1
    return (tot / n) if n else 1.0

def recolor(img, target, lo=0.35, hi=1.85):
    al = avg_lum(img) or 1.0
    out = Image(img.w, img.h, bytearray(img.px))
    px = out.px
    for i in range(0, len(px), 4):
        if px[i + 3] == 0:
            continue
        lum = (px[i] * 3 + px[i + 1] * 6 + px[i + 2]) / 10.0
        r = min(hi, max(lo, lum / al))
        for c in range(3):
            px[i + c] = min(255, max(0, int(round(target[c] * r))))
    return out

def recolor_set(imgs, palette):
    return {(fo, fn): (recolor(im, palette[fo]) if fo in palette else im)
            for (fo, fn), im in imgs.items()}

def avg_rgb(img):
    t = [0, 0, 0]; n = 0; px = img.px
    for i in range(0, len(px), 4):
        if px[i + 3] > 8:
            t[0] += px[i]; t[1] += px[i + 1]; t[2] += px[i + 2]; n += 1
    n = max(n, 1)
    return tuple(x // n for x in t)

def lum(rgb):
    return (rgb[0] * 3 + rgb[1] * 6 + rgb[2]) / 10.0

# ---------------- 合成（液面底部固定 / 心居中 / 环居中） ----------------
def compose(imgs, val, cx=50, cy=50, discs=True):
    cv = Image(100, 100)
    def get(folder, name):
        return imgs.get((folder, name))
    # ⚠️ 编译后的 anim.bin 实测：bg/bg2 两层圆盘被摆在 (-86.5,-87.6)，在徽章范围外
    #    → 实际渲染里它们不参与显示。discs=False 还原"真正看到的样子"。
    if discs:
        for folder, name in (("bg2", "bg2-0.png"), ("bg", "bg-0.png")):
            im = get(folder, name)
            if im:
                blit(cv, im, cx - im.w // 2, cy - im.h // 2)
    idx = int(round((1.0 - val) * (N_LIQ - 1)))
    liq = get("health_level", "health_level-%d.png" % idx)
    blit(cv, liq, cx - liq.w // 2, cy + 31 - liq.h)
    he = get("heart", "heart-%d.png" % min(N_HEART - 1, int(val * N_HEART)))
    blit(cv, he, cx - he.w // 2, cy - he.h // 2)
    rg = get("frame_circle", "frame_circle-0.png")
    blit(cv, rg, cx - rg.w // 2, cy - rg.h // 2 + 1)
    return cv

def zoom(img, z):
    out = Image(img.w * z, img.h * z)
    for y in range(img.h):
        for x in range(img.w):
            i = (y * img.w + x) * 4
            for dy in range(z):
                for dx in range(z):
                    j = ((y * z + dy) * out.w + (x * z + dx)) * 4
                    out.px[j:j + 4] = img.px[i:i + 4]
    return out

def ascii_cell(cv, step=3):
    for y in range(6, 94, step):
        s = ""
        for x in range(6, 94, 2):
            i = (y * cv.w + x) * 4
            r, g, b, a = cv.px[i], cv.px[i + 1], cv.px[i + 2], cv.px[i + 3]
            if a < 40:
                s += " "
            elif r > 150 and g > 140 and b < 175 and r > b + 30:
                s += "o"          # 亮金 / 亮底
            elif b > r + 25:
                s += "B"          # 青液面
            elif g > r + 15 and g > b + 15:
                s += "G"
            else:
                s += "#" if (r * 3 + g * 6 + b) / 10 < 70 else "+"
        print(s)

# ---------------- 主流程 ----------------
def main():
    if not os.path.isdir(BAK):                       # 首次运行：备份原图
        os.makedirs(BAK, exist_ok=True)
        for folder in ("bg", "bg2", "heart", "health_level", "frame_circle"):
            d = os.path.join(E, folder)
            if os.path.isdir(d):
                os.makedirs(os.path.join(BAK, folder), exist_ok=True)
                for f in os.listdir(d):
                    if f.lower().endswith(".png"):
                        shutil.copy2(os.path.join(d, f), os.path.join(BAK, folder, f))
        print("已备份原图 →", BAK)
    src = load_set(BAK)                              # 源 = 原图（幂等）
    if not src:
        print("!! 备份目录里没有图，中止"); return
    print("读到原图 %d 张" % len(src))

    v1 = recolor_set(src, V1)
    v2 = recolor_set(src, TARGET)

    # 写盘（V2）
    written = 0
    for (folder, name), im in v2.items():
        if folder not in TARGET:
            continue
        write_png(os.path.join(E, folder, name), im)
        written += 1
    print("写入 V2 %d 张（frame_circle 未动）" % written)

    # 明暗对比自检（液面 vs 空槽底 vs 中心）
    def rep(tag, s):
        q = avg_rgb(s[("health_level", "health_level-0.png")])
        d = avg_rgb(s[("bg", "bg-0.png")])
        h = avg_rgb(s[("heart", "heart-0.png")])
        print("  %-4s 液面%s 亮度%.0f | 空槽%s 亮度%.0f | 中心%s 亮度%.0f | 液-槽差 %.0f%s"
              % (tag, q, lum(q), d, lum(d), h, lum(h), lum(q) - lum(d),
                 "" if lum(q) - lum(d) > 45 else "  ← 对比不足!"))
    print("明暗对比自检：")
    rep("原版", src); rep("V1", v1); rep("V2", v2)

    # 对照图：行1/2 = 实际渲染(圆盘在徽章外不画) 行3 = 若把圆盘归位当油箱底的样子
    vals = (1.0, 0.75, 0.5, 0.25, 0.0)
    rows = [("换色前·实际", [zoom(compose(src, v, discs=False), 2) for v in vals]),
            ("换色后·实际", [zoom(compose(v2, v, discs=False), 2) for v in vals]),
            ("换色后+圆盘归位", [zoom(compose(v2, v, discs=True), 2) for v in vals])]
    os.makedirs(os.path.join(E, "_concept"), exist_ok=True)
    contact_sheet(rows, os.path.join(E, "_concept", "energy_recolor_20260916.png"), pad=10, bg=(58, 58, 66))
    p2 = os.path.join(DESKTOP, "能量UI_换色对照_20260916.png")
    contact_sheet(rows, p2, pad=10, bg=(58, 58, 66))
    print("对照图 →", p2)

    print("\nV2 val=1.0 ASCII:")
    ascii_cell(compose(v2, 1.0))
    print("\nV2 val=0.5 ASCII:")
    ascii_cell(compose(v2, 0.5))
    print("\nV2 val=0.0 ASCII:")
    ascii_cell(compose(v2, 0.0))

main()
