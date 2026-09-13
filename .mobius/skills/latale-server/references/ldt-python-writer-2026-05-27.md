# LDT Python 写入工具（2026-05-27 开发）

本会话开发了完整的LDT写入工具，能将CSV数据写回二进制LDT格式。

## 核心文件

- `C:\Users\Administrator\Temp\ldt_writer.py` — 解析+写入一体工具
- `C:\Users\Administrator\Temp\latale_ldt_tool\` — Go导出的CSV目录

## ldt_writer.py 核心函数

### `parse_ldt_header(data)`
解析LDT文件头，返回dict包含：
- `col_count`: 列数
- `row_count`: 行数
- `col_names`: 列名列表（含_RowId）
- `col_types`: 类型列表（0=uint,1=string,2=bool,3=int,4=float）
- `data_start`: 数据区起始偏移（固定8716）

### `read_rows(data, header)`
读取所有数据行，每行是一个字符串列表。

### `build_ldt(header, rows, orig_data)`
将修改后的行数据写回二进制LDT格式。
- 保留原文件头、列名区、类型定义区
- 只替换数据区
- 自动更新行数
- 返回bytes

## 写入验证

对NPCTRADE.LDT测试：写入后重新读取对比原始CSV，**100%一致**（1301行全部匹配）。

## 批处理替换脚本

- `batch_replace_ldt.py` — 批量替换"艾丽斯"→"爱丽丝"（348处）
- `batch_t2s.py` — OpenCC+内置映射表繁转简
- `fix_remaining_trad.py` — 补充修复（8352处）
- `full_t2s_batch.py` — 全量繁转简（14581处）
- `fast_t2s.py` — 快速替换（4111处）
- `fix_more_t2s.py` — 补充词表
- `replace_bonus_yebi.py` — 红利→点券, 耶比→龙猫（527处）
- `fix_dragon_setting.py` — 红龙幼虫→红龙幼龙, 設定→设置
- `fix_stone_find_yoshino.py` — 爱丽丝石塔雕刻→传送

## 总计替换

本次会话共执行了18,692+处繁→简替换，覆盖了NPCTALK、NPC、QUEST系列、ITEM_1/2/3、EFFECT、CASH_SHOP、GLOBAL_STRING等关键文本文件。
