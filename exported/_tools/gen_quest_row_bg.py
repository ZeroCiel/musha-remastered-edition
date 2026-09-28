# -*- coding: utf-8 -*-
"""
Quest row backing preview generator (pure stdlib, no PIL).

Goal (user spec 2026-09-28): 主页任务行下面那层「淡白色半透明椭圆底框」。
The PNG body is pure opaque white; translucency is a code knob
(SetTint alpha, SSOT 建议起手 0.7) so it can be tuned without re-converting.

Outputs (图片/):
  任务行底_预览A_椭圆.png            660x58 椭圆，透明底
  任务行底_预览B_胶囊.png            660x58 胶囊（半圆端帽），透明底
  任务行底_预览_对照.png             奶黄底合成：上 A / 下 B，中间棕线分隔（给用户看形）

AA: 4x4 supersampling per pixel.
Usage: python gen_quest_row_bg.py
Exit codes: 0 ok, 1 write failed.
"""
import os
import struct
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))          # exported\_tools
MOD_ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))  # musha\
OUT_DIR = os.path.join(MOD_ROOT, "图片")

W, H = 660, 58
SS = 4  # supersample per axis

BG = (250, 240, 209)          # 奶黄底 = 面板内纸近似色，白色身才看得出
DIV = (139, 111, 71)          # 分隔线（深棕）


def write_png(path, w, h, rows):
    """rows: list of h byte-strings, each w*4 (RGBA)."""
    raw = b"".join(b"\x00" + r for r in rows)

    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data
                + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff))

    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw, 9))
           + chunk(b"IEND", b""))
    with open(path, "wb") as f:
        f.write(png)


def inside_ellipse(x, y, cx, cy, rx, ry):
    nx = (x - cx) / rx
    ny = (y - cy) / ry
    return nx * nx + ny * ny <= 1.0


def inside_pill(x, y, cx, cy, r):
    """stadium: 中段平直 + 两端半圆（端帽半径 = 半高）"""
    dx = max(abs(x - cx) - (W / 2.0 - r), 0.0)
    dy = y - cy
    return dx * dx + dy * dy <= r * r


def alpha_row(shape, py):
    """One row of alpha values (0..255) for the 660x58 shape (py = 像素行)."""
    cx, cy = W / 2.0, H / 2.0
    step = 1.0 / SS
    off = (SS - 1) / 2.0 * step
    out = bytearray()
    for px in range(W):
        hits = 0
        for sy in range(SS):
            y = py + off + sy * step
            for sx in range(SS):
                x = px + off + sx * step
                if shape == "ellipse":
                    ok = inside_ellipse(x, y, cx, cy, W / 2.0, H / 2.0)
                else:
                    ok = inside_pill(x, y, cx, cy, H / 2.0)
                if ok:
                    hits += 1
        out.append(int(round(255.0 * hits / (SS * SS))))
    return out


def render_shape(shape):
    rows = []
    for py in range(H):
        a = alpha_row(shape, py)
        rows.append(bytes(b"".join(bytes((255, 255, 255, a[x])) for x in range(W))))
    return rows


def composite():
    """Cream board with A on top, B below, brown divider in between."""
    cw, ch = 700, 200
    rows = []
    ay, by = 30, 112          # shape top-left y in composite (shape H = 58)
    ax = (cw - W) // 2
    ea = render_shape("ellipse")
    pb = render_shape("pill")
    for y in range(ch):
        row = bytearray()
        for x in range(cw):
            r, g, b = BG
            src, ox, oy = (ea, ax, ay) if ay <= y < ay + H else \
                          ((pb, ax, by) if by <= y < by + H else (None, 0, 0))
            if src is not None and ox <= x < ox + W:
                a = src[y - oy][(x - ox) * 4 + 3]
                f = a / 255.0
                r = int(255 * f + r * (1 - f))
                g = int(255 * f + g * (1 - f))
                b = int(255 * f + b * (1 - f))
            if y == 100:                       # divider line
                r, g, b = DIV
            row += bytes((r, g, b, 255))
        rows.append(bytes(row))
    return cw, ch, rows


def main():
    if not os.path.isdir(OUT_DIR):
        os.makedirs(OUT_DIR)

    a_rows = render_shape("ellipse")
    b_rows = render_shape("pill")
    pa = os.path.join(OUT_DIR, "任务行底_预览A_椭圆.png")
    pb = os.path.join(OUT_DIR, "任务行底_预览B_胶囊.png")
    write_png(pa, W, H, a_rows)
    write_png(pb, W, H, b_rows)

    cw, ch, crows = composite()
    pc = os.path.join(OUT_DIR, "任务行底_预览_对照.png")
    write_png(pc, cw, ch, crows)

    for p in (pa, pb, pc):
        print("wrote %s (%d bytes)" % (p, os.path.getsize(p)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
