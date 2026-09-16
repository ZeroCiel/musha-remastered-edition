"""把官方 boat_cannon 的 scml 直接按 z_index + x/y + pivot 拼出来（验证"关联"结构）

用途：输出两张图到桌面
  1) 官方boat_cannon_朝向表_20260916.png  —— 5 个朝向的 idle 拼装图 + 各部件帧序对照（带 pivot 红十字）
  2) 官方boat_cannon_组装验证_20260916.png —— 12 层按 z 叠加的逐层分解（选修，脚本第二段）

关键口径（已实测）：
  * Spriter 的 y 是"向上为正"（图里 barrel y=163 在 base y=54 上方）→ 画布 y = cy - y
  * 素材 pivot_y 从"图片底部"往上数 → 图片内坐标 p = (pivot_x*w, (1-pivot_y)*h)
  * 摆放：物体 pivot 点落在动画坐标 (x, y) 上 → 左上角 = (cx + x - p.x, cy - y - p.y)
  * angle 是绕 pivot 旋转（-180 就是把同一张侧板翻转当另一侧用）
运行：python boat_scml_render.py
"""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import xml.etree.ElementTree as ET
from pnglib import read_png, write_png, Image, blit

SCML = r"C:\Users\Administrator\Desktop\boat_cannon(2)\boat_cannon.scml"
DESK = r"C:\Users\Administrator\Desktop"
OUT_DIR = os.path.dirname(os.path.abspath(__file__))

# ---------- 5x7 点阵字体（只用大写/数字/_-. :） ----------
FONT = {
 "A":[".###.","#...#","#...#","#####","#...#","#...#","#...#"],
 "B":["####.","#...#","#...#","####.","#...#","#...#","####."],
 "C":[".###.","#...#","#....","#....","#....","#...#",".###."],
 "D":["####.","#...#","#...#","#...#","#...#","#...#","####."],
 "E":["#####","#....","#....","####.","#....","#....","#####"],
 "F":["#####","#....","#....","####.","#....","#....","#...."],
 "G":[".###.","#...#","#....","#.###","#...#","#...#",".###."],
 "H":["#...#","#...#","#...#","#####","#...#","#...#","#...#"],
 "I":["#####","..#..","..#..","..#..","..#..","..#..","#####"],
 "J":["....#","....#","....#","....#","#...#","#...#",".###."],
 "K":["#...#","#..#.","#.#..","##...","#.#..","#..#.","#...#"],
 "L":["#....","#....","#....","#....","#....","#....","#####"],
 "M":["#...#","##.##","#.#.#","#...#","#...#","#...#","#...#"],
 "N":["#...#","##..#","#.#.#","#..##","#...#","#...#","#...#"],
 "O":[".###.","#...#","#...#","#...#","#...#","#...#",".###."],
 "P":["####.","#...#","#...#","####.","#....","#....","#...."],
 "Q":[".###.","#...#","#...#","#...#","#.#.#","#..#.",".##.#"],
 "R":["####.","#...#","#...#","####.","#.#..","#..#.","#...#"],
 "S":[".####","#....","#....",".###.","....#","....#","####."],
 "T":["#####","..#..","..#..","..#..","..#..","..#..","..#.."],
 "U":["#...#","#...#","#...#","#...#","#...#","#...#",".###."],
 "V":["#...#","#...#","#...#","#...#","#...#",".#.#.","..#.."],
 "W":["#...#","#...#","#...#","#.#.#","#.#.#","##.##","#...#"],
 "X":["#...#","#...#",".#.#.","..#..",".#.#.","#...#","#...#"],
 "Y":["#...#","#...#",".#.#.","..#..","..#..","..#..","..#.."],
 "Z":["#####","....#","...#.","..#..",".#...","#....","#####"],
 "0":[".###.","#...#","#..##","#.#.#","##..#","#...#",".###."],
 "1":["..#..",".##..","..#..","..#..","..#..","..#..",".###."],
 "2":[".###.","#...#","....#","...#.","..#..",".#...","#####"],
 "3":["#####","...#.","..#..","...#.","....#","#...#",".###."],
 "4":["...#.","..##.",".#.#.","#..#.","#####","...#.","...#."],
 "5":["#####","#....","####.","....#","....#","#...#",".###."],
 "6":["..##.",".#...","#....","####.","#...#","#...#",".###."],
 "7":["#####","....#","...#.","..#..",".#...",".#...",".#..."],
 "8":[".###.","#...#","#...#",".###.","#...#","#...#",".###."],
 "9":[".###.","#...#","#...#",".####","....#","...#.",".##.."],
 "_":[".....",".....",".....",".....",".....",".....","#####"],
 "-":[".....",".....",".....","#####",".....",".....","....."],
 ".":[".....",".....",".....",".....",".....",".##..",".##.."],
 "/":["....#","...#.","...#.","..#..",".#...",".#...","#...."],
 ":":[".....",".##..",".##..",".....",".##..",".##..","....."],
 " ":[".....",".....",".....",".....",".....",".....","....."],
}


