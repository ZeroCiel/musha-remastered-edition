# LaTale Server Full Rebuild (VS2013)

## Overview

Full source-based rebuild of the CHD "他乡彩虹岛" LaTale private server (LataleMgmtServer) using VS2013 (v120, /MT). All 7 dependency libraries plus the main executable were rebuilt from source in one pass.

## Components

| Library | Source .cpp | Compiled OK | Notes |
|---------|-------------|-------------|-------|
| ServerCore.lib | 24 | 24 | Static lib from ServerCore/ + Src/ + Common/ |
| ServerBase.lib | 27 | 27 | Static lib from ServerBase/ + Src/ |
| LataleMapLoader.lib | 19 | 18+1 skipped | LDPLoader.cpp failed (needs CLogManager2 from ServerBase); excluded from lib |
| LataleBattleSystem.lib | 4 | 4 | OK |
| LataleCheatSystem.lib | 2 | 2 | OK |
| OSPAPI.lib | 8 | 8 | OK |
| MonsterAPI.lib | 4 | 4 | OK |
| **LataleGameLogic.lib** (stub) | 1 | 1 | 60KB stub replacing 76MB LTCG original |

## Compilation Strategy

### Approach: Python subprocess with manually set INCLUDE/LIB

All compilation uses Python `subprocess.Popen` calling `cl.exe` directly with environment variables set in-process. No batch files, no `vcvarsall.bat`.

```python
env['PATH'] = r'D:\VS2013\VC\bin;' + env['PATH']
env['INCLUDE'] = (
    r'D:\VS2013\VC\include;'
    r'D:\VS2013\VC\atlmfc\include;'
    r'C:\Program Files (x86)\Windows Kits\8.0\Include\shared;'
    r'C:\Program Files (x86)\Windows Kits\8.0\Include\um;'
    r'C:\Program Files (x86)\Windows Kits\8.0\Include\WinRT;'
    r'C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Include'
)
env['LIB'] = (
    r'D:\VS2013\VC\lib;'
    r'D:\VS2013\VC\atlmfc\lib;'
    r'C:\Program Files (x86)\Windows Kits\8.0\Lib\Win8\um\x86;'
    r'C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Lib'
)
```

### Compile Flags

```
cl.exe /nologo /c /MT /O2 /W1
  /I. /I..\include /I..\src
  /DWIN32 /DNDEBUG /D_LIB /D_LATALE_SERVER
  /D_WIN32_WINNT=0x0602
  /D_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS
  /D_CRT_SECURE_NO_WARNINGS
  /FIstdafx.h
  /FoRelease_v120\
```

Key choices:
- **`/MT`** (static CRT) — all library .lib must share this
- **`/FIstdafx.h`** — force-include the precompiled header file (even without PCH)
- **No PCH** (`/Yu"stdafx.h"`) — these projects don't use precompiled headers despite having stdafx.h

### Linking Flags

```
link.exe /nologo /OUT:..\bin\LataleMgmtServer.exe /SUBSYSTEM:CONSOLE
  /LIBPATH:..\bin /LIBPATH:..\Lib
  objs...
  ServerCore.lib ServerBase.lib LataleMapLoader.lib LataleGameLogic.lib
  LataleBattleSystem.lib LataleCheatSystem.lib OSPAPI.lib MonsterAPI.lib
  ws2_32.lib
```

## MgmtServer Source Handling

### Normal sources
56 .cpp files in LataleMgmtServer/ compiled with:
- `DWIN32 /DNDEBUG /D_CONSOLE /D_LATALE_SERVER /D_LATALE_MS`
- `D_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS /D_CRT_SECURE_NO_WARNINGS`
- `D_ALLOW_RTCc_IN_STL /D_HAS_EXCEPTIONS=0`

### vcxproj hidden sources
The `.vcxproj` also includes files from sibling directories that a simple `glob("*.cpp")` misses:
- `..\Common\ServerLog.cpp`
- `..\Common\ServerStatistics.cpp`
- `..\Common\OnlineUserInfo.cpp`
- `..\Common\MakeDSNString.cpp`
- `..\LataleMapLoader\LataleVersionDef.cpp`
- `..\LataleMapLoader\SPLDTFile.cpp`, `SPLDTManager.cpp`, etc.

These must be compiled separately and added to the link.

### Stub files

**MgmtStubs.cpp** provides:
- `CIOCP` static instance + methods (Create, Associate, PostStatus, GetHandle)
- `CIOCPThread2` methods (SetIOCPHandle, Stop, SendPacket_PlainText, SendPacket_Into_SendQueue)
- `Cipher_*` extern "C" functions (Init, Exit, SetInfo, Decrypt, GetLastError)
- `Latale_AtzCheck()`
- `CTeamManager`/`CTeam` stub classes (static member, Find, Add, Delete, New)
- `IOCPThread2Proc_` (global thread proc)

