# BaseSwimSkill Mod — Full Session Record (2026-06-24)

## Goal

Create an ONI mod that grants all newly-printed duplicants the Swimming skill automatically, with printing pod UI displaying the skill icon.

## Result

**Skill works functionally but printing pod UI does NOT display the skill icon. All approaches to fix UI display exhausted.**

## Session Timeline

### Phase 1: `Db.Initialize` + `defaultSkill` field

- Used GrantSwimSkill pattern: iterate `Db.Get().Skills.resources`, find skill by Id=="Swimming1", reflect `defaultSkill=true`
- **Failed:** Harmony patch on `Db.Initialize` did NOT trigger on U59-737790
- Skill Id in U59 is `"Swimming"` (not `"Swimming1"`) — discovered via reflection dump

### Phase 2: `MinionIdentity.OnSpawn` manual harmony.Patch

- Called `harmony.Patch(minionIdentityOnSpawn, postfix: ...)` in OnLoad
- **Failed:** Log showed `Patched MinionIdentity.OnSpawn!` but Postfix never fired
- Root cause: U59 MonoMod bypasses Harmony for virtual methods

### Phase 3: `KMonoBehaviour.OnSpawn` manual harmony.Patch

- Same pattern, parent class
- **Failed:** Same issue — virtual method bypass

### Phase 4: `Game.LateUpdate` one-shot

- Patched `Game.LateUpdate` with one-shot flag
- Used `FindObjectsOfType<MinionIdentity>()` to grant Swimming
- **Worked for existing dupes at game start** — log confirmed "Granted Swimming to X"
- **Did NOT handle newly-printed dupes** — LateUpdate one-shot only ran once

### Phase 5: `MinionStartingStats` constructor hook (two attempts)

- First attempt: `typeof(MinionStartingStats).GetConstructor(new[] { typeof(bool) })` via `TargetMethod()`
  - **Failed:** TargetMethod returned null at mod load → mod auto-disabled
- Second attempt: `GetConstructors()` loop in OnLoad, manual harmony.Patch
  - **Failed mod loading** — runtime error caused mod to be disabled

### Phase 6: `MinionStartingStats` ctor + detailed dump

- Dumped full contents of `skillAptitudes` field — discovered it's `Dictionary<SkillGroup, float>` NOT `Dictionary<Skill, SkillAptitude>`
- Found swim skill group: `swimSkill.GetField("skillGroup")` = `"SwimmingSkills"`
- Found `Db.Get().SkillGroups` matching Id
- Injected `swimGroup` with value `1f` via `apts.Add(swimGroup, 1f)`
- **Result:** Soft error `Could not find ChoreGroup: 游泳` from `CharacterContainer.SetInfoText` — UI tries to display SkillGroup by looking up its ChoreGroup, but Swimming has none registered

### Phase 7: Continuous polling via Game.LateUpdate

- Changed one-shot flag to `HashSet<int>` by InstanceID for continuous monitoring
- Every LateUpdate frame: Find all MinionIdentities, skip already-granted, grant Swimming to new ones
- **Functional success:** All new printing pod dupes get Swimming skill automatically
- **UI icon still not displayed** (as with all prior approaches)

### Phase 8: Custom Trait attempt

- Tried adding a custom Trait with `grantedSkills` including Swimming
- **Failed:** `Trait` constructor signature differs in U59 (7-param overload doesn't exist), `Db.Traits` is not accessible as public property

## Key Technical Discoveries

### U59-737790 Specifics
- Skill Id: `"Swimming"` (not `"Swimming1"`)
- Skill class has NO `defaultSkill` field
- `Skill` class fields: `description`, `requiredDlcIds`, `forbiddenDlcIds`, `skillGroup` (=`"SwimmingSkills"`), `hat`, `badge`, `tier`, `deprecated`, `perks`, `priorSkills`, `requiredDuplicantModel`, `Name`, `Id`, `IdHash`, `Disabled`
- `MinionStartingStats.skillAptitudes` type: `Dictionary<SkillGroup, float>` (NOT `Dictionary<Skill, SkillAptitude>`)
- The `SkillGroup` Id for swimming is `"SwimmingSkills"`
- `CharacterContainer.SetInfoText` triggers `ChoreGroup` lookup based on SkillGroup — no corresponding ChoreGroup for Swimming

### Harmony U59 Compatibility
- ✅ `Game.LateUpdate` — works (not virtual)
- ❌ `MinionIdentity.OnSpawn` — virtual, bypassed
- ❌ `KMonoBehaviour.OnSpawn` — virtual, bypassed
- ❌ `MinionResume.OnSpawn` — virtual, bypassed
- ❌ `Db.Initialize` — doesn't trigger
- ❌ `MinionStartingStats` constructor via TargetMethod — returns null
- ❌ `Game.OnPrefabInit` — doesn't trigger

### Mod File Locations
- Source: `D:\Backup\Documents\Klei\OxygenNotIncluded\mods\local\BaseSwimSkill\BaseSwimSkill.cs`
- Project: `D:\Backup\Documents\Klei\OxygenNotIncluded\mods\local\BaseSwimSkill\BaseSwimSkill.csproj`
- Output DLL: `...\bin\Release\BaseSwimSkill.dll`
- Runtime DLL (copied): `...\BaseSwimSkill.dll`
- Config: `...\mod_info.yaml` (minimumSupportedBuild: 587362, APIVersion: 2)
- Player.log: `C:\Users\Administrator\AppData\LocalLow\Klei\Oxygen Not Included\Player.log`

### Final Working Code

```csharp
using HarmonyLib;
using Klei.AI;
using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

namespace BaseSwimSkill
{
    public class BaseSwimSkillMod : KMod.UserMod2
    {
        private static HashSet<int> _grantedMinions = new HashSet<int>();

        public override void OnLoad(Harmony harmony)
        {
            base.OnLoad(harmony);

            try
            {
                var lateUpdate = typeof(Game).GetMethod("LateUpdate",
                    BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
                var postfix = typeof(BaseSwimSkillMod).GetMethod("OnLateUpdate",
                    BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
                harmony.Patch(lateUpdate, postfix: new HarmonyMethod(postfix));
            }
            catch (Exception e) { }
        }

        public static void OnLateUpdate(Game __instance)
        {
            var minions = UnityEngine.Object.FindObjectsOfType<MinionIdentity>();
            foreach (var minion in minions)
            {
                int id = minion.GetInstanceID();
                if (_grantedMinions.Contains(id)) continue;

                var resume = minion.GetComponent<MinionResume>();
                if (resume == null) continue;

                if (resume.HasMasteredSkill("Swimming"))
                {
                    _grantedMinions.Add(id);
                    continue;
                }

                try
                {
                    resume.MasterSkill("Swimming");
                    _grantedMinions.Add(id);
                }
                catch { }
            }
        }
    }
}
```

### Related Workshop Mod
- PrintListSelect (2019780544) — printing pod UI replacement. Does NOT interfere with skill granting but also does not help with UI display.
