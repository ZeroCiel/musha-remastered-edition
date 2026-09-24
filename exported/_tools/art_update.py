# -*- coding: utf-8 -*-
"""
musha art update interface - agent-facing texture update tool.

Regenerate Klei .tex/.xml atlases from PNG sources, publish art into the
mod's images/ folder, and report which atlases are stale.

Usage:
  python art_update.py status
      List images/*.png that are missing .tex or newer than their .tex.

  python art_update.py convert <png> [--out <file.tex>]
      Convert one PNG to .tex/.xml next to it (no copy, no overwrite of
      existing game art).

  python art_update.py publish <png> <image-name>
      Copy <png> into images/<image-name>.png (backing up whatever was
      there to exported/_tools/_art_backup/), then convert to .tex/.xml.

  Options:
      --png-exe PATH   Override converter path (default below, or env
                       MUSHA_PNG_EXE).

Rules:
  - Preview art with the user BEFORE publish (overwrite is one-way for
    the game until re-convert).
  - After any tex/xml change: FULL restart of DST to see it in game.
  - Console messages are English on purpose (GBK console mangles UTF-8
    Chinese); docs are in README_ART.md (same folder).

Exit codes: 0 ok, 1 usage, 2 tool missing, 3 convert failed, 4 bad input.
"""
import os
import sys
import shutil
import subprocess
import time

HERE = os.path.dirname(os.path.abspath(__file__))            # exported\_tools
MOD_ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))   # musha\
IMAGES = os.path.join(MOD_ROOT, "images")
BACKUP_DIR = os.path.join(HERE, "_art_backup")

DEFAULT_PNG_EXE = os.path.join(
    r"D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools\mod_tools",
    "png.exe")

CREATE_NO_WINDOW = 0x08000000 if os.name == "nt" else 0


def find_png_exe(override=None):
    cand = override or os.environ.get("MUSHA_PNG_EXE") or DEFAULT_PNG_EXE
    if os.path.isfile(cand):
        return cand
    return None


def run_convert(png_exe, src_png, out_tex):
    """src_png -> out_tex (+ sibling .xml). Returns (ok, message)."""
    src_png = os.path.abspath(src_png)
    out_tex = os.path.abspath(out_tex)
    out_dir = os.path.dirname(out_tex)
    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)
    # remove stale outputs so we can prove conversion really happened
    out_xml = os.path.splitext(out_tex)[0] + ".xml"
    for p in (out_tex, out_xml):
        if os.path.exists(p):
            os.remove(p)
    try:
        r = subprocess.run(
            [png_exe, src_png, out_tex],
            cwd=out_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            creationflags=CREATE_NO_WINDOW,
        )
    except OSError as e:
        return False, "failed to launch png.exe: %s" % e
    log = r.stdout.decode("gbk", "replace").strip()
    if r.returncode != 0:
        return False, "png.exe exit=%d: %s" % (r.returncode, log[-400:])
    if not (os.path.isfile(out_tex) and os.path.isfile(out_xml)):
        return False, "outputs missing after convert: %s" % log[-400:]
    if os.path.getsize(out_tex) == 0:
        return False, "converted tex is empty"
    return True, "tex=%d bytes, xml=%d bytes" % (
        os.path.getsize(out_tex), os.path.getsize(out_xml))


def backup_existing(name):
    """Copy images/<name>.{png,tex,xml} into _art_backup/<name>_<ts>/."""
    stamp = time.strftime("%Y%m%d_%H%M%S")
    bdir = os.path.join(BACKUP_DIR, "%s_%s" % (name, stamp))
    moved = []
    for ext in (".png", ".tex", ".xml"):
        src = os.path.join(IMAGES, name + ext)
        if os.path.isfile(src):
            if not os.path.isdir(bdir):
                os.makedirs(bdir)
            shutil.copy2(src, os.path.join(bdir, name + ext))
            moved.append(ext)
    return (bdir if moved else None)


