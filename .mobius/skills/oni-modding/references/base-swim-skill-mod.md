# BaseSwimSkill Mod — Grant Swimming1 to All Duplicants (build 587362)

**Purpose:** Every printed duplicant (initial + print pods) gets Swimming1 automatically.

## Key Discovery

`Db.Initialize` Postfix does NOT trigger on build 587362. The `defaultSkill` reflection approach in the original GrantSwimSkill mod never executed.

**Working approach for build 587362:** Patch `MinionIdentity.OnSpawn` — this fires once per duplicant at spawn time and reliably works.

## Final Working Code

```csharp
using HarmonyLib;
using Klei.AI;
using System;
using System.Reflection;

namespace BaseSwimSkill
{
    public class BaseSwimSkillMod : KMod.UserMod2
    {
        public override void OnLoad(Harmony harmony)
        {
            base.OnLoad(harmony);
        }
    }

    [HarmonyPatch(typeof(MinionIdentity), "OnSpawn")]
    public static class MinionIdentity_OnSpawn_Patch
    {
        public static void Postfix(MinionIdentity __instance)
        {
            try
            {
                var resume = __instance.GetComponent<MinionResume>();
                if (resume == null) return;

                if (!resume.HasMasteredSkill("Swimming1"))
                {
                    resume.MasterSkill("Swimming1");
                }
            }
            catch (Exception e)
            {
                Debug.Log("[BaseSwimSkill] OnSpawn error: " + e.ToString());
            }
        }
    }
}
```

## mod_info.yaml

```yaml
supportedContent: ALL
minimumSupportedBuild: 587362
APIVersion: 2
version: 1.0
title: "基本游泳技能"
description: "所有复制人生成时自动学会游泳1级。"
dlls:
  - BaseSwimSkill.dll
```

## Project Structure

```
mods/Local/BaseSwimSkill/
├── BaseSwimSkill.cs
├── BaseSwimSkill.csproj     # net48 + LangVersion 7.3
├── BaseSwimSkill.dll
└── mod_info.yaml
```

## csproj Notes

TargetFramework must be `net48` not `net471` (ONI's assemblies target .NET 4.8). Reference dlls via HintPath from `C:\Program Files (x86)\Steam\...\Managed\`.

## Debugging Mod Load Failures

If the mod auto-disables:
1. Check Player-prev.log for `TargetMethod() returned an unexpected result: null`
2. This means a `[HarmonyPatch]` + `TargetMethod()` patch returned null at mod load
3. The entire mod DLL gets disabled by ONI — re-enable in Mods menu after fixing the code

## Session History

08:15 — Initial code with `Db.Initialize` Postfix (same approach as GrantSwimSkill)
08:17 — Built, tested — no effect
08:22 — Added `MinionStartingStats` TargetMethod patch — mod crashed on load (TargetMethod returned null)
08:25 — Switched to `MinionIdentity.OnSpawn` — compiled and built successfully
— Awaiting user test result
