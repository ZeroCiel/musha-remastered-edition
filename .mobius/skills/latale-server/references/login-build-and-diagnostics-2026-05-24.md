# LoginServer Build & Login Diagnostics (2026-05-24)

## Summary

MgmtServer was fully rebuilt from source and runs successfully. LoginServer was also rebuilt from source (254KB, no Cipher). Client TCP connects (SessionCount=1) but login hangs on "连接中" after entering credentials.

## Key Diagnostic Finding: LoginSource Source Tree Incompleteness

The `LataleLoginServer` source tree is **incomplete** relative to the old precompiled EXE:

| Missing Component | Required By | Status |
|---|---|---|
| `CNamedPipe` class (`.h`/`.cpp`) | `ServerMGMTThread.h` (`#include "NamedPipe.h"`) | **No source file exists anywhere** in the project tree. Likely from a different built environment. Excluded from build. |
| `CIOCPThread` class (`.h`) | `LataleWorkerThread_Login.h` (inherits `CIOCPThread`) | Only `IOCPThread2.h` exists. `CIOCPThread` is a **different class** — not just a different filename. Excluded from build. |
| `CSessionManager` header | `Src/` directory (`#error "NOT SUPPORT!!!"` at line 1) | Old deprecated template — excluded via transitive include avoidance. |

The files that were excluded from compilation may process the actual login packets. If the client sends the right protocol but the handler isn't compiled in, login will silently hang.

## OSPMode Configuration

`configure_share.ini` `[OSP]` section:

```ini
OSPMode=0  ; Local(0) — use DB auth, don't call OSP server
           ; was 7 (OGP) — causes LoginServer to try OSP handshake and hang
```

When OSPMode is non-zero, LoginServer calls `RequestAuthizingToOSP2()` to verify credentials through an external OSP server on port 5217. No such server exists locally — 5217 is used by the gateway as a proxy port, not an auth server. **Set OSPMode=0 to use local database auth.**

## Auth Flow in `AUTH_CS_LOGIN_EX`

```
1. GETVALUE(option, major, minor) → version check
2. GETVALUE(lenParam[0], lenParam[1]) → ID/PW lengths
3. GETDATA(szParam[0], szParam[1]) → read ID/PW
4. CheckResourceVersion() → if client resource version doesn't match, return LT_ERROR_RESOURCE_VERSION_LOWER
5. switch(g_iOSPMode):
   - SITE_ACTOZ(1): CheckMaskString(ID)
   - SITE_LOCAL(0): m_AccountDB.AddAccount(ID, resultCode, userID)
                    → if account exists, returns existing userID
                    → if account doesn't exist, CREATES it (auto-register!)
                    → NO PASSWORD CHECK in local mode!
   - default: RequestAuthizingToOSP2() → needs OSP server
6. SENDPACKET_WITH_SENDQUEUE_BEGIN(AUTH_SC_LOGIN) → send result to client
```

Key observation: in SITE_LOCAL mode, the password is RECEIVED but NEVER CHECKED. The `AddAccount` function either finds or creates the account by ID alone. This is a development/debug feature — the real auth happens in OSP mode.

## Why Login Still Hangs

Possible causes (in order):

1. **`AUTH_CS_LOGIN` handler not compiled** — the excluded `LataleWorkerThread_Login.cpp` registers `AUTH_CS_LOGIN`. If the client sends the old protocol (not `AUTH_CS_LOGIN_EX`), no handler fires and the client waits forever.
2. **Packet format mismatch** — the client's login packet structure (field order, sizes, version bytes) may not match what the source expects.
3. **Resource version check** — `CheckResourceVersion` reads additional fields from the client's packet. If parsing fails, the function may skip sending any response.
4. **`SENDPACKET_WITH_SENDQUEUE_BEGIN` macro may silently fail** — if `CSessionContext` is invalid or send queue is uninitialized, the response packet may not be sent.

## How to Debug Further

1. Add `printf` at the start of `AUTH_CS_LOGIN_EX` and at the `endProc:` label to confirm the function is reached
2. Check if `CheckResourceVersion` returns true (forces `bNeedResPatch=true` → `LT_ERROR_RESOURCE_VERSION_LOWER` → goes to endProc)
3. Compare client packet layout (from old EXE logic or packet capture) with source expectations
4. Add a stub `AUTH_CS_LOGIN` handler (the old protocol) to see if the client sends that instead
