-- 数据更新辅助函数：同步客户端副本数据
local function DoUpdata(self, data)
    if self.inst.replica.musha_profession_component then
        self.inst.replica.musha_profession_component:DoUpdata(data) -- 打包发送到服务端里去
    end
end

local function UpdataWarrior(self, data)
    if self.inst.replica.musha_profession_component then
        self.inst.replica.musha_profession_component:UpdataWarrior(data) -- 打包战士的信息部分
    end
end

local function UpdataSaber(self, data)
    if self.inst.replica.musha_profession_component then
        self.inst.replica.musha_profession_component:UpdataSaber(data) -- 打包剑士的信息部分
    end
end

local function UpdataGuardian(self, data)
    if self.inst.replica.musha_profession_component then
        self.inst.replica.musha_profession_component:UpdataGuardian(data) -- 打包近卫
    end
end

local function OnKilledOther(inst, data)
    local self = inst.components.musha_profession_component
    if not self then
        return
    end

    -- 检查是否是可获得经验的生物
    if data.victim:HasTag("player") or data.victim:HasTag("companion") or data.victim:HasTag("wall") or
        data.victim:HasTag("structure") then
        return
    end

    local max_health = data.victim.components.health.maxhealth

    -- 计算经验值：每100血量获得1~3点经验
    local health_ratio = max_health / 100
    local base_exp = math.floor(health_ratio) -- 基础倍数

    if base_exp <= 0 then
        return
    end

    -- 随机1~3点经验
    local random_exp = math.random(1, 3)
    local total_exp = base_exp * random_exp

    -- 确保至少有1点经验
    if total_exp <= 0 then
        total_exp = 1
    end

    self:AddExperience(total_exp)

    -- 调试信息
    if inst.components.talker then
        inst.components.talker:Say(string.format("获得击杀经验: +%d 经验", total_exp))
    end

    -- 只处理剑士职业
    if not self.userdata.carrer_special or self.userdata.carrer_special ~= "saber" then
        return
    end

    if not data or not data.victim then
        return
    end

    -- 获取剑士特性
    local saber_traits = self.class_traits.saber
    if not saber_traits then
        return
    end

    -- 获取玩家实体
    local player = self.inst

    -- 检查是否有战斗组件
    if not player.components.combat or not player.components.combat.externaldamagemultipliers then
        return
    end

    -- 移除旧的加成，准备叠加新的
    player.components.combat.externaldamagemultipliers:RemoveModifier(player, "saber_hunt_bonus")

    -- 增加猎杀加成，最高150%
    saber_traits.current_hunt_bonus = math.min(saber_traits.current_hunt_bonus + 0.1, 1.5)

    -- 应用新的伤害加成
    player.components.combat.externaldamagemultipliers:SetModifier(player, saber_traits.current_hunt_bonus,
        "saber_hunt_bonus")
end

-- 2. 解锁新配方获得经验（每次获得5点经验）
local function OnRecipeLearned(inst, data)
    local self = inst.components.musha_profession_component
    if not self then
        return
    end

    if not data or not data.recipe then
        return
    end

    -- 只处理实际解锁的新配方
    if data.recipe == "" or data.recipe == "unknown" then
        return
    end

    -- 每次解锁配方获得5点经验
    local exp_amount = 5

    -- 添加经验
    self:AddExperience(exp_amount)

    -- 调试信息
    if inst.components.talker then
        inst.components.talker:Say(string.format("配方解锁经验: +%d 经验", exp_amount))
    end
end

-- 3. 每日生存获得经验（每生存1日获得3~7点经验）
local function NewDay(inst)
    local self = inst.components.musha_profession_component
    if not self then
        return
    end

    local exp_amount = math.random(3, 7)

    -- 添加经验
    self:AddExperience(exp_amount)

    -- 调试信息
    if inst.components.talker then
        inst.components.talker:Say(string.format("生存经验: 获得 +%d 经验", exp_amount))
    end
end

-- 战斗恢复处理
local function OnLostTarget(inst, data)
    local self = inst.components.musha_profession_component
    if not self then
        return
    end

    -- 如果是战士职业，启动战斗恢复
    if self.userdata.carrer_base and self.userdata.carrer_base == "warrior" then
        local heal_amount = 0
        
        -- 获取当前战斗恢复技能等级效果
        local cr = self.warrior.combat_recovery
        if cr and cr.current_level > 0 and cr.level_effects[cr.current_level] then
            heal_amount = cr.level_effects[cr.current_level]
        end
        
        if heal_amount > 0 and not self.healthtask then
            self.healthtask = self.inst:DoPeriodicTask(1, function()
                if self.inst.components.health and not self.inst.components.health:IsDead() then
                    self.inst.components.health:DoDelta(heal_amount)
                end
            end)
        end
    end

    -- 只处理剑士职业
    if not self.userdata.carrer_special or self.userdata.carrer_special ~= "saber" then
        return
    end

    -- 获取剑士特性
    local saber_traits = self.class_traits.saber
    if not saber_traits then
        return
    end

    -- 获取玩家实体
    local player = self.inst

    -- 检查是否有战斗组件
    if not player.components.combat or not player.components.combat.externaldamagemultipliers then
        return
    end

    -- 只有当存在加成时才清零，避免无效操作
    if saber_traits.current_hunt_bonus > 0 then
        saber_traits.current_hunt_bonus = 0

        -- 从战斗组件移除加成
        player.components.combat.externaldamagemultipliers:RemoveModifier(player, "saber_hunt_bonus")
    end
