TOOL.Category = "Construction"
TOOL.Name = "Hoverball - Offset"
TOOL.Command = nil
TOOL.ConfigName = "" -- Setting this means that you do not have to create external configuration files to define the layout of the tool config-hud

TOOL.ClientConVar = {
  ["force"]            = 100,
  ["height"]           = 100,
  ["air_resistance"]   = 2,
  ["angular_damping"]  = 10,
  ["detects_water"]    = 1,
  ["model"]            = "models/dav0r/hoverball.mdl",
  ["adjust_speed"]     = 0.8,
  ["brake_resistance"] = 15,
  ["nocollide"]        = 1,
  -- Toggle numpad keys
  ["key_toggle"]       = 51, -- Numpad enter
  ["key_heightdown"]   = 49, -- Numpad -
  ["key_heightup"]     = 50, -- Numpad +
  ["key_brake"]        = 42  -- Numpad 5
}

local ConVarsDefault = TOOL:BuildConVarList()

cleanup.Register("offset_hoverballs")

function TOOL:NotifyAction(mesg, type)
  local frm = "notification.AddLegacy(\"%s\", NOTIFY_%s, 6)"
  self:GetOwner():SendLua(frm:format(mesg, type))
end

function TOOL:LeftClick(trace)
  if (CLIENT) then return false end
  local ball, ply = trace.Entity, self:GetOwner()
  
  -- Click on existing offset hoverballs to update their settings.
  if (IsValid(ball) and ball:GetClass() == "offset_hoverball") then
    ball.hoverdistance   = self:GetClientNumber("height")
    ball.hoverforce      = self:GetClientNumber("force")
    ball.damping         = self:GetClientNumber("air_resistance")
    ball.rotdamping      = self:GetClientNumber("angular_damping")
    ball.detectswater    = tobool(self:GetClientNumber("detects_water"))
    ball.nocollide       = tobool(self:GetClientNumber("nocollide"))
    ball.adjustspeed     = self:GetClientNumber("adjust_speed")
    ball.brakeresistance = self:GetClientNumber("brake_resistance")

    -- Depend on entity internals
    ball:UpdateMask()
    ball:UpdateCollide()
    ball:UpdateHoverText()

    -- Update keys
    numpad.Remove(ball.key_heightup)
    numpad.Remove(ball.key_heightbackup)
    numpad.Remove(ball.key_heightdown)
    numpad.Remove(ball.key_heightbackdown)
    numpad.Remove(ball.key_brake)
    numpad.Remove(ball.key_brakerelease)
    numpad.Remove(ball.key_toggle)

    ball.key_heightup       = numpad.OnDown(ply, self:GetClientNumber("key_heightup")  , "offset_hoverball_heightup"  , ball, true)
    ball.key_heightbackup   = numpad.OnUp  (ply, self:GetClientNumber("key_heightup")  , "offset_hoverball_heightup"  , ball, false)
    ball.key_heightdown     = numpad.OnDown(ply, self:GetClientNumber("key_heightdown"), "offset_hoverball_heightdown", ball, true)
    ball.key_heightbackdown = numpad.OnUp  (ply, self:GetClientNumber("key_heightdown"), "offset_hoverball_heightdown", ball, false)
    ball.key_brake          = numpad.OnDown(ply, self:GetClientNumber("key_brake")     , "offset_hoverball_brake"     , ball, true)
    ball.key_brakerelease    = numpad.OnUp  (ply, self:GetClientNumber("key_brake")     , "offset_hoverball_brake"     , ball, false)

    if (key_toggle) then
      ball.key_toggle = numpad.OnDown(ply, self:GetClientNumber("key_toggle"), "offset_hoverball_toggle", ball)
    end

    self:NotifyAction("Hoverball updated", "UNDO")
	ply:EmitSound("buttons/button16.wav", 45, 100, 0.5)
	
	return true
  else
  
    -- Place a new hoverball instead.
    local ball = NewHoverballOffset(ply, trace.HitPos, self:GetClientNumber("height"),
                                    self:GetClientNumber("force"), self:GetClientNumber("air_resistance"),
                                    self:GetClientNumber("angular_damping"),
                                    self:GetClientNumber("detects_water"), self:GetClientNumber("adjust_speed"),
                                    self:GetClientInfo("model"), self:GetClientNumber("nocollide"),
                                    self:GetClientNumber("key_toggle"), self:GetClientNumber("key_heightup"),
                                    self:GetClientNumber("key_heightdown"), self:GetClientNumber("key_brake"),
                                    self:GetClientNumber("brake_resistance"))

    local ang = trace.HitNormal:Angle()
    ang.pitch = ang.pitch + 90
    ball:SetAngles(ang)

    local CurPos = ball:GetPos()
    local NrPoint = ball:NearestPoint(CurPos - (trace.HitNormal * 512))
    local Offset = CurPos - NrPoint
    ball:SetPos(trace.HitPos + Offset)

    if (IsValid(ball)) then -- TODO: Update height automatically when placed on an entity
      local weld = constraint.Weld(ball, trace.Entity, 0, trace.PhysicsBone, 0, true, false)
    end

    undo.Create("Offset hoverball")
    undo.AddEntity(ball)
    undo.SetPlayer(ply)
    undo.Finish()
	
	-- Might get annoying to send a message every time we left click
    --self:NotifyAction("Hoverball created!", "GENERIC");
	
	return true
  end
