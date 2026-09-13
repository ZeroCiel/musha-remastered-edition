# Latale S2 Server Suite Startup — 2026-05-24 Session Notes

## Discovery: D:\Server contains a complete 2017 hexiang (他乡) build

The directory `D:\Server\` was created by the user (unintended duplication of old server files) but turned out to be **a fully working 2017 precompiled server suite**:

- **BIN2/** — All server EXEs + CHDS.dll (VMProtect companion) + gateways
- **SPF/** — SPF resource archives (ROWID.SPF is the main data bundle)
- **彩虹岛樱花网关.exe** — OSP gateway (standalone, binds 5217/5317/19730)

The source tree remains at `D:\LaTaleServer-\` untouched.

## Architecture

```
Gateway (5217 OSP, 5317 Shop, 19730)
  ├── MgmtServer (10001) — world manager hub
  ├── AS (10020) — auth service
  ├── LoginServer (19999) — client-facing login (requires OSP from Gateway)
  ├── LobbyServer (10002) — channel list
  ├── BayServer (10006) — auction/coin (connects to Gateway:5317 for shop)
  ├── RoomServer (10007) — multiplayer rooms
  └── GameServer_101 (20001) — game world instance
```

Key insight: LoginServer's `configure_share.ini` has `OSPMode = 7` — meaning it relies on an external OSP server (the gateway) for authentication. Without the gateway running, LoginServer's thread continuously retries `FD_CONNECT=[0, 10061] : Dest=[127.0.0.1:5217]` (every ~10s).

## Verified Startup Sequence

The user ran the server suite manually by launching each process. The gateway (彩虹岛樱花网关.exe) **must be started first** because:
1. It binds 5217/5317 as the OSP endpoint
2. LoginServer connects to 5217 for authentication
3. BayServer connects to 5317 for shop data
4. Without it, LoginServer logs 10061 errors and no client can authenticate

The resulting healthy server shows all these ESTABLISHED connections:
```
Gateway(5217) ── LoginServer ── AS ── MgmtServer ── LobbyServer
                           └── AS ── MgmtServer ── BayServer ── Gateway(5317)
                                                    └── RoomServer ── GameServer
```

## Verification: Client Successfully Logged In

With the full server suite running:
1. Client (LaTaleClient.exe with batch file args) connects to LoginServer:19999
2. OSP handshake with gateway succeeds (trace log shows "OSP Return : [12] [* 3 200 O")
3. User reached character selection → channel selection → successfully entered game!

## Startup Scripts (created 2026-05-24)

### `start_server.bat` (in BIN2 dir)

One-click launcher that:
1. Accepts optional IP parameter for LAN/Hamachi
2. Patches configure.ini IP fields via PowerShell
3. Launches gateway first (via `start ""` for Chinese filename)
4. Launches all 7 backend services in sequence with `start /B`
5. Falls back to 127.0.0.1 if no IP given

Usage:
```
start_server.bat          # localhost
start_server.bat 192.168.1.100   # LAN
start_server.bat 25.xxx.xxx.xxx  # Hamachi
```

### `start_client.bat` (in client dir)

Simple launcher that passes LoginServer IP to LaTaleClient.exe:

```
start_client.bat                  # connects to 127.0.0.1:19999
start_client.bat 192.168.1.100   # connects to LAN server
```

## Issues Discovered

### 1. CASH_SHOP.LDT — 941 items hidden

All visible items: ~3202, Hidden: 941 (CategoryView=0). The hidden items existed in the LDT but were not displayed in the in-game shop. Fix: toggle all CategoryView Bool from 0→1 and re-pack into ROWID.SPF.

### 2. GameServer section name mismatch

`Latalegameserver_101.exe` (2017 build) looks for `[LataleGameServer]` section in configure.ini, but the file only has `[LataleGameServer_101]`. Error: `INVALID SECTION INFO : INI_FILE=[...] SECTION=[LataleGameServer]`. Fix: add a bare `[LataleGameServer]` section with ServerID=101 and all required fields.

### 3. ResourceDir path garbled

Original path `D:\彩虹岛\Server\SPF\` was stored in ANSI encoding but the bytes became UTF-8 replacement characters (0xEFBFBD ×5) when processed through mixed-encoding tools. Fixed via binary replacement to `D:\Server\SPF\`.

### 4. No teleport stone (순간이동석) in data

Search in ITEM_1/2.LDT found only `[삶땡] Gatia Sue Stone(7莖)` in ITEM_2 — a temporary event item, not a permanent teleport stone. Confirmed: Taiwan S2 removed the teleport stone that exists in the Chinese S4 version. To add it back would require creating the item definition in ITEM_2.LDT and adding it to CASH_SHOP.LDT.

## User Interaction Takeaways

- This user is a Chinese-speaking private server developer (彩虹岛/LaTale). Communicate in Chinese.
- Responds with short confirmations: "1", "开始吧", "嗯嗯"
- Prefers direct action: "先搞" (do it now) rather than discussing options
- Uses machine translation as a fallback but acknowledges poor quality for Korean→Chinese
- Familiar with hex editing, SQL, server process management
- Willing to manually copy/edit files over using automation tools
