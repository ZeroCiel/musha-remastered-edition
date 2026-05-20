-- ====================================
-- musha_skillui.lua
-- 客户端技能书 UI widget
-- 显示头像/EXP/MP/技能列表/加点按钮
-- 右键翻页
-- ====================================
local _ENV = _G

-- 每页显示技能数（不含头部）
local SKILLS_PER_PAGE = 5

-- 本地常量定义（避免依赖 modmain 加载时序）
local MUSHA_JOB_NONE = 0
local MUSHA_JOB_WARRIOR = 1
local MUSHA_JOB_MAGE = 2
local MUSHA_JOB_RANGER = 3
local MUSHA_JOB_ASSASSIN = 4
local MUSHA_JOB_SWORDSMAN = 11
local MUSHA_JOB_GUARDIAN = 12
local MUSHA_JOB_ALCHEMIST = 21
local MUSHA_JOB_ELEMENTALIST = 22
local MUSHA_JOB_BARD = 31
local MUSHA_JOB_MOONSHADOW = 41

local MUSHA_ADVANCE_MAP = {
    [MUSHA_JOB_WARRIOR] = { MUSHA_JOB_SWORDSMAN, MUSHA_JOB_GUARDIAN },
    [MUSHA_JOB_MAGE] = { MUSHA_JOB_ALCHEMIST, MUSHA_JOB_ELEMENTALIST },
    [MUSHA_JOB_RANGER] = { MUSHA_JOB_BARD },
    [MUSHA_JOB_ASSASSIN] = { MUSHA_JOB_MOONSHADOW },
}

-- UI 回调接口
local MUSHA_SKILLUI = Class(function(self, inst)
    self.inst = inst

    -- UI 状态
    self._is_open = false
    self._current_page = 1
    self._total_pages = 1

    -- 数据缓存
    self._skill_points = 0
    self._level = 1
    self._exp = 0
    self._exp_needed = 1
    self._job = MUSHA_JOB_NONE
    self._advance_job = MUSHA_JOB_NONE
    self._skills = {}         -- { skill_id = level, ... }
    self._skill_list = {}     -- 有序的技能列表（带数据）

    -- widget 实例
    self._widget = nil
    self._root = nil
end,
nil,
{
    OnRemoveFromEntity = function(self)
        self:CloseUI()
    end,
})

-- ====== 数据接收（从服务端或 RPC） ======
function MUSHA_SKILLUI:ReceiveData(data)
    if data.skill_points ~= nil then self._skill_points = data.skill_points end
    if data.level ~= nil then self._level = data.level end
    if data.exp ~= nil then self._exp = data.exp end
    if data.job ~= nil then self._job = data.job end
    if data.advance_job ~= nil then self._advance_job = data.advance_job end
    if data.skills then
        self._skills = data.skills
    end

    -- 计算 EXP
    self._exp_needed = self:CalcExpNeeded()

    -- 更新技能列表
    self:RefreshSkillList()

    -- 如果 UI 已打开则刷新
    if self._is_open and self._root then
        self:Render()
    end
end

function MUSHA_SKILLUI:CalcExpNeeded()
    return math.floor(50 * self._level * (1 + self._level / 10))
end

