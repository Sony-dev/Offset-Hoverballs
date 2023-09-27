local gsModes = "offset_hoverball"
local gsClass = "offset_hoverball"

if (CLIENT) then

	TOOL.Information = {
		{name = "holdshift"  	, icon = "gui/info" , 	stage = 0},
		{name = "left"      	, icon = "gui/lmb.png", stage = 0},
		{name = "right"     	, icon = "gui/rmb.png", stage = 0},
		{name = "reload"    	, icon = "gui/r.png"  , stage = 0},
		
		{name = "holdingshift"  , icon = "gui/info",	stage = 1},
		{name = "shift_left"  	, icon = "gui/lmb.png", stage = 1},
		{name = "shift_right" 	, icon = "gui/rmb.png", stage = 1},
		{name = "shift_reload"	, icon = "gui/r.png"  , stage = 1},
	}

	language.Add("tool."..gsModes..".category", "Construction")
end

TOOL.Name       = language and language.GetPhrase("tool."..gsModes..".name")
TOOL.Category   = language and language.GetPhrase("tool."..gsModes..".category")
TOOL.Command    = nil
TOOL.ConfigName = "" -- No external configuration files to define the layout of the tool config-hud

-- Default preset values.
TOOL.ClientConVar = {
	["force"] = "100",
	["height"] = "100",
	["air_resistance"] = "2",
	["angular_damping"] = "10",
	["hover_damping"] = "10",
	["detects_water"] = "true",
	["model"] = "models/dav0r/hoverball.mdl",
	["adjust_speed"] = "0.8",
	["brake_resistance"] = "15",
	["nocollide"] = "true",
	["detects_water"] = "true",
	["detects_props"] = "true",
	["start_on"] = "true",
	
	-- Experimental settings:
	["slipenabled"] = "0",
	["slip"] = "1000",
	["minslipangle"] = "0.1",

	-- Toolgun settings:
	["spawnmargin"] = "1",
	["useparenting"] = "false",
	["copykeybinds"] = "true",
	["showlasers"] = "true",
	["alwaysshowlasers"] = "false",
	["showdecimals"] = "false",  -- Per-client setting to show/hide decimals on hover UI

	-- Toggle numpad keys
	["key_toggle"]       = "51", -- Numpad enter
	["key_heightdown"]   = "49", -- Numpad -
	["key_heightup"]     = "50", -- Numpad +
	["key_brake"]        = "37"  -- Numpad 0
}

