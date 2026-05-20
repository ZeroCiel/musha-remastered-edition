-- 客户端职业组件
-- 文件名：musha_profession_replica.lua
-- 描述：客户端版本，用于接收和显示服务端的职业数据

local Musha_Profession_Component = Class(function(self, inst)
    self.inst = inst
    
    -- 网络变量定义
    self.gamedata = net_string(inst.GUID, "musha_gamedata", "gamedata_dirty")
    
    -- 职业相关网络变量
    self.warrior = net_string(inst.GUID, "musha_warrior_data", "warrior_dirty")
    self.saber = net_string(inst.GUID, "musha_saber_data", "saber_dirty")
    self.guardian = net_string(inst.GUID, "musha_guardian_data", "guardian_dirty")
    self.mage = net_string(inst.GUID, "musha_mage_data", "mage_dirty")
    
    -- 本地缓存的数据
    self.cached_data = {
        userdata = {},
        warrior = {},
        saber = {},
        guardian = {},
        mage = {}
    }
    
    -- 脏标记
    self.is_dirty = false
    self.last_update_time = 0
    
    -- 监听网络变量变化
    self.inst:ListenForEvent("gamedata_dirty", function(inst)
        self:OnGameDataDirty()
    end)
    
    self.inst:ListenForEvent("warrior_dirty", function(inst)
        self:OnWarriorDataDirty()
    end)
    
    self.inst:ListenForEvent("saber_dirty", function(inst)
        self:OnSaberDataDirty()
    end)
    
    self.inst:ListenForEvent("guardian_dirty", function(inst)
        self:OnGuardianDataDirty()
    end)
    
    self.inst:ListenForEvent("mage_dirty", function(inst)
        self:OnMageDataDirty()
    end)
    
    -- 调试模式
    self.debug_mode = false
end)

-- 更新主数据
function Musha_Profession_Component:DoUpdata(pair)
    if not pair then
        return false
    end
    
    local success, json_str = pcall(json.encode, pair)
    if success and json_str then
        self.gamedata:set(json_str)
        
        -- 尝试解析并缓存
        local parse_success, parsed_data = pcall(json.decode, json_str)
        if parse_success and parsed_data then
            self.cached_data.userdata = parsed_data
            self.is_dirty = true
            self.last_update_time = GetTime()
            
            if self.debug_mode then
                print("[Musha Client] 主数据更新成功")
            end
        end
        
        return true
    end
    
    return false
end

-- 更新战士数据
function Musha_Profession_Component:UpdataWarrior(data)
    if not data then
        return false
    end
    
    local success, json_str = pcall(json.encode, data)
    if success and json_str then
        self.warrior:set(json_str)
        
        local parse_success, parsed_data = pcall(json.decode, json_str)
        if parse_success and parsed_data then
            self.cached_data.warrior = parsed_data
            self.is_dirty = true
            
            if self.debug_mode then
                print("[Musha Client] 战士数据更新成功")
            end
        end
        
        return true
    end
    
    return false
end

-- 更新剑士数据
function Musha_Profession_Component:UpdataSaber(data)
    if not data then
        return false
    end
    
    local success, json_str = pcall(json.encode, data)
    if success and json_str then
        self.saber:set(json_str)
        
        local parse_success, parsed_data = pcall(json.decode, json_str)
        if parse_success and parsed_data then
            self.cached_data.saber = parsed_data
            self.is_dirty = true
            
            if self.debug_mode then
                print("[Musha Client] 剑士数据更新成功")
            end
        end
        
        return true
    end
    
    return false
end

-- 更新近卫数据
function Musha_Profession_Component:UpdataGuardian(data)
    if not data then
        return false
    end
    
    local success, json_str = pcall(json.encode, data)
    if success and json_str then
        self.guardian:set(json_str)
        
        local parse_success, parsed_data = pcall(json.decode, json_str)
        if parse_success and parsed_data then
            self.cached_data.guardian = parsed_data
            self.is_dirty = true
            
            if self.debug_mode then
                print("[Musha Client] 近卫数据更新成功")
            end
        end
        
        return true
    end
    
    return false