end

-- 攻击时处理
local function OnAttackOther(inst, data)
    local self = inst.components.musha_profession_component
    if not self then
        return
    end

    -- 停止战斗恢复计时器
    if self.healthtask then
        self.healthtask:Cancel()
        self.healthtask = nil
    end
    
    -- 处理近卫生命偷取 这个有问题 我记得改成了荆棘伤害
    if self.userdata.carrer_special and self.userdata.carrer_special == "guardian" and data and data.damage then
        local ll = self.guardian.life_leech
        if ll and ll.current_level > 0 and ll.level_effects[ll.current_level] then
            local heal_ratio = ll.level_effects[ll.current_level] or 0
            local heal_amount = data.damage * heal_ratio
            
            if heal_amount > 0 and self.inst.components.health then
                self.inst.components.health:DoDelta(heal_amount)
            end
        end
    end
    
    -- 处理刺客SAN消耗
    if self.userdata.carrer_base and self.userdata.carrer_base == "rogue" and self.inst.components.sanity then
        local traits = self.class_traits.rogue
        if traits and traits.attack_san_cost then
            self.inst.components.sanity:DoDelta(-traits.attack_san_cost)
        end
    end
end

-- 被攻击时处理
local function GetAttacked(inst, data)
    local self = inst.components.musha_profession_component
    if not self then
        return
    end
    
    -- 停止战斗恢复计时器
    if self.healthtask then
        self.healthtask:Cancel()
        self.healthtask = nil
    end
end

-- ====================================
-- 转职配送
-- 触发 musha_job_changed 事件时按职业给物品
local JOB_WEAPONS = {
    [1] = { prefab = "musha_sword" },
}
local function OnJobChanged(inst, job_id)
    local self = inst.components.musha_profession_component
    if not self then return end

    -- 按职业配送
    local weapon_def = JOB_WEAPONS[job_id]
    if weapon_def then
        local item = SpawnPrefab(weapon_def.prefab)
        if item and inst.components.inventory then
            inst.components.inventory:GiveItem(item)
        end
    end
end

