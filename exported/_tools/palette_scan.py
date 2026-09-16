import sys, os, colorsys, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "musha")


def analyse(folder, indices=None):
    d = os.path.join(BASE, folder)
    files = sorted([f for f in os.listdir(d) if f.endswith(".png")],
                   key=lambda f: int(f.rsplit("-", 1)[1].split(".")[0]))
    if indices:
        files = [f for f in files if int(f.rsplit("-", 1)[1].split(".")[0]) in indices]
    buckets = collections.Counter()
    rep = {}
    for f in files:
        im = read_png(os.path.join(d, f))
        for i in range(0, len(im.px), 4):
            r, g, b, a = im.px[i], im.px[i+1], im.px[i+2], im.px[i+3]
            if a < 200:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if s < 0.15:
                key = "GRAY(v%02d)" % int(v * 10)
            else:
                key = "h%03d" % int(h * 360)
            buckets[key] += 1
            rep.setdefault(key, [0, 0, 0, 0])
            t = rep[key]
            t[0] += r; t[1] += g; t[2] += b; t[3] += 1
    total = sum(buckets.values()) or 1
    print("== %s (%d files, %d px)" % (folder, len(files), total))
    for k, c in buckets.most_common(14):
        t = rep[k]
        print("   %-9s %5.1f%%  avg RGB(%3d,%3d,%3d)" % (k, 100.0 * c / total, t[0]/t[3], t[1]/t[3], t[2]/t[3]))


for f in ["torso", "torso_pelvis", "skirt", "arm_upper", "arm_lower", "arm_upper_skin",
          "leg", "foot", "hand", "headbase", "tail", "hair", "face"]:
    try:
        analyse(f)
    except Exception as e:
        print("ERR", f, e)
