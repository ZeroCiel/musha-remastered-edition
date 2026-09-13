# Python LDT 读写工具

## 格式总结

```
偏移 0-3:   未使用(通常0x00000000)
偏移 4-7:   列数(不含_RowId, 即字段定义数)
偏移 8-11:  行数
偏移 12+:   列名区, 每列64字节, ASCII+`\x00`+空格填充
偏移 8204:  类型定义区, 每列4字节 (0=uint, 1=string, 2=bool, 3=int, 4=float)
偏移 8716:  数据区
```

## 数据区编码

- 数值(uint/int/bool/float): 都是4字节小端, bool是0/1的uint32
- 字符串: 先2字节长度(ushort), 然后GBK编码的内容
- 第一列_RowId不是文件头里的字段, 是读取时自动加的; 写入时视为普通int列

## Python 读写工具

文件位置: `C:\Users\Administrator\Temp\ldt_writer.py`

两个核心函数:

### parse_ldt_header(data) -> dict
解析文件头, 返回 {col_count, row_count, col_names, col_types, data_start}

### read_rows(data, header) -> list[list[str]]
读取所有行, 每行是字符串列表

### build_ldt(header, rows, orig_data) -> bytes
从CSV行数据和原始文件头重建LDT二进制

## 批量文本替换

```python
# 对所有文件执行"艾丽斯"→"爱丽丝"替换
python C:\Users\Administrator\Temp\batch_replace_ldt.py
```

该脚本会:
1. 遍历所有LDT文件(带string类型列的)
2. 读取→替换文本→备份(.bak_allice)→写回
3. 统计替换总数

## 注意
- LDT写回后需用latale_ldt_tool重新导出验证 100% 一致
- 验证命令: diff orig_export.csv new_export.csv (应为空)
- 任何不一致都意味着write逻辑有bug, 不要使用不匹配的输出
