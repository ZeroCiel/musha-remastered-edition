---
name: oni-modding
title: "Oxygen Not Included Mod Troubleshooting & Analysis"
description: "Diagnose and fix Oxygen Not Included mod issues — workshop mod identification, DLL string extraction, mod conflict debugging, worldgen troubleshooting, crash diagnostics, Harmony mod development. Covers U59-737790."
triggers:
  - "oni mod"
  - "oxygen not included mod crash"
  - "steam workshop mod conflict"
  - "oni .dll string read"
  - "compile oni mod"
  - "oni mod build failed"
  - "incompatible dlc configuration"
  - "不兼容的DLC配置"
  - "harmony patch not working"
  - "oni harmony oni build 587362"
  - "oni mod disabled automatically"
  - "Assembly-CSharp.dll search strings"
  - "power bank discharger mod oni"
  - "large discharger 4000w"
  - "battery smart battery capacity mod"
  - "oni mod upload workshop"
  - "oni prefab id check building type"
  - "algae oxygen"
  - "绿藻产氧"
  - "藻类氧气"
  - "DissolvingAlgae"
  - "lamprey algae"
  - "灯喙鱼"
  - "GeneratorWattageRating vs EnergyConsumptionWhenActive"
  - "oni mod folder path case windows"
  - "oni mod yaml title staticID workshop"
  - "floating point string search in dll"
  - "swimming skill mod"
  - "base swim skill"
  - "grant swimming to all dupes"
  - "printing pod UI brain icon"
  - "MinionStartingStats Traits GrantSkill"
  - "coral min temp"
  - "氧齿珊瑚"
  - "浮游珊瑚"
  - "灯泡花最低温度"
  - "BulbPlantMinTemp"
  - "BulbPlantConfig"
  - "plant temperature mod"
  - "CreatePrefab postfix"
  - "natural backwall"
  - "backwall element"
  - "Grid.BackwallElement"
  - "Components.Buildings"
  - "algae backwall oxygen"
  - "SimMessages.SetBackwallData"
  - "no pressure farm tile"
  - "宽液培砖透气"
  - "tile gas permeable"
  - "SimCellOccupier"
  - "custom building U59"
  - "register building U59"
  - "gas permeable farm tile"
  - "透气种植砖"
  - "new IBuildingConfig U59"
  - "flydo"
  - "飞寻机"
  - "飞鱼"
  - "FlydoAerialMining"
  - "FlydoMinerMonitor"
  - "flydo build"
  - "flydo construct"
  - "DLL string extraction"
  - "dll reverse engineer"
  - "port workshop mod to local"
  - "mod_info.yaml missing"
  - "BuildLocationRule Anywhere"
  - "OccupyArea method names U59"
---

# Oxygen Not Included Mod Development & Debugging (U59-737790)

> This skill documents ONI U59-737790 quirks on Windows.
> Harmony 2.4.2 bundled; some patches work, some silently fail.

