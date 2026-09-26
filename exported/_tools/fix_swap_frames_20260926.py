#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""swap_backpack 补帧（2026-09-26，用户拍板：缺的帧用黑色色块补）
官方动画引用 swap_body 帧 14/15（teleport/amulet_rebirth 姿势），build 只有 0-13。
补：swap_body-14/15.png（100x100 黑块）+ scml 加 id 14/15 → 重编 anim zip。
幂等：重复运行安全。
"""
import os
import subprocess
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.normpath(os.path.join(HERE, "..", ".."))
D = os.path.join(MOD, "exported", "swap_backpack")
SCML = os.path.join(D, "swap_backpack.scml")
SCML_EXE = r"D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools\mod_tools\scml.exe"
BUILD = "swap_backpack"

# ── 1) 黑色占位帧 100×100 ──
for n in (14, 15):
    p = os.path.join(D, "swap_body", "swap_body-%d.png" % n)
    Image.new("RGBA", (100, 100), (0, 0, 0, 255)).save(p)
    print("黑块帧:", p)

# ── 2) scml 按行插入 id 14/15（幂等）──
t = open(SCML, encoding="utf-8", errors="replace").read()
if "swap_body-14.png" in t:
    print("scml 已有帧 14/15，跳过插入")
else:
    out_lines = []
    for l in t.split("\n"):
        out_lines.append(l)
        if "swap_body-13.png" in l and "<file" in l:
            out_lines.append('\t\t<file id="14" name="swap_body/swap_body-14.png" width="100" height="100" pivot_x="0.5" pivot_y="0.5" />')
            out_lines.append('\t\t<file id="15" name="swap_body/swap_body-15.png" width="100" height="100" pivot_x="0.5" pivot_y="0.5" />')
    t = "\n".join(out_lines)
    open(SCML, "w", encoding="utf-8", newline="\n").write(t)
    print("scml 已插入帧 14/15 条目")

# ── 3) 重编（备份旧 zip）──
import shutil
zpath = os.path.join(MOD, "anim", "swap_backpack.zip")
bak = os.path.join(HERE, "_tmp", "swap_backpack_zip_backup_20260926.zip")
os.makedirs(os.path.dirname(bak), exist_ok=True)
shutil.copyfile(zpath, bak)
r = subprocess.run([SCML_EXE, BUILD + ".scml", MOD], cwd=D,
                   capture_output=True, text=True, errors="replace")
print((r.stdout or "").strip()[-80:])
print("anim zip:", os.path.getsize(zpath), "B")

# ── 4) 验证 ──
import sys
sys_path = os.path.join(HERE)
sys.path.insert(0, sys_path)
import sp_model_tool as S
b = S.parse_build(zpath)
total = sum(len(s["frames"]) for s in b["syms"])
print("重编后: build = %s  帧数 = %d（应 16）" % (b["name"], total))
