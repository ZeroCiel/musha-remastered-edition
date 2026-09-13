# 编译状态总览 (2026-05-23, updated 2026-05-23 after rebuild)

## 工具链 — 重装后再次编译

| 工具 | 路径 | _MSC_VER |
|------|------|----------|
| VS2012 完整版 | `C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC` | 1700 (v110) |
| VS2013 | `D:\VS2013` | 1800 (v120) |
| VS2012 手拆版（不完整，缺 CRT 头文件） | `D:\VS2012` | 1700 不可用 |

## git-bash 注意事项

- MSBuild 开关用 `-p:Config=Release` 不用 `/p:`
- PowerShell 命令避免在 MSYS bash 中内联（路径转换损坏）
- 用 `cmd /c` 或 PowerShell 脚本文件执行

## vcproj→vcxproj 自动转换

使用 `scripts/convert_vcproj.py` 批量转换。**注意**：脚本会保留原始 vcproj 中的 preprocessor definitions（如 `_RES_BELOS`），手工编辑 vcxproj 时不要误删这些项目特有宏。

```bash
python scripts/convert_vcproj.py  # 批量转换所有已知项目
python scripts/convert_vcproj.py path/to/Project.vcproj  # 单个转换
```

## 依赖库编译

```bash
# 批量编译所有依赖库 (ServerCore 需单独转)
for proj in ServerBase LataleMapLoader LataleBattleSystem LataleCheatSystem OSPAPI MonsterAPI; do
    D:/VSBuildTools/MSBuild/Current/Bin/MSBuild.exe \
      "D:/LaTaleServer-/$proj/${proj}.vcxproj" \
      -p:Configuration=Release -p:Platform=Win32 -t:Build -m
done
```

## LataleGameLogic 特殊处理

无官方源码（纯头文件库，仅 .h 无 .cpp）。预编译 .lib 使用 VS2012 `/GL`（全程序优化），内嵌 MSIL 中间码，**与 VS2022 链接器完全不兼容**（链接器报 `找到 MSIL .netmodule` 并重启 LTCG 后仍失败）。

头文件全量 include 编译方案失败 — 144 个头文件之间存在循环依赖和缺失的 prerequisite include（CLockObject, MAX_GAMBLING_RANK 等），无法单独编译。

**结论**：必须使用 VS2012 工具链 (v110) 才能链接 MgmtServer。VS2022 无法完成此任务，VS2013 (v120) 同样不行 — 已实测 VS2013 全量编译所有 7 个依赖库 + MgmtServer 源码，链接时仍报 `fatal error C1047: LataleGameLogic.lib 是用比其它对象更老的编译器创建的` 和 `LNK1257: 代码生成失败`。v110 是唯一可行工具链。

### ✅ VS2012 Express for Desktop（唯一有效方案）

**VS2022 Build Tools 加装 v110 组件失败**：`vs_installer.exe modify --add Microsoft.VisualStudio.Component.VC.v110.xp` 退出 0 但未安装任何 v110 文件，Build Tools 版不支持此组件。

**唯一可行路径**：下载 **Visual Studio Express 2012 for Windows Desktop** (wdexpress_full.exe) web 安装器，运行后安装全量 v110 工具链（包含 CRT 头文件 + 静态/动态库 + MSBuild 集成）。

安装后路径：`C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\`

## VS2013 工具链 (D:\\VS2013) — 可用

VS2013 安装器在 Win11 上同样静默退出（Burn engine MBA .NET 加载失败，详见 `references/vs2012-toolchain-trial.md`），但 **ISO 解压出的文件是完整的**，cl.exe 和 link.exe 可以直接使用：

### VS2013 Stub Library 技术

当旧 `.lib` 是 LTCG 编译且无法重编时，可以编译一个 **Stub 静态库** 替代它提供给链接器。Stub 库包含所有需要的符号但实现为空，只需要能通过编译。

**Shadow Header 技巧**：当 stub 的 `.cpp` 文件 `#include` 头文件时，如果这些头文件又引用了其他目录中的真实头文件（如 `..\src\LockObject.h`、`..\LataleGameServer\Character.h`），会触发复杂的依赖链并导致编译失败。

解法是在 **Stub 库自己的项目目录**中放置同名的空头文件，利用 MSVC 的 include 搜索顺序：`当前目录 .` → `-I 路径` → 系统路径。当前目录下的空文件会**遮蔽**其他路径中的真实头文件，让编译器只看到空的 `#pragma once` 定义。

```cpp
// Stub.cpp 中手动提供缺失类型的完整定义
class CLockObject { ... };
class CCharacter { ... };
class CPacketComposer { ... };
typedef struct _IO_CONTEXT { char dummy[256]; } IO_CONTEXT;
```

**对 include 路径使用相对路径的头文件**（如 `#include "../LataleGameServer/Character.h"`）无法被 shadow header 遮蔽——编译器会按相对路径查找。解法：直接修改项目中的头文件，把相对 include 替换为 stub 友好的定义（例如用 `#define CHAR_LIMIT_LV 200` 替代 `#include "../LataleGameServer/Character.h"`）。

