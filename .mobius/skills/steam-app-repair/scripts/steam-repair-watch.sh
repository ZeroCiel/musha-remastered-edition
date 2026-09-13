#!/bin/bash
# Steam 应用缺文件：等 Steam 自己修完 → 自动通过 Steam 拉起 → 报进程与日志
#
# 用法:
#   bash steam-repair-watch.sh [appid] [app目录] [日志目录]
# 默认:
#   appid   = 431960 (Wallpaper Engine)
#   app目录 = C:\Program Files (x86)\Steam\steamapps\common\wallpaper_engine
#   日志目录 = $HOME
#
# 原理: 应用目录成批文件缺失时, 用 steam://rungameid/<appid> 拉一次
#       = 让 Steam 跑完整性校验, 它在 content_log.txt 报 'Files Missing'
#       并自动重下。本脚本只管"等它修完再拉起来", 不做任何删除。
#
# 读法/真因判定见 SKILL.md 的「文件缺失：让 Steam 自己修」段。
# 后台跑: terminal(background=true, notify_on_complete=true)

set -u
APPID="${1:-431960}"
APP="${2:-/c/Program Files (x86)/Steam/steamapps/common/wallpaper_engine}"
LOGDIR="${3:-$HOME}"
LOG="$LOGDIR/steam-repair-watch.log"

# 修完的标志文件(按目标 app 改) —— 全齐视为 Steam 已补齐
SENTINELS=(launcher.exe bin/wallpaperui.exe bin/steam_api64.dll)
MAIN_EXE="wallpaper64"                 # 用于报进程名
MAX_CHECKS="${MAX_CHECKS:-120}"        # 120 × 30s = 60 分钟上限

exec > >(tee -a "$LOG") 2>&1
log()     { echo "[$(date '+%H:%M:%S')] $*"; }
missing() { for f in "${SENTINELS[@]}"; do [ -f "$APP/$f" ] || printf '%s ' "$f"; done; }

log "==== 监视 appid=$APPID 修复 ===="
log "应用目录: $APP"
log "启动前缺失: $(missing)"

for i in $(seq 1 "$MAX_CHECKS"); do
  [ -z "$(missing)" ] && { log "文件齐了(第 $i 次检查) → 等 20s 让 Steam 收尾"; sleep 20; break; }
  [ $((i % 6)) -eq 0 ] && log "第 $i 次: 还缺 $(missing)"
  sleep 30
done

if [ -n "$(missing)" ]; then
  log "!! 等了 $((MAX_CHECKS * 30 / 60)) 分钟仍未补齐, 放弃自动启动"
  log "   Steam 里手动点「开始游戏」; 仍缺 → 属性 → 已安装文件 → 验证游戏文件完整性"
  exit 1
fi

log "旧进程(残留僵尸需手动: taskkill //F //PID <pid>):"
tasklist 2>/dev/null | grep -iE "$MAIN_EXE|wallpaperui" || log "  (无)"

log "通过 Steam 拉起: steam://rungameid/$APPID"
cmd //c "start steam://rungameid/$APPID" >/dev/null 2>&1
sleep 30

log "30s 后进程:"
tasklist 2>/dev/null | grep -iE "$MAIN_EXE|wallpaperui" || log "  (还没有进程 —— 多半 Steam 还在下, 看下一条)"
log "Steam content_log 尾部:"
tail -6 "/c/Program Files (x86)/Steam/logs/content_log.txt" 2>/dev/null | tr -d '\r' | cut -c1-150
if [ -f "$APP/log.txt" ]; then
  log "应用 log.txt 尾部:"; tail -6 "$APP/log.txt" | tr -d '\r' | cut -c1-160
else
  log "应用 log.txt 仍不存在 = 它还没成功启动过"
fi
log "==== 结束 ===="
