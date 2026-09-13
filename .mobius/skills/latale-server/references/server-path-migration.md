# 服务端路径迁移 — 批量替换硬编码路径

将服务端从 C 盘迁移到 D 盘时，批量修改硬编码路径的方法。

## 场景

JSQL2008 (轻量 MSSQL) 的安装脚本、注册表文件全部硬编码 `C:\JSQL2008\`，需要移到 `D:\彩虹岛\彩虹岛物语\服务端\JSQL2008\`。

## 涉及文件类型

| 文件 | 编码 | 替换方式 |
|------|------|----------|
| `.bat` | ASCII/GBK | 直接文本替换 |
| `.reg` | **UTF-16LE** | 二进制替换，不能用文本编辑器 |

## .reg 文件处理 (UTF-16LE)

`.reg` 文件是 Windows 注册表格式，编码为 UTF-16LE（带 BOM），路径中的反斜杠需要转义 (`\\`)。

```python
# 读取
with open('jinstall.reg', 'rb') as f:
    data = f.read()

# 替换: 注意 .reg 里路径是 \\ 转义的
old = 'C:\\\\JSQL2008'.encode('utf-16-le')
new = 'D:\\\\目标路径\\\\JSQL2008'.encode('utf-16-le')
data = data.replace(old, new)

# 写回
with open('jinstall.reg', 'wb') as f:
    f.write(data)
```

## .bat 文件处理

直接文本替换即可：

```batch
:: 之前
reg import "C:\JSQL2008\jinstall.reg"
sc create "MSSQL$JSQL2008" binpath= "C:\JSQL2008\...\sqlservr.exe -sJSQL2008"

:: 之后
reg import "D:\目标路径\JSQL2008\jinstall.reg"
sc create "MSSQL$JSQL2008" binpath= "D:\目标路径\JSQL2008\...\sqlservr.exe -sJSQL2008"
```

### 🔥 中文路径避坑: 用 `%~dp0` 代替 set 变量

当 .bat 所在路径包含中文时，`set "VAR=D:\中文\路径\"` 会在 CMD 中解析失败，
表现为变量名被截断（`'stall' is not recognized` / `'OME' is not recognized`）。

```batch
:: ❌ 中文路径放进变量会炸
set "JSQL_HOME=D:\彩虹岛\...\JSQL2008"
reg import "%JSQL_HOME%\jinstall.reg"    -- 解析失败!

:: ✅ 用 %~dp0 自动获取脚本所在目录（不经过变量赋值）
cd /d "%~dp0"
reg import "%~dp0jinstall.reg"
```

`%~dp0` = 脚本所在驱动器+路径（含末尾 `\`），完全避免中文路径的变量解析问题。

### ⚠️ `\r` 换行符冲突

当 .bat 文件使用 CRLF (`\r\n`) 换行时，若路径中包含 `\r` + 换行的组合
（如 `c:\Windows\SysWOW64\reg.exe` 行末的 `\r`），CMD 会将 `\r\n` 解释为行终止符，
导致命令截断（`'c:\Windows\SysWOW64eg.exe'` — 缺少 `\r`）。

```python
# 写 .bat 文件时用 LF-only 换行
with open(path, 'w', encoding='gbk', newline='\n') as f:
    f.write(content)
```

## 需要检查的文件

- `jinstall.bat` — 安装服务（sc create 的 binpath）
- `junstall.bat` — 卸载
- `jstart.bat` / `jstop.bat` — 启动/停止
- `jrun_cmd.bat` — 命令行启动
- `jinstall.reg` — 注册表（UTF-16LE，12+ 处路径）
- `junstall.reg` — 注册表（UTF-16LE）
- 桌面快捷方式 `.lnk` — 二进制格式，建议删除重建

## 验证

修改后检查 reg 文件中不再有旧路径：

```python
test = data.decode('utf-16-le')
remaining = test.count('C:\\\\\\\\旧路径')
assert remaining == 0, f"还有 {remaining} 处未替换!"
```

## 服务管理避坑

### `sc create` 错误 1073: 服务已存在

修改 binpath 后重新运行 jinstall.bat 会报 1073。需要先删再建：

```batch
sc query "MSSQL$JSQL2008" >nul 2>&1
if not errorlevel 1 (
    sc stop "MSSQL$JSQL2008" >nul 2>&1
    sc delete "MSSQL$JSQL2008"
)
sc create "MSSQL$JSQL2008" binpath= ...
```

### 启动失败: NET HELPMSG 3523

STATE = START_PENDING (2) 且不变成 RUNNING (4):
- **常见原因**: 数据文件路径不匹配 (master.mdf 找不到)
- **检查**: `sc qc "MSSQL$JSQL2008"` 看 binpath 是否正确
- **检查注册表**: `reg query "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL10_50.JSQL2008\Setup" /v SQLPath` 看路径是否指向正确位置
- **日志**: `MSSQL10_50.JSQL2008\MSSQL\Log\ERRORLOG` (UTF-16LE 编码)
- **替代方案**: 直接运行 `JSQL_Helper.exe` 图形界面管理启停

### 🔥 SQL Server 2008 在 Win10/11 崩溃 (弹框无文字)

SQL Server 2008 Express 依赖 VC++ 2005 (VC80) 运行库。Win10/11 的 SxS (Side-by-Side)
机制不认可应用本地目录的 `Microsoft.VC80.CRT\msvcr80.dll` 等文件，必须系统级安装。

- **症状**: sqlservr.exe 弹窗崩溃, ERRORLOG 不更新 (未跑到写日志)
- **根因**: `Microsoft.VC80.CRT.manifest` 声明的版本需要匹配 WinSxS 中已注册的版本
- **解决**: 下载并安装 [VC++ 2005 SP1 Redistributable x86](https://www.microsoft.com/en-us/download/details.aspx?id=26347) (`vcredist_x86.exe`, ~2.6MB)
- **替代**: 安装 [VC++ 2015-2022 合集](https://aka.ms/vs/17/release/vc_redist.x86.exe)

注意: `1.安装常用运行库合集.exe` 之类的第三方打包工具不一定包含 VC2005。