**跳过复杂依赖链的头文件**：对于含有深层依赖链的头文件（如 `MobManager2.h` → `MOBAI.h` → `CMonster` → `CCharacter` → `CPC`），直接在 Stub.cpp 中注释掉 `#include` 并手动提供该文件中类的符号定义。

### ⚠️ MSYS 下调用 cl.exe 的三个陷阱

1. **`/` 被 MSYS 转为 Windows 路径**：`/MT` → `C:/Program Files/Git/MT`。设 `MSYS_NO_PATHCONV=1` 或通过 Python subprocess + cmd.exe 调用。
2. **cmd.exe stdout 被管道吞掉**：在 MSYS bash 里 `cmd.exe /c "cl ..."` 的输出可能为空。写 .bat 文件并重定向到日志文件。
3. **cl.exe 不在 PATH**：用 Python subprocess 设好 `INCLUDE`/`LIB`/`PATH` 环境变量再调用。

```python
# 正确调用模式
import subprocess, os
env = os.environ.copy()
env['PATH'] = r'D:\VS2013\VC\bin;' + env['PATH']
env['INCLUDE'] = r'D:\VS2013\VC\include;C:\Program Files (x86)\Windows Kits\8.0\Include\shared;...'
env['LIB'] = r'D:\VS2013\VC\lib;C:\Program Files (x86)\Windows Kits\8.0\Lib\win8\um\x86;...'
result = subprocess.run(
    [r'D:\VS2013\VC\bin\cl.exe', '/nologo', '/c', '/MT', 'source.cpp'],
    capture_output=True, text=True, env=env
)
```

| 工具 | 路径 | 版本 |
|------|------|------|
| cl.exe | `D:\\\\VS2013\\\\VC\\\\bin\\\\cl.exe` | VS2013 (v120, _MSC_VER=1800) |
| link.exe | `D:\\\\VS2013\\\\VC\\\\bin\\\\link.exe` | 12.00.31101.0 |
| vcvarsall.bat | `D:\\\\VS2013\\\\VC\\\\vcvarsall.bat` | ⚠️ 重装系统后不可用（缺注册表） |
| CRT libs | `D:\\\\VS2013\\\\VC\\\\lib\\\\` | msvcrt/msvcprt/oldnames/kernel32 齐全 |
| CRT headers | `D:\\\\VS2013\\\\VC\\\\include\\\\` | 齐全 |
| Windows Kits | `C:\\\\Program Files (x86)\\\\Windows Kits\\\\8.0\\\\` | 系统自带 |

### ⚠️ 重装系统后 vcvarsall.bat 不可用

`vcvarsall.bat` 依赖注册表键 `VS120COMNTOOLS` 来定位自身路径。系统重装后这些键不存在，报错：
```
ERROR: Cannot determine the location of the VS Common Tools folder.
```
**编译器文件本身仍完整可用**，只需手动设置环境变量后用 `cmd.exe` 调用编译。写一个 wrapper .bat 文件：

```bat
@echo off
set PATH=D:\VS2013\VC\bin;%PATH%
set INCLUDE=D:\VS2013\VC\include;C:\Program Files (x86)\Windows Kits\8.0\Include\shared;C:\Program Files (x86)\Windows Kits\8.0\Include\um
set LIB=D:\VS2013\VC\lib;C:\Program Files (x86)\Windows Kits\8.0\Lib\win8\um\x86
cd /d D:\VS2013
cl %*
```

从 Python 调用时也用同样方式包装：
```python
import subprocess
bat = r'''
set PATH=D:\VS2013\VC\bin;%PATH%
set INCLUDE=D:\VS2013\VC\include;...
set LIB=D:\VS2013\VC\lib;...
cl %*
'''
subprocess.run(['cmd.exe', '/c', bat], ...)
```

已验证：用此方法编译 hello.c 并成功运行。**VS2012 (D:\\VS2012) 同理** — vcvarsall.bat 依赖 `VS110COMNTOOLS` 注册表键，重装后需手动设环境变量。

**注意**：VS2013 的 _MSC_VER=1800，与 ServerCore.lib 和 LataleMapLoader.lib 匹配，但与 VS2012 链接器 (_MSC_VER=1700) 和 MgmtServer 当前 obj (VS2015, _MSC_VER=1900) 不兼容。

### VS2012/2013 安装器在 Win11 上失败的共同根因