list.Set("OffsetHoverballModels", "models/dav0r/hoverball.mdl", {})
list.Set("OffsetHoverballModels", "models/maxofs2d/hover_basic.mdl", {})
list.Set("OffsetHoverballModels", "models/maxofs2d/hover_classic.mdl", {})
list.Set("OffsetHoverballModels", "models/maxofs2d/hover_plate.mdl", {})
list.Set("OffsetHoverballModels", "models/maxofs2d/hover_propeller.mdl", {})
list.Set("OffsetHoverballModels", "models/maxofs2d/hover_rings.mdl", {})
list.Set("OffsetHoverballModels", "models/Combine_Helicopter/helicopter_bomb01.mdl", {})
list.Set("OffsetHoverballModels", "models/props_junk/sawblade001a.mdl", {})
list.Set("OffsetHoverballModels", "models/props_wasteland/prison_lamp001c.mdl", {})
list.Set("OffsetHoverballModels", "models/props_phx/wheels/drugster_front.mdl", {})
list.Set("OffsetHoverballModels", "models/props_phx/wheels/metal_wheel1.mdl", {})
list.Set("OffsetHoverballModels", "models/props_phx/smallwheel.mdl", {})
list.Set("OffsetHoverballModels", "models/props_phx/wheels/magnetic_small.mdl", {})
list.Set("OffsetHoverballModels", "models/props_phx/wheels/magnetic_medium.mdl", {})
list.Set("OffsetHoverballModels", "models/props_phx/wheels/magnetic_large.mdl", {})
list.Set("OffsetHoverballModels", "models/mechanics/wheels/wheel_smooth_24f.mdl", {})
list.Set("OffsetHoverballModels", "models/mechanics/wheels/wheel_smooth_48.mdl", {})
list.Set("OffsetHoverballModels", "models/mechanics/wheels/wheel_smooth_72.mdl", {})
list.Set("OffsetHoverballModels", "models/mechanics/wheels/wheel_smooth_18r.mdl", {})
list.Set("OffsetHoverballModels", "models/mechanics/wheels/wheel_smooth_24.mdl", {})
list.Set("OffsetHoverballModels", "models/mechanics/wheels/wheel_rounded_36s.mdl", {})
list.Set("OffsetHoverballModels", "models/props_phx/gears/bevel9.mdl", {})
list.Set("OffsetHoverballModels", "models/props_phx/gears/bevel12.mdl", {})
list.Set("OffsetHoverballModels", "models/props_phx/gears/bevel24.mdl", {})
list.Set("OffsetHoverballModels", "models/props_phx/gears/bevel36.mdl", {})
list.Set("OffsetHoverballModels", "models/hunter/plates/plate025x025.mdl", {})
list.Set("OffsetHoverballModels", "models/hunter/blocks/cube025x025x025.mdl", {})
list.Set("OffsetHoverballModels", "models/hunter/blocks/cube05x05x025.mdl", {})
list.Set("OffsetHoverballModels", "models/hunter/blocks/cube05x05x05.mdl", {})
list.Set("OffsetHoverballModels", "models/hunter/plates/plate.mdl", {})
list.Set("OffsetHoverballModels", "models/squad/sf_plates/sf_plate1x1.mdl", {})
list.Set("OffsetHoverballModels", "models/squad/sf_plates/sf_plate2x2.mdl", {})
list.Set("OffsetHoverballModels", "models/hunter/misc/sphere025x025.mdl", {})
list.Set("OffsetHoverballModels", "models/props_phx/misc/potato_launcher_cap.mdl", {})
list.Set("OffsetHoverballModels", "models/xqm/jetenginepropeller.mdl", {})
list.Set("OffsetHoverballModels", "models/items/combine_rifle_ammo01.mdl", {})
list.Set("OffsetHoverballModels", "models/jaanus/thruster_flat.mdl", {})
list.Set("OffsetHoverballModels", "models/props_phx2/garbage_metalcan001a.mdl", {})

if (SERVER) then
	CreateConVar("sbox_max"..gsClass.."s", "20", FCVAR_ARCHIVE, "Max offset hoverballs per player", 0)

	function CreateOffsetHoverball(ply, pos, ang, hoverdistance, hoverforce, damping, rotdamping,
		                             hovdamping, detects_water, detects_props, start_on, adjustspeed, model,
		                             nocollide, key_toggle, key_heightup, key_heightdown,
		                             key_brake, brakeresistance, slip, minslipangle)

		if (IsValid(ply) and not ply:CheckLimit(gsClass.."s")) then return nil end

		local ball = ents.Create(gsClass)

		-- Check whether we successfully made an entity, if not - bail
		if (not IsValid(ball)) then return nil end

		ball.hoverenabled = false -- Keep disabled until initialized

		ball:SetModel(model)
		ball:Spawn()

		if (IsValid(ply)) then
			-- Used for setting the creator player
			ball:SetPlayer(ply)
			ball:SetCreator(ply)

			-- Used for server ownership and cleanup
			ply:AddCount(gsClass.."s", ball) -- Add to what is registered via `cleanup.Register`
			ply:AddCleanup(gsClass.."s", ball) -- Add to our personal hoverball cleanup button
		end

		-- Either specified by our spawn tool, or filled in automatically by the duplicator.
		ball:Setup(ply, pos, ang, hoverdistance, hoverforce, damping,
			rotdamping, hovdamping, detects_water, detects_props, start_on,
			adjustspeed, nocollide, key_toggle,
			key_heightup, key_heightdown, key_brake,
			brakeresistance, slip, minslipangle)

		DoPropSpawnedEffect(ball)

		local phys = ball:GetPhysicsObject()
		if (phys:IsValid()) then phys:Wake() end

		ball:PhysicsUpdate()

		return ball
	end

	-- This is deliberately missing "ply" as first argument here, as the duplicator adds it in automatically when pasting.
	duplicator.RegisterEntityClass(gsClass, CreateOffsetHoverball, "pos", "ang", "hoverdistance", "hoverforce",
		"damping", "rotdamping", "hovdamping", "detects_water", "detects_props", "start_on", "adjustspeed", "model", "nocollide", "key_toggle",
		"key_heightup", "key_heightdown", "key_brake", "brakeresistance", "slip", "minslipangle")

