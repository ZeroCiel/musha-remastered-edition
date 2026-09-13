# 全LDT繁体字扫描工具 (scan_all_trad.py)

## 源码
`C:\Users\Administrator\Temp\scan_all_trad.py`

## 功能
扫描 D:\彩虹岛\resource\ROWID\DATA\LDT\ 下所有LDT文件的string字段中的繁体字。
输出到桌面：彩虹岛LDT繁体字扫描.xlsx（含3个Sheet）

## 输出说明
- Sheet1 "按文件汇总"：文件名、总行数、含繁体行数、繁体总计、不同繁体字种数、每个字段的统计
- Sheet2 "按字段统计"：每处匹配的详细信息（文件名、字段名、示例文本）
- Sheet3 "字体总统计"：每个繁体字的出现次数和涉及文件数，按次数降序排列

## 内置繁简映射
约600个汉字映射对，覆盖常见简繁差异。
特殊跳过："设"/"计"（GS崩溃已知原因）

## 运行
```bash
python C:\Users\Administrator\Temp\scan_all_trad.py
```

## 前提
LDT目录必须已解包（pack=0模式或已解包状态）。
如果resource下只有SPF包，先用解包-打包工具解包。

## 扫描耗时
约30-60秒（255个LDT文件）
