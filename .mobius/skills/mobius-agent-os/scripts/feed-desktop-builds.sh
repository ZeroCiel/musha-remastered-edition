#!/bin/bash
# 把离线下好的桌面端安装包喂给 Mobius 的 /desktop-builds/（绕开后端 GitHub 同步）
# 用法: bash feed-desktop-builds.sh <zip路径> [项目根目录]
#   例: bash feed-desktop-builds.sh /mnt/d/mobius-desktop/mobius-desktop-0.0.29-win-x64.zip
#
# 做三件事：拷进 desktop-builds → 生成 manifest.json → 校验。幂等，可重复跑。
# 前提：zip 已下载好（探活的加速镜像见 skill gfw-network-troubleshooting）
set -u

ZIP="${1:?用法: bash feed-desktop-builds.sh <zip路径> [项目根目录]}"
PROJ="${2:-$HOME/mobius-main}"
DEST="$PROJ/mobius/desktop-builds"
PKG="$PROJ/mobius/desktop/package.json"

echo "=== 喂桌面端产物 ==="

# ---------- 0. 前置检查 ----------
[ -f "$ZIP" ] || { echo "!! zip 不存在: $ZIP"; exit 1; }
[ -f "$PKG" ] || { echo "!! 找不到 $PKG（项目根传错了？）"; exit 1; }

BYTES=$(stat -c %s "$ZIP")
NAME=$(basename "$ZIP")
echo "zip   : $ZIP"
echo "大小  : $BYTES 字节"
printf "魔数  : " ; head -c 4 "$ZIP" | xxd | head -1
# ★ zip 魔数必须是 504b0304(PK)；半截下载会导致 manifest 里的 sha 对不上
if [ "$(head -c 2 "$ZIP")" != "PK" ]; then
  echo "!! 不是合法 zip（魔数非 PK）→ 多半是半截下载，重新下，别喂进去"; exit 1
fi

# ---------- 1. 版本一致性（manifest 的唯一可信版本源 = desktop/package.json） ----------
V_PKG=$(python3 -c "import json;print(json.load(open('$PKG'))['version'])" 2>/dev/null)
echo "package.json 版本: $V_PKG"
case "$NAME" in
  *"$V_PKG"*) echo "文件名版本 ✓ 一致" ;;
  *) echo "!! 警告：文件名里没出现版本 $V_PKG —— 下载的包与代码版本不一致，manifest 校验可能失败" ;;
esac

# ---------- 2. 拷进去 ----------
mkdir -p "$DEST"
cp -f "$ZIP" "$DEST/"
ls -la "$DEST"

# ---------- 3. 生成 + 校验 manifest ----------
echo "--- manifest generate ---"
python3 "$PROJ/scripts/desktop_manifest.py" generate --dir "$DEST" 2>&1 | tail -15

echo "--- manifest validate ---"
python3 "$PROJ/scripts/desktop_manifest.py" validate --dir "$DEST" 2>&1 | tail -10

# ---------- 4. 报结果 ----------
echo "--- manifest.json ---"
cat "$DEST/manifest.json" 2>/dev/null
cat <<'EOT'

--- 验证网页入口（端口以启动日志打印的为准，别照 .env 猜）---
  curl -s -o /dev/null -w "%{http_code}\n" localhost:<port>/desktop-builds/manifest.json   # 期望 200
  curl -s -o /dev/null -w "%{http_code}\n" -r 0-1024 localhost:<port>/desktop-builds/<file> # 期望 206

若 generate 报"版本不一致"：版本源是 mobius/desktop/package.json，
和你下的 releases tag 必须对得上（改代码版本或换对应 tag 的包）。
EOT
