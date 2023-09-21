AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local gsModes = "offset_hoverball"
local gsClass = "offset_hoverball"
local formInfoBT = "%g,%g,%g,%g,%g,%g" -- For better tooltip.
local CoBrake1 = Color(255, 100, 100)
local CoBrake2 = Color(255, 255, 255)

util.AddNetworkString(gsModes.."SendUpdateMask")
util.AddNetworkString(gsModes.."SendUpdateFilter")

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

-- https://wiki.facepunch.com/gmod/Enums/MASK
-- TODO: Properly send this information to the client
function ENT:UpdateMask(mask)
	self.mask = mask or MASK_NPCWORLDSTATIC
	if (self.detects_water) then
		self.mask = bit.bor(self.mask, MASK_WATER)
	end
	if (self.detects_props) then
		self.mask = bit.bor(self.mask, MASK_SOLID)
	end
	net.Start(gsModes.."SendUpdateMask")
		net.WriteEntity(self)
		net.WriteUInt(self.mask, 32)
	net.Send(self:GetCreator())
end

--[[
	Updates the trace filter when hit props is enabled
	set > Custom filter hash list being used [tab.Res]
	 * table   > A table of entities
	 * string  > Entity IDs separated by commas
	 * number  > An entity ID
	 * boolean > Act accordingly:
	   1. True : Use self entity as trace filter
	   2. False: Remove the trace filter entierly
	tab.Res > Table in format {K1   = Ent1, K2   = Ent2}
	tab.Key > Table in format {Ent1 = true, Ent2 = true}
]]
local function getProps(self)
	local tab = self.props
	if tab then table.Empty(self.props)
	else self.props = {}; tab = self.props end
	tab.Key, tab.Res = {}, {}
	tab.Key[self] = true; return tab
end

local function setProps(self)
	local cnt, str, tab = 1, "", self.props
	for k, v in pairs(tab.Res) do tab.Key[v] = true end; table.Empty(tab.Res)
	for k, v in pairs(tab.Key) do tab[cnt] = k; str = str..k:EntIndex()..","; cnt = cnt + 1 end
	table.Empty(tab.Res); table.Empty(tab.Key); tab.Key, tab.Res, cnt = nil, nil, nil
	net.Start(gsModes.."SendUpdateFilter")
		net.WriteEntity(self)
		net.WriteString(str:sub(1, -2))
	net.Send(self:GetCreator())
end

function ENT:UpdateFilter(set)
	if(set == false) then
		table.Empty(self.props)
		self.props = nil
		net.Start(gsModes.."SendUpdateFilter")
			net.WriteEntity(self)
			net.WriteString("nil")
		net.Send(self:GetCreator())
	else
		if(set) then
			local typ = type(set)
			if(typ == "table") then
				local tab = getProps(self)
					for k, v in pairs(set) do
						tab.Res[k] = set[k]
					end
				setProps(self)
			elseif(typ == "string") then
				local tab, i = getProps(self), 0
				local exp = (","):Explode(set)
					for k, v in pairs(exp) do
						local e = Entity(tonumber(v) or 0)
						if(e and e:IsValid()) then
							i = i + 1; tab.Res[i] = e
						end
					end
				setProps(self)
			elseif(typ == "number") then
				local tab = getProps(self)
					tab.Res[1] = Entity(set)
				setProps(self)
			elseif(typ == "boolean") then
				local tab = getProps(self)
					tab.Res[1] = self
				setProps(self)
			end
		elseif(constraint.HasConstraints(self)) then
			local tab = getProps(self)
			constraint.GetAllConstrainedEntities(self, tab.Res)
			setProps(self)
		end
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
	if WireLib then self.Inputs = WireLib.CreateInputs(self, {
		"Enable", "Height", "Brake", "Force","Air resistance",
		"Angular damping", "Hover damping", "Brake strength", "Slip", "Min slip angle"
	}) end
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
		
		-- Bit scuffed, but doesn't use an extra var
		-- Quick-fix for adjusting height with brakes on removing the header.
		if self.damping_actual == self.brakeresistance then
			self:UpdateHoverText(self:GetHeader(1))
		else
			self:UpdateHoverText()
		end
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
numpad.Register(gsClass.."_heightup", function(pl, ent, keydown)
	if (not IsValid(ent)) then return false end
	ent.up_input = keydown and 1 or 0
	return true
end)

-- Modify down input on keydown
numpad.Register(gsClass.."_heightdown", function(pl, ent, keydown)
	if (not IsValid(ent)) then return false end
	ent.down_input = keydown and -1 or 0
	return true
end)

numpad.Register(gsClass.."_toggle", function(pl, ent, keydown)
	if (not IsValid(ent)) then return false end
	ent.hoverenabled = (not ent.hoverenabled)

	if (not ent.hoverenabled) then
		ent.damping_actual = ent.damping
		ent:SetColor(CoBrake2)
		ent:UpdateHoverText(ent:GetHeader(2)) -- Shows disabled header on tooltip.
	else
		ent:UpdateHoverText()
		ent:PhysWake() -- Nudges the physics entity out of sleep, was sometimes causing issues.
	end

	ent:PhysicsUpdate()
	return true
end)

