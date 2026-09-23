# -*- coding: utf-8 -*-
"""musha scml 拼装渲染器（纯标准库）—— 把 Spriter 工程按 z 叠加渲染成 PNG，可指定第几个 key。

用法：
  python musha_scml_render.py <x.scml> <out.png> [--keys 0,3,6] [--scale 0.5] [--canvas WxH] [--strip]
    --keys    渲染哪些 key（默认 0）；--strip 时把所有 key 横排成一张总表
    --canvas  固定画布 "1659x879"（角色 build 的规范画布）；不给就自动裁到内容框
    --nobg     不要灰底

口径（沿用 boat_scml_render.py 实测出来的那套，并补上 scale/负 scale 的 y 翻转）：
  * canvas_y = cy - y（y 向上为正）；物体 pivot 点落在 (x, y)
  * 图内 pivot 像素 p = (pivot_x*w, (1-pivot_y)*h)
  * 合成矩阵（镜像到 y 向下后）= [[a,-b],[-c,-d']]；直接把 scml 的 angle/scale_x/scale_y 代进
    下面的 R·S 公式即等价（scml 里 angle 与 scale_y 已经带了符号）
  * z 越大越靠前（按 z 升序贴 = 最后贴的在最上）
"""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import xml.etree.ElementTree as ET
from pnglib import Image, write_png, read_png

BG = (46, 48, 56)


def fnum(v, d=0.0):
    try:
        return float(v)
    except (TypeError, ValueError):
        return d


def load_scml(path):
    root = ET.parse(path).getroot()
    folders = {}
    for f in root.findall("folder"):
        fid = int(f.get("id"))
        files = []
        for x in f.findall("file"):
            files.append((x.get("name"), int(x.get("width")), int(x.get("height")),
                          fnum(x.get("pivot_x"), 0.5), fnum(x.get("pivot_y"), 0.5)))
        folders[fid] = {"name": f.get("name"), "files": files}
    ent = root.find("entity")
    anims = {}
    for a in ent.findall("animation"):
        keys = []
        tl_names = {}
        objs = {}
        for tl in a.findall("timeline"):
            tid = int(tl.get("id"))
            tl_names[tid] = tl.get("name")
            for k in tl.findall("key"):
                kid = int(k.get("id"))
                o = k.find("object")
                if o is None:
                    continue
                objs[(tid, kid)] = dict(
                    folder=int(o.get("folder", 0)), file=int(o.get("file", 0)),
                    x=fnum(o.get("x")), y=fnum(o.get("y")), ang=fnum(o.get("angle")),
                    sx=fnum(o.get("scale_x"), 1.0), sy=fnum(o.get("scale_y"), 1.0))
        ml = a.find("mainline")
        nkeys = 0
        if ml is not None:
            for k in ml.findall("key"):
                kid = int(k.get("id"))
                nkeys = max(nkeys, kid + 1)
                layers = []
                for ref in k.findall("object_ref"):
                    tid = int(ref.get("timeline"))
                    ok = int(ref.get("key", kid))
                    o = objs.get((tid, ok))
                    if o is None:
                        continue
                    o = dict(o, z=int(ref.get("z_index", 0)), tl=tl_names.get(tid, "?"))
                    layers.append(o)
                keys.append((kid, layers))
        keys.sort()
        anims[a.get("name")] = dict(length=int(a.get("length", 0)),
                                    interval=int(a.get("interval", 25)),
                                    keys=keys, nkeys=max(nkeys, len(keys)))
    return folders, anims


def draw_layer(cv, src, cx0, cy0, ox, oy, ang, sx, sy, pvx, pvy, bbox):
    """把 src 以 pivot 为中心 scale/rotate 后贴到 cv（pivot 落在 canvas 坐标 (ox,oy)）"""
    w, h = src.w, src.h
    px, py = pvx * w, (1.0 - pvy) * h
    rad = math.radians(ang)
    ca, sa = math.cos(rad), math.sin(rad)
    # 4 角在 canvas 上的位置 → 目标包围盒
    xs, ys = [], []
    for (u, v) in ((0, 0), (w, 0), (0, h), (w, h)):
        du, dv = u - px, v - py
        X = ox + ca * du * sx - sa * dv * sy
        Y = oy + sa * du * sx + ca * dv * sy
        xs.append(X); ys.append(Y)
    x0 = max(0, int(math.floor(min(xs))) - cx0)
    x1 = min(cv.w, int(math.ceil(max(xs))) + 1 - cx0)
    y0 = max(0, int(math.floor(min(ys))) - cy0)
    y1 = min(cv.h, int(math.ceil(max(ys))) + 1 - cy0)
    if x1 <= x0 or y1 <= y0:
        return
    det = sx * sy  # 变换行列式（含镜像）
    if abs(det) < 1e-9:
        return
    for Y in range(y0, y1):
        Wy = Y + cy0 - oy
        for X in range(x0, x1):
            Wx = X + cx0 - ox
            # 反变换：先反旋转，再反 scale
            du = ca * Wx + sa * Wy
            dv = -sa * Wx + ca * Wy
            u = du / sx + px
            v = dv / sy + py
            iu, iv = int(u + 0.5), int(v + 0.5)
            if iu < 0 or iv < 0 or iu >= w or iv >= h:
                continue
            i = (iv * w + iu) * 4
            a = src.px[i + 3]
            if a == 0:
                continue
            j = (Y * cv.w + X) * 4
            if a == 255:
                cv.px[j:j + 4] = src.px[i:i + 4]
            else:
                ia = 255 - a
                for k in range(3):
                    cv.px[j + k] = (src.px[i + k] * a + cv.px[j + k] * ia) // 255
                cv.px[j + 3] = max(cv.px[j + 3], a)


