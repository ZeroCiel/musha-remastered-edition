# Latale Server Version Port Map

Reference document for port mapping differences between Latale server builds on this machine.

## S3 (D:\LaTale\彩虹岛S3) — 已删，配置保留备查

Base path: `D:\LaTale\彩虹岛S3\Server\`
Configure file: `bin2\configure.ini` (明文)
Status: EXEs are CHDS.dll protected (silent exit 0)

| Service | S3 Port | Notes |
|---------|---------|-------|
| LataleMgmtServer | 10001 | |
| LataleAS | 10020 | |
| LataleLoginServer | 50077 | Key difference from S4chd |
| LataleToolServer | 9001 | |
| LataleBayServer | 10006 | |
| LataleLobbyServer | 10002 | |
| LataleRoomServer | 10007 | |
| LataleGameServer_101 | 10101 | Field channel |
| LataleGameServer_102 | 10102 | Field channel |
| LataleGameServer_103 | 10103 | Field channel |
| LataleGameServer_104 | 10104 | Field channel |
| LataleGameServer_105 | 10105 | Field channel |
| LataleGameServer_151 | 10151 | Indun (instance) |
| LataleGameServer_181 | 10181 | PVP |
| Monster | 6769 | MS A monitor |
| OSP / Gateway (樱花) | 5217, 5317 | Not used; gateway deleted |

Client launch: `LaTaleClient.exe /Full /LoginServer:127.0.0.1:50077 /Run:VHIGH /LOCALE:TAIWAN /PUBLISHER:GAMEFLIER`
(Note: port 50077, NOT 19999 or 20200)

## S4chd (D:\LaTale\S4chd) — 99元国服端，exe正常

Base path: `D:\LaTale\S4chd\`
Configure file: `bin2\configure.ini` (明文)
Status: All EXEs working, no CHDS protection

| Service | S4chd Port | Notes |
|---------|------------|-------|
| LataleMgmtServer | 10001 | |
| LataleAS | 10020 | |
| LataleLoginServer | 20200 | Key difference from S3 |
| LataleToolServer | 9001 | |
| LataleBayServer | 10006 | |
| LataleLobbyServer | 10002 | + 20002 (World 2) |
| LataleRoomServer | 10007 | |
| LataleGameServer_101 | 11023 | Field channel |
| LataleGameServer_102 | 11024 | Field channel |
| LataleGameServer_103 | 11025 | Field channel |
| LataleGameServer_104 | 11026 | Field channel |
| LataleGameServer_105 | 11027 | Field channel |
| LataleGameServer_151 | 11151 | Indun |
| LataleGameServer_152 | 11152 | Indun |
| LataleGameServer_181 | 11181 | PVP |
| Monster | 6769 | |

Client launch: `start LaTaleClient.exe /Full /LoginServer:127.0.0.1:20200 /Run:VHIGH /LOCALE:GSP /PUBLISHER:GSP`

## Database

All versions connect to the same SQL instance (port 59157, LiteSQL 2014 or 2022).
- `dbLaTaleAccount` — account data, shared across versions
- `dbLaTaleWorld_2` — character/game data, shared across versions

Account data IS compatible between S2, S3, and S4 — same table structures from the same source code lineage.
