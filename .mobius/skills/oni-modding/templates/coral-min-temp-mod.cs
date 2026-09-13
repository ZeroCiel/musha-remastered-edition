// CoralMinTemp.cs — ONI U59 template
// Sets OxyCoral and PlanktonCoral minimum temperature to 15°C
// U59 uses TemperatureVulnerable, NOT PlantablePlot.lethalLowTemp
// Pattern: *Config.CreatePrefab Postfix

using HarmonyLib;
using System;
using System.Reflection;
using UnityEngine;

namespace CoralMinTemp
{
    public class CoralMinTempMod : KMod.UserMod2
    {
        public override void OnLoad(Harmony harmony)
        {
            base.OnLoad(harmony);

            var types = new[] { "OxyCoralConfig", "PlanktonCoralConfig" };
            foreach (var typeName in types)
            {
                var t = Type.GetType(typeName + ", Assembly-CSharp");
                if (t == null) continue;

                var method = t.GetMethod("CreatePrefab",
                    BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
                if (method == null) continue;

                var postfix = typeof(CoralMinTempMod).GetMethod("Postfix_CreatePrefab",
                    BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
                harmony.Patch(method, postfix: new HarmonyMethod(postfix));
                Debug.Log("[CoralMinTemp] Patched " + typeName + ".CreatePrefab");
            }
        }

        public static void Postfix_CreatePrefab(ref GameObject __result)
        {
            if (__result == null) return;

            // U59: Temperature is on TemperatureVulnerable component
            var tempVuln = __result.GetComponent<TemperatureVulnerable>();
            if (tempVuln == null) return;

            // Use reflection since field names are not public API
            var t = typeof(TemperatureVulnerable);
            var lethal = t.GetField("internalTemperatureLethal_Low",
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            var warning = t.GetField("internalTemperatureWarning_Low",
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);

            if (lethal != null) lethal.SetValue(tempVuln, 288.15f);  // 15°C
            if (warning != null) warning.SetValue(tempVuln, 288.15f); // 15°C
        }
    }
}
