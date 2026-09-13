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

-- ====================================
-- 战斗恢复（战士 combat_recovery）—— 常驻回血 tick
--   2026-09-12 用户要求："脱离战斗后回血应当一直保持，写个task"
--   原来：OnLostTarget 里起 DoPeriodicTask、OnAttackOther/GetAttacked 里 Cancel()
--         → 被打一下就 Cancel，而"丢目标"事件不一定再来 → 回血再也起不来（永久停）
--   现在：组件构造时起一个**常驻 tick**（每秒），自己判断能不能回血 → 永远不会永久停
--   条件：服务端 + 战士 + 技能等级>0 + 没死 + 未满血 + 当前没有攻击目标
--         + 距上次交手 > REGEN_COMBAT_GRACE 秒（"还在战斗中"不回血）
-- ====================================
local REGEN_TICK         = 1    -- 每几秒回一次
local REGEN_COMBAT_GRACE = 3    -- 距上次攻击/被攻击多少秒内算"还在战斗"

-- ★ 2026-09-12 剑士「背水一战」参数（用户拍板：触发方式 = a 被动自动；限流 = 冷却 80 秒）
local LAST_STAND_COOLDOWN  = 80    -- 冷却（秒）
local LAST_STAND_THRESHOLD = 0.5   -- 触发血线（血量 ≤50%）

