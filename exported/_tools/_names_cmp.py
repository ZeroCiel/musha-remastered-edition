# -*- coding: utf-8 -*-
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from buildxml_to_scml import parse_build, parse_anim, build_scml
M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
SRC = r"C:\Users\Administrator\AppData\Local\Temp\clothv01"
syms = parse_build(os.path.join(SRC, "build.xml"))
anim = parse_anim(os.path.join(SRC, "animation.xml"))
_, names = build_scml(syms, anim)
ref = re.findall(r'<timeline id="\d+" name="([^"]+)"', open(os.path.join(M, "exported", "musha", "musha.scml"), encoding="utf-8").read())
layer0 = [e["layer"] for e in anim["frames"][0][1]]
print("idx  原始layername          我                ref               z")
for i, (l, m, r) in enumerate(zip(layer0, names, ref)):
    flag = "" if m == r else "  <<<"
    print("%3d  %-22s %-16s %-16s %s%s" % (i, l, m, r, anim["frames"][0][1][i]["z"], flag))
    if i > 27:
        break
