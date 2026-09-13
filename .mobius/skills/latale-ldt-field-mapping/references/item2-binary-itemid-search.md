# ITEM_2.LDT 二进制搜索ItemID方法

## 场景

已知某个道具的ItemID（如81271605），需要在ITEM_2.LDT中找到它的行信息（名称、Type、SubType等），但格式B二进制解析困难，int列偏移不确定。

## 方法：用ItemID的4字节小端编码在LDT中搜索

```python
import struct

f = open('ITEM_2.LDT', 'rb')
data = f.read()
f.close()

target_id = 81271605
packed = struct.pack('<I', target_id)

idx = data.find(packed)
data_off = 12 + 125*64 + 125*4  # = 8512 (ITEM_2格式B)
row_size = 500

if idx >= data_off:
    row = (idx - data_off) // row_size
    off = data_off + row * row_size
    
    # 读该行的字符串区（第48列之后）
    str_area = data[off+192:off+500]
    strs = []
    s = 0
    while s < len(str_area):
        end = s
        while end < len(str_area) and str_area[end] != 0:
            end += 1
        if end > s:
            try:
                strs.append(str_area[s:end].decode('gbk', errors='replace'))
            except:
                strs.append('<bin>')
        else:
            strs.append('')
        s = end + 1
        if len(strs) >= 8:
            break
    
    print(f'ItemID={target_id}, row={row}')
    for i, s in enumerate(strs):
        if s and len(s) < 60:
            print(f'  str[{i}]: {s}')
else:
    print(f'ItemID {target_id} 不在数据区')
```

## 原理

- ITEM_2.LDT（格式B）的_Num列（ItemID）以4字节小端int存储在行首偏移+4处
- 用 `struct.pack('<I', id)` 生成4字节，在LDT文件中搜索即可定位该行
- 找到后读取字符串区（行偏移192以后，\x00分隔）得到道具名
- 这比解析int列偏移的格式B要可靠，因为ItemID本身就是int32

## 注意事项

- 搜到的偏移可能出现在列名区（偏移<8512），需要过滤掉
- 同一个ItemID可能在文件中出现多次（如同时出现在Name和Description字段的int引用中），但第一次在数据区的命中通常就是_Num列
- 搜到的字符串区内容需要区分_Name和_Description：名通常短（<30字符），描述通常含`\n※参考※`等标记
- 如果LDT文件过大（>10MB），搜索可能较慢，但通常都在1秒内
