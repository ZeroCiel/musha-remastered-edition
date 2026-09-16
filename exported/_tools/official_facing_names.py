"""把 crescent 的 scml 动画名改成**官方多面向命名**（图不动，只改名字）

官方规则（来源：Don't Starve Mod Tools/mod_tools/tools/scripts/buildanimation.py）：
  ANIM 格式 v4 每条动画 = [名字][朝向位掩码 1 字节][root符号][帧率][帧...]
  编译器**按名字后缀自动算掩码**，并把后缀从名字里去掉：
      _up/_down/_side/_left/_right/_upside/_downside
      _upleft/_upright/_downleft/_downright/_45s/_90s（无后缀 = 全 8 向）
  位掩码：RIGHT=1<<0, UP=1<<1, LEFT=1<<2, DOWN=1<<3,
          UPRIGHT=1<<4, UPLEFT=1<<5, DOWNRIGHT=1<<6, DOWNLEFT=1<<7

本脚本做的事：anim_0..anim_7 → slash_<朝向>，别的（folder/file/pivot/帧长）原样保留。
命名对应关系（我们的素材：dir k = 世界角 k×45°，+X 起往 +Z；已做"世界→屏幕"投影）：
    dir0(+X)      → slash_downright
    dir1(+X+Z)    → slash_down
    dir2(+Z)      → slash_downleft
    dir3(-X+Z)    → slash_left
    dir4(-X)      → slash_upleft
    dir5(-X-Z)    → slash_up
    dir6(-Z)      → slash_upright
    dir7(+X-Z)    → slash_right
  （口径：屏幕向下的那条 = 世界 +X+Z = dir1；屏幕向右 = 世界 +X-Z = dir7。
    引擎按 Transform 旋转挑面；若实测整圈偏了，改 lua 里的 FX_ROT_OFFSET，不用重导素材。）

跑法：python official_facing_names.py
"""
import os
import re
import shutil

MOD = r"D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\musha"
TARGETS = [
    os.path.join(MOD, "exported", "crescent_moon", "crescent_cyan8.scml"),
    os.path.join(MOD, "exported", "crescent_cyan", "crescent_cyan8.scml"),
]
# dir k → 官方朝向后缀（顺序不能乱，见文件头口径）
FACING = ["downright", "down", "downleft", "left", "upleft", "up", "upright", "right"]
BASE = "slash"


def convert(path):
    src = open(path, encoding="utf-8").read()
    if "slash_" in src:
        print("  已经改过，跳过：", path)
        return False
    bak = os.path.join(os.path.dirname(path), "_bak_scml_anim0_20260916.scml")
    if not os.path.exists(bak):
        shutil.copy2(path, bak)
    out = src
    # timeline 名与 anim 名同步（纯标签，随动画走就行）
    for k, f in enumerate(FACING):
        out = out.replace('name="anim_%d"' % k, 'name="%s_%s"' % (BASE, f))
        out = re.sub(r'(<animation[^>]*name="%s_%s"[^>]*>.*?</animation>)' % (BASE, f),
                     lambda m: m.group(1), out, flags=re.S)
    open(path, "w", encoding="utf-8").write(out)
    print("  改好：", path)
    return True


for t in TARGETS:
    if os.path.exists(t):
        convert(t)
    else:
        print("  缺文件：", t)

# 自检：把改完的 scml 里的 anim 名列出来
for t in TARGETS:
    if not os.path.exists(t):
        continue
    s = open(t, encoding="utf-8").read()
    names = re.findall(r'<animation id="\d+" name="([^"]+)"', s)
    print("  %s → %s" % (os.path.basename(os.path.dirname(t)), names))
