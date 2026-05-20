-- ====================================
-- musha_quest.lua
-- 任务系统组件
-- 13种任务，3个槽位按顺序完成
-- ====================================

-- 全局任务池（存储在 world 上的 musha_quest_pool 组件）
-- 用于管理任务卷轴的 13 种任务分配

-- 任务类型定义
MUSHA_QUEST_TYPES = {
    -- id, name_key, check_fn 检查函数名（在下方实现）
    { id = 1,  name = "见到龙蝇",           type = "discover",   target = 1,  exp = 10 },
    { id = 2,  name = "击杀20只蜘蛛",        type = "kill_spider",  target = 20, exp = 15 },
    { id = 3,  name = "存活5天",            type = "survive",    target = 5,  exp = 10 },
    { id = 4,  name = "找到格罗姆",          type = "discover",   target = 1,  exp = 20 },
    { id = 5,  name = "获得七个噩梦燃料",     type = "collect",    target = 7,  exp = 15, item = "nightmarefuel" },
    { id = 6,  name = "收集三色宝石",        type = "collect_gems", target = 1, exp = 25 },
    { id = 7,  name = "制造20个物品",        type = "craft",      target = 20, exp = 10 },
    { id = 8,  name = "收获五次烹饪锅",      type = "cookpot",    target = 5,  exp = 12 },
    { id = 9,  name = "击败野猪x8",         type = "kill_pig",    target = 8,  exp = 12 },
    { id = 10, name = "击败五只火猎犬",      type = "kill_firehound", target = 5, exp = 18 },
    { id = 11, name = "找到海象营地",        type = "discover",   target = 1,  exp = 15 },
    { id = 12, name = "使用回复技能达到5次",  type = "heal_skill", target = 5,  exp = 10 },
    { id = 13, name = "建造一个科学机器",    type = "craft_science", target = 1, exp = 8 },
}

-- 任务按难度分类（123 对应任务卷轴 1/2/3）
MUSHA_QUEST_POOLS = {
    -- 卷轴 1：简单任务
    [1] = { 3, 5, 7, 8, 13 },
    -- 卷轴 2：中等任务
    [2] = { 2, 4, 5, 9, 12 },
    -- 卷轴 3：困难任务
    [3] = { 1, 6, 10, 11 },
}

