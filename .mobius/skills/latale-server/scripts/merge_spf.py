#!/usr/bin/env python3
"""
Merge 国服 LDT into S2 SPF — ONLY for structurally compatible files.
Checks: same field count + same field type sequence.
UI_SKIP: 38 UI/MOTION/visual LDTs always keep S2 version.
"""
import struct, os, sys, shutil

sys.path.insert(0, r"D:\彩虹岛")
from ldt_tool import parse_ldt

ENTRY_SIZE = 140
GUOFU_LDT = r"D:\Server\SPF\guofu\DATA\LDT"
S2_EXTRACTED = r"D:\Server\SPF\extracted\DATA\LDT"
OUTPUT_SPF = r"D:\Server\SPF\ROWID_NEW.SPF"
S2_SPF = r"D:\Server\SPF\ROWID.SPF"

# UI 相关 LDT — 不合并国服版，保留 S2 原版
UI_SKIP = {
    "CHAT_COLOR.LDT", "CHAT_COMMAND.LDT", "CHAT_MACRO.LDT", "CHAT_TYPE.LDT",
    "CUT_IN_POS.LDT", "CUTIN_TALK.LDT",
    "FLAG_INFO.LDT",
    "FX_GROUP.LDT", "FX_GROUP_ROBOT.LDT", "FX_LIST.LDT", "FX_UNIT.LDT",
    "GLOBAL_RES.LDT",
    "HELP.LDT", "HELP_CONTENT.LDT", "HELP_MENU.LDT", "HELP_UIBTN.LDT",
    "KEY_DEFAULT.LDT", "KEY_ENABLE.LDT", "KEY_Y.LDT",
    "LOADING_IMAGE.LDT", "LOBBY_MOTION.LDT", "LOCALIZE.LDT",
    "MENU_TOOLTIP.LDT", "MIKE.LDT",
    "MOTION_SOUND.LDT", "MOTION_STATUS.LDT", "MOTIONFX_TYPE.LDT", "MOTIONFX_TYPE2.LDT", "MOTIONTYPE.LDT",
    "NOTICE_RANDOM.LDT",
    "TALKROOM_AUTOSUBJECT.LDT", "TALKROOM_ROOMSTYLE.LDT", "TALKROOM_STYLE.LDT",
    "UI_HELP.LDT", "UI_TOOLTIP.LDT",
    "WORLD_MAP_GROUP.LDT", "WORLD_MAP_IMAGE.LDT", "WORLD_MAP_MENU.LDT", "WORLD_MAP_STAGE.LDT",
    "PROLOGUE_AVATAR.LDT", "PROLOGUE_FX_GROUP.LDT", "PROLOGUE_FX_UNIT.LDT", "PROLOGUE_MESS.LDT",
    "RANDOM_LOADING.LDT",
}

def read_spf_entries(spf_path):
    with open(spf_path, 'rb') as f:
        data = f.read()
    file_size = len(data)
    entries = []
    ptr = file_size - ENTRY_SIZE * 2
    while ptr >= 0:
        path_raw = data[ptr:ptr+128]
        null_pos = path_raw.find(b'\x00')
        if null_pos < 0: null_pos = 128
        path = path_raw[:null_pos].decode('latin-1', errors='replace').strip()
        cp = struct.unpack_from('<i', data, ptr+128)[0]
        cs = struct.unpack_from('<i', data, ptr+132)[0]
        rid = struct.unpack_from('<i', data, ptr+136)[0]
        if cp == 0 or not path: break
        entries.append({'path': path, 'pos': cp, 'size': cs, 'res_id': rid})
        ptr -= ENTRY_SIZE
    entries.reverse()
    return entries, data, file_size

def write_spf(entries_with_data, out_path):
    data_sec = bytearray()
    new_entries = []
    for entry, file_data in entries_with_data:
        new_pos = len(data_sec)
        new_size = len(file_data)
        data_sec.extend(file_data)
        new_entries.append({'path': entry['path'], 'pos': new_pos, 'size': new_size, 'res_id': entry['res_id']})
    
    finfo = bytearray()
    for e in reversed(new_entries):
        pb = e['path'].encode('latin-1', errors='replace')[:127]
        finfo.extend(pb + b'\x00' * (128 - len(pb)))
        finfo.extend(struct.pack('<iii', e['pos'], e['size'], e['res_id']))
    finfo.extend(b'\x00' * ENTRY_SIZE)
    
    with open(out_path, 'wb') as f:
        f.write(data_sec)
        f.write(finfo)
    print(f"  写入: {out_path} ({len(data_sec):,}B + {len(finfo)}B)")
    return new_entries

def ldt_compatible(s2_path, gf_path):
    try:
        s2_h, _ = parse_ldt(s2_path)
        gf_h, _ = parse_ldt(gf_path)
        s2_sig = (s2_h['n_fields'], tuple(s2_h['field_types'][:s2_h['n_fields']]))
        gf_sig = (gf_h['n_fields'], tuple(gf_h['field_types'][:gf_h['n_fields']]))
        return s2_sig == gf_sig, s2_sig, gf_sig
    except:
        return False, None, None

def main():
    if not os.path.exists(S2_SPF + ".bak2"):
        shutil.copy2(S2_SPF, S2_SPF + ".bak2")
        print(f"备份: {S2_SPF}.bak2")
    
    entries, s2_data, s2_size = read_spf_entries(S2_SPF)
    print(f"读取 S2: {len(entries)} 条目")
    
    gf_map = {}
    for f in os.listdir(GUOFU_LDT):
        if f.endswith('.LDT'):
            gf_map[f.upper()] = os.path.join(GUOFU_LDT, f)
    
    entries_with_data = []
    replaced = 0
    kept = 0
    skipped_struct = 0
    
    for entry in entries:
        basename = os.path.basename(entry['path']).upper()
        s2_extracted_path = os.path.join(S2_EXTRACTED, basename)
        
        if basename in gf_map:
            # 跳过 UI 相关的 LDT — 保留 S2 原版
            if basename in UI_SKIP:
                orig = s2_data[entry['pos']:entry['pos']+entry['size']]
                entries_with_data.append((entry, orig))
                continue
            
            ok, s2sig, gfsig = ldt_compatible(s2_extracted_path, gf_map[basename])
            
            if ok:
                with open(gf_map[basename], 'rb') as f:
                    gf_data = f.read()
                entries_with_data.append((entry, gf_data))
                replaced += 1
                if replaced <= 10:
                    print(f"  ✓ 替换: {entry['path']} ({entry['size']}→{len(gf_data)}B)")
            else:
                orig = s2_data[entry['pos']:entry['pos']+entry['size']]
                entries_with_data.append((entry, orig))
                skipped_struct += 1
                if skipped_struct <= 5:
                    print(f"  ✗ 跳过(结构不同): {entry['path']} S2:{s2sig} ≠ 国:{gfsig}")
        else:
            orig = s2_data[entry['pos']:entry['pos']+entry['size']]
            entries_with_data.append((entry, orig))
            kept += 1
    
    print(f"\n结果: {replaced} 替换 + {skipped_struct} 跳过(结构不同) + {kept} S2独有 = {len(entries_with_data)}")
    
    write_spf(entries_with_data, OUTPUT_SPF)
    shutil.copy2(OUTPUT_SPF, S2_SPF)
    print(f"\n★ 完成! ROWID.SPF 已更新 ({replaced} 个文件替换为国服文本) ★")

if __name__ == '__main__':
    main()
