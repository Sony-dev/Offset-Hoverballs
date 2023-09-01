TOOL.Category = "Construction"
TOOL.Name = "Hoverball - Offset"
TOOL.Command = nil
TOOL.ConfigName = "" -- Setting this means that you do not have to create external configuration files to define the layout of the tool config-hud

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

	language.Add("tool.offset_hoverball.name", 		"Hoverball - Offset")
	language.Add("tool.offset_hoverball.desc", 		"Hoverballs that keep relative distance to the ground and can go up and down slopes")
	language.Add("tool.offset_hoverball.holdshift", 	"Hold SHIFT for more options")
	language.Add("tool.offset_hoverball.left", 		"Place or update hoverball")
	language.Add("tool.offset_hoverball.right", 		"Copy hoverball settings")
	language.Add("tool.offset_hoverball.reload", 		"Remove targeted hoverball safely")
	
	-- Display extra controls when holding SHIFT. (Or whatever their sprint key is)
	language.Add("tool.offset_hoverball.holdingshift", 	"While holding down SHIFT:")
	language.Add("tool.offset_hoverball.shift_left", 	"Place + Set height as distance to ground")
	language.Add("tool.offset_hoverball.shift_right", 	"Select prop to update all attached hoverballs")
	language.Add("tool.offset_hoverball.shift_reload",	"Select prop to remove all attached hoverballs")
	
	language.Add("undone.offset_hoverball", 		"Undone offset hoverball")
end

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
function TOOL:NotifyAction(mesg, type)
	self:GetOwner():SendLua(frmNotif:format(mesg, type))
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

		ply:ConCommand("offset_hoverball_force"           .." "..tent.hoverforce                 .."\n")
		ply:ConCommand("offset_hoverball_height"          .." "..tent.hoverdistance              .."\n")
		ply:ConCommand("offset_hoverball_air_resistance"  .." "..tent.damping                    .."\n")
		ply:ConCommand("offset_hoverball_angular_damping" .." "..tent.rotdamping                 .."\n")
		ply:ConCommand("offset_hoverball_hover_damping"   .." "..tent.hovdamping                 .."\n")
		ply:ConCommand("offset_hoverball_detects_water"   .." "..(tent.detects_water and 1 or 0) .."\n")
		ply:ConCommand("offset_hoverball_nocollide"       .." "..(tent.nocollide     and 1 or 0) .."\n")
		ply:ConCommand("offset_hoverball_adjust_speed"    .." "..tent.adjustspeed                .."\n")
		ply:ConCommand("offset_hoverball_brake_resistance".." "..tent.brakeresistance            .."\n")
		ply:ConCommand("offset_hoverball_slip"            .." "..tent.slip                       .."\n")
		ply:ConCommand("offset_hoverball_minslipangle"    .." "..tent.minslipangle               .."\n")

		-- Copy control hotkeys if enabled.
		if tobool(self:GetClientNumber("copykeybinds")) then
			ply:ConCommand("offset_hoverball_key_heightup"  .." "..tent.key_heightup               .."\n")
			ply:ConCommand("offset_hoverball_key_heightdown".." "..tent.key_heightdown             .."\n")
			ply:ConCommand("offset_hoverball_key_toggle"    .." "..tent.key_toggle                 .."\n")
			ply:ConCommand("offset_hoverball_key_brake"     .." "..tent.key_brake                  .."\n")
		end

		self:NotifyAction("Hoverball settings copied!", "GENERIC")
		ply:EmitSound("buttons/button14.wav", 45, 100, 0.5)
		return true
	end
end


