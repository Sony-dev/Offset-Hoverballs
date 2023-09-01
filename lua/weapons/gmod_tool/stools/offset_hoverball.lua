local gsMode = TOOL.Mode

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

	language.Add("tool."..gsMode..".category", "Construction")
end

TOOL.Name       = language.GetPhrase and language.GetPhrase("tool."..gsMode..".name")
TOOL.Category   = language.GetPhrase and language.GetPhrase("tool."..gsMode..".category")
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

local ConVarsDefault = TOOL:BuildConVarList()
cleanup.Register("offset_hoverballs")

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
		pos,
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

	-- Read the trace entiy and validate it
	local tent = trace.Entity; if not IsValid(tent) then
		self:NotifyAction("Contraption is not eligible for this action!", "ERROR") end

	local tenc = tent:GetClass()

	-- For this one we can click on a prop that has multiple hoverballs attached and update them all at once.
	if tenc == "offset_hoverball" or tenc == "prop_physics" then
		local HB, CN = 0, constraint.GetAllConstrainedEntities( tent )
		if (constraint.HasConstraints( tent )) then
			for k, v in pairs(CN) do
				if (IsValid(v) and v:GetClass() == "offset_hoverball") then
					local suc, out = pcall(func, v)
					if (not suc) then self:NotifyAction("Internal error: "..tostring(out), "ERROR"); return end
					if (not out) then self:NotifyAction("Execution error: "..tostring(out), "ERROR"); return end
					HB = HB + 1
				end
			end

			if HB == 0 then self:NotifyAction("No attached hoverballs found", "ERROR"); return end

			self:NotifyAction("Successfully "..tostring(atyp or "N/A").." "..HB.." hoverball"..((HB == 1) and "" or "s").."!", "GENERIC")
		else
			self:NotifyAction("No hoverball attachments found!", "ERROR")
		end
	end
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
	local slipping         = tobool(self:GetClientNumber("slipenabled")) and self:GetClientNumber("slip") or 0

	-- Click on existing offset hoverballs to update their settings.
	if (IsValid(tent) and tent:GetClass() == "offset_hoverball") then

		tent:Setup(
			ply,
			pos,
			ang,
			height,
			force,
			air_resistance,
			rotdamping,
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

		if (not ply:CheckLimit("offset_hoverball")) then return end

		local ang = trace.HitNormal:Angle()
		ang.pitch = ang.pitch + 90
		ball:SetAngles(ang)

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

		local CurPos = ball:GetPos()
		local NrPoint = ball:NearestPoint(CurPos - (trace.HitNormal * 512))
		local Offset = CurPos - NrPoint
		ball:SetPos(trace.HitPos + Offset)

		-- Hold shift when placing to automatically set hover height.
		if (ply:KeyDown(IN_SPEED))  then
			local tr = ball:GetTrace(nil, -50000)
			ball.hoverdistance = tr.distance
			ball:UpdateHoverText()
		end

		local weld = constraint.Weld(ball, tent, 0, trace.PhysicsBone, 0, true, true)

		-- Will grab the whole contraption and shove it in the trace filter
		ball:UpdateFilter() -- There must be a constraint for it to work

		if tobool(self:GetClientNumber("useparenting")) then ball:SetParent(tent) end

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
	if (ply:KeyDown(IN_SPEED) and tent:GetClass() ~= "offset_hoverball") then
		self:ApplyContraption(trace, function(v) SafeRemoveEntity(v); return true end, "removed")
		return true
	end

	if (IsValid(tent) and tent:GetClass() == "offset_hoverball" and tent:GetCreator() == ply) then
		SafeRemoveEntity(tent)
		return true
	end

end


-- Copy settings with right-click.
function TOOL:RightClick(trace)
	if (CLIENT) then return false end

	local tent, ply = trace.Entity, self:GetOwner()

	-- SHIFT + Right click updates all hoverballs, provided you're looking at a contraption.
	if (ply:KeyDown(IN_SPEED) and tent:GetClass() ~= "offset_hoverball") then
		self:ApplyContraption(trace, function(v) self:UpdateExistingHB(v); return true end, "updated")
		return true
	end

	if (IsValid(tent) and tent:GetClass() == "offset_hoverball") then

		ply:ConCommand(gsMode.."_force"           .." "..tent.hoverforce                 .."\n")
		ply:ConCommand(gsMode.."_height"          .." "..tent.hoverdistance              .."\n")
		ply:ConCommand(gsMode.."_air_resistance"  .." "..tent.damping                    .."\n")
		ply:ConCommand(gsMode.."_angular_damping" .." "..tent.rotdamping                 .."\n")
		ply:ConCommand(gsMode.."_hover_damping"   .." "..tent.hovdamping                 .."\n")
		ply:ConCommand(gsMode.."_detects_water"   .." "..(tent.detects_water and 1 or 0) .."\n")
		ply:ConCommand(gsMode.."_nocollide"       .." "..(tent.nocollide     and 1 or 0) .."\n")
		ply:ConCommand(gsMode.."_adjust_speed"    .." "..tent.adjustspeed                .."\n")
		ply:ConCommand(gsMode.."_brake_resistance".." "..tent.brakeresistance            .."\n")
		ply:ConCommand(gsMode.."_slip"            .." "..tent.slip                       .."\n")
		ply:ConCommand(gsMode.."_minslipangle"    .." "..tent.minslipangle               .."\n")

		-- Copy control hotkeys if enabled.
		if tobool(self:GetClientNumber("copykeybinds")) then
			ply:ConCommand(gsMode.."_key_heightup"  .." "..tent.key_heightup               .."\n")
			ply:ConCommand(gsMode.."_key_heightdown".." "..tent.key_heightdown             .."\n")
			ply:ConCommand(gsMode.."_key_toggle"    .." "..tent.key_toggle                 .."\n")
			ply:ConCommand(gsMode.."_key_brake"     .." "..tent.key_brake                  .."\n")
		end

		self:NotifyAction("Hoverball settings copied!", "GENERIC")
		ply:EmitSound("buttons/button14.wav", 45, 100, 0.5)
		return true
	end
end


function TOOL.BuildCPanel(panel)
	panel:ClearControls(); panel:DockPadding(5, 0, 5, 10)
	local drmSkin, pItem = panel:GetSkin() -- pItem is the current panel created

	pItem = panel:SetName(language.GetPhrase("tool."..gsMode..".name"))
	pItem = panel:Help   (language.GetPhrase("tool."..gsMode..".desc"))

	pItem = vgui.Create("ControlPresets", panel)
	pItem:SetPreset(gsMode)
	pItem:AddOption("Default", ConVarsDefault)
	for key, val in pairs(table.GetKeys(ConVarsDefault)) do pItem:AddConVar(val) end
	pItem:Dock(TOP); panel:AddItem(pItem)

	pItem = panel:PropSelect("Model", gsMode.."_model", list.Get("OffsetHoverballModels"), 5)

	pItem = panel:NumSlider(language.GetPhrase("tool."..gsMode..".force"), gsMode.."_force", 5, 1000, 3)
	pItem:SetDefaultValue(ConVarsDefault[gsMode.."_force"])
	pItem.Label:SetTooltip(language.GetPhrase("tool."..gsMode..".force_tt"))

	pItem = panel:NumSlider(language.GetPhrase("tool."..gsMode..".height"), 5, 1500, 3)
	pItem:SetDefaultValue(ConVarsDefault[gsMode.."_height"])
	pItem.Label:SetTooltip(language.GetPhrase("tool."..gsMode..".height_tt"))

	pItem = panel:NumSlider(language.GetPhrase("tool."..gsMode..".air_resistance"), gsMode.."_air_resistance", 0, 30, 3)
	pItem:SetDefaultValue(ConVarsDefault[gsMode.."_air_resistance"])
	pItem.Label:SetTooltip(language.GetPhrase("tool."..gsMode..".air_resistance_tt"))

	pItem = panel:NumSlider(language.GetPhrase("tool."..gsMode..".angular_damping"), gsMode.."_angular_damping", 0, 100, 3)
	pItem:SetDefaultValue(ConVarsDefault[gsMode.."_angular_damping"])
	pItem.Label:SetTooltip(language.GetPhrase("tool."..gsMode..".angular_damping_tt"))

	pItem = panel:NumSlider(language.GetPhrase("tool."..gsMode..".hover_damping"), gsMode.."_hover_damping", 0, 100, 3)
	pItem:SetDefaultValue(ConVarsDefault[gsMode.."_hover_damping"])
	pItem.Label:SetTooltip(language.GetPhrase("tool."..gsMode..".hover_damping_tt"))

	pItem = panel:ControlHelp(language.GetPhrase("tool."..gsMode..".mouseui"))
	pItem:DockMargin(8,10,0,0)

	pItem = panel:CheckBox(language.GetPhrase("tool."..gsMode..".detects_water"), gsMode.."_detects_water")
	pItem:SetTooltip(language.GetPhrase("tool."..gsMode..".detects_water_tt"))
	pItem:SetChecked(ConVarsDefault[gsMode.."_detects_water"])
	pItem:DockMargin(0,10,0,0)

	pItem = panel:CheckBox(language.GetPhrase("tool."..gsMode..".detects_props"), gsMode.."_detects_props")
	pItem:SetTooltip(language.GetPhrase("tool."..gsMode..".detects_props_tt"))
	pItem:SetChecked(ConVarsDefault[gsMode.."_detects_props"])
	pItem:DockMargin(0,10,0,0)

	pItem = panel:CheckBox(language.GetPhrase("tool."..gsMode..".nocollide"), gsMode.."_nocollide")
	pItem:SetTooltip(language.GetPhrase("tool."..gsMode..".nocollide_tt"))
	pItem:SetChecked(ConVarsDefault[gsMode.."_nocollide"])

	pItem = panel:CheckBox(language.GetPhrase("tool."..gsMode..".start_on"), gsMode.."_start_on")
	pItem:SetTooltip(language.GetPhrase("tool."..gsMode..".start_on_tt"))
	pItem:SetChecked(ConVarsDefault[gsMode.."_start_on"])

	pItem = vgui.Create("CtrlNumPad", panel)
	pItem:SetLabel1(language.GetPhrase("tool."..gsMode..".key_heightup"))
	pItem:SetLabel2(language.GetPhrase("tool."..gsMode..".key_heightdown"))
	pItem:SetConVar1(gsMode.."_key_heightup")
	pItem:SetConVar2(gsMode.."_key_heightdown")
	panel:AddPanel(pItem)
	pItem:DockMargin(0,10,0,0)

	pItem = vgui.Create("CtrlNumPad", panel)
	pItem:SetLabel1(language.GetPhrase("tool."..gsMode..".key_toggle"))
	pItem:SetLabel2(language.GetPhrase("tool."..gsMode..".key_brake"))
	pItem:SetConVar1(gsMode.."_key_toggle")
	pItem:SetConVar2(gsMode.."_key_brake")
	panel:AddPanel(pItem)

	pItem = panel:NumSlider(language.GetPhrase("tool."..gsMode..".adjust_speed"), gsMode.."_adjust_speed", 0, 100, 3)
	pItem:SetDefaultValue(ConVarsDefault[gsMode.."_adjust_speed"])
	pItem.Label:SetTooltip(language.GetPhrase("tool."..gsMode..".adjust_speed_tt"))
	pItem:DockMargin(0,10,0,0)

	pItem = panel:NumSlider(language.GetPhrase("tool."..gsMode..".brake_resistance"), gsMode.."_brake_resistance", 1, 30, 3)
	pItem:SetDefaultValue(ConVarsDefault[gsMode.."_brake_resistance"])
	pItem.Label:SetTooltip(language.GetPhrase("tool."..gsMode..".brake_resistance_tt"))

	pItem = panel:ControlHelp(language.GetPhrase("tool."..gsMode..".help1"))
	pItem:DockMargin(10,0,0,0)
	pItem = panel:ControlHelp(language.GetPhrase("tool."..gsMode..".help2"))
	pItem:DockMargin(10,0,0,0)

	Subheading = panel:Help(language.GetPhrase("tool."..gsMode..".set_def"))
	Subheading:SetFont("DefaultBold")
	Subheading:DockMargin(0,15,0,5)
	
	pItem = panel:CheckBox(language.GetPhrase("tool."..gsMode..".copykeybinds"), gsMode.."_copykeybinds")
	pItem:SetTooltip(language.GetPhrase("tool."..gsMode..".copykeybinds_tt"))
	pItem:SetChecked(ConVarsDefault[gsMode.."_copykeybinds"])

	pItem = panel:CheckBox(language.GetPhrase("tool."..gsMode..".showlasers"), gsMode.."_showlasers")
	pItem:SetTooltip(language.GetPhrase("tool."..gsMode..".showlasers_tt"))
	pItem:SetChecked(ConVarsDefault[gsMode.."_showlasers"])

	pItem = panel:CheckBox(language.GetPhrase("tool."..gsMode..".alwaysshowlasers"), gsMode.."_alwaysshowlasers")
	pItem:SetTooltip(language.GetPhrase("tool."..gsMode..".alwaysshowlasers_tt"))
	pItem:SetChecked(ConVarsDefault[gsMode.."_alwaysshowlasers"])

	pItem = panel:CheckBox(language.GetPhrase("tool."..gsMode..".showdecimals"), gsMode.."_showdecimals")
	pItem:SetTooltip(language.GetPhrase("tool."..gsMode..".showdecimals_tt"))
	pItem:SetChecked(ConVarsDefault[gsMode.."_showdecimals"])

	pItem = panel:CheckBox(language.GetPhrase("tool."..gsMode..".useparenting"), gsMode.."_useparenting")
	pItem:SetTooltip(language.GetPhrase("tool."..gsMode..".useparenting_tt"))
	pItem:SetChecked(ConVarsDefault[gsMode.."_useparenting"])

	panel:ControlHelp(" • More sturdy, but can't be updated with right-click.")
	panel:ControlHelp(" • SHIFT-RMB still works to update them, however.")

	Subheading = panel:Help(language.GetPhrase("tool."..gsMode..".set_exp"))
	Subheading:SetFont("DefaultBold")
	Subheading:DockMargin(0,15,0,0)

	pItem = panel:Help(language.GetPhrase("tool."..gsMode..".set_slip"))
	pItem:DockMargin(1,0,5,0)

	SlipToggle = panel:CheckBox(language.GetPhrase("tool."..gsMode..".slipenabled"), gsMode.."_slipenabled")
	SlipToggle:SetTooltip(language.GetPhrase("tool."..gsMode..".slipenabled_tt"))
	SlipToggle:SetChecked(ConVarsDefault[gsMode.."_slipenabled"])

	SlipNSlider = panel:NumSlider(language.GetPhrase("tool."..gsMode..".slip"), gsMode.."_slip", 0, 5000)
	SlipNSlider:SetTooltip(language.GetPhrase("tool."..gsMode..".slip_tt"))
	SlipNSlider:SetDefaultValue(ConVarsDefault[gsMode.."_slip"])

	SlideAngle = panel:NumSlider(language.GetPhrase("tool."..gsMode..".minslipangle"), gsMode.."_minslipangle", 0.05, 1, 3)
	SlideAngle:SetTooltip(language.GetPhrase("tool."..gsMode..".minslipangle_tt"))
	SlideAngle:SetDefaultValue(ConVarsDefault[gsMode.."_minslipangle"])
	SlideAngle:DockMargin(0,5,0,0)

	SlipNSlider:SetEnabled(false)
	SlideAngle:SetEnabled(false)

	function SlipToggle:OnChange(checked)
		SlipNSlider:SetEnabled(checked)
		SlideAngle:SetEnabled(checked)
	end

	-- Little debug message to let users know if wire support is working.
	if WireLib then
		pItem = panel:ControlHelp(language.GetPhrase("tool."..gsMode..".wire_on"))
		pItem:SetColor( Color(39, 174, 96) )
		pItem:DockMargin(10,40,0,0)
	else
		pItem = panel:ControlHelp(language.GetPhrase("tool."..gsMode..".wire_off"))
		pItem:SetColor( Color(255, 71, 87) )
		pItem:DockMargin(10,40,0,0)
	end
end

function TOOL:UpdateGhostHoverball(ent, ply)

	if (not IsValid(ent)) then return end

	local trace = ply:GetEyeTrace()
	if IsValid(trace.Entity) then
		if (not trace.Hit or trace.Entity and
			 (trace.Entity:IsPlayer() or trace.Entity:GetClass() == "offset_hoverball")) then
			ent:SetNoDraw(true)
			return
		end
	end

	local ang = trace.HitNormal:Angle()
	ang.pitch = ang.pitch + 90
	ent:SetAngles(ang)

	local CurPos = ent:GetPos()
	local NeaPos = ent:NearestPoint(CurPos - (trace.HitNormal * 512))
	CurPos:Sub(NeaPos)
	CurPos:Add(trace.HitPos)
	ent:SetPos(CurPos)

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

if (SERVER) then
	CreateConVar("sbox_maxoffset_hoverball", "20", FCVAR_ARCHIVE, "Max offset hoverballs per player", 0)

	function CreateOffsetHoverball(ply, pos, ang, hoverdistance, hoverforce, damping, rotdamping,
		                             hovdamping, detects_water, detects_props, start_on, adjustspeed, model,
		                             nocollide, key_toggle, key_heightup, key_heightdown,
		                             key_brake, brakeresistance, slip, minslipangle)

		if (IsValid(ply) and not ply:CheckLimit("offset_hoverball")) then return false end
		
		local ball = ents.Create("offset_hoverball")
		
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
			ply:AddCount("offset_hoverball", ball)
			ply:AddCleanup("offset_hoverball", ball)
		end

		-- Either specified by our spawn tool, or filled in automatically by the duplicator.
		ball:Setup(ply, pos, ang, hoverdistance, hoverforce, damping,
			rotdamping, hovdamping, detects_water, detects_props, start_on,
			adjustspeed, nocollide, key_toggle,
			key_heightup, key_heightdown, key_brake,
			brakeresistance, slip, minslipangle)

		ball:UpdateMask()
		ball:UpdateCollide()
		ball:UpdateHoverText()

		DoPropSpawnedEffect(ball)
		
		local phys = ball:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:Wake()
		end

		return ball
	end
	
	-- This is deliberately missing "ply" as first argument here, as the duplicator adds it in automatically when pasting.
	duplicator.RegisterEntityClass("offset_hoverball", CreateOffsetHoverball, "pos", "ang", "hoverdistance", "hoverforce",
		"damping", "rotdamping", "hovdamping", "detects_water", "detects_props", "start_on", "adjustspeed", "model", "nocollide", "key_toggle",
		"key_heightup", "key_heightdown", "key_brake", "brakeresistance", "slip", "minslipangle")

end

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
