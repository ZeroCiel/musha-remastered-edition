# -*- coding: utf-8 -*-
"""把光斩的 8 方向图套出来拼一张对照图（桌面 + 项目各一份）"""
import sys, os
TOOLS = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\exported\_tools"
sys.path.insert(0, TOOLS)
from pnglib import Image, read_png, write_png, blit, contact_sheet

SRC = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\exported\crescent_moon"
OUT_PROJ = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\exported\crescent_moon\dirs_sheet_20260916.png"
DESKTOP = r"C:\Users\Administrator\Desktop\光斩8方向_20260916.png"
CELL = 300          # 每格缩到多大

def shrink(im, n):
    out = Image(n, n)
    step = im.w / float(n)
    for y in range(n):
        for x in range(n):
            r = g = b = a = 0
            cnt = 0
            for j in range(int(step)):
                for i in range(int(step)):
                    sx, sy = int(x * step) + i, int(y * step) + j
                    if 0 <= sx < im.w and 0 <= sy < im.h:
                        c = im.get(sx, sy)
                        r += c[0]; g += c[1]; b += c[2]; a += c[3]
                        cnt += 1
            cnt = max(1, cnt)
            out.put(x, y, (r // cnt, g // cnt, b // cnt, a // cnt))
    return out

def cell_bg(im, bg=(40, 44, 56)):
    out = Image(im.w, im.h)
    for i in range(0, im.w * im.h * 4, 4):
        out.px[i:i + 3] = bytes(bg)
        out.px[i + 3] = 255
    blit(out, im, 0, 0)
    return out

# 尺寸统一：每张缩到 CELL，按 dir0..dir7 顺序
raw = []
for k in range(8):
    p = os.path.join(SRC, "crescent_dir%d.png" % k)
    im = read_png(p)
    small = shrink(im, CELL) if im.w != CELL else im
    raw.append(cell_bg(small))
    print("dir%d  %s  %dx%d -> %d 格" % (k, os.path.basename(p), im.w, im.h, CELL))

# 4 列 x 2 行
rows = [("", raw[0:4]), ("", raw[4:8])]
contact_sheet(rows, OUT_PROJ, pad=14, bg=(24, 26, 34))
data = open(OUT_PROJ, "rb").read()
open(DESKTOP, "wb").write(data)
print("\n对照图（项目）：%s" % OUT_PROJ)
print("对照图（桌面）：%s" % DESKTOP)
print("排布：第一行 dir0 dir1 dir2 dir3 ／ 第二行 dir4 dir5 dir6 dir7（就是 scml 里 anim_0..anim_7 的顺序）")
