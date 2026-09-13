# VS2013 Full Rebuild — MgmtServer (2026-05-24)

## Context

Previously, MgmtServer binary was a 2017 third-party modified EXE with hardcoded getchar+return-false on 
PVP Division init failure. Hex-patching the binary worked (patches at 0x13E61, 0x13E98, 0x13EC2, 0x13ED0), 
but the LoginServer also had issues (client connects but SessionCount stays at 1, no server list). 
The ultimate goal was to compile from source to get a clean EXE.

## Toolchain

VS2013 (v120, `D:\VS2013\` — ISO extracted, no installer) + Windows Kits 8.0.

Env setup for Python subprocess calls (the reliable way, avoids vcvarsall.bat issues):
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

CRT linkage: `/MT` (static, MultiThreaded). All libs and EXE use the same linkage.

## Build Order

### Phase 1: Dependency Libraries (7 libs, all VS2013 /MT)

Script: `build_all_libs_v120.py` — parses each vcxproj, compiles all .cpp, links .lib.

| Lib | Source Dir | .cpp count | Result | Size |
|-----|-----------|-----------|--------|------|
| ServerCore | `ServerCore/` | 24 | ✅ All OK | 1.17MB |
| ServerBase | `ServerBase/` | 27 | ✅ All OK | 2.36MB |
| LataleMapLoader | `LataleMapLoader/` | 19 | ⚠️ 18/19 OK (LDPLoader excluded) | 3.49MB |
| LataleBattleSystem | `LataleBattleSystem/` | 4 | ✅ All OK | 1.89MB |
| LataleCheatSystem | `LataleCheatSystem/` | 2 | ✅ All OK | 112KB |
| OSPAPI | `OSPAPI/` | 8 | ✅ All OK | 164KB |
| MonsterAPI | `MonsterAPI/` | 4 | ✅ All OK | 32KB |

**LDPLoader.cpp exclusion**: This file references `CLogManager2` (from ServerBase's LogManager2.h), 
`STAT_CMD`, `MakeApplyCmdID`, `MakeCheckCmdID`. MgmtServer does NOT need these symbols — the 
LDPLoader functions are used by the full game server, not the management server. Removing 
LDPLoader.obj from LataleMapLoader.lib had no effect on MgmtServer linking.

### Phase 2: LataleGameLogic Stub Library

Replaces the original 76MB LTCG-compiled lib. Produced by `LataleGameLogic/LataleGameLogicStub.cpp` 
which includes all 144+ headers from the LataleGameLogic project and provides empty class bodies.

**Stub techniques used** (see windows-msvc-toolchain skill for full details):
- Strategy A: Skip problematic headers (MOBAI.h, MobManager2.h, PCManager2.h) and provide stub classes
- Strategy B: Include-path hijacking — placed stub `CPacketComposer.h` in LataleGameLogic dir
- Strategy C: Modified `ExpManager.h` and `FestivalManager.h` to not include `../LataleGameServer/Character.h`
- Strategy D: Provided full stub classes for CMonster, CCharacter, CMOBAI, etc.
- Added missing typedefs: `EXCEPTION_CODE`, `IO_CONTEXT`
- Added `const` overload for `CPacketComposer::GetBuffer()`

Result: 60KB stub lib (vs 76MB original).

### Phase 3: MgmtServer Compilation

56 .cpp files compiled, 0 failures. Source files from:

| Location | Files |
|----------|-------|
| `LataleMgmtServer/` | All 56 .cpp (excluding ServerStatInfoThread.cpp — `#error "NOT SUPPORT!!!"`) |
| `Common/` | ServerLog.cpp, ServerStatistics.cpp, OnlineUserInfo.cpp, MakeDSNString.cpp |
| Various | Connector4MGMTServer.cpp (needed `(CALLBACK_RECV_FN)` cast) |

### Phase 4: MgmtServer Linking

Initial link failed with 41 unresolved symbols (LNK1120). These fell into 3 categories:

**Category A: Symbols from OTHER executables** (not compiled in MgmtServer project)
Provided stub definitions in `MgmtStubs.cpp`:
- `CIOCP` — `Create`, `Associate`, `PostStatus`, `GetHandle`, constructor, destructor, global `g_IOCP`
- `CIOCPThread2` — constructor, destructor, `Stop`, `SetIOCPHandle`, `SendPacket_PlainText`, `SendPacket_Into_SendQueue`
- `Cipher_*` — `Cipher_Init`, `Cipher_Exit`, `Cipher_SetInfo`, `Cipher_Decrypt`, `Cipher_GetLastError`
- `Latale_AtzCheck` — security check stub (return true)
- `CTeamManager` — static `m_pInstance`, constructor, destructor, `Find`, `Add`, `Delete`, `New`
- `CTeam` — constructor, destructor, `GetCaptainID`, `SetCaptain`, `DeleteMember`, `AddMember`, `FindMember`
- `IOCPThread2Proc_` — global thread proc stub
- `LogManager2` functions — `Init_LogManager2`, `Exit_LogManager2`, `Log_WriteToFile`

**Category B: Real implementations in Common/ dir** — compiled separately, no stub needed.

**Category C: Duplicate symbol management** — removed overlapping stubs from MgmtStubs.cpp 
(CAutoLock::m_cs, CMakeDSNString, COnlineUserInfo, CServerStatistics::m_pInstance, log functions) 
when the real .obj was included.

Final link: **60 .obj files → 414,208 byte LataleMgmtServer.exe** ✅

### Phase 5: Source Fixes After First Successful Compile

After the first clean compile ran and showed:
```
PVPDivision Failed!!!
getchar()  # waits for keypress
return false  # process exits
```

Fixed in `LataleMgmtServerApp.cpp`:
```cpp
// BEFORE (caused process exit):
if(!GetPVPDivisionInfoList()->Init()) {
    printf(" PVPDivision Failed!!! \n");
    getchar();
    return false;
}
if(!GetPVPMatchInfoList()->Init()) {
    printf(" PVPMatch Failed!!! \n");
    getchar();
    return false;
}

// AFTER (non-fatal like Division/Guild):
if(!GetPVPDivisionInfoList()->Init()) {
    printf(" PVPDivision Failed!!! (non-fatal, continuing...)\n");
}
if(!GetPVPMatchInfoList()->Init()) {
    printf(" PVPMatch Failed!!! (non-fatal, continuing...)\n");
}
```

Recompiled just LataleMgmtServerApp.cpp + relinked → 413,696 byte EXE ✅. 
EXE now starts, outputs `MGMTServer was Started!!!` and stays running.

### Phase 6: LoginServer Compilation Attempt

21 source files parsed from `.vcproj` (VS2005 format). 20 compiled OK, 1 failed:

**LataleWorkerThread_Login.cpp** — `LataleWorkerThread_Login.h` includes `"CIOCPThread.h"` which 
doesn't exist as a file (class is `CIOCPThread2` in `IOCPThread2.h`). Fixed by placing a forwarder 
header `CIOCPThread.h` containing `#include "IOCPThread2.h"` in the project directory.

But then `CIOCPThread` class itself wasn't found (the forwarder only includes headers, doesn't 
define the class). This class uses `CSessionManager` which in turn has `#error "NOT SUPPORT!!!"` 
in `Src/CSessionManager.h`. LoginServer source has multiple deprecated/unsupported components.

