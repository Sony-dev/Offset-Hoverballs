AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local statInfo = {"Brake enabled", "Hover disabled"}
local formInfoBT = "%g,%g,%g,%g,%g,%g" -- For better tooltip.
local CoBrake1 = Color(255, 100, 100)
local CoBrake2 = Color(255, 255, 255)

-- https://wiki.facepunch.com/gmod/Enums/MASK
function ENT:UpdateMask(mask)
	self.mask = mask or MASK_NPCWORLDSTATIC
	if (self.detects_water) then
		self.mask = bit.bor(self.mask, MASK_WATER)
	end
end

-- https://wiki.facepunch.com/gmod/Enums/COLLISION_GROUP
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

function ENT:UpdateHoverText(str)
	self:SetNWString("OHB-BetterTip", tostring(str or "")..","..
		formInfoBT:format(self.hoverdistance, self.hoverforce, self.damping,
		                  self.rotdamping   , self.hovdamping, self.brakeresistance))
end

function ENT:Initialize()

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self:UpdateMask()
	self:UpdateCollide()

	self.delayedForce = 0
	self.hoverenabled = false
	self.damping = 2                   -- Is air_resistance value from tool.
	self.rotdamping = 10               -- Is angular_damping value from tool.
	self.damping_actual = self.damping -- Needed to account for braking.
	self.hovdamping = 10               -- Controls the vertical damping when going up/down.
	self.up_input = 0
	self.down_input = 0
	self.slip = 0                      -- Slippery mode is considered enabled if this is anything but 0.
	self.minslipangle = 0.1
	
	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake() -- Starts calling `PhysicsUpdate`
		phys:SetDamping(0.4, 1)
		phys:SetMass(50)
	end

	-- If wiremod is installed then add some wire inputs to our ball.
	if WireLib then self.Inputs = WireLib.CreateInputs(self, {"Enable", "Height", "Brake", "Force", "Air resistance", "Angular damping", "Hover damping", "Brake strength", "Slip", "Min slip angle"}) end
end

function ENT:PhysicsUpdate()
	-- Don't bother doing anything if we're switched off.
	if (not self.hoverenabled) then return end

	-- Pulling the physics object from PhysicsUpdate()
	-- Doesn't seem to work quite right. This will do for now.
	local phys = self:GetPhysicsObject()
	if (not phys:IsValid()) then return end

	-- Do not update unless the game is running
	-- Otherwise the entity will sag when game is unpaused
	if (FrameTime() == 0) then return end

	local hbpos = self:GetPos()
	local force, vforce = 0, Vector()
	local hoverdistance = self.hoverdistance

	-- Handle smoothly adjusting up and down. Controlled by above inputs
	-- If this is 0 we do nothing, if it is -1 we go down, 1 we go up
	local smoothadjust = (self.up_input + self.down_input)

	if smoothadjust ~= 0 then -- Smooth adjustment is +1/-1
		self.hoverdistance = self.hoverdistance + smoothadjust * self.adjustspeed
		self.hoverdistance = math.max(0.01, self.hoverdistance)
		self:UpdateHoverText() -- Update hover text accordingly
	end

	phys:SetDamping(self.damping_actual, self.rotdamping)

	local tr = self:GetTrace()

	if (tr.distance < hoverdistance) then
		force = (hoverdistance - tr.distance) * self.hoverforce
		-- Apply hover damping. Defines transition process when
		-- the ball goes up/down. This is the derivative term of
		-- the PD-controller. It is tuned by the hover_damping value
		vforce.z = vforce.z - phys:GetVelocity().z * self.hovdamping

		-- Experimental sliding physics:
		if tr.Hit and self.slip ~= 0 then
			if math.abs(tr.HitNormal.x) > self.minslipangle or
				math.abs(tr.HitNormal.y) > self.minslipangle
			then
				vforce.x = vforce.x + tr.HitNormal.x * self.slip
				vforce.y = vforce.y + tr.HitNormal.y * self.slip
			end
		end
	end

	if (force > self.delayedForce) then
		self.delayedForce = (self.delayedForce * 2 + force) / 3
	else
		self.delayedForce = self.delayedForce * 0.7
	end
	vforce.z = vforce.z + self.delayedForce

	phys:ApplyForceCenter(vforce)
