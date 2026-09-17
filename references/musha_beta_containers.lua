local containers = require "containers"
local params = containers.params
params.musha_armor_prototype = {
    widget = {
        slotpos = {},
        animbank = "ui_backpack_2x4",
        animbuild = "ui_backpack_2x4",
        pos = Vector3(-5, -70, 0),
        side_align_tip = 160
    },
    issidewidget = true,
    type = "pack"
}
for y = 0, 3 do
    table.insert(params.musha_armor_prototype.widget.slotpos, Vector3(-162, -75 * y + 114, 0))
    table.insert(params.musha_armor_prototype.widget.slotpos, Vector3(-162 + 75, -75 * y + 114, 0))
end

params.musha_armor_princess = {
    widget = {
        slotpos = {},
        animbank = "ui_krampusbag_2x8",
        animbuild = "ui_krampusbag_2x8",
        pos = Vector3(-5, -80, 0),
        side_align_tip = 160
    },
    issidewidget = true,
    type = "pack"
}
for y = -1, 5 do
    table.insert(params.musha_armor_princess.widget.slotpos, Vector3(-162, -75 * y + 170, 0))
    table.insert(params.musha_armor_princess.widget.slotpos, Vector3(-162 + 75, -75 * y + 170, 0))
end

params.musha_armor_frost = {
    widget = {
        slotpos = {},
        animbank = "ui_backpack_2x4",
        animbuild = "ui_backpack_2x4",
        pos = Vector3(-5, -70, 0),
        side_align_tip = 160
    },
    issidewidget = true,
    type = "pack"
}
for y = 0, 3 do
    table.insert(params.musha_armor_frost.widget.slotpos, Vector3(-162, -75 * y + 114, 0))
    table.insert(params.musha_armor_frost.widget.slotpos, Vector3(-162 + 75, -75 * y + 114, 0))
end

params.musha_armor_pirate = {
    widget = {
        slotpos = {},
        animbank = "ui_krampusbag_2x8",
        animbuild = "ui_krampusbag_2x8",
        pos = Vector3(-5, -80, 0),
        side_align_tip = 160
    },
    issidewidget = true,
    type = "pack"
}
for y = -1, 5 do
    table.insert(params.musha_armor_pirate.widget.slotpos, Vector3(-162, -75 * y + 170, 0))
    table.insert(params.musha_armor_pirate.widget.slotpos, Vector3(-162 + 75, -75 * y + 170, 0))
end

--super bird
params.super_yamche = {
    widget = {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = Vector3(0, 200, 0),
        side_align_tip = 160
    },
    type = "chest"
}
for y = 2, 0, -1 do
    for x = 0, 2 do
        table.insert(params.super_yamche.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0))
    end
end

---pill_bottle_gourd
params.chest_yamche0 = {
    widget = {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = Vector3(0, 150, 0),
        side_align_tip = 160
    },
    type = "chest"
}
for y = 1, 0, -1 do
    table.insert(params.chest_yamche0.widget.slotpos, Vector3(74 * y - 74 * 2 + 70, 0))
end

params.chest_yamche1 = {
    widget = {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = Vector3(0, 150, 0),
        side_align_tip = 160
    },
    type = "chest"
}
for y = 1, 0, -1 do
    for x = 0, 1 do
        table.insert(params.chest_yamche1.widget.slotpos, Vector3(80 * x - 80 * 2 + 78, 80 * y - 80 * 2 + 80, 0))
    end
end

params.chest_yamche2 = {
    widget = {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = Vector3(0, 180, 0),
        side_align_tip = 160
    },
    type = "chest"
}
for y = 2, 0, -1 do
    for x = 0, 1 do
        table.insert(params.chest_yamche2.widget.slotpos, Vector3(80 * x - 76 * 2 + 78, 80 * y - 78 * 2 + 78, 0))
    end
end

params.chest_yamche3 = {
    widget = {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = Vector3(0, 180, 0),
        side_align_tip = 160
    },
    type = "chest"
}
for y = 2, 0, -1 do
    for x = 0, 1 do
        table.insert(params.chest_yamche3.widget.slotpos, Vector3(80 * x - 76 * 2 + 78, 80 * y - 78 * 2 + 78, 0))
    end
end

