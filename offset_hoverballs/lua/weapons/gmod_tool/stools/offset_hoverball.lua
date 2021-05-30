
// TODO:
// Look into wiremod support?



TOOL.Category = "Construction"
TOOL.Name = "Hoverball - Offset"
TOOL.Command = nil
TOOL.ConfigName = "" --Setting this means that you do not have to create external configuration files to define the layout of the tool config-hud 

TOOL.ClientConVar[ "force" ] = "100"
TOOL.ClientConVar[ "height" ] = "100"
TOOL.ClientConVar[ "air_resistance" ] = "2"
TOOL.ClientConVar[ "angular_damping" ] = "10"
TOOL.ClientConVar[ "detects_water" ] = "true"
TOOL.ClientConVar[ "model" ] = "models/dav0r/hoverball.mdl"
TOOL.ClientConVar[ "adjust_speed" ] = "5"
TOOL.ClientConVar[ "brake_resistance" ] = "15"
TOOL.ClientConVar[ "offset_hoverball_nocollide" ] = "true"

TOOL.ClientConVar[ "key_toggle" ] = "0"
TOOL.ClientConVar[ "key_heightdown" ] = "0"
TOOL.ClientConVar[ "key_heightup" ] = "0"
TOOL.ClientConVar[ "key_brake" ] = "0"

local ConVarsDefault = TOOL:BuildConVarList()

cleanup.Register( "offset_hoverballs" )

function TOOL:LeftClick( trace )
	local model = self:GetClientInfo( "model" )
	if (SERVER) then
	
		// Update existing hoverballs.
		if ( IsValid( trace.Entity ) && trace.Entity:GetClass() == "offset_hoverball" ) then

			trace.Entity.hoverdistance = 		self:GetClientNumber( "height" )
			trace.Entity.hoverforce = 		self:GetClientNumber( "force" )
			trace.Entity.damping = 			self:GetClientNumber( "air_resistance" )
			trace.Entity.rotdamping = 		self:GetClientNumber( "angular_damping" )
			trace.Entity.detectswater = 		self:GetClientNumber( "detects_water" )
			trace.Entity.adjustspeed = 		self:GetClientNumber( "adjust_speed" )
			trace.Entity.brakeresistance = 		self:GetClientNumber( "brake_resistance" )
			trace.Entity:SetOverlayText( string.format( "Hover height: %g\nForce: %g\nAir resistance: %g\nAngular damping: %g\n Brake resistance: %g", trace.Entity.hoverdistance, trace.Entity.hoverforce, trace.Entity.damping, trace.Entity.rotdamping, trace.Entity.brakeresistance  ))

			// Update keys
			numpad.Remove( trace.Entity.key_heightup )
			numpad.Remove( trace.Entity.key_heightbackup )
			numpad.Remove( trace.Entity.key_heightdown )
			numpad.Remove( trace.Entity.key_heightbackdown )
			numpad.Remove( trace.Entity.key_brake )
			numpad.Remove( trace.Entity.key_brakerelease )
			numpad.Remove( trace.Entity.key_toggle )
			
			trace.Entity.key_heightup = numpad.OnDown( ply, key_heightup, "offset_hoverball_heightup", trace.Entity, true )
			trace.Entity.key_heightbackup = numpad.OnUp( ply, key_heightup, "offset_hoverball_heightup", trace.Entity, false )

			trace.Entity.key_heightdown = numpad.OnDown( ply, key_heightdown, "offset_hoverball_heightdown", trace.Entity, true )
			trace.Entity.key_heightbackdown = numpad.OnUp( ply, key_heightdown, "offset_hoverball_heightdown", trace.Entity, false )

			trace.Entity.key_brake = numpad.OnDown( ply, key_brake, "offset_hoverball_brake", trace.Entity, true )
			trace.Entity.key_brakerelase = numpad.OnUp( ply, key_brake, "offset_hoverball_brake", trace.Entity, false )
		
			if ( key_toggle ) then trace.Entity.key_toggle = numpad.OnDown( ply, key_toggle, "offset_hoverball_toggle", trace.Entity ) end
			
			self:GetOwner():ChatPrint( "Updated existing hoverball with new values." )
		else
		
			// Place a new hoverball instead.
			local ball = Create_offset_hoverball( self:GetOwner(), trace.HitPos, self:GetClientNumber( "height" ), self:GetClientNumber( "force" ), self:GetClientNumber( "air_resistance" ), self:GetClientNumber( "angular_damping" ), self:GetClientNumber( "detects_water" ), self:GetClientNumber( "adjust_speed" ), self:GetClientInfo( "model" ), self:GetClientNumber( "offset_hoverball_nocollide" ), self:GetClientNumber( "key_toggle" ), self:GetClientNumber( "key_heightup" ), self:GetClientNumber( "key_heightdown" ), self:GetClientNumber( "key_brake" ), self:GetClientNumber( "brake_resistance" )  )
			
			local ang = trace.HitNormal:Angle()
			ang.pitch = ang.pitch + 90
			ball:SetAngles( ang )
			
			local CurPos = ball:GetPos()
			local NearestPoint = ball:NearestPoint( CurPos - ( trace.HitNormal * 512 ) )
			local Offset = CurPos - NearestPoint
			ball:SetPos(trace.HitPos + Offset)
			
			if (IsValid(trace.Entity)) then
				local weld = constraint.Weld( ball, trace.Entity, 0, trace.PhysicsBone, 0, true , false )
			end
			
			undo.Create( "Offset hoverball" )
				undo.AddEntity( ball )
				undo.SetPlayer( self:GetOwner() )
			undo.Finish()
		end
	end
