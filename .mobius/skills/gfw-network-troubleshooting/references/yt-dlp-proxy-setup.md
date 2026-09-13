# yt-dlp 代理配置全命令集（墙内 / Clash Verge）

> 归档自原独立技能 `yt-dlp-proxy-setup`（2026-09 合并入本伞）。这是 gfw-network-troubleshooting 的"工具级代理配置"参考文件——SKILL.md 主流程负责网络诊断，本文件收该变体的完整命令集。

## 适用场景
用户位于墙内（中国大陆），需要下载 YouTube、PornHub 等外网视频站。已安装 yt-dlp，代理客户端使用 Clash Verge。代理栈本身正常，缺的是让 yt-dlp 走代理。

## 代理排查流程

### 1. 查 Clash Verge 监听端口
Clash Verge 装在 `C:\Program Files\Clash Verge\`，核心进程是 `verge-mihomo.exe`。

```bash
netstat -ano | grep -i listen | grep -v "\[::\]"
```

找到 `verge-mihomo` 进程（PID 对应）监听的端口。常见端口：
- `7897` — HTTP 混合代理（可能需要 http:// 而非 https://）
- `1053` — DNS / 混合端口

### 2. 测试代理连通性
```bash
# HTTP 测试（部分代理只响应 http 不响应 https）
curl -x "http://127.0.0.1:7897" -s -o /dev/null -w "%{http_code}" http://www.google.com

# HTTPS 测试
curl -x "http://127.0.0.1:7897" -s -o /dev/null -w "%{http_code}" https://www.google.com
```

常见结果：
- `000` + exit code 35 — HTTPS 不通（代理只支持纯 HTTP）
- `502` 或 `200` — 通

### 3. yt-dlp 使用代理
```bash
# HTTP 代理
yt-dlp --proxy "http://127.0.0.1:7897" -F <URL>

# SOCKS5 代理（如果 HTTP 不通）
yt-dlp --proxy "socks5://127.0.0.1:7897" -F <URL>
```

### 4. yt-dlp 常见命令

```bash
# 查看可用格式
yt-dlp --proxy "http://127.0.0.1:7897" -F <URL>

# 最佳 mp4 + m4a 音频合成 mp4（需要 ffmpeg）
yt-dlp --proxy "http://127.0.0.1:7897" -f 'bv[ext=mp4]+ba[ext=m4a]' --embed-metadata --merge-output-format mp4 <URL>

# 仅下载音频（m4a）
yt-dlp --proxy "http://127.0.0.1:7897" -f 140 <URL>

# 音频转 mp3
yt-dlp --proxy "http://127.0.0.1:7897" -f 140 -x --audio-format mp3 <URL>

# 指定文件名（不含 ID）
yt-dlp --proxy "http://127.0.0.1:7897" -f 'bv[ext=mp4]+ba[ext=m4a]' --merge-output-format mp4 <URL> -o '%(title)s.mp4'
```

## ffmpeg 安装
下载编译好的 exe 版本：
- https://www.gyan.dev/ffmpeg/builds/ （`ffmpeg-release-full.7z`，解压后 `bin\ffmpeg.exe` 放到 D 盘或加入 PATH）
- 或 winget: `winget install ffmpeg`
- 或 https://github.com/BtbN/FFmpeg-Builds/releases

**不要下源码包**（没有 exe 需要编译），要下带 `bin\ffmpeg.exe` 的 release 包。

## 常见问题

- **HTTP Error 410 Gone** — 视频已被删除
- **WinError 10061 连接被拒绝** — 代理端口不对或代理未运行
- **Impersonation 警告** — 不影响下载，youtube-dl 的兼容警告
- **FFmpeg 未安装** — 下 720p 及以下（单视频流自带音频）不需要 ffmpeg；下 1080p+ 必须装

## 用户偏好（源自原技能会话）
- 用户：墙内用户，Clash Verge 代理，偏好"试试怎么炸"实操模式
- 沟通：直接给结论，不绕圈子分析
- HTTPS 不通就试 HTTP
