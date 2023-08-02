include("shared.lua")

local laser = Material("sprites/bluelaser1")
local ShouldRenderLasers = GetConVar("offset_hoverball_showlasers")
local ShouldAlwaysRenderLasers = GetConVar("offset_hoverball_alwaysshowlasers")
local ToolMode = GetConVar("gmod_toolmode")

-- Baed on garrysmod/lua/derma/init.lua it looks like the game comes with the Roboto font, so it should be safe to use on all platforms?
surface.CreateFont( "OHBTipFont", {
	font = "Roboto Regular",
	size = 24,
	weight = 13,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	extended = true,
} )

surface.CreateFont( "OHBTipFontGlow", {
	font = "Roboto Regular",
	size = 24,
	weight = 13,
	scanlines = 0,
	antialias = true,
	extended = true,
	blursize = 5,
} )


surface.CreateFont( "OHBTipFontSmall", {
	font = "Roboto Regular",
	size = 20,
	weight = 13,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	extended = true,
} )


function ENT:DrawLaser()
	
	if ShouldAlwaysRenderLasers:GetBool() or (LocalPlayer():GetActiveWeapon():GetClass() == "gmod_tool" and ToolMode:GetString() == "offset_hoverball") then

		local hbpos = self:WorldSpaceCenter()
		local function traceFilter(ent) if (ent:GetClass() == "prop_physics") then return false end end
		local tr = util.TraceLine({
			start  = hbpos,
			output = output,
			endpos = hbpos + Vector(0, 0, -500),
			filter = traceFilter, mask = self.mask
		});
	
		if tr.Hit then
			cam.Start3D()
				render.SetMaterial(laser)
				render.DrawBeam(hbpos, tr.HitPos, 5, 0, 0, Color(100, 100, 255))
				render.SetMaterial(Material("Sprites/light_glow02_add"))
				render.DrawQuadEasy(tr.HitPos + Vector(0,0,1), tr.HitNormal, 30, 30, Color(100, 100, 255))
				render.DrawQuadEasy(hbpos, (EyePos() - LocalPlayer():GetEyeTrace().HitPos):GetNormal(), 30, 30, Color(100, 100, 255))
			cam.End3D()
		end
	end
end

local BoxOffsetX, BoxOffsetY = ScrW()/2+60, ScrH()/2-50

