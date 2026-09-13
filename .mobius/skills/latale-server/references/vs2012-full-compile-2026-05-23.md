# VS2012 全量编译尝试记录 (2026-05-23)

系统重装后重新编译 MgmtServer 的过程记录。

## 关键发现

### VS2012 完整安装成功

VS2012 Express for Desktop 在 Win11 上成功安装到了 `C:\Program Files (x86)\Microsoft Visual Studio 11.0\`。
**vcvarsall.bat 的注册表键在完整安装后被持久化**，系统重装后仍然可用（不在注册表里的 VS2013 解压版则不行）。

### 依赖库全部重编成功

所有依赖库用 VS2012 (v110 /MT) 编译成功：
- ServerCore.lib, ServerBase.lib, LataleMapLoader.lib
- LataleBattleSystem.lib, LataleCheatSystem.lib
- OSPAPI.lib, MonsterAPI.lib

**编译时要注意的额外文件**（在 vcxproj 中遗漏但在旧编译产物中存在）：
- `Src\CIOCP.cpp`, `Src\IOCPThread2.cpp`, `Src\ConnectorEx.cpp`

### 每个项目的 stdafx.h 路径不同

这是最大的坑点。`/FI`（强制包含）必须指向正确的 stdafx.h：
- LataleMgmtServer 源文件 → `LataleMgmtServer\stdafx.h`
- ServerCore 源文件 → `ServerCore\stdafx.h`
- ServerBase 引用的 Src/ 下通用文件 → `ServerBase\stdafx.h`
- LataleMapLoader → `LataleMapLoader\stdafx.h`
- Common/ 下文件 → `Common\StdAfx.h`

不能用一个全局 `/FI` 解决——每个项目单独编译，分别传各自的 stdafx。

### LataleMapLoader 的额外 include 路径

编译 LataleBattleSystem 时需加 `/I LataleMapLoader`（SPStream.h 在那里）。
编译 LataleMapLoader 时需加 `/I LataleBattleSystem`。

### MgmtServer 源码改动可行

`LataleMgmtServerApp.cpp` 中，`__ADD_GUILD` 块内的 Division/Guild 初始化失败已改为非致命（打印警告后 continue），见第 118-128 行。
`__ADD_PVP` 块内仍有 `getchar() + return false`，需要时一同改掉。

`DivisionInfoList::Init()` 可直接改为 `return true` 跳过 LDT 加载（Division 数据在单机环境无影响）。

## LataleGameLogic.lib 链接阻塞

**这是当前最大的阻碍。** 77MB 的 `LataleGameLogic.lib` 是 `/GL` (LTCG) / 预编译的，引用了原始开发机 PCH 路径。

### LTCG 的特性

- `/GL` 编译的 .obj 包含 MSIL 中间代码，不是最终机器码
- 链接阶段才展开为机器码（LTCG = Link-Time Code Generation）
- 展开需要原始编译时使用的 `.pch` 文件
- 旧 PCH 路径 `d:\chd-s1\server\latalegamelogic\release\latalegamelogic.pch` 在本机不存在
- 即使不用 `/LTCG` 标志，链接器遇到 LTCG .obj 也会尝试展开 → 找 PCH → 致命错误 C1083

### 失败的绕过尝试

| 方法 | 结果 | 原因 |
|------|------|------|
| 手动编译 Stub.cpp (include 144 个头文件) | ❌ | 循环依赖（AuctionType/AuctionTypes）、缺 boost（PCManager2.h）、缺 CLockObject 等 |
| `lib /REMOVE:TeamManager.obj` | ❌ | LTCG 编译后成员被合并，无法单独移除 |
| ASM stub 提供 `_Myptr` + `CCharacter` 符号 | ❌ | 链接器仍尝试展开 TeamManager.obj 的 LTCG 代码 |
| 不用旧 LGL，用空 Stub.obj 替代 | ❌ | 丢失大量符号（CTeamManager、CTeam、CashShopManager 等） |

### 真正解决需要

在可运行 VS2012 完整安装的环境中，用 VS2012 编译 LataleGameLogic 的源码（144 个头文件）。
但纯头文件库的编译可能需要：
1. 修复 AuctionType.h vs AuctionTypes.h 的 enum 冲突
2. 在 stdafx.h 中加入 LockObject.h 的 include 路径
3. 安装 boost（PCManager2.h 依赖 boost/detail/lightweight_mutex.hpp）
4. 修补 ItemStruct.h 中注释掉的 ITEM_CREATE_TYPE

或者：在 Win10 虚拟机中安装 VS2012，全量编译所有项目。

## MSVC 运行时（CRT）部署

系统重装后，BIN2 的 exe 依赖 `msvcr110.dll`（VS2012 CRT）。解决方案：
1. 从 VS2012 的 `VC\redist\2052\vcredist_x86.exe` 安装 VC 可再发行组件
2. 或将 `VC\redist\x86\Microsoft.VC110.CRT\msvcr110.dll` + `msvcp110.dll` 复制到 BIN2 目录

## ASM Stub 符号技术

当旧库引用已被移除的 CRT/ABI 内部符号时，可以用 MASM 提供空桩：

```asm
.486
.MODEL flat

; std::string::_Myptr() const (VS2003-2010 内部函数，VS2012+ 移除)
PUBLIC ?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ
PUBLIC __imp_?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ
_TEXT SEGMENT
?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ PROC
    lea eax, [ecx+4]  ; return internal buffer pointer
    ret
?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ ENDP
__imp_?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ PROC
    lea eax, [ecx+4]
    ret
__imp_?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ ENDP
_TEXT ENDS
END
```

```bat
ml /c /Fo%OUT%\symbol_stubs.obj symbol_stubs.asm
```

注意：ASM stub 不能解决 LTCG PCH 问题——它只解决符号缺失问题。
