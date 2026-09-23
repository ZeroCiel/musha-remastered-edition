# -*- coding: utf-8 -*-
"""服装版本判色：区分「素布衣(低饱和)」与「原版(高饱和)」"""
import os, sys, colorsys, struct, zlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
Z = r"C:\Users\Administrator\AppData\Local\Temp\clothv01"
PROJ = os.path.join(M, "exported", "musha")
BAK = os.path.join(M, "exported", "_bak_musha_outfit")

def stats(p):
    im = read_png(p)
    n = 0; sr = sg = sb = 0; ss = 0; sv = 0; hues = {}
    for i in range(0, im.w*im.h*4, 4):
        a = im.px[i+3]
        if a < 120: continue
        r, g, b = im.px[i], im.px[i+1], im.px[i+2]
        h, s, v = colorsys.rgb_to_hsv(r/255, g/255, b/255)
        n += 1; sr += r; sg += g; sb += b; ss += s; sv += v
        hues[int(h*360)//30] = hues.get(int(h*360)//30, 0) + 1
    if n == 0: return "空(全透明)"
    top = sorted(hues.items(), key=lambda kv: -kv[1])[:3]
    return (f"像素{n:6d} 平均RGB({sr//n:3d},{sg//n:3d},{sb//n:3d}) 饱和{ss/n:.2f} 明度{sv/n:.2f} "
            f"主色相 {[f'{k*30}-{k*30+30}度:{v*100//n}%' for k,v in top]}")

print("部件                 zip(Downloads)                        | 项目 exported/musha                   | _bak 原图")
for sym, idx in [("torso", 0), ("torso", 8), ("torso_pelvis", 0), ("skirt", 0),
                 ("arm_upper", 0), ("arm_lower", 0), ("arm_upper_skin", 0),
                 ("headbase", 0), ("face", 0), ("hand", 0), ("leg", 0), ("foot", 0), ("hair", 0)]:
    fn = f"{sym}-{idx}.png"
    row = [fn.ljust(18)]
    for base in (Z, os.path.join(PROJ, sym), os.path.join(BAK, sym)):
        p = os.path.join(base, fn) if base != Z else os.path.join(Z, fn)
        row.append(stats(p) if os.path.exists(p) else "—缺失—")
    print(" | ".join(row))
