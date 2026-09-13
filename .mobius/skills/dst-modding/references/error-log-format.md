# DST Lua Error Log Anatomy

## Module-not-found error

```
[string "../mods/<modname>/scripts/..."]:<line>: module '<module.name>' not found:
    no field package.preload['<module.name>']
    no file '<searched_path_1>' (checked with custom loader)
    no file '<searched_path_2>' (checked with custom loader)
    ...
```

Each `no file` entry is a path the game's custom loader checked. The first one is usually the most relevant — it's the "canonical" path for that module within the mod.

The last-searched paths with backslashes (`\`) are Windows-specific fallbacks.

## Stack traceback

```
LUA ERROR stack traceback:
    =[C]:-1 in (global) require (C) <-1--1>
    ../mods/<mod>/scripts/<file>.lua:<line> in ...
    ...
```

Read **top to bottom**:
- Topmost line: the failing `require` call (the immediate error)
- Lines below: the call chain leading to the error
- The first mod-specific file in the chain is where to start investigating

## Transitive dependency example

```
mingsheng_teleportscreen.lua:6 → require "mingsheng.scripts.lib.uidragzoom"  ← FIRST FIX
uidragzoom.lua:24 → require "persistentdata"                                 ← SECOND FIX
```

Always re-run after the first fix — the second error only surfaces when the first module actually loads.
