#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""encode_anim_gif.py — 动画 zip → 演示 GIF（零额外依赖，PIL 原生）

用法：
  python encode_anim_gif.py <anim.zip> [动画名] [--scale 2] [--fps 40] [--out 出.gif] [--bg R,G,B]
  动画名缺省 = 包里第一个；fps 缺省 = 动画自带帧率
输出：GIF（循环播放）。MP4 版本要 imageio-ffmpeg（pip 装后可加）。
"""
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sp_model_tool as S


def main():
    rest = sys.argv[1:]
    if not rest:
        print(__doc__); return 1
    src = None
    anim_name = None
    scale = 2.0
    fps = None
    out = None
    bg = (110, 150, 110, 255)
    i = 0
    while i < len(rest):
        a = rest[i]
        if a == "--anim":
            anim_name = rest[i + 1]; i += 2
        elif a == "--scale":
            scale = float(rest[i + 1]); i += 2
        elif a == "--fps":
            fps = float(rest[i + 1]); i += 2
        elif a == "--out":
            out = rest[i + 1]; i += 2
        elif a == "--bg":
            try:
                parts = [int(v) for v in rest[i + 1].split(",")]
                bg = tuple(parts + [255] * (4 - len(parts)))
            except Exception: pass
            i += 2
        else:
            src = a; i += 1
    if src is None:
        print(__doc__); return 1
    zpath = os.path.abspath(src)
    anims = [x for x in S.parse_anim(zpath)["anims"] if anim_name is None or x["name"] == anim_name]
    if not anims:
        raise SystemExit("没有匹配的动画")
    fps = fps or (anims[0]["rate"] or 40)
    dur = max(20, int(round(1000 / max(1, fps))))
    n = sum(len(x["frames"]) for x in anims)
    frames = []
    for x in anims:
        zs = S.ZipSource(zpath, anim_name=x["name"], scale=scale)
        for fr in zs.frames:
            cv = Image.new("RGBA", fr.size, bg)
            cv.alpha_composite(fr)
            frames.append(cv.convert("P", palette=Image.ADAPTIVE, colors=255))
    if out is None:
        out = os.path.join(HERE, "_test_out", "anim_gif", "%s_%s.gif" % (os.path.splitext(os.path.basename(zpath))[0], anims[0]["name"]))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=dur, loop=0, disposal=2, optimize=False)
    sz = os.path.getsize(out)
    print("GIF：%s  %d 帧 @%dfps  %dx%d  %.2f MB" % (out, n, fps, frames[0].width, frames[0].height, sz / 1048576.0))
    return 0


if __name__ == "__main__":
    sys.exit(main())
