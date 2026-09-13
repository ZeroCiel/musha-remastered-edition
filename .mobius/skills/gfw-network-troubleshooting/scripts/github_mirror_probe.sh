#!/usr/bin/env bash
# 探 GitHub Release 附件的可用下载源（直连 / 加速镜像 / 大学镜像转发）。
#
# 用法:
#   bash github_mirror_probe.sh <owner> <repo> <tag> <filename>
# 例:
#   bash github_mirror_probe.sh mobius-system mobius desktop-v0.0.29 mobius-desktop-0.0.29-win-x64.zip
#   bash github_mirror_probe.sh astral-sh python-build-standalone 20260901 cpython-3.12.14+20260901-x86_64-unknown-linux-gnu-install_only_stripped.tar.gz
#
# 为什么需要它：加速镜像的可用性是**时效性事实**（同一批域名 403 → 200 → 000 都出现过）。
# 别照旧结论直接放弃，每次都探一条。取首个 HTTP 200 的用。
set -u

OWNER=${1:?用法: github_mirror_probe.sh <owner> <repo> <tag> <filename>}
REPO=${2:?缺 repo}
TAG=${3:?缺 tag}
FILE=${4:?缺 filename}
SECS=${5:-12}

ORIG="https://github.com/$OWNER/$REPO/releases/download/$TAG/$FILE"
echo "目标附件:"
echo "  $ORIG"
echo
printf '%-34s %-6s %-9s %s\n' "来源" "HTTP" "耗时" "说明"
printf '%-34s %-6s %-9s %s\n' "----" "----" "----" "----"

probe() { # $1=名称 $2=URL $3=说明
    local code t
    read -r code t < <(curl -sL -m "$SECS" -r 0-0 -o /dev/null \
        -w "%{http_code} %{time_total}" "$2" 2>/dev/null)
    printf '%-34s %-6s %-9s %s\n' "$1" "${code:-000}" "${t:+${t}s}" "$3"
}

probe "github.com (直连)" "$ORIG" "被墙/被 hosts 劫持时 000 或 302→127.0.0.1"

for M in "https://ghfast.top/" "https://gh-proxy.com/" "https://ghproxy.net/" \
         "https://github.moeyy.xyz/" "https://ghp.ci/" "https://gh.llkk.cc/"; do
    probe "加速镜像 $M" "${M}${ORIG}" "代理型，时好时坏，每次现探"
done

# 大学镜像的 github-release 转发：路径里没有 /releases/download
probe "mirrors.nju.edu.cn"  "https://mirrors.nju.edu.cn/github-release/$OWNER/$REPO/$TAG/$FILE"  "南大，release 转发"
probe "mirrors.ustc.edu.cn" "https://mirrors.ustc.edu.cn/github-release/$OWNER/$REPO/$TAG/$FILE" "中科大，release 转发"
probe "mirrors.tuna.tsinghua.edu.cn" \
      "https://mirrors.tuna.tsinghua.edu.cn/github-release/$OWNER/$REPO/$TAG/$FILE" "清华，只镜像部分仓库，常 404"

cat <<'EOF'

下一步：取首个 200 的，把「镜像前缀 + 原始 URL」拼起来下载
  curl -L --retry 3 --retry-delay 5 -o <本地文件> '<镜像前缀>https://github.com/<owner>/<repo>/releases/download/<tag>/<file>'

★ 下完必须核验，别直接信 200：
  1) curl -sIL <url> | grep -i content-length   ← 先拿期望字节数
  2) ls -l <本地文件>                            ← 比对，一致才算下全
  3) 有 sha256 就再核 sha256
  4) 若目标是 .zip，验头部魔数：head -c 4 <文件> | xxd   → 应为 504b 0304 (PK..)
EOF
