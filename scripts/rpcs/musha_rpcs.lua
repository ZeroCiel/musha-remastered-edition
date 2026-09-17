-- ====================================
-- musha_rpcs.lua
-- ModRPC 定义
-- DST API：AddModRPCHandler(namespace, name, fn) / GetModRPC(namespace, name)
-- ====================================

local NS = "musha"

-- ====================================
-- 礼包领取（客户端→服务端，2026-09-12 新增）
--   面板「礼包」页点「领取」调它；数据表在 scripts/musha_gifts.lua
--   服务端校验：礼包存在 / enabled / 活动时间内 / 没领过 → 发物品 + 记 pc.userdata.gifts
-- ====================================
GLOBAL.AddModRPCHandler(NS, "musha_claim_gift", function(player, gift_id)
    if not player or not player:IsValid() then return end
    if not GLOBAL.TheWorld.ismastersim then return end
    if type(gift_id) ~= "string" then return end

    local function Say(msg, t)
        if player.components.talker then
            player.components.talker:Say(msg, t or 3)
        end
    end

    local ok, GIFTS = pcall(GLOBAL.require, "musha_gifts")
    if not ok or type(GIFTS) ~= "table" then
        Say("礼包数据读取失败")
        return
    end

    local gift = nil
    for _, g in ipairs(GIFTS) do
        if g.id == gift_id then
            gift = g
            break
        end
    end
    if gift == nil then
        Say("没有这个礼包")
        return
    end
    if gift.enabled == false then
        Say("该礼包暂未开放")
        return
    end

    local pc = player.components.musha_profession_component
    if not pc then
        Say("职业系统未就绪")
        return
    end
    pc.userdata.gifts = pc.userdata.gifts or {}
    if pc.userdata.gifts[gift_id] then
        Say("这个礼包你已经领过了")
        return
    end

    -- ★ 可领判定（2026-09-14 改双轨；跟面板显示同一口径）
    local cycles = (GLOBAL.TheWorld.state and GLOBAL.TheWorld.state.cycles) or 0
    if gift.kind == "cycle" then
        -- ① 游戏时间礼包：按游戏内天数
        local need = gift.day or 0
        if cycles < need then
            Say(string.format("还差 %d 天才能领（第 %d 天开放）", need - cycles, need))
            return
        end
    elseif gift.kind == "festival" then
        -- ② 节日礼包：按现实日期窗口（本机时间，含首尾）
        local today = os.date("%Y-%m-%d")
        if gift.from ~= nil and today < gift.from then
            Say("这个礼包还没到时间")
            return
        end
        if gift.to ~= nil and today > gift.to then
            Say("这个礼包已经结束了")
            return
        end
    else
        -- ③ 老字段兼容：period.start_day / end_day（游戏内天数区间）
        local p = gift.period
        if p and p.start_day and p.end_day then
            if cycles < p.start_day or cycles > p.end_day then
                Say("这个礼包不在活动时间内")
                return
            end
        end
    end

    -- 发放
    local inv = player.components.inventory
    if not inv then
        Say("背包不可用")
        return
    end
    local given = 0
    for _, it in ipairs(gift.items or {}) do
        for _ = 1, (it.count or 1) do
            local ent = GLOBAL.SpawnPrefab(it.prefab)
            if ent then
                inv:GiveItem(ent)
                given = given + 1
            end
        end
    end
    if given <= 0 then
        Say("礼包发放失败")
        return
    end

    pc.userdata.gifts[gift_id] = GLOBAL.GetTime() or 0
    -- 推一次给客机（面板据此把按钮变成"已领取"）
    pcall(function() pc:PushSettings() end)

    Say("礼包已领取：" .. tostring(gift.name) .. "（共 " .. tostring(given) .. " 件）", 4)
end)

