#!/usr/bin/env python3
"""
生成时装CASH_SHOP追加清单（txt | 分隔 + xls）

用法：
  python gen_fashion_export.py              # 全部时装
  python gen_fashion_export.py 3             # 只发型
  python gen_fashion_export.py 3 4           # 发型+衣服

输出：桌面 → 时装追加_CASH_SHOP格式.txt 和 .xls
  txt: | 分隔，64列（不含_RowId），可复制粘贴到彩虹岛编辑器
  xls: 65列（含_RowId），Excel查看用
"""
import struct, os, sys, xlwt

LDT_DIR = r'D:\彩虹岛\resource\ROWID\DATA\LDT'
I2_PATH = os.path.join(LDT_DIR, 'ITEM_2.LDT')

POSID_MAP = {3: '发型', 4: '衣服', 5: '裤子', 6: '手套', 7: '鞋子', 8: '披风'}
CS_HEADERS = [
    '_CategoryView','_CategoryIndex','_CategoryIndex2','_CategoryIndex3',
    '_PositionIndex','_EventType','_Name','_Description',
    '_IconFile','_IconIndex','_Gender','_PriceType','_CashPrice','_SalePrice','_EventIcon',
    '_ItemID1','_ItemRare1','_ItemCount1','_PriceRate1',
    '_ItemID2','_ItemRare2','_ItemCount2','_PriceRate2',
    '_ItemID3','_ItemRare3','_ItemCount3','_PriceRate3',
    '_ItemID4','_ItemRare4','_ItemCount4','_PriceRate4',
    '_ItemID5','_ItemRare5','_ItemCount5','_PriceRate5',
    '_ItemID6','_ItemRare6','_ItemCount6','_PriceRate6',
    '_ItemID7','_ItemRare7','_ItemCount7','_PriceRate7',
    '_ItemID8','_ItemRare8','_ItemCount8','_PriceRate8',
    '_MotionID','_ClassID',
    '_Require1_Type','_Require1_ID','_Require1_Value1','_Require1_Value2',
    '_Require2_Type','_Require2_ID','_Require2_Value1','_Require2_Value2',
    '_Require3_Type','_Require3_ID','_Require3_Value1','_Require3_Value2',
    '_Buy_Disable','_Give_Disable','_Limited_Time_Type',
]

ROWID_START = 2400
POSIDX_START = 912008

if len(sys.argv) > 1:
    targets = set(int(a) for a in sys.argv[1:])
else:
    targets = {3, 4, 5, 6, 7, 8}

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

posid1_idx = col_names.index('_PosID1')
name_idx = col_names.index('_Name')
desc_idx = col_names.index('_Description')
life_idx = col_names.index('_Lifetime')
ttype_idx = col_names.index('_Time_Type')
icon_idx = col_names.index('_Icon')
iconidx_idx = col_names.index('_IconIndex')
cc_idx = col_names.index('_CashCheck')

items = []
pos = 8716
for ri in range(rc):
    if pos + 4 > len(data): break
    row_id = struct.unpack('<I', data[pos:pos+4])[0]
    pos += 4
    vals = {}
    for ci in range(cc):
        if pos + 4 > len(data): break
        t = col_types[ci]
        if t == 1:
            slen = struct.unpack('<H', data[pos:pos+2])[0]
            pos += 2
            val = data[pos:pos+slen].decode('gbk', errors='replace') if slen > 0 else ''
            pos += slen
            vals[ci] = val
        else:
            vals[ci] = struct.unpack('<I', data[pos:pos+4])[0]
            pos += 4
    
    p1 = vals.get(posid1_idx, 0)
    if p1 not in targets: continue
    desc = str(vals.get(desc_idx, ''))
    if desc.startswith('基本'): continue
    n = str(vals.get(name_idx, '')).strip()
    if not n: continue
    
    items.append({
        'id': row_id, 'name': n, 'posid': p1,
        'has_time': vals.get(life_idx, 0) > 0 or vals.get(ttype_idx, 0) > 0,
        'icon': vals.get(icon_idx, 10001201),
        'iconidx': vals.get(iconidx_idx, 1),
        'cashcheck': vals.get(cc_idx, 0),
    })

target_names = ', '.join(f'{k}={v}' for k,v in POSID_MAP.items() if k in targets)
perm = sum(1 for x in items if not x['has_time'])
timed = sum(1 for x in items if x['has_time'])
cc0 = sum(1 for x in items if x['cashcheck'] == 0)
print(f"共 {len(items)} 件 ({target_names})")
print(f"  永久{perm}, 时限{timed}")
print(f"  CashCheck=0: {cc0} (需先执行enable_cashcheck_fashion.py)")

