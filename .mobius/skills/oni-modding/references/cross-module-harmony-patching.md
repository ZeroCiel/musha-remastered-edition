# Cross-Module Harmony Patching (Delayed Patcher Pattern)

When your Harmony mod needs to patch a type defined in **another mod's DLL** (not Assembly-CSharp), standard approaches fail because the target DLL isn't loaded yet.

## The Problem

- `AccessTools.TypeByName()` searches **already-loaded assemblies** only
- During `OnLoad()`, other mod DLLs may not be in `AppDomain.GetAssemblies()` yet
- `TargetMethods()` that `yield return null` **crashes Harmony** and disables the entire mod
- Even `Game.OnPrefabInit` may be too early for some mods

### The `TargetMethods` null trap

```csharp
// ❌ CRASH — yields null when type/method not found
static IEnumerable<MethodBase> TargetMethods()
{
    var type = AccessTools.TypeByName("ExternalModType");
    if (type != null)
        yield return AccessTools.Method(type, "SomeMethod"); // null!
}

// ✅ SAFE — no yield if not found
static IEnumerable<MethodBase> TargetMethods()
{
    var type = AccessTools.TypeByName("ExternalModType");
    if (type != null)
    {
        var method = AccessTools.Method(type, "SomeMethod");
        if (method != null)
            yield return method;
    }
    // No yield = no patch = no crash
}
```

## Solutions

### Option A: Delayed coroutine patching (recommended for cross-module)

Skip `[HarmonyPatch]` entirely. Use a Unity coroutine that retries until the target assembly loads:

```csharp
public class MyMod : KMod.UserMod2
{
    public override void OnLoad(Harmony harmony)
    {
        base.OnLoad(harmony);
        var go = new UnityEngine.GameObject("MyModDelayedPatcher");
        go.AddComponent<DelayedPatcher>();
        UnityEngine.Object.DontDestroyOnLoad(go);
    }
}

public class DelayedPatcher : UnityEngine.MonoBehaviour
{
    private float _retryTimer = 0f;
    private bool _patched = false;

    void Update()
    {
        if (_patched) return;
        _retryTimer += UnityEngine.Time.deltaTime;
        if (_retryTimer < 1f) return;
        _retryTimer = 0f;

        var targetType = FindType("TargetTypeFromOtherMod");
        if (targetType == null) return;

        try
        {
            var harmony = new Harmony("MyMod.Delayed");
            var method = AccessTools.Method(targetType, "TargetMethod");
            if (method != null)
            {
                var prefix = AccessTools.Method(typeof(MyPrefix), "Prefix");
                harmony.Patch(method, new HarmonyMethod(prefix));
                Debug.Log("[MyMod] Patched!");
            }
            _patched = true;
            UnityEngine.Object.Destroy(gameObject);
        }
        catch (System.Exception e)
        {
            Debug.LogWarning($"[MyMod] Patch error: {e.Message}");
        }
    }

    private static System.Type FindType(string name)
    {
        foreach (var asm in System.AppDomain.CurrentDomain.GetAssemblies())
        {
            var t = asm.GetType(name);
            if (t != null) return t;
        }
        return null;
    }
}
```

**Key points:**
- Use a **different Harmony ID** (`new Harmony("MyMod.Delayed")`) from the `OnLoad` one
- Component self-destructs after patching succeeds
- 1-second check interval avoids perf impact

### Option B: Manual patch in `Game.OnPrefabInit` (for Assembly-CSharp types)

```csharp
[HarmonyPatch(typeof(Game), "OnPrefabInit")]
public static class GameInitPatch
{
    static void Postfix(Game __instance)
    {
        __instance.StartCoroutine(DelayedPatch());
    }

    static System.Collections.IEnumerator DelayedPatch()
    {
        yield return new WaitForSeconds(3f);
        // ... find type and patch manually
    }
}
```

### Special case: Building class name != Config class name

ONI building classes often have different class names from their config:

| Config class | Actual building class | Notes |
|---|---|---|
| `LargeElectrobankDischargerConfig` | `ElectrobankDischarger` | Drops `Large` prefix |
| `SmallElectrobankDischargerConfig` | `ElectrobankDischarger` | Same class shared |

Always verify by searching DLL strings for the actual type name before hardcoding.