def draw_text(cv, x, y, text, scale=2, col=(232, 232, 240)):
    for ch in text.upper():
        g = FONT.get(ch, FONT[" "])
        for ry, row in enumerate(g):
            for rx, c in enumerate(row):
                if c == "#":
                    for dy in range(scale):
                        for dx in range(scale):
                            cv.put(x + rx * scale + dx, y + ry * scale + dy, (col[0], col[1], col[2], 255))
        x += 6 * scale
    return x


def text_w(text, scale=2):
    return len(text) * 6 * scale


def alpha_blit(dst, src, dx, dy, ang=0.0, piv=None):
    """把 src 以 pivot 为中心旋转 ang 度后贴到 dst 的 (dx,dy)（dx,dy 是 src 左上角未旋转时的位置）"""
    if abs(ang) < 0.001:
        blit(dst, src, dx, dy)
        return
    rad = math.radians(ang)
    ca, sa = math.cos(rad), math.sin(rad)
    px, py = piv
    for y in range(src.h):
        for x in range(src.w):
            i = (y * src.w + x) * 4
            a = src.px[i + 3]
            if a == 0:
                continue
            # 相对 pivot 的向量，反向旋转求源坐标
            vx, vy = x - px, y - py
            sx = px + vx * ca - vy * sa
            sy = py + vx * sa + vy * ca
            tx, ty = dx + int(round(sx)), dy + int(round(sy))
            if 0 <= tx < dst.w and 0 <= ty < dst.h:
                j = (ty * dst.w + tx) * 4
                if a == 255:
                    dst.px[j:j + 4] = src.px[i:i + 4]
                else:
                    ia = 255 - a
                    for k in range(3):
                        dst.px[j + k] = (src.px[i + k] * a + dst.px[j + k] * ia) // 255
                    dst.px[j + 3] = 255


def cross(cv, x, y, size=9, col=(255, 40, 90)):
    for d in range(-size, size + 1):
        if 0 <= x + d < cv.w:
            cv.put(x + d, y, (col[0], col[1], col[2], 255))
            if abs(d) < 3:
                cv.put(x + d, y + 1, (col[0], col[1], col[2], 255))
        if 0 <= y + d < cv.h:
            cv.put(x, y + d, (col[0], col[1], col[2], 255))
            if abs(d) < 3:
                cv.put(x + 1, y + d, (col[0], col[1], col[2], 255))


def load():
    root = ET.parse(SCML).getroot()
    folders = {}
    for f in root.findall("folder"):
        folders[int(f.get("id"))] = {
            "name": f.get("name"),
            "files": [(x.get("name"), int(x.get("width")), int(x.get("height")),
                       float(x.get("pivot_x")), float(x.get("pivot_y"))) for x in f.findall("file")],
        }
    anims = {}
    ent = root.find("entity")
    for a in ent.findall("animation"):
        zmap = {}
        ml = a.find("mainline")
        if ml is not None:
            for o in ml.find("key").findall("object_ref"):
                zmap[o.get("timeline")] = int(o.get("z_index"))
        layers = []
        for tl in a.findall("timeline"):
            k = tl.find("key")
            o = k.find("object")
            layers.append(dict(
                z=zmap.get(tl.get("id"), 99),
                tl=tl.get("name"),
                folder=int(o.get("folder")), file=int(o.get("file")),
                x=float(o.get("x") or 0), y=float(o.get("y") or 0),
                ang=float(o.get("angle") or 0),
                sx=float(o.get("scale_x") or 1), sy=float(o.get("scale_y") or 1),
            ))
        anims[a.get("name")] = dict(length=int(a.get("length")), interval=int(a.get("interval") or 33), layers=layers)
    return folders, anims


CACHE = {}


def get_img(folders, fid, i):
    key = (fid, i)
    if key not in CACHE:
        rel = folders[fid]["files"][i][0]
        CACHE[key] = read_png(os.path.join(os.path.dirname(SCML), rel.replace("/", os.sep)))
    return CACHE[key]


def render_anim(folders, anim, pad=40):
    """按 z 叠加拼出一个朝向的完整图；返回 (Image, 每层信息)"""
    W = H = 0
    pos = []
    for L in sorted(anim["layers"], key=lambda z: z["z"]):
        fname, w, h, pvx, pvy = folders[L["folder"]]["files"][L["file"]]
        p = (pvx * w, (1.0 - pvy) * h)
        left = L["x"] - p[0]
        top = -L["y"] - p[1]
        pos.append((L, left, top, w, h, p))
        W = max(W, left + w)
        H = max(H, top + h)
    minx = min(p[1] for p in pos)
    miny = min(p[2] for p in pos)
    W = int(math.ceil(W - minx)) + pad * 2
    H = int(math.ceil(H - miny)) + pad * 2
    cv = Image(W, H)
    for i in range(0, W * H * 4, 4):
        cv.px[i:i + 3] = b"\x00\x00\x00"
        cv.px[i + 3] = 0
    info = []
    for L, left, top, w, h, p in pos:
        src = get_img(folders, L["folder"], L["file"])
        alpha_blit(cv, src, int(round(left - minx)) + pad, int(round(top - miny)) + pad, L["ang"], p)
        info.append((L["z"], L["tl"], folders[L["folder"]]["name"] + "/" + folders[L["folder"]]["files"][L["file"]][0].split("/")[-1],
                     int(round(left - minx)) + pad, int(round(top - miny)) + pad))
    return cv, info