# --- TXT输出（|分隔，64列，可粘贴到编辑器）---
lines = ['|'.join(CS_HEADERS)]
for i, item in enumerate(items):
    if item['has_time']:
        cv, c1, c2, c3 = 1, 7, 22, 0
        ev, ev_icon, limited = 1, 1, 2
    else:
        if item['posid'] == 3:
            cv, c1, c2, c3 = 1, 1, 2, 5
        elif item['posid'] == 4:
            cv, c1, c2, c3 = 1, 1, 1, 4
        elif item['posid'] == 5:
            cv, c1, c2, c3 = 1, 1, 1, 2
        elif item['posid'] == 6:
            cv, c1, c2, c3 = 1, 1, 4, 10
        elif item['posid'] == 7:
            cv, c1, c2, c3 = 1, 1, 3, 8
        elif item['posid'] == 8:
            cv, c1, c2, c3 = 1, 1, 1, 4
        else:
            cv, c1, c2, c3 = 1, 1, 1, 0
        ev, ev_icon, limited = 0, 0, 0
    
    name = item['name'].replace('|', '丨')
    vals = [
        str(cv), str(c1), str(c2), str(c3),
        str(POSIDX_START + i), str(ev),
        name, '',
        str(item['icon']), str(item['iconidx']),
        '0', '1', '240', '0', str(ev_icon),
        str(item['id']), '1', '1', '1',
        '0','1','0','0',
        '0','1','0','0',
        '0','1','0','0',
        '0','1','0','0',
        '0','1','0','0',
        '0','1','0','0',
        '0','1','0','0',
        '0','0',
        '0','0','0','0',
        '0','0','0','0',
        '0','0','0','0',
        '1','1',str(limited),
    ]
    lines.append('|'.join(vals))

txt_content = '\n'.join(lines)
txt_path = r'C:\Users\Administrator\Desktop\时装追加_CASH_SHOP格式.txt'
with open(txt_path, 'w', encoding='utf-8') as f:
    f.write(txt_content)
print(f"txt: {txt_path} ({len(txt_content):,}字节)")

# --- XLS输出（65列，含_RowId）---
wb = xlwt.Workbook(encoding='utf-8')
ws = wb.add_sheet('时装追加')
header_style = xlwt.XFStyle()
hf = xlwt.Font(); hf.bold = True; hf.height = 200
header_style.font = hf
hb = xlwt.Borders(); hb.left = 1; hb.right = 1; hb.top = 1; hb.bottom = 1
header_style.borders = hb
ha = xlwt.Alignment(); ha.horz = xlwt.Alignment.HORZ_CENTER
header_style.alignment = ha
data_style = xlwt.XFStyle()
db = xlwt.Borders(); db.left = 1; db.right = 1; db.top = 1; db.bottom = 1
data_style.borders = db

full_headers = ['_RowId'] + CS_HEADERS
for ci, h in enumerate(full_headers):
    ws.write(0, ci, h, header_style)

for i, item in enumerate(items):
    if item['has_time']:
        cv, c1, c2, c3 = 1, 7, 22, 0
        ev, ev_icon, limited = 1, 1, 2
    else:
        cat_map = {3: (1,1,2,5), 4: (1,1,1,4), 5: (1,1,1,2),
                   6: (1,1,4,10), 7: (1,1,3,8), 8: (1,1,1,4)}
        cv, c1, c2, c3 = cat_map.get(item['posid'], (1,1,1,0))
        ev, ev_icon, limited = 0, 0, 0
    
    row_data = [
        ROWID_START + i,
        cv, c1, c2, c3,
        POSIDX_START + i, ev,
        item['name'], '',
        item['icon'], item['iconidx'],
        0, 1, 240, 0, ev_icon,
        item['id'], 1, 1, 1,
        0,1,0,0, 0,1,0,0, 0,1,0,0, 0,1,0,0,
        0,1,0,0, 0,1,0,0, 0,1,0,0,
        0,0,
        0,0,0,0, 0,0,0,0, 0,0,0,0,
        1,1,limited,
    ]
    for ci, v in enumerate(row_data):
        ws.write(i + 1, ci, v, data_style)

col_widths = [10] + [30 if ('Name' in h or 'Description' in h) else 14 if ('Require' in h or 'ItemID' in h) else 12 for h in CS_HEADERS]
for i, w in enumerate(col_widths):
    ws.col(i).width = w * 256

xls_path = r'C:\Users\Administrator\Desktop\时装追加_CASH_SHOP格式.xls'
wb.save(xls_path)
print(f"xls: {xls_path}")
