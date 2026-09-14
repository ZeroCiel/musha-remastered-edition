-- ====================================
-- musha_keyhandler.lua
-- 可配置按键系统
-- 按键绑定保存在客户端本地，每个玩家独立
-- ====================================

-- 默认按键绑定（通用 namespace: "musha_skill"）
-- 玩家调用 ChangeKeybind 修改后存入本地配置
local DEFAULT_KEYBINDS = {
    -- 技能快捷键（1-5）
    skill_1 = KEY_1,
    skill_2 = KEY_2,
    skill_3 = KEY_3,
    skill_4 = KEY_4,
    skill_5 = KEY_5,
    -- 打开技能书
    open_skillbook = KEY_K,
}

-- 当前按键映射（从本地配置加载）
local KEYBINDS = {}

-- 从本地配置加载键位
local function LoadKeybinds()
    local success, data = pcall(TheSim.GetPersistentString, "musha_keybinds")
    if success and data and data ~= "" then
        local ok, parsed = pcall(json.decode, data)
        if ok and type(parsed) == "table" then
            -- 合并默认值（新版本新增的键位用默认值补全）
            for k, v in pairs(DEFAULT_KEYBINDS) do
                if parsed[k] == nil then
                    parsed[k] = v
                end
            end
            KEYBINDS = parsed
            return
        end
    end
    -- 默认
    KEYBINDS = {}
    for k, v in pairs(DEFAULT_KEYBINDS) do
        KEYBINDS[k] = v
    end
end

-- 保存键位到本地
local function SaveKeybinds()
    local json_str = json.encode(KEYBINDS)
    TheSim:SetPersistentString("musha_keybinds", json_str)
end

-- 获取当前绑定的按键
function GetKeybind(action_id)
    return KEYBINDS[action_id] or DEFAULT_KEYBINDS[action_id]
end

-- 修改按键绑定
-- action_id: 动作 ID（如 "skill_1"）
-- new_key: 按键常量（如 KEY_R, KEY_F1 等）
function ChangeKeybind(action_id, new_key)
    if DEFAULT_KEYBINDS[action_id] == nil then
        return false, "未知动作"
    end
    KEYBINDS[action_id] = new_key
    SaveKeybinds()
    return true, "ok"
end

-- 重置为默认
function ResetKeybinds()
    for k, v in pairs(DEFAULT_KEYBINDS) do
        KEYBINDS[k] = v
    end
    SaveKeybinds()
end

-- ====================================
-- KeyHandler 组件
-- 挂载在玩家身上，监听按键
-- ====================================

local KeyHandler = Class(function(self, inst)
    self.inst = inst

    -- 加载键位
    LoadKeybinds()

    -- 注册键盘监听（客户端 only）
    if TheInput then
        self.handler = TheInput:AddKeyHandler(function(key, down)
            self:OnRawKey(key, down)
        end)
    end

    -- 动作监听表 { action_id = function, ... }
    self.action_handlers = {}
    -- 按键对应的动作（反向查找）
    self._key_to_action = nil
end)

-- 反向查找：当前按下的键对应什么动作
function KeyHandler:GetActionForKey(key)
    if not self._key_to_action then
        self._key_to_action = {}
        for action_id, bound_key in pairs(KEYBINDS) do
            self._key_to_action[bound_key] = action_id
        end
    end
    return self._key_to_action[key]
end

-- 刷新反向映射（改键后调用）
function KeyHandler:RefreshKeyMap()
    self._key_to_action = nil
end

-- 原始按键回调
function KeyHandler:OnRawKey(key, down)
    -- 2026-09-13 修：原来这里写 `if TheWorld.ismastersim then return end`（仅客户端）
    --   → 自己当服主时按技能键**完全没反应**。现在主机也响应，
    --   要不要走 RPC 由注册的动作处理器自己判断。
    if down then return end  -- 只响应释放（避免连发）
    if IsPaused() then return end

    -- 检查是否在 HUD 界面（不是其他 UI 界面）
    local active_screen = TheFrontEnd:GetActiveScreen()
    if active_screen and type(active_screen.name) == "string" and active_screen.name ~= "HUD" then
        return  -- 有其他 UI 打开时不响应
    end

    local action_id = self:GetActionForKey(key)
    if not action_id then return end

    -- 执行动作
    local handler = self.action_handlers[action_id]
    if handler then
        handler(self.inst, ThePlayer)
    end