end

-- 更新法师数据
function Musha_Profession_Component:UpdataMage(data)
    if not data then
        return false
    end
    
    local success, json_str = pcall(json.encode, data)
    if success and json_str then
        self.mage:set(json_str)
        
        local parse_success, parsed_data = pcall(json.decode, json_str)
        if parse_success and parsed_data then
            self.cached_data.mage = parsed_data
            self.is_dirty = true
            
            if self.debug_mode then
                print("[Musha Client] 法师数据更新成功")
            end
        end
        
        return true
    end
    
    return false
end

-- 网络变量变化处理函数
function Musha_Profession_Component:OnGameDataDirty()
    local json_str = self.gamedata:value()
    if json_str and json_str ~= "" then
        local success, parsed_data = pcall(json.decode, json_str)
        if success and parsed_data then
            self.cached_data.userdata = parsed_data
            self.is_dirty = true
            self.last_update_time = GetTime()
            
            -- 触发事件
            self.inst:PushEvent("musha_gamedata_updated", {data = parsed_data})
            
            if self.debug_mode then
                print("[Musha Client] 游戏数据同步完成")
            end
        end
    end
end

function Musha_Profession_Component:OnWarriorDataDirty()
    local json_str = self.warrior:value()
    if json_str and json_str ~= "" then
        local success, parsed_data = pcall(json.decode, json_str)
        if success and parsed_data then
            self.cached_data.warrior = parsed_data
            self.is_dirty = true
            
            self.inst:PushEvent("musha_warrior_updated", {data = parsed_data})
        end
    end
end

function Musha_Profession_Component:OnSaberDataDirty()
    local json_str = self.saber:value()
    if json_str and json_str ~= "" then
        local success, parsed_data = pcall(json.decode, json_str)
        if success and parsed_data then
            self.cached_data.saber = parsed_data
            self.is_dirty = true
            
            self.inst:PushEvent("musha_saber_updated", {data = parsed_data})
        end
    end
end

function Musha_Profession_Component:OnGuardianDataDirty()
    local json_str = self.guardian:value()
    if json_str and json_str ~= "" then
        local success, parsed_data = pcall(json.decode, json_str)
        if success and parsed_data then
            self.cached_data.guardian = parsed_data
            self.is_dirty = true
            
            self.inst:PushEvent("musha_guardian_updated", {data = parsed_data})
        end
    end
end

function Musha_Profession_Component:OnMageDataDirty()
    local json_str = self.mage:value()
    if json_str and json_str ~= "" then
        local success, parsed_data = pcall(json.decode, json_str)
        if success and parsed_data then
            self.cached_data.mage = parsed_data
            self.is_dirty = true
            
            self.inst:PushEvent("musha_mage_updated", {data = parsed_data})
        end
    end
end

-- 获取玩家职业信息的接口
function Musha_Profession_Component:GetProfessionInfo()
    local userdata = self.cached_data.userdata or {}
    
    return {
        base = userdata.carrer_base or nil,      -- 基础职业
        special = userdata.carrer_special or nil, -- 一转职业
        level = userdata.level or 0,             -- 等级
        skill_points = userdata.skill_points or 0, -- 技能点
        exp = userdata.exp or 0,                 -- 当前经验
        exp_to_next = userdata.exp_to_next or 0,  -- 下一级所需经验
        total_exp = userdata.total_exp or 0       -- 总经验
    }
end

-- 检查是否是特定职业
function Musha_Profession_Component:IsProfession(profession_type)
    local userdata = self.cached_data.userdata or {}
    
    if profession_type == "warrior" or profession_type == "rogue" or 
       profession_type == "mage" or profession_type == "ranger" then
        return userdata.carrer_base == profession_type
    else
        return userdata.carrer_special == profession_type
    end
end

