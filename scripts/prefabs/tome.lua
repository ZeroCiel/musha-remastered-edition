-- 职业书数据配置
-- 使用 _G.STRINGS 表引用，而不是硬编码中文
local STRINGS = _G.STRINGS
local BOOK_DATA = {
    warrior = {
        name = "warrior_tome",
        display_name = "职业书(战士)",
        simple_name = "职业书",
        carrer = "warrior"
    },
    rogue = {
        name = "rogue_tome",
        display_name = "职业书(刺客)",
        simple_name = "职业书",
        carrer = "rogue"
    },
    mage = {
        name = "mage_tome",
        display_name = "职业书(法师)",
        simple_name = "职业书",
        carrer = "mage"
    },
    ranger = {
        name = "ranger_tome",
        display_name = "职业书(游侠)",
        simple_name = "职业书",
        carrer = "ranger"
    }
}

-- 获取显示名称的函数
local function GetDisplayName(inst)
    local player = ThePlayer
    if not player or not player.replica or not player.replica.musha_profession_component then
        -- 从 STRINGS 表获取完整的显示名称
        if inst._book_data and inst._book_data.name and STRINGS.NAMES[inst._book_data.name:upper()] then
            return STRINGS.NAMES[inst._book_data.name:upper()]
        end
        return "职业书"
    end

    local prof_info = player.replica.musha_profession_component:GetProfessionInfo()

    if prof_info and prof_info.base then
        -- 有职业时返回简单名称
        if inst._book_data and inst._book_data.name and STRINGS.NAMES[inst._book_data.name:upper() .. "_SIMPLE"] then
            return STRINGS.NAMES[inst._book_data.name:upper() .. "_SIMPLE"]
        end
        return "职业书"
    else
        -- 无职业时返回完整名称
        if inst._book_data and inst._book_data.name and STRINGS.NAMES[inst._book_data.name:upper()] then
            return STRINGS.NAMES[inst._book_data.name:upper()]
        end
        return "职业书(未知)"
    end
end

-- 获取职业书描述的函数
local function GetBookDescription(data)
    if not data or not data.name then
        return "一本神秘的书籍。"
    end
    
    local description_key = data.name:upper() .. "_DESCRIPTION"
    if STRINGS.NAMES[description_key] then
        return STRINGS.NAMES[description_key]
    end
    
    -- 回退到通用描述
    if STRINGS.CHARACTERS.GENERIC.DESCRIBE[data.name:upper()] then
        return STRINGS.CHARACTERS.GENERIC.DESCRIBE[data.name:upper()]
    end
    
    return "一本记载着知识的书籍。"
end

-- 使用职业书的函数
local function OnUseItem(inst, doer)
    if not doer or not doer.components.musha_profession_component then
        return false
    end
    
    local comp = doer.components.musha_profession_component
    
    if comp:GetCarrer_base() then
        doer.components.talker:Say(STRINGS.MUSHA_HAS_CARRER)
        return false
    end
    
    local profession = inst._book_data and inst._book_data.carrer
    if not profession then
        doer.components.talker:Say(STRINGS.MUSHA_CHANGE_FAIL)
        return false
    end
    
    local success = comp:SetCarrerBase(profession)
    if not success then
        doer.components.talker:Say(STRINGS.MUSHA_CHANGE_FAIL)
        return false
    end
    
    doer:PushEvent("musha_profession_changed", {profession = profession})
    
    if doer.SoundEmitter then
        doer.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_pulled")
    end
    
    local profession_names = {
        warrior = STRINGS.MUSHA_PROFESSION_WARRIOR or "战士",
        rogue = STRINGS.MUSHA_PROFESSION_ROGUE or "刺客", 
        mage = STRINGS.MUSHA_PROFESSION_MAGE or "法师",
        ranger = STRINGS.MUSHA_PROFESSION_RANGER or "游侠"
    }
    
    doer.components.talker:Say(string.format(STRINGS.MUSHA_BECOME_PROFESSION or "我已成为%s！", profession_names[profession] or profession))
    
    return true
end

-- 创建职业书的函数
local function CreateProfessionBook(data)
    local assets = {Asset("ANIM", "anim/tome.zip"), Asset("ATLAS", "images/inventoryimages/" .. data.name .. ".xml")}
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("tome")
        inst.AnimState:SetBuild("tome")
        
        local anim_suffix = string.gsub(data.name, "_tome", "")
        inst.AnimState:PlayAnimation("idle_" .. anim_suffix)

        inst:AddTag("book")
        inst:AddTag("musha_profession_book")
        inst:AddTag("nosteal")

        inst._book_data = data

        inst.displaynamefn = GetDisplayName

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst.components.inspectable.descriptionfn = function()
            return GetBookDescription(data)
        end

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. data.name .. ".xml"

        inst:AddComponent("musha_book")
        inst.components.musha_book:SetOnRead(function(book, reader)
            if not inst.components.musha_book:CheckConditions(reader) then
                return false
            end

            local success = OnUseItem(inst, reader)

            if success then
                if reader.userid then
                    inst.components.musha_book:RecordPlayer(reader.userid)
                end
                inst.components.musha_book:ChangeIconStyle()
            end

            return success
        end)

        inst.components.musha_book:SetConditions(function(reader)
            if reader.components.musha_profession_component and
                reader.components.musha_profession_component:GetCarrer_base() then
                reader.components.talker:Say(STRINGS.MUSHA_HAS_CARRER)
                return false, STRINGS.MUSHA_HAS_CARRER
            end

            return true, STRINGS.MUSHA_CAN_USE
        end)

        inst:ListenForEvent("musha_profession_changed", function(player, data)
            if inst.components.inventoryitem and inst.components.inventoryitem.owner then
                inst.components.inventoryitem.owner.components.inventory:GiveItem(inst)
            end
        end)

        MakeHauntableLaunch(inst)
        
        function inst:OnSave()
            return {
                book_data = data
            }
        end
        
        function inst:OnLoad(data)
            if data and data.book_data then
                self._book_data = data.book_data
            end
        end

        return inst
    end

    return Prefab(data.name, fn, assets)
end

-- 创建所有职业书
local prefabs = {}
for profession, data in pairs(BOOK_DATA) do
    table.insert(prefabs, CreateProfessionBook(data))
end

-- 字符串定义的引用点说明：
-- 1. 职业书名称：STRINGS.NAMES.WARRIOR_TOME, STRINGS.NAMES.WARRIOR_TOME_SIMPLE
-- 2. 职业书描述：STRINGS.NAMES.WARRIOR_TOME_DESCRIPTION
-- 3. 角色描述：STRINGS.CHARACTERS.GENERIC.DESCRIBE.WARRIOR_TOME
-- 4. UI提示：STRINGS.UI.HUD.TALK.MUSHA_*
-- 5. 职业名称：STRINGS.UI.HUD.TALK.MUSHA_PROFESSION_*

return unpack(prefabs)