function MUSHA_SKILLUI:RefreshSkillList()
    -- 根据当前职业获取技能列表
    local job_to_check = self._job
    if self._advance_job ~= MUSHA_JOB_NONE then
        job_to_check = self._advance_job
    end

    self._skill_list = rawget(_G, "GetJobSkillList")(job_to_check)
    if #self._skill_list == 0 then
        -- 如果进阶职业没技能，尝试基础职业
        for base_id, adv_map in pairs(MUSHA_ADVANCE_MAP) do
            for _, adv_id in ipairs(adv_map) do
                if adv_id == job_to_check then
                    self._skill_list = GetJobSkillList(base_id)
                    break
                end
            end
            if #self._skill_list > 0 then break end
        end
    end

    self._total_pages = math.max(1, math.ceil(#self._skill_list / SKILLS_PER_PAGE))
    if self._current_page > self._total_pages then
        self._current_page = self._total_pages
    end
end

-- ====== 打开 / 关闭 UI ======
function MUSHA_SKILLUI:OpenUI()
    if self._is_open then return end
    self._is_open = true

    -- 请求服务端数据
    if TheWorld.ismastersim then
        -- 单机：直接取数据
        local pc = self.inst.components.musha_profession_component
        local skills_comp = self.inst.components.musha_skills
        if pc and skills_comp then
            self:ReceiveData({
                skill_points = pc.mydata.skill_points or 0,
                level = pc.mydata.level or 0,
                exp = pc.mydata.exp or 0,
                job = pc.mydata.carrer_base,
                advance_job = pc.mydata.carrer_special,
                skills = skills_comp.skill_levels,
            })
        end
    else
        -- 联机：通过 RPC 请求
        SendModRPCToServer(
            GetModRPCIndex("musha_request_skill_data")
        )
    end

    self:CreateWidget()
end

function MUSHA_SKILLUI:CloseUI()
    if not self._is_open then return end
    self._is_open = false
    if self._widget then
        self._widget:Kill()
        self._widget = nil
        self._root = nil
    end
    -- 解锁鼠标/键盘
    TheFrontEnd:GetMouseConsumed()
end

-- ====== 创建 UI ======
function MUSHA_SKILLUI:CreateWidget()
    -- 使用 DST FrontEnd 的 Widget 系统
    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local Text = require "widgets/text"
    local Button = require "widgets/button"

    -- 阻止点击穿透
    TheFrontEnd:GetMouseConsumed()

    -- 根 widget
    self._root = Widget("musha_skill_root")
    self._root:SetVAnchor(ANCHOR_MIDDLE)
    self._root:SetHAnchor(ANCHOR_MIDDLE)
    self._root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self._root:SetPosition(0, 50, 0)

    -- 背景遮罩（点击关闭）
    local bg = self._root:AddChild(Image("images/global.xml", "square.tex"))
    bg:SetScale(RESOLUTION_X, RESOLUTION_Y)
    bg:SetPosition(0, 0, 0)
    bg:SetTint(0, 0, 0, 0.5)
    bg:SetClickable(true)
    bg:SetOnClick(function()
        self:CloseUI()
    end)

    -- 主面板（书页容器）
    local panel = self._root:AddChild(Widget("musha_panel"))
    panel:SetPosition(0, 0, 0)
    panel:SetClickable(false)

    -- 渲染内容
    self:Render()

    -- 注册鼠标事件
    self._root:SetOnAnyPress(function(button, down)
        -- 只处理鼠标右键按下
        if not down and button == MOUSEBUTTON_RIGHT then
            self:OnRightClick()
        end
    end)

    self._widget = self._root
    TheFrontEnd:Push(self._widget)
end

-- ====== 翻页 ======
function MUSHA_SKILLUI:OnRightClick()
    if self._total_pages <= 1 then
        self:CloseUI()
        return
    end
    -- 翻到下一页，到尾页则关闭
    self._current_page = self._current_page + 1
    if self._current_page > self._total_pages then
        self:CloseUI()
        return
    end
    self:Render()
end

-- ====== 渲染 UI ======
function MUSHA_SKILLUI:Render()
    -- 清除旧内容（保留 root 和 bg）
    local old_widgets = {}
    for i, child in ipairs(self._root.children) do
        if child ~= self._root.children[1] then
            table.insert(old_widgets, child)
        end
    end
    for _, w in ipairs(old_widgets) do
        self._root:RemoveChild(w)
    end

    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local Text = require "widgets/text"
    local Button = require "widgets/button"

    local panel = self._root:AddChild(Widget("musha_panel"))
    panel:SetClickable(false)

    -- 书页背景
    local page_bg = panel:AddChild(Image("images/bookpage_bg.xml", "bookpage_bg.tex"))
    page_bg:SetScale(250, 340)
    page_bg:SetPosition(0, 0, 0)

    -- 计算当前页的技能
    local start_idx = (self._current_page - 1) * SKILLS_PER_PAGE + 1
    local end_idx = math.min(start_idx + SKILLS_PER_PAGE - 1, #self._skill_list)

    -- 第一页显示头像+信息
    if self._current_page == 1 then
        self:RenderHeader(panel)
    end

    -- 技能点行
    local sp_y = 125
    if self._current_page == 1 then
        sp_y = 65
    end

    local sp_text = panel:AddChild(Text(UIFONT, 22, "技能点  " .. self._skill_points .. " 可用"))
    sp_text:SetPosition(0, sp_y, 0)
    sp_text:SetColour(0.23, 0.16, 0.10, 1)
    sp_text:SetHAlign(ANCHOR_MIDDLE)

    -- 渲染技能列表
    local skill_y = sp_y - 30

    for i = start_idx, end_idx do
        local entry = self._skill_list[i]
        local skill_def = entry.data
        local skill_lv = self._skills[entry.id] or 0
        local is_learned = skill_lv > 0
        local is_maxed = skill_lv >= skill_def.max_level
        local can_upgrade = (not is_maxed) and self._skill_points > 0
            and (not skill_def.req_lv[skill_lv + 1] or self._level >= skill_def.req_lv[skill_lv + 1])
        local is_locked = not is_learned and (skill_def.req_level and self._level < skill_def.req_level)

        self:RenderSkillItem(panel, entry.id, skill_def, skill_lv, can_upgrade, is_locked, skill_y)
        skill_y = skill_y - 55
    end

    -- 分页指示
    if self._total_pages > 1 then
        local page_text = panel:AddChild(Text(UIFONT, 18, "— 右键翻页 " .. self._current_page .. "/" .. self._total_pages .. " —"))
        page_text:SetPosition(0, skill_y - 15, 0)
        page_text:SetColour(0.54, 0.48, 0.38, 1)
        page_text:SetHAlign(ANCHOR_MIDDLE)
    end

    -- 关闭提示
    local close_text = panel:AddChild(Text(UIFONT, 16, "— 右键关闭 —"))
    close_text:SetPosition(0, skill_y - 40, 0)
    close_text:SetColour(0.54, 0.48, 0.38, 1)
    close_text:SetHAlign(ANCHOR_MIDDLE)
end

-- ====== 渲染头部 ======
function MUSHA_SKILLUI:RenderHeader(parent)
    local Image = require "widgets/image"
    local Text = require "widgets/text"

    -- 头像框
    local avatar_bg = parent:AddChild(Image("images/global.xml", "square.tex"))
    avatar_bg:SetScale(38, 38)
    avatar_bg:SetPosition(-85, 155, 0)
    avatar_bg:SetTint(0.78, 0.69, 0.50, 1)

    -- 头像
    local avatar_img = parent:AddChild(Image("images/global.xml", "square.tex"))
    avatar_img:SetScale(34, 34)
    avatar_img:SetPosition(-85, 155, 0)
    avatar_img:SetTint(0.6, 0.5, 0.3, 1)

    -- 名字
    local name_text = parent:AddChild(Text(UIFONT, 28, self.inst.name or "???"))
    name_text:SetPosition(-30, 163, 0)
    name_text:SetColour(0.23, 0.16, 0.10, 1)
    name_text:SetHAlign(ANCHOR_LEFT)

    -- EXP 条背景
    local exp_bg = parent:AddChild(Image("images/global.xml", "square.tex"))
    exp_bg:SetScale(150, 10)
    exp_bg:SetPosition(-30, 147, 0)
    exp_bg:SetTint(0.85, 0.78, 0.65, 1)

    -- EXP 条填充
    local exp_pct = self._exp_needed > 0 and (self._exp / self._exp_needed) or 0
    exp_pct = math.min(1, math.max(0, exp_pct))
    local exp_fill = parent:AddChild(Image("images/global.xml", "square.tex"))
    exp_fill:SetScale(150 * exp_pct, 10)
    exp_fill:SetPosition(-30 - 75 + (150 * exp_pct / 2), 147, 0)
    exp_fill:SetTint(0.38, 0.69, 0.38, 1)

    -- EXP 文字
    local exp_text = parent:AddChild(Text(UIFONT, 14, "EXP " .. self._exp .. "/" .. self._exp_needed))
    exp_text:SetPosition(65, 147, 0)
    exp_text:SetColour(0.42, 0.35, 0.25, 1)
    exp_text:SetHAlign(ANCHOR_RIGHT)

    -- MP 条背景
    local mp_bg = parent:AddChild(Image("images/global.xml", "square.tex"))
    mp_bg:SetScale(150, 10)
    mp_bg:SetPosition(-30, 134, 0)
    mp_bg:SetTint(0.85, 0.78, 0.65, 1)

    -- MP 条填充（表演用）
    local mp_fill = parent:AddChild(Image("images/global.xml", "square.tex"))
    mp_fill:SetScale(150 * 0.42, 10)
    mp_fill:SetPosition(-30 - 75 + (150 * 0.42 / 2), 134, 0)
    mp_fill:SetTint(0.25, 0.41, 0.75, 1)

    local mp_text = parent:AddChild(Text(UIFONT, 14, "MP 42/100"))
    mp_text:SetPosition(65, 134, 0)
    mp_text:SetColour(0.42, 0.35, 0.25, 1)
    mp_text:SetHAlign(ANCHOR_RIGHT)

    -- 分割线
    local divider = parent:AddChild(Image("images/global.xml", "square.tex"))
    divider:SetScale(220, 1)
    divider:SetPosition(0, 125, 0)
    divider:SetTint(0.63, 0.50, 0.31, 0.6)
end

-- ====== 渲染单个技能项 ======
function MUSHA_SKILLUI:RenderSkillItem(parent, skill_id, skill_def, level, can_upgrade, is_locked, y_pos)
    local Image = require "widgets/image"
    local Text = require "widgets/text"
    local Button = require "widgets/button"

    -- 透明度
    local alpha = is_locked and 0.4 or 1.0

    -- 图标框
    local icon_bg = parent:AddChild(Image("images/global.xml", "square.tex"))
    icon_bg:SetScale(26, 26)
    icon_bg:SetPosition(-95, y_pos, 0)
    icon_bg:SetTint(0.78, 0.69, 0.50, alpha)

    -- 图标文字
    local icon_text = parent:AddChild(Text(UIFONT, 20, is_locked and "?" or skill_def.icon or "?"))
    icon_text:SetPosition(-95, y_pos, 0)
    icon_text:SetColour(0.42, 0.31, 0.25, alpha)
    icon_text:SetHAlign(ANCHOR_MIDDLE)
    icon_text:SetVAlign(ANCHOR_MIDDLE)

    -- 技能名
    local name_str = skill_def.name
    if is_locked then
        name_str = "???"
    elseif level > 0 then
        name_str = name_str .. "  Lv." .. level
    else
        name_str = name_str .. "  Lv.0"
    end

    local name_text = parent:AddChild(Text(UIFONT, 22, name_str))
    name_text:SetPosition(-62, y_pos + 6, 0)
    name_text:SetColour(0.23, 0.16, 0.10, alpha)
    name_text:SetHAlign(ANCHOR_LEFT)

    -- 描述
    local desc_str = ""
    if is_locked then
        desc_str = "需要等级 " .. skill_def.req_level
    elseif level > 0 then
        local lv_data = skill_def.levels[level]
        if lv_data then
            desc_str = skill_def.desc
            for k, v in pairs(lv_data) do
                desc_str = desc_str:gsub("{" .. k .. "}", tostring(v))
            end
        end
    else
        local lv1_req = skill_def.req_lv and skill_def.req_lv[1]
        if lv1_req and self._level < lv1_req then
            desc_str = "需要等级 " .. lv1_req
        else
            local lv1_data = skill_def.levels[1]
            if lv1_data then
                desc_str = skill_def.desc
                for k, v in pairs(lv1_data) do
                    desc_str = desc_str:gsub("{" .. k .. "}", tostring(v))
                end
            end
        end
    end

    local desc_text = parent:AddChild(Text(UIFONT, 16, desc_str))
    desc_text:SetPosition(-62, y_pos - 10, 0)
    desc_text:SetColour(0.48, 0.42, 0.31, alpha)
    desc_text:SetHAlign(ANCHOR_LEFT)

    -- 加号按钮
    if can_upgrade and not is_locked then
        local plus_btn = parent:AddChild(Button("images/global.xml", "square.tex", nil, nil, nil, nil))
        plus_btn:SetScale(14, 14)
        plus_btn:SetPosition(-70, y_pos + 6, 0)
        plus_btn:SetNormalTint(0.54, 0.69, 0.25, 1)
        plus_btn:SetHoverTint(0.63, 0.82, 0.31, 1)
        plus_btn:SetOnClick(function()
            self:OnUpgradeSkill(skill_id)
        end)

        local plus_text = parent:AddChild(Text(UIFONT, 18, "+"))
        plus_text:SetPosition(-70, y_pos + 6, 0)
        plus_text:SetColour(1, 1, 1, 1)
        plus_text:SetHAlign(ANCHOR_MIDDLE)
        plus_text:SetVAlign(ANCHOR_MIDDLE)
    end

    -- 下一级提示
    if level > 0 and level < skill_def.max_level then
        local req_lv_str = ""
        if skill_def.req_lv and skill_def.req_lv[level + 1] then
            req_lv_str = " Lv." .. skill_def.req_lv[level + 1]
        end
        local next_text = parent:AddChild(Text(UIFONT, 14, "→" .. req_lv_str))
        next_text:SetPosition(80, y_pos + 6, 0)
        next_text:SetColour(0.54, 0.48, 0.38, alpha)
        next_text:SetHAlign(ANCHOR_RIGHT)
    elseif level >= skill_def.max_level then
        local max_text = parent:AddChild(Text(UIFONT, 14, "MAX"))
        max_text:SetPosition(80, y_pos + 6, 0)
        max_text:SetColour(0.63, 0.50, 0.31, alpha)
        max_text:SetHAlign(ANCHOR_RIGHT)
    end

    -- 等级需求（锁定状态）
    if is_locked then
        local lock_text = parent:AddChild(Text(UIFONT, 14, "Lv." .. skill_def.req_level))
        lock_text:SetPosition(80, y_pos + 6, 0)
        lock_text:SetColour(0.54, 0.48, 0.38, 0.5)
        lock_text:SetHAlign(ANCHOR_RIGHT)
    end
end

-- ====== 加点操作 ======
function MUSHA_SKILLUI:OnUpgradeSkill(skill_id)
    if TheWorld.ismastersim then
        -- 单机模式
        local pc = self.inst.components.musha_profession_component
        local skills_comp = self.inst.components.musha_skills
        if pc and skills_comp then
            skills_comp:TryUpgradeSkill(skill_id, pc)
            -- 刷新数据
            self:ReceiveData({
                skill_points = pc.mydata.skill_points or 0,
                level = pc.mydata.level or 0,
                exp = self._exp,
                job = self._job,
                advance_job = self._advance_job,
                skills = skills_comp.skill_levels,
            })
        end
    else
        -- 联机模式：发送 RPC
        SendModRPCToServer(
            GetModRPCIndex("musha_skill_upgrade"),
            skill_id
        )
    end
end

return MUSHA_SKILLUI