local Musha_Profession_Component = Class(function(self, inst)
    self.inst = inst

    self.userdata = {
        carrer_base = nil, -- 选定以后，客户端会将信息发送到这里来，从而设定职业。
        carrer_special = nil, -- 一转，其实是选择特殊职业。7级后就可以启动转职职业
        level = 0, -- 开始是0级，所以此级别经验需求为5
        exp = 0, -- 满足条件就升级
        skill_points = 0, -- 可用技能点
        exp_to_next = 5, -- 1级需要5经验
        total_exp = 0, -- 累计获得经验
        has_advanced = false, -- 是否已完成一转
        quests_for_advance = {}, -- 当前进阶任务的3个任务 ID
        quests_for_advance_done = {}, -- {1=true, 2=true, 3=true}
        current_advance_target = nil, -- 当前进阶的目标职业 ID
        learned_skills = {}, -- 学习过的技能
    }

    self.exp_table = {0, 5, 12, 20, 30, 45, 60, 80, 100, 125, 155, 190, 230, 275, 325, 380, 440, 505, 575, 650, 730, 820, 920, 1030, 1150, 1280, 1420, 1570, 1730, 1900}

    -- 职业特性表
    self.class_traits = {
        warrior = {
            combat_growth = 0.25, -- 战斗成长 (防御加成)
            health_regen = 0.22, -- 基础生命回复
            health_growth = 4.5, -- 每级生命成长
            sanity_growth = 2.0, -- 每级精神成长
            mp_base = 80, -- 初始MP
            mp_max_growth = 2.5, -- 每级MP成长
            mp_regen_base = 0.5, -- 基础MP回复/秒
            mp_regen_growth = 0.02, -- 每级MP回复成长
            luck = 1 -- 幸运值
        },

        saber = {
            weapon_mastery = 2.5, -- 剑/矛伤害倍率
            hunt_bonus_max = 1.5, -- 猎杀强化最大150%
            current_hunt_bonus = 0, -- 当前猎杀加成
            luck = 1 -- 幸运值
        },

        guardian = {
            mp_base = 240, -- 初始MP
            mp_max_growth = 3, -- 每级MP成长
            mp_regen = 1.2, -- MP恢复速率固定1.2/秒
            defense_max = 0.4, -- 防御上限40%
            luck = 1 -- 幸运值
        },

        mage = {
            health_growth = 2.0,
            sanity_growth = 3.0,
            mp_base = 60, -- 初始MP
            mp_max_growth = 12, -- 20级300MP
            mp_regen_base = 2.4, -- 基础MP回复/秒
            mp_regen_growth = 0.08, -- MP回复成长
            luck = 1
        },

        elementalist = {
            current_element = "wind", -- 当前元素
            elements = {"wind", "fire", "ice"}
        },

        rogue = {
            sanity_max = 80, -- SAN上限 (成长到120)
            sanity_growth = 2.1, -- SAN成长/级
            night_sanity_immune = true, -- 黄昏夜晚不掉SAN
            no_charlie_duration = 120, -- 缺光源查理免疫秒数
            stealth_thermoreg = true, -- 潜行温度恒定
            attack_san_cost = 1.5, -- 平均攻击消耗SAN
            health_growth = 3.0, -- 每级生命成长
            mp_base = 80, -- 初始MP
            mp_max_growth = 2, -- 20级120MP
            mp_regen_base = 1.1, -- 基础MP回复/秒
            mp_regen_growth = 0.112, -- MP回复成长
            luck = 1 -- 幸运值
        },

        moonshadow = {
            backstab_mult = 10.0, -- 背刺倍率
            backstab_min_san = 40 -- 背刺最低SAN要求
        },

        ranger = {
            health_growth = 3.5,
            sanity_growth = 2.5,
            mp_base = 120, -- 初始MP
            mp_max_growth = 1.5, -- 20级150MP
            mp_regen_base = 0.84, -- 基础MP回复/秒
            mp_regen_growth = 0.35, -- MP回复成长
            luck = 3, -- 幸运3
            double_harvest = true -- 双倍采集
        },

        bard = {
            sanity_regen_boost = 2.0, -- SAN回复加成
            can_summon_fairy = true, -- 可召唤小精灵
            fairy_light = true -- 精灵发光
        }
    }

    -- 战士技能树
    self.warrior = {
        combat_recovery = {
            current_level = 0, -- 当前技能等级，0表示未学习
            max_level = 3, -- 技能最大等级
            level_effects = { -- 各等级效果
                [1] = 0.11, -- 等级1效果
                [2] = 0.18, -- 等级2效果
                [3] = 0.22  -- 等级3效果
            },
            unlock_requirements = { -- 解锁要求
                [1] = 0,  -- 等级1默认解锁
                [2] = 3,  -- 等级2需要3级
                [3] = 5   -- 等级3需要5级
            }
        },
        
        weapon_proficiency = {
            current_level = 0,
            max_level = 3,
            level_effects = { -- 额外增伤倍率
                [1] = 0.30, -- 30%伤害
                [2] = 0.48, -- 48%伤害
                [3] = 0.63  -- 63%伤害
            },
            unlock_requirements = {
                [1] = 3,
                [2] = 5,
                [3] = 7
            }
        }
    }

    -- 剑士技能树
    self.saber = {
        hit = {
            current_level = 0,
            max_level = 4,
            level_effects = {
                [1] = 0.10, -- 10%效果
                [2] = 0.20, -- 20%效果
                [3] = 0.30, -- 30%效果
                [4] = 0.40  -- 40%效果
            },
            unlock_requirements = {
                [1] = 7,
                [2] = 9,
                [3] = 12,
                [4] = 16
            }
        },

        stealing_life = {
            current_level = 0,
            max_level = 4,
            level_effects = {
                [1] = 0.023, -- 2.3%吸血
                [2] = 0.054, -- 5.4%吸血
                [3] = 0.086, -- 8.6%吸血
                [4] = 0.114  -- 11.4%吸血
            },
            unlock_requirements = {
                [1] = 4,
                [2] = 7,
                [3] = 11,
                [4] = 15
            }
        }
    }

    -- 近卫技能树
    self.guardian = {
        iron_will = { -- 钢铁意志（替代武器精通）
            current_level = 0,
            max_level = 3,
            level_effects = { -- 钢铁意志每级增加5%防御
                [1] = 0.05,  -- 5%额外伤害减免
                [2] = 0.10,  -- 10%额外伤害减免
                [3] = 0.15   -- 15%额外伤害减免
            },
            unlock_requirements = {
                [1] = 3,
                [2] = 5,
                [3] = 7
            }
        },

        life_leech = { -- 生命偷取
            current_level = 0,
            max_level = 4,
            level_effects = {
                [1] = 0.05,  -- 5%伤害转治疗
                [2] = 0.10,  -- 10%伤害转治疗
                [3] = 0.15,  -- 15%伤害转治疗
                [4] = 0.20   -- 20%伤害转治疗
            },
            unlock_requirements = {
                [1] = 4,
                [2] = 7,
                [3] = 10,
                [4] = 13
            }
        }
    }
    
    -- 状态标记
    self.applied_status = {
        combat_growth = nil,
        weapon_proficiency = nil,
        iron_will = nil,
        life_leech = nil,
    }
    
    -- 任务计时器
    self.healthtask = nil
    self.task = nil

    -- 事件监听
    self.inst:ListenForEvent("losttarget", OnLostTarget)
    self.inst:ListenForEvent("killedother", OnKilledOther)
    self.inst:ListenForEvent("unlockrecipe", OnRecipeLearned)
    self.inst:ListenForEvent("onattackother", OnAttackOther)
    self.inst:ListenForEvent("attacked", GetAttacked)
    self.inst:WatchWorldState("startday", NewDay)

    -- 转职事件监听 — 只用这一个，按职业给内容
    self.inst:ListenForEvent("musha_job_changed", function(inst, data)
        if not data or not data.job_id then return end
        OnJobChanged(inst, data.job_id)
    end)
end, nil, {
    userdata = DoUpdata,
    warrior = UpdataWarrior,
    saber = UpdataSaber,
    guardian = UpdataGuardian
})

