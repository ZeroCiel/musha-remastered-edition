-- ====================================
-- musha_note_ui.lua
-- 便签 UI — 全屏文字逐行浮动浮现
-- 不依赖外部图片，纯 UI Text 控件
-- ====================================

local Widget = require "widgets/widget"
local Text = require "widgets/text"

return function(bg_atlas, bg_image, scalemode_fill, anchor_middle)
    scalemode_fill = scalemode_fill or 1
    anchor_middle = anchor_middle or 1

    -- 创建根 Widget（全屏）
    local root = Widget("MushaNoteRoot")
    root:SetScaleMode(scalemode_fill)
    root:SetVAnchor(anchor_middle)
    root:SetHAnchor(anchor_middle)

    -- 半透明黑底
    local black = root:AddChild(Widget("BlackBg"))
    black:SetVAnchor(anchor_middle)
    black:SetHAnchor(anchor_middle)
    black:SetScaleMode(scalemode_fill)
    -- 用 Image 实现纯黑背景
    local Image = require "widgets/image"
    local bg_img = black:AddChild(Image())
    bg_img:SetTexture(nil)
    bg_img:SetScaleMode(scalemode_fill)
    bg_img:SetVAnchor(anchor_middle)
    bg_img:SetHAnchor(anchor_middle)
    bg_img:SetColour(0, 0, 0, 0.55)

    -- 文字层
    local text_layer = root:AddChild(Widget("TextLayer"))
    text_layer:SetPosition(0, 30)

    -- 台词
    local lines = {
        { text = "啊，迷途的旅者啊……",          delay = 0.5 },
        { text = "你已踏上这片危机四伏的土地，",    delay = 1.0 },
        { text = "此地遍布机遇，亦暗藏深渊。",      delay = 1.0 },
        { text = "在启程之前，你须做出一个抉择——", delay = 1.0 },
        { text = "",                             delay = 0.3 },
        { text = "是成为高举利剑的战士，",         delay = 0.8 },
        { text = "吟唱咒语的法师，",              delay = 0.8 },
        { text = "穿梭暗影的刺客，",              delay = 0.8 },
        { text = "亦或是奏响命运的游侠？",         delay = 0.8 },
        { text = "",                             delay = 0.3 },
        { text = "—— 雪儿",                       delay = 0.5 },
    }

    -- 创建 Text 控件
    local text_widgets = {}
    local y_start = 200
    local current_y = y_start

    for i, ld in ipairs(lines) do
        local font_size = 28
        local color = {0.95, 0.9, 0.7}
        if i >= 6 and i <= 9 then
            font_size = 26
            color = {1, 1, 1}
        end
        if i == 11 then
            font_size = 22
            color = {0.8, 0.75, 0.6}
        end

        if ld.text ~= "" then
            -- 阴影层
            local shadow = text_layer:AddChild(Text(BODYTEXTFONT, font_size))
            shadow:SetString(ld.text)
            shadow:SetColour(0, 0, 0, 0)
            shadow:SetPosition(2, current_y - 2)

            -- 主文本层
            local main = text_layer:AddChild(Text(BODYTEXTFONT, font_size))
            main:SetString(ld.text)
            main:SetColour(color[1], color[2], color[3], 0)
            main:SetPosition(0, current_y)

            text_widgets[i] = { main = main, shadow = shadow, delay = ld.delay }
        else
            text_widgets[i] = { delay = ld.delay, is_empty = true }
        end

        current_y = current_y - (ld.text == "" and 24 or 34)
    end

    -- 状态
    local current_line = 0
    local total_lines = #lines
    local float_time = 0
    local closed = false

    -- 逐行浮现
    local function RevealNextLine()
        if closed then return end
        current_line = current_line + 1
        if current_line > total_lines then return end

        local w = text_widgets[current_line]
        if not w then return end

        if w.is_empty then
            root.inst:DoTaskInTime(w.delay, RevealNextLine)
            return
        end

        local elapsed = 0
        local fade_dur = 0.35
        local c = {0.95, 0.9, 0.7}
        if current_line >= 6 and current_line <= 9 then c = {1, 1, 1} end
        if current_line == 11 then c = {0.8, 0.75, 0.6} end

        local fade_task = root.inst:DoPeriodicTask(0, function()
            elapsed = elapsed + 0.05
            local t = math.min(elapsed / fade_dur, 1)
            local eased = t * t * (3 - 2 * t)

            w.main:SetColour(c[1], c[2], c[3], eased)
            w.shadow:SetColour(0, 0, 0, 0.6 * eased)

            if t >= 1 then
                fade_task:Cancel()
                root.inst:DoTaskInTime(w.delay, RevealNextLine)
            end
        end)
    end

    -- 浮动动画
    root.OnUpdate = function(self, dt)
        if closed then return end
        float_time = float_time + dt
        local offset = math.sin(float_time * 1.5) * 3
        text_layer:SetPosition(0, 30 + offset)
    end

    -- 关闭
    local function CloseUI()
        if closed then return end
        closed = true
        root:Kill()
    end

    -- 鼠标/键盘
    root:EnableMouseInput(true)
    root:SetMouseClickFn(CloseUI)
    local key_handler = TheInput:AddKeyDownHandler(KEY_ESCAPE, CloseUI)

    -- 监测移除时清理
    root.OnRemoveEntity = function()
        if key_handler then
            key_handler:Remove()
            key_handler = nil
        end
    end

    -- 启动浮现
    root.inst:DoTaskInTime(0.5, RevealNextLine)

    return root
end
