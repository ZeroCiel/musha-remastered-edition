# No Water Stress Mod — Block Effects on Duplicants with Specific Traits

## Goal
Prevent negative status effects (WetFeet, SoakingWet) from being applied to duplicants who have the DiversLung trait.

## Approach Comparison

### Approach 1: Effects.AddEffect Prefix — BEST
Directly block the effect before it's applied:
```csharp
[HarmonyPatch(typeof(Effects), "AddEffect")]
public static class BlockWetEffectsPatch
{
    static bool Prefix(Effects __instance, string effect_id)
    {
        if (effect_id != "WetFeet" && effect_id != "SoakingWet") return true;
        // Check minion for DiversLung trait, return false to block
        return true;
    }
}
```
**⚠️ Must use TargetMethod() to handle overload resolution**, since Effects.AddEffect has multiple signatures. Using plain `[HarmonyPatch(typeof(Effects), "AddEffect")]` may match the wrong overload and crash the game.

### Approach 2: IsWearingAirtightSuit Postfix — ELEGANT
Make DiversLung duplicants appear to be wearing an airtight suit:
```csharp
// Manual patch via harmony.Patch() in Game.OnPrefabInit postfix
// Find the IsWearingAirtightSuit getter method
// Add a postfix that sets __result = true for DiversLung duplicants
```
**Requires runtime method resolution** since the property location (MinionIdentity vs MinionModifiers) varies by ONI version.

### Approach 3: Db.Initialize — Remove Stress Modifiers
Keeps the visual effect but removes stress impact:
```csharp
[HarmonyPatch(typeof(Db), "Initialize")]
public static class DbInitPatch
{
    static void Postfix()
    {
        foreach (var effect in Db.Get().effects.resources)
        {
            if (effect.Id.Contains("Wet") || effect.Id.Contains("Soak"))
            {
                for (int i = effect.SelfModifiers.Count - 1; i >= 0; i--)
                {
                    if (effect.SelfModifiers[i].AttributeId == "Stress")
                        effect.SelfModifiers.RemoveAt(i);
                }
            }
        }
    }
}
```

### Approach 4: Coroutine — FAILED
```csharp
// Tried: effects.RemoveEffect("WetFeet") but RemoveEffect(string) doesn't exist in build 587362
// Tried: directly manipulating internal 'effects' list field — list contains EffectHandle structs, removing from list has no visible effect
```

## Key Findings
1. **`Effects.RemoveEffect(string)` does NOT exist in build 587362** — removed effects re-appear every frame
2. **Effect IDs confirmed:** "WetFeet", "SoakingWet"
3. **SensitiveFeet** is the NeedStateMachine that triggers WetFeet — patches to SensitiveFeet states are unreliable because the game checks IsFloorWet every frame
4. **`IsWearingAirtightSuit`** is the property that airtight suits (DrySuit) set to true — patching this getter to return true for DiversLung duplicants would prevent ALL liquid exposure effects
