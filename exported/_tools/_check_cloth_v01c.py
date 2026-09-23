import os, re, struct, zipfile, zlib

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
EXP = os.path.join(M, "exported", "musha")
Z = r"C:\Users\Administrator\AppData\Local\Temp\clothv01"

def png_info(path):
    d = open(path, 'rb').read()
    w, h = struct.unpack(">II", d[16:24])
    # 解 alpha 覆盖
    pos = 8; idat = b""; ct = None; bd = None
    while pos < len(d):
        ln = struct.unpack(">I", d[pos:pos+4])[0]; typ = d[pos+4:pos+8]
        ch = d[pos+8:pos+8+ln]; pos += 12+ln
        if typ == b"IHDR": w,h,bd,ct = struct.unpack(">IIBB", ch[:10])
        elif typ == b"IDAT": idat += ch
        elif typ == b"IEND": break
    raw = zlib.decompress(idat)
    nch = {0:1,2:3,3:1,4:2,6:4}[ct]
    stride = w*nch if bd == 8 else (w*nch*2 if bd == 16 else (w*bd+7)//8)
    # 只统计 non-zero 字节占比（近似“有没有内容”）
    nz = sum(1 for y in range(h) for x in range(stride) if raw[y*(stride+1)+1+x])
    return w, h, len(d), nz, stride*h

print("=== anim/musha.zip (生产包) 里的符号尺寸 ===")
p = os.path.join(M, "anim", "musha.zip")
print("  ", p, os.path.getsize(p), os.path.getmtime(p))
z = zipfile.ZipFile(p)
names = z.namelist()
print("  内容:", [n for n in names if not n.lower().endswith('.png')][:10], " png数:", len([n for n in names if n.lower().endswith('.png')]))
if "build.xml" in names:
    bx = z.read("build.xml").decode("utf-8", "replace")
    for m in re.finditer(r'<Symbol name="([^"]+)">(.*?)</Symbol>', bx, re.S):
        fr = re.findall(r'w="(\d+)" h="(\d+)"', m.group(2))
        print(f"  {m.group(1):16s} {len(fr)} 帧  尺寸样本 {fr[:3]}")

print("\n=== 关键文件尺寸/内容量对比 ===")
tests = [
    ("zip   skirt-0", os.path.join(Z, "skirt-0.png")),
    ("proj  skirt-0", os.path.join(EXP, "skirt", "skirt-0.png")),
    ("zip   skirt-4", os.path.join(Z, "skirt-4.png")),
    ("zip   tail-0",  os.path.join(Z, "tail-0.png")),
    ("proj  tail-0",  os.path.join(EXP, "tail", "tail-0.png")),
    ("zip   torso-8", os.path.join(Z, "torso-8.png")),
    ("proj  torso-8", os.path.join(EXP, "torso", "torso-8.png")),
    ("zip   headbase-0", os.path.join(Z, "headbase-0.png")),
    ("proj  headbase-0", os.path.join(EXP, "headbase", "headbase-0.png")),
    ("zip   face-0", os.path.join(Z, "face-0.png")),
    ("proj  face-0", os.path.join(EXP, "face", "face-0.png")),
    ("zip   hairfront-0", os.path.join(Z, "hairfront-0.png")),
    ("proj  hairfront-0", os.path.join(EXP, "hairfront", "hairfront-0.png")),
]
for label, p in tests:
    if os.path.exists(p):
        w, h, size, nz, tot = png_info(p)
        print(f"  {label:18s} {w}x{h}  {size}B  非零字节 {nz}/{tot} ({100.0*nz/tot:.1f}%)")
    else:
        print(f"  {label:18s} 缺失")
