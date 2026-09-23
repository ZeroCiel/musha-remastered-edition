# -*- coding: utf-8 -*-
"""反推「出图规则」：量现有素材里每个符号每帧的 pivot 落在不透明包围盒的什么位置。
如果规律稳定 → 就能让 AI 只画部件，pivot/对齐由脚本自动算。"""
import os, sys, struct, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png
from buildxml_to_scml import parse_build

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
TPL = os.path.join(M, "exported", "musha_cloth_v01")

syms = parse_build(os.path.join(TPL, "build.xml"))

def stats(p):
    im = read_png(p)
    x0, y0, x1, y1 = im.w, im.h, -1, -1
    for y in range(im.h):
        for x in range(im.w):
            if im.px[(y * im.w + x) * 4 + 3] > 40:
                if x < x0: x0 = x
                if x > x1: x1 = x
                if y < y0: y0 = y
                if y > y1: y1 = y
    if x1 < 0:
        return None
    return x0, y0, x1, y1

print("%-15s %-4s %-13s %-13s %-22s %s" % ("符号", "帧", "画布", "内容框", "pivot像素(图内)", "pivot 在内容框里的位置"))
rows = collections.defaultdict(list)
for sym, frames in syms:
    for f in frames:
        p = os.path.join(TPL, sym, f["img"] + ".png")
        bb = stats(p)
        px = (0.5 - f["x"] / f["w"]) * f["w"]
        py = (0.5 + f["y"] / f["h"]) * f["h"]
        if bb is None:
            print("%-15s %-4d %-13s %-13s (%-6.1f,%-6.1f)  空图" % (sym, f["n"], "%dx%d" % (f["w"], f["h"]), "空", px, py))
            continue
        bw, bh = bb[2] - bb[0] + 1, bb[3] - bb[1] + 1
        fx = (px - bb[0]) / bw          # 0=内容左缘 1=内容右缘
        fy = (py - bb[1]) / bh          # 0=内容上缘 1=内容下缘
        rows[sym].append((fx, fy, bw, bh, f["w"], f["h"]))
        print("%-15s %-4d %-13s %-13s (%-6.1f,%-6.1f)  x=%.2f y=%.2f  (内容 %dx%d / 画布 %dx%d)"
              % (sym, f["n"], "%dx%d" % (f["w"], f["h"]), "%dx%d" % (bw, bh), px, py, fx, fy, bw, bh, f["w"], f["h"]))

print("\n=== 汇总（pivot 在内容框里的相对位置，0..1）===")
for sym, lst in rows.items():
    fx = [r[0] for r in lst]; fy = [r[1] for r in lst]
    print("  %-15s n=%-3d  x均值 %.2f (%.2f~%.2f)   y均值 %.2f (%.2f~%.2f)"
          % (sym, len(lst), sum(fx)/len(fx), min(fx), max(fx), sum(fy)/len(fy), min(fy), max(fy)))
