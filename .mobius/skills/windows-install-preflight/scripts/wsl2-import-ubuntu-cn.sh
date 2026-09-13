#!/bin/bash
# 墙内 Windows：下载 Ubuntu WSL rootfs（带 sha256 校验门）→ wsl --import → 冒烟测试 → 跑配置脚本
# 幂等，可重复运行。用法：
#   bash wsl2-import-ubuntu-cn.sh                      # 只做下载+导入+冒烟
#   bash wsl2-import-ubuntu-cn.sh /mnt/d/xx/setup.sh   # 顺便以 root 跑这个配置脚本
#
# 前置：内核已装（C:\Windows\System32\lxss\tools\kernel 存在）
# 设计要点（都是踩过的坑，别改）：
#   - 下载绝不用 curl -C -（国内镜像可能忽略 Range → 追加 → 文件变拼接垃圾）
#   - 校验门放在 import 之前（wsl --import 不校验 tar，坏 tar 也 exit 0）
#   - import 之后先冒烟测试再跑配置

set -u
DL=${DL:-/d/wsl-dl}                     # 下载目录（放空间大的盘）
DISTRO=${DISTRO:-Ubuntu2204}
INSTALL_DIR=${INSTALL_DIR:-"D:\\WSL\\Ubuntu2204"}
FNAME=ubuntu-jammy-wsl-amd64-ubuntu22.04lts.rootfs.tar.gz
SIZE=341130963
SHA=1483cc5c1dce13064f774834cbffdff226559fd522a67a381a8ea77d63fb4109
PRIMARY="https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cloud-images/wsl/jammy/current"
FALLBACK="https://mirrors.ustc.edu.cn/ubuntu-cloud-images/wsl/jammy/current"
SETUP_SCRIPT=${1:-}
TAR=$DL/$FNAME

mkdir -p "$DL"
exec > >(tee -a "$DL/wsl2-install.log") 2>&1
log() { echo "[$(date '+%m-%d %H:%M:%S')] $*"; }

log "==== wsl2 import 启动 (distro=$DISTRO) ===="

if wsl.exe -d "$DISTRO" -u root -- echo WSLREADY 2>/dev/null | grep -q WSLREADY; then
  log "发行版 $DISTRO 已可用 → 跳过下载/导入"
else
  ok=0
  for round in 1 2 3; do
    [ $round -eq 1 ] && BASE=$PRIMARY || BASE=$FALLBACK
    log "第 $round 轮下载：$BASE"
    rm -f "$TAR"
    curl -L --retry 3 --retry-delay 5 -m 2400 -o "$TAR" "$BASE/$FNAME" \
      -w "curl: http=%{http_code} size=%{size_download} time=%{time_total}s\n"
    got=$(stat -c %s "$TAR" 2>/dev/null || echo 0)
    log "落盘 $got / $SIZE"
    [ "$got" != "$SIZE" ] && { log "!! 大小不符"; continue; }
    calc=$(sha256sum "$TAR" | cut -d' ' -f1)
    [ "$calc" = "$SHA" ] && { log "✓ sha256 校验通过"; ok=1; break; }
    log "!! sha256 不符（$calc）"
  done
  [ $ok -ne 1 ] && { log "!! 三轮都失败，放弃"; exit 1; }

  log "卸载同名旧发行版（如有）..."
  wsl.exe --unregister "$DISTRO" >/dev/null 2>&1
  sleep 2

  log "wsl --import 开始..."
  wsl.exe --import "$DISTRO" "$INSTALL_DIR" "$(cygpath -w "$TAR")" --version 2
  rc=$?; log "import 退出码 $rc"
  [ $rc -ne 0 ] && exit 1
fi

sleep 3
smoke=$(wsl.exe -d "$DISTRO" -u root -- echo WSLREADY 2>&1 | tr -d '\r\0')
log "冒烟测试: $smoke"
echo "$smoke" | grep -q WSLREADY || { log "!! 发行版起不来，停止"; exit 1; }
log "内核: $(wsl.exe -d "$DISTRO" -u root -- uname -r 2>&1 | tr -d '\r\0')"

if [ -n "$SETUP_SCRIPT" ]; then
  log "跑配置脚本 $SETUP_SCRIPT ..."
  win=$(cygpath -w "$SETUP_SCRIPT")
  wsl.exe -d "$DISTRO" -u root -- bash -c "sed -i 's/\r\$//' '$win'; bash '$win'"
  log "配置退出码 $?"
fi

wsl.exe --terminate "$DISTRO" 2>/dev/null
sleep 3
log "默认用户: $(wsl.exe -d "$DISTRO" -- whoami 2>&1 | tr -d '\r\0')"
log "==== 结束 ===="
