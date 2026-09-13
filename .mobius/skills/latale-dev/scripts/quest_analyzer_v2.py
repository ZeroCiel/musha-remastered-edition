#!/usr/bin/env python3
"""
彩虹岛任务分析器 v2 - 关联QUEST_REWARD_1 + QUEST_INFO_1
输出：BaseLV分布 + 新手村异常 + 任务链追踪

用法:
  python quest_analyzer_v2.py <REWARD_TXT> <INFO_TXT>
例:
  python quest_analyzer_v2.py 111.txt 123.txt
"""

import sys, os
from collections import Counter

def parse_reward(path):
    rows = {}
    with open(path, 'r', encoding='utf-8-sig') as f:
        for lineno, line in enumerate(f, 1):
            line = line.strip()
            if not line: continue
            parts = line.split('\t')
            if len(parts) < 2: continue
            rid = parts[0].strip()
            exp = int(parts[1]) if parts[1].strip() else 0
            ely = int(parts[2]) if parts[2].strip() else 0
            fame = int(parts[3]) if len(parts) > 3 and parts[3].strip() else 0
            rows[lineno] = {'RowId': rid, 'EXP': exp, 'Ely': ely, 'Fame': fame}
    return rows

def parse_info(path):
    """QUEST_INFO_1导出TXT，29列TAB分隔"""
    rows = {}
    with open(path, 'r', encoding='utf-8-sig') as f:
        for lineno, line in enumerate(f, 1):
            line = line.strip()
            if not line: continue
            parts = line.split('\t')
            if len(parts) < 29: continue
            rows[lineno] = {
                'place': parts[3],       # _Place_Info1
                'npc': parts[4],         # _NPC_Info1
                'base_lv': int(parts[20]) if parts[20].strip() else 0,
                'kind': parts[21],
                'next': parts[24],       # _Quest_Next
                'purpose': parts[9],
                'accept': parts[10],
                'complete': parts[11],
            }
    return rows

def find_chain(info, reward, start_rid, max_depth=50):
    """通过_Quest_Next追踪任务链"""
    # 按RowId建立索引
    by_rid = {}
    for rn, r in reward.items():
        by_rid[r['RowId']] = rn
    
    chain = []
    current_rid = start_rid
    for _ in range(max_depth):
        rn = by_rid.get(current_rid)
        if not rn: break
        chain.append(rn)
        i = info.get(rn)
        if not i: break
        next_id = i.get('next', '0')
        if next_id == '0' or next_id == current_rid: break
        current_rid = next_id
    return chain

def find_next_rn(info, by_rid, next_rid):
    """根据_Quest_Next值找行号"""
    if next_rid in by_rid:
        return by_rid[next_rid]
    return None

def main():
    if len(sys.argv) < 3:
        print("用法: python quest_analyzer_v2.py <REWARD_TXT> <INFO_TXT>")
        sys.exit(1)
    
    rpath = sys.argv[1]
    ipath = sys.argv[2]
    
    reward = parse_reward(rpath)
    info = parse_info(ipath)
    
    print(f"奖励表: {len(reward)} 行, 信息表: {len(info)} 行")
    
    # BaseLV分布
    lv_counter = Counter()
    for rn in reward:
        blv = info.get(rn, {}).get('base_lv', -1)
        lv_counter[blv] += 1
    
    print(f"\nBaseLV分布:")
    for lv in sorted(lv_counter.keys()):
        cnt = lv_counter[lv]
        total_2b = sum(1 for rn in reward 
                       if info.get(rn, {}).get('base_lv', -1) == lv 
                       and reward[rn]['EXP'] == 2000000000)
        suffix = f" (其中{total_2b}个20亿)" if total_2b else ""
        print(f"  BaseLV={lv}: {cnt} 个{suffix}")
    
    # 新手村异常
    print(f"\n{'='*70}")
    print(f"贝罗斯+艾利亚斯 新手村异常任务")
    print(f"{'='*70}")
    for rn in sorted(reward.keys()):
        if rn not in info or rn not in reward: continue
        i = info[rn]
        r = reward[rn]
        place = i.get('place', '')
        if '贝罗斯' in place or '艾利亚斯' in place.replace('亞', '亚'):
            flag = ''
            if r['EXP'] >= 2000000000: flag = ' ← 20亿!'
            elif r['EXP'] >= 100000000: flag = ' ← 过亿!'
            elif r['EXP'] >= 10000000: flag = ' ← 偏高'
            print(f"行{rn:>4}: BaseLV={i['base_lv']:>3} EXP={r['EXP']:>15,} Ely={r['Ely']:>10,}{flag}")
            print(f"      地点={place:<12} NPC={i['npc']:<10} 目的={i['purpose'][:40]}")
    
    # 任务链 - 搜新手村相关
    print(f"\n{'='*70}")
    print(f"新手村任务链追踪 (BaseLV<=10 且 EXP>0 的任务)")
    print(f"{'='*70}")
    
    # 构建by_rid索引
    by_rid = {}
    for rn, r in reward.items():
        by_rid[r['RowId']] = rn
    
    candidates = [(rn, r) for rn, r in reward.items() 
                  if r['EXP'] > 0 and info.get(rn, {}).get('base_lv', 999) <= 10]
    candidates.sort(key=lambda x: x[0])
    
    for rn, r in candidates[:30]:
        i = info.get(rn, {})
        chain = find_chain(info, reward, r['RowId'])
        chain_str = '→'.join(str(c) for c in chain) if chain else '(孤立)'
        print(f"行{rn:>4}: {r['RowId']:<15} EXP={r['EXP']:>15,} BaseLV={i.get('base_lv', '?'):>3}")
        print(f"      地点={i.get('place','?'):<12} NPC={i.get('npc','?'):<10}")
        print(f"      链: {chain_str}")

if __name__ == '__main__':
    main()
