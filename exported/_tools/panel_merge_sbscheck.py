# -*- coding: utf-8 -*-
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import read_png

PROBE = os.path.join(HERE, "_panel_probe")
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sbs = read_png(os.path.join(PROBE, "merged_side_by_side.png"))
mg = read_png(os.path.join(PROBE, "merged_full.png"))
og = read_png(os.path.join(ROOT, "images", "panel_bg.png"))

def px(img, x, y):
    i = (y*img.w + x)*4
    p = img.px
    return (p[i], p[i+1], p[i+2])

print("sbs size:", sbs.w, sbs.h)
print("sbs(600,315)   =", px(sbs, 600, 315), "  <- panelA divider zone (expect gap ~250,241,193)")
print("sbs(1809,315)  =", px(sbs, 1809, 315), "  <- panelB same zone (expect merged ~250,243,215)")
print("orig(600,315)  =", px(og, 600, 315))
print("merged(600,315)=", px(mg, 600, 315))