-- 核心：应用职业数据的统一函数
function Musha_Profession_Component:ApplyProfessionData()
    if not self.inst or not self.inst.components.health then
        return
    end
    
    local player = self.inst
    
    -- 1. 应用战士基础防御 (0.25) - 所有战士分支共享
    if self.userdata.carrer_base and self.userdata.carrer_base == "warrior" then
        if not self.applied_status.combat_growth then
            player.components.health.externalabsorbmodifiers:RemoveModifier(player, "warrior_base_defense")
            player.components.health.externalabsorbmodifiers:SetModifier(
                player, 0.25, "warrior_base_defense"
            )
            self.applied_status.combat_growth = 0.25
        end
    end
    
    -- 2. 应用武器精通（仅剑士）
    if self.userdata.carrer_special and self.userdata.carrer_special == "saber" then
        local wp = self.warrior.weapon_proficiency
        if wp and wp.current_level > 0 and wp.level_effects[wp.current_level] then
            local effect = wp.level_effects[wp.current_level]
            if self.applied_status.weapon_proficiency ~= effect then
                if player.components.combat and player.components.combat.externaldamagemultipliers then
                    player.components.combat.externaldamagemultipliers:RemoveModifier(
                        player, "warrior_weapon_proficiency"
                    )
                    player.components.combat.externaldamagemultipliers:SetModifier(
                        player, effect, "warrior_weapon_proficiency"
                    )
                    self.applied_status.weapon_proficiency = effect
                end
            end
        end
    end
    
    -- 3. 应用钢铁意志（仅近卫）
    if self.userdata.carrer_special and self.userdata.carrer_special == "guardian" then
        local iw = self.guardian.iron_will
        if iw and iw.current_level > 0 and iw.level_effects[iw.current_level] then
            local effect = 0.25 + iw.level_effects[iw.current_level]  -- 基础0.25 + 钢铁意志效果
            if self.applied_status.iron_will ~= effect then
                player.components.health.externalabsorbmodifiers:RemoveModifier(
                    player, "guardian_iron_will"
                )
                player.components.health.externalabsorbmodifiers:SetModifier(
                    player, effect, "guardian_iron_will"
                )
                self.applied_status.iron_will = effect
            end
        end
    end
    
    -- 4. 应用生命偷取（仅近卫）
    if self.userdata.carrer_special and self.userdata.carrer_special == "guardian" then
        local ll = self.guardian.life_leech
        if ll and ll.current_level > 0 and ll.level_effects[ll.current_level] then
            local effect = ll.level_effects[ll.current_level]
            if self.applied_status.life_leech ~= effect then
                if player.components.combat and player.components.combat.externaldamagemultipliers then
                    player.components.combat.externaldamagemultipliers:RemoveModifier(
                        player, "guardian_life_leech"
                    )
                    player.components.combat.externaldamagemultipliers:SetModifier(
                        player, effect, "guardian_life_leech"
                    )
                    self.applied_status.life_leech = effect
                end
            end
        end
    end
    
    -- 5. 如果转职近卫，移除武器精通效果
    if self.userdata.carrer_special and self.userdata.carrer_special == "guardian" then
        if self.applied_status.weapon_proficiency then
            if player.components.combat and player.components.combat.externaldamagemultipliers then
                player.components.combat.externaldamagemultipliers:RemoveModifier(
                    player, "warrior_weapon_proficiency"
                )
                self.applied_status.weapon_proficiency = nil
            end
        end
    end
    
    -- 6. 如果转职剑士，移除钢铁意志效果
    if self.userdata.carrer_special and self.userdata.carrer_special == "saber" then
        if self.applied_status.iron_will then
            player.components.health.externalabsorbmodifiers:RemoveModifier(
                player, "guardian_iron_will"
            )
            self.applied_status.iron_will = nil
        end
        
        if self.applied_status.life_leech then
            if player.components.combat and player.components.combat.externaldamagemultipliers then
                player.components.combat.externaldamagemultipliers:RemoveModifier(
                    player, "guardian_life_leech"
                )
                self.applied_status.life_leech = nil
            end
        end
    end
