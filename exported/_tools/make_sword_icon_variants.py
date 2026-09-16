# -*- coding: utf-8 -*-
"""剑图标 角度/朝向 候选对照（2026-09-16 用户：「倾斜只是对于一般的平面游戏来说，在这里可能要动下脑子」）
产出：exported/musha_sword_v2/icon_variants_20260916.png（对照图，4x）+ icon_v<角度>.png（64x64 实际尺寸）
"""
import sys, math, os
TOOLS = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\exported\_tools"
sys.path.insert(0, TOOLS)
from pnglib import Image, read_png, write_png, blit, contact_sheet

OUT = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\exported\musha_sword_v2"
SRC = os.path.join(OUT, "musha_sword.png")
CUR = os.path.join(OUT, "icon_musha_sword_64.png")

src = read_png(SRC)
# 1) 实体 bbox（带 4px 余量）
xs, ys = [], []
for y in range(src.h):
    for x in range(src.w):
        if src.px[(y * src.w + x) * 4 + 3] > 40:
            xs.append(x); ys.append(y)
x0, x1, y0, y1 = min(xs) - 4, max(xs) + 4, min(ys) - 4, max(ys) + 4
cw, ch = x1 - x0 + 1, y1 - y0 + 1
print("源图实体（含余量）%dx%d @(%d,%d)" % (cw, ch, x0, y0))

def sample(px, py):
    """把裁剪区按双线性插值采样成 (r,g,b,a)"""
    ix, iy = int(math.floor(px)), int(math.floor(py))
    fx, fy = px - ix, py - iy
    out = [0.0, 0.0, 0.0, 0.0]
    for dy in (0, 1):
        for dx in (0, 1):
            sx, sy = ix + dx, iy + dy
            w = (fx if dx else 1 - fx) * (fy if dy else 1 - fy)
            if 0 <= sx < cw and 0 <= sy < ch:
                i = ((y0 + sy) * src.w + (x0 + sx)) * 4
                for k in range(4):
                    out[k] += src.px[i + k] * w
    return tuple(int(v + 0.5) for v in out)

def render_icon(angle_deg, size=64, ss=4, fill=0.88):
    """把剑按 angle_deg（从竖直算起，正数=剑尖往右倒）旋转后填进 size x size"""
    N = size * ss
    th = math.radians(angle_deg)
    cos, sin = math.cos(th), math.sin(th)
    cx, cy = (cw - 1) / 2.0, (ch - 1) / 2.0
    # 旋转后的包围盒 → 定缩放
    pts = [(x, y) for x in (-cx, cw - 1 - cx) for y in (-cy, ch - 1 - cy)]
    rw = max(abs(x * cos - y * sin) for x, y in pts) * 2
    rh = max(abs(x * sin + y * cos) for x, y in pts) * 2
    scale = (N * fill) / max(rw, rh, 1e-6)
    img = Image(size, size)
    for dy in range(size):
        for dx in range(size):
            r = g = b = a = 0
            for j in range(ss):
                for i in range(ss):
                    px = (dx * ss + i + 0.5) - N / 2.0
                    py = (dy * ss + j + 0.5) - N / 2.0
                    # 逆旋转回裁剪图坐标
                    ux = (px * cos + py * sin) / scale + cx
                    uy = (-px * sin + py * cos) / scale + cy
                    c = sample(ux, uy) if (0 <= ux < cw and 0 <= uy < ch) else (0, 0, 0, 0)
                    r += c[0]; g += c[1]; b += c[2]; a += c[3]
            k = ss * ss
            img.put(dx, dy, (r // k, g // k, b // k, a // k))
    return img

def upscale4(icon):
    big = Image(icon.w * 4, icon.h * 4)
    for y in range(icon.h):
        for x in range(icon.w):
            c = icon.get(x, y)
            for j in range(4):
                for i in range(4):
                    big.put(x * 4 + i, y * 4 + j, c)
    return big

variants = [(0, "竖直 0°"), (20, "右倒 20°"), (35, "右倒 35°"), (50, "右倒 50°"),
            (-20, "左倒 20°"), (-35, "左倒 35°")]
rows = [("current", [upscale4(read_png(CUR))])]
print("\n行序（对照图从上到下）：第1行=现在的图标，之后依次 " + " / ".join("%d°" % a for a, _ in variants))
for ang, label in variants:
    icon = render_icon(ang)
    icon_path = os.path.join(OUT, "icon_v%+03d.png" % ang)
    write_png(icon_path, icon)
    rows.append((label, [upscale4(icon)]))
    # 自检：ASCII 轮廓（32 宽）
    print("\n--- %s ---" % label)
    for gy in range(0, 64, 2):
        line = ""
        for gx in range(0, 64, 2):
            a = icon.get(gx, gy)[3]
            line += " " if a < 40 else ("." if a < 150 else "#")
        print("   " + line)

sheet = os.path.join(OUT, "icon_variants_20260916.png")
contact_sheet(rows, sheet)
print("\n对照图：%s" % sheet)
