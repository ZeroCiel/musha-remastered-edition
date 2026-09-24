-- ====================================
-- musha_panel_registered.lua
-- 职业面板：Screen 打开入口（照搬明生神行传送架构）
-- 面板本身是 Screen，用 TheFrontEnd:PushScreen 打开，不再是 HUD Widget
--
-- 【诊断版】每次打开请求都会 print 出走到了哪一步，
-- 方便在 client_log.txt 里定位"按了没反应"的断点。
--
-- ★ 2026-09-24 用户（选项 A）：**B 键不再开面板**，整段摘掉，注释保留可随时恢复。
--   现在入口只剩两条：① 技能书/职业书右键 → musha_open_skill_panel 事件
--                     ② 控制台命令 scripts/commands/musha_panel.lua
-- ====================================

-- B 键入口已于 2026-09-24 按用户要求**移除**（B 是游戏原生键，抢它会跟原版打架）。
-- 现在开面板只剩两条：技能书/职业书右键（musha_open_skill_panel 事件）、控制台命令。
-- 想恢复 B 键：见文件末尾注释块（原实现在 git 历史里也有）。

-- 面板是否已在屏幕栈顶
-- 注意：DST 的 Screen 没有 name 字段，所以用面板自己打的标记 self.musha_panel
local function PanelIsOnTop()
    local fe = TheFrontEnd
    local stack = fe and fe.screenstack
    if not stack then return false end
    local top = stack[#stack]
    return top ~= nil and top.musha_panel == true
end

local function OpenMushaPanel(owner, from)
    print("[Musha Panel] 打开请求 from=" .. tostring(from) .. " owner=" .. tostring(owner))

    if not owner or not owner:IsValid() then
        print("[Musha Panel] 中止: owner 无效")
        return
    end
    if not TheFrontEnd then
        print("[Musha Panel] 中止: TheFrontEnd 不存在")
        return
    end

    -- 已经开着就不重复推
    if PanelIsOnTop() then
        print("[Musha Panel] 中止: 面板已经在栈顶")
        return
    end

    -- 防死锁：标志残留为 true 但面板其实不在栈上 → 清掉继续开
    -- （标志是在 Panel Screen 构造函数第 216 行设的，构造中途报错就会永久残留）
    if owner._musha_panel_screen_open then
        print("[Musha Panel] 检测到残留的 _musha_panel_screen_open，已清除")
        owner._musha_panel_screen_open = nil
    end

    local ok, mod = pcall(require, "screens/musha_panel_screen")
    if not ok or not mod then
        print("[Musha Panel] require 失败: " .. tostring(mod))
        return
    end

    -- 构造也要 pcall：构造中途报错会留下脏标志，这里兜底清掉
    local ok2, inst = pcall(mod, owner)
    if not ok2 or not inst then
        print("[Musha Panel] 构造失败: " .. tostring(inst))
        owner._musha_panel_screen_open = nil
        return
    end

    TheFrontEnd:PushScreen(inst)
    print("[Musha Panel] 面板已推入屏幕栈")
end

AddClassPostConstruct("widgets/controls", function(self)
    if not self.owner or not self.owner:HasTag("musha") then
        return
    end

    -- 服务端 net_bool → 客户端 PushEvent → 打开面板
    --   （技能书/职业书右键走这条，保留）
    self.owner:ListenForEvent("musha_open_skill_panel", function()
        OpenMushaPanel(self.owner, "event")
    end)

    -- ★ 2026-09-24 用户拍板：**B 键不再开面板**（选项 A：B 不要出）
    --   原实现：TheInput:AddKeyDownHandler(KEY_B, ...) 开/关面板。
    --   注意 B 是游戏原生"检查/口癖"键，抢它会跟原版功能打架，所以直接摘掉。
    --   想恢复：把下面这段取消注释即可（git 历史里也有）。
    -- if TheInput then
    --     self._musha_panel_key_b = TheInput:AddKeyDownHandler(KEY_B, function()
    --         print("[Musha Panel] B 键按下")
    --         if PanelIsOnTop() then
    --             TheFrontEnd:PopScreen()
    --         else
    --             OpenMushaPanel(self.owner, "keyB")
    --         end
    --     end)
    -- end
    print("[Musha Panel Register] B 键入口已移除，开面板只剩：技能书右键 / musha_open_skill_panel 事件")

    print("[Musha Panel Register] 面板入口(Screen)已注册")
end)
