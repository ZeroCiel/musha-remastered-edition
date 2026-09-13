# Grant Swim Skill & No Water Stress Session (June 20, 2026)

## Goal
Make printed duplicants immune to wet feet / soaking wet stress effects.

## Attempted Approaches

### 1. Patch Effects.AddEffect to block WetFeet/SoakingWet (CRASHED)
- `[HarmonyPatch(typeof(Effects), "AddEffect")]` with `static bool Prefix` returning `false`
- Crashed on enable — overload resolution failure (multiple AddEffect overloads)
- `TargetMethod()` returned null (wrong method found), also crashed
- **Lesson**: `Effects.AddEffect(string)` may not exist on build 587362; use TargetMethod with explicit param types

### 2. Coroutine Removal from internal effects list (FAILED)
- `game.StartCoroutine(...)` in `Game.OnPrefabInit` postfix
- Tried accessing `effects.effects` (internal IList field) and removing WetFeet/SoakingWet
- Also tried `RemoveEffect(string)` via reflection — method doesn't exist on this version
- **Lesson**: Effects component's internal structure on old ONI is different; RemoveEffect(string) was added later

### 3. Patch Db.Initialize to strip Stress modifiers from wet effects (NOT TESTED)
- Find wet-related effects by name match (contains "Wet"/"Soak")
- Remove `SelfModifiers` entries with `AttributeId == "Stress"`
- Effect stays visible but no stress impact

### 4. Patch IsWearingAirtightSuit (PLANNED — code written but not tested)
- Manual `harmony.Patch()` in `Game.OnPrefabInit` postfix
- Postfix checks for DiversLung trait, sets `__result = true`
- **Theory**: Should work because this is how dry suits prevent wetness natively

### 5. Grant Swimming1 skill (WRITTEN — compiled but not tested)
- Use `Game.OnPrefabInit` + coroutine, find `Swimming1` skill from `Db.Get().Skills`
- Call `MinionModifiers.MasterSkill(targetSkill)` on all duplicants periodically
- **Theory**: Swimming skill naturally prevents wet feet stress, no Harmony magic needed

## Key Discoveries

### Swimming-Related Skills/IDs
- `Swimming1` — basic swimming skill (prevents wet stress)
- `Swimming2` — advanced swimming skill
- `GRANTSKILL_SWIMMING` — trait that grants Swimming
- `EnsureSwimmingSkill` — game method that checks/grants swimming
- `hasSwimSkill` — flag/field on duplicant

### Wetness Prevention Chain (natively)
DrySuit/RubberBoots → `IsWearingAirtightSuit = true` → Ga sliquidExposureMonitor skips irritation → WetFeet/SoakingWet not applied

### Effects.RemoveEffect(string) Does NOT Exist on Build 587362
This method was added in a later ONI update. Attempting to use it crashes. All reflection fallbacks also fail.

### Files Created
- `D:/.../mods/local/NoWaterStress/` — various attempts at preventing wet stress
- `D:/.../mods/local/GrantSwimSkill/` — grant swimming skill to all duplicants
- `D:/.../mods/local/AllDiversLung/` — force DiversLung trait on all duplicants (Harmony style issue)
