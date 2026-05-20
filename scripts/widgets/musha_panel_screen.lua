-- ====================================
-- musha_panel_screen.lua
-- 职业面板 UI — 纸片风格，右下角显示
-- ====================================
print("[Musha Panel] 文件开始加载")

local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"

-- 安全读取全局 STRINGS（绕过 strict 模式）
local function GetGlobalSTRINGS()
    local ok, s = pcall(function() return rawget(_G, "STRINGS") end)
    if ok and s then return s end
    return STRINGS
end

local function JobName(key)
    if not key or key == "" then return "无职业" end
    local S = GetGlobalSTRINGS()
    local name = S["MUSHA_JOB_" .. string.upper(key)]
    if name and name ~= "" then return name end
    -- fallback: 键名首字母大写
    return key:gsub("^%l", string.upper)
end

-- 任务名称表（避免依赖全局 GetQuestName 在 strict 模式下不可用）
local QUEST_NAMES = {
    [1] = "见到龙蝇",
    [2] = "击杀20只蜘蛛",
    [3] = "存活5天",
    [4] = "找到格罗姆",
    [5] = "获得七个噩梦燃料",
    [6] = "收集三色宝石",
    [7] = "制造20个物品",
    [8] = "收获五次烹饪锅",
    [9] = "击败野猪x8",
    [10] = "击败五只火猎犬",
    [11] = "找到海象营地",
    [12] = "使用回复技能达到5次",
    [13] = "建造一个科学机器",
}

local function QuestName(quest_id)
    return QUEST_NAMES[quest_id] or "未知任务"
end

