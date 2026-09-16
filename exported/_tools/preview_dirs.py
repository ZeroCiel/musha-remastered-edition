"""把 crescent_dir0..7.png 拼成一张预览图放桌面（缩小 4 倍 + 标注方向名），并打一份 ASCII 方便无视觉环境核对。

用法：python preview_dirs.py [素材目录] [输出png]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image, blit
from boat_scml_render import draw_text, text_w

LABELS = [
    "DIR0 +X      SLASH_DOWNRIGHT",
    "DIR1 +X+Z    SLASH_DOWN",
    "DIR2 +Z      SLASH_DOWNLEFT",
    "DIR3 -X+Z    SLASH_LEFT",
    "DIR4 -X      SLASH_UPLEFT",
    "DIR5 -X-Z    SLASH_UP",
    "DIR6 -Z      SLASH_UPRIGHT",
    "DIR7 +X-Z    SLASH_RIGHT",
]
SCALE = 4            # 缩小倍数
COLS = 4
BG = (46, 48, 56)
CELL_PAD = 6


def shrink(im, k):
    w = im.w // k
    h = im.h // k
    out = Image(w, h)
    for y in range(h):
        for x in range(w):
            # 盒式平均（含 alpha 加权，避免边缘发黑）
            r = g = b = a = 0
            for dy in range(k):
                for dx in range(k):
                    sr, sg, sb, sa = im.get(x * k + dx, y * k + dy)
                    r += sr * sa; g += sg * sa; b += sb * sa; a += sa
            if a == 0:
                out.put(x, y, (0, 0, 0, 0))
            else:
                out.put(x, y, (r // a, g // a, b // a, a // (k * k)))
    return out


def main(argv):
    d = argv[0] if argv else r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\exported\crescent_moon"
    out_path = argv[1] if len(argv) > 1 else r"C:\Users\Administrator\Desktop\光斩新素材_20260916.png"
    arms = []
    for i in range(8):
        im = read_png(os.path.join(d, "crescent_dir%d.png" % i))
        arms.append(shrink(im, SCALE))
    cw = arms[0].w + CELL_PAD * 2
    ch = arms[0].h + CELL_PAD * 2 + 40
    rows = 2
    W = cw * COLS
    H = ch * rows + 60
    cv = Image(W, H)
    for i in range(0, W * H * 4, 4):
        cv.px[i:i + 3] = bytes(BG)
        cv.px[i + 3] = 255
    draw_text(cv, 20, 14, "CRESCENT DIR0..7  (4TH VARIANT: THICK + ZERO GLOW)", 2, (255, 214, 120))
    for i, im in enumerate(arms):
        c, r = i % COLS, i // COLS
        x = c * cw + CELL_PAD
        y = 60 + r * ch + CELL_PAD
        blit(cv, im, x + (arms[0].w - im.w) // 2, y, alpha=False)
        draw_text(cv, x, y + im.h + 8, LABELS[i], 2, (150, 230, 255))
    write_png(out_path, cv)
    print("预览图:", out_path, "%dx%d" % (W, H))

    # ASCII 底图（看形状/上下宽窄）
    base = read_png(os.path.join(d, "crescent_light.png"))
    print("\n底图 ASCII（左=开口侧，右=凸面/刃口；行密=越大）:")
    for yy in range(0, base.h, 40):
        line = ""
        for xx in range(0, base.w, 32):
            mx = 0
            for y in range(yy, min(yy + 40, base.h), 8):
                for x in range(xx, min(xx + 32, base.w), 8):
                    v = base.get(x, y)[3]
                    if v > mx:
                        mx = v
            line += " " if mx < 40 else ("." if mx < 140 else ("o" if mx < 230 else "#"))
        print("   " + line.rstrip())


if __name__ == "__main__":
    main(sys.argv[1:])
