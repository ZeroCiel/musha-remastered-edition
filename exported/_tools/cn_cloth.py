"""musha 默认衣服 → 中国古代素布衣（第四版 / 定稿思路）。

关键认识（三版踩出来的）：
  1) 每帧 PNG 的尺寸和 pivot 都不一样（torso-0 宽 160、torso-10 宽 80）→ 结构只能沿用原图，
     自己另画"交领/腰带"必然跨帧串位。原图的领口线/袖口线/衣褶线位置天然正确。
  2) 上一版失败的根因：把"内缩 2px 的环"当缘边 → 衣服内部每条边都算进去，41% 像素变深边 → 整件糊掉。
     正确做法：只认**外轮廓**（从画面边界 BFS 找"外面"），按"离外面的距离"分带。
  3) 素布 = 一大片均匀布色 + 干净外描边 + 淡衣纹。线稿不能压太深（深了就成"布上有花纹"）。

分带规则（distance = 到"画面外部"的 4 邻接步数）：
  d == 1       外描边（深）
  d == 2..4    滚边/缘边（布色稍深）—— 中式布衣的"缘"，领口袖口下摆一圈
  d >= 5       布面；原图的细线在这里压成**淡衣纹**（不是黑线，比布色深一点）

用法：
    python cn_cloth.py                 # 出候选对照图（原图 | 1 亮麻 | 2 中麻 | 3 青灰）
    python cn_cloth.py --apply 2       # 定稿覆盖 39 张 + 同步项目 zip
    python cn_cloth.py --revert        # 还原原图
"""
import os, sys, shutil, zipfile
from collections import deque
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image, blit

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.normpath(os.path.join(HERE, "..", "musha"))
BAK = os.path.normpath(os.path.join(HERE, "..", "_bak_musha_outfit"))
OUTDIR = os.path.join(HERE, "_test_out")
PARTS = ["torso", "torso_pelvis", "arm_upper", "arm_lower", "arm_upper_skin"]

A_SOLID = 110          # alpha 阈值：算"实体"
BLACK_CUT = 30         # 原图亮度 < 此值 = 深色（可能是线稿，也可能是深色布块）
LINE_THICK = 3         # 深色连通域厚度 < 此值 → 细线（留成衣纹）；否则是粗色块（当布料重画）
                       # 每档可单独覆盖（cfg["line_thick"]）：数值越大，保留的原画墨线越多 = 越"精细"
D_HEM = 3              # 离外面 ≤ 此距离的实体像素 = 滚边带（d=1 是外描边，d=2..3 是滚边）
Q_LO, Q_HI = 0.25, 0.80   # 原图亮度分位区间（只用来给布面加一点点受光/背光起伏）

#            布色            滚边/包边      外描边          淡衣纹(墨线)   带宽-  带宽+  经纬  斑驳  交领  线宽
VARIANTS = {
    "1": dict(cloth=(162,156,144), hem=(132,126,115), edge=(52,48,42),  crease=(112,107,98), lo=-14, hi=+18, weave=(3, 2), mottle=4, hanfu=False),
    "2": dict(cloth=(141,135,125), hem=(114,109,100), edge=(48,45,40),  crease=(97,93,85),   lo=-13, hi=+17, weave=(3, 2), mottle=4, hanfu=False),
    "3": dict(cloth=(128,131,133), hem=(103,106,109), edge=(44,45,48),  crease=(88,91,94),   lo=-12, hi=+15, weave=(3, 3), mottle=3, hanfu=False),
    "4": dict(cloth=(141,135,125), hem=(112,107,98),  edge=(48,45,40),  crease=(99,95,87),   lo=-13, hi=+17, weave=(3, 2), mottle=4, hanfu=True),
    "5": dict(cloth=(150,144,133), hem=(118,112,103), edge=(50,47,42),  crease=(104,100,92), lo=-13, hi=+17, weave=(3, 2), mottle=4, hanfu=True, belt=True),
    # ↓ 精细 + 加深：留回原画墨线（line_thick 放宽），布色压深，明暗拉大，纱痕更细
    "6": dict(cloth=(136,130,120), hem=(108,103,95),  edge=(44,41,37),  crease=(88,84,77),   lo=-22, hi=+20, weave=(2, 2), mottle=3, hanfu=True, belt=True, line_thick=5, ink=42),
    "7": dict(cloth=(120,115,106), hem=( 95, 91, 84), edge=(40,38,34),  crease=(76,73,67),   lo=-24, hi=+18, weave=(2, 2), mottle=3, hanfu=True, belt=True, line_thick=5, ink=42),
    "8": dict(cloth=(108,106,104), hem=( 86, 85, 84), edge=(36,35,34),  crease=(68,67,66),   lo=-24, hi=+16, weave=(2, 2), mottle=3, hanfu=True, belt=True, line_thick=6, ink=34),
}
V_HALF_W = 0.28        # 交领 V 的半宽（占衣服宽度比例）
V_TOP, V_DEPTH = 0.10, 0.32   # V 起于衣服顶部 10% 处，中缝处下探到顶部 42%
V_BAND = 2             # 襟边（领缘）带半宽 px
BELT_AT, BELT_H = 0.72, 5     # 腰带：衣服顶部起 72% 处，5px 高