end

function Musha_Profession_Component:GetCarrer_base()
    return self.userdata.carrer_base
end

function Musha_Profession_Component:GetCarrer_special()
    return self.userdata.carrer_special
end

function Musha_Profession_Component:SetCarrerBase(carrer)
    if not carrer or carrer == "" then
        return false
    end
    self.userdata.carrer_base = carrer
    self:ApplyProfessionData()  -- 应用新职业的效果
    return true
end

function Musha_Profession_Component:SetCarrerSpecial(carrer)
    if not carrer or carrer == "" then
        return false
    end
    self.userdata.carrer_special = carrer
    self:ApplyProfessionData()  -- 应用新职业的效果
    return true
end

function Musha_Profession_Component:GetExpInfo()
    return {
        level = self.userdata.level,
        exp = self.userdata.exp,
        exp_to_next = self.userdata.exp_to_next,
        total_exp = self.userdata.total_exp,
        exp_percent = self.userdata.level < 20 and (self.userdata.exp / self.exp_table[self.userdata.level + 1]) * 100 or 100
    }
end

function Musha_Profession_Component:GetCarrerInfo()
    return {
        base = self.userdata.carrer_base,
        special = self.userdata.carrer_special
    }
end

function Musha_Profession_Component:GetSkillPointsInfo()
    return self.userdata.skill_points
end

function Musha_Profession_Component:UpdateExpToNext()
    if self.userdata.level < 0 or self.userdata.level >= #self.exp_table then
        self.userdata.exp_to_next = 0
    else
        self.userdata.exp_to_next = self.exp_table[self.userdata.level + 1] - self.userdata.exp
    end
end

-- 添加经验
function Musha_Profession_Component:AddExperience(amount)
    if not amount or amount <= 0 then
        return false
    end

    self.userdata.exp = self.userdata.exp + amount
    self.userdata.total_exp = self.userdata.total_exp + amount

    local levels_gained = 0
    while self.userdata.level < 30 and self.userdata.level < #self.exp_table and self.userdata.exp >= self.exp_table[self.userdata.level + 1] do
        self.userdata.level = self.userdata.level + 1
        self.userdata.skill_points = self.userdata.skill_points + 1
        levels_gained = levels_gained + 1
    end

    if levels_gained > 0 then
        if self.inst.SoundEmitter then
            self.inst.SoundEmitter:PlaySound("dontstarve/common/statsup")
        end
    end

    self:UpdateExpToNext()

    return true, levels_gained > 0, levels_gained
end

-- 检查是否可以升级技能
function Musha_Profession_Component:CanUpgradeSkill(skill_tree, skill_name)
    if not self[skill_tree] or not self[skill_tree][skill_name] then
        return false, "技能不存在"
    end

    local skill = self[skill_tree][skill_name]

    -- 检查是否已达最大等级
    if skill.current_level >= skill.max_level then
        return false, "已达技能最大等级"
    end

    local next_level = skill.current_level + 1

    -- 检查等级要求
    if skill.unlock_requirements and skill.unlock_requirements[next_level] then
        if self.userdata.level < skill.unlock_requirements[next_level] then
            return false, string.format("需要等级%d才能学习", skill.unlock_requirements[next_level])
        end
    end

    return true, "可以升级"
end

-- 升级技能
function Musha_Profession_Component:UpgradeSkill(skill_tree, skill_name)
    local can_upgrade, reason = self:CanUpgradeSkill(skill_tree, skill_name)
    if not can_upgrade then
        return false, reason
    end

    local skill = self[skill_tree][skill_name]

    -- 检查技能点
    if self.userdata.skill_points < 1 then
        if self.inst.components.talker then
            self.inst.components.talker:Say(STRINGS.MUSHA_SKILL_NEED_SKILL_POINTS or
                                                "技能点不足")
        end
        return false, "技能点不足"
    end

    -- 消耗技能点
    self.userdata.skill_points = self.userdata.skill_points - 1

    -- 升级技能
    skill.current_level = skill.current_level + 1

    local new_level = skill.current_level
    local new_effect = skill.level_effects[new_level] or 0

    -- 应用新效果
    self:ApplyProfessionData()

    return true,
        string.format("技能 %s 已升级到等级 %d (效果: %.1f%%)", skill_name, new_level, new_effect * 100)
end

