local Widget = require "widgets/widget"

local MushaText = Class(Widget, function(self, font, size, text, colour)
    Widget._ctor(self, "MushaText")

    self.inst.entity:AddTextWidget()

    self.inst.TextWidget:SetFont(font)
    self.font = font

    -- 直接设 size，不经过 LOC.GetTextScale()
    self.inst.TextWidget:SetSize(size)
    self.size = size

    self:SetColour(colour or { 1, 1, 1, 1 })

    if text ~= nil then
        self:SetString(text)
    end
end)

function MushaText:SetColour(r, g, b, a)
    self.colour = type(r) == "number" and { r, g, b, a } or r
    self.inst.TextWidget:SetColour(unpack(self.colour))
end

function MushaText:SetString(str)
    self.string = str
    self.inst.TextWidget:SetString(str or "")
end

function MushaText:GetString()
    return self.inst.TextWidget:GetString() or ""
end

function MushaText:SetFont(font)
    self.inst.TextWidget:SetFont(font)
    self.font = font
end

function MushaText:SetSize(sz)
    self.inst.TextWidget:SetSize(sz)
    self.size = sz
end

function MushaText:GetSize()
    return self.size
end

function MushaText:SetColour(r, g, b, a)
    self.colour = type(r) == "number" and { r, g, b, a } or r
    self.inst.TextWidget:SetColour(unpack(self.colour))
end

function MushaText:SetAlpha(a)
    self.inst.TextWidget:SetColour(1, 1, 1, a)
end

function MushaText:UpdateAlpha(a)
    self.colour[4] = a
    self.inst.TextWidget:SetColour(unpack(self.colour))
end

-- 文字变形：旋转
function MushaText:SetTextRotation(angle)
    self.inst.UITransform:SetRotation(angle)
end

-- 文字变形：缩放
function MushaText:SetTextScale(x, y)
    self.inst.UITransform:SetScale(x, y or x, 1)
end

-- 文字变形：倾斜（通过旋转+缩放模拟）
function MushaText:SetTextSkew(x, y)
    -- 不能用原生倾斜，用旋转代替
    self.inst.UITransform:SetRotation(x or 0)
end

return MushaText
