#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""musha_skillbook 地面动画改平放版（2026-09-26，用户草图口径）
封面立视图 → 透视压扁 + 轻旋 → 平放，加书页侧面（2.5D 厚度）→ 重编 anim
图标（64² 立绘封面）不动——物品栏本来就该显示封面。
"""
import os
import subprocess
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.normpath(os.path.join(HERE, "..", ".."))
SRC = r"C:\Users\Administrator\.zcode\cli\image-cache\sess_fa2bfaa7-01a7-4997-83a5-262118e76067\image-e4e3c75b1b53d52361524fc543fae6e3.png"
OUTDIR = os.path.join(MOD, "exported", "musha_skillbook")
INV = os.path.join(MOD, "images", "inventoryimages")
SCML_EXE = r"D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools\mod_tools\scml.exe"
BUILD = "musha_skillbook"

# ── 1) 重新得到透明立绘（白底洪泛 + 水印角清除 + 裁剪，同 make_skillbook）──
im = Image.open(SRC).convert("RGBA")
W, H = im.size
px = im.load()


def whiteish(c):
    r, g, b, a = c
    return a > 0 and min(r, g, b) > 238 and (max(r, g, b) - min(r, g, b)) < 18


keyed = bytearray(W * H)
q = deque = __import__("collections").deque()
for x in range(W):
    for y in (0, H - 1):
        if whiteish(px[x, y]) and not keyed[y * W + x]:
            keyed[y * W + x] = 1; q.append((x, y))
for y in range(H):
    for x in (0, W - 1):
        if whiteish(px[x, y]) and not keyed[y * W + x]:
            keyed[y * W + x] = 1; q.append((x, y))
while q:
    x, y = q.popleft()
    px[x, y] = (0, 0, 0, 0)
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < W and 0 <= ny < H and not keyed[ny * W + nx] and whiteish(px[nx, ny]):
            keyed[ny * W + nx] = 1; q.append((nx, ny))
for y in range(950, H):
    for x in range(820, W):
        px[x, y] = (0, 0, 0, 0)
a = im.getchannel("A")
bbox = a.point(lambda v: 255 if v > 8 else 0).getbbox()
book = im.crop(bbox)
bw, bh = book.size
print("透明立绘:", bw, "x", bh)

# ── 2) 平放变换：纵向压扁 ×0.42 → 顺旋 8° ──
flat = book.resize((bw, max(1, round(bh * 0.42))), Image.LANCZOS)
flat = flat.rotate(-8, expand=True, resample=Image.BICUBIC)
fw, fh = flat.size
print("压扁+旋转:", fw, "x", fh)

# ── 3) 书页侧面（2.5D 厚度）：轮廓向下挤出 6px 的纸色底层 ──
BASE = Image.new("RGBA", (fw + 8, fh + 8), (0, 0, 0, 0))
mask = flat.getchannel("A").point(lambda v: 255 if v > 10 else 0)
# 底层 = 轮廓下移 6px（用形变的掩膜）
base_mask = Image.new("L", (fw, fh), 0)
bp = base_mask.load(); mp = mask.load()
for y in range(fh):
    for x in range(fw):
        if mp[x, y] > 10:
            yy = min(fh - 1, y + 6)
            bp[x, yy] = 255
base_mask = base_mask.filter(ImageFilter.MaxFilter(3))
base_col = Image.new("RGBA", (fw, fh), (232, 224, 200, 255))   # 纸色
base_col.putalpha(base_mask)
BASE.paste(base_col, (4, 6), base_col)
BASE.alpha_composite(flat, (4, 0))
# 描边（dilate 底层轮廓）
edge_src = BASE.getchannel("A").filter(ImageFilter.MaxFilter(3))
edge = Image.new("RGBA", BASE.size, (0, 0, 0, 0))
ep, sp, ap2 = edge.load(), edge_src.load(), BASE.getchannel("A").load()
for y in range(BASE.height):
    for x in range(BASE.width):
        if sp[x, y] > 10 and ap2[x, y] == 0:
            ep[x, y] = (58, 46, 46, 255)
edge = edge.filter(ImageFilter.GaussianBlur(0.5))
out = Image.new("RGBA", BASE.size, (0, 0, 0, 0))
out.alpha_composite(edge)
out.alpha_composite(BASE)

# ── 4) 装进 128² 世界画布 ──
ow, oh = out.size
F = min(122.0 / ow, 122.0 / oh)
ww, wh = max(1, round(ow * F)), max(1, round(oh * F))
world = out.resize((ww, wh), Image.LANCZOS)
wimg = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
wimg.paste(world, ((128 - ww) // 2, (128 - wh) // 2), world)
world_png = os.path.join(OUTDIR, BUILD + "-0.png")
wimg.save(world_png)
print("平放世界图 128²（内容 %dx%d 居中）" % (ww, wh))

# ── 5) 重编 anim zip ──
r = subprocess.run([SCML_EXE, BUILD + ".scml", os.path.normpath(os.path.join(HERE, "..", ".."))],
                   cwd=OUTDIR, capture_output=True, text=True, errors="replace")
zpath = os.path.join(MOD, "anim", BUILD + ".zip")
print("anim zip:", os.path.getsize(zpath), "B")
