import os, re, struct

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
EXP = os.path.join(M, "exported", "musha")
Z = r"C:\Users\Administrator\AppData\Local\Temp\clothv01"

def png_dim(p):
    d = open(p, 'rb').read(33)
    return struct.unpack(">II", d[16:24])

bx = open(os.path.join(Z, "build.xml"), encoding="utf-8").read()

def scan(root, bxpath):
    build = {}
    for m in re.finditer(r'<Symbol name="([^"]+)">(.*?)</Symbol>', open(bxpath, encoding="utf-8").read(), re.S):
        frames = []
        for f in re.finditer(r'<Frame framenum="(\d+)" duration="\d+" image="([^"]+)" w="(\d+)" h="(\d+)" x="([-0-9.eE]+)" y="([-0-9.eE]+)"', m.group(2)):
            frames.append((int(f.group(1)), f.group(2), int(f.group(3)), int(f.group(4))))
        build[m.group(1)] = frames
    return build

print("=== zip 内：build.xml 声明尺寸 vs PNG 实际尺寸（只列不一致）===")
build = scan(Z, os.path.join(Z, "build.xml"))
for sym, frames in build.items():
    for n, img, w, h in frames:
        p = os.path.join(Z, img + ".png")
        if not os.path.exists(p):
            print(f"  {img}: 文件缺失")
        else:
            aw, ah = png_dim(p)
            if (aw, ah) != (w, h):
                print(f"  {sym:16s} {img:20s} 声明 {w}x{h}  实际 {aw}x{ah}")

print("\n=== 项目 exported/musha：同名 PNG 实际尺寸（只列与 zip 不同的）===")
for sym in sorted(os.listdir(EXP)):
    d = os.path.join(EXP, sym)
    if not os.path.isdir(d):
        continue
    for f in sorted(os.listdir(d)):
        if not f.endswith(".png"):
            continue
        a = os.path.join(Z, f)
        b = os.path.join(d, f)
        if os.path.exists(a) and png_dim(a) != png_dim(b):
            print(f"  {sym:16s} {f:20s} zip {png_dim(a)}  项目 {png_dim(b)}")
