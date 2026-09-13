using HarmonyLib;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

/// <summary>
/// Example: Postfix fallback for FlydoMinerMonitor.FindBestMineableCell
/// 
/// When the original method returns -1 (no dig target found),
/// this fallback scans all Diggable GameObjects within 50 cells
/// and returns the nearest valid cell.
/// 
/// Usage in DelayedPatcher (after FlydoMinerMonitor Type is found):
/// 
/// var m = AccessTools.Method(monitorType, "FindBestMineableCell");
/// if (m != null)
///     harmony.Patch(m, postfix: new HarmonyMethod(typeof(Fallback), nameof(Fallback.FBMC)));
/// </summary>
public static class Fallback
{
    /// <summary>
    /// FindBestMineableCell 找不到目标时 → 自己扫描 Diggable
    /// </summary>
    public static void FBMC(object __instance, ref int __result)
    {
        if (__result != -1) return; // 原方法已找到目标，不动

        try
        {
            var go = GetGO(__instance);
            if (go == null) return;

            Vector3 pos = go.transform.position;

            // Scan all Diggable (marked for mining)
            var diggables = Object.FindObjectsOfType<Diggable>();
            Diggable best = null;
            float bestDist = 999f;

            foreach (var d in diggables)
            {
                if (d == null) continue;
                float dist = Vector3.Distance(pos, d.transform.position);
                if (dist < bestDist && dist < 50f)
                {
                    var cell = Grid.PosToCell(d);
                    if (Grid.IsValidCell(cell))
                    {
                        bestDist = dist;
                        best = d;
                    }
                }
            }

            if (best != null)
            {
                int cell = Grid.PosToCell(best);
                if (Grid.IsValidCell(cell))
                {
                    __result = cell;
                    Debug.Log($"[FlydoMiningHotfix] Fallback: found dig target at cell {cell}, dist {bestDist:F1}");
                }
            }
        }
        catch (System.Exception e)
        {
            Debug.LogWarning($"[FlydoMiningHotfix] FBMC fallback error: {e.Message}");
        }
    }

    static GameObject GetGO(object instance)
    {
        try
        {
            if (instance is Component c) return c.gameObject;
            var p = instance.GetType().GetProperty("gameObject",
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            return p?.GetValue(instance) as GameObject;
        }
        catch { return null; }
    }
}