params.chest_yamche4 = {
    widget = {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "UI_Musha_4x4",
        pos = Vector3(0, 0, 0)
        -- side_align_tip = 160
    },
    type = "chest"
}
for y = 3, 0, -1 do
    for x = 0, 3 do
        table.insert(params.chest_yamche4.widget.slotpos, Vector3(75 * x - 75 * 2 + 30, 75 * y - 75 * 2 + 30, 0))
    end
end

params.musha_icebox = {
    widget = {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "UI_Musha_4x4",
        pos = Vector3(-120, 180, 0)
        -- side_align_tip = 160
    },
    type = "chest"
}
for y = 3, 0, -1 do
    for x = 0.6, 3.6 do
        table.insert(params.musha_icebox.widget.slotpos, Vector3(75 * x - 75 * 2 + 25, 75 * y - 75 * 2 + 25, 0))
    end
end

function params.musha_icebox.itemtestfn(container, item, slot)
    if item:HasTag("icebox_valid") or item:HasTag("fish") then
        return true
    end

    --Perishable
    if not (item:HasTag("fresh") or item:HasTag("stale") or item:HasTag("spoiled")) then
        return false
    end

    if item:HasTag("smallcreature") then
        return false
    end

    --Edible
    for k, v in pairs(FOODTYPE) do
        if item:HasTag("edible_" .. v) then
            return true
        end
    end

    return false
end

-- function params.musha_icebox.itemtestfn(container, item, slot)
-- return item.components.edible
-- end

params.arong = {
    widget = {
        slotpos = {},
        animbank = "ui_chester_shadow_3x4",
        animbuild = "ui_chester_shadow_3x4",
        pos = Vector3(0, 180, 0),
        side_align_tip = 160
    },
    type = "chest"
}
for y = 4, 0, -1 do
    for x = 0, 3 do
        table.insert(params.arong.widget.slotpos, Vector3(75 * x - 75 * 2 + 30, 75 * y - 75 * 2 + 2, 0))
    end
end

params.arom = {
    widget = {
        slotpos = {},
        animbank = "ui_chester_shadow_3x4",
        animbuild = "ui_chester_shadow_3x4",
        pos = Vector3(0, 180, 0),
        side_align_tip = 160
    },
    type = "chest"
}
for y = 4, 0, -1 do
    for x = 0, 3 do
        table.insert(params.arom.widget.slotpos, Vector3(75 * x - 75 * 2 + 30, 75 * y - 75 * 2 + 2, 0))
    end
end

params.musha_forge = {
    widget = {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "UI_Musha_forege",
        pos = Vector3(-220, 160, 0),
        side_align_tip = 0
    },
    type = "chest"
}
for y = 3, -1, -1 do
    for x = 0.2, 3.2 do
        table.insert(params.musha_forge.widget.slotpos, Vector3(75 * x - 75 * 2 + 60, 75 * y - 75 * 2 + 60, 0))
    end
end

params.musha_arrow_rast = {
    widget = {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "UI_Musha_arrow_rast",
        pos = Vector3(-180, 220, 0)
        -- side_align_tip = 160
    },
    type = "chest"
}
for y = 1, 0, -1 do
    for x = 0.6, 3.6 do
        table.insert(params.musha_arrow_rast.widget.slotpos, Vector3(75 * x - 75 * 2 + 25, 75 * y - 75 * 2 + 25, 0))
    end
end

function params.musha_arrow_rast.itemtestfn(container, item, slot)
    return item:HasTag("musha_weapon_arrow") or item.prefab == "musha_weapon_bow"
end

params.musha_weapon_bow = {
    widget = {
        slotpos = {
            Vector3(-35, 15, 0),
            Vector3(45, 15, 0)
        },
        slotbg = {
            {
                atlas = "images/ui/ui_musha_arror.xml",
                image = "ui_musha_arror.tex"
            },
            {
                atlas = "images/ui/ui_musha_arror.xml",
                image = "ui_musha_arror.tex"
            }
        },
        animbank = "ui_chest_3x3",
        animbuild = "UI_Musha_weapon",
        pos = Vector3(0, 30, 0)
        -- side_align_tip = 160
    },
    -- issidewidget = true,
    -- usespecificslotsforitems = true,
    type = "hand_inv"
}

function params.musha_weapon_bow.itemtestfn(container, item, slot)
    return item:HasTag("musha_weapon_arrow")
end