end

-- 注册一个动作处理器
-- action_id: 动作名（如 "skill_1"）
-- handler: function(inst, player) 回调
function KeyHandler:RegisterAction(action_id, handler)
    self.action_handlers[action_id] = handler
end

-- 取消注册
function KeyHandler:UnregisterAction(action_id)
    self.action_handlers[action_id] = nil
end

-- 开始监听按键设置模式
-- 回调 function(old_action, new_key) 用户按了新键后触发
function KeyHandler:StartListeningForBind(callback)
    if self._listening then return end
    self._listening = true

    self._bind_listener = TheInput:AddKeyHandler(function(key, down)
        if not down then return end  -- 按下瞬间触发

        -- 跳过鼠标按键
        if key >= MOUSEBUTTON_LEFT and key <= MOUSEBUTTON_LAST then return end

        -- 查找这个键当前绑定了什么动作
        local old_action = self:GetActionForKey(key)

        self._listening = false
        if self._bind_listener then
            self._bind_listener:Remove()
            self._bind_listener = nil
        end

        if callback then
            callback(old_action, key)
        end
    end)
end

function KeyHandler:StopListening()
    self._listening = false
    if self._bind_listener then
        self._bind_listener:Remove()
        self._bind_listener = nil
    end
end

-- ====== 工具函数 ======

-- 按键 → 可读名称
function KeyName(key)
    local names = {
        [KEY_A] = "A", [KEY_B] = "B", [KEY_C] = "C",
        [KEY_D] = "D", [KEY_E] = "E", [KEY_F] = "F",
        [KEY_G] = "G", [KEY_H] = "H", [KEY_I] = "I",
        [KEY_J] = "J", [KEY_K] = "K", [KEY_L] = "L",
        [KEY_M] = "M", [KEY_N] = "N", [KEY_O] = "O",
        [KEY_P] = "P", [KEY_Q] = "Q", [KEY_R] = "R",
        [KEY_S] = "S", [KEY_T] = "T", [KEY_U] = "U",
        [KEY_V] = "V", [KEY_W] = "W", [KEY_X] = "X",
        [KEY_Y] = "Y", [KEY_Z] = "Z",
        [KEY_1] = "1", [KEY_2] = "2", [KEY_3] = "3",
        [KEY_4] = "4", [KEY_5] = "5", [KEY_6] = "6",
        [KEY_7] = "7", [KEY_8] = "8", [KEY_9] = "9", [KEY_0] = "0",
        [KEY_F1] = "F1", [KEY_F2] = "F2", [KEY_F3] = "F3",
        [KEY_F4] = "F4", [KEY_F5] = "F5", [KEY_F6] = "F6",
        [KEY_F7] = "F7", [KEY_F8] = "F8", [KEY_F9] = "F9",
        [KEY_F10] = "F10", [KEY_F11] = "F11", [KEY_F12] = "F12",
        [KEY_TAB] = "Tab", [KEY_SPACE] = "Space",
        [KEY_ESCAPE] = "Esc", [KEY_BACKSPACE] = "Backspace",
        [KEY_ENTER] = "Enter", [KEY_CTRL] = "Ctrl",
        [KEY_SHIFT] = "Shift", [KEY_ALT] = "Alt",
        [KEY_UP] = "↑", [KEY_DOWN] = "↓",
        [KEY_LEFT] = "←", [KEY_RIGHT] = "→",
        [KEY_MINUS] = "-", [KEY_EQUALS] = "=",
        [KEY_LEFTBRACKET] = "[", [KEY_RIGHTBRACKET] = "]",
        [KEY_SEMICOLON] = ";", [KEY_QUOTE] = "'",
        [KEY_COMMA] = ",", [KEY_PERIOD] = ".", [KEY_SLASH] = "/",
        [KEY_BACKSLASH] = "\\", [KEY_TILDE] = "~",
    }
    return names[key] or ("Key" .. tostring(key))
end

return KeyHandler