end

function TOOL:RightClick( trace )
	
end

function TOOL.BuildCPanel( panel )

	panel:AddControl( "Header", { Description = "Hoverballs spawned by this tool will try to maintain their height relative to the terrain." } )

	panel:AddControl( "ComboBox", { MenuButton = 1, Folder = "hoverball_offset", Options = { [ "#preset.default" ] = ConVarsDefault }, CVars = table.GetKeys( ConVarsDefault ), Help = true } )

	panel:AddControl( "PropSelect", { Label = "Model", ConVar = "offset_hoverball_model", Models = list.Get( "DistanceHoverballModels" ), Height = 5 } )
 
	panel:AddControl("Slider", {
	    Label = "Force",
	    Type = "Float",
	    Min = "5",
	    Max = "1000",
	    Command = "offset_hoverball_force"
	})
	
	panel:AddControl("Slider", {
	    Label = "Height",
	    Type = "Float",
	    Min = "5",
	    Max = "1500",
	    Command = "offset_hoverball_height"
	})

	panel:AddControl("Slider", {
	    Label = "Air Resistance",
	    Type = "Float",
	    Min = "0",
	    Max = "30",
	    Command = "offset_hoverball_air_resistance"
	})
	
	panel:AddControl("Slider", {
	    Label = "Angular Damping",
	    Type = "Float",
	    Min = "0",
	    Max = "100",
	    Command = "offset_hoverball_angular_damping"
	})

	panel:AddControl("checkbox", {
		Label = "Hovers over water",
		Command = "offset_hoverball_detects_water"
	})

	panel:AddControl("checkbox", {
		Label = "Spawn nocollided",
		Command = "offset_hoverball_nocollide"
	})
	
	panel:AddControl( "Numpad", { Label = "Increase hover height", Command = "offset_hoverball_key_heightup", Label2 = "Decrease hover height", Command2 = "offset_hoverball_key_heightdown" } )
	panel:AddControl( "Numpad", { Label = "Toggle hoverball on/off", Command = "offset_hoverball_key_toggle", Label2 = "Brake (Hold)", Command2 = "offset_hoverball_key_brake" } )

	panel:AddControl("Slider", {
	    Label = "Height adjust rate",
	    Type = "Float",
	    Min = "0",
	    Max = "100",
	    Command = "offset_hoverball_adjust_speed"
	})
	
	panel:AddControl("Slider", {
	    Label = "Adjust braking resistance",
	    Type = "Float",
	    Min = "1",
	    Max = "30",
	    Command = "offset_hoverball_brake_resistance"
	})
	
	panel:AddControl( "Header", { Description = "Help:" } )
	panel:AddControl( "Header", { Description = "All keyboard controls are optional, Hoverballs will work fine without them." } )
	panel:AddControl( "Header", { Description = "Braking works by adjusting the air resistance value up while you're holding the brake key." } )
	
	panel:AddControl( "Header", { Description = "\n\n" } )
end

function TOOL:UpdateGhostHoverball( ent, ply )

	if ( !IsValid( ent ) ) then return end

	local trace = ply:GetEyeTrace()
	if IsValid(trace.Entity) then
		if ( !trace.Hit || trace.Entity && ( trace.Entity:GetClass() == "offset_hoverball" || trace.Entity:IsPlayer() ) ) then

			ent:SetNoDraw( true )
			return

		end
	end

	local ang = trace.HitNormal:Angle()
	ang.pitch = ang.pitch + 90
	ent:SetAngles( ang )

	local CurPos = ent:GetPos()
	local NearestPoint = ent:NearestPoint( CurPos - ( trace.HitNormal * 512 ) )
	local Offset = CurPos - NearestPoint
	ent:SetPos( trace.HitPos + Offset )

	ent:SetNoDraw( false )

