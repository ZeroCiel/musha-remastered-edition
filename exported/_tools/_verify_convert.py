# -*- coding: utf-8 -*-
import re, sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from buildxml_to_scml import parse_build, parse_anim, build_scml, decompose

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
SRC = r"C:\Users\Administrator\AppData\Local\Temp\clothv01"
REF = os.path.join(M, "exported", "musha", "musha.scml")

syms = parse_build(os.path.join(SRC, "build.xml"))
anim = parse_anim(os.path.join(SRC, "animation.xml"))
scml, names = build_scml(syms, anim)

ref_txt = open(REF, encoding="utf-8").read()
ref_names = re.findall(r'<timeline id="\d+" name="([^"]+)"', ref_txt)
print("时间轴：我生成 %d 条 / 现有 musha.scml %d 条" % (len(names), len(ref_names)))
print("  名字+顺序完全相同:", names == ref_names)
if names != ref_names:
    for i, (a, b) in enumerate(zip(names, ref_names)):
        if a != b:
            print("   第 %d 个不同: 我=%s  ref=%s" % (i, a, b))
            if i > 6:
                break

# 逐元素数值校验（我生成 vs 参考工程 key0 / key1）
ref_keys = {}
for m in re.finditer(r'<timeline id="(\d+)" name="[^"]+">(.*?)</timeline>', ref_txt, re.S):
    tid = int(m.group(1))
    for k in re.finditer(r'<key id="(\d+)"[^>]*>\s*<object folder="(\d+)" file="(\d+)" x="([-0-9.eE]+)" y="([-0-9.eE]+)" '
                         r'scale_x="([-0-9.eE]+)" scale_y="([-0-9.eE]+)" angle="([-0-9.eE]+)"', m.group(2)):
        ref_keys[(tid, int(k.group(1)))] = (float(k.group(4)), float(k.group(5)), float(k.group(6)), float(k.group(7)), float(k.group(8)))
print("参考工程 object 数:", len(ref_keys))

worst = 0.0; wi = None
for kid, (idx, els) in enumerate(anim["frames"]):
    if kid > 2:
        break
    for ti, e in enumerate(els):
        if (ti, kid) not in ref_keys:
            continue
        x, y, sx, sy, ang = ref_keys[(ti, kid)]
        msx, msy, mang = decompose(e["a"], e["b"], e["c"], e["d"])
        d = max(abs(x - e["tx"]), abs(y + e["ty"]), abs(sx - msx), abs(sy - msy),
                abs((ang - mang + 180) % 360 - 180))
        if d > worst:
            worst = d; wi = (kid, ti, names[ti], ref_keys[(ti, kid)], (msx, msy, mang, e["tx"], -e["ty"]))
print("前 3 帧逐元素最大误差: %.6f  %s" % (worst, wi if worst > 0.001 else ""))
