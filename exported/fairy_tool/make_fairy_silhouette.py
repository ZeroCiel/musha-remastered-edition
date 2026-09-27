# -*- coding: utf-8 -*-
"""
元素精灵（精灵伙伴）剪影光点表生成器 —— 纯标准库，不需要任何第三方库。

干什么用：
  「粒子汇聚成精灵」的出场动画里，每颗光点要飞到一个固定落点，
  这些落点拼出来就是精灵的剪影（圆头 + 薄翼 + 光尾）。
  本脚本负责把这张剪影变成 36 个坐标点，写进
  scripts/musha_fairy_silhouette.lua，并输出一张预览图
  exported/fairy_tool/preview_fairy.png（点阵效果，游戏内观感参考）。

想改精灵的样子（头更大 / 翼更宽 / 尾更长）：
  改下面 SHAPES 里的形状参数，重跑一次本脚本即可（lua 表和预览图都会重新生成）。
  改完把 scripts/musha_fairy_silhouette.lua 一起提交。

坐标系约定（和游戏一致）：
  - 原点 (0,0) = 精灵的「本体锚点」（游戏里 Transform 的位置，漂浮在离地约 0.8 格）
  - y 向上为正，单位 = 游戏世界单位（1 单位 ≈ 1 格）
  - 光尾最低点约 -0.25（离地还有 0.55 格，不会拖地）
"""

import math
import os
import struct
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))      # musha mod 根目录
LUA_OUT = os.path.join(ROOT, "scripts", "musha_fairy_silhouette.lua")
PREVIEW_OUT = os.path.join(HERE, "preview_fairy.png")

GRID = 240               # 采样网格分辨率

# ---------------------------------------------------------------------------
# 剪影部件（全部是椭圆，参数 = 中心(x, y) / 半径(rx, ry) / 旋转角(度，正=逆时针)）
# 对称部件（wing）只写一半，代码自动镜像；count 是两侧合计。
# ---------------------------------------------------------------------------
SHAPES = [
    # name          cx     cy     rx     ry    rot   count  scale
    ("head",       0.00,  0.86,  0.235, 0.215,  0,    12,   1.20),
    ("wing",      -0.33,  0.72,  0.235, 0.085, 34,    10,   0.95),
    ("body",       0.00,  0.52,  0.145, 0.20,   0,     8,   1.05),
    ("tail",       0.06,  0.06,  0.075, 0.28, -14,     6,   0.85),
]


def _divisors(n):
    return [d for d in range(1, n + 1) if n % d == 0]


def _grid_split(n):
    """把 n 拆成尽量接近正方形的 nx×ny（nx >= ny）"""
    best = (1, n)
    for d in _divisors(n):
        a, b = n // d, d
        if abs(a - b) < abs(best[0] - best[1]):
            best = (a, b)
    return max(best), min(best)


def to_world(lx, ly, cx, cy, rot, mirror=False):
    """椭圆局部坐标 → 世界坐标（镜像 = 整个形状按 x 翻转）"""
    a = math.radians(rot)
    wx = lx * math.cos(a) - ly * math.sin(a) + cx
    wy = lx * math.sin(a) + ly * math.cos(a) + cy
    if mirror:
        wx = -wx
    return wx, wy


def in_shape(px, py, cx, cy, rx, ry, rot, mirror=False):
    """世界点是否在部件内；mirror 时先把点按 x 翻转再按原形状判"""
    if mirror:
        px = -px
    a = math.radians(-rot)
    dx, dy = px - cx, py - cy
    ux = dx * math.cos(a) - dy * math.sin(a)
    uy = dx * math.sin(a) + dy * math.cos(a)
    return (ux / rx) ** 2 + (uy / ry) ** 2


def sample_points():
    """轮廓优先的采样：外圈沿形状边缘、内部稀疏、尾巴是一条连续曲线。
    36 点 = 头 12（外圈8+内圈4）/ 翼 10（每侧5 沿长轴）/ 身 8（外圈6+内2）/ 尾 6（沿弧线）"""
    import random as _r
    _r.seed(7)                                    # 固定种子：每次重跑结果一致（可提交、可复现）
    out = []

    def add(part, x, y, s, jx=0.018, jy=0.018):
        out.append({"part": part, "x": round(x + _r.uniform(-jx, jx), 3),
                    "y": round(y + _r.uniform(-jy, jy), 3),
                    "s": round(s * _r.uniform(0.92, 1.08), 2)})

    # 头：外圈 9（沿椭圆边缘，圆感）+ 内圈 3（错开）
    hx, hy, hrx, hry = 0.0, 0.86, 0.225, 0.205
    for i in range(9):
        t = math.radians(i * 40)
        add("head", hx + hrx * math.cos(t), hy + hry * math.sin(t), 1.22)
    for i in range(3):
        t = math.radians(i * 120 + 20)
        add("head", hx + hrx * 0.45 * math.cos(t), hy + hry * 0.45 * math.sin(t), 1.0)

    # 翼：每侧 5 点沿翼长轴（根部→翼尖），带一点弧度
    wcx, wcy, wrx, wry, wrot = -0.26, 0.70, 0.28, 0.07, 144
    a = math.radians(wrot)
    for side in (1, -1):
        for i, t in enumerate((-0.92, -0.48, -0.04, 0.40, 0.84)):
            lx = wrx * t
            ly = wry * math.sin(t * 2.2) * 0.55          # 翼面微弧
            wx0 = lx * math.cos(a) - ly * math.sin(a) + wcx
            wy0 = lx * math.sin(a) + ly * math.cos(a) + wcy
            add("wing", wx0 if side == 1 else -wx0, wy0, 0.92, 0.012, 0.012)

    # 身：外圈 6（沿椭圆边缘）+ 内部 2
    bx, by, brx, bry = 0.0, 0.50, 0.15, 0.19
    for i in range(6):
        t = math.radians(i * 60 + 90)
        add("body", bx + brx * math.cos(t), by + bry * math.sin(t), 1.06)
    add("body", bx, by + bry * 0.35, 0.95, 0.01, 0.01)
    add("body", bx, by - bry * 0.35, 0.95, 0.01, 0.01)

    # 尾：向右下飘逸的一条弧（从身体下方 → 右下），6 点
    for i in range(6):
        u = i / 5.0
        tx = 0.02 + 0.26 * u + 0.05 * math.sin(u * 4.0)
        ty = 0.27 - 0.55 * u - 0.04 * math.sin(u * 4.0)
        add("tail", tx, ty, 0.86 - u * 0.1, 0.012, 0.012)

    return out