def render_key(folders, anim, kid, base, scale=1.0, canvas=None, bg=BG, pad=20, cache=None):
    """渲染 anim 的第 kid 个 key；canvas 不给就自动裁到内容框。返回 Image"""
    layers = None
    for k, ls in anim["keys"]:
        if k == kid:
            layers = ls
            break
    if layers is None:
        return None
    # 1) 先算内容包围盒（在 build 坐标里，y 向上）
    ext = []
    for L in layers:
        fname, w, h, pvx, pvy = folders[L["folder"]]["files"][L["file"]]
        px, py = pvx * w, (1.0 - pvy) * h
        rad = math.radians(L["ang"]); ca, sa = math.cos(rad), math.sin(rad)
        xs, ys = [], []
        for (u, v) in ((0, 0), (w, 0), (0, h), (w, h)):
            du, dv = u - px, v - py
            X = L["x"] + ca * du * L["sx"] - sa * dv * L["sy"]
            Y = L["y"] + sa * du * L["sx"] + ca * dv * L["sy"]
            xs.append(X); ys.append(Y)
        ext.append((min(xs), max(xs), min(ys), max(ys)))
    if canvas:
        cw, ch = canvas
        cylo = max(e[2] for e in ext); cyhi = min(e[3] for e in ext)
        cxlo = min(e[0] for e in ext); cxhi = max(e[1] for e in ext)
    else:
        cxlo = min(e[0] for e in ext) - pad
        cxhi = max(e[1] for e in ext) + pad
        cylo = min(e[2] for e in ext) - pad
        cyhi = max(e[3] for e in ext) + pad
        cw = int(math.ceil((cxhi - cxlo) * scale)); ch = int(math.ceil((cyhi - cylo) * scale))
    W = max(1, int(math.ceil((cxhi - cxlo) * scale)))
    H = max(1, int(math.ceil((cyhi - cylo) * scale)))
    cv = Image(W, H)
    if bg is not None:
        for i in range(0, W * H * 4, 4):
            cv.px[i:i + 3] = bytes(bg); cv.px[i + 3] = 255
    for L in sorted(layers, key=lambda z: z["z"]):
        fname, w, h, pvx, pvy = folders[L["folder"]]["files"][L["file"]]
        key = (L["folder"], L["file"])
        if cache is None:
            cache = {}
        if key not in cache:
            p = os.path.join(base, fname.replace("/", os.sep))
            cache[key] = read_png(p) if os.path.exists(p) else None
        src = cache[key]
        if src is None:
            continue
        # build 坐标 → canvas 坐标：先平移到内容框左下角，再翻 y、乘 scale
        def T(bx, by):
            return ((bx - cxlo) * scale, (cyhi - by) * scale)
        ox, oy = T(L["x"], L["y"])
        draw_layer(cv, src, 0, 0, ox, oy, L["ang"], L["sx"] * scale, L["sy"] * scale, pvx, pvy, None)
    return cv


def sheet(images, cols, bg=BG, pad=6, labels=None):
    """把若干 Image 排成表（等比不缩放）"""
    rows = (len(images) + cols - 1) // cols
    cw = max(im.w for im in images); chh = max(im.h for im in images)
    W = cols * (cw + pad) + pad
    H = rows * (chh + pad) + pad
    cv = Image(W, H)
    for i in range(0, W * H * 4, 4):
        cv.px[i:i + 3] = bytes(bg); cv.px[i + 3] = 255
    for n, im in enumerate(images):
        r, c = divmod(n, cols)
        dx = pad + c * (cw + pad) + (cw - im.w) // 2
        dy = pad + r * (chh + pad) + (chh - im.h) // 2
        for y in range(im.h):
            ty = dy + y
            if ty < 0 or ty >= H:
                continue
            for x in range(im.w):
                tx = dx + x
                if tx < 0 or tx >= W:
                    continue
                i = (y * im.w + x) * 4
                a = im.px[i + 3]
                if a == 0:
                    continue
                j = (ty * W + tx) * 4
                if a == 255:
                    cv.px[j:j + 4] = im.px[i:i + 4]
                else:
                    ia = 255 - a
                    for k in range(3):
                        cv.px[j + k] = (im.px[i + k] * a + cv.px[j + k] * ia) // 255
                    cv.px[j + 3] = 255
    return cv


def main():
    args = sys.argv[1:]
    scml = args[0]; out = args[1]
    keys = [0]; scale = 1.0; canvas = None; bg = BG; nrows = 1
    i = 2
    while i < len(args):
        a = args[i]
        if a == "--keys":
            keys = [int(x) for x in args[i + 1].split(",")]; i += 2
        elif a == "--scale":
            scale = float(args[i + 1]); i += 2
        elif a == "--canvas":
            w, h = args[i + 1].lower().split("x"); canvas = (int(w), int(h)); i += 2
        elif a == "--nobg":
            bg = None; i += 1
        else:
            i += 1
    folders, anims = load_scml(scml)
    base = os.path.dirname(os.path.abspath(scml))
    aname = list(anims)[0]
    anim = anims[aname]
    print(f"scml: {os.path.basename(scml)}  animation={aname} keys={anim['nkeys']} length={anim['length']}")
    cache = {}
    ims = []
    for k in keys:
        im = render_key(folders, anim, k, base, scale, canvas, bg, cache=cache)
        if im is None:
            print("  key", k, "跳过（没有这个 key）"); continue
        print(f"  key {k:3d} -> {im.w}x{im.h}")
        ims.append(im)
    if not ims:
        return
    res = ims[0] if len(ims) == 1 else sheet(ims, 6)
    write_png(out, res)
    print("写好:", out, res.w, "x", res.h)


if __name__ == "__main__":
    main()
