-- ====================================
-- musha_panel.lua
-- 职业面板显示
-- 使用聊天事件监听方式（兼容所有 DST 版本）
-- ====================================

-- 显示职业面板的函数
local function ShowMushaPanel(inst)
    if not inst or not inst:IsValid() then 
        return 
    end
    
    -- 只有服务端能处理
    if not GLOBAL.TheWorld or not GLOBAL.TheWorld.ismastersim then 
        return 
    end

    local pc = inst.components.musha_profession_component
    if not pc then
        if inst.components.talker then
            inst.components.talker:Say("未加载 Musha 职业系统。", 4)
        end
        return
    end

    -- 基础信息
    local lines = {}
    table.insert(lines, "======= Musha 职业面板 =======")

    -- 职业
    local job_name = pc:GetCarrer_base() or "无职业"
    table.insert(lines, "职业: " .. job_name)
    
    local adv_name = pc:GetCarrer_special()
    if adv_name and adv_name ~= "" then
        table.insert(lines, "进阶: " .. adv_name .. " ★")
    end

    -- 等级
    local level = pc:GetLevel() or 1
    local max_level = pc:GetMaxLevel() or 30
    table.insert(lines, "等级: " .. level .. " / " .. max_level)

    -- 经验
    local exp = pc:GetExp() or 0
    local exp_needed = pc:GetExpForNextLevel() or 100
    local pct = 0
    if exp_needed > 0 then
        pct = math.floor(exp / exp_needed * 100)
    end
    table.insert(lines, "经验: " .. exp .. " / " .. exp_needed .. " (" .. pct .. "%)")

    -- 技能点
    if pc:GetSkillPoints() and pc:GetSkillPoints() > 0 then
        table.insert(lines, "可用技能点: " .. pc:GetSkillPoints())
    end

    -- 任务进度
    local quest = inst.components.musha_quest
    if quest then
        local quest_text = quest:GetQuestDisplay() or ""
        if quest:HasActiveQuest() then
            table.insert(lines, "")
            table.insert(lines, "--- 任务进度 ---")
            table.insert(lines, quest_text)
        else
            if not (pc.userdata.has_advanced or pc:GetCarrer_special()) and pc:HasJob() then
                table.insert(lines, "")
                table.insert(lines, "前往酒馆接取转职任务。")
            end
        end
    end

    -- 总览底栏
    table.insert(lines, "================================")

    -- 一次说完全部内容
    if inst.components.talker then
        inst.components.talker:Say(table.concat(lines, "\n"), 10)
    end
end

-- =============================================
-- 聊天命令处理
-- 监听玩家聊天消息，检测命令前缀
-- 兼容所有 DST 版本
-- =============================================

local COMMANDS = {
    ["/musha"] = true,
    ["/class"] = true,
    ["/职业"] = true,
}

-- 命令处理器参数表
local function HandleChatCommand(inst, message)
    if not inst or not inst:IsValid() then return false end
    if not inst:HasTag("musha") then return false end
    
    local msg = string.lower(GLOBAL.string.trim(message or ""))
    
    for cmd_prefix in pairs(COMMANDS) do
        if msg == cmd_prefix or msg:find(cmd_prefix .. " ", 1, true) == 1 then
            ShowMushaPanel(inst)
            return true
        end
    end
    
    return false
end

-- 方式一：监听玩家聊天事件（DST 标准方法）
AddPrefabPostInit("musha", function(inst)
    if not GLOBAL.TheWorld or not GLOBAL.TheWorld.ismastersim then
        return
    end
    
    -- 确保组件存在
    if not inst.components.musha_profession_component then
        inst:AddComponent("musha_profession_component")
    end
    if not inst.components.musha_quest then
        inst:AddComponent("musha_quest")
    end
    
    -- 监听玩家聊天
    if inst.components.talker then
        inst:ListenForEvent("musha_chat", function(src, data)
            if data and data.message then
                HandleChatCommand(src, data.message)
            end
        end)
    end
end)

-- 方式二：监听全局 SendRPC 事件（备用通道）
-- 玩家发送聊天时触发 OnPlayerChat
if GLOBAL.TheNet and GLOBAL.TheNet:IsDedicated() then
    -- 专用服务器
end

-- 方式三：劫持玩家聊天消息（最可靠的方法）
-- 通过 ListenForEvent 捕获玩家发送的消息
AddPlayerPostInit(function(inst)
    if not GLOBAL.TheWorld or not GLOBAL.TheWorld.ismastersim then
        return
    end
    
    -- 玩家发送聊天时触发
    inst:ListenForEvent("ms_player_message", function(player, data)
        if data and data.message then
            HandleChatCommand(player, data.message)
        end
    end)
end)

-- 延迟初始化标记
local initialized = false
local function InitPanel()
    if initialized then return end
    initialized = true
    
    print("[Musha Panel] 职业面板初始化完成")
    print("[Musha Panel] 聊天命令可用: /musha, /class, /职业")
end

-- 服务器启动后初始化
AddPrefabPostInit("world", function(inst)
    if not GLOBAL.TheWorld or not GLOBAL.TheWorld.ismastersim then 
        return 
    end
    inst:DoTaskInTime(0.1, InitPanel)
end)

print("[Musha Panel] 职业面板已加载")