def luma(r, g, b):
    return 0.299 * r + 0.587 * g + 0.114 * b


def solid_mask(w, h, px):
    return bytearray(1 if px[i*4+3] > A_SOLID else 0 for i in range(w * h))


def outside_and_depth(w, h, solid):
    """从画面边界 BFS 找外部，并给出每个实体像素到外部的 4 邻接步数。
       ★ D_MAX 必须够大：截断太小会让衣服内部深处的像素停在 0，被当成"边缘半透明"染暗
         （踩过：D_MAX=6 时 torso 有 71% 的像素落进这个坑）。"""
    D_MAX = 4096
    outside = bytearray(w * h)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            i = y * w + x
            if not solid[i] and not outside[i]:
                outside[i] = 1; q.append(i)
    for y in range(h):
        for x in (0, w - 1):
            i = y * w + x
            if not solid[i] and not outside[i]:
                outside[i] = 1; q.append(i)
    while q:
        i = q.popleft()
        x, y = i % w, i // w
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            X, Y = x + dx, y + dy
            if 0 <= X < w and 0 <= Y < h:
                j = Y * w + X
                if not solid[j] and not outside[j]:
                    outside[j] = 1; q.append(j)
    depth = bytearray(w * h)
    q = deque()
    for i in range(w * h):
        if solid[i]:
            x, y = i % w, i // w
            adj_out = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                X, Y = x + dx, y + dy
                if not (0 <= X < w and 0 <= Y < h) or outside[Y * w + X]:
                    adj_out = True; break
            if adj_out:
                depth[i] = 1; q.append(i)
    while q:
        i = q.popleft()
        d = depth[i]
        if d >= D_MAX:
            continue
        x, y = i % w, i // w
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            X, Y = x + dx, y + dy
            if 0 <= X < w and 0 <= Y < h:
                j = Y * w + X
                if solid[j] and depth[j] == 0:
                    depth[j] = d + 1; q.append(j)
    return depth


def thin_line_mask(w, h, px, thick_limit=None):
    """区分「细线」和「粗色块」——按深色连通域的**厚度**判：
       一个深色连通域内部最厚处 < thick_limit px → 细线（保留成衣纹）；否则是粗色块（整块当布料重画）。
       之前用 5x5 邻域计数会误判粗块的边缘，导致整件衣服都被衣纹色盖住。
       thick_limit 越大 → 越多原画墨线被保留 → 画面越"精细"。"""
    thick_limit = thick_limit or LINE_THICK
    dark = bytearray(w * h)
    for i in range(w * h):
        if px[i*4+3] > A_SOLID and luma(px[i*4], px[i*4+1], px[i*4+2]) < BLACK_CUT:
            dark[i] = 1
    keep = bytearray(w * h)
    seen = bytearray(w * h)
    for s in range(w * h):
        if not dark[s] or seen[s]:
            continue
        # 收集连通域
        comp = []
        q = deque([s]); seen[s] = 1
        while q:
            i = q.popleft(); comp.append(i)
            x, y = i % w, i // w
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                X, Y = x + dx, y + dy
                if 0 <= X < w and 0 <= Y < h:
                    j = Y * w + X
                    if dark[j] and not seen[j]:
                        seen[j] = 1; q.append(j)
        # 域内厚度（到域边界的 4 邻接步数）
        depth = {i: 0 for i in comp}
        q = deque()
        for i in comp:
            x, y = i % w, i // w
            edge = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                X, Y = x + dx, y + dy
                if not (0 <= X < w and 0 <= Y < h) or not dark[Y * w + X]:
                    edge = True; break
            if edge:
                depth[i] = 1; q.append(i)
        thick = 1
        while q:
            i = q.popleft()
            d = depth[i]
            if d > thick:
                thick = d
            if d >= LINE_THICK:
                continue
            x, y = i % w, i // w
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                X, Y = x + dx, y + dy
                if 0 <= X < w and 0 <= Y < h:
                    j = Y * w + X
                    if dark[j] and depth[j] == 0:
                        depth[j] = d + 1; q.append(j)
        if thick < LINE_THICK:
            for i in comp:
                keep[i] = 1
    return keep


