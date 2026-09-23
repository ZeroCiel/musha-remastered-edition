local Widget = require "widgets/widget"
local Text = require "widgets/text"

My_Image = Class(Widget, function(self, atlas, tex, default_tex, String)
    Widget._ctor(self, "My_Image")

    self.inst.entity:AddImageWidget()

    assert( ( atlas == nil and tex == nil ) or ( atlas ~= nil and tex ~= nil ) )

    self.font = NEWFONT
    self.textcolour = {0, 0, 0, 1}
    self.textfocuscolour = {0, 0, 0, 1}
    self.text = self:AddChild(Text(self.font, 40))
    self.text:SetVAlign(ANCHOR_MIDDLE)
    self.text:SetColour(self.textcolour)
    self.text:SetString(String or "")
    self.text:Show()

	self.tint = {1,1,1,1}

    if atlas and tex then
		self:SetTexture(atlas, tex, default_tex)
    end
end)

function My_Image:__tostring()
	return string.format("%s - %s:%s", self.name, self.atlas or "", self.texture or "")
end

function My_Image:DebugDraw_AddSection(dbui, panel)
    My_Image._base.DebugDraw_AddSection(self, dbui, panel)

    dbui.Spacing()
    dbui.Text("My_Image")
    dbui.Indent() do
        -- Clearly show the bounds of blank and other hard-to-see
        -- My_Images. (Great for debugging buttons.)
        local show_region = self.region_preview ~= nil
        local changed, show = dbui.Checkbox("white out My_Image region", show_region)
        if changed then
            if show then
                self.region_preview = self:AddChild(My_Image("My_Images/ui.xml", "white.tex"))
                self.region_preview:SetSize(self:GetSize())
            else
                self.region_preview:Kill()
                self.region_preview = nil
            end
        end

        -- SetTexture doesn't gracefully fail on bad input, so don't allow editing
        -- (we'd call SetTexture for every keystroke).
        local function My_Image_from_atlastexture(label, atlastexture)
            dbui.SetNextTreeNodeOpen(true, dbui.constant.SetCond.Appearing)
            if dbui.TreeNode(label ..": ".. tostring(atlastexture)) then
                if atlastexture then
                    local parts = atlastexture:split()
                    if #parts == 2 then
                        dbui.AtlasMy_Image(parts[1], parts[2], self:GetSize())
                    end
                end
                dbui.TreePop()
            end
        end
        -- Building a string to parse it is ugly, but not uglier than handling two
        -- input types. Must pass empty text for nil so AtlasMy_Image isn't called on
        -- invalid data!
        My_Image_from_atlastexture("atlas:texture", string.format("%s:%s", self.atlas or "", self.texture or ""))
        My_Image_from_atlastexture("mouse over texture", self.mouseovertex)
        My_Image_from_atlastexture("disabled texture", self.disabledtex)

        local changed, r,g,b,a = dbui.ColorEdit4("tint", unpack(self.tint))
        if changed then
            self:SetTint(r, g, b, a)
        end
        local w,h = self:GetSize()
        changed, w,h = dbui.DragFloat3("size", w,h,0, 1,1,1000)
        if changed then
            self:SetSize(w,h)
            if self.region_preview then
                self.region_preview:SetSize(self:GetSize())
            end
        end
    end
    dbui.Unindent()
end

function My_Image:SetAlphaRange(min, max)
	self.inst.ImageWidget:SetAlphaRange(min, max)
end

-- NOTE: the default_tex parameter is handled, but using
-- it will produce a bunch of warnings in the log.
function My_Image:SetTexture(atlas, tex, default_tex)
    assert( atlas ~= nil )
    assert( tex ~= nil )

	self.atlas = type(atlas) == "string" and resolvefilepath(atlas) or atlas
	self.texture = tex
	--print(atlas, tex)
    self.inst.ImageWidget:SetTexture(self.atlas, self.texture, default_tex)

	-- changing the texture may have changed our metrics
	self.inst.UITransform:UpdateTransform()
end

function My_Image:SetMouseOverTexture(atlas, tex)
	self.atlas = type(atlas) == "string" and resolvefilepath(atlas) or atlas
	self.mouseovertex = tex
end

function My_Image:SetDisabledTexture(atlas, tex)
	self.atlas = type(atlas) == "string" and resolvefilepath(atlas) or atlas
	self.disabledtex = tex
end

function My_Image:SetSize(w,h)
    if type(w) == "number" then
        self.inst.ImageWidget:SetSize(w,h)
    else
        self.inst.ImageWidget:SetSize(w[1],w[2])
    end
end

function My_Image:GetSize()
    local w, h = self.inst.ImageWidget:GetSize()
    return w, h
end

function My_Image:GetScaledSize()
    local w, h = self.inst.ImageWidget:GetSize()
    local w1, h1 = self:GetLooseScale()
    local w2, h2 = self:GetParent():GetLooseScale()
    return w*w1*w2, h*h1*h2
end

function My_Image:ScaleToSize(w, h)
	local w0, h0 = self.inst.ImageWidget:GetSize()
	local scalex = w / w0
	local scaley = h / h0
	self:SetScale(scalex, scaley, 1)
end

function My_Image:ScaleToSizeIgnoreParent(w, h)
    local w0, h0 = self.inst.ImageWidget:GetSize()
    local w1, h1 = self:GetParent():GetLooseScale()
	local scalex = w / w0
    local scaley = h / h0
    self:SetScale(scalex/w1, scaley/h1, 1)
end

function My_Image:SetTint(r,g,b,a)
    self.inst.ImageWidget:SetTint(r,g,b,a)
    self.tint = {r, g, b, a}
end

function My_Image:SetFadeAlpha(a, skipChildren)
	if not self.can_fade_alpha then return end

    self.inst.ImageWidget:SetTint(self.tint[1], self.tint[2], self.tint[3], self.tint[4] * a)
    Widget.SetFadeAlpha( self, a, skipChildren )
end

function My_Image:SetVRegPoint(anchor)
    self.inst.ImageWidget:SetVAnchor(anchor)
end

function My_Image:SetHRegPoint(anchor)
    self.inst.ImageWidget:SetHAnchor(anchor)
end

function My_Image:OnMouseOver()
	--print("My_Image:OnMouseOver", self)
	if self.enabled and self.mouseovertex then
		self.inst.ImageWidget:SetTexture(self.atlas, self.mouseovertex)
	end
	Widget.OnMouseOver( self )
end

function My_Image:OnMouseOut()
	--print("My_Image:OnMouseOut", self)
	if self.enabled and self.mouseovertex then
		self.inst.ImageWidget:SetTexture(self.atlas, self.texture)
	end
	Widget.OnMouseOut( self )
end

function My_Image:OnEnable()
    if self.mouse_over_self then
		self:OnMouseOver()
	else
		self.inst.ImageWidget:SetTexture(self.atlas, self.texture)
	end
end

function My_Image:OnDisable()
	self.inst.ImageWidget:SetTexture(self.atlas, self.disabledtex)
end

function My_Image:SetEffect(filename)
    self.inst.ImageWidget:SetEffect(filename)

    if filename == "shaders/ui_cc.ksh" then
        --hack for faked ambient lighting influence (common_postinit, quagmire.lua)
        --might need to get the colour from the gamemode???
        --If we're going to use the ui_cc shader again, we'll have to have a more sane implementation for setting the ambient lighting influence
        self.inst.ImageWidget:SetEffectParams( 0.784, 0.784, 0.784, 1)
    end
end

function My_Image:SetEffectParams(param1, param2, param3, param4)
	self.inst.ImageWidget:SetEffectParams(param1, param2, param3, param4)
end

function My_Image:SetEffectParams2(param1, param2, param3, param4)
    self.inst.ImageWidget:SetEffectParams2(param1, param2, param3, param4)
end

function My_Image:EnableEffectParams(enabled)
	self.inst.ImageWidget:EnableEffectParams(enabled)
end

function My_Image:EnableEffectParams2(enabled)
    self.inst.ImageWidget:EnableEffectParams2(enabled)
end

function My_Image:SetUVScale(xScale, yScale)
	self.inst.ImageWidget:SetUVScale(xScale, yScale)
end

function My_Image:SetUVMode(uvmode)
    self.inst.ImageWidget:SetUVMode(uvmode)
end

function My_Image:SetBlendMode(mode)
	self.inst.ImageWidget:SetBlendMode(mode)
end

return My_Image
