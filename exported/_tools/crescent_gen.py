#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
月牙（剑气斩）素材生成器 —— 一把梭：底图 + N 张方向图 + Spriter 工程(.scml)
================================================================================
2026-09-14 重写版。原来的 make_lightslash.py + make_dirs.py 被清掉了（打包目录
不能放脚本），这里把两步合成一个文件，逻辑跟旧版**逐行一致**：
  · 底图 = 两等圆差集(lune) → 严格关于长轴对称的弓形月牙 + 辉光 + 白刃口
  · 方向图 = 世界方向映射到**屏幕方向**后做**画面平面纯旋转**（BILLBOARD 模式，
    贴图立着正对镜头、不吃 Y 轴旋转 —— 见 musha_slash_qi_fx.lua 的注释）
  · 每张图把月牙 bbox 居中到画布中心（游戏 pivot = 画布中心）

用法
----
    python crescent_gen.py                     # 默认写到同级 ../crescent_cyan/
    python crescent_gen.py 别的输出目录
    python crescent_gen.py 输出目录 8 2.0      # 输出目录 / 方向数 / 相位(度)

改形状/颜色就动下面 CONFIG，然后重跑 → 用 DST Mod Tool 导 scml 覆盖 anim 包。
⚠️ 脚本别放在打包目录里（Mod Tool 打包时会被多余文件挡），放 _tools/ 这种地方。
"""

import math
import os
import struct
import sys
import zlib

# ============================== CONFIG ==============================
# ---- 形状（"太大/太瘦/太直"改这里）----
R          = 330.0        # 两等圆半径（整体大小；游戏里还要乘 ART.scale）
# ---- 2026-09-16 22:00 用户定稿：改用 `crescent_variants.py` **最底下那版（第 4 版 厚版+零辉光）** ----
#   对照关系（variants 里 R=110、e=46）→ 这里 R=330，等比换算：e/R = 46/110 = 0.4182
E          = 138.0        # 两圆错开量 = 月牙最厚处厚度（= 0.4182R，厚版；薄版是 0.30R = 99.0）
XS, YS     = 1.05, 0.40   # 横向拉宽 / 纵向压扁
# ---- 上窄下宽（2026-09-16 用户手绘稿 + 五轮对照后定稿）----
#   月牙**立着**（凸面/白刃口朝右、开口朝左）；上端略窄略短、下端略长。
#   上半按 YS_TOP、下半按 YS_BOT：0.98 / 1.06（近对称，只是下端尖长一点点）
YS_TOP     = 0.95        # ★ 第 4 版：上窄
YS_BOT     = 1.15        # ★ 第 4 版：下宽（"上窄下宽"必须烤进素材，引擎不会帮我们变形）
TOP_TAPER  = 1.0

# ---- 颜色（改绿/改白改这里）----
COL_CORE   = (1.00, 1.00, 1.00)   # 刃口色（白）
COL_BODY   = (0.30, 0.86, 1.00)   # 本体色（亮青）→ 想直接要绿就填 (0.35, 1.00, 0.35)
CORE_MIX   = 0.85                 # 刃口发白程度（0 = 全本体色，1 = 全白）

# ---- 辉光（"太糊/太亮"改这里）----
#   ★ 2026-09-16 用户看图后定："1/2 后面那圈雾不对" → 辉光调到 0（只剩本体，游戏里还有 bloom）
GLOW1      = (0.00, 26.0)         # 内层辉光（强度, 衰减长度）
GLOW2      = (0.00, 55.0)         # 外层柔光
EDGE       = 0.8                  # 边缘柔化（像素）

# ---- 画布 / 采样 ----
W, H       = 1024, 1024           # 底图画布
SS         = 3                    # 超采样倍数（抗锯齿）
CANVAS     = 1280                 # 方向图画布边长

# ---- 方向图 ----
COUNT      = 8                    # 方向数（8 = 每 45°；4 = 每 90°；代码里 dirs 表要跟着改）
PHASE_DEG  = 0.0                  # 整体相位（8 张一致偏一点就调它）
K_SCREEN   = 0.5                  # 屏幕纵向压缩（DST 等距 2:1）
BASE_ANGLE_DEG = 0.0              # 底图凸面在美术空间的角度（我们画的朝 +X = 0.0，别改）

# ---- 输出名 ----
OUT_BASE   = "crescent_light.png"      # 底图
DIR_PREFIX = "crescent_dir"            # 方向图前缀：crescent_dir0.png ...
SCML_NAME  = "crescent_cyan8.scml"     # 工程文件名
# ---- 官方多面向命名（2026-09-16）----
#   官方规则（Don't Starve Mod Tools/mod_tools/tools/scripts/buildanimation.py）：
#   动画名带后缀 → 编译器自动写"朝向位掩码"，并把后缀从名字里去掉；
#   游戏里 PlayAnimation(基础名)，引擎按 Transform 的旋转自己挑面。
#   dir k（世界角 k×45°，+X 起往 +Z）→ 后缀对应表（口径见 _tools/official_facing_names.py）
FACING_NAMES = ["downright", "down", "downleft", "left", "upleft", "up", "upright", "right"]
ANIM_BASE    = "slash"                 # 基础名（要跟 lua 里 FACING_ANIM 一致）
BUILD_NAME = "crescent_cyan8"          # build/entity 名（要跟 anim 包、代码 FX_ART 一致）
# ====================================================================

MARK = 0.70710678


# ----------------------------- PNG 读写 -----------------------------
def write_png(path, w, h, px):
    """px = [(r,g,b,a), ...] 长度 w*h"""
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        for (r, g, b, a) in px[y * w:(y + 1) * w]:
            raw += bytes((r, g, b, a))

    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data
                + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))

    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(bytes(raw), 6))
           + chunk(b"IEND", b""))
    open(path, "wb").write(png)


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
        pa, pb, pc = abs(bb - c), abs(a - c), abs(a + bb - 2 * c)
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
    return w, h, px


# ----------------------------- 小工具 -----------------------------
def clamp(v, a=0.0, b=1.0):
    return a if v < a else (b if v > b else v)


def mix(c1, c2, k):
    return (c1[0] + (c2[0] - c1[0]) * k,
            c1[1] + (c2[1] - c1[1]) * k,
            c1[2] + (c2[2] - c1[2]) * k)


def mat_mul(m, n):
    return [m[0] * n[0] + m[1] * n[2], m[0] * n[1] + m[1] * n[3],
            m[2] * n[0] + m[3] * n[2], m[2] * n[1] + m[3] * n[3]]


def mat_apply(m, vx, vy):
    return (m[0] * vx + m[1] * vy, m[2] * vx + m[3] * vy)


def rot_mat(deg):
    r = math.radians(deg)
    c, s = math.cos(r), math.sin(r)
    return [c, -s, s, c]


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
    return (min(255, int(out[0] / al + 0.5)), min(255, int(out[1] / al + 0.5)),
            min(255, int(out[2] / al + 0.5)), min(255, int(a + 0.5)))


def bbox_of(px, w, h):
    x0, y0, x1, y1 = w, h, -1, -1
    for y in range(h):
        base = y * w
        for x in range(w):
            if px[base + x][3] > 8:
                if x < x0: x0 = x
                if x > x1: x1 = x
                if y < y0: y0 = y
                if y > y1: y1 = y
    return x0, y0, x1, y1


def shift(px, w, h, dx, dy):
    out = [(0, 0, 0, 0)] * (w * h)
    for y in range(h):
        ys = y - dy
        if ys < 0 or ys >= h:
            continue
        for x in range(w):
            xs = x - dx
            if 0 <= xs < w:
                out[y * w + x] = px[ys * w + xs]
    return out


# ----------------------------- 底图：画月牙 -----------------------------
def sample_lune(sx, sy, cx, cy):
    """美术空间采样：两等圆差集 + 辉光 + 白刃口，返回 (r,g,b,a) 0..255"""
    u = (sx - cx) / XS
    dy = sy - cy
    if dy < 0:                                   # 上半：从脊线往上逐渐变薄 → 上窄
        k = clamp(-dy / (R * YS_BOT * TOP_TAPER))
        ys = YS_BOT + (YS_TOP - YS_BOT) * k
    else:                                        # 下半：整体更厚 → 下宽
        ys = YS_BOT
    v = dy / ys
    d_out = math.hypot(u, v) - R                       # <0 = 在外圆内
    f_in = R - math.hypot(u + E, v)                    # >0 = 在内圆里（要挖掉）
    sd = d_out if d_out > f_in else f_in               # <0 = 在月牙体内
    t = clamp(-d_out / E)                              # 0 = 刃口（凸面） → 1 = 背

    body = clamp((EDGE - sd) / (2.0 * EDGE))
    glow = (GLOW1[0] * math.exp(-max(sd, 0.0) / GLOW1[1])
            + GLOW2[0] * math.exp(-max(sd, 0.0) / GLOW2[1]))
    core = (1.0 - t) ** 1.6 * CORE_MIX
    col = mix(COL_BODY, COL_CORE, clamp(core))
    a = clamp(body * (0.80 + 0.20 * (1.0 - t)) + glow * (1.0 - 0.6 * body))
    # 画布边缘淡出（不然贴图在游戏里能看到一个方框边）
    e = min(sx, sy, W - 1 - sx, H - 1 - sy) / 48.0
    if e < 1.0:
        a *= max(0.0, e)
    return (int(col[0] * 255 + 0.5), int(col[1] * 255 + 0.5), int(col[2] * 255 + 0.5),
            int(a * 255 + 0.5))


def make_base(out_path):
    cx, cy = (W - 1) / 2.0, (H - 1) / 2.0
    inv = 1.0 / (SS * SS)
    px = []
    for y in range(H):
        for x in range(W):
            r = g = b = a = 0.0
            for sy2 in range(SS):
                for sx2 in range(SS):
                    rr, gg, bb, aa = sample_lune(x + (sx2 + 0.5) / SS - 0.5,
                                                 y + (sy2 + 0.5) / SS - 0.5, cx, cy)
                    r += rr; g += gg; b += bb; a += aa
            px.append((int(r * inv + 0.5), int(g * inv + 0.5), int(b * inv + 0.5), int(a * inv + 0.5)))
    write_png(out_path, W, H, px)

    def opaque_bbox():
        return bbox_of(px, W, H)
    x0, y0, x1, y1 = opaque_bbox()
    print("底图 %dx%d  不透明外框 %dx%d" % (W, H, x1 - x0 + 1, y1 - y0 + 1))
    return px


# ----------------------------- 方向图 -----------------------------
def make_dirs(base_px, out_dir, count, phase):
    w, h = W, H
    (cx, cy) = (w - 1) / 2.0, (h - 1) / 2.0
    bbox = bbox_of(base_px, w, h)

    # 凸面朝向（美术空间）：我们画的朝 +X
    a = math.radians(BASE_ANGLE_DEG)
    d_art = (math.cos(a), math.sin(a))
    ang_base = BASE_ANGLE_DEG        # BILLBOARD：贴图正对镜头，底图朝向就是美术角度

    # 世界方向 → 屏幕方向：sx=(u-v)/√2, sy=+k(u+v)/√2
    # ★ 2026-09-14 **修正为 + 号**（原来抄旧脚本用的 - 号是错的）：
    #   符号一翻，等于把画面沿水平轴镜像 —— 角度 α 变 -α。
    #   不动的只有 α=0°/180°，也就是**世界 135° / 315°** 这两条；
    #   而用户实测"只有左下方向对" —— 左下正好是世界 135°，**正是那个不动点**。
    #   （其余 6 个方向全偏，屏幕上看就是"月牙凸面朝上、像在往下飞"。）
    P = [MARK, -MARK, MARK * K_SCREEN, MARK * K_SCREEN]

    NC = CANVAS
    cnew = (NC / 2.0, NC / 2.0)
    names = []
    for m in range(count):
        theta = (360.0 / count) * m + (180.0 / count)      # 该桶中心角（世界 +X 起，往 +Z）
        t = math.radians(theta)
        sx, sy = mat_apply(P, math.cos(t), math.sin(t))
        ang_want = math.degrees(math.atan2(sy, sx))
        d = ang_want - ang_base + phase
        M = rot_mat(d)                                     # 画面平面纯旋转（BILLBOARD）

        out = [(0, 0, 0, 0)] * (NC * NC)
        # 只扫 bbox 映射过去的那块
        corners = []
        for (px0, py0) in ((bbox[0], bbox[1]), (bbox[2], bbox[1]),
                           (bbox[0], bbox[3]), (bbox[2], bbox[3])):
            ux, uy = px0 - cx, py0 - cy
            rx, ry = mat_apply(M, ux, uy)
            corners.append((rx + cnew[0], ry + cnew[1]))
        x_lo = max(0, int(min(c[0] for c in corners)) - 2)
        x_hi = min(NC - 1, int(max(c[0] for c in corners)) + 2)
        y_lo = max(0, int(min(c[1] for c in corners)) - 2)
        y_hi = min(NC - 1, int(max(c[1] for c in corners)) + 2)

        # 旋转的逆（用转置即可：纯旋转矩阵的逆 = 转置）
        Mt = [M[0], M[2], M[1], M[3]]
        for oy in range(y_lo, y_hi + 1):
            ry = oy - cnew[1]
            ux = Mt[0] * (x_lo - cnew[0]) + Mt[1] * ry
            uy = Mt[2] * (x_lo - cnew[0]) + Mt[3] * ry
            row = oy * NC
            for ox in range(x_lo, x_hi + 1):
                out[row + ox] = bilinear(base_px, w, h, cx + ux, cy + uy)
                ux += Mt[0]
                uy += Mt[2]

        # 月牙 bbox 居中到画布中心（游戏 pivot = 画布中心）
        bx0, by0, bx1, by1 = bbox_of(out, NC, NC)
        if bx1 > bx0:
            mx, my = (bx0 + bx1) / 2.0, (by0 + by1) / 2.0
            dx2, dy2 = int(round(cnew[0] - mx)), int(round(cnew[1] - my))
            if dx2 or dy2:
                out = shift(out, NC, NC, dx2, dy2)

        name = "%s%d.png" % (DIR_PREFIX, m)
        write_png(os.path.join(out_dir, name), NC, NC, out)
        names.append(name)
        print("  %-20s 世界角 %3.0f°  画面旋转 %+6.1f°" % (name, theta, d))

    # ---- scml ----
    L = ['<?xml version="1.0" encoding="UTF-8"?>',
         '<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="r7">',
         '    <folder id="0" name="%s">' % BUILD_NAME]
    for i, nm in enumerate(names):
        L.append('        <file id="%d" name="%s" width="%d" height="%d" pivot_x="0.5" pivot_y="0.5"/>'
                 % (i, nm, NC, NC))
    L.append('    </folder>')
    L.append('    <entity id="0" name="%s">' % BUILD_NAME)
    for i, nm in enumerate(names):
        # ★ 2026-09-16 定稿：用**无后缀点名声**（引擎挑面那套验不了：原版脚本 4044 个文件里
        #   没有任何一处用带后缀的名字播动画，说明后缀只是编译期标记，运行时只能靠引擎挑面）。
        #   方向改由 lua 按"引擎真实旋转"点名播对应 dir（见 musha_slash_qi_fx.lua）。
        an = "%s_dir%d" % (ANIM_BASE, i)
        L.append('        <animation id="%d" name="%s" length="1000" interval="100">' % (i, an))
        L.append('            <mainline>')
        L.append('                <key id="0">')
        L.append('                    <object_ref id="0" timeline="0" key="0" z_index="0"/>')
        L.append('                </key>')
        L.append('            </mainline>')
        L.append('            <timeline id="0" name="%s">' % an)
        L.append('                <key id="0" spin="0">')
        L.append('                    <object folder="0" file="%d"/>' % i)
        L.append('                </key>')
        L.append('            </timeline>')
        L.append('        </animation>')
    L.append('    </entity>')
    L.append('</spriter_data>')
    open(os.path.join(out_dir, SCML_NAME), "w", encoding="utf-8").write("\n".join(L) + "\n")
    print("  → %s" % SCML_NAME)
    return names


def main(argv):
    here = os.path.dirname(os.path.abspath(__file__))
    out_dir = argv[0] if argv else os.path.normpath(os.path.join(here, "..", "crescent_cyan"))
    count = int(argv[1]) if len(argv) > 1 else COUNT
    phase = float(argv[2]) if len(argv) > 2 else PHASE_DEG
    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)

    print("=== 1) 画底图 ===")
    base_path = os.path.join(out_dir, OUT_BASE)
    base_px = make_base(base_path)
    print("=== 2) 派生 %d 张方向图 ===" % count)
    make_dirs(base_px, out_dir, count, phase)
    print("=== 完 ===")
    print("输出目录：%s" % out_dir)
    print("下一步：DST Mod Tool 打开 %s → 导出 → 覆盖 anim/%s.zip" % (SCML_NAME, BUILD_NAME))
    print("（脚本别放打包目录里，否则 Mod Tool 打包会被挡）")


if __name__ == "__main__":
    main(sys.argv[1:])
