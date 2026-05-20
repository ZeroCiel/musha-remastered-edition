local MakePlayerCharacter = require "prefabs/player_common"

local assets = {Asset("SCRIPT", "scripts/prefabs/player_common.lua")}
local Character = "musha"
local ATLAS = {
    map_icons = {
        main_path = "images",
        secondary_path = "map_icons",
        xml = {""}
    },
    avatars = {
        main_path = "images",
        secondary_path = "avatars",
        xml = {"avatar_", "avatar_ghost_", "self_inspect_"}
    },
    --[[saveslot_portraits = {
        main_path = "images",
        secondary_path = "saveslot_portraits",
        xml = { "" }
    },]]
    bigportraits = {
        main_path = "bigportraits",
        xml = {"", "_none"}
    }
}

for k, v in pairs(ATLAS) do
    if v.main_path and v.secondary_path then
        for i, _name in pairs(v.xml) do
            table.insert(assets, Asset("ATLAS", v.main_path .. "/" .. v.secondary_path .. "/" .. (_name or "") ..
                Character .. ".xml"))
        end
    elseif v.main_path and v.secondary_path == nil then
        for i, _name in pairs(v.xml) do
            table.insert(assets, Asset("ATLAS", v.main_path .. "/" .. Character .. (_name or "") .. ".xml"))
        end
    end
end

table.insert(assets, Asset("ANIM", "anim/" .. Character .. ".zip"))
table.insert(assets, Asset("ANIM", "anim/ghost_" .. Character .. "_build.zip"))
table.insert(assets, Asset("ATLAS", "images/names_" .. Character .. ".xml"))

local item = {"musha_note"}
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.MUSHA = {"musha_note"}
TUNING.STARTING_ITEM_IMAGE_OVERRIDE["musha_note"] = {
    atlas = "images/inventoryimages/musha_note.xml",
    image = "musha_note.tex"
}

TUNING.MUSHA_HEALTH = 120
TUNING.MUSHA_SANITY = 80
TUNING.MUSHA_HUNGER = 180

-- 主客机都会执行的部分
local common_postinit = function(inst)
    inst:AddTag(Character)
    inst.MiniMapEntity:SetIcon(Character .. ".tex")
    -- 网络变量：服务端改值后客户端监听 mushapanelchanged 事件
    inst._musha_panel_net = net_bool(inst.GUID, "musha_panel_net", "mushapanelchanged")
    -- 监听网络变量变化（服务端和客户端都注册，函数内过滤）
    inst:ListenForEvent("mushapanelchanged", function()
        if TheWorld.ismastersim then return end
        if inst._musha_panel_net and inst._musha_panel_net:value() then
            local p = ThePlayer
            if p and p.components.musha_skillui and not p.components.musha_skillui._is_open then
                SendModRPCToServer(GetModRPCIndex("musha_request_skill_data"))
                p.components.musha_skillui:OpenUI()
            end
        end
    end)
end

-- 主机执行部分
local master_postinit = function(inst, data)
    inst.soundsname = "wilson"
    inst.components.health:SetMaxHealth(TUNING.MUSHA_HEALTH)
    inst.components.sanity:SetMax(TUNING.MUSHA_SANITY)
    inst.components.hunger:SetMax(TUNING.MUSHA_HUNGER)

    -- 服务端组件
    inst:AddComponent("musha_profession_component")
end

return MakePlayerCharacter(Character, nil, assets, common_postinit, master_postinit, item),
    CreatePrefabSkin("musha_none", {
        base_prefab = "musha", -- 主要的皮肤
        type = "base",
        rarity = "Character",
        skins = {
            normal_skin = "musha",
            ghost_skin = "ghost_musha_build"
        },
        assets = {Asset("ANIM", "anim/musha.zip"), Asset("ANIM", "anim/ghost_musha_build.zip")},
        skin_tags = {"BASE", "musha", "CHARACTER"},
        build_name_override = "musha"
    })