end

function TOOL:Reload(trace)

  if (CLIENT) then return false end
  local ball, ply = trace.Entity, self:GetOwner()
  if (IsValid(ball) and ball:GetClass() == "offset_hoverball") then
	 
     SafeRemoveEntity(ball)
     return true
  end

  return false
end

function TOOL:RightClick(trace)
  if (CLIENT) then return false end
  local ball, ply = trace.Entity, self:GetOwner()
  if (IsValid(ball) and ball:GetClass() == "offset_hoverball") then
     ply:ConCommand("hoverball_offset_force"           .." "..ball.hoverforce                .."\n")
     ply:ConCommand("hoverball_offset_height"          .." "..ball.hoverdistance             .."\n")
     ply:ConCommand("hoverball_offset_air_resistance"  .." "..ball.damping                   .."\n")
     ply:ConCommand("hoverball_offset_angular_damping" .." "..ball.rotdamping                .."\n")
     ply:ConCommand("hoverball_offset_detects_water"   .." "..(ball.detectswater and 1 or 0) .."\n")
     ply:ConCommand("hoverball_offset_nocollide"       .." "..(ball.nocollide    and 1 or 0) .."\n")
     ply:ConCommand("hoverball_offset_adjust_speed"    .." "..ball.adjustspeed               .."\n")
     ply:ConCommand("hoverball_offset_brake_resistance".." "..ball.brakeresistance           .."\n")
     self:NotifyAction("Hoverball settings copied", "GENERIC")
	 ply:EmitSound("buttons/button14.wav", 45, 100, 0.5)
     return true
  end

  return false
end

function TOOL.BuildCPanel(panel)
  panel:ClearControls(); panel:DockPadding(5, 0, 5, 10)
  local drmSkin, pItem = panel:GetSkin() -- pItem is the current panel created
  pItem = panel:SetName(language.GetPhrase("tool.offset_hoverball.name"))
  pItem = panel:Help   (language.GetPhrase("tool.offset_hoverball.desc"))
 
  pItem = vgui.Create("ControlPresets", panel)
  pItem:SetPreset("hoverball_offset")
  pItem:AddOption("Default", ConVarsDefault)
  for key, val in pairs(table.GetKeys(ConVarsDefault)) do pItem:AddConVar(val) end
  pItem:Dock(TOP); panel:AddItem(pItem)
  pItem = panel:PropSelect("Model", "hoverball_offset_model", list.GetForEdit("DistanceHoverballModels"), 5)
  pItem = panel:NumSlider("Force", "hoverball_offset_force", 5, 1000, 3); pItem:SetDefaultValue(ConVarsDefault["hoverball_offset_force"])
  pItem = panel:NumSlider("Height", "hoverball_offset_height", 5, 1500, 3); pItem:SetDefaultValue(ConVarsDefault["hoverball_offset_height"])
  pItem = panel:NumSlider("Air Resistance", "hoverball_offset_air_resistance", 0, 30, 3); pItem:SetDefaultValue(ConVarsDefault["hoverball_offset_air_resistance"])
  pItem = panel:NumSlider("Angular Damping", "hoverball_offset_angular_damping", 0, 100, 3); pItem:SetDefaultValue(ConVarsDefault["hoverball_offset_angular_damping"])
  pItem = panel:CheckBox("Hovers over water", "hoverball_offset_detects_water")
  pItem = panel:CheckBox("Disable collisions", "hoverball_offset_nocollide")

  pItem = vgui.Create("CtrlNumPad", panel)
  pItem:SetLabel1("Increase height")
  pItem:SetLabel2("Decrease height")
  pItem:SetConVar1("hoverball_offset_key_heightup")
  pItem:SetConVar2("hoverball_offset_key_heightdown")
  panel:AddPanel(pItem)

  pItem = vgui.Create("CtrlNumPad", panel)
  pItem:SetLabel1("Toggle on/off")
  pItem:SetLabel2("Brake (Hold)")
  pItem:SetConVar1("hoverball_offset_key_toggle")
  pItem:SetConVar2("hoverball_offset_key_brake")
  panel:AddPanel(pItem)

  pItem = panel:NumSlider("Height adjust rate", "hoverball_offset_adjust_speed", 0, 100, 3); pItem:SetDefaultValue(ConVarsDefault["hoverball_offset_adjust_speed"])
  pItem = panel:NumSlider("Braking resistance", "hoverball_offset_brake_resistance", 1, 30, 3); pItem:SetDefaultValue(ConVarsDefault["hoverball_offset_brake_resistance"])
  panel:ControlHelp("All keyboard controls are optional, Hoverballs can work fine without them.")
  panel:ControlHelp("Braking works by increasing the air resistance value while you're holding the brake key.")

  -- Little debug message to let users know if wire support is working.
  if WireLib then panel:AddControl("Header", {Description = "Wiremod integration: ENABLED"}) end
