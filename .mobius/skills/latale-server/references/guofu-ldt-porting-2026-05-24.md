# Guofu (S4 Chinese) LDT Porting to S2 — 2026-05-24

## Summary

The installed guofu client at `D:\Program Files\上海数龙科技有限公司\彩虹岛Online\` contains LDT files with **simplified Chinese text** encoded in **GBK**, not euc-kr Korean. The S2 server can read these after switching to `Pack=0` (directory mode) and pointing to the extracted LDT directory.

## Compatible LDTs (direct replace — column structure identical)

| LDT | S2 Cols | GF Cols | S2 Rows | GF Rows | Notes |
|-----|---------|---------|---------|---------|-------|
| WORLD_MAP_STAGE.LDT | 18 | 19 | 500 | 375 | GF has 1 extra col `_Map_Search` at end |
| GLOBAL_STRING.LDT | 3 | 3 | 3500 | 5825 | Same 3 cols |
| SKILL_TXT.LDT | 4 | 4 | 4862 | 3878 | Identical |
| NPCTALK.LDT | 34 | 37 | 30179 | 79041 | GF has 3 extra cols |
| UI_TOOLTIP.LDT | 6 | 6 | 1000 | 1506 | Identical |
| LOCALIZE.LDT | 3 | 3 | 100 | 108 | **⚠️ KNOWN ISSUE** — see below |

## INCOMPATIBLE LDTs

| LDT | S2 Cols | GF Cols | Issue |
|-----|---------|---------|-------|
| MAP_INFO.LDT | 4 | 47 | Completely different structure |
| GLOBAL_SYS.LDT | 3 | 3 | Col 1 type differs: S2=Str vs GF=S32 |
| CASH_SHOP.LDT | 65 | 71 | GF has 6 extra cols + different _Name encoding (still euc-kr Korean, not Chinese) |
| ITEM_1/2/3.LDT | 126/127 | 127/127 | Not checked — ItemID differences expected |

## LOCALIZE.LDT Issue

When using the guofu LOCALIZE.LDT, AS fails to start with:
```
LOCAL_DEFINE_EXTEND_CHARSLOT is out of range!!!
LoadLocalizeLDT() -- LOCAL_DEFINE_EXTEND_CHARSLOT = 14
```

**Root cause**: The guofu LOCALIZE.LDT has a different layout or value for EXTEND_CHARSLOT that exceeds the S2 server's expected range. The AS process binds port 10020 but never finishes initialization — Lobby/Bay/Room also fail to start because they depend on AS.

**Fix**: Keep the original S2 LOCALIZE.LDT. Do NOT replace it.

## Pack=0 Mode (Directory-Based Resource Loading)

Instead of repacking SPF files (which requires full SPF rebuild when file sizes change), set:

```ini
ResourceDir = D:\Server\SPF\extracted\
Pack = 0
```

This makes the server read LDT files directly from the `DATA/LDT/` subdirectory under `ResourceDir`.

**Important**: ALL service sections need their own `Pack=0` + `ResourceDir` override. The `[LataleGameServer_101]` section, `[LataleRoomServer]`, etc. each have their own `Pack=` setting that overrides the global one.

**Verification**: After setting pack=0, the server's console output at startup shows:
```
ResourceDir:D:\Server\SPF\extracted\
```

## GLOBAL_STRING.LDT File Size Issue

| Version | Size | Encoding | Text |
|---------|------|----------|------|
| S2 (original) | 110,575 bytes | euc-kr | Korean/mojibake |
| Guofu (S4) | 300,079 bytes | **GBK** | ✅ Simplified Chinese |

The guofu version is ~3x larger because it has more strings (5825 rows vs 3500) and Chinese text uses fewer bytes than Korean multi-byte sequences — wait, Chinese should be *smaller*. The size difference is from 2325 extra rows.

**Because sizes differ, in-place SPF replacement is impossible.** Must use `Pack=0` directory mode.

## Decoding

```python
# guofu LDTs use GBK encoding, NOT euc-kr
with open('guofu_LDT', 'rb') as f:
    data = f.read()
text = data.decode('gbk', errors='replace')
```

## What Was Actually Replaced (2026-05-24)

Files copied from guofu `DATA/LDT/` to S2 `extracted/DATA/LDT/`:
- WORLD_MAP_STAGE.LDT ✅ — shows "贝罗斯城市", "艾丽娅斯城市" etc.
- GLOBAL_STRING.LDT ✅ — UI text in simplified Chinese
- SKILL_TXT.LDT ✅
- NPCTALK.LDT ✅
- UI_TOOLTIP.LDT ✅
- LOCALIZE.LDT ❌ — reverted to S2 original (AS crash)

These were NOT copied to the SPF archive (ROWID.SPF) because their sizes differ from the originals. The server uses `Pack=0` directory mode to read them from `extracted/`.

## Verification Method

After replacing and restarting with Pack=0:
1. Start the game client
2. Open world map / talk to NPCs / check UI text
3. If still showing traditional Chinese (繁体) or Korean → the server is still reading from the SPF archive. Check that ALL service sections in configure.ini have `Pack=0`.
