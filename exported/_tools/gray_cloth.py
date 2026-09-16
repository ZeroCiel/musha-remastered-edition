"""把 musha 角色 build 的「衣服/护甲」部件去色成灰色布衣。

原理：DST 角色 build 里 torso / torso_pelvis / arm_upper / arm_lower / arm_upper_skin
     就是角色默认穿在身上的那套衣服（护甲是另一份 swap_body 素材，不受影响）。
     本脚本只改这些 PNG 的颜色，不动 alpha、不动几何、不动文件名 → 不用改一行代码。

用法：
    python gray_cloth.py            # 干跑：只出预览图，不覆盖
    python gray_cloth.py --apply    # 备份原图 → 就地覆盖成灰布
    python gray_cloth.py --revert   # 从备份还原

调参（想更亮/更暗只改这几个数，重跑 --apply 即可）：
    BLACK_CUT  亮度低于此值当线稿，原样保留（保住描边）
    LIFT/TOP   其余像素的灰阶映射区间（LIFT 越小越黑、TOP 越大越亮）
"""
import os, sys, shutil, time, zipfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import read_png, write_png, Image

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.normpath(os.path.join(HERE, "..", "musha"))          # exported/musha
BAK = os.path.normpath(os.path.join(HERE, "..", "_bak_musha_outfit"))  # exported/_bak_musha_outfit

PARTS = ["torso", "torso_pelvis", "arm_upper", "arm_lower", "arm_upper_skin"]
BLACK_CUT = 26
LIFT = 55    # 灰布最暗处的灰阶（越大越亮）
TOP = 210    # 最亮处（金饰/高光）的灰阶
TINT = (1.00, 0.99, 0.965)   # 极轻微暖灰，避免纯中性灰发死

# 不想被去色的部件（比如裸皮肤/手/腿脚）写这里
SKIP = os.environ.get("GRAY_SKIP", "")


def luma(r, g, b):
    return 0.299 * r + 0.587 * g + 0.114 * b


def gray_pixel(r, g, b):
    L = luma(r, g, b)
    if L < BLACK_CUT:
        v = L                                    # 线稿：只去色、不改亮度（保住描边/阴影线）
    else:
        t = (L - BLACK_CUT) / (255.0 - BLACK_CUT)
        v = LIFT + t * (TOP - LIFT)
    return tuple(min(255, max(0, int(round(v * c)))) for c in TINT)


def process(path):
    im = read_png(path)
    px = im.px
    for i in range(0, len(px), 4):
        if px[i+3] == 0:
            continue
        r, g, b = gray_pixel(px[i], px[i+1], px[i+2])
        px[i], px[i+1], px[i+2] = r, g, b
    return im


def files_of(part):
    d = os.path.join(PROJ, part)
    return [os.path.join(d, f) for f in sorted(os.listdir(d), key=lambda f: int(f.rsplit("-", 1)[1].split(".")[0]))
            if f.endswith(".png")]


def rebuild_project_zip():
    """把 exported/musha/musha.zip（Mod Tool 的项目包）里的 PNG 同步成新贴图。
    注意：项目 zip 里的 PNG 名是**平铺**的（torso-0.png），磁盘上在子目录里（torso/torso-0.png）。"""
    out = os.path.join(PROJ, "musha.zip")
    if not os.path.exists(out):
        return None
    index = {}
    for root, _, fs in os.walk(PROJ):
        for f in fs:
            if f.lower().endswith(".png"):
                index[f] = os.path.join(root, f)
    n = 0
    tmp = out + ".tmp"
    with zipfile.ZipFile(out) as zin, zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
        for it in zin.infolist():
            name = it.filename
            base = os.path.basename(name)
            if name.lower().endswith(".png") and base in index:
                zout.write(index[base], name)
                n += 1
            else:
                zout.writestr(it, zin.read(name))
    os.replace(tmp, out)
    return out, n


def main():
    apply_ = "--apply" in sys.argv
    revert = "--revert" in sys.argv

    if "--zip-only" in sys.argv:      # 只重同步项目 zip，不碰 PNG（幂等，安全）
        print("项目包已同步：", rebuild_project_zip()); return

    if revert:
        if not os.path.isdir(BAK):
            print("没有备份目录：", BAK); return
        n = 0
        for part in os.listdir(BAK):
            src = os.path.join(BAK, part)
            dst = os.path.join(PROJ, part)
            if os.path.isdir(src):
                shutil.rmtree(dst, ignore_errors=True)
                shutil.copytree(src, dst)
                n += len(os.listdir(dst))
        rebuild_project_zip()
        print("已还原 %d 个 PNG（并同步回项目 zip）" % n)
        return

    parts = [p for p in PARTS if p != SKIP]
    total = 0
    outdir = os.path.join(HERE, "_test_out", "gray")
    os.makedirs(outdir, exist_ok=True)

    if apply_ and not os.path.isdir(BAK):
        os.makedirs(BAK)
        for part in parts:
            shutil.copytree(os.path.join(PROJ, part), os.path.join(BAK, part))
        print("原图已备份到：", BAK)

    for part in parts:
        for p in files_of(part):
            im = process(p)
            total += 1
            if apply_:
                write_png(p, im)
            else:
                write_png(os.path.join(outdir, os.path.basename(p)), im)
        print("  %-16s %d 张%s" % (part, len(files_of(part)), " → 已覆盖" if apply_ else " → 预览"))

    if apply_:
        z = rebuild_project_zip()
        print("项目包已同步：", z)
    print(("已改 %d 张 PNG。这是【真改】。" if apply_ else "干跑完成（未覆盖）：%d 张预览在 ") % total, "" if apply_ else outdir)
    if apply_:
        print("下一步：DST Mod Tool → 打开 %s → 编译/导出 → 覆盖 anim/musha.zip" % os.path.join(PROJ, "musha.scml"))
        print("想还原：python gray_cloth.py --revert")


main()
