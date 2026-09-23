#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""回城石草稿生成器（B 档：3 张分层 + 宝石呼吸闪）

输出到 exported/_test_out/回城石/：
  v1_stone.png / v1_gem.png / v1_glow.png     变体1（圆润鹅卵石）
  v2_stone.png / v2_gem.png / v2_glow.png     变体2（方正石台）
  icon_v1.png / icon_v2.png                   64x64 背包图标
  _预览.png                                    对照图（2 倍放大）
纯标准库（复用 pnglib），无 PIL。
"""
import math, os, random, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import Image, write_png

OUT = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\exported\_test_out\回城石"
SW, SH = 60, 80          # 世界物件画布（参考原版宝石 54x75）
GW = 26                  # 宝石
GLW = 52                 # 光晕

# ── 暗黑调配色（描边不用纯黑）
C_OUTLINE = (58, 46, 46)
ROCK = [(222, 212, 192), (180, 170, 150), (128, 118, 108), (56, 50, 52), (48, 44, 46)]
GEM = [(78, 44, 110), (110, 66, 152), (146, 100, 194), (196, 158, 232), (236, 224, 248)]
GLOW_C = (176, 126, 232)


def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def sat(c):
    mx = max(c[:3]); mn = min(c[:3])
    return 0.0 if mx == 0 else (mx - mn) / mx * 100.0


def shade(base, f):
    return tuple(max(0, min(255, int(v * f))) for v in base[:3]) + (255,)


# ─────────────────────────────────────────── 石头
def stone_blob(w, h, rnd, style):
    """返回 (mask 函数, 高度场函数)。mask: 该点是否在石头内；height: 0..1（1=最亮）"""
    cx, cy = w / 2.0, h / 2.0 + 2
    if style == 1:      # 圆润鹅卵石
        R = min(w, h) * 0.46
        h1, p1 = 0.085, rnd.uniform(0, 6.28)
        h2, p2 = 0.05, rnd.uniform(0, 6.28)

        def rad(a):
            return R * (1 + h1 * math.sin(3 * a + p1) + h2 * math.sin(5 * a + p2))
    else:               # 方正石台
        R = min(w, h) * 0.47

        def rad(a):
            k = max(abs(math.cos(a)), abs(math.sin(a)))
            return R * (1.10 - 0.12 * k) * (1 + 0.03 * math.sin(7 * a))

    def inside(x, y):
        dx, dy = x + 0.5 - cx, y + 0.5 - cy
        a = math.atan2(dy, dx)
        r = math.hypot(dx, dy)
        if style == 1:
            return r <= rad(a)
        # 方：切比雪夫距离 + 圆角
        m = max(abs(dx) / (R * 1.05), abs(dy) / (R * 1.28))
        return m <= 1.0 - 0.10 * (1 - min(1.0, (abs(dx) / (R * 1.05)) ** 8 + (abs(dy) / (R * 1.28)) ** 8))

    def height(x, y):
        # 左上打光：离光源越近越亮
        lx, ly = cx - R * 0.38, cy - R * 0.55
        d = math.hypot(x - lx, y - ly) / (R * 1.55)
        return max(0.0, min(1.0, 1.0 - d))

    return inside, height


def draw_stone(style, seed):
    rnd = random.Random(seed)
    im = Image(SW, SH)
    inside, height = stone_blob(SW, SH, rnd, style)
    # 凹槽（放宝石的圆窝）
    gx, gy, gr = SW / 2.0, SH * 0.42, 15.0

    for y in range(SH):
        for x in range(SW):
            if not inside(x, y):
                continue
            t = height(x, y) ** 0.85                 # 略偏亮
            band = int((1 - t) * 3.99)          # 0..3
            c = ROCK[min(band, 3)] + (255,)     # ★ 必须 4 元组：3 元组会把 px 缩短 1 字节
            n = rnd.random()
            if n < 0.05:                        # 麻点
                c = shade(c, 0.86)
            elif n > 0.96:
                c = shade(c, 1.10)
            # 凹槽内部压暗 + 上沿暗、下沿亮（看起来是"凹"）
            d = math.hypot(x + 0.5 - gx, y + 0.5 - gy)
            if d < gr:
                c = shade(c, 0.60)
                if y + 0.5 < gy and d > gr - 3.0:
                    c = shade(c, 0.72)
                if y + 0.5 > gy and d > gr - 3.5:
                    c = shade(c, 1.22)
            im.put(x, y, c)

    # 描边（不用纯黑）
    for y in range(SH):
        for x in range(SW):
            if inside(x, y):
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < SW and 0 <= ny < SH and not inside(nx, ny):
                        im.put(x, y, C_OUTLINE + (255,))
                        break
    return im, (gx, gy, gr)


# ─────────────────────────────────────────── 宝石
def draw_gem(seed=7, s=GW):
    rnd = random.Random(seed)
    im = Image(s, s)
    cx = cy = s / 2.0
    R = s * 0.46
    pts = []
    for i in range(6):
        a = -math.pi / 2 + i * math.pi / 3
        rr = R * (1 + rnd.uniform(-0.06, 0.06))
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr * 1.06))

    def inside(x, y):
        # 凸六边形判定
        px, py = x + 0.5 - cx, y + 0.5 - cy
        if math.hypot(px, py) > R * 1.06:
            return False
        for i in range(6):
            ax, ay = pts[i]; bx, by = pts[(i + 1) % 6]
            ex, ey = bx - ax, by - ay
            if (px - (ax - cx)) * ey - (py - (ay - cy)) * ex > R * 0.35:
                return False
        return True

    for y in range(s):
        for x in range(s):
            if not inside(x, y):
                continue
            px, py = x + 0.5 - cx, y + 0.5 - cy
            # 刻面：按角度/半径分 4 个色阶
            ang = (math.atan2(py, px) + math.pi) / (2 * math.pi)
            r = math.hypot(px, py) / R
            if r < 0.42:
                c = GEM[2] if (px + py) < 0 else GEM[1]
            elif ang < 0.25 or ang > 0.75:
                c = GEM[1]
            elif r > 0.82:
                c = GEM[0]
            else:
                c = GEM[2]
            if px + py < -R * 0.45:             # 左上高光
                c = GEM[3]
            im.put(x, y, c + (255,))
    # 描边 + 一点星芒
    for y in range(s):
        for x in range(s):
            if inside(x, y):
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if not inside(nx, ny):
                        im.put(x, y, GEM[0] + (255,))
                        break
    for i in range(2):
        for j in range(3):
            xx, yy = int(cx - 4 + i), int(cy - 5 + j)
            if 0 <= xx < s and 0 <= yy < s:
                im.put(xx, yy, GEM[4] + (255,))
    return im


# ─────────────────────────────────────────── 光晕
def draw_glow(s=GLW, peak=1.0):
    im = Image(s, s)
    c = s / 2.0
    R = s / 2.0 - 1
    for y in range(s):
        for x in range(s):
            d = math.hypot(x + 0.5 - c, y + 0.5 - c) / R
            if d >= 1.0:
                continue
            a = int(255 * peak * (1 - d) ** 2.2)
            if a <= 2:
                continue
            im.put(x, y, GLOW_C + (a,))
    return im


# ─────────────────────────────────────────── 合成 + 统计
def compose(stone, gem, glow, gem_scale=1.0, glow_peak=1.0, groove=None):
    im = Image(SW, SH)
    im.px[:] = stone.px
    gx, gy, _ = groove
    # 光晕（半透明叠加）
    gs = glow.w
    ox, oy = int(gx - gs / 2), int(gy - gs / 2)
    for y in range(gs):
        for x in range(gs):
            r, g, b, a = glow.get(x, y)
            if a == 0:
                continue
            X, Y = ox + x, oy + y
            if not (0 <= X < SW and 0 <= Y < SH):
                continue
            dr, dg, db, da = im.get(X, Y)
            aa = a / 255.0
            im.put(X, Y, (int(dr + (r - dr) * aa), int(dg + (g - dg) * aa), int(db + (b - db) * aa), max(da, a)))
    # 宝石（缩放后贴）
    if gem_scale != 1.0:
        n = max(1, int(gem.w * gem_scale))
        sc = Image(n, n)
        for y in range(n):
            for x in range(n):
                sc.put(x, y, gem.get(min(gem.w - 1, int(x / gem_scale)), min(gem.h - 1, int(y / gem_scale))))
        gem = sc
    ox, oy = int(gx - gem.w / 2), int(gy - gem.h / 2)
    for y in range(gem.h):
        for x in range(gem.w):
            r, g, b, a = gem.get(x, y)
            if a > 128:
                im.put(ox + x, oy + y, (r, g, b, 255))
    return im


def stats(im):
    ls, ss, dark, n = [], [], 0, 0
    for i in range(0, len(im.px), 4):
        r, g, b, a = im.px[i], im.px[i + 1], im.px[i + 2], im.px[i + 3]
        if a < 200:                     # 只统计不透明像素（世界物件口径）
            continue
        c = (r, g, b)
        L = lum(c)
        ls.append(L); ss.append(sat(c)); n += 1
        if L < 60:
            dark += 1
    if not n:
        return (0, 0, 0, 0)
    return (sum(ls) / n, dark / n * 100.0, sum(ss) / n, n)


def upscale(im, k):
    o = Image(im.w * k, im.h * k)
    for y in range(im.h):
        for x in range(im.w):
            c = im.get(x, y)
            for dy in range(k):
                for dx in range(k):
                    o.put(x * k + dx, y * k + dy, c)
    return o


def main():
    os.makedirs(OUT, exist_ok=True)
    rnd = random.Random(11)
    gem = draw_gem()
    glow = draw_glow()
    variants = {}
    for style in (1, 2):
        stone, groove = draw_stone(style, 100 + style)
        write_png(os.path.join(OUT, f"v{style}_stone.png"), stone)
        write_png(os.path.join(OUT, f"v{style}_gem.png"), gem)
        write_png(os.path.join(OUT, f"v{style}_glow.png"), glow)
        f0 = compose(stone, gem, glow, 1.00, 0.45, groove)
        f4 = compose(stone, gem, glow, 1.09, 0.85, groove)
        write_png(os.path.join(OUT, f"v{style}_合成_呼吸前.png"), f0)
        write_png(os.path.join(OUT, f"v{style}_合成_呼吸峰.png"), f4)
        # 64x64 图标（石头缩到 96% 居中 + 宝石）
        icon = Image(64, 64)
        for y in range(64):
            for x in range(64):
                sx = int((x - 32) / 1.0 + SW / 2)
                sy = int((y - 36) / 1.0 + SH / 2)
                if 0 <= sx < SW and 0 <= sy < SH:
                    icon.put(x, y, f0.get(sx, sy))
        write_png(os.path.join(OUT, f"icon_v{style}.png"), icon)
        variants[style] = (f0, f4, icon, stone, gem, glow)
        L, dk, sa, n = stats(f0)
        print(f"变体{style}: 平均亮度 {L:.0f} / 近黑(<60) {dk:.0f}% / 饱和 {sa:.0f} / 不透明像素 {n}"
              f"   (目标 128 / 28% / 28)")

    # ── 对照图（2 倍）
    cells = []
    for style in (1, 2):
        f0, f4, icon, stone, gem, glow = variants[style]
        cells.append([up_ := upscale(stone, 1), upscale(gem, 1), upscale(glow, 1), upscale(f0, 1), upscale(f4, 1)])
    k = 2
    pad = 10
    cols = 5
    cwid = max(max(c.w for c in row) for row in cells) * k
    chei = max(max(c.h for c in row) for row in cells) * k
    W = cols * (cwid + pad) + pad
    H = len(cells) * (chei + pad) + pad
    sheet = Image(W, H, bytearray([58, 58, 66, 255] * (W * H)))
    for ri, row in enumerate(cells):
        for ci, im in enumerate(row):
            u = upscale(im, k)
            ox = pad + ci * (cwid + pad)
            oy = pad + ri * (chei + pad)
            for y in range(u.h):
                for x in range(u.w):
                    c = u.get(x, y)
                    if c[3] > 0:
                        sheet.put(ox + x, oy + y, c)
    p = os.path.join(OUT, "_预览.png")
    write_png(p, sheet)
    print("预览:", p)
    print("顺序：石头 | 宝石 | 光晕 | 合成(呼吸前) | 合成(呼吸峰)   上排=变体1 下排=变体2")


if __name__ == "__main__":
    main()
