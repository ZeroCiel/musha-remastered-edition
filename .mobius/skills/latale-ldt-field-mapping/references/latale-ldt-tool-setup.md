# latale_ldt_tool 设置指南

## 项目信息
- GitHub: https://github.com/hopenobug/latale_ldt_tool
- 语言: Go
- 功能: 将彩虹岛二进制 LDT 文件导出为 UTF-8 CSV

## 安装

### 首次编译（需要Go环境）
1. 下载 Go: https://go.dev/dl/go1.22.5.windows-amd64.msi
2. 安装（默认路径 `C:\Program Files\Go`）
3. 编译：
```bash
export PATH="$PATH:/c/Program Files/Go/bin"
cd <工具目录>
# 如网络连不上GitHub，设国内代理
export GOPROXY=https://goproxy.cn,direct
go mod tidy
go build -o ldt_tool.exe .
```

### 依赖
- github.com/axgle/mahonia（GBK→UTF-8转换）
- golang.org/x/net（charset检测）
- golang.org/x/text

## 使用
```bash
export PATH="$PATH:/c/Program Files/Go/bin"
cd <工具目录>
./ldt_tool.exe "/d/彩虹岛/resource/ROWID/DATA/LDT/XXXX.LDT"
```
输出：同目录生成 `XXXX.csv`（UTF-8 BOM头）

## CSV 格式
- 行1：表头（`item_id,_FieldName1|type1,_FieldName2|type2,…`）
- 后续行：数据
- 类型：`int` / `uint` / `string` / `bool` / `float`
- 编码：UTF-8 with BOM (`\xEF\xBB\xBF`)
- 分隔符：逗号 `,`
- 过滤：自动跳过 item_id=0 的空记录

## 局限
1. **只支持导出，不支持导入**（CSV→LDT 写入功能缺失）
2. 固定偏移读取（类型定义 @8204, 数据区 @8716），部分新格式可能不兼容
3. 字符串类型从 GBK 转 UTF-8

## 已验证可用的 LDT 文件
- NPCTRADE.LDT
- NPCTRADE_DETAIL.LDT
- NPCTRADE_LIST.LDT
- CASH_SHOP.LDT
- ITEM_1.LDT / ITEM_2.LDT / ITEM_3.LDT
- NPC.LDT
