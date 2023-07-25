TOOL.Category = "Construction"
TOOL.Name = "Hoverball - Offset"
TOOL.Command = nil
TOOL.ConfigName = "" -- Setting this means that you do not have to create external configuration files to define the layout of the tool config-hud

-- Default preset values.
TOOL.ClientConVar = {
	["force"] = "100",
	["height"] = "100",
	["air_resistance"] = "2",
	["angular_damping"] = "10",
	["detects_water"] = "true",
	["model"] = "models/dav0r/hoverball.mdl",
	["adjust_speed"] = "0.8",
	["brake_resistance"] = "15",
	["nocollide"] = "true",
	["detects_water"] = "true",
	["start_on"] = "true",
	["copykeybinds"] = "true",
	
	-- Toggle numpad keys
	["key_toggle"]       = 51, -- Numpad enter
	["key_heightdown"]   = 49, -- Numpad -
	["key_heightup"]     = 50, -- Numpad +
	["key_brake"]        = 37  -- Numpad 0
}

local ConVarsDefault = TOOL:BuildConVarList()
cleanup.Register("offset_hoverballs")


local frmNotif = "notification.AddLegacy(\"%s\", NOTIFY_%s, 6)"
function TOOL:NotifyAction(mesg, type)
  self:GetOwner():SendLua(frmNotif:format(mesg, type))
end


function TOOL:LeftClick(trace)
	local model = self:GetClientInfo("model")
	local ball, ply = trace.Entity, self:GetOwner()
	
	if (CLIENT) then return false end

	-- Click on existing offset hoverballs to update their settings.
	if (IsValid(ball) and ball:GetClass() == "offset_hoverball") then
		
		-- Remove existing keybinds.
		numpad.Remove(ball.ImpulseID_heightup)
		numpad.Remove(ball.ImpulseID_heightbackup)
		numpad.Remove(ball.ImpulseID_heightdown)
		numpad.Remove(ball.ImpulseID_heightbackdown)
		numpad.Remove(ball.ImpulseID_brake)
		numpad.Remove(ball.ImpulseID_brakerelease)
		numpad.Remove(ball.ImpulseID_toggle)

		-- Get new keybinds and save them to the entity so that the duplicator can recreate them later.
		ball.key_brake = self:GetClientNumber("key_brake")
		ball.key_toggle = self:GetClientNumber("key_toggle")
		ball.key_heightup = self:GetClientNumber("key_heightup")
		ball.key_heightdown = self:GetClientNumber("key_heightdown")

		-- Update keybinds from above.
		ball.ImpulseID_heightup       = numpad.OnDown(ply, ball.key_heightup  , "offset_hoverball_heightup"  , ball, true)
		ball.ImpulseID_heightbackup   = numpad.OnUp  (ply, ball.key_heightup  , "offset_hoverball_heightup"  , ball, false)
		ball.ImpulseID_heightdown     = numpad.OnDown(ply, ball.key_heightdown, "offset_hoverball_heightdown", ball, true)
		ball.ImpulseID_heightbackdown = numpad.OnUp  (ply, ball.key_heightdown, "offset_hoverball_heightdown", ball, false)
		ball.ImpulseID_brake          = numpad.OnDown(ply, ball.key_brake     , "offset_hoverball_brake"     , ball, true)
		ball.ImpulseID_brakerelease   = numpad.OnUp  (ply, ball.key_brake     , "offset_hoverball_brake"     , ball, false)

		-- No OnUp func required for toggle.
		ball.ImpulseID_toggle = numpad.OnDown(ply, ball.key_toggle, "offset_hoverball_toggle", ball, true)

		-- Update settings to our new values.
		ball.hoverforce      = self:GetClientNumber("force")
		ball.hoverdistance   = self:GetClientNumber("height")
		ball.adjustspeed     = self:GetClientNumber("adjust_speed")
		ball.damping         = self:GetClientNumber("air_resistance")
		ball.rotdamping      = self:GetClientNumber("angular_damping")
		ball.brakeresistance = self:GetClientNumber("brake_resistance")
		ball.nocollide       = tobool(self:GetClientNumber("nocollide"))
		ball.detects_water   = tobool(self:GetClientNumber("detects_water"))
		ball.start_on   	 = tobool(self:GetClientNumber("start_on"))

		-- Depends on entity internals.
		ball:UpdateMask()
		ball:UpdateCollide()
		ball:UpdateHoverText()

		self:NotifyAction("Hoverball updated!", "GENERIC")
		ply:EmitSound("buttons/button16.wav", 45, 100, 0.5)

		return true -- Don't forget to return true or the toolgun animation/effect doesn't play.
	else

		if (not self:GetOwner():CheckLimit("offset_hoverball")) then return end

		-- Not updating anything, Place a new hoverball instead.
		local ball = CreateOffsetHoverball(
			self:GetOwner(),
			trace.HitPos,
			self:GetClientNumber("height"),
			self:GetClientNumber("force"),
			self:GetClientNumber("air_resistance"),
			self:GetClientNumber("angular_damping"),
			tobool(self:GetClientNumber("detects_water")),
			tobool(self:GetClientNumber("start_on")),
			self:GetClientNumber("adjust_speed"),
			self:GetClientInfo("model"),
			self:GetClientNumber("offset_hoverball_nocollide"),
			self:GetClientNumber("key_toggle"),
			self:GetClientNumber("key_heightup"),
			self:GetClientNumber("key_heightdown"),
			self:GetClientNumber("key_brake"),
			self:GetClientNumber("brake_resistance")
		)

		local ang = trace.HitNormal:Angle()
		ang.pitch = ang.pitch + 90
		ball:SetAngles(ang)

		local CurPos = ball:GetPos()
		local NrPoint = ball:NearestPoint(CurPos - (trace.HitNormal * 512))
		local Offset = CurPos - NrPoint
		ball:SetPos(trace.HitPos + Offset)

		if (IsValid(ball)) then
			local weld = constraint.Weld(ball, trace.Entity, 0, trace.PhysicsBone, 0, true, true)
		end

		undo.Create("Offset hoverball")
		undo.AddEntity(ball)
		undo.SetPlayer(ply)
		undo.Finish()

		return true
	end
