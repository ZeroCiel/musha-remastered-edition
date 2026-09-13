# VS2012 下链接旧 LTCG .lib 的 ASM Stub 技术

2026-05-23 编译 MgmtServer 时的实战记录。

## 问题

旧的 `LataleGameLogic.lib`（77MB）是用 VS2003/VS2005 + `/GL`（LTCG）编译的。
用 VS2012 cl.exe 重编所有 .obj 后，最终链接时遇到三种缺失符号：

### 1. 旧 CRT 内部函数（_Myptr）

`std::string::_Myptr()const` 在 VS2003-2005 中存在，VS2012+ 移除。
旧 lib 中的 `TeamManager.obj` 引用了它。

### 2. 跨组件成员函数

`CCharacter::ActionCommand(LPARAM)` 和 `ActionCompleteCommand(LPARAM)`
定义在 `LataleGameServer/Character.cpp` 中，但 `LataleMapLoader/SPGOBCoordPhysics.cpp`
（编译到 LataleMapLoader.lib）调用了它们。

### 3. 未定义的静态成员变量

`CRITICAL_SECTION CAutoLock::m_cs` 在 `CAutoLock.h` 中声明为 `static`，
但在 `Src/CAutoLock.cpp` 中没有对应的定义。

## ASM Stub 方案

MASM (ml.exe) 可以直接提供指定符号名的空桩函数。

```asm
; symbol_stubs.asm
.486
.MODEL flat

; std::string::_Myptr()const
PUBLIC ?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ
PUBLIC __imp_?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ

_TEXT SEGMENT
?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ PROC
    lea eax, [ecx+4]   ; thiscall, ECX=this
    ret
?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ ENDP

; __imp_ 变体（dllimport 引用）
__imp_?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ PROC
    lea eax, [ecx+4]
    ret
__imp_?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ ENDP

; CCharacter::ActionCommand(long)
PUBLIC ?ActionCommand@CCharacter@@QAEXJ@Z
?ActionCommand@CCharacter@@QAEXJ@Z PROC
    ret
?ActionCommand@CCharacter@@QAEXJ@Z ENDP

; CCharacter::ActionCompleteCommand(long)
PUBLIC ?ActionCompleteCommand@CCharacter@@QAEXJ@Z
?ActionCompleteCommand@CCharacter@@QAEXJ@Z PROC
    ret
?ActionCompleteCommand@CCharacter@@QAEXJ@Z ENDP

_TEXT ENDS
END
```

编译方式：
```bat
ml /c /Foobj\symbol_stubs.obj symbol_stubs.asm
```

链接时加入：
```bat
link ... obj\symbol_stubs.obj obj\*.obj
```

### 静态成员变量

不能通过 ASM 解决，必须在 C++ 源文件中提供定义：
```cpp
#include "CAutoLock.h"
CRITICAL_SECTION CAutoLock::m_cs;
```

## 局限性

对于 LTCG (`/GL`) 编译的 .lib，即使在链接时不加 `/LTCG` 参数，
链接器也会尝试展开 LTCG 对象中的 IL 中间码，需要原始 PCH 文件。
ASM stub 无法绕过这个限制——如果 `C1047` 或 PCH-not-found 错误出现，
必须放弃旧的 LTCG .lib，完全从源码重编。
