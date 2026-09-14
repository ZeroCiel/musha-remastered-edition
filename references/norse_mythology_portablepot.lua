local assets = {
    Asset("ANIM", "anim/norse_mythology_portablepot.zip"),
    Asset("ATLAS", "images/inventoryimages/norse_mythology_portablepot.xml"),
    Asset("ATLAS", "images/inventoryimages/norse_mythology_portablepot_item.xml")
}

local cooking = require("cooking")

local cookpot_recipes = cooking.recipes["cookpot"]
local portablecookpot_recipes = cooking.recipes["portablecookpot"]

for k, recipe in pairs(cookpot_recipes) do
    AddCookerRecipe("norse_mythology_portablepot", recipe, cooking.IsModCookerFood(k))
end
--[[
for k,recipe in pairs (portablecookpot_recipes) do 
	AddCookerRecipe("norse_mythology_portablepot", recipe, cooking.IsModCookerFood(k)) 
end]]

local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
end

--截止
local function CheckFood(inst)
    for k = 5, 8 do
        if inst.components.container:GetItemInSlot(k) ~= nil then
            return true
        end
    end
    return false
end

local function ShowAnim(inst)
    local item = inst.components.container:GetItemInSlot(1)
    if inst.components.container:IsEmpty() and not inst.components.burnable:IsBurning() then
        inst.AnimState:PlayAnimation("idle")
    elseif not (inst.components.stewer:IsSpoiling() and inst.components.stewer:IsCooking() and not inst.components.container:IsOpen() and inst.components.stewer.product == nil) then
        -- print("烧烤BBQ")
		if inst.components.burnable:IsBurning() then
            -- print("有火")
			local level = math.clamp(inst.components.fueled:GetCurrentSection(), 0, 3)
            local anim = "stand_ordinary_Lv"
            if item and item.prefab == "redgem" then
                anim = "stand_fire_Lv"
            elseif item and item.prefab == "bluegem" then
                anim = "stand_cold_Lv"
            end
            inst.AnimState:PlayAnimation(anim .. level, true)
        elseif not inst.components.burnable:IsBurning() then
            -- print("无火")
			local anim = "idle"
            if item and item.prefab == "redgem" then
                anim = "fire"
            elseif item and item.prefab == "bluegem" then
                anim = "cold"
            end
            inst.AnimState:PlayAnimation(anim, true)
        end
    elseif (inst.components.stewer:IsSpoiling() or inst.components.stewer:IsCooking() or inst.components.container:IsOpen()) then
        -- print("可能在烹饪？")
		local anim = "idle"
		local cook = "cooking_open_"
        if item and item.prefab == "redgem" then
            anim = "fire"
			-- print("超级大火")
        elseif item and item.prefab == "bluegem" then
            anim = "cold"
			-- print("这是冰淇淋？")
        end
		
		if inst.components.stewer:IsCooking() then
            cook = "cooking_"
			-- print("真的在烹煮")
        end

        inst.AnimState:PlayAnimation(cook .. anim .. "_pot", true)
    end
end

local function onopen(inst)
    inst.SoundEmitter:KillSound("snd")
    inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_open")
    inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot", "snd")
end

local function GetProduct(item)
    local prefab = nil
    if item.components.cookable.product then
        prefab = item.components.cookable.product
        if type(item.components.cookable.product) == "function" then
            prefab = item.components.cookable.product(item)
        end
    end
    return prefab
end

local function EasyCook(inst)
    for k = 2, 4 do
        local food = inst.components.container:GetItemInSlot(k)
        if food and food.components.cookable then
            local replacement = GetProduct(food)
            local stacksize = 1
            if food.components.stackable then
                stacksize = food.components.stackable:StackSize()
            end
            local newprefab = SpawnPrefab(replacement)
            if newprefab.components.stackable then
                newprefab.components.stackable:SetStackSize(stacksize)
            end
            inst.components.container:RemoveItemBySlot(k)
            food:Remove()

            newprefab.components.inventoryitem:ChangeImageName(newprefab.prefab)

            inst:DoTaskInTime(
                0,
                function()
                    inst.components.container:GiveItem(newprefab, k)
                end
            )
        end
    end