BG = (48, 50, 58)
FACINGS = ["down", "downside", "side", "upside", "up"]


def main():
    folders, anims = load()
    # 先量：拼装图最大多大
    renders = {}
    for f in FACINGS:
        renders[f] = render_anim(folders, anims["idle_" + f])
    cw = max(r[0].w for r in renders.values()) + 12
    chh = max(r[0].h for r in renders.values()) + 12
    title_h = 90
    # 行1：5 个朝向拼装
    row1 = chh + 70
    # 行2：barrel 帧序 0..4
    bar = folders[0]
    row2h = max(bar["files"][i][2] for i in range(5)) + 90
    side = folders[1]
    row3h = max(side["files"][i][2] for i in range(4)) + 90
    shared_ids = [11, 6, 3, 15]  # shadow, base, basebottom, fuse
    shared_imgs = []
    for fid in shared_ids:
        for i in range(len(folders[fid]["files"])):
            shared_imgs.append((fid, i))
    row4h = max(folders[fid]["files"][i][2] for fid, i in shared_imgs) + 90
    W = max(cw * 5 + 60, 1200)
    H = title_h + row1 + row2h + row3h + row4h + 40
    cv = Image(W, H)
    for i in range(0, W * H * 4, 4):
        cv.px[i:i + 3] = bytes(BG)
        cv.px[i + 3] = 255

    y = 20
    draw_text(cv, 30, y, "OFFICIAL BOAT_CANNON - HOW 8-FACING IS PACKED", 3, (255, 214, 120))
    y += 34
    draw_text(cv, 30, y, "SAME BANK, 5 ART FACINGS: IDLE_DOWN / IDLE_DOWNSIDE / IDLE_SIDE / IDLE_UPSIDE / IDLE_UP", 2, (200, 205, 215))
    y = title_h

    # ---- 行1：拼装 ----
    x = (W - cw * 5) // 2
    for f in FACINGS:
        im, info = renders[f]
        dx = x + (cw - im.w) // 2
        dy = y + (chh - im.h) // 2
        blit(cv, im, dx, dy)
        lbl = "IDLE_" + f.upper()
        draw_text(cv, x + (cw - text_w(lbl, 2)) // 2, y + chh + 6, lbl, 2, (140, 230, 255))
        x += cw
    y += row1

    # ---- 行2：cannon_barrel 帧序 ----
    draw_text(cv, 30, y - 26, "SYMBOL CANNON_BARREL: FRAME INDEX 0..4 == FACING ORDER (PIVOT = RED CROSS)", 2, (255, 214, 120))
    x = 40
    for i in range(5):
        fname, w, h, pvx, pvy = bar["files"][i]
        im = get_img(folders, 0, i)
        blit(cv, im, x, y + (row2h - 90 - h) // 2)
        cross(cv, x + int(pvx * w), y + (row2h - 90 - h) // 2 + int((1 - pvy) * h))
        draw_text(cv, x + 30, y + row2h - 60, f"F{i} {FACINGS[i].upper()}"[:14], 2, (140, 230, 255))
        x += w + 40
    y += row2h

    # ---- 行3：cannon_side ----
    draw_text(cv, 30, y - 26, "SYMBOL CANNON_SIDE: F0 USED FOR DOWN/UP, F2 FOR SIDE, F1+F3 BOTH USED FOR DIAGONALS", 2, (255, 214, 120))
    x = 40
    for i in range(4):
        fname, w, h, pvx, pvy = side["files"][i]
        im = get_img(folders, 1, i)
        blit(cv, im, x, y + (row3h - 90 - h) // 2)
        cross(cv, x + int(pvx * w), y + (row3h - 90 - h) // 2 + int((1 - pvy) * h))
        draw_text(cv, x + 20, y + row3h - 60, f"SIDE F{i}", 2, (140, 230, 255))
        x += w + 50
    y += row3h

    # ---- 行4：共用部件 ----
    draw_text(cv, 30, y - 26, "SHARED LAYERS (SINGLE FRAME, NOT PER-FACING): SHADOW / BASE / BASEBOTTOM / FUSE", 2, (255, 214, 120))
    x = 40
    for fid, i in shared_imgs:
        fname, w, h, pvx, pvy = folders[fid]["files"][i]
        im = get_img(folders, fid, i)
        blit(cv, im, x, y + (row4h - 90 - h) // 2)
        cross(cv, x + int(pvx * w), y + (row4h - 90 - h) // 2 + int((1 - pvy) * h))
        nm = ("FUSE_F%d" % i) if folders[fid]["name"] == "cannon_fuse" else folders[fid]["name"].upper()
        draw_text(cv, x, y + row4h - 60, nm[:16], 2, (140, 230, 255))
        x += w + 40

    out = os.path.join(DESK, "官方boat_cannon_朝向表_20260916.png")
    write_png(out, cv)
    print("写好:", out, cv.w, "x", cv.h)
    return renders


if __name__ == "__main__":
    main()