function TOOL.BuildCPanel(panel)
	panel:ClearControls(); panel:DockPadding(5, 0, 5, 10)
	local drmSkin, pItem = panel:GetSkin() -- pItem is the current panel created

	pItem = panel:SetName(language.GetPhrase("tool.offset_hoverball.name"))
	pItem = panel:Help   (language.GetPhrase("tool.offset_hoverball.desc"))

	pItem = vgui.Create("ControlPresets", panel)
	pItem:SetPreset("offset_hoverball")
	pItem:AddOption("Default", ConVarsDefault)
	for key, val in pairs(table.GetKeys(ConVarsDefault)) do pItem:AddConVar(val) end
	pItem:Dock(TOP); panel:AddItem(pItem)

	pItem = panel:PropSelect("Model", "offset_hoverball_model", list.Get("OffsetHoverballModels"), 5)

	pItem = panel:NumSlider("Force", "offset_hoverball_force", 5, 1000, 3)
	pItem:SetDefaultValue(ConVarsDefault["offset_hoverball_force"])
	pItem.Label:SetTooltip("Controls how strong the hovering effect is.\nHigher values can lift heavier objects.")

	pItem = panel:NumSlider("Height", "offset_hoverball_height", 5, 1500, 3)
	pItem:SetDefaultValue(ConVarsDefault["offset_hoverball_height"])
	pItem.Label:SetTooltip("Controls how far off the ground the hoverball floats.\nCan be adjusted using hotkeys.")

	pItem = panel:NumSlider("Air Resistance", "offset_hoverball_air_resistance", 0, 30, 3)
	pItem:SetDefaultValue(ConVarsDefault["offset_hoverball_air_resistance"])
	pItem.Label:SetTooltip("Controls how much air drag the hoverball has.\nLower values are easier to push.")

	pItem = panel:NumSlider("Angular Damping", "offset_hoverball_angular_damping", 0, 100, 3)
	pItem:SetDefaultValue(ConVarsDefault["offset_hoverball_angular_damping"])
	pItem.Label:SetTooltip("Controls how much the hoverball resists rotation forces.\nLower values rotate more freely.")

	pItem = panel:NumSlider("Hover Damping", "offset_hoverball_hover_damping", 0, 100, 3)
	pItem:SetDefaultValue(ConVarsDefault["offset_hoverball_hover_damping"])
	pItem.Label:SetTooltip("Controls how springy the hover effect is.\nLower values are more bouncy.")

	pItem = panel:ControlHelp(" • Mouse over slider labels to see more info.")
	pItem:DockMargin(8,10,0,0)

	pItem = panel:CheckBox("Hovers over water", "offset_hoverball_detects_water")
	pItem:SetChecked(ConVarsDefault["offset_hoverball_detects_water"])
	pItem:DockMargin(0,10,0,0)

	pItem = panel:CheckBox("Hovers over props", "offset_hoverball_detects_props")
	pItem:SetChecked(ConVarsDefault["offset_hoverball_detects_props"])
	pItem:DockMargin(0,10,0,0)

	pItem = panel:CheckBox("Disable collisions", "offset_hoverball_nocollide")
	pItem:SetChecked(ConVarsDefault["offset_hoverball_nocollide"])

	pItem = panel:CheckBox("Start on", "offset_hoverball_start_on")
	pItem:SetChecked(ConVarsDefault["offset_hoverball_start_on"])

	pItem = vgui.Create("CtrlNumPad", panel)
	pItem:SetLabel1("Increase height")
	pItem:SetLabel2("Decrease height")
	pItem:SetConVar1("offset_hoverball_key_heightup")
	pItem:SetConVar2("offset_hoverball_key_heightdown")
	panel:AddPanel(pItem)
	pItem:DockMargin(0,10,0,0)

	pItem = vgui.Create("CtrlNumPad", panel)
	pItem:SetLabel1("Toggle on/off")
	pItem:SetLabel2("Brake (Hold)")
	pItem:SetConVar1("offset_hoverball_key_toggle")
	pItem:SetConVar2("offset_hoverball_key_brake")
	panel:AddPanel(pItem)

	pItem = panel:NumSlider("Height adjust rate", "offset_hoverball_adjust_speed", 0, 100, 3)
	pItem:SetDefaultValue(ConVarsDefault["offset_hoverball_adjust_speed"])
	pItem.Label:SetTooltip("Controls how fast the hoverball moves up/down\nwhen the height adjust keys are pressed.\nHigher values move faster.")
	pItem:DockMargin(0,10,0,0)

	pItem = panel:NumSlider("Braking resistance", "offset_hoverball_brake_resistance", 1, 30, 3)
	pItem:SetDefaultValue(ConVarsDefault["offset_hoverball_brake_resistance"])
	pItem.Label:SetTooltip("Controls how much extra air drag is added when\nthe brake key is held.\nHigher values will stop faster.")

	pItem = panel:ControlHelp("• Keyboard controls are optional.")
	pItem:DockMargin(10,0,0,0)
	pItem = panel:ControlHelp("• Brake key increases air resistance while held.")
	pItem:DockMargin(10,0,0,0)

	Subheading = panel:Help("Tool settings:")
	Subheading:SetFont("DefaultBold")
	Subheading:DockMargin(0,15,0,5)
	
	pItem = panel:CheckBox("Right-click settings copy includes keybinds", "offset_hoverball_copykeybinds")
	pItem:SetChecked(ConVarsDefault["offset_hoverball_copykeybinds"])

	pItem = panel:CheckBox("Visualise traces when holding toolgun", "offset_hoverball_showlasers")
	pItem:SetChecked(ConVarsDefault["offset_hoverball_showlasers"])

	pItem = panel:CheckBox("Always show traces", "offset_hoverball_alwaysshowlasers")
	pItem:SetChecked(ConVarsDefault["offset_hoverball_alwaysshowlasers"])

	pItem = panel:CheckBox("Show decimals on hover UI", "offset_hoverball_showdecimals")
	pItem:SetChecked(ConVarsDefault["offset_hoverball_showdecimals"])

	pItem = panel:CheckBox("Attach hoverballs using parent instead of weld", "offset_hoverball_useparenting")
	pItem:SetChecked(ConVarsDefault["offset_hoverball_useparenting"])

	panel:ControlHelp(" • More sturdy, but can't be updated with right-click.")
	panel:ControlHelp(" • SHIFT-RMB still works to update them, however.")

	Subheading = panel:Help("Experimental:")
	Subheading:SetFont("DefaultBold")
	Subheading:DockMargin(0,15,0,0)

	pItem = panel:Help("Slippery mode will cause hoverballs to slide on uneven surfaces.\nBalance settings with air resistance for best results.")
	pItem:DockMargin(1,0,5,0)

	SlipToggle = panel:CheckBox("Enable slippery mode", "offset_hoverball_slipenabled")
	SlipToggle:SetChecked(ConVarsDefault["offset_hoverball_slipenabled"])
	SlipToggle:SetChecked(false)

	SlipNSlider = panel:NumSlider("Slipperiness", "offset_hoverball_slip", 0, 5000)
	SlipNSlider:SetDefaultValue(ConVarsDefault["offset_hoverball_slip"])
	
	pItem = panel:ControlHelp("• Higher values slide faster.")
	pItem:DockMargin(10,0,0,0)
	
	SlideAngle = panel:NumSlider("Minimum slip angle", "offset_hoverball_minslipangle", 0.05, 1, 3)
	SlideAngle:SetDefaultValue(ConVarsDefault["offset_hoverball_minslipangle"])
	SlideAngle:DockMargin(0,5,0,0)
	
	pItem = panel:ControlHelp("• How steep an incline has to be before we start slipping.")
	pItem:DockMargin(10,0,0,0)
	
	SlipNSlider:SetEnabled(false)
	SlideAngle:SetEnabled(false)

	function SlipToggle:OnChange(checked)
		SlipNSlider:SetEnabled(checked)
		SlideAngle:SetEnabled(checked)
	end

	-- Little debug message to let users know if wire support is working.
	if WireLib then
		pItem = panel:ControlHelp("✔ Wiremod integration enabled")
		pItem:SetColor( Color(39, 174, 96) )
		pItem:DockMargin(10,40,0,0)
	else
		pItem = panel:ControlHelp("✖ Wiremod integration disabled ( Wiremod is not installed )")
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