numpad.Register(gsClass.."_brake", function(pl, ent, keydown)
	if (not IsValid(ent)) then return false end
	if not ent.hoverenabled then return end -- Brakes won't react if hovering is disabled.

	if (keydown and ent.hoverenabled) then
		ent.damping_actual = ent.brakeresistance
		ent:UpdateHoverText(ent:GetHeader(1))
		ent:SetColor(CoBrake1)
	else
		ent.damping_actual = ent.damping
		ent:UpdateHoverText()
		ent:SetColor(CoBrake2)
	end

	ent:PhysicsUpdate()
	return true
end)

-- Manage our wiremod inputs.
if WireLib then
	function ENT:TriggerInput(name, value)

		if (not IsValid(self)) then return false end

		if name == "Brake" then
			if not self.hoverenabled then return end -- Brakes won't react if hovering is disabled.

			if (value >= 1 and self.hoverenabled) then
				self.damping_actual = self.brakeresistance
				self:UpdateHoverText(self:GetHeader(1))
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
				self:UpdateHoverText(self:GetHeader(2))
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
	end
end

function ENT:Setup(ply, pos, ang, hoverdistance, hoverforce, damping,
	rotdamping, hovdamping, detects_water, detects_props, start_on,
	adjustspeed, nocollide, key_toggle,
	key_heightup, key_heightdown, key_brake,
	brakeresistance, slip, minslipangle)
	-- Setup position and angle
	if(pos) then self:SetPos(pos) end
	if(ang) then self:SetAngles(ang) end

	-- Remove existing keybinds.
	numpad.Remove(self.imp_heightup)
	numpad.Remove(self.imp_heightbackup)
	numpad.Remove(self.imp_heightdown)
	numpad.Remove(self.imp_heightbackdown)
	numpad.Remove(self.imp_brake)
	numpad.Remove(self.imp_brakerelease)
	numpad.Remove(self.imp_toggle)

	-- Get new keybinds and save them to the entity so that the duplicator can recreate them later.
	self.key_brake      = tonumber(key_brake     )
	self.key_toggle     = tonumber(key_toggle    )
	self.key_heightup   = tonumber(key_heightup  )
	self.key_heightdown = tonumber(key_heightdown)

	-- Update keybinds from above.
	self.imp_heightup       = numpad.OnDown(ply, self.key_heightup  , gsModes.."_heightup"  , self, true)
	self.imp_heightbackup   = numpad.OnUp  (ply, self.key_heightup  , gsModes.."_heightup"  , self, false)
	self.imp_heightdown     = numpad.OnDown(ply, self.key_heightdown, gsModes.."_heightdown", self, true)
	self.imp_heightbackdown = numpad.OnUp  (ply, self.key_heightdown, gsModes.."_heightdown", self, false)
	self.imp_brake          = numpad.OnDown(ply, self.key_brake     , gsModes.."_brake"     , self, true)
	self.imp_brakerelease   = numpad.OnUp  (ply, self.key_brake     , gsModes.."_brake"     , self, false)

	-- No OnUp func required for toggle.
	self.imp_toggle = numpad.OnDown(ply, self.key_toggle, gsModes.."_toggle", self, true)

	-- Update settings to our new values. Place value clampings here in this method
	self.hoverforce      = math.Clamp(tonumber(hoverforce)    or 0, 0, 999999) -- Clamped to fix physics crash.
	self.hoverdistance   = math.Clamp(tonumber(hoverdistance) or 0, 0, 999999)
	self.adjustspeed     = tonumber(adjustspeed    )
	self.damping         = tonumber(damping        )
	self.rotdamping      = tonumber(rotdamping     )
	self.hovdamping      = tonumber(hovdamping     )
	self.brakeresistance = tonumber(brakeresistance)
	self.minslipangle    = tonumber(minslipangle   )
	self.slip            = tonumber(slip           )
	self.nocollide       = tobool(nocollide    )
	self.detects_water   = tobool(detects_water)
	self.detects_props   = tobool(detects_props)
	self.start_on        = tobool(start_on     )

	-- Depends on entity internals.
	self:UpdateMask()
	self:UpdateFilter()
	self:UpdateCollide()
	self:UpdateHoverText(self:GetHeader(2))

	-- Fixes issue with air-resi not updating correctly.
	self.damping_actual = self.damping

	-- Start the hoverball if applicavle
	self.hoverenabled = self.start_on

	self:PhysicsUpdate()
end

--[[
	Specific stuff to do after HB is pasted
]]
function ENT:PostEntityPaste(ply, ball, info)
	ball:UpdateMask()
	if(ball.detects_props) then
		ball:UpdateFilter(info)
	else
		ball:UpdateFilter(false)
	end
	ball:UpdateCollide()
	ball:UpdateHoverText(ball:GetHeader(2))
end
