"""把 musha 默认衣服「重新画」成灰色粗布衣（不是去色）。

思路（三段式，保证版型/动画不错位）：
  1) 版型   = 原图的 alpha 通道（衣服轮廓、每帧位置完全不动，pivot 不变）
  2) 明暗底 = 原图亮度（保留衣服的立体褶皱关系，但对比度可压平 → 更像一整块布）
  3) 布面   = 程序化织出来的：低频褶皱噪声 + 3px 交织织纹 + 沿轮廓 2px 的缝边虚线
  描边（近黑像素）原样保留 → 角色轮廓线不丢。

用法：
    python draw_cloth.py                 # 干跑：只出候选预览图
    python draw_cloth.py --apply a|b|c   # 备份原图 → 调用某个候选覆盖（默认 b）
    python draw_cloth.py --revert        # 从备份还原（原图在 _bak_musha_outfit）

候选（改 VARIANTS 里的数就行，越大越明显）：
    a 细腻布   b 粗糙布（默认）   c 素布/毡布（对比最平、补丁）
"""
import os, sys, shutil, zipfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image, blit

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.normpath(os.path.join(HERE, "..", "musha"))
BAK = os.path.normpath(os.path.join(HERE, "..", "_bak_musha_outfit"))
OUTDIR = os.path.join(HERE, "_test_out")

PARTS = ["torso", "torso_pelvis", "arm_upper", "arm_lower", "arm_upper_skin"]

BLACK_CUT = 30          # 亮度低于此值 = 深色（可能是描边，也可能是衣服的深色块）
LINE_NEI = 5            # 深色像素 5x5 邻域里"亮邻居"≥此数 → 判定为线稿（保留），否则当布料
T_RANGE = 150.0         # 原图亮度归一到 0..1 的上限

#   中灰   明暗跨度 褶皱 ± 织纹 ± 缝线压暗 补丁  色调(微冷灰)
VARIANTS = {
    "a": dict(mid=128, span=72, fold=10, weave=5,  contrast=1.0, seam=0.86, patch=False, tint=(0.985, 1.0, 1.050)),
    "b": dict(mid=122, span=80, fold=17, weave=11, contrast=1.0, seam=0.78, patch=False, tint=(0.985, 1.0, 1.050)),
    "c": dict(mid=138, span=58, fold=8,  weave=15, contrast=1.0, seam=0.90, patch=True,  tint=(1.0,   1.0, 1.030)),
}


def dark_line_mask(w, h, px):
    """区分「线稿」和「衣服上的深色块」：
       深色像素 5x5 邻域里亮像素/透明像素多 → 是描边或细线（保留）；
       四周全是深色 → 是一大块深色布料（重画成灰布）。"""
    dark = bytearray(w * h)
    for i in range(w * h):
        if px[i * 4 + 3] > 110 and luma(px[i * 4], px[i * 4 + 1], px[i * 4 + 2]) < BLACK_CUT:
            dark[i] = 1
    keep = bytearray(w * h)
    for y in range(h):
        for x in range(w):
            i = y * w + x
            if not dark[i]:
                continue
            light = 0
            for dy in range(-2, 3):
                Y = y + dy
                if Y < 0 or Y >= h:
                    light += 5
                    continue
                for dx in range(-2, 3):
                    X = x + dx
                    if X < 0 or X >= w:
                        light += 1
                    else:
                        j = Y * w + X
                        if px[j * 4 + 3] < 110 or not dark[j]:
                            light += 1
            if light >= LINE_NEI:
                keep[i] = 1
    return keep


def luma(r, g, b):
    return 0.299 * r + 0.587 * g + 0.114 * b


def h2(x, y, seed):
    n = (x * 374761393 + y * 668265263 + seed * 2246822519) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    n ^= n >> 16
    return (n & 0xFFFF) / 65535.0


def smooth(t):
    return t * t * (3 - 2 * t)


_noise_cache = {}


