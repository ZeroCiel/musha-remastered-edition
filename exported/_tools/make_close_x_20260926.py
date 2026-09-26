#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""close_x 叉叉按钮 + panel_bg_alt 贴叉（2026-09-26 用户指示）

1) images/close_button_red.png 白底洪泛抠图 → _tmp/close_x.png（透明底、最长边 256）
2) images/panel_bg_alt.png 右上金星实测 bbox（HSV 阈值，窗口 x>=1300/y<240）
   → 叉叉贴纸定位：圆心=星质心，直径=2*最远角距+8（盖住金星，clamp 130..170）
3) 产物：
   _tmp/close_x.png               （发布：art_update.py publish _tmp/close_x.png close_x）
   _tmp/panel_bg_alt_with_x.png   （发布：art_update.py publish _tmp/panel_bg_alt_with_x.png panel_bg_alt）
   并打印 content 换算 → musha_panel_screen.lua close_btn 接线参数
"""
import os
import math
from collections import deque
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
IMAGES = os.path.join(HERE, "..", "..", "images")
TMP = os.path.join(HERE, "_tmp")
ICON_SRC = os.path.join(IMAGES, "close_button_red.png")
# ★ 09-26 B案重烤：images/panel_bg_alt.png 已是贴过叉的版本 → 必须从干净备份（含金星）烤
BG = os.path.join(HERE, "_art_backup", "panel_bg_alt_20260926_060807", "panel_bg_alt.png")
OUT_ICON = os.path.join(TMP, "close_x.png")
OUT_BG = os.path.join(TMP, "panel_bg_alt_with_x.png")
QC_CROP = os.path.join(TMP, "qc_close_corner.png")
QC_ONFRAME = os.path.join(TMP, "qc_close_onframe.png")

# display SetSize（musha_panel_screen.lua:538，1741 时代定的，保持不动）
SET_W, SET_H = 1285.1, 887.2

os.makedirs(TMP, exist_ok=True)

# ---- 1) 抠白底：边沿洪泛（min>228 & spread<26），X 白笔画被红圈包住不可达 ----
im = Image.open(ICON_SRC).convert("RGBA")
W, H = im.size
px = im.load()
print("icon src", W, "x", H)


def whiteish(c):
    r, g, b, a = c
    return a > 0 and min(r, g, b) > 228 and (max(r, g, b) - min(r, g, b)) < 26


q = deque()
for x in range(W):
    for y in (0, H - 1):
        if whiteish(px[x, y]):
            q.append((x, y))
for y in range(H):
    for x in (0, W - 1):
        if whiteish(px[x, y]):
            q.append((x, y))
seen = bytearray(W * H)
for x, y in q:
    seen[y * W + x] = 1
while q:
    x, y = q.popleft()
    px[x, y] = (0, 0, 0, 0)
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < W and 0 <= ny < H and not seen[ny * W + nx] and whiteish(px[nx, ny]):
            seen[ny * W + nx] = 1
            q.append((nx, ny))

ab = im.split()[3].getbbox()
icon = im.crop(ab)
iw, ih = icon.size
print("icon trimmed", iw, "x", ih)
# 最长边 256（显示约 130-170px，2x 余量）
if max(iw, ih) > 256:
    s = 256.0 / max(iw, ih)
    icon = icon.resize((max(1, int(round(iw * s))), max(1, int(round(ih * s)))), Image.LANCZOS)
    iw, ih = icon.size

# ---- 1.5) ★ 09-26 "叉号歪"第二因：X 字形比盘心低 5px（源 art 自带）→ 整体上移 5px ----
#   白笔画(8788px,c=(126,131)) ∪ 深红外描边(1754px,c=(126,131.5))，盘心 (126,126)
#   上移后挖空的底部 5 行：同行左右最近的非字形像素取色（红渐变自然补上）
import numpy as np
from scipy import ndimage

_a = np.array(icon)
_rgb = _a[..., :3].astype(np.int32)
_al = _a[..., 3]
_red = (_rgb[..., 0] > 150) & (_rgb[..., 1] < 110) & (_rgb[..., 2] < 110) & (_al > 60)
_lab, _n = ndimage.label(_red, structure=np.ones((3, 3), int))
_sizes = ndimage.sum(_red, _lab, range(1, _n + 1))
_disc = _lab == int(np.argmax(_sizes)) + 1
_disc = ndimage.binary_fill_holes(_disc)          # 白 X 是红盘上的洞 → 填洞才装得下字形
_ys, _xs = np.where(_disc)
_in = np.zeros(_disc.shape, bool)
_in[_ys.min() + 4:_ys.max() - 3, _xs.min() + 4:_xs.max() - 3] = True
_bright = (_rgb.min(axis=-1) > 165) & (_al > 60) & _in
_lb, _nb = ndimage.label(_bright, structure=np.ones((3, 3), int))
_sb = ndimage.sum(_bright, _lb, range(1, _nb + 1))
_glyph = _lb == int(np.argmax(_sb)) + 1          # 最亮最大连通域 = X 白笔画
_gy, _gx = np.where(_glyph)
_gbox = (_gx.min(), _gx.max(), _gy.min(), _gy.max())
_dark = (_rgb.max(axis=-1) < 95) & (_al > 60) & _in
_ld, _nd = ndimage.label(_dark, structure=np.ones((3, 3), int))
_best, _bo = None, -1                            # 描边 = 与白笔画 bbox 大幅重叠的最大深色域
for _i in range(1, _nd + 1):
    _yy, _xx = np.where(_ld == _i)
    if len(_xx) < 50:
        continue
    if not (_xx.min() <= _gbox[1] and _xx.max() >= _gbox[0] and
            _yy.min() <= _gbox[3] and _yy.max() >= _gbox[2]):
        continue
    _ov = int(((_xx >= _gbox[0]) & (_xx <= _gbox[1]) &
               (_yy >= _gbox[2]) & (_yy <= _gbox[3])).sum())
    if _ov > _bo:
        _bo, _best = _ov, _i
if _best:
    _glyph = _glyph | (_ld == _best)
_glyph = ndimage.binary_dilation(_glyph, iterations=1) & _disc   # +1px 吃掉抗锯齿边缘

_SHIFT = 5
_dst = np.roll(_glyph, -_SHIFT, axis=0)          # 上移后的字形占位（内容取原 y+5）
_vac = _glyph & ~_dst                            # 被腾空的底部 5 行 → 字形正下方同列取色补
_out = _a.copy()
_colb = np.full(_a.shape[1], -1, np.int32)       # 每列的字形底缘 y
for _x in range(_a.shape[1]):
    _ysc = np.where(_glyph[:, _x])[0]
    if _ysc.size:
        _colb[_x] = _ysc.max()
_vy, _vx = np.where(_vac)
for _y, _x in zip(_vy, _vx):
    _b = _colb[_x]
    _s = None
    for _d in (6, 10, 14, 18):                   # 字形底缘下方 6..18 行（红盘内部）
        _t = _b + _d
        if _t < _a.shape[0] and (not _glyph[_t, _x]) and _al[_t, _x] > 0:
            _s = _a[_t, _x]
            break
    if _s is None:                               # 兜底：同行左右最近非字形像素
        _keep = np.where(~_glyph[_y] & (_al[_y] > 0))[0]
        if _keep.size == 0:
            continue
        _l = _keep[_keep < _x]
        _r = _keep[_keep > _x]
        if _l.size and _r.size:
            _sx2 = _l[-1] if (_x - _l[-1]) <= (_r[0] - _x) else _r[0]
        elif _l.size:
            _sx2 = _l[-1]
        elif _r.size:
            _sx2 = _r[0]
        else:
            continue
        _s = _a[_y, _sx2]
    _out[_y, _x] = _s
# 上移：占位处取原图 y+SHIFT（字形内容整体上移）
_src_ok = _dst.copy()
_src_ok[_a.shape[0] - _SHIFT:] = False
_sy, _sx = np.where(_src_ok)
_out[_sy, _sx] = _a[_sy + _SHIFT, _sx]
icon = Image.fromarray(_out)
print("glyph shift: +5px up, vacated=%d, dst=%d" % (_vac.sum(), _dst.sum()))

icon.save(OUT_ICON)
print("out icon", OUT_ICON, iw, "x", ih)

# ---- 2) 底图 + 金星实测 ----
bg = Image.open(BG).convert("RGBA")
BW, BH = bg.size
bpx = bg.load()
print("bg", BW, "x", BH)

xs, ys = [], []
for y in range(45, 145):
    for x in range(1345, 1475):
        r, g, b, a = bpx[x, y]
        if a == 0:
            continue
        mx = max(r, g, b)
        mn = min(r, g, b)
        if mx == 0 or r < g or g < b:
            continue
        h = 60.0 * (g - b) / (mx - mn) if mx != mn else 0.0
        s = (mx - mn) / float(mx)
        # 星/亮金系 h36-58 s>=0.45 v>=150（框带亮部也进来，靠连通域分离）
        if 36.0 <= h <= 58.0 and s >= 0.45 and mx >= 150:
            xs.append(x)
            ys.append(y)

# ---- 连通域：星=被深棕描边包住的岛；框带触窗口边全弃 ----
mask = set(zip(xs, ys))
WIN_X0, WIN_Y0, WIN_X1, WIN_Y1 = 1345, 45, 1474, 144
comps = []
seen = set()
for p in mask:
    if p in seen:
        continue
    q = [p]
    seen.add(p)
    cells = []
    touches = False
    while q:
        x, y = q.pop()
        cells.append((x, y))
        if x in (WIN_X0, WIN_X1) or y in (WIN_Y0, WIN_Y1):
            touches = True
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                if dx == 0 and dy == 0:
                    continue
                np_ = (x + dx, y + dy)
                if np_ in mask and np_ not in seen:
                    seen.add(np_)
                    q.append(np_)
    if not touches:
        comps.append(cells)
print("components (islands only):")
best = None
for cells in sorted(comps, key=len, reverse=True)[:6]:
    ax = [c[0] for c in cells]
    ay = [c[1] for c in cells]
    print("  area=%d bbox=x%d..%d y%d..%d" %
          (len(cells), min(ax), max(ax), min(ay), max(ay)))
    if best is None and 600 <= len(cells) <= 6000 and 55 <= max(ax) - min(ax) + 1 <= 115 \
            and 40 <= max(ay) - min(ay) + 1 <= 95:
        best = cells

if not comps:
    print("!! star island not found -> fallback")
    best = None
else:
    # 邻岛合并：星的左右臂被饱和度谷切断成碎片（间隙 1-5px），单链接归并
    boxes = []
    for cells in comps:
        ax = [c[0] for c in cells]
        ay = [c[1] for c in cells]
        boxes.append((min(ax), max(ax), min(ay), max(ay), list(cells)))
    groups = [[b] for b in boxes]
    changed = True
    while changed:
        changed = False
        for i in range(len(groups)):
            for j in range(i + 1, len(groups)):
                if groups[i] is None or groups[j] is None:
                    continue
                def bgap(gs):
                    x0 = min(b[0] for b in gs); x1 = max(b[1] for b in gs)
                    y0 = min(b[2] for b in gs); y1 = max(b[3] for b in gs)
                    return x0, x1, y0, y1
                ax0, ax1, ay0, ay1 = bgap(groups[i])
                bx0, bx1, by0, by1 = bgap(groups[j])
                gx = max(0, max(ax0 - bx1, bx0 - ax1))
                gy = max(0, max(ay0 - by1, by0 - ay1))
                if max(gx, gy) <= 16:
                    groups[i] = groups[i] + groups[j]
                    groups[j] = None
                    changed = True
                    break
            if changed:
                break
    groups = [g for g in groups if g]
    best = None
    for g in sorted(groups, key=lambda g: sum(len(b[4]) for b in g), reverse=True):
        cells = [c for b in g for c in b[4]]
        ax = [c[0] for c in cells]
        ay = [c[1] for c in cells]
        print("  merged area=%d bbox=x%d..%d y%d..%d" %
              (len(cells), min(ax), max(ax), min(ay), max(ay)))
        if best is None and 600 <= len(cells) <= 6000 and 45 <= max(ax) - min(ax) + 1 <= 115 \
                and 40 <= max(ay) - min(ay) + 1 <= 95:
            best = cells

if not best:
    print("!! star island not found -> fallback")
    cx, cy, D = 1412.0, 85.0, 94
else:
    xs = [c[0] for c in best]
    ys = [c[1] for c in best]
    minx, maxx, miny, maxy = min(xs), max(xs), min(ys), max(ys)
    n = len(best)
    # ★ 09-26 B案（定案）：盘心 = 星 bbox 中心，不再从星顶下锚
    #   原圆顶锚星顶 extra=7 → 盘心 y98、盘底坠框下 65px（星只坠 29px）→ "歪"
    #   现盘心 (1412,85)；D 从 94 起，罩不住整星（含 3px 描边）才 +2（clamp 134）
    OUT = 3
    cx = (minx + maxx) / 2.0
    cy = (miny + maxy) / 2.0
    D = 94
    nbad = sum(1 for x, y in zip(xs, ys) if math.hypot(x - cx, y - cy) + OUT > D / 2.0)
    while nbad and D <= 134:
        D += 2
        nbad = sum(1 for x, y in zip(xs, ys) if math.hypot(x - cx, y - cy) + OUT > D / 2.0)
    print("star n=%d bbox=x%d..%d y%d..%d -> B案 D=%d center=(%.1f,%.1f) uncovered=%d"
          % (n, minx, maxx, miny, maxy, D, cx, cy, nbad))

# 掩码可视化 QC（红点覆盖，2x）
vis = bg.crop((1300, 30, 1536, 200)).convert("RGB")
vis = vis.resize((vis.width * 2, vis.height * 2), Image.NEAREST)
vp = vis.load()
for x, y in zip(xs, ys):
    vx, vy = (x - 1300) * 2, (y - 30) * 2
    if 0 <= vx < vis.width and 0 <= vy < vis.height:
        vp[vx, vy] = (255, 0, 0)
vis.save(QC_CROP)

# ---- 3) 贴叉（保纵横比，圆心=星质心）----
disp_h = D
disp_w = int(round(D * iw / float(ih)))
icon_r = icon.resize((disp_w, disp_h), Image.LANCZOS)
left = int(round(cx - disp_w / 2.0))
top = int(round(cy - disp_h / 2.0))
bg.alpha_composite(icon_r, (left, top))
bg.save(OUT_BG)
print("out bg", OUT_BG, "paste @(%d,%d) %dx%d" % (left, top, disp_w, disp_h))

# QC 裁片（右上角成品 + 贴在框上的图标本体）
bg.crop((1280, 30, BW, 300)).save(QC_CROP)
orange = Image.new("RGBA", (disp_w + 40, disp_h + 40), (217, 142, 74, 255))
orange.alpha_composite(icon_r, (20, 20))
orange.save(QC_ONFRAME)

# ---- 4) content 换算（接线参数）----
ccx = (cx - BW / 2.0) * SET_W / BW
ccy = (BH / 2.0 - cy) * SET_H / BH
cw = disp_w * SET_W / BW
ch = disp_h * SET_H / BH
hot_w = cw + 4
hot_h = ch + 4
print("content center = (%.1f, %.1f)" % (ccx, ccy))
print("content visual = %.1f x %.1f" % (cw, ch))
print("content hot    = %.1f x %.1f  (ForceImageSize)" % (hot_w, hot_h))
print("setpos: SetPosition(%.1f, %.1f) ForceImageSize(%.1f, %.1f)" % (ccx, ccy, hot_w, hot_h))
