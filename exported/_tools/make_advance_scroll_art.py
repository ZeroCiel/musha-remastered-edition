"""转职卷轴美术：把 图片/任务卷轴.png（2048²，用户说"参考彩虹岛风格"那张）做成游戏素材，
   替掉现在借的原版莎草纸占位。

产出：
  images/inventoryimages/musha_advance_scroll.png   64² 图标（**还要 Mod Tool 转 .tex/.xml**）
  exported/musha_advance_scroll/musha_advance_scroll.png   72² 地上/手中贴图
  exported/musha_advance_scroll/musha_advance_scroll.scml  bank/build = musha_advance_scroll
  _tools/_test_out/advance_scroll_preview.png              放大预览

⚠️ 没打包时 prefab 会自动退回原版莎草纸（asset_exists 自检），不会禁 mod。
用法：python exported/_tools/make_advance_scroll_art.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import Image, read_png, write_png

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.normpath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(MOD, "图片", "任务卷轴.png")
OUT = os.path.join(MOD, "exported", "musha_advance_scroll")
NAME = "musha_advance_scroll"
ICON_SIZE = 64
ITEM_SIZE = 72
ALPHA = 8


def bbox_alpha(im):
    w, h, px = im.w, im.h, im.px
    x0, y0, x1, y1 = w, h, -1, -1
    for y in range(h):
        base = y * w * 4
        for x in range(w):
            if px[base + x * 4 + 3] > ALPHA:
                if x < x0: x0 = x
                if x > x1: x1 = x
                if y < y0: y0 = y
                if y > y1: y1 = y
    return x0, y0, x1, y1


def downscale(im, box, size):
    """预乘 alpha 区域平均（跟 make_skill_scroll.py / make_jobbook_art.py 同一套口径）"""
    x0, y0, x1, y1 = box
    sw, sh = x1 - x0 + 1, y1 - y0 + 1
    s = min(float(size) / sw, float(size) / sh)
    ow, oh = max(1, int(round(sw * s))), max(1, int(round(sh * s)))
    ox, oy = (size - ow) // 2, (size - oh) // 2
    out = Image(size, size)
    spx, swid = im.px, im.w
    inv = 1.0 / s
    for ty in range(oh):
        iy0 = int(y0 + ty * inv)
        iy1 = max(int(y0 + (ty + 1) * inv), iy0 + 1)
        for tx in range(ow):
            ix0 = int(x0 + tx * inv)
            ix1 = max(int(x0 + (tx + 1) * inv), ix0 + 1)
            sa = sr = sg = sb = n = 0
            for yy in range(iy0, iy1):
                if yy < 0 or yy >= im.h:
                    continue
                rb = yy * swid * 4
                for xx in range(ix0, ix1):
                    if xx < 0 or xx >= swid:
                        continue
                    i = rb + xx * 4
                    a = spx[i + 3]
                    n += 1
                    if a == 0:
                        continue
                    sa += a
                    sr += spx[i] * a
                    sg += spx[i + 1] * a
                    sb += spx[i + 2] * a
            if n == 0:
                continue
            j = ((oy + ty) * size + (ox + tx)) * 4
            if sa == 0:
                out.px[j:j + 4] = bytes((0, 0, 0, 0))
            else:
                out.px[j:j + 4] = bytes((min(255, sr // sa), min(255, sg // sa),
                                         min(255, sb // sa), min(255, sa // n)))
    return out


def preview(im, scale, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out = Image(im.w * scale, im.h * scale)
    for y in range(out.h):
        for x in range(out.w):
            i = ((y // scale) * im.w + (x // scale)) * 4
            j = (y * out.w + x) * 4
            if im.px[i + 3] == 0:
                v = 100 if ((x // 8) + (y // 8)) % 2 == 0 else 132
                out.px[j:j + 3] = bytes((v, v, v + 4))
            else:
                out.px[j:j + 3] = im.px[i:i + 3]
            out.px[j + 3] = 255
    write_png(path, out)


def main():
    im = read_png(SRC)
    print("源图:", im.w, "x", im.h)
    bx = bbox_alpha(im)
    print("内容 bbox:", bx, "→ %dx%d" % (bx[2] - bx[0] + 1, bx[3] - bx[1] + 1))
    icon = downscale(im, bx, ICON_SIZE)
    item = downscale(im, bx, ITEM_SIZE)
    dst_icon = os.path.join(MOD, "images", "inventoryimages", NAME + ".png")
    write_png(dst_icon, icon)
    print("图标:", dst_icon)
    os.makedirs(OUT, exist_ok=True)
    write_png(os.path.join(OUT, NAME + ".png"), item)
    scml = '''<?xml version="1.0" encoding="UTF-8"?>
<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="r11">
 <folder id="0" name="{n}">
  <file id="0" name="{n}.png" width="{w}" height="{w}" pivot_x="0.5" pivot_y="0.5" />
 </folder>
 <entity id="0" name="{n}">
  <animation id="0" name="idle" length="1000" interval="100">
   <mainline>
    <key id="0" time="0">
     <object_ref id="0" timeline="0" key="0" z_index="0" name="swap_object" />
    </key>
   </mainline>
   <timeline id="0" name="swap_object">
    <key id="0" time="0" spin="0">
     <object folder="0" file="0" scale_x="1" scale_y="1" />
    </key>
   </timeline>
  </animation>
 </entity>
</spriter_data>
'''.format(n=NAME, w=ITEM_SIZE)
    open(os.path.join(OUT, NAME + ".scml"), "w", encoding="utf-8").write(scml)
    print("工程:", OUT, "->", NAME + ".{png,scml}")
    preview(item, 5, os.path.join(HERE, "_test_out", "advance_scroll_preview.png"))
    print("预览:", os.path.join(HERE, "_test_out", "advance_scroll_preview.png"))
    print("\n图标形状自检（#=/纸 o=卷轴）：")
    ramp = " .:-=+*#%@"
    for y in range(0, ICON_SIZE, 2):
        row = []
        for x in range(ICON_SIZE):
            i = (y * ICON_SIZE + x) * 4
            if icon.px[i + 3] <= ALPHA:
                row.append(" ")
                continue
            lum = (icon.px[i] * 299 + icon.px[i + 1] * 587 + icon.px[i + 2] * 114) // 1000
            row.append(ramp[min(9, lum * 10 // 256)])
        print("   |" + "".join(row) + "|")


if __name__ == "__main__":
    main()
