import sys, os, zipfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image, blit

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.normpath(os.path.join(HERE, "..", "musha"))
BAK = os.path.normpath(os.path.join(HERE, "..", "_bak_musha_outfit"))
OUT = os.path.join(HERE, "_test_out", "gray_cloth_preview.png")


def checker(W, H, s=12):
    im = Image(W, H)
    px = im.px
    for y in range(H):
        for x in range(W):
            v = 105 if ((x // s) + (y // s)) % 2 == 0 else 140
            i = (y * W + x) * 4
            px[i:i+4] = bytes((v, v, v + 5, 255))
    return im


PARTS = [("torso", 4), ("torso_pelvis", 4), ("arm_upper", 4), ("arm_lower", 4), ("arm_upper_skin", 3)]
rows = []
for part, n in PARTS:
    orig = [read_png(os.path.join(BAK, part, "%s-%d.png" % (part, i))) for i in range(n)]
    gray = [read_png(os.path.join(PROJ, part, "%s-%d.png" % (part, i))) for i in range(n)]
    rows.append((part, orig + gray))

pad = 10
W = max(sum(im.w for im in ims) + pad * (len(ims) + 1) for _, ims in rows)
H = sum(max(im.h for im in ims) + pad * 2 for _, ims in rows)
canvas = checker(W, H)
y = 0
for _, ims in rows:
    x = pad
    for k, im in enumerate(ims):
        blit(canvas, im, x, y + pad)
        x += im.w + pad
    # 中线：把左半(原图)与右半(灰版)分开
    y += max(im.h for im in ims) + pad * 2
write_png(OUT, canvas)
print("预览图（每行：左边原图，右边灰布版）：", OUT)

# 校验项目 zip 里的 PNG 已同步
zp = os.path.join(PROJ, "musha.zip")
with zipfile.ZipFile(zp) as z:
    ok = 0
    for part, n in PARTS:
        for i in range(n):
            name = "%s-%d.png" % (part, i)
            if z.read(name) == open(os.path.join(PROJ, part, name), "rb").read():
                ok += 1
print("项目 zip 同步校验：%d/%d 张一致" % (ok, sum(n for _, n in PARTS)))
