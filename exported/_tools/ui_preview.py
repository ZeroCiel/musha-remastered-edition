#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ui_preview.py — Musha 面板 UI 离线预览器（不进游戏看 UI）

用法：
  python ui_preview.py                 # 开小窗口（监听 spec 文件，保存即自动重渲染）
  python ui_preview.py --export x.png  # 无头渲染一张 PNG（给视觉模型审图用）
  python ui_preview.py --export x.png --debug   # 带图标位置十字标注

口径：
  · 规格唯一真源 = panel_layout.json（元素/坐标/尺寸；坐标单位 = 底图像素，原点左上）
  · 每次渲染自动镜像一份 panel_layout.lua（扁平 key=value），供 musha_panel_screen.lua
    定稿后 dofile 接线——游戏和预览读同一份，不会两套口径。
  · 图标：inventoryimages 的 png 直接读；tex 用 tex2png 解码。
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SPEC = os.path.join(HERE, "panel_layout.json")
LUA_MIRROR = os.path.join(HERE, "panel_layout.lua")
FONT = r"C:\Windows\Fonts\msyh.ttc"


def load_spec():
    with open(SPEC, encoding="utf-8") as f:
        return json.load(f)


def resolve_image(spec_root, ref):
    """ref: 相对 mod 根的资源路径（png 直接读；tex 用 tex2png 解码）"""
    mod = os.path.normpath(os.path.join(HERE, "..", ".."))
    p = os.path.join(mod, ref.replace("/", os.sep))
    if p.lower().endswith(".png") and os.path.exists(p):
        return Image.open(p).convert("RGBA")
    if p.lower().endswith(".tex") and os.path.exists(p):
        base = os.path.join(HERE, "_tmp")
        os.makedirs(base, exist_ok=True)
        tmp = os.path.join(base, os.path.basename(p).replace(".tex", ".png"))
        if not os.path.exists(tmp) or os.path.getmtime(tmp) < os.path.getmtime(p):
            sys.path.insert(0, r"C:\Users\Administrator\AppData\Local\hermes\skills\gaming\dst-art-pipeline\scripts")
            import tex2png
            bb, w, h = tex2png.tex_info(p)
            cands = sorted(tex2png._guess_format(len(bb), w, h), key=lambda c: (c[1] != "dxt5", -c[0]))
            count, kind, entry, hdrlen = cands[0]
            sizes = tex2png._mip_sizes(w, h, count, kind)
            data = bb[hdrlen:hdrlen + sizes[0]]
            if kind == "dxt5":
                rgba = tex2png.decode_dxt5(data, w, h, False)
            elif kind == "dxt3":
                rgba = tex2png.decode_dxt3(data, w, h, False)
            elif kind == "dxt1":
                rgba = tex2png.decode_dxt1(data, w, h, False)
            else:
                rgba = tex2png.decode_raw(data, w, h, 4, False)
            out = Image.frombytes("RGBA", (w, h), bytes(rgba))
            out.save(tmp)
            return out
    return None


