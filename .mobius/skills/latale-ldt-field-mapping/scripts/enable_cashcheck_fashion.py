#!/usr/bin/env python3
"""
ITEM_2 时装 CashCheck 0→1（上架前置步骤）
用法：python enable_cashcheck_fashion.py [部位数字]

部位数字: 3=发型, 4=衣服, 5=裤子, 6=手套, 7=鞋子, 8=披风
不传参数则改全部部位 {3,4,5,6,7,8}（注意不包含11=翅膀位）

前置条件：备份ITEM_2.LDT到.bak_cashcheck
验证：打包SPF重启GS，无报错即可继续追加CASH_SHOP
"""
import struct, os, sys, shutil

LDT_DIR = r'D:\彩虹岛\resource\ROWID\DATA\LDT'
I2_PATH = os.path.join(LDT_DIR, 'ITEM_2.LDT')
BAK_PATH = I2_PATH + '.bak_cashcheck'

# 部位选择
POSID_MAP = {3: '发型', 4: '衣服', 5: '裤子', 6: '手套', 7: '鞋子', 8: '披风'}
ALL_FASHION = {3, 4, 5, 6, 7, 8}  # 注意：不包含11！

if len(sys.argv) > 1:
    target = {int(sys.argv[1])}
else:
    target = ALL_FASHION

with open(I2_PATH, 'rb') as f:
    data = bytearray(f.read())

cc = struct.unpack('<I', data[4:8])[0]
rc = struct.unpack('<I', data[8:12])[0]
col_names = []
col_types = []
for i in range(cc):
    off = 12 + i * 64
    name = data[off:off+64].split(b'\x00')[0].decode('ascii', errors='replace').strip()
    col_names.append(name)
    t = struct.unpack('<I', data[8204 + i*4:8204 + i*4 + 4])[0]
    col_types.append(t)

cc_idx = col_names.index('_CashCheck')
posid1_idx = col_names.index('_PosID1')
desc_idx = col_names.index('_Description')
name_idx = col_names.index('_Name')

pos = 8716
changed = 0
stats = {p: {'total': 0, 'cc0': 0, 'basic': 0, 'cc1': 0} for p in POSID_MAP}

for ri in range(rc):
    rid = struct.unpack('<I', data[pos:pos+4])[0]
    pos += 4
    
    p1 = None; cc_val = None; cc_off = None; desc = ''; nm = ''
    for ci in range(cc):
        t = col_types[ci]
        if t == 1:
            slen = struct.unpack('<H', data[pos:pos+2])[0]
            pos += 2
            s = data[pos:pos+slen].decode('gbk', errors='replace') if slen > 0 else ''
            pos += slen
            if ci == desc_idx: desc = s
            elif ci == name_idx: nm = s
        else:
            if ci == cc_idx: cc_off = pos
            v = struct.unpack('<I', data[pos:pos+4])[0]
            if ci == posid1_idx: p1 = v
            elif ci == cc_idx: cc_val = v
            pos += 4
    
    if p1 not in target:
        continue
    
    s = stats[p1]
    s['total'] += 1
    
    if desc.startswith('基本'):
        s['basic'] += 1
        continue
    
    if cc_val != 0:
        s['cc1'] += 1
        continue
    
    struct.pack_into('<I', data, cc_off, 1)
    s['cc0'] += 1
    changed += 1

print(f"目标部位: {', '.join(f'{k}={v}' for k,v in POSID_MAP.items() if k in target)}")
print()
for p in sorted(target):
    s = stats[p]
    print(f"  {POSID_MAP[p]}({p}): t={s['total']}, 基本={s['basic']}, CC=0→1={s['cc0']}, 原是1={s['cc1']}")

if changed > 0:
    shutil.copy2(I2_PATH, BAK_PATH)
    with open(I2_PATH, 'wb') as f:
        f.write(bytes(data))
    print(f"\n共改 {changed} 件，已备份: {BAK_PATH}")
    print("下一步：打包SPF → 重启GS → 确认正常 → 追加CASH_SHOP")
else:
    print("\n无需修改")
