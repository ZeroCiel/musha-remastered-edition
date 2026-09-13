# Latale Database & Port Configuration Reference

## Database Instance Locations

| Instance | Path | Typical Port | Contains |
|----------|------|-------------|----------|
| LiteSQL2014 (S4chd) | `D:\LaTale\S4chd\数据库\LiteSQL2014_Release\` | 2433 | dbLataleAccount, dbLaTaleWorld_2 |
| LiteSQL2022 (S4chd) | `D:\LaTale\S4chd\数据库\LiteSQL2022\` | varies | Same databases |
| JSQL2008 (S2 他乡专属) | `C:\JSQL2008\` | 1433 or random | dbLataleAccount, dbLaTaleWorld_2 |
| 彩虹岛S4 | `D:\LaTale\彩虹岛S4\数据库\LiteSQL2014_Release\` | 2433 | Same databases (different instance) |

## Global_ODBC.ini Configuration

All Latale server builds use the same structure in their `Global_ODBC.ini`:

```ini
[AccountDB]
IP = 127.0.0.1,{port}
ID = sa
PW = 123456
DATABASE=dbLataleAccount

[GameDB_1]
IP = 127.0.0.1,{port}
ID = sa
PW = 123456
DATABASE=dbLaTaleWorld_2
```

Key: The default SA password across ALL Chinese private server builds is `123456`.

## Port Mapping by Build

| Service | S2 他乡端 | S3 彩虹岛S3 | S4chd (99元) | 彩虹岛单机 |
|---------|-----------|------------|-------------|-----------|
| MgmtServer | 10001 | 10001 | 10001 | 10001 |
| AS | 10020 | 10020 | 10020 | 10020 |
| LoginServer | 50077 | 50077 | 20200 | 19100 |
| ToolServer | — | 9001 | 9001 | — |
| LobbyServer | 10002 | 10002 | 10002 | 10002 |
| BayServer | 10006 | 10006 | 10006 | 10006 |
| RoomServer | 10007 | 10007 | 10007 | 10007 |
| GS 101 | 10101 | 10101 | 11023 | 10003 |
| GS 102 | 10102 | 10102 | 11024 | 20003 |
| GS 103 | — | 10103 | 11025 | — |
| GS 151 (Indun) | 10151 | 10151 | 11151 | 10005 |
| GS 181 (PVP) | 10181 | 10181 | 11181 | — |
| Monster | 6769 | 6769 | 6769 | 6769 |

## Troubleshooting Database Connection

1. **Check which SQL instance is running**: `tasklist | findstr sqlservr`
2. **Find its port**: `netstat -ano | findstr {PID}`
3. **Verify the port matches** the `Global_ODBC.ini` setting
4. **Common problem**: After switching between builds, the SQL instance serving port 59157 may no longer be running. Update Global_ODBC.ini to point to the active instance's port.
