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

-- ============================================================
-- 信差包（5 格可见 + 9 格"待寄区"隐藏格）
--   ★ 关键：`numslots` 写 14（容器真实格数）、`slotpos` 只列 5 个（玩家看得见）
--     原版 containers.lua:15 是 `SetNumSlots(widget.numslots or #slotpos)`
--     → 组件和 replica **双端**都会拿到 14；而 UI 只按 slotpos 画 5 个格子。
--     隐藏格不画、点不到，但原版 container 的存档逻辑照样存它们 = 免费拿到一个"暗格"。
--   UI 框先借原版 ui_chest_3x2（用户说开包界面他自己做，这里只是占位）
-- ============================================================
params.musha_mailbag = {
    widget = {
        slotpos = {
            Vector3(-75,  36.5, 0),
            Vector3(  0,  36.5, 0),
            Vector3( 75,  36.5, 0),
            Vector3(-37.5, -36.5, 0),
            Vector3( 37.5, -36.5, 0),
        },
        numslots = 14,                 -- ← 5 可见 + 9 隐藏
        animbank = "ui_chest_3x2",
        animbuild = "ui_chest_3x2",
        pos = Vector3(0, 200, 0),
        side_align_tip = 120,
        -- ★★ 2026-09-20 用户实测「信差包没有发送按钮」的根因 ★★
        --   `buttoninfo` 必须写在 **widget 里**！原版 containerwidget.lua:28 拿的是 `container:GetWidget()`
        --   （= WidgetSetup 从 params.<名>.widget 复制出来的那张表），第 54 行读 `widget.buttoninfo`；
        --   原版全都这么写（containers.lua:316/363/414/465/503 都是 `params.<名>.widget.buttoninfo = {...}`）。
        --   之前我们放在 params 顶层 → 永远读不到 → 按钮不显示。
        buttoninfo = {
            text = "发送",
            position = Vector3(0, -95, 0),
            fn = function(container, doer)
                if TheNet ~= nil and TheNet:GetIsClient() then
                    SendModRPCToServer(GetModRPC("musha", "musha_mailbag_send"))
                elseif MushaMailBagSend ~= nil then
                    MushaMailBagSend(doer or ThePlayer)          -- 主机自己按：直接调同一套逻辑
                end
            end,
        },
    },
    acceptsstacks = true,
    type = "chest",
}

-- ============================================================
-- 信箱收件箱（网格 4 列 x 3 行 = 12 格）
--   ★ 2026-09-20 用户："信箱面板改 4x3、遗漏最后一格、设计为 12 就好"
--     → 从原版的 3 列 x 4 行（竖高）改成 **4 列 x 3 行**（横宽、矮一点），一共 12 格，格格都能解锁
--   未解锁的格子靠 itemtestfn 拦住（放不进去）；UI 上的"叉号"靠 widget.slotbg 画
--   → slotbg 是逐格覆盖的钩子：widget.slotbg[i] = { atlas = ..., image = ... }
--     （原版 containerwidget.lua:136-142：每格底图 = slotbg[i] 或默认 images/hud.xml + inv_slot.tex）
--   ⚠️ 底板/边框：原版 data/anim 里**没有 4x3 的容器底图**
--      （只有 ui_chester_shadow_3x4 / ui_wishbox... / ui_woby_3x4 这些 3 列 4 行的）
--      → 这里先把 animbank/animbuild 摘掉（格子自己带底图，功能完全正常），
--        用户画好 4x3 底板后：填回 animbank/animbuild（或者用 bgatlas/bgimage 挂一张静态底图）即可。
-- ============================================================
-- ★★ 2026-09-21 重做：params 的 key 必须**等于实体 prefab 名**（原版契约）
--   客机上 `container_replica` 的构造函数是 `containers.widgetsetup(self)` →
--   它取的是 `params[container.inst.prefab]`。我们的收件箱实体叫 `musha_mailbox_shadow`，
--   而参数原来挂在 `musha_mailbox` 这个名字下 → 客机取不到（widget = nil）→ 客机开箱直接崩。
--   所以现在 5 张表全部按 prefab 名生成，并按"已解锁档位"给不同的叉号底图：
--     3 格 = musha_mailbox_shadow        （默认档，客机 ctor 就是取这张）
--     5/7/9/11/12 格 = ..._u5 / _u7 / _u9 / _u11 / _u12（11 = 老档兜底，新档套件 IV 直上 12）
--   → 服务端换档时用 `container:WidgetSetup("musha_mailbox_shadow_u7")`，
--     客机由 musha_maillevel 组件监听到网络值变化后对 `replica.container` 做同样调用
--     （= 原版 firepit.lua:131 的"prefaboverride"那套写法）。
--   ⚠️ slotbg 是逐格覆盖的钩子（原版 containerwidget.lua:136-142）；每张表只按自己档位标叉号。
local MAIL_X_ATLAS, MAIL_X_IMAGE = "images/musha_mail_x.xml", "musha_mail_x.tex"

