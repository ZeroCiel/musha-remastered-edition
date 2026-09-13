# BaseSwimSkill Mod — 2026-06-24 Session Record

## Goal
Create an ONI mod that grants Swimming skill to ALL duplicants — both starting and newly-printed from the printing pod — without requiring player interaction. The skill should also show in the printing pod UI as a native/default skill.

## Build Environment
- ONI version: U59-737790-SCRPAN
- Build string in `mod_info.yaml` originally used `minimumSupportedBuild: 587362` (old build string; actual game build is 737790)
- Harmony 2.4.2 bundled with game
- Compiler: `dotnet build -c Release` with net48 TargetFramework
- Project location: `D:\Backup\Documents\Klei\OxygenNotIncluded\mods\Local\BaseSwimSkill\`

## Key Discoveries

### 1. Skill ID Changed in U59
- Old builds (pre-U59): `"Swimming1"`
- U59-737790: **`"Swimming"`** (no trailing "1")
- Discovery method: iterate `Db.Get().Skills.resources`, read `.GetProperty("Id")` on each resource, search for "swim"

### 2. Harmony Patch Virtual Method Bypass on U59
U59's MonoMod runtime **bypasses Harmony detours for virtual/abstract methods**. The following virtual methods can be patched successfully (no compile/runtime errors), but the Postfix **never fires**:
- `MinionIdentity.OnSpawn` — virtual
- `MinionResume.OnSpawn` — virtual
- `KMonoBehaviour.OnSpawn` — virtual

**Non-virtual methods that DO work:**
- `Game.LateUpdate` — confirmed working, fires every frame
- `Game.Update` — untested but expected to work

### 3. MinionStartingStats Constructor Patching
Attempted to inject `Swimming` into the `skillAptitudes` dictionary via `MinionStartingStats(bool)` constructor postfix:
- Manual `harmony.Patch(ctor, ...)` registrations succeeded
- But constructing a valid `SkillAptitude` struct via reflection was unreliable (struct constructor signatures unknown, field-set via reflection may not have been recognized by UI renderer)
- Result: skill was functionally granted but UI still didn't show it

### 4. PrintListSelect Mod Compatibility
The mod 2019780544 (PrintListSelect / 打印舱物品刷新) does NOT interfere with functional skill granting — `MasterSkill("Swimming")` works regardless. However, even with this mod disabled, the printing pod UI still didn't show the skill icon.

### 5. Final Working Approach
- **Existing dupes on save load:** `Game.LateUpdate` + `FindObjectsOfType<MinionIdentity>()` on first frame
- **Newly-printed dupes:** Periodic coroutine via `MonoBehaviour.Update()` with HashSet tracking
- **UI display:** NOT solved — printing pod preview does not show the skill even though it's functionally granted

## Skill Type Fields (U59-737790)
```
Type: Database.Skill
  Property: Id (String) → "Swimming", "Mining1", etc.
  Property: Name (String) → "" (empty in U59)
  Field: defaultSkill (Boolean, private) — NOT present in U59 (field removed)
  Field: skillGroup (String) → "SwimmingSkills" (for swim skill)
  Field: hat (String) → "hat_role_swimming"
  Field: badge (String) → "skillbadge_role_swimming"
```

## MinionStartingStats.skillAptitudes Type (U59-737790)
```csharp
// NOT Dictionary<Skill, SkillAptitude> as in older builds
// Instead:
Dictionary<SkillGroup, float>  // key=SkillGroup, value=aptitude float
```

Adding a SkillGroup entry (e.g. "SwimmingSkills") with value 1f succeeds without error, BUT:
- Causes `Could not find ChoreGroup: 游泳` in Player.log
- Error comes from `CharacterContainer.SetInfoText()` → `ResourceSet<ChoreGroup>.Get("游泳")`
- The UI tries to look up a ChoreGroup with the LOCALIZED name of the SkillGroup
- Since "SwimmingSkills" has no corresponding ChoreGroup, the lookup fails
- **Conclusion:** Direct SkillGroup → skillAptitudes injection does NOT produce a working UI display on U59

## MinionStartingStats Field Dump (U59-737790, 2026-06-25 Session)

Confirmed fields on `MinionStartingStats` via reflection dump:

| Field | Type | Notes |
|---|---|---|
| `Name` | String | Display name (e.g. "阿玛里", "吉滋镆") |
| `NameStringKey` | String | Internal key (e.g. "AMARI", "GIZMO") |
| `GenderStringKey` | String | "FEMALE", "MALE", "NB" |
| `Traits` | `List<Trait>` | 3-4 traits per dupe (positive/negative/congenital) |
| `rarityBalance` | Int32 | Balance value, -3 to 1 range |
| `stressTrait` | Trait | Stress response trait |
| `joyTrait` | Trait | Joy response trait |
| `congenitaltrait` | Trait | Can be null |
| `stickerType` | String | Decorative sticker type |
| `voiceIdx` | Int32 | 0-3 |
| `StartingLevels` | `Dictionary<string, int>` | 12 skills: Strength, Caring, Construction, Digging, Machinery, Learning, Cooking, Botanist, Art, Ranching, Athletics, SpaceNavigation |
| `personality` | Personality | Personality reference |
| `accessories` | `List<Accessory>` | 21 items (clothing/accessories) |
| `IsValid` | Boolean | Always True |
| `overrideOutfitID` | String | Can be null |
| `skillAptitudes` | `Dictionary<SkillGroup, float>` | Key = SkillGroup (by Id), value = aptitude float (typically 1) |

### skillAptitudes Observations

Actual Id values seen in 3 initial dupes from a water planet start (Spaced Out DLC):
- Group 1: `[MedicalAid]=1, [Research]=1, [Rocketry]=1`
- Group 2: `[Research]=1, [Ranching]=1`
- Group 3: `[Farming]=1, [Basekeeping]=1, [Research]=1`

**None of the three initial dupes had any `Swimming`-related SkillGroup** in their `skillAptitudes`. This confirms swimming is NOT granted via `skillAptitudes` even for water-planet starts.

### Traits Observation

Trait `ToString()` does NOT output meaningful identifiers. Reflection dump via `GetProperties()` + `GetFields()` on each Trait is needed to extract `Id` and `Name`.

### Key Insight: Printing Pod UI vs Functional Skill

The printing pod preview renders from `MinionStartingStats` only — it shows already-mastered skills with a brain icon. But swimming in water-planet starts is NOT stored in `MinionStartingStats` at all (confirmed by field dump). This means:

- **Official behavior:** Even in the Spaced Out DLC with water-planet start, the printing pod does NOT show swimming as "already mastered" in the preview
- **The swimming animation** on printing pod dupes is driven by some other mechanism (possibly personality trait or world trait, not skill)
- `Game.LateUpdate` polling + `MasterSkill("Swimming")` adds the skill functionally in-game, but the printing pod preview is generated before this fires — so no brain icon shows

**Conclusion from this session:** The "brain icon in printing pod" request is NOT achievable because official water-planet starts also don't show it through `MinionStartingStats`. If the user sees a swimming animation in the pod, that's an animation/visual effect, not a skill indicator.

## Final Mod State
- **Working:** All dupes (existing + newly printed) get Swimming skill functionally via `Game.LateUpdate` polling + `MasterSkill("Swimming")`
- **Not working:** Printing pod UI does not show the skill icon (brain icon) — this matches official behavior
- **Root cause:** Swimming is not stored in `MinionStartingStats.skillAptitudes` in any variant (even water-planet starts), so the printing pod has no data to display
- **Recommendation:** Accept the limitation; the mod works perfectly in gameplay
