# SKILL.xls 按Name种类批量还原 — S4端实测（2026-06-07）

## 情景

S4端 SKILL.xls（D:\LaTale\S4\resource\ROWID\DATA\XLS\）中，用户手动将 Name 从乱码改为中文，GS 报 `iSkillID not found`。这里记录了用.bak3还原"生存本能"种类25行 Name 的完整过程。

## 判断标准

| Name 状态 | 含义 | GS 行为 |
|-----------|------|---------|
| GBK乱码（如 `〖 积粮夯瓷 〗`） | 原始正确数据 | 正常加载 |
| 正常中文（如 `【 生存本能 】`） | 手动改过 | 报 iSkillID not found |

## 目标种类：生存本能

**GS报错ID**：3812606
**ID范围**：3812606（行2095）~ 3817306（行3360）
**同Name行数**：25行

### 所有涉及的ID

3812606, 3812706, 3812806, 3812906, 3813006, 3813106, 3813206,
3813606, 3813706, 3813806, 3813906, 3814006, 3814106, 3814206,
3814306, 3814406, 3814506, 3814906, 3815206, 3815606, 3816006,
3816406, 3816806, 3816906, 3817306

### Name字节值对比

| 来源 | 字节 | 解码 |
|------|------|------|
| 当前SKILL.xls（损坏） | `\xa1\xbe \xc9\xfa\xb4\xe6\xb1\xbe\xc4\xdc \xa1\xbf` | 【 生存本能 】 |
| SKILL.xls.bak3（原始） | `\xa1\xbc \xbb\xfd\xc1\xb8\xba\xbb\xb4\xc9 \xa1\xbd` | 〖 积粮夯瓷 〗 |

### 替换脚本核心逻辑

```python
import shutil
src = r'D:\LaTale\S4\resource\ROWID\DATA\XLS\SKILL.xls'
bak = src + '.bak_before_survival'
shutil.copy2(src, bak)

with open(src, 'rb') as f:
    raw = bytearray(f.read())
lines = raw.split(b'\n')

old_name = b'\xa1\xbe \xc9\xfa\xb4\xe6\xb1\xbe\xc4\xdc \xa1\xbf'
new_name = b'\xa1\xbc \xbb\xfd\xc1\xb8\xba\xbb\xb4\xc9 \xa1\xbd'

count = 0
for i in range(len(lines)):
    parts = lines[i].split(b'\t')
    if len(parts) >= 2 and parts[1] == old_name:
        lines[i] = parts[0] + b'\t' + new_name + b'\t' + b'\t'.join(parts[2:])
        count += 1

result = b'\n'.join(lines)
with open(src, 'wb') as f:
    f.write(result)
print(f'替换完成: {count}行')
```

## 还原后的用户操作

Name 还原为原始乱码后，用户用彩虹岛编辑器打开 SKILL.xls，在编辑器界面中逐行将 Name 改为正确中文（如"生存本能"）。编辑器负责编码转换，不会破坏GS可识别的格式。

## 备份链

| 文件 | 作用 |
|------|------|
| SKILL.xls.bak3（之前已有） | S3覆盖前的备份，含原始Name |
| SKILL.xls.bak_before_survival（本次新建） | 本次替换前的快照 |
