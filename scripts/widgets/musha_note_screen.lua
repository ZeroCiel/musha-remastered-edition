-- ====================================
-- musha_note_screen.lua
-- 便签 UI — 全屏文字逐行浮动浮现
-- 作为 controls Widget 常驻，收到事件时显示
-- ====================================
print("[Musha Note] 文件开始加载")

local Widget = require "widgets/widget"
local Text = require "widgets/musha_text"
local Image = require "widgets/image"

local MUSHA_VERSION = "v0.7.6"

local LINES = {{
    text = "啊，迷途的旅者啊……",
    delay = 1.5
}, {
    text = "你已踏入这片交织着荣光与诅咒的土地，",
    delay = 4.5
}, {
    text = "前方是馈赠，亦是试炼。",
    delay = 4.5
}, {
    text = "在命运交织之前，请聆听你血脉的回响——",
    delay = 4.5
}, {
    text = "",
    delay = 0.5
}, {
    text = "是紧握剑盾，成为不可撼动的坚壁；",
    delay = 4.5
}, {
    text = "是共鸣元素，驱使千变万化的秘法；",
    delay = 4.5
}, {
    text = "是化身幽影，践行无声正义的利刃；",
    delay = 4.5
}, {
    text = "还是心弦共鸣，与自然缔结盟约的风语者？",
    delay = 4.0
}, {
    text = "",
    delay = 0.5
}, {
    text = "—— 雪儿",
    delay = 1.0
}}

