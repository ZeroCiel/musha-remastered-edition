-- ====================================
-- musha_quest.lua
-- 任务系统组件（2026-09-08 重构版）
-- 两套任务：
--   每日任务 daily_quests  — 每天自动发 N 个(配置)，可累积上限10；
--                            探索/发现类(discover)隔日作废，其他保留到做完
--   转职任务 advance_quest — 雕像接取，一次 1 个，共 3 轮，第 3 轮完成即进阶
-- ====================================

-- 任务类型定义（id, name, type, target, exp）
-- ★ 2026-09-13 临时调试开关（查明「建造科学机器/制造」计数问题用）
--   true  → 每次建造都打一行日志：[Musha Quest] builditem: recipe=xxx prefab=yyy
--           并把每天新发的任务 id 打出来
--   查完改回 false（或删掉这几行 + 对应 print）
local DEBUG_QUEST = true

MUSHA_QUEST_TYPES = {
    { id = 1,  name = "见到龙蝇",           type = "discover",    target = 1,  exp = 10 },
    { id = 2,  name = "击杀20只蜘蛛",        type = "kill_spider", target = 20, exp = 15 },
    { id = 3,  name = "存活5天",            type = "survive",     target = 5,  exp = 10 },
    { id = 4,  name = "找到格罗姆",          type = "discover",    target = 1,  exp = 20 },
    { id = 5,  name = "获得七个噩梦燃料",     type = "collect",     target = 7,  exp = 15 },
    -- ★ 2026-09-12 用户拍板：三色宝石 = **红/绿/蓝各一颗**（target 1 → 3），经验 25 → 30
    { id = 6,  name = "收集三色宝石",        type = "collect_gems", target = 3, exp = 30 },
    { id = 7,  name = "制造20个物品",        type = "craft",       target = 20, exp = 10 },
    { id = 8,  name = "收获五次烹饪锅",      type = "cookpot",     target = 5,  exp = 12 },
    { id = 9,  name = "击败野猪x8",         type = "kill_pig",     target = 8,  exp = 12 },
    { id = 10, name = "击败五只火猎犬",      type = "kill_firehound", target = 5, exp = 18 },
    { id = 11, name = "找到海象营地",        type = "discover",    target = 1,  exp = 15 },
    { id = 12, name = "使用回复技能达到5次",  type = "heal_skill",  target = 5,  exp = 10 },
    { id = 13, name = "建造一个科学机器",    type = "craft_science", target = 1, exp = 8 },
}

-- 任务难度池（保留；新逻辑每日发放从全池抽，池字段留作转职轮次难度递进参考）
MUSHA_QUEST_POOLS = {
    [1] = { 3, 5, 7, 8, 13 },
    [2] = { 2, 4, 5, 9, 12 },
    [3] = { 1, 6, 10, 11 },
}

-- 转职轮次难度递进：第 1 轮简单 / 第 2 轮中等 / 第 3 轮困难
local ADVANCE_POOL_BY_ROUND = { [1] = 1, [2] = 2, [3] = 3 }
-- ★ 转职（进阶）等级门槛：设定文档写的是「5级一转」→ 不到 5 级不能接转职任务
--   （2026-09-12 补：之前祭坛只查"有职业/未进阶"，等级完全没判 → 1 级就能接）
local ADVANCE_MIN_LEVEL = 5
-- 每日上限 / 每日发放数默认（可被 mod 配置覆盖）
local DAILY_MAX = 10

-- 收集类任务"完成后要扣掉的物品"（2026-09-12 用户选 b：完成即从物品栏扣除同等数量）
--   collect      = 获得七个噩梦燃料 → 扣 7 个噩梦燃料
--   collect_gems = 收集三色宝石     → 扣 q.target 颗宝石（红/绿/蓝任选，凑够数量即可）
local CONSUME_BY_TYPE = {
    collect      = { nightmarefuel = true },
    collect_gems = { ruby = true, emerald = true, sapphire = true },
}

