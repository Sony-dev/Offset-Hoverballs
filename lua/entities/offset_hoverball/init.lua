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

		-- Using PhysObj:EnableCollisions caused an issue with duped hoverballs falling through the world.
		-- Also the wiki has red text and who am I to argue?
		
		-- Collides with world but not ents/props/players/etc
		self:SetCollisionGroup(COLLISION_GROUP_WORLD) 
	else
		-- Collides with everything except players and vehicles. The only one to work reliably during testing.
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON) 
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
	   2. False: Remove the trace filter entirely
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
					tab.Res[1] = Entity(math.floor(set))
				setProps(self)
			elseif(typ == "function") then
				local tab = getProps(self)
				local suc, out = pcall(set)
				if(suc) then tab.Res = out -- Success table
				else error("Filter update: "..out) end
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


--[[
	Sends "1", "2" or "" as the header and translate on the client.
	Enables support for multiple languages and reduces NWString size.
	ball:UpdateHoverText()    -- No header
	ball:UpdateHoverText("1") -- Brakes on
	ball:UpdateHoverText("2") -- Hover disabled
]]
function ENT:UpdateHoverText(arg)
	self:SetNWString("OHB-BetterTip", tostring(arg or "")..","
		..formInfoBT:format(self.hoverdistance, self.hoverforce, self.damping,
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
			self:UpdateHoverText(1)
		else
			self:UpdateHoverText()
		end
	end

	phys:SetDamping(self.damping_actual, self.rotdamping)

	local tr = self:GetTrace()

	if (tr.Distance < hoverdistance) then
		force = (hoverdistance - tr.Distance) * self.hoverforce
		-- Apply hover damping. Defines transition process when
		-- the ball goes up/down. This is the derivative term of
		-- the PD-controller. It is tuned by the hover_damping value
		vforce.z = vforce.z - phys:GetVelocity().z * self.hovdamping

		-- Experimental sliding physics:
		if tr.Hit and self.slip ~= 0 then
			local slp, sla = self.slip, self.minslipangle
			local trx, try = tr.HitNormal.x, tr.HitNormal.y
			-- Check normal and make the base prop slide back
			if math.abs(trx) > sla or math.abs(try) > sla then
				vforce.x = vforce.x + trx * slp
				vforce.y = vforce.y + try * slp
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
		ent:UpdateHoverText(2) -- Shows disabled header on tooltip.
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
		ent:UpdateHoverText(1)
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
				self:UpdateHoverText(1)
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
				self:UpdateHoverText(2)
			end
			self:PhysicsUpdate()
			return
		end

		-- Don't update vars if hover isn't enabled.
		if not self.hoverenabled then return end

		if name == "Height" then
			if type(value) == "number" then	self:SetHoverDistance(value) end

		elseif name == "Force" then
			if type(value) == "number" then self:SetHoverForce(value) end

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
		
		-- Update hover text after a value changes via wiremod input.
		-- Don't overwrite the header if the brakes are already enabled.
		if self.damping_actual == self.brakeresistance then
			self:UpdateHoverText(1)
		else
			self:UpdateHoverText()
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
	self.key_brake      = tonumber(key_brake)
	self.key_toggle     = tonumber(key_toggle)
	self.key_heightup   = tonumber(key_heightup)
	self.key_heightdown = tonumber(key_heightdown)

	-- Update keybinds from above.
	self.imp_heightup       = numpad.OnDown(ply, self.key_heightup  , gsModes.."_heightup"  , self, true)
	self.imp_heightbackup   = numpad.OnUp  (ply, self.key_heightup  , gsModes.."_heightup"  , self, false)
	self.imp_heightdown     = numpad.OnDown(ply, self.key_heightdown, gsModes.."_heightdown", self, true)
	self.imp_heightbackdown = numpad.OnUp  (ply, self.key_heightdown, gsModes.."_heightdown", self, false)
	self.imp_brake          = numpad.OnDown(ply, self.key_brake     , gsModes.."_brake"     , self, true)
	self.imp_brakerelease   = numpad.OnUp  (ply, self.key_brake     , gsModes.."_brake"     , self, false)

	-- No OnUp function required for toggle.
	self.imp_toggle = numpad.OnDown(ply, self.key_toggle, gsModes.."_toggle", self, true)

	-- Update settings to our new values. Place value clamps here in this method.
	self:SetHoverForce(hoverforce)
	self:SetHoverDistance(hoverdistance)
	self.adjustspeed     = tonumber(adjustspeed)
	self.damping         = tonumber(damping)
	self.rotdamping      = tonumber(rotdamping)
	self.hovdamping      = tonumber(hovdamping)
	self.brakeresistance = tonumber(brakeresistance)
	self.minslipangle    = tonumber(minslipangle)
	self.slip            = tonumber(slip)
	self.nocollide       = tobool(nocollide)
	self.detects_water   = tobool(detects_water)
	self.detects_props   = tobool(detects_props)
	self.start_on        = tobool(start_on)

	-- Depends on entity internals.
	self:UpdateMask()
	self:UpdateFilter()
	self:UpdateCollide()
	self:UpdateHoverText(self.start_on and "" or 2)

	-- Fixes issue with air-resist not updating correctly.
	self.damping_actual = self.damping

	-- Start the hoverball if applicable.
	self.hoverenabled = self.start_on

	self:PhysicsUpdate()
end

-- Some wirelib stuff that should all be done automatically but isn't because we're not actually a wiremod entity.
local function EntityLookup(created)
	return function(id, default)
		if id == nil then return default end
		if id == 0 then return game.GetWorld() end
		local ent = created[id]
		if IsValid(ent) then return ent else return default end
	end
end

-- Specific stuff to do after HB is pasted
function ENT:PostEntityPaste(ply, ball, info)
	ball:UpdateMask()
	if(ball.detects_props) then
		ball:UpdateFilter(info)
	else
		ball:UpdateFilter(false)
	end
	ball:UpdateCollide()
	ball:UpdateHoverText(self.start_on and "" or 2)
	
	-- We need to re-wire all our inputs as they were before we were duped.
	-- Luckily wirelib has a function for this. Would be great if any of it was documented.
	if WireLib then
		local mods = ball.EntityMods
		if mods and mods.WireDupeInfo then
			WireLib.ApplyDupeInfo(ply, ball, mods.WireDupeInfo, EntityLookup(info))
		end
	end
end

-- Save the wiremod wiring layout so we can recreate it when we're pasted.
-- Source: https://github.com/wiremod/wire/blob/master/lua/entities/base_wire_entity.lua
function ENT:PreEntityCopy()
	if WireLib then
		duplicator.ClearEntityModifier(self, "WireDupeInfo")
		local info = WireLib.BuildDupeInfo(self)
		if info then
			duplicator.StoreEntityModifier(self, "WireDupeInfo", info)
		end
	end
end

-- Supposedly prevents some kind of crash according to wiremod?
-- Unable to verify if actually required for our end.
function ENT:OnEntityCopyTableFinish(dupedata)
	dupedata.OverlayData = nil
	dupedata.lastWireOverlayUpdate = nil
	dupedata.WireDebugName = nil
end