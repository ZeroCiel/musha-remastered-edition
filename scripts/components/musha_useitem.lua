local Musha_Useitem = Class(function(self, inst)
    self.inst = inst
    self.fn = nil
    inst:AddTag("musha_item")
end)

function Musha_Useitem:OnRemoveFromEntity()
    self.inst:RemoveTag("musha_item")
end

function Musha_Useitem:SetFn(fn)
    self.fn = fn
end

function Musha_Useitem:UseItem(doer)
    if doer ~= nil then
        self.fn(self.inst, doer)
    end
end

return Musha_Useitem
