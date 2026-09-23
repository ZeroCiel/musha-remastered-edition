local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local AnimButton = require "widgets/_animbutton"
local TextButton = require "widgets/textbutton"
local UIAnim = require "widgets/uianim"
local _S = STRINGS
local count = 0
local MyImage = require "widgets/my_image"
local Image = require "widgets/image"

local _Controls = {
    General = {
        name = "General",
        font = _S.M_General,
		Mian_Location = 0,
        Submenu = {Character = "Character", CareerSkill = "CareerSkill", Combat = "Combat", Life = "Life", OtherInfo = "OtherInfo"},
        Location = {Character = 0, CareerSkill = 1, Combat = 2, Life = 3, OtherInfo = 4}, --排序这些UI的位置
        String = {Character = _S.M_Character, CareerSkill = _S.M_CareerSkill, Combat = _S.M_Combat, Life = _S.M_Life, OtherInfo = _S.M_OtherInfo}, --子选项
        Key = "Character", --默认界面 点进去时提示的
        CanClick = true --当前可以点击
    },
    Wiki = {
        name = "Wiki",
        font = _S.M_Wiki,
		Mian_Location = 1,
        Submenu = {Equip = "Equip", Strategy = "Strategy", Exclusive_recipes = "Exclusive_recipes", Career_Info = "Career_Info"},
        Location = {Equip = 0, Strategy = 1, Exclusive_recipes = 2, Career_Info = 3},
        String = {Equip = _S.M_Equip, Strategy = _S.M_Strategy, Exclusive_recipes = _S.M_Exclusive_recipes, Career_Info = _S.M_Career_Info},
        Key = "Equip",
        CanClick = false
    },
    Function = {
        name = "Function",
        font = _S.M_Function,
		Mian_Location = 2,
        Submenu = {Combine = "Combine", Strengthen = "Strengthen"},
        Location = {Combine = 0, Strengthen = 1},
        String = {Combine = _S.M_Combine, Strengthen = _S.M_Strengthen},
        Key = "Combine",
        CanClick = false
    },
    Announcement = {
        name = "Announcement",
        font = _S.M_Announcement,
		Mian_Location = 3,
        Submenu = {Announcement = "Announcement", FAQ = "FAQ", Updata_Log = "Updata_Log", Support = "Support", JoinUs = "JoinUs"},
        Location = {Announcement = 0, FAQ = 1, Updata_Log = 2, Support = 3, JoinUs = 4},
        String = {Announcement = _S.M_Announcement, FAQ = _S.M_FAQ, Updata_Log = _S.M_Updata_Log, Support = _S.M_Support, JoinUs = _S.M_JoinUs},
        Key = "Updata_Log",
        CanClick = true
    }
}

--用来回退上一级界面的默认按钮
local _Key = {
    General = "General",
    Wiki = "Wiki",
    Function = "Function",
    Announcement = "Announcement"
}

