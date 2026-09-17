"""ChatGPT 给的「三本职业书」大图 → 切三本 → 出游戏素材（图标 64² / 地上 128² + scml）

源图：mods/musha/images/591fb365-dd9b-42d8-8180-4819ffdb5d9e.png（1508x680，三本书横排）
  左 = 战士 WARRIOR   → 一转职业书（musha_jobbook_warrior）【用户点名要用这本】
  中 = 剑士 SWORDSMAN → 二转赠礼的职业技能书（musha_skillbook_saber，属于剑气斩技能树）
  右 = 近卫 GUARDIAN  → 本次不上线，只导出来当展示/废案备着

产出：
  images/inventoryimages/musha_jobbook_warrior.png   64²  （旧图自动备份到 _bak/）
  images/inventoryimages/musha_skillbook_saber.png   64²
  exported/musha_jobbook_warrior/{musha_jobbook_warrior.png 128², musha_jobbook_warrior.scml}
  exported/musha_skillbook_saber/{musha_skillbook_saber.png 128², musha_skillbook_saber.scml}
  exported/jobbook_guardian_未上线/{icon 64², world 128²}   ← 只留着，没接任何代码
  _tools/_test_out/jobbook_art_preview.png（三本并排预览，给用户看）

⚠️ 图标 tex 和 anim zip 还是得你打包（我这边只出 PNG + scml）。
用法：python exported/_tools/make_jobbook_art.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import Image, read_png, write_png, contact_sheet

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.normpath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(MOD, "images", "591fb365-dd9b-42d8-8180-4819ffdb5d9e.png")

ICON = 64
WORLD = 128
ALPHA = 8

# 书本内容列（脚本自己按"空列分段"再算一遍，这里只做兜底/对账）
EXPECT = ["warrior", "saber", "guardian"]


def col_segments(im):
    w, h, px = im.w, im.h, im.px
    out = []
    st = None
    for x in range(w):
        n = 0
        for y in range(h):
            if px[(y * w + x) * 4 + 3] > ALPHA:
                n += 1
        if n > 0 and st is None:
            st = x
        elif n == 0 and st is not None:
            if x - st > 20:
                out.append((st, x - 1))
            st = None
    if st is not None:
        out.append((st, w - 1))
    return out


def row_profile(im, x0, x1):
    """返回每行是否"有内容"（按列采样，避免太慢）"""
    w, h, px = im.w, im.h, im.px
    rows = []
    for y in range(h):
        base = y * w * 4
        has = False
        for x in range(x0, x1 + 1, 2):
            if px[base + x * 4 + 3] > ALPHA:
                has = True
                break
        rows.append(has)
    return rows


def split_book_and_caption(im, x0, x1, fallback=None):
    """书本体 和 下面那行"战士/WARRIOR"字幕 之间有一整条窄空白带
       → 取**第一条**（高>=3、且下面 120px 内还有内容的）空带当分界；找不到就用 fallback"""
    rows = row_profile(im, x0, x1)
    h = len(rows)
    start = int(h * 0.45)
    y = start
    while y < h:
        if not rows[y]:
            y0 = y
            while y < h and not rows[y]:
                y += 1
            below = any(rows[min(h - 1, y + k)] for k in range(1, min(120, h - y)))
            if (y - y0) >= 3 and below:
                return 0, y0 - 1, (y0, y - 1)
        else:
            y += 1
    if fallback is not None:
        return 0, fallback, None
    return 0, h - 1, None


def bbox(im, x0, y0, x1, y1):
    w, px = im.w, im.px
    bx0, by0, bx1, by1 = x1, y1, x0, y0
    for y in range(y0, y1 + 1):
        base = y * w * 4
        for x in range(x0, x1 + 1):
            if px[base + x * 4 + 3] > ALPHA:
                if x < bx0: bx0 = x
                if x > bx1: bx1 = x
                if y < by0: by0 = y
                if y > by1: by1 = y
    return bx0, by0, bx1, by1


def downscale(im, box, size):
    """预乘 alpha 的区域平均缩图（跟 make_skill_scroll.py 同一套口径）"""
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


def scml(name):
    return '''<?xml version="1.0" encoding="UTF-8"?>
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
'''.format(n=name, w=WORLD)


def put_scml_and_png(out_dir, name, img):
    os.makedirs(out_dir, exist_ok=True)
    write_png(os.path.join(out_dir, name + ".png"), img)
    open(os.path.join(out_dir, name + ".scml"), "w", encoding="utf-8").write(scml(name))
    print("   工程:", out_dir, "->", name + ".{png,scml}")


def main():
    im = read_png(SRC)
    print("源图:", im.w, "x", im.h)
    segs = col_segments(im)
    print("列分段:", segs)
    if len(segs) != 3:
        print("!! 期望 3 段，实际", len(segs), "—— 先人工看一下再继续")
        return

    # 先逐列找"书本 / 字幕"分界；某列找不到就用其它列的最小值兜底（第三本没空带）
    cuts = []
    for (x0, x1) in segs:
        _a, _ry1, _gap = split_book_and_caption(im, x0, x1)
        cuts.append((_ry1, _gap))
    fb = min([c[0] for c in cuts if c[1] is not None] or [int(im.h * 0.78)])
    print("字幕分界兜底值 =", fb)

    rows = []
    for idx, (x0, x1) in enumerate(segs):
        ry1, gap = cuts[idx]
        if gap is None:
            ry1 = fb
        print("  第%d本: 列 x %d..%d ｜ 书本体用到 y<=%d ｜ 字幕带 %s" % (idx + 1, x0, x1, ry1, gap))
        ytop = 0
        while ytop < im.h and not any(im.px[(ytop * im.w + x) * 4 + 3] > ALPHA for x in range(x0, x1 + 1, 2)):
            ytop += 1
        bx = bbox(im, x0, ytop, x1, ry1)
        print("    书本体 bbox:", bx, "尺寸 %dx%d" % (bx[2] - bx[0] + 1, bx[3] - bx[1] + 1))
        rows.append((EXPECT[idx], bx, x0, x1))

    # ---- 战士：替换现役图标 ----
    _n, bx, _a, _b = rows[0]
    icon = downscale(im, bx, ICON)
    world = downscale(im, bx, WORLD)
    dst_icon = os.path.join(MOD, "images", "inventoryimages", "musha_jobbook_warrior.png")
    bak_dir = os.path.join(MOD, "images", "inventoryimages", "_bak")
    os.makedirs(bak_dir, exist_ok=True)
    if os.path.exists(dst_icon):
        import shutil
        shutil.copy2(dst_icon, os.path.join(bak_dir, "musha_jobbook_warrior_旧版_20260917.png"))
        print("  旧战士职业书图标已备份 → images/inventoryimages/_bak/")
    write_png(dst_icon, icon)
    print("  [战士] 图标写出:", dst_icon)
    put_scml_and_png(os.path.join(MOD, "exported", "musha_jobbook_warrior"), "musha_jobbook_warrior", world)

    # ---- 剑士：二转赠礼的职业技能书 ----
    _n, bx, _a, _b = rows[1]
    icon = downscale(im, bx, ICON)
    world = downscale(im, bx, WORLD)
    write_png(os.path.join(MOD, "images", "inventoryimages", "musha_skillbook_saber.png"), icon)
    print("  [剑士] 图标写出: images/inventoryimages/musha_skillbook_saber.png")
    put_scml_and_png(os.path.join(MOD, "exported", "musha_skillbook_saber"), "musha_skillbook_saber", world)

    # ---- 近卫：只导出来留着（不上线）----
    _n, bx, _a, _b = rows[2]
    icon = downscale(im, bx, ICON)
    world = downscale(im, bx, WORLD)
    out_dir = os.path.join(MOD, "exported", "jobbook_guardian_未上线")
    os.makedirs(out_dir, exist_ok=True)
    write_png(os.path.join(out_dir, "icon_musha_jobbook_guardian.png"), icon)
    write_png(os.path.join(out_dir, "musha_jobbook_guardian.png"), world)
    print("  [近卫] 只导出备用（未接代码）→", out_dir)

    # 预览（三本并排：上排图标 6x，下排地上 3x）
    contact_sheet(
        [("icons", [downscale(im, rows[0][1], ICON), downscale(im, rows[1][1], ICON), downscale(im, rows[2][1], ICON)]),
         ("world", [downscale(im, rows[0][1], WORLD), downscale(im, rows[1][1], WORLD), downscale(im, rows[2][1], WORLD)])],
        os.path.join(HERE, "_test_out", "jobbook_art_preview.png"))
    print("预览:", os.path.join(HERE, "_test_out", "jobbook_art_preview.png"))


if __name__ == "__main__":
    main()
