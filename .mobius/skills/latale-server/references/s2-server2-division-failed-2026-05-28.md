# S2 Server2 Division-Failed Fatal Bug Confirmed (2026-05-28)

## The Bug (100% reproducible)

The S2 hisxiang MgmtServer.exe (both D:\Server\BIN2\ and D:\LaTale\Server2\BIN2\ versions) exits immediately after:

```
LataleMGMTServer_W1S11
    GUILD infos loading... Division Failed!!! 
```

**Exit code**: 0 (clean exit, no crash)

**Root cause**: `CDivisionInfoList::Init()` in the server source code loads Division/PVP LDT data, fails (because the LDT file doesn't exist or has wrong format in hisxiang's stripped SPF), and the error handler path calls `getchar()` then `return false`, causing `OnStartup` to return false and the process to terminate.

**Known fix**: Hex-patch the exe to make Division failure non-fatal (skip the error handler). See `references/hex-patch-mgmtserver.md` for the exact patch offsets.

**Alternative fix**: Recompile MgmtServer from source with the `CDivisionInfoList::Init()` failure path modified to continue instead of exit. The compiled VS2013 version (414KB) at D:\LaTaleServer-\ works correctly.

## Server2-Specific Context

This session tested the S2 server at `D:\LaTale\Server2\BIN2\` with the following result:

1. The exe prints `Load configure from Security INI` (not regular configure.ini) — confirms it's hisxiang's modified exe with CHDS protection
2. Build time: Oct 5 2017 13:33:29
3. Division Failed!!! is fatal — process exits after the error
4. All 7 servers (Mgmt, AS, Login, Lobby, Bay, Room, GS) affected: if Mgmt won't bind port 10001, the rest can't connect

## Attempted Workarounds

| Attempt | Result |
|---------|--------|
| Pack=1 (default, read encrypted SPF) | Division Failed (GLOBAL_SYS.LDT missing from stripped SPF) |
| Pack=0 (directory mode) | Division Failed (GLOBAL_SYS.LDT missing + exe SPF integrity check) |
| Remove CHDS.dll | Mgmt starts but same Division Failed exit |
| Fix resourceDir paths | Same Division Failed exit — not a path issue |

**Conclusion**: The S2 hisxiang server files at D:\LaTale\Server2\ are not usable. The exe has a fatal Division/PVP initialization bug that prevents MgmtServer from binding its port. Without hex-patching the exe or recompiling from source, no configuration change fixes this.

**User verdict**: "不用了.jpg" — abandoned this approach in favor of S4CHD.
