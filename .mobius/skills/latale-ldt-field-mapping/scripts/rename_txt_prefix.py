#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ITEM_2 TXT 批量改名脚本。
在编辑器导出的TAB分隔TXT中，搜索名称前缀并替换为另一个前缀。

用法：
  python rename_txt_prefix.py <输入文件> [输出文件] [--old 旧前缀] [--new 新前缀]

示例：
  # 将"活动用"改为"（活动）"，直接覆盖原文件
  python rename_txt_prefix.py item2_clean.txt --old "活动用" --new "（活动）"

  # 将"【韩国专属合作道具，其他国家服无法使用】"去掉，输出到新文件
  python rename_txt_prefix.py item2.txt item2_clean.txt --old "【韩国专属合作道具，其他国家服无法使用】" --new ""
"""

import sys, os, csv

def main():
    args = sys.argv[1:]
    if len(args) < 1:
        print(__doc__)
        sys.exit(1)

    src = args[0]
    dst = args[1] if len(args) > 1 and not args[1].startswith('--') else src

    old_prefix = '活动用'
    new_prefix = '（活动）'
    col_index = 4  # Name列索引(0-based)

    i = 1 if dst != src else 0
    while i < len(args):
        if args[i] == '--old' and i + 1 < len(args):
            old_prefix = args[i + 1]
            i += 2
        elif args[i] == '--new' and i + 1 < len(args):
            new_prefix = args[i + 1]
            i += 2
        elif args[i] == '--col' and i + 1 < len(args):
            col_index = int(args[i + 1])
            i += 2
        else:
            i += 1

    changed = 0
    total = 0
    tmp = dst + '.tmp'

    with open(src, 'r', encoding='utf-8') as fin, \
         open(tmp, 'w', encoding='utf-8', newline='') as fout:
        for line in fin:
            parts = line.rstrip('\n').split('\t')
            if len(parts) > col_index:
                name = parts[col_index].strip()
                if name.startswith(old_prefix):
                    parts[col_index] = new_prefix + name[len(old_prefix):]
                    changed += 1
            fout.write('\t'.join(parts) + '\n')
            total += 1

    os.replace(tmp, dst)
    print('总行: %d, 改名: %d' % (total, changed))
    print('规则: %s → %s (col%d)' % (old_prefix, new_prefix, col_index))

if __name__ == '__main__':
    main()
