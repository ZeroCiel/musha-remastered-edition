# -*- coding: utf-8 -*-
"""天使皮肤 · 改装试验 v1（纯标准库）

做两件事：
  A. 整色：把 musha_cloth_v01 的 19 个符号整体改成「奶白 + 淡金 + 白金发 + 金瞳」
  B. 换眼：face-0 的两只眼睛按检测到的原眼眶重画（金瞳 + 睫毛 + 高光）

产物只写到 exported/_test_out/angel_v1/，绝不碰 anim/ 与工程原图。

用法：
  python angel_kin_v1.py            # 改装 + 打印报告
"""
import os, sys, shutil, colorsys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import Image, read_png, write_png

MUSHA = os.path.abspath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(MUSHA, "exported", "musha_cloth_v01")
DST = os.path.join(MUSHA, "exported", "_test_out", "angel_v1")

# ---------- 调色板 ----------
OUTLINE = (40, 30, 22)          # 暖黑描边（不纯黑）
HAIR_SHADOW = (208, 193, 158)
HAIR_LIGHT = (255, 254, 248)
CLOTH_SHADOW = (204, 197, 182)
CLOTH_LIGHT = (250, 247, 238)
TRIM_GOLD_DARK = (192, 158, 86)
TRIM_GOLD_LIGHT = (252, 232, 180)
IRIS_DARK = (204, 142, 34)
IRIS_LIGHT = (255, 238, 168)
MOUTH_DARK = (150, 90, 96)
MOUTH_LIGHT = (216, 142, 148)
CHEEK_DARK = (248, 220, 212)
CHEEK_LIGHT = (255, 247, 242)
EYE_LASH = (34, 24, 18)

HAIR_SYMS = {"hair", "hairfront", "hair_hat", "hairpigtails"}
SKIN_SYMS = {"headbase", "headbase_hat"}
BODY_SYMS = {"torso", "torso_pelvis", "arm_upper", "arm_lower", "arm_upper_skin",
             "hand", "leg", "foot", "skirt", "tail", "swap_icon"}


def lerp(a, b, t):
    t = 0.0 if t < 0 else (1.0 if t > 1 else t)
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def clamp01(v):
    return 0.0 if v < 0 else (1.0 if v > 1 else v)


def hsv(r, g, b):
    return colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)


def pxl(im, x, y):
    i = (y * im.w + x) * 4
    return im.px[i], im.px[i + 1], im.px[i + 2], im.px[i + 3]


def pxset(im, x, y, c):
    i = (y * im.w + x) * 4
    if len(c) == 3:
        c = (c[0], c[1], c[2], 255)
    im.px[i:i + 4] = bytes(c)


def map_pixel(sym, r, g, b):
    """返回新 RGB。"""
    h, s, v = hsv(r, g, b)

    if sym in HAIR_SYMS:
        if v < 0.30:
            return OUTLINE
        t = clamp01((v - 0.34) / 0.55)
        return lerp(HAIR_SHADOW, HAIR_LIGHT, t)

    if sym in SKIN_SYMS:
        if v < 0.22 and s < 0.55:
            return OUTLINE
        # 提亮 + 去饱和 → 奶白肤色；保留原本的腮红/阴影层次
        return lerp((r, g, b), (250, 246, 242), 0.55)

    if sym == "face":
        if v < 0.30:
            return OUTLINE
        if s < 0.13 and v > 0.72:
            return (255, 255, 250)
        if 0.85 < h < 0.99 and s > 0.30:
            if v > 0.72:
                return lerp(IRIS_DARK, IRIS_LIGHT, clamp01((v - 0.80) / 0.19))
            return lerp(MOUTH_DARK, MOUTH_LIGHT, clamp01(v / 0.75))
        return (r, g, b)

    if sym == "cheeks":
        return lerp(CHEEK_DARK, CHEEK_LIGHT, clamp01((v - 0.78) / 0.22))

    if sym in BODY_SYMS:
        if v < 0.06:
            return OUTLINE
        t = clamp01((v - 0.10) / 0.70)
        if s > 0.22 and 0.07 < h < 0.17:       # 原滚边/米色 → 淡金
            return lerp(TRIM_GOLD_DARK, TRIM_GOLD_LIGHT, t)
        return lerp(CLOTH_SHADOW, CLOTH_LIGHT, t)

    return (r, g, b)


def recolor(im, sym):
    out = Image(im.w, im.h, bytearray(im.px))
    for y in range(im.h):
        for x in range(im.w):
            r, g, b, a = pxl(im, x, y)
            if a == 0:
                continue
            pxset(out, x, y, map_pixel(sym, r, g, b) + (a,))
    return out