def cmd_status():
    if not os.path.isdir(IMAGES):
        print("ERROR: images dir not found: %s" % IMAGES)
        return 3
    stale, missing, ok_n = [], [], 0
    for fn in sorted(os.listdir(IMAGES)):
        if not fn.lower().endswith(".png"):
            continue
        base = fn[:-4]
        png = os.path.join(IMAGES, fn)
        tex = os.path.join(IMAGES, base + ".tex")
        if not os.path.isfile(tex):
            missing.append(fn)
        elif os.path.getmtime(png) > os.path.getmtime(tex):
            stale.append(fn)
        else:
            ok_n += 1
    print("images/ atlases: %d up-to-date, %d STALE, %d MISSING tex"
          % (ok_n, len(stale), len(missing)))
    for fn in stale:
        print("  STALE   %s  (png newer than tex -> run publish)" % fn)
    for fn in missing:
        print("  MISSING %s  (no .tex -> run publish)" % fn)
    return 0


def cmd_convert(argv):
    if len(argv) < 1:
        print("convert needs a png path")
        return 1
    src = argv[0]
    if not os.path.isfile(src):
        print("ERROR: not a file: %s" % src)
        return 4
    out_tex = None
    if "--out" in argv:
        i = argv.index("--out")
        if i + 1 >= len(argv):
            print("--out needs a value")
            return 1
        out_tex = argv[i + 1]
    if out_tex is None:
        out_tex = os.path.splitext(src)[0] + ".tex"
    png_exe = find_png_exe(_opt(argv, "--png-exe"))
    if not png_exe:
        print("ERROR: png.exe not found (use --png-exe or MUSHA_PNG_EXE)")
        return 2
    ok, msg = run_convert(png_exe, src, out_tex)
    print(("OK   " if ok else "FAIL ") + out_tex + " : " + msg)
    return 0 if ok else 3


def cmd_publish(argv):
    if len(argv) < 2:
        print("publish needs: <png> <image-name>")
        return 1
    src = argv[0]
    name = os.path.splitext(os.path.basename(argv[1]))[0]
    if not os.path.isfile(src):
        print("ERROR: not a file: %s" % src)
        return 4
    if not os.path.isdir(IMAGES):
        print("ERROR: images dir not found: %s" % IMAGES)
        return 3
    png_exe = find_png_exe(_opt(argv, "--png-exe"))
    if not png_exe:
        print("ERROR: png.exe not found (use --png-exe or MUSHA_PNG_EXE)")
        return 2
    src_abs = os.path.abspath(src)
    dst_png = os.path.join(IMAGES, name + ".png")
    same = os.path.normcase(src_abs) == os.path.normcase(dst_png)
    bdir = None
    if os.path.isfile(dst_png) and not same:
        bdir = backup_existing(name)
        print("backed up old atlas -> %s" % (bdir or "(none)"))
    if not same:
        shutil.copy2(src_abs, dst_png)
        print("copied %s -> %s" % (src_abs, dst_png))
    ok, msg = run_convert(png_exe, dst_png, os.path.join(IMAGES, name + ".tex"))
    print(("OK   " if ok else "FAIL ") + name + " : " + msg)
    if ok:
        print("done. FULL restart DST to see the change in game.")
    return 0 if ok else 3


def _opt(argv, key):
    if key in argv:
        i = argv.index(key)
        if i + 1 < len(argv):
            return argv[i + 1]
    return None


def main(argv):
    if len(argv) == 0 or argv[0] in ("-h", "--help", "help"):
        print(__doc__)
        return 0
    cmd, rest = argv[0], argv[1:]
    # strip options from positionals for convert/publish
    if cmd == "status":
        return cmd_status()
    if cmd == "convert":
        pos, skip = [], False
        for a in rest:
            if skip:
                skip = False
                continue
            if a in ("--out", "--png-exe"):
                skip = True
                continue
            if a.startswith("--"):
                continue
            pos.append(a)
        return cmd_convert(pos)
    if cmd == "publish":
        pos = []
        skip = False
        for a in rest:
            if skip:
                skip = False
                continue
            if a in ("--png-exe",):
                skip = True
                continue
            if a.startswith("--"):
                continue
            pos.append(a)
        return cmd_publish(pos)
    print("unknown command: %s (try: status | convert | publish)" % cmd)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
