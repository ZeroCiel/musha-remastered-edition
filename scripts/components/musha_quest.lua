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
local DEBUG_QUEST = false  -- ★ 2026-09-28 用户拍板关闭（release blocker 清单）

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
    collect_gems = { redgem = true, greengem = true, bluegem = true },
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

    -- 每日任务（= 已接取、进行中）
    self.daily_quests = {}    -- {quest_id, progress, target, type, name, done, day}
    -- ★ 2026-09-28 酒馆委托板：**可接列表**（还没接的每日委托挂在酒馆里）
    --   用户拍板："玩家每日获得的任务都移动过去，接取了才会出现任务去进行，不用每日轮询"
    self.available_quests = {}
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
-- ★ 2026-09-28 酒馆委托板（服务端逻辑）
--   · available_quests = 酒馆板上挂着、还没接的委托
--   · daily_quests     = 已接取、进行中（上限仍是 DAILY_MAX=10，玩法不变）
--   · 换天**不再自动塞进行中**，只把可接列表补满；进不进行中由玩家点「接取」
--   · 转职任务 advance_quest 完全不动（卷轴/仪式那套照旧）
-- ====================================

-- 品质：按任务经验分档 —— 普通(灰) / 白 / 银 / 金
--   （用户："分普通（灰色）白色 银色 金色"；按 exp 分正好四档：
--     灰 8~10：见龙蝇/存活/制造/回复/科学机器　白 12~15：锅/野猪/蜘蛛/燃料/海象
--     银 18~20：火猎犬/格罗姆　金 ≥25：三色宝石）
local function QualityOf(exp)
    exp = exp or 0
    if exp >= 25 then return 4 end   -- 金
    if exp >= 18 then return 3 end   -- 银
    if exp >= 12 then return 2 end   -- 白
    return 1                          -- 普通（灰）
end

-- ★ 2026-09-28 用户（0.7.13 批）：同一委托最多 3 人同时接取
--   进度各自独立（daily_quests 本来就是每人一份组件数据 → 天然不共享，无需额外改）
--   「金色任务共享」后续版本再尝试，现在暂停
local QUEST_MAX_TAKERS = 3
local function CountQuestTakers(quest_id, exclude)
    local n = 0
    for _, p in ipairs(AllPlayers) do
        local q = p.components and p.components.musha_quest
        if q and q ~= exclude then
            for _, dq in ipairs(q.daily_quests or {}) do
                if dq.quest_id == quest_id then
                    n = n + 1
                    break
                end
            end
        end
    end
    return n
end