-- 从任务池随机抽 N 个不重复
function PickQuestsFromPool(pool_index, count)
    local pool = MUSHA_QUEST_POOLS[pool_index]
    if not pool then return {} end
    local shuffled = {}
    for _, id in ipairs(pool) do
        table.insert(shuffled, id)
    end
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    local result = {}
    for i = 1, math.min(count, #shuffled) do
        table.insert(result, shuffled[i])
    end
    return result
end

-- 从全池随机抽 N 个（跳过指定 id 集合）
function PickQuestsFromAll(count, skip_ids)
    skip_ids = skip_ids or {}
    local bucket = {}
    for _, qt in ipairs(MUSHA_QUEST_TYPES) do
        if not skip_ids[qt.id] then
            table.insert(bucket, qt.id)
        end
    end
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

function GetQuestTemplate(quest_id)
    for _, qt in ipairs(MUSHA_QUEST_TYPES) do
        if qt.id == quest_id then
            return qt
        end
    end
    return nil
end

function GetQuestName(quest_id)
    local qt = GetQuestTemplate(quest_id)
    return qt and qt.name or "未知任务"
end

-- ====================================
-- MUSHA_QUEST 组件（挂在玩家身上）
-- ====================================

local MUSHA_QUEST = Class(function(self, inst)
    self.inst = inst

    -- 每日任务
    self.daily_quests = {}    -- {quest_id, progress, target, type, name, done, day}
    -- 转职任务
    self.advance_quest = nil  -- 同上结构
    self.advance_round = 1    -- 1..3
    self.advance_target = nil -- 目标职业(字符串，如 saber)

    self:RegisterListeners()

    -- 兜底轮询（2026-09-12）：万一 "startday" 世界状态没触发，按"天号"对时补发。
    --   和 WatchWorldState 的事件共用 OnNewDay 的天号去重 → 谁先到都只处理一次。
    if self._day_poll == nil then
        self._day_poll = inst:DoPeriodicTask(5, function()
            self:CheckNewDay()
        end)
    end
end)

-- ⚠️ 测试用：每日任务固定发放数。想看 8 个就设成 8；发布前应保持 nil。
-- 现在"每日任务数量"已经进了局内设置（世界级 daily_quest_count），
-- 所以这里默认 nil，让设置生效。要强制测试值再手动改回数字。
local TEST_DAILY_COUNT = nil

-- 读取每日发放数（modmain 在玩家初始化时把配置写到 self.daily_count_override，默认 4）
-- 2026-09-10：范围放宽到 1..10，跟局内设置 daily_quest_count 对齐
function MUSHA_QUEST:GetDailyCount()
    if TEST_DAILY_COUNT then
        return math.min(TEST_DAILY_COUNT, DAILY_MAX)
    end
    local n = self.daily_count_override
    if type(n) == "number" and n >= 1 and n <= 10 then
        return math.floor(n)
    end
    return 4
end

function MUSHA_QUEST:RegisterListeners()
    local inst = self.inst

    -- ★ 2026-09-13 修（用户提醒"建造监听有好几个不同"——他是对的）：
    --   原版 builder 的 DoBuild 里有**两个互斥的成功事件**（if/else 两条路）：
    --     · builder.lua:739  `builditem`      {item,recipe,skin,prototyper} → 产物**进背包**（物品）
    --     · builder.lua:819  `buildstructure` {item,recipe,skin}            → 产物**直接落地**（建筑）
    --   科学机器是 **placer 配方**（recipes.lua:371 `Recipe2("researchlab",…,{placer="researchlab_placer"})`），
    --   走的是"落地"那条 → **只听 builditem 永远收不到** → 这就是"建了没反应"的真因。
    --   ⇒ 两个都听；因为是 if/else，同一次建造只会触发其中一个，不会重复计数。
    self._craft_listener = inst:ListenForEvent("builditem", function(_, data)
        self:OnCrafted(data, "builditem")
    end)
    self._structure_listener = inst:ListenForEvent("buildstructure", function(_, data)
        self:OnCrafted(data, "buildstructure")
    end)

    -- ★ 2026-09-12 修：原来监听的是 "harvest" —— **原版根本没有这个事件**（全项目 grep 不到），
    --   而 modmain 的 stewer hook 推的是 "musha_cookpot_harvest" → 两边对不上，
    --   "收获五次烹饪锅"从来没计过数（用户报"采集烹饪锅不会获得"）。
    self._cookpot_listener = inst:ListenForEvent("musha_cookpot_harvest", function()
        self:OnCookpotHarvest()
    end)

    -- 历史遗留监听（发现任务由 modmain 5s 轮询驱动；保留避免注册残留）
    self._area_listener = inst:ListenForEvent("areatrigger", function(_, data)
        self:OnAreaTrigger(data)
    end)

    self._kill_listener = inst:ListenForEvent("killed", function(_, data)
        if not data or not data.victim then return end
        local victim = data.victim
        local victim_type = nil
        if victim:HasTag("spider") then
            victim_type = "spider"
        elseif victim:HasTag("pig") and not victim:HasTag("friendly") then
            victim_type = "pig"
        elseif victim.prefab == "firehound" then
            -- ★ 2026-09-13 修「击败五只火猎犬」不计数：
            --   原来查的是 `HasTag("hound") and HasTag("fire")`，但**火猎犬身上没有 "fire" tag**！
            --   原版 prefabs/hound.lua:643 fnfire → fncommon("hound","hound_red_ocean",{"hound","icehound"},…)
            --   tag 列表是 {"hound","icehound"}（Klei 这写法很怪，但事实就是没有 fire）
            --   → 改按 **prefab 名** 认（prefab == "firehound"），下面那行留着当兜底
            victim_type = "firehound"
        elseif victim:HasTag("hound") and victim:HasTag("fire") then
            victim_type = "firehound"
        end
        if victim_type then
            self:OnKilled(victim_type)
        end
    end)

    self._collect_listener = inst:ListenForEvent("musha_item_collected", function(_, data)
        if data and data.prefab then
            -- ★ 2026-09-12 修：带上堆叠数（一次捡 7 个噩梦燃料 = +7，不是 +1）
            self:OnCollected(data.prefab, data.count)
        end
    end)

    self._day_listener = inst:WatchWorldState("startday", function()
        self:OnNewDay()
    end)
end

function MUSHA_QUEST:OnRemoveEntity()
    if self._craft_listener then self._craft_listener:Remove() end
    if self._structure_listener then self._structure_listener:Remove() end
    if self._cookpot_listener then self._cookpot_listener:Remove() end
    if self._area_listener then self._area_listener:Remove() end
    if self._kill_listener then self._kill_listener:Remove() end
    if self._collect_listener then self._collect_listener:Remove() end
    if self._day_listener then self._day_listener:Remove() end
    if self._day_poll then self._day_poll:Cancel() self._day_poll = nil end
end

-- ====================================
-- 构造任务条目
-- ====================================
local function MakeQuestEntry(quest_id)
    local qt = GetQuestTemplate(quest_id)
    if not qt then return nil end
    return {
        quest_id = quest_id,
        progress = 0,
        target = qt.target,
        type = qt.type,
        name = qt.name,
        exp = qt.exp,
        done = false,
    }
end

-- ====================================
-- 每日任务发放/过期
-- ====================================

-- 新的一天：探索类(discover)隔日作废清除；补发至目标数量
function MUSHA_QUEST:OnNewDay()
    -- 只在服务端跑（客户端那份组件是空壳，别在自己那边造任务）
    if TheWorld and not TheWorld.ismastersim then return end

    -- ★ 按"天号"去重：WatchWorldState 和轮询兜底谁先到都只处理一次（2026-09-12）
    local cycles = TheWorld and TheWorld.state and TheWorld.state.cycles
    if cycles ~= nil then
        if self._last_newday_cycles == cycles then return end
        self._last_newday_cycles = cycles
    end

    -- 1. discover 未完成 → 作废
    local kept = {}
    for _, q in ipairs(self.daily_quests) do
        if q.done or q.type ~= "discover" then
            table.insert(kept, q)
        end
    end
    self.daily_quests = kept

    -- 2. survive 进度 +1（存活任务跨天推进）
    for _, q in ipairs(self.daily_quests) do
        if not q.done and q.type == "survive" then
            q.progress = q.progress + 1
            if q.progress >= q.target then
                self:CompleteDailyQuest(q)
            end
        end
    end

    -- 3. 新增当天的任务（累积，上限 10）
    self:GrantNewDayQuests()

    -- 4. 推送
    self:SyncToPanel()
end

-- 轮询兜底：天号变了就补一次（OnNewDay 内部会去重）
function MUSHA_QUEST:CheckNewDay()
    if not TheWorld or not TheWorld.ismastersim then return end
    local cycles = TheWorld.state and TheWorld.state.cycles
    if cycles == nil then return end
    if self._last_newday_cycles == nil then
        self._last_newday_cycles = cycles   -- 首次只记天号（首日任务由 OnLoad / modmain 负责）
        return
    end
    if cycles ~= self._last_newday_cycles then
        self:OnNewDay()
    end
end

-- 新的一天"新增"N 个（累积，上限 DAILY_MAX=10）
-- ★ 2026-09-12 修：旧实现是 FillDailyQuests()（补到 N 个）→ 手里还剩 N 个没做完时
--   to_add = want - active = 0 → **次日一个都不发**（用户报"到次日 不加任务"）。
--   现在改成"每天新增 GetDailyCount() 个"，做完的清掉、没做完的留着，总量封顶 10。
function MUSHA_QUEST:GrantNewDayQuests()
    local want = self:GetDailyCount()
    local room = math.max(0, DAILY_MAX - #self.daily_quests)
    local to_add = math.min(want, room)
    if to_add <= 0 then return end

    local skip_ids = {}
    for _, q in ipairs(self.daily_quests) do
        skip_ids[q.quest_id] = true
    end

    local ids = PickQuestsFromAll(to_add, skip_ids)
    for _, qid in ipairs(ids) do
        local q = MakeQuestEntry(qid)
        if q then
            table.insert(self.daily_quests, q)
        end
    end

    if DEBUG_QUEST then
        local all = {}
        for _, q in ipairs(self.daily_quests) do
            table.insert(all, tostring(q.quest_id) .. "(" .. tostring(q.name) .. ")")
        end
        print("[Musha Quest] 换天新增任务，当前任务列表: " .. table.concat(all, ", "))
    end
end

-- 补发每日任务直到达标
function MUSHA_QUEST:FillDailyQuests()
    local want = self:GetDailyCount()
    local active_daily = 0
    local skip_ids = {}
    for _, q in ipairs(self.daily_quests) do
        if not q.done then
            active_daily = active_daily + 1
        end
        skip_ids[q.quest_id] = true
    end

    local room = math.max(0, DAILY_MAX - #self.daily_quests)
    local to_add = math.min(want - active_daily, room)
    if to_add <= 0 then return end

    local ids = PickQuestsFromAll(to_add, skip_ids)
    for _, qid in ipairs(ids) do
        local q = MakeQuestEntry(qid)
        if q then
            table.insert(self.daily_quests, q)
        end
    end
end

-- 接取每日任务时立刻补一批（雕像暂不开放每日，保留方法给未来 NPC/指令）
function MUSHA_QUEST:AddDailyQuests(manual_count)
    if manual_count and manual_count > 0 then
        -- 手动加指定数量（忽略每日限制，直接补到池）
        local ids = PickQuestsFromAll(manual_count, nil)
        for _, qid in ipairs(ids) do
            local q = MakeQuestEntry(qid)
            if q then
                table.insert(self.daily_quests, q)
            end
        end
    else
        self:FillDailyQuests()
    end
    self:SyncToPanel()
end

-- ====================================
-- 转职任务（雕像接取，一次 1 个，共 3 轮）
-- ====================================

-- 接取当前轮转职任务（雕像调用）
function MUSHA_QUEST:AcceptAdvanceQuest(target_job)
    -- ★ 等级门槛（2026-09-12 补）：设定文档「5级一转」→ 不到 ADVANCE_MIN_LEVEL 不能接
    local pc = self.inst.components.musha_profession_component
    local lv = (pc and pc.GetLevel) and pc:GetLevel() or 0
    if lv < ADVANCE_MIN_LEVEL then
        return false, string.format("需要 %d 级才能接取转职任务（当前 %d 级）", ADVANCE_MIN_LEVEL, lv)
    end

    if self.advance_quest and not self.advance_quest.done then
        return false, "已有进行中的转职任务"
    end
    if self.advance_round > 3 then
        return false, "转职轮次已完成"
    end

    local pool = ADVANCE_POOL_BY_ROUND[self.advance_round] or 1
    -- 跳过 heal_skill（技能系统未启用）
    local ids = PickQuestsFromAll(1, { [12] = true })
    if #ids == 0 then
        return false, "任务池为空"
    end

    local q = MakeQuestEntry(ids[1])
    if not q then
        return false, "任务生成失败"
    end

    self.advance_quest = q
    self.advance_target = target_job
    self:SyncToPanel()

    if self.inst.components.talker then
        self.inst.components.talker:Say("接取转职任务（第 " .. self.advance_round .. "/3 轮）：" .. q.name, 5)
    end
    return true
end

-- 转职任务完成 → 推进轮次；第 3 轮完成 → 进阶
function MUSHA_QUEST:CompleteAdvanceQuest()
    if not self.advance_quest then return end
    self.advance_quest = nil

    if self.advance_round >= 3 then
        -- 进阶完成
        local pc = self.inst.components.musha_profession_component
        if pc then
            -- 设置进阶职业并清转职状态
            pc.userdata.carrer_special = self.advance_target
            pc.userdata.has_advanced = true
            pc.userdata.advance_round = nil
            pcall(function() pc:ApplyProfessionData() end)
            -- 给一转技能书
            local book = SpawnPrefab("musha_skillbook")
            if book and self.inst.components.inventory then
                self.inst.components.inventory:GiveItem(book)
            end
            if self.inst.components.talker then
                self.inst.components.talker:Say("一转进阶完成！当前职业：" .. tostring(self.advance_target), 5)
            end
        end
        self.advance_round = 1
        self.advance_target = nil
    else
        self.advance_round = self.advance_round + 1
        if self.inst.components.talker then
            self.inst.components.talker:Say("转职任务完成！可去祭坛接取下一轮（" .. self.advance_round .. "/3）。", 4)
        end
    end
    self:SyncToPanel()
end

-- 放弃转职任务（重置轮次）
function MUSHA_QUEST:AbortAdvanceQuest()
    self.advance_quest = nil
    self.advance_round = 1
    self.advance_target = nil
    self:SyncToPanel()
end

-- ====================================
-- 通用完成处理
-- ====================================

function MUSHA_QUEST:GrantQuestReward(q)
    local pc = self.inst.components.musha_profession_component
    if pc and q.exp then
        pcall(function() pc:AddExp(q.exp) end)
    end
end

-- 从物品栏拿走指定 prefab 的 N 个（整堆 Remove / 部分 SetStackSize），返回实际拿走数量
function MUSHA_QUEST:TakeItemsFromInventory(prefab, amount)
    local inv = self.inst.components.inventory
    if not inv or not prefab or not amount or amount <= 0 then return 0 end

    local removed = 0
    local guard = 0
    while removed < amount and guard < 30 do
        guard = guard + 1
        local item = nil
        pcall(function()
            if inv.FindItem then
                item = inv:FindItem(function(it) return it.prefab == prefab end)
            end
        end)
        if item == nil then break end

        local st = item.components.stackable
        local n = (st and st:StackSize()) or 1
        local take = math.min(n, amount - removed)
        if take >= n then
            item:Remove()                       -- 整个堆叠带走
        else
            st:SetStackSize(n - take)           -- 只扣一部分
        end
        removed = removed + take
    end
    return removed
end

-- 收集类任务完成时：从物品栏扣掉对应数量的物品（2026-09-12 用户拍板 b）
--   数量不够就"扣多少算多少"—— 不卡完成（否则捡到手后中途丢掉/用掉，任务永远交不掉）
function MUSHA_QUEST:ConsumeQuestItems(q)
    if not q then return end

    -- 三色宝石：按"这次收集到的颜色"各扣 1 颗（红/绿/蓝各一）
    if q.type == "collect_gems" then
        local list = {}
        if q.gems then
            for c in pairs(q.gems) do table.insert(list, c) end
        end
        if #list == 0 then
            list = { "ruby", "emerald", "sapphire" }
        end
        for _, c in ipairs(list) do
            self:TakeItemsFromInventory(c, 1)
        end
        return
    end

    if not q.target or q.target <= 0 then return end
    local allowed = CONSUME_BY_TYPE[q.type]
    if not allowed then return end              -- 非收集类任务不扣东西

    local remaining = q.target
    for prefab in pairs(allowed) do
        if remaining <= 0 then break end
        local got = self:TakeItemsFromInventory(prefab, remaining)
        remaining = remaining - got
        if DEBUG_QUEST then
            print(string.format("[Musha Quest] 完成扣除：%s 需要 %d，实扣 %d", tostring(prefab), q.target, got))
        end
    end
end

-- 完成一条每日任务
function MUSHA_QUEST:CompleteDailyQuest(q)
    if q.done then return end
    q.done = true
    self:GrantQuestReward(q)
    -- ★ 2026-09-13 修：收集类"完成即扣"要**延到下一帧**扣
    --   原因：进度是 modmain 的 SetOnPutInInventoryFn 钩子推来的，那个钩子在"物品真正进包之前"触发 →
    --   此刻背包里可能只有 6 个（第 7 个还没进）→ 当场扣只能扣到 6 个，看着就像"没被消耗"。
    --   延一帧：物品已进包，扣多少就是多少。
    self.inst:DoTaskInTime(0, function()
        self:ConsumeQuestItems(q)
        self:SyncToPanel()
    end)
    -- 保留已完成的在列表(打勾显示)，或直接移除？设计"保留到做完"→ 完成即从列表移除更干净
    -- 选择：完成移除 + 奖励提示
    for i, e in ipairs(self.daily_quests) do
        if e == q then
            table.remove(self.daily_quests, i)
            break
        end
    end
    if self.inst.components.talker then
        self.inst.components.talker:Say("每日任务完成：" .. q.name, 4)
    end
    self:SyncToPanel()
end

-- 完成当前转职任务
function MUSHA_QUEST:CompleteCurrentAdvance()
    if not self.advance_quest or self.advance_quest.done then return end
    self.advance_quest.done = true
    self:GrantQuestReward(self.advance_quest)
    self:ConsumeQuestItems(self.advance_quest)   -- ★ 转职任务同理（也可能抽到收集类）
    if self.inst.components.talker then
        self.inst.components.talker:Say("转职任务完成：" .. self.advance_quest.name, 4)
    end
    self:CompleteAdvanceQuest()
end

-- ====================================
-- 进度推进（每日 + 转职都检查）
-- ====================================

-- amount：本次推进的数量（默认 1）—— 收集类任务传堆叠数，堆叠才算得对
function MUSHA_QUEST:ProgressQuests(match_fn, amount)
    amount = amount or 1
    -- 每日任务
    for _, q in ipairs(self.daily_quests) do
        if not q.done and match_fn(q) then
            q.progress = q.progress + amount
            if q.progress >= q.target then
                self:CompleteDailyQuest(q)
            else
                self:SyncToPanel()
            end
        end
    end
    -- 转职当前任务
    local aq = self.advance_quest
    if aq and not aq.done and match_fn(aq) then
        aq.progress = aq.progress + amount
        if aq.progress >= aq.target then
            self:CompleteCurrentAdvance()
        else
            self:SyncToPanel()
        end
    end
end

-- 制造 / 建造（data 来自 builditem 或 buildstructure，source 标明哪一个）
function MUSHA_QUEST:OnCrafted(data, source)
    source = source or "builditem"
    -- ★ 2026-09-13 修「建造一个科学机器」不计数：
    --   原版科学机器的**配方名是 "researchlab"**（prefab 也叫 researchlab），
    --   见 data/databundles/scripts/recipes.lua:371 与 prefabs/scienceprototyper.lua:299
    --   原来这里写的是 "science_machine"（加了下划线的自造名）→ 永远匹配不上 → 任务 13 从未计过数
    local rname = data and data.recipe and data.recipe.name
    local pname = data and data.item and data.item.prefab
    if DEBUG_QUEST then
        print(string.format("[Musha Quest] %s: recipe=%s prefab=%s",
            source, tostring(rname), tostring(pname)))
    end
    local is_science_machine = (rname == "researchlab") or (pname == "researchlab")
        or (rname == "sciencemachine") or (pname == "sciencemachine")
        or (rname == "researchlab2") or (pname == "researchlab2")   -- 炼金引擎也算（跳过科学机器也能完成）

    -- 物品制造（builditem）才算"制造物品"；直接落地的建筑（buildstructure）不记进 id7
    local is_item_craft = (source == "builditem")

    self:ProgressQuests(function(q)
        if q.type == "craft" and is_item_craft then
            return true
        elseif q.type == "craft_science" and is_science_machine then
            return true
        end
        return false
    end)
end

-- 烹饪锅收获
function MUSHA_QUEST:OnCookpotHarvest()
    self:ProgressQuests(function(q)
        return q.type == "cookpot"
    end)
end

-- 发现（modmain 5s 轮询调用）
function MUSHA_QUEST:OnDiscovered(discovery_type)
    self:ProgressQuests(function(q)
        if q.type ~= "discover" then return false end
        local qinfo = GetQuestTemplate(q.quest_id)
        if not qinfo then return false end
        if qinfo.name == "见到龙蝇" and discovery_type == "dragonfly" then
            return true
        elseif qinfo.name == "找到格罗姆" and discovery_type == "glommer" then
            return true
        elseif qinfo.name == "找到海象营地" and discovery_type == "walrus" then
            return true
        end
        return false
    end)
end

function MUSHA_QUEST:OnAreaTrigger()
    -- 历史遗留空方法
end

-- 击杀
function MUSHA_QUEST:OnKilled(victim_type)
    self:ProgressQuests(function(q)
        if q.type == "kill_spider" and victim_type == "spider" then
            return true
        elseif q.type == "kill_pig" and victim_type == "pig" then
            return true
        elseif q.type == "kill_firehound" and victim_type == "firehound" then
            return true
        end
        return false
    end)
end

-- 收集
function MUSHA_QUEST:OnCollected(item_type, count)
    count = count or 1
    if item_type == "nightmarefuel" then
        self:ProgressQuests(function(q) return q.type == "collect" end, count)
        return
    end
    if item_type == "ruby" or item_type == "emerald" or item_type == "sapphire" then
        self:ProgressGemQuest(item_type)
    end
end

-- 三色宝石专用推进（2026-09-12）：进度 = **集齐了几种颜色**（红/绿/蓝各一，target=3）
--   ——普通收集类按数量叠加，这个按"颜色种类"去重
function MUSHA_QUEST:ProgressGemQuest(color)
    local function Apply(q)
        if q.done or q.type ~= "collect_gems" then return false end
        q.gems = q.gems or {}
        if q.gems[color] then return false end      -- 同色再来不再计数
        q.gems[color] = true
        local n = 0
        for _ in pairs(q.gems) do n = n + 1 end
        q.progress = math.max(q.progress or 0, n)
        if q.progress >= math.max(1, q.target or 3) then
            return true                             -- 集齐 → 交给调用方完成
        end
        return false
    end

    local dirty = false
    for _, q in ipairs(self.daily_quests) do
        if Apply(q) then
            self:CompleteDailyQuest(q)
        else
            dirty = true
        end
    end
    local aq = self.advance_quest
    if aq then
        if Apply(aq) then
            self:CompleteCurrentAdvance()
        else
            dirty = true
        end
    end
    if dirty then self:SyncToPanel() end
end

-- 回复技能
function MUSHA_QUEST:OnHealUsed()
    self:ProgressQuests(function(q)
        return q.type == "heal_skill"
    end)
end

-- 存活天数：由 OnNewDay 内单独处理（survive 每日 +1）

-- ====================================
-- 同步到 pc.userdata（面板读取）
-- ====================================
function MUSHA_QUEST:SyncToPanel()
    local pc = self.inst.components.musha_profession_component
    if not pc then return end

    pc.userdata.daily_quests = {}
    for _, q in ipairs(self.daily_quests) do
        table.insert(pc.userdata.daily_quests, {
            id = q.quest_id,
            n = q.name,
            p = q.progress,
            t = q.target,
            done = q.done or false,
        })
    end

    if self.advance_quest then
        pc.userdata.advance_quest = {
            id = self.advance_quest.quest_id,
            n = self.advance_quest.name,
            p = self.advance_quest.progress,
            t = self.advance_quest.target,
            done = self.advance_quest.done or false,
        }
    else
        pc.userdata.advance_quest = nil
    end
    pc.userdata.advance_round = self.advance_round
    pc.userdata.advance_target = self.advance_target

    -- 旧字段兼容清空（面板新版不再用 quests_for_advance）
    pc.userdata.quests_for_advance = {}
    pc.userdata.quests_for_advance_done = {}

    if pc.inst and pc.inst.replica and pc.inst.replica.musha_profession_component then
        pcall(function()
            pc.inst.replica.musha_profession_component:DoUpdata(pc.userdata)
        end)
    end
end

-- 兼容旧接口（GetQuestDisplay / 聊天面板用）
function MUSHA_QUEST:GetQuestDisplay()
    local lines = {}
    if #self.daily_quests > 0 then
        table.insert(lines, "每日任务：")
        for i, q in ipairs(self.daily_quests) do
            table.insert(lines, (i) .. ". " .. q.name .. " [" .. q.progress .. "/" .. q.target .. "]")
        end
    end
    if self.advance_quest then
        table.insert(lines, "转职任务（" .. self.advance_round .. "/3）：" .. self.advance_quest.name
            .. " [" .. self.advance_quest.progress .. "/" .. self.advance_quest.target .. "]")
    end
    if #lines == 0 then
        return "当前没有任务。"
    end
    return table.concat(lines, "\n")
end

-- 兼容旧 active 判断（聊天命令 / modmain 用）
function MUSHA_QUEST:HasActiveQuest()
    return #self.daily_quests > 0 or (self.advance_quest ~= nil)
end

-- ====================================
-- Save/Load
-- ====================================

function MUSHA_QUEST:OnSave()
    local data = {}
    data.daily_quests = self.daily_quests
    data.advance_quest = self.advance_quest
    data.advance_round = self.advance_round
    data.advance_target = self.advance_target
    return data
end

function MUSHA_QUEST:OnLoad(data)
    if data then
        self.daily_quests = data.daily_quests or {}
        self.advance_quest = data.advance_quest or nil
        self.advance_round = data.advance_round or 1
        self.advance_target = data.advance_target or nil
    end

    -- 空则补发（首日/旧档无任务数据时）
    local has = #self.daily_quests > 0
    if not has then
        self:FillDailyQuests()
    end
    self:SyncToPanel()
end

return MUSHA_QUEST
