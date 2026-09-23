# -*- coding: utf-8 -*-
"""拟合 animation.xml 的 (a,b,c,d,tx,ty) → scml 的 (x,y,scale_x,scale_y,angle)"""
import os, re, math, sys
sys.path.insert(0, r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha\exported\_tools")
from musha_scml_render import load_scml

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
Z = r"C:\Users\Administrator\AppData\Local\Temp\clothv01"

ax = open(os.path.join(Z, "animation.xml"), encoding="utf-8").read()
frames = re.findall(r'<frame idx="(\d+)"[^>]*>(.*?)</frame>', ax, re.S)
print("animation.xml frame 数:", len(frames))
els0 = re.findall(r'<element name="([^"]+)" layername="([^"]*)" frame="(\d+)" z_index="(-?\d+)" '
                  r'm_a="([-0-9.eE]+)" m_b="([-0-9.eE]+)" m_c="([-0-9.eE]+)" m_d="([-0-9.eE]+)" '
                  r'm_tx="([-0-9.eE]+)" m_ty="([-0-9.eE]+)"', frames[0][1])
print("frame0 element 数:", len(els0))

folders, anims = load_scml(os.path.join(M, "exported", "musha", "musha.scml"))
aname = list(anims)[0]
a = anims[aname]
k0, layers0 = a["keys"][0]
print("scml key0 层数:", len(layers0))

# scml key0 的层按文档顺序 = mainline object_ref 顺序；动画里 order 应对应
bad = 0
err1 = err2 = 0.0
mirror = 0
for i, (name, lname, fr, z, A, B, C, D, TX, TY) in enumerate(els0[:len(layers0)]):
    A, B, C, D, TX, TY = map(float, (A, B, C, D, TX, TY))
    L = layers0[i] if i < len(layers0) else None
    if L is None:
        break
    sx1 = math.sqrt(A * A + B * B); sy1 = -math.sqrt(C * C + D * D)
    an1 = -math.degrees(math.atan2(B, A))
    e = max(abs(L["x"] - TX), abs(L["y"] - (-TY)), abs(L["sx"] - sx1), abs(L["sy"] - sy1),
            abs((L["ang"] - an1 + 180) % 360 - 180))
    err1 = max(err1, e)
    # 备选：angle 用 atan2(-C, D) ? 随便试一个
    an2 = math.degrees(math.atan2(-C, D))
    e2 = max(abs(L["sx"] - sx1), abs(L["sy"] - sy1), abs((L["ang"] - an2 + 180) % 360 - 180))
    err2 = max(err2, e2)
    det = A * D - B * C
    if det < 0:
        mirror += 1
    if e > 0.01:
        bad += 1
        if bad <= 6:
            print("  不匹配 #%d %s/%s scml(x=%.3f y=%.3f sx=%.4f sy=%.4f ang=%.3f)  拟合(x=%.3f y=%.3f sx=%.4f sy=%.4f ang=%.3f)"
                  % (i, name, lname, L["x"], L["y"], L["sx"], L["sy"], L["ang"], TX, -TY, sx1, sy1, an1))
print(f"\n公式1(sx=+√(a²+b²), sy=-√(c²+d²), ang=-atan2(b,a)) 最大误差 {err1:.6f}；不匹配 {bad}/{min(len(els0),len(layers0))}")
print(f"公式2 ang=atan2(-c,d) 最大误差 {err2:.6f}")
print(f"负行列式(镜像)元素数: {mirror}")
# 逐帧 element 结构一致性
for idx, body in frames[:5]:
    n = len(re.findall(r"<element ", body))
    names = [m[1] for m in re.findall(r'<element name="([^"]+)" layername="([^"]*)"', body)]
    print(f"  frame {idx}: {n} 层, 前5 layername {names[:5]}")
print("所有 frame 层数:", set(len(re.findall(r'<element ', b)) for _, b in frames))
seq = [tuple(m[1] for m in re.findall(r'<element name="([^"]+)" layername="([^"]*)"', b)) for _, b in frames]
print("所有 frame 的 layername 序列是否完全一致:", all(s == seq[0] for s in seq))
print("frame0 vs frame1 layername 不同的位置:",
      [i for i, (x, y) in enumerate(zip(seq[0], seq[1])) if x != y][:20])
dup = [n for n in set(seq[0]) if seq[0].count(n) > 1]
print("frame0 内重复的 layername:", dup)
print("frame0 唯一 layername 数:", len(set(seq[0])))
