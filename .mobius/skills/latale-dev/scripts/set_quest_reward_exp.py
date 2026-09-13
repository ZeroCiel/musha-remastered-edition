#!/usr/bin/env python3
"""
修改 QUEST_REWARD_1.LDT 中指定行的_Reward_EXP值。
用于修复4个BaseLV=1异常任务的奖励经验。

用法：
  python set_quest_reward_exp.py <行号> <新经验值>
  python set_quest_reward_exp.py 1002 10000     # 行1002经验改为10000

说明：
  - 行号是0-based二进制行号（彩虹岛编辑器显示的行号）
  - 经验值写入的是_Reward_EXP列（具体列索引从文件头部解析）
  - 修改前自动备份到同目录 .bak
"""

import struct, sys, os, shutil

if len(sys.argv) != 3:
    print("用法: python set_quest_reward_exp.py <行号> <新经验值>")
    sys.exit(1)

row_num = int(sys.argv[1])
new_exp = int(sys.argv[2])

path = r"d:\彩虹岛\resource\ROWID\DATA\LDT\QUEST_REWARD_1.LDT"
bak_path = path + f".bak_row{row_num}"

with open(path, 'rb') as f:
    data = bytearray(f.read())

col_count = struct.unpack_from('<I', data, 4)[0]
row_count = struct.unpack_from('<I', data, 8)[0]

print(f"QUEST_REWARD_1.LDT: {col_count}列, {row_count}行")

# 解析列名和类型
col_names = []
for i in range(col_count):
    raw = data[12 + i*64 : 12 + i*64 + 64]
    name = raw.split(b'\x00')[0].decode('gbk', errors='ignore').strip()
    col_names.append(name)

type_off = (12 + col_count * 64 + 3) & ~3
types = [struct.unpack_from('<I', data, type_off + i*4)[0] for i in range(col_count)]
data_off = (type_off + col_count * 4 + 3) & ~3

# 找到_Reward_EXP列
exp_col = -1
for i, (c, t) in enumerate(zip(col_names, types)):
    if 'EXP' in c.upper() or 'Reward' in c.upper():
        if 'EXP' in c.upper() and 'Max' not in c.upper():
            exp_col = i
            break

if exp_col == -1:
    # 找第一列名为_Reward开头的
    for i, c in enumerate(col_names):
        if 'Reward' in c and 'Exp' in c:
            exp_col = i
            break

if exp_col == -1:
    print("未找到EXP列！列名:", col_names[:20])
    sys.exit(1)

print(f"目标列[{exp_col}]: {col_names[exp_col]} (type={types[exp_col]})")

# 定位到该行对应列的数据
# 先计算行偏移（跳过前面的string列）
row_sizes = []
for r in range(row_count):
    o = data_off
    row_start = o
    for i in range(col_count):
        t = types[i]
        if t == 5:  # string
            slen = struct.unpack_from('<H', data, o)[0]
            o += 2 + slen
        elif t == 0: o += 1
        elif t == 1: o += 2
        elif t == 2: o += 4
        elif t == 3: o += 4  # float/实际int32
        elif t == 4: o += 8
        else: o += 4
    row_sizes.append(o - row_start)

# 验证行偏移一致性
if len(set(row_sizes)) > 1:
    print(f"警告：行大小不一致！{set(row_sizes)}")
else:
    print(f"固定行大小: {row_sizes[0]}字节")

if row_num >= row_count:
    print(f"错误：行号{row_num}超出范围（最大{row_count-1}）")
    sys.exit(1)

# 定位到目标行
o = data_off
for r in range(row_num):
    o += row_sizes[r]

# 在该行内定位到exp列
for i in range(exp_col):
    t = types[i]
    if t == 5:
        slen = struct.unpack_from('<H', data, o)[0]
        o += 2 + slen
    elif t == 0: o += 1
    elif t == 1: o += 2
    elif t == 2: o += 4
    elif t == 3: o += 4
    elif t == 4: o += 8
    else: o += 4

# 读旧值
t = types[exp_col]
if t == 3:
    old_val = struct.unpack_from('<i', data, o)[0]  # int32
else:
    old_val = struct.unpack_from('<I', data, o)[0]

print(f"行{row_num} [{col_names[exp_col]}]: {old_val} → {new_exp}")

if old_val == new_exp:
    print("值相同，无需修改")
    sys.exit(0)

# 备份
if not os.path.exists(bak_path):
    shutil.copy2(path, bak_path)
    print(f"已备份: {bak_path}")

# 写入新值
if t == 3:
    struct.pack_into('<i', data, o, new_exp)
else:
    struct.pack_into('<I', data, o, new_exp)

with open(path, 'wb') as f:
    f.write(data)

print("修改完成！")
print(f"提示：修改后需重新打包SPF才能生效。")
