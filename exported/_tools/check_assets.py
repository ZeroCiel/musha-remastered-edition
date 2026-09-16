"""发布前自检：所有 Asset("类型","路径") 声明的文件是否真的存在。

为什么需要：DST 在 RegisterPrefabs 阶段解析 Asset 路径，**文件缺失 = assert 失败 = 整个 mod 被禁**
（2026-09-14 生命树枝、2026-09-16 便签，两次都是这个坑）。
把这段当发布前例行检查跑一遍，能提前拦住"一进游戏 mod 就被禁用"。

判定口径：
  · ANIM  → .zip 若在原版 data/anim/ 里（statue_maxwell / swap_spear / tome…）算通过
  · ATLAS/IMAGE → 必须在本 mod 目录里存在
  · 路径里有 ".."（运行时拼接）→ 跳过（例：anim/ghost_ .. Character .. _build.zip）
  · 已注掉的行（--）→ 跳过
  · 脚本只报"疑似缺"，会明确打印原因，人工过一眼

用法：python exported/_tools/check_assets.py
"""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.normpath(os.path.join(HERE, "..", ".."))
GAME = os.path.normpath(os.path.join(MOD, "..", ".."))   # mushа/.. = mods，再 .. = 游戏根目录

def strip_comments(t):
    return "\n".join((l if l.find("--") < 0 else l[:l.find("--")]) for l in t.split("\n"))

PAT = re.compile(r'Asset\(\s*"(ANIM|ATLAS|IMAGE|SOUND)"\s*,\s*"([^"]+)"')

def collect():
    srcs = [os.path.join(MOD, "modmain.lua")]
    pdir = os.path.join(MOD, "scripts", "prefabs")
    if os.path.isdir(pdir):
        srcs += [os.path.join(pdir, f) for f in sorted(os.listdir(pdir)) if f.endswith(".lua")]
    rows = []
    for s in srcs:
        t = strip_comments(open(s, encoding="utf-8", errors="replace").read())
        for m in PAT.finditer(t):
            kind, path = m.group(1), m.group(2)
            if ".." in path or "." not in os.path.basename(path):
                continue          # 运行时拼接的片段（如 "anim/ghost_"）、无扩展名 → 跳过
            rows.append((os.path.relpath(s, MOD), kind, path))
    return rows

def main():
    # 原版 anim 素材：data/anim/ 里的散包 + databundles 里打进去的（statue_maxwell 等在里面）
    vanilla_anim = set()
    import zipfile
    adir = os.path.join(GAME, "data", "anim")
    if os.path.isdir(adir):
        vanilla_anim |= set(os.listdir(adir))
    for bundle in ("anim_dynamic.zip", "anim.zip"):
        bp = os.path.join(GAME, "data", "databundles", bundle)
        if os.path.exists(bp):
            try:
                with zipfile.ZipFile(bp) as z:
                    vanilla_anim |= {os.path.basename(n) for n in z.namelist() if n.endswith(".zip")}
            except Exception:
                pass
    # 在 PrefabFiles 里出现的 prefab = 会被加载；其余属死文件，缺素材不影响启动
    modmain = open(os.path.join(MOD, "modmain.lua"), encoding="utf-8", errors="replace").read()
    m = re.search(r"PrefabFiles\s*=\s*\{(.*?)\}", modmain, re.S)
    loaded = set(re.findall(r'"([^"]+)"', m.group(1))) if m else set()

    rows = collect()
    real, dead = [], []
    for src, kind, path in rows:
        if os.path.exists(os.path.join(MOD, path.replace("/", os.sep))):
            continue
        if kind == "ANIM" and os.path.basename(path) in vanilla_anim:
            continue
        name = os.path.basename(src)[:-4]
        (dead if (name not in loaded and name != "modmain") else real).append((src, kind, path))

    print("Asset 声明 %d 处" % len(rows))
    print("★ 需要处理（所属 prefab 会被加载）：%d 处" % len(real))
    for r in real:
        print("    %-38s %-6s %s" % r)
    print("  说明：若这些文件已经用 asset_exists()/softresolvefilepath 做过自检，可忽略（见 mushа_note.lua / mushа_lifebranch.lua）")
    if dead:
        print("（不影响启动：所属 prefab 不在 PrefabFiles 里 = 死文件，共 %d 处）" % len(dead))
        for r in dead:
            print("    %-38s %-6s %s" % r)

main()
