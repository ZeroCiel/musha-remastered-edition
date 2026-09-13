# DST Mod 数值配置化（TUNING 四档模式）

明生 mod S3 落地的 v3 配置体系，任何需要"可调数值+档位"的 DST mod 可直接复用。

## 结构

```
scripts/mingsheng_tuning.lua   -- 四档常量表（TIERS[1..4]）
modmain.lua                     -- 顶部初始化（必须最早，见下）
modinfo.lua                     -- configuration_options（档位+开关）
```

### 常量表（scripts/mingsheng_tuning.lua）
```lua
local TIERS = {
    [1] = { ztm_base_damage = 42, ... },  -- Ⅰ 顶配
    [2] = { ... },
    [3] = { ... },                        -- Ⅲ 默认
    [4] = { ... },
}
return { GetTuning = function(tier) return TIERS[tier] or TIERS[3] end }
```

### modmain 顶部初始化（关键坑）
```lua
-- 必须放在所有数值引用（配方、COOLDOWN_SECONDS、AddAction）之前！
GLOBAL.MINGSHENG_TUNING = require("mingsheng_tuning"):GetTuning(tonumber(GetModConfigData("tier")) or 3)
GLOBAL.MINGSHENG_CONFIG = {
    shadow_gift = GetModConfigData("shadow_gift"),
    ...
}
```
- `require("mingsheng_tuning")` 直接可用：DST mod 的 `scripts/` 目录在 package.path 里（与 `require "speech_xxx"` 同理）
- GetModConfigData 在 modmain 全局可用（env __index → GLOBAL）
- 配置项没设置时 GetModConfigData 返回 nil → 开关要处理 nil（`or true`）或 modinfo 默认值兜底

## prefab 引用规则（strict 模式坑）
- **prefab 文件（scripts/prefabs/*.lua）里没有 GLOBAL 变量**——写 `GLOBAL.MINGSHENG_CONFIG` 会报 `variable 'GLOBAL' is not declared`（strict.lua）
- 正确姿势：modmain 用 `GLOBAL.MINGSHENG_TUNING = ...` 写入真全局；prefab 里**直接**写 `MINGSHENG_TUNING.xxx`（prefab env 的 __index 会查到全局）
- modmain 内引用 MINGSHENG_TUNING 也直接写（modmain env 同样 __index → GLOBAL）

## modinfo 配置项
- 用 AddConfig helper：name/label/hover/options/default
- label/hover 中英双语（`"档位/Tier"`、`"数值档位：…\nDifficulty tier: …"`）
- 开关用 `{description="开/On", data=true}` / `{description="关/Off", data=false}`
- 档位用 data = 1..4 数字，默认 3

## 数值收敛清单（哪些要换）
配方三维成本（Ingredient amount × cost_mult，math.floor 取整）、numtogive、冷却秒数（天数×480）、prefab 内所有 local 常量（血/攻/防/持续/半径/概率）、被动效果数值。

## 存档兼容
- OnSave/OnLoad 只存运行时状态（timer_data/flag），不存档位数值 → 中途改档不崩档，数值即时生效
- 常量表里定义但功能未实现的字段（如 zaoyu_duration 体温锁定、celestial_planar 随从协同、gaoshizhe_* 独立战斗体）保留备用，S2 实现时直接引用
