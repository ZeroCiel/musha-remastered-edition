#!/usr/bin/env python3
"""
从ITEM_2.LDT筛选时装->生成CASH_SHOP格式.xls
用法：python gen_cashshop_xls.py <ITEM_2.LDT路径> <输出xls路径>
默认：ITEM_2路径=D:\彩虹岛\resource\ROWID\DATA\LDT\ITEM_2.LDT
      输出=C:\Users\Administrator\Desktop\时装追加_CASH_SHOP格式.xls

生成65列xls（第1列_RowId + 64个CASH_SHOP字段），第1行为字段名。
RowId从2400开始（非1，非最大RowId+1），PositionIndex从912008递增。
用xlwt生成.xls（不是xlsx），用户导入工具已验证通过。
"""
import struct, os, sys
import xlwt

# CASH_SHOP 64字段名（按顺序）
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

# 完整表头（65列：_RowId + 64 CASH_SHOP字段）
FULL_HEADERS = ['_RowId'] + CS_HEADERS

POSIDX_START = 912008
ROWID_START = 2400


def parse_item2(ldt_path):
    """解析ITEM_2.LDT，返回时装列表（已过滤基础发型）"""
    with open(ldt_path, 'rb') as f:
        data = bytearray(f.read())

    col_count = struct.unpack('<I', data[4:8])[0]
    row_count = struct.unpack('<I', data[8:12])[0]

    col_names = []
    col_types = []
    for i in range(col_count):
        off = 12 + i * 64
        name = data[off:off+64].split(b'\x00')[0].decode('ascii', errors='replace').strip()
        col_names.append(name)
        t = struct.unpack('<I', data[8204 + i*4:8204 + i*4 + 4])[0]
        col_types.append(t)

    name_idx = col_names.index('_Name')
    posid1_idx = col_names.index('_PosID1')
    cc_idx = col_names.index('_CashCheck')
    life_idx = col_names.index('_Lifetime')
    ttype_idx = col_names.index('_Time_Type')
    icon_idx = col_names.index('_Icon')
    iconidx_idx = col_names.index('_IconIndex')

    FASHION_POSIDS = {3, 4, 5, 6, 7, 8, 11}
    items = []

    pos = 8716
    for ri in range(row_count):
        if pos + 4 > len(data): break
        row_id = struct.unpack('<I', data[pos:pos+4])[0]
        pos += 4
        
        vals = {}
        for ci in range(col_count):
            if pos + 4 > len(data): break
            t = col_types[ci]
            if t == 1:
                slen = struct.unpack('<H', data[pos:pos+2])[0]
                pos += 2
                val = ''
                if slen > 0 and pos + slen <= len(data):
                    val = data[pos:pos+slen].decode('gbk', errors='replace')
                    pos += slen
                vals[ci] = val
            elif t in (0, 2, 3):
                v = struct.unpack('<I', data[pos:pos+4])[0]
                vals[ci] = v
                pos += 4
            else:
                pos += 4
                vals[ci] = 0
        
        p1 = vals.get(posid1_idx, 0)
        cc = vals.get(cc_idx, 1)
        
        if p1 in FASHION_POSIDS and cc == 0:
            n = str(vals.get(name_idx, '')).strip()
            if not n:
                n = '未命名'
            
            # 过滤：Description以"基本"开头的基础发型/眼型/皮肤
            # 用户2026-05-28确认：_Description='基本发型_女_XXX'等为创角基础模板，不应上架商城
            desc = str(vals.get(desc_idx, ''))
            if desc.startswith('基本'):
                continue
            
            items.append({
                'id': row_id,
                'name': n,
                'posid': p1,
                'has_time': vals.get(life_idx, 0) > 0 or vals.get(ttype_idx, 0) > 0,
                'icon': vals.get(icon_idx, 10001201),
                'iconidx': vals.get(iconidx_idx, 1),
            })
    return items


def make_row(item, rowid, posidx):
    """为单个时装生成65列数据（含_RowId）"""
    if item['has_time']:
        cat_v, ci1, ci2, ci3 = 1, 7, 22, 0
        ev_type, ev_icon, limited = 1, 1, 2
    else:
        if item['posid'] == 3:
            cat_v, ci1, ci2, ci3 = 1, 1, 2, 5
        elif item['posid'] == 4:
            cat_v, ci1, ci2, ci3 = 1, 1, 1, 4
        else:
            cat_v, ci1, ci2, ci3 = 1, 1, 1, 0
        ev_type, ev_icon, limited = 0, 0, 0
    
    return [
        rowid,  # _RowId（第1列）
        cat_v, ci1, ci2, ci3,
        posidx, ev_type,
        item['name'], '',
        item['icon'], item['iconidx'],
        0, 1, 240, 0, ev_icon,
        item['id'], 1, 1, 1,
        0, 1, 0, 0,  # ID2
        0, 1, 0, 0,  # ID3
        0, 1, 0, 0,  # ID4
        0, 1, 0, 0,  # ID5
        0, 1, 0, 0,  # ID6
        0, 1, 0, 0,  # ID7
        0, 1, 0, 0,  # ID8
        0, 0,  # MotionID, ClassID
        0, 0, 0, 0,  # Require1
        0, 0, 0, 0,  # Require2
        0, 0, 0, 0,  # Require3
        1, 1, limited,
    ]


def write_xls(items, output_path):
    wb = xlwt.Workbook(encoding='utf-8')
    ws = wb.add_sheet('时装追加')
    
    header_style = xlwt.XFStyle()
    hf = xlwt.Font()
    hf.bold = True
    hf.height = 200
    header_style.font = hf
    hb = xlwt.Borders()
    hb.left = 1; hb.right = 1; hb.top = 1; hb.bottom = 1
    header_style.borders = hb
    ha = xlwt.Alignment()
    ha.horz = xlwt.Alignment.HORZ_CENTER
    header_style.alignment = ha
    
    data_style = xlwt.XFStyle()
    db = xlwt.Borders()
    db.left = 1; db.right = 1; db.top = 1; db.bottom = 1
    data_style.borders = db
    
    for col_idx, h in enumerate(FULL_HEADERS):
        ws.write(0, col_idx, h, header_style)
    
    for i, item in enumerate(items):
        row_data = make_row(item, ROWID_START + i, POSIDX_START + i)
        for col_idx, v in enumerate(row_data):
            ws.write(i + 1, col_idx, v, data_style)
    
    col_widths = [10]  # _RowId
    for h in CS_HEADERS:
        if 'Name' in h or 'Description' in h:
            col_widths.append(30)
        elif 'Require' in h or h.startswith('_ItemID'):
            col_widths.append(14)
        else:
            col_widths.append(12)
    for i, w in enumerate(col_widths):
        ws.col(i).width = w * 256
    
    wb.save(output_path)


if __name__ == '__main__':
    item2_path = r'D:\彩虹岛\resource\ROWID\DATA\LDT\ITEM_2.LDT' if len(sys.argv) < 2 else sys.argv[1]
    output_path = r'C:\Users\Administrator\Desktop\时装追加_CASH_SHOP格式.xls' if len(sys.argv) < 3 else sys.argv[2]
    
    items = parse_item2(item2_path)
    write_xls(items, output_path)
    
    perm = sum(1 for x in items if not x['has_time'])
    timed = sum(1 for x in items if x['has_time'])
    print(f'共 {len(items)} 件时装（永久 {perm}，时限 {timed}）')
    print(f'RowId从{ROWID_START}开始，PositionIndex从{POSIDX_START}开始')
    print(f'已过滤基础发型（短发/中长/长发/基本发型/基本眼型）')
    print(f'已输出: {output_path}')