end

local function IsValidHoverballModel( model )
	for mdl, _ in pairs( list.Get( "DistanceHoverballModels" ) ) do
		if ( mdl:lower() == model:lower() ) then return true end
	end
	return false
end

function TOOL:Think()

	local mdl = self:GetClientInfo( "model" )
	if ( !IsValidHoverballModel( mdl ) ) then self:ReleaseGhostEntity() return end

	if ( !IsValid( self.GhostEntity ) || self.GhostEntity:GetModel() != mdl ) then
		self:MakeGhostEntity( mdl, vector_origin, angle_zero )
	end

	self:UpdateGhostHoverball( self.GhostEntity, self:GetOwner() )
end

function toolGunEffect( trace, self ) 
    local effectdata = EffectData()
	effectdata:SetOrigin( trace.HitPos )
	effectdata:SetStart( self:GetOwner():GetShootPos() )
	util.Effect( "ToolTracer", effectdata )
end 


if ( SERVER ) then
	CreateConVar( "sbox_maxoffset_hoverball", "20", FCVAR_ARCHIVE, "How many distance hoverballs are players allowed?", 0)

	function Create_offset_hoverball( ply, pos, hoverdistance, hoverforce, damping, rotdamping, detectswater, adjustspeed, model, nocollide, key_toggle, key_heightup, key_heightdown, key_brake, brakeresistance )

		if ( IsValid( ply ) && !ply:CheckLimit( "offset_hoverball" ) ) then return false end
		if ( !IsValidHoverballModel( model ) ) then return false end
		
		local ball = ents.Create( "offset_hoverball" )
		ball:SetPos( pos )		
		
		ball.hoverdistance = 	hoverdistance
		ball.hoverforce = 		hoverforce
		ball.damping = 			damping
		ball.rotdamping = 		rotdamping
		ball.detectswater = 	detectswater
		ball.adjustspeed = 		adjustspeed
		ball.brakeresistance = 	brakeresistance
		ball:SetModel( model )
		ball:Spawn()
		
		ball:SetOverlayText( string.format( "Hover height: %g\nForce: %g\nAir resistance: %g\nAngular damping: %g\nBrake resistance: %g", ball.hoverdistance, ball.hoverforce, ball.damping, ball.rotdamping, ball.brakeresistance ))

		if ( IsValid( ply ) ) then
			ball:SetPlayer( ply )
		end

		// Setup numpad controls:
		ball.key_heightup = numpad.OnDown( ply, key_heightup, "offset_hoverball_heightup", ball, true )
		ball.key_heighbacktup = numpad.OnUp( ply, key_heightup, "offset_hoverball_heightup", ball, false )

		ball.key_heightdown = numpad.OnDown( ply, key_heightdown, "offset_hoverball_heightdown", ball, true )
		ball.key_heightbackdown = numpad.OnUp( ply, key_heightdown, "offset_hoverball_heightdown", ball, false )

		ball.key_brake = numpad.OnDown( ply, key_brake, "offset_hoverball_brake", ball, true )
		ball.key_brakerelase = numpad.OnUp( ply, key_brake, "offset_hoverball_brake", ball, false )
		
		if ( key_toggle ) then ball.key_toggle = numpad.OnDown( ply, key_toggle, "offset_hoverball_toggle", ball ) end

		if ( nocollide == true ) then
			if ( IsValid( ball:GetPhysicsObject() ) ) then ball:GetPhysicsObject():EnableCollisions( false ) end
			ball:SetCollisionGroup( COLLISION_GROUP_WORLD )
		end

		local ttable = {
			key_heightdown = key_heightdown,
			key_heightup = key_heightup,
			key_toggle = key_toggle,
			pl = ply,
			nocollide = nocollide,
			hoverdistance = hoverdistance,
			hoverforce = hoverforce,
			damping = damping,
			rotdamping = rotdamping,
			detectswater = detectswater,
			adjustspeed = adjustspeed,
			key_brake = key_brake,
			brakeresistance = brakeresistance,
			model = model
		}
		table.Merge( ball:GetTable(), ttable )

		if ( IsValid( ply ) ) then
			ply:AddCount( "offset_hoverballs", ball )
			ply:AddCleanup( "offset_hoverballs", ball )
		end

		DoPropSpawnedEffect( ball )

		return ball

	end
	duplicator.RegisterEntityClass( "offset_hoverball", Create_offset_hoverball, "pos", "hoverdistance", "hoverforce", "damping", "rotdamping", "detectswater", "adjustspeed", "model", "nocollide", "key_toggle", "key_heightup", "key_heightdown", "key_brake", "brakeresistance")
	
