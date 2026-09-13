---
name: windows-app-install
description: 帮 Windows 用户装桌面软件（微信/QQ/常用工具）——先查是否已装、探官方源拿 Content-Length、后台下载到 Downloads、校验字节数、交用户双击向导。含墙内 CDN 与 winget 备选。
---

# Windows 桌面软件安装（帮用户把包备好，让他自己点向导）

触发：用户说「帮我安装 <某软件>」「装个微信电脑版」这类。

## ★ 核心用户偏好（实测）
**只负责把安装包准备好 + 告诉他双击，不要替他跑安装向导、不要默认走 winget 静默安装。**
这位用户习惯手动双击跑向导（自己选安装路径 / 勾选项）。

回话给两样就够，别写长：
1. **安装包的绝对路径**
2. **向导里值得留意的 1–2 处**（能不能换盘、要不要取消开机自启、要不要扫码登录）

## 步骤

### 1. 先查是否已装（别重复装）
```bash
ls -d "/c/Program Files/<厂商>/<软件>" "/c/Program Files (x86)/<厂商>/<软件>" "$LOCALAPPDATA/<厂商>/<软件>" 2>/dev/null
ls "/c/Users/<user>/Desktop/" | grep -i "<关键词>"      # 桌面快捷方式
winget --version                                        # 顺带确认 winget 可用
```

### 2. 探官方下载源，拿 Content-Length 当校验基准
```bash
curl -sI --max-time 15 "<官方安装包URL>" | head -6
```
`HTTP/1.1 200 OK` + `Content-Length` 就是可用。**同时探一次备用 CDN 域名**，
主源慢/断时直接换域名重试，比调参快。

### 3. 后台下载到 Downloads（200MB+ 别前台阻塞）
```
terminal(background=true, notify_on_complete=true,
  command='mkdir -p "/c/Users/<user>/Downloads" && curl -L --retry 3 --connect-timeout 20 \
           -o "/c/Users/<user>/Downloads/<Name>Setup.exe" "<URL>" \
           && ls -l "/c/Users/<user>/Downloads/<Name>Setup.exe"')
```
中途报进度：`ls -l <文件> | awk '{printf "已下载 %.1f MB / <总MB> MB\n", $5/1048576}'`

### 4. 校验字节数 == 第 2 步的 Content-Length
一字不差才算下好（看 `ls -l` 的 size 列）。不等就重下，别交付。

### 5. 交用户双击，收工
给路径 + 向导注意事项（见上「核心用户偏好」）。

## 备选：winget
`winget install <Publisher.App>`（例 `Tencent.WeChat`）。
**只在用户说"懒得点、你直接装"时才用**；默认不要替他决定。

## 坑
- **大文件别前台等**：前台 timeout 上限 600s；`process action=wait` 的 timeout 会被夹到 ~60s。
  正解是 `background=true` + `notify_on_complete=true`，配合 `ls -l` 轮询字节数。
- **墙内网络**：优先厂商的**国内 CDN** 域名（腾讯系 `dldir1v6.qq.com` / `dldir1.qq.com` 等都直连可用）。
  这台机器有 Steamcommunity_302 常驻（劫持 127.0.0.1:80/443）——若 curl 出现莫名的失败/空响应，
  先怀疑它，排查顺序见 skill `gfw-network-troubleshooting`。
- 厂商官网首页往往给的是跳转页，`curl -sI` 直接打**安装包直链**才看得到 Content-Length。
- 老版本 / 新版（如微信 3.x vs 4.x）链接不同，别凭记忆拼 URL，以官网当下给的直链为准。

## 相关
- `gfw-network-troubleshooting` — 墙内下载/连接不通时的代理栈排查
