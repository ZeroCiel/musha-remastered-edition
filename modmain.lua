-- ==========================================
-- Musha 0.7.6 — 职业系统重制版
-- 雪儿 (Ciel) © 2026
-- ==========================================
print("[Musha] ★ 模组开始加载...")

-- print 追踪：闪退定位
print("[Musha TRACE] 1 - modmain 开始")

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
print("[Musha TRACE] 2 - setmetatable 前")
GLOBAL.setmetatable(env, {
    __index = function(t, k)
        return GLOBAL.rawget(GLOBAL, k)
    end
})
print("[Musha TRACE] 3 - setmetatable 后")

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

-- 导航图标（2026-09-13）—— 清单在 scripts/musha_nav_icons.lua（唯一真源，两处共用）
--   打包好 images/nav_xxx.tex + nav_xxx.xml（同 bookpage_bg 的做法）就往清单里留哪一行。
--   缺 tex 不会崩：面板画图标时用 pcall 兜住，只在日志里打一行。
Safe("导航图标 assets", function()
    local NAVICON = require("musha_nav_icons")
    for _, def in ipairs(NAVICON) do
        table.insert(Assets, Asset("ATLAS", "images/" .. def.file .. ".xml"))
        table.insert(Assets, Asset("IMAGE", "images/" .. def.file .. ".tex"))
    end
    print("[Musha] 导航图标 assets 注册: " .. #NAVICON .. " 张")
end)

-- 能量条动画（2026-09-13）—— 挂同名的 prefab assets 之外这里再声明一次，
--   保证纯客户端（别人开 musha 角色时）也一定加载到这个 build
table.insert(Assets, Asset("ANIM", "anim/energy.zip"))

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
print("[Musha TRACE] 4 - 聊天命令前")
Safe("聊天命令", function()
    modimport "scripts/commands/musha_panel"
    print("[Musha] 聊天命令已加载")
end)
print("[Musha TRACE] 5 - 聊天命令后")

-- =====================
-- HUD 注册（便签 UI 等）
-- =====================
print("[Musha TRACE] 6 - HUD注册前")
Safe("HUD注册", function()
    print("[Musha TRACE] 6.1 - HUD modimport 开始")
    modimport "scripts/widgets/musha_note_registered"
    print("[Musha TRACE] 6.2 - HUD modimport 完成")
    print("[Musha] HUD 已注册")
end)
print("[Musha TRACE] 7 - HUD注册后")

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
-- 注册 Prefab
-- =====================
print("[Musha TRACE] 8 - PrefabFiles 前")
PrefabFiles = {"musha_jobbook_warrior", "musha_jobbook_saber", "musha_skillbook", "musha_sword", "musha_lifebranch", "musha_note", "musha", "musha_advance_altar", "musha_slash_qi_fx", "musha_skill_point"}
-- ⚠️ "musha_jobbook_saber" = **测试专用**（右键直通二转，跳过祭坛 3 轮任务）
--    上线前删除 3 处：这一项 + scripts/prefabs/musha_jobbook_saber.lua + STRINGS 的 MUSHA_JOBBOOK_SABER
print("[Musha TRACE] 9 - PrefabFiles 后")
print("[Musha] PrefabFiles 已设置")
print("[Musha TRACE] 10 - AddModCharacter 前")

AddMinimapAtlas("images/map_icons/musha.xml")
AddModCharacter("musha", "FEMALE")
print("[Musha TRACE] 11 - AddModCharacter 后")
print("[Musha] 角色注册完成")

-- =====================
-- 玩家初始化
-- =====================
print("[Musha TRACE] 12 - 玩家初始化前")
Safe("玩家初始化", function()
    local function InitMushaPlayer(inst)
        if not GLOBAL.TheWorld or not GLOBAL.TheWorld.ismastersim then
            return
        end
        print("[Musha TRACE] InitMushaPlayer 触发: " .. tostring(inst))
        if not inst:HasTag("musha") then
            return
        end

        local first_time = not inst.components.musha_profession_component
        if not inst.components.musha_profession_component then
            print("[Musha TRACE] InitMushaPlayer 添加组件前")
            inst:AddComponent("musha_profession_component")
            print("[Musha TRACE] InitMushaPlayer + musha_profession_component")
        end
        if not inst.components.musha_quest then
            inst:AddComponent("musha_quest")
            print("[Musha TRACE] InitMushaPlayer + musha_quest")
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
        print("[Musha] 玩家组件已添加: " .. tostring(inst) .. " (first=" .. tostring(first_time) .. ")")
    end
    AddPrefabPostInit("musha", InitMushaPlayer)
    print("[Musha TRACE] 12.5 - AddPrefabPostInit('musha') 已注册")

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
    print("[Musha TRACE] 12.6 - musha_world_settings 世界挂载已注册")
end)
print("[Musha TRACE] 13 - 玩家初始化后")

-- =====================
-- 职业武器配方
-- =====================
print("[Musha TRACE] 14 - 武器配方前")
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
--   ⚠️ 图标暂用 musha_note 占位 —— 美术待补真祭坛图标（换图只需改下面 atlas/image 两行）
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
        atlas = "images/inventoryimages/musha_note.xml",
        image = "musha_note.tex",
        builder_tag = "musha",
    },
    { "CHARACTER" })
print("[Musha] 进阶祭坛配方已注册（石块12+木头8+金块6+硝石2 / 科学机器）")

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

