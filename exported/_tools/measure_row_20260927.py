# 只读：按行扫 panel_bg_alt.png，打印 kind 转换点（out=透明 / paper=浅米白内纸 / wood=其它）
# 用来定「右侧书页内纸」的左右边界 → 内纸中心，给礼包三行居中/技能树位置用
import sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
P = os.path.join(HERE, "..", "..", "images", "panel_bg_alt.png")
im = Image.open(P).convert("RGBA")
W, H = im.size
px = im.load()
SX = W / 1285.1
SY = H / 887.2


def kind(c):
    r, g, b, a = c
    if a < 40:
        return "out"
    if r > 205 and g > 195 and b > 170 and (r - b) < 70:
        return "paper"
    return "wood"


def to_cx(px_x):
    return (px_x - W / 2) / SX


def scan_row(y, minlen=6):
    prev = None
    runs = []
    start = 0
    for x in range(W):
        k = kind(px[x, y])
        if k != prev:
            if prev is not None:
                runs.append((prev, start, x - 1))
            prev = k
            start = x
    runs.append((prev, start, W - 1))
    # 只留长度够的段
    out = []
    for k, a, b in runs:
        if b - a + 1 >= minlen:
            out.append("%s[%.0f..%.0f]cx %.0f..%.0f" % (k, a, b, to_cx(a), to_cx(b)))
    return out


for cy in (200, 77, -140, -300):
    y = int(H / 2 - cy * SY)
    print("content y=%d -> py=%d :" % (cy, y))
    for seg in scan_row(y):
        print("   ", seg)