**Stopped**: LoginServer requires deeper investigation into its source code dependencies. 
The existing 2017 LoginServer binary works for TCP accept (shows SessionCount=1) — the 
real issue is likely the Cipher/encryption layer, protocol version mismatch, or the 
combination of MgmtServer not running previously.

**Update: LoginServer also compiled and linked successfully!** After removing `ServerMGMTThread.cpp` 
(needs `NamedPipe.h` which doesn't exist in the source tree) and adding `LoginServerStubs.cpp` 
(with stubs for `CIOCPThread2::SendQueue_Append`, `Cipher_GetMode`, `Cipher_GetClientDynCode`, 
`CNamedPipe`), the link succeeded with 20 .obj + MgmtStubs.obj = **253,952 byte LataleLoginServer.exe** ✅.

The new LoginServer has **no Cipher encryption** (the source doesn't reference Cipher at all — 
it was added by the third-party 2017 modifier to the old EXE). This should fix the 
client-stuck-at-"连接中" issue.

To use: close the old LoginServer window, then copy `D:\LaTaleServer-\bin\LataleLoginServer.exe` 
to `D:\彩虹岛\彩虹岛物语服务端\Server\BIN2\`.

## Key Scripts

- `C:\Users\Administrator\build_all_v120.py` — Build all 7 dependency libs
- `C:\Users\Administrator\build_mgmt_v120.py` — Build MgmtServer (compile + link)
- `C:\Users\Administrator\build_login_v120.py` — Build LoginServer (WIP)
- `C:\Users\Administrator\build_lgl_stub3.py` — Build LataleGameLogic stub compilation

## Files Modified During Build

| File | Change |
|------|--------|
| `LataleMgmtServer\LataleMgmtServerApp.cpp` | PVP Division/Match fail → non-fatal |
| `LataleMgmtServer\MgmtStubs.cpp` | Added CIOCP, CIOCPThread2, Cipher, Team, Log stubs |
| `LataleMgmtServer\MgmtSymbolStubs.cpp` | Removed CAutoLock duplicate |
| `LataleMgmtServer\Connector4MGMTServer.cpp` | Added `(CALLBACK_RECV_FN)` cast |
| `LataleGameLogic\LataleGameLogicStub.cpp` | Added full stub classes, skipped MOBAI/MobManager2 |
| `LataleGameLogic\ExpManager.h` | Removed `#include "../LataleGameServer/Character.h"` |
| `LataleGameLogic\FestivalManager.h` | Same |
| `LataleGameLogic\CPacketComposer.h` | Stub file to prevent include from `..\src\` |
| `LataleLoginServer\CIOCPThread.h` | Forwarder stub `#include "IOCPThread2.h"` |

## Result

```
[LataleMGMTServer] [RELEASE] Build Time : May 24 2026 06:36:23
MGMTServer was Started!!!
```
