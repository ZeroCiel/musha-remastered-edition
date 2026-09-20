# -*- coding: utf-8 -*-
"""
musha_cutout.py —— 把 AI 出的「平图」自动拆成透明底零件（纯 PIL，无需 numpy）

用途（用户 2026-09-21 的痛点：ChatGPT 不给分层图，只能截图后手动抠）：
  1) 去背   : 按底色（黑/白/洋红/自定义）把背景抠成透明
  2) 拆件   : 自动找连通块（每个元素一块）→ 每块导出一张透明 PNG + 一张拼版预览图
  3) 九宫格 : 面板底图按 9-slice 切开（左右/上下边框自动量）

用法：
  python musha_cutout.py 输入.png 输出目录 [--key auto|black|white|magenta|#RRGGBB]
         [--tol 36] [--min-area 400] [--pad 4] [--grid R C] [--nine]
  例：
  python musha_cutout.py clip.png out --key auto            # 自动去背 + 拆件
  python musha_cutout.py bookpage_bg.png out9 --nine        # 九宫格切面板
  python musha_cutout.py sheet.png out --grid 3 2           # 均匀切 3x2
"""
import os, sys, json, math
from PIL import Image

# ---------------- 参数 ----------------
args = sys.argv[1:]
if len(args) < 2:
    print(__doc__)
    sys.exit(1)
SRC, OUT = args[0], args[1]
opts = {"key": "auto", "tol": 36, "min_area": 400, "pad": 4, "grid": None, "nine": False}
i = 2
while i < len(args):
    a = args[i]
    if a == "--key":       opts["key"] = args[i + 1]; i += 2
    elif a == "--tol":     opts["tol"] = int(args[i + 1]); i += 2
    elif a == "--min-area":opts["min_area"] = int(args[i + 1]); i += 2
    elif a == "--pad":     opts["pad"] = int(args[i + 1]); i += 2
    elif a == "--grid":    opts["grid"] = (int(args[i + 1]), int(args[i + 2])); i += 3
    elif a == "--nine":    opts["nine"] = True; i += 1
    else: i += 1

os.makedirs(OUT, exist_ok=True)
im = Image.open(SRC).convert("RGBA")
W, H = im.size
px = im.load()
print("输入 %s  %dx%d" % (os.path.basename(SRC), W, H))

