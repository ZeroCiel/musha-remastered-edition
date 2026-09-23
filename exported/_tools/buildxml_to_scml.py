# -*- coding: utf-8 -*-
"""build.xml + animation.xml（Mod Tool 导出的 build 源） → Spriter .scml

用途：拿到一份 build 源（build.xml/animation.xml/一堆 <符号>-N.png），整理成 musha 那套
Spriter 工程（每符号一个子文件夹 + 一个 .scml），可以直接用 Mod Tool / scml.exe 重新编译。

口径（2026-09-18 用 exported/musha/musha.scml 反推 + 逐元素校验）：
  pivot_x = 0.5 - x / w            （x = build.xml Frame 的 x）
  pivot_y = 0.5 + y / h            （y = build.xml Frame 的 y）
  动画元素 (a,b,c,d,tx,ty) → scml object：
      x = tx,  y = -ty
      sx = hypot(a, c),  th = atan2(c, a)          # M = R(th)·S(sx,sy)
      sy = -b/sin(th)  （|sin| 小的时候用 d/cos(th)）
      angle = -degrees(th)                          # canvas y 向下 = 世界镜像
  时间轴名 = animation.xml 的 layername（同帧内重名按出现次序加 _1 _2 …）
  z_index  = 每个 key 的 mainline object_ref
"""
import os, re, math, shutil, sys, zipfile, subprocess

TOOLS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOLS)


def parse_build(path):
    txt = open(path, encoding="utf-8", errors="replace").read()
    syms = []
    for m in re.finditer(r'<Symbol name="([^"]+)">(.*?)</Symbol>', txt, re.S):
        frames = []
        for f in re.finditer(r'<Frame framenum="(\d+)" duration="(\d+)" image="([^"]+)" '
                             r'w="(\d+)" h="(\d+)" x="([-0-9.eE]+)" y="([-0-9.eE]+)"', m.group(2)):
            frames.append(dict(n=int(f.group(1)), dur=int(f.group(2)), img=f.group(3),
                               w=int(f.group(4)), h=int(f.group(5)),
                               x=float(f.group(6)), y=float(f.group(7))))
        syms.append((m.group(1), frames))
    return syms


def parse_anim(path):
    txt = open(path, encoding="utf-8", errors="replace").read()
    head = re.search(r'<anim name="([^"]+)" root="([^"]*)" numframes="(\d+)" framerate="(\d+)"', txt)
    name, root, numframes, framerate = head.group(1), head.group(2), int(head.group(3)), int(head.group(4))
    frames = []
    for m in re.finditer(r'<frame idx="(\d+)"[^>]*>(.*?)</frame>', txt, re.S):
        els = []
        for e in re.finditer(r'<element name="([^"]+)" layername="([^"]*)" frame="(\d+)" z_index="(-?\d+)" '
                             r'm_a="([-0-9.eE]+)" m_b="([-0-9.eE]+)" m_c="([-0-9.eE]+)" m_d="([-0-9.eE]+)" '
                             r'm_tx="([-0-9.eE]+)" m_ty="([-0-9.eE]+)"', m.group(2)):
            els.append(dict(sym=e.group(1), layer=e.group(2), bframe=int(e.group(3)), z=int(e.group(4)),
                            a=float(e.group(5)), b=float(e.group(6)), c=float(e.group(7)), d=float(e.group(8)),
                            tx=float(e.group(9)), ty=float(e.group(10))))
        frames.append((int(m.group(1)), els))
    return dict(name=name, root=root, numframes=numframes, framerate=framerate, frames=frames)


def decompose(a, b, c, d):
    """(a,b,c,d) → (sx, sy, angle_deg) —— scml 口径（2026-09-18 与现有工程逐元素拟合确认）

      参考工程实测：sx = hypot(a,b)；angle = -atan2(b,a)；
                    sy = sign(det)·hypot(c,d)（mirror 层 det<0 → sy 取负）
    """
    sx = math.hypot(a, b)
    th = math.atan2(b, a)
    det = a * d - b * c
    sy = math.copysign(math.hypot(c, d), det if abs(det) > 1e-9 else 1.0)
    return sx, sy, -math.degrees(th)


def fmt(v):
    return ("%.6f" % v).rstrip("0").rstrip(".") if v == v else "0"


def layer_names(frames0):
    """按 frame0 的 layername 定时间轴名（重名加 _1 _2 …）"""
    seen = {}
    out = []
    for e in frames0:
        base = e["layer"]
        seen[base] = seen.get(base, 0) + 1
        out.append(base if seen[base] == 1 else "%s_%d" % (base, seen[base] - 1))
    return out