-- 加点请求（客户端→服务端）
-- 参数：skill_id (string)
GLOBAL.AddModRPCHandler(NS, "musha_skill_upgrade", function(player, skill_id)
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

-- 用背包里的技能书解锁（客户端 → 服务端）
--   ★ 2026-09-18：面板技能页「点锁 / 点 +」走这条（用户："点加点和图片都可以打开"）；
--   失败原因原样回给玩家（没有书 / 已经解锁过 / 这技能不用书）
GLOBAL.AddModRPCHandler(NS, "musha_skill_unlock", function(player, skill_id)
    if not player or not player:IsValid() then return end
    if not GLOBAL.TheWorld.ismastersim then return end

    local pc = player.components.musha_profession_component
    if not pc then return end

    local tree, name = skill_id and skill_id:match("^(%w+)_(.+)$")
    if not tree or not name then
        if player.components.talker then player.components.talker:Say("无效技能", 3) end
        return
    end

    local ok, reason = pc:UnlockSkillWithItem(tree, name)
    if not ok and player.components.talker then
        player.components.talker:Say(tostring(reason), 3)
    end
end)

-- 服务端→客户端：发送技能数据刷新 UI
GLOBAL.AddModRPCHandler(NS, "musha_skill_data_update", function(player, data_str)
    if GLOBAL.TheWorld.ismastersim then return end

    local data = GLOBAL.json.decode(data_str)
    if not data then return end

    local player_inst = GLOBAL.ThePlayer
    if player_inst and player_inst.components.musha_skillui then
        player_inst.components.musha_skillui:ReceiveData(data)
    end
end)

-- 请求打开技能书 UI（客户端→服务端，获取初始数据）
GLOBAL.AddModRPCHandler(NS, "musha_request_skill_data", function(player)
    if not player or not player:IsValid() then return end
    if not GLOBAL.TheWorld.ismastersim then return end

    local pc = player.components.musha_profession_component
    if not pc then return end

    local data = {
        skill_points = pc.userdata.skill_points or 0,
        level = pc.userdata.level or 0,
        exp = pc.userdata.exp or 0,
        job = pc.userdata.carrer_base,
        advance_job = pc.userdata.carrer_special,
    }

    local skill_info = pc:GetAllSkillLevels()

    data.skills = skill_info

    local json_str = GLOBAL.json.encode(data)
    player.Network:SendModRPCToClient(GLOBAL.GetModRPC(NS, "musha_skill_data_update"), json_str)
end)

-- 打开技能面板（服务端→客户端）
GLOBAL.AddModRPCHandler(NS, "musha_open_skill_panel", function(player)
    if GLOBAL.TheWorld.ismastersim then return end

    local player_inst = GLOBAL.ThePlayer
    if not player_inst then return end

    -- 先请求服务端数据
    SendModRPCToServer(GetModRPC(NS, "musha_request_skill_data"))

    -- 打开技能 UI（如果有 skillui 组件）
    if player_inst.components.musha_skillui then
        player_inst.components.musha_skillui:OpenUI()
    end
end)

-- ====================================
-- 武器绑定的技能：施放（客户端→服务端，2026-09-13）
--   客户端只发瞄点；校验/冷却/伤害全在服务端（见 scripts/musha_weapon_skill.lua）
--   x/z = -9999 表示"客户端没瞄点"，服务端按角色面向自己推
-- ====================================
GLOBAL.AddModRPCHandler(NS, "musha_weapon_skill_cast", function(player, x, z)
    if not player or not player:IsValid() then return end
    if not GLOBAL.TheWorld.ismastersim then return end

    local ok, WS = pcall(GLOBAL.require, "musha_weapon_skill")
    if not ok or type(WS) ~= "table" then return end

    local pos = nil
    if type(x) == "number" and type(z) == "number" and x > -9000 then
        pos = GLOBAL.Vector3(x, 0, z)
    end
    WS.DoCast(player, pos)
end)

-- ====================================
-- 局内设置（2026-09-10 新增）
-- ====================================

-- 设置：客户端→服务端
-- 参数：scope("world"/"player"), key(string), value(number)  —— bool 用 1/0 传
GLOBAL.AddModRPCHandler(NS, "musha_set_setting", function(player, scope, key, value)
    if not player or not player:IsValid() then return end
    if not GLOBAL.TheWorld.ismastersim then return end

    local pc = player.components.musha_profession_component
    if not pc then return end

    local ok, reason = pc:SetMushaSetting(scope, key, value, player)
    if not ok and reason == "no_permission" and player.components.talker then
        player.components.talker:Say("只有房主/管理员能改世界设置", 3)
    end
end)

-- 设置：客户端开面板时拉一次最新值（服务端→回推设置快照）
GLOBAL.AddModRPCHandler(NS, "musha_request_settings", function(player)
    if not player or not player:IsValid() then return end
    if not GLOBAL.TheWorld.ismastersim then return end

    local pc = player.components.musha_profession_component
    if pc then
        pc:PushSettings()
    end
end)