两个安装器都无法启动 → 不是个别 ISO 损坏，而是 Win11 对旧版 .NET Framework bootstrapper 和 SHA-1 签名可执行文件的安全限制。setup.exe 是 .NET 应用，Win11 直接阻止其运行。但 ISO 解压出的工具链文件本身无需安装即可使用。
```xml
<?xml version="1.0" encoding="utf-8"?>
<AdminDeploymentCustomizations xmlns="http://schemas.microsoft.com/wix/2011/AdminDeployment">
   <BundleCustomizations TargetDir="D:\VS2012" NoWeb="yes"/>
   <SelectableItemCustomizations>
     <!-- 所有非 VC 组件设 Selected="no" -->
     <!-- VC++ 组件设 Selected="yes": -->
     <SelectableItemCustomization Id="VCCompilerHidden" Selected="yes"/>
     <SelectableItemCustomization Id="VCCoreHidden" Selected="yes"/>
     <SelectableItemCustomization Id="VCDebugHidden" Selected="yes"/>
     <SelectableItemCustomization Id="VCDesigntimeHidden" Selected="yes"/>
     <SelectableItemCustomization Id="VCExtendedHidden" Selected="yes"/>
     <SelectableItemCustomization Id="WinSDKHidden" Selected="yes"/>
     <!-- 其余全部 Selected="no" -->
   </SelectableItemCustomizations>
</AdminDeploymentCustomizations>
```
3. 运行：`vs_ultimate.exe /adminfile admin_deploy_vc.xml /quiet /norestart`

**MSI 独立安装不可行** — `vc_compilercore.msi` 和 `vc_librarycore.msi` 的 `msiexec /i` 会报 exit 86（致命错误），`msiexec /a` 管理安装会挂起。这些 MSI 被设计为必须由 VS setup bootstrapper 编排安装。

## MgmtServer 编译+链接

```bash
D:/VSBuildTools/MSBuild/Current/Bin/MSBuild.exe \
  "D:/LaTaleServer-/LataleMgmtServer/LataleMgmtServer.vcxproj" \
  -p:Configuration=Release -p:Platform=Win32 -t:Build -m
```

## 常见编译错误速查

| 错误 | 原因 | 修复 |
|---|---|---|
| `std::map/string` 未定义 | stdafx.h 缺 `<map><string>` | 补 include |
| `SAFE_DELETE` 未定义 | GlobalDefines.h 未 include | stdafx.h 加 `#include "GlobalDefines.h"` |
| `SC_ERROR` 未定义 | DebugPrint.h 未 include | stdafx.h 加 `#include "DebugPrint.h"` |
| `MAX_PACKET_SIZE` 未定义 | BaseTypes.h 未 include | stdafx.h 加 `#include "BaseTypes.h"` |
| `binary_function` 未定义 | C++17 移除此类 | 加 `_HAS_AUTO_PTR_ETC=1` 或 `#include <functional>` |
| `RtlCaptureContext` 未找到 | Win SDK 版本 | 加 `_WIN32_WINNT=0x0602` |
| C4819 编码警告 | 源码含韩文注释 | 无害，可忽略 |
| LNK2001 `__imp_` 符号 | ABI 不匹配 (/MD vs /MT, VS版本) | 对齐 RuntimeLibrary |
| MSB4025 | .vcproj 格式 | 转 .vcxproj |
| LNK2001 + `找到 MSIL .netmodule` | 预编译 lib 用了 `/GL` (LTCG) | 无法用 VS2022 链接，需同版本工具链 |

## 链接器 ABI 不匹配诊断

链接失败时，错误信息中包含关键版本线索：

### _MSC_VER 版本映射

| _MSC_VER | VS 版本 | 工具链 | 年份 |
|----------|---------|--------|------|
| 1700 | VS2012 | v110 | 2012 |
| 1800 | VS2013 | v120 | 2013 |
| 1900 | VS2015 | v140 | 2015 |
| 1910-1916 | VS2017 | v141 | 2017 |
| 1920-1929 | VS2019 | v142 | 2019 |
| 1930+ | VS2022 | v143 | 2022 |

### RuntimeLibrary 冲突

```
MT_StaticRelease  → /MT  (静态链接 CRT, libcmt.lib)
MD_DynamicRelease → /MD  (动态链接 CRT, msvcrt.lib)
```

所有 obj 和 lib 必须使用**相同**的 RuntimeLibrary，否则链接失败。

### 诊断示例（本次会话实际错误）

```
ServerCore.lib(perfmon.obj) : _MSC_VER mismatch: 1800 vs 1900 (Connector4Server.obj)
→ ServerCore.lib 用 VS2013 编译，Connector4Server.obj 用 VS2015 编译

ServerCore.lib(perfmon.obj) : RuntimeLibrary mismatch: MT_StaticRelease vs MD_DynamicRelease
→ ServerCore.lib 用 /MT，Connector4Server.obj 用 /MD

fatal error C1047: LataleGameLogic.lib 是用比其它对象更老的编译器创建的
→ LataleGameLogic.lib 的 _MSC_VER < 所有其他 obj/lib
```

### 实际版本对照（当前 LaTaleServer- 状态）

| 文件 | _MSC_VER | RuntimeLibrary |
|------|----------|----------------|
| MgmtServer/*.obj (当前) | **1900** (VS2015) | **MD_DynamicRelease** |
| ServerCore.lib | **1800** (VS2013) | **MT_StaticRelease** |
| LataleMapLoader.lib | **1800** (VS2013) | **MT_StaticRelease** |
| LataleGameLogic.lib | **<1700** (VS2010 或更早?) | 未知 |

**当前不匹配**：MgmtServer obj (VS2015/MD) 与所有库 (VS2013/MT) 都不兼容。
