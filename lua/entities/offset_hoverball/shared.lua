ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Category = "Other"
ENT.PrintName = "Offset Hoverball"
ENT.Spawnable = false -- Disable spawning via entities menu. Use the tool.
ENT.AdminOnly = false -- This can't be true or they won't be spawnable.

local function traceFilter(ent) if (ent:GetClass() == "prop_physics") then return false end end

function ENT:GetTrace(origin, length, output)
	local filter = self.props and self.props or traceFilter
	local hover, hmask = self.hoverdistance, self.mask
	local hleng = (length or (-hover * 2))
	local hbpos = (origin or self:GetPos())
	local tr = util.TraceLine({
		collisiongroup = COLLISION_GROUP_NONE,
		start  = hbpos, output = output,
		endpos = hbpos + Vector(0, 0, hleng),
		filter = filter, mask = hmask
	}); tr.Distance = math.abs(hleng) * tr.Fraction
	return tr
end

function ENT:SetHoverForce(arg)
	self.hoverforce = math.Clamp(math.abs(tonumber(arg) or 0), 0, 999999)
end

function ENT:SetHoverDistance(arg)
	self.hoverdistance = math.Clamp(math.abs(tonumber(arg) or 0), 0, 999999)
end
