#!/usr/bin/env bash
# mod_ref_audit.sh — DST mod 静态引用审计
#
# 作用：把 modmain.lua / prefabs 里所有「指向文件」的引用抽出来，逐个核对文件是否存在。
# 为什么需要：AddComponent / modimport / PrefabFiles 引用一个不存在的文件时，
#   DST 不是让那个功能报错，而是抛 "module ... not found" 并 **Disabling <mod> because it had an error**
#   ——整个 mod 被禁用。这种死引用常年藏在 "first_time" / 早退分支里不被人发现，
#   一旦放宽早退（改成「缺就补」）就立刻暴露。改初始化逻辑前先跑这个脚本。
#
# 用法：
#   cd "D:/SteamLibrary/steamapps/common/Don't Starve Together/mods/<yourmod>"
#   bash mod_ref_audit.sh            # 审计当前目录
#   bash mod_ref_audit.sh /path/to/mod
#
# 退出码：发现缺失文件时返回 1（可接进 CI / 提交前钩子）。

set -u
ROOT="${1:-.}"
cd "$ROOT" || { echo "目录不存在: $ROOT" >&2; exit 2; }

fail=0
SRC_GLOBS="modmain.lua scripts/prefabs/*.lua scripts/components/*.lua"

check() { # $1=描述 $2=相对 mod 根的路径
    if [ -f "$2" ]; then
        printf '  OK    %s\n' "$1"
    else
        printf '  缺失  %s   ->  %s\n' "$1" "$2"
        fail=1
    fi
}

echo "== AddComponent 目标（scripts/components/<name>.lua）=="
for c in $(grep -ho 'AddComponent("[a-z_]*")' $SRC_GLOBS 2>/dev/null \
           | sed 's/.*AddComponent("//;s/")//' | sort -u); do
    check "$c" "scripts/components/$c.lua"
done

echo
echo "== modimport 目标（路径相对 mod 根，注意有些自带 .lua 后缀）=="
for f in $(grep -ho 'modimport "[^"]*"' $SRC_GLOBS 2>/dev/null \
           | sed 's/modimport "//;s/"//' | sort -u); do
    case "$f" in
        *.lua) check "$f" "$f" ;;
        *)     check "$f" "$f.lua" ;;
    esac
done

echo
echo "== require(\"components/...\") 目标 =="
for f in $(grep -ho 'require("components/[a-z_]*")' $SRC_GLOBS 2>/dev/null \
           | sed 's/require("//;s/")//' | sort -u); do
    check "$f" "$f.lua"
done

echo
echo "== PrefabFiles 目标（scripts/prefabs/<name>.lua）=="
# 抓 PrefabFiles = { "a", "b", ... } 块里的字符串（跨行，取到第一个 }）
for p in $(awk '/PrefabFiles[[:space:]]*=/{f=1} f{print} f&&/\}/{f=0}' modmain.lua 2>/dev/null \
           | grep -o '"[a-z_0-9]*"' | tr -d '"' | sort -u); do
    check "$p" "scripts/prefabs/$p.lua"
done

echo
echo "== replica 组件核对（每个 _replica.lua 都应有同名组件 + AddReplicableComponent）=="
for r in scripts/components/*_replica.lua; do
    [ -e "$r" ] || continue
    base=$(basename "$r" _replica.lua)
    if grep -q "AddReplicableComponent(\"$base\")" modmain.lua 2>/dev/null; then
        printf '  OK    replica %s 已注册\n' "$base"
    else
        printf '  缺失  replica %s 未 AddReplicableComponent -> 客户端 inst.replica.%s 恒 nil\n' "$base" "$base"
        fail=1
    fi
done

echo
if [ "$fail" -eq 0 ]; then
    echo "全部引用存在。"
else
    echo "存在缺失引用 —— 修完再进游戏，否则 mod 会被禁用。"
fi
exit $fail
