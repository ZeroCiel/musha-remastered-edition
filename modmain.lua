-- ==========================================
-- Musha 0.7.6 — 职业系统重制版
-- 雪儿 (Ciel) © 2026
-- ==========================================
print("[Musha] ★ 模组开始加载...")
-- ★ 2026-09-17 发布前清理：33 处 [Musha TRACE] 全部改走这个开关
--   默认 false = 发布版日志安静；要定位闪退时改成 true，那 33 条追踪就全回来
local MUSHA_TRACE = false
local function TRACE(msg)
    if MUSHA_TRACE then print(msg) end
end

-- print 追踪：闪退定位
TRACE("[Musha TRACE] 1 - modmain 开始")

-- 全局调试标记
local DEBUG_MODE = false

-- =====================
-- 安全执行辅助
-- =====================
local function Safe(name, ...)
    local ok, err = pcall(...)
    if not ok then
        print("[Musha ERROR] " .. name .. ": " .. tostring(err))
        print("[Musha] 请检查上述错误行号")
    end
    return ok
end

local function DebugPrint(...)
    if DEBUG_MODE then
        print("[Musha DEBUG]", ...)
    end
end

-- =====================
-- 环境检查
-- =====================
local is_server = (TheNet and (TheNet:GetIsServer() or TheNet:IsDedicated()))
local is_client = (TheNet and TheNet:GetIsClient())
print(string.format("[Musha] 环境: 服务器=%s 客户端=%s", tostring(is_server or false),
    tostring(is_client or false)))

-- =====================
-- 设置全局环境访问
-- =====================
TRACE("[Musha TRACE] 2 - setmetatable 前")
GLOBAL.setmetatable(env, {
    __index = function(t, k)
        return GLOBAL.rawget(GLOBAL, k)
    end
})
TRACE("[Musha TRACE] 3 - setmetatable 后")

-- =====================
-- 兼容 JSON 模块
-- =====================
if not json then
    json = _G.json or {}
    if not json.encode then
        json.encode = function(t)
            return DataDumper(t, nil, true)
        end
        json.decode = function(s)
            local ok, v = pcall(_G.json.decode, s)
            if ok then
                return v
            else
                return {}
            end
        end
    end
end
DebugPrint("JSON 模块就绪")

-- =====================
-- 职业常量定义
-- =====================
MUSHA_JOB = {
    NONE = 0,
    WARRIOR = 1,
    MAGE = 2,
    RANGER = 3,
    ASSASSIN = 4,
    SWORDSMAN = 11,
    GUARDIAN = 12,
    ALCHEMIST = 21,
    ELEMENTALIST = 22,
    BARD = 31,
    MOONSHADOW = 41
}
print("[Musha] 职业常量定义完成")

-- =====================
-- 注册中文字体（暂禁用，发布后修）
--Assets = Assets or {}
--table.insert(Assets, Asset("FONT", "front/Lolita.ttf"))

-- 注册便签背景图
Assets = Assets or {}
table.insert(Assets, Asset("ATLAS", "images/musha_note_bg.xml"))
table.insert(Assets, Asset("IMAGE", "images/musha_note_bg.tex"))

-- 注册书页背景图
table.insert(Assets, Asset("ATLAS", "images/bookpage_bg.xml"))
table.insert(Assets, Asset("IMAGE", "images/bookpage_bg.tex"))
-- ★ 2026-09-25 新底板 panel_bg_alt（定稿+已授权；红叉 A/B 取证 = 映射 B 框贴合）
--   ★ 2026-09-26 旧 panel_bg.* 三件已删（用户指示；备份 _art_backup/panel_bg_old_20260926）
table.insert(Assets, Asset("ATLAS", "images/panel_bg_alt.xml"))
table.insert(Assets, Asset("IMAGE", "images/panel_bg_alt.tex"))
-- ★ 2026-09-26 叉叉关闭按钮贴图（close_button_red 抠白底版；控件层悬停 1.0↔1.24 缩放）
table.insert(Assets, Asset("ATLAS", "images/close_x.xml"))
table.insert(Assets, Asset("IMAGE", "images/close_x.tex"))
-- ★ 2026-09-26 经验条装饰框（图片/进度条.png 裁 alpha 内容框 2031×523 → exp_frame）
table.insert(Assets, Asset("ATLAS", "images/exp_frame.xml"))
table.insert(Assets, Asset("IMAGE", "images/exp_frame.tex"))
table.insert(Assets, Asset("ATLAS", "images/button_decor.xml"))
table.insert(Assets, Asset("IMAGE", "images/button_decor.tex"))
-- ★ 2026-09-28 主页任务行的淡白半透明底框（用户选 B 胶囊，预览图 图片/任务行底_预览_对照.png）
--   由 exported/_tools/art_update.py publish 生成；行里走 SetTint alpha 0.7（SSOT:1957 口径）
table.insert(Assets, Asset("ATLAS", "images/quest_row_bg.xml"))
table.insert(Assets, Asset("IMAGE", "images/quest_row_bg.tex"))
-- ★ UI 装饰元素（2026-09-21 修正）
--   这些是**互相独立的单元素图集**（每个 xml 只有一张全图 tex），不是一个合并图集。
--   之前误注册了不存在的合并图集 images/ui_elements.tex → 进世界时 assert 崩（client_log:
--   "Could not find an asset matching images/ui_elements.tex"）。已删，改注册真实存在的 4 张。
--   wechat_qr 2026-09-24 起有代码引用了（面板右下赞助入口点开收款码）→ 加进 UI_ELEMENTS 注册。
local UI_ELEMENTS = { "angel_new", "purse", "sponsor_frame", "close_button_red", "wechat_qr" }
for _, name in ipairs(UI_ELEMENTS) do
    table.insert(Assets, Asset("ATLAS", "images/" .. name .. ".xml"))
    table.insert(Assets, Asset("IMAGE", "images/" .. name .. ".tex"))
end

-- ★ 职业头像（2026-09-22）：图片\职业图标.png 是 1×3 横排（战士/剑士/近卫），
--   已切成 job_warrior / job_saber / job_guardian 三张单元素图集。
--   ⚠️ Image:SetTexture 引用 atlas 前必须在这里注册，否则 client_log 报
--   "Invalid resource handle for atlas '...job_warrior.xml'" 且贴图不显示。
--   每张图自带"战士 WARRIOR"字样，面板上不再叠职业名文字。
local JOB_ICONS = { "job_warrior", "job_saber", "job_guardian" }
for _, name in ipairs(JOB_ICONS) do
    table.insert(Assets, Asset("ATLAS", "images/" .. name .. ".xml"))
    table.insert(Assets, Asset("IMAGE", "images/" .. name .. ".tex"))
end

