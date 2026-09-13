# LaTale MgmtServer Compilation Status

## Project structure

Source: `D:\LaTaleServer-\`
Compile target: VS2013 (v120) toolchain, `/MT` (static CRT), console subsystem

## 2026-05-24: Full rebuild with VS2013 — SUCCESS

**Strategy**: Rebuilt ALL 7 dependency libraries from source with VS2013 v120 /MT instead of mixing precompiled VS2012 libs with VS2013 objs.

### Build method

Python script (`C:\Users\Administrator\build_all_v120.py`) parses .vcxproj, extracts source files and compile flags, calls cl.exe via subprocess with INCLUDE/LIB env vars.

### Results

| Component | Status | Size | Notes |
|-----------|--------|------|-------|
| ServerCore.lib | OK | 1.17MB | 24/24 obj |
| ServerBase.lib | OK | 2.36MB | 27/27 obj |
| LataleBattleSystem.lib | OK | 1.89MB | 4/4 obj |
| LataleCheatSystem.lib | OK | 112KB | 2/2 obj |
| OSPAPI.lib | OK | 164KB | 8/8 obj |
| MonsterAPI.lib | OK | 32KB | 4/4 obj |
| LataleMapLoader.lib | OK | 3.49MB | 18/19 obj (excl LDPLoader.cpp) |
| LataleGameLogic.lib | OK (stub) | 60KB | |
| MgmtServer link | OK | 414KB exe | Fully static, no DLL deps |

### Link fix strategy

Three categories of missing symbols:

1. **Stubs in MgmtStubs.cpp**: CIOCP, CIOCPThread2, Cipher_*, Latale_AtzCheck, CTeamManager, CTeam, IOCPThread2Proc_
2. **Real .cpp from Common/**: ServerLog.cpp, ServerStatistics.cpp, OnlineUserInfo.cpp, MakeDSNString.cpp
3. **Remove duplicates**: MgmtSymbolStubs.cpp/MgmtStubs.cpp entries conflicting with real .obj

### Current exe

- Path: `D:\\LaTaleServer-\\bin\\LataleMgmtServer.exe` (414KB)
- Deployed to BIN2 directory
- Runs and outputs `MGMTServer was Started!!!`

## LoginServer rebuild (partial — 2026-05-24)

**Status**: Links successfully (254KB EXE), starts and accepts connections (`LOGINServer was Started!!!`, `SessionCount=[1]`), but login flow doesn't complete.

### Excluded source files

| File | Reason | Impact |
|------|--------|--------|
| `LataleWorkerThread_Login.cpp` | Inherits `CIOCPThread` — class doesn't exist in source (only `CIOCPThread2` exists) | Auth worker may be non-functional |
| `ServerMGMTThread.cpp` | Requires `CNamedPipe` — class has no source file anywhere | GM pipe communication only |
| `ConnectOnly.cpp` | Deep include chain with missing types | MW connector, not needed for single server |
| `Connector2MW.cpp` | MW-specific macros undefined | MW connector, not needed |

### Stubs added

See `LoginServerStubs.cpp` for: `SendQueue_Append`, `Cipher_GetMode`, `Cipher_GetClientDynCode`, and `CNamedPipe`.

### Key finding

The precompiled LoginServer EXE (2.1MB, Oct 2017) contains code that **doesn't exist in the source tree**. The 2017 "他乡" builder modified the EXE directly or used a different source base. A fully working self-compiled LoginServer would need these missing classes reconstructed.
