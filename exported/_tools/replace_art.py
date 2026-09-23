# -*- coding: utf-8 -*-
"""把新美术「替换进现有工程」并编译 —— 用**原始 scml 名**（编译出来的 build 名 = 工程名，游戏才找得到）。

    python replace_art.py --src <zip或文件夹> --sym torso [--sym skirt ...] \
        [--proj ../musha] [--out _test_out/replace] [--install] [--dry]

流程：
  1) 从 zip/文件夹里取 <sym>-N.png
  2) 与工程 exported/musha/<sym>/ 里的同名文件比 md5 → 报「哪些真的变了」
  3) 尺寸校验：与 build.xml 声明的 w×h 不一致 → **默认拒绝**（会错位；加 --force 才覆盖）
  4) 备份原图到 exported/_bak_<sym>_<日期>/，再覆盖
  5) 用工程原 scml 编译（scml.exe）→ <out>/anim/<工程名>.zip
  6) --install：把编好的 zip 装到 mods/musha/anim/（先把原 zip 备份成 _bak_<日期>.zip）
"""
import os, re, sys, shutil, zipfile, struct, hashlib, subprocess, datetime

TOOLS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOLS)
from buildxml_to_scml import parse_build

MOD = os.path.normpath(os.path.join(TOOLS, "..", ".."))          # mods/musha
PROJ = os.path.normpath(os.path.join(TOOLS, "..", "musha"))      # exported/musha
SCML = os.path.join(PROJ, "musha.scml")
SCML_EXE = r"D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools\mod_tools\scml.exe"
TODAY = datetime.date.today().strftime("%Y%m%d")


def md5(p):
    return hashlib.md5(open(p, "rb").read()).hexdigest()


def dim(p):
    d = open(p, "rb").read(33)
    return struct.unpack(">II", d[16:24])


def collect_src(src, syms, workdir):
    """返回 {符号: {文件名: 路径}}"""
    out = {s: {} for s in syms}
    if os.path.isdir(src):
        files = []
        for root, _, fs in os.walk(src):
            for f in fs:
                files.append(os.path.join(root, f))
    else:
        os.makedirs(workdir, exist_ok=True)
        z = zipfile.ZipFile(src)
        z.extractall(workdir)
        files = [os.path.join(workdir, n) for n in z.namelist()]
    for p in files:
        b = os.path.basename(p)
        if not b.endswith(".png"):
            continue
        sym = b.rsplit("-", 1)[0]
        if sym in out:
            out[sym][b] = p
    return out


def main():
    args = sys.argv[1:]
    src = args[args.index("--src") + 1]
    syms = [args[i + 1] for i, a in enumerate(args) if a == "--sym"]
    proj = args[args.index("--proj") + 1] if "--proj" in args else PROJ
    outdir = args[args.index("--out") + 1] if "--out" in args else os.path.join(TOOLS, "_test_out", "replace")
    install = "--install" in args
    dry = "--dry" in args
    force = "--force" in args
    scml = args[args.index("--scml") + 1] if "--scml" in args else os.path.join(proj, "musha.scml")
    scml = os.path.abspath(scml)

    # 声明尺寸表：直接从 scml 的 <file> 读（工程目录下不一定有 build.xml）
    declared = {}
    for m in re.finditer(r'<file id="\d+" name="([^/"]+/)?([^/"]+)\.png" width="(\d+)" height="(\d+)"', open(scml, encoding="utf-8").read()):
        declared[m.group(2)] = (int(m.group(3)), int(m.group(4)))
    if not declared:
        raise SystemExit("没能从 scml 读到尺寸表")

    srcdir = os.path.join(TOOLS, "_test_out", "_src_unzip_" + TODAY)
    got = collect_src(src, syms, srcdir)
    print("源:", src)
    print("工程:", proj)
    print("scml:", scml, "（build 名 = %s）" % os.path.basename(scml).rsplit(".", 1)[0])

    todo = []
    for sym in syms:
        names = sorted(got[sym], key=lambda n: int(re.findall(r"-(\d+)\.png$", n)[0]) if re.search(r"-(\d+)\.png$", n) else 0)
        if not names:
            print("  [%s] 源里没有这个符号的图" % sym)
            continue
        changed = same = 0
        for b in names:
            dst = os.path.join(proj, sym, b)
            if not os.path.exists(dst):
                print("  [%s] %s：工程里没有 → 跳过（不是替换，是新增，得先改 scml）" % (sym, b))
                continue
            ok_size = dim(got[sym][b]) == declared.get(b.rsplit(".", 1)[0], (0, 0))[:2]
            is_same = md5(got[sym][b]) == md5(dst)
            if is_same:
                same += 1
            else:
                changed += 1
                if not ok_size and not force:
                    print("  [%s] %s：⚠ 尺寸 %s ≠ 声明 %s → 拒绝（会错位；--force 可强上）"
                          % (sym, b, dim(got[sym][b]), declared.get(b.rsplit(".", 1)[0], (0, 0))[:2]))
                    continue
                todo.append((sym, b, got[sym][b], dst))
        print("  [%s] 源 %d 张：真的变了 %d 张，与工程相同 %d 张" % (sym, len(names), changed, same))

    if not todo:
        print("\n→ 没有需要替换的图（内容与工程完全相同）。工程没动，没编译。")
        return
    print("\n要替换 %d 张：" % len(todo))
    bak = os.path.join(os.path.dirname(proj), "_bak_%s_%s" % ("_".join(syms), TODAY))
    os.makedirs(bak, exist_ok=True)
    for sym, b, srcp, dst in todo:
        os.makedirs(os.path.join(bak, sym), exist_ok=True)
        shutil.copy2(dst, os.path.join(bak, sym, b))
        if dry:
            print("   (dry) %s/%s" % (sym, b))
        else:
            shutil.copy2(srcp, dst)
            print("   %s/%s  ←  %s" % (sym, b, os.path.basename(srcp)))
    if dry:
        print("dry-run，未改动。")
        return
    print("原图备份:", bak)

    # 编译
    os.makedirs(outdir, exist_ok=True)
    print("\n编译:", scml)
    r = subprocess.run([SCML_EXE, scml, outdir], capture_output=True, text=True, errors="replace")
    zips = []
    for root, _, fs in os.walk(outdir):
        zips += [os.path.join(root, f) for f in fs if f.endswith(".zip") and "anim" in root]
    outzip = os.path.join(outdir, "anim", os.path.basename(scml).rsplit(".", 1)[0] + ".zip")
    if not os.path.exists(outzip):
        print("编译失败/找不到产物：", outzip)
        print(r.stdout[-800:], r.stderr[-800:])
        return
    print("产物:", outzip, os.path.getsize(outzip), "字节")
    if install:
        dst = os.path.join(MOD, "anim", os.path.basename(outzip))
        bak2 = dst.replace(".zip", "_bak_%s.zip" % TODAY)
        if os.path.exists(dst) and not os.path.exists(bak2):
            shutil.copy2(dst, bak2)
            print("原 zip 备份:", bak2)
        shutil.copy2(outzip, dst)
        print("已装到:", dst)
        print("（游戏里换 build 生效：热更新要重新勾 mod）")
    else:
        print("（没装到 anim/：要装加 --install）")


if __name__ == "__main__":
    main()
