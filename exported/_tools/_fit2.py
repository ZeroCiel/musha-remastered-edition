# -*- coding: utf-8 -*-
"""拟合：animation.xml 的 (a,b,c,d) → 参考工程 musha.scml 的 (sx,sy,angle) 用哪套公式"""
import os, re, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

M = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
SRC = r"C:\Users\Administrator\AppData\Local\Temp\clothv01"

ax = open(os.path.join(SRC, "animation.xml"), encoding="utf-8", errors="replace").read()
body0 = re.search(r'<frame idx="0"[^>]*>(.*?)</frame>', ax, re.S).group(1)
els = [tuple(map(float, m[4:10]))
       for m in re.findall(r'<element name="([^"]+)" layername="([^"]*)" frame="(\d+)" z_index="(-?\d+)" '
                           r'm_a="([-0-9.eE]+)" m_b="([-0-9.eE]+)" m_c="([-0-9.eE]+)" m_d="([-0-9.eE]+)" '
                           r'm_tx="([-0-9.eE]+)" m_ty="([-0-9.eE]+)"', body0)]
els = [(A, B, C, D) for (A, B, C, D, TX, TY) in els]
ref_txt = open(os.path.join(M, "exported", "musha", "musha.scml"), encoding="utf-8").read()
ref = []
for m in re.finditer(r'<timeline id="\d+" name="[^"]+">(.*?)</timeline>', ref_txt, re.S):
    k = re.search(r'<key id="0"[^>]*>\s*<object folder="\d+" file="\d+" x="[-0-9.eE]+" y="[-0-9.eE]+" '
                  r'scale_x="([-0-9.eE]+)" scale_y="([-0-9.eE]+)" angle="([-0-9.eE]+)"', m.group(1))
    if k:
        ref.append((float(k.group(1)), float(k.group(2)), float(k.group(3))))

def ad(x, y):
    return abs((x - y + 180) % 360 - 180)

ang_rules = {
    "-at2(c,a)": lambda A, B, C, D: -math.degrees(math.atan2(C, A)),
    "+at2(c,a)": lambda A, B, C, D: math.degrees(math.atan2(C, A)),
    "-at2(b,a)": lambda A, B, C, D: -math.degrees(math.atan2(B, A)),
    "+at2(b,a)": lambda A, B, C, D: math.degrees(math.atan2(B, A)),
    "-at2(-b,-a)": lambda A, B, C, D: -math.degrees(math.atan2(-B, -A)),
    "+at2(-c,-a)": lambda A, B, C, D: math.degrees(math.atan2(-C, -A)),
}
sx_rules = {"hypot(a,c)": lambda A, B, C, D: math.hypot(A, C),
            "hypot(a,b)": lambda A, B, C, D: math.hypot(A, B)}
sy_rules = {"-hypot(b,d)": lambda A, B, C, D: -math.hypot(B, D),
            "+hypot(b,d)": lambda A, B, C, D: math.hypot(B, D),
            "-hypot(c,d)": lambda A, B, C, D: -math.hypot(C, D),
            "+hypot(c,d)": lambda A, B, C, D: math.hypot(C, D),
            "-hypot(a,c)": lambda A, B, C, D: -math.hypot(A, C),
            "+hypot(a,c)": lambda A, B, C, D: math.hypot(A, C)}

print("元素 %d, ref %d" % (len(els), len(ref)))
best = []
for an, af in ang_rules.items():
    for xn, xf in sx_rules.items():
        for yn, yf in sy_rules.items():
            ok = sum(1 for (A, B, C, D), (rsx, rsy, rang) in zip(els, ref)
                     if ad(af(A, B, C, D), rang) < 0.05
                     and abs(xf(A, B, C, D) - rsx) < 0.002 and abs(yf(A, B, C, D) - rsy) < 0.002)
            best.append((ok, "ang=%s sx=%s sy=%s" % (an, xn, yn)))
best.sort(reverse=True)
for ok, name in best[:5]:
    print("  %3d/%d  %s" % (ok, len(els), name))

# 用最优组合细看不匹配的
ok0, name0 = best[0]
print("\n最优组合:", name0)
an, xn, yn = re.match(r"ang=(\S+) sx=(\S+) sy=(\S+)", name0).groups()
af, xf, yf = ang_rules[an], sx_rules[xn], sy_rules[yn]
bad = 0
for i, ((A, B, C, D), (rsx, rsy, rang)) in enumerate(zip(els, ref)):
    d = max(ad(af(A, B, C, D), rang), abs(xf(A, B, C, D) - rsx), abs(yf(A, B, C, D) - rsy))
    if d > 0.05:
        bad += 1
        if bad <= 5:
            print("  #%2d ref(ang=%8.3f sx=%.4f sy=%+.4f) 拟合(ang=%8.3f sx=%.4f sy=%+.4f) det=%+.3f a=%+.4f b=%+.4f c=%+.4f d=%+.4f"
                  % (i, rang, rsx, rsy, af(A, B, C, D), xf(A, B, C, D), yf(A, B, C, D), A * D - B * C, A, B, C, D))
print("  不匹配 %d/%d" % (bad, len(els)))
