# -*- coding: utf-8 -*-
"""slice_nav_20260926.py — 重切导航横幅（图片/UI_{zh,en}.png → images/nav_*[_en].png）

背景（2026-09-26）：旧切法按固定 2列3行格子切，横幅比格子大 →
    nav_mail/set/gift/dex 顶部混入邻格碎屑、两侧切损（用户实测「切坏了 chatgpt用不了」）。
新切法（内容感知三步）：
    1) mask = (alpha>16) & ~白 —— 源图「白底+局部透明」混合，两态通吃（白底实为透明 alpha=0）；
    2) scipy 连通岛：整只横幅（含跨谷的兔子耳朵——整兔一岛、质心在本排）= 一个岛，
       按质心落 行谷 × 列谷 六宫格（谷位置按图高/宽比例自适应）；
    3) 每宫联合包围盒 → **按岛 ID 剔除矩形里的异岛像素**（上下排包围盒重叠 8~14px，
       不剔会带进下排耳尖/蝴蝶结尖）→ contain 进 512×256（左右 pad4、可见高上限 0.80）。
设计前提：面板 NAV 200×100、盒距 91.6，设计可见高 0.736 → 视觉缝 ≈18px；
    不切损 ⇒ 可见高实测 0.68-0.80 → 视觉缝 ≈12-22px（与旧 14-20 同量级）。

用法：
    python slice_nav_20260926.py analyze [zh|en]   # 只打印几何 + 旧成品统计，不写文件
    python slice_nav_20260926.py cut [zh|en]       # 切到 _tmp/nav_{zh,en}_20260926/ + QC 联络表
    python slice_nav_20260926.py install [zh|en]   # 备份旧 6 张 → 覆盖 images/nav_*[_en].png

映射（2列3行 行优先）：zh 主页/技能/信箱/设置/礼包/图鉴；en Home/Skills/Mailbox/Settings/Gift Pack/Gallery。
"""
import os
import sys
import shutil
import time

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

MOD = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
IMG_DIR = os.path.join(MOD, "images")

OUT_W, OUT_H = 512, 256          # 与现有 nav_*.png / 按钮 200×100 同为 2:1
PAD_X = 4                        # 左右各留 4px
H_CAP = 0.80                     # 可见高上限（防视觉缝塌掉；设计值 0.736）
MIN_ISLAND = 50                  # 连通岛最小面积（去尘）
BASE_NAMES = ["nav_home", "nav_skill", "nav_mail", "nav_set", "nav_gift", "nav_dex"]
LABELS = {
    "zh": ["主页", "技能", "信箱", "设置", "礼包", "图鉴"],
    "en": ["Home", "Skills", "Mailbox", "Settings", "Gift Pack", "Gallery"],
}
LANG = "zh"                      # 由 main 覆写


def names():
    return [n + ("" if LANG == "zh" else "_en") for n in BASE_NAMES]


def tmp_dir():
    return os.path.join(MOD, "exported", "_tools", "_tmp", "nav_%s_20260926" % LANG)


def backup_dir():
    return os.path.join(MOD, "exported", "_tools", "_art_backup",
                        "nav_%s_old_20260926" % LANG)


def find_source(lang):
    for p in (
        os.path.join(MOD, "图片", "UI_%s.png" % lang),
        os.path.join(MOD, "png", "UI_%s.png" % lang),
    ):
        if os.path.exists(p):
            return p
    raise SystemExit("找不到源图 UI_%s.png" % lang)


def load_mask(path):
    im = Image.open(path)
    a = np.array(im.convert("RGBA"))
    alpha = a[..., 3]
    rgb = a[..., :3].astype(int)
    whiteish = (rgb >= 245).all(axis=-1)
    mask = (alpha > 16) & (~whiteish)
    info = {
        "size": im.size, "mode": im.mode,
        "alpha_min": int(alpha.min()), "alpha_max": int(alpha.max()),
        "zero_pct": round(float((alpha == 0).mean()) * 100, 1),
        "white_pct": round(float(whiteish.mean()) * 100, 1),
        "opaque_white_pct": round(float((whiteish & (alpha > 16)).mean()) * 100, 1),
        "bg": "mixed-alpha+white",
    }
    return im, mask, info