-- 获取技能信息
function Musha_Profession_Component:GetSkillInfo(skill_tree, skill_name)
    if not self[skill_tree] or not self[skill_tree][skill_name] then
        return nil
    end

    local skill = self[skill_tree][skill_name]
    local info = {
        name = skill_name,
        current_level = skill.current_level or 0,
        max_level = skill.max_level or 0,
        effect = 0,
        next_effect = 0,
        can_upgrade = false,
        requirement = 0
    }

    -- 当前效果
    if skill.current_level > 0 and skill.level_effects[skill.current_level] then
        info.effect = skill.level_effects[skill.current_level]
    end

    -- 下一级效果
    if skill.current_level < skill.max_level then
        local next_level = skill.current_level + 1
        if skill.level_effects[next_level] then
            info.next_effect = skill.level_effects[next_level]
        end

        -- 升级要求
        if skill.unlock_requirements and skill.unlock_requirements[next_level] then
            info.requirement = skill.unlock_requirements[next_level]
        end

        -- 是否可以升级
        info.can_upgrade = self.userdata.skill_points > 0 and self.userdata.level >= info.requirement
    end

    return info
end

-- 替换原来的 UpdataMushaData
function Musha_Profession_Component:UpdateCharacterStats()
    self:ApplyProfessionData()
end

-- ====== 职业操作（从 musha_playerdata 迁移） ======

function Musha_Profession_Component:HasBaseJob()
    return self.userdata.carrer_base ~= nil
end

function Musha_Profession_Component:HasJob()
    return self.userdata.carrer_base ~= nil
end

-- 获取所有技能等级的扁平表 { skill_id = level, ... }
-- 合并三个职业技能树，供 UI 使用
function Musha_Profession_Component:GetAllSkillLevels()
    local levels = {}
    -- 战士技能树
    for name, skill in pairs(self.warrior) do
        if skill.current_level and skill.current_level > 0 then
            levels["warrior_" .. name] = skill.current_level
        end
    end
    -- 剑士技能树
    for name, skill in pairs(self.saber) do
        if skill.current_level and skill.current_level > 0 then
            levels["saber_" .. name] = skill.current_level
        end
    end
    -- 近卫技能树
    for name, skill in pairs(self.guardian) do
        if skill.current_level and skill.current_level > 0 then
            levels["guardian_" .. name] = skill.current_level
        end
    end
    return levels
end

function Musha_Profession_Component:GetJob()
    return self.userdata.carrer_base
end

function Musha_Profession_Component:GetAdvanceJob()
    return self.userdata.carrer_special
end

-- GetLevel / GetExp 系列
function Musha_Profession_Component:GetLevel()
    return self.userdata.level or 0
end

function Musha_Profession_Component:GetMaxLevel()
    return 30
end

function Musha_Profession_Component:GetExp()
    return self.userdata.exp or 0
end

function Musha_Profession_Component:GetExpForNextLevel()
    local level = self.userdata.level
    if level < #self.exp_table then
        return self.exp_table[level + 1]
    end
    return 0
end

function Musha_Profession_Component:GetSkillPoints()
    return self.userdata.skill_points or 0
end

-- 获取职业名称（需要 GLOBAL.STRINGS）
function Musha_Profession_Component:GetJobName()
    if not self.userdata.carrer_base then return "无职业" end
    local name_key = "MUSHA_JOB_" .. string.upper(self.userdata.carrer_base)
    if GLOBAL.STRINGS[name_key] then
        return GLOBAL.STRINGS[name_key]
    end
    return self.userdata.carrer_base
end

function Musha_Profession_Component:GetAdvanceJobName()
    if not self.userdata.carrer_special then return nil end
    local name_key = "MUSHA_JOB_" .. string.upper(self.userdata.carrer_special)
    if GLOBAL.STRINGS[name_key] then
        return GLOBAL.STRINGS[name_key]
    end
    return self.userdata.carrer_special
end

-- 获取基础职业 ID（从进阶职业反推）
function Musha_Profession_Component:GetBaseJobName()
    if not self.userdata.carrer_base then return nil end
    if self.userdata.carrer_special then
        -- 反向查找：遍历 MUSHA_ADVANCE_MAP 找匹配
        for base_name, adv_list in pairs({
            warrior = {"saber", "guardian"},
            mage = {"alchemist", "elementalist"},
            ranger = {"bard"},
            assassin = {"moonshadow"},
        }) do
            for _, adv_name in ipairs(adv_list) do
                if adv_name == self.userdata.carrer_special then
                    return base_name
                end
            end
        end
    end
    return self.userdata.carrer_base
end

-- 增加经验（别名，统一接口）
function Musha_Profession_Component:AddExp(amount)
    if not amount or amount <= 0 then return 0, false end
    local _, leveled_up, levels = self:AddExperience(amount)
    return amount, leveled_up or false
end

