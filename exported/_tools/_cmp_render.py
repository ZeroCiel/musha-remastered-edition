# -*- coding: utf-8 -*-
"""用像素级对比验证转换口径：把「现有工程 musha.scml」和「我转换出来的 scml」渲染同一 key，比较差异"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from musha_scml_render import load_scml, render_key
from pnglib import write_png, Image

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
REF = os.path.join(M, "exported", "musha", "musha.scml")
NEW = os.path.join(M, "exported", "_tools", "_test_out", "scmltest2", "cloth_v01", "cloth_v01.scml")
OUT = os.path.join(M, "exported", "_tools", "_test_out")

def render(path, key):
    f, a = load_scml(path)
    anim = a[list(a)[0]]
    return render_key(f, anim, key, os.path.dirname(os.path.abspath(path)), 1.0, None, None, cache={})

for key in (0, 20):
    r = render(REF, key)
    n = render(NEW, key)
    print("key %d: 参考 %dx%d  新 %dx%d" % (key, r.w, r.h, n.w, n.h))
    if (r.w, r.h) != (n.w, n.h):
        print("  尺寸不同 —— 直接叠图看")
    W, H = max(r.w, n.w), max(r.h, n.h)
    diff = 0; tot = 0
    for y in range(H):
        for x in range(W):
            ia = (y * r.w + x) * 4 if (y < r.h and x < r.w) else None
            ib = (y * n.w + x) * 4 if (y < n.h and x < n.w) else None
            pa = tuple(r.px[ia:ia+4]) if ia is not None else (0, 0, 0, 0)
            pb = tuple(n.px[ib:ib+4]) if ib is not None else (0, 0, 0, 0)
            tot += 1
            if pa[3] != pb[3] or max(abs(pa[i] - pb[i]) for i in range(3)) > 24:
                diff += 1
    print("  不同像素 %d/%d = %.2f%%" % (diff, tot, 100.0 * diff / tot))
    # 并排图
    side = Image(min(r.w, n.w) * 2 + 12, max(r.h, n.h))
    for y in range(max(r.h, n.h)):
        for x in range(side.w):
            j = (y * side.w + x) * 4
            side.px[j:j+3] = b"\x28\x28\x30"; side.px[j+3] = 255
    def blit(dst, src, dx):
        for y in range(src.h):
            for x in range(src.w):
                i = (y * src.w + x) * 4
                a = src.px[i+3]
                if a == 0: continue
                j = (y * dst.w + dx + x) * 4
                if a == 255: dst.px[j:j+4] = src.px[i:i+4]
                else:
                    ia = 255 - a
                    for k in range(3): dst.px[j+k] = (src.px[i+k]*a + dst.px[j+k]*ia)//255
                    dst.px[j+3] = 255
    blit(side, r, 0); blit(side, n, min(r.w, n.w) + 12)
    write_png(os.path.join(OUT, "cmp_key%d.png" % key), side)
    print("  并排图: _test_out/cmp_key%d.png (左=现有工程 右=我转换)" % key)
