#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""sp_model_tool.py —— DST Spriter（Sp）模型工具（窗口化 · 逐帧截图 · 视觉审片 · scml 总成）

2026-09-25 夜间按 opencode（exported/_tools + hermes dst-art-pipeline）的口径重建。
渲染数学沿用 musha_scml_render.py 实测那套（y 翻转矩阵 / pivot 从底算 / z 升序叠加），
编译 zip 解码沿用 dump_anim_frames.py（BILD v6 / ANIM v4），并修正一处历史遗留：
  ★ anim 图集（KTEX flag 0xfffd…，scml.exe 与官方 anim 皆如此）在解码视图里是垂直
    倒序存储的，引擎加载时自行翻转（图标 tex flag 0xfffc 不翻）。所以：
    · zip 预览必须把 uv 裁剪区垂直翻回来才是游戏所见（本工具已内置）；
    · dump_anim_frames.py 的渲染因此一直上下颠倒（placement 正确、像素颠倒），
      其"v 不翻转"口诀只对"定位区域"成立。四路证据：item.png / 信差包 / musha 脸 /
      wilson swap_icon 的图集存储 MAE 全是"上下翻"完胜，而 wilson/musha 游戏内正立。
  → 结论：游戏里素材是正的，别因此改源图；预览工具补一次 FLIP_TOP_BOTTOM 即可。

支持的两种源：
  ① scml 工程     exported/<name>/<name>.scml（按 interval 采样出帧，台阶保持 = scml.exe 的落帧口径）
  ② 编译 anim zip anim/<name>.zip（anim.bin + build.bin + atlas-0.tex，所见 = 游戏所见）

功能：
  · 窗口化预览：播放/暂停、逐帧、缩放、棋盘格/黑/白/洋红/游戏绿底
  · 逐帧截图：--export 目录 → frame_XX.png（按所选底色）+ _alpha/ 透明底原帧
              + 00_总表_洋红底.png + manifest.json + REVIEW_TASK.md（审片任务书，直接发给视觉模型）
  · scml 总成：write_scml() 按房规生成工程；--demo 一键跑通 编写→编译→解码→截图 全链路
  · 编译：GUI「编译」按钮 / CLI compile，直接调官方 scml.exe（<file.scml> <outdir> → <outdir>/anim/<name>.zip）

scml 房规（都踩过坑，写死在工具里，别再手写 scml）：
  1. folder 的 name = build 里的 symbol 名（一个 folder 一个 symbol，多 file = 该 symbol 的多帧）
  2. key 里的 scale_x/scale_y 会被 scml.exe 忽略 → 目标尺寸必须烘进 PNG，声明 1:1
  3. key 必须带 time=（25ms 网格）+ curve_type="instant"；无 time 会全部塌到第 0 帧
  4. mainline 每帧一个 key，object_ref 的 key=i 逐帧指过去（换帧动画的灵魂）

用法：
  python sp_model_tool.py 源                       # 开窗口（scml 或 anim zip）
  python sp_model_tool.py 源 --export 出目录       # 无头逐帧截图 + 总表 + 审片任务书
  python sp_model_tool.py 源 --export 出目录 --scale 2 --bg magenta
  python sp_model_tool.py --demo 出目录            # 总成演示全链路
  python sp_model_tool.py 源 --selftest            # 窗口自检：真实开窗渲染 + 抓屏存图
