# -*- coding: utf-8 -*-
"""用 animation.xml 的 frame 矩形（w/h/x/y）反推正确的变换口径"""
import os, re, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
SRC = r"C:\Users\Administrator\AppData\Local\Temp\clothv01"

ax = open(os.path.join(SRC, "animation.xml"), encoding="utf-8", errors="replace").read()
bx = open(os.path.join(SRC, "build.xml"), encoding="utf-8", errors="replace").read()

# build.xml 帧尺寸/偏移
framesz = {}
for m in re.finditer(r'<Frame framenum="(\d+)" duration="\d+" image="([^"]+)" w="(\d+)" h="(\d+)" x="([-0-9.eE]+)" y="([-0-9.eE]+)"', bx):
    framesz[m.group(2)] = (int(m.group(3)), int(m.group(4)), float(m.group(5)), float(m.group(6)))

fr0 = re.search(r'<frame idx="0" w="(\d+)" h="(\d+)" x="([-0-9.eE]+)" y="([-0-9.eE]+)"', ax)
print("animation.xml frame0 矩形: w=%s h=%s x=%s y=%s" % fr0.groups())

els = re.findall(r'<element name="([^"]+)" layername="([^"]*)" frame="(\d+)" z_index="(-?\d+)" '
                 r'm_a="([-0-9.eE]+)" m_b="([-0-9.eE]+)" m_c="([-0-9.eE]+)" m_d="([-0-9.eE]+)" '
                 r'm_tx="([-0-9.eE]+)" m_ty="([-0-9.eE]+)"', fr0.string if False else ax)
# 只取 frame0 的
body0 = re.search(r'<frame idx="0"[^>]*>(.*?)</frame>', ax, re.S).group(1)
els0 = re.findall(r'<element name="([^"]+)" layername="([^"]*)" frame="(\d+)" z_index="(-?\d+)" '
                  r'm_a="([-0-9.eE]+)" m_b="([-0-9.eE]+)" m_c="([-0-9.eE]+)" m_d="([-0-9.eE]+)" '
                  r'm_tx="([-0-9.eE]+)" m_ty="([-0-9.eE]+)"', body0)


def quad(e, mode):
    """返回该元素在 canvas 坐标(y 向下，x 右)下的 4 角"""
    sym, layer, bfi = e[0], e[1], int(e[2])
    A, B, C, D, TX, TY = map(float, e[4:10])
    w, h, fx, fy = framesz["%s-%d" % (sym, bfi)]
    px, py = (0.5 - fx / w) * w, (0.5 + fy / h) * h      # 图内 pivot 像素
    pts = []
    for (u, v) in ((0, 0), (w, 0), (0, h), (w, h)):
        du, dv = u - px, v - py
        if mode == "world":      # 图内坐标(y 下) 直接乘 (a,b,c,d)，平移 (tx,ty)，然后 y 取反
            X = A * du + B * dv + TX
            Y = C * du + D * dv + TY
            pts.append((X, -Y))
        elif mode == "mirror":   # [[a,-b],[-c,d]]
            X = A * du - B * dv + TX
            Y = -C * du + D * dv - TY
            pts.append((X, Y))
        elif mode == "transpose":  # [[a,c],[b,d]]
            X = A * du + C * dv + TX
            Y = B * du + D * dv - TY
            pts.append((X, Y))
        elif mode == "flipuv":   # 图内坐标 y 向下，垂直翻转：(u-px, py-v)
            X = A * du + B * (-dv) + TX
            Y = -(C * du + D * (-dv) + TY)
            pts.append((X, -Y))
    return pts


for mode in ("world", "mirror", "transpose", "flipuv"):
    xs, ys = [], []
    for e in els0:
        for (X, Y) in quad(e, mode):
            xs.append(X); ys.append(Y)
    print("  [%9s] x %.1f..%.1f  y %.1f..%.1f   宽 %.1f 高 %.1f" % (mode, min(xs), max(xs), min(ys), max(ys), max(xs) - min(xs), max(ys) - min(ys)))
