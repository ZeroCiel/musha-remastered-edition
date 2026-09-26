# 只读：量 panel_bg_alt.png 里「内纸(浅米白)」的水平边界 → 换算 content 坐标
# 用途：礼包三行/标题居中、技能树位置是否出内纸（09-27 用户：三行没居中、白纸框要修）
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


def is_paper(c):
    r, g, b, a = c
    if a < 40:
        return False
    # 浅米白=内纸；外层黄纸 r-b 太大 → 不算
    return r > 205 and g > 195 and b > 170 and (r - b) < 70


def to_content(px_x, px_y):
    return ((px_x - W / 2) / SX, (H / 2 - px_y) / SY)


# 整张内纸 bbox
x0, y0, x1, y1 = W, H, -1, -1
for y in range(0, H, 2):
    for x in range(0, W, 2):
        if is_paper(px[x, y]):
            if x < x0: x0 = x
            if x > x1: x1 = x
            if y < y0: y0 = y
            if y > y1: y1 = y

print("inner paper px  x %d..%d  y %d..%d  (size %dx%d)" % (x0, x1, y0, y1, x1 - x0 + 1, y1 - y0 + 1))
cl, cr = to_content(x0, 0)[0], to_content(x1, 0)[0]
ct, cb = to_content(0, y0)[1], to_content(0, y1)[1]
print("inner paper content: left %.1f  right %.1f  center %.1f  width %.1f" % (cl, cr, (cl + cr) / 2, cr - cl))
print("inner paper content: top %.1f  bottom %.1f  center %.1f  height %.1f" % (ct, cb, (ct + cb) / 2, ct - cb))

# 只看右侧书页区（排除左侧导航栏那条竖纸）：content x > -100 的部分
x0b, x1b = W, -1
for y in range(0, H, 2):
    for x in range(0, W, 2):
        if is_paper(px[x, y]) and to_content(x, 0)[0] > -100:
            if x < x0b: x0b = x
            if x > x1b: x1b = x
cl2, cr2 = to_content(x0b, 0)[0], to_content(x1b, 0)[0]
print("right page content: left %.1f  right %.1f  center %.1f  width %.1f" % (cl2, cr2, (cl2 + cr2) / 2, cr2 - cl2))
