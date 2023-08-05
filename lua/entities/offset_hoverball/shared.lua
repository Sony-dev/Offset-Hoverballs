ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Category = "Other"

ENT.PrintName = "Offset Hoverball"
ENT.Author = ""
ENT.Contact = ""
ENT.Purpose = "Spawn me using the tool, not this menu please."
ENT.Instructions = ""
ENT.Spawnable = true
ENT.AdminOnly = false -- This can't be true or they won't be spawnable.

local function traceFilter(ent) if (ent:GetClass() == "prop_physics") then return false end end

function ENT:GetTrace(origin, length, output)
  local hover, hmask = self.hoverdistance, self.mask
  local hleng = (length or (-hover * 2))
  local hbpos = (origin or self:GetPos())
  local tr = util.TraceLine({
    start  = hbpos, output = output,
    endpos = hbpos + Vector(0, 0, hleng),
    filter = traceFilter, mask = hmask
  }); tr.distance = math.abs(hleng) * tr.Fraction
  return tr
end
