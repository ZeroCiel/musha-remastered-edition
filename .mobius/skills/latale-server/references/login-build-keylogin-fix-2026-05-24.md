# LoginServer KEYLOGIN handler: Local-mode authentication fix

## Problem

Compiled LoginServer starts successfully (`LOGINServer was Started!!!`), accepts TCP connections (`SessionCount=[1]`), but **doesn't respond** when the client sends login credentials. The client stays stuck on "连接中" (connecting...).

## Root Cause

The client sends `AUTH_CS_KEYLOGIN` (not `AUTH_CS_LOGIN_EX`). The KEYLOGIN handler in `LataleWorkerThread_auth.cpp` has:

```cpp
if(g_iOSPMode > SITE_LOCAL)  // i.e., OSPMode != 0
{
    RequestAuthizingToOSP2(...)  // sends auth to OSP server
}
// No else branch! When OSPMode=0 (local), the function falls through
// and returns without sending any response to the client.
```

With `OSPMode=0` (local mode) in `configure_share.ini`, the `if` block is skipped entirely, and **no packet is ever sent back** to the client.

## Fix

Add an `else` branch in the KEYLOGIN handler for local mode:

```cpp
else
{
    // Local mode: validate against DB directly
    RESULTCODE resultCode2 = LT_ERROR_FAILED;

    if(_tcslen(szKeyID) > MAX_LEN_ID_DB)
    {
        resultCode2 = LT_ERROR_UNAVAILABLEID;
    }
    else
    {
        USERID userID = 0;
        int iDBResultCode = 0;

        if(pThis->m_AccountDB.AddAccount(szKeyID, iDBResultCode, userID))
        {
            resultCode2 = (RESULTCODE)iDBResultCode;
            if(LT_NO_ERROR == resultCode2)
            {
                pSessionContext->SetProcessStep(PLAYSTEP_AUTH);
                pSessionContext->SetUserID(userID);
            }
        }
    }

    SENDPACKET_WITH_SENDQUEUE_BEGIN(AUTH_SC_LOGIN)
        packet << resultCode2;
    if(resultCode2 == LT_NO_ERROR)
    {
        USERID userID = pSessionContext->GetUserID();
        PASSPORT passport = 0;
        packet << userID << passport << g_ServerID;
        packet.PushBack(szKeyID, MAX_LEN_ID);
    }
    SENDPACKET_WITH_SENDQUEUE_END(pSessionContext);
    return;
}
```

## However — this fix wasn't tested because...

The client sends `AUTH_CS_KEYLOGIN`, but adding a printf at the top of `AUTH_CS_KEYLOGIN` and `AUTH_CS_LOGIN_EX` revealed: **neither handler produced output**, meaning the client is sending a different protocol entirely or the packet dispatch doesn't reach these handlers.

The session ended before root-causing which packet the client actually sends. Candidates:
- `AUTH_CS_KEYLOGIN` (standard key-based login)
- `AUTH_CS_LOGIN_EX` (extended login)
- `AUTH_CS_EKEY` (external key login for Sanda/SHANDA)
- `PROTOCOL_CS_START_RES` (session start — unlikely to be the login packet itself)

## Diagnostic technique

Add `printf()` at the start of every `DEFINE_PACKET_PROC` handler in `ServerMainThread.cpp`'s registered packet list:

```cpp
DEFINE_PACKET_PROC(PROTOCOL_CS_START_RES)
{
    printf("[PROTOCOL_CS_START_RES] Received\n");
    ...
}
```

Then observe the LoginServer console when the client connects and submits credentials.

## Files modified

| File | Change |
|------|--------|
| `LataleWorkerThread_auth.cpp` | Added `else` branch for `OSPMode <= SITE_LOCAL` in `AUTH_CS_KEYLOGIN` |
| `LataleWorkerThread_Auth_Ex.cpp` | Added `printf` debug to `AUTH_CS_LOGIN_EX` |
| `LataleWorkerThread_MGMT.cpp` | Added `printf` debug to `PROTOCOL_CS_START_RES` |
| `LataleWorkerThread_World.cpp` | Added `printf` debug to `WORLD_CS_GETLIST` |
