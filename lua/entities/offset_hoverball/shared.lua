ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Category = "Other"
ENT.PrintName = "Offset Hoverball"
ENT.Author = "" --Autor name... Sony-dev  ?
ENT.Contact = "" -- Autor e-mail
ENT.Purpose = "Spawn using the tool, not this menu please."
ENT.Instructions = "Snap to a prop to make it hover at a distance"
ENT.Spawnable = false -- Disable spawning via entities menu. Use the tool
ENT.AdminOnly = false -- This can't be true or they won't be spawnable.

local gsModes = "offset_hoverball"
local gsClass = "offset_hoverball"

local statInfo = {"Brake enabled", "Hover disabled"}

function ENT:GetHeader(idx)
	return (self.hoverenabled and "" or tostring(idx and statInfo[idx] or "N/A").."\n")
end

function ENT:SetPosition(trace, mar)
	local pos, mar = self:GetPos(), (tonumber(mar) or 0)
	local pnt = self:NearestPoint(pos - (trace.HitNormal * mar))
	pos:Sub(pnt); pos:Add(trace.HitPos); self:SetPos(pos)
end

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
	}); tr.distance = math.abs(hleng) * tr.Fraction
	return tr
end
