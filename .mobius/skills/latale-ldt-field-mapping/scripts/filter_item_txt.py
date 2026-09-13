#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
彩虹岛 ITEM_2.txt 批量过滤器
从编辑器导出的完整TAB分隔TXT中，按多种规则过滤数据。
输出 item2_clean.txt 到桌面。
"""

import csv, re, os
from collections import defaultdict

# ======================== 配置 ========================
INPUT = r'C:\Users\Administrator\Desktop\item2.txt'
OUTPUT = r'C:\Users\Administrator\Desktop\item2_clean.txt'
SHOP = r'C:\Users\Administrator\Desktop\商店.txt'

COL_NAME = 4    # 道具名
COL_TYPE = 9    # _Type（确认：从彩虹泡泡看，col9=4, col10=3）
COL_SUBTYPE = 10
COL_ROWID = 0   # RowId = 商店.txt的ItemID1

# ======================== 规则 ========================
# Step 1: 基础过滤（名称关键词）
BAD_KEYWORDS = ['不使用', '定制']

def has_bad_keyword(name):
    for kw in BAD_KEYWORDS:
        if kw in name:
            return True
    return False

# Step 2: 眼睛类
EYE_KEYWORDS = ['眼镜', '墨镜', '眼罩', '眼睛', '眼尾', '瞳孔']

def has_eye_keyword(name):
    for kw in EYE_KEYWORDS:
        if kw in name:
            return True
    return False

# Step 2b: 眼睛类误删捞回
RECOVER_EYES = {
    '眼镜蛇下衣', '眼镜蛇凉鞋', '眼镜蛇比基尼上衣（女）',
    '眼镜蛇法老上衣（男）', '眼镜蛇王冠', '活动眼镜蛇王冠(30日)',
    '[活动]眼镜蛇皇冠',
}

# Step 5: 强化结晶系列只保留+9和MAX/最高
REMOVE_LOW_ENHANCE = [
    ('彩虹泡泡', 9),
    ('玫瑰盛典', 9),
    ('2020happy New year', 9),
    ('C4炸弹 FLOORP', 9),
    ('圣诞袜 FLOORP', 9),
    ('万圣节南瓜 FLOORP', 9),
    ('乌云 FLOORP', 9),
]

# Step 8: 过期活动
REMOVE_LEGACY = [
    ('祈福同心', 15),      # 只留+15
    ('千机翅膀', 15),      # 只留+15
    ('七彩蝴蝶翅膀', 15),  # 只留+15
]
REMOVE_ALL = ['蕴含舞扇忍者气息的图腾']  # 全部删除

def should_remove_enhance(name):
    """检查名称是否应因低等级被删除"""
    for base, min_keep in REMOVE_LOW_ENHANCE + REMOVE_LEGACY:
        m = re.match(r'^%s(.*)$' % re.escape(base), name)
        if m:
            suffix = m.group(1)
            if not suffix:
                return True  # 基础名（无+号）删
            if suffix == ' MAX':
                return False
            m2 = re.search(r'\+(\d+)$', suffix)
            if m2:
                return int(m2.group(1)) < min_keep
            return False
    return None

def should_delete_all(name):
    for base in REMOVE_ALL:
        if name.startswith(base):
            return True
    return False

# ======================== 主流程 ========================
if __name__ == '__main__':
    # 读商店已上架的ItemID
    shop_ids = set()
    if os.path.exists(SHOP):
        with open(SHOP, encoding='utf-8') as f:
            for line in f:
                parts = line.rstrip('\n').split('\t')
                if len(parts) > 16 and parts[16].strip() not in ('0', ''):
                    shop_ids.add(parts[16].strip())
        print('商店已有: %d 条' % len(shop_ids))

    total = 0
    kept = 0
    removed = 0
    reasons = defaultdict(int)

    with open(INPUT, 'r', encoding='utf-8') as fin, \
         open(OUTPUT, 'w', encoding='utf-8', newline='') as fout:
        writer = csv.writer(fout, delimiter='\t')
        for line in fin:
            parts = line.rstrip('\n').split('\t')
            if len(parts) < 11:
                total += 1; writer.writerow(parts); kept += 1
                continue

            name = parts[COL_NAME].strip()
            typ = parts[COL_TYPE].strip()
            subtype = parts[COL_SUBTYPE].strip()
            rowid = parts[COL_ROWID].strip()

            total += 1

            # Step 1: 基础过滤
            if has_bad_keyword(name):
                removed += 1; reasons['不使用/定制'] += 1
                continue

            # Step 2: 眼睛类（排除眼镜蛇）
            if has_eye_keyword(name) and name not in RECOVER_EYES:
                removed += 1; reasons['眼睛类'] += 1
                continue

            # Step 3: 勋章类 + 强化结晶仅保留高级
            r = should_remove_enhance(name)
            if r is not None and r:
                removed += 1; reasons['低强化'] += 1
                continue

            # Step 4: 全部删除类
            if should_delete_all(name):
                removed += 1; reasons['废弃活动'] += 1
                continue

            writer.writerow(parts)
            kept += 1

    print('总计: %d, 保留: %d, 删除: %d' % (total, kept, removed))
    for reason, cnt in sorted(reasons.items(), key=lambda x: -x[1]):
        print('  %s: %d' % (reason, cnt))
    print('输出: %s' % OUTPUT)