end

local ConVarsDefault = TOOL:BuildConVarList()

cleanup.Register(gsClass.."s")

function TOOL:SetCenterOBB(ent, tr)
	local ang, mar = ent:GetAngles(), self:GetClientNumber("spawnmargin")
	local obb = ent:OBBCenter(); obb:Negate(); obb:Rotate(ang)
	local xbb = ent:OBBMaxs(); xbb:Sub(ent:OBBMins()); xbb:Rotate(ang)
	local nrm = Vector(tr.HitNormal)
	local mox = (xbb:Dot(nrm) / 2)
	obb:Add(tr.HitPos); nrm:Mul(mar * mox)
	obb:Add(nrm); ent:SetPos(obb)
	return obb
end


local frmNotif = "notification.AddLegacy(\"%s\", NOTIFY_%s, 6)"
function TOOL:NotifyAction(mesg, ntype)
	self:GetOwner():SendLua(frmNotif:format(mesg, ntype))
end

function TOOL:UpdateExistingHB(ball)
	
	-- Read client's configurations
	local height           = self:GetClientNumber("height")
	local force            = self:GetClientNumber("force")
	local air_resistance   = self:GetClientNumber("air_resistance")
	local angular_damping  = self:GetClientNumber("angular_damping")
	local hover_damping    = self:GetClientNumber("hover_damping")
	local adjust_speed     = self:GetClientNumber("adjust_speed")
	local nocollide        = self:GetClientNumber("nocollide")
	local key_brake        = self:GetClientNumber("key_brake")
	local key_toggle       = self:GetClientNumber("key_toggle")
	local key_heightup     = self:GetClientNumber("key_heightup")
	local key_heightdown   = self:GetClientNumber("key_heightdown")
	local minslipangle     = self:GetClientNumber("minslipangle")
	local brake_resistance = self:GetClientNumber("brake_resistance")
	local start_on         = tobool(self:GetClientNumber("start_on"))
	local detects_water    = tobool(self:GetClientNumber("detects_water"))
	local detects_props    = tobool(self:GetClientNumber("detects_props"))
	local slipping         = tobool(self:GetClientNumber("slipenabled")) and self:GetClientNumber("slip") or 0

	ball:Setup(
		ply,
		nil,
		nil,
		height,
		force,
		air_resistance,
		angular_damping,
		hover_damping,
		detects_water,
		detects_props,
		start_on,
		adjust_speed,
		nocollide,
		key_toggle,
		key_heightup,
		key_heightdown,
		key_brake,
		brake_resistance,
		slipping,
		minslipangle
	)

end

function TOOL:ApplyContraption(trace, func, atyp)
	if (CLIENT) then return false end
	
	-- Read the trace entity and validate it.
	local tent = trace.Entity
	if not IsValid(tent) then self:NotifyAction("Contraption is not eligible for this action!", "ERROR") return end
	local tenc = tent:GetClass()
	if tenc == "" then self:NotifyAction("Trace class is not eligible for this action!", "ERROR") return end
	
	-- For this one we can click on a prop that has multiple hoverballs attached and update them all at once.
	local prc, HB = tostring(atyp or "N/A"), 0
	local CN = constraint.GetAllConstrainedEntities( tent )
	if (constraint.HasConstraints( tent )) then
		for k, v in pairs(CN) do
			if (IsValid(v) and v:GetClass() == gsClass) then local suc, out = pcall(func, v)
				if (not suc) then self:NotifyAction("Internal error: "..tostring(out), "ERROR"); return end
				if (not out) then self:NotifyAction("Execution error: "..tostring(out), "ERROR"); return end
				HB = HB + 1
			end
		end
		if HB ~= 0 then
			self:NotifyAction("Successfully "..prc.." "..HB.." hoverball"..((HB == 1) and "" or "s").."!", "GENERIC"); return
		end
	end
	self:NotifyAction("No hoverball attachments found for "..prc.."!", "ERROR")
end

