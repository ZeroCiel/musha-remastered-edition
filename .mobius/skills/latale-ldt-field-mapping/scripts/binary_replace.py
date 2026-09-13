"""
二进制等长替换LDT中string字段的指定关键词。
安全：只做GBK byte-level replace，不解析LDT结构。
用法: python binary_replace.py <关键词> <替换词>
示例:
  python binary_replace.py 愛麗絲 爱丽丝
  python binary_replace.py 設計 设计  # 会跳过（"设计"会导致GS崩溃）
"""
import struct, os, sys

if len(sys.argv) < 3:
    print("用法: python binary_replace.py <关键词> <替换词>")
    sys.exit(1)

old_word = sys.argv[1]
new_word = sys.argv[2]
ldt_dir = r'D:\彩虹岛\resource\ROWID\DATA\LDT'

old_gbk = old_word.encode('gbk')
new_gbk = new_word.encode('gbk')

if len(old_gbk) != len(new_gbk):
    print(f"错误: 不等长替换! {old_word}({len(old_gbk)}B) -> {new_word}({len(new_gbk)}B)")
    print("二进制替换只支持等长映射。不等长请用彩虹岛编辑器手动改。")
    sys.exit(1)

# 检查是否是已知危险词
danger_words = ['设', '计']
for c in old_word:
    if c in danger_words:
        print(f"警告: '{c}' 属于已知危险字（'设计'会导致GS崩溃），跳过所有文件")
        sys.exit(1)

total_files = 0
total_changes = 0
for fname in sorted(os.listdir(ldt_dir)):
    if not fname.endswith('.LDT') or fname.endswith('.bak'):
        continue
    fpath = os.path.join(ldt_dir, fname)
    with open(fpath, 'rb') as f:
        data = bytearray(f.read())
    
    found = data.count(old_gbk)
    if found == 0:
        continue
    
    # 确认是在string数据区（检查string类型列）
    col_count = struct.unpack('<I', data[4:8])[0]
    string_cols = []
    for i in range(col_count):
        t = struct.unpack('<I', data[8204 + i*4:8204 + i*4 + 4])[0]
        if t == 1:
            string_cols.append(i)
    if not string_cols:
        continue
    
    # 备份
    with open(fpath + '.bak', 'wb') as f:
        f.write(data)
    
    # 替换
    data = data.replace(old_gbk, new_gbk)
    
    with open(fpath, 'wb') as f:
        f.write(data)
    
    total_files += 1
    total_changes += found
    print(f"  {fname}: {found}处")

print(f"\n完成: {total_files}个文件, {total_changes}处替换")
print(f"替换: '{old_word}' → '{new_word}'")
print("提示: 修改后需要重新打包ROWID.SPF重启GS才能生效")