def detect_boxes(mask):
    """连通岛 → 质心落六宫格 → 每宫联合包围盒。返回 (boxes, meta, meta_d, ids, lbl)。"""
    H, W = mask.shape
    rs = mask.sum(axis=1).astype(float)
    rss = np.convolve(rs, np.ones(5) / 5, mode="same")
    # 两条行谷按比例窗找（zh 实测 0.269-0.422 / 0.607-0.738）
    w1 = (int(0.269 * H), int(0.422 * H))
    w2 = (int(0.607 * H), int(0.738 * H))
    row_edges = (int(np.argmin(rss[w1[0]:w1[1]])) + w1[0],
                 int(np.argmin(rss[w2[0]:w2[1]])) + w2[0])
    cs = mask.sum(axis=0)
    # 最长全空列谷（0.301-0.784W 内）= 左右列分界
    x0w, x1w = int(0.301 * W), int(0.784 * W)
    runs, s = [], None
    for x in range(x0w, x1w):
        if cs[x] == 0 and s is None:
            s = x
        if cs[x] != 0 and s is not None:
            runs.append((s, x - 1)); s = None
    if s is not None:
        runs.append((s, x1w - 1))
    assert runs, "找不到列谷"
    zg = max(runs, key=lambda r: r[1] - r[0])
    col_edge = (zg[0] + zg[1]) / 2.0

    lbl, n = ndimage.label(mask, structure=np.ones((3, 3)))
    groups = {(r, c): [] for r in range(3) for c in range(2)}
    dropped = 0
    for i, sl in enumerate(ndimage.find_objects(lbl), start=1):
        if sl is None:
            continue
        m = (lbl[sl] == i)
        area = int(m.sum())
        if area < MIN_ISLAND:
            dropped += 1
            continue
        y0, y1 = sl[0].start, sl[0].stop - 1
        x0, x1 = sl[1].start, sl[1].stop - 1
        cy, cx = (y0 + y1) / 2.0, (x0 + x1) / 2.0
        r = 0 if cy < row_edges[0] else (1 if cy < row_edges[1] else 2)
        c = 0 if cx < col_edge else 1
        groups[(r, c)].append((x0, y0, x1, y1, area, i))

    boxes, meta, ids_all = [], [], []
    for r in range(3):
        for c in range(2):
            items = groups[(r, c)]
            assert items, "宫格 (row%d,col%d) 无岛" % (r, c)
            bx0 = min(it[0] for it in items); by0 = min(it[1] for it in items)
            bx1 = max(it[2] for it in items); by1 = max(it[3] for it in items)
            boxes.append((bx0, by0, bx1, by1))
            meta.append({"islands": len(items), "area": sum(it[4] for it in items)})
            ids_all.append([it[5] for it in items])
    meta_d = {"row_edges": row_edges, "col_edge": col_edge, "islands_dropped": dropped}
    return boxes, meta, meta_d, ids_all, lbl


def fit_box(b):
    w, h = b[2] - b[0] + 1, b[3] - b[1] + 1
    s = min((OUT_W - 2 * PAD_X) / w, (OUT_H * H_CAP) / h)
    return max(1, round(w * s)), max(1, round(h * s))


def analyze():
    src = find_source(LANG)
    im, mask, info = load_mask(src)
    print("SRC", src)
    print(info)
    boxes, meta, meta_d, ids_all, lbl = detect_boxes(mask)
    print("gates:", meta_d)
    print("---- detected bboxes (row-major) ----")
    for i, (n, lb, b, m) in enumerate(zip(names(), LABELS[LANG], boxes, meta)):
        w, h = b[2] - b[0] + 1, b[3] - b[1] + 1
        nw, nh = fit_box(b)
        rect_lbl = lbl[b[1]:b[3] + 1, b[0]:b[2] + 1]
        foreign = int(np.isin(
            rect_lbl, [x for j, lst in enumerate(ids_all) if j != i for x in lst]).sum())
        print("%-14s %-10s bbox=%-26s w=%d h=%d aspect=%.2f islands=%d -> fit %dx%d h_ratio=%.3f rect异岛px=%d"
              % (n, lb, str(b), w, h, w / h, m["islands"], nw, nh, nh / OUT_H, foreign))
    print("---- old visible bbox (alpha>16) ----")
    for n in names():
        p = os.path.join(IMG_DIR, n + ".png")
        ba = np.array(Image.open(p).convert("RGBA"))[..., 3]
        ys, xs = np.where(ba > 16)
        bb = (int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()))
        bw, bh = bb[2] - bb[0] + 1, bb[3] - bb[1] + 1
        print("%-14s bbox=%-26s w=%d h=%d h_ratio=%.3f cx=%.1f cy=%.1f"
              % (n, str(bb), bw, bh, bh / OUT_H, (bb[0] + bb[2]) / 2, (bb[1] + bb[3]) / 2))