end

function TOOL:UpdateGhostHoverball(ent, ply)
  if (not IsValid(ent)) then return end

  local trace = ply:GetEyeTrace()
  if IsValid(trace.Entity) then
    if (not trace.Hit or trace.Entity and
       (trace.Entity:GetClass() == "offset_hoverball" or trace.Entity:IsPlayer())
    ) then
      ent:SetNoDraw(true)
      return
    end
  end

  local ang = trace.HitNormal:Angle()
  ang.pitch = ang.pitch + 90
  ent:SetAngles(ang)

  local CurPos = ent:GetPos()
  local NrPoint = ent:NearestPoint(CurPos - (trace.HitNormal * 512))
  local Offset = CurPos - NrPoint
  ent:SetPos(trace.HitPos + Offset)

  ent:SetNoDraw(false)
end

local function IsValidHoverballModel(model)
  return list.HasEntry("DistanceHoverballModels", model:lower())
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
  CreateConVar("sbox_maxoffset_hoverball", 20, FCVAR_ARCHIVE, "How many distance hoverballs are players allowed?", 0)

  function NewHoverballOffset(ply, pos, hoverdistance, hoverforce, damping, rotdamping, detectswater, adjustspeed,
                              model, nocollide, key_toggle, key_heightup, key_heightdown, key_brake,
                              brakeresistance)

    if (IsValid(ply) and not ply:CheckLimit("offset_hoverball")) then return false end
    if (not IsValidHoverballModel(model)) then return false end

    local ball = ents.Create("offset_hoverball")
    if (not IsValid(ball)) then return false end
    ball:SetPos(pos)
    ball.hoverdistance   = hoverdistance
    ball.hoverforce      = hoverforce
    ball.damping         = damping
    ball.rotdamping      = rotdamping
    ball.detectswater    = tobool(detectswater)
    ball.nocollide       = tobool(nocollide)
    ball.adjustspeed     = adjustspeed
    ball.brakeresistance = brakeresistance
    ball:SetModel(model)
    ball:Spawn()
    ball:UpdateMask()
    ball:UpdateCollide()
    ball:UpdateHoverText()

    -- Setup numpad controls:
    ball.key_heightup       = numpad.OnDown(ply, key_heightup  , "offset_hoverball_heightup"  , ball, true)
	ball.key_heightbackup   = numpad.OnUp  (ply, key_heightup  , "offset_hoverball_heightup"  , ball, false)
    ball.key_heightdown     = numpad.OnDown(ply, key_heightdown, "offset_hoverball_heightdown", ball, true)
    ball.key_heightbackdown = numpad.OnUp  (ply, key_heightdown, "offset_hoverball_heightdown", ball, false)
    ball.key_brake          = numpad.OnDown(ply, key_brake     , "offset_hoverball_brake"     , ball, true)
	ball.key_brakerelease    = numpad.OnUp  (ply, key_brake     , "offset_hoverball_brake"     , ball, false)

    if (key_toggle) then ball.key_toggle = numpad.OnDown(ply, key_toggle, "offset_hoverball_toggle", ball) end

    local ttable = {
      pl = ply,
      model = model,
      damping = damping,
      nocollide = nocollide,
      key_brake = key_brake,
      key_toggle = key_toggle,
      hoverforce = hoverforce,
      rotdamping = rotdamping,
      adjustspeed = adjustspeed,
      key_heightup = key_heightup,
      detectswater = detectswater,
      hoverdistance = hoverdistance,
      key_heightdown = key_heightdown,
      brakeresistance = brakeresistance
    }
    table.Merge(ball:GetTable(), ttable)

    if (IsValid(ply)) then
      ball:SetPlayer(ply)
      ball:SetCreator(ply)
      ply:AddCount("offset_hoverballs", ball)
      ply:AddCleanup("offset_hoverballs", ball)
    end

    DoPropSpawnedEffect(ball)

    return ball
  end

  duplicator.RegisterEntityClass("offset_hoverball", NewHoverballOffset, ply, "pos", "hoverdistance", "hoverforce",
                                 "damping", "rotdamping", "detectswater", "adjustspeed", "model", "nocollide",
                                 "key_toggle", "key_heightup", "key_heightdown", "key_brake", "brakeresistance")
