"""
彩虹岛S2 EXPERIENCE.LDT 经验值重写脚本

用法：python rewrite_exp_ldt.py [--multiplier 2.5]

默认策略：Lv1~50 经验×2.5倍，Lv50~100 线性递减到×1.0
备份自动生成到原始文件同目录
"""
import struct, math, os, shutil

SRC = 'D:/彩虹岛/resource/ROWID/DATA/LDT/EXPERIENCE.LDT'

def parse_exp(path):
    """解析EXPERIENCE.LDT，返回列表 [(level_idx, exp_value), ...]"""
    with open(path, 'rb') as f:
        data = f.read()
    end_mark = data.find(b'END')
    text_raw = data[8722:end_mark].decode('ascii', errors='replace')
    import re
    cleaned = re.sub(r'[^\d\s]', ' ', text_raw)
    nums = [int(x) for x in cleaned.split() if x.isdigit()]
    seen = set()
    ordered = []
    for n in nums:
        if n not in seen:
            seen.add(n)
            ordered.append(n)
    return ordered

def build_ldt_binary(exp_values):
    """
    将经验值列表写回LDT格式
    LDT头部: [4B unk=1] [4B col_count=2] [4B row_count]
    + 列名区(128B) + 类型区(8B) + 填充0到偏移8204
    + 文本区: 每行 [4B level_idx] [4B 0x10000000] [ASCII数字] [1B 0x20]
    + END标记
    """
    row_count = len(exp_values)
    
    # 头部
    header = bytearray()
    header += struct.pack('<III', 1, 2, row_count)  # unk, col_count, row_count
    
    # 列名区: 列名64B填充
    col_names = [b'_MinXp', b'_MaxXp']
    for name in col_names:
        entry = name.ljust(64, b'\x00')[:64]
        header += entry
    
    # 类型区: 2列int32(0) 对齐到4
    padding = (4 - (len(header) % 4)) % 4
    header += b'\x00' * padding
    header += struct.pack('<II', 0, 0)  # 2列type=0
    
    # 填充到8204
    header += b'\x00' * (8204 - len(header))
    
    # 填充从8204到8721的0区域 (518字节)
    header += b'\x00' * 518
    
    # 文本数据区(从8722开始)
    text_data = bytearray()
    for i, exp in enumerate(exp_values):
        exp_str = str(exp)
        text_data += struct.pack('<I', i)  # level_idx
        text_data += struct.pack('<I', 0x10)  # flag
        text_data += exp_str.encode('ascii')
        text_data += b' '  # 空格分隔
    
    # END标记 + 填充
    end_block = b'END' + b' ' * 61
    
    return bytes(header + text_data + end_block)

def apply_strategy(exp_values, strategy='scale', multiplier=2.5):
    """
    应用修改策略
    strategy='scale': Lv1~50 ×multiplier, Lv50~100 线性递减到×1
    strategy='plateau': 前50级分段常量
    strategy='formula': 公式化重写
    """
    new_exp = list(exp_values)
    total = len(new_exp)
    
    if strategy == 'scale':
        for i in range(1, total):
            if i <= 50:
                factor = multiplier - (multiplier - 1.0) * (i / 50) * 0.3  # 前50级缓慢递减
                new_exp[i] = int(new_exp[i] * factor)
            elif i <= 100:
                factor = 1.0 + (multiplier - 1.0) * 0.3 * (1 - (i - 50) / 50)
                new_exp[i] = int(new_exp[i] * factor)
            # 100级后不变
        
        # 确保单调递增
        for i in range(1, total):
            if new_exp[i] <= new_exp[i-1]:
                new_exp[i] = new_exp[i-1] + 1
    
    elif strategy == 'plateau':
        # 分段常量
        segments = [(1, 10, 10000), (11, 30, 50000), (31, 50, 200000),
                    (51, 70, 1000000), (71, 100, None)]
        cum = 0
        for start, end, val in segments:
            for i in range(start, min(end + 1, total)):
                if val is None:
                    new_exp[i] = exp_values[i]  # 保留原值
                else:
                    cum += val
                    new_exp[i] = cum
    
    return new_exp

if __name__ == '__main__':
    import sys
    mult = float(sys.argv[1]) if len(sys.argv) > 1 else 2.5
    
    exp_vals = parse_exp(SRC)
    print(f'解析到 {len(exp_vals)} 个等级')
    print(f'Lv1: {exp_vals[0]:,}  Lv50: {exp_vals[49]:,}  Lv100: {exp_vals[99]:,}')
    
    new_vals = apply_strategy(exp_vals, 'scale', mult)
    
    # 备份
    bak = SRC + '.bak'
    if not os.path.exists(bak):
        shutil.copy2(SRC, bak)
        print(f'备份: {bak}')
    
    # 写入
    data = build_ldt_binary(new_vals)
    with open(SRC, 'wb') as f:
        f.write(data)
    
    print(f'写入完成 ({len(data)} bytes)')
    print(f'Lv1: {exp_vals[0]:,}→{new_vals[0]:,}')
    print(f'Lv50: {exp_vals[49]:,}→{new_vals[49]:,}')
    print(f'Lv100: {exp_vals[99]:,}→{new_vals[99]:,}')