function TOOL:LeftClick(trace)
	local model = self:GetClientInfo("model")
	local tent, ply = trace.Entity, self:GetOwner()

	if (CLIENT) then return false end

	-- Read client's configurations
	local model            = self:GetClientInfo("model")
	local height           = self:GetClientNumber("height")
	local force            = self:GetClientNumber("force")
	local air_resistance   = self:GetClientNumber("air_resistance")
	local angular_damping  = self:GetClientNumber("angular_damping")
	local hover_damping    = self:GetClientNumber("hover_damping")
	local adjust_speed     = self:GetClientNumber("adjust_speed")
	local nocollide        = self:GetClientNumber("nocollide")
	local key_brake        = self:GetClientNumber("key_brake")
	local key_toggle       = self:GetClientNumber("key_toggle")
	local key_heightup     = self:GetClientNumber("key_heightup")
	local key_heightdown   = self:GetClientNumber("key_heightdown")
	local minslipangle     = self:GetClientNumber("minslipangle")
	local brake_resistance = self:GetClientNumber("brake_resistance")
	local start_on         = tobool(self:GetClientNumber("start_on"))
	local detects_water    = tobool(self:GetClientNumber("detects_water"))
	local detects_props    = tobool(self:GetClientNumber("detects_props"))
	local useparenting     = tobool(self:GetClientNumber("useparenting"))
	local slipping         = tobool(self:GetClientNumber("slipenabled")) and self:GetClientNumber("slip") or 0

	-- Click on existing offset hoverballs to update their settings.
	if (IsValid(tent) and tent:GetClass() == gsClass) then

		tent:Setup(
			ply,
			nil, -- Skip updating the position
			nil, -- Skip updating the angles
			height,
			force,
			air_resistance,
			angular_damping,
			hover_damping,
			detects_water,
			detects_props,
			start_on,
			adjust_speed,
			nocollide,
			key_toggle,
			key_heightup,
			key_heightdown,
			key_brake,
			brake_resistance,
			slipping,
			minslipangle
		)
		self:NotifyAction("Hoverball updated!", "GENERIC")
		ply:EmitSound("buttons/button16.wav", 45, 100, 0.5)

		return true -- Don't forget to return true or the toolgun animation/effect doesn't play.
	else
		
		-- Don't place hoverballs on invalid entities.
		if not IsValid(tent) and not tent:IsWorld() then
			self:NotifyAction("Must be placed on a valid entity!", "ERROR")
			ply:EmitSound("ambient/machines/squeak_1.wav", 45, 100, 0.5) -- This sound is silly and I love it.
			return false
		end
		
		-- Abort if spawn position is outside the world.
		if not util.IsInWorld( trace.HitPos ) then
			self:NotifyAction("Cannot spawn here, trace is outside the world.", "ERROR")
			ply:EmitSound("ambient/machines/squeak_1.wav", 45, 100, 0.5)		
			return false
		end
		
		-- Make sure to pass angle to be stored in duplicator
		local ang = trace.HitNormal:Angle(); ang.pitch = ang.pitch + 90

		-- Not updating anything, Place a new hoverball instead.
		local ball = CreateOffsetHoverball(
			ply,
			trace.HitPos,
			ang,
			height,
			force,
			air_resistance,
			angular_damping,
			hover_damping,
			detects_water,
			detects_props,
			start_on,
			adjust_speed,
			model,
			nocollide,
			key_toggle,
			key_heightup,
			key_heightdown,
			key_brake,
			brake_resistance,
			slipping,
			minslipangle
		)

		if not IsValid(ball) then return false end

		-- Call the dedicated method to position the ball.
		local BallSpawnPos = self:SetCenterOBB(ball, trace)

		-- Check if adding the margin offset would put us outside the world.
		if not util.IsInWorld( BallSpawnPos ) then
			self:NotifyAction("Cannot spawn here, position is outside the world.", "ERROR")
			ply:EmitSound("ambient/machines/squeak_1.wav", 45, 100, 0.5)
			ball:Remove()
			return false
		end

		-- If OHB is spawned directly on the world then it won't weld or parent, and holding shift does nothing.
		if not tent:IsWorld() then

			local weld = constraint.Weld(ball, tent, 0, trace.PhysicsBone, 0, true, true)

			-- Will grab the whole contraption and shove it in the trace filter
			ball:UpdateFilter() -- There must be a constraint for it to work

			-- Hold shift when placing to automatically set hover height.
			if (ply:KeyDown(IN_SPEED))  then
				local tr = ball:GetTrace(nil, -50000)
				ball.hoverdistance = tr.distance

				-- ENT:Setup doesn't know we've adjusted the height, update hover text manually.
				if start_on then ball:UpdateHoverText() else ball:UpdateHoverText(2) end
			end

			if useparenting then ball:SetParent(tent) end
		end
		
		undo.Create("Offset hoverball")
		undo.AddEntity(ball) -- Remove the weld on undo
		if IsValid(weld) then undo.AddEntity(weld) end
		undo.SetPlayer(ply) -- Specify player
		undo.Finish()

		return true
	end
