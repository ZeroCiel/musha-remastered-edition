-- ============================================
-- musha_item_stats2.lua（2026-09-13 自动生成）
--   追加字段（悬停面板用）：
--     food_hunger / food_sanity / food_health  食物三项（edible.*value）
--     uses_max    耐久上限（finiteuses:SetMaxUses）
--     perish_days 新鲜时长（perishable:SetPerishTime，值是秒）
--     fuel_max    燃料上限（fueled:InitializeFuelLevel）
--     stack_max   堆叠上限（stackable:SetMaxSize / .maxsize）
--   值的形式：数字 = 数值；字符串 = TUNING 键名（原版改了会自动跟）
--   ★ 载入顺序：必须在 musha_item_stats 之后（它把字段并进同一张 STATS 表）
-- ============================================

local EXTRA = {
    ["acorn"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_TINY", perish_days = "PERISH_PRESERVED", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["acorn_cooked"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_TINY", perish_days = "PERISH_PRESERVED", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["acorn_placer"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_TINY", perish_days = "PERISH_PRESERVED", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["acorn_sapling"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_TINY", perish_days = "PERISH_PRESERVED", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["alterguardian"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["alterguardian_hat_equipped"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["alterguardianhat_projectile"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["alterguardianhatlight"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["amulet"] = { fuel_max = "BLUEAMULET_FUEL", uses_max = "REDAMULET_USES" },   -- vanilla
    ["ancientfruit_gem"] = { food_hunger = 3, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["ancientfruit_nightvision"] = { food_hunger = 3, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["ancientfruit_nightvision_cooked"] = { food_hunger = 3, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["antchovies"] = { food_health = 0, food_hunger = "CALORIES_TINY", food_sanity = 0, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["antlion"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["antliontrinket"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["archive_resonator"] = { uses_max = "ARCHIVE_RESONATOR" },   -- vanilla
    ["archive_resonator_base"] = { uses_max = "ARCHIVE_RESONATOR" },   -- vanilla
    ["archive_resonator_item"] = { uses_max = "ARCHIVE_RESONATOR" },   -- vanilla
    ["archive_resonator_item_placer"] = { uses_max = "ARCHIVE_RESONATOR" },   -- vanilla
    ["armor_carrotlure"] = { perish_days = "ARMOR_CARROTLURE_PERISHTIME" },   -- vanilla
    ["armorskeleton"] = { fuel_max = 4 },   -- vanilla
    ["armorslurper"] = { fuel_max = "HUNGERBELT_PERISHTIME" },   -- vanilla
    ["ash"] = { fuel_max = 0 },   -- vanilla
    ["axe"] = { uses_max = "AXE_USES" },   -- vanilla
    ["balloon"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["balloon_mapicon"] = { fuel_max = "BALLOON_SPEED_DURATION" },   -- vanilla
    ["balloonspeed"] = { fuel_max = "BALLOON_SPEED_DURATION" },   -- vanilla
    ["balloonvest"] = { fuel_max = "PERISH_ONE_DAY" },   -- vanilla
    ["bandage"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["bandage_butterflywings"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["barnacle"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["barnacle_cooked"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["batbat"] = { uses_max = "BATBAT_USES" },   -- vanilla
    ["batbat_bats"] = { uses_max = "BATBAT_USES" },   -- vanilla
    ["batbat_fantasy_fx"] = { uses_max = "BATBAT_USES" },   -- vanilla
    ["bathbomb"] = { perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["batnose"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["batnose_cooked"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["batwing"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["batwing_cooked"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["beardhair"] = { fuel_max = "BERNIE_FUEL" },   -- vanilla
    ["bearger_fur"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["beargervest"] = { fuel_max = "BEARGERVEST_PERISHTIME" },   -- vanilla
    ["beaver"] = { food_hunger = "CALORIES_MED", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["bedroll_furry"] = { stack_max = "STACK_SIZE_LARGEITEM", uses_max = "BEDROLL_FURRY_USES" },   -- vanilla
    ["bedroll_straw"] = { stack_max = "STACK_SIZE_LARGEITEM", uses_max = "BEDROLL_FURRY_USES" },   -- vanilla
    ["bee"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["beefalo"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["beefalowool"] = { fuel_max = "BERNIE_FUEL" },   -- vanilla
    ["beeswax"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["beeswax_spray"] = { uses_max = "BEESWAX_SPRAY_USES" },   -- vanilla
    ["beeswax_spray_fx"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["bernie_active"] = { fuel_max = "BERNIE_FUEL" },   -- vanilla
    ["bernie_inactive"] = { fuel_max = "BERNIE_FUEL" },   -- vanilla
    ["bird_egg"] = { food_health = 0, food_hunger = "CALORIES_TINY", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["bird_egg_cooked"] = { food_health = 0, food_hunger = "CALORIES_TINY", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["birdtrap"] = { uses_max = "TRAP_USES" },   -- vanilla
    ["blackflag"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["blue_mushroom"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["blueamulet"] = { fuel_max = "BLUEAMULET_FUEL", uses_max = "REDAMULET_USES" },   -- vanilla
    ["boards"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boatfragment01"] = { food_health = 0, food_hunger = 0 },   -- vanilla
    ["boatfragment02"] = { food_health = 0, food_hunger = 0 },   -- vanilla
    ["boatfragment03"] = { food_health = 0, food_hunger = 0 },   -- vanilla
    ["boatfragment04"] = { food_health = 0, food_hunger = 0 },   -- vanilla
    ["boatfragment05"] = { food_health = 0, food_hunger = 0 },   -- vanilla
    ["boatpatch"] = { food_hunger = "CALORIES_TINY", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["boatpatch_kelp"] = { food_hunger = "CALORIES_TINY", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["boomerang"] = { uses_max = "BOOMERANG_USES" },   -- vanilla
    ["bootleg"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["bootleg_placer"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["boss_antlion"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_bearger"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_beequeen"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_celestialchampion1"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_celestialchampion2"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_celestialchampion3"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_celestialchampion4"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_celestialrevenant"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_celestialscion"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_crabking"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_crabkingpearl"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_daywalker"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_daywalker2"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_deerclops"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_dragonfly"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_eyeofterror1"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_eyeofterror2"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_fuelweaver"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_hermithouse"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_klaus"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_krampus"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_malbatross"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_minotaur"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_moose"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_mutatedbearger"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_mutateddeerclops"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_mutatedwarg"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_noeyeblue"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_noeyered"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_pearl"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_sharkboi"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_toadstool"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_toadstool_misery"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_wagstaff"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_warbot"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["boss_wormboss"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["bramblefx_trap"] = { uses_max = "TRAP_BRAMBLE_USES" },   -- vanilla
    ["brush"] = { uses_max = "BRUSH_USES" },   -- vanilla
    ["buff_firefrenzy"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["bugnet"] = { uses_max = "BUGNET_USES" },   -- vanilla
    ["bullkelp_plant"] = { perish_days = "PERISH_SUPERSLOW", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["bullkelp_root"] = { uses_max = "TRIDENT" },   -- vanilla
    ["bullkelp_root_placer"] = { perish_days = "PERISH_SUPERSLOW", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["bundle"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["bundle_container"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["bush"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["butter"] = { food_health = "HEALING_LARGE", food_hunger = "CALORIES_MED", perish_days = "PERISH_SUPERSLOW", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["butterflywings"] = { food_health = "HEALING_MEDSMALL", food_hunger = "CALORIES_TINY", perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["cactus"] = { food_health = "HEALING_MEDSMALL", food_hunger = "CALORIES_SMALL", food_sanity = "SANITY_TINY", perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["cactus_flower"] = { food_health = "HEALING_MEDSMALL", food_hunger = "CALORIES_SMALL", food_sanity = "SANITY_TINY", perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["campfire"] = { fuel_max = 0 },   -- vanilla
    ["campfire_placer"] = { fuel_max = 0 },   -- vanilla
    ["canary_poisoned"] = { perish_days = "BIRD_PERISH_TIME" },   -- vanilla
    ["cannonball_rock"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["cannonball_rock_item"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["cannonball_used"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["carnival_food"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["carnival_gametoken"] = { food_hunger = 2, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["carnival_prizeticket"] = { stack_max = "STACK_SIZE_TINYITEM" },   -- vanilla
    ["carnival_seedpacket"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["carnival_vest_a"] = { fuel_max = "CARNIVAL_VEST_PERISHTIME" },   -- vanilla
    ["carnival_vest_b"] = { fuel_max = "CARNIVAL_VEST_PERISHTIME" },   -- vanilla
    ["carnival_vest_c"] = { fuel_max = "CARNIVAL_VEST_PERISHTIME" },   -- vanilla
    ["carrot_spinner"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_TINY", perish_days = "PERISH_SUPERSLOW", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["catcoon"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["channel_absorb_fire_fx"] = { fuel_max = "LIGHTER_FUEL" },   -- vanilla
    ["charcoal"] = { fuel_max = 0 },   -- vanilla
    ["coldfire"] = { fuel_max = 0 },   -- vanilla
    ["coldfire_placer"] = { fuel_max = 0 },   -- vanilla
    ["coldfirepit"] = { fuel_max = 0 },   -- vanilla
    ["coldfirepit_placer"] = { fuel_max = 0 },   -- vanilla
    ["collapse_big"] = { uses_max = "TENT_USES" },   -- vanilla
    ["collapse_small"] = { fuel_max = 0 },   -- vanilla
    ["compass"] = { fuel_max = "COMPASS_FUEL" },   -- vanilla
    ["compostheal_buff"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["compostwrap"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["construction_container"] = { fuel_max = 0 },   -- vanilla
    ["construction_container_1x1"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["construction_rebuild_container"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["construction_repair_container"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["cookedmandrake"] = { food_health = "HEALING_HUGE", food_hunger = "CALORIES_HUGE", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["cookedmeat"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["cookedmonstermeat"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["cookedsmallmeat"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["cookiecutter"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["cookiecuttershell"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["coolant"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["corpse_gestalt"] = { food_health = 0, food_hunger = "CALORIES_SUPERHUGE" },   -- vanilla
    ["cotl_tabernacle_level1"] = { fuel_max = 0 },   -- vanilla
    ["cotl_tabernacle_level1_placer"] = { fuel_max = 0 },   -- vanilla
    ["cotl_tabernacle_level2"] = { fuel_max = 0 },   -- vanilla
    ["cotl_tabernacle_level3"] = { fuel_max = 0 },   -- vanilla
    ["cotl_trinket"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["crab_king_waterspout"] = { uses_max = "TRIDENT" },   -- vanilla
    ["critter_bulbin"] = { perish_days = "CRITTER_HUNGERTIME" },   -- vanilla
    ["critter_dragonling"] = { perish_days = "CRITTER_HUNGERTIME" },   -- vanilla
    ["critter_eyeofterror"] = { perish_days = "CRITTER_HUNGERTIME" },   -- vanilla
    ["critter_glomling"] = { perish_days = "CRITTER_HUNGERTIME" },   -- vanilla
    ["critter_kitten"] = { perish_days = "CRITTER_HUNGERTIME" },   -- vanilla
    ["critter_lamb"] = { perish_days = "CRITTER_HUNGERTIME" },   -- vanilla
    ["critter_lunarmothling"] = { perish_days = "CRITTER_HUNGERTIME" },   -- vanilla
    ["critter_perdling"] = { perish_days = "CRITTER_HUNGERTIME" },   -- vanilla
    ["critter_puppy"] = { perish_days = "CRITTER_HUNGERTIME" },   -- vanilla
    ["critterbuff_lunarmoth"] = { perish_days = "CRITTER_HUNGERTIME" },   -- vanilla
    ["crumbs"] = { food_health = 0, food_hunger = 1, perish_days = "PERISH_ONE_DAY", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["cursed_monkey_token"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["cursed_monkey_token_prop"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["cutgrass"] = { uses_max = "FIRESTAFF_USES" },   -- vanilla
    ["cutless"] = { uses_max = "CUTLESS_USES" },   -- vanilla
    ["cutlichen"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", perish_days = "PERISH_TWO_DAY", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["cutreeds"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_TINY", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["cutstone"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["decor_lamp"] = { fuel_max = "LANTERN_LIGHTTIME" },   -- vanilla
    ["deerclops_eyeball"] = { food_health = "HEALING_HUGE", food_hunger = "CALORIES_HUGE", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["desert"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["dirt_puff"] = { uses_max = "FARM_PLOW_USES" },   -- vanilla
    ["dock_kit"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["dock_tile_registrator"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["dock_woodposts"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["dock_woodposts_item"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["dock_woodposts_item_placer"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["dragon_scales"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["dragonbody"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["dragonhead"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["dragontail"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["dreadstone"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["driedplants"] = { food_hunger = 0, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["driftwood_log"] = { food_health = 0, food_hunger = 0 },   -- vanilla
    ["drumstick"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["drumstick_cooked"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["dug_"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["dug_trap_starfish"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["dug_trap_starfish_placer"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["dumbbell"] = { uses_max = "DUMBBELL_HEAT_MAX_USES" },   -- vanilla
    ["dumbbell_bluegem"] = { uses_max = "DUMBBELL_HEAT_MAX_USES" },   -- vanilla
    ["dumbbell_gem"] = { uses_max = "DUMBBELL_HEAT_MAX_USES" },   -- vanilla
    ["dumbbell_golden"] = { uses_max = "DUMBBELL_HEAT_MAX_USES" },   -- vanilla
    ["dumbbell_heat"] = { uses_max = "DUMBBELL_HEAT_MAX_USES" },   -- vanilla
    ["dumbbell_marble"] = { uses_max = "DUMBBELL_HEAT_MAX_USES" },   -- vanilla
    ["dumbbell_redgem"] = { uses_max = "DUMBBELL_HEAT_MAX_USES" },   -- vanilla
    ["dustmeringue"] = { food_hunger = "CALORIES_SMALL", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["earmuffs"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["eel"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_TINY", perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["emberlight"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["explode_firecrackers"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["explode_small"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["eyebrella"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["eyemask"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["fan_wheel"] = { fuel_max = "MINIFAN_FUEL" },   -- vanilla
    ["fancy"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["farm_hoe"] = { uses_max = "FARM_HOE_USES" },   -- vanilla
    ["farm_plant_randomseed"] = { food_health = 0, food_hunger = "CALORIES_TINY", perish_days = "PERISH_SUPERSLOW", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["farm_plow"] = { uses_max = "FARM_PLOW_USES" },   -- vanilla
    ["farm_plow_item"] = { uses_max = "FARM_PLOW_USES" },   -- vanilla
    ["farm_plow_item_placer"] = { uses_max = "FARM_PLOW_USES" },   -- vanilla
    ["farm_soil"] = { uses_max = "FARM_PLOW_USES" },   -- vanilla
    ["farm_soil_debris"] = { uses_max = "FARM_PLOW_USES" },   -- vanilla
    ["feather"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["featherfan"] = { uses_max = "FEATHERFAN_USES" },   -- vanilla
    ["featherpencil"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["feathers"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["fence"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["fence_electric"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["fence_electric_item"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["fence_electric_item_placer"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["fence_gate"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["fence_gate_anim"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["fence_gate_item"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["fence_gate_item_placer"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["fence_item"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["fence_item_placer"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["fence_junk"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["fence_rotator"] = { uses_max = "FENCE_ROTATOR_USES" },   -- vanilla
    ["fertilizer"] = { uses_max = "FERTILIZER_USES" },   -- vanilla
    ["festivalevents1"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["festivalevents2"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["festivalevents3"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["festivalevents4"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["festivalevents5"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["firecrackers"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["fireflies"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["firenettle_toxin"] = { food_hunger = 0, perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["firenettles"] = { food_hunger = 0, perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["firepen"] = { uses_max = "FIREPEN_MAXUSES" },   -- vanilla
    ["firepit"] = { fuel_max = 0 },   -- vanilla
    ["firepit_placer"] = { fuel_max = 0 },   -- vanilla
    ["firering_fx"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["firesplash_fx"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["firestaff"] = { uses_max = "FIRESTAFF_USES" },   -- vanilla
    ["firesuppressor"] = { fuel_max = "FIRESUPPRESSOR_MAX_FUEL_TIME" },   -- vanilla
    ["firesuppressor_glow"] = { fuel_max = "FIRESUPPRESSOR_MAX_FUEL_TIME" },   -- vanilla
    ["firesuppressor_placer"] = { fuel_max = "FIRESUPPRESSOR_MAX_FUEL_TIME" },   -- vanilla
    ["fish"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_SMALL", perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["fishingnet"] = { uses_max = "FISHING_NET_USES" },   -- vanilla
    ["fishingrod"] = { uses_max = "FISHINGROD_USES" },   -- vanilla
    ["fishmeat"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["fishmeat_cooked"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["fishmeat_dried"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["fishmeat_small"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["fishmeat_small_cooked"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["fishmeat_small_dried"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["flamethrower_fx"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["flint"] = { food_hunger = 1, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["floatinglantern"] = { fuel_max = "FLOATINGLANTERN_DURATION" },   -- vanilla
    ["floatinglantern_shadow"] = { fuel_max = "FLOATINGLANTERN_DURATION" },   -- vanilla
    ["flower"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["foliage"] = { food_health = "HEALING_TINY", food_hunger = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["football"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["forcefieldfx"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["forgetmelots"] = { food_health = 0, food_hunger = 0, food_sanity = "SANITY_SUPERTINY", perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["fossil_piece"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["fossil_piece_clean"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["fossil_piece_placer"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["fossil_stalker"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["friendlyfruitfly"] = { perish_days = "PERISH_FAST" },   -- vanilla
    ["froglegs"] = { food_health = 0, food_hunger = "CALORIES_SMALL", perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["froglegs_cooked"] = { food_health = 0, food_hunger = "CALORIES_SMALL", perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["fruitfly"] = { perish_days = "PERISH_FAST" },   -- vanilla
    ["fruitflyfruit"] = { perish_days = "PERISH_FAST" },   -- vanilla
    ["furtuft"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["gears"] = { food_health = "HEALING_HUGE", food_hunger = "CALORIES_HUGE", food_sanity = "SANITY_HUGE", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["gelblob_bottle"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["gelblob_small_fx"] = { food_hunger = 1, stack_max = "STACK_SIZE_PELLET" },   -- vanilla
    ["gem"] = { food_hunger = 5, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["gestalt_evolved_planting_visual_projectile"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["gestalt_guard_evolved"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["ghostflower"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["ghostflower_spirit"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["gift"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["glasscutter"] = { uses_max = "GLASSCUTTER" },   -- vanilla
    ["globalmapicon"] = { fuel_max = "FLOATINGLANTERN_DURATION" },   -- vanilla
    ["glommerflower"] = { perish_days = "PERISH_FAST" },   -- vanilla
    ["glommerfuel"] = { food_health = "HEALING_LARGE", food_hunger = "CALORIES_TINY" },   -- vanilla
    ["gnarwail_horn"] = { uses_max = "GNARWAIL_HORN" },   -- vanilla
    ["goatmilk"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = "SANITY_SMALL", perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["goggles"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["golden_farm_hoe"] = { uses_max = "FARM_HOE_USES" },   -- vanilla
    ["goldenaxe"] = { uses_max = "AXE_USES" },   -- vanilla
    ["goldenpickaxe"] = { uses_max = "PICKAXE_USES" },   -- vanilla
    ["goldenpitchfork"] = { uses_max = "PITCHFORK_USES" },   -- vanilla
    ["goldenshovel"] = { uses_max = "SHOVEL_USES" },   -- vanilla
    ["goldnugget"] = { food_hunger = 2 },   -- vanilla
    ["goose"] = { food_hunger = "CALORIES_MED", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["goose_feather"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["grass_umbrella"] = { fuel_max = "UMBRELLA_PERISHTIME", perish_days = "GRASS_UMBRELLA_PERISHTIME" },   -- vanilla
    ["green_mushroom"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["greenamulet"] = { fuel_max = "BLUEAMULET_FUEL", uses_max = "REDAMULET_USES" },   -- vanilla
    ["greenstaff"] = { uses_max = "FIRESTAFF_USES" },   -- vanilla
    ["gunpowder"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["halloween_ornament_"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["halloweencandy_"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["hambat"] = { food_hunger = "CALORIES_MED", perish_days = "PERISH_MED" },   -- vanilla
    ["hammer"] = { uses_max = "HAMMER_USES" },   -- vanilla
    ["hareball"] = { food_health = 0, food_hunger = 0, perish_days = "PERISH_FAST" },   -- vanilla
    ["hawaiianshirt"] = { perish_days = "HAWAIIANSHIRT_PERISHTIME" },   -- vanilla
    ["healingsalve"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["healingsalve_acid"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["healingsalve_acidbuff"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["heatrock"] = { fuel_max = 100 },   -- vanilla
    ["heatrocklight"] = { fuel_max = 100 },   -- vanilla
    ["hermit_bundle"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["hermit_bundle_shells"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["hermitcrab_fx_med"] = { uses_max = "HERMITCRAB_SHELL_USES" },   -- vanilla
    ["hermitcrab_shell"] = { uses_max = "HERMITCRAB_SHELL_USES" },   -- vanilla
    ["hermithouse_ornament"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["hermithouse_ornament_fx"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["hitsparks_fx"] = { uses_max = "VOIDCLOTH_SCYTHE_USES" },   -- vanilla
    ["hive"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["honey"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_TINY", perish_days = "PERISH_SUPERSLOW", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["honey_trail"] = { food_hunger = 1, stack_max = "STACK_SIZE_PELLET" },   -- vanilla
    ["honeycomb"] = { food_health = "HONEYCOMB_HEALTH", food_hunger = "HONEYCOMB_HUNGER" },   -- vanilla
    ["horn"] = { uses_max = "HORN_USES" },   -- vanilla
    ["horrorfuel"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["horseshoe"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["houndfire"] = { uses_max = "DUMBBELL_HEAT_MAX_USES" },   -- vanilla
    ["houndstooth"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["houndwhistle"] = { uses_max = "HOUNDWHISTLE_USES" },   -- vanilla
    ["humanmeat"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["humanmeat_cooked"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["humanmeat_dried"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["ice"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_TINY", perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["icestaff"] = { uses_max = "FIRESTAFF_USES" },   -- vanilla
    ["icestaff2"] = { uses_max = "FIRESTAFF_USES" },   -- vanilla
    ["icestaff3"] = { uses_max = "FIRESTAFF_USES" },   -- vanilla
    ["impact"] = { uses_max = "WHIP_USES" },   -- vanilla
    ["inspectacles"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["inspectacleshat_fx"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["ipecacsyrup"] = { food_hunger = "CALORIES_TINY", food_sanity = 0, stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["ipecacsyrup_buff"] = { food_hunger = "CALORIES_TINY", food_sanity = 0, stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["junk_break_fx"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["kelp"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["knight_yoth"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["lantern"] = { fuel_max = "LANTERN_LIGHTTIME" },   -- vanilla
    ["lanternlight"] = { fuel_max = "LANTERN_LIGHTTIME" },   -- vanilla
    ["lavalight"] = { fuel_max = 0 },   -- vanilla
    ["leif_idol"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["lifeinjector"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["light"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["lightbulb"] = { food_health = "HEALING_TINY", food_hunger = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["lighter"] = { fuel_max = "LIGHTER_FUEL" },   -- vanilla
    ["lightninggoathorn"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["livinglog"] = { food_health = 0, food_hunger = 0 },   -- vanilla
    ["livingtree_root"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["livingtree_root_placer"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["livingtree_sapling"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["log"] = { food_health = 0, food_hunger = 0 },   -- vanilla
    ["lordfruitfly"] = { perish_days = "PERISH_FAST" },   -- vanilla
    ["lucky_goldnugget"] = { food_hunger = 2 },   -- vanilla
    ["lunarplant"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["lunarplant_husk"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["lunarplant_kit"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["lunarplanthat_fx"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["lunarplanttentacle"] = { food_hunger = 1, stack_max = "STACK_SIZE_PELLET" },   -- vanilla
    ["lureplant"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["lureplantbulb"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["lureplantbulb_placer"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["malbatross_beak"] = { food_health = 0, food_hunger = 0 },   -- vanilla
    ["malbatross_feather"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["malbatross_feather_fall"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["malbatross_feathered_weave"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["mandrake"] = { food_health = "HEALING_HUGE", food_hunger = "CALORIES_HUGE", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["manrabbit_tail"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["marble"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["marblebean"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["marblebean_placer"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["marblebean_sapling"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["mask_ancient_architect"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mask_ancient_handmaid"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mask_ancient_mason"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mask_blacksmith"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mask_doll"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mask_dollbroken"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mask_dollrepaired"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mask_fool"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mask_halfwit"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mask_halfwit_fx"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mask_king"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mask_mirror"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mask_princess"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mask_queen"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mask_sage"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mask_toady"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mask_tree"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mast"] = { fuel_max = "MAST_LAMP_LIGHTTIME" },   -- vanilla
    ["mast_item"] = { fuel_max = "MAST_LAMP_LIGHTTIME" },   -- vanilla
    ["mast_item_placer"] = { fuel_max = "MAST_LAMP_LIGHTTIME" },   -- vanilla
    ["mast_malbatross"] = { fuel_max = "MAST_LAMP_LIGHTTIME" },   -- vanilla
    ["mast_malbatross_item"] = { fuel_max = "MAST_LAMP_LIGHTTIME" },   -- vanilla
    ["mast_malbatross_item_placer"] = { fuel_max = "MAST_LAMP_LIGHTTIME" },   -- vanilla
    ["mast_yotd"] = { fuel_max = "MAST_LAMP_LIGHTTIME" },   -- vanilla
    ["mast_yotd_item"] = { fuel_max = "MAST_LAMP_LIGHTTIME" },   -- vanilla
    ["mast_yotd_item_placer"] = { fuel_max = "MAST_LAMP_LIGHTTIME" },   -- vanilla
    ["meat"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["meat_dried"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["merm"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mermarmor"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["mermarmorupgraded"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["messagebottle"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["messagebottle_break_fx"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["messagebottle_throwable"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["messagebottleempty"] = { perish_days = "PERISH_SUPERFAST", uses_max = "SOILAMENDER_FERMENTED_USES" },   -- vanilla
    ["miasma_cloud"] = { food_health = 0, food_hunger = "CALORIES_LARGE" },   -- vanilla
    ["miasma_cloud_fx"] = { food_health = 0, food_hunger = "CALORIES_LARGE" },   -- vanilla
    ["miasma_ember_fx"] = { food_health = 0, food_hunger = "CALORIES_LARGE" },   -- vanilla
    ["milkywhites"] = { food_health = "HEALING_MEDSMALL", food_hunger = "CALORIES_SMALL", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["miner"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["minerhatlight"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["miniboatlantern"] = { fuel_max = "MINIBOATLANTERN_LIGHTTIME" },   -- vanilla
    ["miniboatlantern_loseballoon"] = { fuel_max = "MINIBOATLANTERN_LIGHTTIME" },   -- vanilla
    ["miniboatlanternlight"] = { fuel_max = "MINIBOATLANTERN_LIGHTTIME" },   -- vanilla
    ["minifan"] = { fuel_max = "MINIFAN_FUEL" },   -- vanilla
    ["minisign"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["minisign_drawn"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["minisign_drawn_placer"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["minisign_item"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["minisign_item_placer"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["minotaurhorn"] = { food_health = "HEALING_HUGE", food_hunger = "CALORIES_HUGE", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["mole"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["monkey_medium"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["monkey_small"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["monstermeat"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["monstermeat_dried"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["moon_cap"] = { food_health = 0, food_hunger = "CALORIES_SMALL", food_sanity = "SANITY_SMALL", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["moon_cap_cooked"] = { food_health = 0, food_hunger = "CALORIES_SMALL", food_sanity = "SANITY_SMALL", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["moon_mushroom"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["moon_tree_blossom"] = { food_health = "HEALING_TINY", food_hunger = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["moon_tree_blossom_worldgen"] = { food_health = "HEALING_TINY", food_hunger = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["moonbutterfly"] = { perish_days = "MOONBUTTERFLY_PERISH_TIME" },   -- vanilla
    ["moonbutterfly_placer"] = { perish_days = "MOONBUTTERFLY_PERISH_TIME" },   -- vanilla
    ["moonbutterfly_sapling"] = { perish_days = "MOONBUTTERFLY_PERISH_TIME" },   -- vanilla
    ["moonbutterflywings"] = { food_health = "HEALING_MEDSMALL", food_hunger = "CALORIES_TINY", food_sanity = "SANITY_MED", perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["moonglass"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_SMALL", perish_days = "MOONGLASS_CHARGED_PERISH_TIME", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["moonglassaxe"] = { uses_max = "AXE_USES" },   -- vanilla
    ["moonrocknugget"] = { food_hunger = 1, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["moonstorm_goggles"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["moonstorm_spark"] = { perish_days = "SPARK_PERISH_TIME" },   -- vanilla
    ["moonstorm_static"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["moonstorm_static_catcher"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["moonstorm_static_item"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["moonstorm_static_nowag"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["moonstorm_static_roamer"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["moose"] = { food_hunger = "CALORIES_MED", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["mosquitomermsalve"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["mosquitomusk"] = { perish_days = "PERISH_FASTISH" },   -- vanilla
    ["multitool_axe_pickaxe"] = { uses_max = "MULTITOOL_AXE_PICKAXE_USES" },   -- vanilla
    ["mushtree_spores"] = { perish_days = "SEG_TIME" },   -- vanilla
    ["mutator_"] = { food_hunger = "CALORIES_SMALL" },   -- vanilla
    ["nightcap"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["nightlight"] = { fuel_max = 0 },   -- vanilla
    ["nightlight_placer"] = { fuel_max = 0 },   -- vanilla
    ["nightmarefuel"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["nightstick"] = { fuel_max = "NIGHTSTICK_FUEL" },   -- vanilla
    ["nightstickfire"] = { fuel_max = "NIGHTSTICK_FUEL" },   -- vanilla
    ["nightsword"] = { uses_max = "NIGHTSWORD_USES" },   -- vanilla
    ["nightvision_buff"] = { food_hunger = 3, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["nitre"] = { food_hunger = 2, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["nutrientsgoggles"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["oar"] = { food_health = 0, food_hunger = 0 },   -- vanilla
    ["oar_driftwood"] = { food_health = 0, food_hunger = 0 },   -- vanilla
    ["oar_monkey"] = { food_health = 0, food_hunger = 0 },   -- vanilla
    ["oasis_cactus"] = { food_health = "HEALING_MEDSMALL", food_hunger = "CALORIES_SMALL", food_sanity = "SANITY_TINY", perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["ocean_splash_ripple"] = { food_hunger = 1, stack_max = "STACK_SIZE_PELLET" },   -- vanilla
    ["oceanfishinghook_ripple"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["oceanfishinglure"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["oceanwhirlportal"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["onemanband"] = { fuel_max = "ONEMANBAND_PERISHTIME" },   -- vanilla
    ["opalstaff"] = { uses_max = "FIRESTAFF_USES" },   -- vanilla
    ["orangeamulet"] = { fuel_max = "BLUEAMULET_FUEL", uses_max = "REDAMULET_USES" },   -- vanilla
    ["orangestaff"] = { uses_max = "FIRESTAFF_USES" },   -- vanilla
    ["panflute"] = { uses_max = "PANFLUTE_USES" },   -- vanilla
    ["papyrus"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["perdfan"] = { uses_max = "FEATHERFAN_USES" },   -- vanilla
    ["petals"] = { food_health = "HEALING_TINY", food_hunger = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["petals_evil"] = { food_health = 0, food_hunger = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["phlegm"] = { food_health = 0, food_hunger = "CALORIES_SMALL", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["pickaxe"] = { uses_max = "PICKAXE_USES" },   -- vanilla
    ["pickaxe_lunarplant"] = { uses_max = "PICKAXE_LUNARPLANT_USES" },   -- vanilla
    ["pig_coin"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["pig_token"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["pigelitefighter"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["pigskin"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["pigtorch"] = { fuel_max = 0 },   -- vanilla
    ["pigtorch_fuel"] = { fuel_max = 0 },   -- vanilla
    ["pinecone"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["pitchfork"] = { uses_max = "PITCHFORK_USES" },   -- vanilla
    ["plain"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["plant_normal_ground"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_TINY", perish_days = "PERISH_SUPERSLOW", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["plantmeat"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["plantmeat_cooked"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["plantregistry"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["pocket_scale"] = { uses_max = "POCKETSCALE_USES" },   -- vanilla
    ["pocketwatch_parts"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["pocketwatch_weapon"] = { fuel_max = 4 },   -- vanilla
    ["pocketwatch_weapon_fx"] = { fuel_max = 4 },   -- vanilla
    ["polly_rogers"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["pondeel"] = { food_sanity = 0 },   -- vanilla
    ["pondfish"] = { food_sanity = 0 },   -- vanilla
    ["poop"] = { food_hunger = "CALORIES_TINY", food_sanity = 0, stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["poopcloud"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["portablefirepit"] = { fuel_max = 0 },   -- vanilla
    ["portablefirepit_item"] = { fuel_max = 0 },   -- vanilla
    ["portablefirepit_item_placer"] = { fuel_max = 0 },   -- vanilla
    ["portabletent"] = { uses_max = "PORTABLE_TENT_USES" },   -- vanilla
    ["portabletent_item"] = { uses_max = "PORTABLE_TENT_USES" },   -- vanilla
    ["portabletent_item_placer"] = { uses_max = "PORTABLE_TENT_USES" },   -- vanilla
    ["preparedfoods"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["pull_smoke_fx"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["pumpkin"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["pumpkinhat_fx"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["purebrilliance"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["purebrilliance_symbol_fx"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["purpleamulet"] = { fuel_max = "BLUEAMULET_FUEL", uses_max = "REDAMULET_USES" },   -- vanilla
    ["quagmire_campfire"] = { fuel_max = 0 },   -- vanilla
    ["quagmire_cookedsmallmeat"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["quagmire_foliage_cooked"] = { food_health = "HEALING_TINY", food_hunger = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["quagmire_park_gate"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["quagmire_park_gate_anim"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["quagmire_smallmeat"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["rabbit"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["rabbithat_fx"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["rabbitkinghorn"] = { uses_max = "RABBITKINGHORN_USES" },   -- vanilla
    ["rabbitkinghorn_chest"] = { uses_max = "RABBITKINGHORN_USES" },   -- vanilla
    ["rabbitkingspear"] = { uses_max = "RABBITKINGSPEAR_USES" },   -- vanilla
    ["rain"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["raincoat"] = { fuel_max = "RAINCOAT_PERISHTIME" },   -- vanilla
    ["red_mushroom"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["redlantern"] = { fuel_max = "REDLANTERN_LIGHTTIME" },   -- vanilla
    ["redlanternbody"] = { fuel_max = "REDLANTERN_LIGHTTIME" },   -- vanilla
    ["redlanternlight"] = { fuel_max = "REDLANTERN_LIGHTTIME" },   -- vanilla
    ["redpouch"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["redpouch_yot_catcoon"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["redpouch_yotb"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["redpouch_yotc"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["redpouch_yotd"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["redpouch_yoth"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["redpouch_yoth_small"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["redpouch_yotp"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["redpouch_yotr"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["refined_dust"] = { food_hunger = 1, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["reflectivevest"] = { fuel_max = "REFLECTIVEVEST_PERISHTIME" },   -- vanilla
    ["reticuleaoewinonaengineeringping"] = { fuel_max = "WINONA_REMOTE_FUEL" },   -- vanilla
    ["rock_avocado_bush"] = { food_health = "HEALING_TINY", food_hunger = 2, food_sanity = 0, perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["rock_avocado_fruit"] = { food_health = "HEALING_TINY", food_hunger = 2, food_sanity = 0, perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["rock_avocado_fruit_ripe"] = { food_health = "HEALING_TINY", food_hunger = 2, food_sanity = 0, perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["rock_avocado_fruit_ripe_cooked"] = { food_health = "HEALING_TINY", food_hunger = 2, food_sanity = 0, perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["rock_avocado_fruit_sprout"] = { food_health = "HEALING_TINY", food_hunger = 2, food_sanity = 0, perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["rock_avocado_fruit_sprout_placer"] = { food_health = "HEALING_TINY", food_hunger = 2, food_sanity = 0, perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["rock_avocado_fruit_sprout_sapling"] = { food_health = "HEALING_TINY", food_hunger = 2, food_sanity = 0, perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["rock_light"] = { fuel_max = 0 },   -- vanilla
    ["rocks"] = { food_hunger = 1, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["rope_bridge_fx"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["rope_bridge_kit"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["rope_bridge_kit_placer"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["roseglasses"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["rottenegg"] = { food_health = 0, food_hunger = "CALORIES_TINY", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["round_puff_fx_sm"] = { uses_max = "DUMBBELL_HEAT_MAX_USES" },   -- vanilla
    ["royal_jelly"] = { food_health = "HEALING_LARGE", food_hunger = "CALORIES_SMALL", food_sanity = "SANITY_MED", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["ruins"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["ruins_bat"] = { uses_max = "RUINS_BAT_USES" },   -- vanilla
    ["saddlehorn"] = { uses_max = "SADDLEHORN_USES" },   -- vanilla
    ["saltlick"] = { uses_max = "SALTLICK_MAX_LICKS" },   -- vanilla
    ["saltlick_improved"] = { uses_max = "SALTLICK_MAX_LICKS" },   -- vanilla
    ["saltlick_improved_placer"] = { uses_max = "SALTLICK_MAX_LICKS" },   -- vanilla
    ["saltlick_placer"] = { uses_max = "SALTLICK_MAX_LICKS" },   -- vanilla
    ["saltrock"] = { food_hunger = 1, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["salty_dog"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["sand_puff"] = { fuel_max = "BLUEAMULET_FUEL", uses_max = "REDAMULET_USES" },   -- vanilla
    ["scandata"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["scrap"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["scrap_monocle"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["scrapbook_page"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["scrapbook_page_special"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["seeds"] = { food_health = 0, food_hunger = "CALORIES_TINY", perish_days = "PERISH_SUPERSLOW", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["seeds_cooked"] = { food_health = 0, food_hunger = "CALORIES_TINY", perish_days = "PERISH_SUPERSLOW", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["seeds_placer"] = { food_health = 0, food_hunger = "CALORIES_TINY", perish_days = "PERISH_SUPERSLOW", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["sewing_kit"] = { uses_max = "SEWINGKIT_USES" },   -- vanilla
    ["sewing_tape"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["shadow_battleaxe"] = { uses_max = "SHADOW_BATTLEAXE" },   -- vanilla
    ["shadow_battleaxe_classified"] = { uses_max = "SHADOW_BATTLEAXE" },   -- vanilla
    ["shadow_battleaxe_fx"] = { uses_max = "SHADOW_BATTLEAXE" },   -- vanilla
    ["shadow_pillar_spell"] = { fuel_max = "LARGE_FUEL" },   -- vanilla
    ["shadow_shield"] = { fuel_max = 4 },   -- vanilla
    ["shadow_thrall_parasite"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["shadow_thrall_parasitehat_fx"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["shadow_trap"] = { fuel_max = "LARGE_FUEL" },   -- vanilla
    ["shadowtentacle"] = { food_hunger = 1, stack_max = "STACK_SIZE_PELLET" },   -- vanilla
    ["shadowthralls"] = { fuel_max = 160, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["shatter"] = { food_hunger = 1, stack_max = "STACK_SIZE_PELLET" },   -- vanilla
    ["shovel"] = { uses_max = "SHOVEL_USES" },   -- vanilla
    ["shovel_lunarplant"] = { uses_max = "SHOVEL_LUNARPLANT_USES" },   -- vanilla
    ["shroom_skin"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["siestahut"] = { uses_max = "TENT_USES" },   -- vanilla
    ["siestahut_placer"] = { uses_max = "TENT_USES" },   -- vanilla
    ["silk"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["skeleton"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["sleepcloud_lunar"] = { food_health = 0, food_hunger = "CALORIES_SMALL", food_sanity = "SANITY_SMALL", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["slingshot_aoe_fx"] = { food_hunger = 1, stack_max = "STACK_SIZE_PELLET" },   -- vanilla
    ["slingshotammo_dreadstone"] = { food_hunger = 1, stack_max = "STACK_SIZE_PELLET" },   -- vanilla
    ["slingshotammo_gunpowder_explode"] = { food_hunger = 1, stack_max = "STACK_SIZE_PELLET" },   -- vanilla
    ["slingshotammo_horrorfuel_debuff_fx"] = { food_hunger = 1, stack_max = "STACK_SIZE_PELLET" },   -- vanilla
    ["slingshotammo_slow_debuff_fx"] = { food_hunger = 1, stack_max = "STACK_SIZE_PELLET" },   -- vanilla
    ["slurper_pelt"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["slurtle"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["slurtle_shellpieces"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["slurtleslime"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["small_puff"] = { food_health = "HEALING_TINY", food_hunger = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["smallbird"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_MED", perish_days = "PERISH_FAST" },   -- vanilla
    ["smallmeat"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["smallmeat_dried"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_SMALL", food_sanity = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["snowball"] = { fuel_max = "FIRESUPPRESSOR_MAX_FUEL_TIME" },   -- vanilla
    ["snowball_item"] = { perish_days = "PERISH_TWO_DAY", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["snowball_shatter_fx"] = { perish_days = "PERISH_TWO_DAY", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["snowman"] = { perish_days = "PERISH_TWO_DAY", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["soil_amender"] = { perish_days = "PERISH_SUPERFAST", uses_max = "SOILAMENDER_FERMENTED_USES" },   -- vanilla
    ["soil_amender_fermented"] = { perish_days = "PERISH_SUPERFAST", uses_max = "SOILAMENDER_FERMENTED_USES" },   -- vanilla
    ["sparks"] = { fuel_max = "STORAGE_ROBOT_FUEL" },   -- vanilla
    ["spear"] = { uses_max = "SPEAR_USES" },   -- vanilla
    ["spice_chili"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["spice_garlic"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["spice_salt"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["spice_sugar"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["spider"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["spiderden"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["spidereggsack"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["spidereggsack_placer"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["splash"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_SMALL", perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["splash_green_small"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["splash_ocean"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["splash_sink"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["splash_snow_fx"] = { perish_days = "PERISH_TWO_DAY", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["spoiled_fish"] = { food_health = "SPOILED_HEALTH", food_hunger = "SPOILED_HUNGER", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["spoiled_fish_small"] = { food_health = "SPOILED_HEALTH", food_hunger = "SPOILED_HUNGER", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["spoiled_food"] = { food_health = "SPOILED_HEALTH", food_hunger = "SPOILED_HUNGER", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["spore_moon"] = { perish_days = "MOONSPORE_PERISH_TIME" },   -- vanilla
    ["staff_lunarplant"] = { uses_max = "STAFF_LUNARPLANT_USES" },   -- vanilla
    ["staff_lunarplant_fx"] = { uses_max = "STAFF_LUNARPLANT_USES" },   -- vanilla
    ["staff_tornado"] = { uses_max = "TORNADOSTAFF_USES" },   -- vanilla
    ["stash_map"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["steelwool"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["stinger"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["storage_robot"] = { fuel_max = "STORAGE_ROBOT_FUEL" },   -- vanilla
    ["straw"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["succulent_picked"] = { food_health = "HEALING_TINY", food_hunger = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["succulent_plant"] = { food_health = "HEALING_TINY", food_hunger = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["sweatervest"] = { fuel_max = "SWEATERVEST_PERISHTIME" },   -- vanilla
    ["sweettea_buff"] = { food_health = 0, food_hunger = 0, food_sanity = "SANITY_SUPERTINY", perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["sword_lunarplant"] = { uses_max = "SWORD_LUNARPLANT_USES" },   -- vanilla
    ["sword_lunarplant_blade_fx"] = { uses_max = "SWORD_LUNARPLANT_USES" },   -- vanilla
    ["tallbirdegg"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_MED", perish_days = "PERISH_FAST" },   -- vanilla
    ["tallbirdegg_cooked"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_MED", perish_days = "PERISH_FAST" },   -- vanilla
    ["tallbirdegg_cracked"] = { food_health = "HEALING_SMALL", food_hunger = "CALORIES_MED", perish_days = "PERISH_FAST" },   -- vanilla
    ["telestaff"] = { uses_max = "FIRESTAFF_USES" },   -- vanilla
    ["tent"] = { uses_max = "TENT_USES" },   -- vanilla
    ["tent_placer"] = { uses_max = "TENT_USES" },   -- vanilla
    ["tentaclespike"] = { uses_max = "SPIKE_USES" },   -- vanilla
    ["tentaclespots"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["thulecite"] = { food_hunger = 3 },   -- vanilla
    ["thulecite_pieces"] = { food_hunger = 1, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["thulecitebugnet"] = { uses_max = "BUGNET_USES" },   -- vanilla
    ["thurible"] = { fuel_max = "THURIBLE_FUEL_MAX" },   -- vanilla
    ["thurible_smoke"] = { fuel_max = "THURIBLE_FUEL_MAX" },   -- vanilla
    ["thuriblebody"] = { fuel_max = "THURIBLE_FUEL_MAX" },   -- vanilla
    ["tile_outline"] = { food_health = 0, food_hunger = "CALORIES_TINY", perish_days = "PERISH_SUPERSLOW", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["tillweed"] = { food_health = "HEALING_TINY", food_hunger = 0, perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["tillweedsalve"] = { perish_days = "PERISH_MED", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["tillweedsalve_buff"] = { perish_days = "PERISH_MED", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["top"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["tophat_container"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["tophat_shadow_fx"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["torch"] = { fuel_max = "TORCH_FUEL" },   -- vanilla
    ["torchfire"] = { fuel_max = 0 },   -- vanilla
    ["tornado"] = { uses_max = "TORNADOSTAFF_USES" },   -- vanilla
    ["townportaltalisman"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["transistor"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["trap"] = { uses_max = "TRAP_USES" },   -- vanilla
    ["trap_bramble"] = { uses_max = "TRAP_BRAMBLE_USES" },   -- vanilla
    ["trap_bramble_placer"] = { uses_max = "TRAP_BRAMBLE_USES" },   -- vanilla
    ["trap_starfish"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["trap_teeth"] = { uses_max = "TRAP_TEETH_USES" },   -- vanilla
    ["trap_teeth_maxwell"] = { uses_max = "TRAP_TEETH_USES" },   -- vanilla
    ["trap_teeth_placer"] = { uses_max = "TRAP_TEETH_USES" },   -- vanilla
    ["tree_rock_sapling"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_TINY", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["tree_rock_seed"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_TINY", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["tree_rock_seed_placer"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_TINY", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["treegrowthsolution"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["trident"] = { uses_max = "TRIDENT" },   -- vanilla
    ["trinket_"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["trunk_cooked"] = { food_health = "HEALING_MEDLARGE", food_hunger = "CALORIES_LARGE", perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["trunk_summer"] = { food_health = "HEALING_MEDLARGE", food_hunger = "CALORIES_LARGE", perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["trunk_winter"] = { food_health = "HEALING_MEDLARGE", food_hunger = "CALORIES_LARGE", perish_days = "PERISH_FAST", stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["trunkvest_summer"] = { fuel_max = "TRUNKVEST_PERISHTIME" },   -- vanilla
    ["trunkvest_winter"] = { fuel_max = "TRUNKVEST_PERISHTIME" },   -- vanilla
    ["turf_"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["turf_smoke_fx"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["twigs"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_TINY", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["umbrella"] = { fuel_max = "UMBRELLA_PERISHTIME", perish_days = "GRASS_UMBRELLA_PERISHTIME" },   -- vanilla
    ["voidcloth"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["voidcloth_boomerang"] = { uses_max = "VOIDCLOTH_BOOMERANG_USES" },   -- vanilla
    ["voidcloth_boomerang_fx"] = { uses_max = "VOIDCLOTH_BOOMERANG_USES" },   -- vanilla
    ["voidcloth_boomerang_impact_fx"] = { uses_max = "VOIDCLOTH_BOOMERANG_USES" },   -- vanilla
    ["voidcloth_boomerang_launch_fx"] = { uses_max = "VOIDCLOTH_BOOMERANG_USES" },   -- vanilla
    ["voidcloth_boomerang_proj"] = { uses_max = "VOIDCLOTH_BOOMERANG_USES" },   -- vanilla
    ["voidcloth_kit"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["voidcloth_scythe"] = { uses_max = "VOIDCLOTH_SCYTHE_USES" },   -- vanilla
    ["voidcloth_scythe_classified"] = { uses_max = "VOIDCLOTH_SCYTHE_USES" },   -- vanilla
    ["voidcloth_scythe_fx"] = { uses_max = "VOIDCLOTH_SCYTHE_USES" },   -- vanilla
    ["voidcloth_umbrella"] = { fuel_max = "VOIDCLOTH_UMBRELLA_PERISHTIME" },   -- vanilla
    ["voidcloth_umbrella_fx"] = { fuel_max = "VOIDCLOTH_UMBRELLA_PERISHTIME" },   -- vanilla
    ["voidclothhat_fx"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["wagboss_robot_constructionsite"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wagboss_robot_constructionsite_kit"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wagboss_robot_constructionsite_kit_placer"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wagboss_robot_constructionsite_placerindicator"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wagboss_robot_creation_parts"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wagdrone_common"] = { uses_max = "WAGDRONE_ROLLING_USES" },   -- vanilla
    ["wagdrone_parts"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["wagpunk"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["wagpunk_bits"] = { food_health = "HEALING_HUGE", food_hunger = "CALORIES_HUGE", food_sanity = "SANITY_HUGE", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["wagpunk_floor_kit"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["wagpunk_floor_kit_placer"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["wagpunk_floor_marker"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["wagpunk_floor_placerindicator"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["wagpunkbits_kit"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wagpunkhat_classified"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["wagpunkhat_fx"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["wagstaff_tools"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["walking_stick"] = { fuel_max = "WALKING_STICK_PERISHTIME" },   -- vanilla
    ["wall_"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["walrus"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["walrus_tusk"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["walter"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["watermelon"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["waterplant_planter"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["waterstreak_projectile"] = { food_health = 0, food_hunger = 0, food_sanity = 0, perish_days = "PERISH_ONE_DAY" },   -- vanilla
    ["wathgrithr"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["wathgrithr_improved"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["wave_splash"] = { uses_max = "GNARWAIL_HORN" },   -- vanilla
    ["waxpaper"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["waxwelljournal"] = { fuel_max = "LARGE_FUEL" },   -- vanilla
    ["weed_forgetmelots"] = { food_health = 0, food_hunger = 0, food_sanity = "SANITY_SUPERTINY", perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["weed_forgetmelots_respawner"] = { food_health = 0, food_hunger = 0, food_sanity = "SANITY_SUPERTINY", perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["wereitem_"] = { food_hunger = "CALORIES_MED", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wetpouch"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["whip"] = { uses_max = "WHIP_USES" },   -- vanilla
    ["willow_ember"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["willow_frenzy"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["willow_shadow_flame"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["willow_throw_flame"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["winona_battery_low"] = { fuel_max = "WINONA_BATTERY_LOW_MAX_FUEL_TIME" },   -- vanilla
    ["winona_battery_low_item"] = { fuel_max = "WINONA_BATTERY_LOW_MAX_FUEL_TIME" },   -- vanilla
    ["winona_battery_low_item_placer"] = { fuel_max = "WINONA_BATTERY_LOW_MAX_FUEL_TIME" },   -- vanilla
    ["winona_battery_sparks"] = { fuel_max = "WINONA_TELEBRELLA_MAX_FUEL_TIME" },   -- vanilla
    ["winona_holotelebrella"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["winona_holotelepad"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["winona_machineparts_1"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["winona_machineparts_2"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["winona_recipescanner"] = { stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["winona_remote"] = { fuel_max = "WINONA_REMOTE_FUEL" },   -- vanilla
    ["winona_storage_robot"] = { fuel_max = "WINONA_STORAGE_ROBOT_FUEL" },   -- vanilla
    ["winona_storage_robot_placer"] = { fuel_max = "WINONA_STORAGE_ROBOT_FUEL" },   -- vanilla
    ["winona_telebrella"] = { fuel_max = "WINONA_TELEBRELLA_MAX_FUEL_TIME" },   -- vanilla
    ["winona_telebrella_swap_fx"] = { fuel_max = "WINONA_TELEBRELLA_MAX_FUEL_TIME" },   -- vanilla
    ["winter"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["winter_food"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["wintersfeastfuel"] = { food_health = 0, food_hunger = 0, stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["wobster_moonglass"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_SMALL", perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wobster_moonglass_land"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_SMALL", perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wobster_sheller"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_SMALL", perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wobster_sheller_dead"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_SMALL", perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wobster_sheller_dead_cooked"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_SMALL", perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wobster_sheller_land"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_SMALL", perish_days = "PERISH_SUPERFAST", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["woby_treat"] = { food_hunger = "CALORIES_TINY", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["woodcarved"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["wormlight"] = { food_health = "HEALING_MEDSMALL", food_hunger = "CALORIES_MED", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wormlight_lesser"] = { food_health = "HEALING_MEDSMALL", food_hunger = "CALORIES_MED", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wormlight_light"] = { food_health = "HEALING_MEDSMALL", food_hunger = "CALORIES_MED", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wormlight_light_fx"] = { food_health = "HEALING_MEDSMALL", food_hunger = "CALORIES_MED", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wormlight_light_fx_greater"] = { food_health = "HEALING_MEDSMALL", food_hunger = "CALORIES_MED", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wormlight_light_fx_lesser"] = { food_health = "HEALING_MEDSMALL", food_hunger = "CALORIES_MED", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wormlight_light_greater"] = { food_health = "HEALING_MEDSMALL", food_hunger = "CALORIES_MED", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wormlight_light_lesser"] = { food_health = "HEALING_MEDSMALL", food_hunger = "CALORIES_MED", perish_days = "PERISH_MED", stack_max = "STACK_SIZE_LARGEITEM" },   -- vanilla
    ["wortox_reviver"] = { perish_days = "SKILLS" },   -- vanilla
    ["wortox_reviver_body"] = { perish_days = "SKILLS" },   -- vanilla
    ["wortox_soul"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["wortox_soul_spawn"] = { uses_max = "PANFLUTE_USES" },   -- vanilla
    ["wortox_soul_spawn_fx"] = { uses_max = "PANFLUTE_USES" },   -- vanilla
    ["wx78_drone_zap"] = { uses_max = "SKILLS" },   -- vanilla
    ["wx78_drone_zap_remote"] = { uses_max = "SKILLS" },   -- vanilla
    ["wx78_foodbrick"] = { food_health = "HEALING_TINY", food_hunger = "CALORIES_MEDSMALL", food_sanity = 0, perish_days = "PERISH_ONE_DAY", stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["wx78module_"] = { uses_max = "WX78_MODULE_USES" },   -- vanilla
    ["yellowamulet"] = { fuel_max = "BLUEAMULET_FUEL", uses_max = "REDAMULET_USES" },   -- vanilla
    ["yellowamuletlight"] = { fuel_max = "BLUEAMULET_FUEL", uses_max = "REDAMULET_USES" },   -- vanilla
    ["yellowstaff"] = { uses_max = "FIRESTAFF_USES" },   -- vanilla
    ["yotb_beefalo_dolls"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["yotb_pattern_fragments"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["yotc_seedpacket"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["yotc_seedpacket_rare"] = { stack_max = "STACK_SIZE_MEDITEM" },   -- vanilla
    ["yotd_oar"] = { food_health = 0, food_hunger = 0 },   -- vanilla
    ["yoth_knight"] = { fuel_max = "STRAWHAT_PERISHTIME", perish_days = "PERISH_FAST", uses_max = "ANTLIONHAT_USES" },   -- vanilla
    ["yoth_knightstick"] = { fuel_max = "YOTH_KNIGHTSTICK_PERISHTIME" },   -- vanilla
    ["yoth_lance"] = { uses_max = "YOTH_LANCE_USES" },   -- vanilla
    ["yotp_food"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["yotr_food"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["yotr_token"] = { stack_max = "STACK_SIZE_SMALLITEM" },   -- vanilla
    ["yots_redlantern"] = { fuel_max = "REDLANTERN_LIGHTTIME" },   -- vanilla
}

local STATS = MUSHA_ITEM_STATS or {}
for k, v in pairs(EXTRA) do
    STATS[k] = STATS[k] or {}
    for kk, vv in pairs(v) do
        STATS[k][kk] = vv
    end
end
MUSHA_ITEM_STATS = STATS

return EXTRA
