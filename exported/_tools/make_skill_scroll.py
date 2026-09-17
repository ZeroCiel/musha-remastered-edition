"""技能卷轴素材：把美术给的 4096² 原图缩成能进游戏的尺寸。
   （Windows 侧没有 PIL/numpy → 纯标准库 + 项目自带 pnglib；4096² 读一次约 30 秒，正常）

产出：
  images/inventoryimages/musha_skill_scroll.png   64×64 背包图标 ← 图片/技能卷轴_图标.png
        ⚠️ 还要用 Mod Tool 转一次 .tex/.xml 才会在游戏里显示（没转 = prefab 自动退回 papyrus 图标）
  exported/musha_skill_scroll/musha_skill_scroll.png   72×72 地上/手中贴图 ← 图片/技能卷轴_地上.png
  exported/musha_skill_scroll/musha_skill_scroll.scml  bank/build = musha_skill_scroll，动画 idle，timeline 名 swap_object
  exported/_tools/_test_out/skill_scroll_preview.png   4 倍放大预览（给用户看）

用法：python exported/_tools/make_skill_scroll.py
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import Image, read_png, write_png

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.normpath(os.path.join(HERE, "..", ".."))
OUTDIR = os.path.join(MOD, "exported", "musha_skill_scroll")

ICON_SRC = os.path.join(MOD, "图片", "技能卷轴_图标.png")
ITEM_SRC = os.path.join(MOD, "图片", "技能卷轴_地上.png")

ICON_SIZE = 64          # 背包图标（本项目其他图标都是 64×64）
ITEM_SIZE = 72          # 地上/手中（便签是 64；卷轴稍大一点）
ALPHA_MIN = 8


def bbox_alpha(im):
    """按 alpha>ALPHA_MIN 求内容包围盒"""
    w, h, px = im.w, im.h, im.px
    x0, y0, x1, y1 = w, h, -1, -1
    for y in range(h):
        base = y * w * 4
        for x in range(w):
            if px[base + x * 4 + 3] > ALPHA_MIN:
                if x < x0:
                    x0 = x
                if x > x1:
                    x1 = x
                if y < y0:
                    y0 = y
                if y > y1:
                    y1 = y
    return x0, y0, x1, y1


def downscale(im, box, size, fit=True):
    """把 box 区域等比缩进 size×size（预乘 alpha 的区域平均，避免白边/黑边）"""
    x0, y0, x1, y1 = box
    sw, sh = x1 - x0 + 1, y1 - y0 + 1
    if fit:
        s = min(float(size) / sw, float(size) / sh)
    else:
        s = max(float(size) / sw, float(size) / sh)
    ow, oh = max(1, int(round(sw * s))), max(1, int(round(sh * s)))
    ox = (size - ow) // 2
    oy = (size - oh) // 2

    out = Image(size, size)
    src_px, src_w = im.px, im.w
    inv = 1.0 / s
    for ty in range(oh):
        sy0 = y0 + ty * inv
        sy1 = y0 + (ty + 1) * inv
        iy0, iy1 = int(sy0), max(int(sy1), int(sy0) + 1)
        for tx in range(ow):
            sx0 = x0 + tx * inv
            sx1 = x0 + (tx + 1) * inv
            ix0, ix1 = int(sx0), max(int(sx1), int(sx0) + 1)
            sa = sr = sg = sb = 0
            n = 0
            for yy in range(iy0, iy1):
                if yy < 0 or yy >= im.h:
                    continue
                rb = yy * src_w * 4
                for xx in range(ix0, ix1):
                    if xx < 0 or xx >= src_w:
                        continue
                    i = rb + xx * 4
                    a = src_px[i + 3]
                    n += 1
                    if a == 0:
                        continue
                    sa += a
                    sr += src_px[i] * a
                    sg += src_px[i + 1] * a
                    sb += src_px[i + 2] * a
            if n == 0:
                continue
            j = ((oy + ty) * size + (ox + tx)) * 4
            if sa == 0:
                out.px[j:j + 4] = bytes((0, 0, 0, 0))
            else:
                out.px[j:j + 4] = bytes((
                    min(255, sr // sa), min(255, sg // sa), min(255, sb // sa),
                    min(255, sa // n),
                ))
    return out


def ascii_check(im, cols=48, ramp=" .:-=+*#%@"):
    step = max(1, im.w // cols)
    rows = im.h // step
    for r in range(rows):
        line = []
        for c in range(cols):
            x = min(im.w - 1, c * step + step // 2)
            y = min(im.h - 1, r * step + step // 2)
            i = (y * im.w + x) * 4
            if im.px[i + 3] < ALPHA_MIN:
                line.append(" ")
                continue
            lum = (im.px[i] * 299 + im.px[i + 1] * 587 + im.px[i + 2] * 114) // 1000
            line.append(ramp[min(len(ramp) - 1, lum * len(ramp) // 256)])
        print("   |" + "".join(line) + "|")


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
    return path


def main():
    print("读图标（4096²，约 30 秒）…")
    icon_src = read_png(ICON_SRC)
    ibox = bbox_alpha(icon_src)
    print("  图标内容 bbox =", ibox, "尺寸", ibox[2] - ibox[0] + 1, "x", ibox[3] - ibox[1] + 1)
    icon = downscale(icon_src, ibox, ICON_SIZE)
    dst_icon = os.path.join(MOD, "images", "inventoryimages", "musha_skill_scroll.png")
    write_png(dst_icon, icon)
    print("  图标写出：", dst_icon)
    print("  图标形状自检：")
    ascii_check(icon, 48)
    preview(icon, 6, os.path.join(HERE, "_test_out", "skill_scroll_icon_preview.png"))

    print("读地上图（4096²，约 30 秒）…")
    item_src = read_png(ITEM_SRC)
    jbox = bbox_alpha(item_src)
    print("  地上内容 bbox =", jbox, "尺寸", jbox[2] - jbox[0] + 1, "x", jbox[3] - jbox[1] + 1)
    item = downscale(item_src, jbox, ITEM_SIZE)
    os.makedirs(OUTDIR, exist_ok=True)
    dst_item = os.path.join(OUTDIR, "musha_skill_scroll.png")
    write_png(dst_item, item)
    print("  地上贴图写出：", dst_item, "(%d×%d)" % (item.w, item.h))
    print("  地上形状自检：")
    ascii_check(item, 48)
    preview(item, 5, os.path.join(HERE, "_test_out", "skill_scroll_item_preview.png"))

    scml = '''<?xml version="1.0" encoding="UTF-8"?>
<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="r11">
 <folder id="0" name="musha_skill_scroll">
  <file id="0" name="musha_skill_scroll.png" width="{w}" height="{h}" pivot_x="0.5" pivot_y="0.5" />
 </folder>
 <entity id="0" name="musha_skill_scroll">
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
'''.format(w=item.w, h=item.h)
    dst_scml = os.path.join(OUTDIR, "musha_skill_scroll.scml")
    open(dst_scml, "w", encoding="utf-8").write(scml)
    print("  工程(scml)写出：", dst_scml)
    print("下一步（我这边会用命令行编译，一般不用你动手）：")
    print("  \"Don't Starve Mod Tools/mod_tools/scml.exe\" %s %s" % (dst_scml, OUTDIR))
    print("  图标还要你用 Mod Tool 把 images/inventoryimages/musha_skill_scroll.png 转成 .tex/.xml")


if __name__ == "__main__":
    main()
