#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
月牙「方向图」生成器（纯标准库，不需要 PIL / 不需要联网 / 不需要即梦额度）

背景（为什么要这么麻烦）：
  贴图是 OnGround（平铺在地面平面）的，游戏会把地面平面**投影**成"转 45° + 纵向压缩 k"的样子。
  直接让引擎原地旋转贴图 → 斜着飞的时候贴图被压扁（"光和面倾斜"），怎么调都不像洛克人 ZERO。
  解法 = 每个方向各画一张，贴图不旋转。这张脚本负责"把一张原图自动派生成 8 张"：
  先在美术空间做反向补偿  M = P⁻¹ · R(Δ) · P  （P = 地面投影矩阵，R = 画面内旋转）
  这样游戏投影之后，**画面上看到的**正好是"月牙朝着该飞行方向"的样子，不再压扁。

用法：
    python make_dirs.py                 # 用同目录的 crescent_cyan-0.png
    python make_dirs.py 别的图.png      # 指定底图
可调参数就在下面 CONFIG 区（K / PHASE_DEG / COUNT / CANVAS）。

输出（同目录 dirs/ 下）：
    crescent_dir0.png … crescent_dir7.png   8 张方向图（1280x1280，RU 透明底）
    crescent_cyan8.scml                     配套 Spriter 工程（8 个动画 anim_0..anim_7）
    _preview_all8.png                       8 张拼一起的预览图
    README.txt                              打包步骤