-- 获取特定职业的数据
function Musha_Profession_Component:GetProfessionData(profession_type)
    if profession_type == "warrior" then
        return self.cached_data.warrior or {}
    elseif profession_type == "saber" then
        return self.cached_data.saber or {}
    elseif profession_type == "guardian" then
        return self.cached_data.guardian or {}
    elseif profession_type == "mage" then
        return self.cached_data.mage or {}
    end
    
    return {}
end

-- 获取所有职业数据
function Musha_Profession_Component:GetAllProfessionData()
    return {
        userdata = self.cached_data.userdata or {},
        warrior = self.cached_data.warrior or {},
        saber = self.cached_data.saber or {},
        guardian = self.cached_data.guardian or {},
        mage = self.cached_data.mage or {}
    }
end

-- 检查是否有职业
function Musha_Profession_Component:HasProfession()
    local userdata = self.cached_data.userdata or {}
    return userdata.carrer_base ~= nil
end

-- 检查是否可以转职
function Musha_Profession_Component:CanSpecialize()
    local userdata = self.cached_data.userdata or {}
    
    if not userdata.carrer_base then
        return false, "还没有选择基础职业"
    end
    
    if userdata.carrer_special then
        return false, "已经转职过了"
    end
    
    if (userdata.level or 0) < 7 then
        return false, "需要达到7级才能转职"
    end
    
    return true, "可以转职"
end

-- 获取职业描述
function Musha_Profession_Component:GetProfessionDescription()
    local userdata = self.cached_data.userdata or {}
    local base = userdata.carrer_base
    local special = userdata.carrer_special
    
    if not base then
        return "无职业"
    end
    
    local descriptions = {
        warrior = "战士",
        rogue = "刺客",
        mage = "法师",
        ranger = "游侠",
        saber = "剑士",
        guardian = "近卫"
    }
    
    if special then
        return string.format("%s → %s", descriptions[base] or base, descriptions[special] or special)
    else
        return string.format("%s (Lv.%d)", descriptions[base] or base, userdata.level or 0)
    end
end

-- 获取经验信息
function Musha_Profession_Component:GetExpInfo()
    local userdata = self.cached_data.userdata or {}
    local level = userdata.level or 0
    local exp = userdata.exp or 0
    local exp_to_next = userdata.exp_to_next or 0
    
    return {
        level = level,
        exp = exp,
        exp_to_next = exp_to_next,
        exp_percent = exp_to_next > 0 and (exp / exp_to_next) * 100 or 0
    }
end

-- 获取技能点信息
function Musha_Profession_Component:GetSkillPointsInfo()
    local userdata = self.cached_data.userdata or {}
    return {
        skill_points = userdata.skill_points or 0,
        level = userdata.level or 0
    }
end

-- 调试功能
function Musha_Profession_Component:SetDebugMode(enabled)
    self.debug_mode = enabled
    if enabled then
        print("[Musha Client] 调试模式已启用")
    end
end

function Musha_Profession_Component:DebugPrint()
    if not self.debug_mode then
        return
    end
    
    print("=== Musha Client Debug Info ===")
    print("Last Update: " .. (self.last_update_time or 0))
    print("Is Dirty: " .. tostring(self.is_dirty))
    
    local prof_info = self:GetProfessionInfo()
    print("Profession: " .. (prof_info.base or "None"))
    print("Special: " .. (prof_info.special or "None"))
    print("Level: " .. prof_info.level)
    print("Skill Points: " .. prof_info.skill_points)
    print("================================")
end

-- 序列化支持
function Musha_Profession_Component:OnSave()
    return {
        cached_data = self.cached_data,
        last_update_time = self.last_update_time
    }
end

function Musha_Profession_Component:OnLoad(data)
    if data then
        if data.cached_data then
            self.cached_data = data.cached_data
        end
        if data.last_update_time then
            self.last_update_time = data.last_update_time
        end
        
        self.is_dirty = true
    end
end

-- 强制刷新
function Musha_Profession_Component:ForceRefresh()
    self.is_dirty = true
    self.inst:PushEvent("musha_data_force_refresh")
end

return Musha_Profession_Component