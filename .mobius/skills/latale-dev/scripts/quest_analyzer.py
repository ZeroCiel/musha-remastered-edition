#!/usr/bin/env python3
"""
彩虹岛任务分析器 v1 - QUEST_REWARD_1 单表分析
输出：全量按EXP降序排列 + 量级分组 + 20亿模板块分析

用法:
  python quest_analyzer.py <QUEST_REWARD_TXT路径>
例:
  python quest_analyzer.py 111.txt
"""

import sys, os

def parse_reward_txt(path):
    rows = {}
    with open(path, 'r', encoding='utf-8-sig') as f:
        for lineno, line in enumerate(f, 1):
            line = line.strip()
            if not line: continue
            parts = line.split('\t')
            if len(parts) < 2: continue
            row_id = parts[0].strip()
            exp = int(parts[1]) if parts[1].strip() else 0
            ely = int(parts[2]) if parts[2].strip() else 0
            fame = int(parts[3]) if len(parts) > 3 and parts[3].strip() else 0
            rows[lineno] = {'RowId': row_id, 'EXP': exp, 'Ely': ely, 'Fame': fame}
    return rows

def main():
    if len(sys.argv) < 2:
        print("用法: python quest_analyzer.py <QUEST_REWARD_TXT路径>")
        sys.exit(1)
    
    path = sys.argv[1]
    if not os.path.exists(path):
        print(f"文件不存在: {path}")
        sys.exit(1)
    
    reward = parse_reward_txt(path)
    print(f"总任务数: {len(reward)}")

    has_exp = [(rn, r) for rn, r in reward.items() if r['EXP'] > 0]
    has_exp.sort(key=lambda x: x[1]['EXP'], reverse=True)
    total_exp = sum(r['EXP'] for _, r in has_exp)
    print(f"非零EXP: {len(has_exp)}")
    print(f"总经验: {total_exp:,}")

    print("\n量级分布:")
    buckets = [
        ('1~10万', 1, 100000),
        ('10万~100万', 100000, 1000000),
        ('100万~1000万', 1000000, 10000000),
        ('1000万~1亿', 10000000, 100000000),
        ('1亿~10亿', 100000000, 1000000000),
        ('10亿+', 1000000000, 999999999999),
    ]
    for label, lo, hi in buckets:
        cnt = sum(1 for _, r in has_exp if lo <= r['EXP'] < hi)
        if cnt:
            sub_total = sum(r['EXP'] for _, r in has_exp if lo <= r['EXP'] < hi)
            print(f"  {label}: {cnt} 个 (合计{sub_total:,})")

    print(f"\n全量排序 (共{len(has_exp)}行):")
    print(f"{'行号':>4} | {'RowId':<14} | {'EXP':>18} | {'Ely':>15} | {'Fame':>8}")
    print("-"*73)
    for rn, r in has_exp:
        print(f"{rn:>4} | {r['RowId']:<14} | {r['EXP']:>18,} | {r['Ely']:>15,} | {r['Fame']:>8}")

    # 20亿模板块
    two_b = [rn for rn, r in reward.items() if r['EXP'] == 2000000000]
    if two_b:
        sorted_tb = sorted(two_b)
        print(f"\n20亿EXP: {len(two_b)} 个")
        print(f"行号: {sorted_tb}")
        gaps = [sorted_tb[i+1] - sorted_tb[i] for i in range(len(sorted_tb)-1)]
        uniq = set(gaps)
        if len(uniq) == 1:
            print(f"间隔: {gaps[0]} (规律数据块)")
        else:
            print(f"间隔(前20): {gaps[:20]}")

if __name__ == '__main__':
    main()