end

if (CLIENT) then
  language.Add("tool.hoverball_offset.name", "Hoverball - Offset")
  language.Add("tool.hoverball_offset.desc", "Hoverballs that keep relative distance to the ground and can go up and down slopes.")
  language.Add("tool.hoverball_offset.0"   , "LMB: Place or update hoverball, RMB: Copy settings, REL: Remove. Select an entity to weld to it.")
  language.Add("undone.hoverball_offset"   , "Undone offset hoverball")
end

list.Set("DistanceHoverballModels", "models/dav0r/hoverball.mdl", {})
list.Set("DistanceHoverballModels", "models/maxofs2d/hover_basic.mdl", {})
list.Set("DistanceHoverballModels", "models/maxofs2d/hover_classic.mdl", {})
list.Set("DistanceHoverballModels", "models/maxofs2d/hover_plate.mdl", {})
list.Set("DistanceHoverballModels", "models/maxofs2d/hover_propeller.mdl", {})
list.Set("DistanceHoverballModels", "models/maxofs2d/hover_rings.mdl", {})
list.Set("DistanceHoverballModels", "models/combine_helicopter/helicopter_bomb01.mdl", {})
list.Set("DistanceHoverballModels", "models/props_junk/sawblade001a.mdl", {})
list.Set("DistanceHoverballModels", "models/props_wasteland/prison_lamp001c.mdl", {})
list.Set("DistanceHoverballModels", "models/props_phx/wheels/drugster_front.mdl", {})
list.Set("DistanceHoverballModels", "models/props_phx/wheels/metal_wheel1.mdl", {})
list.Set("DistanceHoverballModels", "models/props_phx/smallwheel.mdl", {})
list.Set("DistanceHoverballModels", "models/props_phx/wheels/magnetic_small.mdl", {})
list.Set("DistanceHoverballModels", "models/props_phx/wheels/magnetic_medium.mdl", {})
list.Set("DistanceHoverballModels", "models/props_phx/wheels/magnetic_large.mdl", {})
list.Set("DistanceHoverballModels", "models/mechanics/wheels/wheel_smooth_24f.mdl", {})
list.Set("DistanceHoverballModels", "models/mechanics/wheels/wheel_smooth_48.mdl", {})
list.Set("DistanceHoverballModels", "models/mechanics/wheels/wheel_smooth_72.mdl", {})
list.Set("DistanceHoverballModels", "models/mechanics/wheels/wheel_smooth_18r.mdl", {})
list.Set("DistanceHoverballModels", "models/mechanics/wheels/wheel_smooth_24.mdl", {})
list.Set("DistanceHoverballModels", "models/mechanics/wheels/wheel_rounded_36s.mdl", {})
list.Set("DistanceHoverballModels", "models/props_phx/gears/bevel9.mdl", {})
list.Set("DistanceHoverballModels", "models/props_phx/gears/bevel12.mdl", {})
list.Set("DistanceHoverballModels", "models/props_phx/gears/bevel24.mdl", {})
list.Set("DistanceHoverballModels", "models/props_phx/gears/bevel36.mdl", {})
list.Set("DistanceHoverballModels", "models/hunter/plates/plate025x025.mdl", {})
list.Set("DistanceHoverballModels", "models/hunter/blocks/cube025x025x025.mdl", {})
list.Set("DistanceHoverballModels", "models/hunter/blocks/cube05x05x025.mdl", {})
list.Set("DistanceHoverballModels", "models/hunter/blocks/cube05x05x05.mdl", {})
list.Set("DistanceHoverballModels", "models/squad/sf_plates/sf_plate1x1.mdl", {})
list.Set("DistanceHoverballModels", "models/squad/sf_plates/sf_plate2x2.mdl", {})
list.Set("DistanceHoverballModels", "models/hunter/misc/sphere025x025.mdl", {})
list.Set("DistanceHoverballModels", "models/props_phx/misc/potato_launcher_cap.mdl", {})
list.Set("DistanceHoverballModels", "models/xqm/jetenginepropeller.mdl", {})
list.Set("DistanceHoverballModels", "models/items/combine_rifle_ammo01.mdl", {})
