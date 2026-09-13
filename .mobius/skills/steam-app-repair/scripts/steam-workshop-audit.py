#!/usr/bin/env python3
"""Steam 创意工坊体检 —— 一条命令看清「为什么下载卡死 / 哪个盘要被撑爆」。

用法（Windows git-bash 或任意 python）：
    python scripts/steam-workshop-audit.py 431960
    python scripts/steam-workshop-audit.py 431960 --staging-top 10

431960 = Wallpaper Engine（实测样本：163 个暂存条目 / 19 G，只有 2 个装完）。

输出：每个 Steam 库的 暂存(downloads) vs 已安装(content) 条目数与大小、
订阅总数（从 appworkshop_<appid>.acf 数 "manifest"，别数行——嵌套键会翻十倍）、
各盘剩余空间、以及最占地方的暂存条目（可删候选）。

只读，不改任何东西。
"""
import os
import re
import shutil
import sys

CANDIDATE_ROOTS = [
    r"C:\Program Files (x86)\Steam",
    r"C:\Program Files\Steam",
    r"D:\Steam",
    r"D:\SteamLibrary",
]


def steam_root():
    # 先看注册表（最准）
    try:
        import winreg
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Valve\Steam") as k:
            p, _ = winreg.QueryValueEx(k, "SteamPath")
            if p and os.path.isdir(p):
                return p.replace("/", "\\")
    except Exception:
        pass
    for p in CANDIDATE_ROOTS:
        if os.path.isdir(os.path.join(p, "steamapps")):
            return p
    return None


def libraries(root):
    """返回所有 Steam 库根目录（含 root 自身）。"""
    libs = [root]
    vdf = os.path.join(root, "steamapps", "libraryfolders.vdf")
    if os.path.isfile(vdf):
        txt = open(vdf, encoding="utf-8", errors="replace").read()
        for m in re.finditer(r'"path"\s*"([^"]+)"', txt):
            p = m.group(1).replace("\\\\", "\\")
            if p not in libs and os.path.isdir(p):
                libs.append(p)
    return libs


def du(path):
    total = 0
    for dirpath, _dirnames, filenames in os.walk(path):
        for f in filenames:
            try:
                total += os.path.getsize(os.path.join(dirpath, f))
            except OSError:
                pass
    return total


def mb(n):
    return f"{n / 1048576:.1f} MB" if n < 1073741824 else f"{n / 1073741824:.2f} GB"


def count_manifest(acf):
    """订阅总数：数 '"manifest"' 出现次数（每个订阅项一条）。
    不要数 WorkshopItemDetails 区块里的行数 —— 有嵌套键，会翻十倍。"""
    if not os.path.isfile(acf):
        return None
    txt = open(acf, encoding="utf-8", errors="replace").read()
    return txt.count('"manifest"')


def appmanifest_state(acf):
    if not os.path.isfile(acf):
        return None
    txt = open(acf, encoding="utf-8", errors="replace").read()
    out = {}
    for key in ("StateFlags", "SizeOnDisk", "LastUpdated", "buildid"):
        m = re.search(r'"%s"\s*"([^"]*)"' % key, txt)
        if m:
            out[key] = m.group(1)
    return out


def main():
    if len(sys.argv) < 2 or not sys.argv[1].isdigit():
        print(__doc__)
        return 2
    appid = sys.argv[1]
    top = 10
    if "--staging-top" in sys.argv:
        i = sys.argv.index("--staging-top")
        try:
            top = int(sys.argv[i + 1])
        except (IndexError, ValueError):
            pass

    root = steam_root()
    if not root:
        print("!! 找不到 Steam 安装目录，手动传路径")
        return 1
    print(f"Steam 根目录: {root}\n")

    grand_stage = grand_content = 0
    for lib in libraries(root):
        sa = os.path.join(lib, "steamapps")
        stage = os.path.join(sa, "workshop", "downloads", appid)
        content = os.path.join(sa, "workshop", "content", appid)
        acf = os.path.join(sa, "workshop", f"appworkshop_{appid}.acf")
        drive = os.path.splitdrive(lib)[0] or "C:"

        print(f"=== 库 {lib}  (盘 {drive}) ===")
        try:
            u = shutil.disk_usage(os.path.splitdrive(lib)[0] + "\\")
            print(f"  盘剩余: {mb(u.free)} / 共 {mb(u.total)}")
        except OSError:
            pass

        for label, path in (("暂存 downloads", stage), ("已装 content", content)):
            if os.path.isdir(path):
                items = sorted(os.listdir(path))
                size = du(path)
                if label.startswith("暂存"):
                    grand_stage += size
                else:
                    grand_content += size
                print(f"  {label}: {len(items)} 个条目 / {mb(size)}")
            else:
                print(f"  {label}: (无)")
                items = []
                size = 0

        subs = count_manifest(acf)
        st = appmanifest_state(os.path.join(sa, f"appmanifest_{appid}.acf"))
        if subs is not None:
            print(f"  订阅总数(数 manifest): {subs}")
        if st:
            print(f"  appmanifest: StateFlags={st.get('StateFlags')} "
                  f"(4=Fully Installed)  SizeOnDisk={st.get('SizeOnDisk')}")

        # 卡死判据
        if os.path.isdir(stage) and os.path.isdir(content):
            if len(os.listdir(stage)) > 5 * max(1, len(os.listdir(content))):
                print("  ★ 暂存条目远多于已装条目 → 卡在「下载→暂存」，"
                      "先看这盘的剩余空间（多半是盘满）")

        # 最占地方的暂存条目 = 清理候选
        if os.path.isdir(stage) and top:
            sizes = []
            for it in os.listdir(stage):
                p = os.path.join(stage, it)
                if os.path.isdir(p):
                    sizes.append((du(p), it))
            sizes.sort(reverse=True)
            if sizes:
                print(f"  暂存大头（前 {min(top, len(sizes))}，删掉后 Steam 会重排）:")
                for s, it in sizes[:top]:
                    print(f"    {mb(s):>10}  {it}")
        print()

    print(f"合计: 暂存 {mb(grand_stage)} / 已装 {mb(grand_content)}")
    if grand_stage > grand_content * 5:
        print("→ 暂存远大于已装：按 skill 的处理顺序走"
              "（暂停下载 → 移库 → 清暂存 → 砍订阅）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
