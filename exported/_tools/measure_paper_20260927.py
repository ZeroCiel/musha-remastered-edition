# 只读：量 panel_bg_alt.png 里"内纸"边界，跟任务栏底框(724x456 @122,-160)比对是否超框
import sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
P = os.path.join(HERE, "..", "..", "images", "panel_bg_alt.png")
im = Image.open(P).convert("RGBA")
W, H = im.size
px = im.load()
print("size", W, H)

def kind(c):
    r, g, b, a = c
    if a < 40:
        return "out"          # 透明（面板外）
    if r > 205 and g > 195 and b > 170 and (r - b) < 70:
        return "paper"        # 内纸（浅米白）
    return "wood"             # 木框/其他

def scan_col(x):
    prev = None
    out = []
    for y in range(H):
        k = kind(px[x, y])
        if k != prev:
            out.append((y, k))
            prev = k
    return out

def scan_row(y):
    prev = None
    out = []
    for x in range(W):
        k = kind(px[x, y])
        if k != prev:
            out.append((x, k))
            prev = k
    return out

print("col x=768 :", scan_col(768)[:14])
print("col x=482 :", scan_col(482)[:14])
print("col x=1346:", scan_col(1346)[:14])
print("row y=433 :", scan_row(433)[:14])
print("row y=700 :", scan_row(700)[:14])
print("row y=960 :", scan_row(960)[:14])

# 任务栏底框（content → png 像素）
SX = W / 1285.1
SY = H / 887.2
def to_px(x, y):
    return (W / 2 + x * SX, H / 2 - y * SY)
x0, y0 = to_px(122 - 362, -160 + 228)   # 左上
x1, y1 = to_px(122 + 362, -160 - 228)   # 右下
print("quest_bg frame px: x %.1f..%.1f  y %.1f..%.1f" % (x0, x1, y0, y1))
