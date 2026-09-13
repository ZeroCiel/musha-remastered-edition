# 彩虹岛编辑器导出TXT格式说明

## 重要前提

**不要用binary解析他乡端ITEM_2.LDT！** 
他乡端（D:\LaTale\S2）的ITEM_2.LDT二进制解析器只读出22条Type=1,SubType=2的道具，
但编辑器导出TXT能看到大量Type=4,SubType=3的结晶类道具。
所有ITEM_2相关操作必须通过编辑器导出TXT进行。

## 导出TXT格式

彩虹岛编辑器「导出」功能生成的是 **TAB分隔** 的txt文件（不是竖线分隔的编辑器显示格式）。

### 列位置（1-indexed）实测

以彩虹泡泡+0为例：
```
20121677	5111	106	17	彩虹泡泡	\n\n可强化至+10\n...	 10002423	131	1	0	1	null	1	1	4	3	...	
```

| TAB列 | 字段 | 示例值 | 类型 |
|-------|------|--------|------|
| col1 | _RowId | 20121677 | int |
| col2 | ? | 5111 | int |
| col3 | ? | 106 | int |
| col4 | _PosID1? | 17 | int |
| **col5** | **_Name** | 彩虹泡泡 | string |
| col6 | _Description | \n\n可强化至+10\n... | string(含换行) |
| col8 | ? | 1 | int |
| col9 | ? | 0 | int |
| col10 | ? | 1 | int |
| col11 | ? | null | 前置符号 |
| col12 | _Icon | 1 | int |
| col13 | ? | 1 | int |
| **col14 (col9?)** | **_Type** | 4 | int |
| **col15 (col10?)** | **_SubType** | 3 | int |

注意：编辑器显示的列名和CSV列名顺序不完全一致。_Type/_SubType在编辑器窗口中可能位于不同的索引。
关键是根据值判断：彩虹泡泡是Type=4,SubType=3的结晶类。

### 强化等级判断

道具名末尾 `+0` `+1` `+2` … `+9`、`MAX` 就是强化等级。
TXT中无单独的强化等级列，只能从Name后缀判断。

### 处理流程

1. 编辑器导出整个ITEM_2.LDT为TXT（TAB分隔）
2. Python脚本读TXT，按第几列筛_Type和_SubType
3. 按Name后缀判断强化等级（+0~+3保留，+4及以上过滤）
4. 排除已上架CASH_SHOP的ItemID
5. 生成65列CASH_SHOP追加TXT

### 一个重要参数

编辑器导出的txt中，道具描述含换行符（\n）会导致解析困难。
推荐处理方式：描述列整列字符串取用，不细解析，除非要改描述。
