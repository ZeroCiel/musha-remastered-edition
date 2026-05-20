-- ====================================
-- musha_panel_registered.lua
-- 将职业面板注册到 HUD
-- ====================================

AddClassPostConstruct("widgets/controls", function(self)
    if not self.owner or not self.owner:HasTag("musha") then
        return
    end

    print("[Musha Panel Register] 创建职业面板...")
    local CreatePanel = require("widgets/musha_panel_screen")
    local panel = CreatePanel(self.owner)
    self:AddChild(panel)

    -- B 键打开职业面板
    if TheInput then
        panel._key_handler_b = TheInput:AddKeyDownHandler(KEY_B, function()
            if panel.playing then
                panel:HidePanel()
            else
                panel:ShowPanel()
            end
        end)
    end
end)
