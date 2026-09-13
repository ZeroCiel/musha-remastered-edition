-- ============================================
-- musha_item_stats.lua（2026-09-12 自动生成 + 可手工补充）
--   用途：客户端悬停信息面板显示"伤害 / 位面伤害 / 保暖"等数值，
--         但**客户端读不到** weapon.damage、insulator.insulation、planardamage.basedamage
--         （这些组件都没有 replica，是服务端专有的）→ 用这张静态表代替（Show Me 同一套路）
--   数据来源：扫描原版 data/databundles/scripts/prefabs/*.lua 与 mod 自己 prefabs/*.lua 里的
--       SetDamage(...)                 → dmg    普通伤害
--       planardamage:SetBaseDamage(..) → planar 位面伤害
--       SetInsulation(...)             → warm   保暖（冬季隔热）
--       SetInsulationFromHeat(...)     → cool   隔热（夏季）
--       planardefense:SetBaseDefense() → pdef   位面防御
--   值的形式：数字 = 数值；字符串 = TUNING 里的键名（原版改了会自动跟）
--   扩展：以后做"宝藏值 / 能量回复"就往对应条目加 treasure = / mp_regen = 字段
-- ============================================

local STATS = {
    ["abigail"] = { planar = "ABIGAIL_SHADOW_VEX_PLANAR_DAMAGE", pdef = "SKILLS.WENDY.GHOST_PLANARDEFENSE" },
    ["abigail_murder_buff"] = { planar = "ABIGAIL_SHADOW_VEX_PLANAR_DAMAGE", pdef = "SKILLS.WENDY.GHOST_PLANARDEFENSE" },
    ["abigail_retaliation"] = { planar = "ABIGAIL_SHADOW_VEX_PLANAR_DAMAGE", pdef = "SKILLS.WENDY.GHOST_PLANARDEFENSE" },
    ["abigail_vex_hit"] = { planar = "ABIGAIL_SHADOW_VEX_PLANAR_DAMAGE", pdef = "SKILLS.WENDY.GHOST_PLANARDEFENSE" },
    ["alterguardian_phase1"] = { planar = "ALTERGUARDIAN_PHASE1_LUNARRIFT_PLANAR_DAMAGE" },
    ["alterguardian_phase1_lunarrift"] = { planar = "ALTERGUARDIAN_PHASE1_LUNARRIFT_PLANAR_DAMAGE" },
    ["alterguardian_phase1_lunarrift_gestalt"] = { planar = "ALTERGUARDIAN_PHASE1_LUNARRIFT_PLANAR_DAMAGE" },
    ["alterguardian_phase2"] = { planar = "ALTERGUARDIAN_PHASE1_LUNARRIFT_PLANAR_DAMAGE" },
    ["alterguardian_phase4_lunarrift"] = { planar = "ALTERGUARDIAN_PHASE4_LUNARRIFT_PLANAR_DAMAGE" },
    ["armor_lunarplant"] = { pdef = "ARMOR_LUNARPLANT_PLANAR_DEF" },
    ["armor_lunarplant_husk"] = { pdef = "ARMOR_LUNARPLANT_PLANAR_DEF" },
    ["armor_voidcloth"] = { pdef = "ARMOR_VOIDCLOTH_PLANAR_DEF" },
    ["armordreadstone"] = { pdef = "ARMORDREADSTONE_PLANAR_DEF" },
    ["armorwagpunk"] = { pdef = "ARMORPUNK_PLANAR_DEF" },
    ["ash"] = { planar = "WAGBOSS_MISSILE_PLANAR_DAMAGE" },
    ["axe"] = { dmg = "AXE_DAMAGE" },
    ["batbat"] = { dmg = "BATBAT_DAMAGE" },
    ["bearger"] = { planar = "MUTATED_BEARGER_PLANAR_DAMAGE" },
    ["beargervest"] = { warm = "INSULATION_LARGE" },
    ["bernie_big"] = { planar = "BERNIE_PLANAR_DAMAGE", pdef = "BERNIE_PLANAR_DEFENCE" },
    ["bernie_big_fire"] = { planar = "BERNIE_PLANAR_DAMAGE", pdef = "BERNIE_PLANAR_DEFENCE" },
    ["bernie_inactive"] = { planar = "BERNIE_PLANAR_DAMAGE", pdef = "BERNIE_PLANAR_DEFENCE" },
    ["bodypillow_"] = { dmg = "PILLOW_DAMAGE" },
    ["bomb_lunarplant"] = { planar = "BOMB_LUNARPLANT_PLANAR_DAMAGE" },
    ["boomerang"] = { dmg = "BOOMERANG_DAMAGE" },
    ["bramblefx_armor_upgrade"] = { pdef = "ARMOR_LUNARPLANT_PLANAR_DEF" },
    ["brush"] = { dmg = "BRUSH_DAMAGE" },
    ["bugnet"] = { dmg = "BUGNET_DAMAGE" },
    ["bullkelp_plant"] = { dmg = "BULLKELP_ROOT_DAMAGE" },
    ["bullkelp_root"] = { dmg = "BULLKELP_ROOT_DAMAGE" },
    ["buzzard"] = { planar = "MUTATEDBUZZARD_PLANAR_DAMAGE" },
    ["cane"] = { dmg = "CANE_DAMAGE" },
    ["cave_vent_mite"] = { planar = "CAVE_MITE_PLANAR_DAMAGE" },
    ["chest_mimic"] = { planar = "CHEST_MIMIC_PLANAR_DAMAGE" },
    ["chest_mimic_revealed"] = { planar = "CHEST_MIMIC_PLANAR_DAMAGE" },
    ["chum"] = { dmg = "UNARMED_DAMAGE" },
    ["chum_aoe"] = { dmg = "UNARMED_DAMAGE" },
    ["clayhound"] = { planar = "MUTATED_WARG_PLANAR_DAMAGE" },
    ["collapse_small"] = { dmg = 75, planar = "ALTERGUARDIAN_PHASE1_LUNARRIFT_PLANAR_DAMAGE" },
    ["compass"] = { dmg = "UNARMED_DAMAGE" },
    ["cutless"] = { dmg = "CUTLESS_DAMAGE" },
    ["deerclops"] = { planar = "MUTATED_DEERCLOPS_PLANAR_DAMAGE" },
    ["deerclops_laserscorch"] = { planar = "WILLOW_LUNAR_FIRE_PLANAR_DAMAGE" },
    ["eyeflame"] = { planar = "MUTATED_WARG_PLANAR_DAMAGE" },
    ["fan_wheel"] = { dmg = "MINIFAN_DAMAGE" },
    ["farm_hoe"] = { dmg = "FARM_HOE_DAMAGE" },
    ["fence_rotator"] = { dmg = "FENCE_ROTATOR_DAMAGE" },
    ["fishingrod"] = { dmg = "FISHINGROD_DAMAGE" },
    ["forcefieldfx"] = { planar = "SHADOWTHRALL_PARASITE_PLANAR_DAMAGE", warm = "INSULATION_SMALL", pdef = "ARMOR_DREADSTONEHAT_PLANAR_DEF" },
    ["frog"] = { planar = "LUNARFROG_PLANAR_DAMAGE" },
    ["frogsplash"] = { planar = "LUNARFROG_PLANAR_DAMAGE" },
    ["fused_shadeling"] = { planar = "FUSED_SHADELING_PLANAR_DAMAGE" },
    ["fused_shadeling_bomb_scorch"] = { planar = "SHADOWTHRALL_WINGS_PLANAR_DAMAGE" },
    ["gelblob"] = { planar = "GELBLOB_PLANAR_DAMAGE" },
    ["gestalt_cage"] = { dmg = "GESTALT_CAGE_DAMAGE" },
    ["gestalt_cage_filled1"] = { dmg = "GESTALT_CAGE_DAMAGE" },
    ["gestalt_cage_filled2"] = { dmg = "GESTALT_CAGE_DAMAGE" },
    ["gestalt_cage_filled3"] = { dmg = "GESTALT_CAGE_DAMAGE" },
    ["gestalt_cage_filled_placerindicator"] = { dmg = "GESTALT_CAGE_DAMAGE" },
    ["gestalt_guard_evolved"] = { dmg = "GESTALT_EVOLVED_FAR_DAMAGE", planar = "GESTALT_EVOLVED_MID_PLANAR_DAMAGE", warm = "INSULATION_SMALL", pdef = "ARMOR_DREADSTONEHAT_PLANAR_DEF" },
    ["gestalt_guard_head"] = { dmg = "GESTALT_EVOLVED_FAR_DAMAGE", planar = "GESTALT_EVOLVED_MID_PLANAR_DAMAGE" },
    ["glasscutter"] = { dmg = "GLASSCUTTER.DAMAGE" },
    ["golden_farm_hoe"] = { dmg = "FARM_HOE_DAMAGE" },
    ["goldenaxe"] = { dmg = "AXE_DAMAGE" },
    ["goldenpickaxe"] = { dmg = "PICK_DAMAGE" },
    ["goldenpitchfork"] = { dmg = "PITCHFORK_DAMAGE" },
    ["goldenshovel"] = { dmg = "SHOVEL_DAMAGE" },
    ["grass_umbrella"] = { warm = "INSULATION_MED" },
    ["ground_chunks_breaking"] = { planar = "SADDLE_SHADOW_PLANAR_DAMAGE", pdef = "SADDLE_SHADOW_PLANAR_DEF" },
    ["hambat"] = { dmg = "HAMBAT_DAMAGE" },
    ["hammer"] = { dmg = "HAMMER_DAMAGE" },
    ["handpillow_"] = { dmg = "PILLOW_DAMAGE" },
    ["hawaiianshirt"] = { warm = "INSULATION_LARGE" },
    ["horrorfuel"] = { planar = "SHADOWTHRALL_PARASITE_PLANAR_DAMAGE", warm = "INSULATION_SMALL", pdef = "ARMOR_DREADSTONEHAT_PLANAR_DEF" },
    ["houndstooth_blowpipe"] = { dmg = "UNARMED_DAMAGE", planar = "HOUNDSTOOTH_BLOWPIPE_PLANAR_DAMAGE" },
    ["houndstooth_proj"] = { dmg = "UNARMED_DAMAGE", planar = "HOUNDSTOOTH_BLOWPIPE_PLANAR_DAMAGE" },
    ["impact"] = { planar = "BERNIE_PLANAR_DAMAGE", pdef = "BERNIE_PLANAR_DEFENCE" },
    ["knight_yoth"] = { planar = "SHADOWTHRALL_PARASITE_PLANAR_DAMAGE", warm = "INSULATION_SMALL", pdef = "ARMOR_DREADSTONEHAT_PLANAR_DEF" },
    ["koalefantcorpse"] = { planar = "MUTATED_WARG_PLANAR_DAMAGE" },
    ["koalefantcorpse_prop"] = { dmg = "SPAT_PHLEGM_DAMAGE", planar = "MUTATED_WARG_PLANAR_DAMAGE" },
    ["lunar_grazer"] = { planar = "LUNAR_GRAZER_PLANAR_DAMAGE" },
    ["lunar_grazer_debris"] = { planar = "LUNAR_GRAZER_PLANAR_DAMAGE" },
    ["lunarfrog"] = { planar = "LUNARFROG_PLANAR_DAMAGE" },
    ["lunarplanttentacle"] = { planar = "LUNARPLANTTENTACLE_PLANARDAMAGE" },
    ["lunarthrall_plant"] = { planar = "LUNARTHRALL_PLANT_PLANAR_DAMAGE" },
    ["lunarthrall_plant_back"] = { planar = "LUNARTHRALL_PLANT_PLANAR_DAMAGE" },
    ["lunarthrall_plant_vine"] = { planar = "LUNARTHRALL_PLANT_PLANAR_DAMAGE" },
    ["lunarthrall_plant_vine_end"] = { planar = "LUNARTHRALL_PLANT_PLANAR_DAMAGE" },
    ["malbatross"] = { dmg = 75 },
    ["malbatross_feather_fall"] = { dmg = 75 },
    ["minifan"] = { dmg = "MINIFAN_DAMAGE" },
    ["monkey"] = { dmg = "MONKEY_RANGED_DAMAGE" },
    ["moonglassaxe"] = { dmg = "AXE_DAMAGE" },
    ["moonspider_spike"] = { dmg = "SPIDER_SPITTER_DAMAGE_RANGED" },
    ["multitool_axe_pickaxe"] = { dmg = "MULTITOOL_DAMAGE" },
    ["musha_sword"] = { dmg = 42 },  -- musha
    ["mutatedbearger"] = { planar = "MUTATED_BEARGER_PLANAR_DAMAGE" },
    ["mutatedbird"] = { planar = "RIFT_BIRD_PLANAR_DAMAGE" },
    ["mutatedbuzzard_gestalt"] = { planar = "MUTATEDBUZZARD_PLANAR_DAMAGE" },
    ["mutateddeerclops"] = { planar = "MUTATED_DEERCLOPS_PLANAR_DAMAGE" },
    ["nightstick"] = { dmg = "NIGHTSTICK_DAMAGE" },
    ["nightstickfire"] = { dmg = "NIGHTSTICK_DAMAGE" },
    ["nightsword"] = { dmg = "NIGHTSWORD_DAMAGE" },
    ["oceanfishingrod"] = { dmg = "FISHINGROD_DAMAGE" },
    ["pandorachest_reset"] = { planar = "CHEST_MIMIC_PLANAR_DAMAGE" },
    ["pickaxe"] = { dmg = "PICK_DAMAGE" },
    ["pickaxe_lunarplant"] = { planar = "PICKAXE_LUNARPLANT_PLANAR_DAMAGE" },
    ["pitchfork"] = { dmg = "PITCHFORK_DAMAGE" },
    ["pocketwatch_weapon"] = { dmg = "POCKETWATCH_SHADOW_DAMAGE" },
    ["poop"] = { dmg = "MONKEY_RANGED_DAMAGE" },
    ["propsign"] = { dmg = 1 },
    ["propsignshatterfx"] = { dmg = 1 },
    ["raincoat"] = { warm = "INSULATION_SMALL" },
    ["reflectivevest"] = { warm = "INSULATION_MED" },
    ["ruins_bat"] = { dmg = "RUINS_BAT_DAMAGE" },
    ["saddlehorn"] = { dmg = "SADDLEHORN_DAMAGE" },
    ["shadow_battleaxe"] = { dmg = "SHADOW_BATTLEAXE.DAMAGE", planar = "SHADOW_BATTLEAXE.LEVEL[inst.level].PLANAR_DAMAGE" },
    ["shadow_battleaxe_classified"] = { dmg = "SHADOW_BATTLEAXE.DAMAGE", planar = "SHADOW_BATTLEAXE.LEVEL[inst.level].PLANAR_DAMAGE" },
    ["shadow_puff_large_front"] = { planar = "ABIGAIL_SHADOW_VEX_PLANAR_DAMAGE", pdef = "SKILLS.WENDY.GHOST_PLANARDEFENSE" },
    ["shadowtentacle"] = { dmg = "RUINS_BAT_DAMAGE" },
    ["shadowthrall_centipede_body"] = { planar = "SHADOWTHRALL_CENTIPEDE.PLANAR_DAMAGE" },
    ["shadowthrall_centipede_controller"] = { planar = "SHADOWTHRALL_CENTIPEDE.PLANAR_DAMAGE" },
    ["shadowthrall_centipede_head"] = { planar = "SHADOWTHRALL_CENTIPEDE.PLANAR_DAMAGE" },
    ["shadowthrall_hands"] = { planar = "SHADOWTHRALL_HANDS_PLANAR_DAMAGE" },
    ["shadowthrall_horns"] = { planar = "SHADOWTHRALL_HORNS_PLANAR_DAMAGE" },
    ["shadowthrall_mouth"] = { planar = "SHADOWTHRALL_MOUTH_BITE_PLANAR_DAMAGE" },
    ["shadowthrall_wings"] = { planar = "SHADOWTHRALL_WINGS_PLANAR_DAMAGE" },
    ["shieldofterror"] = { dmg = "SHIELDOFTERROR_DAMAGE" },
    ["shovel"] = { dmg = "SHOVEL_DAMAGE" },
    ["shovel_lunarplant"] = { planar = "SHOVEL_LUNARPLANT_PLANAR_DAMAGE" },
    ["slingshotammo_purebrilliance_debuff"] = { planar = "SLINGSHOT_BRILLIANCE_MARK_PLANAR_DAMAGE" },
    ["spat"] = { dmg = "SPAT_PHLEGM_DAMAGE" },
    ["spat_bomb"] = { dmg = "SPAT_PHLEGM_DAMAGE" },
    ["spear"] = { dmg = "SPEAR_DAMAGE" },
    ["spear_wathgrithr"] = { dmg = "SPEAR_WATHGRITHR_LIGHTNING_LUNGE_DAMAGE" },
    ["spider"] = { dmg = "SPIDER_SPITTER_DAMAGE_RANGED" },
    ["spider_dropper"] = { dmg = "SPIDER_SPITTER_DAMAGE_RANGED" },
    ["spider_healer"] = { dmg = "SPIDER_SPITTER_DAMAGE_RANGED" },
    ["spider_hider"] = { dmg = "SPIDER_SPITTER_DAMAGE_RANGED" },
    ["spider_moon"] = { dmg = "SPIDER_SPITTER_DAMAGE_RANGED" },
    ["spider_spitter"] = { dmg = "SPIDER_SPITTER_DAMAGE_RANGED" },
    ["spider_warrior"] = { dmg = "SPIDER_SPITTER_DAMAGE_RANGED" },
    ["spider_water"] = { dmg = "SPIDER_SPITTER_DAMAGE_RANGED" },
    ["splash_green"] = { dmg = "UNARMED_DAMAGE" },
    ["splash_sink"] = { dmg = "WATERPLANT.ITEM_DAMAGE" },
    ["staff_lunarplant"] = { planar = "STAFF_LUNARPLANT_PLANAR_DAMAGE" },
    ["statue_transition"] = { dmg = "MONKEY_RANGED_DAMAGE" },
    ["statue_transition_2"] = { dmg = "MONKEY_RANGED_DAMAGE" },
    ["sweatervest"] = { warm = "INSULATION_SMALL" },
    ["sword_lunarplant"] = { planar = "SWORD_LUNARPLANT_PLANAR_DAMAGE" },
    ["tentaclespike"] = { dmg = "SPIKE_DAMAGE" },
    ["thulecitebugnet"] = { dmg = "BUGNET_DAMAGE" },
    ["tophat_container"] = { planar = "SHADOWTHRALL_PARASITE_PLANAR_DAMAGE", warm = "INSULATION_SMALL", pdef = "ARMOR_DREADSTONEHAT_PLANAR_DEF" },
    ["torch"] = { dmg = "TORCH_DAMAGE" },
    ["trap_vines"] = { planar = "TRAP_VINES_PLANAR_DAMAGE" },
    ["trunkvest_summer"] = { warm = "INSULATION_SMALL" },
    ["trunkvest_winter"] = { warm = "INSULATION_SMALL" },
    ["umbrella"] = { warm = "INSULATION_MED" },
    ["voidcloth_boomerang"] = { dmg = "VOIDCLOTH_BOOMERANG_DAMAGE.min", planar = "VOIDCLOTH_BOOMERANG_PLANAR_DAMAGE.min" },
    ["voidcloth_boomerang_proj"] = { dmg = "VOIDCLOTH_BOOMERANG_DAMAGE.min", planar = "VOIDCLOTH_BOOMERANG_PLANAR_DAMAGE.min" },
    ["voidcloth_scythe"] = { dmg = "VOIDCLOTH_SCYTHE_DAMAGE", planar = "VOIDCLOTH_SCYTHE_PLANAR_DAMAGE" },
    ["voidcloth_scythe_classified"] = { dmg = "VOIDCLOTH_SCYTHE_DAMAGE", planar = "VOIDCLOTH_SCYTHE_PLANAR_DAMAGE" },
    ["voidcloth_umbrella"] = { warm = "INSULATION_LARGE" },
    ["wagboss_missile"] = { planar = "WAGBOSS_MISSILE_PLANAR_DAMAGE" },
    ["wagboss_robot"] = { planar = "WAGBOSS_ROBOT_PLANAR_DAMAGE" },
    ["wagpunkhat_classified"] = { planar = "SHADOWTHRALL_PARASITE_PLANAR_DAMAGE", warm = "INSULATION_SMALL", pdef = "ARMOR_DREADSTONEHAT_PLANAR_DEF" },
    ["warg_gooicing"] = { planar = "MUTATED_WARG_PLANAR_DAMAGE" },
    ["waterplant_bomb"] = { dmg = "WATERPLANT.ITEM_DAMAGE" },
    ["waterplant_burr_burst"] = { dmg = "WATERPLANT.ITEM_DAMAGE" },
    ["whip"] = { dmg = "WHIP_DAMAGE" },
    ["willow_frenzy"] = { planar = "WILLOW_LUNAR_FIRE_PLANAR_DAMAGE" },
    ["willow_throw_flame"] = { planar = "WILLOW_LUNAR_FIRE_PLANAR_DAMAGE" },
    ["wortox_nabbag"] = { dmg = "SKILLS.WORTOX.NABBAG_DAMAGE_MIN" },
    ["wortox_nabbag_body"] = { dmg = "SKILLS.WORTOX.NABBAG_DAMAGE_MIN" },
    ["wortox_nabbag_body_soulfx"] = { dmg = "SKILLS.WORTOX.NABBAG_DAMAGE_MIN" },
    ["wurt_merm_planar"] = { planar = "WURT_PLANAR_BUFF_DAMAGE" },
    ["wurt_tentacle_warning"] = { planar = "WURT_PLANAR_BUFF_DAMAGE" },
    ["wurt_water_splash_"] = { planar = "WURT_PLANAR_BUFF_DAMAGE" },
    ["yoth_knightstick"] = { dmg = "CANE_DAMAGE" },
    ["yoth_lance"] = { dmg = "YOTH_LANCE_ATTACK_DAMAGE" },
}

-- 取一项数值：field = "dmg" / "planar" / "warm" / "cool" / "pdef" / "treasure" / "mp_regen"
--   TUNING 键名形式的在调用时解析（读不到就当没有，不报错）
function MushaItemStat(prefab, field)
    local e = STATS[prefab]
    if not e then return nil end
    local v = e[field]
    if v == nil then return nil end
    if type(v) == "string" then
        local T = TUNING
        return T and T[v] or nil
    end
    return v
end

function MushaHasItemStat(prefab)
    return STATS[prefab] ~= nil
end


-- ── 追加：护甲减伤 absorb / 移速倍率 speed（2026-09-13 自动扫描 prefabs 生成，39 条） ──
--   来源：prefabs 里的 SetAbsorption / InitCondition(_, absorb) / InitIndestructible / equippable.walkspeedmult
--   ⚠️ 客户端读不到 item.components.armor（armor 等组件写在 master_postinit，客户端没有副本）→ 只能靠这张表
--   speed < 1 = 减速（重甲/背包），speed 缺省 = 不影响移速
local ARMOR_EXTRA = {
    ["amulet"] = { speed = 1.2 },   -- vanilla
    ["armor_bramble"] = { absorb = "ARMORBRAMBLE_ABSORPTION" },   -- vanilla
    ["armor_dragonfly"] = { absorb = "ARMORDRAGONFLY_ABSORPTION" },   -- vanilla
    ["armor_dreadstone"] = { absorb = "ARMORDREADSTONE_ABSORPTION" },   -- vanilla
    ["armor_grass"] = { absorb = "ARMORGRASS_ABSORPTION" },   -- vanilla
    ["armor_lunarplant"] = { absorb = "ARMOR_LUNARPLANT_ABSORPTION" },   -- vanilla
    ["armor_marble"] = { absorb = "ARMORMARBLE_ABSORPTION", speed = "ARMORMARBLE_SLOW" },   -- vanilla
    ["armor_ruins"] = { absorb = "ARMORRUINS_ABSORPTION" },   -- vanilla
    ["armor_sanity"] = { absorb = "ARMOR_SANITY_ABSORPTION" },   -- vanilla
    ["armor_snurtleshell"] = { absorb = "ARMORSNURTLESHELL_ABSORPTION" },   -- vanilla
    ["armor_voidcloth"] = { absorb = "ARMOR_VOIDCLOTH_ABSORPTION" },   -- vanilla
    ["armor_wagpunk"] = { absorb = "ARMORPUNK_ABSORPTION", speed = 1 },   -- vanilla
    ["armor_wood"] = { absorb = "ARMORWOOD_ABSORPTION" },   -- vanilla
    ["armor_yoth_knight"] = { absorb = "ARMOR_YOTH_KNIGHT_ABSORPTION" },   -- vanilla
    ["beargervest"] = { absorb = "ARMOR_BEEHAT_ABSORPTION" },   -- vanilla
    ["cane"] = { speed = "CANE_SPEED_MULT" },   -- vanilla
    ["cavein_boulder"] = { speed = "HEAVY_SPEED_MULT" },   -- vanilla
    ["chesspieces"] = { speed = "HEAVY_SPEED_MULT" },   -- vanilla
    ["costumes"] = { absorb = "COSTUME_PRINCESS_BODY_ABSORPTION" },   -- vanilla
    ["glass_spike"] = { speed = "HEAVY_SPEED_MULT" },   -- vanilla
    ["hats"] = { absorb = "ARMOR_YOTH_KNIGHTHAT_ABSORPTION", speed = "ICEHAT_SPEED_MULT" },   -- vanilla
    ["moon_altar_pieces"] = { speed = "HEAVY_SPEED_MULT" },   -- vanilla
    ["musha_sword"] = { speed = 1.0 },   -- musha
    ["oceantreenut"] = { speed = "HEAVY_SPEED_MULT" },   -- vanilla
    ["piggyback"] = { speed = "PIGGYBACK_SPEED_MULT" },   -- vanilla
    ["potatosack"] = { speed = "HEAVY_SPEED_MULT" },   -- vanilla
    ["ruins_bat"] = { speed = "RUINS_BAT_SPEED_MULT" },   -- vanilla
    ["sculpture_pieces"] = { speed = "HEAVY_SPEED_MULT" },   -- vanilla
    ["shell_cluster"] = { speed = "HEAVY_SPEED_MULT" },   -- vanilla
    ["shieldofterror"] = { absorb = "SHIELDOFTERROR_ABSORPTION" },   -- vanilla
    ["snowman"] = { speed = "HEAVY_SPEED_MULT" },   -- vanilla
    ["spear_wathgrithr"] = { speed = "SPEAR_WATHGRITHR_LIGHTNING_CHARGED_SPEED_MULT" },   -- vanilla
    ["staff"] = { speed = "CANE_SPEED_MULT" },   -- vanilla
    ["treasurechest"] = { speed = "HEAVY_SPEED_MULT" },   -- vanilla
    ["veggies"] = { speed = "HEAVY_SPEED_MULT" },   -- vanilla
    ["voidcloth_boomerang"] = { speed = "VOIDCLOTH_BOOMERANG_SPEEDMULT" },   -- vanilla
    ["walking_stick"] = { speed = "WALKING_STICK_SPEED_MULT" },   -- vanilla
    ["wathgrithr_shield"] = { absorb = "WATHGRITHR_SHIELD_ABSORPTION" },   -- vanilla
    ["yoth_knightstick"] = { speed = "CANE_SPEED_MULT" },   -- vanilla
}
for k, v in pairs(ARMOR_EXTRA) do
    STATS[k] = STATS[k] or {}
    for kk, vv in pairs(v) do
        STATS[k][kk] = vv
    end
end

MUSHA_ITEM_STATS = STATS

return STATS
