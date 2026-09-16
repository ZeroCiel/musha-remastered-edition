"""纯标准库 PNG 读写 + 拼图工具（Windows 侧无 PIL，module 级零依赖）

用法：
    from pnglib import read_png, write_png, Image, contact_sheet
    im = read_png("a.png")            # -> Image(w,h,pixels:bytes RGBA)
    contact_sheet([("torso", [im1,im2])], "sheet.png")
"""
import zlib, struct

class Image:
    __slots__ = ("w", "h", "px")
    def __init__(self, w, h, px=None):
        self.w = w
        self.h = h
        self.px = px if px is not None else bytearray(w * h * 4)
    def get(self, x, y):
        i = (y * self.w + x) * 4
        return tuple(self.px[i:i+4])
    def put(self, x, y, c):
        i = (y * self.w + x) * 4
        self.px[i:i+4] = bytes(c)


def _paeth(a, b, c):
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc: return a
    if pb <= pc: return b
    return c


def read_png(path):
    data = open(path, "rb").read()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", "not png: " + path
    pos = 8
    idat = b""
    plte = None
    trns = None
    w = h = bd = ct = None
    while pos < len(data):
        ln = struct.unpack(">I", data[pos:pos+4])[0]
        typ = data[pos+4:pos+8]
        chunk = data[pos+8:pos+8+ln]
        pos += 12 + ln
        if typ == b"IHDR":
            w, h, bd, ct, comp, filt, inter = struct.unpack(">IIBBBBB", chunk)
            assert inter == 0, "interlaced png unsupported"
        elif typ == b"PLTE":
            plte = chunk
        elif typ == b"tRNS":
            trns = chunk
        elif typ == b"IDAT":
            idat += chunk
        elif typ == b"IEND":
            break
    raw = zlib.decompress(idat)
    nch = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ct]
    if bd == 16:
        nch_px = nch
        bpp = nch * 2
        stride = w * bpp
    elif bd == 8:
        bpp = nch
        stride = w * bpp
    else:  # bd 1/2/4 只可能用于灰度或调色板
        bpp = 1
        stride = (w * bd + 7) // 8
    out = bytearray(stride * h)
    prev = bytearray(stride)
    p = 0
    for y in range(h):
        f = raw[p]; p += 1
        line = bytearray(raw[p:p+stride]); p += stride
        if f == 1:
            for i in range(bpp, stride): line[i] = (line[i] + line[i-bpp]) & 255
        elif f == 2:
            for i in range(stride): line[i] = (line[i] + prev[i]) & 255
        elif f == 3:
            for i in range(stride):
                a = line[i-bpp] if i >= bpp else 0
                line[i] = (line[i] + ((a + prev[i]) >> 1)) & 255
        elif f == 4:
            for i in range(stride):
                a = line[i-bpp] if i >= bpp else 0
                c = prev[i-bpp] if i >= bpp else 0
                line[i] = (line[i] + _paeth(a, prev[i], c)) & 255
        out[y*stride:(y+1)*stride] = line
        prev = line
    img = Image(w, h)
    px = img.px
    for y in range(h):
        base = y * stride
        row = out[base:base+stride]
        o = y * w * 4
        if ct == 6:
            if bd == 8:
                px[o:o+w*4] = row
            else:
                for x in range(w):
                    i = x * 8
                    px[o+x*4:o+x*4+4] = bytes((row[i], row[i+2], row[i+4], row[i+6]))
        elif ct == 2:
            if bd == 8:
                for x in range(w):
                    i = x * 3
                    px[o+x*4:o+x*4+4] = bytes((row[i], row[i+1], row[i+2], 255))
            else:
                for x in range(w):
                    i = x * 6
                    px[o+x*4:o+x*4+4] = bytes((row[i], row[i+2], row[i+4], 255))
        elif ct == 0:
            if bd == 8:
                for x in range(w):
                    v = row[x]
                    px[o+x*4:o+x*4+4] = bytes((v, v, v, 255))
            elif bd == 16:
                for x in range(w):
                    v = row[x*2]
                    px[o+x*4:o+x*4+4] = bytes((v, v, v, 255))
            else:
                per = 8 // bd
                mask = (1 << bd) - 1
                scale = 255 // mask
                for x in range(w):
                    byte = row[x // per]
                    shift = 8 - bd * (x % per + 1)
                    v = ((byte >> shift) & mask) * scale
                    px[o+x*4:o+x*4+4] = bytes((v, v, v, 255))
        elif ct == 4:
            for x in range(w):
                v = row[x*2]
                a = row[x*2+1]
                px[o+x*4:o+x*4+4] = bytes((v, v, v, a))
        elif ct == 3:
            per = 8 // bd
            mask = (1 << bd) - 1
            for x in range(w):
                if bd == 8:
                    idx = row[x]
                else:
                    idx = (row[x // per] >> (8 - bd * (x % per + 1))) & mask
                px[o+x*4:o+x*4+4] = bytes((plte[idx*3], plte[idx*3+1], plte[idx*3+2],
                                            255 if trns is None else (trns[idx] if idx < len(trns) else 255)))
    return img


def write_png(path, img):
    raw = bytearray()
    stride = img.w * 4
    for y in range(img.h):
        raw.append(0)
        raw += img.px[y*stride:(y+1)*stride]
    def chunk(typ, payload):
        return (struct.pack(">I", len(payload)) + typ + payload
                + struct.pack(">I", zlib.crc32(typ + payload) & 0xffffffff))
    hdr = struct.pack(">IIBBBBB", img.w, img.h, 8, 6, 0, 0, 0)
    out = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", hdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    open(path, "wb").write(out)


def blit(dst, src, dx, dy, alpha=True):
    for y in range(src.h):
        ty = dy + y
        if ty < 0 or ty >= dst.h: continue
        for x in range(src.w):
            tx = dx + x
            if tx < 0 or tx >= dst.w: continue
            i = (y * src.w + x) * 4
            a = src.px[i+3]
            if a == 0: continue
            j = (ty * dst.w + tx) * 4
            if a == 255 or not alpha:
                dst.px[j:j+4] = src.px[i:i+4]
            else:
                ia = 255 - a
                for k in range(3):
                    dst.px[j+k] = (src.px[i+k] * a + dst.px[j+k] * ia) // 255
                dst.px[j+3] = 255


def contact_sheet(rows, out_path, pad=8, bg=(58, 58, 66)):
    """rows = [(label, [Image, ...]), ...] 按行水平排列，行内等高左侧标签位（不写字，靠位置认）。"""
    widths = []
    heights = []
    for _, ims in rows:
        widths.append(sum(im.w for im in ims) + pad * (len(ims) + 1))
        heights.append(max([im.h for im in ims] + [0]) + pad * 2)
    W = max(widths); H = sum(heights)
    canvas = Image(W, H)
    for i in range(0, W * H * 4, 4):
        canvas.px[i:i+3] = bytes(bg)
        canvas.px[i+3] = 255
    y = 0
    for r, (_, ims) in enumerate(rows):
        x = pad
        for im in ims:
            blit(canvas, im, x, y + pad)
            x += im.w + pad
        y += heights[r]
    write_png(out_path, canvas)
    return W, H
