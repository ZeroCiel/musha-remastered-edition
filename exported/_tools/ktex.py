# -*- coding: utf-8 -*-
"""DST .tex (KTEX) 解码器：2048x2048 / BC3(DXT5) / 1 字节每像素 / 后有 mips
—— 2026-09-16 试出来的真实格式（之前按"1024²裸 RGBA"解一直是花的）：
  文件头 155 字节；之后 BC3 数据；1 个 4x4 块 = 16 字节（8B alpha + 8B 颜色）
"""
import struct

def rgb565_table():
    t = []
    for v in range(65536):
        r = (v >> 11) & 0x1F
        g = (v >> 5) & 0x3F
        b = v & 0x1F
        t.append(((r << 3) | (r >> 2), (g << 2) | (g >> 4), (b << 3) | (b >> 2)))
    return t

RGB565 = rgb565_table()

def decode_region(tex, off, atlas_w, x0, y0, w, h):
    """解 (x0,y0,w,h) 这块（自动对齐到 4x4 块）。返回 bytearray RGBA，行宽 = w 对齐后的宽"""
    bx0, by0 = x0 // 4, y0 // 4
    bx1, by1 = (x0 + w + 3) // 4, (y0 + h + 3) // 4
    bw, bh = bx1 - bx0, by1 - by0
    out_w, out_h = bw * 4, bh * 4
    out = bytearray(out_w * out_h * 4)
    for by in range(by0, by1):
        for bx in range(bx0, bx1):
            p = off + ((by * (atlas_w // 4)) + bx) * 16
            blk = tex[p:p + 16]
            a0, a1 = blk[0], blk[1]
            if a0 > a1:
                alphas = [a0, a1]
                for i in range(2, 8):
                    alphas.append(((8 - i) * a0 + (i - 1) * a1) // 7)
            else:
                alphas = [a0, a1]
                for i in range(2, 6):
                    alphas.append(((6 - i) * a0 + (i - 1) * a1) // 5)
                alphas += [0, 255]
            # 48 bit 索引（每像素 3 bit，小端）
            aidx = blk[2:8]
            abit = int.from_bytes(aidx, "little")
            c0 = blk[8] | (blk[9] << 8)
            c1 = blk[10] | (blk[11] << 8)
            r0, g0, b0 = RGB565[c0]
            r1, g1, b1 = RGB565[c1]
            if c0 > c1:
                cs = [(r0, g0, b0), (r1, g1, b1),
                      ((2 * r0 + r1) // 3, (2 * g0 + g1) // 3, (2 * b0 + b1) // 3),
                      ((r0 + 2 * r1) // 3, (g0 + 2 * g1) // 3, (b0 + 2 * b1) // 3)]
            else:
                cs = [(r0, g0, b0), (r1, g1, b1),
                      ((r0 + r1) // 2, (g0 + g1) // 2, (b0 + b1) // 2), (0, 0, 0)]
            cidx = int.from_bytes(blk[12:16], "little")
            for j in range(4):
                for i in range(4):
                    k = j * 4 + i
                    a = alphas[(abit >> (3 * k)) & 7]
                    r, g, b = cs[(cidx >> (2 * k)) & 3]
                    oy = (by - by0) * 4 + j
                    ox = (bx - bx0) * 4 + i
                    o = (oy * out_w + ox) * 4
                    out[o] = r; out[o + 1] = g; out[o + 2] = b; out[o + 3] = a
    return out, out_w, out_h

def save_png(path, rgba, w, h):
    import zlib
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        raw += rgba[y * w * 4:(y + 1) * w * 4]
    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 6))
    png += chunk(b"IEND", b"")
    open(path, "wb").write(png)
