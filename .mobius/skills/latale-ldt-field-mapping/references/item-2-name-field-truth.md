# ITEM_2 _Name 字段真相

## 核心发现

ITEM_2（时装/道具表）的 `_Name` 字段**不是中文名**，而是**数字ID引用**！

- 所有时装的 `_Name` 都是纯数字（"4", "6", "17", "36", "2" 等）
- 真正的中文名在 **`_Description`** 字段
- 其他表（NPCTALK, QUEST等）的 `_Name` 是正常中文

## 数据证明

扫描 ITEM_2 中所有时装（PosID∈{3,4,5,6,7,8,11} 且 _CashCheck=0）共2497件：

| 行ID | _Name | _Description | PosID |
|------|-------|--------------|-------|
| 130229504 | "4" | "梅" | 3 |
| 130120306 | "6" | "耶拉恩_男" | 3 |
| 430110316 | "17" | "星光满路+15" | 4 |
| 911110261 | "64" | "恶魔翅膀" | 3 |

**中文名 = 0 件，数字名 = 2497 件**

## 对CASH_SHOP的影响

CASH_SHOP的 `_Name` 字段应该填 **ITEM_2._Description** 的内容，不是 _Name 的数字ID。

## 之前解析出"链子短裤"等中文名的原因

之前的解析中偶尔能读出中文，是因为写了正确的行遍历代码。后续重写时修复了bug，才暴露出 _Name 实际是数字引用这个事实。

## 建议的读取方式

```python
# 获取CASH_SHOP的NAME
name = vals[desc_idx]  # 从_Description取
if isinstance(name, str) and name:
    clean_name = name.split('\\n')[0].split('\n')[0].strip()
else:
    clean_name = '未命名'
```