end

local function onclose(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_close")
    if not CheckFood then
        inst.playing = false
        ShowAnim(inst)
    end
end

local function SetProductSymbol(inst, product, overridebuild)
    local recipe = cooking.GetRecipe(inst.prefab, product)
    local potlevel = recipe ~= nil and recipe.potlevel or nil
    local build = (recipe ~= nil and recipe.overridebuild) or overridebuild or "cook_pot_food"
    local overridesymbol = (recipe ~= nil and recipe.overridesymbolname) or product

    if potlevel == "high" then
        inst.AnimState:Show("swap_high")
        inst.AnimState:Hide("swap_mid")
        inst.AnimState:Hide("swap_low")
    elseif potlevel == "low" then
        inst.AnimState:Hide("swap_high")
        inst.AnimState:Hide("swap_mid")
        inst.AnimState:Show("swap_low")
    else
        inst.AnimState:Hide("swap_high")
        inst.AnimState:Show("swap_mid")
        inst.AnimState:Hide("swap_low")
    end

    inst.AnimState:OverrideSymbol("swap_cooked", build, overridesymbol)
end

local function ShowProduct(inst) --显示食物内容
    local product = inst.components.stewer.product
    SetProductSymbol(inst, product, IsModCookingProduct(inst.prefab, product) and product or nil)
end

local function donecookfn(inst) --结束烹饪
    local item = inst.components.container:GetItemInSlot(1)
    local name = "ordinary"
    if item ~= nil then
        if item.prefab == "redgem" then
            name = "fire"
        elseif item.prefab == "bluegem" then
            name = "cold"
        end
    end

    inst.AnimState:PushAnimation("cooking_done_" .. name .. "_pot", true)
    ShowProduct(inst)
    inst.SoundEmitter:KillSound("snd")
    inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_finish")
    inst.Light:Enable(false)
    -- inst.playing = true
end

local function continuedonefn(inst) --登录游戏时继续显示的动画
    ShowAnim(inst)
    ShowProduct(inst)
end

local function continuecookfn(inst) --材料满了 或者烹饪中
    local item = inst.components.container:GetItemInSlot(1)
    local anim = "ordinary"
    if item ~= nil then
        if item.prefab == "redgem" then
            anim = "fire"
        elseif item.prefab == "bluegem" then
            anim = "cold"
        end
    end

    inst.AnimState:PlayAnimation("cooking_" .. anim .. "_pot", true) --煮东西
    inst.Light:Enable(true)
    inst.SoundEmitter:KillSound("snd")
    inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_rattle", "snd")
end

local function harvestfn(inst) --收获食物
    ShowAnim(inst)
    inst.playing = false
    inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_close")
end

local function SetProductSymbol(inst, product, overridebuild)
    local recipe = cooking.GetRecipe(inst.prefab, product)
    local potlevel = recipe ~= nil and recipe.potlevel or nil
    local build = (recipe ~= nil and recipe.overridebuild) or overridebuild or "cook_pot_food"
    local overridesymbol = (recipe ~= nil and recipe.overridesymbolname) or product

    inst.AnimState:OverrideSymbol("swap_cooked", build, overridesymbol)
end

local function spoilfn(inst)
    inst.components.stewer.product = inst.components.stewer.spoiledproduct
    SetProductSymbol(inst, inst.components.stewer.product)
end

local function startcookfn(inst)
    local item = inst.components.container:GetItemInSlot(1)
    local anim = inst.cookstate or "ordinary"
    if not inst.playing then
        inst.AnimState:PlayAnimation("birth_" .. anim .. "_pot", true) --开始煮东西
        inst.playing = true
    end

    inst.AnimState:PushAnimation("cooking_" .. anim .. "_pot", true)
    inst.SoundEmitter:KillSound("snd")
    inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_rattle", "snd")
    inst.Light:Enable(true)
end

local function onbuilt(inst)
    inst.components.fueled:SetPercent(0.05)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", true)
end

local function dospoil(inst, self)
    self.task = nil
    self.targettime = nil
    self.spoiltime = nil

    if self.onspoil ~= nil then
        self.onspoil(inst)
    end
end

local function dostew(inst, self)
    self.task = nil
    self.targettime = nil
    self.spoiltime = nil

    if self.ondonecooking ~= nil then
        self.ondonecooking(inst)
    end

    if self.product == self.spoiledproduct then
        if self.onspoil ~= nil then
            self.onspoil(inst)
        end
    elseif self.product ~= nil then
        local recipe = cooking.GetRecipe(inst.prefab, self.product)
        local prep_perishtime = (recipe ~= nil and (recipe.cookpot_perishtime or recipe.perishtime)) or 0
        if prep_perishtime > 0 then
            local prod_spoil = self.product_spoilage or 1
            self.spoiltime = prep_perishtime * prod_spoil
            self.targettime = GetTime() + self.spoiltime
            self.task = self.inst:DoTaskInTime(self.spoiltime, dospoil, self)
        end
    end

    self.done = true
end

local function onextinguish(inst)
    if inst.components.fueled ~= nil then
        inst.components.fueled:InitializeFuelLevel(0)
    end
    ShowAnim(inst)
end

local function ontakefuel(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
end

local function updatefuelrate(inst)
    inst.components.fueled.rate = TheWorld.state.israining and 1 + TUNING.FIREPIT_RAIN_RATE * TheWorld.state.precipitationrate or 1
end

local function onupdatefueled(inst)
    if inst.components.burnable ~= nil and inst.components.fueled ~= nil then
        updatefuelrate(inst)
        -- ShowAnim(inst)
        inst.components.burnable:SetFXLevel(inst.components.fueled:GetCurrentSection(), inst.components.fueled:GetSectionPercent())
    end
end

local function onfuelchange(newsection, oldsection, inst, doer)
    if newsection <= 0 then
        inst.components.burnable:Extinguish()
        -- ShowAnim(inst)
    else
        if not inst.components.burnable:IsBurning() then
            updatefuelrate(inst)
            inst.components.burnable:Ignite(nil, nil, doer)
        end
        ShowAnim(inst)
        inst.components.burnable:SetFXLevel(newsection, inst.components.fueled:GetSectionPercent())
    end
end

local function AddFuel(inst)
    local doer = FindEntity(
        inst,
        12,
        function(target)
            return target and target:HasTag("player")
        end
    )
    for k = 1, 4 do
        local item = inst.components.container:GetItemInSlot(k)
        if inst.components.fueled:GetPercent() <= 0.8 and item and inst.components.fueled:CanAcceptFuelItem(item) and doer then
            local size = item.components.stackable and item.components.stackable:StackSize() or 1
            while inst.components.fueled:GetPercent() <= 0.8 do
                if item == nil or inst.components.fueled:GetPercent() > 0.8 then
                    break
                end
                inst.components.fueled:TakeFuelItem(item, doer)
            end
        elseif inst.components.fueled:GetPercent() > 0.8 then
            break
        end
    end
end

--便携
local function ChangeToItem(inst)
    if inst.components.stewer.product ~= nil and inst.components.stewer:IsDone() then
        inst.components.stewer:Harvest()
    end
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end

    local item = SpawnPrefab("norse_mythology_portablepot_item", inst.linked_skinname, inst.skin_id)
    item.Transform:SetPosition(inst.Transform:GetWorldPosition())
    --item.AnimState:PlayAnimation("idle")
end

local function OnDismantle(inst) --, doer)
    ChangeToItem(inst)
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()

    inst.Light:Enable(false)
    inst.Light:SetRadius(.6)
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.5)
    inst.Light:SetColour(235 / 255, 62 / 255, 12 / 255)
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.75)
    inst.Transform:SetScale(2, 2, 2)

    inst:AddTag("structure")

    inst.AnimState:SetBank("norse_mythology_portablepot")
    inst.AnimState:SetBuild("norse_mythology_portablepot")

    inst.MiniMapEntity:SetIcon("norse_mythology_portablepot")

    MakeSnowCoveredPristine(inst)

    inst:AddTag("storytellingprop")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("norse_mythology_portablepot")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("norse_mythology_portablepot")
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    --[[inst.components.container.GetSpecificSlotForItem = function(self, item, ...)
        if self.usespecificslotsforitems and self.itemtestfn ~= nil then
            local k = 1
			if (item.prefab ~= "redgem" or item.prefab ~= "bluegem") then
			    i = 1
			elseif item.components.fuel then
			    k = 4
			end
			
			for i = 1, self:GetNumSlots() do
                if self:itemtestfn(item, i) then
                    return i
                end
            end
        end
    end]]
    inst.components.container.GiveItem = function(self, item, slot, src_pos, drop_on_fail, ...) --需要测试
        if item == nil then
            return false
        elseif item.components.inventoryitem ~= nil and self:CanTakeItemInSlot(item, slot) then
            if slot == nil then
                slot = self:GetSpecificSlotForItem(item)
            end

            --try to burn off stacks if we're just dumping it in there
            if item.components.stackable ~= nil and self.acceptsstacks then
                --Added this for when we want to dump a stack back into a
                --specific spot (e.g. moving half a stack failed, so we
                --need to dump the leftovers back into the original stack)
                if slot ~= nil and slot <= self.numslots then
                    local other_item = self.slots[slot]
                    if other_item ~= nil and other_item.prefab == item.prefab and other_item.skinname == item.skinname and not other_item.components.stackable:IsFull() then
                        if self.inst.components.inventoryitem ~= nil and self.inst.components.inventoryitem.owner ~= nil then
                            self.inst.components.inventoryitem.owner:PushEvent("gotnewitem", { item = item, slot = slot })
                        end

                        item = other_item.components.stackable:Put(item, src_pos)
                        if item == nil then
                            return true
                        end

                        slot = self:GetSpecificSlotForItem(item)
                    end
                end

                if slot == nil then
                    for k = 1, self.numslots do
                        local other_item = self.slots[k]
                        if other_item and other_item.prefab == item.prefab and other_item.skinname == item.skinname and not other_item.components.stackable:IsFull() then
                            if self.inst.components.inventoryitem ~= nil and self.inst.components.inventoryitem.owner ~= nil then
                                self.inst.components.inventoryitem.owner:PushEvent("gotnewitem", { item = item, slot = k })
                            end

                            item = other_item.components.stackable:Put(item, src_pos)
                            if item == nil then
                                return true
                            end
                        end
                    end
                end
            end

            local in_slot = nil
            if slot ~= nil and slot <= self.numslots and not self.slots[slot] then
                in_slot = slot
            elseif not self.usespecificslotsforitems and self.numslots > 0 then
                for i = 1, self.numslots do
                    if not self.slots[i] then
                        in_slot = i
                        break
                    end
                end
            end

            if in_slot and self:CanTakeItemInSlot(item, in_slot) then
                --weird case where we are trying to force a stack into a non-stacking container. this should probably have been handled earlier, but this is a failsafe
                if not self.acceptsstacks and item.components.stackable and item.components.stackable:StackSize() > 1 and (in_slot and (in_slot == 1 or in_slot >= 5)) then
                    item = item.components.stackable:Get()
                    self.slots[in_slot] = item
                    item.components.inventoryitem:OnPutInInventory(self.inst)
                    self.inst:PushEvent("itemget", { slot = in_slot, item = item, src_pos = src_pos, })
                    return false
                end

                self.slots[in_slot] = item
                item.components.inventoryitem:OnPutInInventory(self.inst)
                self.inst:PushEvent("itemget", { slot = in_slot, item = item, src_pos = src_pos })

                if not self.ignoresound and self.inst.components.inventoryitem ~= nil and self.inst.components.inventoryitem.owner ~= nil then
                    self.inst.components.inventoryitem.owner:PushEvent("gotnewitem", { item = item, slot = in_slot })
                end

                return true
            end
        end

        --default to true if nil
        if drop_on_fail ~= false then
            item.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
            if item.components.inventoryitem ~= nil then
                item.components.inventoryitem:OnDropped(true)
            end
        end
        return false
    end

    --[[local PutOneOfActiveItemInSlot = inst.components.container.PutOneOfActiveItemInSlot
    inst.components.container.PutOneOfActiveItemInSlot = function(self, slot, opener)
        local inventory, active_item = QueryActiveItem(self, opener)
        if active_item ~= nil and
            self:GetItemInSlot(slot) == nil and
            self:CanTakeItemInSlot(active_item, slot) and
            active_item.components.stackable ~= nil and
            active_item.components.stackable:IsStack() then

            self.currentuser = opener

            self.ignoresound = true
            self:GiveItem(active_item.components.stackable:Get(1), slot)
            self.ignoresound = false

            self.currentuser = nil
        end
    end]]

    --[[local PutAllOfActiveItemInSlot = inst.components.container.PutAllOfActiveItemInSlot
    inst.components.container.PutAllOfActiveItemInSlot = function(self, slot, opener)
        print("PutAllOfActiveItemInSlot")
        return PutAllOfActiveItemInSlot(self, slot, opener)
    end]]


    inst:AddComponent("burnable")
    --inst.components.burnable:SetFXLevel(2)
    inst.components.burnable:AddBurnFX("campfirefire", Vector3(0, 0, 0), "firefx", true)
    inst:ListenForEvent("onextinguish", onextinguish)

    inst:AddComponent("stewer")
    inst.components.stewer.onstartcooking = startcookfn
    inst.components.stewer.oncontinuecooking = continuecookfn
    inst.components.stewer.oncontinuedone = continuedonefn
    inst.components.stewer.ondonecooking = donecookfn
    inst.components.stewer.onharvest = harvestfn
    inst.components.stewer.onspoil = spoilfn
    inst.components.stewer.CanCook = function(self, ...)
        return CheckFood(self.inst)
    end
    inst.components.container.DestroyContents = function(self, ...)
        for k = 5, self.numslots do
            local item = self:RemoveItemBySlot(k)
            if item ~= nil then
                item:Remove()
            end
        end
    end
    inst.components.stewer.StartCooking = function(self, doer, ...)
        if self.targettime == nil and self.inst.components.container ~= nil then
            self.chef_id = (doer ~= nil and doer.player_classified ~= nil) and doer.userid
            self.ingredient_prefabs = {}

            self.done = nil
            self.spoiltime = nil

            if self.onstartcooking ~= nil then
                self.onstartcooking(self.inst)
            end

            for k, v in pairs(self.inst.components.container.slots) do
                if cooking.IsCookingIngredient(v.prefab) then
                    table.insert(self.ingredient_prefabs, v.prefab)
                end
            end


            local cooktime = 1
            self.product, cooktime = cooking.CalculateRecipe(self.inst.prefab, self.ingredient_prefabs)
            local productperishtime = cooking.GetRecipe(self.inst.prefab, self.product).perishtime or 0
            productperishtime = productperishtime * 0.75 --CD缩减

            if productperishtime > 0 then
                local spoilage_total = 0
                local spoilage_n = 0
                for k = 5, 8 do
                    local item = self.inst.components.container:GetItemInSlot(k)
                    if item.components.perishable ~= nil then
                        spoilage_n = spoilage_n + 1
                        spoilage_total = spoilage_total + item.components.perishable:GetPercent()
                    end
                end
                self.product_spoilage = (spoilage_n <= 0 and 1) or
                    (self.keepspoilage and spoilage_total / spoilage_n) or
                    1 - (1 - spoilage_total / spoilage_n) * .5
            else
                self.product_spoilage = nil
            end

            cooktime = TUNING.BASE_COOK_TIME * cooktime * self.cooktimemult
            self.targettime = GetTime() + cooktime
            if self.task ~= nil then
                self.task:Cancel()
            end
            self.task = self.inst:DoTaskInTime(cooktime, dostew, self)

            self.inst.components.container:Close()
            self.inst.components.container:DestroyContents()
            self.inst.components.container.canbeopened = false
        end
    end

    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = TUNING.FIREPIT_FUEL_MAX
    inst.components.fueled.accepting = true
    inst.components.fueled:SetSections(4)
    inst.components.fueled.bonusmult = TUNING.FIREPIT_BONUS_MULT
    inst.components.fueled:SetUpdateFn(onupdatefueled)
    inst.components.fueled:SetSectionCallback(onfuelchange)
    inst.components.fueled:InitializeFuelLevel(TUNING.FIREPIT_FUEL_START)

    inst:AddComponent("storytellingprop")

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("portablestructure")
    inst.components.portablestructure:SetOnDismantleFn(OnDismantle)

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(8)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    MakeSnowCovered(inst)
    inst:ListenForEvent("onbuilt", onbuilt)
	
	inst.cookstate = nil

    inst.OnLoad = function() --冷藏BUG
        ShowAnim(inst)
        local item = inst.components.container:GetItemInSlot(1)
        if item then
            if item.prefab == "bluegem" then
                inst.components.burnable.fxdata.prefab = "coldfirefire"
                inst.components.burnable.fxdata.follow = nil
                inst:AddTag("fridge")
				inst.cookstate = "cold"
            elseif item.prefab == "redgem" then
                inst:RemoveTag("fridge")
				inst.cookstate = "fire"
                inst.components.burnable.fxdata.prefab = "campfirefire"
                inst.components.burnable.fxdata.follow = "firefx"
            end
        end
    end

    inst:ListenForEvent(
        "itemget",
        function(inst, data)
            if not (data and data.src_pos) then
                return
            end
            --[[local slot = data.slot
			if (data.slot == 1 or data.slot >= 5) then
			    local item = inst.components.container:GetItemInSlot(slot)
				if item.components.stackable then
				    item.components.stackable:Put(item, data.src_pos)
				end
			end]]

            if data.item and (data.item.prefab == "bluegem" or data.item.prefab == "redgem") then
                if data.item.prefab == "bluegem" then
                    inst.components.burnable.fxdata.prefab = "coldfirefire"
                    inst.components.burnable.fxdata.follow = nil
                    inst:AddTag("fridge")
					inst.cookstate = "cold"
                elseif data.item.prefab == "redgem" then
                    inst:RemoveTag("fridge")
                    inst.components.burnable.fxdata.prefab = "campfirefire"
                    inst.components.burnable.fxdata.follow = "firefx"
					inst.cookstate = "fire"
                end
                ShowAnim(inst)
            else
                if data.item.components.fuel then
                    -- AddFuel(inst)
                elseif cooking.IsCookingIngredient(data.item.prefab) then
                    EasyCook(inst)
                end
            end


        end
    )

    inst:ListenForEvent(
        "itemlost",
        function(inst, data)
            if not data then
                return
            end

            if data.prev_item.prefab == "bluegem" or data.prev_item.prefab == "redgem" then
                inst:RemoveTag("fridge")
                inst.components.burnable.fxdata.prefab = "campfirefire"
                inst.components.burnable.fxdata.follow = "firefx"
				inst.cookstate = nil
            end
        end
    )

    return inst
