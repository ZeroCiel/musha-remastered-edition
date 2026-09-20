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
params.musha_mailbox = {
    widget = {
        slotpos = {},
        -- animbank = "ui_chester_shadow_3x4",   -- ← 3x4 的旧占位框，跟 4x3 的格子对不上，先摘掉等新底板
        -- animbuild = "ui_chester_shadow_3x4",
        pos = Vector3(0, 220, 0),
        side_align_tip = 160,
    },
    acceptsstacks = true,
    type = "chest",
}

-- 4 列 x 3 行 = 12：格距 75（单格 64），整块居中（X = ±112.5 / ±37.5，Y = 75 / 0 / -75）
--   格子顺序 = 行优先：1~4 是上面那行，9~12 是最下面那行（解锁按 1→12 顺序走）
for row = 0, 2 do
    for col = 0, 3 do
        table.insert(params.musha_mailbox.widget.slotpos,
            Vector3(75 * col - 112.5, 75 - 75 * row, 0))
    end
end

-- ★ 2026-09-20 叉号格（用户说"邮箱 叉号没做"）：
--   未解锁的格子换成「叉号底图」= images/musha_mail_x.png（→ .tex/.xml，槽底+粗叉）
--   已解锁的格子 slotbg 留 nil = 原版槽的样子，不用画
--   ⚠️ slotbg 是**静态**的（WidgetSetup 时照这张表复制一份），这里按默认「解锁 3 格」填 4~12；
--      以后用邮包套件升级（unlocked 3→5→7→9→11）要让叉号跟着退 → 见文件末尾说明
local MAIL_X_ATLAS, MAIL_X_IMAGE = "images/musha_mail_x.xml", "musha_mail_x.tex"
params.musha_mailbox.widget.slotbg = params.musha_mailbox.widget.slotbg or {}
for i = 3 + 1, 12 do   -- 3 = musha_mail.BOX_SLOT_INIT（初始解锁格数），改了它这里也要改
    params.musha_mailbox.widget.slotbg[i] = { atlas = MAIL_X_ATLAS, image = MAIL_X_IMAGE }
end

-- 未解锁的格子放不进去（真实判断在 prefab 里，那边能看到 inst.unlocked；这里只兜底）
--   ⚠️ 2026-09-21：加载期间（inst._loading，见 prefab 的 OnPreLoad）**一律放行** ——
--      不然读档时容器先把物品往格子里塞、unlocked 还没恢复 → 超过 3 格的东西会被这里拦掉丢失。
function params.musha_mailbox.itemtestfn(container, item, slot)
    local inst = container ~= nil and container.inst or nil
    if inst ~= nil and inst._loading then return true end
    local unlocked = (inst ~= nil and inst.unlocked) or 3
    if slot == nil then return false end
    return slot <= unlocked
end

-- MAXITEMSLOTS 是原版 containers.lua 末尾按各自 slotpos 算的最大值；
-- 我们的 params 是**加载完之后**才加进去的 → 手动顶上（最大的那个是包的 14 格）
containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS or 0, 14)


print("[Musha] 容器参数已登记: musha_advance_altar（1 格 / ui_chest_1x1）")

-- ============================================================
-- ⚠️ 叉号格什么时候会不准 / 怎么改成动态（2026-09-20 记）
--   slotbg 是 WidgetSetup 时按 params 复制进 widget 的**静态**表，所以：
--     · 默认 3 格解锁 → 现在正好对（4~12 是叉）
--     · 玩家用邮包套件升级到 5/7/9/11 格后，叉号还留在旧位置 → 需要动态重填
--   动态做法（没做，等需要时上）：
--     ① musha_mailbox_shadow 里把 unlocked 用 netvar 同步（net_smallbyte[0..63]），
--        服务端 UpgradeMailbox 时 push；
--     ② 客户端 AddClassPostConstruct("widgets/containerwidget")：widget 建好后，
--        若 container 的 inst 带 musha_mail_shadow tag，就按真实 unlocked 重填
--        self.inv[i] 那格底图（已解锁 = 原版槽图，未解锁 = images/musha_mail_x.xml）。
--   判断"是不是收件箱"只看 tag：inst:HasTag("musha_mail_shadow")
-- ============================================================
