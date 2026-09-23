# -*- coding: utf-8 -*-
"""基础衣服逐帧预览（带 pivot 红十字）—— 给用户看「现在的衣服长什么样」。

    python cloth_base_sheet.py <工程.scml> <out.png> torso torso_pelvis skirt ...

每个部件一行：左→右按 scml 里的 file id 顺序（= 帧号），
图上红十字 = 该帧的 pivot（Spriter 里的锚点），红字 = 帧号 + 画布尺寸 + pivot。
全透明的帧会画成「红线框 + 空白」（一眼能看出是占位）。
"""
import os, re, sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image
from boat_scml_render import draw_text

BG = (44, 46, 54)
CROSS = (255, 60, 90, 255)
CHECK = (70, 74, 86)


def parse_scml(path):
    txt = open(path, encoding="utf-8").read()
    folders = {}
    for fm in re.finditer(r'<folder id="(\d+)" name="([^"]+)">(.*?)</folder>', txt, re.S):
        fid, fname, body = int(fm.group(1)), fm.group(2), fm.group(3)
        files = []
        for x in re.finditer(
                r'<file id="(\d+)" name="([^"]+)" width="([\d.]+)" height="([\d.]+)" '
                r'pivot_x="([-\d.eE]+)" pivot_y="([-\d.eE]+)"', body):
            files.append(dict(id=int(x.group(1)), name=x.group(2),
                              w=int(float(x.group(3))), h=int(float(x.group(4))),
                              px=float(x.group(5)), py=float(x.group(6))))
        folders[fname] = files
    return folders


def blank(w, h):
    im = Image(w, h)
    return im


def draw_frame(cv, im, x, y, w, h, px, py):
    """把帧画到 cv 的 (x,y)，帧画布 w x h；再画 pivot 十字"""
    for yy in range(min(h, im.h)):
        for xx in range(min(w, im.w)):
            i = (yy * im.w + xx) * 4
            a = im.px[i + 3]
            if a == 0:
                continue
            j = ((y + yy) * cv.w + x + xx) * 4
            if a == 255:
                cv.px[j:j + 4] = im.px[i:i + 4]
            else:
                ia = 255 - a
                for k in range(3):
                    cv.px[j + k] = (im.px[i + k] * a + cv.px[j + k] * ia) // 255
                cv.px[j + 3] = 255
    # pivot 红十字（scml 的 y 向上为正）
    cx = x + int(round(w * px))
    cy = y + int(round(h * (1.0 - py)))
    for d in range(-7, 8):
        if 0 <= cx + d < cv.w:
            cv.put(cx + d, min(cv.h - 1, cy), CROSS)
        if 0 <= cy + d < cv.h:
            cv.put(min(cv.w - 1, cx), cy + d, CROSS)


def main():
    scml, out = sys.argv[1], sys.argv[2]
    parts = sys.argv[3:] or ["torso", "torso_pelvis", "skirt"]
    base = os.path.dirname(os.path.abspath(scml))
    folders = parse_scml(scml)
    rows = []
    report = []
    for p in parts:
        files = folders.get(p)
        if not files:
            report.append(f"{p}: scml 里没有这个 folder")
            continue
        ims = []
        for f in files:
            fp = os.path.join(base, f["name"])
            im = read_png(fp) if os.path.exists(fp) else blank(f["w"], f["h"])
            opaque = sum(1 for i in range(3, len(im.px), 4) if im.px[i] > 8)
            ims.append((im, f, opaque))
        gap, lab = 14, 30
        cw = max(f["w"] for _, f, _ in ims)
        ch = max(f["h"] for _, f, _ in ims)
        W = gap + len(ims) * (cw + gap)
        H = gap + ch + lab + gap
        cv = Image(W, H)
        for i in range(0, W * H * 4, 4):
            cv.px[i:i + 3] = bytes(BG)
            cv.px[i + 3] = 255
        x = gap
        for im, f, opaque in ims:
            # 画布=声明尺寸；实际图比声明小就居中放（并在地图上标出）
            dx = x + (cw - f["w"]) // 2
            dy = gap + (ch - f["h"]) // 2
            # 帧边框
            for xx in range(f["w"]):
                cv.put(dx + xx, dy, CHECK)
                cv.put(dx + xx, dy + f["h"] - 1, CHECK)
            for yy in range(f["h"]):
                cv.put(dx, dy + yy, CHECK)
                cv.put(dx + f["w"] - 1, dy + yy, CHECK)
            draw_frame(cv, im, dx, dy, f["w"], f["h"], f["px"], f["py"])
            draw_text(cv, x, H - lab + 2, "%d %dx%d P%.2f/%.2f" % (f["id"], f["w"], f["h"], f["px"], f["py"]), 1,
                      (140, 210, 255))
            x += cw + gap
        draw_text(cv, 4, 4, "%s  %d frames" % (p, len(ims)), 2, (255, 230, 120))
        rows.append(cv)
        report.append("%s: %d 帧, 声明画布 %s, 实际 %s, 不透明帧 %d/%d"
                      % (p, len(ims),
                         sorted({(f["w"], f["h"]) for _, f, _ in ims}),
                         sorted({(im.w, im.h) for im, _, _ in ims}),
                         sum(1 for _, _, o in ims if o > 0), len(ims)))
    if not rows:
        print("\n".join(report)); return
    W = max(r.w for r in rows)
    H = sum(r.h + 10 for r in rows) + 10
    cv = Image(W, H)
    for i in range(0, W * H * 4, 4):
        cv.px[i:i + 3] = bytes((28, 30, 36))
        cv.px[i + 3] = 255
    y = 10
    for r in rows:
        for yy in range(r.h):
            for xx in range(r.w):
                i = (yy * r.w + xx) * 4
                j = ((y + yy) * W + xx) * 4
                cv.px[j:j + 4] = r.px[i:i + 4]
        y += r.h + 10
    write_png(out, cv)
    print("写好:", out, cv.w, "x", cv.h)
    for l in report:
        print("  " + l)


if __name__ == "__main__":
    main()
