-- ====================================
-- musha_rpcs.lua
-- ModRPC 定义
-- 客户端→服务端：加点请求
-- 服务端→客户端：技能数据同步
-- ====================================

-- 加点请求（客户端→服务端）
-- 参数：skill_id (string)
GLOBAL.AddModRPCHandler("musha_skill_upgrade", function(player, skill_id)
    if not player or not player:IsValid() then return end
    if not GLOBAL.TheWorld.ismastersim then return end

    local pc = player.components.musha_profession_component
    if not pc then return end

    -- skill_id 如 "warrior_combat_recovery" → skill_tree="warrior", skill_name="combat_recovery"
    local tree, name = skill_id:match("^(%w+)_(.+)$")
    if not tree or not name then
        if player.components.talker then
            player.components.talker:Say("无效技能", 3)
        end
        return
    end

    local success, reason = pc:UpgradeSkill(tree, name)
    if not success and player.components.talker then
        player.components.talker:Say("技能升级失败: " .. tostring(reason), 3)
    end
end)

-- 服务端→客户端：发送技能数据刷新 UI
GLOBAL.AddModRPCHandler("musha_skill_data_update", function(player, data_str)
    if GLOBAL.TheWorld.ismastersim then return end

    local data = GLOBAL.json.decode(data_str)
    if not data then return end

    local player_inst = GLOBAL.ThePlayer
    if player_inst and player_inst.components.musha_skillui then
        player_inst.components.musha_skillui:ReceiveData(data)
    end
end)

-- 请求打开技能书 UI（客户端→服务端，获取初始数据）
GLOBAL.AddModRPCHandler("musha_request_skill_data", function(player)
    if not player or not player:IsValid() then return end
    if not GLOBAL.TheWorld.ismastersim then return end

    local pc = player.components.musha_profession_component
    if not pc then return end

    local data = {
        skill_points = pc.mydata.skill_points or 0,
        level = pc.mydata.level or 0,
        exp = pc.mydata.exp or 0,
        job = pc.mydata.carrer_base,
        advance_job = pc.mydata.carrer_special,
    }

    local skill_info = pc:GetAllSkillLevels()

    data.skills = skill_info

    local json_str = GLOBAL.json.encode(data)
    player.Network:SendModRPCToClient(
        GLOBAL.GetModRPCIndex("musha_skill_data_update"),
        json_str
    )
end)

-- 打开技能面板（服务端→客户端）
GLOBAL.AddModRPCHandler("musha_open_skill_panel", function(player)
    if GLOBAL.TheWorld.ismastersim then return end

    local player_inst = GLOBAL.ThePlayer
    if not player_inst then return end

    -- 先请求服务端数据
    SendModRPCToServer(GetModRPCIndex("musha_request_skill_data"))

    -- 打开技能 UI（如果有 skillui 组件）
    if player_inst.components.musha_skillui then
        player_inst.components.musha_skillui:OpenUI()
    end
end)