params.musha_weapon_sword = {
    widget = {
        slotpos = {
            Vector3(-40, 15, 0),
            Vector3(30, 15, 0)
        },
        slotbg = {
            {
                atlas = "images/ui/ui_musha_magic_gem.xml",
                image = "ui_musha_magic_gem.tex"
            },
            {
                atlas = "images/ui/ui_musha_properties_gem.xml",
                image = "ui_musha_properties_gem.tex"
            }
        },
        animbank = "ui_chest_3x3",
        animbuild = "UI_Musha_weapon",
        pos = Vector3(0, 30, 0)
    },
    acceptsstacks = false,
    type = "hand_inv"
}

function params.musha_weapon_sword.itemtestfn(container, item, slot)
    return (slot == 1 and (item.prefab == "redgem" or item.prefab == "bluegem" or item.prefab == "greengem")) or (slot == 2 and (item.prefab == "yellowgem" or item.prefab == "orangegem" or item.prefab == "purplegem"))
end

params.musha_forge_x = {
    widget = {
        slotpos = {
            Vector3(0, 120, 0),
            Vector3(0, 30, 0),
            Vector3(0, -30, 0),
            Vector3(0, -90, 0)
        },
        --[[slotbg = {
            {
                atlas = "images/ui/inv_slot_construction.xml",
                image = "inv_slot_construction.tex"
            },
            {
                atlas = "images/ui/inv_slot_construction.xml",
                image = "inv_slot_construction.tex"
            },
            {
                atlas = "images/ui/inv_slot_construction.xml",
                image = "inv_slot_construction.tex"
            },
            {
                atlas = "images/ui/inv_slot_construction.xml",
                image = "inv_slot_construction.tex"
            }
        },]]
        animbank = "ui_cookpot_1x4",
        animbuild = "ui_cookpot_1x4",
        pos = Vector3(0, 30, 0),
        buttoninfo = {
            text = STRINGS.MUSHA_ARMOR_FORGE,
            position = Vector3(0, -165, 0)
        }
    },
    acceptsstacks = false,
    type = "cooker"
}

--[[function params.musha_forge_x.itemtestfn(container, item, slot)
    return (slot == 1 and (item.prefab == "redgem" or item.prefab == "bluegem" or item.prefab == "greengem")) or (slot == 2 and (item.prefab == "yellowgem" or item.prefab == "orangegem" or item.prefab == "purplegem"))
end]]

function params.musha_forge_x.widget.buttoninfo.validfn(inst)
    return inst.replica.container ~= nil and not inst.replica.container:IsEmpty()
end

--[[function params.musha_weapon_sword.widget.buttoninfo.fn(inst)
    if inst.components.container ~= nil and inst.components.inventoryitem ~= nil then
        BufferedAction(inst.components.container.opener, inst, ACTIONS.MUSHA_SWORD_STATE):Do()
    elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
        SendRPCToServer(RPC.DoWidgetButtonAction, ACTIONS.MUSHA_SWORD_STATE.code, inst, ACTIONS.MUSHA_SWORD_STATE.mod_name)
    end
end]]
params.musha_weapon_spear = {
    widget = {
        slotpos = {
            Vector3(-0, 15, 0)
        },
        slotbg = {
            {
                atlas = "images/ui/ui_musha_magic_gem.xml",
                image = "ui_musha_magic_gem.tex"
            }
        },
        animbank = "ui_chest_3x3",
        animbuild = "UI_Musha_spear",
        pos = Vector3(0, 30, 0)
    },
    acceptsstacks = false,
    type = "hand_inv"
}

function params.musha_weapon_spear.itemtestfn(container, item, slot)
    return item.prefab == "redgem" or item.prefab == "bluegem"
end

params.musha_moon_tree = {
    widget = {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_moon",
        pos = GLOBAL.Vector3(0, 180, 0),
        side_align_tip = 160
    },
    type = "chest"
}
for y = 5, 0, -1 do
    for x = 0, 14 do
        table.insert(params.musha_moon_tree.widget.slotpos, Vector3(60 * x - 60 * 2 + -150, 60 * y - 60 * 2 + 10, 0))
    end
end

params.musha_treasure_chest = {
    widget = {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "UI_Musha_4x4",
        pos = Vector3(-120, 180, 0)
        -- side_align_tip = 160
    },
    type = "chest"
}
for y = 3, 0, -1 do
    for x = 0.6, 3.6 do
        table.insert(params.musha_treasure_chest.widget.slotpos, Vector3(75 * x - 75 * 2 + 25, 75 * y - 75 * 2 + 25, 0))
    end
end

for k, v in pairs(params) do
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
end
