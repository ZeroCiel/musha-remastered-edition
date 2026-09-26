# 2026-09-27：只读比对 —— 干净底图（贴叉前）vs 现役底图（贴叉后）
# 目的：确认两者只差"右上烤叉"这一块，若成立 → 直接回滚干净底图 = 去掉左边那个红叉
import sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
from PIL import Image, ImageChops

HERE = os.path.dirname(os.path.abspath(__file__))
CLEAN = os.path.join(HERE, "_art_backup", "panel_bg_alt_20260926_060807", "panel_bg_alt.png")
CUR = os.path.join(HERE, "..", "..", "images", "panel_bg_alt.png")

a = Image.open(CLEAN).convert("RGBA")
b = Image.open(CUR).convert("RGBA")
print("clean  :", a.size, os.path.getsize(CLEAN))
print("current:", b.size, os.path.getsize(CUR))
if a.size != b.size:
    print(">>> 尺寸不同，不能直接回滚")
    sys.exit(0)

diff = ImageChops.difference(a, b)
print("严格差异 bbox:", diff.getbbox())

# 容差 8 以内的差异（抗锯齿/压缩噪声）
g = diff.convert("L").point(lambda p: 255 if p > 8 else 0)
print("容差外差异 bbox:", g.getbbox())

TMP = os.path.join(HERE, "_tmp")
os.makedirs(TMP, exist_ok=True)
box = (1280, 0, 1741, 320)   # 右上角
a.crop(box).save(os.path.join(TMP, "qc_x_corner_clean.png"))
b.crop(box).save(os.path.join(TMP, "qc_x_corner_current.png"))
print("已存对照裁图: _tmp/qc_x_corner_clean.png / qc_x_corner_current.png")
