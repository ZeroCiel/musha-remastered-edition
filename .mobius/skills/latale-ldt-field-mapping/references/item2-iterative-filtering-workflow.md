# ITEM_2 迭代筛选工作流（2026-06-04）

## 背景
从彩虹岛编辑器导出ITEM_2.LDT的完整TXT（10056行），逐步筛选出要上架商城的道具。每次筛掉一类不想要的条目，保留 `item2_clean.txt`，最终得到要上架商城的短清单。

## 文件
- `桌面\item2.txt` — 编辑器导出的原始全表TAB分隔，col0=_RowId, col4=_Name, col14=_Type, col15=_SubType
- `桌面\item2_clean.txt` — 每次过滤后覆盖

## 执行过的过滤步骤

### 1. 去除"不使用"和"定制预留"道具
删除名称包含"不使用"或"定制"的道具（测试/占位道具）。
- 删除 175 条
- 保留 9881 → 9878条

### 2. 勋章类：只保留各系列最高强化等级
Type=4,SubType=11（徽章/勋章），只保留MAX/+15/+20等最高级，去掉勤快的劳动者徽章。
- 删除 103 条（各类+0~+14，含财源滚滚、蝴蝶缀饰、浓情密意、樱花漫舞、星光满路、绿野仙踪、玫瑰盛典的弱化版本）
- 保留 9774条 → 后因眼睛类被删 9423条？不对，是9435条

### 3. 眼睛类：按关键词删除
名称含 眼镜/墨镜/眼罩/瞳孔/眼睛/眼尾 的道具删除。注意"眼镜蛇"系类（蛇系列衣服/鞋子/皇冠）是误删，需捞回。
- 删除 342 条，后捞回7条眼镜蛇系 → 净删除 335条

### 4. FLOORP系列：只保留+9和MAX
2020happy New year、C4炸弹 FLOORP、圣诞袜 FLOORP、万圣节南瓜 FLOORP、乌云 FLOORP 这5个系列，只保留+9和MAX，+0~+8删除。
- 删除 45 条

### 5. 韩国合作道具：移除前缀
找到名称含"【韩国专属合作道具，其他国家服无法使用】"的131条道具，去掉此前缀。
- TXT直接文字替换（131条）
- ITEM_2.LDT二进制替换前缀GBK字节（131处，含15处末尾有非法GBK字节的先清理suffix再写回）

### 6. 彩虹泡泡/玫瑰盛典：只保留+9及以上
彩虹泡泡和玫瑰盛典系列，去掉+0~+8，保留+9、MAX、+15。
- 删除 19 条

### 7. 废弃活动装备（待处理）
超高强化等级的道具疑似已废弃活动遗留：
- Miss戒指 +0~+100（101个等级）
- 蕴含舞扇忍者气息的图腾 +0~+99（100个等级）
- 阿思玛的和谐红晕 +0~+30（31个等级）
- 阿思玛的神秘红晕 +0~+30（31个等级）
- 七彩蝴蝶翅膀 +0~+15
- 千机翅膀 +0~+15
- 灵魂破坏者的眼泪 +0~+15
- 祈福同心 +0~+15

## ITEM_2.LDT 二进制改名（去掉名称前缀）

当需要批量修改LDT中的道具名称（去掉统一前缀）时，直接在二进制文件中搜索原名的GBK字节，覆盖写回：

```python
prefix_gbk = '【韩国专属合作道具，其他国家服无法使用】'.encode('gbk')
data = bytearray(open(ldt_path, 'rb').read())

pos = 0
while True:
    idx = data.find(prefix_gbk, pos)
    if idx == -1: break
    if idx < 8512: pos = idx + 1; continue  # 跳过列名区
    
    # 找完整字符串范围（前后\x00界定）
    start = idx
    while start > 0 and data[start - 1] != 0: start -= 1
    end = idx + len(prefix_gbk)
    while end < len(data) and data[end] != 0: end += 1
    
    # 新名字 = 前缀后的内容
    new_gbk = data[idx + len(prefix_gbk):end]
    # 处理非法GBK字节
    try:
        new_str = new_gbk.decode('gbk').strip()
        new_gbk = new_str.encode('gbk')
    except:
        # 字节级别清理非法对
        ...
    
    if len(new_gbk) <= end - start:
        data[start:start+len(new_gbk)] = new_gbk
        for i in range(start+len(new_gbk), end):
            data[i] = 0x20  # 空格填充
    pos = idx + 1
```

注意：
- 必须以字节为单位操作，不要依赖字符串解码（LDT中可能混入非法GBK字节）
- 用空格(0x20)填充多余空间，不要用0x00（会截断字符串并破坏后续字段）
- 前置的`start`回溯找到真正的字符串起始（跳过\x00）

## 通用筛选脚本模板

```python
import csv, re, os

SRC = r'C:\Users\Administrator\Desktop\item2_clean.txt'
COL_NAME = 4

def should_remove(name):
    # 返回 True=删除, False=保留, None=不处理
    if '关键词' in name: return True
    return None

kept = removed = 0
with open(SRC, 'r', encoding='utf-8') as fin, open(SRC+'.tmp', 'w', encoding='utf-8', newline='') as fout:
    for line in fin:
        parts = line.rstrip('\n').split('\t')
        name = parts[COL_NAME].strip()
        result = should_remove(name)
        if result is True:
            removed += 1
            continue
        fout.write(line)
        kept += 1

os.replace(SRC+'.tmp', SRC)
print('保留: %d, 删除: %d' % (kept, removed))
```
