# -*- coding: utf-8 -*-
"""DST 编译好的 anim 包 → 逐帧 PNG（纯标准库，不需要 ktech/krane/Pillow）

为什么要这个：原版角色的"站立/待机"动画是编译过的（anim.bin + build.bin + atlas-0.tex），
想看/想当参考就得自己解。本脚本一次解两包：
    build 包  = <build>.zip         （build.bin + atlas-0.tex）← 有图
    anim  包  = <anim>.zip          （只有 anim.bin）        ← 有时间轴
（例：build = data/anim/wilson.zip，anim = data/anim/player_idles_wilson.zip）

用法:
    python dump_anim_frames.py list   <anim.zip> [更多 anim.zip...]
    python dump_anim_frames.py render <build.zip> <anim.zip> <动画名> <出参目录> [--scale 2] [--sheet]

格式依据（见 skill dst-art-pipeline/references/build-compile-and-anim-decode.md）：
  build.bin (BILD v6): 符号数 / 帧总数 / build名 / 图集名 / 每符号(名字hash,帧数)
       每帧: u32 framenum, u32 duration, ffff x,y,w,h, u32 alpha起点, u32 顶点数
       全局顶点表: 每顶点 6 个 float (x,y,z,u,v,sampler)
       末尾: hash→名字表
  anim.bin (ANIM v4): 每动画(名字, 朝向, root hash, 帧率, 帧数)
       每帧: ffff rootX,rootY,rootW,rootH, u32 事件数(每条 u32 hash + u32 frame), u32 元素数
       每元素: u32 符号hash, u32 build内帧号, u32 图层hash, 7 个 float (a,b,c,d,tx,ty,z)
  · 元件落点 = anim 的 tx/ty + build 帧的 x/y（x,y 是元件中心）
  · z 越大越靠前
  ★ 2026-09-20 实测两条（都踩过）：
    ① **v 不用翻转**：tex2png 解出来的图集（自上而下）跟 build.bin 顶点里的 u/v 是同一套朝向。
       翻了反而全错（实测 headbase/hair/foot 的不透明率从 61%/58%/27% 掉到 0%）。
    ② **anim 的 y 是朝下的**（= scml 里 object y 取反），渲染时要按"y 越大越靠下"排；
       按 y 朝上再翻一次 → 人会上下颠倒 + 部件散架。
"""
import os
import struct
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
try:
    from pnglib import Image, write_png, blit
except Exception:                                            # 兜底：自己内联一份最小写入
    write_png = None

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL_TEX2PNG = r"C:\Users\Administrator\AppData\Local\hermes\skills\gaming\dst-art-pipeline\scripts"


# ---------------------------------------------------------------- 基础读取
class R:
    def __init__(self, b):
        self.b, self.p = b, 0

    def u32(self):
        v = struct.unpack_from("<I", self.b, self.p)[0]; self.p += 4; return v

    def i32(self):
        v = struct.unpack_from("<i", self.b, self.p)[0]; self.p += 4; return v

    def u8(self):
        v = self.b[self.p]; self.p += 1; return v

    def f32(self):
        v = struct.unpack_from("<f", self.b, self.p)[0]; self.p += 4; return v

    def s(self):
        n = self.i32()
        v = self.b[self.p:self.p + n].decode("utf-8", "replace"); self.p += n
        return v

    def f4(self):
        return [self.f32() for _ in range(4)]


def parse_names(r):
    """末尾的 hash→名字表：u32 条数 + 每条(u32 hash, i32 len, bytes)"""
    n = r.u32()
    out = {}
    for _ in range(n):
        h = r.u32()
        out[h] = r.s()
    return out