local function CreatePanelScreen(owner)
    print("[Musha Panel] CreatePanelScreen owner=" .. tostring(owner))
    local self = Widget()

    self.owner = owner
    self.playing = false
    owner.screen_musha_panel = self
    -- 监听服务端 PushEvent 打开面板
    owner:ListenForEvent("musha_open_skill_panel", function()
        if self and not self.playing then
            self:ShowPanel()
        end
    end)

    -- 不撑满全屏，只占右下角
    self:SetScaleMode(SCALEMODE_FILLSCREEN)
    self:SetHAnchor(0)
    self:SetVAnchor(0)
    self:SetPosition(0, 0, 0)
    self:Hide()

    -- 纸背景（bookpage_bg）— 原图700x1026，放大3倍视觉效果
    self.bg = self:AddChild(Image("images/bookpage_bg.xml", "bookpage_bg.tex"))
    self.bg:SetSize(1000, 1467)
    self.bg:SetScale(0.54) -- 0.36 * 3 = 1.08，实际渲染约1296x1878
    self.bg:SetPosition(-540, 90)

    -- ===== 头像 =====
    self.avatar = self.bg:AddChild(Image("images/avatars/avatar_musha.xml", "avatar_musha.tex"))
    self.avatar:SetSize(200, 200)
    self.avatar:SetPosition(-260, 450)

    -- 职业名 — 头像上方
    self.job_text = self.bg:AddChild(Text(UIFONT, 54))
    self.job_text:SetString("")
    self.job_text:SetColour(0.8, 0.6, 0.3, 1)
    self.job_text:SetPosition(-20, 530)

    -- ===== 等级/经验 — 头像右侧 =====
    self.level_text = self.bg:AddChild(Text(UIFONT, 42))
    self.level_text:SetString("Lv.1")
    self.level_text:SetColour(1, 1, 1, 1)
    self.level_text:SetPosition(300, 530)

    -- 经验条背景 — 职业名下方靠左
    self.exp_bg = self.bg:AddChild(Image("images/global.xml", "square.tex"))
    self.exp_bg:SetSize(400, 20)
    self.exp_bg:SetPosition(-20, 455)
    self.exp_bg:SetTint(0.3, 0.3, 0.3, 0.6)

    -- 经验条填充
    self.exp_fill = self.bg:AddChild(Image("images/global.xml", "square.tex"))
    self.exp_fill:SetSize(200, 20)
    self.exp_fill:SetPosition(-120, 455)
    self.exp_fill:SetTint(0.2, 0.6, 1.0, 0.9)

    -- 经验数值 — 经验条右侧
    self.exp_text = self.bg:AddChild(Text(UIFONT, 28))
    self.exp_text:SetString("50/100")
    self.exp_text:SetColour(1, 1, 1, 0.7)
    self.exp_text:SetPosition(400, 455)

    -- ===== 分隔线 =====
    self.divider = self.bg:AddChild(Text(UIFONT, 24))
    self.divider:SetString("━━━━━━━━━━━━")
    self.divider:SetColour(0.5, 0.4, 0.3, 0.6)
    self.divider:SetPosition(-60, 310)

    -- ===== 任务区域（替代被动技能）=====
    self.quest_title = self.bg:AddChild(Text(UIFONT, 36))
    self.quest_title:SetString("转职任务")
    self.quest_title:SetColour(0.8, 0.6, 0.3, 1)
    self.quest_title:SetPosition(-60, 270)

    self.quest_slots = {}
    for i = 1, 3 do
        local y = 210 - (i - 1) * 55
        local name = self.bg:AddChild(Text(UIFONT, 24))
        name:SetString("")
        name:SetColour(0.9, 0.9, 0.9, 1)
        name:SetPosition(-240, y)

        local status = self.bg:AddChild(Text(UIFONT, 22))
        status:SetString("")
        status:SetColour(0.6, 0.6, 0.6, 1)
        status:SetPosition(100, y)

        self.quest_slots[i] = { name = name, status = status }
    end

    -- 从 replica 监听数据更新（替代 OnUpdate 轮询）
    local function OnGameDataChanged()
        if not self or not self.owner then return end
        local replica = self.owner.replica.musha_profession_component
        local cached = replica and replica.cached_data
        if not cached or not cached.userdata then return end
        local md = cached.userdata

        local job_name = JobName(md.carrer_base)
        self.job_text:SetString(job_name)

        local lv = md.level or 0
        local exp = md.exp or 0
        local exp_max = md.exp_to_next or 1
        self.level_text:SetString("Lv." .. lv)
        self.exp_text:SetString(exp .. "/" .. exp_max)
        local pct = exp_max > 0 and math.min(exp / exp_max, 1) or 0
        self.exp_fill:SetSize(400 * pct, 20)

        -- 任务数据显示
        local qa = md.quests_for_advance or {}
        local qd = md.quests_for_advance_done or {}
        local has_task = next(qa) ~= nil
        self.quest_title:SetString(has_task and "转职任务" or "暂无任务")
        for i = 1, 3 do
            local slot = self.quest_slots[i]
            local quest_id = qa[i]
            if quest_id then
                local qname = QuestName(quest_id)
                local done = qd[i] == true
                slot.name:SetString(qname)
                slot.name:SetColour(done and 0.4 or 0.9, done and 0.8 or 0.9, done and 0.4 or 0.9, 1)
                slot.status:SetString(done and "✓ 已完成" or "进行中")
                slot.status:SetColour(done and 0.3 or 0.6, done and 0.8 or 0.6, done and 0.3 or 0.6, 1)
            else
                slot.name:SetString("")
                slot.status:SetString("")
            end
        end
    end

    -- 监听所有 dirty 事件
    local replica = owner.replica.musha_profession_component
    if replica then
        owner:ListenForEvent("gamedata_dirty", OnGameDataChanged)
        owner:ListenForEvent("warrior_dirty", OnGameDataChanged)
        owner:ListenForEvent("saber_dirty", OnGameDataChanged)
        owner:ListenForEvent("guardian_dirty", OnGameDataChanged)
        owner:ListenForEvent("mage_dirty", OnGameDataChanged)
    end

    -- 初始刷新一次
    OnGameDataChanged()

    print("[Musha Panel] UI 创建完成")

    -- 从 replica 刷新数据
    function self:Refresh()
        if not self.owner then
            return
        end
        local replica = self.owner.replica and self.owner.replica.musha_profession_component
        if not replica then
            return
        end
        local cd = replica.cached_data
        if not cd or not cd.userdata then
            return
        end
        local md = cd.userdata

        -- 职业名
        local job_name = JobName(md.carrer_base)
        self.job_text:SetString(job_name)

        -- 等级/经验
        local lv = md.level or 0
        local exp = md.exp or 0
        local exp_max = md.exp_to_next or 1
        self.level_text:SetString("Lv." .. lv)
        self.exp_text:SetString(exp .. "/" .. exp_max)
        local pct = exp_max > 0 and math.min(exp / exp_max, 1) or 0
        self.exp_fill:SetSize(400 * pct, 20)

        -- 任务数据刷新
        local qa = md.quests_for_advance or {}
        local qd = md.quests_for_advance_done or {}
        local has_task = next(qa) ~= nil
        self.quest_title:SetString(has_task and "转职任务" or "暂无任务")
        for i = 1, 3 do
            local slot = self.quest_slots[i]
            local quest_id = qa[i]
            if quest_id then
                local qname = QuestName(quest_id)
                local done = qd[i] == true
                slot.name:SetString(qname)
                slot.name:SetColour(done and 0.4 or 0.9, done and 0.8 or 0.9, done and 0.4 or 0.9, 1)
                slot.status:SetString(done and "✓ 已完成" or "进行中")
                slot.status:SetColour(done and 0.3 or 0.6, done and 0.8 or 0.6, done and 0.3 or 0.6, 1)
            else
                slot.name:SetString("")
                slot.status:SetString("")
            end
        end
    end

    -- 显示/隐藏
    function self:ShowPanel()
        if self.playing then
            return
        end
        self.playing = true
        self:Refresh()
        self:Show()
        self.focus = true
        if TheInput and KEY_ESCAPE and not self._key_handler then
            self._key_handler = TheInput:AddKeyDownHandler(KEY_ESCAPE, function()
                self:HidePanel()
            end)
        end
    end

    function self:HidePanel()
        if not self.playing then
            return
        end
        self.playing = false
        self.focus = false
        if self._key_handler then
            self._key_handler:Remove()
            self._key_handler = nil
        end
        self:Hide()
    end

    function self:OnMouseButton(button, down, x, y)
        if down then
            self:HidePanel()
        end
        return true
    end

    function self:OnRemove()
        self.playing = false
        if self._key_handler then
            self._key_handler:Remove()
            self._key_handler = nil
        end
    end

    return self
end

print("[Musha Panel] 返回 CreatePanelScreen")
return CreatePanelScreen
