# -*- coding: utf-8 -*-
"""按当前 heart-0..4 出徽章表情预览（顺序改了就跑这个）"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import Image, read_png, blit, contact_sheet
M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
H = os.path.join(M, "exported", "energy", "heart")
def zoom(im, z):
    out = Image(im.w*z, im.h*z)
    for y in range(im.h):
        for x in range(im.w):
            i=(y*im.w+x)*4
            for dy in range(z):
                for dx in range(z):
                    j=((y*z+dy)*out.w+(x*z+dx))*4
                    out.px[j:j+4]=im.px[i:i+4]
    return out
faces = [read_png(os.path.join(H, "heart-%d.png" % i)) for i in range(5)]
ring = read_png(os.path.join(M,"exported","energy","frame_circle","frame_circle-0.png"))
row = []
for i, val in enumerate((1.0, 0.85, 0.6, 0.35, 0.1)):
    cv = Image(100,100)
    idx = int(round((1.0-val)*22))
    liq = read_png(os.path.join(M,"exported","energy","health_level","health_level-%d.png" % idx))
    blit(cv, liq, 50-liq.w//2, 50+31-liq.h)
    f = faces[i]; blit(cv, f, 50-f.w//2, 50-f.h//2)
    blit(cv, ring, 50-ring.w//2, 50-ring.h//2+1)
    row.append(zoom(cv,2))
rows = [("5表情 0-4", [zoom(f,4) for f in faces]), ("装进徽章", row)]
p = r"C:\Users\Administrator\Desktop\能量徽章表情_20260916.png"
contact_sheet(rows, p, pad=10, bg=(58,58,66))
contact_sheet(rows, os.path.join(M,"exported","energy","_concept","badge_faces_20260916.png"), pad=10, bg=(58,58,66))
print("预览已更新 →", p)