-- 扣除经验
function Musha_Profession_Component:RemoveExp(amount)
    self.userdata.exp = math.max(0, (self.userdata.exp or 0) - (amount or 0))
    self.userdata.total_exp = math.max(0, (self.userdata.total_exp or 0) - (amount or 0))
    self:UpdateExpToNext()
end

-- 惩罚经验（可为负）
function Musha_Profession_Component:PenaltyExp(amount)
    self.userdata.exp = (self.userdata.exp or 0) - (amount or 0)
    self.userdata.total_exp = math.max(0, (self.userdata.total_exp or 0) - (amount or 0))
    self:UpdateExpToNext()
end

-- ====== 进阶任务操作（从 musha_playerdata 迁移） ======

function Musha_Profession_Component:SetAdvanceQuest(quest_ids, target_job)
    self.userdata.quests_for_advance = quest_ids or {}
    self.userdata.quests_for_advance_done = {}
    self.userdata.current_advance_target = target_job
end

function Musha_Profession_Component:MarkAdvanceQuestDone(slot_index)
    if not self.userdata.quests_for_advance_done then
        self.userdata.quests_for_advance_done = {}
    end
    self.userdata.quests_for_advance_done[slot_index] = true
end

function Musha_Profession_Component:IsAdvanceQuestDone(slot_index)
    return self.userdata.quests_for_advance_done and self.userdata.quests_for_advance_done[slot_index] == true
end

function Musha_Profession_Component:AreAllAdvanceQuestsDone()
    for i = 1, 3 do
        if not self.userdata.quests_for_advance_done or not self.userdata.quests_for_advance_done[i] then
            return false
        end
    end
    return true
end

function Musha_Profession_Component:CompleteAdvance()
    if not self.userdata.current_advance_target then return end
    self.userdata.carrer_special = self.userdata.current_advance_target
    self.userdata.has_advanced = true
    self.userdata.quests_for_advance = {}
    self.userdata.quests_for_advance_done = {}
    self.userdata.current_advance_target = nil

    -- 给予一转基础技能书
    local skillbook_map = {
        swordsman = "musha_skillbook_swordsman",
        guardian = "musha_skillbook_guardian",
        alchemist = "musha_skillbook_alchemist",
        elementalist = "musha_skillbook_elementalist",
        bard = "musha_skillbook_bard",
        moonshadow = "musha_skillbook_moonshadow",
    }
    local prefab_name = skillbook_map[self.userdata.carrer_special]
    if prefab_name and SpawnPrefab then
        local book = SpawnPrefab(prefab_name)
        if book and self.inst.components.inventory then
            self.inst.components.inventory:GiveItem(book)
        end
    end

    if self.inst.components.talker then
        self.inst.components.talker:Say("一转进阶完成！当前职业: " .. (self:GetAdvanceJobName() or "未知"), 5)
    end
    print("[Musha] " .. tostring(self.inst.prefab) .. " 完成一转进阶: " .. (self.userdata.carrer_special or "未知"))
end

-- ====== 技能系统（从 musha_playerdata 迁移） ======

function Musha_Profession_Component:LearnSkill(skill_id)
    if not self.userdata.learned_skills then
        self.userdata.learned_skills = {}
    end
    if self.userdata.learned_skills[skill_id] then
        return false, "已学习过该技能"
    end
    self.userdata.learned_skills[skill_id] = true
    return true
end

function Musha_Profession_Component:HasSkill(skill_id)
    return self.userdata.learned_skills and self.userdata.learned_skills[skill_id] == true
end

function Musha_Profession_Component:UseSkillPoint()
    if not self.userdata.skill_points or self.userdata.skill_points <= 0 then
        return false
    end
    self.userdata.skill_points = self.userdata.skill_points - 1
    return true
end

function Musha_Profession_Component:OnSave()
    return {
        userdata = self.userdata,
        warrior = {
            combat_recovery = {
                current_level = self.warrior.combat_recovery.current_level or 0
            },
            weapon_proficiency = {
                current_level = self.warrior.weapon_proficiency.current_level or 0
            }
        },
        saber = {
            hit = {
                current_level = self.saber.hit.current_level or 0
            },
            stealing_life = {
                current_level = self.saber.stealing_life.current_level or 0
            }
        },
        guardian = {
            iron_will = {
                current_level = self.guardian.iron_will.current_level or 0
            },
            life_leech = {
                current_level = self.guardian.life_leech.current_level or 0
            }
        },
        class_traits = {
            saber = { current_hunt_bonus = self.class_traits.saber.current_hunt_bonus or 0 }
        }
    }
end