def parse_build(path):
    z = zipfile.ZipFile(path)
    r = R(z.read("build.bin"))
    assert r.b[:4] == b"BILD", "不是 build.bin"
    r.p = 4
    ver = r.i32()
    nsym = r.u32()
    total_frames = r.u32()
    build_name = r.s()
    natlas = r.u32()
    atlas_names = [r.s() for _ in range(natlas)]

    syms = []
    for _ in range(nsym):
        h = r.u32()
        nf = r.u32()
        frames = []
        for _ in range(nf):
            fnum = r.u32(); dur = r.u32()
            x, y, w, hh = r.f4()
            astart = r.u32(); nverts = r.u32()
            frames.append(dict(num=fnum, dur=dur, x=x, y=y, w=w, h=hh,
                               astart=astart, nverts=nverts))
        syms.append(dict(hash=h, frames=frames))

    nv = r.u32()
    verts = []
    for _ in range(nv):
        verts.append([r.f32() for _ in range(6)])         # x,y,z,u,v,sampler
    names = parse_names(r)

    for s in syms:
        s["name"] = names.get(s["hash"], "hash_%d" % s["hash"])
        for f in s["frames"]:
            us = [verts[i][3] for i in range(f["astart"], f["astart"] + f["nverts"])]
            vs = [verts[i][4] for i in range(f["astart"], f["astart"] + f["nverts"])]
            if us:
                f["uv"] = (min(us), min(vs), max(us), max(vs))
            else:
                f["uv"] = None
    return dict(name=build_name, atlases=atlas_names, syms=syms,
                sym_by_hash={s["hash"]: s for s in syms}, ver=ver,
                total_frames=total_frames)


def parse_anim(path):
    z = zipfile.ZipFile(path)
    d = z.read("anim.bin")
    r = R(d)
    assert d[:4] == b"ANIM", "不是 anim.bin"
    r.p = 4
    ver = r.i32()
    nelem = r.u32(); nframes_total = r.u32(); nev = r.u32(); nanim = r.u32()
    anims = []
    for _ in range(nanim):
        name = r.s()
        facing = r.u8()
        root = r.u32()
        rate = r.f32()
        nf = r.u32()
        frames = []
        for _ in range(nf):
            rootrect = r.f4()
            nev_f = r.u32()
            evs = [(r.u32(), r.u32()) for _ in range(nev_f)]
            ne = r.u32()
            elems = []
            for _ in range(ne):
                sh = r.u32(); fi = r.u32(); lh = r.u32()
                m = [r.f32() for _ in range(7)]
                elems.append(dict(sym=sh, frame=fi, layer=lh, m=m))
            frames.append(dict(root=rootrect, events=evs, elems=elems))
        anims.append(dict(name=name, facing=facing, root=root, rate=rate, frames=frames))
    # 尾部名字表：元素符号名 + **图层名**（图层名才是"这层默认隐不隐藏"的依据）
    names = {}
    try:
        names = parse_names(r)
    except Exception:
        names = {}
    return dict(ver=ver, elems=nelem, frames=nframes_total, events=nev,
                anims=anims, names=names)


# 游戏里**默认隐藏**的图层（DST 用 AnimState:Hide("ARM_carry") 这类调用控制）。
# 不滤掉的话，渲染出来会多出一条"抱东西的胳膊"（飘在身体右边）。
HIDE_DEFAULT = {
    "arm_carry",          # 抱着/举着东西的胳膊（idle 时隐藏）
    "lantern_overlay",    # 提灯的光晕
    "swap_face", "beard", # 换脸/胡子（无胡子时隐藏）
    "hat", "head_hat", "hair_hat",   # 帽子 + 戴帽子用的头/发型
    "swap_body", "swap_body_tall",   # 皮肤身体替换
}


def layer_hidden(name, hide_set):
    if not name:
        return False
    n = name.strip().lower()
    if n in hide_set:
        return True
    # 宽松匹配：交换/携带/覆盖类一律默认不画
    return ("swap" in n) or ("carry" in n) or ("overlay" in n)


# ---------------------------------------------------------------- 图集解码
def decode_atlas(zip_path, atlas_name="atlas-0.tex", tmpdir=None):
    """返回 (w, h, rgba bytes, 从上到下)"""
    sys.path.insert(0, SKILL_TEX2PNG)
    import tex2png
    tmpdir = tmpdir or os.path.join(HERE, "_tmp")
    os.makedirs(tmpdir, exist_ok=True)
    out = os.path.join(tmpdir, os.path.basename(atlas_name))
    with open(out, "wb") as f:
        f.write(zipfile.ZipFile(zip_path).read(atlas_name))
    b, w, h = tex2png.tex_info(out)
    cands = tex2png._guess_format(len(b), w, h)
    if not cands:
        raise RuntimeError("认不出图集压缩格式: " + out)
    cands.sort(key=lambda c: (c[1] != "dxt5", -c[0]))
    count, kind, entry, hdrlen = cands[0]
    sizes = tex2png._mip_sizes(w, h, count, kind)
    data = b[hdrlen:hdrlen + sizes[0]]
    dec = {"dxt5": tex2png.decode_dxt5, "dxt3": tex2png.decode_dxt3,
           "dxt1": tex2png.decode_dxt1}.get(kind)
    if dec:
        rgba = dec(data, w, h, False)
    elif kind == "rgba":
        rgba = tex2png.decode_raw(data, w, h, 4, False)
    else:
        rgba = tex2png.decode_raw(data, w, h, 3, False)
    return w, h, rgba


