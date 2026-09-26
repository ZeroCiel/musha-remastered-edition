#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""panel_bg_alt 残留清理：连通域分析——灰色成分（阴影断线/即梦AI水印）删除，
彩色成分（面板/星星/招牌/兔铃铛）保留；然后按 alpha bbox+36 重新裁剪。"""
import os
from collections import deque
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
P = os.path.join(HERE, "..", "..", "images", "panel_bg_alt.png")
im = Image.open(P).convert("RGBA")
W, H = im.size
px = im.load()

visited = bytearray(W * H)
comps = []
for y0 in range(H):
    for x0 in range(W):
        k0 = y0 * W + x0
        if visited[k0] or px[x0, y0][3] == 0:
            continue
        comp = []
        visited[k0] = 1
        q = deque([(x0, y0)])
        while q:
            x, y = q.popleft()
            comp.append((x, y))
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                k = ny * W + nx
                if 0 <= nx < W and 0 <= ny < H and not visited[k] and px[nx, ny][3] > 0:
                    visited[k] = 1
                    q.append((nx, ny))
        comps.append(comp)
print("连通域 %d 个" % len(comps))

removed = kept = 0
for comp in comps:
    xs = [p[0] for p in comp]; ys = [p[1] for p in comp]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    spread = sum((max(px[x, y][:3]) - min(px[x, y][:3])) for x, y in comp) / len(comp)
    gray = spread < 26
    in_logo_zone = x0 > 1850 and y0 > 1380
    in_badge_zone = x1 < 320 and y1 < 180
    if gray or in_logo_zone or in_badge_zone:
        for x, y in comp:
            px[x, y] = (0, 0, 0, 0)
        removed += 1
        print("  删除成分: bbox=(%d,%d)-(%d,%d) %dpx 平均spread=%.0f" % (x0, y0, x1, y1, len(comp), spread))
    else:
        kept += 1
        print("  保留成分: bbox=(%d,%d)-(%d,%d) %dpx 平均spread=%.0f" % (x0, y0, x1, y1, len(comp), spread))
print("删除 %d / 保留 %d" % (removed, kept))

# 重裁剪
sx0, sy0, sx1, sy1 = W, H, -1, -1
for y in range(H):
    for x in range(W):
        if px[x, y][3] > 0:
            if x < sx0: sx0 = x
            if x > sx1: sx1 = x
            if y < sy0: sy0 = y
            if y > sy1: sy1 = y
M = 36
out = im.crop((max(0, sx0 - M), max(0, sy0 - M), min(W, sx1 + M + 1), min(H, sy1 + M + 1)))
out.save(P)
print("重裁剪 →", out.size)

bg = Image.new("RGBA", out.size, (45, 45, 52, 255)); bg.alpha_composite(out)
pv = bg.resize((out.width // 3, out.height // 3), Image.LANCZOS)
pv.save(r"C:\Users\Administrator\.zcode\workspace\default\_panel_alt_preview2.png")
print("预览已存")
