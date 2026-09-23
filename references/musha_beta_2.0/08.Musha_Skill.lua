local function Shield_cding(inst)
    if inst.cdtime > 0 then
        inst.cdtime = inst.cdtime - 1
    elseif inst.cdtime <= 0 then
        if inst.Shield_Useing then
            inst.Shield_Useing = false
            inst.components.talker:Say(STRINGS.MUSHA_TALK_SHIELD_FULL)
        end

        if inst.DoShield_CD then
            inst.DoShield_CD:Cancel()
            inst.DoShield_CD = nil
        end
    end
end

--通用技能[睡眠，激活，非musha不持有宠物技能]
--睡眠
AddModRPCHandler(
    "musha",
    "Musha_Sleep",
    function(inst)
        if inst:HasTag("norse_mythology_career_system") then
            local ghost = inst:HasTag("playerghost") or inst.components.health:IsDead() and true or false
            local hunger = inst.components.hunger.current < 40 and not inst.sg:HasStateTag("sleeping") and true or false
            local riding = inst.components.rider:IsRiding() and true or false
            local text = ghost and STRINGS.MUSHA_TALK_GHOST_OOOOHHHH or hunger and GetString(inst, "ANNOUNCE_NOHUNGERSIESTA") or riding and GetString(inst, "ANNOUNCE_NODAYSLEEP") or nil
            if (ghost or hunger or riding) and text ~= nil then
                inst.components.talker:Say(text)
            else
                inst.components.musha_sleep:TrySleep()
            end
        end
    end
)

--激活武器
AddModRPCHandler(
    "musha",
    "Musha_weapon",
    function(inst)
        local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if item and item.components.musha_equip_skill and inst.components.inventory and inst.components.inventory:IsOpenedBy(inst) then
            if not item.components.musha_equip_skill:GetState() then
                item.components.musha_equip_skill:StartChangeState(inst)
            elseif item.components.musha_equip_skill:GetState() then
                item.components.musha_equip_skill:StopState(inst)
            end
        end
    end
)

AddModRPCHandler(
    "musha",
    "Musha_call_yamache",
    function(inst)
        local hat = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if hat and hat:HasTag("yamache") then
            inst.components.talker:Say(STRINGS.MUSHA_YAMCHE_ALREADYYAMCHE)
            return false
        end

        if inst.yamache ~= nil then
            inst.components.talker:Say(STRINGS.MUSHA_TALK_ORDER_YAMCHE_STAY)
            inst.yamache.components.follower:StopFollowing()

            if inst.yamache then
                inst.yamache.persists = true
                inst.yamache = nil
            end
            return
        end

        local yamache =
            FindEntity(
            inst,
            9,
            function(target)
                return (target:HasTag("yamache"))
            end
        )

        if not yamache and not inst.yamache then
            inst.components.talker:Say(STRINGS.MUSHA_TALK_ORDER_YAMCHE_LOST)
            return
        elseif yamache and not inst.yamache then
            if yamache.components.follower.leader ~= nil then
                inst.components.talker:Say(STRINGS.MSHHA_TALK_YAMACHE_MASTER)
            elseif yamache.components.follower.leader == nil then
                yamache.components.follower:SetLeader(inst)
                yamache.persists = false

                inst.components.talker:Say(STRINGS.MUSHA_TALK_ORDER_YAMCHE_FOLLOW)
                inst.yamache = yamache
            end
        end
    end
)

AddModRPCHandler(
    "musha",
    "Musha_call_mypet",
    function(inst)
        if inst.beefalo ~= nil then
            inst.components.talker:Say(STRINGS.MUSHA_TALK_ORDER_ARONG_STAY)
            inst.beefalo.components.follower:StopFollowing()

            if inst.beefalo then
                -- inst.beefalo.persists = true
                inst.beefalo = nil
            end
            return
        end

        local beefalo =
            FindEntity(
            inst,
            9,
            function(target)
                return (target:HasTag("musha_beefalo"))
            end
        )

        if not beefalo and not inst.beefalo then
            inst.components.talker:Say(STRINGS.MUSHA_TALK_ORDER_ARONG_LOST)
            return
        elseif beefalo and not inst.beefalo then
            if beefalo.components.follower.leader ~= nil then
                inst.components.talker:Say(STRINGS.MUSHA_TALK_ORDER_ARONG_LOST)
            elseif beefalo.components.follower.leader == nil then
                beefalo.components.follower:SetLeader(inst)
                -- beefalo.persists = false

                inst.components.talker:Say(STRINGS.MUSHA_TALK_ORDER_ARONG_FOLLOW)
                inst.beefalo = beefalo
            end
        end
    end
)

