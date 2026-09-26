#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""酒馆（祭坛建筑 musha_advance_altar）换装 + 物品栏图标（2026-09-26）
1) 世界图：图片/酒馆_透明.png → 裁可见 bbox → 预乘缩小到高 500px → tavern-0.png
   （scml.exe 忽略 key 的 scale——尺寸必须烘进 PNG，铁律）
2) 重写 scml：单 folder 单 file，pivot 0.5/0（底边中心=落地点），key time=0，无 scale
3) 编译 anim/musha_advance_altar.zip（用户已拍板换装，属授权覆盖）
4) 物品栏图标：64×64（内容 fit 60）→ png.exe → tex/xml（旧 128² 三件套先备份）
"""
import os
import subprocess
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
D = os.path.join(HERE, "..", "..", "exported", "musha_advance_altar")
INV = os.path.join(HERE, "..", "..", "images", "inventoryimages")
TMP = os.path.join(HERE, "_tmp")
SRC = os.path.join(HERE, "..", "..", "图片", "酒馆_透明.png")
SCML_EXE = r"D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools\mod_tools\scml.exe"
PNG_EXE = r"D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools\mod_tools\png.exe"
BUILD = "musha_advance_altar"

os.makedirs(TMP, exist_ok=True)

# ── 1) 世界图：高 500px ──
im = Image.open(SRC).convert("RGBA")
vis = im.getchannel("A").point(lambda v: 255 if v >= 8 else 0)
x0, y0, x1, y1 = vis.getbbox()
crop = im.crop((x0, y0, x1, y1))
cw, ch = crop.size
f = 500.0 / ch
tw, th = round(cw * f), round(ch * f)
# 预乘缩小
pm = crop.copy(); pp = pm.load()
for y in range(ch):
    for x in range(cw):
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
tavern = os.path.join(D, "tavern-0.png")
small.save(tavern)
print("世界图 %dx%d → %s" % (tw, th, tavern))

# ── 2) scml（房规：folder 名=build 名；声明 1:1；pivot 0.5/0 底中心；key time=0 无 scale）──
scml = os.path.join(D, BUILD + ".scml")
open(scml, "w", encoding="utf-8", newline="\n").write(f'''<?xml version="1.0" encoding="UTF-8"?>
<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="r7">
    <folder id="0" name="{BUILD}">
        <file id="0" name="tavern-0.png" width="{tw}" height="{th}" pivot_x="0.5" pivot_y="0"/>
    </folder>
    <entity id="0" name="{BUILD}">
        <animation id="0" name="idle" length="1000" interval="100">
            <mainline>
                <key id="0">
                    <object_ref id="0" timeline="0" key="0" z_index="0"/>
                </key>
            </mainline>
            <timeline id="0" name="{BUILD}">
                <key id="0" time="0" spin="0">
                    <object folder="0" file="0" x="0" y="0"/>
                </key>
            </timeline>
        </animation>
    </entity>
</spriter_data>
''')
print("scml 重写完成（旧 scml 备份 _tmp/）")

# ── 3) 编译 anim zip ──
r = subprocess.run([SCML_EXE, BUILD + ".scml", os.path.normpath(os.path.join(HERE, "..", ".."))],
                   cwd=D, capture_output=True, text=True, errors="replace")
print((r.stdout or "").strip()[-120:])
zpath = os.path.join(HERE, "..", "..", "anim", BUILD + ".zip")
print("anim zip:", os.path.getsize(zpath), "B")

# ── 4) 物品栏图标 64×64 ──
F = min(60.0 / cw, 60.0 / ch)
iw, ih = max(1, round(cw * F)), max(1, round(ch * F))
pm2 = crop.copy(); p2 = pm2.load()
for y in range(ch):
    for x in range(cw):
        r, g, b, a = p2[x, y]
        if a < 255:
            p2[x, y] = (r * a // 255, g * a // 255, b * a // 255, a)
ic = pm2.resize((iw, ih), Image.LANCZOS)
ip = ic.load()
for y in range(ih):
    for x in range(iw):
        r, g, b, a = ip[x, y]
        if 0 < a < 255:
            ip[x, y] = (min(255, r * 255 // a), min(255, g * 255 // a), min(255, b * 255 // a), a)
icon = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
icon.paste(ic, ((64 - iw) // 2, (64 - ih) // 2), ic)
icon_png = os.path.join(INV, BUILD + ".png")
icon.save(icon_png)
print("图标 64x64（内容 %dx%d 居中）→ %s" % (iw, ih, icon_png))

# png.exe → tex + 自动 xml（裸文件名 + cwd=INV，同 scml.exe 的路径坑）
r2 = subprocess.run([PNG_EXE, BUILD + ".png", BUILD + ".tex"],
                    cwd=INV, capture_output=True, text=True, errors="replace")
print("png.exe:", (r2.stdout or r2.stderr or "").strip()[:100], "exit=", r2.returncode)