# ---------------------------------------------------------------- 渲染
def sample_atlas(aw, ah, rgba, rect, w, h):
    """把图集 rect（归一化 u0,v0,u1,v1，v 已翻转）取成 w×h 的 RGBA 区块"""
    u0, v0, u1, v1 = rect
    out = bytearray(w * h * 4)
    for y in range(h):
        fy = v0 + (v1 - v0) * ((y + 0.5) / h)
        sy = min(ah - 1, max(0, int(fy * ah)))
        for x in range(w):
            fx = u0 + (u1 - u0) * ((x + 0.5) / w)
            sx = min(aw - 1, max(0, int(fx * aw)))
            i = (sy * aw + sx) * 4
            o = (y * w + x) * 4
            out[o:o + 4] = rgba[i:i + 4]
    return out


def blit_rgba(canvas, cw, ch, src, sw, sh, dx, dy):
    """把 src(sw×sh) 贴到 canvas 的 (dx,dy)（左上角），alpha 混合"""
    for y in range(sh):
        ty = dy + y
        if ty < 0 or ty >= ch:
            continue
        row = ty * cw * 4
        srow = y * sw * 4
        for x in range(sw):
            tx = dx + x
            if tx < 0 or tx >= cw:
                continue
            i = srow + x * 4
            a = src[i + 3]
            if a == 0:
                continue
            j = row + tx * 4
            if a == 255:
                canvas[j:j + 4] = src[i:i + 4]
            else:
                ia = 255 - a
                canvas[j] = (src[i] * a + canvas[j] * ia) // 255
                canvas[j + 1] = (src[i + 1] * a + canvas[j + 1] * ia) // 255
                canvas[j + 2] = (src[i + 2] * a + canvas[j + 2] * ia) // 255
                canvas[j + 3] = max(canvas[j + 3], a)


