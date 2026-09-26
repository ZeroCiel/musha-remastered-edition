#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""官方骨架弓箭最简版（2026-09-26）
模板工作流：player_bow.scml（官方弓动画 bow_pre/loop/pst）+ musha 部件替换
  · musha 拥有的核心符号：按帧号一一对应替换（face 33<34 clamp，弓不用 face-33）
  · wilson 独有符号（string 弦/bolt 箭/swap_object 手持/FX）：保留官方贴图=弓的视觉
  · entity 改名 wilson → musha_bow（避免污染官方 wilson bank）
输出：exported/_tools/_test_out/sp_bow_official/（scml + 部件 + 编译 zip）
"""
import os
import re
import shutil
import subprocess
import sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
T = r"D:\SteamLibrary\steamapps\workshop\content\322330\2898572674\template"
M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
MUSHA_SRC = os.path.join(M, "exported", "musha")
OUT = os.path.join(HERE, "_test_out", "sp_bow_official")
SCML_EXE = r"D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools\mod_tools\scml.exe"

os.makedirs(OUT, exist_ok=True)

# ── 1) 读模板 scml，收集引用的文件 ──
src = open(os.path.join(T, "player_bow.scml"), encoding="utf-8", errors="replace").read()
file_entries = re.findall(r'<file[^>]*?name="([^"]+)"[^>]*?width="(\d+)"[^>]*?height="(\d+)"', src)
print("player_bow 引用文件 %d 个" % len(file_entries))

# musha.scml → folder 名 → 有序文件名列表
musha_scml = open(os.path.join(MUSHA_SRC, "musha.scml"), encoding="utf-8", errors="replace").read()
folders = {}
cur = None
for line in musha_scml.split("\n"):
    mf = re.search(r'<folder[^>]*name="([^"]+)"', line)
    if mf:
        cur = mf.group(1); folders.setdefault(cur, [])
        continue
    ff = re.search(r'<file[^>]*name="([^"]+)"', line)
    if ff and cur:
        folders[cur].append(ff.group(1))
musha_syms = set(folders.keys())
BLOCKLIST = {"beard", "beard_long", "beard_medium", "beard_short", "face_monkeyparts"}   # musha 无须：wilson 胡子不进 build
print("musha 部件符号 %d 个" % len(musha_syms))

# ── 2) 逐文件替换/复制 + 同步声明尺寸 ──
substituted = kept = 0
for name, w, h in file_entries:
    base = name.split("/")[-1].split("\\")[-1]
    m = re.match(r"(.+)-(\d+)\.png$", base)
    sym, idx = (m.group(1), int(m.group(2))) if m else (base[:-4], 0)
    dst = os.path.join(OUT, name.replace("/", os.sep))
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    used = None
    if sym in musha_syms and folders.get(sym):
        files = folders[sym]
        fi = min(idx, len(files) - 1)
        srcf = os.path.join(MUSHA_SRC, files[fi].replace("/", os.sep))
        if os.path.exists(srcf):
            shutil.copyfile(srcf, dst)
            substituted += 1
            used = srcf
    if used is None:
        srcf = os.path.join(T, name.replace("/", os.sep))
        if sym in BLOCKLIST:
            # musha 无须：胡子/猴脸部件透明占位（编译通过、渲染为空）
            Image.new("RGBA", (int(w), int(h)), (0, 0, 0, 0)).save(dst)
            kept += 1
            print("  🚫 黑名单透明占位:", name)
        elif os.path.exists(srcf):
            shutil.copyfile(srcf, dst)
            kept += 1
        else:
            # 两边都缺 → 透明占位（声明尺寸），渲染为空=该部件不显示
            Image.new("RGBA", (int(w), int(h)), (0, 0, 0, 0)).save(dst)
            kept += 1
            print("  ⚠️ 透明占位:", name)
        continue
    # musha 部件实际尺寸可能 ≠ wilson 声明 → 同步 scml 声明
    im = Image.open(dst)
    if int(w) != im.width or int(h) != im.height:
        old = 'name="%s" width="%s" height="%s"' % (name, w, h)
        new = 'name="%s" width="%d" height="%d"' % (name, im.width, im.height)
        src = src.replace(old, new)
print("部件替换 %d（musha）/ 保留官方 %d" % (substituted, kept))

# ── 3) entity 改名 + 写出 scml ──
src = src.replace('<entity id="0" name="wilson">', '<entity id="0" name="musha_bow">')
scml_path = os.path.join(OUT, "musha_bow.scml")
open(scml_path, "w", encoding="utf-8", newline="\n").write(src)

# ── 4) 编译 ──
r = subprocess.run([SCML_EXE, "musha_bow.scml", OUT], cwd=OUT,
                   capture_output=True, text=True, errors="replace")
print((r.stdout or "").strip()[-100:])
if r.returncode != 0:
    print("编译失败:", (r.stderr or "")[:300]); sys.exit(1)
zpath = os.path.join(OUT, "anim", "musha_bow.zip")
print("编译产物:", os.path.getsize(zpath), "B")

# ── 5) 解析 + 渲染验证 ──
sys.path.insert(0, HERE)
import sp_model_tool as S
b = S.parse_build(zpath)
a = S.parse_anim(zpath)
print("build =", b["name"], " 符号", len(b["syms"]), "个")
print("anims:", [x["name"] for x in a["anims"]])
for anim in a["anims"]:
    zs = S.ZipSource(zpath, anim_name=anim["name"], scale=1.0)
    n = len(zs.frames)
    picks = sorted(set([0, n // 3, (2 * n) // 3, n - 1]))
    tiles = []
    for i in picks:
        fr = zs.frames[i]
        bg = Image.new("RGBA", fr.size, (110, 150, 110, 255)); bg.alpha_composite(fr)
        tiles.append(bg)
    Wt = sum(t.width for t in tiles) + 10 * (len(tiles) + 1)
    Ht = max(t.height for t in tiles) + 20
    sheet = Image.new("RGBA", (Wt, Ht), (30, 30, 34, 255))
    xx = 10
    for t2 in tiles:
        sheet.alpha_composite(t2, (xx, 10)); xx += t2.width + 10
    out = os.path.join(OUT, "_render_%s.png" % anim["name"])
    sheet.save(out)
    print("渲染 %s（%d 帧，抽 %d）→ %s" % (anim["name"], n, len(picks), out))