**MgmtSymbolStubs.cpp** provides:
- `CCharacter::ActionCommand`/`ActionCompleteCommand`
- `SPGOBCoordPhysics` stub struct

### Non-fatal PVP/Guild initialization
Patched `LataleMgmtServerApp.cpp` to make PVP Division/Match init failures non-fatal (remove `getchar()` + `return false`, replace with `printf("... (non-fatal, continuing...)\n")`).

## Skipped Files

| File | Reason | Action |
|------|--------|--------|
| `ServerStatInfoThread.cpp` | `#error "NOT SUPPORT!!!"` in header | Excluded from compilation |
| `LataleMapLoader/LDPLoader.cpp` | References `CLogManager2` from ServerBase (circular dep) | Excluded from lib; its symbols not used by MgmtServer |
| `stdafx.cpp` | PCH not used | Excluded from compilation |

## Result

- **LataleMgmtServer.exe**: 414KB, VS2013 /MT statically linked
- **Build date**: May 24, 2026
- **Server starts successfully**, outputs `MGMTServer was Started!!!`
- Guild/PVP initialization failures are now non-fatal
- Configure.ini ResourceDir paths must be corrected to `D:\\彩虹岛\\彩虹岛物语服务端\\Server\\SPF\\`

## LoginServer Rebuild (In Progress)

### Build method

Same Python subprocess approach as MgmtServer. Source files from `LataleLoginServer/` plus `..\\Common\\` and `..\\LataleMapLoader\\`.

### Compilation: 20/20 OK (after removing problematic sources)

| Status | File | Reason Excluded |
|--------|------|----------------|
| EXCLUDED | `ServerMGMTThread.cpp` | Requires `CNamedPipe` — class has no source file anywhere in the project tree |
| EXCLUDED | `LataleWorkerThread_Login.cpp` | Inherits from `CIOCPThread` — distinct from `CIOCPThread2`; the real header doesn't exist |
| EXCLUDED | `ConnectOnly.cpp` | Uses `IO_CONTEXT2` and `CLockObject` from deep include chains |
| EXCLUDED | `Connector2MW.cpp` | Uses MW-specific macros (`SENDPACKET2MW_BEGIN`, `DEFAULT_MW_SERVER_PORT`) |
| EXCLUDED | `stdafx.cpp` | PCH not used |

### Forwarder header technique

Created `LataleLoginServer/CIOCPThread.h` as a forwarder:
```cpp
#pragma once
// CIOCPThread.h -> forwards to the real header which has the class
#include "IOCPThread2.h"
```

This worked for finding the header but `CIOCPThread` and `CIOCPThread2` are **different classes** (different vtable layout), so `CLataleWorkerThread_Login : public CIOCPThread` still fails — the class it inherits from simply doesn't exist in the source tree. Solution: exclude this source file.

### Stub file requirements

LoginServer needs additional stubs beyond MgmtStubs:

| Symbol | Source |
|--------|--------|
| `CIOCPThread2::SendQueue_Append` | Own stub |
| `Cipher_GetMode`, `Cipher_GetClientDynCode` | Own stub (LoginServer doesn't have Cipher in source, only the precompiled EXE did) |
| `CNamedPipe` (constructor, destructor, Create, Close, Listen, Read, Write) | Required by ServerMGMTThread — but class is missing from source tree entirely |

### Link status

20 .obj files compile clean. Link fails with ~20 unresolved symbols — these are the same MgmtStubs symbols (CIOCP, Cipher_*, IOCPThread2Proc_, etc.) plus extra LoginServer-specific ones. Adding MgmtStubs.obj to the link resolves most of them. Final result: **successful link, 254KB EXE**.

### Current blocker

The LoginServer EXE links and runs, outputs `LOGINServer was Started!!!` and `SessionCount=[1]` when a client connects. However, client login still hangs — likely because:
- The excluded `LataleWorkerThread_Login.cpp` is the actual authentication handler
- The alternate thread (`LataleLoginWorkerThreadWithMQ`) may not be fully functional without the Login worker
- Database ODBC configuration may need adjustment

### Takeaway for LoginServer on this source base

The `LataleLoginServer` source tree appears **incomplete** relative to the precompiled EXE — critical source files (CIOCPThread, CNamedPipe) exist only as compiled artifacts in the .exe, not in the source. A full rebuild would need either:
1. Reconstructing missing classes from the old EXE
2. Finding a more complete source tree
3. Hex-patching the old EXE to bypass Cipher/security checks instead
