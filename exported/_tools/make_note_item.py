"""便签「地上/手中」形态素材：一卷系着绳的纸（小尺寸，给世界里的道具用）。

为什么要新做：原 anim/musha_note.zip 里只有 UI 那套（1800x1011 的底纸 + 9 行文字），
没有 idle 动画 → prefab 里 PlayAnimation("idle") 对不上 → 便签掉地上是空白。
本脚本产出：
  exported/musha_note_item/musha_note_item.png    64x64 卷纸（1 帧）
  exported/musha_note_item/musha_note_item.scml   bank/build = musha_note_item，动画 idle（timeline 名 swap_object → 拿在手里也能显示）
  exported/musha_note_item/musha_note_item.zip    DST Mod Tool 的工程包（build.xml + animation.xml + png）
  _tools/_test_out/note_item_preview.png          4 倍放大预览（给用户看）

用法：python make_note_item.py
"""
import os, sys, zipfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pnglib import Image, write_png

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.normpath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(MOD, "exported", "musha_note_item")
W = H = 64

PAPER = (232, 224, 203)
PAPER_HI = (246, 241, 226)
PAPER_SH = (203, 194, 172)
ROLL = (214, 205, 183)
ROLL_SH = (186, 177, 156)
SPIRAL = (152, 143, 124)
FLAP = (240, 234, 219)
TIE = (168, 86, 64)
TIE_SH = (132, 62, 46)
LINE = (44, 38, 30)

canvas = Image(W, H)


def setpx(x, y, c, a=255):
    if 0 <= x < W and 0 <= y < H:
        i = (y * W + x) * 4
        canvas.px[i:i + 4] = bytes((c[0], c[1], c[2], a))


