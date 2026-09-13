# Compilation Pitfall: Per-Project stdafx.h

Each project in the LaTaleServer source tree has its own `stdafx.h` with different includes. When compiling with `cl.exe` directly (without MSBuild), you must pass the **correct** `/FI` path for each source file.

## Which stdafx.h each project uses

| Project | stdafx.h location | Key includes |
|---------|-------------------|--------------|
| MgmtServer | `LataleMgmtServer/stdafx.h` | `GlobalDefines.h`, `LT_Error.h`, `GuardLock.h`, `LockObject.h`, `PacketMsgQueue.h` |
| ServerCore | `ServerCore/stdafx.h` | Windows headers, `Configure.h`, `BaseTypes.h`, `GlobalDefines.h`, `DebugPrint.h`, `PacketcID.h` |
| ServerBase | `ServerBase/stdafx.h` | Minimal — `windows.h`, `tchar.h` **only**. No `GlobalDefines.h`, no `DefaultServerDefines.h` |
| LataleGameLogic | `LataleGameLogic/stdafx.h` | `hash_set`, `hash_map`, `SPGOBClusterDef.h`, `SPStage.h`, `SPTerrainAttribute.h` |
| OSPAPI | `OSPAPI/stdafx.h` | Windows + winsock |
| MonsterAPI | `MonsterAPI/stdafx.h` | Windows + winsock |

## The mismatch trap

When compiling per-project source files, the **same physical .cpp** may need different stdafx.h depending on which project "owns" it:

```cpp
// Src\CServerBase.cpp — compiled as part of ServerBase
// Needs ServerBase\stdafx.h which has very minimal includes
// ENGINE_VERSION_MAJOR/MINOR come from DefaultServerDefines.h
// If stdafx doesn't include it, compilation fails
```

* SRc/Common/ files like `perfmon.cpp`, `StackWalker.cpp`, `ServerLog.cpp` — compiled with ServerCore's stdafx
* `LataleCipher/LataleCipherUtil.cpp` — compiled with ServerBase's stdafx

## Strategy for batch compilation

Group source files by their "owner" project and use that project's `/FI`:

```bat
set BASE=/nologo /c /MT /O2 /W1 /DWIN32 /DNDEBUG /D_LIB /D_LATALE_SERVER /Foobj\

:: ServerCore files → use ServerCore stdafx
cl %BASE% /IServerCore /Iinclude /Isrc /ICommon /FIServerCore\stdafx.h Src\CallbackTimer.cpp

:: ServerBase files → use ServerBase stdafx (minimal!)
cl %BASE% /IServerBase /Iinclude /Isrc /ICommon /ILataleCipher /FIServerBase\stdafx.h Src\CServerBase.cpp

:: LataleBattleSystem → use LataleBattleSystem stdafx (needs MapLoader headers)
cl %BASE% /ILataleBattleSystem /ILataleMapLoader /Iinclude /Isrc /FI%SRC%\LataleBattleSystem\stdafx.h LataleBattleSystem\SPBattle.cpp
```
