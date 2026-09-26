#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
crescent_reorient.py —— 把 8 张 crescent_dir*.png 精确转到**官方后缀名对应的屏幕方向**
==================================================================================
2026-09-26 用户指令「动画命名方向是错的，按官方的写法做八个面」→ 根因实测 + 修法：

根因（dir_measure 实测）：
  · 旧图按「世界格中心 45k+22.5°」经 K_SCREEN=0.5 压扁投影 → **屏幕指向不均匀**
    （间隔 79.3/38.7/23.4/38.7…），对官方 nominal 标签的偏差 = +8.4/+42.7/+36.4/+14.8°…
    → dir1/dir2/dir5/dir6 错到快半格；且裸改名会撞名（left/right 各抢两张、down/up 无人指）
  · 结论：**必须重定图的指向，不能只改名**；图对了，官方名才是真的。

修法（闭环自校准）：
  1. 先在临时副本上标定 rotate_by(d) 的实际符号约定（PIL 正角方向因版本而异）
  2. 测每张图当前飞行指向 flight（PCA 主轴 + 前后判别；flight = pointing - 90）
  3. delta = 最短差(NOM_k - flight)，按标定符号转；复测 |flight - NOM| <= 2° 才算过
  4. alpha bbox 重新居中到画布中心（游戏 pivot = 画布中心，生成器同款口径）
  5. 原图备份在 _bak_dirs_原版_20260926/，回退 = 拷回 + 重编 zip

官方映射（scml: file k -> slash_<后缀>；NOM = 屏幕角 y-down，0=右，90=下）：
  dir0->downright(45) dir1->down(90) dir2->downleft(135) dir3->left(180)
  dir4->upleft(225)    dir5->up(270) dir6->upright(315)   dir7->right(0)

跑法：python crescent_reorient.py          （Python311，带 PIL）
"""
import math
import os
import shutil
import sys
import tempfile

from PIL import Image

MOD = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
PROJ = os.path.join(MOD, "exported", "crescent_moon")
# 官方后缀顺序（file id = 下标）与对应 nominal 屏幕角
FACING = ["downright", "down", "downleft", "left", "upleft", "up", "upright", "right"]
NOM = [45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0, 0.0]
TOL = 2.0          # 容差（度）——PCA 对"上窄下宽"有 ~3° 固定倾斜，闭环下该偏差自抵消
CANVAS = 1280      # scml 声明的画布尺寸


def shortest(a, b):
    """a-b 折到 (-180,180]"""
    d = (a - b) % 360.0
    return d - 360.0 if d > 180.0 else d


def measure(path):
    """返回 (flight, pointing)：flight = 凸面白刃朝向（屏幕角 y-down，0=右，90=下）"""
    im = Image.open(path).convert("RGBA")
    W, H = im.size
    px = im.load()
    pts = [(x, y) for y in range(0, H, 2) for x in range(0, W, 2) if px[x, y][3] > 64]
    if not pts:
        raise RuntimeError("no alpha pixels: " + path)
    n = len(pts)
    cx = sum(p[0] for p in pts) / n
    cy = sum(p[1] for p in pts) / n
    sxx = sum((p[0] - cx) ** 2 for p in pts) / n
    syy = sum((p[1] - cy) ** 2 for p in pts) / n
    sxy = sum((p[0] - cx) * (p[1] - cy) for p in pts) / n
    ang = 0.5 * math.atan2(2 * sxy, sxx - syy)           # 主轴（弦向，mod 180°）
    ca, sa = math.cos(ang), math.sin(ang)
    us = [(p[0] - cx) * ca + (p[1] - cy) * sa for p in pts]
    vs = [-(p[0] - cx) * sa + (p[1] - cy) * ca for p in pts]
    umin, umax = min(us), max(us)
    span = umax - umin
    front_v = sorted(abs(v) for u, v in zip(us, vs) if u > umax - 0.12 * span)
    back_v = sorted(abs(v) for u, v in zip(us, vs) if u < umin + 0.12 * span)

    def p90(a):
        return a[int(0.9 * (len(a) - 1))]

    # 单峰小|v| = 凸面尖（前）；双峰大|v| = 角尖（后）
    front = +1 if p90(front_v) <= p90(back_v) else -1
    pointing = (math.degrees(ang) + (0 if front > 0 else 180.0)) % 360.0
    flight = (pointing - 90.0) % 360.0                   # 实测口径：弦向 - 90° = 飞行轴
    return flight, pointing


def rotate_by(path, delta):
    """把内容朝向按 delta（顺时针为正）转：PIL 正角约定由 calibrate() 标定后传入正确符号"""
    im = Image.open(path).convert("RGBA")
    out = im.rotate(delta, resample=Image.BICUBIC, expand=False)   # PIL 角（约定待标定）
    out.save(path)


def recentre(path):
    """alpha bbox 居中回画布中心（生成器口径：游戏 pivot = 画布中心）"""
    im = Image.open(path).convert("RGBA")
    bbox = im.getbbox()
    if bbox is None:
        return
    crop = im.crop(bbox)
    cw, ch = crop.size
    if cw > CANVAS or ch > CANVAS:
        raise RuntimeError("bbox larger than canvas: %s %dx%d" % (path, cw, ch))
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.paste(crop, ((CANVAS - cw) // 2, (CANVAS - ch) // 2))
    canvas.save(path)


def calibrate():
    """在临时副本上试转 +10，看 flight 往哪边动 → 返回约定符号 conv（conv=+1: rotate_by(d) 内容 +d）"""
    src = os.path.join(PROJ, "crescent_dir0.png")
    tmp = os.path.join(tempfile.gettempdir(), "_cres_calib.png")
    shutil.copy2(src, tmp)
    f0, _ = measure(tmp)
    rotate_by(tmp, 10.0)
    f1, _ = measure(tmp)
    os.remove(tmp)
    d = shortest(f1, f0)
    if abs(shortest(d, 10.0)) <= 5.0:
        return +1
    if abs(shortest(d, 350.0)) <= 5.0:      # d ≈ -10
        return -1
    raise RuntimeError("calibrate failed: flight moved by %.1f" % d)


def main():
    conv = calibrate()
    print("rotate convention: rotate_by(d) -> content rotation = %.0f*d" % conv)
    ok_all = True
    for k in range(8):
        path = os.path.join(PROJ, "crescent_dir%d.png" % k)
        fl0, _ = measure(path)
        delta = shortest(NOM[k], fl0)                     # 需要的内容旋转（顺时针为正）
        if abs(delta) > 0.5:
            # 需要内容 +delta；rotate_by(d) 实际给 conv*d → d = delta/conv
            rotate_by(path, conv * delta)
            recentre(path)
        fl1, _ = measure(path)
        err = shortest(fl1, NOM[k])
        flag = "OK" if abs(err) <= TOL else "FAIL"
        if flag == "FAIL":
            ok_all = False
        print("dir%d  %-10s  before=%6.1f  delta=%+7.1f  after=%6.1f  nom=%5.1f  err=%+6.1f  %s"
              % (k, FACING[k], fl0, delta, fl1, NOM[k], err, flag))
    print("RESULT:", "ALL OK" if ok_all else "HAS FAILURES")
    return 0 if ok_all else 1


if __name__ == "__main__":
    sys.exit(main())
