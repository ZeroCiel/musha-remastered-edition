# U59 Swim Skill ID Discovery (2026-06-24)

**Build:** U59-737790 (minimumSupportedBuild 587362)
**Session goal:** Create a mod that grants Swimming skill to all dupes.

## Key Discovery: Skill ID Changed

In previous ONI versions (pre-U59), the swimming skill ID was `"Swimming1"`. In **U59-737790**, it's **`"Swimming"`** (no trailing "1").

## Discovery Method

Iterate all registered skills and print their IDs:
```csharp
var skills = Db.Get().Skills;
for (int i = 0; i < skills.resources.Count; i++)
{
    var skill = skills.resources[i];
    var idProp = skill.GetType().GetProperty("Id",
        BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
    string id = idProp?.GetValue(skill, null)?.ToString() ?? "";
    Debug.Log($"[Mod] Skill[{i}]: id='{id}'");
}
```

## Results

- `Skill[0..41]` — various skill IDs (Mining1-4, Building1-3, Farming1-3, etc.)
- `Skill[42]: id='Swimming'` — **the swimming skill** (last in the list)

No other skill ID contains "swim" or "游泳".

## Harmony Patch Compatibility on U59-737790

| Target Method | Virtual? | Works? |
|---|---|---|
| `Game.LateUpdate` | No | ✅ |
| `MinionIdentity.OnSpawn` | Yes | ❌ (registers but never fires) |
| `KMonoBehaviour.OnSpawn` | Yes | ❌ (registers but never fires) |
| `MinionResume.OnSpawn` | Yes | ❌ (registers but never fires) |
| `Db.Initialize` | No | ❌ (unclear why) |
| `MinionStartingStats(bool).ctor` | N/A | ❌ (TargetMethod returns null on this build) |

## Working Approach: Game.LateUpdate + FindObjectsOfType

Patches `Game.LateUpdate` (non-virtual, one-shot via static bool) to grant Swimming to all existing dupes on first frame. Does NOT handle newly-printed dupes.

## API Notes

- `MinionResume.HasMasteredSkill(string id)` — takes a string, not a Skill object
- `MinionResume.MasterSkill(string id)` — takes a string, not a Skill object
- Calling `MasterSkill("Swimming1")` (wrong ID) → `Could not find Database.Skill: Swimming1`
- Calling `MasterSkill("Swimming")` (correct ID on U59) → success