function Musha_Profession_Component:OnLoad(data)
    if data then
        if data.userdata then
            self.userdata = data.userdata
        end

        if data.warrior then
            if data.warrior.combat_recovery then
                self.warrior.combat_recovery.current_level = data.warrior.combat_recovery.current_level or 0
            end
            if data.warrior.weapon_proficiency then
                self.warrior.weapon_proficiency.current_level = data.warrior.weapon_proficiency.current_level or 0
            end
        end

        if data.saber then
            if data.saber.hit then
                self.saber.hit.current_level = data.saber.hit.current_level or 0
            end
            if data.saber.stealing_life then
                self.saber.stealing_life.current_level = data.saber.stealing_life.current_level or 0
            end
        end
        
        if data.guardian then
            if data.guardian.iron_will then
                self.guardian.iron_will.current_level = data.guardian.iron_will.current_level or 0
            end
            if data.guardian.life_leech then
                self.guardian.life_leech.current_level = data.guardian.life_leech.current_level or 0
            end
        end

        if data.class_traits and data.class_traits.saber then
            self.class_traits.saber.current_hunt_bonus = data.class_traits.saber.current_hunt_bonus or 0
        end

        self:UpdateExpToNext()
        self:UpdateCharacterStats()  -- 使用新的统一函数
    end
end

function Musha_Profession_Component:OnRemoveFromEntity()
    self.inst:RemoveEventCallback("killedother", OnKilledOther)
    self.inst:RemoveEventCallback("losttarget", OnLostTarget)
    self.inst:RemoveEventCallback("unlockrecipe", OnRecipeLearned)
    self.inst:RemoveEventCallback("onattackother", OnAttackOther)
    self.inst:RemoveEventCallback("attacked", GetAttacked)
    self.inst:StopWatchingWorldState("startday", NewDay)

    if self.healthtask then
        self.healthtask:Cancel()
        self.healthtask = nil
    end
    
    if self.task then
        self.task:Cancel()
        self.task = nil
    end
    
    -- 清理所有应用的效果
    local player = self.inst
    if player.components.health then
        player.components.health.externalabsorbmodifiers:RemoveModifier(player, "warrior_base_defense")
        player.components.health.externalabsorbmodifiers:RemoveModifier(player, "guardian_iron_will")
    end
    
    if player.components.combat and player.components.combat.externaldamagemultipliers then
        player.components.combat.externaldamagemultipliers:RemoveModifier(player, "warrior_weapon_proficiency")
        player.components.combat.externaldamagemultipliers:RemoveModifier(player, "guardian_life_leech")
        player.components.combat.externaldamagemultipliers:RemoveModifier(player, "saber_hunt_bonus")
    end
end

function Musha_Profession_Component:GetDebugString()
    local carrer_info = self:GetCarrerInfo()
    local exp_info = self:GetExpInfo()

    local skill_count = 0
    for _, skill_tree in pairs({self.warrior, self.saber, self.guardian}) do
        for skill_name, skill_data in pairs(skill_tree) do
            if skill_data.current_level and skill_data.current_level > 0 then
                skill_count = skill_count + 1
            end
        end
    end

    -- 添加经验统计
    local exp_stats = self:GetExperienceStats()

    return string.format(
        "Lv%d 经验:%d/%d 总经验:%d 职业:%s|%s 技能点:%d 已学技能:%d", 
        exp_info.level, 
        exp_info.exp, 
        exp_info.exp_to_next + exp_info.exp, 
        exp_stats.total_exp,
        carrer_info.base or "无", 
        carrer_info.special or "无",
        self.userdata.skill_points, 
        skill_count
    )
end

-- 经验获取统计功能
function Musha_Profession_Component:GetExperienceStats()
    return {
        total_exp = self.userdata.total_exp or 0,
        level = self.userdata.level or 0,
        exp_to_next = self.userdata.exp_to_next or 0,
        skill_points = self.userdata.skill_points or 0
    }
end

-- 调试函数：显示经验信息
function Musha_Profession_Component:ShowExperienceInfo()
    local stats = self:GetExperienceStats()

    if self.inst.components.talker then
        self.inst.components.talker:Say(string.format(
            "Lv%d 经验:%d/%d 技能点:%d 总经验:%d", 
            stats.level,
            self.userdata.exp or 0, 
            stats.exp_to_next + (self.userdata.exp or 0), 
            stats.skill_points, 
            stats.total_exp
        ))
    end
end

-- Musha_Profession_Component
-- 旧版完整职业系统组件
--
-- 职责：职业特性应用（战士防御/剑士猎杀/近卫铁壁/技能树）+ 击杀经验/配方经验/每日经验
-- 等级上限 30 级，exp_table 自定义公式，技能树等级按职业区分
--
-- 注意：musha_playerdata 是独立的新版精简数据层，有另一套 exp/level 体系（20级）
--   两者数据不互通，各自维护自己的经验/等级
--   击杀事件 killedother 已挂在此组件（第463行）
--   配方解锁事件 unlockrecipe 已挂在此组件（第464行）
--   每日生存事件 startday 已挂在此组件（第467行）
-- ====================================

return Musha_Profession_Component