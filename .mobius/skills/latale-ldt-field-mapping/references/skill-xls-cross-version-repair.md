# SKILL.xls 跨版本文本修复（ID映射对照法）

## 适用场景
S2/S3/S4不同端的SKILL.LDT中_Name/_Description显示乱码（如"饭骇捞 何练钦聪促"、"剧颊八 付胶磐府[檬鞭]"、"沥飞狼 泪犁仿"），但另一版本的SKILL.xls文本正常且ID体系一致。

## 根因
UTF-8或其他编码写入的文本被彩虹岛编辑器当GBK读出，字节边界错位导致乱码。**不可逆**——不能用转码算法恢复。

## 修复原理
彩虹岛SKILL数据虽然版本不同，但**_ID是同一套编号体系**（如8000301=熟练双手剑[初级]）。利用这一事实，从对照端按ID提取_Name和_Description，覆盖到当前端。

## 修复步骤

### 1. 准备对照端
```python
with open('对照端/SKILL.xls', 'rb') as f:
    raw = f.read()
text = raw.decode('gbk', errors='replace')
lines = text.split('\n')
col_names = lines[1].strip().split('\t')
name_idx = col_names.index('_Name')
desc_idx = col_names.index('_Description')

ref_map = {}
for line in lines[2:]:
    parts = line.strip().split('\t')
    if len(parts) > desc_idx:
        sid = parts[0].strip()
        name = parts[name_idx].strip()
        desc = parts[desc_idx].strip()
        if sid and name:
            ref_map[sid] = (name, desc)
```

### 2. 判断乱码（CJK字符比例法）
```python
cjk = sum(1 for c in cur_name if '\u4e00' <= c <= '\u9fff')
is_garbled = cjk < len(cur_name) * 0.3 if len(cur_name) > 0 else True
s3_cjk = sum(1 for c in ref_name if '\u4e00' <= c <= '\u9fff')
ref_good = s3_cjk >= len(ref_name) * 0.3 if len(ref_name) > 0 else False

if is_garbled and ref_good:
    # 替换_Name
    parts[name_idx] = ref_name
```

### 3. 验证
写回后搜已知乱码关键词确认无残留：
```python
for kw in ['沥飞狼', '付牢靛', '饭骇', '剧颊']:
    if kw in text:
        print('残留:', kw, len(lines), '行')
```

## 已知对照源
| 源 | 路径 | 说明 |
|----|------|------|
| 怀旧端(S2) | D:\\ROWID\\DATA\\XLS\\SKILL.xls | 3259条，绝大部分Name正常 |
| 台服S3 | D:\\LaTale\\彩虹岛S3\\ROWID\\DATA\\XLS\\SKILL.xls | 3541条，约260条Name乱码 |

## 注意事项
- 对照端也可能有乱码（S3约260条），用CJK比例过滤
- **只改xls不够**——必须用彩虹岛编辑器把xls写回SKILL.LDT，GS才生效
- xls备份保留（SKILL.xls.bak3等），改坏可恢复
- 修改时备份原xls：`shutil.copy('SKILL.xls', 'SKILL.xls.bak')`

## 已知乱码对照（调试用）
| 乱码 | 正确文本 |
|------|---------|
| 剧颊八 付胶磐府[檬鞭] | 熟练双手剑[初级] |
| 剧颊八 付胶磐府[吝鞭] | 熟练双手剑[中级] |
| 剧颊八 付胶磐府[惑鞭] | 熟练双手剑[高级] |
| 沥飞狼 泪犁仿 | 精灵潜力 |
| 付牢靛 牧飘费 | (念力控制相关技能) |
| 饭骇 | (大量技能名中的通用乱码字) |