end


-- Toolgun reload removes hoverballs.
function TOOL:Reload(trace)

	if (CLIENT) then return end

	local tent, ply = trace.Entity, self:GetOwner()

	-- Only remove all from contraption if they click the contraption itself, not a hoverball. Lower risk of deleting all when you only intended one.
	-- TODO: Should we have an ownership check of some kind here? I don't know how this would interact with prop-protection addons in multiplayer.
	if (ply:KeyDown(IN_SPEED) and tent:GetClass() ~= gsClass) then
		self:ApplyContraption(trace, function(v) SafeRemoveEntity(v); return true end, "removed")
		return true
	end

	if (IsValid(tent) and tent:GetClass() == gsClass and tent:GetCreator() == ply) then
		SafeRemoveEntity(tent)
		return true
	end

end


-- Copy settings with right-click.
function TOOL:RightClick(trace)
	if (CLIENT) then return false end

	local tent, ply = trace.Entity, self:GetOwner()

	-- SHIFT + Right click updates all hoverballs, provided you're looking at a contraption.
	if ply:KeyDown(IN_SPEED) then
		self:ApplyContraption(trace, function(v) self:UpdateExistingHB(v); return true end, "updated")
		return true
	end

	if (IsValid(tent) and tent:GetClass() == gsClass) then

		ply:ConCommand(gsModes.."_force"           .." "..tent.hoverforce                 .."\n")
		ply:ConCommand(gsModes.."_height"          .." "..tent.hoverdistance              .."\n")
		ply:ConCommand(gsModes.."_air_resistance"  .." "..tent.damping                    .."\n")
		ply:ConCommand(gsModes.."_angular_damping" .." "..tent.rotdamping                 .."\n")
		ply:ConCommand(gsModes.."_hover_damping"   .." "..tent.hovdamping                 .."\n")
		ply:ConCommand(gsModes.."_detects_water"   .." "..(tent.detects_water and 1 or 0) .."\n")
		ply:ConCommand(gsModes.."_detects_props"   .." "..(tent.detects_props and 1 or 0) .."\n")
		ply:ConCommand(gsModes.."_nocollide"       .." "..(tent.nocollide     and 1 or 0) .."\n")
		ply:ConCommand(gsModes.."_adjust_speed"    .." "..tent.adjustspeed                .."\n")
		ply:ConCommand(gsModes.."_brake_resistance".." "..tent.brakeresistance            .."\n")
		ply:ConCommand(gsModes.."_slip"            .." "..tent.slip                       .."\n")
		ply:ConCommand(gsModes.."_minslipangle"    .." "..tent.minslipangle               .."\n")

		-- Copy control hotkeys if enabled.
		if tobool(self:GetClientNumber("copykeybinds")) then
			ply:ConCommand(gsModes.."_key_heightup"  .." "..tent.key_heightup               .."\n")
			ply:ConCommand(gsModes.."_key_heightdown".." "..tent.key_heightdown             .."\n")
			ply:ConCommand(gsModes.."_key_toggle"    .." "..tent.key_toggle                 .."\n")
			ply:ConCommand(gsModes.."_key_brake"     .." "..tent.key_brake                  .."\n")
		end

		self:NotifyAction("Hoverball settings copied!", "GENERIC")
		ply:EmitSound("buttons/button14.wav", 45, 100, 0.5)
		return true
	end
end