-- 把可接列表补满到 GetDailyCount() 条（已在进行中 / 已经挂着的不重复放）
function MUSHA_QUEST:RefreshAvailableQuests()
    if TheWorld and not TheWorld.ismastersim then return end
    if self.available_quests == nil then self.available_quests = {} end

    local skip = {}
    for _, q in ipairs(self.daily_quests or {}) do skip[q.quest_id] = true end
    for _, q in ipairs(self.available_quests) do skip[q.quest_id] = true end

    local room = self:GetDailyCount() - #self.available_quests
    if room <= 0 then return end

    for _, qid in ipairs(PickQuestsFromAll(room, skip)) do
        local q = MakeQuestEntry(qid)
        if q then
            q.quality = QualityOf(q.exp)
            table.insert(self.available_quests, q)
        end
    end

    if DEBUG_QUEST then
        local ids = {}
        for _, q in ipairs(self.available_quests) do
            ids[#ids + 1] = tostring(q.quest_id) .. "(Q" .. tostring(q.quality or 1) .. ")"
        end
        print("[Musha Quest] 酒馆可接列表补满: " .. table.concat(ids, ", "))
    end
end

-- 接取一条酒馆委托 → 移进"进行中"（面板/酒馆板的「接取」按钮走这条）
function MUSHA_QUEST:AcceptQuest(quest_id)
    if TheWorld and not TheWorld.ismastersim then return false, "server_only" end
    quest_id = tonumber(quest_id)
    if not quest_id then return false, "bad_id" end
    if self.available_quests == nil then self.available_quests = {} end

    for _, q in ipairs(self.daily_quests) do
        if q.quest_id == quest_id then return false, "already" end
    end
    if #self.daily_quests >= DAILY_MAX then return false, "full" end

    local idx
    for i, q in ipairs(self.available_quests) do
        if q.quest_id == quest_id then idx = i break end
    end
    if not idx then return false, "not_available" end

    -- ★ 0.7.13 批：同一委托最多 3 人同时接（各人进度独立、不共享）
    if CountQuestTakers(quest_id, self) >= QUEST_MAX_TAKERS then
        return false, "takers_full"
    end

    local q = table.remove(self.available_quests, idx)
    q.progress = 0
    q.done = false
    q.day = (TheWorld and TheWorld.state and TheWorld.state.cycles) or 0
    table.insert(self.daily_quests, q)

    self:RefreshAvailableQuests()   -- 补一条进来，板子不会越接越空
    self:SyncToPanel()
    if DEBUG_QUEST then
        print("[Musha Quest] 接取委托 " .. tostring(q.quest_id) .. " " .. tostring(q.name))
    end
    return true, q
end

-- ★ 2026-09-29 用户「任务面板的任务加上放弃」：把进行中的每日委托丢掉（面板详情子行的「放弃」按钮走这条）
--   · 进度清零：进度存在任务条目里，条目删了进度自然没了（不另外清字段）
--   · 放回酒馆可接列表**最前面** → 板上一眼看得到，能立刻重接、从 0 开始
--   · 不发奖励、不动每日配额（配额只在换天/手动补发时算，这里不算账）
--   · 已完成（q.done）的不让丢；转职任务不走这条（它有自己的 AbortAdvanceQuest）
--   · 放弃后别人接这同一委托的坑位也空出来（CountQuestTakers 数的是各人 daily_quests）
function MUSHA_QUEST:AbandonQuest(quest_id)
    if TheWorld and not TheWorld.ismastersim then return false, "server_only" end
    quest_id = tonumber(quest_id)
    if not quest_id then return false, "bad_id" end

    local idx, q
    for i, e in ipairs(self.daily_quests or {}) do
        if e.quest_id == quest_id then idx, q = i, e break end
    end
    if not idx then return false, "not_active" end
    if q.done then return false, "done" end

    table.remove(self.daily_quests, idx)

    -- 插回可接列表（列表已满就不插，避免酒馆板第 5 行被 AVAIL_MAX 挤掉）
    if self.available_quests == nil then self.available_quests = {} end
    local seen = false
    for _, e in ipairs(self.available_quests) do
        if e.quest_id == quest_id then seen = true break end
    end
    if not seen and #self.available_quests < self:GetDailyCount() then
        local back = MakeQuestEntry(quest_id)
        if back then
            back.quality = QualityOf(back.exp)
            table.insert(self.available_quests, 1, back)
        end
    end
    self:RefreshAvailableQuests()   -- 兜底补满（放弃只占一个坑时这里会另补一条别的委托）
    self:SyncToPanel()
    if DEBUG_QUEST then
        print("[Musha Quest] 放弃委托 " .. tostring(quest_id) .. " " .. tostring(q.name))
    end
    return true, q
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

    -- 2b. ★ 2026-09-15 修：转职任务也可能是 survive 类（用户报「接到转职任务存活5天，五天进度条一动不动」）
    --   根因：上面那个循环只遍历 daily_quests，转职任务挂在 self.advance_quest 上，
    --   而事件型推进（ProgressQuests）只处理 kill/collect/craft/discover 这类，
    --   没有任何地方给 advance_quest 的 survive 类型加天数 → 永远停在 0/5。
    local aq = self.advance_quest
    if aq and not aq.done and aq.type == "survive" then
        aq.progress = (aq.progress or 0) + 1
        if aq.progress >= aq.target then
            self:CompleteCurrentAdvance()      -- 到点即完成本轮（内部会推进轮次 / 第3轮进阶）
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

-- 新的一天 → **只补满酒馆可接列表**（2026-09-28 用户拍板）
-- ★ 历史：这里是"每天新增 GetDailyCount() 个直接塞进 daily_quests"（2026-09-12 修）。
--   2026-09-28 用户："玩家每日获得的任务都移动过去，接取了玩家才会出现任务去进行，
--   不用每日轮询" → 每日委托搬进酒馆板，**换天不再自动发进进行中**，
--   进行中只能靠玩家点「接取」；已接的（survive 跨天推进 / discover 隔日作废）
--   仍旧由 OnNewDay 处理，玩法不变。
function MUSHA_QUEST:GrantNewDayQuests()
    self:RefreshAvailableQuests()
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

    -- ★ 就职仪式待办中不再接新任务（先回祭坛把仪式做完）
    if self.advance_ceremony_pending then
        return false, "先回酒馆完成就职仪式"
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

-- ★★ 2026-09-17 就职仪式开关（用户拍板；对应设定文档「回到建筑进行最终交互，完成就职仪式」）
--   true  = 第 3 轮任务完成后**不立刻进阶**，要回祭坛做「就职仪式」（祭坛右键，见 musha_advance_altar.lua）
--   false = 旧行为：第 3 轮完成即自动进阶
local CEREMONY_ON_FINAL_ROUND = true

-- 转职任务完成 → 推进轮次；第 3 轮完成 → 回祭坛做就职仪式 → 进阶
function MUSHA_QUEST:CompleteAdvanceQuest()
    if not self.advance_quest then return end
    self.advance_quest = nil

    if self.advance_round >= 3 then
        -- ★ 仪式待办：只挂标记，真正进阶在 DoAdvanceCeremony()
        --   ⚠️ advance_target 必须留着 —— 仪式那一刻才知道要转成什么职业
        if CEREMONY_ON_FINAL_ROUND then
            self.advance_ceremony_pending = true
            if self.inst.components.talker then
                self.inst.components.talker:Say("第 3 轮考验完成！回到酒馆，完成就职仪式。", 6)
            end
            self:SyncToPanel()
            return
        end
        -- 进阶完成
        local pc = self.inst.components.musha_profession_component
        if pc then
            -- 设置进阶职业并清转职状态
            pc.userdata.carrer_special = self.advance_target
            pc.userdata.has_advanced = true
            pc.userdata.advance_round = nil
            pcall(function() pc:ApplyProfessionData() end)
            -- ★ 2026-09-14 用户：「二转不该再给技能面板」→ 这里不再发 musha_skillbook
            --   （技能书 = 技能面板，只在一转时给一本，见 scripts/prefabs/musha_jobbook_warrior.lua）
            -- ★ 2026-09-17 改：二转赠礼 = 一卷【技能卷轴】（右键展开 → 解锁本职业专属技能）
            if pc.GrantAdvanceGift then
                pcall(function() pc:GrantAdvanceGift(self.advance_target) end)
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
            self.inst.components.talker:Say("转职任务完成！可去酒馆接取下一轮（" .. self.advance_round .. "/3）。", 4)
        end
    end
    self:SyncToPanel()
end

-- 就职仪式是否待办（第 3 轮任务已完成、等玩家回祭坛）
function MUSHA_QUEST:IsCeremonyPending()
    return self.advance_ceremony_pending == true
end

-- 回祭坛完成【就职仪式】：真正把进阶职业落下去 + 发二转赠礼（技能卷轴）
--   由 scripts/prefabs/musha_advance_altar.lua 的右键（MUSHA_OPEN_ALTAR）调
--   返回 true = 这次完成了仪式（祭坛那边就不再开容器）
function MUSHA_QUEST:DoAdvanceCeremony(doer)
    if not self.advance_ceremony_pending then return false end
    local pc = self.inst.components.musha_profession_component
    if pc == nil then return false end

    -- ★★ 2026-09-18 改（用户拍板 C + 两枚徽记）：
    --   仪式**不再直接进阶**，而是发两枚方向徽记（剑士 / 近卫）；用掉其中一枚才落地
    --   （pc:UseAdvanceCrest → 设职业 + 发赠礼 + 清仪式待办）。两枚共用绑定 ID。
    --   仪式待办（advance_ceremony_pending）**先留着**：祭坛继续不补卷、不接新任务，直到选定方向。
    local choices = (pc.GetAdvanceChoices ~= nil) and pc:GetAdvanceChoices() or {}
    if #choices > 1 and pc.GrantAdvanceCrests ~= nil then
        local ok, ret = pcall(pc.GrantAdvanceCrests, pc)
        if ok and ret then
            if self.inst.components.talker then
                self.inst.components.talker:Say("就职仪式准备好了——用掉你手里的其中一枚徽记。", 6)
            end
            self:SyncToPanel()
            print(string.format("[Musha] %s 就职仪式 → 已发方向徽记 [%s]（等玩家选择）",
                tostring(self.inst and self.inst.prefab), table.concat(choices, "/")))
            return true
        end
        print("[Musha ERROR] 发方向徽记失败，退回旧的直接进阶流程：" .. tostring(ret))
    end

    -- ===== 旧流程（单出口职业 / 发徽记失败时的兜底，保持原样）=====
    local target = self.advance_target
    pc.userdata.carrer_special = target
    pc.userdata.has_advanced = true
    pc.userdata.advance_round = nil
    pcall(function() pc:ApplyProfessionData() end)

    -- 二转赠礼（用户 2026-09-17：「转职之后给技能卷轴」）—— 0 级不直接加，改成发一卷
    --   展开后由 pc:UnlockSkillByBook() 解锁（剑士 = 剑气斩 Lv1）
    --   ⚠️ 必须 pcall：赠礼这一步出任何错都不该把"仪式待办"卡住（否则每次右键祭坛都崩同一个地方）
    local gave = false
    if pc.GrantAdvanceGift then
        local ok, ret = pcall(pc.GrantAdvanceGift, pc, target)
        if not ok then
            print("[Musha ERROR] 就职仪式赠礼失败（已跳过，仪式照常完成）：" .. tostring(ret))
        else
            gave = ret and true or false
        end
    end

    self.advance_ceremony_pending = nil
    self.advance_round = 1
    self.advance_target = nil

    if self.inst.components.talker then
        self.inst.components.talker:Say("就职仪式完成！当前职业：" .. tostring(target), 6)
    end
    self:SyncToPanel()
    print(string.format("[Musha] %s 完成就职仪式 → %s（赠礼技能卷轴=%s）",
        tostring(self.inst and self.inst.prefab), tostring(target), gave and "yes" or "no"))
    return true
end

-- 放弃转职任务（重置轮次）
function MUSHA_QUEST:AbortAdvanceQuest()
    self.advance_quest = nil
    self.advance_ceremony_pending = nil
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
            list = { "redgem", "greengem", "bluegem" }
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
    -- ★ 2026-09-16：用**原版 prefab 名**（redgem/greengem/bluegem）；ruby/emerald/sapphire 原版不存在
    if item_type == "redgem" or item_type == "greengem" or item_type == "bluegem" then
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

-- 存活天数：由 OnNewDay 内单独处理（survive 每日 +1；★ 2026-09-15 起**每日任务和转职任务都推进**）

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
            ty = q.type, -- ★ 2026-09-27：面板详情子行"需要什么"用（json 通道通用，直接带）
            exp = q.exp, --   + "奖励：职业经验 N" 预览
        })
    end

    -- ★ 2026-09-28 酒馆委托板：把"还没接的"一起推给客户端（q = 品质 1灰/2白/3银/4金）
    pc.userdata.available_quests = {}
    for _, q in ipairs(self.available_quests or {}) do
        table.insert(pc.userdata.available_quests, {
            id = q.quest_id,
            n = q.name,
            t = q.target,
            done = false,
            ty = q.type,
            exp = q.exp,
            q = q.quality or QualityOf(q.exp),
            tk = CountQuestTakers(q.quest_id, nil),   -- ★ 0.7.13：已接人数（板上显示 n/3）
        })
    end

    if self.advance_ceremony_pending then
        -- ★ 2026-09-17：第 3 轮任务已完成、等回祭坛做就职仪式 —— 这时 advance_quest 是 nil，
        --   面板上会"什么都没了"（用户报「做完没反应」）。塞一行**假任务**当提示，
        --   让玩家一眼看到"回酒馆完成就职仪式"（画 ✓，不是可推进的任务）。
        -- ★★ 2026-09-18：仪式做完后 pending 仍会留着（等玩家用徽记选方向）→ 分两句提示
        -- ★ 2026-09-29 英文第二批：服务端**只发 key + 职业 key 列表**（n 兜底保留中文），
        --   客户端按自己的语言用 STRINGS.MUSHA_PANEL 拼句（专用服务器上 Profile=nil，
        --   服务端读不到玩家语言 → 服务端拼句必然错人）。
        local hint = "就职仪式：回酒馆右键完成"
        local nkey, ck = "CEREMONY_HINT", nil
        if pc.userdata.advance_choice_pending == true then
            local names = {}
            local choices = (pc.GetAdvanceChoices ~= nil) and pc:GetAdvanceChoices() or {}
            for _, c in ipairs(choices) do
                names[#names + 1] = STRINGS["MUSHA_JOB_" .. string.upper(tostring(c))] or tostring(c)
            end
            hint = "选定方向：用掉手里的徽记（" .. table.concat(names, " / ") .. "）"
            nkey, ck = "CEREMONY_CHOICE", choices
        end
        pc.userdata.advance_quest = {
            id = "ceremony",
            n = hint,
            nkey = nkey,   -- ★ 09-29：STRINGS.MUSHA_PANEL 的 key
            ck = ck,       -- ★ 09-29：职业 key 列表（客户端本地查 STRINGS.MUSHA_JOB_* 拼名）
            p = 1,
            t = 1,
            done = true,
        }
    elseif self.advance_quest then
        pc.userdata.advance_quest = {
            id = self.advance_quest.quest_id,
            n = self.advance_quest.name,
            p = self.advance_quest.progress,
            t = self.advance_quest.target,
            done = self.advance_quest.done or false,
            ty = self.advance_quest.type, -- ★ 2026-09-27：同上，详情子行用
            exp = self.advance_quest.exp,
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
    data.available_quests = self.available_quests   -- ★ 09-28 酒馆可接列表
    data.advance_quest = self.advance_quest
    data.advance_round = self.advance_round
    data.advance_target = self.advance_target
    data.advance_ceremony_pending = self.advance_ceremony_pending
    return data
end

function MUSHA_QUEST:OnLoad(data)
    if data then
        self.daily_quests = data.daily_quests or {}
        self.available_quests = data.available_quests or {}   -- ★ 09-28 旧档 = 空，下面补满
        self.advance_quest = data.advance_quest or nil
        self.advance_round = data.advance_round or 1
        self.advance_target = data.advance_target or nil
        self.advance_ceremony_pending = data.advance_ceremony_pending or nil
    else
        self.available_quests = {}
    end

    -- ★ 2026-09-28 改：不再 FillDailyQuests()（那会把每日任务**自动塞进行中**）。
    --   每日委托现在挂酒馆板上，只有玩家点「接取」才进 daily_quests。
    --   这里只补满**可接列表**（首日/旧档无数据时才有东西可接）。
    self:RefreshAvailableQuests()
    self:SyncToPanel()
end

return MUSHA_QUEST
