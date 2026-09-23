import os, re, struct

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
EXP = os.path.join(M, "exported", "musha")
Z = r"C:\Users\Administrator\AppData\Local\Temp\clothv01"

def png_dim(p):
    d = open(p, 'rb').read(33)
    return struct.unpack(">II", d[16:24])

bx = open(os.path.join(Z, "build.xml"), encoding="utf-8").read()
scml = open(os.path.join(EXP, "musha.scml"), encoding="utf-8").read()

build = {}
for m in re.finditer(r'<Symbol name="([^"]+)">(.*?)</Symbol>', bx, re.S):
    frames = []
    for f in re.finditer(r'<Frame framenum="(\d+)" duration="\d+" image="([^"]+)" w="(\d+)" h="(\d+)" x="([-0-9.eE]+)" y="([-0-9.eE]+)"', m.group(2)):
        frames.append(dict(n=int(f.group(1)), img=f.group(2), w=int(f.group(3)), h=int(f.group(4)),
                           x=float(f.group(5)), y=float(f.group(6))))
    build[m.group(1)] = frames

sfold = {}
for m in re.finditer(r'<folder id="(\d+)" name="([^"]+)">(.*?)</folder>', scml, re.S):
    files = []
    for f in re.finditer(r'<file id="(\d+)" name="([^"]+)" width="(\d+)" height="(\d+)" pivot_x="([-0-9.eE]+)" pivot_y="([-0-9.eE]+)"', m.group(3)):
        files.append(dict(name=f.group(2), w=int(f.group(3)), h=int(f.group(4)),
                          px=float(f.group(5)), py=float(f.group(6))))
    sfold[m.group(2)] = files

print("symbol             帧   dims pivot png  maxXYerr")
diffs = []
for sym, frames in build.items():
    s = sfold.get(sym)
    if s is None:
        print("  !! 缺失", sym); diffs.append(sym); continue
    dim_ok = piv_ok = png_ok = True
    maxerr = 0.0
    for fr, sf in zip(frames, s):
        if (fr['w'], fr['h']) != (sf['w'], sf['h']):
            dim_ok = False
        dx = abs((0.5 - sf['px']) * sf['w'] - fr['x'])
        dy = abs((sf['py'] - 0.5) * sf['h'] - fr['y'])
        maxerr = max(maxerr, dx, dy)
        if dx > 0.02 or dy > 0.02:
            piv_ok = False
        p = os.path.join(Z, fr['img'] + ".png")
        if not os.path.exists(p) or png_dim(p) != (fr['w'], fr['h']):
            png_ok = False
    print(f"{sym:18s} {len(frames):3d}  {int(dim_ok)}    {int(piv_ok)}    {int(png_ok)}   {maxerr:.4f}")
    if not (dim_ok and piv_ok and png_ok):
        diffs.append(sym)
print("\n不一致:", diffs)

print("\n=== 布衣三件套 PNG 尺寸（zip / 项目）===")
for sym in ("skirt", "torso", "torso_pelvis", "arm_upper", "arm_lower"):
    za = sorted(f for f in os.listdir(Z) if f.startswith(sym + "-"))
    a = [png_dim(os.path.join(Z, f)) for f in za]
    bdir = os.path.join(EXP, sym)
    b = [png_dim(os.path.join(bdir, f)) for f in sorted(os.listdir(bdir))]
    flag = "同" if a == b else "**不同**"
    print(f"  {sym:14s} {flag}\n     zip  {a}\n     项目 {b}")
