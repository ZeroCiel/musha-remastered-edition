#!/usr/bin/env python3
"""墙内找参考图 / 取参考色 —— 不依赖任何代理，只走国内可达站点。

用途：用户说「你去找找 <某个参考物>」要一个颜色/一张参考图时，代理栈挂了也要能干活。

用法：
    python cn_bing_images.py "日本 彩虹糖果 插画"            # 搜索 + 下载 + 打印主色
    python cn_bing_images.py "七色飴 イラスト" "金太郎飴"     # 多关键词轮流试

输出：每个关键词命中数、下载到的图片路径、该图的主色 hex 占比（需要 Pillow）。

已验证的墙内可达性（本机实测）：
    baidu.com / cn.bing.com / image.baidu.com  -> 200
    google.com / www.bing.com                  -> 000（直连被墙，代理没开时不通）
"""
import os
import re
import ssl
import sys
import urllib.parse
import urllib.request
from collections import Counter

ssl._create_default_https_context = ssl._create_unverified_context

UA = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36",
    "Accept-Language": "zh-CN,zh;q=0.9,ja;q=0.8",
}


def bing_images(query, first=1):
    """cn.bing.com 图片搜索 -> 原图 URL 列表。HTML 里 murl&quot;:&quot;<url>&quot;。"""
    url = (
        "https://cn.bing.com/images/search?q="
        + urllib.parse.quote(query)
        + f"&form=HDRSC2&first={first}"
    )
    req = urllib.request.Request(url, headers=UA)
    html = urllib.request.urlopen(req, timeout=25).read().decode("utf-8", "ignore")
    urls = re.findall(r"murl&quot;:&quot;(.*?)&quot;", html)
    if not urls:
        urls = re.findall(r'"murl":"(.*?)"', html)
    return [u.replace("\\/", "/") for u in urls]


def dominant_colors(path, bins=6, box=150):
    """量化主色。返回 [(r,g,b,percent), ...]；没装 Pillow 返回 None。"""
    try:
        from PIL import Image
    except Exception:
        return None
    try:
        im = Image.open(path).convert("RGB")
        im.thumbnail((box, box))
        px = list(im.getdata())
        q = Counter((r // 24 * 24, g // 24 * 24, b // 24 * 24) for r, g, b in px)
        total = len(px)
        return [(r, g, b, c * 100 // total) for (r, g, b), c in q.most_common(bins)]
    except Exception:
        return None


def main():
    queries = sys.argv[1:] or ["彩虹糖果 插画"]
    outdir = os.path.join(os.path.expanduser("~"), "web_ref_images")
    os.makedirs(outdir, exist_ok=True)

    for q in queries:
        print("=" * 8, q)
        try:
            urls = bing_images(q)
        except Exception as e:
            print("  search ERR", repr(e)[:120])
            continue
        print("  hits:", len(urls))
        got = 0
        for u in urls:
            if got >= 3:
                break
            try:
                data = urllib.request.urlopen(
                    urllib.request.Request(u, headers=UA), timeout=20
                ).read()
                if len(data) < 3000:          # 缩略图/占位图跳过
                    continue
                p = os.path.join(outdir, f"{abs(hash(u)) % 10 ** 8}.img")
                with open(p, "wb") as f:
                    f.write(data)
                cols = dominant_colors(p)
                tag = ""
                if cols:
                    tag = " | " + " ".join(
                        f"#{r:02X}{g:02X}{b:02X}({pct}%)" for r, g, b, pct in cols
                    )
                print(f"  {p} {len(data)}B{tag}")
                got += 1
            except Exception:
                continue          # 单个图挂了不影响整体


if __name__ == "__main__":
    main()