# ---------- 超采样画笔 ----------
class SS(object):
    def __init__(self, w, h, s=4):
        self.s = s
        self.W = w * s
        self.H = h * s
        self.buf = bytearray(self.W * self.H * 4)

    def _blend(self, X, Y, c):
        if not (0 <= X < self.W and 0 <= Y < self.H):
            return
        i = (Y * self.W + X) * 4
        a = c[3]
        if a == 0:
            return
        oa = self.buf[i + 3]
        na = a + oa * (255 - a) // 255
        if na:
            for k in range(3):
                num = c[k] * a + self.buf[i + k] * oa * (255 - a) // 255
                self.buf[i + k] = num // na
        self.buf[i + 3] = na

    def disc(self, cx, cy, rx, ry, color, alpha=255):
        s = self.s
        col = (color[0], color[1], color[2], alpha)
        X0, X1 = int((cx - rx - 1) * s), int((cx + rx + 2) * s)
        Y0, Y1 = int((cy - ry - 1) * s), int((cy + ry + 2) * s)
        for Y in range(max(0, Y0), min(self.H, Y1)):
            yy = (Y + 0.5) / s - cy
            for X in range(max(0, X0), min(self.W, X1)):
                xx = (X + 0.5) / s - cx
                if (xx / rx) ** 2 + (yy / ry) ** 2 <= 1.0:
                    self._blend(X, Y, col)

    def stroke(self, pts, width, color, alpha=255, taper=0.0):
        col = (color[0], color[1], color[2], alpha)
        n = len(pts) - 1
        for k in range(n):
            x0, y0 = pts[k]
            x1, y1 = pts[k + 1]
            seg = max(1, int(((x1 - x0) ** 2 + (y1 - y0) ** 2) ** 0.5 * 6))
            for j in range(seg + 1):
                t = j / float(seg)
                w = width
                if taper:
                    w = width * (1.0 - taper * (k + t) / max(1, n))
                self.disc(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, w / 2.0, w / 2.0, color, alpha)

    def resolve(self, w, h):
        s = self.s
        out = Image(w, h)
        for y in range(h):
            for x in range(w):
                sr = sg = sb = sa = 0
                for dy in range(s):
                    for dx in range(s):
                        i = ((y * s + dy) * self.W + (x * s + dx)) * 4
                        a = self.buf[i + 3]
                        if a == 0:
                            continue
                        sr += self.buf[i] * a
                        sg += self.buf[i + 1] * a
                        sb += self.buf[i + 2] * a
                        sa += a
                if sa == 0:
                    continue
                o = (y * w + x) * 4
                out.px[o] = sr // sa
                out.px[o + 1] = sg // sa
                out.px[o + 2] = sb // sa
                out.px[o + 3] = sa // (s * s)
        return out


def components(im, thr=40):
    """alpha>thr 的 4 邻域连通块 → [(area, x0,y0,x1,y1, set((x,y)))]"""
    seen = bytearray(im.w * im.h)
    comps = []
    for y0 in range(im.h):
        for x0 in range(im.w):
            if seen[y0 * im.w + x0]:
                continue
            if im.px[(y0 * im.w + x0) * 4 + 3] <= thr:
                seen[y0 * im.w + x0] = 1
                continue
            stack = [(x0, y0)]
            seen[y0 * im.w + x0] = 1
            pts = []
            while stack:
                x, y = stack.pop()
                pts.append((x, y))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < im.w and 0 <= ny < im.h and not seen[ny * im.w + nx]:
                        seen[ny * im.w + nx] = 1
                        if im.px[(ny * im.w + nx) * 4 + 3] > thr:
                            stack.append((nx, ny))
            xs = [p[0] for p in pts]
            ys = [p[1] for p in pts]
            comps.append((len(pts), min(xs), min(ys), max(xs), max(ys), set(pts)))
    comps.sort(key=lambda c: -c[0])
    return comps