纯标准库 + Pillow；编译 zip 解码另需 hermes dst-art-pipeline 的 tex2png.py（本机已装）。
"""
import json
import math
import os
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile

from PIL import Image, ImageTk

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

MOD = os.path.normpath(os.path.join(HERE, "..", ".."))
SCML_EXE = r"D:\SteamLibrary\steamapps\common\Don't Starve Mod Tools\mod_tools\scml.exe"
TEX2PNG_DIR = r"C:\Users\Administrator\AppData\Local\hermes\skills\gaming\dst-art-pipeline\scripts"

MAGENTA = (255, 0, 255, 255)
GREY = (70, 70, 78, 255)


def log(*a):
    print(*a, flush=True)


# ════════════════ 引擎 A：编译 anim zip（口径 = dump_anim_frames.py 实测） ════════════════

class R:
    def __init__(self, b):
        self.b, self.p = b, 0

    def u32(self):
        v = struct.unpack_from("<I", self.b, self.p)[0]; self.p += 4; return v

    def i32(self):
        v = struct.unpack_from("<i", self.b, self.p)[0]; self.p += 4; return v

    def f32(self):
        v = struct.unpack_from("<f", self.b, self.p)[0]; self.p += 4; return v

    def u8(self):
        v = self.b[self.p]; self.p += 1; return v

    def s(self):
        n = self.i32()
        v = self.b[self.p:self.p + n].decode("utf-8", "replace"); self.p += n
        return v


def _parse_names(r):
    n = r.u32()
    out = {}
    for _ in range(n):
        h = r.u32()
        out[h] = r.s()
    return out


def parse_build(zip_path):
    z = zipfile.ZipFile(zip_path)
    r = R(z.read("build.bin"))
    assert r.b[:4] == b"BILD", "不是 build.bin"
    r.p = 4
    r.i32()
    nsym, total = r.u32(), r.u32()
    build_name = r.s()
    natlas = r.u32()
    atlases = [r.s() for _ in range(natlas)]
    syms = []
    for _ in range(nsym):
        h, nf = r.u32(), r.u32()
        frames = []
        for _ in range(nf):
            fnum, dur = r.u32(), r.u32()
            x, y, w, hh = r.f32(), r.f32(), r.f32(), r.f32()
            astart, nverts = r.u32(), r.u32()
            frames.append(dict(num=fnum, x=x, y=y, w=w, h=hh, astart=astart, nverts=nverts))
        syms.append(dict(hash=h, frames=frames))
    nv = r.u32()
    verts = [r.f32() for _ in range(nv * 6)]          # x,y,z,u,v,sampler 原始保留（瓦片渲染要用）
    names = _parse_names(r)
    for s in syms:
        s["name"] = names.get(s["hash"], "hash_%d" % s["hash"])
        for f in s["frames"]:
            raw = verts[f["astart"] * 6:(f["astart"] + f["nverts"]) * 6]
            # sampler = 该瓦片所在图集页索引（scml.exe 素材多时会分页 atlas-0/1/...）
            f["verts"] = [(raw[k], raw[k + 1], raw[k + 3], raw[k + 4], raw[k + 5])
                          for k in range(0, len(raw), 6)]
            us = [v[2] for v in f["verts"]]
            vs = [v[3] for v in f["verts"]]
            f["uv"] = (min(us), min(vs), max(us), max(vs)) if us else None
    return dict(name=build_name, atlases=atlases, syms=syms,
                sym_by_hash={s["hash"]: s for s in syms}, total=total)


def parse_anim(zip_path):
    z = zipfile.ZipFile(zip_path)
    d = z.read("anim.bin")
    r = R(d)
    assert d[:4] == b"ANIM", "不是 anim.bin"
    r.p = 4
    r.i32()
    r.u32(); r.u32(); r.u32()
    nanim = r.u32()
    anims = []
    for _ in range(nanim):
        name = r.s()
        r.u8()                                  # facing
        r.u32()                                 # root hash
        rate = r.f32()
        nf = r.u32()
        frames = []
        for _ in range(nf):
            [r.f32() for _ in range(4)]         # root rect
            nevf = r.u32()
            for _ in range(nevf):
                r.u32(); r.u32()
            ne = r.u32()
            elems = []
            for _ in range(ne):
                sh, fi, lh = r.u32(), r.u32(), r.u32()
                m = [r.f32() for _ in range(7)]  # a,b,c,d,tx,ty,z
                elems.append(dict(sym=sh, frame=fi, layer=lh, m=m))
            frames.append(dict(elems=elems))
        anims.append(dict(name=name, rate=rate, frames=frames))
    # 尾部 hash→名字表（图层名在 anim.bin 里，用于过滤 swap/overlay 层）
    names = {}
    try:
        names = _parse_names(r)
    except Exception:
        names = {}
    return dict(anims=anims, names=names)


def decode_atlas_tex(tex_path):
    """KTEX → (w, h, RGBA bytes 自上而下)。用 opencode 的 tex2png（认头 + dxt1/3/5/rgba）"""
    if TEX2PNG_DIR not in sys.path:
        sys.path.insert(0, TEX2PNG_DIR)
    import tex2png
    b, w, h = tex2png.tex_info(tex_path)
    cands = tex2png._guess_format(len(b), w, h)
    if not cands:
        raise RuntimeError("认不出图集压缩格式: " + tex_path)
    cands.sort(key=lambda c: (c[1] != "dxt5", -c[0]))
    count, kind, entry, hdrlen = cands[0]
    sizes = tex2png._mip_sizes(w, h, count, kind)
    data = b[hdrlen:hdrlen + sizes[0]]
    dec = {"dxt5": tex2png.decode_dxt5, "dxt3": tex2png.decode_dxt3,
           "dxt1": tex2png.decode_dxt1}.get(kind)
    if dec:
        return w, h, dec(data, w, h, False)
    if kind == "rgba":
        return w, h, tex2png.decode_raw(data, w, h, 4, False)
    return w, h, tex2png.decode_raw(data, w, h, 3, False)


def _blit(canvas, src, dx, dy):
    w, h = src.size
    if dx < 0 or dy < 0 or dx + w > canvas.width or dy + h > canvas.height:
        sx0, sy0 = max(0, -dx), max(0, -dy)
        sx1, sy1 = min(w, canvas.width - dx), min(h, canvas.height - dy)
        if sx1 <= sx0 or sy1 <= sy0:
            return
        src = src.crop((sx0, sy0, sx1, sy1))
        dx, dy = dx + sx0, dy + sy0
    canvas.alpha_composite(src, (dx, dy))


# 游戏运行时默认隐藏的图层（dump_anim_frames.py 同款）：离线预览也必须过滤，
# 否则 swap_body/swap_hat/swap_face 等默认贴图会画在角色身上（棕色椭圆事故）
HIDE_DEFAULT = {
    "arm_carry", "lantern_overlay", "swap_face", "beard", "hat", "head_hat",
    "hair_hat", "swap_body", "swap_body_tall", "milestone_companion",
}


def layer_hidden(name):
    if not name:
        return False
    n = name.strip().lower()
    if n in HIDE_DEFAULT:
        return True
    return ("swap" in n) or ("carry" in n) or ("overlay" in n)


class ZipSource:
    """编译 anim zip → 逐帧 PIL Image（所见 = 游戏所见）"""

    def __init__(self, zip_path, anim_name=None, scale=1.0):
        self.path = zip_path
        self.build = parse_build(zip_path)
        animdata = parse_anim(zip_path)
        anims = animdata["anims"]
        self.layer_names = animdata.get("names", {})
        if anim_name is None:
            anim_name = anims[0]["name"]
        self.anim_name = anim_name
        anim = next((a for a in anims if a["name"] == anim_name), None)
        if anim is None:
            raise SystemExit("zip 里没有动画 %r；可选：%s" % (anim_name, ", ".join(a["name"] for a in anims)))
        self.anim = anim
        self.fps = anim["rate"]
        self.scale = scale
        self.symbols = [s["name"] for s in self.build["syms"]]
        self.pages = [Image.frombytes("RGBA", (w, h), bytes(rgba))
                      for _, w, h, rgba in self._atlases()]
        self.frames = self._render()

    def _atlases(self):
        """解码 build 里所有图集页 → [(名字, w, h, rgba)]"""
        out = []
        with zipfile.ZipFile(self.path) as z:
            for name in self.build["atlases"]:
                tmp = os.path.join(HERE, "_tmp")
                os.makedirs(tmp, exist_ok=True)
                p = os.path.join(tmp, os.path.basename(name))
                with open(p, "wb") as f:
                    f.write(z.read(name))
                aw, ah, rgba = decode_atlas_tex(p)
                out.append((name, aw, ah, rgba))
        return out

    def _render(self):
        b = self.build
        # 通用逐 quad 渲染：world = M_anim × build_vert + (tx, ty)
        #   M = [[m0, m1], [m2, m3]]（row-major a,b,c,d），支持旋转/镜像/缩放/分页；
        #   恒等矩阵时与旧 crop+flip+place 逐像素等价（已对照验证）。
        #   每角 uv 直接对应（图集倒序存储由顶点 v 编号天然吸收，无需显式翻转）。
        quads = []                               # (fi, z, page, uniq_corners)
        for fi, fr in enumerate(self.anim["frames"]):
            for e in fr["elems"]:
                lname = self.layer_names.get(e["layer"], "")
                if layer_hidden(lname):
                    continue                                   # swap/carry/overlay 层：运行时隐藏
                s = b["sym_by_hash"].get(e["sym"])
                if not s:
                    continue
                f = next((f for f in s["frames"] if f["num"] == e["frame"]), None)
                if not f or not f.get("verts"):
                    continue
                a_, b_, c_, d_ = e["m"][0], e["m"][1], e["m"][2], e["m"][3]
                tx, ty = e["m"][4], e["m"][5]
                vs = f["verts"]
                page = int(round(vs[0][4])) if len(vs[0]) > 4 else 0
                if page < 0 or page >= len(self.pages):
                    page = 0
                pw, ph = self.pages[page].size
                corners = []
                for (bx, by, u, v, pg) in vs:
                    wx = a_ * bx + b_ * by + tx
                    wy = c_ * bx + d_ * by + ty
                    corners.append((wx, wy, u * pw, v * ph))
                uniq = []
                for c in corners:
                    if c not in uniq:
                        uniq.append(c)
                if len(uniq) < 3:
                    continue
                quads.append((fi, e["m"][6], page, uniq))
        if not quads:
            raise SystemExit("动画里没有可渲染的元件")
        quads.sort(key=lambda q: q[1])           # z 升序（同帧内后贴的在上面）

        gx0 = gy0 = 10 ** 9
        gx1 = gy1 = -10 ** 9
        for fi, z, page, uniq in quads:
            for (wx, wy, ax, ay) in uniq:
                gx0, gy0 = min(gx0, wx), min(gy0, wy)
                gx1, gy1 = max(gx1, wx), max(gy1, wy)
        PAD = 2
        cw = max(1, int(round(gx1 - gx0)) + PAD * 2)
        ch = max(1, int(round(gy1 - gy0)) + PAD * 2)
        self.canvas_size = (cw, ch)

        buf = [None] * len(self.anim["frames"])
        for fi, z, page, uniq in quads:
            cv = buf[fi]
            if cv is None:
                cv = buf[fi] = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
            page_img = self.pages[page]
            nwx, nwy, nax, nay = min(uniq, key=lambda p: p[0] + p[1])
            swx, swy, sax, say = min(uniq, key=lambda p: p[0] - p[1])
            sex, sey, sax2, say2 = max(uniq, key=lambda p: p[0] + p[1])
            nex, ney, nax2, nay2 = max(uniq, key=lambda p: p[0] - p[1])
            bw = max(1, int(round(sex - nwx)))
            bh = max(1, int(round(sey - nwy)))
            # PIL QUAD：data = 源（图集）四角 NW/SW/SE/NE → 输出 (0,0),(0,h),(w,h),(w,0)
            data = (nax, nay, sax, say, sax2, say2, nax2, nay2)
            try:
                tile = page_img.transform((bw, bh), Image.QUAD, data, resample=Image.BILINEAR)
            except Exception:
                continue
            dx = int(round(nwx - gx0)) + PAD
            dy = int(round(nwy - gy0)) + PAD
            _blit(cv, tile, dx, dy)
        frames = []
        for cv in buf:
            if cv is None:
                cv = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
            if self.scale != 1.0:
                cv = cv.resize((max(1, int(cw * self.scale)), max(1, int(ch * self.scale))), Image.NEAREST)
            frames.append(cv)
        return frames


# ════════════════ 引擎 B：scml 源（口径 = musha_scml_render.py 实测） ════════════════
# canvas_y = cy − y（build 空间 y 向上）；pivot 像素 = (pvx·w, (1−pvy)·h)；
# y 向下画布合成：X = ox + ca·du·sx − sa·dv·sy，Y = oy + sa·du·sx + ca·dv·sy；z 升序贴。

def fnum(v, d=0.0):
    try:
        return float(v)
    except (TypeError, ValueError):
        return d


def load_scml(path):
    root = ET.parse(path).getroot()
    folders = {}
    for f in root.findall("folder"):
        files = []
        for x in f.findall("file"):
            files.append(dict(name=x.get("name"), w=int(x.get("width")), h=int(x.get("height")),
                              pvx=fnum(x.get("pivot_x"), 0.5), pvy=fnum(x.get("pivot_y"), 0.5)))
        folders[int(f.get("id"))] = dict(name=f.get("name"), files=files)
    ent = root.find("entity")
    anims = {}
    for a in ent.findall("animation"):
        interval = int(a.get("interval", 25))
        objs, tl_names = {}, {}
        for tl in a.findall("timeline"):
            tid = int(tl.get("id"))
            tl_names[tid] = tl.get("name")
            for k in tl.findall("key"):
                kid = int(k.get("id"))
                o = k.find("object")
                if o is None:
                    continue
                objs[(tid, kid)] = dict(folder=int(o.get("folder", 0)), file=int(o.get("file", 0)),
                                        x=fnum(o.get("x")), y=fnum(o.get("y")), ang=fnum(o.get("angle")),
                                        sx=fnum(o.get("scale_x"), 1.0), sy=fnum(o.get("scale_y"), 1.0),
                                        time=fnum(k.get("time"), kid * interval))
        keys = []
        ml = a.find("mainline")
        for k in (ml.findall("key") if ml is not None else []):
            layers = []
            for ref in k.findall("object_ref"):
                tid, ok = int(ref.get("timeline")), int(ref.get("key", ref.get("id", 0)))
                o = objs.get((tid, ok))
                if o is None:
                    continue
                layers.append(dict(o, z=int(ref.get("z_index", 0)), tl=tl_names.get(tid, "?")))
            keys.append(sorted(layers, key=lambda L: L["z"]))
        anims[a.get("name")] = dict(length=int(a.get("length", 0)), interval=interval, keys=keys)
    return folders, anims


def scml_sample_frames(anim):
    """按 25ms 网格采样（台阶保持）→ [层列表, ...]。
    实测 scml.exe 落帧按 25ms 网格（interval=100 的 scml 也编出 40fps），所以这里固定 25，
    保证「预览 = 编译后所见」。"""
    STEP = 25
    keys = sorted(anim["keys"], key=lambda k: k[0]["time"] if k else 0)
    if not keys:
        return []
    n = max(1, int(round(anim["length"] / STEP))) if anim["length"] else 1
    out = []
    for i in range(n):
        t = i * STEP
        cur = keys[0]
        for k in keys:
            if (k[0]["time"] if k else 0) <= t:
                cur = k
        out.append(cur)
    return out


class ScmlSource:
    """scml 工程 → 逐帧 PIL Image（稳定画布：全帧统一 bbox，播放不抖）"""

    def __init__(self, scml_path, anim_name=None, scale=1.0):
        self.path = scml_path
        self.base = os.path.dirname(os.path.abspath(scml_path))
        self.folders, anims = load_scml(scml_path)
        if anim_name is None:
            anim_name = list(anims)[0]
        self.anim_name = anim_name
        if anim_name not in anims:
            raise SystemExit("scml 里没有动画 %r；可选：%s" % (anim_name, ", ".join(anims)))
        self.anim = anims[anim_name]
        self.fps = 40.0                          # scml.exe 按 25ms 网格落帧（实测），预览同口径
        self.scale = scale
        self.symbols = [f["name"] or ("folder_%d" % fid) for fid, f in sorted(self.folders.items())]
        self.samples = scml_sample_frames(self.anim)
        self.frames = self._render()

    def _file_img(self, fid, fi, cache):
        key = (fid, fi)
        if key not in cache:
            f = self.folders[fid]["files"][fi]
            p = os.path.join(self.base, f["name"].replace("/", os.sep))
            cache[key] = Image.open(p).convert("RGBA") if os.path.exists(p) else None
        return cache[key]

    def _corners(self, L, src):
        """4 角在 build 空间（y 向上）的包围盒"""
        w, h = src.size
        f = self.folders[L["folder"]]["files"][L["file"]]
        px, py = f["pvx"] * w, (1.0 - f["pvy"]) * h
        rad = math.radians(L["ang"])
        ca, sa = math.cos(rad), math.sin(rad)
        xs, ys = [], []
        for (u, v) in ((0, 0), (w, 0), (0, h), (w, h)):
            du, dv = u - px, v - py
            xs.append(L["x"] + ca * du * L["sx"] - sa * dv * L["sy"])
            ys.append(L["y"] + sa * du * L["sx"] + ca * dv * L["sy"])
        return min(xs), max(xs), min(ys), max(ys)

    def _render(self):
        cache = {}
        pad = 4
        bx0 = by0 = 10 ** 9
        bx1 = by1 = -10 ** 9
        for layers in self.samples:
            for L in layers:
                src = self._file_img(L["folder"], L["file"], cache)
                if src is None:
                    continue
                x0, x1, y0, y1 = self._corners(L, src)
                bx0, by0 = min(bx0, x0), min(by0, y0)
                bx1, by1 = max(bx1, x1), max(by1, y1)
        if bx1 < bx0:
            bx0 = by0 = 0.0
            bx1 = by1 = 1.0
        cxlo, cylo = bx0 - pad, by0 - pad
        cxhi, cyhi = bx1 + pad, by1 + pad
        sc = self.scale
        cw = max(1, int(math.ceil((cxhi - cxlo) * sc)))
        ch = max(1, int(math.ceil((cyhi - cylo) * sc)))
        self.canvas_size = (cw, ch)
        frames = []
        for layers in self.samples:
            cv = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
            for L in layers:                             # 已按 z 升序
                src = self._file_img(L["folder"], L["file"], cache)
                if src is None:
                    log("  [缺图] folder=%d file=%d (%s)" % (L["folder"], L["file"], L.get("tl", "?")))
                    continue
                w, h = src.size
                f = self.folders[L["folder"]]["files"][L["file"]]
                px, py = f["pvx"] * w, (1.0 - f["pvy"]) * h
                rad = math.radians(L["ang"])
                ca, sa = math.cos(rad), math.sin(rad)
                sxs, sys_ = L["sx"] * sc, L["sy"] * sc
                ox = (L["x"] - cxlo) * sc                # 内容框左下角 → 翻 y → 乘 scale
                oy = (cyhi - L["y"]) * sc
                xs, ys = [], []
                for (u, v) in ((0, 0), (w, 0), (0, h), (w, h)):
                    du, dv = u - px, v - py
                    xs.append(ox + ca * du * sxs - sa * dv * sys_)
                    ys.append(oy + sa * du * sxs + ca * dv * sys_)
                x0, x1 = int(math.floor(min(xs))) - 1, int(math.ceil(max(xs))) + 1
                y0, y1 = int(math.floor(min(ys))) - 1, int(math.ceil(max(ys))) + 1
                ow, oh = max(1, x1 - x0), max(1, y1 - y0)
                # PIL AFFINE：输出→输入 (a,b,c,d,e,f)，C 速度等价于逐像素逆变换
                coef = (ca / sxs, sa / sxs, (ca * (x0 - ox) + sa * (y0 - oy)) / sxs + px,
                        -sa / sys_, ca / sys_, (-sa * (x0 - ox) + ca * (y0 - oy)) / sys_ + py)
                layer = src.transform((ow, oh), Image.AFFINE, coef, resample=Image.NEAREST)
                _blit(cv, layer, x0, y0)
            frames.append(cv)
        return frames


def make_source(path, anim_name=None, scale=1.0):
    p = path.lower()
    if p.endswith(".zip"):
        return ZipSource(path, anim_name, scale)
    if p.endswith(".scml"):
        return ScmlSource(path, anim_name, scale)
    raise SystemExit("认不出的源（要 .scml 或 anim .zip）: " + path)


# ════════════════ 输出：逐帧截图 + 总表 + 审片任务书 ════════════════

BGS = {"checker": None, "black": (0, 0, 0, 255), "white": (255, 255, 255, 255),
       "magenta": MAGENTA, "grey": GREY, "game": (0, 128, 0, 255)}


def checkerboard(w, h, cell=8):
    cv = Image.new("RGBA", (w, h))
    p = cv.load()
    for y in range(h):
        for x in range(w):
            p[x, y] = (100, 100, 108, 255) if ((x // cell) + (y // cell)) % 2 else (140, 140, 148, 255)
    return cv


def compose_bg(frame, bg):
    if bg is None:
        cv = checkerboard(frame.width, frame.height)
        cv.alpha_composite(frame)
        return cv
    cv = Image.new("RGBA", frame.size, bg)
    cv.alpha_composite(frame)
    return cv


def contact_sheet(frames, cols=8, bg=MAGENTA, pad=6):
    cols = max(1, min(cols, len(frames)))
    rows = (len(frames) + cols - 1) // cols
    cw = max(f.width for f in frames)
    chh = max(f.height for f in frames)
    cv = Image.new("RGBA", (cols * (cw + pad) + pad, rows * (chh + pad) + pad), bg)
    for n, f in enumerate(frames):
        r, c = divmod(n, cols)
        cv.alpha_composite(f, (pad + c * (cw + pad) + (cw - f.width) // 2,
                               pad + r * (chh + pad) + (chh - f.height) // 2))
    return cv


REVIEW_TEMPLATE = """# 视觉审片任务书（发给视觉模型）

