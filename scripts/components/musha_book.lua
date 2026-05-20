-- 文件名：musha_book_component.lua
-- 描述：Musha职业书组件，包含使用条件检查、图标变更、玩家记录等功能

local MushaBook = Class(function(self, inst)
    self.inst = inst
    self.onreadfn = nil              -- 使用回调函数
    self.conditionsfn = nil          -- 条件检查函数
    self.transformfn = nil           -- 转换函数（用于变成手册）
    self.used_players = {}           -- 记录使用过的玩家ID
    self.is_used_style = false       -- 是否已使用样式
    self.owner_id = nil              -- 拥有者ID
    self.profession = nil            -- 所属职业
    self.is_manual = false           -- 是否是职业手册
    self.manual_data = nil           -- 手册数据
end)

-- 设置使用回调函数
function MushaBook:SetOnRead(fn)
    self.onreadfn = fn
end

-- 设置条件检查函数
function MushaBook:SetConditions(fn)
    self.conditionsfn = fn
end

-- 设置转换函数
function MushaBook:SetTransformFn(fn)
    self.transformfn = fn
end

-- 检查使用条件
function MushaBook:CheckConditions(reader)
    if not reader then
        return false, "没有读者"
    end
    
    if not self.conditionsfn then
        return true, "无限制条件"
    end
    
    return self.conditionsfn(reader)
end

-- 记录玩家ID
function MushaBook:RecordPlayer(player_id)
    if not player_id then
        return false
    end
    
    if not self.used_players[player_id] then
        self.used_players[player_id] = true
        self.owner_id = player_id
        self.inst:AddTag("used_by_" .. player_id)
        
        return true
    end
    
    return false
end

-- 检查玩家是否已使用过
function MushaBook:IsUsedByPlayer(player)
    if not player or not player.userid then
        return false
    end
    
    return self.used_players[player.userid] or false
end

-- 变更图标样式
function MushaBook:ChangeIconStyle(used_atlas, used_image, new_name, new_description)
    if not self.inst.components.inventoryitem then
        return false
    end
    
    if used_atlas and used_image then
        self.inst.components.inventoryitem.atlasname = used_atlas
        self.inst.components.inventoryitem.imagename = used_image
    end
    
    if new_name and self.inst.components.named then
        self.inst.components.named:SetName(new_name)
    end
    
    if new_description and self.inst.components.inspectable then
        self.inst.components.inspectable.descriptionfn = function()
            return new_description
        end
    end
    
    self.is_used_style = true
    
    if self.inst.components.inventoryitem.owner and 
       self.inst.components.inventoryitem.owner.components.inventory then
        self.inst.components.inventoryitem.owner.components.inventory:GiveItem(self.inst)
    end
    
    return true
end

-- 恢复图标样式
function MushaBook:RestoreIconStyle(original_atlas, original_image, original_name, original_description)
    if not self.inst.components.inventoryitem then
        return false
    end
    
    if original_atlas and original_image then
        self.inst.components.inventoryitem.atlasname = original_atlas
        self.inst.components.inventoryitem.imagename = original_image
    end
    
    if original_name and self.inst.components.named then
        self.inst.components.named:SetName(original_name)
    end
    
    if original_description and self.inst.components.inspectable then
        self.inst.components.inspectable.descriptionfn = function()
            return original_description
        end
    end
    
    self.is_used_style = false
    
    if self.inst.components.inventoryitem.owner and 
       self.inst.components.inventoryitem.owner.components.inventory then
        self.inst.components.inventoryitem.owner.components.inventory:GiveItem(self.inst)
    end
    
    return true
end

-- 设置职业
function MushaBook:SetProfession(profession)
    self.profession = profession
    self.inst:AddTag("profession_" .. profession)
end

-- 获取职业
function MushaBook:GetProfession()
    return self.profession
end

-- 转换职业书为职业手册
function MushaBook:TransformToManual(player, manual_data)
    if not player or not manual_data then
        return false
    end
    
    self.is_manual = true
    self.manual_data = manual_data
    self.owner_id = player.userid
    
    self.inst:AddTag("profession_manual")
    self.inst:AddTag("owner_" .. (player.userid or "unknown"))
    
    if self.transformfn then
        return self.transformfn(self.inst, player, manual_data)
    end
    
    return false
end

-- 获取手册数据
function MushaBook:GetManualData()
    return self.manual_data
end

-- 检查是否是手册
function MushaBook:IsManual()
    return self.is_manual
end

-- 获取拥有者ID
function MushaBook:GetOwnerId()
    return self.owner_id
end

-- 检查拥有者
function MushaBook:IsOwnedBy(player)
    if not player or not player.userid then
        return false
    end
    
    return self.owner_id == player.userid
end

-- 打开手册（查看信息）
function MushaBook:OpenManual(reader)
    if not self.is_manual then
        return false, "这不是职业手册"
    end
    
    if not self:IsOwnedBy(reader) then
        return false, "这不是我的职业手册"
    end
    
    if reader.components.talker then
        reader.components.talker:Say("正在查看职业信息...")
    end
    
    reader:PushEvent("open_musha_profession_info", {
        profession = self.profession,
        owner_id = self.owner_id,
        manual_data = self.manual_data
    })
    
    return true, "正在打开职业信息"
end

-- 序列化
function MushaBook:OnSave()
    return {
        used_players = self.used_players,
        is_used_style = self.is_used_style,
        owner_id = self.owner_id,
        profession = self.profession,
        is_manual = self.is_manual,
        manual_data = self.manual_data
    }
end

function MushaBook:OnLoad(data)
    if data then
        if data.used_players then
            self.used_players = data.used_players
        end
        
        if data.owner_id then
            self.owner_id = data.owner_id
        end
        
        if data.profession then
            self.profession = data.profession
        end
        
        if data.is_used_style ~= nil then
            self.is_used_style = data.is_used_style
        end
        
        if data.is_manual ~= nil then
            self.is_manual = data.is_manual
        end
        
        if data.manual_data then
            self.manual_data = data.manual_data
        end
    end
end

function MushaBook:OnLoadPostPass()
    if self.owner_id and ThePlayer and ThePlayer.userid == self.owner_id then
        if self.is_used_style and not self.inst:HasTag("owner_" .. self.owner_id) then
            self.inst:AddTag("owner_" .. self.owner_id)
        end
        
        if self.is_manual and not self.inst:HasTag("profession_manual") then
            self.inst:AddTag("profession_manual")
        end
    end
end

-- 获取调试信息
function MushaBook:GetDebugString()
    local parts = {}
    
    if self.profession then
        table.insert(parts, "职业:" .. self.profession)
    end
    
    if self.owner_id then
        table.insert(parts, "拥有者:" .. self.owner_id)
    end
    
    if self.is_used_style then
        table.insert(parts, "已使用")
    end
    
    if self.is_manual then
        table.insert(parts, "是手册")
    end
    
    if #self.used_players > 0 then
        table.insert(parts, "使用人数:" .. tostring(#self.used_players))
    end
    
    return table.concat(parts, " ")
end

-- 重置组件
function MushaBook:Reset()
    self.used_players = {}
    self.is_used_style = false
    self.owner_id = nil
    self.is_manual = false
    self.manual_data = nil
    
    self.inst:RemoveTag("profession_manual")
    
    for tag in pairs(self.inst.tags) do
        if tag:find("^owner_") or tag:find("^used_by_") or tag:find("^profession_") then
            self.inst:RemoveTag(tag)
        end
    end
    
    return true
end

-- 组件注册
return MushaBook