> **Related skill:** `dst-modding` — sibling Klei game modding guide (Don't Starve Together, Lua modmain/Spriter). Different toolchain (script mods vs compiled DLLs); load it for Lua/Spriter modding problems.

## User Preferences (ONI Modding)

- **Extreme brevity** -- give conclusions first, skip analysis/explanation.
- **Iteration pattern** -- fix, compile, deploy, "进游戏试试". Three failed attempts -> "不行，换方案".
- **Mod file correctness** -- ALWAYS create BOTH `mod.yaml` AND `mod_info.yaml` for EVERY new local mod. Missing either -> game rejects as "不兼容的DLC配置" / incompatible. `mod_info.yaml` is NON-NEGOTIABLE. User explicitly said "modinfo 以后也要写 不要忘记否则会变成不兼容". This is the #1 recurring issue.
- **Porting workshop mods to local** -- Extract DLL from `*_legacy.bin` (ZIP), create fresh `mod.yaml` + `mod_info.yaml` with `minimumSupportedBuild: 737790` and `supportedContent: ALL`. The original workshop `mod_info.yaml` almost certainly has outdated `minimumSupportedBuild`.
- **Code style** -- use `[HarmonyPatch]` attribute + Postfix pattern. Clean structure.
- **Focus** -- one mod at a time, finish it, deploy DLL, tell user to test. Don't explain what you're about to do.
- **Disease/contamination mods** -- user prefers manual approach over modding: empty storage first, then deconstruct. Don't write disease-clearing mods unless specifically asked.
- **Mod limitations** -- when 3+ approaches fail, say "无解" directly with a clear reason instead of suggesting more iterations. User appreciates knowing when a mod is architecturally impossible vs just difficult.

## Path & Build System Caveats (Windows)

- **Project directory vs game directory:** ONI reads mods from `D:\Backup\Documents\Klei\OxygenNotIncluded\mods\Local\` (capital L). `dotnet build` outputs to `mods/local\bin\Release\` (lowercase l). After every build, MANUALLY copy `bin\Release\<ModName>.dll` UP to the root of the `mods/Local/<ModName>/` folder.
- **Two mod folders with same name (capitalization difference):** Windows treats `Local` and `local` the same visually but ONI might find one and not the other. Standardize on `mods/Local/` (capital L).
- **Primary build command:** `cd /d/<project-path> && dotnet build -c Release`
- **CRITICAL: TargetFramework must be `net48` NOT `net471`.** ONI's bundled assemblies target .NET 4.8.

## Harmony Patch Behavior on U59-737790

### KNOWN-WORKING patches
- `*Config.CreateBuildingDef` -- ALWAYS works
- `*Config.CreatePrefab` -- works (non-virtual)
- `Game.LateUpdate` -- works (use one-shot flag for init)
- `Game.Update` -- works
- `BuildingComplete_OnSpawn` -- works (underscore naming, not `OnSpawn`)
- `BuildingComplete_OnInit` -- works

### KNOWN-BROKEN patches (virtual methods bypassed by MonoMod)
- `Db.Initialize` -- does NOT trigger
- `MinionIdentity.OnSpawn` -- virtual
- `KMonoBehaviour.OnSpawn` -- virtual base
- `Game.OnPrefabInit` -- virtual
- `ElectrobankDischarger.OnSpawn/OnPrefabInit` -- virtual
- `Building.ForcePermanentCheck` -- DOES NOT EXIST
- `BuildingComplete.OnSpawn` -- name is `BuildingComplete_OnSpawn`, NOT `OnSpawn`
- `OccupyArea.IsValidTileLocation` -- DOES NOT EXIST

### Key: Virtual methods do NOT work with Harmony on U59 (for game classes)

Harmony cannot patch virtual methods on game-built-in classes (MonoMod bypass). Use one of these workarounds:
- **Game.LateUpdate + one-shot flag** — for global/periodic logic
- **Custom KMonoBehaviour component** (attached via CreatePrefab postfix) — for per-building cleanup/interception
- **Underscore-named concrete methods** — e.g. `BuildingComplete_OnSpawn` instead of `BuildingComplete.OnSpawn`

### U59 BuildingComplete method names (from DLL string dump)
- BuildingComplete_OnSpawn
- BuildingComplete_OnInit

### Known Prefab IDs for BuildingDef checks\n- `"HydroponicFarm"` — hydroponic farm tile (NOT `"HydroponicFarmTile"` or `"WideFarmTile"`)\n- `"WideFarmTile"` — standard farm tile (base class for HydroponicFarm)

### OccupyArea methods in U59 — LIMITED SET
U59-737790's `OccupyArea` class has very few publicly-visible method names in the DLL metadata:
- `OccupyArea` (class itself)
- `OccupyAreaContents` (inner class)
- `CanOccupyArea`
- `CheckIsOccupying`
- `RefreshCellOccupy`

**CONFIRMED NON-EXISTENT methods (attempting to patch these crashes the DLL with Harmony.ArgumentException):**
- ❌ `OccupyArea.IsValidTileLocation` — DOES NOT EXIST
- ❌ `OccupyArea.SetOccupyGridSpace` — DOES NOT EXIST (contradicts earlier incorrect notes)
- ❌ `Building.ForcePermanentCheck` — DOES NOT EXIST

Only `CanOccupyArea` and `CheckIsOccupying` are viable OccupyArea patch targets.

### Manual Harmony Patch Registration
When the target method might not exist, use manual registration in `OnLoad` instead of `[HarmonyPatch]`:
```csharp
public override void OnLoad(Harmony harmony)
{
    base.OnLoad(harmony);
    var m = typeof(Game).GetMethod("LateUpdate", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
    if (m != null)
        harmony.Patch(m, postfix: new HarmonyMethod(typeof(MyPatch), nameof(MyPatch.Postfix)));
}
```

## PrimaryElement.DiseaseCount — Read-only, use reflection

`PrimaryElement.DiseaseCount` is a **read-only property** in the C# API (`error CS0200: cannot assign -- it is read-only`). The internal setter exists in the DLL (`set_diseaseCount`) but is not publicly exposed.

To write it, use reflection:
```csharp
private static PropertyInfo _diseaseCountProp = typeof(PrimaryElement)
    .GetProperty("DiseaseCount", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);

public static void ClearDisease(PrimaryElement elem)
{
    if (elem == null || _diseaseCountProp == null) return;
    int current = (int)_diseaseCountProp.GetValue(elem);
    if (current > 0) _diseaseCountProp.SetValue(elem, 0);
}
```

This is useful for mods that clear disease before deconstruction (e.g., preventing hydroponic farm tile disease release into water).

## PrimaryElement methods in U59 DLL:
- `get_diseaseCount` / `set_diseaseCount` — both exist internally
- `AddDisease` — adds disease (usable)
- `ModifyDiseaseCount` — called on modification events

`Components.Buildings` does not exist in U59-737790.

**Alternatives (confirmed working):**
- `Components.BuildingCompletes.Items` -- works for scanning BuildingComplete objects
- `Components.Pickupables.Items` -- works for scanning ground items
- `Components.Storages` -- also removed. Use `UnityEngine.Object.FindObjectsOfType<Storage>()` as fallback

## Backwall Element Detection (U59 -- No Public Read API)

`Grid.BackwallElement` does not exist in U59. Background wall elements live in the native sim layer and are not exposed through any public C# API.

**Write-only API (confirmed signature U59):**
- `SimMessages.SetBackwallData(int cell, ushort elemIdx, float mass, float temperature)`
- elemIdx is `ushort` NOT `int`. Harmony parameter matching is type-strict.
- Manual Harmony patch in OnLoad, NOT `[HarmonyPatch]` attribute.

**Read API:** None. Not via `Grid.Element`, `Grid.ElementIdx`, `Grid.BackwallElement`, or `BackwallManager`.

**Workaround:** Hook `SimMessages.SetBackwallData` via Harmony Postfix to intercept writes and maintain a local `HashSet<int>` cache.

## Making Tiles Gas-Permeable on U59

**2026-06-27 Final Verdict: WideFarmTile CANNOT be made gas-permeable in U59.**

After exhausting all approaches:
1. `isSolidTile=false` (confirmed by field reflection)
2. `SimCellOccupier` destroyed
3. `OccupyArea` destroyed -- causes crash (`DecorProvider requires OccupyArea`)
4. `PressureVulnerable` destroyed

**Root cause:** sim-level cell solidity persists even after `SimCellOccupier` is removed. The cell was marked solid when built and destroying the C# component does NOT retroactively clear the sim-level solid flag.

**ONLY viable path:** Register a new building (not patch existing WideFarmTile). Define it as non-solid from `CreateBuildingDef`.

## Custom Building Registration in U59

### U59 API removal checklist
- `TUNING.BUILDINGS.CONSTRUCTION_MASS_KG.TIER3` -- works
- `TUNING.BUILDINGS.DECOR.NONE` -- works
- `NOISE_POLLUTION.NONE` -- works
- `FarmTileConfig.SetupFarmTile(go)` -- does NOT exist
- `GameTags.FarmTile` -- does NOT exist. Use `new Tag("WideFarmTile")`
- `DlcManager.AVAILABLE_ALL_VERSIONS` -- obsolete

### ElectrobankCharger: Cannot use FindObjectsOfType<>

ElectrobankCharger is a plain C# class (StateMachine definition), NOT UnityEngine.Object. Scan all GameObjects and check `GetComponent(typeof(ElectrobankCharger))`.

### Charger Efficiency Transpiler Fallback
When a mod's Transpiler breaks in U59 (different IL), replace with Game.LateUpdate + per-frame battery charge boost via reflection on `Battery.charge` field.

## Changing Building Placement Rules (BuildLocationRule)

Target: `*Config.CreateBuildingDef` Postfix
```csharp
public static void Postfix(BuildingDef __result)
{
    var f = typeof(BuildingDef).GetField("BuildLocationRule",
        BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
    if (f != null) f.SetValue(__result, BuildLocationRule.Anywhere);
}
```

### Post-Build Ground Check -- Game.LateUpdate OccupyArea Removal

`BuildLocationRule.Anywhere` controls blueprint placement but after completion,
OccupyArea triggers "没有地面砖块" popup (cosmetic, but user finds it annoying).

**CONFIRMED NON-EXISTENT in U59 (patching these crashes the mod DLL with Harmony.ArgumentException):**
- `OccupyArea.IsValidTileLocation` -- DOES NOT EXIST
- `Building.ForcePermanentCheck` -- DOES NOT EXIST
- `OccupyArea.SetOccupyGridSpace` -- DOES NOT EXIST in U59 metadata
- `OccupyArea.RefreshCellOccupy` -- DOES NOT EXIST in U59 metadata

**Crash signature:**
```
HarmonyLib.HarmonyException: Patching exception in method null
  ---> System.ArgumentException: Undefined target method for patch method ...
```
This kills the entire mod DLL on load. ONI auto-disables it. Must manually re-enable.

**Strategy to remove the popup:**
Patch `Game.LateUpdate` + check every 60 frames. Scan `BuildingComplete` objects by prefab ID and destroy `OccupyArea`:
```csharp
[HarmonyPatch(typeof(Game), "LateUpdate")]
public static void OnLateUpdate()
{
    if (Game.Instance == null) return;
    if (Time.frameCount % 60 != 0) return;
    var buildings = Object.FindObjectsOfType<BuildingComplete>();
    foreach (var b in buildings)
    {
        if (b.Def.PrefabID != "SMALLELECTROBANKDISCHARGER") continue;
        var occ = b.GetComponent<OccupyArea>();
        if (occ != null) Object.DestroyImmediate(occ);
    }
}
```
**WARNING:** Do NOT use `FindObjectsOfType<GameObject>()` in LateUpdate -- it exhausts memory (causes `OutOfMemoryException` in NavGrid constructor). Always filter to the specific type.

IMPORTANT: Test that deleting OccupyArea doesn't crash (DecorProvider dependency). For ElectrobankDischarger it's safe (no DecorProvider).

## Required Mod Manifest Files

**CRITICAL: ALWAYS create BOTH files for every new local mod. The user has corrected us on this multiple times. This is the #1 recurring mistake. Do not skip it.**

### mod.yaml
```yaml
title: "Mod Name"
description: "What it does."
staticID: SomeUniqueID
supportedContent:
  - ALL
```

### mod_info.yaml (MANDATORY - game rejects mods without it as incompatible)
```yaml
title: "Mod Name"
description: "What it does."
staticID: SomeUniqueID
minimumSupportedBuild: 737790
version: 1
APIVersion: 2
```

Both files must be at the mod root directory alongside the DLL.
mod.yaml uses supportedContent: with a list (- ALL), not a string.
mod_info.yaml uses APIVersion: 2 and minimumSupportedBuild: 737790 for U59.
Missing either one -> game auto-disables the mod with "incompatible DLC configuration".

## Flydo Aerial Mining -- Hotfix Details

### Workshop Mod Info
- Workshop ID: 3714990201
- staticID: FlydoAerialMining
- Version: 1.9.0
- DLL classes: FlydoMinerMonitor, FlydoMinerConfig, FlydoAerialMiningMod, FlydoGood, Diggable_GetAnim_Patch, Diggable_OnWorkTick_FlydoLaser_Patch

**BulbPlantConfig (灯泡花) — Temperature Modding (U59 TRICKY)**

**2026-07-02 definitive finding: TemperatureVulnerable field changes have NO effect on BulbPlant wilting.**

**2026-07-05 update: WiltCondition has [MyCmpReq] constraint — cannot delete**

DestroyImmediate(WiltCondition) on BulbPlant causes PrickleGrass to crash:
```
UnityEngine.GameObject 'BulbPlant' requires a component of type WiltCondition as requested by PrickleGrass!
  at Util.RequireComponent[T] (Component cmp)
  at MyCmp.RequireComponent[T] (KMonoBehaviour c, Boolean isStart)
  at KMonoBehaviour.Start()
```

**灯泡花组件结构（U59-737790）：**\n- PrefabTag: `BulbPlant`\n- 使用 `PrickleGrass` 状态机（`PrickleGrass+States|WiltingState`）控制枯萎\n- 有 `HeatBulb` 组件（非MonoBehaviour子类，反射字段极少暴露）\n- 有 `TemperatureVulnerable`（可改字段但无效果）\n- 有 `WiltCondition`（PrickleGrass 的 `[MyCmpReq]` 必需组件，不可删除）\n- 无 `PlantablePlot`\n- 初始温度值：lethalLow=288K (15°C), warnLow=293.15K (20°C)\n- 实际温度下限 **~40°C** 左右才不萎（原版标称15°C lethal 完全无效）\n\n**已证明无效的方法（所有四层保护都失败，2026-07-05 最终结论）：**\n1. ❌ `CreatePrefab` Postfix 改 TemperatureVulnerable 字段 → 值改了但Still wilts\n2. ❌ `PrickleGrass.OnSpawn` Postfix 强制复位 → 同结果\n3. ❌ `Game.LateUpdate` 每2秒强制复位 TemperatureVulnerable → 同结果\n4. ❌ `DestroyImmediate(WiltCondition)` → PrickleGrass 报错崩（`[MyCmpReq]` 约束）\n5. ❌ `Game.LateUpdate` 反射强制 `WiltCondition.isWilting = false` → 仍然枯萎\n6. ❌ `Game.LateUpdate` 反射强制 TemperatureVulnerable + isWilting 双保险 → 仍然枯萎\n7. ✅ 值确实被改成285.15K（日志确认多次），但PrickleGrass WiltingState无视TemperatureVulnerable\n\n**PrickleGrass暴露的可Patch方法（全是非virtual，可用）：**\n- `DestroySelf`\n- `OnPrefabInit`\n- `OnSpawn`\n- **无** `GetWiltCondition` 方法\n\n**2026-07-05 最终结论：mod层面无法让灯泡花无视低温枯萎。**\n\nPrickleGrass 状态机直接读 `PrimaryElement.Temperature` 做枯萎判断，完全绕过 `TemperatureVulnerable`、`WiltCondition.isWilting` 和所有常规 wilting 控制字段。PrickleGrass 的状态机方法在U59上全是 virtual 的，Harmony 无法 patch。\n\n**唯一可能有效的暴力方案：** 每帧强制 BulbPlant 的 `PrimaryElement.Temperature ≥ 目标值`（如285.15K）。代价是灯泡花在冷环境会主动发热。\n\n**对比珊瑚（Coral）：** 珊瑚用标准植物组件（`TemperatureVulnerable` + `Growing`），改 `internalTemperatureLethal_Low` 直接生效。灯泡花特殊在复用了 PrickleGrass 的状态机，这是 Frosty Planet DLC 的设计——灯泡花就是设计成需要高温环境的。\n\n**参考文件：** `references/bulb-plant-min-temp-mod-20260629.md`（验证记录）和 `references/bulb-plant-min-temp-session-20260702.md`（详细session）

### CRITICAL: FindObjectsOfType<GameObject>() OOM Pitfall

**NEVER use `FindObjectsOfType<GameObject>()` in a per-frame patch** (Game.LateUpdate, Game.Update, etc.).

This method allocates a NEW array of ALL GameObjects in the scene **every call**. In a typical mid-game ONI save with ~10,000+ GameObjects, each call allocates ~80-120KB. At 60 FPS that's 5-7 MB/s of GC pressure. This eventually starves the NavGrid constructor (and other array allocations) causing:

```
System.OutOfMemoryException: Out of memory
  at (wrapper managed-to-native) System.Object.__icall_wrapper_ves_icall_array_new_specific
  at NavGrid..ctor_Patch1(...)
  at GameNavGrids.CreateFlyerNavigation(...)
```

**Always filter to the specific type:**
- ✅ `FindObjectsOfType<BuildingComplete>()` — safe, typically < 500
- ✅ `FindObjectsOfType<Diggable>()` — safe
- ✅ `FindObjectsOfType<Battery>()` — safe
- ❌ `FindObjectsOfType<GameObject>()` — UNSAFE in any loop
- ❌ Looping over `FindObjectsOfType<GameObject>()` inside another loop — catastrophic

The OOM manifests in an unrelated system (NavGrid), making it extremely misleading to diagnose.

### Known FlydoMinerMonitor Methods
- UpdateWorkTarget() -- scans for dig targets
- FindBestMineableCell() -- returns nearest diggable cell
- IsDiggable(GameObject) -- checks if target can be mined
- StartDigChore() -- creates WorkChore<Diggable>
- RefreshLaser() -- dig laser animation (OOM culprit)
- targetCell field

### Hotfix Pitfalls
- DO NOT throttle UpdateWorkTarget and RefreshLaser with a shared dictionary
- Only throttle RefreshLaser (100ms). Leave UpdateWorkTarget and FindBestMineableCell unpatched.
- FindType must scan ALL types, not just asm.GetType(name), because workshop mod DLLs have no namespace.
- If Player.log shows "Loaded!" but no "Patched" messages, FindType failed. Add diagnostic logging.
- Keep retrying every 2s for up to 30s.
- When the workshop mod is auto-disabled due to old minimumSupportedBuild, port to mods/Local/.
- **Laser ON/OFF cycling is very fast** -- the original mod cycles Laser ON->OFF every 0.3-0.5s during normal operation. Strong throttling (100ms) is safe; don't go above 500ms or the laser state machine may get confused.
- **The hotfix MUST NOT replace the mod's own logic** -- only throttle the render/crash-causing part. The original UpdateWorkTarget and FindBestMineableCell already work correctly when unthrottled.
- **NEVER** use `FindObjectsOfType<GameObject>()` in a Game.LateUpdate patch. This allocates enormous arrays every frame and causes OutOfMemoryException in unrelated systems (NavGrid constructor, etc.). Always filter to the specific component type.
- **DO NOT** force-call `UpdateWorkTarget` or `FindBestMineableCell` via reflection from LateUpdate. This can cause the mod's state machine to desync. The mod's own Update loop handles this correctly when not throttled.

### `FindBestMineableCell` Postfix Fallback
When the original method returns `-1` (no target found), a Postfix can scan all `Diggable` objects and return the nearest one. See `references/flydo-findbestmineablecell-fallback-20260628.md`.

### Architecture Limit: BUILD IS NOT POSSIBLE via Hotfix
Adding build capability to Flydo cannot be done through a Harmony hotfix. The mod's architecture is dig-only:
- State machine fields (_currentDiggable, _digLaserCtrl, _digLaserAnim) have no build equivalents
- Custom laser animation tied to digging
- WorkChore<Diggable> only, not WorkChore<Constructable>
- Navigation: dig positioning and build positioning are different

To add building, write a complete standalone mod (fork FlydoMinerMonitor + add build states).

## mod_info.yaml vs mod.yaml — Both Required for Different Purposes

ONI supports TWO metadata files for local mods. **You need BOTH in every mod folder.** Missing one → game auto-disables the mod.

### mod.yaml (display metadata, minimal)
```yaml
title: "Mod Name"
description: "What it does."
staticID: SomeUniqueID
supportedContent:
  - ALL
```

**CRITICAL WARNINGS:**
- **Do NOT add `supportedContent` as a list in mod.yaml** — the ONI YAML parser may choke on array-format fields and log `Recoverable parse error`. When this happens the game marks the mod as "expired/outdated". If you see "expired" despite having correct fields, remove list/array fields from mod.yaml.
- **mod_info.yaml must be YAML, NOT JSON.** Files like `{ "title": "...", "staticID": "..." }` are valid JSON but invalid YAML for ONI's loader. Use proper key-value format with colons.

### mod_info.yaml (version metadata, MANDATORY)
```yaml
minimumSupportedBuild: 737790
version: 1.0.0
APIVersion: 2
```

**Fields that prevent "expired/outdated" flag in-game:**
- `version` (string like `1.0.0`)
- `staticID` (unique string)
- `supportedContent` with at least `VANILLA_ID`
- `title` and `description`

**⚠️ Do NOT put both `mod_info.yaml` AND `mod.yaml` with conflicting fields.** Having both can cause the game to show the mod as "expired/outdated". Use mod.yaml for display metadata and mod_info.yaml for version metadata.

**⚠️ "Expired/outdated" troubleshooting checklist:**
1. Player.log shows `Recoverable parse error` in mod.yaml → remove list/array fields
2. Player.log shows no error but still outdated → check mod_info.yaml format is YAML, not JSON
3. Still outdated → check if both files exist with conflicting fields (delete one's duplicate fields)
4. Reference: FlydoMiningHotfix has only 3 fields in mod.yaml + 3 fields in mod_info.yaml

## Runtime Data Structure Discovery (Dumping ONI Objects)

When exploring ONI's obfuscated or version-dependent classes, use a Harmony postfix to dump all fields to Player.log:

```csharp
public override void OnLoad(Harmony harmony)
{
    base.OnLoad(harmony);
    var type = typeof(TargetClass);
    foreach (var ctor in type.GetConstructors(
        BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
    {
        var dumper = typeof(MyDumper).GetMethod("Dump",
            BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
        harmony.Patch(ctor, postfix: new HarmonyMethod(dumper));
    }
}

public static void Dump(TargetClass __instance)
{
    var type = __instance.GetType();
    string output = "[MyMod] === TargetClass DUMP ===\\n";
    foreach (var f in type.GetFields(
        BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
    {
        var val = f.GetValue(__instance);
        string str;
        if (val is IDictionary dict) {
            str = "{Dict count=" + dict.Count + "}";
            foreach (var key in dict.Keys) {
                string keyStr = key?.ToString() ?? "null";
                if (key != null) {
                    var kt = key.GetType();
                    var idP = kt.GetProperty("Id");
                    if (idP != null) keyStr = idP.GetValue(key)?.ToString() ?? keyStr;
                    else {
                        var idF = kt.GetField("Id", 
                            BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
                        if (idF != null) keyStr = idF.GetValue(key)?.ToString() ?? keyStr;
                    }
                }
                str += "\\n    [" + keyStr + "] = " + (dict[key]?.ToString() ?? "null");
            }
        }
        else if (val is IList list && !(val is Array)) {
            str = "[" + list.Count + " items]";
            foreach (var item in list) {
                if (item == null) { str += "\\n    - null"; continue; }
                string extra = "";
                var itemType = item.GetType();
                foreach (var p in itemType.GetProperties(
                    BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
                { try { var v = p.GetValue(item); extra += $"  .{p.Name}={v}"; } catch {} }
                foreach (var f2 in itemType.GetFields(
                    BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
                { try { var v = f2.GetValue(item); extra += $"  .{f2.Name}={v}"; } catch {} }
                str += "\\n    - " + item.ToString() + extra;
            }
        }
        else if (val is Array arr) str = "[" + arr.Length + " items]";
        else str = val?.ToString() ?? "null";
        output += $"  Field {f.Name} ({f.FieldType.Name}) = {str}\\n";
    }
    Debug.Log(output);
}
```

**Caveats:**
- Do NOT access `Db.Get()` inside `OnLoad()` or `MinionStartingStats` constructor postfix hooks — database is null during startup
- **MinionStartingStats ctor patches fire DURING asset loading** — only use `Game.LateUpdate` + `_didInit` guard for Db-dependent operations
- If the dump crashes, wrap in try/catch

## Harmony Patching Patterns — Detailed Reference

### Quick Reference: Known Working vs Broken Patch Targets

| Target | Method | Status | Notes |
|--------|--------|--------|-------|
| `*Config.CreateBuildingDef` | Attribute | ✅ Works | Always reliable |
| `*Config.CreatePrefab` | Attribute | ✅ Works | Non-virtual |
| `Game.LateUpdate` | Manual | ✅ Works | Use one-shot flag for init |
| `BuildingComplete_OnSpawn` | Attribute | ✅ Works | Underscore naming |
| `BuildingComplete_OnInit` | Attribute | ✅ Works | |
| Custom KMonoBehaviour.OnCleanUp | None needed | ✅ Works | Custom subclass, not bypassed by MonoMod. ⚠️ Only clears building's own PrimaryElement — does NOT clear disease in Storage contents. See Pattern 5 for details. |
| `Db.Initialize` | Any | ❌ Broken | Silently ignored |
| `KMonoBehaviour.OnSpawn` | Any | ❌ Broken | Virtual, bypassed by MonoMod |
| `MinionIdentity.OnSpawn` | Any | ❌ Broken | Virtual |
| `Game.OnPrefabInit` | Any | ❌ Broken | Virtual |
| `BuildingComplete.OnSpawn` | Any | ❌ Broken | Actual name is `BuildingComplete_OnSpawn` |
| `Building.ForcePermanentCheck` | Any | ❌ Broken | Does not exist |

### Pattern 1: Manual `harmony.Patch()` in OnLoad (RECOMMENDED — works on U59)

On U59 (build 737790+), `[HarmonyPatch]` attribute auto-discovery may NOT work. Use manual `harmony.Patch()` in `UserMod2.OnLoad`:

```csharp
public class MyMod : KMod.UserMod2
{
    public override void OnLoad(Harmony harmony)
    {
        base.OnLoad(harmony);
        try
        {
            var method = typeof(TargetClass).GetMethod("TargetMethod",
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            if (method == null) { /* log and return */ }

            var postfix = typeof(MyMod).GetMethod("MyPostfix",
                BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);

            harmony.Patch(method, postfix: new HarmonyMethod(postfix));
            Debug.Log("[MyMod] Patched TargetClass.TargetMethod!");
        }
        catch (Exception e) { Debug.Log("[MyMod] " + e.ToString()); }
    }
}
```

The Harmony instance passed to OnLoad is the global game Harmony — use it directly. Do NOT create a new `Harmony("id")` unless you need a separate domain (e.g. delayed patching).

### Pattern 2: Patch a base class like KMonoBehaviour

If your Postfix never fires:
1. Confirm the patch was applied (check log output from OnLoad)
2. If applied but never called, try an alternative hook point:
   - `Game.LateUpdate` (one-time startup)
   - `MinionResume.OnSpawn` (per-duplicate)
   - A concrete non-virtual method on the specific type

### Pattern 3: Game.LateUpdate one-shot for startup grants

```csharp
var lateUpdate = typeof(Game).GetMethod("LateUpdate", ...);
harmony.Patch(lateUpdate, postfix: new HarmonyMethod(...));
// Guard with: private static bool _initialized = false;
// Set _initialized = true on first call
```

### Pattern 4: MinionResume.OnSpawn for per-dupe grants

```csharp
var resumeType = typeof(MinionResume);
var onSpawn = resumeType.GetMethod("OnSpawn",
    BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
harmony.Patch(onSpawn, postfix: new HarmonyMethod(...));
```

### Pattern 5: Custom KMonoBehaviour component + OnCleanUp (bypasses MonoMod virtual-method bypass)

**Problem:** `OnCleanUp` is a virtual method on `KMonoBehaviour`. MonoMod bypasses virtual method patches for game classes.

**Solution:** Instead of patching `OnCleanUp`, attach your OWN `KMonoBehaviour` subclass to the prefab, and override `OnCleanUp` on YOUR class. Custom classes are NOT affected by MonoMod's virtual-method bypass — only game-built-in classes are.

```csharp
// Step 1: Patch CreatePrefab to attach custom component
public override void OnLoad(Harmony harmony)
{
    base.OnLoad(harmony);
    var m = typeof(WideFarmTileConfig).GetMethod("CreatePrefab",
        BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
    if (m != null)
        harmony.Patch(m, postfix: new HarmonyMethod(typeof(MyMod), nameof(CreatePrefabPostfix)));
}

private static void CreatePrefabPostfix(GameObject __result)
{
    if (__result == null) return;
    __result.AddComponent<DiseaseCleaner>();
}

// Step 2: Custom component — OnCleanUp fires before content release
public class DiseaseCleaner : KMonoBehaviour
{
    protected override void OnCleanUp()
    {
        base.OnCleanUp();
        var pe = GetComponent<PrimaryElement>();
        if (pe != null) MyMod.ClearDisease(pe);
    }
}
```

**CRITICAL LIMITATION: Clearing building's PrimaryElement does NOT clear disease in its Storage contents.**

Many buildings (like WideFarmTile/hydroponic farm tiles) have a `Storage` component holding **separate GameObjects** (e.g., nutrient liquid or fertilizer particles with their own `PrimaryElement`). The building's own `PrimaryElement.DiseaseCount` only reflects disease ON the building structure itself, NOT on the stored contents.

When the building is deconstructed:
1. `OnCleanUp` fires on the building GameObject
2. The `Storage` component drops all its contents as `Pickupable` items  
3. Those items carry their own `PrimaryElement` with their own disease counts
4. So clearing the building's `PrimaryElement.DiseaseCount` in a custom `OnCleanUp` override does NOT prevent disease spilling from stored liquids/items

**KEY FINDING: In many cases (like HydroponicFarm), pipes show no liquid but the farm tile's Storage contains diseased fertilizer content items.** The disease is on solid/fertilizer particles in the Storage, not on piped liquid. These particles get their own `Pickupable` GameObjects when dropped during deconstruction, carrying their disease into the environment.

**If you need to clear disease before content release, you must also iterate the Storage's items:**

```csharp
public class DiseaseCleaner : KMonoBehaviour
{
    protected override void OnCleanUp()
    {
        base.OnCleanUp();
        // Still clear the building's own disease
        var pe = GetComponent<PrimaryElement>();
        if (pe != null) CleanFarmTileDiseaseMod.ClearDisease(pe);
        
        // ALSO clear disease on all items in Storage
        var storage = GetComponent<Storage>();
        if (storage != null)
        {
            foreach (var item in storage.items)
            {
                var itemPe = item.GetComponent<PrimaryElement>();
                if (itemPe != null) CleanFarmTileDiseaseMod.ClearDisease(itemPe);
            }
        }
    }
}
```

However, even this may be insufficient if the Storage's `OnCleanUp` fires BEFORE your custom component's `OnCleanUp` (component fire order within a single GameObject's cleanup is not guaranteed). In practice, for WideFarmTile deconstruction, the disease on stored nutrient liquid elements is released to surrounding cells bypassing the component `OnCleanUp` entirely — the disease is on **liquid element droplets** that get spawned as pickupables when the storage empties, not on persistent GameObjects in the storage items list.

**Bottom line for clearing building storage disease before deconstruction:** This is fundamentally difficult on U59 because the disease-carrying elements are created as new `Pickupable` objects during the cleanup process, not pre-existing in the Storage's items list. A `Game.LateUpdate` approach (periodically scanning for buildings with `GameTags.Destroyed` and clearing their storage contents) may be more reliable than trying to intercept `OnCleanUp`.

**Use this pattern when:**
- You need to run code when a building is deconstructed/destroyed, BEFORE content is released to the environment
- You'd normally use `OnCleanUp` but it's virtual and Harmony won't hook it
- The action is per-building-instance (not global/per-frame)

**Don't use for:**
- One-shot startup logic (use Game.LateUpdate + flag)
- Global system hooks (use Game.LateUpdate)
- Per-dupe logic (use MinionResume.OnSpawn)

**Important:** Custom component `OnCleanUp` fires during the game's normal cleanup sequence, BEFORE the `PrimaryElement` and `Pickupable` content is dropped. This makes it ideal for clearing disease counts, modifying dropped items, or logging deconstruction events.

### Pattern 6: Game.LateUpdate periodic storage disease clearing

Use when you need to clear disease from Storage items inside a building type before deconstruction or on a regular basis. More reliable than intercepting `OnCleanUp` because disease-carrying Pickupable objects are created during the Storage cleanup process, not pre-existing in the items list.

```csharp
private static void OnLateUpdate()
{
    if (Game.Instance == null) return;
    if (Time.frameCount % 30 != 0) return; // throttle: every ~0.5s

    var buildings = Object.FindObjectsOfType<BuildingComplete>();
    foreach (var building in buildings)
    {
        if (building.Def.PrefabID != "HydroponicFarm") continue; // check target prefab
        
        var storage = building.GetComponent<Storage>();
        if (storage == null) continue;

        foreach (var item in storage.items)
        {
            if (item == null) continue;
            var pe = item.GetComponent<PrimaryElement>();
            if (pe != null && pe.DiseaseCount > 0)
                ClearDiseaseViaReflection(pe);
        }
    }
}
```

**Key: `FindObjectsOfType<BuildingComplete>()` is safe** (typically < 500 instances). Never use `FindObjectsOfType<GameObject>()` in a loop. See the OOM pitfall section for details.

### Pattern 7: MinionStartingStats ctor for printing pod UI display

```csharp
var statsType = typeof(MinionStartingStats);
var ctors = statsType.GetConstructors(/* all bindings */);
foreach (var ctor in ctors) harmony.Patch(ctor, ...);
```

### CRITICAL: [MyCmpReq] prevents DestroyImmediate of components

When a component is decorated with `[MyCmpReq]` attribute on another component, you **cannot** `DestroyImmediate()` it at runtime. The dependent component's `Start()` method calls `Util.RequireComponent<T>()` which throws an error and breaks the game object.

**Crash signature:**
```
UnityEngine.GameObject 'X' requires a component of type Y as requested by Z!
  at Util.RequireComponent[T] (UnityEngine.Component cmp)
  at MyCmp.RequireComponent[T] (KMonoBehaviour c, System.Boolean isStart)
  at KMonoBehaviour.Start ()
```

**Known cases:**
- `WiltCondition` is `[MyCmpReq]` on `PrickleGrass` (BulbPlant uses PrickleGrass)
- If you need to disable the component's behavior, modify its internal fields via reflection instead

**Solution:** Instead of removing the component, set its critical fields via Game.LateUpdate:
```csharp
var isWiltingField = typeof(WiltCondition).GetField("isWilting",
    BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
isWiltingField?.SetValue(wiltComponent, false);
```

### Crash debug: LegacyModMain in error trace

If the crash trace includes `LegacyModMain.LoadBuildings` or `LegacyModMain.Load`, the crashing mod uses the Legacy API (not `KMod.UserMod2`). These are old-format mods loaded by the game's backward compatibility layer. Symptoms:
- `NullReferenceException` at `Assets.OnPrefabInit` during startup
- `AdvancedApothecary..ctor` or similar base class constructors failing
- Caused by the mod registering buildings (`GeneratedBuildings.LoadGeneratedBuildings`) before its dependencies are ready

**Fix**: Disable the offending Legacy mod in the Mods menu. If the crash happens even with only your mod enabled, check if you accidentally copied a `LegacyModMain` DLL from another mod into your mod folder — ONI scans ALL DLLs in `mods/Local/`, not just the one listed in your mod_info.yaml.

### Crash debug: Zolibrary + AddToTechnology

If crash trace includes `Zolibrary.Utilities.BuildingUtils.AddToTechnology`:
- The mod depends on Zolibrary (a library mod for building registration)
- Zolibrary's `OnPrefabInit` hook tries to register tech before the tech database is ready
- **Fix**: Update Zolibrary to latest version, or check if the mod's Zolibrary.dll is outdated
- Workaround: Remove Zolibrary.dll from the mod folder (mod may have built-in fallback)

### Common Issues Quick Reference

**"Could not find Database.Skill: Swimming1"** — The skill ID changed between versions. Log all skills at runtime to find actual IDs.

**[HarmonyPatch] attribute patches silently don't apply** — On U59, attribute-based patches may be ignored. Use manual `harmony.Patch()` in `OnLoad` instead.

**Mod loads but doesn't appear in Subscribe list** — Check mod_info.yaml syntax. Common errors: wrong `supportedContent`, missing `dlls:` list, or malformed YAML.

**Assembly references not resolving** — Use `net48` target framework, all managed DLLs from `OxygenNotIncluded_Data/Managed/`. If `dotnet build` says "project is up to date" incorrectly: `dotnet clean -c Release` first.

**PrintListSelect mod (workshop 2019780544) compatibility** — This mod replaces printing pod UI. If your `MinionStartingStats` patches work without it but not with it, disable PrintListSelect for testing. It intercepts the character generation pipeline and may override vanilla code paths.

**LLM models cannot see DLL file contents** — When debugging mod loading issues from Player.log, focus on log messages the mod prints. To verify strings exist in the compiled binary: `cat mod.dll | tr -d '\0' | grep -ao "MyString"`.

### ElementConverter-based mods (csproj note)

When patching ore items with `ElementConverter` for passive gas/liquid production, **ensure Assembly-CSharp-firstpass is referenced** — `ElementConverter`, `Tag`, and `Storage` all derive from types in that assembly:

```xml
<Reference Include="Assembly-CSharp-firstpass">
  <HintPath>...\OxygenNotIncluded_Data\Managed\Assembly-CSharp-firstpass.dll</HintPath>
</Reference>
```

Without this reference, `AddComponent<ElementConverter>()` fails with `KMonoBehaviour not found` error.

### DLL Caching (Timestamps Matter)

ONI does NOT re-read DLLs if the file timestamp hasn't changed. When updating a mod:
1. Always `rm -f ./MyMod.dll` before copying the new one
2. Verify with `md5sum` that the root DLL matches `bin/Release/` after copy
3. Same-size DLLs may still be the old version if the build cache didn't update — always `dotnet clean -c Release` first
4. If in doubt: add a new log message string to confirm the new version loaded

### Debugging workflow (log-based)
1. Mod loads? → grep for `YourMod` + `Successfully loaded`
2. OnLoad fires? → grep for `[YourMod] OnLoad called`
3. Patch registered? → grep for `[YourMod] Patched`
4. Patch fires? → grep for Postfix log message
5. Exception? → grep for `[YourMod]` + `error` or `Exception` near your mod's log lines
6. Mod crashed and auto-disabled? → ONI disables it on next launch; manually re-enable in Mods menu
7. **Player.log path**: `%USERPROFILE%\\AppData\\LocalLow\\Klei\\Oxygen Not Included\\Player.log`
8. **Player-prev.log**: previous session's logs

## Analyzing & Porting Third-Party Mods from Steam Workshop

### Query mod details via Steam API

When the Steam Workshop website is blocked (DNS wall), use the Steam API directly:

```bash
curl -s "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/" \
  -d "itemcount=1&publishedfileids[0]=<WORKSHOP_ID>"
```

Returns JSON with: `title`, `description`, `file_url` (direct CDN download link), `creator`, `consumer_app_id`, `preview_url`, `tags`, `file_size`, `time_updated`.

Note: `consumer_app_id: 457140` = Oxygen Not Included.

### Download mod zip from Steam CDN

```bash
curl -sL "<file_url>" -o mod.zip
mkdir mod_unpacked && cd mod_unpacked
unzip ../mod.zip
```

The zip usually contains: `mod.yaml`, `mod_info.yaml`, `*.dll`, `anim/`, `preview.png`.

### Analyzing compiled DLLs (no source code)

Extract readable strings to understand architecture:

```python
with open('mod.dll', 'rb') as f:
    data = f.read()

strings = set()
current = b''
for byte in data:
    if 32 <= byte < 127:
        current += bytes([byte])
    else:
        if len(current) >= 5:
            strings.add(current.decode('ascii'))
        current = b''

for s in sorted(strings):
    if is_interesting(s):
        print(s)
```

Key things to identify:
- **Class names**: `MyModName`, `MyModConfig`, etc.
- **Types referenced**: `BuildingDef`, `PlantablePlot`, `SingleEntityReceptacle`, `HarmonyPatch`
- **Methods**: `SpawnOccupyingObject`, `ConfigureBuildingTemplate`, `CreateBuildingDef`
- **Tags**: `FARMABLE`, `PLANT`, `MUTANT_PLANT`
- **UI strings**: building descriptions, tooltips, status items
- **Referenced assemblies**: `Assembly-CSharp`, `UnityEngine.CoreModule`, `0Harmony`

### Porting workflow

1. Download mod via Steam API
2. Extract strings from DLL to understand architecture
3. Identify Harmony patch targets (which methods it hooks)
4. Check `minimumSupportedBuild` against your game version
5. If outdated: list the game version-specific fields/classes used, create a new project
6. Build against the current game DLLs
7. Deploy as a local mod

## Steam Workshop Mod to Local Porting

1. Find mod ID folder under `content/457140/<ID>/`
2. Extract DLL from `*_legacy.bin` (ZIP format)
3. Create `mod.yaml` with `supportedContent: ALL`
4. Create `mod_info.yaml` with `minimumSupportedBuild: 737790`, `APIVersion: 2`
5. User must re-enable the mod in-game (it moves from Workshop to Local tab)

## Mod Crash -> Auto-Disable Mechanism

If a mod throws a Harmony exception during loading, ONI marks it as broken.
Next game launch, the DLL is SKIPPED entirely.
Fix: Go to Mods menu -> find the mod -> manually re-enable it.
Deleting and replacing the DLL alone is NOT enough.