"""

import math
import os
import struct
import sys
import zlib

# ============ CONFIG（要校准就改这里）============
K         = 0.5      # 地面纵向压缩（DST 相机近似 2:1 俯视）——画面上"斜飞的月牙扁不扁"不对就调它
PHASE_DEG = 0.0      # 全局相位（度）：8 张整体偏了一个角度就调它（±45 以内微调）
COUNT     = 8        # 方向数（8 = 每 45° 一张）
CANVAS    = 1280     # 新画布边长（要比 512 大：反向补偿会把图拉长，得留余量）
BASE_NAME = "crescent_cyan-0.png"
OUT_DIR   = "dirs"
ANIM_FMT  = "anim_%d"          # 动画名格式（代码里的 FX_DIRS 要跟它对上）
KNOWN_MARK = 0.70710678
# ===============================================


# ---------- PNG 读（照搬 桌面/tex导出工具/recolor.py 的纯标准库实现）----------
def read_png(path):
    b = open(path, "rb").read()
    if b[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("不是 PNG：%s" % path)
    pos, idat = 8, b""
    w = h = bitd = ctype = None
    while pos < len(b):
        ln = struct.unpack(">I", b[pos:pos + 4])[0]
        tag = b[pos + 4:pos + 8]
        data = b[pos + 8:pos + 8 + ln]
        if tag == b"IHDR":
            w, h, bitd, ctype = struct.unpack(">IIBB", data[:10])
        elif tag == b"IDAT":
            idat += data
        pos += 12 + ln
    if bitd != 8:
        raise ValueError("只支持 8bit PNG")
    ch = {0: 1, 2: 3, 4: 2, 6: 4}[ctype]
    raw = zlib.decompress(idat)
    stride = w * ch
    prev = bytearray(stride)
    rows = []
    i = 0

    def paeth(a, bb, c):
        pa = abs(bb - c); pb = abs(a - c); pc = abs(a + bb - 2 * c)
        return a if (pa <= pb and pa <= pc) else (bb if pb <= pc else c)

    for _y in range(h):
        f = raw[i]; i += 1
        line = bytearray(raw[i:i + stride]); i += stride
        if f == 1:
            for x in range(ch, stride):
                line[x] = (line[x] + line[x - ch]) & 255
        elif f == 2:
            for x in range(stride):
                line[x] = (line[x] + prev[x]) & 255
        elif f == 3:
            for x in range(stride):
                a = line[x - ch] if x >= ch else 0
                line[x] = (line[x] + ((a + prev[x]) >> 1)) & 255
        elif f == 4:
            for x in range(stride):
                a = line[x - ch] if x >= ch else 0
                c = prev[x - ch] if x >= ch else 0
                line[x] = (line[x] + paeth(a, prev[x], c)) & 255
        rows.append(line)
        prev = line
    return w, h, ch, rows


def to_rgba(w, h, ch, rows):
    """统一成 (w,h,[(r,g,b,a)...])"""
    px = []
    for y in range(h):
        line = rows[y]
        for x in range(w):
            o = x * ch
            if ch == 1:
                v = line[o]; px.append((v, v, v, 255))
            elif ch == 2:
                v = line[o]; px.append((v, v, v, line[o + 1]))
            elif ch == 3:
                px.append((line[o], line[o + 1], line[o + 2], 255))
            else:
                px.append((line[o], line[o + 1], line[o + 2], line[o + 3]))
    return px


def write_png(path, w, h, px):
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        row = px[y * w:(y + 1) * w]
        for (r, g, b, a) in row:
            raw += bytes((r, g, b, a))

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + \
            struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(bytes(raw), 6))
           + chunk(b"IEND", b""))
    open(path, "wb").write(png)


# ---------- 矩阵小工具（2x2，行主序 [a b; c d]）----------
def mat_mul(m, n):
    return [m[0] * n[0] + m[1] * n[2], m[0] * n[1] + m[1] * n[3],
            m[2] * n[0] + m[3] * n[2], m[2] * n[1] + m[3] * n[3]]


def mat_apply(m, vx, vy):
    return (m[0] * vx + m[1] * vy, m[2] * vx + m[3] * vy)


def mat_inv(m):
    det = m[0] * m[3] - m[1] * m[2]
    if abs(det) < 1e-12:
        raise ValueError("矩阵不可逆")
    return [m[3] / det, -m[1] / det, -m[2] / det, m[0] / det]


def rot_mat(deg):
    r = math.radians(deg)
    c, s = math.cos(r), math.sin(r)
    return [c, -s, s, c]


# ---------- 底图几何：质心 / 两个尖端 / "凸面朝向" ----------
def analyse(px, w, h):
    pts = []
    for y in range(h):
        base = y * w
        for x in range(w):
            if px[base + x][3] > 8:
                pts.append((x, y))
    if not pts:
        raise ValueError("底图全透明？")
    n = len(pts)
    cx = sum(p[0] for p in pts) / n
    cy = sum(p[1] for p in pts) / n
    # 主轴（PCA）
    sxx = syy = sxy = 0.0
    for (x, y) in pts:
        dx, dy = x - cx, y - cy
        sxx += dx * dx; syy += dy * dy; sxy += dx * dy
    theta = 0.5 * math.atan2(2 * sxy, (sxx - syy))
    ax, ay = math.cos(theta), math.sin(theta)
    lo = min(pts, key=lambda p: (p[0] - cx) * ax + (p[1] - cy) * ay)
    hi = max(pts, key=lambda p: (p[0] - cx) * ax + (p[1] - cy) * ay)
    tips_mid = ((lo[0] + hi[0]) / 2.0, (lo[1] + hi[1]) / 2.0)
    # 凸面方向 = 质心 - 两个尖端的连线中点（月牙的鼓面朝这边）
    dx, dy = cx - tips_mid[0], cy - tips_mid[1]
    ln = math.hypot(dx, dy)
    if ln < 1e-6:
        dx, dy, ln = 1.0, 0.0, 1.0
    d_art = (dx / ln, dy / ln)
    bbox = (min(p[0] for p in pts), min(p[1] for p in pts),
            max(p[0] for p in pts), max(p[1] for p in pts))
    return (cx, cy), d_art, bbox, n


def bilinear(px, w, h, sx, sy):
    """预乘 alpha 的双线性采样（免得边缘发黑）"""
    if sx < 0 or sy < 0 or sx > w - 1 or sy > h - 1:
        return (0, 0, 0, 0)
    x0, y0 = int(math.floor(sx)), int(math.floor(sy))
    x1, y1 = min(x0 + 1, w - 1), min(y0 + 1, h - 1)
    fx, fy = sx - x0, sy - y0
    out = [0.0, 0.0, 0.0, 0.0]
    for (xi, yi, wgt) in ((x0, y0, (1 - fx) * (1 - fy)), (x1, y0, fx * (1 - fy)),
                          (x0, y1, (1 - fx) * fy), (x1, y1, fx * fy)):
        if wgt <= 0.0:
            continue
        r, g, b, a = px[yi * w + xi]
        al = a / 255.0
        out[0] += r * al * wgt; out[1] += g * al * wgt; out[2] += b * al * wgt; out[3] += a * wgt
    a = out[3]
    if a <= 0.5:
        return (0, 0, 0, 0)
    al = a / 255.0
    r = min(255, int(out[0] / al + 0.5))
    g = min(255, int(out[1] / al + 0.5))
    b = min(255, int(out[2] / al + 0.5))
    return (r, g, b, min(255, int(a + 0.5)))


def main(argv):
    src = argv[0] if argv else BASE_NAME
    here = os.path.dirname(os.path.abspath(__file__))
    src_path = src if os.path.isabs(src) else os.path.join(here, src)
    out_dir = os.path.join(here, OUT_DIR)
    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)

    w, h, ch, rows = read_png(src_path)
    px = to_rgba(w, h, ch, rows)
    (cx, cy), d_art, bbox, npx = analyse(px, w, h)
    print("底图 %dx%d  不透明像素 %d  bbox=%s  质心=(%.1f,%.1f)" % (w, h, npx, bbox, cx, cy))
    print("凸面朝向（美术空间）= (%.3f, %.3f)  即 %.1f°" %
          (d_art[0], d_art[1], math.degrees(math.atan2(d_art[1], d_art[0]))))

    # 地面投影 P：美术(u,v) → 画面(sx,sy)      sx=(u-v)/√2,  sy=-k(u+v)/√2
    P = [KNOWN_MARK, -KNOWN_MARK, -KNOWN_MARK * K, -KNOWN_MARK * K]
    Pinv = mat_inv(P)

    # 底图在**画面**里朝向的角度
    bsx, bsy = mat_apply(P, d_art[0], d_art[1])
    ang_base = math.degrees(math.atan2(bsy, bsx))
    print("底图在画面里的朝向 = %.1f°" % ang_base)

    NC = CANVAS
    cc_new = (NC / 2.0, NC / 2.0)
    names = []
    for m in range(COUNT):
        theta = (360.0 / COUNT) * m + (180.0 / COUNT)      # 该桶的中心角（世界 +X 起，往 +Z）
        t = math.radians(theta)
        sx, sy = mat_apply(P, math.cos(t), math.sin(t))
        ang_want = math.degrees(math.atan2(sy, sx))
        d = ang_want - ang_base + PHASE_DEG
        M = mat_mul(mat_mul(Pinv, rot_mat(d)), P)           # 美术空间：先摆正、再让画面旋转 d°
        Minv = mat_inv(M)

        out = [(0, 0, 0, 0)] * (NC * NC)
        # 只扫"原图 bbox 映射到新画布"的那块（外面一定是空的，省一大半时间）
        corners = []
        for (px0, py0) in ((bbox[0], bbox[1]), (bbox[2], bbox[1]),
                           (bbox[0], bbox[3]), (bbox[2], bbox[3])):
            ux, uy = px0 - cx, py0 - cy
            rx, ry = mat_apply(M, ux, uy)
            corners.append((rx + cc_new[0], ry + cc_new[1]))
        x_lo = max(0, int(min(c[0] for c in corners)) - 2)
        x_hi = min(NC - 1, int(max(c[0] for c in corners)) + 2)
        y_lo = max(0, int(min(c[1] for c in corners)) - 2)
        y_hi = min(NC - 1, int(max(c[1] for c in corners)) + 2)

        for oy in range(y_lo, y_hi + 1):
            ry = oy - cc_new[1]
            ux = Minv[0] * (x_lo - cc_new[0]) + Minv[1] * ry
            uy = Minv[2] * (x_lo - cc_new[0]) + Minv[3] * ry
            row = oy * NC
            for ox in range(x_lo, x_hi + 1):
                out[row + ox] = bilinear(px, w, h, cx + ux, cy + uy)
                ux += Minv[0]
                uy += Minv[2]

        # 把新质心对齐到画布中心（保证游戏的 pivot=画布中心 就是月牙中心）
        bx0, by0, bx1, by1 = _bbox(out, NC, NC)
        if bx1 > bx0:
            mx, my = (bx0 + bx1) / 2.0, (by0 + by1) / 2.0
            dx2, dy2 = int(round(cc_new[0] - mx)), int(round(cc_new[1] - my))
            if dx2 or dy2:
                out = _shift(out, NC, NC, dx2, dy2)

        name = "crescent_dir%d.png" % m
        write_png(os.path.join(out_dir, name), NC, NC, out)
        names.append(name)
        print("  %-22s 世界角 %.0f°  画面旋转 %+.1f°  bbox=%s" %
              (name, theta, d, _bbox(out, NC, NC)))

    # 拼预览（4x2 网格，缩到 1/4）
    _preview(os.path.join(out_dir, "_preview_all8.png"), out_dir, names, NC)

    # 配套 scml（8 个动画 anim_0..anim_7，pivot 都在画布中心）
    scml = ['<?xml version="1.0" encoding="UTF-8"?>',
            '<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="r7">',
            '    <folder id="0" name="crescent_cyan8">']
    for i, nm in enumerate(names):
        scml.append('        <file id="%d" name="%s" width="%d" height="%d" pivot_x="0.5" pivot_y="0.5"/>'
                    % (i, nm, NC, NC))
    scml.append('    </folder>')
    scml.append('    <entity id="0" name="crescent_cyan8">')
    for i, nm in enumerate(names):
        scml.append('        <animation id="%d" name="%s" length="1000" interval="100">' % (i, ANIM_FMT % i))
        scml.append('            <mainline>')
        scml.append('                <key id="0">')
        scml.append('                    <object_ref id="0" timeline="0" key="0" z_index="0"/>')
        scml.append('                </key>')
        scml.append('            </mainline>')
        scml.append('            <timeline id="0" name="%s">' % (ANIM_FMT % i))
        scml.append('                <key id="0" spin="0">')
        scml.append('                    <object folder="0" file="%d" x="0" y="0"/>' % i)
        scml.append('                </key>')
        scml.append('            </timeline>')
        scml.append('        </animation>')
    scml.append('    </entity>')
    scml.append('</spriter_data>')
    open(os.path.join(out_dir, "crescent_cyan8.scml"), "w", encoding="utf-8").write("\n".join(scml) + "\n")

    readme = """crescent_cyan8 —— 月牙方向图打包说明
