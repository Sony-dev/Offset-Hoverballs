AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- TODO: Perhaps some kind smooth start setting? Softly raises and lowers the ride height when toggled on and off.

local statInfo = {"-- BRAKES ON --", "-- DISABLED --"}
local formInfo = "Hover height: %g\nForce: %g\nAir resistance: %g\nAngular damping: %g\n Brake resistance: %g"
local brakColr = {Color(255, 100, 100), Color(255, 255, 255)}

function ENT:UpdateMask()
  self.mask = MASK_NPCWORLDSTATIC
  if (self.detectswater) then
    self.mask = self.mask + MASK_WATER
  end
end

function ENT:UpdateCollide()
  local phy = self:GetPhysicsObject()
  if (self.nocollide) then
    if (IsValid(phy)) then phy:EnableCollisions(false) end
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)
  else
    if (IsValid(phy)) then phy:EnableCollisions(true) end
    self:SetCollisionGroup(COLLISION_GROUP_DISSOLVING)
  end
end

function ENT:Initialize()
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid(SOLID_VPHYSICS)
  self:UpdateMask()
  self:UpdateCollide()
  self.delayedForce = 0
  local phys = self:GetPhysicsObject()
  if (phys:IsValid()) then
    phys:Wake() -- Starts calling `PhysicsUpdate`
    phys:SetDamping(0.4, 1)
    phys:SetMass(50)
  end

  self.HoverEnabled = true -- We start on.
  self.damping_actual = self.damping -- Need an extra var to account for braking.
  self.SmoothHeightAdjust = 0 -- If this is 0 we do nothing, if it is -1 we go down, 1 we go up.

  -- If wiremod is installed then add some wire inputs to our ball.
  if WireLib then
    self.Inputs = WireLib.CreateInputs(self,
      {"Enable", "Height", "Brake", "Force", "Damping", "Brake resistance"})
  end
end

local function traceFilter(ent) if (ent:GetClass() == "prop_physics") then return false end end

function ENT:UpdateHoverText(str)
  self:SetOverlayText(tostring(str or "")..formInfo:format(
    self.hoverdistance, self.hoverforce, self.damping, self.rotdamping, self.brakeresistance))
end

function ENT:PhysicsUpdate(phys)
  if not IsValid(phys) then return end
  if self.HoverEnabled == false then return end -- Don't bother doing anything if we're switched off.

  local force = 0
  local hbpos = self:GetPos()
  local detectmask = self.mask
  local hoverforce = self.hoverforce
  local hoverdistance = self.hoverdistance

  -- Handle smoothly adjusting up and down.
  local SmoothHeightAdjust = self.SmoothHeightAdjust

  if SmoothHeightAdjust == 1 then
    self.hoverdistance = self.hoverdistance + self.adjustspeed
    self:UpdateHoverText()
  elseif SmoothHeightAdjust == -1 then
    self.hoverdistance = self.hoverdistance - self.adjustspeed
    self:UpdateHoverText()
  end

  phys:SetDamping(self.damping_actual, self.rotdamping)
  local tr = util.TraceLine({start = hbpos, endpos = hbpos + Vector(0, 0, -hoverdistance * 2), filter = traceFilter, mask = detectmask})

  local distance = self:GetPos():Distance(tr.HitPos)

  if (distance < hoverdistance) then
    force = -(distance - hoverdistance) * hoverforce
    phys:ApplyForceCenter(Vector(0, 0, -phys:GetVelocity().z * 8))
  else
    force = 0
  end

  if (force > self.delayedForce) then
    self.delayedForce = (self.delayedForce * 2 + force) / 3
  else
    self.delayedForce = self.delayedForce * 0.7
  end
  phys:ApplyForceCenter(Vector(0, 0, self.delayedForce))
end

if (SERVER) then

  numpad.Register("offset_hoverball_heightup", function(pl, ent, keydown, idx)
    if (not IsValid(ent)) then return false end
    if (keydown) then
      ent.SmoothHeightAdjust = 1
    else
      ent.SmoothHeightAdjust = 0
    end
    return true
  end)

  numpad.Register("offset_hoverball_heightdown", function(pl, ent, keydown)
    if (not IsValid(ent)) then return false end
    if (keydown) then
      ent.SmoothHeightAdjust = -1
    else
      ent.SmoothHeightAdjust = 0
    end
    return true
  end)

  numpad.Register("offset_hoverball_toggle", function(pl, ent, keydown)
    if (not IsValid(ent)) then return false end
    ent.HoverEnabled = (not ent.HoverEnabled)

  if (not ent.HoverEnabled) then

    -- FIX: Brake damping still doesn't change when switched off?
    ent.damping_actual = ent.damping
    ent:SetColor(Color(255, 255, 255))

    ent:UpdateHoverText(statInfo[2] .. "\n")
  else
    ent:UpdateHoverText()
    ent:PhysWake() -- Nudges the physics entity out of sleep, was sometimes causing issues.
  end

    ent:PhysicsUpdate()
    return true
  end)

  numpad.Register("offset_hoverball_brake", function(pl, ent, keydown)
    if (not IsValid(ent)) then return false end
  if (not ent.HoverEnabled) then return end

    if (keydown) then
      ent.damping_actual = ent.brakeresistance
      ent:UpdateHoverText(statInfo[1] .. "\n")
      ent:SetColor(Color(255, 100, 100))
    else
      ent.damping_actual = ent.damping
      ent:UpdateHoverText()
      ent:SetColor(Color(255, 255, 255))
    end
    ent:PhysicsUpdate()
    return true
  end)

end

-- Manage wiremod inputs.
if WireLib then
  function ENT:TriggerInput(name, value)

    if (not IsValid(self)) then return false end

    self.TitleText = ""

    if name == "Brake" then
      if value >= 1 then
        self.damping_actual = self.brakeresistance
        self.TitleText = statInfo[1] .. "\n"
        self:SetColor(brakColr[1])
        self:PhysicsUpdate()
      else
        self.damping_actual = self.damping
        self:SetColor(brakColr[2])
        self:PhysicsUpdate()
      end

    elseif name == "Enable" then
      if value >= 1 then
        self.HoverEnabled = true
      else
        self.HoverEnabled = false
        self.TitleText = statInfo[2] .. "\n"
      end
      self:PhysicsUpdate()

    elseif name == "Height" then
      self.hoverdistance = value

    elseif name == "Force" then
      self.hoverforce = value

    elseif name == "Damping" then
      self.damping = value

    elseif name == "Brake resistance" then

      -- Update brakes if they're on.
      if self.damping_actual == self.brakeresistance then
        self.brakeresistance = value
        self.damping_actual = self.brakeresistance
      else
        self.brakeresistance = value
      end
    end

    self:UpdateHoverText(self.TitleText)
  end
end