end


-- Toolgun reload removes hoverballs.
function TOOL:Reload(trace)

	if (SERVER) then 
		local ball, ply = trace.Entity, self:GetOwner()
		
		if (IsValid(ball) and ball:GetClass() == "offset_hoverball" and ball:GetCreator() == ply) then
			SafeRemoveEntity(ball)
			return true
		end
		--return false
	end
end


-- Copy settings with right-click.
function TOOL:RightClick(trace)
	if (CLIENT) then return false end
	
	local ball, ply = trace.Entity, self:GetOwner()
	if (IsValid(ball) and ball:GetClass() == "offset_hoverball") then
	
		ply:ConCommand("offset_hoverball_force"           .." "..ball.hoverforce                .."\n")
		ply:ConCommand("offset_hoverball_height"          .." "..ball.hoverdistance             .."\n")
		ply:ConCommand("offset_hoverball_air_resistance"  .." "..ball.damping                   .."\n")
		ply:ConCommand("offset_hoverball_angular_damping" .." "..ball.rotdamping                .."\n")
		ply:ConCommand("offset_hoverball_detects_water"   .." "..(ball.detects_water and 1 or 0) .."\n")
		ply:ConCommand("offset_hoverball_nocollide"       .." "..(ball.nocollide    and 1 or 0) .."\n")
		ply:ConCommand("offset_hoverball_adjust_speed"    .." "..ball.adjustspeed               .."\n")
		ply:ConCommand("offset_hoverball_brake_resistance".." "..ball.brakeresistance           .."\n")

		-- Copy control hotkeys if enabled.
		if tobool(self:GetClientNumber("copykeybinds")) then
			ply:ConCommand("offset_hoverball_key_heightup".." "..ball.key_heightup              .."\n")
			ply:ConCommand("offset_hoverball_key_heightdown".." "..ball.key_heightdown          .."\n")
			ply:ConCommand("offset_hoverball_key_toggle".." "..ball.key_toggle                  .."\n")
			ply:ConCommand("offset_hoverball_key_brake".." "..ball.key_brake                    .."\n")
		end

		self:NotifyAction("Hoverball settings copied!", "GENERIC")
		ply:EmitSound("buttons/button14.wav", 45, 100, 0.5)
		return true
	end

	--return false
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
  pItem = panel:NumSlider("Force", "offset_hoverball_force", 5, 1000, 3); pItem:SetDefaultValue(ConVarsDefault["offset_hoverball_force"])
  pItem = panel:NumSlider("Height", "offset_hoverball_height", 5, 1500, 3); pItem:SetDefaultValue(ConVarsDefault["offset_hoverball_height"])
  pItem = panel:NumSlider("Air Resistance", "offset_hoverball_air_resistance", 0, 30, 3); pItem:SetDefaultValue(ConVarsDefault["offset_hoverball_air_resistance"])
  pItem = panel:NumSlider("Angular Damping", "offset_hoverball_angular_damping", 0, 100, 3); pItem:SetDefaultValue(ConVarsDefault["offset_hoverball_angular_damping"])
  pItem = panel:CheckBox("Hovers over water", "offset_hoverball_detects_water"); pItem:SetChecked(ConVarsDefault["offset_hoverball_detects_water"])
  pItem = panel:CheckBox("Disable collisions", "offset_hoverball_nocollide"); pItem:SetChecked(ConVarsDefault["offset_hoverball_nocollide"])
  pItem = panel:CheckBox("Start on", "offset_hoverball_start_on"); pItem:SetChecked(ConVarsDefault["offset_hoverball_start_on"])
  pItem = panel:CheckBox("Copying settings includes keybinds", "offset_hoverball_copykeybinds"); pItem:SetChecked(ConVarsDefault["offset_hoverball_copykeybinds"])

  pItem = vgui.Create("CtrlNumPad", panel)
  pItem:SetLabel1("Increase height")
  pItem:SetLabel2("Decrease height")
  pItem:SetConVar1("offset_hoverball_key_heightup")
  pItem:SetConVar2("offset_hoverball_key_heightdown")
  panel:AddPanel(pItem)

  pItem = vgui.Create("CtrlNumPad", panel)
  pItem:SetLabel1("Toggle on/off")
  pItem:SetLabel2("Brake (Hold)")
  pItem:SetConVar1("offset_hoverball_key_toggle")
  pItem:SetConVar2("offset_hoverball_key_brake")
  panel:AddPanel(pItem)

  pItem = panel:NumSlider("Height adjust rate", "offset_hoverball_adjust_speed", 0, 100, 3); pItem:SetDefaultValue(ConVarsDefault["offset_hoverball_adjust_speed"])
  pItem = panel:NumSlider("Braking resistance", "offset_hoverball_brake_resistance", 1, 30, 3); pItem:SetDefaultValue(ConVarsDefault["offset_hoverball_brake_resistance"])
  panel:ControlHelp("All keyboard controls are optional, Hoverballs can work fine without them.")
  panel:ControlHelp("Braking works by increasing the air resistance value while the brake key is held.")

	-- Little debug message to let users know if wire support is working.
	if WireLib then
		panel:ControlHelp("\nWiremod integration: ENABLED")
	end
