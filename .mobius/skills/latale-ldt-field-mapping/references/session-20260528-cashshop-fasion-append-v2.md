# 2026-05-28 CASH_SHOP时装追加V2

## 背景

之前session（2026-05-27）尝试从ITEM_2追加时装到CASH_SHOP，两次自动写入均导致GS崩溃。
本次session采取不同策略：先生成xls让用户手动操作，最终用二进制直接写入成功。

## 关键修正

### 1. _Name字段真相（之前一直错的）

之前多个session都认为ITEM_2的Name可能是数字ID引用，所以取了_Description当名字。
**实际验证（30245642=活动黑色短裤, 70140175=愉悦粉红色珠珠凉鞋）**：
- `_Name` = 直接可用的中文商品名
- `_Description` = 道具描述（可能为空或只有换行符）

### 2. 基本发型排除条件

用户指出的"短发发型_亮黄色"这类基础发型不要加。
判断字段不是_NAME，而是**Description以"基本"开头**的：
- 基本发型_XXX → 基础发型
- 基本眼型_XXX → 基础眼型
- 基本眼部整容_XXX → 基础眼部整容
- 基本皮肤_XXX → 基础皮肤

一共排除了281件，保留1852件。

### 3. _PositionIndex的意义（用户主动问的）

是商城同分类下的显示排序序号，数字越小越靠前，唯一递增。不是道具ID。

### 4. 时限时装分类修正

之前错误地把时限时装全放到活动区(7,22,0)。
**用户指出**：兔子背囊和娃娃兔长发帽子套装等时限物品，**放在原部位分类**，只改EventType=1、Limited_Time_Type=2。
查看CASH_SHOP已有数据确认：event=1分布在(1,1,1)~(1,3,8)等常规分类中，每个分类只有1~3件。

### 5. ldt_writer的_RowId列偏移陷阱

`ldt_writer.parse_ldt_header()`自动在col_names前面加`'_RowId'`。
CASH_SHOP.LDT没有_RowId列（列0就是_CategoryView），所以通过ldt_writer写入会导致全列错位。
**后果**：第一次通过ldt_writer写入后，检查发现cat值变成了"true"（_CategoryView type=2 bool被当成了_RowId写入）。

**修复**：改用直接二进制读写，不经过ldt_writer。代码见 `scripts/append_cashshop_v2.py`。

### 6. 导出格式迭代路径（耗时5-6次修正才定稿）

1. txt格式（|分隔，被拒：列不全）
2. csv（|分隔，被拒）
3. xlsx（openpyxl，被拒）
4. xls 64列（被拒：没有_RowId列）
5. xls 65列（加_RowId，被拒：RowId从2540起始不对）
6. xls 65列 RowId从2400起始 + 排除基本发型（✅ 用户最终接受）

**教训**：直接给xls 65列 + RowId从2400开始 + 排除基本发型，可以省掉4-5轮迭代。

## 最终追加结果

- 1852件时装成功写入CASH_SHOP.LDT
- 原1494行 + 新1852行 = 3346行
- 文件大小 926972 字节
- 备份: CASH_SHOP.LDT.bak2
- 价格统一240点券（走个过场）
- EventType/Limited_Time_Type已正确设置时限标记

## 待处理

- 用户说"修一修"（可能指某些时装的名字/描述或位置需要微调）
- 打包SPF后能否正常运行尚未测试
