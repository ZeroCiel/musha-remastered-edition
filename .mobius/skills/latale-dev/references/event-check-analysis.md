# EVENT_CHECK.LDT 活动检查表分析

## 文件位置
`D:\彩虹岛\resource\ROWID\DATA\LDT\EVENT_CHECK.LDT`

## 表结构
13列：_Start_Year, _Start_Month, _Start_Day, _Start_Hour, _End_Year, _End_Month, _End_Day, _End_Hour, _Event_id, _Type, _Type_id, _Event_point, _Use

## 实际数据（3行）
该LDT是特殊格式——标准LDT头部声明的数据区（3行x13列）全为0，真实数据以二进制嵌入在偏移0x2208处，文件末尾以END标记结束。

| 字段 | 活动1 | 活动2 | 活动3 |
|------|-------|-------|-------|
| _Start_Year | 2016 | 2016 | 2016 |
| _Start_Month | 5 | 5 | 5 |
| _Start_Day | 19 | 19 | 19 |
| _Start_Hour | 10 | 10 | 10 |
| _End_Year | 2016 | 2016 | 2016 |
| _End_Month | 6 | 6 | 6 |
| _End_Day | 22 | 22 | 22 |
| _End_Hour | 10 | 10 | 10 |
| _Event_id | 16052501 | 16052502 | 16052503 |
| _Type | 1 | 1 | 1 |
| _Type_id | 190144913 | 190144914 | 190144918 |
| _Event_point | 1 | 1 | 1 |
| _Use | 1 | 1 | 1 |

## 解析记录
- 3个活动为完全相同的配置复制3次
- 时间区间：2016-05-19 10:00 ~ 2016-06-22 10:00（已过期）
- _Event_id：16052501~16052503（对应EVENT_INFO表）
- _Type=1，_Type_id=190144913/4/8（指向具体活动内容）
- _Event_point=1
- _Use=1（全部启用）

## 二进制结构详解
- 标准类型区（从8204起，每列4B）声明的是3(通常=int32)
- 标准数据区（从896起，3行x13列x4B=156B）全为零
- **真实数据**从偏移0x2208开始，以连续int32排列（3行x13列=39个int32）
- 真实数据结束后紧跟4个额外int32，然后 END 标记
- 文件剩余空间用空白（0x20空格）填充到文件尾

## 与EXPERIENCE.LDT的区别
| 文件 | 数据结构 | 存储方式 |
|------|---------|---------|
| EXPERIENCE.LDT | ASCII文本嵌入 | 纯文本，行格式 |
| EVENT_CHECK.LDT | 二进制嵌入 | 连续的int32数组 |

## 删除方法
### 方案A：关闭活动（推荐）
将3行的 _Use 字段改为0即可关闭（不删除，保留数据）

### 方案B：二进制清零
1. 备份原文件
2. 偏移0x2208开始，将第12列（_Use，每行偏移12*4=48）写为0
   - 活动1 _Use 在偏移 0x2208 + 48
   - 活动2 _Use 在偏移 0x2208 + 100
   - 活动3 _Use 在偏移 0x2208 + 152
3. 保持END标记和文件尾不变

## Python修改脚本
```python
import struct, shutil

path = r'D:\彩虹岛\resource\ROWID\DATA\LDT\EVENT_CHECK.LDT'
bak = path + '.bak'
shutil.copy2(path, bak)

with open(path, 'rb') as f:
    data = bytearray(f.read())

# 3行13列，从0x2208开始
for row in range(3):
    off = 0x2208 + row * 13 * 4 + 12 * 4  # _Use列
    struct.pack_into('<i', data, off, 0)

with open(path, 'wb') as f:
    f.write(data)
```