--[[AddModRPCHandler(
    "musha",
    "Musha_shield",
    function(inst)
        if inst:HasTag("playerghost") or inst.components.health:IsDead() then
            inst.components.talker:Say(STRINGS.MUSHA_TALK_GHOST_OOOOHHHH)
            return
        end

        if inst.components.norse_mythology_system and inst.components.norse_mythology_system:Mp_GetPercent() >= 0.3 and inst.cdtime == 0 then
            inst.Shield_Useing = true
            inst.cdtime = 360
        elseif inst.cdtime ~= 0 then
            inst.components.talker:Say(STRINGS.MUSHA_TALK_SHIELD_COOL .. "\n" .. inst.cdtime .. "s")
            return
        elseif inst.components.norse_mythology_system and inst.components.norse_mythology_system:Mp_GetPercent() < 0.3 then
            inst.components.talker:Say(STRINGS.MUSHA_NEED_MOREPOWER)
            return
        end

        inst.components.norse_mythology_system:Mp_DoDelta(-30)

        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 15, {"player", "musha"})
        for k, v in ipairs(ents) do
            if v ~= nil and not (v:HasTag("playerghost") and v.components.health:IsDead()) then
                local fx = SpawnPrefab("musha_fx_shield")
                -- local x1, y1, z1 = v.Transform:GetWorldPosition()
                if v.components.rider ~= nil and v.components.rider:IsRiding() then
                    fx.Transform:SetScale(2, 2, 2)
                end

                local function electrocute(v, data)
                    if v and data and data.attacker ~= nil and (data.attacker:HasTag("_combat") and data.attacker:HasTag("_health")) and not data.attacker:HasTag("epic") then
                        SpawnPrefab("electrichitsparks"):AlignToTarget(data.attacker, v, true)
                        SpawnPrefab("sparks").Transform:SetPosition(v.Transform:GetWorldPosition())
                        SpawnPrefab("electricchargedfx").Transform:SetPosition(data.attacker.Transform:GetWorldPosition())
                        if v.shield_fx ~= nil then
                            v.shield_fx.AnimState:PlayAnimation("hit")
                            v.shield_fx.AnimState:PushAnimation("idle_loop")
                        end
                    end
                end

                -- v:ListenForEvent("attacked", electrocute, v)

                -- fx.entity:AddFollower()
                -- local x1, y1, z1 = inst.Transform:GetWorldPosition()
                -- fx.Follower:FollowSymbol(v.GUID, "swap_body", 0, 0, 0)
                -- fx.entity:SetParent(v.entity)
                -- fx.Transform:SetPosition(v.Transform:GetWorldPosition())
                fx.entity:SetParent(v.entity)
                v.shield_fx = fx
                v.shield = true

                if v.fx_light == nil or not v.fx_light:IsValid() then
                    v.fx_light = SpawnPrefab("wormlight_light")
                    v.fx_light.entity:SetParent(v.entity)
                end

                v.SoundEmitter:PlaySound("dontstarve/creatures/chester/raise")
                v.SoundEmitter:PlaySound("dontstarve/creatures/chester/pop")

                local musha_shield_level = v.components.norse_mythology_system:GetShieldLevel()
                if TUNING.Musha_Upgrade == 0 then
                    musha_shield_level = 7
                end
                musha_shield_level = musha_shield_level - 1
                local skill_time = 6 + musha_shield_level

                v:DoTaskInTime(
                    skill_time,
                    function()
                        if v.fx_light ~= nil then
                            if v.fx_light:IsValid() then
                                v.fx_light:Remove()
                            end
                            v.fx_light = nil
                        end

                        v.shield_fx = nil
                        if fx:IsValid() then
                            fx.kill_fx(fx)
                        end
                        -- inst:RemoveEventCallback("attacked", electrocute, v)
                        v.shield = false
                    end
                )

                if v.Shield_Useing then
                    v.Shield_Useing = false

                    v.cdtime = 360 - musha_shield_level * 50

                    if not v.DoShield_CD then
                        v.DoShield_CD = v:DoPeriodicTask(1, Shield_cding)
                    end
                end
            end
        end
    end
)]]