# ---------------- 1) 底色判定 ----------------
def corner_median():
    pts = []
    n = max(2, min(W, H) // 40)
    for (x0, y0) in [(0, 0), (W - n, 0), (0, H - n), (W - n, H - n)]:
        for x in range(x0, x0 + n):
            for y in range(y0, y0 + n):
                pts.append(px[x, y][:3])
    pts.sort(key=lambda c: c[0] + c[1] + c[2])
    return pts[len(pts) // 2]

NAMED = {"black": (0, 0, 0), "white": (255, 255, 255), "magenta": (255, 0, 255),
         "green": (0, 255, 0), "cyan": (0, 255, 255)}

key = opts["key"]
if key == "auto":
    key = corner_median()
    print("自动取底色 =", key, "（四角中位色）")
elif key in NAMED:
    key = NAMED[key]
elif key.startswith("#"):
    key = tuple(int(key[j:j + 2], 16) for j in (1, 3, 5))
else:
    key = tuple(int(v) for v in key.split(","))

kr, kg, kb = key
key_luma = 0.299 * kr + 0.587 * kg + 0.114 * kb
DARK_MODE = key_luma < 48                     # 底色很黑 → 用"亮度阈值"更稳（AI 图的黑底常有噪点）
tol = opts["tol"]

def alpha_of(c):
    r, g, b = c[0], c[1], c[2]
    if DARK_MODE:
        d = max(r, g, b)
    else:
        d = math.sqrt((r - kr) ** 2 + (g - kg) ** 2 + (b - kb) ** 2)
    if d <= tol: return 0
    if d >= tol * 2: return 255
    return int((d - tol) * 255 / tol)

# 生成透明图
out_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
op = out_img.load()
mask = bytearray(W * H)
for y in range(H):
    for x in range(W):
        a = alpha_of(px[x, y])
        if a > 0:
            r, g, b, _ = px[x, y]
            op[x, y] = (r, g, b, a)
            mask[y * W + x] = 1
ink = sum(mask)
print("去背后不透明像素 %d (%.1f%%)" % (ink, ink * 100.0 / (W * H)))

# ---------------- 2) 连通块（下采样加速） ----------------
def connected_pieces(k=4):
    gw, gh = max(1, W // k), max(1, H // k)
    grid = bytearray(gw * gh)
    for gy in range(gh):
        for gx in range(gw):
            hit = 0
            for y in range(gy * k, min(H, gy * k + k)):
                base = y * W
                for x in range(gx * k, min(W, gx * k + k)):
                    if mask[base + x]:
                        hit = 1; break
                if hit: break
            grid[gy * gw + gx] = hit
    labels = [-1] * (gw * gh)
    pieces = []
    for gy in range(gh):
        for gx in range(gw):
            idx = gy * gw + gx
            if grid[idx] == 0 or labels[idx] >= 0:
                continue
            lab = len(pieces)
            stack = [(gx, gy)]
            labels[idx] = lab
            minx = maxx = gx; miny = maxy = gy
            n = 0
            while stack:
                cx, cy = stack.pop(); n += 1
                if cx < minx: minx = cx
                if cx > maxx: maxx = cx
                if cy < miny: miny = cy
                if cy > maxy: maxy = cy
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < gw and 0 <= ny < gh:
                        ni = ny * gw + nx
                        if grid[ni] and labels[ni] < 0:
                            labels[ni] = lab
                            stack.append((nx, ny))
            pieces.append({"box": (minx * k, miny * k, min((maxx + 1) * k, W), min((maxy + 1) * k, H)), "cells": n})
    return pieces

if opts["grid"]:
    R, C = opts["grid"]
    pieces = []
    for r in range(R):
        for c in range(C):
            pieces.append({"box": (c * W // C, r * H // R, (c + 1) * W // C, (r + 1) * H // R), "cells": 0})
elif opts["nine"]:
    # 九宫格：按"每列/每行是否是边框带"自动定切点（纸面比边框亮）
    def col_dark(x):
        n = 0
        for y in range(0, H, 4):
            c = px[x, y]
            if 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2] < 200: n += 1
        return n / (H / 4.0)
    prof = [col_dark(x) for x in range(W)]
    left = next((x for x in range(W) if prof[x] < 0.15), 0)
    right = next((x for x in range(W - 1, -1, -1) if prof[x] < 0.15), W - 1)
    rowd = []
    for y in range(H):
        n = 0
        for x in range(0, W, 4):
            c = px[x, y]
            if 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2] < 200: n += 1
        rowd.append(n / (W / 4.0))
    top = next((y for y in range(H) if rowd[y] < 0.15), 0)
    bot = next((y for y in range(H - 1, -1, -1) if rowd[y] < 0.15), H - 1)
    print("九宫格切点：左 %d 右 %d 上 %d 下 %d" % (left, right, top, bot))
    xs = [0, left, right, W]; ys = [0, top, bot, H]
    names = ["tl", "t", "tr", "l", "c", "r", "bl", "b", "br"]
    pieces = []
    for r in range(3):
        for c in range(3):
            pieces.append({"box": (xs[c], ys[r], xs[c + 1], ys[r + 1]), "name": names[r * 3 + c], "cells": 0})
else:
    pieces = connected_pieces()
    pieces = [p for p in pieces if (p["box"][2] - p["box"][0]) * (p["box"][3] - p["box"][1]) >= opts["min_area"]]
    pieces.sort(key=lambda p: (p["box"][1], p["box"][0]))

# ---------------- 3) 导出 ----------------
pad = opts["pad"]
meta = []
for n, p in enumerate(pieces):
    x0, y0, x1, y1 = p["box"]
    x0 = max(0, x0 - pad); y0 = max(0, y0 - pad); x1 = min(W, x1 + pad); y1 = min(H, y1 + pad)
    piece = out_img.crop((x0, y0, x1, y1))
    bb = piece.getbbox()
    name = p.get("name") or ("piece_%02d" % n)
    if bb:                             # 再去掉四周全透明边
        piece = piece.crop(bb)
    fn = os.path.join(OUT, "%s.png" % name)
    piece.save(fn)
    meta.append({"file": os.path.basename(fn), "size": piece.size, "at": [x0, y0], "src_box": p["box"]})
    print("  → %s  %dx%d  在原图 (%d,%d)" % (os.path.basename(fn), piece.size[0], piece.size[1], x0, y0))

json.dump(meta, open(os.path.join(OUT, "pieces.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)

# 拼版预览（每个零件贴到网格里，好一眼看全）
if meta:
    cols = min(6, max(1, int(math.ceil(math.sqrt(len(meta))))))
    rows = int(math.ceil(len(meta) / float(cols)))
    cw = max(m["size"][0] for m in meta) + 20
    ch = max(m["size"][1] for m in meta) + 20
    sheet = Image.new("RGBA", (cols * cw, rows * ch), (60, 60, 66, 255))
    for n, m in enumerate(meta):
        pc = Image.open(os.path.join(OUT, m["file"])).convert("RGBA")
        sheet.paste(pc, ((n % cols) * cw + 10, (n // cols) * ch + 10), pc)
    sp = os.path.join(OUT, "00_contact.png")
    sheet.save(sp)
    print("拼版预览 → %s（%d 个零件）" % (sp, len(meta)))
print("完成，输出目录：%s" % os.path.abspath(OUT))
