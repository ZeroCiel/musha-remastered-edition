# RageZone Leads & Server File Sources

Discovered 2026-05-26. User browsed RageZone via local browser and saved HTML pages.

## Primary Lead: Latale S2 Server Files

**Post URL**: `https://forum.ragezone.com/threads/latale-s2-server-files.1126035/`
**Poster**: Anonymous Chinese user (claimed friend hacked the files)
**Date**: 2017-12-03, update: 2017-12-03

### Original Google Drive Links (likely dead)
- **Server**: `https://drive.google.com/file/d/1RjoUUgnEZuVIal-woDZidT78LGDss3CW/view`
- **Database**: `https://drive.google.com/file/d/1edb3UBR4SH2Qw4UvDuseoSrOa1i6sFiv/view`
- **Client**: hidden behind RageZone login

### Second Post (klugor) MEGA Mirror
Link hidden behind RageZone login.

### Key info
- Season 2 (matching current hisxiang pack)
- 2017 vintage

## Secondary Lead: Geordan9's Guide

**Post URL**: `https://forum.ragezone.com/threads/la-tale-private-server-files-everything-you-need-to-know.1126035/`
**Poster**: Geordan9 (ran "GeoTale")
**Date**: 2017-02-13, last edited 2024-12-28

Paywall — download links require login/payment.

## Secondary Lead: "解密3000" / B站 SPF加密作者

User contacted a seller offering **S4 source code for 99 RMB**. This is the most promising path — source code means no SPF encryption, full control. User plans to purchase "in a few days."

## RageZone Page Scraping

RageZone uses Cloudflare. Cannot scrape via curl. User must:
1. Open page in local browser
2. Ctrl+S → save HTML
3. Agent reads saved file

Author names may show as "?" during parsing — check `class="username"` href attribute.

## 2026-05-26 Source Assessment

| Source | Cost | What You Get | Assessment |
|--------|------|-------------|------------|
| Hisxiang pack | Already own | Encrypted SPF + exe | Can't modify SPF |
| RageZone S2 GD links | Free | Server+DB files | Likely dead after 9 years |
| Geordan9 | Paywall | Server files+tools | Paywall |
| **S4 source code** | **99 RMB** | **Full source code** | **Most promising — no encryption** |