def write_min_png(path, w, h, rows):
    def chunk(tag, data):
        c = tag + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)
    raw = b"".join(b"\x00" + bytes(r) for r in rows)
    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw, 6))
           + chunk(b"IEND", b""))
    with open(path, "wb") as f:
        f.write(png)


def write_preview(points):
    """点阵预览图：黑底 + 青白光点 + 地面参考线，模拟游戏内的粒子剪影"""
    scale = 210                                    # 1 世界单位 = 210 px
    W, H = 400, 620
    ox, oy = W // 2, H - 160                       # 精灵原点（离地 0.7 格）
    ground_y = oy + int(0.7 * scale)
    rows = [bytearray([22, 24, 32]) * W for _ in range(H)]
    for x in range(0, W, 2):                       # 地面参考线
        rows[ground_y][x * 3] = 52
        rows[ground_y][x * 3 + 1] = 58
        rows[ground_y][x * 3 + 2] = 70
        rows[ground_y + 1][x * 3] = 40
        rows[ground_y + 1][x * 3 + 1] = 44
        rows[ground_y + 1][x * 3 + 2] = 56
    for p in points:
        cx = int(ox + p["x"] * scale)
        cy = int(oy - p["y"] * scale)              # png y 向下
        r = max(2, int(1.6 + p["s"] * 2.2))
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                d2 = dx * dx + dy * dy
                if d2 > r * r:
                    continue
                x, y = cx + dx, cy + dy
                if not (0 <= x < W and 0 <= y < H):
                    continue
                t = 1.0 - (d2 / (r * r)) ** 0.5
                base = (150, 225, 255) if p["part"] != "tail" else (120, 200, 245)
                for ch in range(3):
                    v = int(base[ch] * (0.55 + 0.45 * t))
                    i = (y * W + x) * 3 + ch
                    rows[i // (W * 3)][i % (W * 3)] = max(rows[i // (W * 3)][i % (W * 3)], v)
    write_min_png(PREVIEW_OUT, W, H, [bytes(r) for r in rows])
    print("预览图已写出:", PREVIEW_OUT)


def main():
    pts = sample_points()
    print("部件采样:", {n: sum(1 for p in pts if p["part"] == n) for n in ("head", "wing", "body", "tail")})
    assert len(pts) == 36, "应为 36 点（当前 %d）" % len(pts)
    assert len({(p["x"], p["y"]) for p in pts}) == len(pts), "点位重复"
    ys = [p["y"] for p in pts]
    print("y 范围: %.2f ~ %.2f（0 = 本体锚点，离地 0.7 格）" % (min(ys), max(ys)))

    lines = []
    lines.append("-- ============================================================")
    lines.append("-- 元素精灵（精灵伙伴）剪影光点落点表 —— 由 exported/fairy_tool/make_fairy_silhouette.py 生成")
    lines.append("--")
    lines.append("--   「粒子汇聚成精灵」的出场动画：每颗光点从四周飞到本表中的一个落点，")
    lines.append("--   全部到位后拼出精灵剪影（圆头 + 薄翼 + 光尾）并常驻漂浮。")
    lines.append("--")
    lines.append("--   坐标系：原点 = 精灵本体锚点（漂浮在离地约 0.7 格），y 向上，单位 = 世界单位")
    lines.append("--   x, y = 落点；s = 这颗光点的相对大小（粒子 scale 乘数）")
    lines.append("--   想改精灵样子：改 exported/fairy_tool/make_fairy_silhouette.py 的 SHAPES 重跑。")
    lines.append("-- ============================================================")
    lines.append("")
    lines.append("local POINTS = {")
    for p in pts:
        lines.append('    { x = %6.3f, y = %6.3f, s = %4.2f },   -- %s'
                     % (p["x"], p["y"], p["s"], p["part"]))
    lines.append("}")
    lines.append("")
    lines.append("return {")
    lines.append("    points = POINTS,")
    lines.append("    total  = %d," % len(pts))
    lines.append("    -- 精灵整体尺寸（世界单位）与本体锚点离地高度")
    lines.append("    height = 1.2,")
    lines.append("    width  = 1.2,")
    lines.append("    anchor_height = 0.7,")
    lines.append("}")
    lines.append("")
    with open(LUA_OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print("lua 表已写出:", LUA_OUT, "（%d 点）" % len(pts))
    write_preview(pts)


if __name__ == "__main__":
    main()
