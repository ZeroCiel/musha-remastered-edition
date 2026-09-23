# -*- coding: utf-8 -*-
"""未解锁格底图（叉号格）→ images/musha_mail_x.png

口径：
  · DST 的格子是 64x64；这张图**整格替换** slotbg（原版 widget.slotbg[i] = {atlas,image}）
    → 所以要把"槽的样子"一起画上（底 + 边框 + 内嵌），再压一个粗叉
  · 只给"未解锁"的格子用；已解锁的格子 slotbg 留 nil = 原版槽的样子（不用画）
用法：python make_slot_lock_art.py [尺寸] [输出png]
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import Image, write_png

S = 64
BASE = (58, 52, 46)        # 槽底（暗暖灰，比原版槽再暗一档）
EDGE = (128, 116, 98)      # 外框
INNER = (38, 34, 30)       # 内嵌暗边
XCOL = (208, 198, 180)     # 叉号本体
XEDGE = (26, 22, 20)       # 叉号描边


def main():
    size = int(sys.argv[1]) if len(sys.argv) > 1 else S
    out = sys.argv[2] if len(sys.argv) > 2 else \
        os.path.abspath(os.path.join(HERE, "..", "..", "images", "musha_mail_x.png"))
    im = Image(size, size)
    k = size / 64.0

    def put(x, y, c):
        if 0 <= x < size and 0 <= y < size:
            im.put(x, y, (c[0], c[1], c[2], 255))

    def rect(x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                put(x, y, c)

    def thick_line(x0, y0, x1, y1, c, t):
        n = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
        for i in range(n + 1):
            f = i / float(n)
            cx, cy = x0 + (x1 - x0) * f, y0 + (y1 - y0) * f
            for dy in range(-t, t + 1):
                for dx in range(-t, t + 1):
                    if dx * dx + dy * dy <= t * t + 1:
                        put(int(round(cx)) + dx, int(round(cy)) + dy, c)

    # 槽底 + 外框 + 内嵌
    rect(0, 0, size - 1, size - 1, BASE)
    for i in range(int(round(2 * k))):
        for x in range(size):
            put(x, i, EDGE); put(x, size - 1 - i, EDGE)
        for y in range(size):
            put(i, y, EDGE); put(size - 1 - i, y, EDGE)
    for i in range(int(round(2 * k)), int(round(5 * k))):
        for x in range(i, size - i):
            put(x, i, INNER); put(x, size - 1 - i, INNER)
        for y in range(i, size - i):
            put(i, y, INNER); put(size - 1 - i, y, INNER)

    # 叉号（先粗描边、再本体）：内嵌留 12%，端点圆头
    a, b = 0.16 * size, 0.84 * size
    for col, t in ((XEDGE, 5), (XCOL, 3)):
        thick_line(a, a, b, b, col, int(round(t * k)))
        thick_line(b, a, a, b, col, int(round(t * k)))

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    write_png(out, im)
    print("写好", out, "%dx%d" % (size, size))


if __name__ == "__main__":
    main()
