# LDT 查找替换工具 (ldt-find-replace)

## 可执行文件
`D:\LaTale\ldt-find-replace.exe`（6.4MB，PyInstaller编译，无Python依赖）

已加入PATH环境变量，新开cmd/powershell直接打 `ldt-find-replace` 就能用。

## 源码
`C:\Users\Administrator\Temp\ldt_find_replace.py`

## 简介
交互式CLI工具，支持**模糊搜索**（部分关键词匹配）和**批量替换**LDT文件中的字符串字段。
相比彩虹岛编辑器（必须全名匹配），这个工具输入部分关键词就能搜到。

## 用法

### 交互模式（推荐）
```bash
ldt-find-replace "D:\彩虹岛\resource\ROWID\DATA\LDT\NPCTALK.LDT"
```

交互模式支持的命令：
- `<关键词>` — 在所有string字段中模糊查找（不区分大小写）
- `/f<字段名>` — 筛选只看某个字段的所有内容
- `/s` — 列出所有string字段
- `/o` — 从.bak备份恢复
- `/h` — 帮助
- 空输入 — 退出

搜索到结果后，输入替换值即可执行替换。支持三种模式：
- **直接输入替换文本** — 替换后需要确认(y/N)
- **`/all`** — 批量替换所有匹配项，不逐条确认
- **`/y`** — 逐条确认替换

### 命令行模式（快速搜索/替换）
```bash
# 搜索
ldt-find-replace search NPCTALK.LDT 爱丽丝

# 搜索+替换
ldt-find-replace replace CASH_SHOP.LDT 宝箱 神秘宝箱
```

## 安全机制
- 首次加载自动创建 `.bak` 备份
- 每次写入前创建 `.bak1` 增量备份
- 写入后自动验证列数和行数完整性（列数不对则拒绝写入）
- 控制台UTF-8支持（自动设置65001代码页）

## 核心原理
1. 用 `parse_ldt_header` + `read_rows` 解析LDT二进制（纯struct实现，无外部依赖）
2. 只搜索 string 类型（type==1）的列，忽略数字/bool/float字段
3. 修改后调用 `build_ldt` 重建二进制
4. 写入前自动备份，写入后自动验证

## 与彩虹岛编辑器的对比

| 特性 | 彩虹岛编辑器 | ldt-find-replace |
|------|-------------|-----------------|
| 搜索方式 | 必须全名匹配 | **模糊/部分匹配** |
| 批量替换 | 逐行手动改 | **一键批量替换** |
| 字段过滤 | 显示所有字段 | **只看string字段** |
| 替换前预览 | 无 | **有（显示替换前后对比）** |
| 安全性 | 直接覆盖 | **自动多层备份(.bak/.bak1)** |
| 速度 | GUI慢 | **秒级完成** |
| 依赖 | 彩虹岛编辑器.exe | **独立exe，无Python/Go依赖** |

## 重新编译

源码改动后重新打包：
```bash
pip install pyinstaller
pyinstaller --onefile --console --name ldt-find-replace ldt_find_replace.py
cp dist/ldt-find-replace.exe D:\LaTale\
```

## 已知限制
- 只替换string类型字段，不碰数字/bool/float字段（安全设计）
- 替换后需要用打包工具重新打SPF（pack=1模式）
- 不会自动处理"设计"等有坑的字（跟繁简转换相同的约束）
