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
-- 注册 Prefab
-- =====================
print("[Musha TRACE] 8 - PrefabFiles 前")
PrefabFiles = {"musha_jobbook_warrior", "musha_skillbook", "musha_sword", "musha_note", "musha"}
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
        if inst.components.musha_profession_component then
            return
        end

        print("[Musha TRACE] InitMushaPlayer 添加组件前")
        inst:AddComponent("musha_profession_component")
        print("[Musha TRACE] InitMushaPlayer + musha_profession_component")
        inst:AddComponent("musha_quest")
        print("[Musha TRACE] InitMushaPlayer + musha_quest")
        inst:AddComponent("musha_rest")
        print("[Musha TRACE] InitMushaPlayer + musha_rest")
        print("[Musha] 玩家组件已添加: " .. tostring(inst))
    end
    AddPrefabPostInit("musha", InitMushaPlayer)
    print("[Musha TRACE] 12.5 - AddPrefabPostInit('musha') 已注册")
end)
print("[Musha TRACE] 13 - 玩家初始化后")

-- =====================
-- 职业武器配方
-- =====================
print("[Musha TRACE] 14 - 武器配方前")
local JOB_WEAPONS = {
    [1] = {
        prefab = "musha_sword",
        recipe = {Ingredient("ruby", 4)},
        tech = GLOBAL.TECH.SCIENCE_ONE
    }
}

for _, def in pairs(JOB_WEAPONS) do
    AddRecipe2(def.prefab, def.recipe, def.tech, {
        atlas = "images/inventoryimages/" .. def.prefab .. ".xml",
        image = def.prefab .. ".tex"
    })
end
print("[Musha] 武器配方已注册")

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
                    prefab = "nightmarefuel"
                })
            end
            if old then
                old(inst, owner)
            end
        end)
    end)
end)

Safe("宝石收集监听", function()
    for _, gem_prefab in ipairs({"ruby", "emerald", "sapphire"}) do
        AddPrefabPostInit(gem_prefab, function(inst)
            if not TheWorld or not TheWorld.ismastersim then
                return
            end
            local old = inst.components.inventoryitem.onputininventoryfn
            inst.components.inventoryitem:SetOnPutInInventoryFn(function(inst, owner)
                if owner and owner:IsValid() then
                    owner:PushEvent("musha_item_collected", {
                        prefab = gem_prefab
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
        if harvester and harvester:HasTag("musha") then
            if oldHarvest then
                local pc = harvester.components.musha_profession_component
                if pc then
                    pc:AddExp(10)
                end
                harvester:PushEvent("musha_cookpot_harvest", {
                    action = "pick"
                })
            end
        end
        return oldHarvest(self, harvester, ...)
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

        inst:DoPeriodicTask(5, function()
            local quest = inst.components.musha_quest
            if not quest or not quest.active then
                return
            end

            local x, y, z = inst.Transform:GetWorldPosition()

            local dragonflies = TheSim:FindEntities(x, y, z, 30, {"dragonfly"})
            if #dragonflies > 0 and not inst._musha_discovered_dragonfly then
                inst._musha_discovered_dragonfly = true
                quest:OnDiscovered("dragonfly")
            end

            local glommers = TheSim:FindEntities(x, y, z, 20, {"glommer"})
            if #glommers > 0 and not inst._musha_discovered_glommer then
                inst._musha_discovered_glommer = true
                quest:OnDiscovered("glommer")
            end

            local walrus = TheSim:FindEntities(x, y, z, 30, {"walrus"})
            if #walrus > 0 and not inst._musha_discovered_walrus then
                inst._musha_discovered_walrus = true
                quest:OnDiscovered("walrus")
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
    -- 缓存 RPC index 给 prefab 使用（prefab 加载时 RPC 系统未初始化）
    _G.__musha_open_panel_rpc_index = GetModRPCIndex("musha_open_skill_panel")
    -- 注册全局回调，prefab 文件通过 rawget 调用这个
    _G.__musha_open_skill_panel = function(user)
        SendModRPCToClient(_G.__musha_open_panel_rpc_index, user)
    end
    print("[Musha] RPC 注册已加载")
end)

-- =====================
-- 客机复制组件
-- =====================
print("[Musha TRACE] 20 - 客机组件前")
Safe("客机组件", function()
    AddReplicableComponent("musha_profession_component")
end)

-- =====================
-- 初始化完成
-- =====================
print("[Musha 0.7.6] ★ 职业系统加载完成 ★")
print("[Musha] 聊天命令: /musha /class /职业")
