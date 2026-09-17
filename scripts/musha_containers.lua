-- ============================================================
-- musha_containers.lua — 容器参数集中登记
--   写法照 **Musha-beta** 的 `main/05.Musha_Containers.lua`：
--     local containers = require "containers" → params = containers.params → 逐个填
--     itemtestfn 挂在 params.<名> 上；组件由**建筑自己的 prefab** 去 AddComponent("container") + WidgetSetup(名)
--   ⚠️ 本文件必须在 PrefabFiles 注册之前 modimport（WidgetSetup 要来查这张表），
--      而且**双端都要跑**（客户端画容器格子也查它）→ 挂在 modmain 里 modimport。
-- ============================================================

local containers = require "containers"
local params = containers.params

-- ============================================================
-- 进阶祭坛（1 格）—— 只放【转职卷轴 musha_scroll】
--   UI 框借原版 1x1：ui_chest_1x1（同原版 yots_lantern_post）
-- ============================================================
params.musha_advance_altar = {
    widget = {
        slotpos = {},
        animbank = "ui_chest_1x1",
        animbuild = "ui_chest_1x1",
        pos = Vector3(0, 160, 0),
        side_align_tip = 100,
    },
    acceptsstacks = false,
    type = "chest",
}
table.insert(params.musha_advance_altar.widget.slotpos, Vector3(0, 0, 0))

-- 祭坛只认卷轴（防玩家把祭坛当箱子塞东西）
function params.musha_advance_altar.itemtestfn(container, item, slot)
    return item:HasTag("musha_scroll") and not container.inst:HasTag("burnt")
end

-- MAXITEMSLOTS 是原版 containers.lua 末尾按各自 slotpos 算的最大值；
-- 我们的 params 是**加载完之后**才加进去的 → 手动顶上（1 格 < 原版上限，改不改都行，写清楚防误会）
containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS or 0, 1)

print("[Musha] 容器参数已登记: musha_advance_altar（1 格 / ui_chest_1x1）")
