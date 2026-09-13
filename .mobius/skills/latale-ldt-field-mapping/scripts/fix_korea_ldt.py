#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ITEM_2.LDT 道具名前缀批量去除工具
场景：去掉"【韩国专属合作道具，其他国家服无法使用】"前缀
原理：在LDT二进制中搜索前缀GBK编码，找到后去掉前缀，剩余用空格填充

⚠️ 高危操作：必须用0x20（空格）填充剩余位，不要用0x00！
"""

import os

LDT_PATH = r'D:\LaTale\S2\resource\ROWID\DATA\LDT\ITEM_2.LDT'
PREFIX = '【韩国专属合作道具，其他国家服无法使用】'
DATA_OFF = 8512  # ITEM_2.LDT 数据区起始偏移

def fix_prefixes(path=LDT_PATH):
    prefix_gbk = PREFIX.encode('gbk')
    plen = len(prefix_gbk)
    data = bytearray(open(path, 'rb').read())
    
    found = 0
    skipped = 0
    pos = 0
    
    while True:
        idx = data.find(prefix_gbk, pos)
        if idx == -1:
            break
        if idx < DATA_OFF:
            pos = idx + 1
            continue
        
        # 定位字符串边界
        start = idx
        while start > 0 and data[start - 1] != 0:
            start -= 1
        end = idx + plen
        while end < len(data) and data[end] != 0:
            end += 1
        if end <= start:
            pos = idx + 1
            continue
        
        old_len = end - start
        
        # 提取后缀（去掉前缀后的部分）
        suffix_raw = data[idx + plen:end]
        
        # 尝试GBK解码，非法字节逐字节过滤
        new_gbk = bytearray()
        i = 0
        while i < len(suffix_raw):
            b = suffix_raw[i]
            if b < 0x80:
                if 0x20 <= b <= 0x7e:
                    new_gbk.append(b)
                i += 1
            elif 0x81 <= b <= 0xfe:
                if i + 1 < len(suffix_raw):
                    pair = suffix_raw[i:i+2]
                    try:
                        pair.decode('gbk')
                        new_gbk.extend(pair)
                    except:
                        pass
                    i += 2
                else:
                    i += 1
            else:
                i += 1
        new_gbk = bytes(new_gbk)
        
        if len(new_gbk) <= old_len:
            data[start:start + len(new_gbk)] = new_gbk
            # ⚠️ 用空格(0x20)填充，不用0x00！
            for i in range(start + len(new_gbk), end):
                data[i] = 0x20
            found += 1
        else:
            skipped += 1
        
        pos = idx + 1
    
    if found > 0:
        open(path, 'wb').write(data)
    return found, skipped


if __name__ == '__main__':
    f, s = fix_prefixes()
    print('替换: %d, 跳过: %d' % (f, s))
