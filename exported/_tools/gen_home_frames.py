# -*- coding: utf-8 -*-
"""
Home frame backing generator (pure stdlib, no PIL) - 2026-09-28.

用户口径：主页分上下两个框（"白色底的bg附加椭圆框"）。
纯椭圆会削掉任务行四角 → 用大圆角矩形（r=50）实现椭圆观感。

Shape: white body + inner brown outline (inset 6px, 4px wide), transparent
background; translucency is a code knob (SetTint alpha, 0.6 同任务行胶囊口径).

Outputs (图片/):
  home_frame_top.png     760x224 r=50  上框（战士/职业/经验条）
  home_frame_bottom.png  780x462 r=50  下框（任务列表+空状态引导）

2026-09-28 修重叠：旧 724x228/780x546 两框重叠 79px（下框顶边横穿经验条）。
新几何按实测坐标收口（分隔线 y=82、经验条 y 77..153 右 413.5、徽标底 80）：
  上框 y 61..285 x -310..440（加宽到 760 让经验条右下角躲开 r=50 圆角）
  下框 y -410..52（与上框缝 9px；任务列表 QLIST_Y 同步 -140→-176 下移）

AA: 4x4 supersampling per pixel.
Usage: python gen_home_frames.py
Exit codes: 0 ok, 1 write failed.
"""
import math
import os
import struct
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))          # exported\_tools
MOD_ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))  # musha\
OUT_DIR = os.path.join(MOD_ROOT, "图片")

SS = 4                       # supersample per axis
R = 50                       # 圆角半径（content 单位 = px）
BODY = (255, 255, 255, 255)  # 白身
STROKE = (139, 111, 71, 255)  # 描边棕（同任务行分隔线色系）
STROKE_INSET = 6.0           # 描边中心线距形状边界（内侧）
STROKE_W = 4.0               # 描边线宽

FRAMES = [
    # ★ 2026-09-29 用户「上下两框铺满上下面板」：
    #   内纸实测（images/panel_bg_alt.png 量出来的）= content x -408..575、y +369.5..-350.5
    #   → 上框 x -408..575、y 61..369   （983x308 @83.5,215；上沿贴内纸上沿）
    #   → 下框 x -408..575、y -368..52  （983x420 @83.5,-158；下沿压到任务滚槽底 -366 再留 2）
    #   两框之间仍留 9px 缝（52..61），经验条/徽标/分隔线位置不动
    ("home_frame_top.png", 983, 308),
    ("home_frame_bottom.png", 983, 420),
]


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


def sd_roundrect(x, y, w, h, r):
    """Signed distance to a rounded rect centered at origin. <0 inside."""
    qx = abs(x) - (w / 2.0 - r)
    qy = abs(y) - (h / 2.0 - r)
    outside = math.hypot(max(qx, 0.0), max(qy, 0.0))
    inside = min(max(qx, qy), 0.0)
    return outside + inside - r


def render(w, h):
    tot = float(SS * SS)
    rows = []
    half_w, half_h = w / 2.0, h / 2.0
    for py in range(h):
        row = bytearray()
        for px in range(w):
            s = 0.0  # stroke coverage
            b = 0.0  # body coverage
            for j in range(SS):
                y = py + (j + 0.5) / SS - half_h
                for i in range(SS):
                    x = px + (i + 0.5) / SS - half_w
                    d = sd_roundrect(x, y, w, h, R)
                    if (-STROKE_INSET - STROKE_W / 2.0 <= d
                            <= -STROKE_INSET + STROKE_W / 2.0):
                        s += 1.0
                    elif d <= 0.0:
                        b += 1.0
            a = s + b
            if a <= 0.0:
                row += bytes((0, 0, 0, 0))
            else:
                r = int(round((STROKE[0] * s + BODY[0] * b) / a))
                g = int(round((STROKE[1] * s + BODY[1] * b) / a))
                bl = int(round((STROKE[2] * s + BODY[2] * b) / a))
                alpha = int(round(255.0 * a / tot))
                row += bytes((r, g, bl, alpha))
        rows.append(bytes(row))
    return rows


def main():
    if not os.path.isdir(OUT_DIR):
        os.makedirs(OUT_DIR)
    for name, w, h in FRAMES:
        rows = render(w, h)
        path = os.path.join(OUT_DIR, name)
        write_png(path, w, h, rows)
        print("wrote %s (%dx%d)" % (path, w, h))
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