end

function TOOL:UpdateGhostHoverball(ent, ply)

	if (not IsValid(ent)) then return end

	local trace = ply:GetEyeTrace()
	if IsValid(trace.Entity) then
		if (not trace.Hit or trace.Entity and (trace.Entity:GetClass() == "offset_hoverball" or trace.Entity:IsPlayer())) then
			ent:SetNoDraw(true)
			return
		end
	end

	local ang = trace.HitNormal:Angle()
	ang.pitch = ang.pitch + 90
	ent:SetAngles(ang)

	local CurPos = ent:GetPos()
	local NearestPoint = ent:NearestPoint(CurPos - (trace.HitNormal * 512))
	local Offset = CurPos - NearestPoint
	ent:SetPos(trace.HitPos + Offset)

	ent:SetNoDraw(false)
end

local function IsValidHoverballModel(model)
	for mdl, _ in pairs(list.Get("OffsetHoverballModels")) do if (mdl:lower() == model:lower()) then return true end end
	return false
end

function TOOL:Think()

	local mdl = self:GetClientInfo("model")
	if (not IsValidHoverballModel(mdl)) then
		self:ReleaseGhostEntity()
		return
	end

	if (not IsValid(self.GhostEntity) or self.GhostEntity:GetModel() ~= mdl) then
		self:MakeGhostEntity(mdl, vector_origin, angle_zero)
	end

	self:UpdateGhostHoverball(self.GhostEntity, self:GetOwner())
end

