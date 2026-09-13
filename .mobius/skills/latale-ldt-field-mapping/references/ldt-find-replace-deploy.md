# ldt-find-replace 工具开发和部署笔记

## 编译
```bash
pip install pyinstaller
cd C:\Users\Administrator\Temp
pyinstaller --onefile --console --name ldt-find-replace ldt_find_replace.py
```

## 部署位置
- exe: `D:\LaTale\ldt-find-replace.exe`
- 源码: `C:\Users\Administrator\Temp\ldt_find_replace.py`
- 快捷入口: `C:\Windows\ldt-find-replace.bat`（内容: `@echo off` + `D:\LaTale\ldt-find-replace.exe %*`）

## PATH设置（踩坑记录）

**setx 失败原因**：
- `setx PATH "D:\LaTale;%PATH%"` 在cmd里自动展开%PATH%成完整字符串
- 展开后值过长，setx会截断或报错
- 写入注册表后值带引号（REG_SZ而非REG_EXPAND_SZ）
- %USERPROFILE%等变量被展开了，导致后续相关路径失效

**最终方案**：.bat放入 `C:\Windows\`。因为C:\Windows在系统PATH里，任何新开的cmd/powershell都能直接调用。

## 后续工具部署约定
所有D:\LaTale\下的exe都通过C:\Windows\下的同名.bat做包装入口。
