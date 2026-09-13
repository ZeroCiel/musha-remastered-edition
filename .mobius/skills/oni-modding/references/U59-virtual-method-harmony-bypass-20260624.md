# U59 Virtual Method Harmony Bypass (2026-06-24)

**Build:** U59-737790
**Key finding:** Harmony patches on **virtual/abstract methods** register successfully but **never fire** on U59.

## The Problem

On U59-737790, ONI uses MonoMod's `DynamicMethodDefinition` for IL rewriting. When you patch a **virtual** method with Harmony:

1. Harmony registers the patch (confirmed via Player.log: `[Mod] Patched X.OnSpawn!`)
2. MonoMod replaces the virtual method dispatch with its own IL hook
3. Harmony's detour (memory-level jmp hook) is bypassed because MonoMod's patched IL never reaches the original memory address that Harmony hooked
4. The Postfix **never executes**

## Affected Methods (Confirmed by Testing)

- `MinionIdentity.OnSpawn()` — derived from `KMonoBehaviour`
- `KMonoBehaviour.OnSpawn()` — abstract base class method
- `Game.OnPrefabInit()` — virtual
- `MinionResume.OnSpawn()` — derived from `KMonoBehaviour`

## Non-Virtual Methods That Work

- `Game.LateUpdate()` — instance method, not virtual
- `*Config.CreateBuildingDef()` — static methods, not virtual
- `*ElectrobankDischarger.OnSpawn()` — confirmed working (may be non-virtual in this build)

## Implications

Any Harmony mod targeting per-dupe lifecycle hooks on U59 must find **non-virtual** entry points:

| Goal | Non-Virtual Alternative |
|---|---|
| Grant skill to all existing dupes | `Game.LateUpdate` + `FindObjectsOfType` |
| Grant skill to newly printed dupes | No working approach found yet |
| Modify dupe stats on spawn | No working approach found yet |
| Run code on building placement | `Config.CreateBuildingDef` or concrete Config class static methods |

## Notes

- The exact MonoMod version in U59-737790 is unknown
- Newer ONI builds (post-U59) may have different behavior
- A Harmony Prefix on a virtual method also fails — it's the dispatch mechanism, not Postfix-specific