local function OnLostTarget(inst, data)
    local self = inst.components.musha_profession_component
    if not self then
        return
    end

    -- 战士"战斗恢复"已改成常驻 tick（见 CombatRecoveryTick），这里不再起任务

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

    -- 交手打点：战斗恢复常驻 tick 靠它判断"还在战斗中"（2026-09-12）
    -- 原来是 Cancel 掉回血任务，但没人再起回来 → 回血永久停
    self.last_combat_time = GetTime()
    
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
    
    -- 交手打点：战斗恢复常驻 tick 靠它判断"还在战斗中"（2026-09-12）
    -- 原来是 Cancel 掉回血任务，但没人再起回来 → 回血永久停
    self.last_combat_time = GetTime()
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
    -- ❌ 2026-09-13 用户拍板摘掉两条：
    --   · 「命中强化」意义不存在（**DST 没有命中率，攻击必中** → +命中% 是空数值）
    --   · 「吸血」战士/剑士不该有（跟近卫的「生命偷取 life_leech」功能重复，违反"技能不重叠"）
    --   两条都**没有任何消费方实现**（全项目只有定义/存档引用）→ 摘掉不影响其它系统
    --   数据留在注释里备查：
    --   hit = { current_level = 0, max_level = 4,
    --           level_effects = { [1]=0.10, [2]=0.20, [3]=0.30, [4]=0.40 },
    --           unlock_requirements = { [1]=7, [2]=9, [3]=12, [4]=16 } },
    --   stealing_life = { current_level = 0, max_level = 4,
    --           level_effects = { [1]=0.023, [2]=0.054, [3]=0.086, [4]=0.114 },
    --           unlock_requirements = { [1]=4, [2]=7, [3]=11, [4]=15 } },
    self.saber = {
        -- ★ 2026-09-12 新增（用户）：剑士专属「背水一战」
        --   血量 ≤50% 被动自动回满；7 级可学、消耗 3 个技能点；冷却 80 秒（见 LastStandTick）
        last_stand = {
            current_level = 0,
            max_level = 1,
            level_effects = {
                [1] = 1          -- 1 = 可触发（回满血）；触发限流走冷却 80 秒
            },
            unlock_requirements = {
                [1] = 7          -- 7 级可学
            },
            skill_point_cost = {
                [1] = 3          -- 消耗 3 技能点（GetSkillView 里 cost 就是读它）
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
    
    -- 刺客技能树
    self.rogue = {
        backstab = {
            current_level = 0,
            max_level = 2,
            level_effects = {
                [1] = 2.0,  -- 2倍伤害
                [2] = 3.0,  -- 3倍伤害
            },
            skill_point_cost = {
                [1] = 2,   -- 2技能点
                [2] = 4,   -- 4技能点
            },
            unlock_requirements = {
                [1] = 1,   -- 1级可学
                [2] = 5,   -- 5级可升2级
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
    self.healthtask = nil        -- 战斗恢复常驻 tick 句柄（OnRemoveFromEntity 里 Cancel）
    self.task = nil
    self.last_combat_time = nil  -- 上次攻击/被攻击时间（脱战判定用）
    self.last_stand_cd = nil     -- 背水一战冷却结束时间（GetTime() 绝对时间，2026-09-12）

    -- 战斗恢复常驻 tick（2026-09-12）：每秒自检，脱战后一直回血
    --   注意：这里只是起任务，实际回血条件在 CombatRecoveryTick 里判断
    --   2026-09-12 起：同一个 1 秒 tick 顺带跑剑士「背水一战」判定（LastStandTick）
    self.healthtask = self.inst:DoPeriodicTask(REGEN_TICK, function()
        self:CombatRecoveryTick()
        self:LastStandTick()
    end)

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

-- ====================================
-- 战斗恢复常驻 tick（必须定义在 Class 之后！Class 之前 Musha_Profession_Component 还是 nil）
--   条件：服务端 + 战士 + 技能等级>0 + 活着 + 未满血 + 没有攻击目标 + 距上次交手 > 宽限期
-- ====================================
function Musha_Profession_Component:CombatRecoveryTick()
    if not TheWorld or not TheWorld.ismastersim then return end
    if not self.userdata or self.userdata.carrer_base ~= "warrior" then return end

    local cr = self.warrior and self.warrior.combat_recovery
    local lvl = (cr and cr.current_level) or 0
    if lvl <= 0 then return end

    local heal = (cr.level_effects and cr.level_effects[lvl]) or 0
    if heal <= 0 then return end

    -- 战斗中不回血：有攻击目标 或 刚交手过
    local combat = self.inst.components.combat
    if combat and combat.target then return end
    if self.last_combat_time and (GetTime() - self.last_combat_time) < REGEN_COMBAT_GRACE then
        return
    end

    local hp = self.inst.components.health
    if not hp or hp:IsDead() then return end
    if hp:GetPercent() >= 1 then return end   -- 满血不回，省掉每秒一次的 healthdelta 事件

    hp:DoDelta(heal)
end

-- ====================================
-- 剑士「背水一战」last_stand（2026-09-12）
--   触发方式：a 被动自动（用户拍板）—— 血量 ≤50% 时服务端直接回满，玩家不用按键
--   限流：冷却 80 秒（LAST_STAND_COOLDOWN），不是"一辈子一次"
--   条件：服务端 + 剑士 + 技能等级>0 + 活着 + 血量 ≤50% + 冷却已好
-- ====================================
function Musha_Profession_Component:LastStandTick()
    if not TheWorld or not TheWorld.ismastersim then return end
    if not self.userdata or self.userdata.carrer_special ~= "saber" then return end

    local sk = self.saber and self.saber.last_stand
    local lvl = (sk and sk.current_level) or 0
    if lvl <= 0 then return end

    local hp = self.inst.components.health
    if not hp or hp:IsDead() then return end
    if hp:GetPercent() > LAST_STAND_THRESHOLD then return end   -- 没到 50% 不管

    local now = GetTime()
    if self.last_stand_cd and now < self.last_stand_cd then return end   -- 冷却中

    self.last_stand_cd = now + LAST_STAND_COOLDOWN

    -- 回满血
    hp:SetPercent(1)

    -- 表现：字幕 + 事件（特效/音效素材等用户画好再接，位置留在这里）
    if self.inst.components.talker then
        self.inst.components.talker:Say("我，活着！")
    end
    self.inst:PushEvent("musha_last_stand", { cooldown = LAST_STAND_COOLDOWN })

    -- 把冷却推给客户端（技能冷却 UI 用）
    self:PushSettings()
end

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
    self:PushSettings()         -- 技能页要换树（2026-09-12）
    return true
end

function Musha_Profession_Component:SetCarrerSpecial(carrer)
    if not carrer or carrer == "" then
        return false
    end
    self.userdata.carrer_special = carrer
    self:ApplyProfessionData()  -- 应用新职业的效果
    self:PushSettings()         -- 技能页要换树（2026-09-12）
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

    -- 局内设置：经验倍率（世界级）
    -- 注意：组件文件 env 没有 GLOBAL，strict 会报"variable 'GLOBAL' is not declared"，
    -- 所以这里用裸 TheWorld（同 musha_skillui.lua:140 的写法）
    local w = TheWorld
    local ws = w and w.components and w.components.musha_world_settings
    if ws then
        local mult = ws:Get("exp_mult") or 1
        if mult ~= 1 then
            amount = math.max(1, math.floor(amount * mult + 0.5))
        end
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

    -- 升级会发技能点、也可能正好跨过技能解锁等级 → 推一次面板数据（技能页要刷新）
    if levels_gained > 0 then
        self:PushSettings()
    end

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

    -- 检查技能点（支持自定义每级消耗）
    -- 🐛 2026-09-12 修：原来这里漏了 next_level（只在上面 CanUpgradeSkill 里算过），
    --    skill_point_cost[nil] 读出来恒 nil → 自定义消耗从来没生效（背刺 2/4 点一直按 1 点算）
    local next_level = skill.current_level + 1
    local cost = 1
    if skill.skill_point_cost and skill.skill_point_cost[next_level] then
        cost = skill.skill_point_cost[next_level]
    end
    if self.userdata.skill_points < cost then
        if self.inst.components.talker then
            self.inst.components.talker:Say(STRINGS.MUSHA_SKILL_NEED_SKILL_POINTS or
                                                string.format("技能点不足 (需要%d点)", cost))
        end
        return false, "技能点不足"
    end

    -- 消耗技能点
    self.userdata.skill_points = self.userdata.skill_points - cost

    -- 升级技能
    skill.current_level = skill.current_level + 1

    local new_level = skill.current_level
    local new_effect = skill.level_effects[new_level] or 0

    -- 应用新效果
    self:ApplyProfessionData()

    -- 推面板（技能页等级/可加点状态要跟着变）
    self:PushSettings()

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

-- ====================================
-- 技能树 → 面板显示数据（2026-09-12 新增）
--   技能树本身只有数字（current_level / level_effects / unlock_requirements），
--   技能名 + 描述文本在这里补，服务端组装成字符串后随 userdata 一起推给客户端
--   （客户端 replica 没有技能树数据，所以文案必须服务端生成）
-- ====================================

-- 显示顺序（按解锁等级排）
local SKILL_ORDER = {
    warrior  = { "combat_recovery", "weapon_proficiency" },
    saber    = { "last_stand" },   -- 2026-09-13：命中强化/吸血 摘掉（见上方注释）
    guardian = { "iron_will", "life_leech" },
    rogue    = { "backstab" },
}

-- fmt(v) 把 level_effects 的数值翻译成人话
local SKILL_UI = {
    warrior = {
        combat_recovery = {
            name = "战斗恢复",
            fmt  = function(v) return string.format("脱离战斗后每秒回复 %.2f 点生命", v) end,
            tip  = "常驻生效；交手中暂停（脱战 3 秒后继续）",
        },
        weapon_proficiency = {
            name = "武器精通",
            fmt  = function(v) return string.format("武器伤害 +%.0f%%", v * 100) end,
        },
    },
    saber = {
        -- ❌ 2026-09-13 摘掉：命中强化（DST 无命中率，数值无意义）、吸血（与近卫生命偷取重复）
        -- hit           = { name = "命中强化", fmt = function(v) return string.format("命中效果 +%.0f%%", v * 100) end },
        -- stealing_life = { name = "吸血",     fmt = function(v) return string.format("攻击吸血 %.1f%%", v * 100) end },
        -- ★ 2026-09-12 新增（用户）：剑士专属，血量 ≤50% 被动自动回满 / 冷却 80 秒 / 7 级 / 3 技能点
        last_stand    = {
            name = "我，活着",
            fmt  = function(v) return string.format("血量低于 50%% 时被动回满生命（冷却 %d 秒）", LAST_STAND_COOLDOWN) end,
            tip  = "7 级可学 · 消耗 3 技能点 · 无需按键，自动触发",
        },
    },
    guardian = {
        iron_will  = { name = "钢铁意志", fmt = function(v) return string.format("额外减伤 %.0f%%", v * 100) end },
        life_leech = { name = "生命偷取", fmt = function(v) return string.format("伤害转化治疗 %.0f%%", v * 100) end },
    },
    rogue = {
        backstab = { name = "背刺", fmt = function(v) return string.format("背刺造成 %.0f 倍伤害", v) end },
    },
}

-- 组装"当前职业技能页"的数据（给客户端面板用）
--   ★ 2026-09-12 改：原来只读 carrer_base 那一棵树 → 二转后技能页还是显示基础职业的技能；
--     现在 **基础树 + 二转树都进面板**（用户："3全部都可"）。每条带 tree_kind 便于客户端区分。
function Musha_Profession_Component:GetSkillView()
    local trees = {}
    local base = self.userdata.carrer_base
    local spec = self.userdata.carrer_special
    if base and self[base] then
        table.insert(trees, { key = base, kind = "base" })
    end
    if spec and spec ~= "" and self[spec] and spec ~= base then
        table.insert(trees, { key = spec, kind = "special" })
    end
    if #trees == 0 then return {} end

    local function TreeNodeName(tree)
        local ok, s = pcall(function() return STRINGS["MUSHA_JOB_" .. string.upper(tree or "")] end)
        if ok and type(s) == "string" and s ~= "" then return s end
        return tree
    end

    local out = {}
    for _, t in ipairs(trees) do
        local tree = t.key
        local order = SKILL_ORDER[tree]
        local defs = SKILL_UI[tree]
        if order then
            for _, key in ipairs(order) do
                local skill = self[tree][key]
                if skill then
                    local info = self:GetSkillInfo(tree, key) or {}
                    local cur = skill.current_level or 0
                    local nxt = cur + 1
                    local d = defs and defs[key] or nil
                    local maxlv = skill.max_level or 0

                    local cost = 1
                    if skill.skill_point_cost and skill.skill_point_cost[nxt] then
                        cost = skill.skill_point_cost[nxt]
                    end

                    local entry = {
                        id     = tree .. "_" .. key,
                        tree   = tree,
                        kind   = t.kind,                        -- base / special
                        tree_name = TreeNodeName(tree),         -- 显示用（战士 / 剑士 …）
                        key    = key,
                        name   = (d and d.name) or key,
                        tip    = d and d.tip or nil,
                        cur    = cur,
                        max    = maxlv,
                        maxed  = cur >= maxlv,
                        req    = info.requirement or 0,
                        cost   = cost,
                        points = self.userdata.skill_points or 0,
                        lv     = self.userdata.level or 0,
                        effect = (d and d.fmt) and d.fmt(skill.level_effects and skill.level_effects[cur] or 0) or "",
                        nextfx = (d and d.fmt) and d.fmt(skill.level_effects and skill.level_effects[nxt] or 0) or "",
                    }
                    entry.can = (not entry.maxed) and entry.points >= entry.cost and entry.lv >= entry.req
                    table.insert(out, entry)
                end
            end
        end
    end
    return out
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
    -- 刺客技能树
    for name, skill in pairs(self.rogue) do
        if skill.current_level and skill.current_level > 0 then
            levels["rogue_" .. name] = skill.current_level
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

-- 获取职业名称（需要 STRINGS）
function Musha_Profession_Component:GetJobName()
    if not self.userdata.carrer_base then return "无职业" end
    local name_key = "MUSHA_JOB_" .. string.upper(self.userdata.carrer_base)
    if STRINGS[name_key] then
        return STRINGS[name_key]
    end
    return self.userdata.carrer_base
end

function Musha_Profession_Component:GetAdvanceJobName()
    if not self.userdata.carrer_special then return nil end
    local name_key = "MUSHA_JOB_" .. string.upper(self.userdata.carrer_special)
    if STRINGS[name_key] then
        return STRINGS[name_key]
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

    -- 给予一转技能书（统一图标样式 musha_skillbook）
    -- 原 skillbook_map 的 6 个进阶书 prefab（musha_skillbook_swordsman 等）从未注册，
    -- SpawnPrefab 返回 nil 导致一转完成永远不发书。
    local book = SpawnPrefab("musha_skillbook")
    if book and self.inst.components.inventory then
        self.inst.components.inventory:GiveItem(book)
    end

    -- 推送进阶结果给客户端面板（2026-09-08 补：原来不发，面板不刷新）
    -- 2026-09-12：改成整包推（userdata + 设置 + 技能页），走同一个 PushSettings 通道
    pcall(function() self:PushSettings() end)

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
            -- 2026-09-13：hit / stealing_life 已摘除，不再存档（旧档里这两项会被忽略）
            -- ★ 2026-09-12 新增：背水一战（不写这里会存不上档 → 重进游戏技能等级归零）
            last_stand = {
                current_level = self.saber.last_stand and self.saber.last_stand.current_level or 0,
                cd_end = self.last_stand_cd or nil   -- 背水一战冷却结束时间（2026-09-12：仅1次 改 80 秒冷却）
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
        rogue = {
            backstab = {
                current_level = self.rogue.backstab.current_level or 0
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
            -- 2026-09-13：hit / stealing_life 已摘除，旧档里的这两项直接丢掉
            -- ★ 2026-09-12 新增：背水一战（等级 + 冷却结束时间）
            if data.saber.last_stand then
                if self.saber.last_stand == nil then
                    self.saber.last_stand = { current_level = 0, max_level = 1, level_effects = { [1] = 1 }, unlock_requirements = { [1] = 7 }, skill_point_cost = { [1] = 3 } }
                end
                self.saber.last_stand.current_level = data.saber.last_stand.current_level or 0
                -- 2026-09-12：冷却结束时间（GetTime() 绝对时间）；旧存档的 used 字段直接丢弃
                self.last_stand_cd = data.saber.last_stand.cd_end or nil
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

        if data.rogue then
            if data.rogue.backstab then
                self.rogue.backstab.current_level = data.rogue.backstab.current_level or 0
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
    for _, skill_tree in pairs({self.warrior, self.saber, self.guardian, self.rogue}) do
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

-- ====================================
-- 局内设置（2026-09-10 新增）
--   世界级 → TheWorld.components.musha_world_settings（惰性补挂）
--   玩家级 → self.inst.components.musha_player_settings
--   同步   → 把设置快照塞进 userdata 的**副本**，复用已有的 DoUpdata 推送
--            （不改 self.userdata，所以存档里不会多出 settings 字段）
-- ====================================

local function EnsureWorldSettings()
    -- 组件 env 无 GLOBAL，用裸 TheWorld（strict 会拦 GLOBAL）
    local w = TheWorld
    if not w or not w.ismastersim then return nil end
    if not w.components.musha_world_settings then
        local ok = pcall(function() w:AddComponent("musha_world_settings") end)
        if not ok then return nil end
    end
    return w.components.musha_world_settings
end

local function PlayerIsAdmin(player)
    if not player or not player.Network then return false end
    local ok, admin = pcall(function() return player.Network:IsServerAdmin() end)
    return (ok and admin == true)
end

-- 组装给客户端的设置快照
function Musha_Profession_Component:GetSettingsView()
    local view = { world = {}, player = {}, can_edit = false }

    local ws = EnsureWorldSettings()
    if ws then view.world = ws:Get() end

    local ps = self.inst.components.musha_player_settings
    if ps then view.player = ps:Get() end

    view.can_edit = PlayerIsAdmin(self.inst)
    return view
end

-- 把设置快照推给客户端（复用职业数据的推送通道）
function Musha_Profession_Component:PushSettings()
    if not self.inst.replica or not self.inst.replica.musha_profession_component then
        return false
    end
    local d = {}
    for k, v in pairs(self.userdata) do
        d[k] = v
    end
    d.settings = self:GetSettingsView()
    d.skills   = self:GetSkillView()   -- 技能页数据（2026-09-12 新增，和设置共用一条推送通道）
    d.gifts    = self.userdata.gifts or {}   -- 礼包页：已领过的 id 表（2026-09-12）

    -- ★ 2026-09-12 技能冷却数据（给「技能冷却 UI」用）
    --   ⚠️ remain 只是"这次推送那一刻"的剩余秒数，不是实时的：
    --     客户端要做实时倒计时得自己按本地时间倒数（或走 RPC），别拿 remain 当每帧真值
    d.cooldowns = {
        last_stand = {
            total  = LAST_STAND_COOLDOWN,
            end_at = self.last_stand_cd or 0,
            remain = math.max(0, (self.last_stand_cd or 0) - GetTime()),
        },
    }
    local ok = pcall(function()
        self.inst.replica.musha_profession_component:DoUpdata(d)
    end)
    return ok
end

-- 改一项设置。scope = "world" | "player"
--   世界级：需要房主/管理员
--   玩家级：改自己的，不需要权限
function Musha_Profession_Component:SetMushaSetting(scope, key, value, player)
    player = player or self.inst

    local target
    if scope == "world" then
        if not PlayerIsAdmin(player) then
            return false, "no_permission"
        end
        target = EnsureWorldSettings()
    elseif scope == "player" then
        target = self.inst.components.musha_player_settings
    else
        return false, "bad_scope"
    end

    if not target then
        return false, "no_component"
    end

    local ok, reason = target:Set(key, value)
    if not ok then
        return false, reason
    end

    self:PushSettings()
    return true
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