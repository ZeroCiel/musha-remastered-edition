import sys, os, colorsys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "musha")


def cls(r, g, b):
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    deg = h * 360
    if s < 0.18:
        c = "."
    elif deg < 20 or deg >= 340:
        c = "r"
    elif deg < 45:
        c = "o"
    elif deg < 70:
        c = "y"
    elif deg < 160:
        c = "g"
    elif deg < 200:
        c = "c"
    elif deg < 265:
        c = "b"
    elif deg < 340:
        c = "p"
    else:
        c = "r"
    if c not in "." and v < 0.28:
        return c  # dark shade
    return c.upper()


def render(path, cols=78):
    im = read_png(path)
    rows = max(1, int(cols * im.h / im.w * 0.5))
    out = []
    for ry in range(rows):
        line = []
        for rx in range(cols):
            x0, x1 = int(rx * im.w / cols), max(int(rx * im.w / cols) + 1, int((rx + 1) * im.w / cols))
            y0, y1 = int(ry * im.h / rows), max(int(ry * im.h / rows) + 1, int((ry + 1) * im.h / rows))
            R = G = B = A = n = 0
            for y in range(y0, y1):
                for x in range(x0, x1):
                    i = (y * im.w + x) * 4
                    a = im.px[i+3]
                    if a < 120:
                        continue
                    A += a
                    R += im.px[i]; G += im.px[i+1]; B += im.px[i+2]
                    n += 1
            line.append(" " if n == 0 else cls(R // n, G // n, B // n))
        out.append("".join(line))
    print("== %s  %dx%d" % (os.path.basename(path), im.w, im.h))
    for l in out:
        print("   " + l)
    print()


if __name__ == "__main__":
    for f in sys.argv[1:]:
        render(os.path.join(BASE, f))