end






if (CLIENT) then
	language.Add( "tool.offset_hoverball.name", "Hoverball - Offset" )
	language.Add( "tool.offset_hoverball.desc", "Hoverballs that keep relative distance to the ground and can go up and down slopes." )
	language.Add( "tool.offset_hoverball.0", "LMB: Place or update hoverball. Select an entity to weld to it." )
	language.Add( "undone.offset_hoverball", "Undone offset hoverball" )
end

list.Set( "DistanceHoverballModels", "models/dav0r/hoverball.mdl", {} )
list.Set( "DistanceHoverballModels", "models/maxofs2d/hover_basic.mdl", {} )
list.Set( "DistanceHoverballModels", "models/maxofs2d/hover_classic.mdl", {} )
list.Set( "DistanceHoverballModels", "models/maxofs2d/hover_plate.mdl", {} )
list.Set( "DistanceHoverballModels", "models/maxofs2d/hover_propeller.mdl", {} )
list.Set( "DistanceHoverballModels", "models/maxofs2d/hover_rings.mdl", {} )
list.Set( "DistanceHoverballModels", "models/Combine_Helicopter/helicopter_bomb01.mdl", {} )
list.Set( "DistanceHoverballModels", "models/props_junk/sawblade001a.mdl", {} )
list.Set( "DistanceHoverballModels", "models/props_wasteland/prison_lamp001c.mdl", {} )
list.Set( "DistanceHoverballModels", "models/props_phx/wheels/drugster_front.mdl", {} )
list.Set( "DistanceHoverballModels", "models/props_phx/wheels/metal_wheel1.mdl", {} )
list.Set( "DistanceHoverballModels", "models/props_phx/smallwheel.mdl", {} )
list.Set( "DistanceHoverballModels", "models/props_phx/wheels/magnetic_small.mdl", {} )
list.Set( "DistanceHoverballModels", "models/props_phx/wheels/magnetic_medium.mdl", {} )
list.Set( "DistanceHoverballModels", "models/props_phx/wheels/magnetic_large.mdl", {} )
list.Set( "DistanceHoverballModels", "models/mechanics/wheels/wheel_smooth_24f.mdl", {} )
list.Set( "DistanceHoverballModels", "models/mechanics/wheels/wheel_smooth_48.mdl", {} )
list.Set( "DistanceHoverballModels", "models/mechanics/wheels/wheel_smooth_72.mdl", {} )
list.Set( "DistanceHoverballModels", "models/mechanics/wheels/wheel_smooth_18r.mdl", {} )
list.Set( "DistanceHoverballModels", "models/mechanics/wheels/wheel_smooth_24.mdl", {} )
list.Set( "DistanceHoverballModels", "models/mechanics/wheels/wheel_rounded_36s.mdl", {} )
list.Set( "DistanceHoverballModels", "models/props_phx/gears/bevel9.mdl", {} )
list.Set( "DistanceHoverballModels", "models/props_phx/gears/bevel12.mdl", {} )
list.Set( "DistanceHoverballModels", "models/props_phx/gears/bevel24.mdl", {} )
list.Set( "DistanceHoverballModels", "models/props_phx/gears/bevel36.mdl", {} )
list.Set( "DistanceHoverballModels", "models/hunter/plates/plate025x025.mdl", {} )
list.Set( "DistanceHoverballModels", "models/hunter/blocks/cube025x025x025.mdl", {} )
list.Set( "DistanceHoverballModels", "models/hunter/blocks/cube05x05x025.mdl", {} )
list.Set( "DistanceHoverballModels", "models/hunter/blocks/cube05x05x05.mdl", {} )
list.Set( "DistanceHoverballModels", "models/squad/sf_plates/sf_plate1x1.mdl", {} )
list.Set( "DistanceHoverballModels", "models/squad/sf_plates/sf_plate2x2.mdl", {} )
list.Set( "DistanceHoverballModels", "models/hunter/misc/sphere025x025.mdl", {} )
list.Set( "DistanceHoverballModels", "models/props_phx/misc/potato_launcher_cap.mdl", {} )
list.Set( "DistanceHoverballModels", "models/xqm/jetenginepropeller.mdl", {} )
list.Set( "DistanceHoverballModels", "models/items/combine_rifle_ammo01.mdl", {} )