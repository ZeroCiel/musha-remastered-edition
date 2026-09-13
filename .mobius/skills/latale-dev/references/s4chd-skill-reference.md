# S4chd 国服简体参考端

## 路径
`D:\LaTale\S4chd\resource\ROWID\DATA\XLS\SKILL s4.xls`

## 概况
- 3937 个 ID（S4端仅3555个）
- 简体中文，Name 和 DisableDescription 全部正确
- 优先于 SKILL2 作为修复参考源

## 用法
按 ID 匹配，只替换 DisableDescription 列（col41），不要整行替换。
```python
s4_disdesc = {}
with open(s4chd_path, 'rb') as f:
    for line in f.read().split(b'\n')[2:]:
        if not line.strip(): continue
        parts = line.split(b'\t')
        if len(parts) < 42: continue
        try: s4_disdesc[int(parts[0])] = parts[41]
        except: pass

with open(skill_path, 'rb') as f:
    cur_lines = f.read().split(b'\n')
for i in range(2, len(cur_lines)):
    line = cur_lines[i]
    parts = line.split(b'\t')
    if len(parts) < 42: continue
    try:
        sid = int(parts[0])
        if sid in s4_disdesc:
            new_parts = parts[:41] + [s4_disdesc[sid]] + parts[42:]
            cur_lines[i] = b'\t'.join(new_parts)
    except: continue
result = b'\n'.join(cur_lines)
```

## S4chd 没有的 ID (残留乱码, 需手动)
1106036, 1109605, 7008572, 6600808, 3605615, 1211003, 1104003, 1105003,
1107100, 1107101, 1109303, 1105034, 1104035, 8003213, 8578579, 1104034,
1106035, 3103435, 8003212, 20213190

## 其他 S4chd 可用文件
- ITEM_2.LDT: D:\LaTale\S4chd\resource\ROWID\DATA\LDT\
- NPC.LDT: D:\LaTale\S4chd\resource\ROWID\DATA\LDT\
