import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image, blit

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "musha")


def load(folder, idx):
    return read_png(os.path.join(BASE, folder, "%s-%d.png" % (folder, idx)))


def checker(W, H, s=12):
    im = Image(W, H)
    px = im.px
    for y in range(H):
        for x in range(W):
            v = 105 if ((x // s) + (y // s)) % 2 == 0 else 140
            i = (y * W + x) * 4
            px[i:i+4] = bytes((v, v, v + 5, 255))
    return im


def sheet(rows, out, pad=10):
    widths = [sum(im.w for im in ims) + pad * (len(ims) + 1) for _, ims in rows]
    if not rows:
        raise SystemExit("empty")
    heights = [max(im.h for im in ims) + pad * 2 for _, ims in rows]
    W, H = max(widths), sum(heights)
    canvas = checker(W, H)
    y = 0
    for r, (_, ims) in enumerate(rows):
        x = pad
        for im in ims:
            blit(canvas, im, x, y + pad)
            x += im.w + pad
        y += heights[r]
    write_png(out, canvas)
    print(out, W, "x", H)


t = [load("torso", i) for i in range(11)]
au = [load("arm_upper", i) for i in range(7)]
al = [load("arm_lower", i) for i in range(7)]
aus = [load("arm_upper_skin", i) for i in range(len(os.listdir(os.path.join(BASE, "arm_upper_skin"))))]
sk = [load("skirt", i) for i in range(len([f for f in os.listdir(os.path.join(BASE, "skirt")) if f.endswith(".png")]))]
tp = [load("torso_pelvis", i) for i in range(len([f for f in os.listdir(os.path.join(BASE, "torso_pelvis")) if f.endswith(".png")]))]

sheet([("torso 0-5", t[:6]),
       ("torso 6-10", t[6:]),
       ("arm_upper 0-6", au),
       ("arm_lower 0-6", al),
       ("arm_upper_skin", aus),
       ("skirt / torso_pelvis", sk + tp)], os.path.join(os.path.dirname(os.path.abspath(__file__)), "_test_out", "cloth_sheet.png"))
