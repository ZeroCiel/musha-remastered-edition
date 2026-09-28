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
    -- ★ 2026-09-16 同一类 bug：current_hunt_bonus 是"加成"（每层 +0.1，上限 1.5 = +150%），
    --   SetModifier 要倍率 → 原来传 0.1 会把伤害打到 10%（越猎越弱）。这里 +1 换算。
    player.components.combat.externaldamagemultipliers:SetModifier(player, 1 + saber_traits.current_hunt_bonus,
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
    
    -- ★★ 2026-09-18 删除：这里原来还有一份【近卫生命偷取】实现（按 data.damage × level_effects 回血），
    --   和构造函数里 2026-09-16 新写的 `onhitother` 监听**同一件事做了两遍** → 攻击一次回两次血。
    --   保留的是 onhitother 那份（口径正确：攻击后按伤害比例回血，走 health:DoDelta(..., "guardian_life_leech")）。
    --   原来那段下面还挂着"这个有问题 我记得改成了荆棘伤害"的备注 —— 荆棘/反击（设定 #9 反击 25% 所受伤害）
    --   是**另一条还没做的机制**（P3 一起做），跟生命偷取不是一回事，别混。

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
        -- ★★ 2026-09-18 进阶方向选择（两本徽记，用户拍板）：
        advance_crest_bind = nil,     -- 本次选择用的绑定 ID（发徽记时生成，两枚共用）
        advance_crest_used = nil,     -- 已用掉的绑定 ID（用掉一枚后记下；另一枚靠校验作废）
        advance_choice_pending = false, -- 已发徽记、还没选方向（面板显示两棵树打锁）
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
        -- ★ 2026-09-14 用户拍板：剑气斩「改为加点学习」——
        --   3 级、解锁门槛 = 角色 3 / 7 / 12 级，每级 1 技能点；
        --   level_effects 存的是【每次施放消耗的能量】：18 → 16 → 14（等级越高越省）
        --   ⚠️ 没学过（current_level = 0）→ 右键不给放（musha_weapon_skill.DoCast 里卡）
        --   ⚠️ 存档：OnSave/OnLoad 都要带上它（漏了会每次重进游戏等级归零）
        slash_qi = {
            current_level = 0,
            max_level = 3,
            level_effects = {
                [1] = 18,
                [2] = 16,
                [3] = 14
            },
            unlock_requirements = {
                [1] = 3,
                [2] = 7,
                [3] = 12
            },
            skill_point_cost = {
                [1] = 1,
                [2] = 1,
                [3] = 1
            }
        },

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

    -- ★★ 2026-09-16 生命偷取（近卫）改成正确口径：**攻击后按伤害比例回血**
    --   用户确认："生命偷取应该是攻击后回复生命，不走那个（伤害乘区）"
    --   原来错挂在 externaldamagemultipliers:SetModifier(0.05) → 近卫伤害直接被压到 5%（已删）。
    --   onhitother 的 data 里带 damage（combat.lua:698）→ 直接按 level_effects 的百分比回血。
    self.inst:ListenForEvent("onhitother", function(inst2, data)
        local self2 = inst2.components ~= nil and inst2.components.musha_profession_component or nil
        if self2 == nil or self2.userdata == nil then return end
        if self2.userdata.carrer_special ~= "guardian" then return end
        local ll = self2.guardian ~= nil and self2.guardian.life_leech or nil
        if ll == nil or (ll.current_level or 0) <= 0 then return end
        local effect = ll.level_effects[ll.current_level]
        local dmg = data ~= nil and data.damage or nil
        if effect == nil or dmg == nil or dmg <= 0 then return end
        local health = inst2.components.health
        if health ~= nil and not health:IsDead() then
            health:DoDelta(dmg * effect, false, "guardian_life_leech")
        end
    end)

    -- ====================================
    -- ★★ 2026-09-20 近卫盾（对照表 #1）：MP 代替护盾
    --   用户拍板走 **redirect**（盾优先）—— 符合设定原文「被攻击先扣盾」。
    --   原版结算链（实测读码）：
    --     combat.lua:611 inventory:ApplyDamage（护甲吸收）
    --     combat.lua:648 health:DoDelta(-damage)
    --        health.lua:623 redirect        ← 本钩子（在吸收之前）
    --        health.lua:628 externalabsorbmodifiers ← 钢铁意志那 0.4 在这
    --   → 语义：盾先吃【护甲/减伤前的原始伤害】(1:1 扣 MP)；盾不够时余量回灌、
    --     才轮到钢铁意志减伤；盾为 0 时完全走正常流程。
    --   ⚠️ 坑 1：余量回灌会再次进 redirect → 用 _in_shield_redirect 重入标志位防无限递归。
    --   ⚠️ 坑 2：只挡【有攻击者 afflicter】的伤害 —— 饥饿/过热/跌落这类 afflicter == nil 一律放过，
    --            否则近卫会被自己的饥饿值吃掉盾。
    --   ⚠️ 坑 3：无敌/传送中要放过（原版 :625 那个检查在 redirect **之后**，钩子里必须自己判）。
    --   ⚠️ 坑 4：ignore_absorb 的真实伤害同样穿透盾（与原版「穿透吸收」语义保持一致）。
    --   数值真源 = class_traits.guardian（mp_base 240 / mp_max_growth 3 / mp_regen 1.2），
    --   盾量就是 musha_mp.current，所以现有能量徽章不用改就能显示盾。
    -- ====================================
    if self.inst.components.health then
        self.inst.components.health.redirect = function(inst2, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
            local self2 = inst2.components ~= nil and inst2.components.musha_profession_component or nil
            if self2 == nil or self2.userdata == nil then return false end
            if self2._in_shield_redirect then return false end                  -- 重入保护：余量回灌不再吃盾
            if self2.userdata.carrer_special ~= "guardian" then return false end -- 只有近卫有盾
            if (amount or 0) >= 0 then return false end                         -- 治疗/回血放过
            if afflicter == nil then return false end                           -- 非实体攻击（饥饿/过热/跌落）放过
            if ignore_absorb then return false end                              -- 真实伤害穿透盾
            local hp2 = inst2.components.health
            if not ignore_invincible and (hp2:IsInvincible() or inst2.is_teleporting) then return false end

            local mp = inst2.components.musha_mp
            if mp == nil or (mp.current or 0) <= 0 then return false end        -- 没盾了，走正常流程

            local dmg = -amount
            local absorbed = math.min(dmg, mp.current)
            mp:DoDelta(-absorbed)                                               -- 盾 = MP，1:1 扣

            local rest = dmg - absorbed
            if rest > 0.01 then                                                 -- 盾碎了，余量回灌（会走钢铁意志）
                self2._in_shield_redirect = true
                hp2:DoDelta(-rest, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
                self2._in_shield_redirect = false
            end

            -- 给反击（#9）/ 盾碎表现留的接口：absorbed=盾吃掉多少，rest=漏到血上多少
            inst2:PushEvent("musha_shield_hit", {
                absorbed = absorbed, rest = rest, attacker = afflicter, broken = rest > 0.01,
            })
            return true                                                         -- 本次 DoDelta 到此结束
        end
    end

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
                    -- ★★ 2026-09-16 修「剑气斩只有 20 伤害」真凶：SetModifier 要的是**倍率**
                    --   （原版例子 mermking_gear_buffs.lua 传 1.05），不是加成值本身！
                    --   原来传 0.48 → 伤害被乘 0.48（42 × 0.48 = 20.2，日志实测），越精通越弱。
                    --   level_effects 存的仍是"加成"（0.30/0.48/0.63 = +30/48/63%），这里 +1 换算。
                    player.components.combat.externaldamagemultipliers:SetModifier(
                        player, 1 + effect, "warrior_weapon_proficiency"
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
            -- ★★ 2026-09-18 修口径（照原版 data/databundles/scripts/components/health.lua:628 实测）：
            --   externalabsorbmodifiers 存的是**吸收比例**（伤害 ×(1 − 总吸收)，且是 SourceModifierList.additive
            --   累加列表），**不是"受伤倍率"**（这跟 externaldamagemultipliers 语义相反，别混）。
            --   ⚠️ 战士基础防御 0.25 已经在本函数第 1 步按 carrer_base == "warrior" 挂过
            --   （`warrior_base_defense`，近卫的基础职业就是 warrior，所以一定在）→ 这里**只能再加钢铁意志自己那部分**。
            --   原来写 `0.25 + level_effects` → 累加后变成 0.25+0.30 = 0.55（Lv3 = 0.65）
            --   → 这就是排期文档里记的"实际减伤 60~75%"的根因。
            --   修正后总吸收 = 0.25 + 0.05 / 0.10 / 0.15 = 0.30 / 0.35 / 0.40
            --   （正好落回 class_traits.guardian.defense_max = 0.4 的设计上限）
            local effect = iw.level_effects[iw.current_level]
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
    
    -- 4. 生命偷取（仅近卫）—— ★ 2026-09-16 从这里**移走**了
    --    它原来把 level_effects（0.05/0.10/0.15/0.20）传给了 externaldamagemultipliers:SetModifier
    --    → 那是**伤害倍率**，等于近卫伤害被压到 5%（越学越弱）。
    --    现在正确实现 = 攻击后按伤害百分比回血（构造函数里的 onhitother 监听）。
    
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

-- ★ 2026-09-17 用户：「剑士的剑气斩改为技能书解锁，但二转后赠送（唯一例外）——其实是将 0 级设置为 1 级」
--   → 下表 = 各职业"可由技能书解锁"的主动技能；二转时把该技能 0 级直接置 1 级（省去第 1 级加点）
local BOOK_UNLOCK_SKILL = {
    saber = "slash_qi",     -- 剑气斩
}

-- ================================================================
-- ★ 2026-09-20 技能树布局（横排树 + 竖线前置）
--   x / y = 图标在树里的格坐标（x = 列，向右递增；y = 行，向下递增）
--   req   = 前置 { 前置技能key = 需要的最低等级 }
-- · 服务端 CanUpgradeSkill 读它拦「前置没学就想点」（防改包，客户端改包绕不过）
-- · 客户端 GetSkillView 把格坐标 + 前置达标情况一起推给面板 → 画连线 + 灰/亮
-- · 加新技能：这里补一行 + SKILL_ORDER 补一项 + SKILL_UI 补文案
--   （图标 = images/skill_icons/<icon>.png，清单在 scripts/musha_skill_icons.lua）
-- ================================================================
-- ⚠️ SKILL_ORDER / SKILL_UI 的真值在文件下面（约 975 / 991 行）定义。这里**前向声明**，
--   否则上面第 847 行的 CanUpgradeSkill 引用不到它们（Lua 局部变量必须先声明后引用）
local SKILL_ORDER
local SKILL_UI

local SKILL_TREE_POS = {
    warrior = {
        combat_recovery    = { x = 0, y = 0, req = {} },
        weapon_proficiency = { x = 1, y = 0, req = { combat_recovery = 1 } },
    },
    saber = {
        slash_qi   = { x = 0, y = 0, req = {} },
        last_stand = { x = 1, y = 0, req = { slash_qi = 1 } },
    },
    guardian = {
        iron_will  = { x = 0, y = 0, req = {} },
        life_leech = { x = 0, y = 1, req = { iron_will = 1 } },
    },
    rogue = {
        backstab   = { x = 0, y = 0, req = {} },
    },
}

function Musha_Profession_Component:SetCarrerSpecial(carrer)
    if not carrer or carrer == "" then
        return false
    end
    self.userdata.carrer_special = carrer
    -- ★ 2026-09-17 二转赠礼：改成一卷【技能卷轴】（右键展开 → 解锁本职业专属技能 Lv1）
    --   （原来这里直接调 GrantSkillLevel1 把 0 级置 1 级；要回去把 ADVANCE_GIFT_IS_SCROLL 改 false）
    self:GrantAdvanceGift(carrer)
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

    -- ★★ 2026-09-20 技能树前置（竖线）：前置技能没到等级 → 不能学
    --   客户端已经灰掉（GetSkillView 里的 pre_ok），这里再拦一道，防改包
    local tpos = SKILL_TREE_POS[skill_tree] and SKILL_TREE_POS[skill_tree][skill_name]
    if tpos and tpos.req then
        for pkey, need in pairs(tpos.req) do
            local pskill = self[skill_tree] and self[skill_tree][pkey]
            local plv = (pskill and pskill.current_level) or 0
            if plv < need then
                local pdef = SKILL_UI[skill_tree] and SKILL_UI[skill_tree][pkey]
                return false, string.format("需要先把「%s」学到 %d 级", (pdef and pdef.name) or pkey, need)
            end
        end
    end

    -- ★★ 2026-09-18 技能书锁（补漏）：0 级的"技能书解锁技"**不能用技能点买**
    --   原来只锁了面板显示（画小锁），服务端这道没写 → 花 1 点也能学 → 用户看到的
    --   "没有技能书学习，我也能直接看到这个技能（已解锁）"。判定必须放服务端（客户端改包绕不过）。
    if (skill.current_level or 0) == 0 and BOOK_UNLOCK_SKILL[skill_tree] == skill_name then
        return false, "需要一本技能书才能解锁"
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

    -- ★ 2026-09-14：广播给"挂在玩家身上的东西"——
    --   例：剑的右键瞄准圈要按"剑气斩学没学"开关（musha_sword 里 ListenForEvent 这个事件）
    self.inst:PushEvent("musha_skill_changed", { tree = skill_tree, name = skill_name, level = new_level })

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
SKILL_ORDER = {
    warrior  = { "combat_recovery", "weapon_proficiency" },
    -- 2026-09-13：命中强化/吸血 摘掉（见上方注释）；2026-09-14：剑气斩上架（加点学习，排在最前）
    saber    = { "slash_qi", "last_stand" },
    guardian = { "iron_will", "life_leech" },
    rogue    = { "backstab" },
}

-- fmt(v) 把 level_effects 的数值翻译成人话
--
-- ★ 2026-09-19 用户给齐了技能图标（128x128 PNG）→ 已铺到 `images/skill_icons/<技能id>.png`
--   · `icon` 字段就是文件名（不带扩展名）；技能树/技能页要画图标时按
--     `images/skill_icons/<icon>.xml` + `<icon>.tex` 取
--   · ⚠️ .tex/.xml 要用户用 Mod Tool 转；**没转好之前 UI 必须退回占位（灰块/纯文字），不许崩**
--   · 目前有图标的 6 个：combat_recovery / weapon_proficiency / slash_qi / last_stand / iron_will / life_leech
--     （backstab 还没有图 → 用别的图标或纯文字兜底）
SKILL_UI = {
    warrior = {
        combat_recovery = {
            name = "战斗恢复",
            icon = "combat_recovery",
            fmt  = function(v) return string.format("脱离战斗后每秒回复 %.2f 点生命", v) end,
            tip  = "常驻生效；交手中暂停（脱战 3 秒后继续）",
            -- ★ 2026-09-28 英文（GetSkillView 按界面语言挑 *_en）
            name_en = "Combat Recovery",
            fmt_en  = function(v) return string.format("Restores %.2f health per second while out of combat", v) end,
            tip_en  = "Always on; pauses during combat (resumes 3 s after leaving it)",
        },
        weapon_proficiency = {
            name = "武器精通",
            icon = "weapon_proficiency",
            fmt  = function(v) return string.format("武器伤害 +%.0f%%", v * 100) end,
            name_en = "Weapon Mastery",
            fmt_en  = function(v) return string.format("Weapon damage +%.0f%%", v * 100) end,
        },
    },
    saber = {
        -- ❌ 2026-09-13 摘掉：命中强化（DST 无命中率，数值无意义）、吸血（与近卫生命偷取重复）
        -- hit           = { name = "命中强化", fmt = function(v) return string.format("命中效果 +%.0f%%", v * 100) end },
        -- stealing_life = { name = "吸血",     fmt = function(v) return string.format("攻击吸血 %.1f%%", v * 100) end },
        -- ★ 2026-09-14 上架：剑气斩（加点学习，3 级；level_effects 存的是每次耗能量）
        slash_qi      = {
            name = "剑气斩",
            icon = "slash_qi",
            fmt  = function(v) return string.format("挥出月牙剑气，命中造成 100%% / 130%% / 160%% 武器伤害 · 每次消耗 %d 点能量", v) end,
            tip  = "解锁：二转赠送 Lv1（=技能书解锁，不花技能点）· Lv2/Lv3 在 7 / 12 级加点（伤害 100→130→160%，耗能量 18→16→14）· 装剑后右键释放",
            name_en = "Slash Qi",
            fmt_en  = function(v) return string.format("Sweeps a crescent blade wave for 100%% / 130%% / 160%% weapon damage · costs %d energy per cast", v) end,
            tip_en  = "Unlock: free Lv1 on second change (= skillbook unlock, no points) · Lv2/Lv3 at level 7 / 12 (damage 100→130→160%, energy 18→16→14) · right-click with a sword equipped",
        },
        -- ★ 2026-09-12 新增（用户）：剑士专属，血量 ≤50% 被动自动回满 / 冷却 80 秒 / 7 级 / 3 技能点
        last_stand    = {
            name = "我，活着",
            icon = "last_stand",
            fmt  = function(v) return string.format("血量低于 50%% 时被动回满生命（冷却 %d 秒）", LAST_STAND_COOLDOWN) end,
            tip  = "7 级可学 · 消耗 3 技能点 · 无需按键，自动触发",
            name_en = "I, Alive",
            fmt_en  = function(v) return string.format("Passively heals to full below 50%% health (cooldown %d s)", LAST_STAND_COOLDOWN) end,
            tip_en  = "Learnable at Lv7 · costs 3 skill points · no key needed, triggers automatically",
        },
    },
    guardian = {
        iron_will  = { name = "钢铁意志", icon = "iron_will",
            fmt = function(v) return string.format("额外减伤 %.0f%%", v * 100) end,
            name_en = "Iron Will",
            fmt_en  = function(v) return string.format("Extra damage reduction %.0f%%", v * 100) end },
        life_leech = { name = "生命偷取", icon = "life_leech",
            fmt = function(v) return string.format("伤害转化治疗 %.0f%%", v * 100) end,
            name_en = "Life Leech",
            fmt_en  = function(v) return string.format("Converts %.0f%% of damage dealt into healing", v * 100) end },
    },
    rogue = {
        backstab = { name = "背刺",
            fmt = function(v) return string.format("背刺造成 %.0f 倍伤害", v) end,
            name_en = "Backstab",
            fmt_en  = function(v) return string.format("Backstabs deal %.0f× damage", v) end },
    },
}

-- ====== 技能解锁（2026-09-17：技能书 / 二转赠送） ======

-- 把某个技能从 0 级免费提到 1 级（返回 true = 这次真的提上去了）
--   ★ 用户："省去1级加点，其实是将0级设置为1级"
function Musha_Profession_Component:GrantSkillLevel1(tree, skill_id)
    local t = self[tree]
    if not t or not t[skill_id] then
        return false
    end
    if (t[skill_id].current_level or 0) >= 1 then
        return false
    end
    t[skill_id].current_level = 1
    local nm = (SKILL_UI[tree] and SKILL_UI[tree][skill_id] and SKILL_UI[tree][skill_id].name) or skill_id
    if self.inst.components.talker then
        self.inst.components.talker:Say(string.format("技能解锁：%s Lv1", nm), 3)
    end
    print(string.format("[Musha] %s 免费解锁技能 %s → Lv1（技能书/二转赠送）", tostring(self.inst.prefab), tostring(skill_id)))
    return true
end

-- 技能书解锁入口（通用技能书右键使用 → 解锁本职业的"技能书解锁技"）
--   返回：ok(是否解锁成功), why("unlocked" 成功 / "already" 已解锁过 / "noskill" 本职业没这类技能)
function Musha_Profession_Component:UnlockSkillByBook()
    local spec = self.userdata.carrer_special
    if not spec or spec == "" then
        return false, "noskill"
    end
    local skill_id = BOOK_UNLOCK_SKILL[spec]
    if not skill_id then
        return false, "noskill"
    end
    if self:GrantSkillLevel1(spec, skill_id) then
        return true, "unlocked"
    end
    return false, "already"
end

-- ====== 用背包里的技能书解锁（2026-09-18 用户：「点加点和图片都可以打开的，
--          消耗物品栏里面的技能书；或者右键自行解锁」）======
--   入口：① 面板技能页 点【锁】或【+】→ RPC musha_skill_unlock ② 背包里右键那本书（各 prefab 自己的 OnUse）
--   两处最终都落到本函数：拿 1 本背包里的书 → 把 0 级的"技能书解锁技"提到 1 级 → 消耗掉那本
local SKILL_BOOK_PREFABS = {
    musha_skillbook       = true,   -- 通用技能书（一转给的）
    musha_skill_scroll    = true,   -- 通用技能卷轴（可制作/可掉落）
    musha_skillbook_saber = true,   -- 剑士技能书（二转赠礼）
}

-- 背包里有没有能用的技能书？返回那个物品（没有 = nil）
function Musha_Profession_Component:FindSkillBookItem()
    local inv = self.inst.components.inventory
    if inv == nil then return nil end
    return inv:FindItem(function(item)
        if item == nil or not item:IsValid() then return false end
        if SKILL_BOOK_PREFABS[item.prefab] then return true end
        -- 兜底：以后新增的书只要挂这两个 tag 之一，也认（不用回来改这里）
        return item:HasTag("musha_skillbook") or item:HasTag("musha_scroll")
    end)
end

-- 用背包里的技能书解锁某个技能（只针对"技能书解锁技"的 0 级；成功 = 消耗 1 本）
function Musha_Profession_Component:UnlockSkillWithItem(skill_tree, skill_name)
    local skill = self[skill_tree] and self[skill_tree][skill_name]
    if skill == nil then return false, "技能不存在" end
    if BOOK_UNLOCK_SKILL[skill_tree] ~= skill_name then
        return false, "这个技能不用技能书，直接加点就行"
    end
    if (skill.current_level or 0) >= 1 then
        return false, "已经解锁过了"
    end

    local book = self:FindSkillBookItem()
    if book == nil then
        return false, "需要一本技能书（背包里没有）"
    end

    if not self:GrantSkillLevel1(skill_tree, skill_name) then
        return false, "解锁失败"
    end
    -- 消耗一本（堆叠就只减 1）
    if book.components.stackable and book.components.stackable:StackSize() > 1 then
        book.components.stackable:Get(1):Remove()
    else
        if book:IsValid() then book:Remove() end
    end

    self:PushSettings()     -- 技能页等级/锁状态要跟着变
    return true, "已解锁"
end

-- ====== 二转赠礼（2026-09-17 用户：「A 我指的是剑气斩，二转完成应该给一本属于剑气斩的技能树」）======
--   默认 = 发**本职业的职业技能书**（剑士 = 剑士技能书，属于剑气斩那棵技能树；右键使用 → 解锁剑气斩 Lv1）
--   美术：ChatGPT 那张三本书里中间那本（SWORDSMAN）→ exported/musha_skillbook_saber/
--   物品本体：scripts/prefabs/musha_skillbook_saber.lua（tag=musha_panel → 右键"打开面板"那套动作）
--   其它两种模式（回退用）：
--     "scroll" = 通用技能卷轴（可制作/可掉落那件，scripts/prefabs/musha_skill_scroll.lua）
--     "level"  = 旧行为（直接 0→1 级，不送东西，用 GrantSkillLevel1）
local ADVANCE_GIFT_MODE = "career_book"

-- 各进阶职业对应的"职业技能书"（没进表的职业 → 退回通用技能卷轴）
local CAREER_BOOK = {
    saber = "musha_skillbook_saber",
}

function Musha_Profession_Component:GiveCareerBook(career)
    local prefab = CAREER_BOOK[career]
    if prefab == nil then return false end
    local inv = self.inst.components.inventory
    if inv == nil then return false end
    local book = SpawnPrefab(prefab)
    if book == nil then return false end
    inv:GiveItem(book)
    return true
end

function Musha_Profession_Component:GiveSkillScroll()
    local inv = self.inst.components.inventory
    if inv == nil then return false end
    local scroll = SpawnPrefab("musha_skill_scroll")
    if scroll == nil then return false end
    -- ★★ 2026-09-17 修崩：`GiveItem(item, slot, ...)` 的**第 2 个参数是槽位号(number)**，不是 bool！
    --   我原来传了 `true` → inventory.lua:1088 `if slot > 0` 直接崩
    --   "attempt to compare boolean with number"（用户实测崩在就职仪式那一刻）
    inv:GiveItem(scroll)
    return true
end

-- 二转赠礼统一入口（返回 true = 这次真的给了东西：发了书/卷轴 或 直接加了等级）
function Musha_Profession_Component:GrantAdvanceGift(career)
    local free_skill = BOOK_UNLOCK_SKILL[career]
    if not free_skill then return false end
    if ADVANCE_GIFT_MODE == "level" then
        return self:GrantSkillLevel1(career, free_skill)
    end
    if ADVANCE_GIFT_MODE == "scroll" then
        local ok = self:GiveSkillScroll()
        if ok and self.inst.components.talker then
            self.inst.components.talker:Say("酒馆给了你一卷技能卷轴——展开它。", 5)
        end
        return ok
    end
    -- 默认：本职业的职业技能书；没有专属书 → 退回卷轴
    if self:GiveCareerBook(career) then
        if self.inst.components.talker then
            self.inst.components.talker:Say("酒馆给了你一本属于你的技能书——去翻开它。", 5)
        end
        return true
    end
    local ok = self:GiveSkillScroll()
    if ok and self.inst.components.talker then
        self.inst.components.talker:Say("酒馆给了你一卷技能卷轴——展开它。", 5)
    end
    return ok
end

-- ====== 进阶方向选择（2026-09-18 用户拍板：C + 两本徽记）======
-- 用户口径（原话摘要）：回到祭坛最后交互时**返还两枚方向徽记**（剑士 / 近卫），
--   两枚都能看到、**共用绑定 ID**；**用掉其中一枚 = 选定方向（不可逆）**，另一枚自动作废。
-- 实现口径（不追着删实体，抗掉地/放箱子/给别人/重进游戏）：
--   ① 徽记身上带 `musha_bind`（服务端字段），背包里另一枚由 VoidSameBindCrests() 直接收走；
--   ② 玩家 `userdata.advance_crest_used` 记下用掉的 bind；
--   ③ **兜底**：只要 doer 已经进阶（has_advanced），任何徽记右键一律判"作废"并消失 ——
--      这样即使实体字段在存档往返后丢失（DST 物品不存自定义字段），也不会出现"两枚都能用"。
local BASE_TO_ADVANCED = {
    warrior  = { "saber", "guardian" },   -- 战士 → 剑士 / 近卫（两条支线）
    mage     = { "alchemist", "elementalist" },
    ranger   = { "bard" },
    assassin = { "moonshadow" },
    rogue    = { "moonshadow" },
}
local CREST_PREFAB = {
    saber    = "musha_crest_saber",
    guardian = "musha_crest_guardian",
}

-- 可选的进阶分支（已进阶 → 空表）
function Musha_Profession_Component:GetAdvanceChoices()
    if self.userdata.has_advanced then return {} end
    local base = self.userdata.carrer_base
    return (base and BASE_TO_ADVANCED[base]) or {}
end

-- 本次选择的绑定 ID（同一次转职只生成一次）
function Musha_Profession_Component:GetAdvanceBind()
    if self.userdata.advance_crest_bind == nil then
        self.userdata.advance_crest_bind = string.format("%s-%d-%d",
            tostring(self.userdata.carrer_base or "none"),
            math.random(100000, 999999),
            math.floor(GetTime() or 0))
    end
    return self.userdata.advance_crest_bind
end

function Musha_Profession_Component:IsAdvanceBindUsed(bind)
    return bind ~= nil and self.userdata.advance_crest_used == bind
end

-- 服务端：发两枚方向徽记（进背包；没有背包就掉在脚下）
function Musha_Profession_Component:GrantAdvanceCrests()
    if not TheWorld or not TheWorld.ismastersim then return false end
    if self.userdata.has_advanced then return false end
    local choices = self:GetAdvanceChoices()
    if #choices == 0 then return false end

    local bind = self:GetAdvanceBind()
    self.userdata.advance_choice_pending = true
    local inv = self.inst.components.inventory
    local n = 0
    for _, career in ipairs(choices) do
        local prefab = CREST_PREFAB[career]
        if prefab ~= nil then
            local crest = SpawnPrefab(prefab)
            if crest ~= nil then
                crest.musha_bind = bind
                crest.musha_career = career
                if inv ~= nil then
                    inv:GiveItem(crest)      -- ⚠️ 第 2 参数是槽位号(number)，别传 bool（踩过）
                else
                    local x, y, z = self.inst.Transform:GetWorldPosition()
                    crest.Transform:SetPosition(x, y, z)
                end
                n = n + 1
            end
        end
    end
    self:PushSettings()
    if n > 0 and self.inst.components.talker then
        self.inst.components.talker:Say("酒馆给了你两枚方向徽记——用掉其中一枚，就是你的道路。", 6)
    end
    return n > 0
end

-- 使用徽记 = 选定方向（服务端权威；不可逆）
--   返回 true = 这次真的转职了；否则 (false, 原因)：void / already / noskill / server
function Musha_Profession_Component:UseAdvanceCrest(crest, career)
    if not TheWorld or not TheWorld.ismastersim then return false, "server" end
    career = career or (crest ~= nil and crest.musha_career) or nil
    if career == nil then return false, "nocareer" end
    local bind = crest ~= nil and crest.musha_bind or nil

    -- ① 已进阶 → 一律作废（兜底，见文件头说明）
    if self.userdata.has_advanced then return false, "void" end
    -- ② 同一个绑定已经用掉另一枚 → 这本作废
    if self:IsAdvanceBindUsed(bind) then return false, "void" end
    -- ③ 方向必须是自己基础职业的分支
    local ok = false
    for _, c in ipairs(self:GetAdvanceChoices()) do
        if c == career then ok = true end
    end
    if not ok then return false, "noskill" end

    -- 落地（和旧的 CompleteAdvance() 同一套写入，只是改由"用徽记"触发）
    self.userdata.carrer_special = career
    self.userdata.has_advanced = true
    self.userdata.current_advance_target = nil
    self.userdata.quests_for_advance = {}
    self.userdata.quests_for_advance_done = {}
    if bind ~= nil then self.userdata.advance_crest_used = bind end
    self.userdata.advance_choice_pending = false

    -- 二转赠礼（技能书/卷轴）：出任何错都别卡流程（就职仪式那次踩过崩溃）
    pcall(function() self:GrantAdvanceGift(career) end)

    self:ApplyProfessionData()
    self:PushSettings()
    self.inst:PushEvent("musha_job_changed", { job_id = career })

    -- 转职链收尾：清掉"仪式待办"，祭坛可以继续补卷/接下一轮
    local q = self.inst.components.musha_quest
    if q ~= nil then
        q.advance_ceremony_pending = nil
        q.advance_target = nil
        q.advance_round = 1
        if q.SyncToPanel ~= nil then pcall(function() q:SyncToPanel() end) end
    end

    -- 背包里同 bind 的另一枚：直接收走（不在背包里的靠右键时校验自灭）
    self:VoidSameBindCrests(bind, crest)
    return true
end

-- 收走背包里其它徽记（只扫自己的背包，不动地上的）
--   ★★ 2026-09-19 修（用户实测：用掉一枚后，另一枚还留在背包里）：
--   原因 = 徽记的 `musha_bind` 是实体字段，**掉线重进后会丢**（DST 不存物品自定义字段），
--   这时 bind 为 nil，原来那句 `if bind == nil then return end` 直接跳过 → 另一枚留着。
--   现在改成：**这次已经转职（has_advanced）→ 背包里所有徽记一律收走**（它们都失效了），
--   bind 只用来做"更早一步"的精确匹配（同一次发下来的两枚）。
function Musha_Profession_Component:VoidSameBindCrests(bind, except)
    local inv = self.inst.components.inventory
    if inv == nil or inv.items == nil then return end
    local advanced = self.userdata.has_advanced == true
    local list = {}
    for _, item in pairs(inv.items) do
        list[#list + 1] = item
    end
    for _, item in ipairs(list) do
        if item ~= nil and item ~= except and item:HasTag("musha_crest") then
            if advanced or (bind ~= nil and item.musha_bind == bind) then
                item:Remove()
            end
        end
    end
end

-- 组装"当前职业技能页"的数据（给客户端面板用）
--   ★ 2026-09-12 改：原来只读 carrer_base 那一棵树 → 二转后技能页还是显示基础职业的技能；
--     现在 **基础树 + 二转树都进面板**（用户："3全部都可"）。每条带 tree_kind 便于客户端区分。
function Musha_Profession_Component:GetSkillView()
    local trees = {}
    local base = self.userdata.carrer_base
    local spec = self.userdata.carrer_special
    -- ★ 2026-09-28「英文全做」：非中文界面 → 技能名/说明/效果文案取 SKILL_UI 的 *_en 字段
    --   （TUNING 在 modmain 里按界面语言算；单机/房主 = 本人语言 ✓。没配 _en 的条目自动退回中文）
    local UI_EN = (TUNING and TUNING.MUSHA_UI_LANG and TUNING.MUSHA_UI_LANG ~= "zh")

    -- ★ 2026-09-28 修（用户："技能面板只查看了没有学习，直接表示我学习完了"）：
    --   原来这里只按 `self[base]` 认**原始键**，存档里的键跟已知技能树键对不上时
    --   trees 为空 → return {} → 面板技能树整棵空白 + 空状态弹「该职业的技能已全部学习」。
    --   三重解析：原键 → 语言名反查（"战士" → warrior，读 STRINGS.MUSHA_JOB_*）→ 前缀匹配；
    --   还空就打一行诊断（client_log 一眼能看到 base/spec 到底是什么）。
    local function ResolveTreeKey(k)
        if not k or k == "" then return nil end
        if self[k] and SKILL_ORDER[k] then return k end
        for cand in pairs(SKILL_ORDER) do
            local ok, nm = pcall(function()
                return STRINGS["MUSHA_JOB_" .. string.upper(cand)]
            end)
            if ok and nm == k then return cand end
        end
        for cand in pairs(SKILL_ORDER) do
            if k:sub(1, #cand) == cand then return cand end
        end
        return nil
    end

    local bk = ResolveTreeKey(base)
    local sk = ResolveTreeKey(spec)
    if bk then
        table.insert(trees, { key = bk, kind = "base" })
    end
    if sk and sk ~= bk then
        table.insert(trees, { key = sk, kind = "special" })
    end
    if #trees == 0 then
        print(string.format("[Musha] GetSkillView 返回空（技能树整棵会空白）: base=%s spec=%s",
            tostring(base), tostring(spec)))
        return {}
    end

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
                    -- 英文文案：有 *_en 就用，没有退回中文（fmt 是函数 → effect/nextfx 都走这一条）
                    local fmt = d and ((UI_EN and d.fmt_en) or d.fmt) or nil

                    local cost = 1
                    if skill.skill_point_cost and skill.skill_point_cost[nxt] then
                        cost = skill.skill_point_cost[nxt]
                    end

                    -- ★ 2026-09-17 技能书锁（用户）：本职业"技能书解锁技"（剑士=剑气斩）在 0 级时**不能**用技能点买，
                    --   要 1 本技能书解锁 → 面板上画小锁 + 悬停显示"需要 1 本技能书才能解锁"
                    local book_need = (BOOK_UNLOCK_SKILL[tree] == key and cur == 0) and 1 or 0

                    local entry = {
                        id     = tree .. "_" .. key,
                        tree   = tree,
                        kind   = t.kind,                        -- base / special
                        tree_name = TreeNodeName(tree),         -- 显示用（战士 / 剑士 …）
                        key    = key,
                        name   = (UI_EN and d and d.name_en) or (d and d.name) or key,
                        tip    = (UI_EN and d and d.tip_en) or (d and d.tip) or nil,
                        cur    = cur,
                        max    = maxlv,
                        maxed  = cur >= maxlv,
                        req    = info.requirement or 0,
                        cost   = cost,
                        points = self.userdata.skill_points or 0,
                        lv     = self.userdata.level or 0,
                        effect = fmt and fmt(skill.level_effects and skill.level_effects[cur] or 0) or "",
                        nextfx = fmt and fmt(skill.level_effects and skill.level_effects[nxt] or 0) or "",
                        book_lock = book_need,     -- >0 = 需要这么多本技能书才能解锁（客户端画锁 + 提示）
                    }
                    -- ★ 2026-09-20 技能树：格坐标 + 前置状态（客户端画连线、判灰亮都读这两样）
                    do
                        local tpos = SKILL_TREE_POS[tree] and SKILL_TREE_POS[tree][key]
                        entry.tree_x = (tpos and tpos.x) or 0
                        entry.tree_y = (tpos and tpos.y) or 0
                        entry.pre    = {}
                        entry.pre_ok = true
                        if tpos and tpos.req then
                            for pkey, need in pairs(tpos.req) do
                                local pskill = self[tree] and self[tree][pkey]
                                local pcur = (pskill and pskill.current_level) or 0
                                local pdef = defs and defs[pkey]
                                table.insert(entry.pre, {
                                    key  = pkey,
                                    name = (UI_EN and pdef and pdef.name_en) or (pdef and pdef.name) or pkey,
                                    need = need,
                                    cur  = pcur,
                                })
                                if pcur < need then entry.pre_ok = false end
                            end
                        end
                    end

                    entry.can = (book_need == 0) and (not entry.maxed) and entry.points >= entry.cost
                                and entry.lv >= entry.req and entry.pre_ok
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
    local target = self.userdata.current_advance_target
    self.userdata.carrer_special = target
    self.userdata.has_advanced = true
    -- ★ 2026-09-17 二转赠送（用户："剑士的剑气斩改为技能书解锁，但二转后赠送"）
    --   ⚠️ 这里必须显式送：祭坛二转走的是本函数，直接给 carrer_special 赋值、不经过 SetCarrerSpecial
    -- ★ 2026-09-17 改：赠礼 = 技能卷轴（同上，走统一入口）
    self:GrantAdvanceGift(target)
    self.userdata.quests_for_advance = {}

    self.userdata.current_advance_target = nil

    -- ❌ 2026-09-14 用户：「不需要再二转之后再发一本技能面板的书」→ 删掉发书
    --   （原来这里 SpawnPrefab("musha_skillbook") + inventory:GiveItem 各发一本）
    --   技能页现在从面板「技能」页看，不需要实体书当入口。

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
            -- ★ 2026-09-14 新增：剑气斩（加点学习，3 级）—— 不写这里会存不上档 → 重进游戏等级归零
            slash_qi = {
                current_level = self.saber.slash_qi and self.saber.slash_qi.current_level or 0
            },
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
            -- ★ 2026-09-14 新增：剑气斩（加点学习，3 级）
            if data.saber.slash_qi then
                if self.saber.slash_qi == nil then
                    self.saber.slash_qi = { current_level = 0, max_level = 3,
                        level_effects = { [1] = 18, [2] = 16, [3] = 14 },
                        unlock_requirements = { [1] = 3, [2] = 7, [3] = 12 },
                        skill_point_cost = { [1] = 1, [2] = 1, [3] = 1 } }
                end
                self.saber.slash_qi.current_level = data.saber.slash_qi.current_level or 0
            end
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

    -- ★ 2026-09-16 修「登录后武器技能放不出来，得把武器装/卸两次才行」
    --   时序坑：读档时手里那把武器先跑 prefab/on_equip（那时候技能等级还没读进来 = 0）
    --   → musha_sword 里挂的 aoetargeting 门被判成"没学"关掉了；之后除了"加点"没有任何事件会重开它。
    --   武器 on_equip 里本来就 ListenForEvent("musha_skill_changed")，所以数据读完这里补广播一次即可。
    if TheWorld ~= nil and TheWorld.ismastersim and self.inst ~= nil and self.inst:IsValid() then
        self.inst:PushEvent("musha_skill_changed", { tree = "saber", name = "load", level = 0 })
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
        player.components.health.redirect = nil      -- ★ 2026-09-20 撤销近卫盾钩子（构造函数里挂的）
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

    -- ★ 2026-09-19 邮包系统：把"这个玩家绑没绑信箱"一起推给客户端
    --   为什么非走这条：光标上的动作名是**客户端**算的，而 has_mailbox 存在服务端组件里。
    --   用户拍板：复用这条已有的推送通道（代价 = 只有 musha 玩家有职业组件，
    --   其他角色的信箱动作名会退回纯「触摸」）。
    local mc = self.inst.components.musha_mail
    d.mail = { bound = (mc ~= nil and mc.has_mailbox) and true or false }

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