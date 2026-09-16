"""月牙"横躺"对照：同一张底图，按滚转角 0 / -90 / +90 各派生一遍方向图，拼成对照图。

背景：DST 的 billboard 贴图**不吃 Transform:SetRotation**（引擎只按朝向换图，不会转贴图），
      所以"横向发射"只能在素材里烤进去 —— 这里就是把整张弧滚 90° 的两个方向各出一版给你挑。
口径：dir7 = 屏幕向右飞的那张；dir1 = 屏幕向下飞的那张（世界 315° / 45°）。

用法：python preview_roll.py [素材目录]
产出：桌面 光斩滚转对照_20260916.png
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import crescent_gen as cg
from pnglib import read_png, write_png, Image, blit
from boat_scml_render import draw_text

SRC = sys.argv[1] if len(sys.argv) > 1 else r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\exported\crescent_moon"
TEST = os.path.join(HERE, "_test_out")
OUT = r"C:\Users\Administrator\Desktop\光斩滚转对照_20260916.png"

ROLLS = [
    ("ROLL 0  = NOW (STANDING / PERPENDICULAR)", 0.0),
    ("ROLL -90 = LIE DOWN (CONVEX UP)", -90.0),
    ("ROLL +90 = LIE DOWN (CONVEX DOWN)", 90.0),
]
SHOW = [(7, "DIR7  FLY SCREEN-RIGHT"), (1, "DIR1  FLY SCREEN-DOWN")]
K = 6            # 缩小倍数
BG = (46, 48, 56)


def shrink6(im, k):
    w, h = im.w // k, im.h // k
    out = Image(w, h)
    for y in range(h):
        for x in range(w):
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


def main():
    # crescent_gen 内部的像素格式 = [(r,g,b,a), ...] 的平表；pnglib 是 bytes → 转一下
    _im = read_png(os.path.join(SRC, "crescent_light.png"))
    base_px = [(_im.px[i * 4], _im.px[i * 4 + 1], _im.px[i * 4 + 2], _im.px[i * 4 + 3])
               for i in range(_im.w * _im.h)]
    print("底图", _im.w, "x", _im.h)
    thumbs = []
    for name, roll in ROLLS:
        d = os.path.join(TEST, "roll_%d" % int(roll))
        os.makedirs(d, exist_ok=True)
        print("=== 生成", name, "===")
        cg.make_dirs(base_px, d, 8, roll)
        thumbs.append((name, [shrink6(read_png(os.path.join(d, "crescent_dir%d.png" % k)), K) for k, _ in SHOW]))

    cw = max(t.w for _, ts in thumbs for t in ts) + 16
    ch = max(t.h for _, ts in thumbs for t in ts) + 16
    W = cw * len(SHOW) + 40
    H = 70 + (ch + 58) * len(thumbs) + 20
    cv = Image(W, H)
    for i in range(0, W * H * 4, 4):
        cv.px[i:i + 3] = bytes(BG)
        cv.px[i + 3] = 255
    draw_text(cv, 20, 14, "MOON SLASH: ROLL COMPARISON (SAME SHAPE, 3 ROLLS)", 2, (255, 214, 120))
    x0 = 20
    for c, (_, lbl) in enumerate(SHOW):
        draw_text(cv, x0 + c * cw + 8, 46, lbl, 2, (150, 230, 255))
    for r, (name, ts) in enumerate(thumbs):
        y = 70 + r * (ch + 58)
        draw_text(cv, 20, y + 2, name, 2, (255, 200, 140))
        for c, t in enumerate(ts):
            blit(cv, t, x0 + c * cw + 8, y + 24, alpha=False)
    write_png(OUT, cv)
    print("对照图:", OUT, "%dx%d" % (W, H))


if __name__ == "__main__":
    main()
