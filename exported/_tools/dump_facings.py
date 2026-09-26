# -*- coding: utf-8 -*-
"""按朝向逐面渲染（dump_anim_frames.py 的伴生补充，不改原脚本）。

为什么要这个：官方名包（如 crescent_cyan8）里 8 个动画的裸名都是 "slash"，
朝向只存在 facing 字节里 —— dump_anim_frames render 按名字匹配只取第一面，
既报错"没有 slash_left"、也无法点名第 N 面（2026-09-26 实测）。
本脚本把同名的每一面分别渲到 f0/f1/.../fN 子目录，并打印 facing 字节供对照。

用法:
    python dump_facings.py <zip> <动画名> <出参目录> [--scale N] [--sheet]

输出:
    <出参目录>/f0/…fN/  逐帧 PNG + 每面一张 _<名>_总览.png（--sheet 时）
    控制台逐面打印: 序号 / facing 字节 / 帧数 / fps
朝向含义以图像实际内容为准（f 序号 = anim.bin 条目顺序，与 scml 顺序逐条核对过）。
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dump_anim_frames as d


def main():
    args = sys.argv[1:]
    if len(args) < 3:
        print(__doc__)
        return 1
    scale, sheet = 1, False
    if "--scale" in args:
        i = args.index("--scale")
        scale = int(args[i + 1])
        del args[i:i + 2]
    if "--sheet" in args:
        sheet = True
        args.remove("--sheet")
    zpath, name, outdir = args[0], args[1], args[2]

    orig = d.parse_anim

    def parse_one(path, keep):
        r = orig(path)
        if keep >= len(r["anims"]):
            raise SystemExit("面序号 %d 越界（共 %d）" % (keep, len(r["anims"])))
        r["anims"] = [r["anims"][keep]]
        return r

    all_anims = orig(zpath)["anims"]
    # ★ 同一 build 的图集每面重复解码是超时主因（2026-09-26 实测 ~130s/面、8 面要 17 分钟）→ 跨面缓存只解一次
    orig_decode = d.decode_atlas
    dec_cache = {}

    def cached_decode(zp, nm, od):
        k = (zp, nm)
        if k not in dec_cache:
            dec_cache[k] = orig_decode(zp, nm, od)
        return dec_cache[k]

    d.decode_atlas = cached_decode
    print("同名 %r 共 %d 面" % (name, len(all_anims)))
    for idx, a in enumerate(all_anims):
        face_dir = os.path.join(outdir, "f%d" % idx)
        # 断点续渲：_总览.png 是最后一步才写的，它在 = 这面已完成（2026-09-26 超时/断电实测）
        if sheet and os.path.exists(os.path.join(face_dir, "_%s_总览.png" % name)):
            print("f%d 已完成，跳过" % idx)
            continue
        print("f%d  facing=%s  %d 帧  %.1f fps" % (idx, a["facing"], len(a["frames"]), a["rate"]))
        d.parse_anim = lambda p, keep=idx: parse_one(p, keep)
        d.render_frames(zpath, zpath, name, face_dir, scale, sheet, False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