return Class(Widget, function(self, owner, data)
    Widget._ctor(self, "Wiki_System", owner)
    self.owner = owner

    function self:TrySave(delay)
        delay = delay or 0.33
        if self.SaveTask then
            self.SaveTask:Cancel()
            self.SaveTask = nil
        end
        self.SaveTask = self.owner:DoTaskInTime(delay, function()
            TheSim:SetPersistentString("mod_config_data/Norse_mythology_Save", json.encode(self.data), true)
            self.SaveTask:Cancel()
            self.SaveTask = nil
        end)
    end

    function self:OnResponse()
        if (TheFrontEnd:GetActiveScreen() and TheFrontEnd:GetActiveScreen().name and type(TheFrontEnd:GetActiveScreen().name) == "string" and TheFrontEnd:GetActiveScreen().name == "HUD") then
            if not self.cd then
                if self.shown then
                    self:Hide()
                    self:TrySave()
                else
                    self:Show()
                end
                self.cd = true
                self.inst:DoTaskInTime(0.2, function() self.cd = false end)
            end
        end
    end
    self.handler = TheInput:AddKeyDownHandler(TUNING.KEY_MUSHA_UI_LEVEL, function() self:OnResponse() end)

    -- Must Setting location
    self:SetHAnchor(0)
    self:SetVAnchor(0)
    self:SetPosition(0, 0, 0)
    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.version = "3.20.1"

    self.button = nil -- 记录当前按下子按钮
    self.key = nil -- 记录总菜单
    self.data = nil -- 记录数据链接

    function self:OnLoad()
        TheSim:GetPersistentString("mod_config_data/Norse_mythology_Save", function(success, encoded_data)
            if success then
                local save_data = json.decode(encoded_data)
                self.data = save_data
            end
        end)

        -- 如果版本不一致 或者存档版本不一致 主动打开主界面
        if (self.data ~= nil and self.data.version ~= self.version) or self.data == nil then
            self:OnResponse() -- 不起作用
            -- SendModRPCToServer(MOD_RPC[TUNING.KEY_MUSHA_UI_LEVEL, self:OnResponse()) --尝试发送监听
            if self.data == nil then
                self.data = {}
            end
            self.data.version = self.version
        end
    end

    local function CreateSubMene(self, pair, key, default)
        local button = self.Image:AddChild(AnimButton("widgets_submenu", "widgets_submenu", "Anim", "OnFocus", "OnControl", "OnClick", "OnControl", pair.String[key]))
        button:SetPosition(-960, (410 - pair.Location[key] * 200))
        button:Hide()
        button:SetClickable(true)
        if key ~= default then
            button:Patch()
        end

        button:SetOnClick(function()
            if self.button ~= nil then
                self.button:SetClickable(true)
                if self.button.animstate:IsCurrentAnimation("Anim") then
                    self.button.animstate:PlayAnimation("Anim", true) -- 把控件关掉
                end
                self.button:Clear()
                self.button:SubOnClick()
                if self.button.widgets ~= nil then
                    self.button.widgets:Hide()
                else
                    if self.button.library ~= nil then
                        for k, v in pairs(self.button.library) do
                            v:Hide()
                        end
                    end
                end
                self.button = nil
            end

            self.button = button
            self.button:SetClickable(false)
            self.button.animstate:PlayAnimation("OnControl", true)
            -- 显示子界面内容
            if self.button.widgets ~= nil then
                self.button.widgets:Show()
            else
                if self.button.library then
                    for k, v in pairs(self.button.library) do
                        if v ~= nil then
                            v:Show()
                        end
                    end
                end
            end

            -- self.button:SubOnClick()
            if self.data[key] == nil then
                self.data[key] = {}
            end
            self.data[key].key = key
        end)
        self._Controls[default].library[key] = button
    end

    -- Must Create Widget
    self.Image = self:AddChild(Image("images/ui/widget.xml", "widget.tex"))
    self.Image:SetSize(1979, 1260)
    self.Image:SetScale(0.48)
    self.Image:SetPosition(0, 0, -20)

    self._Controls = {}
    for k, v in pairs(_Controls) do
        if _Controls[k].CanClick == false then
            self._Controls[k] = self.Image:AddChild(MyImage("images/ui/widgets_min_controls.xml", "widgets_min_controls.tex", "widgets_min_controls.tex", _Controls[k].font))
            self._Controls[k]:SetTint(0.4, 0.4, 0.4, 1)
        else
            self._Controls[k] = self.Image:AddChild(AnimButton("widgets_min_controls", "widgets_min_controls", "Anim", "OnControl", "Anim", "OnControl", "OnControl", _Controls[k].font)) -- bank, build, idle_anim, focus_anim, disabled_anim, down_anim, selected_anim
            self._Controls[k].key = _Controls[k].Submenu
            self._Controls[k]:SetOnClick(function()

                -- 隐藏主菜单	
                for i, p in pairs(_Controls) do
                    self._Controls[i]:Hide()
                end

                -- 显示该菜单下字界面按钮
                for i, options in pairs(_Controls[k].Submenu) do
                    self._Controls[k].library[options]:Show()
                end

                -- 记录主界面按钮
                self.data.key = k
                local key = self.data and self.data[k] and self.data[k].key ~= nil and self.data[k].key or _Controls[k].Key
                -- print(self._Controls[k])
                -- print(self._Controls[k].library[key])
                self._Controls[k].library[key].animstate:PlayAnimation("OnControl", true) -- 进入界面 锁定界面
                self._Controls[k].library[key]:SubOnClick(true) -- 假点击 显示这个子控件当中的所有界面
                self._Controls[k].library[key]:SetClickable(false) -- 禁用当前子菜单选中模式 播放选择动画
                self.button = self._Controls[k].library[key] -- 记录这个按键 因为它需要执行弹起 
            end)
        end
        self._Controls[k]:SetPosition(-960, (410 - (_Controls[k].Mian_Location * 200)), 1)
        self._Controls[k].library = {}
        self._Controls[k]:Show()
        count = count + 1
    end

    -- 生成一堆的子界面 这里不能打包 不然就多重创建了很多子项目
    -- 出于强迫症
    for key, submenu in pairs(_Controls.General.Submenu) do
        CreateSubMene(self, _Controls.General, key, "General")
    end

    for key, submenu in pairs(_Controls.Wiki.Submenu) do
        CreateSubMene(self, _Controls.Wiki, key, "Wiki")
    end

    for key, submenu in pairs(_Controls.Function.Submenu) do
        CreateSubMene(self, _Controls.Function, key, "Function")
    end

    for key, submenu in pairs(_Controls.Announcement.Submenu) do
        CreateSubMene(self, _Controls.Announcement, key, "Announcement")
    end

    -- 生成子界面内容

    self.close = self.Image:AddChild(ImageButton("images/ui/close.xml", "close.tex"))
    self.close:SetPosition(600, 400)
    self.close:SetOnClick(function()
        if self.button ~= nil then
            self.button:SetClickable(true)
            self.button:SubOnClick()
            self.button:Clear()
        end

        for i, options in pairs(self._Controls[self.key].key) do
            self._Controls[k].library[options]:Hide()
        end

        for k, v in pairs(_Key) do
            self._Controls[k]:Show()
        end
    end)
	
	-- Announcement 公告
    local Widget = self.Image:AddChild(MyImage("images/ui/widgets_announcement.xml", "widgets_announcement.tex", "widgets_announcement.tex", _S.M_Talkabout_Announcement))
    Widget:Hide()
    Widget:SetSize(1500, 970)
    self._Controls["Announcement"].library["Announcement"].widgets = Widget

    -- Announcement 公告
    local Widget = self.Image:AddChild(MyImage("images/ui/widgets_announcement.xml", "widgets_announcement.tex", "widgets_announcement.tex", _S.M_Talkabout_Announcement))
    Widget:Hide()
    Widget:SetSize(1500, 970)
    self._Controls["Announcement"].library["Announcement"].widgets = Widget

    -- FAQ 常见问题解答
    local Widget = self.Image:AddChild(MyImage("images/ui/widgets_announcement.xml", "widgets_announcement.tex", "widgets_announcement.tex"))
    Widget:Hide()
    Widget:SetSize(1500, 970)
    self._Controls["Announcement"].library["FAQ"].widgets = Widget

    -- Updata_About 更新日志
    local Widget = self.Image:AddChild(MyImage("images/ui/widgets_announcement.xml", "widgets_announcement.tex", "widgets_announcement.tex"))
    Widget:Hide()
    Widget:SetSize(1500, 970)

    count = 0
    local list = 1
    for key, pair in pairs(STRINGS.NORSE_MYTHOLOGY_UPDATE_LOG) do
        for version, strings in pairs(pair) do
            local description = Widget:AddChild(TextButton())
			description:SetText(strings)
            description:SetPosition(-100, 50 * #pair + count * -100)
			count = count + 1
        end
    end
    self._Controls["Announcement"].library["Updata_Log"].widgets = Widget

    -- Support 支持 发电 维护 转爱发电链接
    local Widget = self.Image:AddChild(MyImage("images/ui/widgets_announcement.xml", "widgets_announcement.tex", "widgets_announcement.tex", _S.M_Talkabout_Supprot))
    Widget:Hide()
    Widget:SetSize(1500, 970)
    self._Controls["Announcement"].library["Support"].widgets = Widget

    -- --QR Code 二维码说明 联系方式
    local JoinUs = {
        discord = "discord",
        qq_group = "qq_group"
    }
    local i = 0
    local Widget = self.Image:AddChild(MyImage("images/ui/widgets_announcement.xml", "widgets_announcement.tex", "widgets_announcement.tex"))
    Widget:SetSize(1500, 970)
    for k, v in pairs(JoinUs) do
        local ui = Widget:AddChild(Image("images/ui/widgets_qr_code.xml", "widgets_qr_code.tex"))
        ui:SetSize(270, 270)
        ui:SetPosition(-300 + i * 600, 200)

        local QR_Code = ui:AddChild(Image("images/ui/" .. v .. ".xml", v .. ".tex"))
        QR_Code:SetSize(250, 250)
        i = i + 1
        if i == 1 then
            local text = Widget:AddChild(Text(BODYTEXTFONT, 45, _S.M_Suggest))
            text:SetPosition(0, -300)
        end
    end
    Widget:Hide()
    self._Controls["Announcement"].library["JoinUs"].widgets = Widget

    -- 移除角色 移除界面
    self.inst:ListenForEvent("onremove", function()
        if self.handler ~= nil then
            self.handler:Remove()
        end
    end)

    -- 登录时读取下界面
    self.owner:DoTaskInTime(0, function() self:OnLoad() end)

end)