=====================================
这里 8 张 crescent_dir0..7.png 是由 make_dirs.py 从 crescent_cyan-0.png 自动派生的
（世界 +X 起，每 45° 一张；画面角度已经做过"地面投影反向补偿"，所以斜飞不会被压扁）。

打包步骤（DST Mod Tool）：
  1. 打开 dirs/crescent_cyan8.scml → 导出 → 得到 crescent_cyan8.zip
  2. 把 zip 放进 mods/musha/anim/crescent_cyan8.zip
  3. 改 scripts/prefabs/musha_slash_qi_fx.lua 的 FX_ART："cyan" → "cyan8"
     （那张表里已经有 cyan8 一项，含 dirs = { anim_0 … anim_7 }）
  4. 进游戏，8 个方向各放一次，看有没有"哪一张歪了/扁了"

校准（改一个数重跑 make_dirs.py 再导一次即可）：
  · 8 张整体偏同一角度 → PHASE_DEG（度）
  · 斜飞的月牙被压扁/拉长 → K（大=更扁，默认 0.5）
  · 方向顺序整体反了（比如朝右的用了朝左的图）→ 代码里 DIR_CCW 取反
"""
    open(os.path.join(out_dir, "README.txt"), "w", encoding="utf-8").write(readme)
    print("\n输出目录：%s" % out_dir)
    return 0


def _bbox(px, w, h):
    bx0, by0, bx1, by1 = w, h, -1, -1
    for y in range(h):
        base = y * w
        for x in range(w):
            if px[base + x][3] > 8:
                if x < bx0: bx0 = x
                if y < by0: by0 = y
                if x > bx1: bx1 = x
                if y > by1: by1 = y
    return (bx0, by0, bx1, by1)


def _shift(px, w, h, dx, dy):
    out = [(0, 0, 0, 0)] * (w * h)
    for y in range(h):
        ny = y + dy
        if ny < 0 or ny >= h:
            continue
        for x in range(w):
            nx = x + dx
            if 0 <= nx < w:
                out[ny * w + nx] = px[y * w + x]
    return out


def _preview(path, out_dir, names, n):
    """4x2 网格，每格缩小 1/4"""
    s = n // 4
    gw, gh = s * 4, s * 2
    grid = [(0, 0, 0, 0)] * (gw * gh)
    for i, nm in enumerate(names):
        w, h, ch, rows = read_png(os.path.join(out_dir, nm))
        px = to_rgba(w, h, ch, rows)
        gx, gy = (i % 4) * s, (i // 4) * s
        for y in range(s):
            for x in range(s):
                r, g, b, a = px[(y * 4) * w + (x * 4)]
                grid[(gy + y) * gw + (gx + x)] = (r, g, b, a)
    write_png(path, gw, gh, grid)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