-- 从任务池中随机抽取 N 个不重复的任务
function PickQuestsFromPool(pool_index, count)
    local pool = MUSHA_QUEST_POOLS[pool_index]
    if not pool then return {} end

    -- 打乱顺序
    local shuffled = {}
    for _, id in ipairs(pool) do
        table.insert(shuffled, id)
    end
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    -- 取前 N 个
    local result = {}
    for i = 1, math.min(count, #shuffled) do
        table.insert(result, shuffled[i])
    end
    return result
end

-- 获取任务模板
function GetQuestTemplate(quest_id)
    for _, qt in ipairs(MUSHA_QUEST_TYPES) do
        if qt.id == quest_id then
            return qt
        end
    end
    return nil
end

-- 获取任务名称
function GetQuestName(quest_id)
    local qt = GetQuestTemplate(quest_id)
    return qt and qt.name or "未知任务"
end

-- ====================================
-- MUSHA_QUEST 组件（挂在玩家身上）
-- ====================================

local MUSHA_QUEST = Class(function(self, inst)
    self.inst = inst

    -- 当前任务进度
    self.current_quests = {}      -- { [1] = {quest_id, progress, target, done}, [2]=..., [3]=... }
    self.active = false           -- 是否有激活的任务
    self.quest_pool_index = 1     -- 当前任务池（第几张卷轴）

    -- 监听注册
    self:RegisterListeners()
end)

function MUSHA_QUEST:RegisterListeners()
    local inst = self.inst

    -- 制造物品
    self._craft_listener = inst:ListenForEvent("craftitem", function(_, data)
        self:OnCrafted(data)
    end)

    -- 烹饪锅收获
    self._cookpot_listener = inst:ListenForEvent("harvest", function(_, data)
        if data and data.action == "pick" and data.dst ~= nil then
            -- 收获锅
            self:OnCookpotHarvest(data)
        end
    end)

    -- 发现地点
    self._area_listener = inst:ListenForEvent("areatrigger", function(_, data)
        self:OnAreaTrigger(data)
    end)

    -- 击杀事件
    self._kill_listener = inst:ListenForEvent("killed", function(_, data)
        if not data or not data.victim then return end
        local victim = data.victim

        local victim_type = nil
        if victim:HasTag("spider") then
            victim_type = "spider"
        elseif victim:HasTag("pig") and not victim:HasTag("friendly") then
            victim_type = "pig"
        elseif victim:HasTag("hound") and victim:HasTag("fire") then
            victim_type = "firehound"
        end
        if victim_type then
            self:OnKilled(victim_type)
        end
    end)
end

function MUSHA_QUEST:OnRemoveEntity()
    if self._craft_listener then self._craft_listener:Remove() end
    if self._cookpot_listener then self._cookpot_listener:Remove() end
    if self._area_listener then self._area_listener:Remove() end
    if self._kill_listener then self._kill_listener:Remove() end
end

-- ====== 任务生命周期 ======

-- 开始新任务（从卷轴接取）
function MUSHA_QUEST:StartQuests(quest_ids, pool_index)
    self.active = true
    self.quest_pool_index = pool_index or 1
    self.current_quests = {}

    for i, quest_id in ipairs(quest_ids) do
        local qt = GetQuestTemplate(quest_id)
        if qt then
            self.current_quests[i] = {
                quest_id = quest_id,
                progress = 0,
                target = qt.target,
                type = qt.type,
                name = qt.name,
                done = false,
            }
        end
    end

    -- 给玩家台词提示
    if self.inst.components.talker then
        local msg = "接取转职任务！\n"
        for i, q in ipairs(self.current_quests) do
            msg = msg .. (i) .. ". " .. q.name .. "\n"
        end
        self.inst.components.talker:Say(msg, 6)
    end
end

-- 放弃任务
function MUSHA_QUEST:AbortQuests()
    local pc = self.inst.components.musha_profession_component
    if pc then
        pc:PenaltyExp(80)
        if self.inst.components.talker then
            self.inst.components.talker:Say("放弃了任务，损失了80点经验。", 4)
        end
    end

    -- 清除进阶任务状态
    if pc then
        pc.mydata.quests_for_advance = {}
        pc.mydata.quests_for_advance_done = {}
        pc.mydata.current_advance_target = nil
    end

    self:ClearQuests()
    self.active = false
end

-- 清除所有任务
function MUSHA_QUEST:ClearQuests()
    self.current_quests = {}
    self.active = false
end

-- 检查单个任务进度
function MUSHA_QUEST:CheckQuest(slot_index)
    if not self.active or not self.current_quests[slot_index] then
        return
    end

    local q = self.current_quests[slot_index]
    if q.done then return end

    -- 根据类型检查
    if q.type == "survive" then
        -- 存活天数：由外部 update 触发
    elseif q.type == "craft" or q.type == "craft_science" then
        -- 由事件触发
    elseif q.type == "discover" then
        -- 由事件触发
    elseif q.type == "kill_spider" or q.type == "kill_pig" or q.type == "kill_firehound" then
        -- 由外部调用
    elseif q.type == "collect" or q.type == "collect_gems" then
        -- 由外部调用
    elseif q.type == "cookpot" then
        -- 由事件触发
    elseif q.type == "heal_skill" then
        -- 由外部调用
    end
end

-- 标记任务完成
function MUSHA_QUEST:MarkQuestDone(slot_index)
    if not self.current_quests[slot_index] then return end
    local q = self.current_quests[slot_index]
    if q.done then return end

    q.done = true
    local pc = self.inst.components.musha_profession_component
    if pc then
        local qt = GetQuestTemplate(q.quest_id)
        if qt then
            pc:AddExp(qt.exp or 10)
        end
        -- 标记转职任务完成
        pc:MarkAdvanceQuestDone(slot_index)
    end

    if self.inst.components.talker then
        self.inst.components.talker:Say("任务完成: " .. q.name, 4)
    end

    -- 检查是否全部完成
    self:CheckAllDone()
end

-- 检查全部3个任务是否完成
function MUSHA_QUEST:CheckAllDone()
    local all_done = true
    for i = 1, 3 do
        if not self.current_quests[i] or not self.current_quests[i].done then
            all_done = false
            break
        end
    end

    if all_done then
        local pc = self.inst.components.musha_profession_component
        if pc then
            pc:CompleteAdvance()
        end
        self:ClearQuests()
        if self.inst.components.talker then
            self.inst.components.talker:Say("所有转职任务已完成！获得基础技能书！", 5)
        end
    end
end

-- ====== 事件监听处理 ======

-- 制造物品
function MUSHA_QUEST:OnCrafted(data)
    if not self.active then return end
    for i, q in ipairs(self.current_quests) do
        if not q.done then
            if q.type == "craft" then
                q.progress = q.progress + 1
                if q.progress >= q.target then
                    self:MarkQuestDone(i)
                end
            elseif q.type == "craft_science" and data and data.recipe and data.recipe.name == "science_machine" then
                q.progress = q.progress + 1
                if q.progress >= q.target then
                    self:MarkQuestDone(i)
                end
            end
        end
    end
end

-- 烹饪锅收获（外部调用）
function MUSHA_QUEST:OnCookpotHarvest(data)
    if not self.active then return end
    for i, q in ipairs(self.current_quests) do
        if not q.done and q.type == "cookpot" then
            q.progress = q.progress + 1
            if q.progress >= q.target then
                self:MarkQuestDone(i)
            end
        end
    end
end

-- 发现（通过外部调用）
function MUSHA_QUEST:OnDiscovered(discovery_type)
    if not self.active then return end
    for i, q in ipairs(self.current_quests) do
        if not q.done and q.type == "discover" then
            local qinfo = GetQuestTemplate(q.quest_id)
            if qinfo then
                local match = false
                if qinfo.name == "见到龙蝇" and discovery_type == "dragonfly" then
                    match = true
                elseif qinfo.name == "找到格罗姆" and discovery_type == "glommer" then
                    match = true
                elseif qinfo.name == "找到海象营地" and discovery_type == "walrus" then
                    match = true
                end
                if match then
                    q.progress = q.progress + 1
                    if q.progress >= q.target then
                        self:MarkQuestDone(i)
                    end
                end
            end
        end
    end
end

-- 击杀
function MUSHA_QUEST:OnKilled(victim_type)
    if not self.active then return end
    for i, q in ipairs(self.current_quests) do
        if not q.done then
            local match = false
            if q.type == "kill_spider" and victim_type == "spider" then
                match = true
            elseif q.type == "kill_pig" and victim_type == "pig" then
                match = true
            elseif q.type == "kill_firehound" and victim_type == "firehound" then
                match = true
            end
            if match then
                q.progress = q.progress + 1
                if q.progress >= q.target then
                    self:MarkQuestDone(i)
                end
            end
        end
    end
end

-- 收集物品
function MUSHA_QUEST:OnCollected(item_type)
    if not self.active then return end
    for i, q in ipairs(self.current_quests) do
        if not q.done then
            local match = false
            -- 收集噩梦燃料
            if q.type == "collect" and item_type == "nightmarefuel" then
                match = true
            -- 收集宝石
            elseif q.type == "collect_gems" and (item_type == "ruby" or item_type == "emerald" or item_type == "sapphire") then
                match = true
            end
            if match then
                q.progress = q.progress + 1
                if q.progress >= q.target then
                    self:MarkQuestDone(i)
                end
            end
        end
    end
end

-- 使用回复技能
function MUSHA_QUEST:OnHealUsed()
    if not self.active then return end
    for i, q in ipairs(self.current_quests) do
        if not q.done and q.type == "heal_skill" then
            q.progress = q.progress + 1
            if q.progress >= q.target then
                self:MarkQuestDone(i)
            end
            break  -- 一次只计数一个任务
        end
    end
end

-- 生存天数（每日更新）
function MUSHA_QUEST:OnDayPassed()
    if not self.active then return end
    for i, q in ipairs(self.current_quests) do
        if not q.done and q.type == "survive" then
            q.progress = q.progress + 1
            if q.progress >= q.target then
                self:MarkQuestDone(i)
            end
            break
        end
    end
end

-- 获取任务显示文本
function MUSHA_QUEST:GetQuestDisplay()
    if not self.active or #self.current_quests == 0 then
        return "当前没有激活的任务。"
    end

    local lines = {}
    for i, q in ipairs(self.current_quests) do
        local status = q.done and "[已完成]" or ("[" .. q.progress .. "/" .. q.target .. "]")
        table.insert(lines, (i) .. ". " .. q.name .. " " .. status)
    end
    return table.concat(lines, "\n")
end

-- ====== Save/Load ======

function MUSHA_QUEST:OnSave()
    if self.active then
        return {
            current_quests = self.current_quests,
            active = true,
            quest_pool_index = self.quest_pool_index,
        }
    end
end

function MUSHA_QUEST:OnLoad(data)
    if data and data.active then
        self.current_quests = data.current_quests or {}
        self.active = true
        self.quest_pool_index = data.quest_pool_index or 1
    end
end

return MUSHA_QUEST