def render(spec, debug=False):
    bg_ref = spec.get("bg", "images/panel_bg_alt.png")
    bg = resolve_image(spec, bg_ref)
    if bg is None:
        raise SystemExit("底图不存在: " + bg_ref)
    canvas = bg.copy()
    d = ImageDraw.Draw(canvas)

    def to_screen(pt):
        s = spec.get("scale", 1.0)
        return (round(pt[0] * s), round(pt[1] * s))

    for el in spec.get("elements", []):
        name = el.get("name", "?")
        kind = el.get("kind", "image")
        x, y = to_screen(el["pos"])
        if kind == "image":
            img = resolve_image(spec, el.get("tex", ""))
            if img is None:
                d.rectangle([x - 20, y - 20, x + 20, y + 20], outline=(255, 0, 255, 255), width=2)
                continue
            size = el.get("size")
            if size:
                size = to_screen(size)
                img = img.resize((max(1, size[0]), max(1, size[1])), Image.LANCZOS)
            anchor = el.get("anchor", "center")
            ax = {"left": 0, "center": img.width // 2, "right": img.width}[anchor]
            ay = {"top": 0, "center": img.height // 2, "bottom": img.height}[el.get("valign", anchor)]
            canvas.alpha_composite(img, (x - ax, y - ay))
        elif kind == "text":
            txt = el.get("text", name)
            fs = to_screen([el.get("size", 28), 0])[0]
            f = ImageFont.truetype(FONT, max(10, fs)) if os.path.exists(FONT) else ImageFont.load_default()
            color = tuple(el.get("color", [250, 240, 210, 255]))
            d.text((x, y), txt, font=f, fill=color)
        elif kind == "rect":
            size = to_screen(el.get("size", [100, 20]))
            color = tuple(el.get("color", [120, 90, 50, 200]))
            d.rounded_rectangle([x, y, x + size[0], y + size[1]], radius=el.get("radius", 8), fill=color)
        elif kind == "rows":
            rows = el.get("rows", 6)
            size = to_screen(el.get("size", [660, 58]))
            gap = to_screen([el.get("gap", 14), 0])[0]
            for i in range(rows):
                ry = y + i * (size[1] + gap)
                d.rounded_rectangle([x, ry, x + size[0], ry + size[1]],
                                    radius=12, fill=tuple(el.get("color", [249, 242, 214, 235])),
                                    outline=(180, 150, 90, 255), width=2)
        if debug:
            d.line([x - 12, y, x + 12, y], fill=(255, 0, 255, 255), width=1)
            d.line([x, y - 12, x, y + 12], fill=(255, 0, 255, 255), width=1)
            f_s = ImageFont.truetype(FONT, 15) if os.path.exists(FONT) else ImageFont.load_default()
            d.text((x + 14, y - 22), name, font=f_s, fill=(255, 60, 255, 255))
    return canvas


def write_lua_mirror(spec):
    lines = ["-- 自动生成：python ui_preview.py（勿手改，真源 = panel_layout.json）", "return {"]
    for k, v in spec.items():
        if k == "elements":
            continue
        if isinstance(v, str):
            lines.append('    %s = "%s",' % (k, v))
        elif isinstance(v, list):
            lines.append("    %s = {%s}," % (k, ", ".join(str(n) for n in v)))
        else:
            lines.append("    %s = %s," % (k, v))
    for el in spec.get("elements", []):
        key = el.get("name", "?")
        if el.get("kind") == "image" and el.get("size"):
            lines.append("    %s_w = %d, %s_h = %d," % (key, el["size"][0], key, el["size"][1]))
        if el.get("pos"):
            lines.append("    %s_x = %d, %s_y = %d," % (key, el["pos"][0], key, el["pos"][1]))
    lines.append("}")
    open(LUA_MIRROR, "w", encoding="utf-8", newline="\n").write("\n".join(lines))


def main():
    args = sys.argv[1:]
    export = None
    debug = "--debug" in args
    if "--export" in args:
        export = args[args.index("--export") + 1]
    spec = load_spec()
    write_lua_mirror(spec)
    img = render(spec, debug=debug)
    if export:
        img.save(export)
        print("渲染 →", export, img.size)
        return 0
    import tkinter as tk
    from PIL import ImageTk
    root = tk.Tk()
    root.title("Musha UI 预览 — panel_layout.json 保存即刷新")
    state = {"mtime": os.path.getmtime(SPEC), "photo": None}
    cv = tk.Canvas(root, width=img.width, height=img.height, bg="#22242c", highlightthickness=0)
    cv.pack(fill="both", expand=True)
    bar = tk.Label(root, text="元素 %d 个 · 真源 panel_layout.json · 镜像 panel_layout.lua" % len(spec.get("elements", [])),
                   bg="#2e3038", fg="#9aa0ad", anchor="w")
    bar.pack(fill="x")

    def redraw():
        img2 = render(load_spec(), debug=debug)
        state["photo"] = ImageTk.PhotoImage(img2)
        cv.delete("all")
        cv.create_image(0, 0, image=state["photo"], anchor="nw")

    def poll():
        try:
            m = os.path.getmtime(SPEC)
            if m != state["mtime"]:
                state["mtime"] = m
                redraw()
                print("spec 变更 → 重渲染")
        except Exception as e:
            print("重渲染失败:", e)
        root.after(500, poll)

    redraw()
    poll()
    root.mainloop()
    return 0


if __name__ == "__main__":
    sys.exit(main())