end

local function ondeploy(inst, pt, deployer)
    local pot = SpawnPrefab("norse_mythology_portablepot")
    if pot ~= nil then
        pot.Physics:SetCollides(false)
        pot.Physics:Teleport(pt.x, 0, pt.z)
        pot.Physics:SetCollides(true)

        pot:PushEvent("onbuilt", { builder = deployer, pos = pt })

        inst:Remove()
    end
end

local function norse_mythology_portablepot_item()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("norse_mythology_portablepot_item")
    inst.AnimState:SetBuild("norse_mythology_portablepot")
    inst.AnimState:PlayAnimation("idle")

    inst.Transform:SetScale(1.5, 1.5, 1.5)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable") --可检查组件

    inst:AddComponent("inventoryitem") --物品组件
    inst.components.inventoryitem.atlasname = ("images/inventoryimages/norse_mythology_portablepot_item.xml")

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("norse_mythology_portablepot", fn, assets), Prefab("norse_mythology_portablepot_item", norse_mythology_portablepot_item, assets), MakePlacer("norse_mythology_portablepot_placer", "norse_mythology_portablepot", "norse_mythology_portablepot", "place"), MakePlacer("norse_mythology_portablepot_item_placer", "norse_mythology_portablepot", "norse_mythology_portablepot", "place")