def ink_line_mask(w, h, px, solid, thresh):
    """把原画的**明暗边界**描成 1px 墨线（Sobel 梯度）→ 衣褶/领口/接缝的线稿感。
       原画的深色区是一大坨连通块（用连通域厚度分不出线条），所以改用梯度找"结构"。"""
    ink = bytearray(w * h)
    if not thresh:
        return ink
    L = [0.0] * (w * h)
    for i in range(w * h):
        if solid[i]:
            L[i] = luma(px[i*4], px[i*4+1], px[i*4+2])
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            i = y * w + x
            if not solid[i]:
                continue
            gx = (L[i - w + 1] + 2 * L[i + 1] + L[i + w + 1]) - (L[i - w - 1] + 2 * L[i - 1] + L[i + w - 1])
            gy = (L[i + w - 1] + 2 * L[i + w] + L[i + w + 1]) - (L[i - w - 1] + 2 * L[i - w] + L[i - w + 1])
            if (abs(gx) + abs(gy)) * 0.25 > thresh:
                ink[i] = 1
    return ink


def percentiles(vals, qlo, qhi):
    s = sorted(vals)
    if not s:
        return 0.0, 1.0
    a = s[int(qlo * (len(s) - 1))]; b = s[int(qhi * (len(s) - 1))]
    return (a, b if b > a else a + 1)