def draw_eye(layer, cx, cy, rx, ry, outer_right):
    r = ry * 0.66
    iy = cy + ry * 0.06
    layer.disc(cx, cy, rx * 0.97, ry * 0.94, (253, 251, 247))
    layer.disc(cx, iy, r, r, (230, 176, 60))
    layer.disc(cx, iy - r * 0.34, r * 0.92, r * 0.60, (252, 216, 116))
    layer.disc(cx, iy + r * 0.55, r * 0.86, r * 0.42, (188, 130, 32))
    # 虹膜外圈
    ring = []
    for k in range(41):
        t = 2 * 3.14159265 * k / 40.0
        ring.append((cx + (r + 0.4) * __import__("math").cos(t), iy + (r + 0.4) * __import__("math").sin(t)))
    layer.stroke(ring, 1.4, (62, 40, 16))
    layer.disc(cx, iy, r * 0.40, r * 0.40, (54, 32, 14))
    layer.disc(cx - r * 0.40, iy - r * 0.30, r * 0.24, r * 0.24, (255, 255, 255))
    layer.disc(cx + r * 0.34, iy + r * 0.42, r * 0.11, r * 0.11, (255, 255, 255), 200)
    # 上眼线（含眼角外挑）
    path = []
    for k in range(29):
        t = 3.14159265 * (1 - 0.10) + (3.14159265 * (1 + 0.20)) * k / 28.0
        path.append((cx + rx * 0.99 * __import__("math").cos(t), cy + ry * 0.96 * __import__("math").sin(t)))
    layer.stroke(path, max(2.2, ry * 0.21), EYE_LASH)
    # 外眼角睫毛
    ex = cx + (rx * 0.99 if outer_right else -rx * 0.99)
    sx = 1.0 if outer_right else -1.0
    layer.stroke([(ex, cy + ry * 0.10), (ex + sx * rx * 0.22, cy - ry * 0.16),
                  (ex + sx * rx * 0.42, cy - ry * 0.46)], max(2.0, ry * 0.19), EYE_LASH, taper=0.55)

    # 下眼线 + 下睫毛
    low = []
    for k in range(19):
        t = 0.16 * 3.14159265 + (3.14159265 * 0.68) * k / 18.0
        low.append((cx + rx * 0.93 * __import__("math").cos(t), cy + ry * 0.90 * __import__("math").sin(t)))
    layer.stroke(low, max(1.2, ry * 0.085), EYE_LASH, alpha=190)
    for d in (0.42, 0.72):
        bx = cx + (rx * 0.55 + rx * 0.30 * d) * sx
        by = cy + ry * 0.62
        layer.stroke([(bx, by), (bx + sx * rx * 0.16, by + ry * 0.30)], max(1.2, ry * 0.10),
                     EYE_LASH, alpha=205, taper=0.5)
    # 双眼皮线
    lid = []
    for k in range(21):
        t = 3.14159265 * 1.22 + (3.14159265 * 0.56) * k / 20.0
        lid.append((cx + rx * 1.06 * __import__("math").cos(t), cy - ry * 0.30 + ry * 0.72 * __import__("math").sin(t)))
    layer.stroke(lid, 1.0, EYE_LASH, alpha=88)


def rebuild_eyes(im):
    comps = components(im)
    eyes = [c for c in comps if (c[3] - c[1]) > 12 and (c[4] - c[2]) > 12]
    eyes = sorted(eyes[:2], key=lambda c: c[1])
    if len(eyes) < 2:
        print("   !! 只认出", len(eyes), "个眼圈，跳过换眼")
        return im, 0
    for c in eyes:                                  # 擦掉旧眼
        for (x, y) in c[5]:
            i = (y * im.w + x) * 4
            im.px[i + 3] = 0
    layer = SS(im.w, im.h, 4)
    info = []
    for idx, c in enumerate(eyes):
        cx = (c[1] + c[3] + 1) / 2.0
        cy = (c[2] + c[4] + 1) / 2.0
        rx = (c[3] - c[1] + 1) / 2.0
        ry = (c[4] - c[2] + 1) / 2.0
        draw_eye(layer, cx, cy, rx, ry, outer_right=(idx == 1))
        info.append((round(cx, 1), round(cy, 1), round(rx, 1), round(ry, 1)))
    new = layer.resolve(im.w, im.h)
    for y in range(im.h):
        for x in range(im.w):
            a = new.px[(y * im.w + x) * 4 + 3]
            if a == 0:
                continue
            nx = pxl(new, x, y)
            ox = pxl(im, x, y)
            na = a + ox[3] * (255 - a) // 255
            if na:
                col = tuple((nx[k] * a + ox[k] * ox[3] * (255 - a) // 255) // na for k in range(3))
            else:
                col = nx[:3]
            pxset(im, x, y, tuple(col) + (na,))
    return im, info


def main():
    if os.path.exists(SRC) and not os.path.exists(DST):
        shutil.copytree(SRC, DST)
    if not os.path.exists(DST):
        shutil.copytree(SRC, DST)
    print("目标目录:", DST)
    n = 0
    for sym in sorted(os.listdir(DST)):
        d = os.path.join(DST, sym)
        if not os.path.isdir(d) or sym in ("参考图",):
            continue
        for fn in sorted(os.listdir(d)):
            if not fn.endswith(".png"):
                continue
            p = os.path.join(d, fn)
            im = read_png(p)
            im2 = recolor(im, sym)
            note = ""
            if sym == "face" and fn == "face-0.png":
                im2, info = rebuild_eyes(im2)
                note = " 换眼:" + str(info)
            write_png(p, im2)
            n += 1
    print("改装 PNG:", n, "张")
    print("写好 →", DST)


if __name__ == "__main__":
    main()