def build_scml(syms, anim, entity="template", names_override=None):
    frames = anim["frames"]
    assert frames, "animation.xml 没有 frame"
    f0 = frames[0][1]
    names = list(names_override) if names_override else layer_names(f0)
    L = []
    L.append('<?xml version="1.0" encoding="UTF-8"?>')
    L.append('<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="r11">')
    fid = {}
    for i, (sym, frs) in enumerate(syms):
        fid[sym] = i
        L.append('\t<folder id="%d" name="%s">' % (i, sym))
        for f in frs:
            px = 0.5 - (f["x"] / f["w"] if f["w"] else 0)
            py = 0.5 + (f["y"] / f["h"] if f["h"] else 0)
            L.append('\t\t<file id="%d" name="%s/%s.png" width="%d" height="%d" pivot_x="%s" pivot_y="%s" />'
                     % (f["n"], sym, f["img"], f["w"], f["h"], fmt(px), fmt(py)))
        L.append('\t</folder>')
    interval = max(1, int(round(1000.0 / anim["framerate"]))) if anim["framerate"] else 25
    length = len(frames) * interval
    L.append('\t<entity id="0" name="%s">' % entity)
    L.append('\t\t<animation id="0" name="%s" length="%d" interval="%d">' % (anim["name"], length, interval))
    # 时间轴
    for ti, nm in enumerate(names):
        L.append('\t\t\t<timeline id="%d" name="%s">' % (ti, nm))
        for kid, (idx, els) in enumerate(frames):
            e = els[ti]
            sx, sy, ang = decompose(e["a"], e["b"], e["c"], e["d"])
            L.append('\t\t\t\t<key id="%d" time="%d" spin="0" curve_type="instant">' % (kid, kid * interval))
            L.append('\t\t\t\t\t<object folder="%d" file="%d" x="%s" y="%s" scale_x="%s" scale_y="%s" angle="%s" />'
                     % (fid[e["sym"]], e["bframe"], fmt(e["tx"]), fmt(-e["ty"]), fmt(sx), fmt(sy), fmt(ang)))
            L.append('\t\t\t\t</key>')
        L.append('\t\t\t</timeline>')
    # mainline
    L.append('\t\t\t<mainline>')
    for kid, (idx, els) in enumerate(frames):
        L.append('\t\t\t\t<key id="%d" time="%d">' % (kid, kid * interval))
        for ti, e in enumerate(els):
            L.append('\t\t\t\t\t<object_ref id="%d" timeline="%d" key="%d" z_index="%d" name="%s" />'
                     % (ti, ti, kid, e["z"], names[ti]))
        L.append('\t\t\t\t</key>')
    L.append('\t\t\t</mainline>')
    L.append('\t\t</animation>')
    L.append('\t</entity>')
    L.append('</spriter_data>')
    return "\n".join(L) + "\n", names


def copy_images(syms, srcdir, outdir, log=print, blank_fix=True):
    """把 PNG 按符号放进子文件夹；源里空白(占位)的按 build.xml 声明尺寸生成空图"""
    from pnglib import Image, write_png, read_png
    import struct
    made_blank = []
    for sym, frs in syms:
        d = os.path.join(outdir, sym)
        os.makedirs(d, exist_ok=True)
        for f in frs:
            src = os.path.join(srcdir, f["img"] + ".png")
            dst = os.path.join(d, f["img"] + ".png")
            need = True
            if os.path.exists(src):
                raw = open(src, "rb").read(33)
                w, h = struct.unpack(">II", raw[16:24])
                if (w, h) == (f["w"], f["h"]):
                    shutil.copy2(src, dst)
                    need = False
                else:
                    im = read_png(src)
                    # 源图有内容但不是声明尺寸 → 缩放到声明尺寸（最近邻）
                    out = Image(f["w"], f["h"])
                    for y in range(f["h"]):
                        sy = min(im.h - 1, y * im.h // f["h"])
                        for x in range(f["w"]):
                            sx = min(im.w - 1, x * im.w // f["w"])
                            i = (sy * im.w + sx) * 4
                            j = (y * f["w"] + x) * 4
                            out.px[j:j + 4] = im.px[i:i + 4]
                    write_png(dst, out)
                    made_blank.append((f["img"], (w, h), (f["w"], f["h"]), "缩放"))
                    need = False
            if need:
                write_png(dst, Image(f["w"], f["h"]))
                made_blank.append((f["img"], None, (f["w"], f["h"]), "空图"))
    return made_blank


if __name__ == "__main__":
    src = sys.argv[1]
    out = sys.argv[2]
    syms = parse_build(os.path.join(src, "build.xml"))
    anim = parse_anim(os.path.join(src, "animation.xml"))
    scml, names = build_scml(syms, anim)
    os.makedirs(out, exist_ok=True)
    name = os.path.basename(os.path.normpath(out))
    open(os.path.join(out, name + ".scml"), "w", encoding="utf-8").write(scml)
    blanks = copy_images(syms, src, out)
    print("符号 %d 个 / 时间轴 %d 条 / %d 帧 → %s" % (len(syms), len(names), len(anim["frames"]), out))
    if blanks:
        print("  占位/缩放 %d 张：" % len(blanks))
        for b in blanks[:12]:
            print("   ", b)
