#!/usr/bin/env python3
"""从游戏 exe 提取 UTF-16LE ASCII 范围字符串并按正则过滤。

用法:
    python extract_utf16_strings.py <exe_path> [regex_pattern]

不带 pattern 打印全部 ASCII 范围字符串(索引+内容);
带 pattern 只打印匹配的(大小写不敏感), 例如:
    python extract_utf16_strings.py pbbg_win32.exe 'revive|rescue|downed'
    python extract_utf16_strings.py pbbg_win32.exe 'BTN_LB|BTN_RB'
    python extract_utf16_strings.py pbbg_win32.exe 'Buttons for'

为什么用这个: 老游戏/日式引擎 exe 的文本常以 UTF-16LE(char\\0) 存放,
ASCII `strings` 工具什么都找不到。索引 i 可用于打印相邻字符串看上下文:
    for j in range(max(0,i-2), i+3): print(j, repr(strs[j]))
"""
import re
import sys

def extract(exe_path, pattern=None):
    data = open(exe_path, 'rb').read()
    pat = re.compile(rb'(?:[\x20-\x7e]\x00){4,}')
    rx = re.compile(pattern, re.IGNORECASE) if pattern else None
    strs = [m.group().decode('utf-16-le') for m in pat.finditer(data)]
    return [(i, s) for i, s in enumerate(strs) if rx is None or rx.search(s)]

if __name__ == '__main__':
    path = sys.argv[1]
    pattern = sys.argv[2] if len(sys.argv) > 2 else None
    for i, s in extract(path, pattern):
        print(i, repr(s))