if CLIENT then

	-- Creates nice header labels for control panel sections.
	function OHB_InsertHeader(text, parent, toppadding, bottompadding)

		if not IsValid(parent) then return nil end
		text = string.TrimRight( text, ":" )

		local HeaderLbl = vgui.Create( "DLabel", parent )
		
		-- Use skin-defined label colours, except for gmod derma default skin where it looks awful.
		HeaderLbl.TxtColor = (HeaderLbl:GetSkin().Name == "Default") and Color(60,60,60,255) or SKIN.Colours.Label.Default
		
		HeaderLbl:Dock(TOP)
		HeaderLbl:DockMargin(0,toppadding or 2,0, bottompadding or 2)
		HeaderLbl:SetText( text )
		HeaderLbl:SetFont( "DermaDefaultBold" )
		HeaderLbl:SetTextInset( 0, HeaderLbl:GetTall() + 100 ) 
		HeaderLbl:SetTall(draw.GetFontHeight( "DermaDefaultBold" )) -- Only needs to be as tall as the text, DockMargin will handle the spacing.

		function HeaderLbl:Paint( w, h )
			if not self:GetText() then return end
			local TW,_ = draw.SimpleText(self:GetText(), "DermaDefaultBold", (w/2), (h/2), self.TxtColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.RoundedBox(0, 5, h/2, w/2-TW/2-10, 1, self.TxtColor)
			draw.RoundedBox(0, w/2+TW/2+10, h/2, w/2, 1, self.TxtColor)
		end

		return HeaderLbl
	end
end


function TOOL.BuildCPanel(panel)

	panel:ClearControls(); panel:DockPadding(5, 0, 5, 10)
	local drmSkin, pItem = panel:GetSkin() -- pItem is the current panel created

	pItem = panel:SetName(language.GetPhrase("tool."..gsModes..".name"))
	pItem = panel:Help   (language.GetPhrase("tool."..gsModes..".desc"))

	pItem = vgui.Create("ControlPresets", panel)
	pItem:SetPreset(gsModes)
	pItem:AddOption("Default", ConVarsDefault)
	for key, val in pairs(table.GetKeys(ConVarsDefault)) do pItem:AddConVar(val) end
	pItem:Dock(TOP); panel:AddItem(pItem)

	pItem = panel:PropSelect("Model", gsModes.."_model", list.Get("OffsetHoverballModels"), 5)

	pItem = panel:NumSlider(language.GetPhrase("tool."..gsModes..".force"), gsModes.."_force", 5, 1000, 2)
	pItem:SetDefaultValue(ConVarsDefault[gsModes.."_force"])
	pItem.Label:SetTooltip(language.GetPhrase("tool."..gsModes..".force_tt"))

	pItem = panel:NumSlider(language.GetPhrase("tool."..gsModes..".height"), gsModes.."_height", 5, 1500, 2)
	pItem:SetDefaultValue(ConVarsDefault[gsModes.."_height"])
	pItem.Label:SetTooltip(language.GetPhrase("tool."..gsModes..".height_tt"))

	pItem = panel:NumSlider(language.GetPhrase("tool."..gsModes..".air_resistance"), gsModes.."_air_resistance", 0, 30, 2)
	pItem:SetDefaultValue(ConVarsDefault[gsModes.."_air_resistance"])
	pItem.Label:SetTooltip(language.GetPhrase("tool."..gsModes..".air_resistance_tt"))

	pItem = panel:NumSlider(language.GetPhrase("tool."..gsModes..".angular_damping"), gsModes.."_angular_damping", 0, 100, 2)
	pItem:SetDefaultValue(ConVarsDefault[gsModes.."_angular_damping"])
	pItem.Label:SetTooltip(language.GetPhrase("tool."..gsModes..".angular_damping_tt"))

	pItem = panel:NumSlider(language.GetPhrase("tool."..gsModes..".hover_damping"), gsModes.."_hover_damping", 0, 100, 2)
	pItem:SetDefaultValue(ConVarsDefault[gsModes.."_hover_damping"])
	pItem.Label:SetTooltip(language.GetPhrase("tool."..gsModes..".hover_damping_tt"))

	pItem = panel:ControlHelp(language.GetPhrase("tool."..gsModes..".mouseui"))
	pItem:DockMargin(8,10,0,0)

	pItem = panel:CheckBox(language.GetPhrase("tool."..gsModes..".detects_water"), gsModes.."_detects_water")
	pItem:SetChecked(ConVarsDefault[gsModes.."_detects_water"])
	pItem:SetTooltip(language.GetPhrase("tool."..gsModes.."._detects_water_tt"))

	pItem = panel:CheckBox(language.GetPhrase("tool."..gsModes..".detects_props"), gsModes.."_detects_props")
	pItem:SetTooltip(language.GetPhrase("tool."..gsModes..".detects_props_tt"))
	pItem:SetChecked(ConVarsDefault[gsModes.."_detects_props"])

	pItem = panel:CheckBox(language.GetPhrase("tool."..gsModes..".nocollide"), gsModes.."_nocollide")
	pItem:SetChecked(ConVarsDefault[gsModes.."_nocollide"])

	pItem = panel:CheckBox(language.GetPhrase("tool."..gsModes..".start_on"), gsModes.."_start_on")
	pItem:SetChecked(ConVarsDefault[gsModes.."_start_on"])

	pItem = vgui.Create("CtrlNumPad", panel)
	pItem:SetLabel1(language.GetPhrase("tool."..gsModes..".key_heightup"))
	pItem:SetLabel2(language.GetPhrase("tool."..gsModes..".key_heightdown"))
	pItem:SetConVar1(gsModes.."_key_heightup")
	pItem:SetConVar2(gsModes.."_key_heightdown")
	panel:AddPanel(pItem)
	pItem:DockMargin(0,10,0,0)

	pItem = vgui.Create("CtrlNumPad", panel)
	pItem:SetLabel1(language.GetPhrase("tool."..gsModes..".key_toggle"))
	pItem:SetLabel2(language.GetPhrase("tool."..gsModes..".key_brake"))
	pItem:SetConVar1(gsModes.."_key_toggle")
	pItem:SetConVar2(gsModes.."_key_brake")
	panel:AddPanel(pItem)

	pItem = panel:NumSlider(language.GetPhrase("tool."..gsModes..".adjust_speed"), gsModes.."_adjust_speed", 0, 100, 2)
	pItem:SetDefaultValue(ConVarsDefault[gsModes.."_adjust_speed"])
	pItem.Label:SetTooltip(language.GetPhrase("tool."..gsModes..".adjust_speed_tt"))
	pItem:DockMargin(0,10,0,0)

	pItem = panel:NumSlider(language.GetPhrase("tool."..gsModes..".brake_resistance"), gsModes.."_brake_resistance", 1, 30, 2)
	pItem:SetDefaultValue(ConVarsDefault[gsModes.."_brake_resistance"])
	pItem.Label:SetTooltip(language.GetPhrase("tool."..gsModes..".brake_resistance_tt"))

	pItem = panel:ControlHelp(language.GetPhrase("tool."..gsModes..".slider_help1"))
	pItem:DockMargin(10,0,0,0)
	pItem = panel:ControlHelp(language.GetPhrase("tool."..gsModes..".slider_help2"))
	pItem:DockMargin(10,0,0,0)

	OHB_InsertHeader(language.GetPhrase("tool."..gsModes..".set_def"), panel, 30, 0)
	
	pItem = panel:NumSlider(language.GetPhrase("tool."..gsModes..".spawnmargin"), gsModes.."_spawnmargin", -2, 2, 2)
	pItem:SetDefaultValue(ConVarsDefault[gsModes.."_spawnmargin"])
	pItem.Label:SetTooltip(language.GetPhrase("tool."..gsModes..".spawnmargin_tt"))
	pItem:DockMargin(0,0,0,5)

	pItem = panel:CheckBox(language.GetPhrase("tool."..gsModes..".copykeybinds"), gsModes.."_copykeybinds")
	pItem:SetTooltip(language.GetPhrase("tool."..gsModes..".copykeybinds_tt"))
	pItem:SetChecked(ConVarsDefault[gsModes.."_copykeybinds"])

	pItem = panel:CheckBox(language.GetPhrase("tool."..gsModes..".showlasers"), gsModes.."_showlasers")
	pItem:SetTooltip(language.GetPhrase("tool."..gsModes..".showlasers_tt"))
	pItem:SetChecked(ConVarsDefault[gsModes.."_showlasers"])

	pItem = panel:CheckBox(language.GetPhrase("tool."..gsModes..".alwaysshowlasers"), gsModes.."_alwaysshowlasers")
	pItem:SetTooltip(language.GetPhrase("tool."..gsModes..".alwaysshowlasers_tt"))
	pItem:SetChecked(ConVarsDefault[gsModes.."_alwaysshowlasers"])

	pItem = panel:CheckBox(language.GetPhrase("tool."..gsModes..".showdecimals"), gsModes.."_showdecimals")
	pItem:SetTooltip(language.GetPhrase("tool."..gsModes..".showdecimals_tt"))
	pItem:SetChecked(ConVarsDefault[gsModes.."_showdecimals"])

	pItem = panel:CheckBox(language.GetPhrase("tool."..gsModes..".useparenting"), gsModes.."_useparenting")
	pItem:SetChecked(ConVarsDefault[gsModes.."_useparenting"])

	panel:ControlHelp(language.GetPhrase("tool."..gsModes..".parent_help1"))
	panel:ControlHelp(language.GetPhrase("tool."..gsModes..".parent_help2"))

	OHB_InsertHeader(language.GetPhrase("tool."..gsModes..".set_exp"), panel, 30, 0)

	pItem = panel:Help(language.GetPhrase("tool."..gsModes..".set_slip"))
	pItem:DockMargin(1,0,5,0)

	SlipToggle = panel:CheckBox(language.GetPhrase("tool."..gsModes..".slipenabled"), gsModes.."_slipenabled")
	SlipToggle:SetChecked(ConVarsDefault[gsModes.."_slipenabled"])

	SlipNSlider = panel:NumSlider(language.GetPhrase("tool."..gsModes..".slip"), gsModes.."_slip", 0, 5000, 0)
	SlipNSlider:SetTooltip(language.GetPhrase("tool."..gsModes..".slip_tt"))
	SlipNSlider:SetDefaultValue(ConVarsDefault[gsModes.."_slip"])

	-- This one has 3 decimal places as it has such a narrow range anyway.
	SlideAngle = panel:NumSlider(language.GetPhrase("tool."..gsModes..".minslipangle"), gsModes.."_minslipangle", 0.05, 1, 3)
	SlideAngle:SetTooltip(language.GetPhrase("tool."..gsModes..".minslipangle_tt"))
	SlideAngle:SetDefaultValue(ConVarsDefault[gsModes.."_minslipangle"])
	SlideAngle:DockMargin(0,5,0,0)

	SlipNSlider:SetEnabled(false)
	SlideAngle:SetEnabled(false)

	function SlipToggle:OnChange(checked)
		SlipNSlider:SetEnabled(checked)
		SlideAngle:SetEnabled(checked)
	end

	-- Little debug message to let users know if wire support is working.
	if WireLib then
		pItem = panel:ControlHelp(language.GetPhrase("tool."..gsModes..".wire_on"))
		pItem:SetColor( Color(39, 174, 96) )
		pItem:DockMargin(10,40,0,0)
	else
		pItem = panel:ControlHelp(language.GetPhrase("tool."..gsModes..".wire_off"))
		pItem:SetColor( Color(255, 71, 87) )
		pItem:DockMargin(10,40,0,0)
	end
end

function TOOL:UpdateGhostHoverball(ent, ply)

	if (not IsValid(ent)) then return end

	local trace = ply:GetEyeTrace()
	local tent = trace.Entity
	if IsValid(tent) then
		if (not trace.Hit or tent and
			(tent:IsPlayer() or tent:GetClass() == gsClass)) then
			ent:SetNoDraw(true)
			return
		end
	end

	local ang = trace.HitNormal:Angle()
	ang.pitch = ang.pitch + 90
	ent:SetAngles(ang)

	self:SetCenterOBB(ent, trace)

	ent:SetNoDraw(false)
end

function TOOL:Think()

	local ply = self:GetOwner()

	-- Updates the UI controls text when you hold shift.
	if ply:KeyDown( IN_SPEED ) then	self:SetStage( 1 ) else self:SetStage( 0 ) end

	local mdl = self:GetClientInfo("model")
	if not util.IsValidModel(mdl) then
		self:ReleaseGhostEntity()
		return
	end

	if (not IsValid(self.GhostEntity) or self.GhostEntity:GetModel() ~= mdl) then
		self:MakeGhostEntity(mdl, vector_origin, angle_zero)
	end

	self:UpdateGhostHoverball(self.GhostEntity, ply)
end
