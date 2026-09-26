#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""musha_skillbook（开面板的技能书）换新皮 + 补地面动画（2026-09-26）
1) 新图（豆包 AI，白底 1024²）→ 白底洪泛抠除 → 裁剪
2) 物品栏图标 64×64 → images/inventoryimages/musha_skillbook.png → png.exe → tex/xml
3) 地面动画：世界图 128×128 → exported/musha_skillbook/（scml 房规：build/bank
   = musha_skillbook，anim = idle，pivot 0.5/0.5）→ scml.exe 编译 anim zip
   （prefab 已 SetBank/SetBuild/PlayAnimation("idle")，之前缺 zip 所以地上隐形）
"""
import os
import subprocess
from collections import deque
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.normpath(os.path.join(HERE, "..", ".."))
SRC = r"C:\Users\Administrator\.zcode\cli\image-cache\sess_fa2bfaa7-01a7-4997-83a5-262118e76067\image-e4e3c75b1b53d52361524fc543fae6e3.png"
OUTDIR = os.path.join(MOD, "exported", "musha_skillbook")
INV = os.path.join(MOD, "images", "inventoryimages")
SCML_EXE = r"D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools\mod_tools\scml.exe"
PNG_EXE = r"D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools\mod_tools\png.exe"
BUILD = "musha_skillbook"

os.makedirs(OUTDIR, exist_ok=True)

im = Image.open(SRC).convert("RGBA")
W, H = im.size
px = im.load()


def whiteish(c):
    r, g, b, a = c
    return a > 0 and min(r, g, b) > 238 and (max(r, g, b) - min(r, g, b)) < 18


# ── 1) 边框洪泛去白底 ──
keyed = bytearray(W * H)
q = deque()
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
print("白底洪泛完成")

# ── 2) 水印角清除（豆包 AI 右下角）+ 裁剪 ──
for y in range(950, H):
    for x in range(820, W):
        px[x, y] = (0, 0, 0, 0)
a = im.getchannel("A")
bbox = a.point(lambda v: 255 if v > 8 else 0).getbbox()
print("内容 bbox:", bbox)
book = im.crop(bbox)
bw, bh = book.size
print("透明书:", bw, "x", bh)

# ── 3) 物品栏图标 64×64 ──
F = min(60.0 / bw, 60.0 / bh)
iw, ih = max(1, round(bw * F)), max(1, round(bh * F))
pm = book.copy(); pp = pm.load()
for y in range(bh):
    for x in range(bw):
        r, g, b, a2 = pp[x, y]
        if a2 < 255:
            pp[x, y] = (r * a2 // 255, g * a2 // 255, b * a2 // 255, a2)
ic = pm.resize((iw, ih), Image.LANCZOS)
ip = ic.load()
for y in range(ih):
    for x in range(iw):
        r, g, b, a2 = ip[x, y]
        if 0 < a2 < 255:
            ip[x, y] = (min(255, r * 255 // a2), min(255, g * 255 // a2), min(255, b * 255 // a2), a2)
icon = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
icon.paste(ic, ((64 - iw) // 2, (64 - ih) // 2), ic)
icon_png = os.path.join(INV, BUILD + ".png")
icon.save(icon_png)
print("图标 64x64（内容 %dx%d 居中）" % (iw, ih))

# ── 4) 世界图 128×128 ──
F2 = min(120.0 / bw, 120.0 / bh)
ww, wh = max(1, round(bw * F2)), max(1, round(bh * F2))
pm2 = book.copy(); p2 = pm2.load()
for y in range(bh):
    for x in range(bw):
        r, g, b, a2 = p2[x, y]
        if a2 < 255:
            p2[x, y] = (r * a2 // 255, g * a2 // 255, b * a2 // 255, a2)
world = pm2.resize((ww, wh), Image.LANCZOS)
wp2 = world.load()
for y in range(wh):
    for x in range(ww):
        r, g, b, a2 = wp2[x, y]
        if 0 < a2 < 255:
            wp2[x, y] = (min(255, r * 255 // a2), min(255, g * 255 // a2), min(255, b * 255 // a2), a2)
wimg = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
wimg.paste(world, ((128 - ww) // 2, (128 - wh) // 2), world)
world_png = os.path.join(OUTDIR, BUILD + "-0.png")
wimg.save(world_png)
print("世界图 128x128（内容 %dx%d 居中）" % (ww, wh))

# ── 5) scml（房规）──
scml = os.path.join(OUTDIR, BUILD + ".scml")
open(scml, "w", encoding="utf-8", newline="\n").write(f'''<?xml version="1.0" encoding="UTF-8"?>
<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="b5">
	<folder id="0" name="{BUILD}">
		<file id="0" name="{BUILD}-0.png" width="128" height="128" pivot_x="0.5" pivot_y="0.5" />
	</folder>
	<entity id="0" name="{BUILD}">
		<animation id="0" name="idle" length="1000" interval="100">
			<mainline>
				<key id="0">
					<object_ref id="0" timeline="0" key="0" z_index="0" />
				</key>
			</mainline>
			<timeline id="0" name="{BUILD}">
				<key id="0" spin="0">
					<object folder="0" file="0" x="0" y="0" />
				</key>
			</timeline>
		</animation>
	</entity>
</spriter_data>
''')
print("scml 完成")

# ── 6) 编译 anim zip + 图标 tex ──
r = subprocess.run([SCML_EXE, BUILD + ".scml", os.path.normpath(os.path.join(HERE, "..", ".."))],
                   cwd=OUTDIR, capture_output=True, text=True, errors="replace")
print((r.stdout or "").strip()[-80:])
zpath = os.path.join(MOD, "anim", BUILD + ".zip")
print("anim zip:", os.path.exists(zpath), os.path.getsize(zpath) if os.path.exists(zpath) else 0, "B")
r2 = subprocess.run([PNG_EXE, BUILD + ".png", BUILD + ".tex"], cwd=INV,
                    capture_output=True, text=True, errors="replace")
print("png.exe exit=", r2.returncode)
