AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
 
include('shared.lua')
 
function ENT:Initialize()

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetCollisionGroup(COLLISION_GROUP_DISSOLVING)
	self.delayedForce = 0
	self.mask = MASK_NPCWORLDSTATIC
	if (self.detectswater) then
		self.mask = self.mask+MASK_WATER
	end
    local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetDamping( 0.4, 1 )
		phys:SetMass(50)
	end
	
	self.HoverEnabled = true // We start on.
	self.damping_actual = self.damping // Need an extra var to account for braking.
end

function ENT:PhysicsUpdate()

	if self.HoverEnabled == false then return end // Don't bother doing anything if we're switched off.

	local hoverdistance = self.hoverdistance
	local hoverforce = self.hoverforce
	local force = 0
	local phys = self:GetPhysicsObject()
	local detectmask = self.mask
	phys:SetDamping( self.damping_actual, self.rotdamping )
	local tr = util.TraceLine( {
	start = self:GetPos(),
	endpos = self:GetPos()+Vector(0,0,-hoverdistance*2),
	filter = function( ent ) if ( ent:GetClass() == "prop_physics" ) then return false end end,
	mask = detectmask
	} )

	local distance = self:GetPos():Distance(tr.HitPos)
	
	if (distance < hoverdistance) then
		force = -(distance-hoverdistance)*hoverforce
		phys:ApplyForceCenter(Vector(0,0,-phys:GetVelocity().z*8))
	else
		force = 0
	end
	
	if (force > self.delayedForce) then
		self.delayedForce = (self.delayedForce*2+force)/3
	else
		self.delayedForce = self.delayedForce*0.7
	end
	phys:ApplyForceCenter(Vector(0,0,self.delayedForce))
end

if ( SERVER ) then

	numpad.Register( "offset_hoverball_heightup", function( pl, ent, keydown, idx )
		if ( !IsValid( ent ) ) then return false end
		if ( keydown ) then
			ent.hoverdistance = ent.hoverdistance + ent.adjustspeed
			ent:SetOverlayText( string.format( "Hover height: %g\nForce: %g\nAir resistance: %g\nAngular damping: %g\n Brake resistance: %g", ent.hoverdistance, ent.hoverforce, ent.damping, ent.rotdamping, ent.brakeresistance  ))
		end
		return true
	end )

	numpad.Register( "offset_hoverball_heightdown", function( pl, ent, keydown )
		if ( !IsValid( ent ) ) then return false end
		if ( keydown ) then
			ent.hoverdistance = ent.hoverdistance - ent.adjustspeed
			ent:SetOverlayText( string.format( "Hover height: %g\nForce: %g\nAir resistance: %g\nAngular damping: %g\n Brake resistance: %g", ent.hoverdistance, ent.hoverforce, ent.damping, ent.rotdamping, ent.brakeresistance  ))
		end
		return true
	end )

	numpad.Register( "offset_hoverball_toggle", function( pl, ent, keydown )
		if ( !IsValid( ent ) ) then return false end
		ent.HoverEnabled = !ent.HoverEnabled
		ent:PhysicsUpdate()
		return true
	end )
	
	numpad.Register( "offset_hoverball_brake", function( pl, ent, keydown )
		if ( !IsValid( ent ) ) then return false end
		if ( keydown ) then
			ent.damping_actual = ent.brakeresistance
			ent:SetOverlayText( string.format( "-- BRAKES ON --\nHover height: %g\nForce: %g\nAir resistance: %g\nAngular damping: %g\n Brake resistance: %g", ent.hoverdistance, ent.hoverforce, ent.damping, ent.rotdamping, ent.brakeresistance  ))
			ent:SetColor(Color(255,100,100))
		else
			ent.damping_actual = ent.damping
			ent:SetOverlayText( string.format( "Hover height: %g\nForce: %g\nAir resistance: %g\nAngular damping: %g\n Brake resistance: %g", ent.hoverdistance, ent.hoverforce, ent.damping, ent.rotdamping, ent.brakeresistance  ))
			ent:SetColor(Color(255,255,255))
		end
		ent:PhysicsUpdate()
		return true
	end )

end