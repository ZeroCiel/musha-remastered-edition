-- ====================================
-- musha_note_registered.lua
-- 将便签 UI 注册到 HUD
-- ====================================

AddClassPostConstruct(
    "widgets/controls",
    function(self)
        if self.owner:HasTag("musha") then
            local widget = require("widgets/musha_note_screen")
            self.Musha_Note = self:AddChild(widget(self.owner))
        end
    end
)