local function CreateNoteScreen(owner)
    print("[Musha Note] CreateNoteScreen owner=" .. tostring(owner))

    -- 用 Class 方式创建，确保 UITransform 正确初始化
    local self = Class(Widget, function(self2)
        Widget._ctor(self2, "MushaNoteScreen")
    end)()
    print("[Musha Note] Widget() 创建成功")

    self.owner = owner
    self.playing = false
    self.current_line = 0
    self.float_time = 0
    self._key_handler = nil
    self.text_widgets = {}
    self.fade_task = nil

    owner.screen_musha_note = self

    -- 全屏占位
    self:SetScaleMode(SCALEMODE_FILLSCREEN) -- SCALEMODE_FILLSCREEN
    self:SetHAnchor(0)
    self:SetVAnchor(0)

    -- 底图
    self.bg = self:AddChild(Image("images/musha_note_bg.xml", "musha_note_bg.tex"))
    self.bg:SetSize(1800, 1011)
    self.bg:SetScale(0.64)

    -- 全屏黑幕（在底图下方，点击关闭便签）
    self.black_overlay = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black_overlay:SetScaleMode(2)  -- FILLSCREEN
    self.black_overlay:SetTint(0, 0, 0, 0.55)
    self.black_overlay:MoveToBack()  -- 放到底图后面
    -- 黑幕点击关闭（通过焦点传递）
    self.black_overlay.focus = true
    function self.black_overlay:OnMouseButton(button, down, x, y)
        if down and self.parent then
            self.parent:HideNote()
        end
        return true
    end

    -- 版本号
    self.version_text = self.bg:AddChild(Text(BODYTEXTFONT, 20))
    self.version_text:SetString(MUSHA_VERSION)
    self.version_text:SetColour(0.6, 0.6, 0.6, 0.5)
    self.version_text:SetPosition(530, -220)

    -- 文字层
    self.text_layer = self.bg:AddChild(Widget("TextLayer"))
    self.text_layer:SetPosition(-25, 40)

    -- 创建所有 Text 控件
    local y_start = 200
    local current_y = y_start

    for i, ld in ipairs(LINES) do
        local font_size = 54
        local color = {0.95, 0.9, 0.7}
        local x_offset = 0
        local y_offset = 0

        if i >= 6 and i <= 9 then
            font_size = 45
            color = {1, 1, 1}
            y_offset = 20
        end
        if i == 11 then
            font_size = 40
            color = {0.8, 0.75, 0.6}
            x_offset = -250
        end

        if ld.text ~= "" then
            -- 整行文本，带整体变形（不使用 per-letter 拆分，避免中文乱码）
            local ch = self.text_layer:AddChild(Text(UIFONT, font_size))
            ch:SetString(ld.text)
            ch:SetColour(color[1], color[2], color[3], 0)
            local line_x
            if i <= 5 then
                line_x = -280 + i * 18  -- 前四行 + 空行
            else
                line_x = -280 + i * 22  -- 后四行
            end
            ch:SetPosition(line_x, current_y + y_offset)
            -- 整行旋转 -7度，每行递增 X 偏移补偿旋转导致的左移
            ch:SetTextRotation(-7)
            ch:SetTextScale(1.02, 1.0)
            local line_x = -280 + (i - 1) * 3  -- 每行往右多偏移3像素

            self.text_widgets[i] = { chars = {ch}, delay = ld.delay }
        else
            self.text_widgets[i] = { delay = ld.delay, is_empty = true }
        end

        if i == 5 then
            current_y = current_y - 40  -- 前四行和后四行之间的间隔
        elseif ld.text == "" then
            current_y = current_y - 50
        elseif i >= 6 then
            current_y = current_y - 55  -- 后四行行距缩小
        else
            current_y = current_y - 72  -- 前四行行距
        end
    end

    -- 默认隐藏
    self:Hide()

    -- 监听事件
    owner:ListenForEvent("musha_use_note", function()
        print("[Musha Note] 收到便签使用事件")
        if not self.playing then
            self:ShowNote()
        end
    end)

    -- 显示便签
    function self:ShowNote()
        if self.playing then
            return
        end
        self.playing = true
        self.current_line = 0
        self.float_time = 0

        -- 重置透明度
        for i, w in ipairs(self.text_widgets) do
            if w.chars then
                local color = {0.95, 0.9, 0.7}
                if i >= 6 and i <= 9 then
                    color = {1, 1, 1}
                end
                if i == 11 then
                    color = {0.8, 0.75, 0.6}
                end
                for _, ch in ipairs(w.chars) do
                    ch:SetColour(color[1], color[2], color[3], 0)
                end
            end
        end

        self:Show()
        self.focus = true

        -- ESC 关闭
        if TheInput and KEY_ESCAPE and not self._key_handler then
            self._key_handler = TheInput:AddKeyDownHandler(KEY_ESCAPE, function()
                self:HideNote()
            end)
        end

        -- 启动浮现
        self.inst:DoTaskInTime(0.5, function()
            self:RevealNextLine()
        end)
    end

    -- 逐行浮现
    function self:RevealNextLine()
        if not self.playing then
            return
        end
        self.current_line = self.current_line + 1
        if self.current_line > #LINES then
            return
        end

        local w = self.text_widgets[self.current_line]
        if not w then
            return
        end

        if w.is_empty then
            self.inst:DoTaskInTime(w.delay, function()
                self:RevealNextLine()
            end)
            return
        end

        local elapsed = 0
        local fade_dur = 0.7
        local c = {0.95, 0.9, 0.7}
        if self.current_line >= 6 and self.current_line <= 9 then c = {1, 1, 1} end
        if self.current_line == 11 then c = {0.8, 0.75, 0.6} end

        if self.fade_task then self.fade_task:Cancel() end
        self.fade_task = self.inst:DoPeriodicTask(0, function()
            elapsed = elapsed + 0.05
            local t = math.min(elapsed / fade_dur, 1)
            local eased = t * t * (3 - 2 * t)

            for _, ch in ipairs(w.chars) do
                ch:SetColour(c[1], c[2], c[3], eased)
            end

            if t >= 1 then
                self.fade_task:Cancel()
                self.fade_task = nil
                self.inst:DoTaskInTime(w.delay, function()
                    self:RevealNextLine()
                end)
            end
        end)
    end

    -- 浮动动画
    function self:OnUpdate(dt)
        if not self.playing or not self.text_layer then
            return
        end
        self.float_time = self.float_time + dt
        local offset = math.sin(self.float_time * 1.5) * 3
        self.text_layer:SetPosition(-25, 40 + offset)
    end

    -- 隐藏便签
    function self:HideNote()
        if not self.playing then
            return
        end
        self.playing = false
        self.focus = false
        if self.fade_task then
            self.fade_task:Cancel()
            self.fade_task = nil
        end
        if self._key_handler then
            self._key_handler:Remove()
            self._key_handler = nil
        end
        self:Hide()
    end

    -- 鼠标点击关闭
    function self:OnMouseButton(button, down, x, y)
        if down then
            self:HideNote()
        end
        return true
    end

    function self:OnRemove()
        self.playing = false
        if self.fade_task then
            self.fade_task:Cancel()
            self.fade_task = nil
        end
        if self._key_handler then
            self._key_handler:Remove()
            self._key_handler = nil
        end
    end

    print("[Musha Note] 创建完成")
    return self
end

print("[Musha Note] 返回 CreateNoteScreen")
return CreateNoteScreen
