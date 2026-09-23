# -*- coding: utf-8 -*-
"""拼一张"v2 / v3 侧脸头 + face-4"对照总表（纯标准库，无 PIL）

版面（每格都画在灰底上，看得清透明区）：
  第1行：v2 face-4 | v3 face-4 | 参考图/face4.png
  第2行：v2 headbase_hat-1 | v3 headbase_hat-1 | v3 head + v3 face 1:1 叠加
  第3行：v2 head + v2 face（按 pivot 比率对齐） | v2 head + v2 face（缩到 237x304 再叠加） | 空
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
P = lambda *a: os.path.join(M, *a)
BG = (70, 72, 80)
GAP = 10

def flatten(im, bg=BG, sc=1):
    w, h = im.w * sc, im.h * sc
    out = Image(w, h)
    for y in range(h):
        sy = y // sc
        for x in range(w):
            sx = x // sc
            i = (sy * im.w + sx) * 4
            a = im.px[i + 3]
            o = (y * w + x) * 4
            if a == 255:
                out.px[o:o + 4] = im.px[i:i + 4]
            elif a == 0:
                out.px[o:o + 4] = bytes(bg) + b"\xff"
            else:
                f = a / 255.0
                out.px[o] = int(im.px[i] * f + bg[0] * (1 - f))
                out.px[o + 1] = int(im.px[i + 1] * f + bg[1] * (1 - f))
                out.px[o + 2] = int(im.px[i + 2] * f + bg[2] * (1 - f))
                out.px[o + 3] = 255
    return out

def resize(im, w, h):
    out = Image(w, h)
    for y in range(h):
        sy = min(im.h - 1, int(y * im.h / h))
        for x in range(w):
            sx = min(im.w - 1, int(x * im.w / w))
            i = (sy * im.w + sx) * 4
            o = (y * w + x) * 4
            out.px[o:o + 4] = im.px[i:i + 4]
    return out

def overlay(base, top, ox=0, oy=0):
    out = Image(base.w, base.h, bytearray(base.px))
    for y in range(top.h):
        ty = y + oy
        if ty < 0 or ty >= out.h: continue
        for x in range(top.w):
            tx = x + ox
            if tx < 0 or tx >= out.w: continue
            i = (y * top.w + x) * 4
            a = top.px[i + 3]
            if a == 0: continue
            o = (ty * out.w + tx) * 4
            if a == 255:
                out.px[o:o + 4] = top.px[i:i + 4]
            else:
                f = a / 255.0
                for c in range(3):
                    out.px[o + c] = int(top.px[i + c] * f + out.px[o + c] * (1 - f))
                out.px[o + 3] = 255
    return out

# ---- 素材 ----
v2_head = read_png(P("exported", "musha v2", "headbase_hat", "headbase_hat-1.png"))
v3_head = read_png(P("exported", "musha v3", "headbase_hat", "headbase_hat-1.png"))
v2_face = read_png(P("exported", "musha v2", "face", "face-4.png"))
v3_face = read_png(P("exported", "musha v3", "face", "face-4.png"))
ref = None
rp = P("参考图", "face4.png")
if os.path.exists(rp):
    ref = read_png(rp)

# v2 face(305x384) 按 pivot 比率 对齐到 head 画布
V2P = (0.57805907, 0.26644737)          # v2 scml 里 headbase-1 / face-4 的 pivot 比率
v2_pivot_px = (V2P[0] * 237, V2P[1] * 304)
f2_pivot_px = (V2P[0] * v2_face.w, V2P[1] * v2_face.h)
off_ratio = (int(round(v2_pivot_px[0] - f2_pivot_px[0])), int(round(v2_pivot_px[1] - f2_pivot_px[1])))
v2_face_scaled = resize(v2_face, 237, 304)      # 另一个假设：缩到 237x304 再叠

panels = [
    [("v2 face-4 %dx%d" % (v2_face.w, v2_face.h), flatten(v2_face)),
     ("v3 face-4 %dx%d" % (v3_face.w, v3_face.h), flatten(v3_face)),
     ("ref face4", flatten(ref) if ref is not None else Image(4, 4))],
    [("v2 head", flatten(v2_head)),
     ("v3 head", flatten(v3_head)),
     ("v3 head+face", flatten(overlay(v3_head, v3_face)))],
    [("v2 head + v2 face(pivot对齐%s)" % str(off_ratio), flatten(overlay(v2_head, v2_face, off_ratio[0], off_ratio[1]))),
     ("v2 head + v2 face(缩237x304)", flatten(overlay(v2_head, v2_face_scaled))),
     ("v2 head + v3 face", flatten(overlay(v2_head, v3_face)))],
]

cw = max(max(p[1].w for p in row) for row in panels)
rh = [max(p[1].h for p in row) for row in panels]
W = GAP + sum(cw + GAP for _ in range(3))
H = GAP + sum(h + GAP for h in rh)
sheet = Image(W, H)
sheet.px[:] = bytes(BG) + b"\xff" * 0
for y in range(H):
    for x in range(W):
        o = (y * W + x) * 4
        sheet.px[o:o + 4] = bytes(BG) + b"\xff"

y0 = GAP
for ri, row in enumerate(panels):
    x0 = GAP
    for title, im in row:
        for y in range(im.h):
            for x in range(im.w):
                i = (y * im.w + x) * 4
                o = ((y0 + y) * W + (x0 + x)) * 4
                sheet.px[o:o + 4] = im.px[i:i + 4]
        x0 += cw + GAP
    y0 += rh[ri] + GAP

out = P("exported", "_test_out", "v2v3_对比", "对照总表.png")
os.makedirs(os.path.dirname(out), exist_ok=True)
write_png(out, sheet)
print("写出:", out, "%dx%d" % (sheet.w, sheet.h))
print("v2 face 实际 %dx%d / v2 scml 声明 237x304 → 差 (%+d, %+d)" % (v2_face.w, v2_face.h, v2_face.w - 237, v2_face.h - 304))
print("v2 face 按 pivot 比率对齐 head 画布 需要平移", off_ratio)
