# 代理栈全挂时的「国内检索」替代方案

场景：用户说「你去找找 X 的参考图 / 参考色」。此时 Clash Verge 没在跑、系统代理没开、
WARP 也没挂在代理模式 —— 海外直连全 `000`。但**国内站点通常是通的**，别直接回「查不到」。

## 一、先花一条命令判可达性（不要盲试）

```bash
for u in https://www.baidu.com https://cn.bing.com https://www.bing.com https://image.baidu.com; do
  printf "%s -> " "$u"; curl -s -m 8 -o /dev/null -w "%{http_code}\n" "$u"
done
```

实测（本机，无代理）：
- `www.baidu.com` / `cn.bing.com` / `image.baidu.com` → **200**（国内可用）
- `www.bing.com` / `google.com` → **000**（海外，代理没开就是不通）

顺手确认一遍没有隐藏代理可用（别只试一个端口）：

```bash
env | grep -i proxy                                     # 有没有 http_proxy 之类
tasklist | grep -iE 'clash|verge|mihomo|v2ray|sing-box|xray|warp'
netstat -ano | grep -i listening | grep -E ':(7890|7891|7897|1053|10808|10809|1080|40000)\b'
for p in socks5h://127.0.0.1:9410 http://127.0.0.1:9410 socks5h://127.0.0.1:40000 http://127.0.0.1:1080; do
  printf "%s -> " "$p"; curl -s -m 8 -o /dev/null -w "%{http_code}\n" -x "$p" https://www.google.com
done
```
注意：**只有 WARP 的 GUI 进程在跑 ≠ 有本地代理端口**。本机见过 `Cloudflare WARP.exe` + `warp-svc.exe`
在跑、`127.0.0.1:9410` 在 listen，但用 `-x` 指过去全是 `000` —— WARP 没开代理模式。
别把「进程在」当成「代理能用」，一定要用 `curl -x` 实测。

## 二、图片搜索：cn.bing.com 的 HTML 抓取（最稳）

`https://cn.bing.com/images/search?q=<urlencode>&form=HDRSC2` 返回的 HTML 里，每张结果都带原始图 URL：

- 形如 `murl&quot;:&quot;https://...&quot;`（HTML 实体转义）
- 少数情况是 `"murl":"https://..."`

正则两种都试：先 `murl&quot;:&quot;(.*?)&quot;`，没有再 `"murl":"(.*?)"`。
拿到的 URL 直接 `urllib`/`curl` 下载（带 UA），下完用 Pillow 量化主色。
**能抓到原图 URL**，所以可以「搜索→下载→取色」一条龙，不依赖任何 API key。

一句话版本：`python scripts/cn_bing_images.py "关键词1" "关键词2"`
（脚本已含搜索 + 下载 + 主色量化，`<3KB` 的缩略图会自动跳过。）

## 三、踩过的坑

- **百度图搜的 `acjson` 接口返回 0 条**：`https://image.baidu.com/search/acjson?tn=resultjson_com&word=...`
  在没有 cookie / 被反爬时 `data` 为空数组。**别在它上面耗时间**，直接换 cn.bing。
- **花瓣（huaban）图链直接 403/567**：`gd-hbimg.huaban.com` 走 urllib 会 `HTTP Error 567`。
- **关键词会被中文搜索引擎带偏**：搜「日本 彩虹糖果」出来的全是《永劫无间》宣传图和摄图网白底素材。
  → 换**日文原名**（七色飴 / 金太郎飴 / キャンディ イラスト）命中率更高；
  → 下载后一定要**看主色**（脚本已打印），色系明显不对就换词，别拿错参考硬套。
- **`delegate_task` 派子代理去联网搜会很慢**：本次带 `web`/`browser`/`vision` 的子代理 600s 超时、0 产出。
  网络本身可疑时，自己在 terminal 里用 curl/python 打国内站点更快。

## 四、拿不到就体面收场（用户偏好）

用户要的是颜色，不是搜索过程。查不到时**别空手回来**，给封闭选项：

1. 让他直接发参考图 / 给文件路径（最省事，优先提这条）
2. 让他给色号（`#F7C948` 这种）
3. 给 2–3 个候选色号 + 一句它们各自的感觉（偏亮/柔和/偏暗），让他挑