end

-- Modify up input on keydown
numpad.Register("offset_hoverball_heightup", function(pl, ent, keydown)
	if (not IsValid(ent)) then return false end
	ent.up_input = keydown and 1 or 0
	return true
end)

-- Modify down input on keydown
numpad.Register("offset_hoverball_heightdown", function(pl, ent, keydown)
	if (not IsValid(ent)) then return false end
	ent.down_input = keydown and -1 or 0
	return true
end)

numpad.Register("offset_hoverball_toggle", function(pl, ent, keydown)
	if (not IsValid(ent)) then return false end
	ent.hoverenabled = (not ent.hoverenabled)

	if (not ent.hoverenabled) then
		ent.damping_actual = ent.damping
		ent:SetColor(CoBrake2)
		ent:UpdateHoverText(statInfo[2] .. "\n") -- Shows disabled header on tooltip.
	else
		ent:UpdateHoverText()
		ent:PhysWake() -- Nudges the physics entity out of sleep, was sometimes causing issues.
	end

	ent:PhysicsUpdate()
	return true
end)

numpad.Register("offset_hoverball_brake", function(pl, ent, keydown)
	if (not IsValid(ent)) then return false end
	if not ent.hoverenabled then return end

	if (keydown and ent.hoverenabled) then -- Brakes won't work if hovering is disabled.
		ent.damping_actual = ent.brakeresistance
		ent:UpdateHoverText(statInfo[1] .. "\n")
		ent:SetColor(CoBrake1)
	else
		ent.damping_actual = ent.damping
		ent:UpdateHoverText()
		ent:SetColor(CoBrake2)
	end

	ent:PhysicsUpdate()
	return true
end)

-- Manage wiremod inputs.
if WireLib then
	function ENT:TriggerInput(name, value)

		if (not IsValid(self)) then return false end

		if name == "Brake" then
			if not self.hoverenabled then return end
			if (value >= 1 and self.hoverenabled) then -- Brakes won't work if hovering is disabled.
				self.damping_actual = self.brakeresistance
				self:UpdateHoverText(statInfo[1] .. "\n")
				self:SetColor(CoBrake1)
			else
				self.damping_actual = self.damping
				self:UpdateHoverText()
				self:SetColor(CoBrake2)
			end
			self:PhysicsUpdate()
			return

		elseif name == "Enable" then
			self.hoverenabled = tobool(value)
		
			if self.hoverenabled then
				self:UpdateHoverText()
				self:PhysWake()
			else
				self.damping_actual = self.damping
				self:SetColor(CoBrake2)
				self:UpdateHoverText(statInfo[2] .. "\n")
			end
			self:PhysicsUpdate()
			return

		elseif name == "Height" then
			if type(value) == "number" then self.hoverdistance = math.abs(value) end

		elseif name == "Force" then
			if type(value) == "number" then self.hoverforce = math.Clamp(value, 0, 999999) end -- Clamped to prevent physics crash.

		elseif name == "Air resistance" then
			if type(value) == "number" then self.damping = math.abs(value) end

		elseif name == "Angular damping" then
			if type(value) == "number" then self.rotdamping = math.abs(value) end

		elseif name == "Hover damping" then
			if type(value) == "number" then self.hovdamping = math.abs(value) end

		elseif name == "Brake strength" then
			if type(value) == "number" then
				self.brakeresistance = math.abs(value)

				-- Update brakes if they're on.
				if self.damping_actual == self.brakeresistance then
					self.brakeresistance = value
					self.damping_actual = self.brakeresistance
				else
					self.brakeresistance = value
				end
			end
			
		elseif name == "Slip" then
			if type(value) == "number" then self.slip = math.abs(value) end
			
		elseif name == "Min slip angle" then
			if type(value) == "number" then self.minslipangle = math.abs(value) end
			
		end
		
		self:UpdateHoverText()
	end
end
