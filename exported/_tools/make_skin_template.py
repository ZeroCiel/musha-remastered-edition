# -*- coding: utf-8 -*-
"""musha 皮肤模板生成器 —— 一条命令把「Mod Tool 导出的 build 源」变成可画的 Spriter 工程 + 参考图。

    python make_skin_template.py <源目录(含 build.xml/animation.xml/*.png)> <输出目录> [模板名] [--from-scml 现有工程.scml]

产物：
    <输出>/<名>.scml               Spriter 工程（39 个 key = 39 个真实姿态）
    <输出>/<符号>/*.png            按符号分文件夹的贴图槽
    <输出>/参考图/*.png            每个符号的帧表 + 全符号总览 + 39 姿态总表（给画师/ChatGPT 看）
    <输出>/README_模板.md          符号表/画布尺寸/画什么/怎么编译
"""
import os, re, sys, math, shutil, struct
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from buildxml_to_scml import parse_build, parse_anim, build_scml, copy_images
from pnglib import read_png, write_png, Image
from boat_scml_render import FONT, draw_text, text_w

BG = (44, 46, 54)
GRID = (66, 70, 82)

# 每个符号是「画在哪」的中文说明（按名字推断，2026-09-18 看图后写的）
DESC = {
    "headbase": "头（基础头型，多帧=正/侧/背等朝向）",
    "headbase_hat": "头（戴帽版本，配合帽子遮挡）",
    "hair": "头发（后发/发束）",
    "hairfront": "前刘海",
    "hair_hat": "帽子压住的头发",
    "hairpigtails": "双马尾",
    "face": "表情（33 帧，正面/侧面/背面 + 各种表情）",
    "cheeks": "腮红",
    "torso": "上衣/躯干（衣服正面背面分帧）",
    "torso_pelvis": "腰胯/下摆",
    "skirt": "裙子（当前是空白占位，要画）",
    "arm_upper": "上臂（衣服袖子）",
    "arm_lower": "小臂（衣服）",
    "arm_upper_skin": "上臂露肤部分",
    "hand": "手（20 帧：张手/握拳/持物/不同朝向）",
    "leg": "腿（裤子）",
    "foot": "脚（鞋子，8 帧朝向）",
    "tail": "尾巴（12 帧，狐狸尾巴分段）",
    "swap_icon": "手持物品时的替换图标（单帧）",
}


def label(cv, x, y, text, scale=2, col=(150, 225, 255)):
    draw_text(cv, x, y, text, scale, col)


def frame_cells(sym, frames, srcdir, max_w=1250):
    """把某个符号的所有帧横排，返回 (Image, 每帧的 x 偏移)"""
    ims = []
    for f in frames:
        p = os.path.join(srcdir, sym, f["img"] + ".png")
        ims.append(read_png(p) if os.path.exists(p) else Image(f["w"], f["h"]))
    gap = 12
    label_h = 26
    W = sum(i.w for i in ims) + gap * (len(ims) + 1)
    H = max(i.h for i in ims) + label_h + gap * 2
    cv = Image(W, H)
    for i in range(0, W * H * 4, 4):
        cv.px[i:i + 3] = bytes(BG); cv.px[i + 3] = 255
    x = gap
    for n, (im, f) in enumerate(zip(ims, frames)):
        y = gap + (max(i.h for i in ims) - im.h)
        for yy in range(im.h):
            for xx in range(im.w):
                i = (yy * im.w + xx) * 4
                a = im.px[i + 3]
                if a == 0:
                    continue
                j = ((y + yy) * W + x + xx) * 4
                if a == 255:
                    cv.px[j:j + 4] = im.px[i:i + 4]
                else:
                    ia = 255 - a
                    for k in range(3):
                        cv.px[j + k] = (im.px[i + k] * a + cv.px[j + k] * ia) // 255
                    cv.px[j + 3] = 255
        # pivot 十字
        px = x + int(f["w"] * (0.5 - f["x"] / f["w"]))
        py = y + int(f["h"] * (0.5 + f["y"] / f["h"]))
        for d in range(-7, 8):
            if 0 <= px + d < W:
                cv.put(px + d, min(H - 1, py), (255, 60, 90, 255))
            if 0 <= py + d < H:
                cv.put(min(W - 1, px), py + d, (255, 60, 90, 255))
        label(cv, x, H - label_h + 2, "%d  %dX%d" % (f["n"], f["w"], f["h"]), 2,
              (140, 210, 255))
        x += im.w + gap
    return cv


