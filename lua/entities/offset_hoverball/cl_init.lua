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

local BoxOffsetX, BoxOffsetY = ScrW()/2+60, ScrH()/2-50
local CoOHBNeme   = Color( 200, 200, 200 )
local CoOHBValue  = Color( 80 , 220, 80  )
local CoOHBBack20 = Color( 20 , 20 , 20  )
local CoOHBBack60 = Color( 60 , 60 , 60  )
local CoOHBBack70 = Color( 70 , 70 , 70  )
local CoLaserBeam = Color( 100, 100, 255 )
local TableDrPoly = {{x=0,y=0},{x=0,y=0},{x=0,y=0}}
local TableOHBInf = {
	{2, "Hover height:    "},
	{3, "Hover force:     "},
	{4, "Air resistance:  "},
	{5, "Angular damping: "},
	{6, "Brake resistance:"}
}

function ENT:DrawLaser()
	
	if ShouldAlwaysRenderLasers:GetBool() or (LocalPlayer():GetActiveWeapon():GetClass() == "gmod_tool" and ToolMode:GetString() == "offset_hoverball") then

		local hbpos = self:WorldSpaceCenter()
		local function traceFilter(ent) if (ent:GetClass() == "prop_physics") then return false end end
		local tr = self:GetTrace(hbpos, -500)

		if tr.Hit then
			cam.Start3D()
				render.SetMaterial(laser)
				render.DrawBeam(hbpos, tr.HitPos, 5, 0, 0, CoLaserBeam)
				render.SetMaterial(Material("Sprites/light_glow02_add"))
				render.DrawQuadEasy(tr.HitPos + Vector(0,0,1), tr.HitNormal, 30, 30, CoLaserBeam)
				render.DrawQuadEasy(hbpos, LocalPlayer():GetAimVector(), 30, 30, CoLaserBeam)
			cam.End3D()
		end
	end
end

hook.Add( "HUDPaint", "OffsetHoverballs_MouseoverUI", function()
	local LookingAt = LocalPlayer():GetEyeTrace().Entity
	local BoxScaleX = 160
	
	if IsValid(LookingAt) and LookingAt:GetClass() == "offset_hoverball" then

		if (LookingAt:GetPos():DistToSqr(LocalPlayer():GetShootPos()) > 30000) then return end

		local HBData = string.Split(LookingAt:GetNWString("OHB-BetterTip"), ",")
		
		surface.SetFont( "OHBTipFontSmall" )
		local TextScaleOffset = 0
		for oi=1,#HBData do
			if surface.GetTextSize(HBData[oi]) > TextScaleOffset then
				TextScaleOffset = surface.GetTextSize(HBData[oi]) end
		end

		BoxScaleX = BoxScaleX+TextScaleOffset

		-- Overlay first argument is present
		if HBData[1] ~= "" then
			BoxOffsetY = ScrH()/2-60
			
			TableDrPoly[1].x = BoxOffsetX-16; TableDrPoly[1].y = BoxOffsetY+60
			TableDrPoly[2].x = BoxOffsetX   ; TableDrPoly[2].y = BoxOffsetY+44
			TableDrPoly[3].x = BoxOffsetX   ; TableDrPoly[3].y = BoxOffsetY+76

			surface.SetDrawColor(CoOHBBack20); draw.NoTexture(); surface.DrawPoly( TableDrPoly )
			
			draw.RoundedBox( 8, BoxOffsetX, BoxOffsetY-5, BoxScaleX, 142, CoOHBBack20 )
			draw.RoundedBox( 8, BoxOffsetX+1, BoxOffsetY-2, BoxScaleX-2, 138, CoOHBBack60 )
			
			TableDrPoly[1].x = BoxOffsetX-15; TableDrPoly[1].y = BoxOffsetY+60
			TableDrPoly[2].x = BoxOffsetX+1 ; TableDrPoly[2].y = BoxOffsetY+45
			TableDrPoly[3].x = BoxOffsetX+1 ; TableDrPoly[3].y = BoxOffsetY+75

			surface.SetDrawColor( CoOHBBack60 ); draw.NoTexture(); surface.DrawPoly( TableDrPoly )
			
			local CoDyn = Color( Pulse*255, Pulse*200, 0, 200 )
			local Pulse = math.Clamp(math.abs( math.sin( CurTime() * 5 ) ), 0.1, 1 )
			draw.RoundedBoxEx( 8, BoxOffsetX+1, BoxOffsetY-4, BoxScaleX-2, 30, CoOHBBack70, true, true, false, false )
			draw.SimpleText( HBData[1], "OHBTipFontGlow", BoxOffsetX+(BoxScaleX/2), BoxOffsetY+24, CoDyn, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText( HBData[1], "OHBTipFont", BoxOffsetX+(BoxScaleX/2), BoxOffsetY+24, CoOHBNeme, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		else
			BoxOffsetY = ScrH()/2-80

			surface.SetDrawColor(CoOHBBack20); draw.NoTexture()

			TableDrPoly[1].x = BoxOffsetX-16; TableDrPoly[1].y = BoxOffsetY+80
			TableDrPoly[2].x = BoxOffsetX   ; TableDrPoly[2].y = BoxOffsetY+64
			TableDrPoly[3].x = BoxOffsetX   ; TableDrPoly[3].y = BoxOffsetY+96

			surface.DrawPoly( TableDrPoly )
			
			draw.RoundedBox( 8, BoxOffsetX  , BoxOffsetY+22, BoxScaleX  , 115, CoOHBBack20 )
			draw.RoundedBox( 8, BoxOffsetX+1, BoxOffsetY+23, BoxScaleX-2, 113, CoOHBBack60 )

			surface.SetDrawColor( CoOHBBack60 ); draw.NoTexture()

			TableDrPoly[1].x = BoxOffsetX-15; TableDrPoly[1].y = BoxOffsetY+80
			TableDrPoly[2].x = BoxOffsetX+1 ; TableDrPoly[2].y = BoxOffsetY+65
			TableDrPoly[3].x = BoxOffsetX+1 ; TableDrPoly[3].y = BoxOffsetY+95

			surface.DrawPoly( TableDrPoly )
		end
		for di = 1, #TableOHBInf do
			local inf = TableOHBInf[di]
			local hbx = BoxOffsetX+10
			local hvx = BoxOffsetX+(BoxScaleX-10)
			local hby = BoxOffsetY+40+((di-1)*20)
			draw.SimpleText( inf[2], "OHBTipFontSmall", hbx, hby , CoOHBNeme, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText( HBData[inf[1]], "OHBTipFontSmall", hvx, hby, CoOHBValue, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
	end
end)


function ENT:Draw()
	-- self.BaseClass.Draw(self) -- Overrides Draw
	self:DrawModel() -- Draws Model Client Side
	if ShouldRenderLasers:GetBool() or ShouldAlwaysRenderLasers:GetBool() then self:DrawLaser() end
end
