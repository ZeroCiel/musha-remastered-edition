#!/usr/bin/env python3
"""
彩虹岛 任务奖励 + 经验表 关联分析工具

分析 QUEST_REWARD_1.LDT（任务奖励）和 EXPERIENCE.LDT（经验表），
找出导致"一天100级"的异常任务行，并支持修改。

两个文件都是"头部空壳+尾部真实数据"的特殊LDT格式：
- 头部列类型声明全是 type=0(byte)，数据区全为0
- 真实经验/奖励值存储在尾部额外数据区

=== 用法 ===

# 分析：列出所有_Reward_EXP非零的任务行
python analyze_quest_exp.py --list-rows

# 分析：列出1~7级所需的经验值
python analyze_quest_exp.py --exp-curve 1 10

# 分析：给定总经验能升到多少级
python analyze_quest_exp.py --what-level total_exp

# 尾部数据格式（需要手动确认）
# 文件大小165588B，头部40305B，尾部125283B
# 推测结构类似EXPERIENCE.LDT:
#   [4B row_index] [4B magic] [ASCII exp_value] [sep]

# 替代方案（推荐）：直接用彩虹岛编辑器打开并查看/修改
"""

import struct, sys, os

LDT_DIR = r"D:\彩虹岛\resource\ROWID\DATA\LDT"
QUEST_REWARD_PATH = os.path.join(LDT_DIR, "QUEST_REWARD_1.LDT")
EXPERIENCE_PATH = os.path.join(LDT_DIR, "EXPERIENCE.LDT")


def read_exp_table(path):
    """读取EXPERIENCE.LDT经验值表, 返回[(level, cumulative_exp), ...]"""
    with open(path, 'rb') as f:
        data = f.read()
    entries = []
    i = 8722
    while i + 12 < len(data):
        level = struct.unpack_from('<I', data, i)[0]
        magic = struct.unpack_from('<I', data, i + 4)[0]
        if magic == 0x10000000 and 0 <= level <= 255:
            num_start = i + 8
            num_end = num_start
            while num_end < len(data) and 0x30 <= data[num_end] <= 0x39:
                num_end += 1
            exp = int(data[num_start:num_end])
            entries.append((level, exp))
            i = num_end + 1
        else:
            i += 4
    if not entries:
        end_pos = data.find(b'END  ')
        if end_pos > 0:
            i = 8722
            while i + 8 < end_pos:
                magic = struct.unpack_from('<I', data, i + 4)[0]
                if magic == 0x10000000:
                    level = struct.unpack_from('<I', data, i)[0]
                    if 0 <= level <= 255:
                        num_start = i + 8
                        num_end = num_start
                        while num_end < end_pos and 0x30 <= data[num_end] <= 0x39:
                            num_end += 1
                        if num_end > num_start:
                            entries.append((level, int(data[num_start:num_end])))
                            i = num_end
                            continue
                i += 1
    return sorted(entries, key=lambda x: x[0])


def scan_quest_tail(path):
    """探测QUEST_REWARD_1.LDT尾部数据，返回尾部大小、行数等"""
    with open(path, 'rb') as f:
        data = bytearray(f.read())
    col_count = struct.unpack_from('<I', data, 4)[0]
    row_count = struct.unpack_from('<I', data, 8)[0]
    type_off = (12 + col_count * 64 + 3) & ~3
    data_off = (type_off + col_count * 4 + 3) & ~3
    head_end = data_off + col_count * row_count  # 33*1153
    tail = data[head_end:]
    
    print(f"QUEST_REWARD_1.LDT: {col_count}列, {row_count}行")
    print(f"头部数据区: {data_off}~{head_end} ({head_end-data_off}B)")
    print(f"尾部数据: {len(tail)}B")
    
    # 策略1: 按EXPERIENCE.LDT格式尝试
    for magic_val in [0x10000000, 0x58000000]:
        results = []
        for i in range(0, len(tail) - 12, 1):
            magic = struct.unpack_from('<I', tail, i + 4)[0]
            if magic == magic_val:
                idx = struct.unpack_from('<I', tail, i)[0]
                if 0 <= idx < row_count:
                    num_start = i + 8
                    num_end = num_start
                    while num_end < len(tail) and 0x30 <= tail[num_end] <= 0x39:
                        num_end += 1
                    if num_end > num_start:
                        results.append((i, idx, int(tail[num_start:num_end])))
        if results:
            print(f"\n格式探索 (magic={hex(magic_val)}): {len(results)} 条")
            for off, idx, exp in results[:10]:
                print(f"  tail+{off}: row={idx}, exp={exp}")
    
    # 策略2: 按固定132B/行(33*4)读尾部
    per_row = col_count * 4
    nrows_tail = len(tail) // per_row
    print(f"\n若每行{per_row}B: {nrows_tail}行")
    if nrows_tail > 5:
        for r in range(min(5, nrows_tail)):
            off = r * per_row
            vals = [struct.unpack_from('<i', tail, off + i*4)[0] for i in range(3)]
            if any(v != 0 for v in vals):
                print(f"  尾部行{r}: exp={vals[0]}, ely={vals[1]}, fame={vals[2]}")

    # 策略3: 搜索"2000000000"等已知值
    targets = [2000000000, 14900226, 10000000, 1000000]
    for t in targets:
        idx = tail.find(struct.pack('<i', t))
        if idx >= 0:
            print(f"\n值 {t} 出现在 tail+{idx}")


def what_level(exp_table, total_exp):
    for lv, cumul in exp_table:
        if total_exp < cumul:
            return lv - 1
    return exp_table[-1][0] if exp_table else 0


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return
    
    cmd = sys.argv[1]
    
    if cmd == "--list-rows":
        scan_quest_tail(QUEST_REWARD_PATH)
    
    elif cmd == "--exp-curve":
        s = int(sys.argv[2]) if len(sys.argv) > 2 else 1
        e = int(sys.argv[3]) if len(sys.argv) > 3 else 10
        tbl = read_exp_table(EXPERIENCE_PATH)
        if tbl:
            print(f"\nEXP Lv{s}~{e}:")
            prev = 0
            for lv, c in tbl:
                if s <= lv <= e:
                    print(f"  Lv{lv}: {c:>12,} (+{c-prev:>8,})")
                    prev = c
        else:
            print("未能解析EXPERIENCE.LDT")
    
    elif cmd == "--what-level":
        total = int(sys.argv[2])
        tbl = read_exp_table(EXPERIENCE_PATH)
        if tbl:
            lv = what_level(tbl, total)
            print(f"{total:,} exp -> Lv{lv}")
    
    else:
        print("命令: --list-rows, --exp-curve, --what-level")


if __name__ == "__main__":
    main()
