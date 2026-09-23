# -*- coding: utf-8 -*-
"""39 个 key 到底一不一样？（逐 key 比对层数值）"""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from buildxml_to_scml import parse_build, parse_anim

SRC = r"C:\Users\Administrator\AppData\Local\Temp\clothv01"
anim = parse_anim(os.path.join(SRC, "animation.xml"))
frs = anim["frames"]
print("frame 数:", len(frs))
base = frs[0][1]
for idx, els in frs:
    if len(els) != len(base):
        print("  frame %d 层数不同" % idx); continue
    worst = 0.0
    for e, b in zip(els, base):
        d = max(abs(e["a"]-b["a"]), abs(e["b"]-b["b"]), abs(e["c"]-b["c"]), abs(e["d"]-b["d"]),
                abs(e["tx"]-b["tx"]), abs(e["ty"]-b["ty"]), abs(e["z"]-b["z"]),
                0 if e["sym"] == b["sym"] and e["bframe"] == b["bframe"] else 999)
        worst = max(worst, d)
    print("  frame %3d vs frame0 最大差 = %.4f" % (idx, worst))
