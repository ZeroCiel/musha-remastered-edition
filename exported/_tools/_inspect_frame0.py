# -*- coding: utf-8 -*-
"""看 frame0 的层到底是几个人/几个视图：按符号列出每个实例的 x/y 和图层名"""
import os, re, sys, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
SRC = r"C:\Users\Administrator\AppData\Local\Temp\clothv01"
ax = open(os.path.join(SRC, "animation.xml"), encoding="utf-8", errors="replace").read()
body = re.search(r'<frame idx="0"[^>]*>(.*?)</frame>', ax, re.S).group(1)
els = re.findall(r'<element name="([^"]+)" layername="([^"]*)" frame="(\d+)" z_index="(-?\d+)" '
                 r'm_a="([-0-9.eE]+)" m_b="([-0-9.eE]+)" m_c="([-0-9.eE]+)" m_d="([-0-9.eE]+)" '
                 r'm_tx="([-0-9.eE]+)" m_ty="([-0-9.eE]+)"', body)
print("frame0 层数:", len(els))
by = collections.OrderedDict()
for e in els:
    by.setdefault(e[0], []).append(e)
for sym, lst in by.items():
    print("--- %s (%d 个实例)" % (sym, len(lst)))
    for e in lst:
        print("     x=%8.1f y=%8.1f  z=%3s  img帧=%s  a=%6.3f d=%6.3f 层名=%s"
              % (float(e[8]), float(e[9]), e[3], e[2], float(e[4]), float(e[7]), e[1]))
# 按 x 聚类
print("\n按 x 分簇（阈值 ±120）:")
clus = {"左(x<-120)": 0, "中(-120..120)": 0, "右(x>120)": 0}
for e in els:
    x = float(e[8])
    k = "左(x<-120)" if x < -120 else ("右(x>120)" if x > 120 else "中(-120..120)")
    clus[k] += 1
print("   ", clus)