def render_frames(build_zip, anim_zip, anim_name, outdir, scale=1, sheet=False, show_all=False):
    b = parse_build(build_zip)
    a = parse_anim(anim_zip)
    anim = None
    for x in a["anims"]:
        if x["name"] == anim_name:
            anim = x
            break
    if anim is None:
        near = [x["name"] for x in a["anims"]]
        raise SystemExit("anim 包里没有动画 %r；可选：%s" % (anim_name, ", ".join(near)))

    aw, ah, rgba = decode_atlas(build_zip, b["atlases"][0], outdir)
    print("图集 %dx%d   build=%s   动画 %s（%d 帧, %.1f fps, root=%s）"
          % (aw, ah, b["name"], anim["name"], len(anim["frames"]), anim["rate"], anim["root"]))

    # ① 先算所有帧的包围盒（画布尺寸）
    minx = miny = 10 ** 9
    maxx = maxy = -10 ** 9
    hidden = set() if show_all else set(HIDE_DEFAULT)

    def visible(e):
        if show_all:
            return True
        lname = a["names"].get(e["layer"], "")
        return not layer_hidden(lname, hidden)

    for fr in anim["frames"]:
        for e in fr["elems"]:
            if not visible(e):
                continue
            s = b["sym_by_hash"].get(e["sym"])
            if not s:
                continue
            f = next((f for f in s["frames"] if f["num"] == e["frame"]), None)
            if not f:
                continue
            tx, ty = e["m"][4], e["m"][5]
            x0 = tx + f["x"] - f["w"] / 2.0
            ytop = ty + f["y"] - f["h"] / 2.0          # y 朝下：这是元件上边缘
            minx = min(minx, x0); miny = min(miny, ytop)
            maxx = max(maxx, x0 + f["w"]); maxy = max(maxy, ytop + f["h"])

    PAD = 4
    cw = int(round(maxx - minx)) + PAD * 2
    ch = int(round(maxy - miny)) + PAD * 2
    cw, ch = max(1, cw * scale), max(1, ch * scale)
    print("画布 %dx%d（scale=%d，内容 %.0fx%.0f）" % (cw, ch, scale, maxx - minx, maxy - miny))

    os.makedirs(outdir, exist_ok=True)
    files = []
    skipped = 0
    for idx, fr in enumerate(anim["frames"]):
        canvas = bytearray(cw * ch * 4)
        # z 越大越靠前 → 升序画
        for e in sorted(fr["elems"], key=lambda e: e["m"][6]):
            if not visible(e):
                skipped += 1
                continue
            s = b["sym_by_hash"].get(e["sym"])
            if not s:
                continue
            f = next((f for f in s["frames"] if f["num"] == e["frame"]), None)
            if not f or not f["uv"]:
                continue
            w = max(1, int(round(f["w"] * scale)))
            h = max(1, int(round(f["h"] * scale)))
            # u/v 直接用（实测不用翻，见文件头）
            u0, v0, u1, v1 = f["uv"]
            rect = (u0, v0, u1, v1)
            src = sample_atlas(aw, ah, rgba, rect, w, h)
            tx, ty = e["m"][4], e["m"][5]
            x0 = tx + f["x"] - f["w"] / 2.0
            y0 = ty + f["y"] - f["h"] / 2.0            # y 朝下：上边缘
            dx = int(round((x0 - minx) * scale)) + PAD * scale
            dy = int(round((y0 - miny) * scale)) + PAD * scale
            blit_rgba(canvas, cw, ch, src, w, h, dx, dy)

        if write_png:
            img = Image(cw, ch, canvas)
        else:
            raise RuntimeError("需要项目里的 exported/_tools/pnglib.py")
        p = os.path.join(outdir, "%s_%02d.png" % (anim_name, idx))
        write_png(p, img)
        files.append(p)
    print("出图 %d 张 -> %s   （按图层过滤掉 %d 个元件%s）"
          % (len(files), outdir, skipped, "，已 --show-all 全画" if show_all else ""))

    if sheet:
        cols = min(8, len(files))
        rows = (len(files) + cols - 1) // cols
        pad = 4
        SW, SH = cols * (cw + pad) + pad, rows * (ch + pad) + pad
        sheetbuf = bytearray(SW * SH * 4)
        for i in range(0, SW * SH * 4, 4):
            sheetbuf[i] = sheetbuf[i + 1] = sheetbuf[i + 2] = 58
            sheetbuf[i + 3] = 255
        for i, p in enumerate(files):
            im = None
            try:
                from pnglib import read_png
                im = read_png(p)
            except Exception:
                continue
            cx = pad + (i % cols) * (cw + pad)
            cy = pad + (i // cols) * (ch + pad)
            blit_rgba(sheetbuf, SW, SH, bytes(im.px), im.w, im.h, cx, cy)
        sp = os.path.join(outdir, "_%s_总览.png" % anim_name)
        write_png(sp, Image(SW, SH, sheetbuf))
        print("总览:", sp)
    return files


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__); return 1
    mode = args[0]
    if mode == "list":
        for p in args[1:]:
            if not p.lower().endswith(".zip"):
                continue
            try:
                a = parse_anim(p)
            except Exception as ex:
                print("  %s: 解析失败 %s" % (os.path.basename(p), ex)); continue
            print("== %s  (%d 个动画, 元素 %d, 帧 %d)"
                  % (os.path.basename(p), len(a["anims"]), a["elems"], a["frames"]))
            for x in a["anims"]:
                print("     %-28s %3d 帧  %.1f fps  root=%d"
                      % (x["name"], len(x["frames"]), x["rate"], x["root"]))
        return 0
    if mode == "render":
        rest = args[1:]
        scale, sheet, show_all = 1, False, False
        if "--scale" in rest:
            i = rest.index("--scale"); scale = int(rest[i + 1]); del rest[i:i + 2]
        if "--sheet" in rest:
            sheet = True; rest.remove("--sheet")
        if "--show-all" in rest:
            show_all = True; rest.remove("--show-all")
        bz, az, name, outdir = rest[0], rest[1], rest[2], rest[3]
        render_frames(bz, az, name, outdir, scale, sheet, show_all)
        return 0
    print(__doc__); return 1


if __name__ == "__main__":
    sys.exit(main())
