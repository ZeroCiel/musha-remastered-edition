# LDT特殊格式表

部分LDT（韩端/台服S2）使用混合存储格式：头部声明标准列结构，但实际数据以ASCII文本嵌入偏移8204之后，原数据区全为零。

## EXPERIENCE.LDT

**位置：** `D:\彩虹岛\resource\ROWID\DATA\LDT\EXPERIENCE.LDT`
**头部说明：** 2列(_MinXp, _MaxXp, type=int32)，255行
**数据状态：** 头部数据区(偏移148~8203)全为零
**真实数据偏移：** 8722 ~ END标记(16067)

### 二进制记录格式

每条记录：
```
[4B level_idx] [4B 0x10000000] [ASCII数字(exp)] [1B 0x20空格]
```

### 解析脚本（Python）

```python
import struct, re

path = 'D:/彩虹岛/resource/ROWID/DATA/LDT/EXPERIENCE.LDT'
with open(path, 'rb') as f:
    data = f.read()

# S2端：文本从8722开始到END
text = data[8722:data.find(b'END')].decode('ascii', errors='replace')
cleaned = re.sub(r'[^\d\s]', ' ', text)
nums = [int(x) for x in cleaned.split() if x.isdigit()]

# 去重保留顺序（去掉Lv50附近1~9的干扰值）
seen = set()
filtered = []
for n in nums:
    if n not in seen:
        seen.add(n)
        if not (len(filtered) > 0 and filtered[-1] > 100000 and n < 10):
            filtered.append(n)

for i, exp in enumerate(filtered):
    if i == 0 and exp == 0:
        continue  # 跳过Lv0=0
    print(f'Lv{i:3d} → {exp:,}')
```

### 经验规律

- **Lv0→Lv1 = 0**（起始级无经验需求）
- **Lv1→Lv2 = 3,004**
- **Lv1~49：线性缓增**，每级增量从~3,000逐渐增长到~10,000
- **Lv50：经验值突变**，Lv50=226,708
- **Lv50~99：快速增长**，从几十万到几百万
- **Lv100~200：指数增长**，Lv100=7,079,720 → Lv200≈1.9e12
- **Lv200~255：** 每级经验高达万亿~百万亿级
- **Lv255上限：** 739,539,197,577,672 (~7.4e14)

### 关键等级经验值一览

| Lv | 所需经验 |
|----|---------|
| 10 | 30,559 |
| 20 | 62,207 |
| 30 | 97,742 |
| 50 | 226,708 |
| 70 | 934,529 |
| 100 | 7,079,720 |
| 150 | 5,644,857,638 |
| 200 | 1,926,397,607,277 |
| 255 | 739,539,197,577,672 |

### S1端差异

S1端（`D:\LaTale\彩虹岛S1\resource\ROWID\DATA\LDT\EXPERIENCE.LDT`）：
- 头部同样2列，但行数=511（0~510级）
- 结构类似，具体偏移需另行计算

## EVENT_CHECK.LDT（活动检查表）

**位置：** `D:\彩虹岛\resource\ROWID\DATA\LDT\EVENT_CHECK.LDT`
**头部说明：** 13列，3行
**数据类型：** 12个int32 + 1个string(`_Use`)，但string区实际为空
**数据状态：** 头部标准数据区全零
**真实数据偏移：** 0x2208（8760十进制），文件末尾以`END`标记结束
**文件大小：** 8,948字节，END在偏移0x22b4

### 数据区结构（偏移0x2208 ~ 0x22a0，3行 x 13列 x 4B = 156字节）

列顺序：`_Start_Year, _Start_Month, _Start_Day, _Start_Hour, _End_Year, _End_Month, _End_Day, _End_Hour, _Event_id, _Type, _Type_id, _Event_point, _Use`

以编辑器导出TXT为准（数据区直接解析会因未对齐而显示异常），该表内容已在 `references/event-check-analysis.md` 中记录。

### 删除/关闭活动的方法
将每行的 `_Use` 字段改为0即可关闭对应活动。

---

## 任务经验表 (QUEST_INFO_1 + QUEST_REWARD_1)

他乡端的任务经验系统独立于主任务表(QUEST.LDT)：
- **QUEST_INFO_1.LDT** (29列, 1607行): 定义任务基础等级(_Quest_BaseLV)、类型(_Quest_Kind)、任务线串联(_Quest_Next)
- **QUEST_REWARD_1.LDT** (33列, 1153行): 行索引与INFO对应，含_Reward_EXP/ _Reward_Ely/ _Reward_Gpoint
- 前100级只有Lv1的4个任务有非零经验（其中行1002有20亿经验为异常值）
- 升级快的原因**不是任务给太多，而是经验表曲线太陡**
- 修改顺序建议：先调EXPERIENCE.LDT再调任务系统

详见 `experience-table-analysis` 技能