并**一句话说明为什么查不到**（哪些站点通了、哪些没通、搜出来的是什么），别长篇解释。

## 五、文本搜索：能用的 / 不能用的（实测）

- **百度 HTML 结果页可解析**：`https://www.baidu.com/s?wd=<urlencode>`，带 UA + `Accept-Language: zh-CN`，
  标题在 `<h3 ...><a ...>标题</a>` 里 → `re.findall(r'<h3[^>]*>.*?<a[^>]*>(.*?)</a>', s, re.S)` 再剥标签。
- **关键词越多越搜不到**：堆 5~6 个词（「恐怖故事 卡带 游戏世界 春夏秋冬 火山 陷阱」）百度返回 **0 条**
  —— 页面照样下到 800KB+，但解析不出任何 `<h3>`。**降到 2~3 个核心词**才出结果。
- **`cn.bing.com/search`（文本）解析不出来**：能 200，但 `<h2><a>` 抓不到标题 → 文本搜索用百度，别用 bing。
- **搜狗**（`www.sogou.com/web?query=`，`<h3>` 结构）能出结果但噪音极大，词一偏全是游戏广告。
- ★ **上限：1~2 轮高质量搜索**。同一问题换词搜到第 3、4 轮基本是浪费（本次连搜 5 轮 0 收获）。
  搜不到就**停手，问用户要判别性细节**，或者等他给出处/链接。
- 反爬提示：正文之外别抓 `acjson` 类接口（见第三节）；能解析标题列表就够用来判断"有没有命中"。

## 六、从链接反查「这是什么」（B站 BVID，免登录）

用户丢一个 `https://www.bilibili.com/video/BVxxxxxxx` 问「这个你看过吗 / 这是什么」时，别猜、别只看 URL ——
B站公开 API **免 cookie** 就能拿到标题/UP/标签/评论，**标签往往直接点破本体名**：

```bash
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36"
BV=BV1eY4y1Q7Q3

# 1) 基本信息：title / owner.name / pubdate / duration / stat / pages / aid
curl -s -A "$UA" -H "Referer: https://www.bilibili.com/" \
  "https://api.bilibili.com/x/web-interface/view?bvid=$BV"

# 2) 标签 —— 最有用的一步
#    本次靠它把「某个短片」认成 Kaizo Trap：标签里直接有 `kaizo trap` / `ARG` / `孔明的陷阱`
curl -s -A "$UA" -H "Referer: https://www.bilibili.com/video/$BV" \
  "https://api.bilibili.com/x/tag/archive/tags?bvid=$BV"

# 3) 评论（oid = 上面 view 返回的 data.aid）—— 评论区常直接点破本体名和题眼
curl -s -A "$UA" -H "Referer: https://www.bilibili.com/video/$BV" \
  "https://api.bilibili.com/x/v2/reply?type=1&oid=<aid>&ps=20&sort=2&pn=1"
```

- 返回 JSON，`code:0` 才是成功；`code:-412/-403` = 被风控，加 `Referer` 重试，仍失败就别硬刷
- 中文在 JSON 里是 `\uXXXX`，`json.load` 后自动还原，不用手工解码
- **`view` 的 `data.desc` 可能是空串** → 别只靠简介；`tags` + `reply` 才是认出本体的关键
- 同一手法可推及其他平台（有公开 API 的站点都行），别只盯页面 HTML 里那点 og 标签

### 汇报纪律（这条比技术重要）
- 认出来 → 给**名字 + 作者 + 年份**，并把用户描述的细节**逐条对上**（他对剧情的记忆就是校验集）
- **没看过正片就直说没看过**，别顺手编剧情细节充数
- 认不出来 → 给「同类原型 / 年代 / 手法」的解剖（例："被吸进电视"=1982《鬼哭神嚎》原型、《世界奇妙物语》手法），
  再让用户补 **2~3 个判别性细节**（中文还是日文、画面是像素还是实拍、结局是什么）——
  比继续硬搜有用得多，而且用户往往下一句就把链接发过来了