def noise_field(w, h, seed):
    """返回 (fold, weave) 两张 w*h 的 -1..1 浮点场；同尺寸只算一次（多帧复用）。"""
    key = (w, h, seed)
    if key in _noise_cache:
        return _noise_cache[key]
    fold = [0.0] * (w * h)
    weave = [0.0] * (w * h)
    for y in range(h):
        for x in range(w):
            # 低频褶皱：竖直方向拉长（布料下垂），两个八度叠加
            v = 0.0
            for scale, amp in ((7.0, 1.0), (17.0, 0.55)):
                gx, gy = x / scale, y / (scale * 2.1)
                ix, iy = int(gx), int(gy)
                fx, fy = smooth(gx - ix), smooth(gy - iy)
                c00 = h2(ix, iy, seed)
                c10 = h2(ix + 1, iy, seed)
                c01 = h2(ix, iy + 1, seed)
                c11 = h2(ix + 1, iy + 1, seed)
                top = c00 + (c10 - c00) * fx
                bot = c01 + (c11 - c01) * fx
                v += (top + (bot - top) * fy - 0.5) * 2.0 * amp
            fold[y * w + x] = v
            # 交织织纹：3px 格子交错 + 少量随机跳线（粗布的经纬感）
            cell = ((x // 3) ^ (y // 3)) & 1
            if h2(x // 3, y // 3, seed + 977) < 0.14:
                cell ^= 1
            weave[y * w + x] = 1.0 if cell else -1.0
    _noise_cache[key] = (fold, weave)
    return fold, weave


def seam_ring(w, h, px, depth=2):
    """轮廓内缩 depth 像素的环（缝边线走向），返回 set of idx。"""
    inside = set()
    for y in range(h):
        for x in range(w):
            if px[(y * w + x) * 4 + 3] > 110:
                inside.add(y * w + x)
    ring = inside
    for _ in range(depth):
        ring = {i for i in ring
                if (i % w) > 0 and (i % w) < w - 1 and i >= w and i < w * (h - 1)
                and (i - 1) in ring and (i + 1) in ring and (i - w) in ring and (i + w) in ring}
    return ring


def patch_zone(w, h, px, x0f, y0f, wf, hf):
    """一小块补丁区域（按比例给定），只取落在衣服上的像素。"""
    x0, y0 = int(w * x0f), int(h * y0f)
    x1, y1 = x0 + int(w * wf), y0 + int(h * hf)
    out = set()
    for y in range(max(0, y0), min(h, y1)):
        for x in range(max(0, x0), min(w, x1)):
            if px[(y * w + x) * 4 + 3] > 110:
                out.add(y * w + x)
    return out


PATCH_SPOTS = [((0.42, 0.62, 0.20, 0.16), -22), ((0.20, 0.30, 0.14, 0.12), -14)]


def draw(im, cfg, seed=1337):
    w, h, px = im.w, im.h, im.px
    fold, weave = noise_field(w, h, seed)
    seam = seam_ring(w, h, px)
    line = dark_line_mask(w, h, px)
    patches = []
    if cfg["patch"]:
        for (spot, darken) in PATCH_SPOTS:
            patches.append((patch_zone(w, h, px, *spot), darken))
    out = Image(w, h)
    op = out.px
    for i in range(w * h):
        a = px[i * 4 + 3]
        if a == 0:
            continue
        r, g, b = px[i * 4], px[i * 4 + 1], px[i * 4 + 2]
        L = luma(r, g, b)
        if line[i]:
            v = L * 1.02                       # 描边/细线：只去色，亮度保留
        else:
            # 灰布本体：以「中灰 + 原图明暗（压低权重）+ 布面噪声」重画
            t = min(1.0, max(0.0, (L - BLACK_CUT) / T_RANGE))
            v = cfg["mid"] + (t - 0.5) * cfg["span"]
            v += fold[i] * cfg["fold"] + weave[i] * cfg["weave"]
            if i in seam and ((i % w) + (i // w)) % 3 != 0:
                v *= cfg["seam"]                # 缝边虚线
            for zone, darken in patches:
                if i in zone:
                    v += darken
        v = min(255.0, max(0.0, v))
        t0, t1, t2 = cfg["tint"]
        op[i * 4] = min(255, max(0, int(round(v * t0))))
        op[i * 4 + 1] = min(255, max(0, int(round(v * t1))))
        op[i * 4 + 2] = min(255, max(0, int(round(v * t2))))
        op[i * 4 + 3] = a
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
    n = 0
    tmp = out + ".tmp"
    with zipfile.ZipFile(out) as zin, zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
        for it in zin.infolist():
            name = it.filename
            base = os.path.basename(name)
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
                shutil.rmtree(dst, ignore_errors=True); shutil.copytree(src, dst)
                n += len(os.listdir(dst))
        print("已还原 %d 张，项目 zip：%s" % (n, rebuild_project_zip())); return
    if "--zip-only" in args:
        print("项目 zip：", rebuild_project_zip()); return

    apply_ = "--apply" in args
    which = "b"
    for i, a in enumerate(args):
        if a == "--apply" and i + 1 < len(args) and args[i + 1] in VARIANTS:
            which = args[i + 1]
    os.makedirs(OUTDIR, exist_ok=True)

    if apply_:
        if not os.path.isdir(BAK):     # 首次：从当前（可能是灰版）起不来 → 强制要求原图备份存在
            print("缺原图备份：", BAK); return
        cfg = VARIANTS[which]
        n = 0
        for part in PARTS:
            for f in files_of(BAK, part):
                im = draw(read_png(os.path.join(BAK, part, f)), cfg)
                write_png(os.path.join(PROJ, part, f), im); n += 1
        print("已按候选 [%s] 重画 %d 张；项目 zip：%s" % (which, n, rebuild_project_zip()))
        return

    # 干跑：出一张对照图（原图 | a | b | c）
    rows = []
    picks = [("torso", 0), ("torso", 5), ("arm_upper", 0), ("arm_lower", 0), ("torso_pelvis", 0)]
    for part, idx in picks:
        name = "%s-%d.png" % (part, idx)
        ims = [read_png(os.path.join(BAK, part, name))]
        for k in ("a", "b", "c"):
            ims.append(draw(ims[0], VARIANTS[k]))
        rows.append((part, ims))
    pad = 10
    W = max(sum(im.w for im in ims) + pad * (len(ims) + 1) for _, ims in rows)
    H = sum(max(im.h for im in ims) + pad * 2 for _, ims in rows)
    canvas = Image(W, H)
    for y in range(H):
        for x in range(W):
            v = 100 if ((x // 12) + (y // 12)) % 2 == 0 else 132
            i = (y * W + x) * 4
            canvas.px[i:i + 4] = bytes((v, v, v + 4, 255))
    y = 0
    for _, ims in rows:
        x = pad
        for im in ims:
            blit(canvas, im, x, y + pad); x += im.w + pad
        y += max(im.h for im in ims) + pad * 2
    p = os.path.join(OUTDIR, "cloth_variants.png")
    write_png(p, canvas)
    print("候选对照图（每行：原图 | a 细腻 | b 粗糙 | c 素布）：", p)
    print("定稿：python draw_cloth.py --apply b")


main()
