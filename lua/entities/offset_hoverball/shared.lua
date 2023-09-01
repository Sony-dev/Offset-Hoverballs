ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Category = "Other"
ENT.PrintName = "Offset Hoverball"
ENT.Author = "" --Autor name... Sony-dev  ?
ENT.Contact = "" -- Autor e-mail
ENT.Purpose = "Spawn me using the tool, not this menu please."
ENT.Instructions = "Snap to a prop to make it hover at a distance"
ENT.Spawnable = false -- Disable spawning via entities menu. Use the tool
ENT.AdminOnly = false -- This can't be true or they won't be spawnable.

local ToolMode = GetConVar("gmod_toolmode")

local function traceFilter(ent) if (ent:GetClass() == "prop_physics") then return false end end

function ENT:GetTrace(origin, length, output)
	--local hover, hmask = self.hoverdistance, self.mask
	local filter = self.props and self.props or traceFilter
	local hover, hmask = self.hoverdistance, MASK_SOLID
	local hleng = (length or (-hover * 2))
	local hbpos = (origin or self:GetPos())
	local tr = util.TraceLine({
		collisiongroup = COLLISION_GROUP_NONE,
		start  = hbpos, output = output,
		endpos = hbpos + Vector(0, 0, hleng),
		filter = filter, mask = hmask
	}); tr.distance = math.abs(hleng) * tr.Fraction
	return tr
end

-- https://wiki.facepunch.com/gmod/Enums/MASK
function ENT:UpdateMask(mask)
	self.mask = mask or MASK_NPCWORLDSTATIC
	if (self.detects_water) then
		self.mask = bit.bor(self.mask, MASK_WATER)
	end
	if (self.detects_solid) then
		self.mask = bit.bor(self.mask, MASK_SOLID)
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
	local mode = ToolMode:GetString()

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
	self.imp_heightup       = numpad.OnDown(ply, self.key_heightup  , mode.."_heightup"  , self, true)
	self.imp_heightbackup   = numpad.OnUp  (ply, self.key_heightup  , mode.."_heightup"  , self, false)
	self.imp_heightdown     = numpad.OnDown(ply, self.key_heightdown, mode.."_heightdown", self, true)
	self.imp_heightbackdown = numpad.OnUp  (ply, self.key_heightdown, mode.."_heightdown", self, false)
	self.imp_brake          = numpad.OnDown(ply, self.key_brake     , mode.."_brake"     , self, true)
	self.imp_brakerelease   = numpad.OnUp  (ply, self.key_brake     , mode.."_brake"     , self, false)

	-- No OnUp func required for toggle.
	self.imp_toggle = numpad.OnDown(ply, self.key_toggle, mode.."_toggle", self, true)

	-- Update settings to our new values.
	self.hoverforce      = math.Clamp(hoverforce, 0, 999999) -- Clamped to fix physics crash.
	self.hoverdistance   = math.Clamp(hoverdistance, 0, 999999)
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
	self:UpdateHoverText()

	-- Fixes issue with air-resi not updating correctly.
	self.damping_actual = self.damping
	self:PhysicsUpdate()
end