def rect(x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            setpx(x, y, c)


def ellipse(cx, cy, rx, ry, c):
    for y in range(int(cy - ry), int(cy + ry) + 1):
        for x in range(int(cx - rx), int(cx + rx) + 1):
            dx = (x - cx) / float(rx)
            dy = (y - cy) / float(ry)
            if dx * dx + dy * dy <= 1.0:
                setpx(x, y, c)


def ring_arc(cx, cy, rx, ry, t0, t1, c):
    import math
    n = max(12, int((t1 - t0) * 24))
    for k in range(n + 1):
        t = t0 + (t1 - t0) * k / float(n)
        setpx(int(round(cx + rx * math.cos(t))), int(round(cy + ry * math.sin(t))), c)


CY = 32
# ① 卷筒主体（横躺）
rect(16, 24, 47, 40, PAPER)
ellipse(16, CY, 3.2, 8.4, PAPER)
ellipse(47, CY, 3.2, 8.4, PAPER)
# ② 两端卷面（横截面圆 + 螺旋线）
ellipse(16, CY, 4.0, 8.6, ROLL)
ring_arc(16, CY, 2.9, 6.4, -1.25, 2.4, SPIRAL)
ring_arc(16, CY, 1.5, 3.4, 1.9, 5.6, SPIRAL)
ellipse(47, CY, 4.0, 8.6, ROLL)
ring_arc(47, CY, 2.9, 6.4, 1.9, 5.6, SPIRAL)
ring_arc(47, CY, 1.5, 3.4, -1.25, 2.4, SPIRAL)
# ③ 右侧露出的纸角
rect(47, 26, 54, 36, FLAP)
ellipse(54, 31, 2.4, 5.4, FLAP)
# ④ 明暗（上亮下暗）
for x in range(17, 48):
    setpx(x, 25, PAPER_HI); setpx(x, 26, PAPER_HI)
    setpx(x, 39, PAPER_SH); setpx(x, 40, PAPER_SH)
for y in range(26, 40):
    setpx(17, y, PAPER_HI)
    setpx(47, y, PAPER_SH)
# ⑤ 系绳（中间一道）
rect(29, 22, 34, 42, TIE)
rect(34, 22, 34, 42, TIE_SH)
for y in range(22, 43):          # 绳的左右描边
    setpx(28, y, LINE); setpx(35, y, LINE)
setpx(29, 22, TIE_SH); setpx(29, 42, TIE_SH); setpx(34, 42, TIE_SH)
# 绳结
rect(30, 26, 33, 29, TIE_SH)
setpx(30, 26, TIE); setpx(33, 26, TIE); setpx(30, 29, TIE); setpx(33, 29, TIE)
# ⑥ 自动描边（贴着透明处的实体像素画 1px 深色）
snapshot = [(canvas.px[(y * W + x) * 4 + 3] > 0) for y in range(H) for x in range(W)]
for y in range(H):
    for x in range(W):
        if snapshot[y * W + x]:
            continue
        near = False
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                X, Y = x + dx, y + dy
                if 0 <= X < W and 0 <= Y < H and snapshot[Y * W + X]:
                    near = True; break
            if near:
                break
        if near:
            setpx(x, y, LINE)

os.makedirs(OUT, exist_ok=True)
png = os.path.join(OUT, "musha_note_item.png")
write_png(png, canvas)
print("贴图：", png, "%dx%d" % (W, H))

# ── scml（bank/build 名 = 文件名 musha_note_item；动画 idle；timeline 名 swap_object）──
SCML = '''<?xml version="1.0" encoding="UTF-8"?>
<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="r11">
 <folder id="0" name="musha_note_item">
  <file id="0" name="musha_note_item.png" width="{w}" height="{h}" pivot_x="0.5" pivot_y="0.5" />
 </folder>
 <entity id="0" name="musha_note_item">
  <animation id="0" name="idle" length="1000" interval="100">
   <mainline>
    <key id="0" time="0">
     <object_ref id="0" timeline="0" key="0" z_index="0" name="swap_object" />
    </key>
   </mainline>
   <timeline id="0" name="swap_object">
    <key id="0" time="0" spin="0">
     <object folder="0" file="0" scale_x="1" scale_y="1" />
    </key>
   </timeline>
  </animation>
 </entity>
</spriter_data>
'''.format(w=W, h=H)
scml = os.path.join(OUT, "musha_note_item.scml")
open(scml, "w", encoding="utf-8").write(SCML)
print("工程(scml)：", scml)

BUILD = '''<Build name="musha_note_item.scml">
 <Symbol name="symbol0">
  <Frame framenum="0" duration="1" image="musha_note_item" w="{w}" h="{h}" x="0.000000" y="0.000000"/>
 </Symbol>
</Build>
'''.format(w=W, h=H)
ANIM = '''<Anims>
 <anim name="idle" root="musha_note_item" numframes="1000" framerate="40">
  <frame idx="0" w="{w}" h="{h}" x="0.000000" y="0.000000">
   <element name="symbol0" layername="swap_object" frame="0" z_index="1" m_a="1.000000" m_b="0.000000" m_c="0.000000" m_d="1.000000" m_tx="0.000000" m_ty="0.000000"/>
  </frame>
 </anim>
</Anims>
'''.format(w=W, h=H)
zp = os.path.join(OUT, "musha_note_item.zip")
with zipfile.ZipFile(zp, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("build.xml", BUILD)
    z.writestr("animation.xml", ANIM)
    z.write(png, "musha_note_item.png")
print("工程包(zip)：", zp)

# ── 4 倍放大预览 ──
S = 4
prev = Image(W * S, H * S)
for y in range(H * S):
    for x in range(W * S):
        i = ((y // S) * W + (x // S)) * 4
        j = (y * W * S + x) * 4
        v = 100 if ((x // 8) + (y // 8)) % 2 == 0 else 132
        if canvas.px[i + 3] == 0:
            prev.px[j:j + 3] = bytes((v, v, v + 4))
        else:
            prev.px[j:j + 3] = canvas.px[i:i + 3]
        prev.px[j + 3] = 255
pv = os.path.join(HERE, "_test_out", "note_item_preview.png")
write_png(pv, prev)
print("预览(4x)：", pv)

# ── 控制台 ASCII 自检 ──
print("\n形状自检（#=纸 o=卷面 =绳 .=描边）:")
for y in range(18, 46):
    row = []
    for x in range(8, 58):
        i = (y * W + x) * 4
        if canvas.px[i + 3] == 0:
            row.append(" ")
        else:
            c = tuple(canvas.px[i:i + 3])
            row.append("." if c == LINE else ("o" if c in (ROLL, ROLL_SH, SPIRAL) else ("=" if c in (TIE, TIE_SH) else "#")))
    print("   " + "".join(row))
