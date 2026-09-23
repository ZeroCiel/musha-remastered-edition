# -*- coding: utf-8 -*-
"""对齐后再比：把两张渲染各自裁到不透明区域，再按中心对齐比差异（排除画布尺寸差）"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from musha_scml_render import load_scml, render_key
from pnglib import Image, write_png

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
REF = os.path.join(M, "exported", "musha", "musha.scml")
NEW = os.path.join(M, "exported", "musha_cloth_v01", "musha_cloth_v01.scml")

def render(path, key):
    f, a = load_scml(path)
    A = a[list(a)[0]]
    return render_key(f, A, key, os.path.dirname(os.path.abspath(path)), 1.0, None, None, cache={})

def bbox(im):
    x0, y0, x1, y1 = im.w, im.h, -1, -1
    for y in range(im.h):
        for x in range(im.w):
            if im.px[(y * im.w + x) * 4 + 3] > 8:
                if x < x0: x0 = x
                if x > x1: x1 = x
                if y < y0: y0 = y
                if y > y1: y1 = y
    return x0, y0, x1, y1

r, n = render(REF, 0), render(NEW, 0)
br, bn = bbox(r), bbox(n)
print("参考画布 %dx%d 内容框 %s (%dx%d)" % (r.w, r.h, br, br[2]-br[0]+1, br[3]-br[1]+1))
print("新 画布 %dx%d 内容框 %s (%dx%d)" % (n.w, n.h, bn, bn[2]-bn[0]+1, bn[3]-bn[1]+1))
W = max(br[2]-br[0], bn[2]-bn[0]) + 1
H = max(br[3]-br[1], bn[3]-bn[1]) + 1
diff = 0; tot = 0
for y in range(H):
    for x in range(W):
        ax, ay = br[0] + x, br[1] + y
        bx, by = bn[0] + x, bn[1] + y
        pa = tuple(r.px[(ay * r.w + ax) * 4:(ay * r.w + ax) * 4 + 4]) if ax < r.w and ay < r.h else (0,0,0,0)
        pb = tuple(n.px[(by * n.w + bx) * 4:(by * n.w + bx) * 4 + 4]) if bx < n.w and by < n.h else (0,0,0,0)
        tot += 1
        if pa[3] != pb[3] or max(abs(pa[i]-pb[i]) for i in range(3)) > 24:
            diff += 1
print("对齐后不同像素 %d/%d = %.2f%%" % (diff, tot, 100.0*diff/tot))
# 差异的行分布（看是整体错位还是局部）
rows = {}
for y in range(H):
    c = 0
    for x in range(W):
        ax, ay = br[0] + x, br[1] + y
        bx, by = bn[0] + x, bn[1] + y
        pa = tuple(r.px[(ay*r.w+ax)*4:(ay*r.w+ax)*4+4]) if ax < r.w and ay < r.h else (0,0,0,0)
        pb = tuple(n.px[(by*n.w+bx)*4:(by*n.w+bx)*4+4]) if bx < n.w and by < n.h else (0,0,0,0)
        if pa[3] != pb[3] or max(abs(pa[i]-pb[i]) for i in range(3)) > 24:
            c += 1
    if c:
        rows[y] = c
print("有差异的行数 %d / %d；差异最集中的 8 行: %s" % (len(rows), H, sorted(rows.items(), key=lambda kv: -kv[1])[:8]))
