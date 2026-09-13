# 明生 (Mingsheng) — DST Character Mod Overview

## Distinction

明生 and Musha (穆莎) are **separate DST character mods** in the same `mods/` directory. Do not confuse them.

- 明生: 卜者 (diviner) — 8 types of 告示 (scrolls) + 知天命 weapon
- Musha: 职业系统 (warrior/mage/ranger/assassin) with quest system

## Mod Location

```
D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\mingsheng\
```

## Core Stats

| Stat | Value |
|------|-------|
| Health | 150 |
| Sanity | 200 |
| Hunger | 110 |

## Abilities

| Condition | Effect |
|-----------|--------|
| Low sanity | Night vision |
| High sanity | Speed boost |
| Always | Won't eat fish |

## Items (8 告示 + 1 weapon)

| Prefab | Name | Function |
|--------|------|----------|
| `mingsheng_ztm` | 知天命 | Weapon + 7-slot container for scrolls |
| `mingsheng_mingli` | 卜算·命理 | Consume HP, revive ally/ghost |
| `mingsheng_mengyan` | 卜算·梦魇 | Consume sanity, summon 2 shadow clones |
| `mingsheng_tianti` | 卜算·天体 | Nightmare fuel → new moon, moonrock → full moon |
| `mingsheng_zaoyu` | 卜算·遭遇 | Consume sanity, AoE sanity regen + sleep enemies |
| `mingsheng_yuehua` | 卜算·月华 | Consume hunger, summon 2 illusion clones |
| `mingsheng_shengcun` | 卜算·生存 | Put in 知天命 → slow hunger drain |
| `mingsheng_shenxing` | 卜算·神行 | Mark signposts → teleport between them |
| `mingsheng_zhuangmihu` | 装迷糊 | Head slot, 77min fuel, warmth + sanity regen + 30% craft cost offset |
| `mingsheng_gaoshizhe` | 告示者 | Paper minion, give to shadow/illusion to fight |
| `mingsheng_mingyun` | 命运之外 | Armor from 7 scroll types, right-click condenses random scroll |

## Known Issues

### Icon Status (2026-06-28)

| Issue | Status |
|-------|--------|
| `mingsheng_zhuangmihu` missing .tex/.xml icon file | ❌ Missing |
| `mingsheng_shenxing` uses `mingsheng_mingli` icon (no own icon) | ⚠️ Shared |
| `mingsheng_shengcun` uses `mingsheng_mingli` icon (no own icon) | ⚠️ Shared |

### modmain.lua Declares Assets

modmain.lua explicitly declares these inventory image assets:
- `mingsheng_hunger.xml` (custom hunger type icon)
- `mingsheng_shengcun.xml`
- `mingsheng_shenxing.xml`

All other scroll icons (mingli, mengyan, tianti, zaoyu, yuehua, ztm, mingyun, etc.) are declared in their respective prefab `.lua` files.

## No Quest System

明生 has **no built-in quest/mission/task system**. The mod is a pure character with divination scrolls. If the user asks about "明生任务", they may be confusing it with Musha's quest system.