hook.Add( "HUDPaint", "OffsetHoverballs_MouseoverUI", function()
	local LookingAt = LocalPlayer():GetEyeTrace().Entity
	local BoxScaleX = 160
	
	if IsValid(LookingAt) and LookingAt:GetClass() == "offset_hoverball" then

		if (LookingAt:GetPos() - LocalPlayer():GetShootPos()):Length() > 300 then return end

		local HBData = string.Split(LookingAt:GetNWString("OHB-BetterTip"), ",")
		
		surface.SetFont( "OHBTipFontSmall" )
		local TextScaleOffset = 0
		for I=1,#HBData do if surface.GetTextSize(HBData[I]) > TextScaleOffset then TextScaleOffset = surface.GetTextSize(HBData[I]) end end
		BoxScaleX = BoxScaleX+TextScaleOffset
		
		if HBData[1] ~= "" then
			BoxOffsetY = ScrH()/2-60
			
			local triangle = {{ x = BoxOffsetX-16, y = BoxOffsetY+60 }, { x = BoxOffsetX, y = BoxOffsetY+44 }, { x = BoxOffsetX, y = BoxOffsetY+76 }}
			surface.SetDrawColor( 20, 20, 20, 255 ); draw.NoTexture(); surface.DrawPoly( triangle )
			
			draw.RoundedBox( 8, BoxOffsetX, BoxOffsetY-5, BoxScaleX, 142, Color( 20, 20, 20, 255 ) )
		    draw.RoundedBox( 8, BoxOffsetX+1, BoxOffsetY-2, BoxScaleX-2, 138, Color( 60, 60, 60, 255 ) )
			
			local triangle = {{ x = BoxOffsetX-15, y = BoxOffsetY+60 }, { x = BoxOffsetX+1,  y = BoxOffsetY+45 },	{ x = BoxOffsetX+1,  y = BoxOffsetY+75 }}
			surface.SetDrawColor( 60, 60, 60, 255 ); draw.NoTexture(); surface.DrawPoly( triangle )
			
			local Pulse = math.Clamp(math.abs( math.sin( CurTime() * 5 ) ), 0.1, 1 )
			draw.RoundedBoxEx( 8, BoxOffsetX+1, BoxOffsetY-4, BoxScaleX-2, 30, Color( 70, 70, 70, 255 ), true, true, false, false )
			draw.SimpleText( HBData[1], "OHBTipFontGlow", BoxOffsetX+(BoxScaleX/2), BoxOffsetY+24, Color( Pulse*255, Pulse*200, 0, 200 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText( HBData[1], "OHBTipFont", BoxOffsetX+(BoxScaleX/2), BoxOffsetY+24, Color( 200,200,200 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		else
			BoxOffsetY = ScrH()/2-80

			surface.SetDrawColor( 20, 20, 20, 255 ); draw.NoTexture(); surface.DrawPoly( {{ x = BoxOffsetX-16, y = BoxOffsetY+80 },	{ x = BoxOffsetX, y = BoxOffsetY+64 }, { x = BoxOffsetX, y = BoxOffsetY+96 }} )
			
			draw.RoundedBox( 8, BoxOffsetX, BoxOffsetY+22, BoxScaleX, 115, Color( 20, 20, 20, 255 ) )
			draw.RoundedBox( 8, BoxOffsetX+1, BoxOffsetY+23, BoxScaleX-2, 113, Color( 60, 60, 60, 255 ) )

			surface.SetDrawColor( 60, 60, 60, 255 ); draw.NoTexture(); surface.DrawPoly( {{ x = BoxOffsetX-15, y = BoxOffsetY+80 },	{ x = BoxOffsetX+1,  y = BoxOffsetY+65 }, { x = BoxOffsetX+1,  y = BoxOffsetY+95 }} )
		end
		
		draw.SimpleText( "Hover height:", "OHBTipFontSmall", BoxOffsetX+10, BoxOffsetY+40, Color( 200, 200, 200 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText( "Hover force:", "OHBTipFontSmall", BoxOffsetX+10, BoxOffsetY+60, Color( 200, 200, 200 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText( "Air resistance:", "OHBTipFontSmall", BoxOffsetX+10, BoxOffsetY+80, Color( 200, 200, 200 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText( "Angular damping:", "OHBTipFontSmall", BoxOffsetX+10, BoxOffsetY+100, Color( 200, 200, 200 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText( "Brake resistance:", "OHBTipFontSmall", BoxOffsetX+10, BoxOffsetY+120, Color( 200, 200, 200 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		
		draw.SimpleText( HBData[2], "OHBTipFontSmall", BoxOffsetX+(BoxScaleX-10), BoxOffsetY+40, Color( 80, 220, 80 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		draw.SimpleText( HBData[3], "OHBTipFontSmall", BoxOffsetX+(BoxScaleX-10), BoxOffsetY+60, Color( 80, 220, 80 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		draw.SimpleText( HBData[4], "OHBTipFontSmall", BoxOffsetX+(BoxScaleX-10), BoxOffsetY+80, Color( 80, 220, 80 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		draw.SimpleText( HBData[5], "OHBTipFontSmall", BoxOffsetX+(BoxScaleX-10), BoxOffsetY+100, Color( 80, 220, 80 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		draw.SimpleText( HBData[6], "OHBTipFontSmall", BoxOffsetX+(BoxScaleX-10), BoxOffsetY+120, Color( 80, 220, 80 ), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end
end)


function ENT:Draw()
	-- self.BaseClass.Draw(self) -- Overrides Draw
	self:DrawModel() -- Draws Model Client Side
	if ShouldRenderLasers:GetBool() or ShouldAlwaysRenderLasers:GetBool() then self:DrawLaser() end
end