def build(srcdir, outdir, name, names_from=None):
    syms = parse_build(os.path.join(srcdir, "build.xml"))
    anim = parse_anim(os.path.join(srcdir, "animation.xml"))
    override = None
    if names_from and os.path.exists(names_from):
        ref = re.findall(r'<timeline id="\d+" name="([^"]+)"', open(names_from, encoding="utf-8").read())
        if len(ref) == len(anim["frames"][0][1]):
            override = ref
            print("  时间轴名沿用:", os.path.basename(names_from))
    scml, names = build_scml(syms, anim, names_override=override)
    os.makedirs(outdir, exist_ok=True)
    open(os.path.join(outdir, name + ".scml"), "w", encoding="utf-8").write(scml)
    shutil.copy2(os.path.join(srcdir, "build.xml"), os.path.join(outdir, "build.xml"))
    shutil.copy2(os.path.join(srcdir, "animation.xml"), os.path.join(outdir, "animation.xml"))
    blanks = copy_images(syms, srcdir, outdir)
    blank_set = set(b[0] for b in blanks)

    refdir = os.path.join(outdir, "参考图")
    os.makedirs(refdir, exist_ok=True)
    rows = []
    for sym, frames in syms:
        cv = frame_cells(sym, frames, outdir)
        write_png(os.path.join(refdir, "%s_帧表.png" % sym), cv)
        rows.append((sym, cv))
        print("  参考图 %-16s %d 帧 %dx%d" % (sym, len(frames), cv.w, cv.h))

    # 总览（每个符号一行，缩到宽 1200）
    scale = 0.5
    W = 0
    H = 0
    scaled = []
    for sym, cv in rows:
        w, h = int(cv.w * scale), int(cv.h * scale)
        out = Image(w, h)
        for y in range(h):
            sy = min(cv.h - 1, int(y / scale))
            for x in range(w):
                sx = min(cv.w - 1, int(x / scale))
                i = (sy * cv.w + sx) * 4
                j = (y * w + x) * 4
                out.px[j:j + 4] = cv.px[i:i + 4]
        scaled.append((sym, out))
        W = max(W, w); H += h + 8
    W += 8
    ov = Image(W, H)
    for i in range(0, W * H * 4, 4):
        ov.px[i:i + 3] = bytes(BG); ov.px[i + 3] = 255
    y = 4
    for sym, im in scaled:
        for yy in range(im.h):
            for xx in range(im.w):
                i = (yy * im.w + xx) * 4
                a = im.px[i + 3]
                if a == 0:
                    continue
                j = ((y + yy) * W + 4 + xx) * 4
                if a == 255:
                    ov.px[j:j + 4] = im.px[i:i + 4]
                else:
                    ia = 255 - a
                    for k in range(3):
                        ov.px[j + k] = (im.px[i + k] * a + ov.px[j + k] * ia) // 255
                    ov.px[j + 3] = 255
        y += im.h + 8
    write_png(os.path.join(refdir, "00_全符号总览.png"), ov)
    print("  参考图 00_全符号总览.png %dx%d" % (W, H))

    # 39 姿态总表
    import musha_scml_render as R
    folders, anims = R.load_scml(os.path.join(outdir, name + ".scml"))
    A = anims[list(anims)[0]]
    cache = {}
    ims = []
    for kid, _ in A["keys"]:
        im = R.render_key(folders, A, kid, outdir, 0.28, None, (40, 42, 50), cache=cache)
        if im:
            ims.append(im)
    sh = R.sheet(ims, 8, (40, 42, 50), 6)
    write_png(os.path.join(refdir, "01_角色姿态总表.png"), sh)
    print("  参考图 01_角色姿态总表.png %dx%d（%d 个 key）" % (sh.w, sh.h, len(ims)))

    # README
    L = []
    L.append("# %s —— 皮肤模板（自动生成）\n" % name)
    L.append("生成工具：`exported/_tools/make_skin_template.py`（源 = `build.xml` + `animation.xml` + 贴图）\n")
    L.append("## 这个工程是什么\n")
    L.append("- Spriter 工程（`.scml`）+ 每符号一个子文件夹的贴图槽，可直接用 Mod Tool / `scml.exe` 编译成")
    L.append("  `anim/%s.zip`（包内 build 名 = `%s`，动画名 = `BUILD_PLAYER`）\n" % (name, name))
    L.append("- %d 个符号、%d 张图、%d 个 key（`BUILD_PLAYER` 长度 %d）。**实测：源数据里这 %d 帧完全相同**"
             "（DST 角色 build 的惯例 = 单姿态模板，游戏动作由 bank 提供），"
             "每个 key 里排着 3 列朝向部件（x≈-325 / 0 / +352）"
             % (len(syms), sum(len(f) for _, f in syms), len(A["keys"]), A["length"], len(A["keys"])))
    L.append("- 坐标系：Spriter 的 y 向上为正；pivot 就是每帧贴图的「锚点」，**改图不要改 pivot**，")
    L.append("  画布尺寸（每帧的 w×h）也**必须保持**，否则会错位\n")
    L.append("## 画皮肤怎么用（推荐流程）\n")
    L.append("1. `参考图/` 里每个符号都有帧表（红十字符号 = pivot 位置）→ 交给画师/ChatGPT 当参考")
    L.append("2. 按「符号 > 帧号」逐张替换 `<符号>/<符号>-N.png`，**尺寸必须等于帧表里标的 w×h**")
    L.append("3. 编译：`scml.exe <本目录>/%s.scml <输出目录>` → `<输出目录>/anim/%s.zip`" % (name, name))
    L.append("4. 把 zip 放进 `mods/musha/anim/`，代码里 `SetBuild(\"%s\")`（或做皮肤切换）" % name)
    L.append("")
    L.append("## 符号表\n")
    L.append("| 符号 | 帧数 | 画布尺寸（各帧） | 说明 | 占位/缺图 |")
    L.append("|---|---|---|---|---|")
    for sym, frames in syms:
        dims = sorted(set("%dx%d" % (f["w"], f["h"]) for f in frames))
        miss = [f["img"] for f in frames if f["img"] in blank_set]
        L.append("| `%s` | %d | %s | %s | %s |" % (
            sym, len(frames), ", ".join(dims), DESC.get(sym, ""),
            ("⚠ 源里是空图/被缩放：" + ", ".join(miss[:6]) + ("…" if len(miss) > 6 else "")) if miss else ""))
    L.append("")
    L.append("## 编译检查（照抄）\n")
    L.append("```bash")
    L.append('"%s/mod_tools/scml.exe" "<本目录>/%s.scml" "<输出目录>"' % (r"D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools", name))
    L.append("```")
    L.append("")
    L.append("## 已知注意\n")
    L.append("- 源包里 `tail` / `hairfront` / `hair_hat` / `skirt` 是 100x100 全透明占位（真实画布更大，见上表）：")
    L.append("  这几个槽位在游戏里本来就看不见，**要显示就得按表里的尺寸重画**。")
    L.append("- 包内图层名与原工程的重名编号可能不同（只影响 `AnimState:Hide(图层名)` 这类按名字隐藏的代码，不影响显示）。")
    open(os.path.join(outdir, "README_模板.md"), "w", encoding="utf-8").write("\n".join(L) + "\n")
    print("  README_模板.md")
    return blanks


if __name__ == "__main__":
    src = sys.argv[1]
    out = sys.argv[2]
    name = sys.argv[3] if len(sys.argv) > 3 else os.path.basename(os.path.normpath(out))
    nf = None
    if "--from-scml" in sys.argv:
        nf = sys.argv[sys.argv.index("--from-scml") + 1]
    print("源:", src, "\n输出:", out, "\n名字:", name)
    blanks = build(src, out, name, nf)
    print("占位/缩放图 %d 张" % len(blanks))