def cut():
    src = find_source(LANG)
    im, mask, info = load_mask(src)
    boxes, meta, meta_d, ids_all, lbl = detect_boxes(mask)
    out_dir = tmp_dir()
    os.makedirs(out_dir, exist_ok=True)
    out_paths = []
    print("gates:", meta_d)
    for idx, (n, b) in enumerate(zip(names(), boxes)):
        w, h = b[2] - b[0] + 1, b[3] - b[1] + 1
        nw, nh = fit_box(b)
        # 上下排包围盒可重叠 8~14px：矩形裁切须按连通岛 ID 剔除异岛像素
        # （自家白件不在任何岛里、不受影响；白底实为透明 alpha=0 本就无害）
        rect = (b[0], b[1], b[2] + 1, b[3] + 1)
        crop = np.array(im.crop(rect))
        rect_lbl = lbl[b[1]:b[3] + 1, b[0]:b[2] + 1]
        foreign_ids = [x for j, lst in enumerate(ids_all) if j != idx for x in lst]
        foreign = np.isin(rect_lbl, foreign_ids)
        excluded = int(foreign.sum())
        crop[..., 3] = np.where(foreign, 0, crop[..., 3])
        cropped = Image.fromarray(crop, "RGBA").resize((nw, nh), Image.LANCZOS)
        canvas = Image.new("RGBA", (OUT_W, OUT_H), (0, 0, 0, 0))
        canvas.paste(cropped, ((OUT_W - nw) // 2, (OUT_H - nh) // 2))
        p = os.path.join(out_dir, n + ".png")
        canvas.save(p)
        out_paths.append(p)
        print("cut %-14s bbox=%-26s -> %dx%d h_ratio=%.3f 剔异岛px=%d"
              % (n, str(b), nw, nh, nh / OUT_H, excluded))
    # 源图红框覆盖图（几何裁决）
    ov = im.convert("RGB")
    d = ImageDraw.Draw(ov)
    for i, b in enumerate(boxes):
        d.rectangle([b[0], b[1], b[2], b[3]], outline=(255, 0, 0), width=5)
        d.text((b[0] + 8, b[1] + 8), names()[i], fill=(255, 0, 0))
    ov_path = os.path.join(out_dir, "qc_boxes_overlay.png")
    ov.save(ov_path)
    print("overlay:", ov_path)
    # QC 联络表（深灰底）
    cw, ch = 384, 192
    sheet = Image.new("RGB", (cw * 3, (ch + 18) * 2), (58, 58, 66))
    d = ImageDraw.Draw(sheet)
    for i, p in enumerate(out_paths):
        t = Image.open(p).convert("RGBA")
        bg = Image.new("RGBA", t.size, (58, 58, 66, 255))
        bg.alpha_composite(t)
        bg = bg.convert("RGB")
        bg.thumbnail((cw - 6, ch - 6))
        x, y = (i % 3) * cw + 3, (i // 3) * (ch + 18) + 3
        sheet.paste(bg, (x, y))
        d.text((x, y + ch - 2), "%d %s" % (i, names()[i]), fill=(255, 255, 0))
    qc = os.path.join(out_dir, "qc_nav_new.png")
    sheet.save(qc)
    print("QC:", qc)


def install():
    out_dir = tmp_dir()
    assert os.path.isdir(out_dir), "先跑 cut"
    bk = backup_dir()
    os.makedirs(bk, exist_ok=True)
    for n in names():
        old = os.path.join(IMG_DIR, n + ".png")
        new = os.path.join(out_dir, n + ".png")
        assert os.path.exists(new), "缺 " + new
        old_kb = os.path.getsize(old) // 1024 if os.path.exists(old) else 0
        if os.path.exists(old):
            shutil.copy2(old, os.path.join(bk, n + ".png"))
        shutil.copy2(new, old)
        print("install %-14s old=%dKB new=%dKB" % (n, old_kb, os.path.getsize(old) // 1024))
    print("backup:", bk)
    print("mtime stamp:", time.strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "analyze"
    LANG = sys.argv[2] if len(sys.argv) > 2 else "zh"
    assert LANG in LABELS, "lang 只支持 zh/en"
    {"analyze": analyze, "cut": cut, "install": install}[mode]()
