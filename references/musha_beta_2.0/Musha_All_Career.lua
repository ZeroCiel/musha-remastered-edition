--人物升级
TUNING.Musha_Upgrade = GetModConfigData("Musha_experience") or 1

--Musha的声音，仅Musha
TUNING.MushaSound = GetModConfigData("sound")

--食物设置 仅Musha
TUNING.MUSHAS_FOOD = GetModConfigData("Musha_food")

--职业数据
TUNING.MUSHA_CAREER_MULTIPLYING =  GetModConfigData("musha_career_multiplying") or 1
TUNING.Musha_health_Setting = GetModConfigData("Musha_health") or 5

--体力
TUNING.MUSHA_SLEEP_DIFFICULT = GetModConfigData("Musha_stamina")

--宝藏
TUNING.MUSHA_TREASURE_HUNTER = GetModConfigData("Musha_treasure_probability")

--[[AddPlayerPostInit(
    function(inst)
        if inst:HasTag("Norse_mythology_general") and not inst:HasTag("musha") then
            --等级经验 需要随时更新的是Hp和Mp 体力与疲劳值
            --此处应该还有4个技能cd的net
            --这里应该还有职业和生活职业

            --宝藏的net 找时间想办法优化了
            inst.musha_treasure_hunter = net_shortint(inst.GUID, "musha_treasure_hunter")
            inst.musha_treasure_currentvalue = net_shortint(inst.GUID, "musha_treasure_currentvalue")

            if TheWorld.ismastersim then
                inst:AddComponent("norse_mythology_system") --主要的等级经验系统 包括成长方向性
				inst:AddComponent("musha_sleep") --睡眠相关
                inst:AddComponent("norse_mythology_career_system") --职业系统预装 分别装入了职业和正常数据
                -- inst:AddComponent("musha_career_skill") --技能系统，主要用于储存技能等级信息，cd冷却
                inst:AddComponent("musha_treasure_hunter") --宝藏系统预装

                --体力系统补丁
                if inst.components.combat then
                    local oldattackfn = inst.components.combat.StartAttack
                    inst.components.combat.StartAttack = function(self, ...)
                        if self.inst:HasTag("norse_mythology_career_system") and self.inst.components.norse_mythology_system then
                            self.inst.components.norse_mythology_system:Stamina_DoDelta(0.02)
                        end
                        return oldattackfn(self, ...)
                    end
                end
            end
        end
    end
)]]

AddComponentPostInit(
    "workable",
    function(self)
        local oldfn = self.WorkedBy
        self.WorkedBy = function(self, worker, numworks, ...)
            if worker and worker:HasTag("norse_mythology_career_system") and worker.components.norse_mythology_system then
                worker.components.norse_mythology_system:Stamina_DoDelta(0.005)
                return oldfn(self, worker, numworks, ...)
            else
                return oldfn(self, worker, numworks, ...)
            end
        end
    end
)