local function MakeMailboxParams(unlocked)
    local t = {
        widget = {
            slotpos = {},
            -- animbank = "ui_chester_shadow_3x4",   -- 3x4 的旧占位框跟 4x3 格子对不上，等 4x3 底板
            -- animbuild = "ui_chester_shadow_3x4",
            pos = Vector3(0, 220, 0),
            side_align_tip = 160,
            slotbg = {},
        },
        acceptsstacks = true,
        type = "chest",
    }

    -- 4 列 x 3 行 = 12：格距 75（单格 64），整块居中（X = ±112.5 / ±37.5，Y = 75 / 0 / -75）
    --   格子顺序 = 行优先：1~4 是上面那行，9~12 是最下面那行（解锁按 1→12 顺序走）
    for row = 0, 2 do
        for col = 0, 3 do
            table.insert(t.widget.slotpos, Vector3(75 * col - 112.5, 75 - 75 * row, 0))
        end
    end

    -- 未解锁格 = 叉号底图（已解锁格留空 = 原版槽的样子）
    for i = unlocked + 1, 12 do
        t.widget.slotbg[i] = { atlas = MAIL_X_ATLAS, image = MAIL_X_IMAGE }
    end

    -- 未解锁的格子放不进去（真实判断看 inst.unlocked；这里兜底 + 加载期放行）
    --   ⚠️ 加载期间（inst._loading，见 prefab 的 OnPreLoad）**一律放行** ——
    --      不然读档时容器先把物品往格子里塞、unlocked 还没恢复 → 超过 3 格的东西会被这里拦掉丢失。
    t.itemtestfn = function(container, item, slot)
        local inst = container ~= nil and container.inst or nil
        if slot == nil then return false end
        -- 读档塞回物品时放行（那时 unlocked 还没恢复）
        if inst ~= nil and inst._loading then return true end
        -- ★★ 2026-09-21：**客机不做限制**。客机上 `inst.unlocked` 这个字段根本不存在（服务端专用），
        --   以前这里 `or 3` → 客机永远只认 3 格 → 升级之后"箱子开着但东西放不进"。
        --   视觉上的叉号由 widget 的档位表负责；能不能放由服务端说了算。
        if not TheWorld.ismastersim then return true end
        local unlocked_now = (inst ~= nil and inst.unlocked) or 3
        return slot <= unlocked_now
    end

    return t
end

params.musha_mailbox_shadow     = MakeMailboxParams(3)
params.musha_mailbox_shadow_u5  = MakeMailboxParams(5)
params.musha_mailbox_shadow_u7  = MakeMailboxParams(7)
params.musha_mailbox_shadow_u9  = MakeMailboxParams(9)
params.musha_mailbox_shadow_u11 = MakeMailboxParams(11)   -- ★ 2026-09-24：老档满档 11 兜底（新档套件 IV → 12）
params.musha_mailbox_shadow_u12 = MakeMailboxParams(12)
params.musha_mailbox = params.musha_mailbox_shadow      -- 兼容旧名字（别处引用不改）

-- （旧的"单独给 params.musha_mailbox 补 slotbg/itemtestfn"那段已删：
--   现在 5 张档位表都由 MakeMailboxParams() 一次生成，slotbg 与 itemtestfn 自带，别再各写一份。）

-- MAXITEMSLOTS 是原版 containers.lua 末尾按各自 slotpos 算的最大值；
-- 我们的 params 是**加载完之后**才加进去的 → 手动顶上（最大的那个是包的 14 格）
containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS or 0, 14)


print("[Musha] 容器参数已登记: musha_advance_altar（1 格 / ui_chest_1x1）")

-- ============================================================
-- ✅ 叉号格随档位变化（2026-09-21 已实现，替代原来的"动态重填 widget"方案）
--   做法 = 原版 firepit.lua:131 那套「换容器 widget」：
--     · params 按 prefab 名 + 档位生成 5 张表（见本文件上部 MakeMailboxParams）
--     · 服务端换档：`inst.components.container:WidgetSetup("musha_mailbox_shadow_u7")`
--       —— Container:WidgetSetup 内部会同步调 `self.inst.replica.container:WidgetSetup(name)`
--     · 客机：`musha_maillevel` 组件监听网络值变化 → 对 `replica.container` 做同样的 WidgetSetup
--     · widget 打开时（containerwidget.lua:136）读的就是 `widget.slotbg[i]` → 叉号自动对
--   ⚠️ 换档时箱子如果正开着，已建好的格子还是旧的 → 关掉重开一次即可（升级本来就要重新点信箱）
-- ============================================================


-- ============================================================
-- 兔子背包（2026-09-26）：8 格 = 原版背包同款 2x4（ui_backpack_2x4）
-- ============================================================
params.musha_rabbitbackpack =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_backpack_2x4",
        animbuild = "ui_backpack_2x4",
        pos = Vector3(-5, -80, 0),
    },
    issidewidget = true,
    type = "pack",
    openlimit = 1,
}

for y = 0, 3 do
    table.insert(params.musha_rabbitbackpack.widget.slotpos, Vector3(-162, -75 * y + 114, 0))
    table.insert(params.musha_rabbitbackpack.widget.slotpos, Vector3(-162 + 75, -75 * y + 114, 0))
end