-- 导航图标（2026-09-13）—— 清单在 scripts/musha_nav_icons.lua（唯一真源，两处共用）
--   打包好 images/nav_xxx.tex + nav_xxx.xml（同 bookpage_bg 的做法）就往清单里留哪一行。
--   缺 tex 不会崩：面板画图标时用 pcall 兜住，只在日志里打一行。
Safe("导航图标 assets", function()
    local NAVICON = require("musha_nav_icons")
    local n = 0
    for _, def in ipairs(NAVICON) do
        table.insert(Assets, Asset("ATLAS", "images/" .. def.file .. ".xml"))
        table.insert(Assets, Asset("IMAGE", "images/" .. def.file .. ".tex"))
        n = n + 1
        -- ★ 2026-09-24 双语：英文版横幅（nav_xxx_en.tex，从 图片/UI_en.png 切）
        --   ⚠️ 这里**不能**按语言判断：本块在 L137 跑，语言加载在 L865，此时 TUNING.MUSHA_UI_LANG 还没算。
        --     两种语言的图都注册（多 6 张 ≈1MB），面板构造时才按 TUNING.MUSHA_UI_LANG 挑。
        --   没有英文版的（如 equip）def.file_en 为 nil → 只有中文版，英文玩家也用它。
        if def.file_en then
            table.insert(Assets, Asset("ATLAS", "images/" .. def.file_en .. ".xml"))
            table.insert(Assets, Asset("IMAGE", "images/" .. def.file_en .. ".tex"))
            n = n + 1
        end
    end
    print("[Musha] 导航图标 assets 注册: " .. #NAVICON .. " 行 / " .. n .. " 张（含双语）")
end)

-- ★ 2026-09-19 技能图标（用户给的 128x128）—— images/skill_icons/<技能id>.{png,xml,tex}
--   做法同导航图标：清单在 scripts/musha_skill_icons.lua（唯一真源）
--   自检：**只注册已经转好 tex/xml 的那几张**（缺的不写进 Assets，绝不 assert 崩 mod）；
--        已注册的 id 挂到 TUNING.MUSHA_SKILL_ICONS → 技能树/技能页只给这些画图标，其余退回占位
Safe("技能图标 assets", function()
    local function SoftExists(path)
        local f = rawget(_G, "softresolvefilepath")
        if f == nil then return false end
        local ok, r = pcall(f, path)
        return ok and r ~= nil
    end
    local ids = require("musha_skill_icons")
    local registered = {}
    local nreg = 0
    for _, id in ipairs(ids) do
        local xml = "images/skill_icons/" .. id .. ".xml"
        local tex = "images/skill_icons/" .. id .. ".tex"
        if SoftExists(xml) and SoftExists(tex) then
            table.insert(Assets, Asset("ATLAS", xml))
            table.insert(Assets, Asset("IMAGE", tex))
            -- ★ 2026-09-27 修（用户：技能树图标没装上）：原来是 table.insert → 存成**数组**，
            --   而唯一消费方 IconAtlas(musha_skill_tree.lua:46) 是按 T[id] **查表** → 永远查不到
            --   → 6 张图全退回占位（灰块+技能名）。改成 map（注释口径本来就是"id 挂到表上"）。
            registered[id] = true
            nreg = nreg + 1
        end
    end
    TUNING.MUSHA_SKILL_ICONS = registered
    print("[Musha] 技能图标 assets 注册: " .. nreg .. " / " .. #ids .. " 张（缺的等 Mod Tool 转 tex）")
end)

-- ★ 2026-09-20 物品图标图集：全局声明进 mod 的 Assets（清单唯一真源 scripts/musha_item_icons.lua）
--   为什么：Too Many Items(TMI+) 这类辅助 mod 是这样找物品贴图的 ——
--     ① 扫"所有启用 mod 的 mod 级 Assets"，把所有含 ".xml" 的路径收进一张表；
--     ② 拿到物品名后，用 TheSim:AtlasContains(xml路径, "<物品名>.tex") 逐个试，命中即用。
--   → 所以物品图标图集**必须在 mod 级 Assets 里声明**，
--     只在各自 prefab 的 assets 里声明，TMI 是扫不到的（图标就不显示）。
--   → 顺带好处：纯客户端也一定提前加载到这些图集。
--   规则：图标里的元素名必须 == prefab 名（musha_mailbox.xml 里得是 musha_mailbox.tex）。
--   自检：只登记 xml+tex **都真实存在**的那几套，缺的跳过（绝不往 Assets 里写不存在的文件 → 会 assert 崩 mod）。
Safe("物品图标 assets", function()
    local function SoftExists(path)
        local f = rawget(_G, "softresolvefilepath")
        if f == nil then return false end
        local ok, r = pcall(f, path)
        return ok and r ~= nil
    end
    local ids = require("musha_item_icons")
    local registered = 0
    for _, id in ipairs(ids) do
        local xml = "images/inventoryimages/" .. id .. ".xml"
        local tex = "images/inventoryimages/" .. id .. ".tex"
        if SoftExists(xml) and SoftExists(tex) then
            table.insert(Assets, Asset("ATLAS", xml))
            table.insert(Assets, Asset("IMAGE", tex))
            registered = registered + 1
        end
    end
    print("[Musha] 物品图标 assets 注册: " .. registered .. " / " .. #ids .. " 张（TMI 兼容）")
end)

-- 能量条动画（2026-09-13）—— 挂同名的 prefab assets 之外这里再声明一次，
--   保证纯客户端（别人开 musha 角色时）也一定加载到这个 build
table.insert(Assets, Asset("ANIM", "anim/energy.zip"))

-- ★ 2026-09-17 技能页"技能书锁"用的挂锁图标 = **官方技能树图集**里的 locked.tex
--   在 mod 的 Assets 里全局声明一次，保证纯客户端也有人加载过这张图集（否则 ImageButton 找不到图集会报错）
table.insert(Assets, Asset("ATLAS", "images/skilltree.xml"))

-- 剑气素材（2026-09-14）—— 全局声明，这样**每个客户端**都一定有这个 build：
--   剑气的「本地粒子」是在客户端用 CreateEntity() 直接建的（不联网，
--   照原版 FX 那套 `--[[Non-networked entity]]` 写法），那时不能再依赖
--   "某个 prefab 的 assets 恰好加载过" → 所以在这里全局挂一次。
table.insert(Assets, Asset("ANIM", "anim/slash_fx.zip"))
-- 自己的亮青月牙（2026-09-14 用户打包）—— 同上，粒子/特效在客户端本地生成时要用到这个 build
table.insert(Assets, Asset("ANIM", "anim/crescent_cyan.zip"))

-- ★ 方向图版月牙（2026-09-14 程序生成 exported/crescent_cyan/dirs/，等用户打包 anim/crescent_cyan8.zip）
--   ⚠️ **不能无条件登记**：assets 里写一个不存在的文件 → RegisterPrefabs 阶段 assert → 整个 mod 被禁。
--   所以先探一下文件在不在（softresolvefilepath 找不到只返回 nil，不 assert），在才登记。
Safe("亮青月牙方向图 assets", function()
    local f = softresolvefilepath
    if f == nil then return end
    local _, resolved = pcall(f, "anim/crescent_cyan8.zip")
    if resolved ~= nil then
        table.insert(Assets, Asset("ANIM", "anim/crescent_cyan8.zip"))
        print("[Musha] 方向图月牙 assets 已登记（anim/crescent_cyan8.zip）")
    end
end)

-- 武器绑定的技能（2026-09-14 v4）—— 右键点地释放改走【女武神战矛那套 AoE 格式】
--   做法：武器 prefab 上
--     · SetPristine **之前**加 aoetargeting（客机要读；缺它右键不进瞄准圈）
--     · 服务端加 aoespell + SetSpellFn（技能本体）
--   详见 scripts/prefabs/musha_sword.lua 里的注释块（那里写了三条硬要求 + 坑）。
--   右键流程：右键按一下 → 进瞄准圈 → 再点地面 → 出现技能名 → 释放。
--   技能数值在 scripts/musha_weapon_skill.lua 文件头（冷却 / 伤害倍率 / 命中半径 / 最大距离）。

-- 技能显示名（2026-09-14 v4）—— 原版 AoE 的那套命名格式
--   原版：ACTIONS.CASTAOE.strfn = string.upper(act.invobject.prefab)
--         → 查 STRINGS.ACTIONS.CASTAOE[<PREFAB 大写>]（表，缺项自动回 GENERIC）
--   所以每加一把带技能的武器，就在这里给它的 prefab 大写名加一行。
--   （v3 那个 CASTSPELL.stroverridefn 改名的做法已废弃：那是法杖那条路线的名字）
Safe("武器技能名(AoE)", function()
    if type(STRINGS.ACTIONS.CASTAOE) ~= "table" then
        STRINGS.ACTIONS.CASTAOE = {}          -- 理论上原版是表；不是就兜一层，免得报错
        print("[Musha] 警告：STRINGS.ACTIONS.CASTAOE 不是表，已补成空表")
    end
    local NAMES = {                            -- 语言 id 见 constants.lua 的 LANGUAGE 表
        [16] = { MUSHA_SWORD = "Удар ци" },    -- 俄
        [19] = { MUSHA_SWORD = "기검참" },      -- 韩
        [20] = { MUSHA_SWORD = "ムシャ斬り" },  -- 日
        [21] = { MUSHA_SWORD = "劍氣斬" },      -- 繁中
        [22] = { MUSHA_SWORD = "剑气斩" },      -- 简中
        [23] = { MUSHA_SWORD = "剑气斩" },      -- 简中(轨道)
    }
    local id = Profile and Profile:GetLanguageID()
    for k, v in pairs(NAMES[id] or NAMES[22]) do
        STRINGS.ACTIONS.CASTAOE[k] = v
    end
    print("[Musha] 武器技能名(AoE) 已挂上")
end)

-- 技能动作（2026-09-14 v5；v10 2026-09-14 改成可一行切换）——
--   问题：CAST AOE 默认落到 SGwilson 的 "castspell" 状态 →
--         播 staff_pre + staff（举杖念咒），而且 PerformBufferedAction 压在 53 帧（≈1.8 秒）才触发，
--         加上 69 帧才解除 busy → 手感就是"举杖举半天、技能半天不出来"。
--   做法：原版 SGwilson 的 CASTAOE handler 是按物品 tag 选状态的：
--           invobject:HasTag("aoeweapon_lunge") → "combat_lunge_start"
--           否则 → "castspell"
--         我们在 ModPostInit 后把那个 handler 的 deststate 包一层：
--         带 musha_weapon tag 的武器 → 直接走 MUSHA_AOE_CAST_STATE（见下），其它物品照原版走。
--   ★ 想换施法动作 = 只改下面这一行（都是 SGwilson 里的原版状态，行号级查证 2026-09-14）：
--       "quickcastspell"     —— atk_pre（抬手举武器）→ atk（挥出）；第 5 帧就 PerformBufferedAction，
--                               16 帧解除 busy ★ 现在用这个 = 用户要的"抬手"
--       "combat_lunge_start" —— lunge_pre → lunge_lag（前倾低扫，第 4 帧出手，无收招段）
--       "castspell"          —— staff_pre → staff（举杖念咒，53 帧才出手，1.8 秒：太慢）
--       "attack"             —— 原版平A（atk_pre → atk → atk_pst），抬手劈下，带攻击音
--       "channeling"         —— channel_loop 举手持续施法（循环，不自己结束，慎用）
--       "powerup"            —— 单帧 powerup（双手上举蓄力）
--   ⚠️ 想改成女武神那种**位移冲刺**：那要另外加 tag "aoeweapon_lunge" + 加 aoeweapon_lunge 组件
--      + 技能结束时 doer:PushEvent("combat_lunge", {...})，三样齐了才会真的冲出去（SGwilson.lua:17214+）。
--      现在故意都不加 → 只借动作，不位移。
--   ⚠️ wilson 和 wilson_client 两条都要包，否则客机预测动作不一致。
local MUSHA_AOE_CAST_STATE = "quickcastspell"
Safe("技能动作(AoE→武器动作)", function()
    local function OverrideAOEState(sg)
        local h = sg ~= nil and sg.actionhandlers ~= nil and sg.actionhandlers[ACTIONS.CASTAOE] or nil
        if h == nil or type(h.deststate) ~= "function" then return end
        local oldfns = h.deststate
        h.deststate = function(inst, action)
            local item = action ~= nil and action.invobject or nil
            if item ~= nil and item.HasTag ~= nil and item:HasTag("musha_weapon") then
                return MUSHA_AOE_CAST_STATE
            end
            return oldfns(inst, action)
        end
    end
    AddStategraphPostInit("wilson", OverrideAOEState)
    AddStategraphPostInit("wilson_client", OverrideAOEState)
    print("[Musha] 技能动作(AoE→" .. MUSHA_AOE_CAST_STATE .. ") 已挂上")
end)

-- =====================
-- 武器技能按键（F）—— ★ 2026-09-14 用户：「F 右键触发删除，采用原方式，容易误触」★
--   已停用：F 是常用键，实战里容易误碰 → 技能变成"白扣能量 + 白进冷却"。
--   现在技能**只走右键那条原版 AoE 路径**（右键 → 瞄准圈 → 点地 → 出「剑气斩」），
--   跟原版女武神战矛完全一致：见 scripts/prefabs/musha_sword.lua 的 aoetargeting / aoespell 段。
--
--   · 连带**现在没人调用、但留着备用**的东西（别顺手删）：
--       scripts/musha_weapon_skill.lua 的 WeaponSkill.CAST_KEY / ClientCast()
--       scripts/rpcs/musha_rpcs.lua 的 "musha_weapon_skill_cast" RPC
--   · 要恢复按键：把下面整块取消注释（原实现在 git 历史里也有）
-- =====================
--[[  已停用（2026-09-14）
Safe("武器技能按键", function()
    if TheNet:IsDedicated() then return end          -- 纯服务器没有客户端输入
    AddSimPostInit(function()                        -- 等 TheInput 准备好
        Safe("武器技能按键(延迟)", function()
            local WS = require("musha_weapon_skill")
            if not TheInput then return end
            TheInput:AddKeyHandler(function(key, down)
                if down then return end               -- 认按下后再松手（避免连发）
                if key ~= WS.CAST_KEY then return end
                if IsPaused() then return end
                local scr = TheFrontEnd and TheFrontEnd:GetActiveScreen()
                if scr and type(scr.name) == "string" and scr.name ~= "HUD" then return end
                local p = ThePlayer
                if not (p and p:IsValid()) then return end
                WS.ClientCast(p)
            end)
            print("[Musha] 武器技能按键已挂上")
        end)
    end)
end)
]]

-- 客户端加载字体（暂禁用，发布后修）
--if TheNet:GetIsClient() then
--    Safe("字体注册", function()
--        AddPrefabPostInit("world", function(inst)
--            if TheFrontEnd and TheFrontEnd:GetEngine() then
--                inst:DoTaskInTime(0, function()
--                    TheFrontEnd:GetEngine():LoadFont("front/Lolita.ttf", "MUSHA_FONT")
--                    print("[Musha] 字体 MUSHA_FONT 已注册")
--                end)
--            end
--        end)
--    end)
--end

-- =====================
-- 聊天命令（职业面板）
-- =====================
TRACE("[Musha TRACE] 4 - 聊天命令前")
Safe("聊天命令", function()
    modimport "scripts/commands/musha_panel"
    print("[Musha] 聊天命令已加载")
end)
TRACE("[Musha TRACE] 5 - 聊天命令后")

-- =====================
-- HUD 注册（便签 UI 等）
-- =====================
TRACE("[Musha TRACE] 6 - HUD注册前")
Safe("HUD注册", function()
    TRACE("[Musha TRACE] 6.1 - HUD modimport 开始")
    modimport "scripts/widgets/musha_note_registered"
    TRACE("[Musha TRACE] 6.2 - HUD modimport 完成")
    print("[Musha] HUD 已注册")
end)
TRACE("[Musha TRACE] 7 - HUD注册后")

-- =====================
-- 职业面板注册
-- =====================
Safe("职业面板", function()
    modimport "scripts/widgets/musha_panel_registered"
    print("[Musha] 职业面板已注册")
end)

-- =====================
-- 能量条挂载（官方挂载：挂进 widgets/statusdisplays 三围栏）
-- =====================
Safe("能量条挂载", function()
    modimport "scripts/widgets/musha_energy_registered"
    print("[Musha] 能量条已挂载")
end)

-- =====================
-- 容器参数登记（必须早于 RegisterPrefabs —— WidgetSetup 会来查 containers.params；双端都要有）
--   写法照 Musha-beta main/05.Musha_Containers.lua（本地留了一份：references/musha_beta_containers.lua）
-- =====================
Safe("容器参数", function()
    modimport "scripts/musha_containers"
end)

-- =====================
-- 注册 Prefab
-- =====================
TRACE("[Musha TRACE] 8 - PrefabFiles 前")
PrefabFiles = {"musha_rabbitbackpack", "musha_jobbook_warrior", "musha_skillbook", "musha_skillbook_saber", "musha_skill_scroll", "musha_sword", "musha_lifebranch", "musha_note", "musha", "musha_advance_altar", "musha_advance_scroll", "musha_slash_qi_fx", "musha_skill_point", "musha_crest_saber", "musha_crest_guardian", "musha_mailbox", "musha_mailbox_shadow", "musha_mailbag", "musha_mailkit_1", "musha_mailkit_2", "musha_mailkit_3", "musha_mailkit_4", "musha_recall_stone", "musha_fairy"}
-- ★ 2026-09-27 新增：musha_fairy「元素精灵」——粒子汇聚出场的胆怯精灵伙伴
--   实现：scripts/prefabs/musha_fairy.lua（本体+本地粒子+说话）+ scripts/musha_fairy_silhouette.lua（剪影落点表）
--   召唤：InitMushaPlayer 里玩家实体激活（登场/重生/下洞回来）时生成（见 MUSHA_FAIRY_ENABLED）
-- ★ 2026-09-19 新增：信箱 + 信差包（邮包系统）
--   实现：scripts/musha_mail.lua（共用）+ prefabs/musha_mailbox*.lua + prefabs/musha_mailbag.lua
--        + components/musha_mail.lua（挂玩家身上）；容器参数在 scripts/musha_containers.lua
--   升级套件（3→5→7→9→12 格，★2026-09-24 满档放开 12）：scripts/musha_mailkit.lua（共用）+ prefabs/musha_mailkit_{1..4}.lua
-- ★ 2026-09-18 新增：进阶方向徽记（就职仪式发两枚，用掉一枚 = 选定剑士/近卫方向）
-- 实现：scripts/musha_crest.lua（共用）+ scripts/prefabs/musha_crest_{saber,guardian}.lua
-- ✅ 2026-09-17 发布前：测试专用 "musha_jobbook_saber" 已从 PrefabFiles 移除
--    （3 处已处理：这里 + prefab 改名 ._bak + STRINGS 注释掉；要恢复测试把这三处改回来即可）
TRACE("[Musha TRACE] 9 - PrefabFiles 后")
print("[Musha] PrefabFiles 已设置")
TRACE("[Musha TRACE] 10 - AddModCharacter 前")

AddMinimapAtlas("images/map_icons/musha.xml")
AddModCharacter("musha", "FEMALE")
TRACE("[Musha TRACE] 11 - AddModCharacter 后")
print("[Musha] 角色注册完成")

-- =====================
-- 玩家初始化
-- =====================
TRACE("[Musha TRACE] 12 - 玩家初始化前")
Safe("玩家初始化", function()
    -- ★ 2026-09-26 兔子背包门控：只有「爱丽丝计划」mod 存在（已启用）时才发
--   口径 = 用户："只有兔子背包存在爱丽丝计划这个名字的mod时，我才能启用它"
--   检测时机 = 玩家出生发放时（运行时查 KnownModIndex，所有 mod 都已就位，不受加载顺序影响）
local function IsAlicePlanModEnabled()
    -- ★ 2026-09-27 修崩溃：KnownModIndex:GetMods 在 mod 环境不存在（实测 attempt to call nil）
    --   → 直接扫 KnownModIndex.mods 表（每项 = { modname=..., modinfo=... }）
    local mods = (KnownModIndex ~= nil and KnownModIndex.mods) or nil
    if type(mods) ~= "table" then return false end
    for _, mod in pairs(mods) do
        local mi = (type(mod) == "table" and mod.modinfo) or nil
        local nm = (mi ~= nil and mi.name) or nil
        if type(nm) == "string" and string.find(nm, "爱丽丝计划", 1, true) ~= nil then
            return true
        end
    end
    return false
end

-- ★ 2026-09-27 元素精灵（精灵伙伴）总开关：false = 一键关闭，玩家登场不再召唤精灵
--   （本体在 scripts/prefabs/musha_fairy.lua，剪影在 scripts/musha_fairy_silhouette.lua）
local MUSHA_FAIRY_ENABLED = false  -- ★ 09-28 用户：元素精灵本版先放下（0.7.12 不放出场，代码全留），下版改回 true
-- 出场冷却：防止 playeractivated 短时间重复触发导致精灵反复重新出场（秒）
local MUSHA_FAIRY_COOLDOWN = 60

local function InitMushaPlayer(inst)
        if not GLOBAL.TheWorld or not GLOBAL.TheWorld.ismastersim then
            return
        end
        TRACE("[Musha TRACE] InitMushaPlayer 触发: " .. tostring(inst))
        if not inst:HasTag("musha") then
            return
        end

        local first_time = not inst.components.musha_profession_component
        if not inst.components.musha_profession_component then
            TRACE("[Musha TRACE] InitMushaPlayer 添加组件前")
            inst:AddComponent("musha_profession_component")
            TRACE("[Musha TRACE] InitMushaPlayer + musha_profession_component")
        end
        if not inst.components.musha_quest then
            inst:AddComponent("musha_quest")
            TRACE("[Musha TRACE] InitMushaPlayer + musha_quest")
        end
        -- 局内设置（玩家级，随玩家存档）
        if not inst.components.musha_player_settings then
            inst:AddComponent("musha_player_settings")
        end

        -- 每日任务补发（首次/旧档都执行；转职任务走雕像接取）
        local q = inst.components.musha_quest
        if q and not q._musha_daily_inited then
            q._musha_daily_inited = true
            -- 每日任务数：优先"局内设置(世界级)"，其次 modinfo 配置
            local n
            local ws = GLOBAL.TheWorld and GLOBAL.TheWorld.components and GLOBAL.TheWorld.components.musha_world_settings
            if ws then
                n = ws:Get("daily_quest_count")
            end
            if type(n) ~= "number" then
                n = GetModConfigData("musha_daily_quest_count")
            end
            if type(n) == "number" and n >= 1 and n <= 10 then
                q.daily_count_override = math.floor(n)
            end
            inst:DoTaskInTime(1, function()
                if q and q.inst and q.inst:IsValid() then
                    q:OnNewDay()
                    print("[Musha] 每日任务已发放:", #q.daily_quests)
                end
            end)
        end
        -- 信箱 / 信差包（2026-09-19）：邮包系统挂在玩家身上
        if not inst.components.musha_mail then
            inst:AddComponent("musha_mail")
            TRACE("[Musha TRACE] InitMushaPlayer + musha_mail")
        end
        -- ★ 2026-09-26 兔子背包：出生自带（8 格）——门控 = 「爱丽丝计划」mod 在位才发
        -- ★ 2026-09-27 兔子背包：改 **15 天发放**（游戏天数 ≥15 发一次；标记存 musha_mail 组件存档）
        if IsAlicePlanModEnabled() then
            local mail = inst.components.musha_mail
            if mail ~= nil and not mail.musha_rabbitpack_granted then
                inst:ListenForEvent("cycleschanged", function(world)
                    if not inst:IsValid() then return end
                    if TheWorld == nil or TheWorld.state.cycles < 15 then return end
                    local pack = SpawnPrefab("musha_rabbitbackpack")
                    if pack ~= nil then
                        if inst.components.inventory ~= nil then
                            inst.components.inventory:GiveItem(pack)
                        end
                        mail.musha_rabbitpack_granted = true
                        print("[Musha] 兔子背包已发放（游戏天数 ≥15 · 爱丽丝计划在位）")
                    end
                end, TheWorld)
            end
        end
        -- ★ 2026-09-27 元素精灵（精灵伙伴）：登场 / 重生 / 下洞穴回来 / 死亡复活 → 自动出场
        --   20 格内随机出生 → 光点汇聚拼形（客户端本地粒子）→ 飘向玩家害羞跟随
        --   新手期（职业 ≤1 级）见面会冒字打招呼 + 引导职业（台词在 prefab 的 FAIRY_LINES）
        --   冷却 / 开关见上面 MUSHA_FAIRY_*；同一玩家永远只有一只（先清旧的再召新的）
        if MUSHA_FAIRY_ENABLED then
            -- 清掉旧精灵（重生 / 死亡时用；精灵不进存档，本来就是「每场一换」）
            local function RemoveFairy(ply)
                if ply._musha_fairy ~= nil then
                    if ply._musha_fairy:IsValid() then
                        ply._musha_fairy:Remove()
                    end
                    ply._musha_fairy = nil
                end
            end
            -- 召唤：20 格内随机出生 → 绑主人（prefab 里走 musha_fairy_bind 事件接手）
            local function SummonFairy(ply)
                if not ply:IsValid() then return end
                local now = GLOBAL.GetTime()
                -- 冷却：防 playeractivated 短时间重复触发；死亡重生走直通（清冷却）
                if ply._musha_fairy_last ~= nil and now - ply._musha_fairy_last < MUSHA_FAIRY_COOLDOWN then
                    return
                end
                ply._musha_fairy_last = now
                RemoveFairy(ply)
                local x, y, z = ply.Transform:GetWorldPosition()
                local ang = math.random() * 2 * math.pi
                local r = 10 + math.random() * 8   -- 20 格内随机出生（含 10~18 格）
                local fairy = SpawnPrefab("musha_fairy")
                if fairy ~= nil then
                    fairy.Transform:SetPosition(x + math.cos(ang) * r, 0.7, z + math.sin(ang) * r)
                    fairy:PushEvent("musha_fairy_bind", { leader = ply })
                    ply._musha_fairy = fairy
                    TRACE("[Musha] 元素精灵已出场（距玩家 " .. string.format("%.1f", r) .. " 格）")
                end
            end
            inst:ListenForEvent("playeractivated", SummonFairy)          -- 登场 / 读档 / 下洞回来
            inst:ListenForEvent("respawnfromghost", function(ply)        -- 死亡复活：精灵重新出场
                if ply ~= nil then ply._musha_fairy_last = nil end
                SummonFairy(ply)
            end)
            inst:ListenForEvent("death", function(ply)                   -- 死亡：元素精灵受惊消散
                RemoveFairy(ply)
            end)
        end
        print("[Musha] 玩家组件已添加: " .. tostring(inst) .. " (first=" .. tostring(first_time) .. ")")
    end
    AddPrefabPostInit("musha", InitMushaPlayer)
    TRACE("[Musha TRACE] 12.5 - AddPrefabPostInit('musha') 已注册")

    -- ★ 2026-09-19 邮包系统：**所有玩家**都挂（不只 musha），否则客机/其他角色摸信箱摸不动
    -- ★ 2026-09-20 用户定案：信差包 = **出生自带**（跟便签一套：prefabs/musha.lua 的 starting_inventory），
    --   所以这里不自动发；没包的人（老玩家 / 死了丢了）= 走配方合成，想要的人让 musha 给他做。
    --   下面这套是**全服自动补发**的备用开关（一人一次：标记存 musha_mail 的存档字段 starter_bag，
    --   老存档没这字段会补发一次）；当前 false = 谁也不发。
    local GIVE_STARTER_MAILBAG = false

    local function InitMushaMail(inst)
        if inst.components.musha_mail == nil then
            inst:AddComponent("musha_mail")
        end
        -- ★ 客机进游戏时拉一次职业数据：
        --   光标上的动作名（触摸/触摸（绑定）/触摸（打开）/升级）读的是客户端的 cached_data，
        --   之前只有"开一次 musha 面板"才会推 → 重进世界后动作名会一直显示成旧状态。
        --   这里开局拉一次，绑定状态当场就是准的。（没有职业组件的角色忽略）
        if TheNet ~= nil and TheNet:GetIsClient() and inst == ThePlayer then
            inst:DoTaskInTime(2, function()
                if inst == nil or not inst:IsValid() then return end
                pcall(function()
                    local rpc = GetModRPC("musha", "musha_request_settings")
                    if rpc ~= nil then SendModRPCToServer(rpc) end
                end)
            end)
        end
        if not GIVE_STARTER_MAILBAG then return end
        -- 延迟 0.5s：玩家实体读档时组件的 OnLoad 在构造之后才跑，等它跑完再判"有没有发过"
        inst:DoTaskInTime(0.5, function()
            if inst == nil or not inst:IsValid() then return end
            if not TheWorld.ismastersim then return end
            local mc = inst.components.musha_mail
            if mc ~= nil and mc.GrantStarterBag ~= nil then
                pcall(function() mc:GrantStarterBag() end)
            end
        end)
    end
    AddPlayerPostInit(InitMushaMail)
    TRACE("[Musha TRACE] 12.7 - AddPlayerPostInit(musha_mail) 已注册")

    -- 世界级设置组件（随世界存档走）：世界 prefab 创建时就挂，
    -- 保证组件在存档 Load 阶段已存在，OnSave/OnLoad 才生效
    local function AddWorldSettings(inst)
        if inst.components.musha_world_settings == nil then
            inst:AddComponent("musha_world_settings")
        end
    end
    AddPrefabPostInit("world", AddWorldSettings)
    AddPrefabPostInit("forest", AddWorldSettings)
    AddPrefabPostInit("cave", AddWorldSettings)
    TRACE("[Musha TRACE] 12.6 - musha_world_settings 世界挂载已注册")
end)
TRACE("[Musha TRACE] 13 - 玩家初始化后")

-- =====================
-- 职业武器配方
-- =====================
TRACE("[Musha TRACE] 14 - 武器配方前")
-- ★ 2026-09-16 用户拍板「不给剑配方」→ 整块注册取消（表留空，方便以后想给再加回来）
--   注：旧代码那行配方写的是 Ingredient("ruby", 4) —— 原版没有 ruby 这个东西（原版是 redgem），
--       所以就算留着也永远点不出来。要恢复的话记得把材料名改对。
local JOB_WEAPONS = {
    -- [1] = { prefab = "musha_sword", recipe = {Ingredient("redgem", 4)}, tech = GLOBAL.TECH.SCIENCE_ONE },
}

for _, def in pairs(JOB_WEAPONS) do
    AddRecipe2(def.prefab, def.recipe, def.tech, {
        atlas = "images/inventoryimages/" .. def.prefab .. ".xml",
        image = def.prefab .. ".tex"
    })
end
print("[Musha] 武器配方已注册（当前 0 条：用户要求不给剑配方）")

-- =====================
-- 转职建筑（进阶祭坛）配方 —— 方案 A（用户 2026-09-12 拍板）
--   石块12 + 木头8 + 金块6 + 硝石2 ｜ 科学机器解锁 ｜ 挖矿砍树顺手就有（5 天内绝对够）
--   ✅ 图标已补：images/inventoryimages/musha_advance_altar.png（2026-09-20，祭坛本体缩的 64²）
--   placer 在 scripts/prefabs/musha_advance_altar.lua 里 MakePlacer 生成
-- =====================
AddRecipe2("musha_advance_altar",
    {
        Ingredient("rocks", 12),
        Ingredient("log", 8),
        Ingredient("goldnugget", 6),
        Ingredient("nitre", 2),
    },
    GLOBAL.TECH.SCIENCE_ONE,
    {
        placer = "musha_advance_altar_placer",
        min_spacing = 3,
        atlas = "images/inventoryimages/musha_advance_altar.xml",   -- ★ 2026-09-20 换成真祭坛图标
        image = "musha_advance_altar.tex",                            --   （旧占位 musha_note 已作废）
        builder_tag = "musha",
    },
    { "CHARACTER" })
print("[Musha] 酒馆配方已注册（石块12+木头8+金块6+硝石2 / 科学机器）")

-- =====================
-- 信箱配方（2026-09-19，邮包系统）—— 材料我拍的，用户还没定，随时改
--   木板4 + 草8 + 金块2 ｜ 科学机器 ｜ placer 在 prefabs/musha_mailbox.lua 里生成
--   ✅ 图标已补（2026-09-20）：images/inventoryimages/musha_mailbox.png（信箱本体缩的 64²）
-- =====================
AddRecipe2("musha_mailbox",
    {
        Ingredient("boards", 4),
        Ingredient("cutgrass", 8),
        Ingredient("goldnugget", 2),
    },
    GLOBAL.TECH.SCIENCE_ONE,
    {
        placer = "musha_mailbox_placer",
        min_spacing = 2,
        atlas = "images/inventoryimages/musha_mailbox.xml",   -- ★ 2026-09-20 真信箱图标（旧 papyrus 占位作废）
        image = "musha_mailbox.tex",
        builder_tag = "musha",
    },
    { "CHARACTER" })
-- =====================
-- 信差包配方（★ 2026-09-20 用户问"配方给了吗" → 之前**根本没有配方**，包只能靠送）
--   草8 + 木板2 + 蜘蛛丝2 ｜ 科学机器 ｜ CHARACTER 页
--   材料是拍的（和信箱同一档"手边就有"），要改就改这几行
--   没加 builder_tag → 谁都能做（邮包系统对所有玩家开放）；要像信箱那样只让 musha 做，加回 builder_tag = "musha"
-- =====================
AddRecipe2("musha_mailbag",
    {
        Ingredient("cutgrass", 8),
        Ingredient("boards", 2),
        Ingredient("silk", 2),
    },
    GLOBAL.TECH.SCIENCE_ONE,
    {
        atlas = "images/inventoryimages/musha_mailbag.xml",
        image = "musha_mailbag.tex",
    },
    { "CHARACTER" })
print("[Musha] 信差包配方已注册（草8+木板2+蜘蛛丝2 / 科学机器 / 谁都能做）")

print("[Musha] 信箱配方已注册（木板4+草8+金块2 / 科学机器；图标已换真信箱图）")

-- =====================
-- 邮包升级套件配方（2026-09-19）—— 用户拍板"做成套件，拿着它右键信箱 = 升级"
--   消耗表来自用户：5 木板 → 10 木板 → 20 木板 → 20 木板 + 2 宝石
--   （木板到 20 封顶，之后每档额外加 2 颗宝石）
--   ★ 2026-09-20 用户拍板：最后一档直接给 12（KITS step4 to=12，12 格全可用；旧口径"第12格以后做/最高11"作废）
--   ⚠️ 图标/地上贴图暂无 → 借原版莎草纸占位（见 musha_mailkit.lua 的素材自检）
-- =====================
local MAILKIT_RECIPES = {
    { "musha_mailkit_1", { Ingredient("boards", 5) },                      GLOBAL.TECH.SCIENCE_ONE },
    { "musha_mailkit_2", { Ingredient("boards", 10) },                     GLOBAL.TECH.SCIENCE_ONE },
    { "musha_mailkit_3", { Ingredient("boards", 20) },                     GLOBAL.TECH.SCIENCE_ONE },
    { "musha_mailkit_4", { Ingredient("boards", 20), Ingredient("redgem", 2) }, GLOBAL.TECH.SCIENCE_TWO },
}
for _, def in ipairs(MAILKIT_RECIPES) do
    AddRecipe2(def[1], def[2], def[3], {
        atlas = "images/inventoryimages.xml",
        image = "papyrus.tex",
        builder_tag = "musha",
    }, { "CHARACTER" })
end
print("[Musha] 邮包升级套件配方已注册（木板5 / 10 / 20 / 20+红宝石2）")

-- =====================
-- 基础职业书配方（一转前置）—— 用户 2026-09-12：8 个草
--   0 级即可造（无科技门槛）= 一转的入口；书不消耗、可反复用
--   老存档同理：旧版本转职时书被吃掉 → 现在 8 个草自己造一本就行（不再自动补发）
--   ⚠️ 目前只有战士那本 prefab；法师/游侠/刺客做出来时照着加
-- =====================
AddRecipe2("musha_jobbook_warrior",
    { Ingredient("cutgrass", 8) },
    GLOBAL.TECH.NONE,
    {
        atlas = "images/inventoryimages/musha_jobbook_warrior.xml",
        image = "musha_jobbook_warrior.tex",
        builder_tag = "musha",
    },
    { "CHARACTER" })
print("[Musha] 基础职业书配方已注册（草 x8）")

-- =====================
-- 技能卷轴配方（2026-09-17）—— 普通技能学习道具
--   用户口径：「技能卷轴是普通技能学习专用的，大部分时候可制作 或 可掉落；
--             珍惜技能 = boss 掉落」→ 这张配方只覆盖**普通技能**那条线
--   材料：莎草纸×2 + 蜘蛛丝×2（科学机器；都属于"5 天内能凑齐"的档位）
--   ⚠️ 图标：专属 tex（images/inventoryimages/musha_skill_scroll.tex）还没转出来 →
--      先用原版莎草纸图标占位；等 Mod Tool 转好、文件一到位，这里**自动**切到专属图标（不用改代码）
--   TODO（未做）：珍惜技能掉落表（boss 掉落；美术参考 图片/珍惜技能.png）
-- =====================
local function MushaAssetExists(path)
    local f = GLOBAL.softresolvefilepath
    if f == nil then return false end
    local ok, r = pcall(f, path)
    return ok and r ~= nil
end

local SKILL_SCROLL_ICON = MushaAssetExists("images/inventoryimages/musha_skill_scroll.xml")
    and { atlas = "images/inventoryimages/musha_skill_scroll.xml", image = "musha_skill_scroll.tex" }
    or  { atlas = "images/inventoryimages.xml",                    image = "papyrus.tex" }

AddRecipe2("musha_skill_scroll",
    {
        Ingredient("papyrus", 2),
        Ingredient("silk", 2),
    },
    GLOBAL.TECH.SCIENCE_ONE,
    {
        atlas = SKILL_SCROLL_ICON.atlas,
        image = SKILL_SCROLL_ICON.image,
        builder_tag = "musha",
    },
    { "CHARACTER" })
print("[Musha] 技能卷轴配方已注册（莎草纸x2+蜘蛛丝x2 / 科学机器）")

-- =====================
-- 回城石配方（★ 2026-09-20 用户需求）
--   用户原话："配方 绿宝石或者红宝石 + 2 个金子，其余的写任意"
--   · "或者"怎么实现：DST 的合成原料是**按 prefab 名精确匹配**的
--     （Container:GetCraftingIngredient 是 `v.prefab == item`，不吃 tag）→ 不能写"任一宝石"
--     ⇒ 做成**两条配方**：红宝石版 + 绿宝石版，两条都产出 musha_recall_stone
--       （第二条靠 config.product 覆盖产物，见 recipe.lua:98 `self.product = product or name`）
--   · "其余的写任意"→ 我挑的：石头 x10（基础料）+ 炼金引擎（有宝石的东西放二本）
--   · 没加 builder_tag → 谁都能做（要只让 musha 做，加 builder_tag = "musha"）
--   图标：专属图还没出 → 先借原版红宝石图标（images/inventoryimages.xml / redgem.tex）
-- =====================
local RECALL_ICON = MushaAssetExists("images/inventoryimages/musha_recall_stone.xml")
    and { atlas = "images/inventoryimages/musha_recall_stone.xml", image = "musha_recall_stone.tex" }
    or  { atlas = "images/inventoryimages.xml",                    image = "redgem.tex" }

AddRecipe2("musha_recall_stone",
    {
        Ingredient("redgem", 1),
        Ingredient("goldnugget", 2),
        Ingredient("rocks", 10),
    },
    GLOBAL.TECH.SCIENCE_TWO,
    {
        atlas = RECALL_ICON.atlas,
        image = RECALL_ICON.image,
    },
    { "CHARACTER" })

AddRecipe2("musha_recall_stone_green",
    {
        Ingredient("greengem", 1),
        Ingredient("goldnugget", 2),
        Ingredient("rocks", 10),
    },
    GLOBAL.TECH.SCIENCE_TWO,
    {
        product = "musha_recall_stone",        -- ★ 产物还是回城石（recipe.lua:98 支持）
        atlas = RECALL_ICON.atlas,
        image = RECALL_ICON.image,
    },
    { "CHARACTER" })
print("[Musha] 回城石配方已注册（红宝石x1 或 绿宝石x1 + 金块x2 + 石头x10 / 炼金引擎 / 谁都能做）")

TRACE("[Musha TRACE] 15 - 武器配方后/任务收集前")
-- =====================
-- 任务收集监听
-- =====================
TRACE("[Musha TRACE] 16 - 噩梦燃料监听前")
Safe("噩梦燃料监听", function()
    AddPrefabPostInit("nightmarefuel", function(inst)
        if not TheWorld or not TheWorld.ismastersim then
            return
        end
        local old = inst.components.inventoryitem.onputininventoryfn
        inst.components.inventoryitem:SetOnPutInInventoryFn(function(inst, owner)
            if owner and owner:IsValid() then
                owner:PushEvent("musha_item_collected", {
                    prefab = "nightmarefuel",
                    -- ★ 2026-09-12：带上堆叠数，否则一次捡一堆也只算 1 个
                    count = (inst.components.stackable and inst.components.stackable:StackSize()) or 1,
                })
            end
            if old then
                old(inst, owner)
            end
        end)
    end)
end)

Safe("宝石收集监听", function()
    -- ★★ 2026-09-16 修「收集三色宝石 任务永远不完成」的**根因**：
    --   这里原来写的是 ruby / emerald / sapphire —— **原版根本没有这三个 prefab**
    --   （原版宝石叫 redgem / greengem / bluegem，另有 purplegem / orangegem / yellowgem）。
    --   AddPrefabPostInit 对不存在的 prefab 不报错、只是永远不触发 → 钩子静默失效 → 任务进度永远是 0/3。
    for _, gem_prefab in ipairs({"redgem", "greengem", "bluegem"}) do
        AddPrefabPostInit(gem_prefab, function(inst)
            if not TheWorld or not TheWorld.ismastersim then
                return
            end
            local old = inst.components.inventoryitem.onputininventoryfn
            inst.components.inventoryitem:SetOnPutInInventoryFn(function(inst, owner)
                if owner and owner:IsValid() then
                    owner:PushEvent("musha_item_collected", {
                        prefab = gem_prefab,
                        -- ★ 2026-09-12：带上堆叠数（宝石同理）
                        count = (inst.components.stackable and inst.components.stackable:StackSize()) or 1,
                    })
                end
                if old then
                    old(inst, owner)
                end
            end)
        end)
    end
end)

AddComponentPostInit("stewer", function(self)
    local oldHarvest = self.Harvest
    self.Harvest = function(self, harvester, ...)
        -- ★ 2026-09-12：先记下"锅里确实有做好的菜"—— oldHarvest 里会把 done/product 清掉。
        --   原来不管锅是空是满、只要点了就加 10 经验 → 对着空锅连点就能刷经验（真 bug）。
        local had_food = (self.done and self.product ~= nil)
        local ret = oldHarvest and oldHarvest(self, harvester, ...)
        if had_food and harvester and harvester:IsValid() and harvester:HasTag("musha") then
            local pc = harvester.components.musha_profession_component
            if pc then
                pc:AddExp(10)
            end
            -- 任务计数：musha_quest 监听的就是这个事件（原来那边监听 "harvest"，对不上 → 任务不计数）
            harvester:PushEvent("musha_cookpot_harvest", {
                action = "pick"
            })
        end
        return ret
    end
end)

-- =====================
-- 发现检测
-- =====================
TRACE("[Musha TRACE] 17 - 发现检测前")
Safe("发现检测", function()
    AddPlayerPostInit(function(inst)
        if not GLOBAL.TheWorld or not GLOBAL.TheWorld.ismastersim then
            return
        end

        -- ★ 2026-09-13 重写（用户报「见到龙蝇 没效果」）：
        --   旧代码三个问题：
        --   ① `inst._musha_discovered_xxx` 是"一辈子只触发一次"的标记且**从不清除** →
        --      玩家一开始在别处路过龙蝇/格罗姆时标记就被打上了，等任务真抽到它时反而永远不再触发（主因）
        --   ② 海象那条查的是 tag "walrus"（海象 NPC），但**海象营地 prefab 叫 "walrus_camp"，不带 "walrus" 标签**
        --      → 营地一直在那儿也不会算（而且海象只在冬天出现）
        --   ③ 龙蝇/格罗姆有同名 tag 所以能查到，但"Once 标记"让它们照样失灵
        --   新逻辑：每 5 秒扫一次周围 30 格，按**prefab 名**认（比 tag 可靠），
        --   标记**每天重置**（发现类任务本来就隔日作废），所以站着不动换天也能重新判到
        local function ResetDiscoverFlags()
            inst._musha_discovered_dragonfly = nil
            inst._musha_discovered_glommer = nil
            inst._musha_discovered_walrus = nil
        end
        inst:WatchWorldState("startday", ResetDiscoverFlags)

        inst:DoPeriodicTask(5, function()
            local quest = inst.components.musha_quest
            if not quest then
                return
            end

            local x, y, z = inst.Transform:GetWorldPosition()
            local found = TheSim:FindEntities(x, y, z, 30, nil, { "INLIMBO", "FX", "NOCLICK" })

            for _, e in ipairs(found) do
                local pf = e.prefab
                if pf == "dragonfly" and not inst._musha_discovered_dragonfly then
                    inst._musha_discovered_dragonfly = true
                    quest:OnDiscovered("dragonfly")
                elseif pf == "glommer" and not inst._musha_discovered_glommer then
                    inst._musha_discovered_glommer = true
                    quest:OnDiscovered("glommer")
                elseif (pf == "walrus_camp" or pf == "walrus") and not inst._musha_discovered_walrus then
                    inst._musha_discovered_walrus = true
                    quest:OnDiscovered("walrus")
                end
            end
        end)
    end)
end)

-- =====================
-- 多语言
-- =====================
TRACE("[Musha TRACE] 18 - 语言加载前")
Safe("语言加载", function()
    local loc = Profile and Profile:GetLanguageID()
    if loc == 21 or loc == 22 or loc == 23 then
        modimport "scripts/languages/chinese.lua"
    else
        modimport "scripts/languages/english.lua"
    end
    print("[Musha] 语言文件已加载")

    -- 🐛 2026-09-13 修复：角色台词文件此前**从未被加载**
    --   AddModCharacter 不会自动加载台词（DST 只对原版角色 require speech_xxx），
    --   所以 scripts/speech_musha_*.lua（4 份、约 6500 行）一直是死文件，
    --   Musha 说的全是 GENERIC 的台词。这里按语言挂上去。
    --   语言 id：16=RUSSIAN 19=KOREAN 20=JAPANESE 21=CHINESE_T 22=CHINESE_S 23=CHINESE_S_RAIL
    local suffix = "en"
    if loc == 21 or loc == 22 or loc == 23 then
        suffix = "zh"
    elseif loc == 19 then
        suffix = "ko"
    elseif loc == 16 then
        suffix = "ru"
    elseif loc == 20 then
        suffix = "jp"
    end
    local ok, speech = pcall(require, "speech_musha_" .. suffix)
    if ok and type(speech) == "table" then
        STRINGS.CHARACTERS.MUSHA = speech
        print("[Musha] 台词已挂载: speech_musha_" .. suffix)
    else
        -- 兜底：该语言没有台词文件时退回英文，避免未挂载
        local ok2, speech_en = pcall(require, "speech_musha_en")
        if ok2 and type(speech_en) == "table" then
            STRINGS.CHARACTERS.MUSHA = speech_en
        end
        print("[Musha] 台词文件缺失，已回退英文: speech_musha_" .. suffix)
    end

    -- ★ 2026-09-24 双语导航：把语言后缀挂 TUNING，面板构造时读它选 zh/en 两套导航横幅
    --   （suffix 上面是 local，面板 require 不到；挂 TUNING 是本 mod 既有约定，见 168 行）
    TUNING.MUSHA_UI_LANG = suffix
    print("[Musha] UI 语言 = " .. tostring(suffix) .. " (language id=" .. tostring(loc) .. ")")
end)

-- =====================
-- 技能数据
-- =====================
TRACE("[Musha TRACE] 18.5 - 技能数据加载前")
Safe("技能数据", function()
    modimport "scripts/skills/musha_skill_data"
    print("[Musha] 技能数据已加载")
end)

-- =====================
-- 动作注册
-- =====================
TRACE("[Musha TRACE] 19 - 动作注册前")
Safe("动作注册", function()
    modimport "scripts/actions/musha_actions"
    print("[Musha] 动作注册已加载")
end)

-- =====================
-- RPC 注册
-- =====================
TRACE("[Musha TRACE] 19.5 - RPC 注册前")
Safe("RPC注册", function()
    modimport "scripts/rpcs/musha_rpcs"
    print("[Musha] RPC 注册已加载")
end)

-- =====================
-- 客机复制组件注册（必须在所有 AddComponent 之后）
-- 缺这行 → 客户端没有 replica，面板 owner.replica.musha_profession_component 恒 nil → 不显示
-- =====================
TRACE("[Musha TRACE] 19.6 - 客机复制组件注册前")
Safe("复制组件", function()
    AddReplicableComponent("musha_profession_component")
    print("[Musha] 客机复制组件已注册: musha_profession_component")
end)

-- =====================
-- 进阶祭坛（2026-09-08 占位 → 09-12 独立 prefab → 09-17 仪式化：打开祭坛取卷轴）
-- 实体 + 容器 + 开坛动作：scripts/prefabs/musha_advance_altar.lua（都在建筑自己身上）
-- 容器参数表：scripts/musha_containers.lua（写法照 Musha-beta main/05.Musha_Containers.lua）
--
-- ★ 2026-09-17 交互链改版（用户要求"多走一步、仪式感"）：
--   旧：右键祭坛 → 直接接取转职任务（一碰就到手）
--   新：右键祭坛 → 动作 MUSHA_OPEN_ALTAR（"打开酒馆"）→ musha_action:InteractScene（祭坛 prefab 里绑的）
--        → 打开【祭坛容器】（1 格）→ 里面躺着 1 卷【转职卷轴 musha_advance_scroll】
--        → 玩家把卷轴拿出来 → 右键卷轴（MUSHA_UNROLL_SCROLL "展开卷轴"）→ 才接取本轮任务
--   本段只留"后厨"：跨文件的补卷函数 / 接取函数（挂 GLOBAL，给 prefab 那边调）
--   容器补卷规则：空坛 + 玩家【有基础职业 / 未进阶 / 身上没有没用掉的卷轴 / 无在跑任务】→ 补 1 卷
-- =====================
TRACE("[Musha TRACE] 20.6 - 酒馆绑定前")
Safe("酒馆占位", function()
    local BASE_TO_ADVANCE = {
        warrior = "saber",   -- 战士 → 剑士（多目标职业选择后续做）
        mage = "alchemist",
        ranger = "bard",
        assassin = "moonshadow",
        rogue = "moonshadow",
    }

    -- 从任务池抽 count 个，跳过 heal_skill（技能系统暂 .bak 未启用）
    local function PickAdvanceQuests(pool_index, count)
        local pool = rawget(GLOBAL, "MUSHA_QUEST_POOLS")
        local templates = rawget(GLOBAL, "MUSHA_QUEST_TYPES")
        if not pool or not templates then return {} end
        local bucket = {}
        for _, id in ipairs(pool[pool_index] or {}) do
            local skip = false
            for _, t in ipairs(templates) do
                if t.id == id and t.type == "heal_skill" then
                    skip = true
                    break
                end
            end
            if not skip then
                table.insert(bucket, id)
            end
        end
        -- 打乱
        for i = #bucket, 2, -1 do
            local j = math.random(i)
            bucket[i], bucket[j] = bucket[j], bucket[i]
        end
        local out = {}
        for i = 1, math.min(count, #bucket) do
            table.insert(out, bucket[i])
        end
        return out
    end

    local function Say(doer, msg, t)
        if doer ~= nil and doer:IsValid() and doer.components.talker then
            doer.components.talker:Say(msg, t or 3)
        end
    end

    -- 能不能进阶 + 进阶目标（职业侧判断，开坛补卷轴 / 展开卷轴 共用同一套）
    local function GetAdvanceTarget(doer)
        local pc = doer.components.musha_profession_component
        if not pc then
            return nil, "Musha 职业系统未就绪。"
        end
        local base = pc:GetCarrer_base()
        if not base then
            return nil, "还没有职业，先去使用职业书转职吧！"
        end
        if pc:GetCarrer_special() or (pc.userdata and pc.userdata.has_advanced) then
            return nil, "已经完成进阶了！"
        end
        local target = BASE_TO_ADVANCE[base]
        if not target then
            return nil, "当前职业暂无可进阶方向。"
        end
        return target
    end

    -- 玩家身上（背包）还有没展开的卷轴吗？→ 防止重复补卷
    --   ⚠️ Inventory:FindItem(fn) 收的是**判断函数**，不是 prefab 名字符串（原版 inventory.lua:623）
    local function HasScrollOnPerson(doer)
        local inv = doer.components.inventory
        if inv == nil then return false end
        return inv:FindItem(function(item)
            return item ~= nil and item.prefab == "musha_advance_scroll"
        end) ~= nil
    end

    -- ★ 打开祭坛时"发现里面的卷轴"：空坛 + 够资格 → 坛里补 1 卷
    --   ⚠️ onopenfn 的第 2 个参数是 { doer = doer } 这张表，不是 doer 本人（原版 container.lua:659）
    local function RefillAltarScroll(inst, doer)
        local c = inst.components.container
        if c == nil or doer == nil or not doer:IsValid() then return end
        if not c:IsEmpty() then return end            -- 坛里已经有一卷了
        -- ★ 2026-09-17 用户：「主动去转职…起码保证祂是满的」→ 撤掉"手上有卷就不补"这道闸
        --   （它最容易造成"莫名其妙空坛"；函数 HasScrollOnPerson 留着，想恢复把下一行取消注释）
        -- if HasScrollOnPerson(doer) then return end
        local target, reason = GetAdvanceTarget(doer)
        if target == nil then
            Say(doer, reason, 3)                      -- 还没一转 / 已进阶 / 无方向 → 空坛 + 说明
            return
        end
        local quest = doer.components.musha_quest
        if quest == nil then return end
        -- ★ 2026-09-17 就职仪式待办中：坛里不再补卷（这次右键应该是在做仪式，先完成它）
        if quest.advance_ceremony_pending then
            Say(doer, "酒馆在等你的就职仪式——去完成它。", 4)
            return
        end
        -- ★ 2026-09-17 同理由：手头有在跑的转职任务也照样补卷（真去接取时会被 AcceptAdvanceQuest
        --   挡下并给台词，且**失败不消耗卷轴**）→ 坛子始终是满的，不再出现"空坛不解释"
        -- if quest.advance_quest ~= nil and not quest.advance_quest.done then
        --     Say(doer, "酒馆里空空如也——先完成手头的转职任务（第 " .. tostring(quest.advance_round or 1) .. "/3 轮）。", 4)
        --     return
        -- end
        local scroll = SpawnPrefab("musha_advance_scroll")
        if scroll ~= nil then
            c:GiveItem(scroll)
            Say(doer, "酒馆深处，一卷古老的卷轴静静躺在那里……", 4)
            print("[Musha] 酒馆补入转职卷轴 → " .. tostring(doer))
        end
    end

    -- ★ 开坛补卷入口（scripts/prefabs/musha_advance_altar.lua 里 container.onopenfn 调这个）
    --   容器 + 开/关动作都在祭坛自己的 prefab 上（照 Musha-beta 的写法），这里只给它一个"后厨"函数
    --   ⚠️ 必须挂 TUNING，**不能挂 GLOBAL**：prefab 环境里 `GLOBAL` 是未声明的全局，
    --      一读就被 scripts/strict.lua 抛 "variable 'GLOBAL' is not declared"（2026-09-17 实测崩过）
    TUNING.MUSHA_ALTAR_REFILL = RefillAltarScroll

    -- ★ 接取入口（scripts/prefabs/musha_advance_scroll.lua 的"展开卷轴"调这个）
    --   返回 true = 已接取（调用方消耗卷轴）；false = 不消耗（原因已由台词说明）
    --   ⚠️ 挂 TUNING 不挂 GLOBAL，原因同上（prefab 读 GLOBAL 会被 strict.lua 抛错）
    TUNING.MUSHA_ALTAR_USE_SCROLL = function(doer)
        if doer == nil or not doer:IsValid() then return false end
        local target, reason = GetAdvanceTarget(doer)
        if target == nil then
            Say(doer, reason, 3)
            return false
        end
        local quest = doer.components.musha_quest
        if quest == nil then
            Say(doer, "任务系统未就绪。", 3)
            return false
        end
        -- 等级门槛 / 重复接取 等判断都在 AcceptAdvanceQuest 里（单一来源，别在这重复写一套）
        local ok, why = quest:AcceptAdvanceQuest(target)
        if not ok then
            Say(doer, why or "暂无法接取。", 3)
            return false
        end
        return true
    end

    -- 祭坛的实体侧（tag / musha_action / container / 开坛动作）全部在 prefab 文件里：
    --   scripts/prefabs/musha_advance_altar.lua
    --   （2026-09-17 用户拍板：容器组件加在"自身的建筑"上，不再由 modmain 的 AddPrefabPostInit 外挂）
    --   参数表在 scripts/musha_containers.lua（写法照 Musha-beta main/05.Musha_Containers.lua）
    --
    -- ⚠️ 旧占位兼容（statuemaxwell 麦斯威尔雕像当祭坛）**已删除**：
    --    容器不能挂在别人家建筑上；老存档里那座雕像现在就是普通雕像，重新打造一座进阶祭坛即可。
end)
TRACE("[Musha TRACE] 20.7 - 酒馆占位后")

-- =====================
-- 背刺判定 (Assassin Backstab)
-- =====================
TRACE("[Musha TRACE] 20.5 - 背刺Hook前")

-- 判断攻击者是否在目标的背后
local function IsBehindTarget(attacker, target)
    if not target or not target.Transform or not attacker.Transform then
        return false
    end
    local tx, _, tz = target.Transform:GetWorldPosition()
    local ax, _, az = attacker.Transform:GetWorldPosition()
    local dx, dz = ax - tx, az - tz
    if dx == 0 and dz == 0 then
        return false
    end
    -- 目标朝向向量 (DST 坐标系统: 旋转角→方向)
    local rot = target.Transform:GetRotation()
    local rad = rot * (math.pi / 180)
    local fx, fz = math.sin(rad), -math.cos(rad)
    -- 点积: < 0 = 在背后
    local dist = math.sqrt(dx * dx + dz * dz)
    local dot = (fx * dx + fz * dz) / dist
    return dot < -0.3 -- 约107度开角
end

Safe("背刺Hook", function()
    local Combat = GLOBAL.require("components/combat")
    if not Combat then
        print("[Musha] Combat 组件未找到，跳过背刺Hook")
        return
    end
    local old_StartAttack = Combat.StartAttack
    Combat.StartAttack = function(self, target, ...)
        -- 清除上一轮背刺标记
        if self.externaldamagemultipliers then
            self.externaldamagemultipliers:RemoveModifier(self.inst, "rogue_backstab")
        end
        -- 检查是否是 Musha 刺客背刺
        if self.inst and self.inst:HasTag("musha") and target then
            local pc = self.inst.components.musha_profession_component
            if pc and pc.rogue and pc.rogue.backstab and pc.rogue.backstab.current_level > 0 then
                if IsBehindTarget(self.inst, target) then
                    local mult = pc.rogue.backstab.level_effects[pc.rogue.backstab.current_level] or 2.0
                    if self.externaldamagemultipliers then
                        self.externaldamagemultipliers:SetModifier(self.inst, mult, "rogue_backstab")
                    end
                    -- 视觉效果提示（仅服务端）
                    if self.inst.components.talker and TheWorld and TheWorld.ismastersim then
                        -- 第一次背刺时提示，避免刷屏
                        if not self.inst._backstab_last_msg_time or
                            (GLOBAL.GetTime() - self.inst._backstab_last_msg_time) > 10 then
                            self.inst.components.talker:Say(
                                string.format("背刺！×%.0f", mult), 1.5)
                            self.inst._backstab_last_msg_time = GLOBAL.GetTime()
                        end
                    end
                end
            end
        end
        return old_StartAttack(self, target, ...)
    end
    print("[Musha] 背刺Hook已安装")
end)

-- =====================
-- 悬停信息面板（2026-09-12 新建）
--   物品数值表：scripts/musha_item_stats.lua（扫描 prefabs 自动生成的静态表，
--   因为客户端读不到 weapon.damage / insulator.insulation —— 那两个组件没 replica）
--   面板本体：scripts/widgets/musha_item_info.lua（纯客户端，挂在 HUD 的 controls 上）
--   规则：只有 musha 玩家看得见；鼠标指到有数值的物品才出现；伤害红字 / 保暖淡白
-- =====================
Safe("物品数值表加载", function()
    local ok, err = pcall(require, "musha_item_stats")
    if not ok then
        print("[Musha] 物品数值表加载失败: " .. tostring(err))
    else
        print("[Musha] 物品数值表已加载")
    end
    -- 追加表（食物/耐久上限/新鲜/燃料/堆叠）—— 会把字段并进上面那张表，必须在它之后
    local ok2, err2 = pcall(require, "musha_item_stats2")
    if not ok2 then
        print("[Musha] 物品数值表2加载失败: " .. tostring(err2))
    else
        print("[Musha] 物品数值表2已加载（食物/耐久/新鲜/燃料/堆叠）")
    end
end)

Safe("悬停信息面板", function()
    require("widgets/musha_item_info")     -- 注册 widget 类
    AddClassPostConstruct("widgets/controls", function(self)
        -- 服务端不需要（没有鼠标/UI）；主机自己也有一份客户端，照样会挂上
        if GLOBAL.TheNet and GLOBAL.TheNet:IsDedicated() then
            return
        end
        local inst = nil
        pcall(function()
            inst = self.owner                     -- controls 的 owner = 玩家
        end)
        if inst == nil then return end

        local ok, w = pcall(function()
            local MushaItemInfo = require("widgets/musha_item_info")
            return MushaItemInfo(self)
        end)
        if ok and w then
            self.musha_item_info = w
            print("[Musha] 悬停信息面板已挂上")
        else
            print("[Musha] 悬停信息面板挂载失败: " .. tostring(w))
        end
    end)
end)

-- =====================
-- 【预留接口】武器"最终伤害"（服务端权威算，客机只显示）
--   用户问："weapon damage 是可以有 getdamage 函数，要预留一个接口"——是的：
--     `Weapon:GetDamage(attacker, target)` 确实存在（weapon.lua:95，会算进 damagetypebonus 等），
--     但 **weapon 组件没有 replica**（components/ 下没有 weapon_replica.lua）→ 客机上
--     `inst.components.weapon` 是 nil → 客机**调不到**这个函数。
--   所以方向只有一个：**服务端算 → 推给客机显示**（让客机算伤害没意义，改包就能骗；而且客机也没数据）。
--   现状（2026-09-12）：只留接口 + 静态表兜底，显示层已经接好：
--     1) 服务端：装备/技能变化时调下面这个函数，把结果存进 pc.userdata（如 d.weapon）
--     2) 同步：**复用** PushSettings() 的 userdata 通道 → 面板/悬停两边都能读到（不用新开网络变量）
--     3) 客机：`scripts/widgets/musha_item_info.lua` 会调 `MushaGetLiveWeaponStats(item, viewer)`，
--        读不到就退回 scripts/musha_item_stats.lua 里的基础值
--        （★ 2026-09-21 更正：原来注释里写的 `MUSHA_LIVE_STATS.get(...)` 那个全局从未定义过，
--          是死代码，已改成直接调本函数）
-- =====================
function MushaGetLiveWeaponStats(item, viewer)
    if not item or not item.components or not viewer or not viewer.IsValid or not viewer:IsValid() then
        return nil
    end
    local w = item.components.weapon
    if not w or not w.GetDamage then
        return nil
    end

    local base, spdmg = nil, nil
    pcall(function()
        -- ★ GetDamage 返回两个值：普通伤害, 位面伤害（位面 = 内部叫 sp damage，SpDamageUtil）
        base, spdmg = w:GetDamage(viewer, nil)
    end)
    if type(base) ~= "number" then
        return nil
    end

    -- musha 自己的加成（目前只有战士"武器精通"走 combat.externaldamagemultipliers）
    local mult = 1
    pcall(function()
        local combat = viewer.components.combat
        if combat and combat.externaldamagemultipliers then
            local m = combat.externaldamagemultipliers:Get()
            if type(m) == "number" and m > 0 then
                mult = m
            end
        end
    end)

    return { base = base, mult = mult, final = base * mult, planar = spdmg }
end

-- =====================
-- 初始化完成
-- =====================
print("[Musha 0.7.6] ★ 职业系统加载完成 ★")
print("[Musha] 聊天命令: /musha /class /职业")

-- ===================== 崩溃桥（2026-09-26）====================
--   挂接点：_G.DisplayError 包装（mainfunctions.lua:1586，按决定）
--     + _G.ScriptErrorWidget 构造包装（漏斗兜底：gamelogic:58 / frontend:1640 /
--       mods.lua:653 的 SetGlobalErrorWidget 最终都 new 它 → 覆盖 mod 加载失败）
--   流程：启动写 challenge.txt（nonce 30s 滚动，留 [当前,上一个] 双格）
--     → 本机 agent（crash_bridge/watcher.ps1）答 HMAC-SHA256（SteamID64 派生 key）
--     → 崩溃时验过才写 out_*.txt；令牌不落盘，盘上只有临时 nonce/应答。
--   想停用：注释掉下面 3 行（watcher 是 agent 侧，不跑它协议也天然停摆）。
local ok_bridge, crash_bridge = pcall(require, "musha_crash_bridge")
if ok_bridge and type(crash_bridge) == "table" then
    local ok_run, err_run = pcall(crash_bridge.start, MODROOT)
    if not ok_run then
        print("[musha-crash-bridge] start error: " .. tostring(err_run))
    end
    pcall(crash_bridge.install_hooks)
else
    print("[musha-crash-bridge] require failed: " .. tostring(crash_bridge))
end
