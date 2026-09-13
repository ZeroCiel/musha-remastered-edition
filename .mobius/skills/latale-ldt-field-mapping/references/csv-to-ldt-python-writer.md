# CSV → LDT 写入工具（实验性）

latale_ldt_tool 只支持导出，不支持写回。本文件记录 Python 重建 LDT 的尝试。

## 约束

- LDT 文件头：12字节 + 字段名区（每字段32字节，空格填充） + 类型定义区（偏移约0x200c） + 数据区（偏移约0x220c）
- 字段类型：0=uint, 1=string, 2=bool, 3=int, 4=float
- 字符串以GBK编码，前2字节为长度（UInt16）
- 偏移0x200c和0x220c是硬编码在latale_ldt_tool里的，不同文件可能不同

## 问题

首次测试写入的文件大小与原件差49字节（343869 vs 343918），格式兼容性未验证。建议优先使用 彩虹岛编辑器 手动编辑LDT。

## 当前状态

工具代码在 `C:\Users\Administrator\Temp\csv_to_ldt.py`，未经實机验证。