print("[Musha TRACE] 15 - 武器配方后/任务收集前")
-- =====================
-- 任务收集监听
-- =====================
print("[Musha TRACE] 16 - 噩梦燃料监听前")
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
print("[Musha TRACE] 17 - 发现检测前")
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
print("[Musha TRACE] 18 - 语言加载前")
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
end)

-- =====================
-- 技能数据
-- =====================
print("[Musha TRACE] 18.5 - 技能数据加载前")
Safe("技能数据", function()
    modimport "scripts/skills/musha_skill_data"
    print("[Musha] 技能数据已加载")
end)

-- =====================
-- 动作注册
-- =====================
print("[Musha TRACE] 19 - 动作注册前")
Safe("动作注册", function()
    modimport "scripts/actions/musha_actions"
    print("[Musha] 动作注册已加载")
end)

-- =====================
-- RPC 注册
-- =====================
print("[Musha TRACE] 19.5 - RPC 注册前")
Safe("RPC注册", function()
    modimport "scripts/rpcs/musha_rpcs"
    print("[Musha] RPC 注册已加载")
end)

-- =====================
-- 客机复制组件注册（必须在所有 AddComponent 之后）
-- 缺这行 → 客户端没有 replica，面板 owner.replica.musha_profession_component 恒 nil → 不显示
-- =====================
print("[Musha TRACE] 19.6 - 客机复制组件注册前")
Safe("复制组件", function()
    AddReplicableComponent("musha_profession_component")
    print("[Musha] 客机复制组件已注册: musha_profession_component")
end)

-- =====================
-- 进阶祭坛（2026-09-08 占位 → 2026-09-12 独立 prefab 落地）
-- 实体：scripts/prefabs/musha_advance_altar.lua（占位动画=原版雕像，模型待移植）
-- 旧占位 statuemaxwell(麦斯威尔雕像) 继续兼容老存档
-- 交互动作链：SCENE 右键 → MUSHA_QUEST_INTERACT → musha_action:InteractScene → 本函数
-- =====================
print("[Musha TRACE] 20.6 - 祭坛绑定前")
Safe("祭坛占位", function()
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

    local function OnAltarInteract(inst, doer)
        if not doer or not doer:IsValid() then return end
        local pc = doer.components.musha_profession_component
        if not pc then
            if doer.components.talker then doer.components.talker:Say("Musha 职业系统未就绪。", 3) end
            return
        end

        -- 条件：有基础职业、未进阶
        local base = pc:GetCarrer_base()
        if not base then
            if doer.components.talker then doer.components.talker:Say("还没有职业，先去使用职业书转职吧！", 3) end
            return
        end
        if pc:GetCarrer_special() or pc.userdata.has_advanced then
            if doer.components.talker then doer.components.talker:Say("已经完成进阶了！", 3) end
            return
        end

        local quest = doer.components.musha_quest
        if not quest then
            if doer.components.talker then doer.components.talker:Say("任务系统未就绪。", 3) end
            return
        end

        local target = BASE_TO_ADVANCE[base]
        if not target then
            if doer.components.talker then doer.components.talker:Say("当前职业暂无可进阶方向。", 3) end
            return
        end

        -- 转职轮次已满？(3轮完成后应在 CompleteAdvanceQuest 已设 carrer_special，正常不会到这)
        -- 接取当前轮（1 个任务；round 由 quest 组件维护）
        local ok, reason = quest:AcceptAdvanceQuest(target)
        if not ok then
            if doer.components.talker then doer.components.talker:Say(reason or "暂无法接取。", 3) end
            return
        end
        -- 通知客户端刷新面板（接取后 advance_quest 数据已由 SyncToPanel 推送）
    end

    -- 祭坛绑定（2026-09-12 起有独立 prefab 了）
    --   musha_advance_altar = 新祭坛（真正的 prefab，见 scripts/prefabs/musha_advance_altar.lua）
    --   statuemaxwell       = 旧占位（老存档里已经摆着的麦斯威尔雕像，继续兼容）
    -- 注意：tag + 组件要在**客户端也加上**，否则客机右键不出 MUSHA_QUEST_INTERACT。
    --       新 prefab 自己在 fn 里 pristine 之前加了；这里补 tag 只为旧占位 statuemaxwell。
    local function BindAltar(inst)
        if not inst:HasTag("musha_altar") then
            inst:AddTag("musha_altar")
        end
        if not inst.components.musha_action then
            inst:AddComponent("musha_action")
        end
        if not GLOBAL.TheWorld or not GLOBAL.TheWorld.ismastersim then
            return
        end
        inst.components.musha_action:SetFn(OnAltarInteract)
        inst.components.musha_action:SetCanUseCheck(function(_, doer)
            return doer and doer:IsValid() and doer.components.musha_profession_component ~= nil
        end)
    end

    AddPrefabPostInit("musha_advance_altar", BindAltar)
    AddPrefabPostInit("statuemaxwell", BindAltar)
    print("[Musha] 祭坛已绑定: musha_advance_altar (新) + statuemaxwell (旧占位兼容)")
end)
print("[Musha TRACE] 20.7 - 祭坛占位后")

-- =====================
-- 背刺判定 (Assassin Backstab)
-- =====================
print("[Musha TRACE] 20.5 - 背刺Hook前")

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
--     3) 客机：`scripts/widgets/musha_item_info.lua` 里会优先读 `MUSHA_LIVE_STATS.get(item, viewer)`，
--        读不到就退回 scripts/musha_item_stats.lua 里的基础值
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
