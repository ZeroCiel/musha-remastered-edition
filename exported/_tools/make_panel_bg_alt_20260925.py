#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""panel_bg 变体处理 v2（源图 2496x1664 全不透明白底）
1) 白洪泛（min>228, spread<26）：从图边框清白底+浅影
2) 灰洪泛（spread<24, min>195）：从图边框清灰色水印/阴影核心——面板内白花瓣
   被描边包围、不可达，安全；彩色装饰非灰，保留
3) 实心 bbox（alpha>0）外扩 36px 裁剪 → images/panel_bg_alt.png
"""
import os
from collections import deque
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = r"C:\Users\Administrator\.zcode\cli\image-cache\sess_fa2bfaa7-01a7-4997-83a5-262118e76067\image-41e5474f4f07c28c9b3fe1a1378a81a6.png"
DST = os.path.join(HERE, "..", "..", "images", "panel_bg_alt.png")
PREVIEW = r"C:\Users\Administrator\.zcode\workspace\default\_panel_alt_preview.png"

im = Image.open(SRC).convert("RGBA")
W, H = im.size
print("源图", W, "x", H)
px = im.load()


def whiteish(c):
    r, g, b, a = c
    return a > 0 and min(r, g, b) > 228 and (max(r, g, b) - min(r, g, b)) < 26


def grayish(c):
    r, g, b, a = c
    return a > 0 and min(r, g, b) > 195 and (max(r, g, b) - min(r, g, b)) < 24


# ── 1) 白洪泛 ──
q = deque()
for x in range(W):
    for y in (0, H - 1):
        if whiteish(px[x, y]): q.append((x, y))
for y in range(H):
    for x in (0, W - 1):
        if whiteish(px[x, y]): q.append((x, y))
seen = bytearray(W * H)
for x, y in q: seen[y * W + x] = 1
while q:
    x, y = q.popleft()
    px[x, y] = (0, 0, 0, 0)
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < W and 0 <= ny < H and not seen[ny * W + nx] and whiteish(px[nx, ny]):
            seen[ny * W + nx] = 1; q.append((nx, ny))
print("白洪泛完成")

# ── 2) 灰洪泛（水印/阴影核心）──
q = deque()
for x in range(W):
    for y in (0, H - 1):
        if grayish(px[x, y]): q.append((x, y))
for y in range(H):
    for x in (0, W - 1):
        if grayish(px[x, y]): q.append((x, y))
seen2 = bytearray(W * H)
for x, y in q: seen2[y * W + x] = 1
n = 0
while q:
    x, y = q.popleft()
    px[x, y] = (0, 0, 0, 0); n += 1
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < W and 0 <= ny < H and not seen2[ny * W + nx] and grayish(px[nx, ny]):
            seen2[ny * W + nx] = 1; q.append((nx, ny))
print("灰洪泛清除 %d px（水印/阴影）" % n)

# ── 3) bbox + 裁剪 ──
sx0, sy0, sx1, sy1 = W, H, -1, -1
for y in range(H):
    for x in range(W):
        if px[x, y][3] > 0:
            if x < sx0: sx0 = x
            if x > sx1: sx1 = x
            if y < sy0: sy0 = y
            if y > sy1: sy1 = y
M = 36
cx0, cy0 = max(0, sx0 - M), max(0, sy0 - M)
cx1, cy1 = min(W - 1, sx1 + M), min(H - 1, sy1 + M)
print("内容 bbox=(%d,%d)-(%d,%d)  裁剪=(%d,%d)-(%d,%d)" % (sx0, sy0, sx1, sy1, cx0, cy0, cx1, cy1))
out = im.crop((cx0, cy0, cx1 + 1, cy1 + 1))
out.save(DST)
print("输出", DST, out.size)

bg = Image.new("RGBA", out.size, (45, 45, 52, 255)); bg.alpha_composite(out)
pv = bg.resize((out.width // 3, out.height // 3), Image.LANCZOS)
pv.save(PREVIEW)
print("预览 →", PREVIEW)
