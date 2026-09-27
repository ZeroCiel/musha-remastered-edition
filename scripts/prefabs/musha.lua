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
-- 能量条（2026-09-13）：bank/build = energy，动画名 = anim（badge 直接吃这个 build）
table.insert(assets, Asset("ANIM", "anim/energy.zip"))

-- ★ 开局自带（2026-09-20 用户定案）：信差包跟便签一样"出生自带"，走原版 starting_inventory
--   机制 = 只在**新出生**时给一次（player_common.lua:1480 OnNewSpawn「only if it is a new spawn」）；
--     读档 / 跨世界（下洞穴、换世界）/ 掉线重连 都走 OnLoad 分支 → **不给**
--     （player_common.lua:1265-1269 "If this character is being loaded then it isn't a new spawn"
--       里显式 `inst.starting_inventory = nil`）→ 正好是用户要的「跨世界不给」
--   其他玩家想要 → 用配方做（谁都能做；也可以让 musha 给他做）
local item = {"musha_note", "musha_mailbag"}
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.MUSHA = {"musha_note", "musha_mailbag"}
TUNING.STARTING_ITEM_IMAGE_OVERRIDE["musha_note"] = {
    atlas = "images/inventoryimages/musha_note.xml",
    image = "musha_note.tex"
}
-- 信差包也要登记图标：角色选择界面的"开局携带物品"预览读这张表
--   （原版 screens/redux/defaultskinselection.lua:54 / widgets/redux/templates.lua:2125）
TUNING.STARTING_ITEM_IMAGE_OVERRIDE["musha_mailbag"] = {
    atlas = "images/inventoryimages/musha_mailbag.xml",
    image = "musha_mailbag.tex"
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
    -- 监听网络变量变化（服务端和客户端都注册）
    -- 服务端 set(true) → 本端+对端都触发 dirty → PushEvent("musha_open_skill_panel") → panel ShowPanel
    -- 注意：不能过滤 TheWorld.ismastersim——单机/主机模式下玩家自己就是服务端，
    -- set 时服务端本地也触发 dirty，过滤掉会导致主机自己打不开面板。
    inst:ListenForEvent("mushapanelchanged", function()
        if inst._musha_panel_net and inst._musha_panel_net:value() then
            inst:PushEvent("musha_open_skill_panel")
        end
    end)

    -- ★ 2026-09-28 酒馆委托板：服务端在"右键酒馆开容器"时把这个位拨 true，
    --   客户端收到 dirty → PushEvent("musha_open_tavern_panel") → 推酒馆板 Screen。
    --   玩法不变（容器照开），只是**多一块右侧板子**；关掉板子就能取转职卷轴。
    --   复用 musha_panel_net 那套写法：单机/主机也吃 dirty，所以不加 ismastersim 过滤。
    inst._musha_tavern_net = net_bool(inst.GUID, "musha_tavern_net", "mushataavernchanged")
    inst:ListenForEvent("mushataavernchanged", function()
        if inst._musha_tavern_net and inst._musha_tavern_net:value() then
            inst:PushEvent("musha_open_tavern_panel")
        end
    end)

    -- 能量条数值：netvar 同步（服务端 set → 客户端 badge 直接读，不用 RPC）
    --   2026-09-13 照「遗迹守卫」那套官方写法
    inst.Musha_MP     = net_float(inst.GUID, "musha_mp", "musha_mp_dirty")
    inst.Musha_MP_MAX = net_float(inst.GUID, "musha_mp_max", "musha_mp_max_dirty")
end

-- 主机执行部分
local master_postinit = function(inst, data)
    inst.soundsname = "wilson"
    inst.components.health:SetMaxHealth(TUNING.MUSHA_HEALTH)
    inst.components.sanity:SetMax(TUNING.MUSHA_SANITY)
    inst.components.hunger:SetMax(TUNING.MUSHA_HUNGER)

    -- 服务端组件
    inst:AddComponent("musha_profession_component")
    inst:AddComponent("musha_mp")          -- 能量（2026-09-13）：上限/回复读职业表
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
