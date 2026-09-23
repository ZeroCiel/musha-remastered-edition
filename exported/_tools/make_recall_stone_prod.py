#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""回城石 → 生产件（变体1）：分层草稿 → 3 层 + 写 scml（呼吸用"换帧"，可靠）

两条 DST scml.exe 实测规矩（都踩过）：
  1. **folder 名 = build 里的 symbol 名**。三个 folder 必须**名字唯一**；
     同一个 folder 里放多个 file = 同一个 symbol 的**多帧**。
     （第一次我把三张图放进同一个 folder → 编出来只有 1 个 symbol，三张挤成一帧序列。）
  2. scml key 里的 **scale_x / scale_y 会被忽略**（编出来的矩阵全是 1.0）。
     → 呼吸/胀缩改用"**在同一个 symbol 里切帧**"实现：把宝石/光晕按几档缩放**预渲染成多张 png**，
       时间线不同 key 引用不同 file，就是逐帧动画。最稳，也最像原版宝石的做法。

产出（exported/musha_recall_stone/）：
  stone-0.png                       石头本体（1 帧）
  gem-0/1/2.png                     宝石 3 档（小 / 中 / 大）
  glow-0/1/2.png                    光晕 3 档
  musha_recall_stone.scml           bank/build = musha_recall_stone，动画 idle 9 帧 30fps 循环
"""
import math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pnglib import Image, read_png, write_png

MOD = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
SRC = os.path.join(MOD, "exported", "_test_out", "回城石")
OUT = os.path.join(MOD, "exported", "musha_recall_stone")
SW, SH = 60, 80
GX, GY = SW / 2.0, SH * 0.42
NKEY = 9                      # 9 帧；scml.exe 按 25ms(40fps) 网格落帧，所以 key 的 time 也按 25 递增
GEM_SCALES = [1.0, 1.045, 1.09]
GLOW_SCALES = [1.0, 1.06, 1.12]
# 9 个 key 各用哪一档（两次呼吸）
GEM_SEQ = [0, 1, 2, 1, 0, 1, 2, 1, 0]
GLOW_SEQ = [0, 1, 2, 1, 0, 1, 2, 1, 0]


def paste(canvas, img, cx, cy):
    ox, oy = int(round(cx - img.w / 2.0)), int(round(cy - img.h / 2.0))
    for y in range(img.h):
        for x in range(img.w):
            r, g, b, a = img.get(x, y)
            if a == 0:
                continue
            X, Y = ox + x, oy + y
            if 0 <= X < canvas.w and 0 <= Y < canvas.h:
                canvas.put(X, Y, (r, g, b, a))


def scaled_on_canvas(src, k):
    """把 src 放大 k 倍后贴到 60x80 画布上（中心 = 宝石/光晕中心）"""
    cv = Image(SW, SH)
    n = max(1, int(round(src.w * k)))
    m = max(1, int(round(src.h * k)))
    tmp = Image(n, m)
    for y in range(m):
        for x in range(n):
            tmp.put(x, y, src.get(min(src.w - 1, int(x / k)), min(src.h - 1, int(y / k))))
    paste(cv, tmp, GX, GY)
    return cv


def main():
    os.makedirs(OUT, exist_ok=True)
    stone = read_png(os.path.join(SRC, "v1_stone.png"))
    gem = read_png(os.path.join(SRC, "v1_gem.png"))
    glow = read_png(os.path.join(SRC, "v1_glow.png"))
    assert (stone.w, stone.h) == (SW, SH)

    write_png(os.path.join(OUT, "stone-0.png"), stone)
    made = ["stone-0.png"]
    for i, k in enumerate(GEM_SCALES):
        p = os.path.join(OUT, f"gem-{i}.png")
        write_png(p, scaled_on_canvas(gem, k))
        made.append(f"gem-{i}.png")
    for i, k in enumerate(GLOW_SCALES):
        p = os.path.join(OUT, f"glow-{i}.png")
        write_png(p, scaled_on_canvas(glow, k))
        made.append(f"glow-{i}.png")
    print("写出图层:", ", ".join(made))

    def files(fid, folder_name, names):
        s = [f'    <folder id="{fid}" name="{folder_name}">']
        for i, n in enumerate(names):
            s.append(f'        <file id="{i}" name="{n}" width="{SW}" height="{SH}" pivot_x="0.5" pivot_y="0.5"/>')
        s.append('    </folder>')
        return "\n".join(s)

    def tl(tid, name, fid, seq):
        s = [f'            <timeline id="{tid}" name="{name}">']
        for i, fi in enumerate(seq):
            # ★ time= 和 curve_type="instant" 必须有：不给 time 的话 scml.exe 无法把 key 放到时间轴上，
            #   会全部塌到第 0 帧（编出来每个动画帧的元件 frame 都是 0）—— 换帧动画就不生效。
            s.append(f'                <key id="{i}" time="{i * 25}" curve_type="instant" spin="0">')
            s.append(f'                    <object folder="{fid}" file="{fi}" x="0" y="0"/>')
            s.append('                </key>')
        s.append('            </timeline>')
        return "\n".join(s)

    main_keys = []
    for i in range(NKEY):
        refs = "".join(f'<object_ref id="{t}" timeline="{t}" key="{i}" z_index="{z}"/>'
                       for t, z in ((0, 0), (1, 1), (2, 2)))
        main_keys.append(f'                <key id="{i}">{refs}</key>')

    xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="r7">
{files(0, "stone", ["stone-0.png"])}
{files(1, "gem", ["gem-0.png", "gem-1.png", "gem-2.png"])}
{files(2, "glow", ["glow-0.png", "glow-1.png", "glow-2.png"])}
    <entity id="0" name="musha_recall_stone">
        <animation id="0" name="idle" length="{(NKEY - 1) * 25}" interval="25">
            <mainline>
{chr(10).join(main_keys)}
            </mainline>
{tl(0, "stone", 0, [0] * NKEY)}
{tl(1, "gem", 1, GEM_SEQ)}
{tl(2, "glow", 2, GLOW_SEQ)}
        </animation>
    </entity>
</spriter_data>
'''
    sp = os.path.join(OUT, "musha_recall_stone.scml")
    open(sp, "w", encoding="utf-8", newline="\n").write(xml)
    print("写出", sp, len(xml), "B")
    print("宝石切帧:", GEM_SEQ, " 光晕切帧:", GLOW_SEQ)


if __name__ == "__main__":
    main()
