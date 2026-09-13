# ITEM_2 批量筛选→商城写入技术备忘（2026-06-04）

## 核心发现：CashCheck 0→1 暴露隐藏的坏数据

**现象**：改CashCheck前服务端正常，改后GS/Server在加载特定ItemID时报错崩溃。

**原因**：ITEM_2.LDT中某些道具行存在无效数据（EffectID=16777216、SetID=65536等），
CashCheck=0时GS不花时间校验这些字段，CashCheck=1后GS尝试完整加载它们到内存，触发校验失败。

**根因溯源**：这些65536(0x10000)和16777216(0x1000000)是位标记值，不是真实ID。
可能是彩虹岛编辑器/打包工具在创建或复制行时，某些高位字节没清干净留下的。

**修复方法**：
1. 在LDT二进制中全局搜索所有65536和16777216并清0（12830处）
2. 或只在出错的ItemID行中查找并清0

## 二进制修改ITEM_2.LDT的安全边界

| 操作 | 安全吗？ | 说明 |
|------|---------|------|
| 改int列(CashCheck/Type等) | ✅ 安全 | 4字节固定，无边界问题 |
| 改string列(Name/Description) | ❌ 危险 | 变长\x00终止，短了没填满会破环文件 |
| 全局替换65536→0 | ✅ 安全 | int列全部为0不影响功能 |
| 用GBK搜索定位行 | ✅ 安全 | `data.find(name_gbk, DATA_OFF)` |

## 彩虹岛编辑器XLS文件格式总结

```
第1行: 列类型号（如 "3\t3\t3\t1\t1..."）
第2行: 列名（如 "_Category\t_Num\t_ColorID..."）
第3行起: TAB分隔的数据行
编码: GBK
魔数: "Type\t3\t3"
```

### 关键列索引（0-based）

**ITEM_2.xls**
| 索引 | 列名 | 说明 |
|------|------|------|
| 0 | (_RowId) | 编辑器显示ID，不是LDT字段 |
| 1 | _Num | 道具ID |
| 3 | _Name | 道具名（GBK） |
| 11 | _CashCheck | 0=禁止上架, 1=允许 |
| 14 | _Type | 物品大类 |
| 15 | _SubType | 子类 |

**CASH_SHOP.xls**
| 索引 | 列名 | 说明 |
|------|------|------|
| 0 | _ID | RowId |
| 1 | _CategoryView | 1=可见 |
| 2 | _CategoryIndex | 大分类(宠物=7) |
| 3 | _CategoryIndex2 | 子分类(宠物=23) |
| 4 | _CategoryIndex3 | 细分类 |
| 6 | _Name | 商城显示名 |
| 7 | _Description | 描述 |
| 8 | _IconFile | 图标文件ID |
| 9 | _IconIndex | 图标索引 |
| 10 | _Gender | 性别 |
| 16 | _ItemID1 | 道具ID(关联ITEM_2._Num) |
| 62 | _Buy_Disable | 必须=1 |
| 63 | _Give_Disable | 必须=1 |
| 64 | _Limited_Time_Type | 0=永久 |

### 二进制改XLS技巧
```python
# 安全改名（等长/更短）
data.replace(b'耶比', b'龙猫')

# 安全改数值列
lines = data.split(b'\n')
for i in range(2, len(lines)):  # 跳过表头
    parts = lines[i].split(b'\t')
    if parts[11].strip() == b'0':
        parts[11] = b'1'
        lines[i] = b'\t'.join(parts)
```

### 致命事故
直接二进制改LDT的**string字段**→BayServer SIGSEGV崩溃(exi 139)，
日志停在`GlobalSys::Init() : [OK]`无dmp。

**恢复方法**：从BARY.rar/SPF解包提取原版ITEM_2.LDT覆盖。
