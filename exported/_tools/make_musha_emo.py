"""Musha 表情小图生成器 —— 高兴 / 愉悦 / 满足 / 低丧（程序化画，纯标准库）

用途：面板 UI 的小图（替代占位美术）。产出 4 张 96×96 透明底 PNG + 桌面 4 倍对照图。
风格：孩童风 / 书页感（圆润、暖色、深棕描边**不用纯黑**）。

用法：python make_musha_emo.py [输出目录]
产出：<输出目录>/emote_*.png  +  桌面 musha表情_20260916.png
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import write_png, Image

W = H = 96
SS = 3                     # 超采样
CX, CY, R = 48.0, 50.0, 33.0

SKIN    = (1.00, 0.87, 0.76)
HAIR    = (0.28, 0.21, 0.18)
OUTLINE = (0.26, 0.19, 0.16)      # 描边：深棕（不纯黑）
BLUSH   = (1.00, 0.60, 0.60)
WHITE   = (1.00, 1.00, 1.00)
SPARK   = (1.00, 0.88, 0.42)
HEART   = (0.95, 0.36, 0.46)
RAIN    = (0.52, 0.70, 0.95)
CLOUD   = (0.82, 0.85, 0.90)
TEAR    = (0.70, 0.85, 1.00)


def cov_circle(x, y, cx, cy, r):
    d = math.hypot(x - cx, y - cy)
    return max(0.0, min(1.0, r - d + 0.5))


def cov_ring(x, y, cx, cy, r, th):
    d = math.hypot(x - cx, y - cy)
    return max(0.0, min(1.0, th / 2.0 - abs(d - r) + 0.5))


def cov_ellipse(x, y, cx, cy, rx, ry):
    v = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
    return 1.0 if v <= 1.0 else 0.0


def cov_arc(x, y, cx, cy, r, th, a0, a1):
    """圆弧描边：角度用**屏幕坐标**（0=右，90=下），逆时针 a0→a1（已取模处理）"""
    dx, dy = x - cx, y - cy
    d = math.hypot(dx, dy)
    if abs(d - r) > th / 2.0 + 1:
        return 0.0
    ang = math.degrees(math.atan2(dy, dx)) % 360.0
    a0 %= 360.0
    a1 %= 360.0
    inside = (a0 <= ang <= a1) if a0 <= a1 else (ang >= a0 or ang <= a1)
    return max(0.0, min(1.0, th / 2.0 - abs(d - r) + 0.5)) if inside else 0.0


def cov_star(x, y, cx, cy, s):
    """四角星（闪光）：|dx|+|dy| 菱形 + 十字臂"""
    dx, dy = abs(x - cx), abs(y - cy)
    if dx + dy <= s:
        return 1.0
    if (dx <= s * 0.22 and dy <= s * 1.35) or (dy <= s * 0.22 and dx <= s * 1.35):
        return 1.0
    return 0.0


def cov_heart(x, y, cx, cy, s):
    u, v = (x - cx) / s, -(y - cy) / s
    return 1.0 if (u * u + v * v - 1) ** 3 - u * u * v * v * v <= 0 else 0.0


def render(emo):
    px = []
    inv = 1.0 / (SS * SS)
    for py in range(H):
        for pxx in range(W):
            acc = [0.0, 0.0, 0.0, 0.0]     # r,g,b,a（a 为覆盖率）
            for sy in range(SS):
                for sx in range(SS):
                    x = pxx + (sx + 0.5) / SS - 0.5
                    y = py + (sy + 0.5) / SS - 0.5
                    col = (0.0, 0.0, 0.0)
                    a = 0.0

                    def paint(c, cov):
                        nonlocal col, a
                        if cov <= 0.0:
                            return
                        col = tuple(col[i] * (1 - cov) + c[i] * cov for i in range(3))
                        a = a + (1 - a) * cov

                    # ---- 头 / 头发 ----
                    #   刘海只压上部（y < CY-16），保证脸有 ~50px 可用；侧鬓两条贴脸边
                    paint(HAIR, cov_circle(x, y, CX, CY - 4, R + 2))
                    paint(SKIN, cov_circle(x, y, CX, CY + 2, R))
                    paint(HAIR, cov_circle(x, y, CX, CY - 6, R + 3) if y < CY - 16 else 0.0)
                    paint(HAIR, cov_ellipse(x, y, CX - 31, CY + 8, 7.5, 20))
                    paint(HAIR, cov_ellipse(x, y, CX + 31, CY + 8, 7.5, 20))
                    paint(OUTLINE, cov_ring(x, y, CX, CY + 2, R, 2.4))

                    ex1, ex2, ey = CX - 11, CX + 11, CY + 4
                    if emo == "happy":
                        paint(OUTLINE, cov_arc(x, y, ex1, ey + 2, 8, 3.0, 200, 340))
                        paint(OUTLINE, cov_arc(x, y, ex2, ey + 2, 8, 3.0, 200, 340))
                        paint(OUTLINE, cov_arc(x, y, CX, CY + 14, 12, 3.2, 20, 160))
                        paint(BLUSH, cov_ellipse(x, y, CX - 21, CY + 12, 7, 4) * 0.6)
                        paint(BLUSH, cov_ellipse(x, y, CX + 21, CY + 12, 7, 4) * 0.6)
                        paint(SPARK, cov_star(x, y, CX - 27, CY - 30, 5))
                        paint(SPARK, cov_star(x, y, CX + 26, CY - 26, 4))
                    elif emo == "joy":
                        paint(WHITE, cov_circle(x, y, ex1, ey, 7.5))
                        paint(WHITE, cov_circle(x, y, ex2, ey, 7.5))
                        paint(OUTLINE, cov_arc(x, y, ex1, ey + 3, 7.5, 2.8, 200, 340))
                        paint(OUTLINE, cov_arc(x, y, ex2, ey + 3, 7.5, 2.8, 200, 340))
                        paint(OUTLINE, cov_ellipse(x, y, CX, CY + 17, 11, 7.5))     # 张嘴
                        paint(WHITE, cov_ellipse(x, y, CX, CY + 20, 7, 3.5) * 0.9)   # 舌头高光
                        paint(BLUSH, cov_ellipse(x, y, CX - 22, CY + 12, 8, 4.5) * 0.8)
                        paint(BLUSH, cov_ellipse(x, y, CX + 22, CY + 12, 8, 4.5) * 0.8)
                        paint(HEART, cov_heart(x, y, CX - 30, CY - 30, 5.5))
                        paint(HEART, cov_heart(x, y, CX + 30, CY - 27, 4.5))
                        paint(HEART, cov_heart(x, y, CX + 35, CY - 11, 3.5))
                    elif emo == "content":
                        paint(OUTLINE, cov_arc(x, y, ex1, ey - 1, 8, 2.8, 25, 155))
                        paint(OUTLINE, cov_arc(x, y, ex2, ey - 1, 8, 2.8, 25, 155))
                        paint(OUTLINE, cov_arc(x, y, CX, CY + 14, 9, 2.6, 35, 145))
                        paint(BLUSH, cov_ellipse(x, y, CX - 20, CY + 12, 6, 3.5) * 0.5)
                        paint(BLUSH, cov_ellipse(x, y, CX + 20, CY + 12, 6, 3.5) * 0.5)
                    else:  # sad（低丧：惨了惨了）
                        paint(WHITE, cov_circle(x, y, ex1, ey + 1, 6.5))
                        paint(WHITE, cov_circle(x, y, ex2, ey + 1, 6.5))
                        paint(OUTLINE, cov_ring(x, y, ex1, ey + 1, 6.5, 2.0))
                        paint(OUTLINE, cov_ring(x, y, ex2, ey + 1, 6.5, 2.0))
                        paint(OUTLINE, cov_arc(x, y, ex1, ey - 7, 7.5, 2.6, 200, 340))   # 八字眉
                        paint(OUTLINE, cov_arc(x, y, ex2, ey - 7, 7.5, 2.6, 200, 340))
                        paint(OUTLINE, cov_arc(x, y, CX, CY + 26, 10, 2.8, 200, 340))   # 撇嘴角
                        paint(TEAR, cov_ellipse(x, y, ex1 - 7, ey + 11, 3, 4.5))         # 泪
                        paint(CLOUD, cov_circle(x, y, CX - 9, CY - 40, 6.5))             # 乌云（头顶上方）
                        paint(CLOUD, cov_circle(x, y, CX, CY - 43, 7.5))
                        paint(CLOUD, cov_circle(x, y, CX + 10, CY - 40, 6.5))
                        paint(RAIN, cov_ellipse(x, y, CX - 13, CY - 30, 2, 4))           # 雨点
                        paint(RAIN, cov_ellipse(x, y, CX + 2, CY - 28, 2, 4))
                        paint(RAIN, cov_ellipse(x, y, CX + 15, CY - 30, 2, 4))

                    acc[0] += col[0] * a
                    acc[1] += col[1] * a
                    acc[2] += col[2] * a
                    acc[3] += a
            aa = acc[3] * inv
            if aa <= 0.002:
                px.append((0, 0, 0, 0))
            else:
                px.append((int(acc[0] * inv / aa * 255 + 0.5),
                           int(acc[1] * inv / aa * 255 + 0.5),
                           int(acc[2] * inv / aa * 255 + 0.5),
                           int(min(1.0, aa) * 255 + 0.5)))
    return px


def main(argv):
    out = argv[0] if argv else r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\images\emotes"
    os.makedirs(out, exist_ok=True)
    names = [("happy", "高兴"), ("joy", "愉悦"), ("content", "满足"), ("sad", "低丧")]
    imgs = []
    for key, cn in names:
        px = render(key)
        p = os.path.join(out, "emote_%s.png" % key)
        # ⚠️ 别用 img.px += —— Image() 初始化时 px 已经是 w*h*4 个 0 字节，
        #    += 会把真数据追加到那堆 0 后面，write_png 只读前 w*h*4 → 出全透明空图（踩过）
        buf = bytearray()
        for (r, g, b, a) in px:
            buf += bytes((r, g, b, a))
        img = Image(W, H, buf)
        write_png(p, img)
        print("  %s  %s" % (p, cn))
        imgs.append((key, cn, px))

    # 桌面 4 倍对照图（暖底 + 英文标签，中文画不了用拼音替代）
    K = 4
    pad = 16
    cw, ch = W * K + pad * 2, H * K + pad * 2 + 26
    cv = Image(cw * 4, ch)
    for i in range(0, cv.w * cv.h * 4, 4):
        cv.px[i:i + 3] = bytes((58, 56, 52))
        cv.px[i + 3] = 255
    for i, (key, cn, px) in enumerate(imgs):
        ox = i * cw + pad
        oy = pad + 20
        for y in range(H):
            for x in range(W):
                r, g, b, a = px[y * W + x]
                if a == 0:
                    continue
                for dy in range(K):
                    for dx in range(K):
                        j = ((oy + y * K + dy) * cv.w + ox + x * K + dx) * 4
                        al = a / 255.0
                        cv.px[j] = int(cv.px[j] * (1 - al) + r * al)
                        cv.px[j + 1] = int(cv.px[j + 1] * (1 - al) + g * al)
                        cv.px[j + 2] = int(cv.px[j + 2] * (1 - al) + b * al)
    sheet = r"C:\Users\Administrator\Desktop\musha表情_20260916.png"
    write_png(sheet, cv)
    print("对照图:", sheet, "%dx%d" % (cv.w, cv.h))


if __name__ == "__main__":
    main(sys.argv[1:])