def draw(im, cfg, seed=99, shape="torso"):
    w, h, px = im.w, im.h, im.px
    solid = solid_mask(w, h, px)
    depth = outside_and_depth(w, h, solid)
    line = thin_line_mask(w, h, px, cfg.get("line_thick"))
    ink = ink_line_mask(w, h, px, solid, cfg.get("ink"))
    body = [i for i in range(w * h) if solid[i] and not line[i] and depth[i] >= D_HEM + 1]
    qlo, qhi = percentiles([luma(px[i*4], px[i*4+1], px[i*4+2]) for i in body], Q_LO, Q_HI)
    # 版型几何（交领 / 腰带 用）
    xs = [i % w for i in range(w * h) if solid[i]]
    ys = [i // w for i in range(w * h) if solid[i]]
    x0, x1 = (min(xs), max(xs)) if xs else (0, w - 1)
    y0, y1 = (min(ys), max(ys)) if ys else (0, h - 1)
    W, H, cx = (x1 - x0 + 1), (y1 - y0 + 1), (x0 + x1) / 2.0
    hanfu = bool(cfg.get("hanfu")) and shape == "torso"
    belt = bool(cfg.get("belt")) and shape in ("torso", "pelvis")
    yb0 = y0 + BELT_AT * H if shape == "torso" else y0
    yb1 = yb0 + BELT_H
    out = Image(w, h); op = out.px
    wv, mv = cfg["weave"], cfg["mottle"]
    for i in range(w * h):
        a = px[i*4+3]
        if a == 0:
            continue
        dep = depth[i] if solid[i] else 0
        x, y = i % w, i // w
        # ── 第 1 层：按"离外面多远"铺底（外描边 → 滚边 → 布面/衣纹）──
        if not solid[i]:               # 边缘半透明像素：布色压暗
            base = cfg["cloth"]; off = -30
        elif dep <= 1:
            base = cfg["edge"]; off = 0
        elif dep <= D_HEM:
            base = cfg["cloth"]; off = -10   # 紧贴轮廓的一圈：淡淡包边（不抢戏）
        elif line[i] or ink[i]:
            Lln = luma(px[i*4], px[i*4+1], px[i*4+2])
            base = cfg["crease"]
            off = min(10.0, max(-16.0, (Lln - 15.0) * 0.9))   # 原墨线的深浅接着用
        else:
            base = cfg["cloth"]
            L = luma(px[i*4], px[i*4+1], px[i*4+2])
            t = (L - qlo) / (qhi - qlo)
            t = 0.0 if t < 0 else (1.0 if t > 1 else t)
            off = cfg["lo"] + t * (cfg["hi"] - cfg["lo"])
            off += (wv[0] if x % 4 == 0 else 0) - (wv[1] if y % 5 == 0 else 0)
            off += ((x * 7 + y * 13 + seed) % 11 - 5) * mv / 5.0
        # ── 第 2 层：交领（右衽）/ 腰带 —— 画在布面上，压过滚边，但不动外描边 ──
        if dep >= 2 and not line[i]:
            if hanfu:
                dn = min(1.0, abs(x - cx) / (V_HALF_W * W))
                ylap = y0 + (V_TOP + (V_DEPTH - V_TOP) * (1.0 - dn)) * H
                dy = y - ylap
                if abs(dy) <= V_BAND:
                    base = cfg["crease"]; off = -2                # 领缘（襟边）
                elif dy < 0:
                    base = cfg["cloth"]; off = 8                  # 领口内侧稍亮
                elif x < cx and dy <= V_BAND + 4:
                    base = cfg["crease"]; off = -8                # 右衽：左襟压过来那道边
            if belt and yb0 <= y <= yb1:
                base = cfg["crease"]
                off = -6 if (y == int(yb0) or y == int(yb1)) else 0   # 腰带上下缘稍深
        c = tuple(min(255, max(0, int(round(base[k] + off)))) for k in range(3))
        op[i*4], op[i*4+1], op[i*4+2] = c
        op[i*4+3] = a
    return out


def files_of(root, part):
    d = os.path.join(root, part)
    return [f for f in sorted(os.listdir(d), key=lambda f: int(f.rsplit("-", 1)[1].split(".")[0])) if f.endswith(".png")]


def rebuild_project_zip():
    out = os.path.join(PROJ, "musha.zip")
    if not os.path.exists(out):
        return None
    index = {}
    for root, _, fs in os.walk(PROJ):
        for f in fs:
            if f.lower().endswith(".png"):
                index[f] = os.path.join(root, f)
    n = 0; tmp = out + ".tmp"
    with zipfile.ZipFile(out) as zin, zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
        for it in zin.infolist():
            name = it.filename; base = os.path.basename(name)
            if name.lower().endswith(".png") and base in index:
                zout.write(index[base], name); n += 1
            else:
                zout.writestr(it, zin.read(name))
    os.replace(tmp, out)
    return out, n


def main():
    args = sys.argv[1:]
    if "--revert" in args:
        n = 0
        for part in os.listdir(BAK):
            src, dst = os.path.join(BAK, part), os.path.join(PROJ, part)
            if os.path.isdir(src):
                shutil.rmtree(dst, ignore_errors=True); shutil.copytree(src, dst); n += len(os.listdir(dst))
        print("已还原 %d 张；项目 zip：%s" % (n, rebuild_project_zip())); return
    if "--zip-only" in args:
        print("项目 zip：", rebuild_project_zip()); return
    if "--apply" in args:
        which = "4"
        i = args.index("--apply")
        if i + 1 < len(args) and args[i+1] in VARIANTS:
            which = args[i+1]
        n = 0
        for part in PARTS:
            shape = "torso" if part == "torso" else ("pelvis" if part == "torso_pelvis" else "arm")
            for f in files_of(BAK, part):
                write_png(os.path.join(PROJ, part, f), draw(read_png(os.path.join(BAK, part, f)), VARIANTS[which], shape=shape))
                n += 1
        print("已按候选 [%s] 重画 %d 张；项目 zip：%s" % (which, n, rebuild_project_zip()))
        return
    picks = [("torso", 0), ("torso", 5), ("torso", 9), ("torso_pelvis", 0), ("arm_upper", 0), ("arm_lower", 0)]
    rows = []
    for part, idx in picks:
        name = "%s-%d.png" % (part, idx)
        shape = "torso" if part == "torso" else ("pelvis" if part == "torso_pelvis" else "arm")
        ims = [read_png(os.path.join(BAK, part, name))]
        for k in ("5", "6", "7", "8"):
            ims.append(draw(ims[0], VARIANTS[k], shape=shape))
        rows.append((part, ims))
    pad = 10
    W = max(sum(im.w for im in ims) + pad * (len(ims) + 1) for _, ims in rows)
    H = sum(max(im.h for im in ims) + pad * 2 for _, ims in rows)
    canvas = Image(W, H)
    for y in range(H):
        for x in range(W):
            v = 96 if ((x // 12) + (y // 12)) % 2 == 0 else 128
            i = (y * W + x) * 4
            canvas.px[i:i+4] = bytes((v, v, v + 4, 255))
    y = 0
    for _, ims in rows:
        x = pad
        for im in ims:
            blit(canvas, im, x, y + pad); x += im.w + pad
        y += max(im.h for im in ims) + pad * 2
    p = os.path.join(OUTDIR, "cn_cloth_variants.png")
    write_png(p, canvas)
    print("对照图（每行：原图 | 5 旧(浅) | 6 精细中麻 | 7 精细加深 | 8 深青灰）：", p)


main()
