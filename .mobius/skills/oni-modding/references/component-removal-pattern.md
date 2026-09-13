# Component Removal Pattern for ONI Mods (U59+)

## Principle
To make a building immune to a specific hazard, remove the vulnerability component from its GameObject during `DoPostConfigureComplete`.

## Working Example: WideFarmTile Pressure Immunity

```csharp
[HarmonyPatch(typeof(WideFarmTileConfig), "DoPostConfigureComplete")]
public static class NoPressurePatch
{
    static void Postfix(GameObject go)
    {
        var pv = go.GetComponent<PressureVulnerable>();
        if (pv != null)
            UnityEngine.Object.DestroyImmediate(pv);
    }
}
```

## Important: Use `DoPostConfigureComplete`, NOT `ConfigureBuildingTemplate`

`ConfigureBuildingTemplate` can receive a **wrong GameObject** — discovered when `CreatureFeederConfig.ConfigureBuildingTemplate` got a StorageLocker GameObject instead of the feeder. This caused a NullReferenceException when trying to `GetComponent<IUserControlledCapacity>()`.

`DoPostConfigureComplete` always receives the correct building GameObject.