if (SERVER) then
	CreateConVar("sbox_maxoffset_hoverball", "20", FCVAR_ARCHIVE, "Max offset hoverballs per player", 0)

	function CreateOffsetHoverball(ply, pos, hoverdistance, hoverforce, damping, rotdamping, detects_water, start_on, adjustspeed, model, nocollide, key_toggle, key_heightup, key_heightdown, key_brake, brakeresistance)

		if (IsValid(ply) and not ply:CheckLimit("offset_hoverball")) then return false end
		
		local ball = ents.Create("offset_hoverball")
		
		if (not IsValid(ball)) then return nil end -- Check whether we successfully made an entity, if not - bail
		
		ball:SetPos(pos) -- Either specified by our spawn tool, or filled in automatically by the duplicator.
		ball.hoverdistance = hoverdistance
		ball.hoverforce = hoverforce
		ball.damping = damping
		ball.rotdamping = rotdamping
		ball.detects_water = detects_water
		ball.start_on = start_on
		ball.HoverEnabled = start_on
		ball.adjustspeed = adjustspeed
		ball.brakeresistance = brakeresistance
		ball:SetModel(model)
		ball:Spawn()
		
		if (IsValid(ply)) then
		
			ball:SetPlayer(ply)
			ball:SetCreator(ply)
			
			-- Used for server ownership and cleanup
			ply:AddCount("offset_hoverball", ball)
			ply:AddCleanup("offset_hoverball", ball)
			
			-- Setup numpad controls:
			ball.ImpulseID_heightup = numpad.OnDown(ply, key_heightup, "offset_hoverball_heightup", ball, true)
			ball.ImpulseID_heightbackup = numpad.OnUp(ply, key_heightup, "offset_hoverball_heightup", ball, false)
			ball.ImpulseID_heightdown = numpad.OnDown(ply, key_heightdown, "offset_hoverball_heightdown", ball, true)
			ball.ImpulseID_heightbackdown = numpad.OnUp(ply, key_heightdown, "offset_hoverball_heightdown", ball, false)
			ball.ImpulseID_brake = numpad.OnDown(ply, key_brake, "offset_hoverball_brake", ball, true)
			ball.ImpulseID_brakerelease = numpad.OnUp(ply, key_brake, "offset_hoverball_brake", ball, false)
			ball.ImpulseID_toggle = numpad.OnDown(ply, key_toggle, "offset_hoverball_toggle", ball)
		end
	
		if (nocollide == true) then
			if (IsValid(ball:GetPhysicsObject())) then ball:GetPhysicsObject():EnableCollisions(false) end
			ball:SetCollisionGroup(COLLISION_GROUP_WORLD)
		end

		-- Duplicator needs to know what keybinds we used.
		ball.key_brake = key_brake
		ball.key_toggle = key_toggle
		ball.key_heightup = key_heightup
		ball.key_heightdown = key_heightdown


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
	duplicator.RegisterEntityClass("offset_hoverball", CreateOffsetHoverball, "pos", "hoverdistance", "hoverforce", "damping", "rotdamping", "detects_water", "start_on", "adjustspeed", "model",
	"nocollide", "key_toggle", "key_heightup", "key_heightdown", "key_brake", "brakeresistance")

end

if (CLIENT) then
	language.Add("tool.offset_hoverball.name", "Hoverball - Offset")
	language.Add("tool.offset_hoverball.desc", "Hoverballs that keep relative distance to the ground and can go up and down slopes.")
	language.Add("tool.offset_hoverball.0", "LMB: Place or update hoverball, RMB: Copy settings, REL: Remove. Select an entity to weld to it.")
	language.Add("undone.offset_hoverball", "Undone offset hoverball")
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
list.Set("OffsetHoverballModels", "models/squad/sf_plates/sf_plate1x1.mdl", {})
list.Set("OffsetHoverballModels", "models/squad/sf_plates/sf_plate2x2.mdl", {})
list.Set("OffsetHoverballModels", "models/hunter/misc/sphere025x025.mdl", {})
list.Set("OffsetHoverballModels", "models/props_phx/misc/potato_launcher_cap.mdl", {})
list.Set("OffsetHoverballModels", "models/xqm/jetenginepropeller.mdl", {})
list.Set("OffsetHoverballModels", "models/items/combine_rifle_ammo01.mdl", {})
