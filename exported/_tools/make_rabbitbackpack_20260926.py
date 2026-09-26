#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""兔子背包资产管线（2026-09-26）
源：图片/兔子背包/ 四视图（1024² 白底）→ 去白底（已完成，_透明版）
出：
  · swap 件：exported/musha_rabbitbackpack/swap_body-0.png（背面视图 ~152 高，上背贴图）
  · 地面图：exported/musha_rabbitbackpack/musha_rabbitbackpack-0.png（正面 128²）
  · 编译：anim/musha_rabbitbackpack.zip（build/bank = musha_rabbitbackpack，
    符号 = musha_rabbitbackpack(地面) + swap_body(上背)，anim = idle）
  · 图标：images/inventoryimages/musha_rabbitbackpack.png 64² → png.exe → tex/xml
"""
import os
import subprocess
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.normpath(os.path.join(HERE, "..", ".."))
VIEWS = os.path.join(MOD, "图片", "兔子背包")
OUTDIR = os.path.join(MOD, "exported", "musha_rabbitbackpack")
INV = os.path.join(MOD, "images", "inventoryimages")
SCML_EXE = r"D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools\mod_tools\scml.exe"
PNG_EXE = r"D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools\mod_tools\png.exe"
BUILD = "musha_rabbitbackpack"

os.makedirs(OUTDIR, exist_ok=True)


def load_transposed(name):
    p = os.path.join(VIEWS, name)
    im = Image.open(p).convert("RGBA")
    vis = im.getchannel("A").point(lambda v: 255 if v > 8 else 0)
    bb = vis.getbbox()
    return im.crop(bb)


def premul_resize(im, tw, th):
    pm = im.copy(); pp = pm.load()
    w, h = pm.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pp[x, y]
            if a < 255:
                pp[x, y] = (r * a // 255, g * a // 255, b * a // 255, a)
    small = pm.resize((tw, th), Image.LANCZOS)
    sp = small.load()
    for y in range(th):
        for x in range(tw):
            r, g, b, a = sp[x, y]
            if 0 < a < 255:
                sp[x, y] = (min(255, r * 255 // a), min(255, g * 255 // a), min(255, b * 255 // a), a)
    return small


# ── 1) swap 件：背面视图 → ~152 高 ──
back = load_transposed("兔子背包-背面_透明.png")
bw, bh = back.size
f = 152.0 / bh
swap = premul_resize(back, max(1, round(bw * f)), 152)
swap_png = os.path.join(OUTDIR, "swap_body-0.png")
swap.save(swap_png)
print("swap 件 %dx%d → %s" % (swap.width, swap.height, swap_png))

# ── 2) 地面图：正面视图 → 128²（fit 120）──
front = load_transposed("兔子背包-正面_透明.png")
fw, fh = front.size
F = min(120.0 / fw, 120.0 / fh)
gw, gh = max(1, round(fw * F)), max(1, round(fh * F))
ground = premul_resize(front, gw, gh)
gimg = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
gimg.paste(ground, ((128 - gw) // 2, (128 - gh) // 2), ground)
ground_png = os.path.join(OUTDIR, BUILD + "-0.png")
gimg.save(ground_png)
print("地面图 128²（内容 %dx%d 居中）" % (gw, gh))

# ── 3) scml（房规；folder 名 = 符号名）──
scml = os.path.join(OUTDIR, BUILD + ".scml")
open(scml, "w", encoding="utf-8", newline="\n").write(f'''<?xml version="1.0" encoding="UTF-8"?>
<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="b5">
	<folder id="0" name="{BUILD}">
		<file id="0" name="{BUILD}-0.png" width="128" height="128" pivot_x="0.5" pivot_y="0.5" />
	</folder>
	<folder id="1" name="swap_body">
		<file id="0" name="swap_body-0.png" width="{swap.width}" height="{swap.height}" pivot_x="0.5" pivot_y="0.5" />
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

# ── 4) 编译 ──
r = subprocess.run([SCML_EXE, BUILD + ".scml", MOD], cwd=OUTDIR,
                   capture_output=True, text=True, errors="replace")
print((r.stdout or "").strip()[-80:])
zpath = os.path.join(MOD, "anim", BUILD + ".zip")
print("anim zip:", os.path.getsize(zpath), "B")

# ── 5) 图标 64² ──
Fi = min(60.0 / fw, 60.0 / fh)
iw, ih = max(1, round(fw * Fi)), max(1, round(fh * Fi))
icon_src = premul_resize(front, iw, ih)
icon = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
icon.paste(icon_src, ((64 - iw) // 2, (64 - ih) // 2), icon_src)
icon_png = os.path.join(INV, BUILD + ".png")
icon.save(icon_png)
r2 = subprocess.run([PNG_EXE, BUILD + ".png", BUILD + ".tex"], cwd=INV,
                    capture_output=True, text=True, errors="replace")
print("图标 64²（内容 %dx%d）png.exe exit=%d" % (iw, ih, r2.returncode))