源：{src}
动画：{anim}   帧数：{n}   fps：{fps:.0f}   画布：{cw}x{ch}
总表：00_总表_洋红底.png（洋红 = 透明区，专查黑边/白边/烂边）

请逐帧检查以下各项，发现问题报「帧号 + 现象」：
1. 主体完整：有无缺件、穿帮、被画布裁掉的部分
2. 逐帧一致性：有没有某帧突然变大/变小/偏移/闪烁（换帧动画重点查）
3. 边缘质量：洋红底上有没有黑边、白边、半透明烂边
4. 中心与接地：主体是否大致居中、底部是否稳定
5. 图层顺序：前后遮挡关系是否正确（z_index 检查）
6. 其他任何观感问题

输出格式：
  PASS 或 FAIL
  问题列表（帧号 + 具体描述 + 严重度 高/中/低）
"""


def export_frames(src, outdir, bg_name="checker", prefix="frame"):
    """逐帧截图：frame_XX.png（所选底色）+ _alpha/ 透明底原帧 + 总表 + manifest + 审片任务书"""
    os.makedirs(outdir, exist_ok=True)
    alpha_dir = os.path.join(outdir, "_alpha")
    os.makedirs(alpha_dir, exist_ok=True)
    bg = BGS.get(bg_name)
    manifest = dict(source=src.path, anim=src.anim_name, fps=src.fps,
                    canvas=list(src.canvas_size), symbols=src.symbols, frames=[])
    for i, fr in enumerate(src.frames):
        compose_bg(fr, bg).save(os.path.join(outdir, "%s_%02d.png" % (prefix, i)))
        fr.save(os.path.join(alpha_dir, "%s_%02d.png" % (prefix, i)))
        manifest["frames"].append(dict(i=i, file="%s_%02d.png" % (prefix, i), size=list(fr.size)))
    n = len(src.frames)
    contact_sheet([compose_bg(f, MAGENTA) for f in src.frames]).save(
        os.path.join(outdir, "00_总表_洋红底.png"))
    with open(os.path.join(outdir, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=1)
    with open(os.path.join(outdir, "REVIEW_TASK.md"), "w", encoding="utf-8") as f:
        f.write(REVIEW_TEMPLATE.format(src=src.path, anim=src.anim_name, n=n, fps=src.fps,
                                       cw=src.canvas_size[0], ch=src.canvas_size[1]))
    log("导出 %d 帧 → %s" % (n, outdir))
    log("  逐帧截图 %s_00..%02d.png（%s 底）+ _alpha/ 透明底" % (prefix, n - 1, bg_name))
    log("  总表 00_总表_洋红底.png + manifest.json + REVIEW_TASK.md（审片任务书）")
    return outdir


# ════════════════ scml 编写器（总成） ════════════════

def fmt(v):
    f = float(v)
    return str(int(f)) if abs(f - round(f)) < 1e-9 else ("%.4f" % f).rstrip("0").rstrip(".")


def _fid(folders, name):
    for fid, (fn, _) in enumerate(folders):
        if fn == name:
            return fid
    raise KeyError("folder 不存在: " + name)


def write_scml(out_path, entity, anims, folders):
    """按房规生成 scml。
    folders: [(symbol名, [png 路径...])]   —— 声明尺寸 = 实际像素（1:1 铁律），pivot 0.5/0.5
    anims:   [(动画名, length_ms, interval_ms,
               [ dict(timeline=symbol名, z=int, keys=[(time_ms, file_idx, x, y), ...]) ])]
    自动写 time= + curve_type="instant"；mainline 每帧一个 key（object_ref key=i）；
    短 timeline 自动重复最后一帧补齐；不写 scale（scml.exe 会忽略，尺寸烘在 PNG 里）。
    """
    fxml = []
    for fid, (fname, pngs) in enumerate(folders):
        fxml.append('    <folder id="%d" name="%s">' % (fid, fname))
        for fi, p in enumerate(pngs):
            im = Image.open(p)
            rel = os.path.relpath(p, os.path.dirname(out_path)).replace("\\", "/")
            fxml.append('        <file id="%d" name="%s" width="%d" height="%d" pivot_x="0.5" pivot_y="0.5"/>'
                        % (fi, rel, im.width, im.height))
        fxml.append('    </folder>')

    axml = []
    for aid, (aname, length, interval, tls) in enumerate(anims):
        nkeys = max(len(tl["keys"]) for tl in tls)
        refs, tls_xml = [], []
        for tid, tl in enumerate(tls):
            fid = _fid(folders, tl["timeline"])
            ks = []
            for kid in range(nkeys):
                t, fi, x, y = tl["keys"][kid if kid < len(tl["keys"]) else -1]
                if kid >= len(tl["keys"]):
                    t = tl["keys"][-1][0] + (kid - len(tl["keys"]) + 1) * interval
                ks.append('                <key id="%d" time="%d" curve_type="instant" spin="0">' % (kid, t))
                ks.append('                    <object folder="%d" file="%d" x="%s" y="%s"/>'
                          % (fid, fi, fmt(x), fmt(y)))
                ks.append('                </key>')
            tls_xml.append('            <timeline id="%d" name="%s">\n%s\n            </timeline>'
                           % (tid, tl["timeline"], "\n".join(ks)))
        for i in range(nkeys):
            inner = "".join('                    <object_ref id="%d" timeline="%d" key="%d" z_index="%d"/>\n'
                            % (tid, tid, i, tl["z"]) for tid, tl in enumerate(tls))
            refs.append('                <key id="%d">\n%s                </key>' % (i, inner.rstrip("\n")))
        axml.append('''        <animation id="%d" name="%s" length="%d" interval="%d">
            <mainline>
%s
            </mainline>
%s
        </animation>''' % (aid, aname, length, interval, "\n".join(refs), "\n".join(tls_xml)))

    xml = '''<?xml version="1.0" encoding="UTF-8"?>
<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="r7">
<!-- sp_model_tool 生成：folder 名 = symbol 名；key 带 time+instant；无 scale（尺寸烘在 PNG 里）；
     mainline 每帧一个 key。房规见 _tools/sp_model_tool.py 文件头。 -->
%s
    <entity id="0" name="%s">
%s
    </entity>
</spriter_data>
''' % ("\n".join(fxml), entity, "\n".join(axml))
    open(out_path, "w", encoding="utf-8", newline="\n").write(xml)
    log("写出", out_path, len(xml), "B")


def compile_scml(scml_path, outdir):
    """官方 scml.exe：<file.scml> <outdir> → <outdir>/anim/<name>.zip
    坑：输入必须是相对 cwd 的裸文件名（cwd = scml 所在目录），输出目录给绝对路径；
    否则 scml.exe 会把输入路径拼到输出目录下找不到。"""
    if not os.path.exists(SCML_EXE):
        raise SystemExit("找不到 scml.exe: " + SCML_EXE)
    scml_path = os.path.abspath(scml_path)
    outdir = os.path.abspath(outdir)
    r = subprocess.run([SCML_EXE, os.path.basename(scml_path), outdir],
                       cwd=os.path.dirname(scml_path),
                       capture_output=True, text=True, errors="replace")
    if r.stdout.strip():
        log(r.stdout.strip())
    if r.returncode != 0:
        raise SystemExit("scml.exe 失败: " + (r.stderr or "").strip())
    name = os.path.splitext(os.path.basename(scml_path))[0]
    out = os.path.join(outdir, "anim", name + ".zip")
    log("编译产物:", out, os.path.getsize(out), "B")
    return out


# ════════════════ 总成演示：呼吸动画全链路 ════════════════

def demo(outdir):
    """3 档缩放烘进 PNG 的「呼吸」项目 → scml → scml.exe 编译 → 解码 → 逐帧截图。
    全程在沙箱目录，不动游戏 anim/。"""
    os.makedirs(outdir, exist_ok=True)
    body_src = os.path.join(MOD, "exported", "musha_recall_stone", "item.png")
    body = Image.open(body_src).convert("RGBA")
    pngs = []
    for i, k in enumerate([1.0, 1.05, 1.10]):
        im = body.resize((max(1, int(body.width * k)), max(1, int(body.height * k))), Image.LANCZOS)
        p = os.path.join(outdir, "stone-%d.png" % i)
        im.save(p)
        pngs.append(p)
    gs = 64
    glow = Image.new("RGBA", (gs, gs), (0, 0, 0, 0))
    gp = glow.load()
    for y in range(gs):
        for x in range(gs):
            d = math.hypot(x + .5 - gs / 2, y + .5 - gs / 2) / (gs / 2 - 1)
            if d < 1:
                gp[x, y] = (176, 126, 232, int(150 * (1 - d) ** 2))
    glow_p = os.path.join(outdir, "glow-0.png")
    glow.save(glow_p)

    seq = [0, 1, 2, 1, 0, 1, 2, 1, 0]
    scml = os.path.join(outdir, "spdemo_breathe.scml")
    write_scml(scml, "spdemo_breathe",
               [("idle", (len(seq) - 1) * 25, 25,
                 [dict(timeline="glow", z=0, keys=[(0, 0, 0, 0)]),
                  dict(timeline="stone", z=1, keys=[(i * 25, seq[i], 0, 0) for i in range(len(seq))])])],
               [("glow", [glow_p]), ("stone", pngs)])

    zpath = compile_scml(scml, outdir)
    src = ZipSource(zpath)
    log("解码编译产物: 动画 %s  %d 帧  %.0f fps  符号 %s  画布 %dx%d"
        % (src.anim_name, len(src.frames), src.fps, ",".join(src.symbols), *src.canvas_size))
    export_frames(src, os.path.join(outdir, "_export"), bg_name="magenta")
    log("全链路完成 ✅   窗口预览: python sp_model_tool.py \"%s\"" % zpath)
    return zpath


# ════════════════ GUI ════════════════

def run_gui(src_path, anim_name=None, scale=2.0, bg_name="checker", auto_close_ms=None):
    import tkinter as tk
    from tkinter import ttk, filedialog, messagebox

    src = make_source(src_path, anim_name, scale)
    root = tk.Tk()
    root.title("Sp 模型工具 — %s · %s" % (os.path.basename(src_path), src.anim_name))
    root.configure(bg="#2e3038")
    state = dict(idx=0, playing=False, zoom=scale, bg_name=bg_name, photo=None)

    cv = tk.Canvas(root, width=src.canvas_size[0] + 40, height=src.canvas_size[1] + 40,
                   bg="#22242c", highlightthickness=0)
    cv.grid(row=0, column=0, sticky="nsew", padx=6, pady=6)
    panel = tk.Frame(root, bg="#2e3038")
    panel.grid(row=0, column=1, sticky="ns", padx=8, pady=6)
    bar = tk.Label(root, text="", bg="#2e3038", fg="#9aa0ad", anchor="w", font=("Microsoft YaHei UI", 9))
    bar.grid(row=1, column=0, columnspan=2, sticky="ew", padx=8)

    def redraw():
        n = len(src.frames)
        state["idx"] %= n
        fr = src.frames[state["idx"]]
        comp = compose_bg(fr, BGS.get(state["bg_name"]))
        z = state["zoom"]
        if z != 1.0:
            comp = comp.resize((max(1, int(comp.width * z)), max(1, int(comp.height * z))), Image.NEAREST)
        state["photo"] = ImageTk.PhotoImage(comp)
        cv.delete("all")
        cv.create_image(20, 20, image=state["photo"], anchor="nw")
        cv.configure(width=comp.width + 40, height=comp.height + 40)
        bar.config(text=" 帧 %d/%d   %.0f fps   画布 %dx%d   符号: %s"
                   % (state["idx"] + 1, n, src.fps, src.canvas_size[0], src.canvas_size[1],
                      ", ".join(src.symbols)))

    def step(d):
        state["idx"] += d
        redraw()

    def tick():
        if state["playing"]:
            step(1)
        root.after(int(1000 / max(1, src.fps)), tick)

    row = [0]

    def lab(t):
        tk.Label(panel, text=t, bg="#2e3038", fg="#8f95a3", font=("Microsoft YaHei UI", 8)).grid(row=row[0], sticky="w")
        row[0] += 1

    def btn(t, fn, big=False):
        tk.Button(panel, text=t, command=fn, bg="#3c3f4a", fg="#e8e8ee", relief="flat",
                  font=("Microsoft YaHei UI", 10 if big else 9), padx=8, pady=4 if big else 2
                  ).grid(row=row[0], sticky="ew", pady=2)
        row[0] += 1

    lab("── 源 ──")
    lab(os.path.basename(src_path))
    lab("动画: " + src.anim_name)
    lab("── 播放 ──")

    def toggle_play():
        state["playing"] = not state["playing"]
        play_btn.config(text="⏸ 暂停" if state["playing"] else "▶ 播放")

    play_btn = tk.Button(panel, text="▶ 播放", command=toggle_play, bg="#3c3f4a", fg="#e8e8ee",
                         relief="flat", font=("Microsoft YaHei UI", 10), padx=8, pady=4)
    play_btn.grid(row=row[0], sticky="ew", pady=2); row[0] += 1
    nav = tk.Frame(panel, bg="#2e3038")
    nav.grid(row=row[0], sticky="ew", pady=2); row[0] += 1
    tk.Button(nav, text="⏮", command=lambda: step(-1), bg="#3c3f4a", fg="#e8e8ee", relief="flat",
              width=5, font=("Microsoft YaHei UI", 9)).pack(side="left", expand=True, fill="x", padx=1)
    tk.Button(nav, text="⏭", command=lambda: step(1), bg="#3c3f4a", fg="#e8e8ee", relief="flat",
              width=5, font=("Microsoft YaHei UI", 9)).pack(side="left", expand=True, fill="x", padx=1)

    lab("── 缩放 ──")
    zoom_var = tk.DoubleVar(value=state["zoom"])
    zs = ttk.Scale(panel, from_=0.25, to=8, variable=zoom_var, orient="horizontal", command=lambda _:
                   (state.__setitem__("zoom", round(zoom_var.get() * 4) / 4), redraw()))
    zs.grid(row=row[0], sticky="ew", pady=2); row[0] += 1
    lab("── 背景 ──")
    bg_var = tk.StringVar(value=state["bg_name"])
    for nm in ("checker", "magenta", "black", "white", "game"):
        tk.Radiobutton(panel, text=nm, variable=bg_var, value=nm,
                       command=lambda: (state.__setitem__("bg_name", bg_var.get()), redraw()),
                       bg="#2e3038", fg="#c8cad4", selectcolor="#22242c",
                       activebackground="#2e3038").grid(row=row[0], sticky="w")
        row[0] += 1

    lab("── 导出 / 编译 ──")

    def do_export():
        d = filedialog.askdirectory(title="逐帧截图导出到…")
        if not d:
            return
        export_frames(src, d, bg_name=state["bg_name"])
        messagebox.showinfo("导出完成", "逐帧截图 + 总表 + 审片任务书 已写入:\n" + d)

    def do_compile():
        if not isinstance(src, ScmlSource):
            messagebox.showwarning("编译", "只有 scml 工程能编译（zip 已是编译产物）")
            return
        try:
            out = compile_scml(src.path, MOD)
            messagebox.showinfo("编译完成", "anim zip 已更新:\n" + out)
        except Exception as ex:
            messagebox.showerror("编译失败", str(ex))

    def do_open():
        p = filedialog.askopenfilename(title="选 scml 或 anim zip",
                                       filetypes=[("Spriter/anim", "*.scml *.zip"), ("全部", "*.*")])
        if p:
            root.destroy()
            run_gui(p, scale=state["zoom"], bg_name=state["bg_name"])

    btn("📸 逐帧截图导出…", do_export, big=True)
    btn("🔨 编译 (scml.exe → anim/)", do_compile)
    btn("📂 打开其他源…", do_open)
    lab("")
    lab("口径：z 升序叠加 · anim y 朝下")
    lab("v 不翻转 · key scale 无效（烘进 PNG）")

    root.columnconfigure(0, weight=1)
    root.rowconfigure(0, weight=1)
    redraw()
    tick()
    if auto_close_ms:
        root.after(auto_close_ms, root.destroy)
    root.mainloop()


# ════════════════ 窗口自检 ════════════════

def selftest(src_path):
    """真实开窗渲染一帧 + 抓屏存 PNG（验证「窗口化」本机可用）"""
    from PIL import ImageGrab
    import tkinter as tk
    src = make_source(src_path, scale=2.0)
    root = tk.Tk()
    root.title("Sp 模型工具 selftest")
    cv = tk.Canvas(root, bg="#22242c", highlightthickness=0)
    cv.pack(fill="both", expand=True)
    comp = compose_bg(src.frames[0], MAGENTA)
    comp = comp.resize((comp.width * 2, comp.height * 2), Image.NEAREST)
    ph = ImageTk.PhotoImage(comp)
    cv.create_image(10, 10, image=ph, anchor="nw")
    cv.configure(width=comp.width + 20, height=comp.height + 20)
    root.geometry("%dx%d" % (comp.width + 40, comp.height + 60))
    root.update_idletasks()
    root.update()

    def grab():
        x, y = root.winfo_rootx(), root.winfo_rooty()
        w, h = root.winfo_width(), root.winfo_height()
        out = os.path.join(HERE, "_tmp", "_selftest_window.png")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        ImageGrab.grab((x, y, x + w, y + h)).save(out)
        log("selftest: 窗口 %dx%d @(%d,%d)，源渲染 %d 帧 → 抓屏 %s"
            % (w, h, x, y, len(src.frames), out))
        root.destroy()

    root.after(900, grab)
    root.mainloop()


# ════════════════ CLI ════════════════

def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return 0
    if args[0] == "--demo":
        out = args[1] if len(args) > 1 else os.path.join(HERE, "_test_out", "sp_tool_demo")
        demo(out)
        return 0
    src_path = args[0]
    anim = None
    scale = None
    outdir = os.path.join(HERE, "_tmp", "sp_export")
    bg_name = "checker"
    export = selft = guitest = False
    i = 1
    while i < len(args):
        a = args[i]
        if a == "--export":
            export = True
            outdir = args[i + 1]; i += 2
        elif a == "--anim":
            anim = args[i + 1]; i += 2
        elif a == "--scale":
            scale = float(args[i + 1]); i += 2
        elif a == "--bg":
            bg_name = args[i + 1]; i += 2
        elif a == "--selftest":
            selft = True; i += 1
        elif a == "--guitest":
            export = False
            guitest = True; i += 1
        else:
            i += 1
    if selft:
        selftest(src_path)
        return 0
    src = make_source(src_path, anim, scale or 1.0)
    log("源: %s\n动画: %s  %d 帧  %.0f fps  画布 %dx%d  符号: %s"
        % (src_path, src.anim_name, len(src.frames), src.fps, *src.canvas_size, ", ".join(src.symbols)))
    if export:
        export_frames(src, outdir, bg_name=bg_name)
    else:
        run_gui(src_path, anim, scale or 2.0, bg_name, auto_close_ms=2000 if guitest else None)
    return 0


if __name__ == "__main__":
    sys.exit(main())
